# route.ts — 받는 서버 주소 `/api/qa-feedback`

- 놓을 곳: `src/app/api/qa-feedback/route.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통 (누구인가는 reporter.ts)
- 출처: sangsiki-quiugi@5e9aa46 `src/app/api/qa-feedback/route.ts`
- 참고 구현에서 바꾼 점: 로그인·탈퇴·팀 읽기를 reporter.ts로 뺌 · 응답 도우미를 안에 실음 · 로그인 없는 방식이면 Origin 머리글이 없는 요청도 거절
- 어댑터: `api-helpers` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 확인 순서(스위치 404 → 같은 출처 403 → 크기 413 → 누구인가 401 → 연속 제출 429 → 내용 400)
- 의존: Next.js App Router

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
import type { NextRequest } from "next/server";
import { formatIssueTime } from "@/lib/qa-feedback/issue";
import { identifyReporter, QA_REPORTER_MODE, reporterDetails } from "@/lib/qa-feedback/reporter";
import { deliverQaReport, deployInfo, parseMeta, parseShot, parseText, qaFeedbackOn, qaRateLimited } from "@/lib/qa-feedback/server";
import { QA_REQUEST_MAX_BYTES, type QaFeedbackResult } from "@/lib/qa-feedback/shared";

// QA 피드백 받기 — 빈 곳 3번 연속 터치 → 한 줄 → 보내기. 로그인 없는 방식·로그인 방식이 같은 라우트를 쓴다(누구인가는 reporter.ts).
// 확인 순서: 스위치(꺼짐 404) → 같은 출처(403) → 요청 크기(413) → 누구인가(로그인 방식만 401) → 연속 제출(429) → 내용(400) → 내보내기.
//  - 스위치가 꺼지면 없는 주소처럼 404 — 화면이 꺼져도 누가 주소를 직접 부를 수 있어 서버도 따로 막는다.
//  - 로그인 없는 방식은 누구나 부를 수 있는 주소라 Origin 머리글이 없는 요청도 거절한다.
//  - 보낸 사람·배포는 화면이 보낸 값을 믿지 않고 여기서 정한다.
//  - deliverQaReport()가 캡처를 캡처 저장소에 커밋하고 이슈(라벨)를 만든다. GitHub 설정이 없으면(로컬 등) 로그만 남긴다.
//  - 응답은 { kind } 하나 — 이슈 번호·주소·토큰은 돌려주지 않는다. 이슈 만들기가 실패하면 failed(502).
//  - 로그인 방식이면 이 주소가 로그인 세션 갱신(middleware/proxy)을 거쳐야 한다 — matcher에서 빼지 않는다.

export const dynamic = "force-dynamic";
/** 함수 전체 시간 — GitHub 호출 시간 제한(github.ts)이 이 안에 든다 */
export const maxDuration = 30;

// [ADAPTER:api-helpers] 응답·같은 출처 도우미. 프로젝트에 같은 도우미가 있으면 그걸 import하고 이 블록을 지운다 — 단 sameOrigin은 requireOrigin(Origin 없으면 거절)을 지켜야 한다
const NO_STORE = { "Cache-Control": "no-store" };

function json(body: unknown, status = 200) {
  return Response.json(body, { status, headers: NO_STORE });
}

/** 다른 사이트에서 보낸 요청은 받지 않는다 — Origin이 있으면 이 주소와 같아야 하고, requireOrigin이면 Origin이 꼭 있어야 한다 */
function sameOrigin(request: NextRequest, requireOrigin: boolean): boolean {
  const origin = request.headers.get("origin");
  if (!origin) return !requireOrigin;
  try {
    return new URL(origin).host === request.nextUrl.host;
  } catch {
    return false;
  }
}
// [/ADAPTER:api-helpers]

const notFound = () => new Response("Not Found", { status: 404, headers: NO_STORE });

export async function POST(request: NextRequest) {
  if (!qaFeedbackOn()) return notFound();
  if (!sameOrigin(request, QA_REPORTER_MODE === "anon")) return json({ error: "forbidden" }, 403);

  const length = Number(request.headers.get("content-length") ?? 0);
  if (length > QA_REQUEST_MAX_BYTES) return json({ error: "too-large" }, 413);

  const who = await identifyReporter(request);
  if (!who) return json({ kind: "signed-out" } satisfies QaFeedbackResult, 401);

  const now = new Date();
  if (qaRateLimited(who.rateKey, now.getTime())) return json({ kind: "too-many" } satisfies QaFeedbackResult, 429);

  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return json({ error: "bad-request" }, 400);
  }
  const text = parseText(form.get("text"));
  if (!text) return json({ error: "bad-text" }, 400);
  const meta = parseMeta(form.get("meta"));
  const shot = await parseShot(form.get("shot"));
  const reporter = await reporterDetails(who, meta);

  try {
    await deliverQaReport({
      text,
      meta,
      shot,
      userAgent: request.headers.get("user-agent") ?? "",
      serverTime: formatIssueTime(now),
      host: request.nextUrl.host,
      reporter,
      deploy: deployInfo(meta.buildId),
    });
  } catch {
    return json({ kind: "failed" } satisfies QaFeedbackResult, 502);
  }
  return json({ kind: "sent" } satisfies QaFeedbackResult);
}
```
