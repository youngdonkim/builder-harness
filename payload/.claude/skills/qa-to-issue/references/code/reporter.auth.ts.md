# reporter.ts — 보낸 사람이 누구인가 — 로그인 방식

- 놓을 곳: `src/lib/qa-feedback/reporter.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: **로그인 방식만** — 로그인 없는 방식이면 reporter.anon.ts.md를 같은 자리에
- 출처: sangsiki-quiugi@5e9aa46 `src/app/api/qa-feedback/route.ts`의 로그인·탈퇴·팀 읽기 부분
- 참고 구현에서 바꾼 점: 라우트에서 떼어 이 파일로 옮김
- 어댑터: `auth-server`, `team?` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 계정·팀은 로그인 세션으로 다시 읽기(화면 값 안 믿음), 팀은 지금 팀원일 때만(RLS)
- 의존: `server-only`, 프로젝트의 서버 로그인 클라이언트

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
import "server-only";
/**
 * QA 피드백 — 보낸 사람이 누구인가: **로그인 방식** (로그인한 사람만 보낸다).
 * 두 방식이 갈리는 서버 쪽 자리는 이 파일 하나다(화면 쪽은 gate.ts).
 *  - 계정·팀은 화면이 보낸 값을 믿지 않고 로그인 세션으로 다시 읽는다. 서버 비밀 키는 쓰지 않는다 — 로그인 세션 클라이언트로 충분하다.
 *  - 팀 이름·팀에서 부르는 이름은 지금 팀원일 때만 읽힌다(RLS) — 다른 팀 id를 주소에 넣어 보내도 못 읽는다.
 *  - 로그인이 없거나 탈퇴했으면 null → 라우트가 401.
 *  - 연속 제출은 계정 기준(rateKey `user:<id>`).
 */
import type { QaTeam } from "./issue";
import type { QaDetailsFn, QaIdentifyFn } from "./server";
// [ADAPTER:auth-server] 로그인 세션을 읽는 서버 클라이언트. 기본값: Supabase(@/lib/supabase/server의 createClient — Supabase 공식 Next.js 예제 모양)
import { createClient } from "@/lib/supabase/server";
// [/ADAPTER:auth-server]

/** 지금 방식 — gate.ts와 같아야 한다. 스킬을 다시 부를 때 이 값으로 방식을 읽는다 */
export const QA_REPORTER_MODE: "anon" | "auth" = "auth";

/** 누구인가 — 로그인한 사용자 id. 로그인이 없거나 탈퇴했으면 null(401) */
export const identifyReporter: QaIdentifyFn = async () => {
  // [ADAPTER:auth-server] 로그인 사용자 id + 탈퇴 여부. 기본값: Supabase getClaims() + profiles.withdrawn_at. 탈퇴 표시 칸이 없으면 profiles 조회 두 줄을 지운다
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const userId = data?.claims?.sub;
  if (typeof userId !== "string" || !userId) return null;
  const { data: profile } = await supabase.from("profiles").select("withdrawn_at").eq("id", userId).maybeSingle();
  if (!profile || profile.withdrawn_at) return null;
  // [/ADAPTER:auth-server]
  return { rateKey: `user:${userId}`, userId };
};

/** 이슈에 적을 보낸 사람 — 계정 id와 (팀 개념이 있으면) 팀 */
export const reporterDetails: QaDetailsFn = async (who, meta) => ({
  mode: "auth",
  userId: who.userId ?? "",
  team: who.userId ? await readTeam(who.userId, meta.path) : null, // [ADAPTER:team?] 팀(워크스페이스) 개념이 없으면 이 줄·아래 팀 블록·위 QaTeam import·인자의 meta를 지운다(이슈에서 「팀」 줄이 빠진다)
});

// [ADAPTER:team?] 팀 읽기. 기본값은 참고 구현 모양 — members·teams 표, profiles.last_team_id, 주소의 ?team= 또는 /teams/{id}. 프로젝트의 표·주소 규칙으로 바꾼다
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** 주소에서 팀 id — ?team= 또는 /teams/{id}/… (모양이 맞을 때만) */
function teamIdFromPath(path: string): string | null {
  const url = new URL(path, "https://qa.invalid");
  const fromQuery = url.searchParams.get("team");
  if (fromQuery && UUID_RE.test(fromQuery)) return fromQuery;
  const fromPath = /^\/teams\/([^/]+)/.exec(url.pathname)?.[1];
  return fromPath && UUID_RE.test(fromPath) ? fromPath : null;
}

/** 주소의 팀 → 없으면 마지막으로 본 팀. 지금 팀원이 아니면 아무것도 안 읽힌다(RLS) */
async function readTeam(userId: string, path: string): Promise<QaTeam | null> {
  const supabase = await createClient();
  let teamId = teamIdFromPath(path);
  if (!teamId) {
    const { data: profile } = await supabase.from("profiles").select("last_team_id").eq("id", userId).maybeSingle();
    teamId = typeof profile?.last_team_id === "string" ? profile.last_team_id : null;
  }
  if (!teamId) return null;
  const [{ data: teamRow }, { data: me }] = await Promise.all([
    supabase.from("teams").select("name").eq("id", teamId).maybeSingle(),
    supabase.from("members").select("display_name").eq("team_id", teamId).eq("user_id", userId).is("left_at", null).is("kicked_at", null).maybeSingle(),
  ]);
  return teamRow ? { id: teamId, name: String(teamRow.name), myName: me?.display_name ? String(me.display_name) : null } : null;
}
// [/ADAPTER:team?]
```
