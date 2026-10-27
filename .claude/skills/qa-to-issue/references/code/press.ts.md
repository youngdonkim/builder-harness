# press.ts — 「빈 곳」 판정

- 놓을 곳: `src/lib/qa-feedback/press.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/press.ts`
- 참고 구현에서 바꾼 점: 「열린 창」 선택자를 shadcn(Radix) 기본값으로
- 어댑터: `overlay-selector` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: INTERACTIVE·MEDIA 목록, 글자 줄 칸 판정
- 의존: 없음

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
/**
 * QA 피드백 — 「빈 곳」 판정. 브라우저에서만 부른다.
 * 누르는 요소·그림·열린 창·일부러 뺀 곳·글자 줄 위면 세 번 터치로 세지 않는다 — 그 자리의 원래 동작(누르기·글자 선택·그림 저장)이 그대로 나오게.
 * 「글자 위」는 눌린 요소 바로 아래 글자 덩어리가 실제로 차지한 줄 칸으로 판정한다 — 카드 여백·줄 끝 뒤 빈칸은 「빈 곳」으로 남는다.
 * (커서 위치 API caretPositionFromPoint는 글자 없는 칸에서도 가까운 글자를 돌려주고 user-select:none에서 null이 와 흔들려서 쓰지 않는다.)
 */

/** 누르는 요소 — 그 위에선 시작하지 않는다 */
const INTERACTIVE =
  "a, button, input, textarea, select, label, summary, [role=button], [role=link], [role=tab], [role=switch], [role=checkbox], [role=slider], [contenteditable], [tabindex]";
/** 그림·영상 */
const MEDIA = "img, picture, svg, video, canvas";
/** 열려 있는 창 위 · 일부러 뺄 곳(필요해지면 쓰는 탈출구 data-qa-ignore) */
const SKIP = "[role=dialog], [role=alertdialog], [data-qa-ignore]"; // [ADAPTER:overlay-selector] 열린 창·시트를 가리키는 선택자. shadcn(Radix) 창은 role=dialog — 실측 필요

/** 글자 줄 네모 칸에 주는 여유 (CSS px — 화면 좌표 계산값이라 토큰과 무관) */
const TEXT_SLACK = 4;

/** 누른 점이 이 요소 바로 아래 글자 덩어리(text node)가 실제로 차지한 줄 칸 안인가 */
function isOverOwnText(el: Element, x: number, y: number): boolean {
  const range = document.createRange();
  for (const node of el.childNodes) {
    if (node.nodeType !== Node.TEXT_NODE || !node.textContent?.trim()) continue;
    range.selectNodeContents(node);
    for (const r of range.getClientRects()) {
      if (x >= r.left - TEXT_SLACK && x <= r.right + TEXT_SLACK && y >= r.top - TEXT_SLACK && y <= r.bottom + TEXT_SLACK) return true;
    }
  }
  return false;
}

/** 여기서 한 터치를 세도 되나 (빈 곳인가) */
export function isEmptySpot(target: EventTarget | null, x: number, y: number): boolean {
  if (!(target instanceof Element)) return false;
  if (target.closest(INTERACTIVE) || target.closest(MEDIA) || target.closest(SKIP)) return false;
  return !isOverOwnText(target, x, y);
}
```
