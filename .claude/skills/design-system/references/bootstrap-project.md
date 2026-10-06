# 새 프로젝트에 이 시스템 도입하기

이 스킬은 builder-harness 하네스에 들어 있어서, 하네스를 적용한 프로젝트에서는 따로
복사할 필요 없이 바로 쓸 수 있다. 새 프로젝트에 이 디자인 시스템을 도입할 때는 아래
순서를 따른다. 스택은 Tailwind + shadcn 고정이다.

CSS 3층만으로(`3-components.css`가 부품 몸통인 구조) 이미 지은 프로젝트는 그대로 둔다 —
이 절차는 새 프로젝트에 적용한다.

## 목차

0. [목업 반입(intake) — 무대 장치 제거](#0-목업-반입intake--무대-장치-제거)
1. [토큰 3층 구축 — shadcn 위에](#1-토큰-3층-구축--shadcn-위에)
   - [1.1 순서](#11-순서)
   - [1.2 2층 파일의 모양](#12-2층-파일의-모양)
   - [1.3 진입 CSS](#13-진입-css)
   - [1.4 모션 토큰과 동작 줄이기 규칙](#14-모션-토큰과-동작-줄이기-규칙)
2. [컴포넌트 인벤토리(사전) 생성](#2-컴포넌트-인벤토리사전-생성)
3. [프레임 정의](#3-프레임-정의)
4. [AGENTS.md에 프로젝트 연결 정보(adapter) 기록](#4-agentsmd에-프로젝트-연결-정보adapter-기록)
5. [다크모드 대비 노트](#5-다크모드-대비-노트)

---

## 0. 목업 반입(intake) — 무대 장치 제거

외부에서 만들어진 목업·프로토타입을 이식해 시작하는 경우에만 필요한 선행 단계.
백지에서 시작한다면 이 절은 건너뛰고 1로.

목업 생성 도구는 결과물을 화면 하나로 보여주는 게 아니라 **"보여주기 위한 무대 장치"**까지
함께 만들어낸다 — 기기 프레임, 가짜 상태바, 고정 크기 캔버스 같은 것들. 이걸 반입 시점에
걷어내지 않으면 이후 몇 주에 걸쳐 화면을 만질 때마다 하나씩 발견하며 뒤늦게 재작업하게 된다.
첫날 한 번에 걷어내는 편이 훨씬 싸다.

**이렇게 들어온 목업인지 확인하기**: 예를 들어 "모바일 앱 디자인" 같은 템플릿으로 뽑은 목업은
아래 무대 장치를 달고 온다. 마크업에 기기 프레임
래퍼, 상태바·다이나믹 아일랜드 마크업, 고정 px 캔버스 크기, 목업에 통째로 박힌 폰트·이미지가
보이면 이 절차부터 거친다.

**무대 장치 체크리스트**:

- **기기 프레임 래퍼 상자**: 뷰포트 안에 '폰'을 연출하는 다중 래퍼
  (`min-height: 100vh` → `relative` `100vh` → `overflow: hidden` …)를 화면 절대배치
  컨테이너 1겹으로 축소한다.
- **가짜 기기 크롬**: 상태바(시계·배터리)·다이나믹 아일랜드·홈 인디케이터 마크업은
  `display: none`이어도 삭제한다. 그 공간 예약값(상단 고정 px, 하단 고정 px)도 함께 삭제하고,
  실기기 안전영역은 `env(safe-area-inset-*)` 토큰으로 대체한다.
- **`display: none` 전수 수색**: 마크업은 죽었는데 예약 공간·상자만 남은 것들을 찾는다.
- **번들 자산**: 목업에 통째로 박힌 폰트(수 MB)는 CDN이 아니라 `next/font`(구글 폰트) 또는
  조각화 CSS(npm 폰트)로 옮긴다 ([font-loading.md](font-loading.md) §4). 이미지는 최적화된 경로로 옮긴다.
- **고정 무대 크기**(예: 430×884)를 반응형 계약으로 전환한다.
- **인라인 스타일의 혈통 인지**: 생성 목업은 반복 요소와 1회성 요소를 구분하지 않고 전부
  인라인으로 찍어낸다. "변장한 반복"(같은 버튼이 여러 화면에 복붙된 경우)이 많으므로,
  이후 2에서 부품 승격 감사를 전제로 진행한다.
- 목업 원본 파일은 정본 참조용으로 로컬에는 보관하되 레포 추적은 해제한다.

이 단계가 끝나면 1로 진행한다.

## 1. 토큰 3층 구축 — shadcn 위에

```
src/app/globals.css     ← 진입 CSS: import 줄만 (§1.3)
src/styles/
  1-foundation/         ← 원시 토큰: 색 램프(oklch), 타입 스케일 원본, 그리드, 그림자, 모션(길이·곡선) — :root에
  2-semantic.css        ← shadcn 이름 + .dark + 다리 블록(@theme inline). 값은 전부 1층 변수 참조
  3-components.css      ← 보조: 클래스로 못 푸는 전용 스타일, body 기본 스타일, 동작 줄이기 전역 규칙(§1.4)
src/components/ui/      ← 3층 몸통(범용): shadcn이 복사해 준 부품
src/components/         ← 3층 몸통(전용): 이 서비스만 쓰는 부품
```

### 1.1 순서

1. **`npx shadcn init`** — `components.json`·`lib/utils.ts`(`cn()`)·진입 CSS의 변수 블록이 생긴다.
   `components.json`의 CSS 경로(`tailwind.css` 칸)는 진입 CSS(`globals.css`)로 둔다. init이 진입 CSS에
   써 넣은 `:root`·`.dark`·`@theme inline` 블록은 2층 파일로 옮기고, 이후 부품을 받을 때 진입 CSS에
   덧붙는 변수(예: sidebar·chart 부품의 변수)도 2층으로 옮긴다 — 도입 때 실측으로 확정한다.
2. **1층 램프** — 채택한 디자인 시스템(또는 자체 브랜드)의 원시 값을 oklch로 채운다. `:root`에 둔다 —
   `@theme`에 두면 `bg-brand-600` 같은 램프 클래스가 생겨 2층을 건너뛰는 길이 열린다. 이 층은 read-only 취급 —
   이후 브랜드가 바뀌면 이 층을 통째로 교체한다.
   모션 원료도 이때 1층에 자리를 잡는다 (§1.4).
3. **2층을 shadcn 이름으로 다시 잇기** — init이 넣은 이름 세트(`--background`·`--card`·`--popover`·`--primary`·
   `--secondary`·`--muted`·`--accent`·`--destructive`·`--border`·`--input`·`--ring`·`--chart-*`·`--sidebar-*` …와
   각자의 `-foreground` 짝)를 지우지 말고 전부 1층 변수로 다시 잇는다(§1.2). 이름 세트를 shadcn이 정해 주니
   받은 부품이 그대로 돈다.
4. **진입 CSS의 import 순서를 고정한다** (§1.3).
5. **필요한 부품을 받는다** — `npx shadcn add <이름>`. 받은 부품은 2층 값만으로 브랜드 옷을 입는다 — 수정 0줄이
   정상이다. 파일을 고쳐야 하면 먼저 2층 값으로 풀 수 있는지 보고, 그래도 고쳤으면 adapter의 「고친 shadcn 부품
   목록」(§4)에 파일과 이유를 한 줄 적는다.

- **폰트 선정 + 로딩 방식 결정도 이 단계에서 함께** 한다. 색 팔레트만 정하고 폰트를 뒤로 미루면
  나중에 foundation을 다시 갈아엎게 된다 ([font-loading.md](font-loading.md)).

### 1.2 2층 파일의 모양

값은 자리표시자다. 1층 이름(`--gray-*`·`--brand-*`·`--b1-base` 등)은 1층이 정한다.

```css
/* src/styles/2-semantic.css — 의미 이름. 값은 전부 1층 변수만 가리킨다 */
:root {
  --background: var(--gray-0);
  --foreground: var(--gray-900);
  --primary: var(--brand-600);
  --primary-foreground: var(--gray-0);
  --muted-foreground: var(--gray-600);   /* 가장 옅은 글자 — 배경과 4.5:1 이상 */
  --destructive: var(--red-600);         /* 상태 의미 전용, 장식 금지 */
  --border: var(--gray-200);
  --radius: var(--radius-base);          /* 하나에서 sm~xl을 파생 */
}
.dark {                                  /* 다크 모드 교체점 — 전환 장치는 아직 두지 않는다 */
  --background: var(--gray-950);
  --foreground: var(--gray-50);
  --primary: var(--brand-400);
  --primary-foreground: var(--gray-950);
}
@theme inline {                          /* 다리 블록 — 여기 적은 이름만 클래스가 된다 */
  --color-*: initial;                    /* Tailwind 기본 팔레트를 끈다 — bg-blue-500 같은 클래스가 아예 안 생긴다 */
  --color-white: oklch(1 0 0);           /* shadcn 복사본의 text-white·bg-black/50이 안 깨지게 둘만 남긴다 */
  --color-black: oklch(0 0 0);
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);

  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-control: calc(var(--radius) - 2px);   /* 용도 이름 — rounded-control. 제품 코드는 이쪽을 먼저 */
  --radius-card: var(--radius);                  /* rounded-card */

  --font-sans: var(--font-base), var(--font-pretendard), "Apple SD Gothic Neo", sans-serif;
                                         /* 구글 폰트(next/font 변수)와 npm 폰트(패밀리 이름)를 여기서만 합친다 */

  --text-b1: var(--b1-base);             /* 우리 글 스케일 — text-b1. 제품 코드는 이 이름을 먼저 */
  --text-b1--line-height: var(--b1-line);
  --text-sm: var(--b2-base);             /* Tailwind 기본 이름을 우리 값으로 다시 정의 — 복사본의 text-sm이 우리 스케일을 쓴다 */
  --text-sm--line-height: var(--b2-line);
  --text-xs: var(--b2-base);             /* 복사본의 text-xs도 글자 바닥선(14px) 아래로 내려가지 않게 */
  --text-xs--line-height: var(--b2-line);
}
```

- **1층 램프는 `@theme`이 아니라 `:root`에 둔다.** 그래야 램프 이름 클래스가 아예 생기지 않는다.
- **다리 블록이 `inline`이어야 하는 이유**: `--font-base`는 `next/font`가 `<html>`에 붙이는 변수라 `:root`
  시점엔 없다. `inline`이면 클래스가 그 자리에서 값을 찾는다.
- **기본 팔레트를 끄는 줄(`--color-*: initial`)은 빼지 않는다.** 빠지면 `bg-blue-500` 같은 팔레트 클래스가
  다시 살아나 2층을 건너뛰는 길이 열린다. 5단계 관문 ①이 이 줄이 있는지 확인한다.
- **글 스케일은 우리 이름(`text-b1` 등)을 먼저 쓴다.** Tailwind 기본 이름(`text-sm`·`text-xs`)은 막지 않고
  우리 값으로 다시 정의해 둔다 — 막으면 shadcn 복사본의 `text-sm`이 사라져 부품이 깨진다. 복사본이 쓰는
  기본 이름이 더 있으면 같은 식으로 다시 정의한다.
- **둥글기는 용도 이름(`rounded-card`)을 먼저 쓴다.** 크기 이름(`rounded-md`)도 허용한다 — shadcn 복사본이
  쓰는 이름이다.

### 1.3 진입 CSS

진입 CSS(`globals.css`)는 import 줄만 둔다:

```css
@import "tailwindcss";
@import "tw-animate-css";                /* shadcn init이 넣는 줄 — 받은 그대로 둔다 */
@import "pretendard/dist/web/variable/pretendardvariable-dynamic-subset.css";
                                         /* npm 폰트를 쓸 때만 — 조각화 CSS (font-loading.md §4) */
@import "../styles/1-foundation/index.css";
@import "../styles/2-semantic.css";
@import "../styles/3-components.css";

@custom-variant dark (&:is(.dark *));    /* shadcn init이 넣는 줄 — import 줄 뒤에 둔다 */
```

- `body`의 `bg-background text-foreground` 같은 기본 스타일은 `3-components.css` 맨 위로 옮긴다.
- 로딩 순서 `tailwindcss` → 1 → 2 → 3은 바꾸지 않는다.

### 1.4 모션 토큰과 동작 줄이기 규칙

움직임 값도 색처럼 1층 원료 → 2층 이름으로 흐른다. 길이 세 단계(빠름·보통·느림)와 가속 곡선(easing) 두세 개면
충분하다. 값 몇 개만 바꾸면 앱 전체 움직임의 느낌이 같이 바뀌게 하려는 것이다. 이름은
[naming-taxonomy.md](naming-taxonomy.md) 유형표 motion 행을 따른다. 값은 자리표시자다 —
idea-to-mvp 5단계면 `mvp/design-brief.md` 「8. 모션·인터랙션 방향」의 분석 결과로 채운다.

```css
/* 1층 — src/styles/1-foundation/motion.css */
:root {
  --motion-fast: 120ms;
  --motion-base: 200ms;
  --motion-slow: 320ms;
  --curve-out: cubic-bezier(0.2, 0, 0, 1);            /* 끝에서 부드럽게 멈춤 */
  --curve-spring: cubic-bezier(0.34, 1.56, 0.64, 1);  /* 끝에서 살짝 튐 — 생동감이 필요할 때만 */
}

/* 2층 — src/styles/2-semantic.css */
:root {
  --duration-fast: var(--motion-fast);
  --duration-base: var(--motion-base);
  --duration-slow: var(--motion-slow);
}
@theme inline {
  --transition-duration-fast: var(--duration-fast);   /* → duration-fast */
  --transition-duration-base: var(--duration-base);   /* → duration-base */
  --transition-duration-slow: var(--duration-slow);   /* → duration-slow */
  --ease-standard: var(--curve-out);                  /* → ease-standard */
  --ease-emphasis: var(--curve-spring);               /* → ease-emphasis */
  --default-transition-duration: var(--duration-fast);         /* transition-colors 같은 클래스의 기본 길이 */
  --default-transition-timing-function: var(--ease-standard);  /* 기본 곡선 — 같은 블록의 2층 이름을 가리킨다 */
}

/* 전역 — src/styles/3-components.css 맨 위, body 기본 스타일 옆. 예외 없음 */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0s !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0s !important;
    scroll-behavior: auto !important;
  }
}
```

- **길이 클래스(`duration-fast` 등)는 다리 블록의 `--transition-duration-*` 이름으로 만든다.** Tailwind가 길이 클래스를
  찾는 이름 자리가 `--transition-duration-*`이라, `--duration-*`을 다리 블록에 그대로 올리면 클래스가 생기지 않는다.
  이렇게 만든 `duration-fast`는 Tailwind의 `duration-150`과 같은 모양(`--tw-duration` 변수 + `transition-duration`)으로
  나와서, CSS 전환과 tw-animate-css 등장 효과(`animate-in`이 `--tw-duration`을 읽는다) 둘 다에 길이가 먹는다.
  곡선은 다리 블록의 `--ease-*` 이름이 바로 클래스가 된다(1층 변수를 가리켜도 된다).
- **기본 길이·곡선(`--default-transition-*`)은 2층 이름을 가리킨다.** 같은 다리 블록 안 이름(`--ease-standard`)을
  가리켜도 `transition-colors` 같은 클래스가 그 값을 쓴다.
- 실측: Tailwind v4.3.3, 2026-10-06 (tw-animate-css 1.4.0과 함께 빌드해 결과 CSS로 확인).
- **동작 줄이기(prefers-reduced-motion)** — 운영체제 설정에서 움직임을 줄여 달라고 켜 둔 사람에게는 움직임을 끈다.
  화면마다 분기하지 않고 위 전역 규칙 한 번으로 처리한다. 값을 `0s`로 적는 건 5단계 관문 ①의 ms 하드코딩 검사에
  걸리지 않게 하려는 것이다. JS로 돌리는 움직임(예: `motion` 라이브러리)은 이 규칙이 못 끄니, 들였으면 그
  라이브러리의 전역 동작 줄이기 설정을 앱 맨 바깥에 한 번 건다.
- **3층·제품 코드에는 ms 값과 곡선을 적지 않는다** — `duration-300`·`duration-[250ms]`·`cubic-bezier(…)` 대신
  `duration-base`·`ease-standard`. Tailwind 기본 곡선 이름(`ease-out` 등)은 끄지 않지만 제품 코드에서 쓰지 않는다 —
  `ease-standard` 같은 우리 이름만. 5단계 관문 ① 11번 grep이 잡는다.

## 2. 컴포넌트 인벤토리(사전) 생성

프로젝트 문서(예: `docs/components.md`)에 새로 작성:
- 등록 단위는 **부품 파일**이다. 칸은 둘 — `components/ui/`(범용, shadcn에서 받은 것)와 `components/`(전용)
- §1.1에서 받은 범용 부품을 등록하고, 앞으로 받거나 만드는 부품은 그때마다 등록한다
- 형식·규칙은 [component-taxonomy.md](component-taxonomy.md) §6

## 3. 프레임 정의

frame-first로 셸·영역·크기 예산을 먼저 정하고, 예산은 layout/frame-budget 토큰으로 박는다.
웹·앱 통합 개발이면 canvas·gutter의 플랫폼별 차이까지 이때 결정한다
([layout-frames.md](layout-frames.md) §4).
화면 아래에 늘 보여야 하는 요소(주 동작 버튼 막대·탭바 등)의 자리도 이때 정한다 —
공통 셸은 하단 고정 요소가 아직 없어도 헤더/본문/하단 세 칸으로 시작한다
([layout-frames.md](layout-frames.md) §2.2).

## 4. AGENTS.md에 프로젝트 연결 정보(adapter) 기록

스킬은 범용, 프로젝트는 제각각 — 둘을 이어주는 **이 프로젝트만의 연결 정보**를 AGENTS.md에 기록한다:
- 진입 CSS와 세 층 파일 경로, import 순서
- `components.json` 위치와 경로 별칭(예: `@/components/ui`)
- 컴포넌트 인벤토리 위치 (두 칸 — `components/ui/`·`components/`)
- 프레임 인벤토리·화면 패턴 목록 위치
- **고친 shadcn 부품 목록** — 받은 뒤 직접 고친 `components/ui/` 파일과 고친 이유 한 줄씩. 부품을 다시 받을 때
  `--diff`로 비교하고 이 목록대로 다시 고친다(`--overwrite` 금지). 목록이 없으면 다시 받는 순간 우리 수정이
  조용히 사라진다
- 관문 ① 예외 줄 (5단계 감사 grep에 걸리지만 남길 값 — 예: `1px` 테두리)과 프로젝트 고유 함정 토큰
- 철칙 요약 (짧게 — 항상 컨텍스트에 있어야 하는 안전벨트)
- **적용 규칙 요약** — 부품 값을 고를 때 매번 필요한 규칙을 구조 규칙 옆에 몇 줄로 요약한다. 항목은 스킬이 정하고, 값은 프로젝트가 채운다: ① 글자 크기 바닥선과 예외 자리 ② 역할 한정 토큰 목록(어느 토큰이 어느 자리 전용인지). 왜 여기 두나 — 스킬 본문은 자동 주입이 아니라서, 지시서만 받는 서브 에이전트는 AGENTS.md에 없는 적용 규칙을 알 길이 없다. (실사고: 글자 크기 바닥 규칙이 스킬에만 있어 본문 한 줄이 캡션용 토큰으로 들어갔는데, 토큰을 썼다는 이유로 구조 검사는 통과했다.)

## 5. 다크모드 대비 노트

지금 다크모드를 만들지 않더라도, **2층의 `.dark` 블록이 교체점이 되도록** 설계해 둔다:
- 색은 반드시 semantic 이름 클래스를 거치게 (제품 코드에 램프 직접 참조 금지 — 철칙 1·2가 곧 다크모드 대비다)
- 색 배경 위 글자는 `-foreground` 짝으로 분리
- 이후 다크모드 = `.dark` 블록의 값을 다크용 램프 단계로 채우는 작업으로 끝난다. 전환 장치(예: `next-themes`)는
  다크모드를 실제로 만들 때 붙인다
