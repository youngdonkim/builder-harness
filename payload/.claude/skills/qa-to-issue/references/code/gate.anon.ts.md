# gate.ts — 3번 터치 감지를 켜도 되나 — 로그인 없는 방식

- 놓을 곳: `src/lib/qa-feedback/gate.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: **로그인 없는 방식만** — 로그인 방식이면 gate.auth.ts.md를 같은 자리에
- 출처: (참고 구현에 없음 — 새로 씀)
- 참고 구현에서 바꾼 점: —
- 어댑터: 없음 — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: —
- 의존: 없음

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
/**
 * QA 피드백 — 3번 터치 감지를 켜도 되나: **로그인 없는 방식**.
 * 두 방식이 갈리는 화면 쪽 자리는 이 파일 하나다(서버 쪽은 reporter.ts). 스위치(QA_FEEDBACK)는 QaFeedback.tsx가 먼저 본다.
 * 로그인이 없으니 스위치가 켜진 빌드에선 첫 화면부터 늘 켠다.
 */

/** 지금 방식 — reporter.ts와 같아야 한다 */
export const QA_REPORTER_MODE: "anon" | "auth" = "anon";

/** 감지를 켜도 되나 — 로그인 없는 방식은 늘 참 */
export function useQaReady(): boolean {
  return true;
}
```
