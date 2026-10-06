# 하네스 설계 노트

하네스 규칙의 설계 경위 모음 — 규칙 본문은 각 스킬에 있고, 여기는 "왜 그렇게 정했나"만 쌓는다.

이 파일은 `payload/` 밖이라 프로젝트로 복사되지 않는다. 하네스를 고치는 사람만 읽는 자리다.

---

## idea-to-mvp — 구 통과 기준③ ProtoRetro 폐지

출처: `payload/.claude/skills/idea-to-mvp/SKILL.md` §1.1 (스킬 범위)

> (구 통과 기준③ ProtoRetro는 폐지했다 — AI 빌더 시대엔 실물 첫 노출이 이미 4단계(DemoValidation)로 당겨져 여기서 다시 검증하면 중복이고, MvpBuild(6단계)가 이미 도는 프로토타입 코드에 백엔드를 얹는 얇은 작업이라 그 앞에 무거운 게이트를 둘 명분도 사라졌다. "기준은 다음 단계가 비쌀 때만 둔다"는 원칙에 따라 역할을 나눠 이관했다: 치명 결함 거르기는 6단계(MvpBuild) 안 **백엔드·DB·로그인 연동 뒤 베타 공유** 스텝(실데이터가 붙은 배포 링크를 4단계 인터뷰이에게 보내 실사용 반응 확인 — 판정 아닌 확인, `references/6-mvp-build.md` §2.3)으로, 빌드 범위는 `mvp-build.md`로, 런치 기준 후보는 7단계 launch-plan 작성 시 `demo-validation.md`의 Pull 데이터에서 도출하는 걸로. 베타 공유를 백엔드 연동 *뒤*에 두는 이유는, 4단계 데모에서 이미 프런트엔드는 실컷 봤으니 여기서 새로 확인할 값어치가 있는 건 "진짜 데이터가 붙어도 멀쩡히 도는가"뿐이기 때문이다.)

지금 규칙은 §2.1 단계 릴레이 표의 6단계 행에 베타 공유가 들어가 있는 것으로 대신한다.

---

## idea-to-mvp — 왜 마이그레이션 직후에 코드로 승격하나

출처: `payload/.claude/skills/idea-to-mvp/SKILL.md` §2.2 (화면 SoT의 진화)

> **왜 마이그레이션 직후에 코드로 승격하나**: 코드가 화면에 대해 아는 전부를 담게 된 뒤에도 목업 HTML을 나란히 유지하면 (1) 둘이 어긋날 때마다 어느 쪽이 진실인지 판단하는 세금이 생기고 (2) 실제로 아무도 다시 안 읽는 파일을 계속 고치는 의례가 된다. 승격 시점을 3단계 안으로 당긴 이유도 같다 — 3↔4 순환의 수정이 이미 코드에 들어가는데 SoT만 목업에 남겨두면, 첫 순환부터 두 개가 어긋난다.

규칙 본문은 SKILL.md §2.2의 "화면 SoT의 진화" 3번 항목(마이그레이션이 끝나는 순간 앱 코드로 승격)에 남아 있다. 규칙을 지키게 만드는 못인 "예외 없는 규칙이 AI 실행자에게 더 잘 지켜진다"는 문장도 SKILL.md에 그대로 남겼다.

---

## idea-to-mvp — 상태 변형 점검을 절차로 이관한 경위

출처: `payload/.claude/skills/idea-to-mvp/SKILL.md` §2.2 (화면 SoT의 진화)

> **상태 변형 점검은 절차로 이관** — 순환·피봇에서 화면을 추가·수정할 땐 빈 상태·오류·로딩 같은 상태 변형을 같이 만들었는지 코드에서 확인한다. 예전엔 2단계 인벤토리의 상태 매트릭스가 하던 점검을, 문서 갱신이 아니라 코드 수정 절차의 체크 항목으로 옮긴 것이다.

SKILL.md에는 규칙 문장(코드에서 상태 변형을 확인한다)만 남겼다.

---

## done-task — squash·합치기 근거는 git-workflow.md에 있다

출처: `payload/.claude/skills/done-task/SKILL.md` §머리말·§1.6

두 근거는 원문이 이미 `payload/docs/git-workflow.md`에 있어서 이 파일로 옮기지 않았다. 스킬 쪽은 규칙 문장 + 포인터로 줄였다.

- **왜 GitHub squash인가 (local squash 아님)** → `payload/docs/git-workflow.md` §2 "왜 뭉쳐서 합치기(squash merge)인가"
- **왜 리베이스가 아니라 합치기인가 (근거 1·2·3 + 옛 규칙 변천사)** → `payload/docs/git-workflow.md` §8.3 "다른 사람 PR이 먼저 들어갔을 때 — 조건부 합치기(merge)"

---

## done-task를 「판단(메인)」과 「ship(fork)」으로 분리 (2026-09-11)

`done-task`는 원래 본문 전체가 `context: fork`(git-flow 서브에이전트)에서 돌았다. 두 문제가 있었다.

1. fork 안에는 Skill 도구가 없어 `/simplify`를 못 돌린다 — `src/`를 고친 브랜치는 simplify 게이트에서 [결정 필요]로 멈추고, 메인이 `/simplify`를 돌린 뒤 다시 불러야 해서 매번 두 번 왕복이었다.
2. "보내줘를 들으면 ship 전에 simplify 판단부터"가 스킬 본문의 "권장 순서"로만 있어, 하네스를 받은 다른 프로젝트에서 같은 동작이 보장되지 않았다.

그래서 둘로 나눴다 — 사용자·클로드가 부르는 이름은 `done-task` 그대로 두고(메인 세션에서 도는 얇은 스킬: simplify 판단 → 필요 시 실행·표식 커밋 → 위임), git 절차는 `ship-task`(기존 본문, fork 유지)로 옮겼다. **fork를 걷어내지 않은 이유**: 본문이 2만 토큰이 넘어 메인에서 돌리면 ship 한 번에 3만 토큰가량이 메인 컨텍스트에 쌓이고, CI 대기까지 메인이 떠안는다. ship-task의 simplify 게이트(§1.5)는 지우지 않고 done-task가 판단을 빠뜨렸을 때의 안전망으로 남겼다.

---

## 하네스 다이어트(2026-09-28)에서 옮겨 온 경위 넷

`docs/harness-diet-review.md` 7회차 결정 3에 따라 지시 문서에서 떼어 낸 설계 이력이다. 규칙 문장은 원래 자리에 그대로 있고, 여기 있는 건 「왜 그렇게 정했나」만이다.

### design-system — 14px 바닥선 규칙이 naming-taxonomy에 있는 이유

출처: `payload/.claude/skills/design-system/references/naming-taxonomy.md` §2 「글자 크기로 위계를 만들려고 계속 줄이지 않는다」 문단 끝

> (근거: idea-to-mvp `2-mockup.md` — 목업 단계 실사용 검증에서 나온 요건이지만, 크기·굵기·대비는 특정 단계가 아니라 서비스 전체에 적용되는 타이포 규칙이라 여기 옮겨 적는다.)

### idea-to-mvp — 2단계가 「목업」, 5단계가 「프로토타입」인 이유

출처: `payload/.claude/skills/idea-to-mvp/references/2-mockup.md` 도입부(목차 앞), `5-frontend-build.md` §1 용어 목록 아래. 같은 설명이 두 문서에 있어 둘 다 옮겼다.

> **이 단계 이름이 목업(Mockup)인 이유** — 업계에서 목업(mockup)은 겉모습만 완성된 정지 그림, 프로토타입(prototype)은 동작으로 이어지는 견본을 뜻한다. 여기 캔버스는 기능 목록을 다듬으려고 보는 정지 그림이라 목업이고, 코드로 곧장 옮겨지는 5단계 캔버스가 프로토타입 캔버스다 (`5-frontend-build.md` 첫머리).

> **2단계 캔버스가 목업, 이 단계 캔버스가 프로토타입인 이유** — 업계에서 목업(mockup)은 겉모습만 완성된 정지 그림, 프로토타입(prototype)은 동작으로 이어지는 견본을 뜻한다. 2단계 캔버스는 기능 목록을 다듬으려고 보는 정지 그림이라 목업이고, 이 단계 캔버스는 곧장 워킹 프로토타입으로 옮겨지는 직전 원본이라 프로토타입이다.

### idea-to-mvp — 2단계 시각 다듬기를 막았다가 푼 경위

출처: `payload/.claude/skills/idea-to-mvp/references/2-mockup.md` 도입부 「보여주는 상대가 단계마다 올라간다」 문단. 결정 문장(사용자 확정 2026-08-29, 시각 왕복 허용, 브리프를 스펙으로 입힘, 「피드백 오염은 기획자 본인이 감수하는 리스크」)은 원래 자리에 남아 있다.

> 옛날엔 다듬을수록 피드백이 겉모습(색·간격)으로 쏠리는 것(피드백 오염)과 버리기 아까워져 구조가 실코드에 눌어붙는 것(눌어붙음)을 걱정해 다듬기를 막았는데, **눌어붙음은 이제 성립하지 않는다** — 캔버스는 그림이라 코드로 옮길 물건이 형식부터 아니고, 이후 단계는 캔버스가 아니라 문서(스토리·기능 목록·브리프·IA)를 입력으로 쓴다 (§4.2).

### idea-to-mvp — 「최종 아이디어·비목표·검증 가설·북극성」의 옛 이름

출처: `payload/.claude/skills/idea-to-mvp/references/3-market-research.md` §2.7 「여기서 하지 않는 것」

이 넷의 옛 이름은 「빌더 가드레일」이었다. 본문의 「(구 "빌더 가드레일")」 괄호는 지웠고, 그 이름을 쓰는 문서는 이제 없다.

---

## shadcn을 고정 스택에 넣고 design-system 스킬을 그 위에 다시 쓰기 — 설계 대응표 (2026-10-06)

「검토」 단계 산출물이다. 스킬·템플릿은 아직 한 글자도 안 바꿨다. 이 대응표를 메인과 사용자가 확정한 뒤 따로 구현한다.

**이미 정한 것 (전제)**

- 5단계 고정 스택 표에 「스타일링·부품: Tailwind + shadcn」 행을 넣는다. 옛 구조(CSS 3층)로 이미 지은 프로젝트는 그대로 두고, 새 프로젝트부터 적용한다.
- 세 층 폴더(`src/styles/1-foundation/`·`2-semantic.css`·`3-components.css`)는 그대로 둔다. 바뀌는 건 내용이다.
  - 1층: 색 램프 그대로.
  - 2층: shadcn 변수 이름(`--background`·`--primary`·`--primary-foreground`·`--radius` …)으로 다시 잇는다. `.dark` 블록과 다리 블록(`@theme inline { --color-primary: var(--primary); … }`)을 같은 파일에 둔다.
  - 3층: 몸통은 `components/ui/*.tsx`(shadcn 복사본)다. `3-components.css`는 프로젝트 전용 클래스만 담는 보조 파일이다.
  - 로딩 순서는 진입 CSS에서 `@import "tailwindcss"` → 1 → 2 → 3.
- 어댑터 내용은 따로 문서를 두지 않고 각 문서에 녹인다. 스택이 고정이라 「shadcn이 아닌 경우」가 없다.
- 글 스케일 이름(`t1~t4`·`h1~h2`·`b1~b2`·`c1~c2`·`label`)은 `@theme`에 정의해 Tailwind 클래스(`text-b1` 등)로 쓴다.
- 유틸리티 클래스(utility class — `p-4`·`bg-primary`처럼 스타일 하나를 이름 하나로 거는 클래스)의 허용 범위:
  - 색은 semantic 이름 클래스(`bg-primary`·`text-muted-foreground`)만 쓴다.
  - 간격·둥글기는 theme 스케일 클래스(`p-4`·`rounded-md`)를 써도 된다.
  - 대괄호 임의 값(arbitrary value — `p-[13px]`·`bg-[#333]`)과 Tailwind 팔레트 이름 직접 사용(`bg-blue-500`)은 금지다.
  - 5단계 관문 ①에 이 셋을 잡는 grep을 더한다.
- 부품의 변형은 `--modifier` 클래스 대신 cva(class-variance-authority — 부품의 변형을 `variant`·`size` 같은 이름으로 묶는 작은 라이브러리)의 variant로 만든다.
- 컴포넌트 인벤토리는 `components/ui/`(범용)와 `components/`(전용) 두 칸이다.
- 폰트는 `next/font`로 불러온다.
- 범위 밖: 마이크로 인터랙션·모션 다듬기. 프로토타입 캔버스 뒤에 따로 다룬다.

**근거 (2026-10-06 공식 문서 확인)**

- Tailwind 공식 문서 「Theme variables」는 `@theme` 블록을 별도 CSS 파일에 두고 `@import`로 가져오는 패턴을 적어 두었다(「Sharing across projects」 예시: `@import "tailwindcss";` 다음 줄에 `@import "../brand/theme.css";`). 그래서 세 층 파일을 따로 두는 구조가 Tailwind와 부딪치지 않는다.
- shadcn 공식 「Tailwind v4」 문서는 `:root`·`.dark`에 변수를 두고, `@theme inline`으로 `--color-background: var(--background)`처럼 다리를 놓는다. 색 형식은 oklch(색을 밝기·채도·색상각으로 적는 CSS 색 형식)로 바뀌었다.
- 같은 날 추가로 확인한 것:
  - Tailwind 「Theme variables」 — 이름 묶음(namespace)마다 클래스가 생긴다(`--text-*` → `text-*`, `--radius-*` → `rounded-*`, `--color-*` → `bg-*` 등). `--color-*: initial`처럼 쓰면 기본값 묶음을 통째로 끈다. 줄 높이는 `--text-{이름}--line-height`로 함께 준다. `@theme inline`은 클래스가 변수 이름 대신 변수의 *값*을 쓰게 해서, 변수가 정의되지 않은 자리에서 엉뚱한 값으로 떨어지는 일을 막는다.
  - shadcn 「CLI」 — `add`는 같은 파일이 있으면 덮을지 묻는다. `--overwrite`를 주면 묻지 않고 덮는다. `--diff`·`--dry-run`으로 받기 전에 차이를 볼 수 있다.
  - shadcn 레지스트리 new-york-v4 `button` — 기본 복사본에 이미 `text-sm`·`text-xs`·`focus-visible:ring-[3px]`·`text-white`가 들어 있다. 아래 §3·§6이 이 사실에 기대고 있다.

### 1. 파일·절 단위 대응표

뜻: **유지** = 그대로 둔다 / **축소** = 일부를 지우거나 줄인다 / **다시 씀** = 같은 자리에 새 내용으로 쓴다 / **삭제** = 절을 없앤다.

**design-system `SKILL.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 1 | 머리 설명(description) | 3단 토큰 + 조립 계층, 언제 쓰나 | 다시 씀 — 「Tailwind + shadcn 위의 세 층」, 발동 조건에 「shadcn 부품 추가·수정」「Tailwind 클래스 고를 때」를 더한다 | 실제 작업에서 쓰는 말과 발동 문구가 맞아야 스킬이 불린다 |
| 2 | 토큰 계층 설명(1~3층) | 3층 = 컴포넌트 클래스/TSX | 다시 씀 — 2층 = shadcn 변수 이름 + `.dark` + 다리 블록, 3층 몸통 = `components/ui/*.tsx`, `3-components.css`는 보조 | 층의 내용물이 바뀌었다 |
| 3 | 조립 계층(frame·pattern·screen) | 뼈대·검증된 조합 | 유지 | 스타일 도구와 상관없는 방법론이다 |
| 4 | 시작하기 전에 | 브랜치 확인, adapter 확인 | 유지 | — |
| 5 | 철칙 0~4 | 컴포넌트 우선 / semantic만 / 원시 값은 2층 안 / 1층 읽기 전용 / 1→2→3 | 0·3 유지. 1 다시 씀(색은 semantic 이름 클래스만, 간격·둥글기는 theme 스케일 클래스). 2 축소(원시 값은 1·2층 CSS 안에서만 — oklch 포함). 4 다시 씀(`tailwindcss` → 1 → 2 → 3) | 「CSS 변수 참조」가 「클래스 이름 고르기」로 바뀌었다 |
| 6 | 결정 트리 「새 화면」 | 변형 셸 = `--modifier` | 축소 — 「셸 부품의 `variant`」로 바꾼다 | 변형은 cva로 만든다 |
| 7 | 결정 트리 「새 UI 요소」 | 인벤토리 → `--modifier` 변형 → 신규 | 다시 씀 — ① 인벤토리 검색 ② 없으면 shadcn 목록에서 찾아 `npx shadcn add` ③ 살짝 다르면 cva variant 추가 ④ 그래도 없으면 전용 부품 | 범용 부품을 직접 짓던 단계를 shadcn이 맡는다 |
| 8 | 결정 트리 「값」 | semantic → 없으면 추가 → 1층 확장 | 유지 + 한 줄: theme 스케일에 있는 간격·둥글기는 그 클래스를 쓴다 | — |
| 9 | 안티패턴 표 | hex·px·폰트·하단 막대·글 쓰는 칸·홈 등 | 축소 + 추가 — hex·px 행의 예를 `bg-[#333]`·`p-[13px]`로 바꾸고, 행 셋을 더한다(팔레트 이름, 괄호 변수 `bg-(--x)`, 화면에서 부품 겉모양을 `className`으로 덮어쓰기). 폰트 행은 `next/font`를 가리킨다. 글 쓰는 칸·홈 행은 유지 | 새 스택에서 생기는 실수 자리가 다르다 |
| 10 | 동심원 radius | `max(0px, 바깥 − padding)` | 유지 + 한 줄: shadcn의 `calc(var(--radius) - Npx)` 파생도 같은 생각 | — |
| 11 | 어느 문서를 언제 읽나 | 문서별 안내 | 축소 — 각 줄의 설명만 새 내용에 맞춘다 | 문서 이름은 그대로다 |

**`references/bootstrap-project.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 12 | §0 목업 반입 | 무대 장치 걷어내기 | 유지 — 번들 폰트 줄만 `next/font`를 가리킨다 | — |
| 13 | §1 토큰 3층 구축 | 폴더 그림, 이전 프로젝트 골격을 복사해 배선만 수정 | 다시 씀 — 순서: `npx shadcn init` → 1층 램프(oklch) → 2층을 shadcn 이름으로 다시 잇기(§2 예시) → 진입 CSS import 순서. 「이전 프로젝트 골격 복사」는 shadcn 변수 이름 세트가 대체한다 | 2층 이름 세트를 shadcn이 정해 준다 |
| 14 | §2 범용 컴포넌트 이사 | 이전 프로젝트에서 코드째 복사, 수정 0줄이 정상 | **삭제** — `npx shadcn add`가 대체한다. 남길 생각 한 줄은 §13으로: 「받은 부품은 2층 값만으로 브랜드 옷을 입는다. 파일을 고쳐야 하면 adapter에 적는다」 | 범용 부품의 출처가 이전 프로젝트에서 shadcn으로 바뀌었다 |
| 15 | §3 인벤토리 생성 | 이사 온 부품 등록 | 축소 — 등록 단위가 「부품 파일」이 된다(`components/ui/`·`components/` 두 칸) | — |
| 16 | §4 프레임 정의 | 셸·영역·예산, 하단 세 칸 | 유지 | 방법론이다 |
| 17 | §5 adapter 기록 | 층 경로·인벤토리·프레임·함정·철칙 요약·적용 규칙 요약 | 다시 씀 — 항목은 #54와 같다 | 기록할 것이 바뀌었다 |
| 18 | §6 다크모드 대비 | semantic이 교체점, `light-dark()` 또는 다크용 램프 | 축소 — 「`.dark` 블록이 교체점」 한 갈래만 남긴다. `light-dark()` 갈래는 지운다 | shadcn이 `.dark` 클래스 방식으로 정해 두었다 |

**`references/naming-taxonomy.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 19 | 머리 용어 표 | foundation·semantic·component·ramp·alias·on- 토큰 | 축소 — on- 토큰 줄을 「`-foreground` 짝」으로, 3층 정의를 `components/ui/`로 | — |
| 20 | §1 명명 문법 | `--{유형}-{역할}[-{변형}][-{상태}]`, 크기는 용도 이름 | 다시 씀 — 2층 색 이름은 shadcn 문법(`--{역할}` + `--{역할}-foreground`). 프로젝트가 더하는 색도 같은 문법(`--success`·`--success-foreground`). 「크기는 용도 이름」 대원칙은 판단 6에 따라 고친다 | 이름 세트를 shadcn에 맞춰야 받은 부품이 그대로 돈다 |
| 21 | §2 유형표 | 유형별 예시·신규 문법, 14px 바닥선, 점진 이관, 자기참조 calc | 다시 씀 — 표에 「어느 블록(`:root`·`.dark`·`@theme inline`)에 무슨 이름으로 두고 어떤 클래스가 생기나」 칸을 더한다. 14px 바닥선·점진 이관 문단은 유지. **자기참조 calc 문단은 고친다** — `--b1-size: calc(var(--b1-size) - 1px)`는 CSS 명세상 자기 자신을 가리키는 순환이라 값이 무효가 된다. 「증감은 1층 원본 변수 기준으로 적는다」(`--b1-size: calc(var(--b1-base) - 1px)`)로 바꾼다 | 클래스로 노출하는 자리가 생겼다. calc 문단은 지금도 틀린 설명이다 |
| 22 | §3 표면 위계 | canvas → sunken → surface → elevated | 축소 — shadcn의 `background`·`card`·`popover`에 대응시키고, 모자라는 canvas·sunken만 추가 토큰으로 둔다 | shadcn이 면 이름 대부분을 준다 |
| 23 | §4 on- 패턴 | 색 배경 위 글자는 `on-` 토큰 | **삭제** — shadcn의 `-foreground` 짝 규칙이 대체한다(§20에 한 줄로 흡수) | 같은 생각을 shadcn이 이름으로 이미 강제한다 |
| 24 | §5 radius 위계 | tight < badge < control < card < sheet < pill | 축소 — `--radius` 하나에서 sm~xl을 파생하는 shadcn 방식이 대체. 위계 그림만 남긴다 | — |
| 25 | §6 새 토큰 추가 절차 | 자리 찾기·이름·값 배선·주석·검증 | 다시 씀 — §6.3 값 배선만 「`:root`·`.dark`·`@theme inline` 세 곳에 한 줄씩」으로. §6.1·§6.2·§6.4·§6.5 유지(역할 한정 토큰 작명·주석 지침 포함) | 새 토큰 하나가 세 블록에 걸친다 |

**`references/component-taxonomy.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 26 | §1 역할 6가지 | action·input·container… | 유지 | — |
| 27 | §2 범용 vs 전용 | 범용은 업계 표준 영어명 강제 | 축소 — 「범용 이름은 shadcn 이름을 따른다」 한 줄로 | shadcn 이름이 곧 업계 표준명이다 |
| 28 | §3 동의어 규칙 | 정본: dialog·sheet·chip·field | 다시 씀 — 정본을 shadcn 이름으로(Dialog·Sheet·Input …). chip은 판단 7 | — |
| 29 | §4 작성 규약(BEM) | `.블록__요소--변형`, 값은 semantic | 다시 씀 — 변형은 cva `variant`·`size`, 클래스 합치기는 `cn()`, 화면은 배치 클래스만. BEM은 `3-components.css` 전용 클래스에만 남긴다 | 부품 모양을 클래스 이름이 아니라 variant가 고른다 |
| 30 | §5 결정 트리 | SKILL.md를 따른다 | 유지 | — |
| 31 | §6 인벤토리 형식 | `이름 \| 범용/전용 \| 한 줄 \| 파일 · 클래스` | 축소 — 마지막 칸을 「파일 경로」로. variant 목록은 적지 않는다(cva 정의가 정본) | 「코드가 진실, 사전은 색인」 원칙 그대로 |
| 32 | §7 이식성 | 범용은 코드째 복사 | 다시 씀 — 범용은 `npx shadcn add`로 다시 받고, adapter의 「고친 부품 목록」대로 다시 고친다 | 판단 1에 묶인다 |

**`references/layout-frames.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 33 | §1 용어 | frame·region·content… | 유지 | — |
| 34 | §2 절차·§2.2 하단 고정 | frame-first, 하단 세 칸 | 유지 | — |
| 35 | §2.1 셸 선택 | 변형 셸 = `--modifier` | 축소 — 변형 셸 = 셸 부품의 `variant`. 자기참조 calc 안내는 #21의 고친 문단을 가리킨다 | — |
| 36 | §3 컨테이너 정책 | 카드 vs 행, 여백 한 겹 | 유지 — shadcn `Card`도 위젯에만 쓴다 | — |
| 37 | §4 플랫폼·안전 영역 | canvas·gutter·`--space-bottom-safe` | 유지 — §4.3 예시의 `calc(기본 + 안전 영역)` 덧셈만 「`3-components.css`의 셸 클래스로」라고 적는다(임의 값 금지라 `pb-[calc(…)]`를 못 쓴다) | 3층 보조 파일이 맡을 대표 예다 |
| 38 | §5 반응형 계약 | 기본은 컨테이너 쿼리, 뷰포트는 화면 전환만 | 축소 — 표기만 바꾼다: 컨테이너 쿼리 = `@container` + `@md:` 접두어, 뷰포트 접두어 `md:`는 화면 전환 전용 | 원칙은 같고 쓰는 문법이 Tailwind다 |
| 39 | §6 프로젝트별 기록 | 프로젝트 문서에 | 유지 | — |

**`references/font-loading.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 40 | §1 원리·§2 깜빡임 | 조각화, FOUT vs CLS | 유지 | — |
| 41 | §3 토큰 계층에서의 자리 | 패밀리는 1층, 제품 코드는 `--font-family-base` | 다시 씀 — `next/font`의 `variable`(예: `--font-base`)이 1층 원료, 2층 다리 블록의 `--font-sans`가 그걸 가리킨다. 제품 코드는 `font-sans` 클래스만 | Tailwind가 폰트를 클래스로 노출한다 |
| 42 | §4 로딩 결정표 | 구글 폰트 = `next/font/google`, npm 패키지 = `@import`(`next/font/local` 금지), CDN 금지 | 축소 — 구글 폰트 행·CDN 행 유지. npm 패키지 행은 판단 5 결과에 따른다 | 「폰트는 `next/font`」 결정과 이 행의 실사고가 부딪친다 |
| 43 | §5 마무리·§6 산출물 관문 | 폰트 스택 정리, 빌드 산출물 3검사 | 유지 | — |

**`references/common-patterns.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 44 | §1~§7 전부 | 홈 첫 화면, 글 쓰는 칸 접근성·컴포저·에디터 | 유지 — `:focus-within` 같은 표현은 Tailwind 접두어로 같은 말이다 | 구조·동작·접근성 규칙이라 스타일 도구와 상관없다 |

**idea-to-mvp 5단계 `references/5-frontend-build.md`**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 45 | §2.4.1 고정 core 표·조사 절차 | 프레임워크·언어·UI·DB·호스팅·lint·npm | 행 추가 「스타일링·부품 \| Tailwind + shadcn」. 조사 목록에 Tailwind 버전을 더한다. shadcn은 패키지가 아니라 CLI가 파일을 복사하는 방식이라 버전 핀 대상이 아니다 — 고른 style과 `components.json`을 ADR에 적는다. 「옛 구조 프로젝트는 그대로」 한 줄 | 결정 반영 |
| 46 | §2.2.3 `/design` 호출 지시 | 입력 세 개의 역할, 바닥선, 일관성 | 유지 — 판단 9가 정해지면 한 줄 더할 수 있다 | — |
| 47 | §2.5.3 디자인 시스템 baseline | 스킬 호출, bootstrap 절차, 안티패턴이면 스킬 쪽으로 고쳐 이식 | 다시 씀 — 순서(shadcn init → 1층 → 2층 → 필요한 부품 add → 화면 이식)와 이 문서 §4 이식 규칙의 요지를 넣는다 | 「고쳐 이식」이 shadcn에서 뜻하는 바를 적어야 한다 |
| 48 | §2.5.8 관문 ① 1·2번 | 하드코딩 0건, 램프 직접 참조 0건 | 축소 수정 — 경로 갱신, 색 함수에 `oklch(` 추가, 2번은 괄호 표기까지 잡게(§3) | — |
| 49 | 관문 ① 3번 | `@media` grep | 축소 수정 — Tailwind 뷰포트 접두어(`md:` 등) grep을 더한다 | 미디어 쿼리가 CSS가 아니라 클래스에 숨는다 |
| 50 | 관문 ① 4번 | 3층 CSS 클래스 ↔ 인벤토리 색인 대조 | 다시 씀 — 대조 대상을 「부품 파일 목록」(+ `3-components.css` 클래스)으로. 자동 생성 색인과 대조하는 원칙은 유지 | 변형이 클래스가 아니라 prop이라 오탐 원인이 사라진다 |
| 51 | 관문 ① 5·6번 | 한글 조합 가드, 안전 영역 | 유지 | — |
| 52 | 관문 ① 새 검사 | — | 추가 — 7 임의 값, 8 팔레트 이름, 9 괄호 변수(§3) | 결정 반영 |

**그 밖**

| # | 자리 | 지금 내용 | 도입 후 | 바뀌는 이유 |
|---|---|---|---|---|
| 53 | `2-mockup.md` §2.4 목업 캔버스 위임 | `/design`에 목업 지시, 홈 유형 제약은 메인이 넣음 | 유지 | 목업 캔버스는 그림이고 뒤 단계 입력이 아니다(§4.2). 스택과 닿는 데가 없다 |
| 54 | `AGENTS.md.template` 디자인 시스템 연결 정보(adapter) | 토큰 3층 경로·인벤토리·함정·적용 규칙 요약 | 다시 씀 — 항목: ① 진입 CSS와 세 층 경로 ② `components.json` 위치와 경로 별칭 ③ 인벤토리 위치(두 칸) ④ 프레임·패턴 위치 ⑤ **고친 shadcn 부품 목록**(파일·고친 이유 한 줄) ⑥ 관문 ① 예외 줄 ⑦ 적용 규칙 요약(글자 바닥선·역할 한정 토큰 — 유지) | ⑤가 판단 1의 안전장치다 |
| 55 | `6-2-backend-auth.md` 113줄 | 「semantic 토큰만, hex·px 하드코딩 금지」 | 축소 수정 — 「semantic 이름 클래스만, 임의 값·팔레트 금지」 | 문구가 옛 구조 기준이다 |

**삭제되는 절**: bootstrap-project §2, naming-taxonomy §4.
**축소되는 절**: SKILL.md 철칙 2·결정 트리 「새 화면」·안티패턴 표·문서 안내 / bootstrap §0·§3·§6 / naming 용어 표·§3·§5 / component-taxonomy §2·§6 / layout-frames §2.1·§5 / font-loading §4 / 5단계 관문 ① 1·2·3번 / 6-2 한 줄.

### 2. 2층 파일의 모양 예시

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
.dark {
  --background: var(--gray-950);
  --foreground: var(--gray-50);
  --primary: var(--brand-400);
  --primary-foreground: var(--gray-950);
}
@theme inline {                          /* 다리 블록 — 여기 적은 이름만 클래스가 된다 */
  --color-background: var(--background);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --radius-md: calc(var(--radius) - 2px);
  --font-sans: var(--font-base), "Apple SD Gothic Neo", sans-serif;
  --text-b1: var(--b1-base);             /* text-b1 */
  --text-b1--line-height: var(--b1-line);
}
```

- 1층 램프는 `@theme`이 아니라 `:root`에 둔다. 그래야 `bg-brand-600` 같은 클래스가 아예 생기지 않는다.
- 다리 블록이 `inline`이어야 하는 이유: `--font-base`는 `next/font`가 `<html>`에 붙이는 변수라 `:root` 시점엔 없다. `inline`이면 클래스가 그 자리에서 값을 찾는다.
- 진입 CSS(`globals.css`)는 import 줄만 둔다: `@import "tailwindcss";` → shadcn init이 넣는 줄(예: 애니메이션 패키지, `@custom-variant dark …`) → 1층 → 2층 → 3층. `body`의 `bg-background text-foreground` 같은 기본 스타일은 `3-components.css` 맨 위로 옮긴다.

### 3. 관문 ① grep 초안

자리: `5-frontend-build.md` §2.5.8 관문 ①. 경로는 기본형(`src/app`·`src/components`·`src/styles/…`)으로 적었다. 실제 문서에는 지금처럼 자리표시자로 둔다.

**1번 (경로 갱신) — 색·크기 하드코딩 0건**

```bash
grep -rnE '#([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})|rgba?\(|hsla?\(|oklch\(|oklab\(' \
  src/styles/3-components.css src/app src/components
grep -rnE '[0-9]+px' src/styles/3-components.css src/app src/components
```

- 잡는 예: `bg-[#333]`, `style={{ color: "#fff" }}`, `p-[13px]`, 3층 CSS의 `oklch(0.6 0.2 250)`.
- 못 잡는 예: 단위 없는 숫자(`style={{ padding: 13 }}`), `rem` 매직넘버(`p-[0.8rem]` — 7번이 잡는다).

**2번 (경로 갱신) — 1층 램프를 2층을 건너뛰고 직접 참조 0건**

```bash
grep -rhoE '^[[:space:]]*--[A-Za-z0-9-]+' src/styles/1-foundation/ \
  | sed -E 's/^[[:space:]]*//' | sort -u > /tmp/foundation-vars.txt
grep -rnwFf /tmp/foundation-vars.txt src/styles/3-components.css src/app src/components
```

- 바뀐 점: 이름을 `var(…)`로 감싸지 않고 이름 그대로 단어 단위(`-w`)로 찾는다. 그래야 Tailwind 괄호 표기까지 잡힌다.
- 잡는 예: `var(--brand-600)`, `bg-(--brand-600)`, `bg-[var(--brand-600)]`.
- 못 잡는 예: 이름을 문자열로 조립한 경우(`` `--brand-${n}` ``).

**3번 (보강) — 뷰포트 분기는 화면 전환용만**

```bash
grep -rn '@media' src/styles/3-components.css src/app src/components
grep -rnoE '(^|[^a-z0-9@-])(max-)?(sm|md|lg|xl|2xl):' src/app src/components
```

- 잡는 예: `md:flex`, `max-md:hidden`. 컨테이너 쿼리 접두어 `@md:`는 앞이 `@`라 안 잡힌다(의도대로).
- 못 잡는 예: 사용자 정의 브레이크포인트 이름(`tablet:`) — 프로젝트가 만들면 정규식에 더한다.
- 주의: shadcn `input` 기본 복사본에 `md:text-sm`이 있다(판단 4).

**4번 (다시 씀) — 부품 파일이 인벤토리 색인에 전부 있나**

```bash
find src/components -name '*.tsx' | xargs -n1 basename | sed 's/\.tsx$//' | sort -u > /tmp/parts.txt
while read -r p; do grep -q -- "$p" <인벤토리 문서의 전체 부품 색인 구간> || echo "미등록: $p"; done < /tmp/parts.txt
```

`3-components.css`의 클래스 대조는 지금 명령을 그대로 남긴다. variant는 prop이라 「`button--l`이 미등록」 같은 오탐(실측 93건 사례)이 생길 자리가 없다.

**7번 (신규) — 대괄호 임의 값 0건**

```bash
grep -rnoE '[a-z0-9]-\[[^]" ]+\]:?' src/app src/components | grep -vE '\]:$'
```

- 원리: 값 자리 대괄호(`p-[13px]`)만 잡고, 조건 자리 대괄호(`data-[state=open]:`·`has-[>svg]:`)는 뒤에 `:`가 붙어서 빼낸다.
- 잡는 예: `p-[13px]`, `bg-[#333]`, `text-[15px]`, `w-[calc(100%-2rem)]`, `bg-[var(--x)]`. shadcn 기본 복사본의 `ring-[3px]`도 잡힌다(판단 4).
- 못 잡는 예: 대괄호로 시작하는 임의 속성(`[mask-type:alpha]`), 문자열을 쪼개 이어 붙인 클래스(`"p-" + "[13px]"`), `style` 속성.

**8번 (신규) — Tailwind 팔레트 이름 0건**

```bash
P='slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose'
grep -rnE "(^|[^a-z0-9-])(bg|text|border|ring|outline|fill|stroke|divide|placeholder|caret|accent|decoration|shadow|from|via|to)-((${P})-[0-9]{2,3}|black|white)" \
  src/app src/components
```

- 잡는 예: `bg-blue-500`, `hover:text-gray-700`, `bg-black/50`·`text-white`(shadcn `dialog`·`button` 기본 복사본에 있다 — 판단 3·4).
- 못 잡는 예: 방향 붙은 테두리(`border-t-red-500`), 버전이 올라 새로 생긴 팔레트 이름 — 구현 때 Tailwind 색 문서의 목록으로 `P`를 맞춘다. 판단 3에서 팔레트를 끄기로 하면 이 검사는 빠진다.

**9번 (신규) — 괄호 변수로 색 이름 클래스 건너뛰기 0건**

```bash
grep -rnE '[a-z]-\((--|[a-z-]+:--)' src/app src/components
```

- 잡는 예: `bg-(--primary)`, `p-(--gap)`, `text-(length:--x)`. semantic 이름 클래스(`bg-primary`)가 있는데 변수를 직접 꽂는 길이다.
- 못 잡는 예: `bg-[var(--x)]`(7번이 잡는다), `style={{ color: "var(--x)" }}`(1층 이름이면 2번이 잡는다).

### 4. 캔버스 → shadcn 이식 규칙 초안

자리: `5-frontend-build.md` §2.5.3. 캔버스(`.dc.html`)는 평문 HTML이라 요소마다 「어느 부품의 어느 variant인가」를 정해 옮긴다.

**요소 대응**

| 캔버스 요소 | 옮길 자리 |
|---|---|
| 버튼(주·보조·글자형·위험) | `Button` + `variant`(default·secondary·ghost·link·destructive) + `size` |
| 버튼처럼 생긴 링크 | `Button asChild` 안에 `Link` |
| 한 줄 입력 + 이름 | `Input` + `Label` (안내 문구를 이름 대신 쓰지 않는다 — common-patterns §2) |
| 여러 줄 입력·댓글창 | `Textarea` — 자동 높이·최대 높이는 common-patterns §5 기준으로 확인 |
| 고르기 | `Select`·`Checkbox`·`RadioGroup`·`Switch` |
| 확인 창 | 되돌리기 어려우면 `AlertDialog`, 그 밖은 `Dialog` |
| 아래에서 올라오는 판 | `Sheet side="bottom"` 또는 `Drawer` |
| 알림 띠 | `Sonner`(toast) |
| 위젯 카드 | `Card` — 목록 항목에는 쓰지 않는다 |
| 화면 안 탭 | `Tabs` (하단 탭 막대 내비는 셸에 속한 전용 부품이다) |
| 태그·칩 | `Badge` (판단 7) |
| 아바타·로딩 뼈대 | `Avatar`·`Skeleton` |
| 셸·내비 막대·행 목록·도메인 부품 | `components/`의 전용 부품. 재료는 shadcn 부품 + semantic 클래스 |

**모양이 shadcn 기본과 다를 때 — 고치는 차례**

1. **2층 값으로 맞춘다** — 색·둥글기·글꼴이 다르면 `--primary`·`--radius`·`--font-sans`를 바꾼다. 대부분 여기서 끝난다.
2. **variant를 더한다** — 같은 부품의 다른 모양이 필요하면 그 부품의 cva에 variant를 추가한다.
3. **부품 파일을 고친다** — 1·2로 안 되면 `components/ui/` 파일을 직접 고치고, adapter의 「고친 shadcn 부품 목록」에 한 줄 적는다.
4. **화면에서 겉모양을 덮어쓰지 않는다** — `<Button className="bg-[#..] rounded-[14px]">`처럼 쓰지 않는다. 화면이 부품에 주는 `className`은 배치(바깥 여백·폭·flex·grid)만이다.

**캔버스 값 → 토큰**

- 색: 캔버스 hex를 oklch로 바꿔 1층 램프의 가장 가까운 단계에 맞춘다. 단계를 새로 만들지 않는다.
- 간격·크기: 캔버스의 `13px` 같은 값은 가장 가까운 theme 스케일(`p-3`)로 반올림한다. 차이가 눈에 띄면 2층·theme 값을 바꾸지, 스케일 밖 값을 쓰지 않는다.

**「스킬 쪽으로 고쳐 이식」이 shadcn에서 뜻하는 것** — 캔버스를 그대로 베끼면 shadcn 부품으로도 안티패턴이 그대로 옮겨진다. 이렇게 바꾼다:

- 목록 항목마다 카드 → `Card`를 빼고 행 목록 전용 부품으로. `Card`는 위젯에만.
- 상태색을 장식에 씀 → `destructive` 같은 상태색은 의미 전달에만. 장식은 `accent`·`muted`.
- 하단 막대를 화면에 붙여 띄움 → 셸의 하단 칸으로.
- 14px 아래 글자 → 글 스케일 바닥선 안에서. 위계는 굵기·`muted-foreground`로.
- 안내 문구가 이름 노릇 → `Label`을 단다.

### 5. 구현 순서 제안

다섯 묶음으로 나눈다. 앞 묶음이 뒤 묶음의 기준이 된다.

| 묶음 | 대상 | 완료 기준 |
|---|---|---|
| A. 스택 결정 반영 | `5-frontend-build.md` §2.4.1 (#45) | 표에 행이 있고, 조사·ADR 항목에 Tailwind·`components.json`이 들어 있고, 「옛 구조 프로젝트는 그대로」 한 줄이 있다 |
| B. 토큰 구조 | SKILL.md(#1~#11), `bootstrap-project.md`(#12~#18), `naming-taxonomy.md`(#19~#25) | 2층 예시(§2)가 들어가 있다. 철칙·안티패턴 표가 새 허용 범위와 맞다. 자기참조 calc 문단이 고쳐졌다. eval-scenarios 23·31번이 여전히 막힌다(하단 세 칸·적용 규칙 요약·역할 한정 토큰 주석) |
| C. 부품·레이아웃·폰트 | `component-taxonomy.md`(#26~#32), `layout-frames.md`(#33~#39), `font-loading.md`(#40~#43) | 스킬 폴더에서 `--modifier`·BEM 언급이 `3-components.css` 맥락 밖에 0건이다. 판단 5 결과가 §4 결정표에 반영됐다. eval-scenarios 23번 유지 |
| D. 5단계 연결 | `5-frontend-build.md` §2.5.3(#47)·관문 ①(#48~#52), `AGENTS.md.template`(#54), `6-2-backend-auth.md`(#55) | 관문 ①에 1~9번 명령이 있다. adapter 항목에 「고친 shadcn 부품 목록」·「관문 ① 예외」 자리가 있다. eval-scenarios 18·32번 유지 |
| E. 마무리 | 루트 `.claude/` 미러 동기화, `docs/eval-scenarios.md` 되짚기, grep 실측 | 미러가 payload와 같다. 빈 연습 프로젝트에 `shadcn init` + 기본 부품 몇 개를 받아 관문 ① 7~9번을 돌려 오탐 수를 세고, 판단 4의 결정대로 정리됐는지 확인한다(관문 4번 오탐 93건 사고처럼 실측 없이 넣으면 첫 프로젝트에서 터진다) |

묶음 B·C는 판단 1~7이 정해져야 쓸 수 있다. 묶음 A는 지금 바로 해도 된다.

### 6. 판단이 갈리는 것

1. **shadcn 부품을 다시 받으면 우리 수정이 덮인다** — `add`는 같은 파일이 있으면 묻고, `--overwrite`면 묻지 않고 덮는다.
   - 갈래 ㉮ 고쳐 쓰되 adapter에 「고친 부품·이유」 목록을 두고, 다시 받기 전엔 `--diff`로 차이를 본다. `--overwrite`는 금지.
   - 갈래 ㉯ 받은 파일은 안 고치고, 고칠 일은 2층 값과 감싸는 전용 부품으로만 푼다.
   - 기울기: ㉮ + 「고치기 전에 2층 값부터」(§4 차례). ㉯는 감싸는 부품이 늘어 인벤토리가 두 겹이 된다.
2. **글 스케일을 `@theme`에 두면 Tailwind 기본 `text-sm` 류를 막을까** — `--text-*: initial`로 막으면 shadcn 복사본의 `text-sm`·`text-xs`가 사라져 부품이 깨진다(button 기본 복사본에서 확인).
   - ㉮ 막고, 받을 때마다 복사본을 우리 스케일로 고친다.
   - ㉯ 두고, 제품 코드(`components/ui` 밖)에서만 grep으로 막는다.
   - ㉰ 기본 이름을 우리 값으로 다시 정의한다(`--text-sm: var(--b2-base)`).
3. **Tailwind 기본 팔레트를 끌까** (`--color-*: initial`) — 끄면 팔레트 클래스가 아예 안 생겨 8번 검사가 필요 없다. 대신 shadcn 복사본의 `text-white`·`bg-black/50`이 깨지니 2층에 `--color-white`·`--color-black`을 두거나 복사본을 고쳐야 한다.
4. **관문 ① 검사 범위에 `components/ui/`를 넣을까** — 기본 복사본에 `ring-[3px]`·`text-white`·`md:text-sm`이 이미 있다.
   - ㉮ 넣고, 받자마자 고치거나 adapter 예외 줄에 올린다.
   - ㉯ 빼고, 제품 코드만 본다(복사본은 2층 값으로만 다룬다는 전제).
   - 판단 1·2·3과 함께 정해야 한다.
5. **「폰트는 `next/font`」와 font-loading §4의 실사고가 부딪친다** — Pretendard 같은 npm 폰트를 `next/font/local`로 부르면 `unicode-range`를 못 써서 MB급 통짜 파일이 모든 화면에 미리 받기로 걸린다(실제로 밟은 함정).
   - ㉮ 구글 폰트는 `next/font/google`, npm 폰트는 지금처럼 조각 CSS `@import`로 두고 2층 `--font-sans`에서만 합친다.
   - ㉯ `next/font`로 통일하고, 한글 폰트는 구글 폰트에 있는 것만 고른다.
6. **둥글기 이름: 용도 이름(`--radius-card`)을 남길까** — naming-taxonomy §1의 「크기는 숫자가 아니라 용도」 대원칙과, 이미 정한 「theme 스케일 클래스(`rounded-md`) 허용」이 부딪친다. 용도 이름을 `@theme`에 더하면(`rounded-card`) 두 체계가 같이 산다.
7. **chip의 정본 이름** — 지금 인벤토리 규칙은 「chip ← tag·pill, badge는 별개 개념」인데, shadcn엔 chip이 없고 `Badge`가 그 모양이다. ㉮ `Badge`를 정본으로 하고 동의어 줄을 고친다 / ㉯ 전용 `Chip` 부품을 따로 둔다.
8. **`components.json`의 CSS 파일 경로** — 일부 부품(예: sidebar·chart)은 `add` 때 CSS 변수를 그 파일에 덧붙인다. 진입 CSS로 두면 변수가 2층 밖에 쌓이고, `2-semantic.css`로 두면 init이 그 파일에 import 줄까지 쓸 수 있다. 구현 묶음 E 실측으로 정한다.
9. **5단계 `/design` 지시에 「shadcn 부품 어휘로 그려라」를 넣을까** — 넣으면 이식이 쉬워진다. 대신 캔버스 표현의 자유가 줄고, 2단계 목업 지시와 결이 달라진다.
10. **(정하지 않아도 되는 것)** 다크 모드 전환 장치(예: `next-themes`)는 이번 범위 밖이다. 2층에 `.dark` 블록 자리만 둔다.

### 구현 메모 (2026-10-06)

§6 판단 1~10은 확정값대로 들어갔다. 구현하면서 설계와 달라졌거나 설계에 없던 것만 적는다.

- **화면 단위 비례 조정 클래스(`.screen--dense`)는 `2-semantic.css`에 둔다.** 설계는 자리를 안 정했고, 처음엔 `3-components.css`에 두었다가 연습 파일로 관문 ①을 돌려 보니 1번(`1px`)과 2번(`--b1-base` 직접 참조)에 둘 다 걸렸다. 1층 변수와 px 증감을 쓰는 자리라 2층이 맞다 (naming-taxonomy §2).
- **절 번호가 당겨졌다.** bootstrap-project §2 삭제로 §3~§6 → §2~§5, naming-taxonomy §4 삭제로 §5·§6 → §4·§5. 이 번호를 가리키던 SKILL.md와 `eval-scenarios.md` 23·31번을 같이 고쳤다. 이 문서의 앞 절(설계 대응표)에 적힌 번호는 옛 번호 그대로다.
- **관문 ① 3번 접두어 정규식 끝에 `[a-z[!-]`를 붙였다.** 설계 초안 그대로면 cva의 `size: { sm: "h-8" }` 같은 객체 키가 걸린다. 콜론 바로 뒤가 클래스 글자일 때만 잡게 했다.
- **관문 ① 4번은 `## 전체 부품 색인` 구간을 잘라 줄 전체 일치(`-x`)로 대조한다.** 부품은 basename이 아니라 경로로 대조한다 — basename은 다른 폴더의 같은 이름 파일과 섞인다. 색인은 꾸밈 없이 한 줄에 하나로 적게 했다.
- **관문 ① 8번은 팔레트 이름 grep 대신 「`--color-*: initial` 줄이 있나」 확인이다** (판단 3). 그래서 제품 코드의 `text-white`·`bg-black`은 기계로 못 잡는다 — 못 잡는 예로 적어 두었다.
- **`@custom-variant dark`는 진입 CSS의 import 줄 뒤에 둔다.** CSS 규칙상 `@import`는 다른 규칙보다 앞에 와야 해서, 설계 §2의 「init 줄 → 1층」 순서에서 이 줄만 뒤로 뺐다.
- **글 스케일 다시 정의에 `text-xs`도 넣고 `b2` 값으로 이었다.** 복사본(badge 등)의 `text-xs`가 14px 바닥선 아래로 내려가지 않게 하려는 것이다. 다른 기본 이름은 「복사본이 쓰면 같은 식으로」로 열어 두었다.
- **부품 전용 글자 토큰 이름을 `--font-size-{부품}`에서 `--text-{부품}`으로 바꿨다.** Tailwind의 글자 크기 이름 묶음이 `--text-*`라 그래야 `text-chip` 클래스가 생긴다.
- **npm 폰트의 1층 원료는 패밀리 이름 변수(예: `--font-pretendard`)다.** 조각 CSS `@import`는 토큰 파일이 아니라 진입 CSS의 import 줄에 둔다 (font-loading §3·§4, 「토큰 파일에 로딩 설정을 섞지 마라」 유지).
- **5단계 완료 체크리스트의 「여섯 검사」를 「아홉 검사」로 고쳤다** (8번은 1 이상이 통과).
- **실측 범위**: 설치 금지 조건이라 빈 연습 프로젝트에 `shadcn init`을 돌리지 못했다. 관문 ① 1~9번은 손으로 쓴 연습 파일(button 복사본 일부·`md:text-sm` input 포함)로 돌려 잡는 예·못 잡는 예를 확인했다. 첫 실제 도입 때 확인할 것: 판단 8의 `components.json` CSS 경로와 부품 추가 때 덧붙는 변수의 자리, `@theme inline` 안의 `--color-*: initial`이 기본 팔레트를 실제로 끄는지, 기본 복사본 몇 개를 받은 뒤 관문 ① 오탐 수.
