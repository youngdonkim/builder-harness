# 하네스 다이어트 검토 보고서

작성일: 2026-08-19 · 브랜치: feat/db-migration · 검토 방식: 3회 분할 정독 + 교차 검토

- 판정 분류: A 일반 지식 중복(설명문만) / B 중복 서술 / C 죽은 참조 / D 낡은 사실 / E 세부 과잉 / F 발동 불가 글롭 / G 층 이동(삭제 아님) / [모순]
- 이 보고서는 **검토만** 한 결과다 — 실제 수정은 항목을 골라 따로 실행한다.

---

## 1회차 — 상시 로드층 + rules/agents/templates + 전역 C·D·F

### 요약

- **상시 로드층에서 줄일 수 있는 분량**: 순수 삭제는 거의 없다(≈1줄). 대신 **층 이동(G)으로 상시 로드층에서 빼낼 분량이 프로젝트 세션 기준 약 10~12줄** — `payload/CLAUDE.md.template` 3줄 + `payload/AGENTS.md.template` 6~7줄 + 루트 `AGENTS.md` 1줄. 하네스 저장소 세션 기준으로는 약 4줄.
- 상시 로드층 4개 파일은 이미 꽤 압축돼 있다. 진짜 성과는 **D 3건**(지금 저장소랑 안 맞는 서술)과 **F 1건**(rules 글롭이 실제로 안 걸림)이다. 이건 다이어트가 아니라 버그다.
- **항목 수**: A 0건 / B 4건(전부 "의도 확인 필요") / C 2건 / D 4건 / E 2건 / F 1건 / G 4건

### 항목

#### `payload/AGENTS.md.template`

**① D — 스택을 6단계에서 고른다는 서술이 지금 설계랑 안 맞음**

- 위치: L33 `"(6단계 MvpBuild에서 스택·..."` / L37 `"6단계 MvpBuild에서 Su..."`
- 근거: 스택은 **3단계에서 고정**된다. 6단계는 고르는 자리가 아니다.
  - `3-prototype.md` §2.4.1: "React 웹을 택했으면 스택 자체는 고정이다 — 후보 제시·사용자 선택 없음." / L256: "고정 범위는 3단계에서 끝나지 않는다. … 6단계는 스택을 새로 고르는 자리가 아니다"
  - 즉 "다른 스택을 골랐으면 이 절을 그 스택에 맞게 바꿔 쓴다"(L37)는 지금 존재하지 않는 분기다.
- 제안: **수정**. L37을 "3단계에서 고정된 Supabase·Vercel 스택 기준이다."로, L33은 "스택은 3단계에서 고정되고, 실행 방법·코드 규칙은 6단계에서 정해지면"으로.

**② G — "이 프로젝트가 쓰는 도구" 마이그레이션 3줄을 스킬층으로**

- 위치: L44~L47 `"**마이그레이션은 자동으로..."` ~ `"없애는 마이그레이션 → **머..."`
- 근거: 똑같은 내용이 실제로 그걸 **강제하는** 게이트 쪽에 이미 원문 그대로 있다 — `done-task/SKILL.md` §1.7(204~205·224~225), `6-mvp-build.md`(300~301). done-task는 머지 직전에 이걸 묻고 막는다. 상시 로드층 사본은 알림 역할뿐이다.
- 제안: **이동**. 상시 로드층엔 한 줄만 — "**마이그레이션은 자동으로 안 올라간다** — 미는 순서는 `done-task` 게이트가 묻는다." (원문은 이미 두 곳에 그대로 있다.)

**③ G — Supabase CLI 사용법 설명을 6단계로**

- 위치: L39 `"**Supabase CLI** — 개발..."`
- 근거: start/stop·`db reset`·`db push --linked` 절차와 "대시보드 직접 수정 → `db push` 실패"는 6-mvp-build.md에 훨씬 자세히 + 공식 문서 인용까지 있다 (§2.2.1·§2.2.2에 20곳).
- 제안: **이동**. 상시 로드층엔 "**Supabase CLI** — 개발 의존성. `npx supabase`로 부른다. 절차는 `6-mvp-build.md` §2.2." 한 줄만.
- 주의: "대시보드에서 스키마를 직접 고치면 이력이 어긋나 `db push`가 실패한다"는 실측 사고 서술 — 6-mvp-build.md L204·L207에 공식 인용까지 붙어 그대로 있으니 유실 없음.

#### `payload/CLAUDE.md.template` + 루트 `CLAUDE.md`

**④ G — "규칙을 어디에 적나"의 근거 문단을 README로**

- 위치: `payload/CLAUDE.md.template:7` / `CLAUDE.md:5` (미러 쌍이라 한 건)
- 근거: 규칙은 첫 문장 하나면 되는데 뒤에 근거 3문장이 붙어 있다. "왜"는 README §7.3(L303·313·314)에 이미 같은 취지로 있다.
- 제안: **이동**. 남길 한 줄 — "**규칙을 어디에 적나** — 어느 AI 도구가 읽어도 될 규칙은 `AGENTS.md`에, 클로드 전용(위임·모델·재위임)은 이 파일에." 내릴 문장(원문 그대로 README §7.3 밑으로): "이렇게 나누는 이유는 도구마다 읽는 파일이 달라서다 …" / "(그록 CLI는 `CLAUDE.md`도 같이 읽는다 — `grok inspect`로 확인된다. …)" / "클로드는 이 파일 맨 끝의 `@AGENTS.md` 줄 덕에 둘 다 읽는다."
- **`grok inspect`로 확인된다**는 실측이라 반드시 원문 그대로 옮긴다. 삭제 절대 금지.

**⑤ G — 재위임 금지의 사고 경위 괄호**

- 위치: `payload/CLAUDE.md.template:22` / `CLAUDE.md:20` — `"(부모는 자기 밑 자식이..."`
- 근거: 규칙은 앞 두 문장으로 끝나고, 괄호는 실측 사고 정황(강제 종료도 안 먹힌다)이다. 상시 로드층에 있을 필요는 없지만 지우면 안 되는 정보.
- 제안: **이동**. README §7에 "재위임을 막는 이유" 항목으로 원문 그대로 내리고, 상시 로드층엔 괄호만 뺀다.

**⑥ D — "`/done-task`가 끝나면 main에 서 있다"는 오너 경로에서만 참**

- 위치: `payload/CLAUDE.md.template:14` / `CLAUDE.md:12`
- 근거: done-task §2.5 — 팀원 경로(push만 true)는 PR 생성까지만 하고 멈춘다. 로컬 main 이동은 §3-d(오너 경로)에만 있다. 팀원 경로에선 done-task가 끝나도 작업 브랜치에 그대로 서 있다.
- 제안: **수정**(삭제 아님). "**`/done-task`가 (오너 경로면) 끝나면 main에 서 있다.**" 등. → 2회차 [모순-4]와 같은 발견 (교차 검증됨).

#### 루트 `AGENTS.md`

**⑦ E — 검증 3번 불릿이 1·2번의 되풀이**

- 위치: L27 `"**역할을 나눈다** — AI는..."`
- 근거: L25(사람 몫)+L26(화면 밖 검사)의 역할 관점 재서술. 새 정보는 "개발 서버를 띄워 접속 주소를 알려준다" 하나뿐.
- 제안: **축약안** — L27 삭제, 새 정보만 L26 끝에: "… 평소대로 돌리고 결과를 보고한다. 개발 서버를 띄워 접속 주소까지 알려주는 것도 AI 몫이다. …"

#### `payload/.claude/rules/threat-model.md`

**⑧ F — 글롭 6개 중 4개가 이 하네스가 강제하는 Next.js 구조에서 절대 안 걸린다**

- 위치: L5~L8 (`src/api/**/*`, `app/api/**/*`, `src/auth/**/*`, `app/auth/**/*`)
- 근거: 하네스 고정 스택은 Next.js App Router + `src/` 디렉터리 — API 라우트는 `src/app/api/**`, auth는 `src/app/auth/**`에 놓인다. 경로 중간에 `app`이 껴서 `src/api/**`는 안 걸리고, 루트 `app/`이 없어 `app/api/**`도 안 걸린다. 살아 있는 건 `**/middleware*`·`**/upload*` 둘뿐. (glob 실측으로 확인)
- 제안: **수정**. `**/api/**/*`·`**/auth/**/*` 둘로 합친다. 4줄 → 2줄이면서 발동은 오히려 넓어진다. **보안 룰이 조용히 죽어 있던 버그.**

#### `payload/.claude/agents/ux-writing-reviewer.md`

**⑨ C — `userflow.md`는 이 하네스 어디서도 안 만드는 파일**

- 위치: L16 `"5. 화면명·라벨이 SoT 문서(예..."`
- 근거: `grep -rn "userflow" payload/` → 이 파일 2곳뿐. `find -name "*userflow*"` → 없음. 화면 SoT는 `mvp/information-architecture.md` → 마이그레이션 후엔 앱 코드.
- 제안: **수정** — `(예: userflow.md)` → `(예: mvp/information-architecture.md)`.

**⑩ D — description의 "userflow-screens", "content collections"가 지금 스택에 없는 개념**

- 위치: L3
- 근거: content collections는 Astro 개념(grep 결과 이 파일이 유일한 히트), 고정 스택은 Next.js. description은 에이전트 발동 판정에 쓰이는 줄이라 없는 개념이 끼면 발동이 흐려진다.
- 제안: **수정** — `userflow-screens, prototype html, content collections` → `mvp/ 산출물, 프로토타입 standalone.html, Next.js 화면·컴포넌트`.

**⑪ B — 잡초 부사 목록이 같은 파일에 두 번**

- 위치: L41 / L78 (L78이 L41의 부분집합)
- 제안: **의도 확인 필요**. §6 표는 한눈 표라 형식이 다름. 줄이려면 L78 행을 "§1.2 목록 참조"로.

#### `payload/.claude/agents/git-flow.md`

**⑫ D — 이 에이전트를 쓰는 스킬이 3개인데 description엔 2개만**

- 근거: `grep "^agent: git-flow"` → new-task·done-task·**rewind-task** 3개. README L145는 3개로 맞게 적혀 있고 에이전트 파일만 낡았다.
- 제안: **수정** — "new-task·done-task·rewind-task 스킬의 fork 실행용" + 본문에 되감기 추가.

#### `payload/.claude/skills/idea-to-mvp/references/7-mvp-launch.md`

**⑬ C — 목차 앵커 하나가 `②`를 빠뜨려 안 걸린다**

- 위치: L19 목차 링크 ↔ L82 실제 헤더 `### 2.3 막3 — launch-retro (통과 기준②, 최종 판정)`. GitHub 슬러그는 ②를 지우지 않으므로 실제 앵커는 `#23-막3--launch-retro-통과-기준②-최종-판정`. (payload 전체 md 앵커 검사에서 죽은 앵커는 이거 하나 — 3회차도 동일 확인.)
- 제안: **수정** — 앵커에 `②` 넣기. 곁들여 `markdown-style.md` L14에 "숫자·글자 성격의 기호(①②)는 남긴다" 한 구절 추가 권장.

#### `payload/.claude/rules/markdown-style.md`

**⑭ E — 나쁜 예 블록**

- 위치: L18~L21
- 근거: L16이 같은 금지를 문장으로 이미 말한다. 좋은 예만 있어도 형식은 전달된다. 이 rule은 `**/*.md`로 걸려 문서 작업마다 뜨니 4줄 절감이 자주 반복된다.
- 제안: **축약안** (확신도 중간 — 나쁜 예/좋은 예 대조가 형식 규칙엔 제일 잘 먹혀서 사람 판단 필요).

#### `payload/.claude/templates/sources-template.md`

**⑮ B — "갱신 시 반드시 fetch" 주석**

- 위치: L7. delegation-integrator 규칙 2("기억 금지")·1단계("raw URL 우선")와 같은 내용.
- 제안: **의도 확인 필요** — 사람이 손으로 채울 때 보는 안내이기도 함.

#### `payload/.claude/agents/delegation-integrator.md`

**⑯ B — "화면 검증은 사람 몫이다"**

- 위치: L87. AGENTS.md L25와 중복. 단 이 에이전트의 T1~T3는 애초에 CLI 테스트라 브라우저가 나올 자리가 아니다.
- 제안: **의도 확인 필요** — 서브 에이전트가 프로젝트 AGENTS.md를 받는지에 따라 갈린다 (아래 "사람이 정해야 할 것" 1).

#### 루트 `AGENTS.md` ↔ `CLAUDE.md`, 템플릿 쌍

**⑰ B — 프로젝트 정의 줄이 두 파일 상단에 똑같이 → 의도된 이중 배치로 확정. 손대지 마라**

- 근거: `4-demo-validation.md` L454가 "두 파일 상단에 같은 프로젝트 정의 줄이 각각 있다. 둘 다 … 덮어쓴다. 한쪽만 고치면 도구마다 다른 정의를 읽게 된다"고 명시.

### 1회차 — 확신 없어 뺀 것

- `AGENTS.md` L26 "린트(lint — …)" 용어 풀이 — L17 전문용어 표기 규칙이 강제. 지우면 자기 규칙 위반.
- `threat-model.md` L15 "`NODE_ENV === 'development'`는 로컬에서만 true" — "내부 베타라 안전" 오판을 교정하는 못.
- `threat-model.md` L26~30 baseline 5줄 — 이 rule의 존재 이유 자체.
- `CLAUDE.md` L23 "스킬 본문은 자동으로 안 들어오니 열어봐야 한다" — "이름 봤으니 안다" 착각을 막는 문장.
- `AGENTS.md.template` L42 Docker 항목 — 도구 인벤토리 항목.
- `ux-writing-reviewer.md` self-check — 수정 후 재검사 장치라 형태가 다름.
- `status-template.md` L4 예시 저장소 이름 — 템플릿 예시고 실재 여부 오프라인 확인 불가.
- `delegation-integrator.md` 5단계 워크플로 — 단계마다 "왜"가 박혀 있어 E 제외.

### 1회차 — 사람이 정해야 할 것

1. **서브 에이전트가 프로젝트 CLAUDE.md/AGENTS.md를 받는가.** git-flow.md L10은 "받는다" 전제, 각 에이전트의 재기재는 "안 받는다" 전제 — 섞여 있다. 이게 정해져야 ⑯류 재기재를 지울지 남길지 갈린다.
2. **AGENTS.md.template의 도구 절을 상시 로드층에 둘 것인가.** ②③대로 내리면 프로젝트 세션마다 6~7줄 절약. "매 세션 보여야 안 틀린다"가 만든 이유였다면 유지 — 그 근거가 어디에도 안 적혀 있다.
3. ⑭ 나쁜 예 블록 삭제 여부.
4. ⑬ 고치면서 markdown-style.md에 기호 처리 명시 여부.

---

## 2회차 — 스킬층 (SKILL.md 7개 + grok-delegation 부속)

### 요약

항목 수: A 2건 / B 11건 / C 1건 / D 1건 / E 2건 / G 6건 / 모순 4건

### 항목

#### grok-delegation/SKILL.md

- **A-1** · 8줄 `그록(Grok)은 xAI가 만든 다른 회사 AI다.` — 순수 설명문, 실측·사고 정황 없음. **삭제** (뒤 문장 "터미널에서 부르는 도구라 …"는 전제라 남김).
- **A-2** · 44줄 `(토큰 token — …)` 용어 풀이 — done-task의 CI·merge 풀이 등 같은 종류 다수. **AGENTS.md 전문용어 표기 규칙과 정면 충돌**이라 사람이 정할 것 (스킬 본문의 독자가 AI뿐인지에 따라).
- **B-6** · 20~21줄 ↔ 46줄 — "묶어서 한 번에·한두 줄은 직접"이 `언제 위임하나`와 `토큰 절약 3원칙`에 통째 2회. **축약** — 한 곳만 남기고 참조.
- **B-7** · 47줄 ↔ 52줄 — "종료 코드 0 + git status 확인" 실측이 2회. **축약** — 실측은 `## 검증`에 한 번만, 토큰 절약 쪽은 한 줄 참조. 실측 자체는 안 지움.
- **G-1** · 39줄 `(grok-bridge.mjs의 sandbox: …)` 소스 인용 — reference.md 11줄에 이미 있음. **이동**(SKILL에선 괄호 삭제 + "근거는 reference.md").
- **G-2** · 32줄 argv 실측 괄호 — reference.md `셸 argv 한도 실측` 절에 이미 있음. **이동**.

#### grok-delegation/sources.md

- **C-1** · 8·10·13·16줄 — 템플릿 자리표시자 `<URL>` 4곳이 안 채워진 채 그대로 (diff로 확인). **수정** — 실제 주소를 채우거나 "미확인 — delegation-integrator가 채울 것"으로.
- **B-8** · 24~27줄 T2 힌트에 동작 설명이 섞임 — reference.md·status.md와 역할 중복. **축약** — "T2(쓰기): --write 필요 (동작·검증 상태는 reference.md)".

#### done-task/SKILL.md

- **모순-4** · 423~426줄 팀원 보고 "브랜치는 아직 살아 있고" ↔ CLAUDE.md 12줄 "끝나면 main에 서 있다". 기준 문서를 고치거나 팀원 보고에 "지금 브랜치 그대로다" 명시. **사람이 정할 것.** (1회차 ⑥과 동일 발견)
- **B-3** · 14줄/41줄/282줄 — "협업자 구조라 머지 권한이 사람마다 다르다" 3중. **축약** — §2.5에만 두고 나머지는 참조.
- **B-4** · 41줄/464줄/513줄 — "비공개+무료 플랜은 브랜치 보호 규칙 불가(API 403)" 3중. **축약** — "안 하는 것"에만.
- **B-5** · 엣지 케이스 표(24행) + "안 하는 것" — 본문 §1~§4의 재서술 구조. **의도 확인 필요** (색인이면 정상 설계. 단 본문 근거가 통째 반복된 행은 "§ 참조"로 축약 가능). new-task·rewind-task도 같은 구조.
- **B-11** · 202~205줄 순서 규칙 두 줄 ↔ AGENTS.md.template 45~47줄 — 층이 다른 중복. **의도 확인 필요** (1회차 ②와 연결).
- **G-3** · 28~33줄 "왜 GitHub squash인가" — git-workflow.md §2에 더 자세히 있음(42~63줄 확인). **이동** — 두 줄 + 포인터.
- **G-4** · 134~138·149~153줄 — 리베이스 금지 근거 전문과 변천사("예전 규칙은 …")가 git-workflow.md §8.3(292~359줄)에 그대로 있음. **이동** — 규칙 세 줄만 남기고 §8.3 포인터로.
- **E-1** · 302~307줄 push 명령 받아쓰기 — 못박은 이유 없음. **축약** — "push한다. tracking 없으면 -u." + 실패 처리 유지.

#### new-task/SKILL.md

- **모순-3** · 287줄 `❌ commit·push` ↔ 45~56줄 args "(a) 지금 변경을 커밋하고 진행" — args 옵션이면 실제로 커밋한다. done-task는 같은 상황에 예외 단서를 달아뒀는데 new-task엔 없다. **수정** — "(단 §1-b (a) 옵션은 예외)" 추가. 위험 없음.
- **B-9** · 191줄 이름 충돌 근거 문단 ↔ git-workflow.md §8.4(360~375줄). **의도 확인 필요** — 절차는 남기고 "왜 원격까지 보나"만 포인터 후보.

#### rewind-task/SKILL.md

- 삭제·이동 후보 없음. (실측 주석 2건은 보호 대상.)

#### project-init/SKILL.md

- **모순-1** · 161줄 "예외는 하나 — 하네스를 막 적용한 직후 …" ↔ CLAUDE.md 11줄 "`/project-init` … **예외 없이** 브랜치를 먼저". 게다가 신규 적용 모드(62~144줄)엔 브랜치 확인 자체가 없다. **사람이 정할 것** — 기준 문서에 예외를 명시하든, 스킬 예외를 지우든.
- (E 제외 기록) 원본 검증 4단계는 "왜 중단하나"가 못박혀 있어 E 아님.

#### idea-to-mvp/SKILL.md

- **모순-2** · 112·131줄 "스택은 고정" ↔ AGENTS.md.template 33·37줄 "6단계에서 고른다". 1회차 ①과 같은 뿌리. **AGENTS.md.template 쪽을 고치는 안** (3-prototype.md 53·173줄이 "고정"을 재확인).
- **B-9(a)** · 45줄 ↔ 239줄 — "한 프로젝트 = 한 아이디어·피봇은 같은 프로젝트" 2중. §1.1이 §3으로 넘기면서도 내용을 다 적음. **축약** — §1.1은 한 줄 참조로.
- **B-10** · 70줄/131줄/168·185줄/235~237줄 — 3단계 산출물 정의·"handoff는 1세대 기록"이 4회. **축약** — 정의는 §2.1 표, 전환 규칙은 §2.2 한 곳으로.
- **G-5** · 56줄 "(구 통과 기준③ ProtoRetro 폐지 경위)" 9줄 — 지금 규칙이 아니라 설계 경위. **이동** — docs/ 설계 노트로.
- **G-6** · 183·189줄 — "왜 마이그레이션 직후 승격하나"·"상태 변형 점검 이관" 배경·변천사. **이동** — 규칙만 남김 (186줄 "예외 없는 규칙이 AI 실행자에게 더 잘 지켜진다"는 남기는 쪽 권장).
- **E-2** · 259~266줄 어휘 swap의 grep→sed→mv→grep 받아쓰기 — **축약** — 한 줄 + 판단 규칙(4·6번) 유지.
- **D-1** · `scripts/run-phases.py` — 폐기된 `planning/cycles/` 구조 전제, **어디서도 안 불림** (`grep -rn "run-phases|planning/cycles|_utils" --include="*.md"` → 0건). **폐기 여부 사람 확인.**

#### 여러 파일 공통

- **B-1** · design-system 27~33 / grok-delegation 10~16 / idea-to-mvp 9~15 — "시작 전 브랜치 확인" 문단이 글자 하나 안 틀리고 3중 복붙 (+project-init 160줄에 같은 이유 한 번 더, CLAUDE.md 11줄에 같은 규칙 — 층 다름). **의도 확인 필요** — 줄이려면 세 곳을 한 줄 + 명령 블록으로. project-init 신규 모드엔 아예 없는 문제는 모순-1과 함께 판단.
- **B-2** · new-task/done-task/rewind-task 14~22줄 — fork 프로토콜 설명 + `## 호출 인자` 문단 3중 (rewind-task만 한 문장 빠짐). **의도 확인 필요** — `## 호출 인자`엔 "삭제 금지" 주석이 있으니 fork 설명만 축약 후보.

### 2회차 — 교차 대조로 문제없음 확인한 것

- design-system·idea-to-mvp·project-init의 앵커·파일 링크 전부 실존. done-task→git-workflow.md §8.3·§2.5 실존. reference.md의 grok-bridge.mjs 줄 번호 인용 전부 일치(592~593·738·739·751·455·81), 버전 0.2.1 일치. `payload/.claude/templates/` 실존.

### 2회차 — 확신 없어 뺀 것

- rewind-task 172줄 git 문법 설명 — 바로 뒤 "실측으로 확인함"이 붙음.
- done-task 380~383줄 `-D`·`--prune` 이유문 — 실제 증상(유령 브랜치)이 적힌 못.
- grok 600초 절단 3파일 기재 — 역할(실행/검증/이력)이 갈려 중복 아님.
- project-init 143줄 `/reload-plugins` — 실존 명령인지 저장소만으론 확인 불가.
- status.md "인증: 미확인" — 명령을 돌려야 알 수 있어 D로 못 올림.
- done-task 275줄 Test plan 문장 — 원칙의 반복이 아니라 적용.

### 2회차 — 사람이 정해야 할 것

1. **용어 풀이 괄호를 스킬 본문에 계속 둘 것인가** (A-2) — "사용자에게 말할 때만 푼다"로 규칙을 좁히면 7개 스킬에서 꽤 걷어낼 수 있다.
2. **팀원 경로 done-task 종료 위치** (모순-4).
3. **스택은 3단계 고정인가 6단계 선택인가** (모순-2) — AGENTS.md.template 31~47줄 결정.
4. **project-init 브랜치 예외 인정 여부** (모순-1).
5. **엣지 케이스 표/안 하는 것을 색인으로 유지할지** (B-5).
6. **`/reload-plugins` 실존 확인.**
7. **idea-to-mvp `scripts/` 폐기 여부** (D-1).

---

## 3회차 — 참조층 (idea-to-mvp·design-system references)

### 요약

정독한 파일 14개 (빠짐 없음): 1-user-story(115) · 2-information-architecture(152) · 3-prototype(578) · 4-demo-validation(720) · 5-market-research(355) · 6-mvp-build(537) · 6-mvp-build-auth-consent(129) · 7-mvp-launch(202) / add-a-token(36) · bootstrap-project(105) · component-taxonomy(98) · font-loading(124) · layout-frames(141) · naming-taxonomy(120)

항목 수: A 2건 / B 7건 / C 1건 / D 3건 / E 0건 / 모순 5건

### 항목

#### 3-prototype.md

- **[B-1]** "1세대 기록"이 한 파일 안에서 9번 반복 (216·405·406·504·510·557·571·574·575 — grep 실측). **축약** — 정의는 §2.3, 전환 시점은 §2.5.7 두 곳만 남기고 §4②·§5 세 줄은 포인터로.
- **[A-1]** 237줄 Flutter vs React Native 비교 설명 — 널리 알려진 도구 비교, 실측·사고 없음. **축약** — "앱이 필요해지면 React Native로 옮긴다(화면 층만 다시 씀). 지금 대비 작업은 하지 않는다." 두 줄로. 명령문은 남김.

#### 6-mvp-build.md

- **[A-2]** 177줄 맥 메모리 압축 / 181줄 RSS 설명문 — OS·ps 일반 지식. **축약** — 명령문 두 줄("압박 판단하지 마라"·"순위만 봐라")만 남김.
- **[B-4]** AGENTS.md.template 도구 절 ↔ 6-mvp-build 76·282·300~301줄·§2.2.1 — 상시 로드층 ↔ 참조층이라 **의도 확인 필요**. "짧은 규칙은 AGENTS.md, 이유·절차는 references" 기준을 정할 것. 순서 두 줄이 글자까지 거의 같아 한쪽만 고치면 어긋난다. (1회차 ②·2회차 B-11과 같은 덩어리)

#### 6-mvp-build-auth-consent.md

- **[D-1]** 89줄 — "화면을 만드는 일이라 §2.6 절차를 거쳐"가 §2.6(옛 단계 내용 가져오기 — 인용 확인 절차)과 안 맞음. **수정** — §2.2 범위 가드 또는 3-prototype §2.5.4로.
- **[D-2]** 35줄 — "2단계 화면 인벤토리에서 이미 정해졌으면" — 인벤토리 칸 7개에 필수/선택 정보 자리가 없음(grep 0건) + 이 시점엔 1세대 기록. **수정** — 그 문장 삭제, "여기서 정한다"만.

#### 7-mvp-launch.md

- **[C-1]** 19줄 목차 앵커 `②` 누락 — 1회차 ⑬과 동일 (14개 파일 전체 앵커 스크립트 대조, 깨진 건 이 한 건뿐).

#### 5-market-research.md

- **[D-3]** 345줄 `## 6. 사용자 응대 톤 + 인터뷰 코칭` — 이 단계에 인터뷰가 없고 본문도 조사·판정 코칭뿐 (4단계에서 복사된 흔적). **수정** — "## 6. 사용자 응대 톤"으로.

#### bootstrap-project.md ↔ component-taxonomy.md

- **[B-2]** 인벤토리 작성 규칙이 두 곳 (bootstrap 79~84 ↔ taxonomy 78~84) — 같은 층·함께 읽히는 파일. bootstrap:84가 이미 "형식·규칙은 component-taxonomy.md §6"이라 넘기는데 위 4줄이 미리 요약해 두 벌. **축약** — bootstrap §3은 두 줄 + §6 링크만.

#### 나머지 B (판단 보류)

- **[B-3]** 4-demo 강도표가 §2.7.2 표와 §4 산출물 템플릿에 두 벌 — 문서 스스로 "변경 시 sync"라고 적어 둔 손 sync 중복. **사람 확인.**
- **[B-5]** "정찰이 못 보는 것" 인용이 4-demo:104 ↔ 5-market:86 — 같은 층이지만 다른 단계라 동시 로드 안 됨. **유지 권장**, 문구만 한 번 맞추기.
- **[B-6]** 좋은/나쁜 질문 패턴이 4-demo §2.6.2(요약)·§2.6.3(전체)·§5.1(예시) — 계단식은 의도, §5.1만 재탕 기미. 축약 여지만.
- **[B-7]** "AI가 자동 도구로 사인오프하지 않는다"가 AGENTS.md ↔ 3-prototype 4회 ↔ 6-mvp-build 4회 — 층 간은 의도로 보이나 **한 파일 안 4회**는 줄일 수 있다.

### [모순]

- **[모순-1] 아이템 폐기 후 — 같은 레포 v2 vs 새 레포 (제일 큼)**
  - `4-demo-validation.md:428` "같은 폴더에서 새 아이디어 시작하면 `demo-validation-v2.md`로 누적. **새 레포로 갈 필요 X**" (+596줄 v2 명명)
  - ↔ `idea-to-mvp/SKILL.md:239` "**한 아이디어 = 한 프로젝트** … 같은 레포에서 두 번째 아이디어는 진행하지 않는다" ↔ `7-mvp-launch.md:92` "새 아이디어는 새 프로젝트에서 처음부터"
  - 7단계는 SKILL.md와 같은 편, 4단계만 반대. **셋 중 하나를 사람이 골라 고칠 것.**
- **[모순-2] 미디어 쿼리 0건 관문 vs 반응형 계약의 예외** — `3-prototype.md:441·458`(0건이어야 통과, 근거는 layout-frames §5) ↔ `layout-frames.md:135`(화면 전체 전환은 뷰포트 기준이 맞다 — 금지가 아니다). 근거 문서가 허용하는 예외를 관문이 막는다. **제안**: 관문에 "화면 전체 전환용 뷰포트 쿼리는 adapter에 예외로 적고 통과" 한 줄.
- **[모순-3] 6단계 범위 가드 vs 온보딩 화면 신설** — `6-mvp-build.md:99`(화면 추가 금지) ↔ `auth-consent:89`(온보딩 화면이 새로 필요). **제안**: 범위 가드에 "동의 온보딩 화면은 예외(auth-consent 참조)" 명시.
- **[모순-4] 차별화 축 E의 뜻이 한 파일 안에서 다름** — `5-market-research.md:181`(E=가이드 톤) ↔ :319(Superhuman 예시의 E=속도 단일 축 10배). 표에 속도 축이 없다. **축 목록을 고칠지 예시를 고칠지 사람이 결정.**
- **[모순-5] "화면 밖 검사"를 예외로 부르는 문제** — AGENTS.md("검증하지 마라가 아니라 화면을 보지 마라다" = 애초에 범위 밖) ↔ `font-loading.md:81`("그 원칙의 **예외다**"). 6-mvp-build:361은 "해당 없다"로 정확히 씀. **제안**: font-loading도 "예외" → "해당 없음"으로 통일 (예외가 늘어난다고 읽히면 다른 데서도 예외를 만들기 시작한다).

### 3회차 — 확신 없어 뺀 것

- 부모 절 참조(3-prototype:489, 7-mvp-launch:65의 "§2.2" — 정확히는 §2.2.3; 3-prototype:530의 "§2.5" — 정확히는 §2.5.4) — 실재하는 부모 절이라 죽은 참조 아님, 정밀도만 아쉬움.
- font-loading §1 조각화 원리 — §4 결정표("next/font/local 금지")의 근거라 유지.
- naming-taxonomy §2 자기참조 calc 설명 — 안 적으면 AI가 '버그'로 고침. 유지.
- 6-mvp-build §2.2.2③ 명령 3개 표 — 아래 절차가 이 표를 전제. 유지.
- naming-taxonomy §3 ↔ layout-frames §1 용어 겹침 — 목적(정의 vs 혼동 방지)이 다름.
- 3-prototype §2.2.3 스택 안내 순서 — 실무 문제인지 확신 없음.

### 3회차 — 사람이 정해야 할 것

1. 폐기 후 새 아이디어: 같은 레포 v2 vs 새 레포 [모순-1]
2. 미디어 쿼리 관문 예외 추가 여부 [모순-2]
3. 동의 온보딩 화면을 범위 가드 예외로 명시할지 [모순-3]
4. 차별화 축 E 정의 [모순-4]
5. AGENTS.md 템플릿 ↔ 6-mvp-build 중복의 역할 기준("규칙은 상시층, 이유·절차는 참조층") 확정 [B-4]
6. 4-demo 강도표 두 벌 유지 여부 [B-3]

---

## 규칙 인덱스 (4회차 교차 대조용)

### 1회차 인덱스

**CLAUDE.md (루트)**: 하네스 원본 저장소 정의 / 규칙 배치(AGENTS vs CLAUDE, grok inspect 실측, @AGENTS.md) / 브랜치는 /new-task로·파일 바꾸는 스킬도 예외 없이 / done-task 끝나면 main / 위임 8개(서브 에이전트 위임·기존 에이전트 우선·모델 난이도 선택·옮겨 적기만 직접·재위임 금지·배포 위임 금지·검토→구현 2단계·외부 CLI는 grok-delegation 스킬 먼저) / @AGENTS.md

**AGENTS.md (루트)**: 저장소 정의 / 작업 흐름은 README / payload가 원본·미러 동기화 / 쉬움 1순위·친근한 반말·조어 금지·전문용어 표기 / main 직접 작업 금지 / 검증 4개(화면은 사람·화면 밖 검사는 돌린다·역할 분담·예외)

**payload/CLAUDE.md.template**: 프로젝트 정의 placeholder / idea-to-mvp 7단계 / mvp·docs 위치 / 규칙 배치 / 브랜치 2개 / 위임 8개 / @AGENTS.md

**payload/AGENTS.md.template**: 프로젝트 정의 / 이 파일은 모든 도구용 / 응답·문서 4개 / main 금지 / 검증 4개 / adapter 자리 / 앱 개발 컨벤션 자리 / 도구 절(Supabase CLI 절차·gh·Vercel·Docker·환경 2단·마이그레이션 자동 안 올라감·배포와 마이그레이션 순서 2줄)

**markdown-style.md**: 목차 형식(앵커 번호 리스트 + ---) / 앵커는 GitHub 슬러그 / · 나열 금지 / 나쁜·좋은 예 / §번호는 본문 교차 참조 전용

**threat-model.md**: 모든 deploy는 외부 도달 가능·NODE_ENV는 로컬만 / attack surface 판정 / baseline 5줄(인증·권한·민감정보·업로드·API) / 상세 룰은 별도 파일로

**delegation-integrator.md**: 테스트가 진실 소스 / 기억 금지·출처 필수 / 테스트 격리(mktemp) / 설치 범위 제한 / 인증은 사용자 몫 / 비용 인지 / 재위임 금지 / 설치는 사용자 확인 후 / 산출물 4종 / status 먼저 읽기 / 5단계 워크플로(조사→세팅→T1~T3→스킬 생성→보고)

**git-flow.md**: fork 실행자 / 직접 실행 / 결정 대리 금지([결정 필요] 반환) / 인자 우선 / 파괴적 명령 최소 / 완료 보고 형식 준수

**user-scenario-writer.md**: 입력 4개·가정 명시 / 장면 8종 구조 / 디자인 방향 4항목 / 출력 포맷 / 작법 5개 / 마무리 UX 장치 / 한국어·mvp/user-story.md 저장

**ux-writing-reviewer.md**: 자동 발동·직접 수정·표 반환 / 절차 5 / 예외 3(도메인 핵심어·톤 전환·의미 변경) / 글쓰기 8원칙 / 에러 3요소·6원칙·구조 / 톤 baseline / 금지 표현 표 / self-check

**templates**: sources(소스 순위·인증 체크·테스트 힌트·scope) / status(선정 방식·환경·테스트 표·이슈·이력)

### 2회차 인덱스

**design-system/SKILL.md**: 토큰만·하드코딩 금지 / 3층+조립 2층 / 브랜치 확인 / adapter 확인·없으면 bootstrap / 철칙 0~4(컴포넌트 우선·semantic만 참조·원시값은 semantic 안·foundation read-only·로딩 순서) / frame-first / 공유 셸 수정 금지 / component-first·인벤토리 등록 / semantic-first / 안티패턴 9종 / 동심원 radius

**done-task/SKILL.md**: 흐름(simplify 게이트→합치기→마이그레이션 게이트→push→PR→CI→squash→정리) / fork·[결정 필요] 프로토콜 / 호출=승인 / GitHub squash 전용 / §1 안전 검사 3 / §1.5 simplify 게이트(표식 2형태) / §1.6 merge-tree 예행·리베이스 금지·force push 금지 / §1.7 마이그레이션 게이트(더하기 먼저·없애기 나중, supabase 직접 실행 안 함) / §2 PR 초안 규칙 / §2.5 권한 판별 3갈래 / §3-c CI 대기·검사 없음 20초 재확인 / §3-d MERGED로 판정·뒷정리 6단계 / §4 보고 3종 / 안 하는 것 14개

**grok-delegation/SKILL.md**: 브랜치 확인 / 언제 위임(한두 줄 직접·잔일 묶기·검토→구현) / 브리지 호출·prompt-file 또는 heredoc·인자 금지 / --background / grok-delegate 에이전트 금지(600초) / 재위임 금지 지시 / --write 규칙 / --resume 한계 / 지시서 구체화 / git status 먼저 / git diff 검증 / 화면은 사람 / CPU·조용함으로 판단 금지 / gitignore·프로젝트 신뢰 / 경계(integrator 몫)

**grok-delegation 부속**: reference(플래그 표+검증 상태+argv 실측) / sources(소스 순위·grok inspect·테스트 힌트) / status(브리지 선정·환경·T1~T3 미실행·이슈 2건)

**idea-to-mvp/SKILL.md**: 단계 판별·references 상속 / 브랜치 확인 / 한 프로젝트 한 아이디어·피봇은 계속 / 통과 기준 2개 / 단계 판별 예외 / 하위 문서는 가리킬 때만 / 인터뷰 코칭(배치 질문·본질 보존·추후 결정 마킹) / 초안 모드 안전판 4 / 단계 릴레이 표·중복 금지 / 이전 결론 대조·소급 수정 금지 / 화면 SoT 이동 / 확인 질문 4+표시 3종 / mvp/ 산출물·vN 금지·handoff 동결 / ADR 단일 파일 / 매 단계 /clear 권장 / 어휘 swap 절차 / 단계 진입 평가·7단계 순서 잠금

**new-task/SKILL.md**: 브랜치=작업 단위 / fork 프로토콜 / 안전 검사(detached·working tree·미머지 PR 권한별) / main 싱크 필수 / 옛 브랜치 정리 3갈래 / type·topic 추론 규칙 / 이름 충돌 로컬+원격 확인·suffix 재시도 / 보고 양식 / 안 하는 것 7개

**project-init/SKILL.md**: 파일 복사 배포·payload 미러 / 전제 3 / 원본 찾기·검증 4단계(어긋나면 중단) / 스탬프 기록 / 모드 판별 / 신규 8단계(인터뷰→CLAUDE→AGENTS→복사→훅 병합→폴더→스탬프→안내) / 복사 예외 셋 / 동기화 7단계(main이면 멈춤+예외 하나·소유물 교체·로컬 수정 판별·CLAUDE/AGENTS 병합·마커 구역 한정) / 안 하는 것 5개

**rewind-task/SKILL.md**: wip 되돌리기 3방법(A 파일/B 새 가지/C 되감기) / fork 프로토콜 / main이면 두 갈래(PR wip 복구 vs revert 안내) / 후보 표 필수·20개 절단 명시 / 지운 브랜치는 refs/pull에서 / 백업 태그 필수·로컬만 / A는 staged로·자동 커밋 금지 / C는 원격 확인 후 / force push 절대 금지 / 안 하는 것 9개

### 3회차 인덱스

**1-user-story**: 게이트 아님 / 산출물 한 파일 / 입력 4개 인터뷰(1·2는 CLAUDE.md로 선채움) / 확정 전 위임 금지 / user-scenario-writer 위임 명세 / 리뷰 3요소 / 체크 4 / /clear 권장 / `# 입력 (확정)` 섹션

**2-information-architecture**: 게이트 아님 / 빠진 화면 없는 목록이 목표 / 일곱 갈래 훑기 / 6개 절 초안 / MVP 포함만 O·미룬 화면 버튼 표 / 자가 점검·재작업 2회 / 체크 7(고아 0·막다른 골목 0 등) / 인벤토리 표 7칸 / 3단계가 완전성+정서 함께 씀·이후 1세대 기록

**3-prototype**: 목업 vs 프로토타입 용어 / 다섯 스텝·작업 모드 표 / 인벤토리 요약부터·X면 2단계 복귀 / Claude Design 호출은 사용자(모드·파일 2개 원문 첨부·권장 프롬프트·zip 6개·재추출 문안·백엔드 못 만듦) / handoff 규칙(이름 그대로·1세대 기록·standalone만 예외) / 스택 선택 인터뷰(RN 방향만·대비 작업 금지) / 고정 core·최신 조합 조사·force 금지·버전 문서에 안 박음 / Next.js 16 CLAUDE.md 바꿔치기 사고·예방책 / Supabase 자리만 / 마이그레이션 5규칙(로컬스토리지 등) / grep 0건 함정 / 디코드는 메인이 / design-system 준수 / SoT 코드 이동 / 관문 ①② / 배포·noindex·사람 클릭 / 순환은 코드만·재배포 / 체크 18

**4-demo-validation**: 통과 기준① / 조사는 5단계로 미룸 / 운영자 모드·frame / 출처 4분류·대상수 / 질문지 AI 생성·맘 테스트·수정 요청 검토 / 1부→2부 순서 강제(닻 내림) / 강도표 ★ / 데모는 설명 없이·Pull은 자발 발화 / 구조적/미세·수렴 조건 / go/no-go·최종 확정 4개·CLAUDE/AGENTS 둘 다 갱신 / no-go면 같은 폴더 v2 (※모순-1) / 체크 13

**5-market-research**: 게이트 아님 / 0번 경쟁자 필수 / deep-research 요금 확인·라이트 기본 / 표본 정직성 / 강도 4등급·해자 5·"없음" 의심 3갈래 / 차별화 축 9(※모순-4) / YC 시뮬 선택 / 확정 금지·소급 수정 금지 / 체크 7

**6-mvp-build**: 목표 5·SoT 책임·안 하는 것 7·SEO는 여기서 / 환경 2단·분할 금지 / 작업 순서 5·RLS 필수·threat-model / 범위 가드(화면 추가 금지 ※모순-3) / Docker·CLI 3종 설치·하드웨어 / 마이그레이션 ①~⑧(파일 정본·search_path·검증 3시점·로컬 못 재는 5·실데이터 실패·자동 안 올라감+Secret 3+게이트·백업·reset 구간) / SEO·베타 공유·퍼널 5종·에러 관측 / 배포·실결제·재작업 2회 / 체크 17

**6-mvp-build-auth-consent**: 법률 자문 아님 / 필수/선택 판별 / 필수만이면 고지문("동의 간주" 금지) / 선택이면 셋(분리·거부 가능·nullable) / 소셜은 가입·로그인 구분 못 함 / 인증 뒤 신규만 온보딩 / 로그인 앞 체크박스 막다른 길 / 증적은 우리 DB / 동의 시각·버전 칸 / 약관 페이지 4규칙

**7-mvp-launch**: 통과 기준② / 순서가 생명·기준 선동결 / 이중 채널 필수 / 확정 전 광고 금지 / go 선은 인터뷰 모드 / 박을 4개·frozen / 소재는 초안 모드·집행은 사용자 / 측정 중 룰 4 / 판정은 사람·3분기 / production 졸업은 사업 단계 / 새 아이디어는 새 프로젝트 (※모순-1) / 체크 7

**design-system references**: add-a-token(semantic에만·이름은 의도·값은 foundation 참조·기존 커버 시 추가 금지) / bootstrap(무대 장치 제거·3층 구축·범용 복사·인벤토리 색인·frame 예산·AGENTS adapter 기록·다크모드 대비) / component-taxonomy(역할 6·범용은 표준 영어명·정본+동의어·BEM·결정 트리·인벤토리 형식·이식성) / font-loading(조각화 원리·FOUT≠CLS·패밀리는 foundation·결정표 next/font/local 금지·관문 3) / layout-frames(용어 8·frame-first 4단계·셸 3분류·카드 vs 행·여백 한 겹·플랫폼별·반응형 계약(※모순-2)·인벤토리 위치는 AGENTS.md) / naming-taxonomy(신규만 적용·문법·유형 14·표면 위계·on- 강제·radius)

---

## 4회차 — 교차 검토 (보고서·인덱스만 읽고 층 간 대조)

### 새로 찾은 층 간 중복 (기잡힘 제외)

- **① design-system 스킬 ↔ references — 규칙 4~5개가 두 층에 통째로.** frame-first(SKILL ↔ layout-frames) / 인벤토리 등록(SKILL ↔ component-taxonomy ↔ bootstrap) / semantic만 참조·원시값 금지(SKILL 철칙 1~2 ↔ add-a-token) / 동심원 radius(SKILL ↔ naming-taxonomy). 2회차는 SKILL만, 3회차는 references만 봐서 생긴 사각지대. 원문 확인 필요 — SKILL 쪽이 요약+포인터인지 전문 복붙인지에 따라 축약 여지가 갈린다. done-task↔git-workflow(G-3·G-4)와 같은 처방 후보.
- **② "화면 검증은 사람 몫"의 grok-delegation 사본** — 3회차 [B-7]에도 1회차 ⑯에도 안 들어간 누락 사본. 처리 여부는 결정 D5에 종속.
- **③ 재위임 금지가 3층에** — CLAUDE.md(상시) ↔ delegation-integrator(에이전트) ↔ grok-delegation(스킬). 원문 확인 필요 — grok 쪽은 "그록에게 시키는 지시"라 대상이 다를 수 있다.
- **④ fork 프로토콜이 4벌** — git-flow.md(에이전트층)까지 넣으면 2회차 [B-2]의 3벌이 4벌이 된다. 원문 확인 필요.
- **⑤ `grok inspect` 실측이 두 층에** — CLAUDE.md(1회차 ④의 이동 대상) ↔ grok-delegation/sources.md. 이동 목적지를 README가 아니라 sources.md로 잡는 게 맞을 수 있다. 원문 확인 필요.
- **⑥ 소급 수정 금지·`/clear` 권장이 스킬층·참조층 양쪽에** — idea-to-mvp SKILL ↔ 5-market·1-user-story. 다른 단계 파일에 더 있는지 원문 확인 필요.
- **⑦ "1세대 기록/handoff 동결"이 두 층 합계 13회** — SKILL 4회([B-10]) + 3-prototype 9회([B-1]) + 2-IA 1회. 정의를 한 곳(3-prototype §2.3)에 못 박고 나머지는 포인터가 자연스럽다. 결정 D1에 종속.

### 새로 찾은 층 간 모순 후보

- **[신-1] `vN 금지`(SKILL) ↔ `demo-validation-v2.md`(4-demo)** — 모순-1(레포 단위)과 뿌리는 같지만 산출물 파일명 규칙이 별도로 어긋난다. 모순-1을 "새 레포"로 정하면 자동 해소.
- **[신-2] 1회차 ⑨ 제안을 그대로 적용하면 안 된다** — ux-writing-reviewer의 SoT를 `mvp/information-architecture.md`로 못 박으면, 마이그레이션 후(SoT=앱 코드)에도 자동 발동하는 이 에이전트가 옛 문서 기준으로 화면 라벨을 되돌릴 수 있다. "SoT는 마이그레이션 전엔 IA 문서, 후엔 앱 코드"로 써야 한다. **다이어트가 아니라 동작 사고 예방.**
- **[신-3] "버전을 문서에 박지 마라"(3-prototype) ↔ reference.md의 0.2.1·줄번호 6곳** — 도메인이 다르면(프로젝트 스택 vs 외부 CLI) 모순 아님. 어느 쪽에도 경계가 안 적혀 있어 다음 사람이 줄번호를 규칙 위반으로 지울 수 있다. 원문 확인 필요.
- **[신-4] 모순-5("예외" 표현)의 사정권 확장** — 루트 AGENTS.md 검증 절 네 번째 항목 자체가 "예외"다. font-loading만 고쳐선 안 닫힌다. 원문 확인 필요.
- **[신-5] noindex를 거는 곳(3-prototype)은 있는데 푸는 곳이 없다** — 6-mvp-build SEO 절에 해제 문장이 있는지 원문 확인 필요. 없으면 색인이 영영 안 되는 구멍.

### 참조 없는 흩어짐 (한쪽만 고치면 어긋나는 자리)

- 인벤토리 위치: layout-frames는 "위치는 AGENTS.md"라는데 AGENTS.md.template엔 adapter 자리만 있다.
- 화면 SoT: ux-writing-reviewer / idea-to-mvp SKILL / 3-prototype / 6-mvp-build 네 곳이 서로 안 가리킨다 → [신-2] 시나리오.
- 프로젝트 정의 줄의 생애: project-init(생성·병합) → 1-user-story(선채움) → 4-demo(갱신) 릴레이인데 앞뒤 참조 없음. 4단계 갱신을 동기화가 덮을 수 있는지 원문 확인 필요.
- fork 보고 형식: git-flow.md "형식 준수" ↔ 형식 본문은 스킬 3개에.
- done-task §3-c CI 대기 ↔ project-init이 복사하는 ci.yml — 워크플로를 갈아끼우면 헛돈다.
- threat-model ↔ auth-consent — 민감정보·동의 증적이 서로 안 가리킨다.
- "재작업 2회" 상한이 2-IA·6-mvp-build에 각각 박혀 있고 정의처가 없다.
- markdown-style.md 앵커 규칙의 기호 처리 모호 — [C-1] 깨진 앵커가 그 산물.

### 사람 결정 목록 통합 (우선순위순)

| # | 결정 | 푸는 항목 | 추천 |
|---|---|---|---|
| D1 | "짧은 규칙은 위층, 이유·절차·경위는 아래층" 기준 확정 | 1회차 ②③④⑤ / 2회차 G 6건·B-3·B-4·B-9·B-11 / 3회차 B-4 / 4회차 ①⑤⑦ | (a) 층별 역할 고정. 단 "이동한 실측은 절대 삭제 금지"를 기준에 못 박고 시작 |
| D2 | 예외 인정 여부와 표기 방식 | 모순 5건(project-init 브랜치·new-task 커밋·미디어 쿼리·온보딩 화면·"예외" 표현)·[신-4] | (a) 기본은 예외 금지 — 규칙 문장을 넓게 다시 쓴다. 불가피한 데만 통일된 표기로 |
| D3 | 스택 3단계 고정 vs 6단계 선택 | 1회차 ① / 2회차 모순-2 | AGENTS.md.template 수정 — 사실상 버그 수정 |
| D4 | 팀원 경로 done-task 종료 위치 | 1회차 ⑥ / 2회차 모순-4 | 기준 문서를 "오너 경로면 main"으로 — 스킬 동작 변경은 위험 |
| D5 | 서브 에이전트가 프로젝트 CLAUDE/AGENTS를 받는가 | 1회차 ⑯ / 4회차 ②③④ | 실측 한 번으로 확인 후, 받으면 재기재 걷어내고 안 받으면 의도로 확정 |
| D6 | 요약표·색인성 중복 허용 여부 | 1회차 ⑪ / 2회차 B-5 / 3회차 B-3·B-6 | (a) 색인은 "§ 참조"만 — 손 sync는 언젠가 어긋난다 |
| D7 | 폐기 후 경로 + vN 명명 | 3회차 모순-1 / 4회차 [신-1] | "새 아이디어 = 새 프로젝트"(다수결)로 정하고 4-demo 428·596 수정 |
| D8 | 용어 풀이 괄호를 스킬 본문에 둘 것인가 | 2회차 A-2 등 | AGENTS.md 표기 규칙을 "사용자에게 말할 때만 푼다"로 좁힘 |
| D9 | 차별화 축 E 정의 | 3회차 모순-4 | 독립 결정, 뒤로 미뤄도 됨 |
| D10 | markdown-style 두 건 | 1회차 ⑬·⑭ | 나쁜 예는 유지, ①② 기호 처리는 추가 |
| D11 | 돌려봐야 아는 것 3건 | `/reload-plugins` 실존·scripts 폐기·sources.md URL | 확인 작업으로 묶어서 한 번에 |

### 총평

지울 분량 자체는 크지 않다. 진짜 이득은 **상시 로드층 10~12줄을 아래층으로 내리는 것**(매 세션 반복이라 복리)과, **D1 하나로 스킬층 G 6건 + 참조층 B 4건 + design-system 두 층 묶음까지 60~100줄을 한 규칙으로 정리하는 것**이다.

**결정 없이 바로 고칠 버그**: threat-model 글롭 4개(보안 룰 침묵), 7-mvp-launch 앵커, ux-writing-reviewer의 userflow.md·description(단 ⑨는 [신-2] 반영해 "전/후"로), git-flow description, auth-consent D-1·D-2, 5-market §6 제목, sources.md 빈 URL. 스택 서술(D3)과 done-task 종료 위치(D4)도 사실상 버그라 앞줄에.

새 발견 중 제일 값진 것: **[신-2]**(자동 발동 에이전트의 SoT 사고 위험) > **①**(design-system 두 층 사각지대) > **[신-5]**(noindex 해제 구멍).
