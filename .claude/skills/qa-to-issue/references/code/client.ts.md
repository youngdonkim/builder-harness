# client.ts — 스위치 · 화면 정보 모으기 · 보내기

- 놓을 곳: `src/lib/qa-feedback/client.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/client.ts`
- 참고 구현에서 바꾼 점: 프로젝트 도우미(`../device`) 대신 UA 기반 최소 기기 판별을 안에 넣음
- 어댑터: `device-line` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 보내는 주소 `/api/qa-feedback`, 상태 코드 → 결과 매핑
- 의존: 없음 (`NEXT_PUBLIC_QA_FEEDBACK`·`NEXT_PUBLIC_BUILD_ID`는 next.config가 넣음 — wiring.md)

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
/**
 * QA 피드백 — 화면 쪽 스위치·자동 정보·보내기 (docs/qa-feedback.md). 브라우저에서만 부른다.
 * 믿을 수 있는 정보(보낸 사람·배포·UA·서버 시각)는 서버가 채운다. 여기선 화면만 아는 것만 모은다.
 */
import { maskPath, type QaClientMeta, type QaCollectedMeta, type QaFeedbackResult } from "./shared";

/** 이 빌드에서 켜져 있나 — 서버 환경변수 QA_FEEDBACK=on을 next.config가 빌드 때 "1"로 옮겨 준다(바꾸면 다시 배포) */
export const QA_FEEDBACK_ENABLED = process.env.NEXT_PUBLIC_QA_FEEDBACK === "1";

// [ADAPTER:device-line] 기기 한 줄 — 이슈에서 개발자가 읽는 값(화면 문구 아님). 프로젝트에 기기 판별 도우미가 있으면 그걸 쓰고, 없으면 아래 최소 판별을 그대로 둔다
function deviceLine(): string {
  const ua = navigator.userAgent;
  // 아이패드 사파리는 PC처럼 "Macintosh"로 자기를 알려서 터치 지점 수로 가른다
  const ios = /iPhone|iPad|iPod/i.test(ua) || (/Macintosh/i.test(ua) && navigator.maxTouchPoints > 1);
  const android = /Android/i.test(ua);
  const inApp = /KAKAOTALK|NAVER\(inapp|Instagram|FBAN|FBAV|Line\//i.test(ua);
  const standalone =
    window.matchMedia?.("(display-mode: standalone)").matches === true ||
    (navigator as Navigator & { standalone?: boolean }).standalone === true;
  const os = ios ? "아이폰·아이패드" : android ? "안드로이드" : "PC·기타";
  const where = inApp ? "앱 안 브라우저" : standalone ? "홈 화면 앱" : "브라우저";
  return `${os} ${where}`;
}
// [/ADAPTER:device-line]

/** 지금 화면의 정보 — 3번 연속 터치가 채워진 순간에 부른다(스크롤 위치가 그때 값이 되게). 주소는 `#` 뒤를 빼고 가린다 */
export function collectMeta(): QaCollectedMeta {
  return {
    path: maskPath(`${location.pathname}${location.search}`),
    device: deviceLine(),
    viewport: {
      width: window.innerWidth,
      height: window.innerHeight,
      dpr: window.devicePixelRatio || 1,
      zoom: window.visualViewport?.scale ?? 1,
      scrollY: Math.round(window.scrollY),
    },
    clientTime: new Date().toISOString(),
    buildId: process.env.NEXT_PUBLIC_BUILD_ID ?? "dev",
  };
}

/** 한 줄 + 정보 + 캡처(없으면 글만)를 서버로 보낸다. 연결 실패도 failed로 돌려준다 */
export async function sendQaFeedback(input: { text: string; meta: QaClientMeta; shot: Blob | null }): Promise<QaFeedbackResult> {
  const form = new FormData();
  form.set("text", input.text);
  form.set("meta", JSON.stringify(input.meta));
  if (input.shot) form.set("shot", input.shot, "shot.jpg");
  try {
    const res = await fetch("/api/qa-feedback", { method: "POST", body: form, cache: "no-store" });
    if (res.ok) return { kind: "sent" };
    if (res.status === 429) return { kind: "too-many" };
    if (res.status === 401) return { kind: "signed-out" };
    return { kind: "failed" };
  } catch {
    return { kind: "failed" };
  }
}
```
