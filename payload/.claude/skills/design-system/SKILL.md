---
name: design-system
description: Tailwind + shadcn 위의 3단 토큰 계층(foundation→semantic→component) + 조립 계층(frame·pattern) 디자인 시스템 방법론.
  화면·컴포넌트에 색/간격/글자/그림자를 적용할 때, Tailwind 클래스를 고를 때, CSS·토큰 파일을 만들거나 수정할 때,
  shadcn 부품을 추가·수정할 때, 새 컴포넌트·화면을 만들 때, 새 프로젝트에 토큰 시스템을 도입할 때, 새 토큰을 추가할 때 사용.
---

# 디자인 시스템 — 계층 아키텍처

모든 시각 값은 CSS 변수(토큰)로만 흐른다. 스택은 Tailwind + shadcn 고정이라, 제품 코드는 토큰을 **클래스 이름으로 고른다** (`bg-primary`·`p-4`·`text-b1`). hex·px·대괄호 임의 값(`p-[13px]`) 금지.

**토큰 계층 (CSS 파일 — 진입 CSS가 `@import "tailwindcss"` 다음에 1→2→3 순서로 불러온다):**

1. **foundation** (`1-foundation/`) — 원료: 색 램프(oklch)·타입 스케일 원본·그리드. `@theme`이 아니라 `:root`에 둔다 — 그래야 램프 이름이 클래스(`bg-brand-600`)로 새지 않는다. 교체 가능 (브랜드/DS 변경 = 이 층 교체)
2. **semantic** (`2-semantic.css`) — 의미: shadcn 변수 이름(`--background`·`--primary`·`--primary-foreground`·`--radius` …)으로 1층을 다시 잇는다. 같은 파일에 `.dark` 블록과 다리 블록(`@theme inline` — 여기 적은 이름만 Tailwind 클래스가 된다)을 둔다. Tailwind 기본 팔레트는 여기서 끈다. **화면·컴포넌트 코드가 참조하는 유일한 층**
3. **component** — 부품: 몸통은 `components/ui/*.tsx`(shadcn 복사본, 범용)와 `components/*.tsx`(전용). `3-components.css`는 클래스로 못 푸는 전용 스타일만 담는 보조 파일

**조립 계층 (방법론 — 파일 없음):**

4. **frame** — 뼈대: 셸 + 영역 + 크기 예산(size budget). 셸 분류·파생 규칙은 [references/layout-frames.md](references/layout-frames.md) 
5. **pattern** — 검증된 조합: 프레임+컴포넌트를 화면 유형별로 묶은 템플릿 (한 프레임 위에 패턴 여러 개 가능)

**screen (실제 화면)** = 패턴 + 콘텐츠 — 패턴의 인스턴스

## 시작하기 전에 (필수)

**시작 전 브랜치 확인** — 파일을 바꾸기 전에 지금 어느 브랜치인지 먼저 본다.

```bash
git branch --show-current
```

**main이면 `/new-task`를 직접 호출해 작업 브랜치를 연 뒤 진행한다.** main에서 파일을 바꾸면 `auto-wip-commit` 훅이 안 돌아 자동 저장이 안 되고(되돌릴 지점이 안 남는다), 나중에 `no-main-push` 훅에 막혀 올리지도 못한다.

프로젝트의 AGENTS.md에서 **프로젝트 연결 정보(adapter)**를 확인한다 — 항목은 [references/bootstrap-project.md](references/bootstrap-project.md) §4가 정한 adapter 항목(적용 규칙 요약 포함).
없으면 [references/bootstrap-project.md](references/bootstrap-project.md)로 도입부터.

## 철칙

0. **컴포넌트-우선**: 커버하는 기존 컴포넌트/클래스가 있으면 반드시 그걸 쓴다. 새로 만드는 건 최후.
1. 제품 코드(화면·컴포넌트)의 색은 **semantic 이름 클래스만** 쓴다 (`bg-primary`·`text-muted-foreground`). 간격·둥글기·글자는 theme 스케일 클래스를 쓴다 (`p-4`·`rounded-card`·`text-b1`). 대괄호 임의 값(`p-[13px]`)과 괄호 변수(`bg-(--x)`)로 이 이름들을 건너뛰지 않는다.
2. 원시 값(램프 변수·oklch·hex·px 매직넘버)은 **1·2층 CSS 안에서만** 쓴다.
3. foundation은 **read-only** — 수정이 아니라 교체의 대상.
4. 진입 CSS의 로딩 순서는 **`tailwindcss` → 1 → 2 → 3 고정** (순서가 바뀌면 변수 참조가 깨진다).

## 결정 트리

**새 화면이 필요하다** (frame-first — 콘텐츠부터 쓰지 말 것)
1. 셸 선택: 프레임 인벤토리 검색 → 그대로 맞으면 재사용 · 뼈대(영역 구성·예산)는 같고
   표현만 다르면 셸 부품의 `variant` · 영역 구성부터 다르면 독립 셸 신설
   → [references/layout-frames.md](references/layout-frames.md) §2.1
   ⚠️ 여럿이 공유하는 셸의 기본 규칙 직접 수정 금지 — 사용처 전부가 같이 바뀐다
2. 기존 패턴에 맞나? 맞으면 패턴 재사용, 콘텐츠만 교체
3. 그다음에야 컴포넌트·토큰 선택으로 내려간다

**새 UI 요소가 필요하다** (component-first)
1. 컴포넌트 인벤토리 검색 — 동의어로도 (예: "모달?" → Dialog 항목)
2. 있다 → 재사용. 살짝 다르면 그 부품의 cva(class-variance-authority — 부품의 변형을 `variant`·`size` 같은 이름으로 묶는 작은 라이브러리)에 `variant`를 더한다 (새 부품 금지). 모양이 기본과 다를 때 고치는 차례는 [references/component-taxonomy.md](references/component-taxonomy.md) §4
3. 없다 → shadcn 부품 목록에서 찾아 `npx shadcn add <이름>`으로 받는다. 같은 파일이 이미 있으면 `--diff`로 먼저 비교하고, `--overwrite`는 쓰지 않는다
4. shadcn에도 없다 → 역할 분류 + 범용/전용 판정 후 `components/`에 전용 부품 신규 생성 → [references/component-taxonomy.md](references/component-taxonomy.md)
5. 인벤토리에 등록 — 적기 전에 한 줄 색인 형식([references/component-taxonomy.md](references/component-taxonomy.md) §6)인지 확인. 값·사용법·변경 이력은 인벤토리가 아니라 부품 파일 머리 주석·git log 몫이다

**값(색·간격·모서리…)이 필요하다** (semantic-first)
1. semantic에 의미가 맞는 토큰이 있나? → [references/naming-taxonomy.md](references/naming-taxonomy.md) 유형표로 탐색
2. 있다 → 쓴다
3. 없다 → semantic에 추가 → [references/naming-taxonomy.md](references/naming-taxonomy.md) §5
4. foundation에 원료 자체가 없다? → 그때만 foundation 확장 검토 (드묾, 신중히)

간격·둥글기·글자처럼 theme 스케일에 이미 있는 값은 그 클래스(`p-4`·`rounded-card`·`text-b1`)를 쓴다 — 새 토큰을 만들지 않는다.

## 안티패턴

| ✗ 금지 | ✓ 대신 |
|---|---|
| hex/rgb 하드코딩 (`bg-[#333]`, `style={{ color: "#fff" }}`) | semantic 이름 클래스 (`bg-primary`·`text-primary-foreground`) |
| px 매직넘버 간격 (`p-[13px]`) | theme 스케일 클래스 (`p-3`) |
| px 매직넘버 글자크기 (`text-[15px]`) | 글 스케일 클래스(`text-b1`), 안 맞으면 `typography/component` 토큰 새로 만들기 (naming-taxonomy.md §2) |
| Tailwind 팔레트 이름 (`bg-blue-500`) | semantic 이름 클래스 — 기본 팔레트는 2층에서 꺼 둔다 ([bootstrap-project.md](references/bootstrap-project.md) §1.2) |
| 괄호 변수로 이름 클래스 건너뛰기 (`bg-(--primary)`, `bg-[var(--x)]`) | 다리 블록에 이름을 올려 클래스로 (`bg-primary`) — naming-taxonomy.md §5.3 |
| 색 있는 배경 위 글자색 하드코딩 | `-foreground` 짝 (`bg-primary text-primary-foreground`) — 배경이 바뀌면 글자도 따라가야 함 |
| 화면에서 부품 겉모양을 `className`으로 덮어쓰기 (`<Button className="bg-… rounded-…">`) | 2층 값 → `variant` → 부품 파일 수정 차례로 ([component-taxonomy.md](references/component-taxonomy.md) §4). 화면이 부품에 주는 `className`은 배치(바깥 여백·폭·flex·grid)만 |
| margin 주려고 wrapper div로 감싸기 | 부품의 `className`에 배치 클래스(`mt-4`) |
| 개념이 같은데 새 부품 생성 (예: `Dialog` 있는데 `Popup` 신설) | 인벤토리 정본 재사용 + `variant` |
| 목록 항목마다 카드로 감싸기 / 카드 중첩 | 밀집 데이터는 행(row)으로 |
| 상태색(danger/success)을 장식용으로 사용 | 상태색은 의미 전달에만 |
| 글자 크기를 계속 줄여 위계 표현 (14px 밑으로) | 굵기(`font-medium` 등)+명도(`text-muted-foreground` 등) 위계로 표현, 가장 옅은 단계도 대비 4.5:1 유지 ([naming-taxonomy.md](references/naming-taxonomy.md)) |
| 통짜 폰트 파일 로딩 / CDN `<link>`로 웹폰트 불러오기 | 구글 폰트는 `next/font/google`, npm 폰트는 조각화 CSS `@import` ([references/font-loading.md](references/font-loading.md) §4) |
| 하단 상시 요소(버튼 막대·입력창·탭바)를 화면에 붙여 띄우고 본문 끝을 어림 여백으로 비우기 | 셸 설계 때 하단 칸을 정하고 거기 흐름대로 — 스크롤은 본문 칸만 ([references/layout-frames.md](references/layout-frames.md) §2.2) |
| 안내 문구(placeholder)를 라벨 대신 씀 | 이름을 따로 단다 — [common-patterns.md](references/common-patterns.md) §2 (WCAG 3.3.2) |
| 글 칸 글자가 16px 아래거나 `user-scalable=no`로 확대를 막음 | 16px 이상, 확대 허용 — 같은 문서 §2 (WCAG 1.4.4) |
| 엔터로 확정하는 칸에 한글 조합 가드가 없음 | 조합 중 엔터는 무시 — 같은 문서 §3 |
| 제목 칸에서 엔터를 누르면 글이 그대로 올라감 | 본문으로 넘기거나 막는다 — 같은 문서 §3 |
| 사용자가 쓴 글을 저장 형식으로 변환하고 미리보기로 메움 | 쓴 것이 그대로 올라가게 — 같은 문서 §6 |
| 댓글·채팅 입력을 한 줄 입력(`<input>`)으로 | 쓰는 만큼 늘어나는 글 칸 — 같은 문서 §5 |
| 홈 최상단을 추천 슬라이드·기획전 배너로 연다 | 검색·카테고리 같은 탐색 진입점을 먼저 — 같은 문서 §1 (관찰 37곳 중 0곳) |
| 게시판 커뮤니티 홈에 자동으로 도는 배너를 넣는다 | 커뮤니티엔 두지 않는다 — 같은 문서 §1 (관찰 18곳 중 0곳) |

## 동심원 radius 규칙

패딩 있는 컨테이너 안의 요소 모서리는 `max(0px, 바깥 radius − padding)`.
(카드 안 버튼이 어색하게 각져 보이는 문제 방지. 하드코딩으로 어긋나게 하지 말 것.)
shadcn이 `--radius` 하나에서 `calc(var(--radius) - 2px)`처럼 sm~xl을 파생하는 것도 같은 생각이다.

## 어느 문서를 언제 읽나

- **값(색·간격·모서리…) 이름을 정하거나 새 토큰을 추가할 때** — [naming-taxonomy.md](references/naming-taxonomy.md) (shadcn 이름 문법·유형표 + 새 토큰을 `:root`·`.dark`·`@theme inline`에 잇는 절차)
- **새 UI 컴포넌트를 받거나 만들거나 인벤토리에 등록할 때** — [component-taxonomy.md](references/component-taxonomy.md) (컴포넌트 역할·범용/전용·shadcn 이름 규칙·cva variant 작성·고치는 차례)
- **홈 첫 화면에 무엇을 먼저 둘지 정할 때** — [common-patterns.md](references/common-patterns.md) §1 (SaaS / 커머스 / 마켓플레이스·O2O / 커뮤니티·SNS 네 유형의 최상단 차례와 로그인 전후 갈래 · 관찰 37곳+51곳 · 관례는 기본값이고 사용자 결정이 우선, 다르게 정하면 이유와 함께 기록)
- **댓글창·게시글 에디터처럼 글을 써서 올리는 칸을 만들 때** — [common-patterns.md](references/common-patterns.md) §2~§7 (접근성 체크 목록 · 컴포저 · 에디터)
- **새 화면·레이아웃을 설계할 때** — [layout-frames.md](references/layout-frames.md) (frame-first 절차, 셸 분류, 컨테이너 정책)
- **폰트를 새로 넣거나 바꿀 때** — [font-loading.md](references/font-loading.md) (조각화·자체 호스팅 원리, Next.js 로딩 결정표 — 구글 폰트·npm 폰트 갈래, `--font-sans`에서 합치기, 빌드 검증 관문 3종)
- **새 프로젝트에 도입할 때** — [bootstrap-project.md](references/bootstrap-project.md)를 순서대로 따른다. 이 절차는 도중에 세 문서를 함께 읽는다: 토큰 3층 단계에서 font-loading.md(폰트 선정·로딩 방식을 같이 정한다 — 미루면 foundation을 다시 갈아엎는다), 인벤토리 생성에서 component-taxonomy.md §6(인벤토리 한 줄 형식), 프레임 정의에서 layout-frames.md §4(웹·앱 통합이면 canvas·gutter 플랫폼 차이)
