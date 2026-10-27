# reporter.ts — 보낸 사람이 누구인가 — 로그인 없는 방식

- 놓을 곳: `src/lib/qa-feedback/reporter.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: **로그인 없는 방식만** — 로그인 방식이면 reporter.auth.ts.md를 같은 자리에
- 출처: (참고 구현에 없음 — 새로 씀)
- 참고 구현에서 바꾼 점: —
- 어댑터: `client-ip` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: IP 원문을 메모리·로그·이슈 어디에도 두지 않기(해시만)
- 의존: `server-only`

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
import "server-only";
/**
 * QA 피드백 — 보낸 사람이 누구인가: **로그인 없는 방식** (Vercel 배포만 있으면 된다 — DB·인증 없음).
 * 두 방식이 갈리는 서버 쪽 자리는 이 파일 하나다. 로그인이 붙으면 이 파일을 로그인 방식 견본으로 통째로 바꾼다(gate.ts도 같이).
 *  - 링크를 연 누구나 보낼 수 있다 → 남발은 접속 IP 기준 30초 1번·하루 20번(server.ts)으로 막는다.
 *  - IP는 한도 계산에만 쓴다. 원문은 메모리에도 두지 않고 인스턴스마다 새로 정한 소금값과 함께 해시한 값만 쓴다. 로그·이슈엔 안 넣는다.
 *  - 이슈엔 계정·팀 칸이 없다 — 테스터에게 「글 앞에 이름을 써 달라」고 미리 부탁한다.
 *  - 누구나 부를 수 있는 주소라 같은 출처 검사를 조인다(Origin 머리글이 없으면 거절 — 라우트가 QA_REPORTER_MODE를 보고 정한다).
 */
import type { NextRequest } from "next/server";
import type { QaDetailsFn, QaIdentifyFn } from "./server";

/** 지금 방식 — gate.ts와 같아야 한다. 스킬을 다시 부를 때 이 값으로 방식을 읽는다 */
export const QA_REPORTER_MODE: "anon" | "auth" = "anon";

/** 인스턴스마다 새로 정하는 소금값 — 해시만 봐서는 IP를 되찾을 수 없게 */
const SALT = crypto.randomUUID();

// [ADAPTER:client-ip] 접속 IP — Vercel은 x-forwarded-for 첫 값. Vercel 밖 호스팅이면 그 플랫폼이 믿을 만하게 채우는 머리글로 바꾼다(실측 필요)
function clientIp(request: NextRequest): string | null {
  const first = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  return first || null;
}
// [/ADAPTER:client-ip]

async function hashIp(ip: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`${SALT}:${ip}`));
  return Array.from(new Uint8Array(digest).slice(0, 12), (b) => b.toString(16).padStart(2, "0")).join("");
}

/** 누구인가 — 로그인이 없으니 늘 통과(401 없음). IP를 못 읽으면 모두 한 칸을 같이 쓴다(더 엄격한 쪽) */
export const identifyReporter: QaIdentifyFn = async (request) => {
  const ip = clientIp(request);
  return { rateKey: ip ? `ip:${await hashIp(ip)}` : "ip:unknown", userId: null };
};

/** 이슈에 적을 보낸 사람 — 「로그인 없는 방식」 한 줄만 */
export const reporterDetails: QaDetailsFn = async () => ({ mode: "anon" });
```
