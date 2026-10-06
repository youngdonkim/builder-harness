# 토큰 명명 문법과 유형표

semantic 층에 토큰을 추가할 때 따르는 규범. **기존 토큰의 이름·값은 바꾸지 않는다**(레거시 허용) —
이 문법은 **신규 추가분**에만 적용한다.

**이 문서의 용어** (토큰 계층):

| 용어 | 뜻 |
|---|---|
| foundation(1층) | 원시 재료 — 팔레트 램프·타입 스케일·그리드. 브랜드/DS 교체 시 통째로 갈아끼우는 층 |
| semantic(2층) | 의도로 명명한 별칭(primary·destructive…). **화면·컴포넌트가 참조하는 유일한 층** |
| component(3층) | 실제 부품 — `components/ui/*.tsx`(shadcn 복사본)·`components/*.tsx`(전용). `3-components.css`는 보조 |
| ramp(램프) | 한 색의 밝기 단계 세트 (예: `grey-50`~`grey-900`) — foundation의 원시 재료 |
| alias(별칭) | 원시 값을 의도 이름으로 다시 가리키는 것 — semantic 층이 하는 일 |
| `-foreground` 짝 | 색 배경 위에 올라가는 글자·아이콘 색. 배경 이름 뒤에 `-foreground`를 붙인 짝 (`--primary` ↔ `--primary-foreground`). 배경이 바뀌면 따라감 (§1) |
| 유형·역할·변형·상태 | 토큰 이름의 문법 조각 — §1에서 정의 |

## 목차

1. [명명 문법 (grammar)](#1-명명-문법-grammar)
2. [유형표 — 새 토큰의 자리 찾기](#2-유형표--새-토큰의-자리-찾기)
3. [표면 위계 규범 (surface hierarchy)](#3-표면-위계-규범-surface-hierarchy)
4. [radius 위계 참고](#4-radius-위계-참고)
5. [새 토큰 추가 절차](#5-새-토큰-추가-절차)
   - [5.1 자리 찾기](#51-자리-찾기)
   - [5.2 이름 짓기](#52-이름-짓기)
   - [5.3 값 배선](#53-값-배선)
   - [5.4 주석](#54-주석)
   - [5.5 검증](#55-검증)

---

## 1. 명명 문법 (grammar)

**색 — shadcn 문법을 따른다.** 2층 색 이름은 shadcn이 정한 세트(`--background`·`--primary`·`--muted` …)를 쓰고,
프로젝트가 더하는 색도 같은 문법으로 짓는다. 이름 세트를 shadcn에 맞춰야 받은 부품이 그대로 돈다.

```
--{역할}                배경·면·선으로 쓰는 색      예: --primary · --success · --sidebar
--{역할}-foreground     그 위에 올라가는 글자·아이콘  예: --primary-foreground · --success-foreground
```

- **색 배경 위 글자는 반드시 `-foreground` 짝으로 분리한다.** 배경이 바뀌면(테마 교체·다크모드) 글자색이
  자동으로 따라가야 하기 때문이다. 배경 색을 새로 더하면 짝도 같이 더한다.

  ```
  ✗ className="bg-primary text-white"
  ✓ className="bg-primary text-primary-foreground"
  ```

**색 밖의 값 — 유형·역할·변형·상태 문법.**

```
--{유형}-{역할}[-{변형}][-{상태}]

유형(category) = 무엇의 값인가: radius · space · shadow · font/weight · ease/duration
역할(role)     = 어떤 의도인가: card · control · sheet · screen …
변형(variant)  = 강도/파생:    strong · weak · light · deep
상태(state)    = 상호작용:     pressed · disabled · hover
```

Tailwind는 이름 묶음(namespace)마다 클래스를 만든다 — `--radius-card`를 다리 블록에 두면 `rounded-card`,
`--text-b1`이면 `text-b1`이 생긴다. 그래서 이름이 곧 제품 코드가 쓰는 클래스 이름이다.

**대원칙 두 가지:**
- 이름은 *색이 아니라 의도*: `--info-foreground` ✓ / `--blue-text` ✗
- 크기는 *숫자보다 용도*: 제품 코드는 용도 이름(`rounded-card`)을 먼저 쓴다. shadcn 복사본이 쓰는 크기 이름
  (`rounded-md`·`text-sm`)도 허용하되, 그 값은 우리 스케일로 다시 정의해 둔다 ([bootstrap-project.md](bootstrap-project.md) §1.2)

## 2. 유형표 — 새 토큰의 자리 찾기

새 토큰 하나는 2층 파일의 세 블록에 걸친다 — 값은 `:root`(다크 값은 `.dark`), 클래스로 꺼내 쓰려면
다리 블록(`@theme inline`)에 이름을 올린다. 「둘 자리」 칸이 그 배치다.

| 유형 | 하위 유형 | 예시 | 둘 자리 → 생기는 클래스 | 신규 추가 문법 |
|---|---|---|---|---|
| color/brand | 주색·보조 | `--primary` · `--secondary` · `--accent` | `:root`·`.dark` + `--color-primary` → `bg-primary`·`text-primary` | shadcn 세트에 있으면 그 이름, 없으면 `--{역할}` + `-foreground` 짝 |
| color/text | 위계 | `--foreground` · `--muted-foreground` | 같음 → `text-foreground`·`text-muted-foreground` | shadcn 2단(기본·`muted`)에 필요하면 희미 1단(`--subtle-foreground`)을 더한다. 그 이상 늘리지 않는다 |
| color/semantic | 상태 의미 | `--destructive` · `--success` · `--success-foreground` | 같음 → `bg-destructive`·`text-success` | `--{의미}` + `--{의미}-foreground` |
| color/surface·line | 면과 선 | `--background` · `--card` · `--popover` · `--border` · `--input` · `--ring` | 같음 → `bg-card`·`border-border` | 표면 위계 규범(§3) 준수 |
| color/control | 컨트롤 전용 | `--neutral-pressed` | 같음 | `--{역할}-{부위}[-{상태}]` |
| color/domain | 기능 전용 팔레트 | `--chart-1`~`--chart-5`(shadcn) · `--bar-*`(계산기) | 같음 → `fill-chart-1` | `--{도메인}-{역할}` — 2개 이상 화면에서 쓸 때만 |
| radius | 용도별 | `--radius`(기준) · `--radius-control` · `--radius-card` · `--radius-sheet` · `--radius-pill` | `--radius`는 `:root`, 나머지는 다리 블록에 — 대개 `calc(var(--radius) ± Npx)`로 파생 → `rounded-card` | `--radius-{용도}` |
| space | 콘텐츠 간격·여백 | 4px 그리드 스칼라 (요소 간 gap, 카드 패딩) | Tailwind 간격 스케일 그대로 → `p-4`·`gap-2` | 스케일 밖 간격이 정말 필요할 때만 `--spacing-{용도}` |
| layout/frame-budget | 프레임 계약 값 | 영역 치수: `--app-max-width` · `--nav-height` / 거터·안전영역: `--space-screen-x` · `--space-bottom-safe` | `:root`. 클래스가 필요하면 다리 블록에 (`--spacing-screen-x: var(--space-screen-x)` → `px-screen-x`) | `--{영역}-{치수}` — 거터·안전영역은 레거시로 `--space-` 접두 유지 |
| shadow | 용도별 | `--shadow-fab/cta/sheet/card` | 다리 블록 → `shadow-card` | `--shadow-{용도}` |
| motion | 이징·시간 | `--ease-standard` · `--duration-fast/base/slow` | 다리 블록 → `ease-standard` | `--ease-{느낌}` / `--duration-{속도}` |
| typography/family | 글꼴 자체 | `--font-sans`(본문 기본) · 필요시 `--font-brand`·`--font-mono` | 다리 블록 → `font-sans` | `--font-{역할}` — 값은 1층 폰트 변수를 합친 것 ([font-loading.md](font-loading.md) §3) |
| typography/weight | 글자 굵기 | 400 · 500 · 700 | Tailwind 기본 → `font-normal`·`font-medium`·`font-bold` | 역할 이름이 필요하면 `--font-weight-{역할}` → `font-{역할}` |
| typography/scale | 글(prose) 전용 — 제목·본문·캡션 | `t1~t4`(제목) `h1~h2` `b1~b2` `c1~c2`·`label` | 다리 블록 `--text-b1` + `--text-b1--line-height` → `text-b1` | 스케일 이름은 시스템 규약으로 고정, 크기 값만 프로젝트별 교체. 11단계에 안 맞는 크기는 typography/component으로 |
| typography/component | UI 부품 전용 — 칩·뱃지·필드라벨·헬퍼텍스트 등 prose 스케일에 안 맞는 크기 | `--text-chip` · `--text-field-label` | 다리 블록 → `text-chip` | `--text-{부품/역할}` — §5 절차로 신규 추가 |

**typography가 두 갈래인 이유:** `t1~label` 11단계는 **글(prose) 역할** 전용이다 — 제목·본문·캡션처럼
문서 구조를 나타내는 텍스트에만 쓴다. 칩·뱃지·필드 라벨·헬퍼텍스트 같은 **UI 부품 텍스트**는 이 11단계에
억지로 맞추지 않는다 — 실무에서 제일 흔한 이탈 지점이 바로 여기서, 안 맞는 크기를 욱여넣거나 그냥
magic-number px로 새 버린다. 부품 텍스트는 `typography/component` 유형으로 별도 토큰을 만든다
(철칙 #2는 그대로 지키되, 스케일 이름만 부품 전용으로 분리하는 것).
Tailwind 기본 글자 이름(`text-sm`·`text-xs` 등)은 shadcn 복사본이 쓰는 이름이라 막지 않고 우리 값으로 다시
정의해 둔다 — 제품 코드는 우리 스케일 이름을 먼저 쓴다.

**글자 크기로 위계를 만들려고 계속 줄이지 않는다.** 사진·이미지 위 캡션을 제외한 모든 텍스트는
14px 아래로 내려가지 않는다(가독성 바닥). 크기 단계가 좁아져 위계가 안 설 때는 크기를 더 쪼개는
대신 `typography/weight`(400/500/700)와 `color/text` 위계(§2 — `text-foreground`·`text-muted-foreground`처럼
기본/보조/희미 3단 정도면 대부분 충분하다)를 함께 써서 위계를 표현한다. 단 가장 옅은 단계도 배경과의 명도 대비는 4.5:1
이상을 지킨다 — 위계를 만들려다 안 보이는 글자를 만들면 본말전도다.

**기존 코드의 하드코딩 px 이관은 점진적으로.** 이미 px가 많은 코드베이스를 한 번에 토큰화하려 들지
말 것 — 과설계 위험이 크고, 각 부품이 어느 역할 토큰에 맞는지 판정하는 데만도 큰 작업이 된다.
대신 그 부품을 **다른 이유로 손댈 때마다** 그 김에 `typography/component` 토큰으로 옮긴다.
새로 만드는 부품 텍스트만 처음부터 토큰으로 — 그러면 시간이 지나며 자연스럽게 정리된다.

**화면/섹션 단위로 토큰을 비례 조정할 때:** `:root`를 덮어쓰지 말고 그 스코프의 클래스 안에서
**1층 원본 변수 기준 calc()**로 증감폭만 적는다 (타입스케일뿐 아니라 spacing·radius 등 다른 유형에도
적용 가능). 1층 변수와 px 증감을 쓰는 자리라 이 스코프 클래스도 `2-semantic.css`에 둔다 — 3층에 두면 5단계
관문 ①의 하드코딩·램프 직접 참조 검사에 걸린다:
```css
/* 2-semantic.css — 조정할 스케일만 중간 변수를 두고, 스코프 클래스에서 1층 원본 기준으로 증감 */
:root         { --b1-size: var(--b1-base); }
@theme inline { --text-b1: var(--b1-size); }
.screen--dense {
  --b1-size: calc(var(--b1-base) - 1px);
}
```
자기 자신을 가리키는 식(`--b1-size: calc(var(--b1-size) - 1px)`)은 쓰지 않는다 — CSS 명세상 한 요소 안에서
변수가 자기 자신을 참조하면 순환으로 보고 값을 무효로 만든다(상위 스코프 값을 가져오지 않는다). 그래서 증감은
1층 원본 변수(`--b1-base`) 기준으로 적는다. 다리 블록이 `inline`이라 `text-b1` 클래스가 그 자리의 `--b1-size`를
읽으니, 스코프 안에서만 값이 바뀐다. 목표값을 직접 하드코딩(`--b1-size: 14px`)하는 대신 이렇게 증감폭만 적으면,
원본 값이 나중에 바뀌어도 자동으로 따라가 사람이 다시 계산할 필요가 없다.

판정 기준 — space vs layout: **프레임 계약에 속하는 값이면 layout, 콘텐츠 사이 간격이면 space.**

## 3. 표면 위계 규범 (surface hierarchy)

배경/표면 토큰은 **시각 깊이의 위계**로 명명한다. 면 이름 대부분은 shadcn이 주고, 모자라는 canvas·sunken만
프로젝트가 더한다:

```
canvas(뷰포트의 배경색 — 웹에선 body background. 프레임이 덮은 곳은 가려짐)   ← 추가 토큰 --canvas
  → sunken(프레임 안 기본 바닥)                                               ← 추가 토큰 --sunken
  → background(콘텐츠 면)                                                     ← shadcn --background
  → card · popover(카드·시트·팝오버)                                          ← shadcn --card · --popover
```

새 표면 토큰이 필요하면 이 위계에서 자리를 정한 뒤 이름 붙인다
(예: 모달 위 팝오버가 생기면 `--overlay` 같은 상위 깊이로, `-foreground` 짝과 함께).

canvas ≠ gutter: canvas는 뷰포트 배경**색(면)**, gutter는 프레임 안 좌우 **여백(간격)** —
gutter는 layout/frame-budget 유형이다.

## 4. radius 위계 참고

값은 shadcn 방식대로 `--radius` 하나에서 파생한다(§2 유형표). 용도 이름은 자유지만, 개념적으로는
안쪽→바깥쪽 위계를 따른다:

```
tight(장식) < badge(작은 태그) < input/control(컨트롤) < card(컨테이너) < sheet(패널) < pill/full(완전 원형)
```

동심원 규칙은 SKILL.md 참조.

## 5. 새 토큰 추가 절차

semantic 층에 토큰을 추가할 때. (foundation 확장은 원료 자체가 없을 때만 — 드묾, 신중히.)

### 5.1 자리 찾기

§2 유형표에서 어느 유형·하위 유형인지 정한다.
기존 토큰으로 커버되면 추가하지 않는다 (중복 별칭 금지).

### 5.2 이름 짓기

색은 `--{역할}` + `--{역할}-foreground`, 그 밖은 `--{유형}-{역할}[-{변형}][-{상태}]` (§1).
의도로 명명: `--info-foreground` ✓ / `--blue-text` ✗
역할이 한정된 토큰(특정 자리 전용)은 이름에 그 자리를 넣는다 — 예: 캡션 전용 크기면 이름에 caption.
이름이 역할을 말해야, 고치는 파일만 읽는 에이전트가 토큰 선택만으로 규칙을 지킨다.

### 5.3 값 배선

`2-semantic.css`의 세 곳에 한 줄씩 넣는다 — **값은 반드시 foundation 변수 참조**:

```css
:root         { --success: var(--green-600); --success-foreground: var(--gray-0); }
.dark         { --success: var(--green-400); --success-foreground: var(--gray-950); }
@theme inline { --color-success: var(--success); --color-success-foreground: var(--success-foreground); }
```

`var(--green-600)` ✓ / `#64A8FF`·`oklch(…)` ✗ — 원시 값을 직접 쓰면 foundation 교체 시 안 따라간다.
다리 블록에 올리지 않은 이름은 클래스가 안 생긴다 — 그 빈자리를 `bg-(--success)` 같은 괄호 변수로 메우지 말고
다리 블록에 올린다.

### 5.4 주석

용처 한 줄 기록 (기존 파일의 주석 스타일 유지).
역할 한정 토큰은 **어디 전용인지, 다른 자리에 쓰면 왜 안 되는지**까지 적는다 — 예: `/* 이미지 위 캡션 전용 — 본문 바닥선 아래 값 */`.
토큰을 썼다는 이유만으로 규칙을 지킨 것처럼 보이는 걸 막는 장치다 — 에이전트가 반드시 읽는 파일은 고치는 파일뿐이라, 토큰 자신이 역할을 말해야 한다.

### 5.5 검증

빌드가 통과하는지 확인 (프로젝트의 빌드 명령은 AGENTS.md 참조).
