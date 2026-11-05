# press.ts — 세 번 터치로 셀 수 있는 곳 판정

- 놓을 곳: `src/lib/qa-feedback/press.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/press.ts`
- 참고 구현에서 바꾼 점: 「열린 창」 선택자를 shadcn(Radix) 기본값으로 · 「빈 곳」만 세던 판정(그림·글자 줄 위 제외)을 「누르는 요소·열린 창·뺀 곳만 제외」로 넓힘(2026-11-05 사람 결정 — why.md §1)
- 어댑터: `overlay-selector` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: INTERACTIVE 목록 · 글자·그림 위도 센다는 약속(제외하는 곳은 누르는 요소·열린 창·`data-qa-ignore`뿐)
- 의존: 없음

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
/**
 * QA 피드백 — 세 번 터치로 셀 수 있는 곳 판정. 브라우저에서만 부른다.
 * 누르는 요소(버튼·링크·탭·입력칸)·열린 창·일부러 뺀 곳(data-qa-ignore)만 세지 않는다 — 그 자리의 원래 동작이 그대로 나오게.
 * 글자·그림 위는 센다(폰 화면이 대부분 글자·카드·그림이라 빈 곳만 세면 찾기 어렵다 — why.md §1).
 */

/** 누르는 요소 — 그 위에선 시작하지 않는다 */
const INTERACTIVE =
  "a, button, input, textarea, select, label, summary, [role=button], [role=link], [role=tab], [role=switch], [role=checkbox], [role=slider], [contenteditable], [tabindex]";
/** 열려 있는 창 위 · 일부러 뺄 곳(필요해지면 쓰는 탈출구 data-qa-ignore) */
const SKIP = "[role=dialog], [role=alertdialog], [data-qa-ignore]"; // [ADAPTER:overlay-selector] 열린 창·시트를 가리키는 선택자. shadcn(Radix) 창은 role=dialog — 실측 필요

/** 여기서 한 터치를 세도 되나 */
export function isCountableTarget(target: EventTarget | null): boolean {
  if (!(target instanceof Element)) return false;
  return !target.closest(INTERACTIVE) && !target.closest(SKIP);
}
```
