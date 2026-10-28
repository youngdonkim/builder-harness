# capture.ts — DOM 캡처 + 아이폰(WebKit) 대응

- 놓을 곳: `src/lib/qa-feedback/capture.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/capture.ts`
- 참고 구현에서 바꾼 점: 빼는 요소 목록(EXCLUDE)의 창·토스트 선택자만 shadcn 기본값으로, 머리 주석 일반화, **안쪽 스크롤 칸 처리 추가**(`markScrolls`·`applyScrolls` — 본문 칸만 스크롤되는 셸에서 캡처가 칸 맨 위로 찍히던 문제, 이벤트 알리미 PC 크롬 실측 2026-10-28. 아이폰 실기기는 아직 — why.md 10절). 그 밖의 코드는 바꾸지 않았다
- 어댑터: `exclude-selectors` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: EXCLUDE 한 줄 밖 전부 — 줄마다 아이폰 실측이 걸려 있다(why.md 「캡처」)
- 의존: `modern-screenshot` (^4.7.0)

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
/**
 * QA 피드백 — 3번째 터치 순간 「보이던 화면만」 JPEG로 찍는다.
 * 이 파일은 3번 연속 터치가 채워졌을 때(또는 한가할 때 미리) 동적 import로만 불린다 — modern-screenshot이 첫 화면 번들에 실리지 않게.
 * 진짜 스크린샷이 아니다 — 웹은 휴대폰 화면을 찍을 수 없어(화면 공유 API는 모바일에서 안 됨) 지금 DOM을 그림으로 다시 그린다.
 *
 * 아래 대응은 PC 크롬에선 필요 없었고 아이폰(WebKit)에서만 깨졌던 것들이다. 크롬도 같은 방식으로 맞게 찍힌다. **손대지 않는다.**
 *  - 스크롤: 복제본을 옮기지(transform) 않는다. 문서 맨 위부터 「보이던 화면 아래 끝」까지 그린 뒤,
 *    우리 캔버스에서 보이던 구간만 잘라 낸다. 아이폰(WebKit)은 옮긴 복제본의 원래 상자 밖을 안 그려서 아래가 검게 나왔다.
 *    잘라 낸 캔버스는 먼저 페이지 바탕색으로 칠한다 — 라이브러리가 사파리용으로 캔버스를 지웠다 다시 그리며 바탕을 지워서,
 *    빈 곳이 JPEG에서 검게 나왔다(왼쪽 검은 세로 띠).
 *  - 안쪽 스크롤 칸(창은 그대로고 본문 칸 같은 상자만 스크롤되는 셸): 복제본은 스크롤이 0으로 돌아가 칸 맨 위가 찍힌다.
 *    그 순간 scrollTop·scrollLeft가 0이 아닌 칸을 계산으로 찾아 두고(클래스 이름에 기대지 않는다), 복제본에서 칸은 원래 크기에
 *    overflow hidden으로 두고 안의 내용만 **여백(margin)으로** 스크롤만큼 당긴다 — 흐름 방향은 맨 앞에 넣은 빈 칸의 음수 여백 하나로
 *    뒤 내용 전체를, 옆 방향은 자식마다 음수 여백으로. transform·relative로 옮기지 않는 이유는 위와 같다(WebKit은 옮긴 상자의
 *    원래 자리 밖을 안 그린다 — 라이브러리의 restoreScrollPosition 기능도 transform이라 쓰지 않는다). 여백은 그리기 단계가 아니라
 *    배치 자체를 바꿔서 이 함정을 비켜 간다. 격자(grid) 칸은 여백으로 옮기면 줄 크기가 바뀌어 건드리지 않는다(맨 위로 찍힌다).
 *  - 복제본 맨 바깥(body): 바깥 여백 0·relative·overflow visible로 둔다. 창이 열리며 body에 건 스크롤 잠금(overflow hidden)이
 *    복제본에 따라 들어가지 않게, 그림 안 기본 여백(8px)이 왼쪽 띠로 나오지 않게.
 *  - 붙어 있는 칸(sticky — 헤더·탭바)·화면에 고정된 칸(fixed): 그 순간 보이던 자리를 재 두고, 복제본에서 그 자리에
 *    absolute로 못 박는다(sticky는 빈 자리 지킴이를 남겨 흐름을 그대로 둔다). 원본에 잠깐 data-qa-pin 표시를 달아 복제본과 짝짓는다.
 *    특정 클래스 이름을 적지 않고 계산된 position으로 찾는다. 안쪽 스크롤 칸 안의 sticky도 같다 — 자리를 그 순간의 기준 상자에서
 *    재고, 기준 상자가 칸 안에 있으면 그 상자도 여백으로 같이 당겨지고, 칸 밖이나 칸 자신이면 원래 그 자리라 따로 손대지 않는다.
 *  - 고리 그림자(`0 0 0 Npx 색` — 흐림·옮김 없는 spread만): WebKit이 그림 안에서 옆으로 어긋나(반달처럼) 그려서, 복제본에서만
 *    맨 위 고리를 outline으로 바꾼다. 흐림 있는 그림자·나머지 층은 그대로.
 *  - 글꼴: 조각(unicode-range) 글꼴은 라이브러리에 맡기면 조각 수백 개를 다 받아 넣는다.
 *    브라우저가 **이미 받아 둔 조각만**(document.fonts에서 status "loaded") 골라 data URL로 바꿔 font.cssText로 넘긴다.
 *    (font.cssText는 라이브러리가 주소를 data URL로 바꿔 주지 않아서 여기서 바꾼다 — 그림(SVG) 안에서는 바깥 주소를 못 부른다)
 *    같은 출처 글꼴만 넣는다 — 다른 사이트(CDN)에서 받는 글꼴은 캡처에서 기본 글꼴로 나온다.
 *  - 상한: 배율 최대 2, JPEG 품질 0.8, 1.5MB 넘으면 배율 1로 다시 만들기, 중간 캔버스 1,200만 픽셀·한 변 16,000px(iOS 캔버스 한도 아래).
 *  - 창·토스트·Next 개발 표시·라이브러리 임시 iframe은 빼고 찍는다.
 * 화면에 그리는 것은 없다. 여기 나오는 px는 브라우저가 잰 런타임 좌표라 CSS 토큰 규칙과 무관하다.
 */
import { domToCanvas } from "modern-screenshot";

/** 캡처에서 빼는 것 — nextjs-portal(Next 개발 표시)·[data-qa-ignore]·라이브러리 임시 iframe은 그대로 두고, 창·토스트 선택자만 프로젝트 것으로 */
const EXCLUDE = '[role=dialog], [data-slot$="-overlay"], [data-radix-popper-content-wrapper], [data-sonner-toaster], nextjs-portal, [data-qa-ignore], iframe[id^="__SANDBOX__"]'; // [ADAPTER:exclude-selectors] 열린 창·토스트 선택자. 기본값은 shadcn(Radix 창·sonner 토스트) 후보 — 실측 필요
/** 원본·복제본 짝짓기 표시 (찍는 동안만 원본에 붙는다) */
const PIN_ATTR = "data-qa-pin";
/** 원본·복제본 안쪽 스크롤 칸 짝짓기 표시 (찍는 동안만 원본에 붙는다) */
const SCROLL_ATTR = "data-qa-scroll";
const JPEG_QUALITY = 0.8;
/** 배율 상한 — 아이폰 캔버스 넓이 한도 안에 두려고 */
const SCALE_MAX = 2;
/** 이보다 크면 배율 1로 다시 만든다 (서버 캡처 한도 2MB) */
const SHOT_RETRY_BYTES = 1.5 * 1024 * 1024;
/** 맨 위부터 그리는 캔버스의 넓이 상한(픽셀 수) — iOS 캔버스 한도(약 1,677만)보다 넉넉히 아래. 넘으면 배율을 낮춘다 */
const RENDER_PIXEL_BUDGET = 12_000_000;
/** 캔버스 한 변 상한 (픽셀) */
const RENDER_SIDE_MAX = 16_000;
/** 글꼴 조각 하나 받기 시간 한도 (캐시에서 나오니 보통 바로) */
const FONT_FETCH_MS = 4000;

/* ── 붙어 있는 칸·고정된 칸 못 박기 ── */

type Pin = { top: number; left: number; inFlow: boolean };

/** absolute 자식의 기준 상자(containing block)가 되는 조상. 못 찾으면 body(복제본에서 relative로 둔다) */
function absoluteContainer(el: Element): Element {
  for (let a = el.parentElement; a && a !== document.body; a = a.parentElement) {
    const cs = getComputedStyle(a);
    if (
      cs.position !== "static" ||
      cs.transform !== "none" ||
      cs.perspective !== "none" ||
      cs.filter !== "none" ||
      (cs.containerType && cs.containerType !== "normal") ||
      /paint|layout|strict|content/.test(cs.contain) ||
      /transform|perspective|filter/.test(cs.willChange)
    )
      return a;
  }
  return document.body;
}

/** 지금 보이는 sticky·fixed 칸의 자리를 재고 원본에 짝 표시를 단다 — 같은 순간 안이라 화면에 그려지지 않는다 */
function markPins(): Pin[] {
  const pins: Pin[] = [];
  for (const el of document.body.querySelectorAll<HTMLElement>("*")) {
    const position = getComputedStyle(el).position;
    if (position !== "sticky" && position !== "fixed") continue;
    if (el.closest(EXCLUDE)) continue;
    if (!el.getClientRects().length) continue; // 안 보이는 칸
    const rect = el.getBoundingClientRect();
    const cb = absoluteContainer(el);
    const cbRect = cb.getBoundingClientRect();
    el.setAttribute(PIN_ATTR, String(pins.length));
    pins.push({ top: rect.top - cbRect.top - cb.clientTop, left: rect.left - cbRect.left - cb.clientLeft, inFlow: position === "sticky" });
  }
  return pins;
}

/** 찍는 동안 원본에 단 짝 표시(못 박기·스크롤 칸)를 모두 뗀다 */
function unmarkAll() {
  document.body.querySelectorAll(`[${PIN_ATTR}], [${SCROLL_ATTR}]`).forEach((el) => {
    el.removeAttribute(PIN_ATTR);
    el.removeAttribute(SCROLL_ATTR);
  });
}

/** absolute로 바꿀 때 지울 논리 방향 값 — 물리 값(top·left·margin)과 겹치면 나중 것이 이겨서 */
const LOGICAL_OFFSETS = [
  "inset", "inset-block", "inset-inline", "inset-block-start", "inset-block-end", "inset-inline-start", "inset-inline-end",
  "margin-block", "margin-inline", "margin-block-start", "margin-block-end", "margin-inline-start", "margin-inline-end",
];

function applyPins(clone: Node, pins: Pin[]) {
  if (!(clone instanceof Element)) return;
  clone.querySelectorAll<HTMLElement>(`[${PIN_ATTR}]`).forEach((el) => {
    const pin = pins[Number(el.getAttribute(PIN_ATTR))];
    el.removeAttribute(PIN_ATTR);
    if (!pin) return;
    if (pin.inFlow) {
      // sticky는 흐름 속 자리를 차지한다 — 같은 크기의 빈 자리 지킴이를 남겨 뒤 칸이 당겨 오지 않게
      const keeper = el.cloneNode(false) as HTMLElement;
      keeper.style.position = "static";
      keeper.style.visibility = "hidden";
      keeper.removeAttribute("id");
      keeper.setAttribute("aria-hidden", "true");
      el.before(keeper);
    }
    for (const name of LOGICAL_OFFSETS) el.style.removeProperty(name);
    el.style.position = "absolute";
    el.style.top = `${pin.top}px`;
    el.style.left = `${pin.left}px`;
    el.style.right = "auto";
    el.style.bottom = "auto";
    el.style.margin = "0";
  });
}

/* ── 안쪽 스크롤 칸 (창이 아니라 상자가 스크롤되는 셸) ── */

/** flow: 내용이 쌓이는 방향 — 블록 흐름·세로 flex는 column, 가로 flex는 row. gap: 그 방향 flex 간격(블록은 0) */
type Scroll = { top: number; left: number; flow: "row" | "column"; gap: number };

/** 지금 스크롤된 안쪽 칸을 찾아 스크롤 양을 재고 원본에 짝 표시를 단다 — 창 스크롤은 captureViewport의 잘라 내기가 맡는다 */
function markScrolls(): Scroll[] {
  const scrolls: Scroll[] = [];
  for (const el of document.body.querySelectorAll<HTMLElement>("*")) {
    const top = el.scrollTop;
    const left = el.scrollLeft;
    if (!(top > 0) && !(left > 0)) continue; // 음수는 거꾸로 쌓는 칸(…-reverse·오른쪽부터 쓰기) — 건드리지 않는다
    if (el.closest(EXCLUDE)) continue;
    const cs = getComputedStyle(el);
    if (cs.display.includes("grid")) continue; // 격자는 여백으로 옮기면 줄 크기가 바뀐다 — 맨 위로 찍히게 둔다
    const flex = cs.display.includes("flex");
    if (flex && cs.flexDirection.endsWith("reverse")) continue;
    const flow = flex && cs.flexDirection === "row" ? "row" : "column";
    const gap = flex ? parseFloat(flow === "row" ? cs.columnGap : cs.rowGap) || 0 : 0;
    el.setAttribute(SCROLL_ATTR, String(scrolls.length));
    scrolls.push({ top: Math.max(0, top), left: Math.max(0, left), flow, gap });
  }
  return scrolls;
}

/** 여백 값 앞에 지울 논리 방향 값 — 겹치면 나중 것이 이겨서 (LOGICAL_OFFSETS와 같은 이유) */
const LOGICAL_MARGIN: Record<"margin-top" | "margin-left", string> = { "margin-top": "margin-block-start", "margin-left": "margin-inline-start" };

/** 복제본에서 스크롤 칸 안의 내용을 여백으로 당긴다 — 칸은 원래 크기·overflow hidden으로 두고, transform·relative는 쓰지 않는다 */
function applyScrolls(clone: Node, scrolls: Scroll[]) {
  if (!(clone instanceof Element)) return;
  clone.querySelectorAll<HTMLElement>(`[${SCROLL_ATTR}]`).forEach((box) => {
    const scroll = scrolls[Number(box.getAttribute(SCROLL_ATTR))];
    box.removeAttribute(SCROLL_ATTR);
    if (!scroll) return;
    const along = scroll.flow === "row" ? scroll.left : scroll.top; // 쌓이는 방향 스크롤
    const across = scroll.flow === "row" ? scroll.top : scroll.left; // 옆 방향 스크롤
    const alongSide = scroll.flow === "row" ? "margin-left" : "margin-top";
    const acrossSide = scroll.flow === "row" ? "margin-top" : "margin-left";

    // 옆 방향은 자식이 서로 밀지 않는다 — 자식마다 당긴다 (복제본 자식은 너비·높이가 px로 박혀 있어 크기는 그대로)
    if (across) {
      for (const child of box.children) {
        if (!(child instanceof HTMLElement)) continue;
        const current = parseFloat(child.style.getPropertyValue(acrossSide)) || 0;
        child.style.removeProperty(LOGICAL_MARGIN[acrossSide]);
        child.style.setProperty(acrossSide, `${current - across}px`);
      }
    }
    // 쌓이는 방향은 맨 앞에 빈 칸 하나를 넣어 음수 여백으로 뒤 내용 전체를 당긴다 (flex면 빈 칸이 만드는 간격 하나도 같이 뺀다)
    if (along) {
      const spacer = box.ownerDocument.createElement("div");
      spacer.setAttribute("aria-hidden", "true");
      spacer.style.cssText = "display:block;flex:none;width:0;height:0;padding:0;border:0;margin:0";
      spacer.style.setProperty(alongSide, `${-(along + scroll.gap)}px`);
      box.prepend(spacer);
    }
    box.style.overflow = "hidden";
  });
}

/* ── 고리 그림자 → outline (복제본만) ── */

/** 괄호 밖의 구분자로 나눈다 — rgb(1, 2, 3) 안의 쉼표·빈칸은 그대로 */
function splitTop(value: string, separator: "," | " "): string[] {
  const out: string[] = [];
  let depth = 0;
  let cur = "";
  for (const ch of value) {
    if (ch === "(") depth++;
    else if (ch === ")") depth--;
    if (depth === 0 && (separator === "," ? ch === "," : /\s/.test(ch))) {
      if (cur.trim()) out.push(cur.trim());
      cur = "";
    } else cur += ch;
  }
  if (cur.trim()) out.push(cur.trim());
  return out;
}

const LENGTH_RE = /^(-?(?:\d+\.?\d*|\.\d+))(px)?$/;

/** `색 0px 0px 0px Npx`(흐림·옮김 없이 spread만, inset 아님)이면 {spread, color} */
function parseRing(layer: string): { spread: number; color: string } | null {
  const lengths: number[] = [];
  const color: string[] = [];
  for (const token of splitTop(layer, " ")) {
    if (token === "inset") return null;
    const m = LENGTH_RE.exec(token);
    if (m) lengths.push(Number(m[1]));
    else color.push(token);
  }
  if (lengths.length !== 4 || lengths[0] !== 0 || lengths[1] !== 0 || lengths[2] !== 0 || !(lengths[3] > 0)) return null;
  return { spread: lengths[3], color: color.join(" ") || "currentcolor" };
}

/** 맨 위(첫 번째) 그림자 층이 고리면 outline으로 옮긴다 — outline은 그림자보다 위에 그려지니 겹침 순서가 같다 */
function ringToOutline(node: Node) {
  if (!(node instanceof HTMLElement)) return;
  const style = node.style;
  const shadow = style.getPropertyValue("box-shadow");
  if (!shadow || shadow === "none") return;
  const outlineStyle = style.getPropertyValue("outline-style");
  if (outlineStyle && outlineStyle !== "none") return; // 제 outline이 있다(포커스 등) — 손대지 않는다
  const layers = splitTop(shadow, ",");
  const ring = parseRing(layers[0]);
  if (!ring) return;
  style.setProperty("outline", `${ring.spread}px solid ${ring.color}`);
  style.setProperty("outline-offset", "0px");
  style.setProperty("box-shadow", layers.length > 1 ? layers.slice(1).join(", ") : "none");
}

/* ── 이미 받은 글꼴 조각만 ── */

const norm = (s: string) => s.replace(/["']/g, "").replace(/\s+/g, "").toLowerCase();
const normWeight = (w: string) => (w === "normal" ? "400" : w === "bold" ? "700" : w);
const faceKey = (family: string, weight: string, style: string, range: string) =>
  [norm(family), normWeight(norm(weight || "normal")), norm(style || "normal"), norm(range || "U+0-10FFFF")].join("|");

function collectFontFaceRules(rules: CSSRuleList, out: CSSFontFaceRule[]) {
  for (const rule of rules) {
    if (rule instanceof CSSFontFaceRule) out.push(rule);
    else if ("cssRules" in rule && rule.cssRules instanceof CSSRuleList) collectFontFaceRules(rule.cssRules, out);
  }
}

function blobToDataUrl(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });
}

/** 브라우저가 이미 받아 둔 글꼴 조각만 data URL로 바꾼 @font-face 묶음 (하나도 못 찾으면 null) */
async function loadedFontCss(): Promise<string | null> {
  const loaded = new Set<string>();
  document.fonts.forEach((f) => {
    if (f.status === "loaded") loaded.add(faceKey(f.family, f.weight, f.style, f.unicodeRange));
  });
  if (!loaded.size) return null;

  const rules: CSSFontFaceRule[] = [];
  for (const sheet of document.styleSheets) {
    try {
      collectFontFaceRules(sheet.cssRules, rules);
    } catch {
      // 다른 사이트 스타일시트는 읽을 수 없다 — 건너뛴다
    }
  }

  const picked = rules.filter((r) =>
    loaded.has(
      faceKey(r.style.getPropertyValue("font-family"), r.style.getPropertyValue("font-weight"), r.style.getPropertyValue("font-style"), r.style.getPropertyValue("unicode-range")),
    ),
  );

  const faces = await Promise.all(
    picked.map(async (rule) => {
      const src = rule.style.getPropertyValue("src");
      const match = /url\(\s*(["']?)([^"')]+)\1\s*\)/.exec(src);
      if (!match) return null;
      try {
        const url = new URL(match[2], rule.parentStyleSheet?.href ?? location.href);
        if (url.origin !== location.origin) return null;
        const res = await fetch(url, { cache: "force-cache", signal: AbortSignal.timeout(FONT_FETCH_MS) });
        if (!res.ok) return null;
        const dataUrl = await blobToDataUrl(await res.blob());
        return rule.cssText.replace(/src\s*:[^;}]+/, `src: url("${dataUrl}")`);
      } catch {
        return null; // 이 조각만 빠진다 — 그 글자는 기본 글꼴로 나온다
      }
    }),
  );
  const css = faces.filter((f): f is string => f !== null).join("\n");
  return css || null;
}

/* ── 찍기 ── */

function canvasToJpeg(canvas: HTMLCanvasElement): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error("toBlob 실패"))), "image/jpeg", JPEG_QUALITY);
  });
}

function pageBackground(): string {
  const transparent = (c: string) => !c || c === "transparent" || c === "rgba(0, 0, 0, 0)";
  const body = getComputedStyle(document.body).backgroundColor;
  if (!transparent(body)) return body;
  const html = getComputedStyle(document.documentElement).backgroundColor;
  return transparent(html) ? "white" : html;
}

/** 보이던 화면(innerWidth × innerHeight)만 JPEG로. 실패하면 오류 */
export async function captureViewport(): Promise<Blob> {
  // 3번째 터치 그 순간의 자리 — 기다리기 전에 먼저 적어 둔다
  const width = window.innerWidth;
  const height = window.innerHeight;
  const bodyRect = document.body.getBoundingClientRect();
  const cropX = Math.max(0, -bodyRect.left); // body 왼쪽 위에서 보이던 구간까지의 거리 = 스크롤
  const cropY = Math.max(0, -bodyRect.top);
  const backgroundColor = pageBackground();
  const scrolls = markScrolls();
  const pins = markPins();

  try {
    const fontCss = await loadedFontCss().catch(() => null);

    // 맨 위부터 보이던 구간 아래 끝까지 그린다 — 넓이 한도를 넘으면 배율을 낮춘다
    const renderWidth = Math.ceil(cropX + width);
    const renderHeight = Math.ceil(cropY + height);
    const renderScale = Math.min(
      window.devicePixelRatio || 1,
      SCALE_MAX,
      Math.sqrt(RENDER_PIXEL_BUDGET / (renderWidth * renderHeight)),
      RENDER_SIDE_MAX / renderWidth,
      RENDER_SIDE_MAX / renderHeight,
    );

    const source = await domToCanvas(document.body, {
      width: renderWidth,
      height: renderHeight,
      scale: renderScale,
      backgroundColor,
      style: { margin: "0", position: "relative", overflow: "visible" },
      filter: (node) => !(node instanceof Element && node.matches(EXCLUDE)),
      font: fontCss ? { cssText: fontCss } : false,
      onCloneEachNode: ringToOutline,
      // 스크롤 칸 먼저 — 못 박은 칸은 applyPins가 여백을 0으로 되돌려 당겨지지 않는다
      onCloneNode: (clone) => {
        applyScrolls(clone, scrolls);
        applyPins(clone, pins);
      },
      timeout: 8000,
    });
    unmarkAll();

    // 보이던 구간만 잘라 바탕색 위에 옮겨 그린다
    const ratioX = source.width / renderWidth;
    const ratioY = source.height / renderHeight;
    const bake = (scale: number) => {
      const out = document.createElement("canvas");
      out.width = Math.max(1, Math.round(width * scale));
      out.height = Math.max(1, Math.round(height * scale));
      const ctx = out.getContext("2d");
      if (!ctx) throw new Error("캔버스를 못 만듦");
      ctx.fillStyle = backgroundColor;
      ctx.fillRect(0, 0, out.width, out.height);
      ctx.drawImage(source, cropX * ratioX, cropY * ratioY, width * ratioX, height * ratioY, 0, 0, out.width, out.height);
      return out;
    };

    try {
      let out = bake(renderScale);
      let blob = await canvasToJpeg(out);
      out.width = out.height = 0;
      if (blob.size > SHOT_RETRY_BYTES && renderScale > 1) {
        out = bake(1);
        blob = await canvasToJpeg(out);
        out.width = out.height = 0;
      }
      return blob;
    } finally {
      source.width = source.height = 0; // 아이폰 캔버스 메모리를 바로 돌려준다
    }
  } finally {
    unmarkAll();
  }
}
```
