# 토큰 명명 문법과 유형표

semantic 층에 토큰을 추가할 때 따르는 규범. **기존 토큰의 이름·값은 바꾸지 않는다**(레거시 허용) —
이 문법은 **신규 추가분**에만 적용한다.

**이 문서의 용어** (토큰 계층):

| 용어 | 뜻 |
|---|---|
| foundation(1층) | 원시 재료 — 팔레트 램프·타입 스케일·그리드. 브랜드/DS 교체 시 통째로 갈아끼우는 층 |
| semantic(2층) | 의도로 명명한 별칭(primary·danger…). **화면·컴포넌트가 참조하는 유일한 층** |
| component(3층) | 실제 부품 — 컴포넌트 클래스/TSX |
| ramp(램프) | 한 색의 밝기 단계 세트 (예: `grey-50`~`grey-900`) — foundation의 원시 재료 |
| alias(별칭) | 원시 값을 의도 이름으로 다시 가리키는 것 — semantic 층이 하는 일 |
| on- 토큰 | 색 배경(fill) 위에 올라가는 글자·아이콘 색 (배경이 바뀌면 따라감, §4) |
| 유형·역할·변형·상태 | 토큰 이름의 문법 조각 — §1에서 정의 |

## 목차

1. [명명 문법 (grammar)](#1-명명-문법-grammar)
2. [유형표 — 새 토큰의 자리 찾기](#2-유형표--새-토큰의-자리-찾기)
3. [표면 위계 규범 (surface hierarchy)](#3-표면-위계-규범-surface-hierarchy)
4. [on- 패턴 규범](#4-on--패턴-규범)
5. [radius 위계 참고](#5-radius-위계-참고)

---

## 1. 명명 문법 (grammar)

```
--{유형}-{역할}[-{변형}][-{상태}]

유형(category) = 무엇의 값인가: color · radius · space · shadow · font/weight · ease/duration
역할(role)     = 어떤 의도인가: primary · text · surface · border · danger · success …
변형(variant)  = 강도/파생:    strong · weak · light · deep · secondary~quaternary · surface
상태(state)    = 상호작용:     pressed · disabled · hover
```

**대원칙 두 가지:**
- 이름은 *색이 아니라 의도*: `--color-info-text` ✓ / `--color-blue-text` ✗
- 크기는 *숫자가 아니라 용도*: `--radius-card` ✓ / `--radius-20`, `--radius-lg` ✗

## 2. 유형표 — 새 토큰의 자리 찾기

| 유형 | 하위 유형 | 예시 | 신규 추가 문법 |
|---|---|---|---|
| color/brand | 주색·파생·표면 | `--color-primary(-strong/-surface/-light/-deep)` | `--color-primary-{변형}` |
| color/text | 위계 | `--color-text(-secondary/-tertiary/-quaternary)` | 위계 4단 유지, 추가 금지 |
| color/semantic | 상태 의미 | `--color-danger` · `--color-success(-surface/-border)` | `--color-{의미}[-surface/-border/-text]` |
| color/surface·line | 면과 선 | `--color-surface(-sunken)` · `--color-border` | 표면 위계 규범(§3) 준수 |
| color/on- | 색 배경 위 | `--text-on-fill` | `--{text/icon}-on-{배경}` |
| color/control | 컨트롤 전용 | `--color-neutral-surface(-pressed)` | `--color-{역할}-{부위}[-{상태}]` |
| color/domain | 기능 전용 팔레트 | `--color-bar-*`(계산기) | `--color-{도메인}-{역할}` — 2개 이상 화면에서 쓸 때만 |
| radius | 용도별 | `--radius-input/control/card/sheet/pill/badge` | `--radius-{용도}` |
| space | 콘텐츠 간격·여백 | 4px 그리드 스칼라 (요소 간 gap, 카드 패딩) | `--space-{위치/용도}` |
| layout/frame-budget | 프레임 계약 값 | 영역 치수: `--app-max-width` · `--nav-height` / 거터·안전영역: `--space-screen-x` · `--space-bottom-safe` | `--{영역}-{치수}` — 거터·안전영역은 레거시로 `--space-` 접두 유지 |
| shadow | 용도별 | `--shadow-fab/cta/sheet/card` | `--shadow-{용도}` |
| motion | 이징·시간 | `--ease-standard` · `--duration-fast/base/slow` | `--ease-{느낌}` / `--duration-{속도}` |
| typography/scale | 글(prose) 전용 — 제목·본문·캡션 | `t1~t4`(제목) `h1~h2` `b1~b2` `c1~c2`·`label` | 스케일 이름은 시스템 규약으로 고정, 크기 값만 프로젝트별 교체. 11단계에 안 맞는 크기는 typography/component으로 |
| typography/component | UI 부품 전용 — 칩·뱃지·필드라벨·헬퍼텍스트 등 prose 스케일에 안 맞는 크기 | `--font-size-chip` · `--font-size-field-label` | `--font-size-{부품/역할}` — [add-a-token.md](add-a-token.md) 절차로 신규 추가 |

**typography가 두 갈래인 이유:** `t1~label` 11단계는 **글(prose) 역할** 전용이다 — 제목·본문·캡션처럼
문서 구조를 나타내는 텍스트에만 쓴다. 칩·뱃지·필드 라벨·헬퍼텍스트 같은 **UI 부품 텍스트**는 이 11단계에
억지로 맞추지 않는다 — 실무에서 제일 흔한 이탈 지점이 바로 여기서, 안 맞는 크기를 욱여넣거나 그냥
magic-number px로 새 버린다. 부품 텍스트는 `typography/component` 유형으로 별도 토큰을 만든다
(철칙 #2는 그대로 지키되, 스케일 이름만 부품 전용으로 분리하는 것).

**기존 코드의 하드코딩 px 이관은 점진적으로.** 이미 px가 많은 코드베이스를 한 번에 토큰화하려 들지
말 것 — 과설계 위험이 크고, 각 부품이 어느 역할 토큰에 맞는지 판정하는 데만도 큰 작업이 된다.
대신 그 클래스를 **다른 이유로 손댈 때마다** 그 김에 `typography/component` 토큰으로 옮긴다.
새로 만드는 부품 텍스트만 처음부터 토큰으로 — 그러면 시간이 지나며 자연스럽게 정리된다.

**화면/섹션 단위로 토큰을 비례 조정할 때:** `:root`를 덮어쓰지 말고 그 스코프의 클래스 안에서
**자기참조 calc()**로 상속값을 변형한다 (타입스케일뿐 아니라 spacing·radius 등 다른 유형에도 적용 가능):
```css
.screen--dense {
  --b1-size: calc(var(--b1-size) - 1px);
}
```
`var(--b1-size)`는 CSS 상속 규칙상 이 규칙이 적용되기 **직전의 값**(즉 상위 스코프의 값)을 가리키므로
순환 참조가 아니다. 목표값을 직접 하드코딩(`--b1-size: 14px`)하는 대신 이렇게 증감폭만 적으면,
원본 값이 나중에 바뀌어도 배율이 자동으로 따라가 사람이 다시 계산할 필요가 없다.

판정 기준 — space vs layout: **프레임 계약에 속하는 값이면 layout, 콘텐츠 사이 간격이면 space.**

## 3. 표면 위계 규범 (surface hierarchy)

배경/표면 토큰은 **시각 깊이의 위계**로 명명한다:

```
canvas(뷰포트의 배경색 — 웹에선 body background. 프레임이 덮은 곳은 가려짐)
  → body/sunken(프레임 안 기본 바닥) → surface(콘텐츠 면) → elevated(카드·시트·팝오버)
```

새 표면 토큰이 필요하면 이 위계에서 자리를 정한 뒤 이름 붙인다.
(예: 모달 위 팝오버가 생기면 `--color-surface-overlay` 같은 상위 깊이로.)

canvas ≠ gutter: canvas는 뷰포트 배경**색(면)**, gutter는 프레임 안 좌우 **여백(간격)** —
gutter는 layout/frame-budget 유형이다. 플랫폼별 차이는 [layout-frames.md](layout-frames.md) §4 참조.

## 4. on- 패턴 규범

색이 있는 배경(fill) 위에 올라가는 글자·아이콘 색은 반드시 `on-` 토큰으로 분리한다.
배경 토큰이 바뀌면(테마 교체·다크모드) 글자색이 자동으로 따라가야 하기 때문.

```
✗ background: var(--color-primary); color: #fff;
✓ background: var(--color-primary); color: var(--text-on-fill);
```

## 5. radius 위계 참고

용도 이름은 자유지만, 개념적으로는 안쪽→바깥쪽 위계를 따른다:

```
tight(장식) < badge(작은 태그) < input/control(컨트롤) < card(컨테이너) < sheet(패널) < pill/full(완전 원형)
```

동심원 규칙(SKILL.md 참조): 컨테이너 안 요소는 `max(0px, 바깥 radius − padding)`.
