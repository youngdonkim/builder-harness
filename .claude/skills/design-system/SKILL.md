---
name: design-system
description: 3단 토큰 계층(foundation→semantic→component) + 조립 계층(frame·pattern) 디자인 시스템 방법론.
  화면·컴포넌트에 색/간격/글자/그림자를 적용할 때, CSS·토큰 파일을 만들거나 수정할 때,
  새 컴포넌트·화면을 만들 때, 새 프로젝트에 토큰 시스템을 도입할 때 사용.
---

# 디자인 시스템 — 계층 아키텍처

모든 시각 값은 CSS 변수(토큰)로만 흐른다. hex·px 하드코딩 금지.

**토큰 계층 (CSS 파일):**

1. **foundation** — 원료: 원시 팔레트 램프·타입 스케일·그리드. 교체 가능 (브랜드/DS 변경 = 이 층 교체)
2. **semantic** — 의미: 의도로 명명한 별칭 (primary, danger…). **화면·컴포넌트 코드가 참조하는 유일한 층**
3. **component** — 부품: 컴포넌트 클래스/TSX (버튼·필드·칩·시트)

**조립 계층 (방법론 — 파일 없음):**

4. **frame** — 뼈대: 셸 + 영역 + 크기 예산(size budget — 영역마다 미리 배정한 크기 한도). 셸 분류·파생 규칙은 [references/layout-frames.md](references/layout-frames.md) 
5. **pattern** — 검증된 조합: 프레임+컴포넌트를 화면 유형별로 묶은 템플릿 (한 프레임 위에 패턴 여러 개 가능)

**screen (실제 화면)** = 패턴 + 콘텐츠 — 패턴의 인스턴스

## 시작하기 전에 (필수)

프로젝트의 CLAUDE.md에서 **프로젝트 연결 정보(adapter)**를 확인한다:
층별 실제 파일 경로 · import 순서 · 프로젝트 고유 예외(함정 토큰 등) · 컴포넌트 인벤토리 위치.
없으면 [references/bootstrap-project.md](references/bootstrap-project.md)로 도입부터.

## 철칙

0. **컴포넌트-우선**: 커버하는 기존 컴포넌트/클래스가 있으면 반드시 그걸 쓴다. 새로 만드는 건 최후.
1. 제품 코드(화면·컴포넌트)는 **semantic 토큰만** 참조한다.
2. 원시 값(램프 변수·hex·px 매직넘버)은 **semantic 층 안에서만** 쓴다.
3. foundation은 **read-only** — 수정이 아니라 교체의 대상.
4. 층 로딩 순서는 **1→2→3 고정** (순서가 바뀌면 변수 참조가 깨진다).

## 결정 트리

**새 화면이 필요하다** (frame-first — 콘텐츠부터 쓰지 말 것)
1. 셸 선택: 프레임 인벤토리 검색 → 그대로 맞으면 재사용 · 뼈대(영역 구성·예산)는 같고
   표현만 다르면 `--modifier` 변형 셸 · 영역 구성부터 다르면 독립 셸 신설
   → [references/layout-frames.md](references/layout-frames.md) §2.1
   ⚠️ 여럿이 공유하는 셸의 기본 규칙 직접 수정 금지 — 사용처 전부가 같이 바뀐다
2. 기존 패턴에 맞나? 맞으면 패턴 재사용, 콘텐츠만 교체
3. 그다음에야 컴포넌트·토큰 선택으로 내려간다

**새 UI 요소가 필요하다** (component-first)
1. 컴포넌트 인벤토리 검색 — 동의어로도 (예: "모달?" → dialog 항목)
2. 있다 → 재사용. 살짝 다르면 `--modifier` 변형 추가 (신규 블록 금지)
3. 없다 → 역할 분류 + 범용/전용 판정 후 신규 생성 → [references/component-taxonomy.md](references/component-taxonomy.md)
4. 인벤토리에 등록

**값(색·간격·모서리…)이 필요하다** (semantic-first)
1. semantic에 의미가 맞는 토큰이 있나? → [references/naming-taxonomy.md](references/naming-taxonomy.md) 유형표로 탐색
2. 있다 → 쓴다
3. 없다 → semantic에 추가 → [references/add-a-token.md](references/add-a-token.md)
4. foundation에 원료 자체가 없다? → 그때만 foundation 확장 검토 (드묾, 신중히)

## 안티패턴

| ✗ 금지 | ✓ 대신 |
|---|---|
| hex/rgb 하드코딩 (`#fff`, `rgb(...)`) | semantic 토큰 (`var(--text-on-fill)`) |
| px 매직넘버 간격 | spacing 토큰 |
| px 매직넘버 글자크기 (3층에서 직접 지정) | `typography/component` 토큰 새로 만들기 (naming-taxonomy.md §2) |
| 색 있는 배경 위 글자색 하드코딩 | `on-` 토큰 (`--text-on-fill`) — 배경이 바뀌면 글자도 따라가야 함 |
| margin 주려고 wrapper div로 감싸기 | 컴포넌트 자체에 스타일 |
| 개념이 같은데 새 블록 생성 (예: dialog 있는데 `.popup` 신설) | 인벤토리 정본 재사용 + 변형 |
| 목록 항목마다 카드로 감싸기 / 카드 중첩 | 밀집 데이터는 행(row)으로 |
| 상태색(danger/success)을 장식용으로 사용 | 상태색은 의미 전달에만 |

## 동심원 radius 규칙

패딩 있는 컨테이너 안의 요소 모서리는 `max(0px, 바깥 radius − padding)`.
(카드 안 버튼이 어색하게 각져 보이는 문제 방지. 하드코딩으로 어긋나게 하지 말 것.)

## 상세 참조

- 토큰 명명 문법·유형표: [references/naming-taxonomy.md](references/naming-taxonomy.md)
- 컴포넌트 역할·티어·어휘 규칙: [references/component-taxonomy.md](references/component-taxonomy.md)
- 프레임·레이아웃 방법론: [references/layout-frames.md](references/layout-frames.md)
- 새 토큰 추가 절차: [references/add-a-token.md](references/add-a-token.md)
- 새 프로젝트 도입: [references/bootstrap-project.md](references/bootstrap-project.md)
