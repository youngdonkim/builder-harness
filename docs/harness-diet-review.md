# 하네스 다이어트 검토 보고서

작성일: 2026-09-28 · 브랜치: harness/instruction-docs-diet-review · 검토 방식: 5회 분할 정독 + 교차 검토

- 회차 구성 (상시 로드층 `AGENTS.md`·`payload/AGENTS.md.template`은 매 회차 기준 문서로 함께 읽힘):
  1. git 흐름 — new-task·done-task·ship-task·rewind-task + 훅 2 + settings-hooks.json + ci.yml + docs/git-workflow.md (2,401줄)
  2. 운영 스킬(project-init·harness-diet·transfer-ownership·deep-research) + 에이전트 5 + rules 2 + 템플릿 2 + docs/account-check.md + README.md (1,861줄)
  3. design-system 스킬·참조 7 + idea-to-mvp SKILL.md·1단계·2단계 (1,916줄)
  4. idea-to-mvp 3·4·5단계 + 6-0·6-1 (1,629줄)
  5. idea-to-mvp 6-2·6-3·7단계 (783줄)
- 판정 분류: A 일반 지식 중복(설명문만) / B 중복 서술(층 표기 필수) / C 죽은 참조(grep 근거 필수) / D 낡은 사실(근거 필수) / E 세부 과잉 / F 발동 불가 글롭 / G 층 이동(삭제 아님) / [모순](양쪽 원문 인용)
- 이 보고서는 **검토만** 한 결과다 — 실제 수정은 항목을 골라 따로 실행한다. 수정 때 철칙 셋: 실측·사고 원문 유실 0 / `payload/` 고치면 루트 `.claude/` 미러 복사 / 수정 후 잔재 grep.

---

## 1회차 — git 흐름 (스킬 4 + 훅 2 + 훅 설정 + CI + git-workflow)

### 요약

**정독한 파일 (11개, 못 읽은 파일 없음)**
- 기준 문서: `AGENTS.md`, `payload/AGENTS.md.template`
- 이번 회차: `payload/.claude/skills/new-task/SKILL.md`, `payload/.claude/skills/done-task/SKILL.md`, `payload/.claude/skills/ship-task/SKILL.md`, `payload/.claude/skills/rewind-task/SKILL.md`, `payload/.claude/hooks/auto-wip-commit.sh`, `payload/.claude/hooks/no-main-push.sh`, `payload/.claude/settings-hooks.json`, `payload/.github/workflows/ci.yml`, `payload/docs/git-workflow.md`
- 미러 대조: 루트 `.claude/`의 스킬 4개와 훅 2개는 payload와 `diff -q` 결과가 전부 같음. 루트 `docs/git-workflow.md`·`docs/account-check.md`도 payload와 같음.

**분류별 항목 수**

| 분류 | 수 |
|---|---|
| A 일반 지식 중복 | 0 |
| B 중복 서술 | 11 (같은 층 삭제·축약 후보 7, 의도 확인 필요 4) |
| C 죽은 참조 | 0 (참조는 전부 살아 있는 것 확인) |
| D 낡은 사실 | 5 |
| E 세부 과잉 | 0 |
| F 발동 불가 | 해당 없음 (이번 회차에 rules 파일 없음) |
| G 층 이동 | 0 |
| [모순] | 4 |

**C가 0인 근거 (확인 명령 결과)**
- 에이전트: `ls payload/.claude/agents` 결과 git-flow.md, ux-writing-reviewer.md 둘 다 있음.
- 모델: `grep "^model" git-flow.md` 결과 `model: sonnet`. 스킬 본문의 "(sonnet)"과 맞음.
- Skill 도구: git-flow의 `tools: Bash, Read, Grep, Glob`에 Skill이 없음 → ship-task의 "fork 안에는 Skill 도구가 없다"와 맞음.
- 문서: `ls payload/docs` 결과 account-check.md, git-workflow.md 있음.
- 6-3 문서: `find` 결과 `payload/.claude/skills/idea-to-mvp/references/6-3-backend-deploy.md`가 있고, 그 안에 `### 2.3 스모크 테스트`가 있음.
- git-workflow 절: §2, §2.5, §8.3이 헤더로 있음.
- 스킬 내부 절: §엣지 — 이름 충돌, §호출 패턴, `## 안 하는 것 (의도적)`, §1-0, §2.5, §3-a가 전부 있음.
- `/simplify`: 클로드 코드 내장 스킬이라 저장소에 파일이 없는 게 정상.

### 파일별 항목

#### payload/.claude/skills/new-task/SKILL.md

**항목 1**
- 위치: §1-c `gh pr status 2>/dev/null` / `gh api repos/{owner}/{repo} --jq` / §3 `gh pr list --head <branch>` (보조로 61·68·114줄). frontmatter `allowed-tools: Bash(git *) Bash(gh *)`도 같이 걸림.
- 분류: D
- 근거: gh 인증은 지금 `.env.cli`의 `GH_TOKEN`으로 한다. 그런데 이 스킬의 gh 명령에는 토큰 로더가 안 붙어 있음.
  - `grep -c GH_TOKEN` 결과: new-task 0, rewind-task 0, ship-task 14.
  - `payload/docs/account-check.md` gh 항목: "부르는 모양은 한 줄로 고정한다 — `env GH_TOKEN=... gh <명령>`", "파일이 없으면 … 저장된 계정으로 돈다".
  - 지금 상태면 전역 활성 계정으로 도니까, 권한 판정(팀장/팀원)이 다른 소유 계정 기준으로 나올 수 있음.
- 제안: 수정안. 세 명령 앞에 ship-task §1-0과 같은 로더 줄을 단다. 본문에 "gh 호출은 ship-task §1-0과 같은 토큰 로더를 같은 셸 호출 앞에 단다" 한 줄. `allowed-tools`에 `Bash(env GH_TOKEN=*)` 추가.

**항목 2**
- 위치: "**호출은 클로드가 직접 한다.** main에 서 있는데…" (15줄)
- 분류: B (스킬층 fork 본문 ↔ 상시층) — 의도 확인 필요
- 근거: 같은 내용이 템플릿 §브랜치에 있음: "`/new-task`·`/done-task`는 클로드가 직접 호출한다 — … 두 스킬 모두 [결정 필요]가 돌아오면 클로드가 판단해 결정을 담아 재호출한다". `context: fork` 스킬 본문은 git-flow 에이전트한테 넘어감. 메인에게 하는 말인데 메인은 이 본문을 못 볼 가능성이 큼.
- 제안: 삭제 후보(의도 확인 뒤). 다만 뒷부분 "PR 없는 로컬 브랜치 삭제처럼 되살릴 수 없는 선택은 애매하면 보존 쪽으로"는 상시층에 없는 내용이라 남긴다.

**항목 3**
- 위치: 엣지 케이스 표의 행들. "PR이 머지 안 됐는데 새 작업 가야 함 — 나는 팀원", "…나는 팀장", "권한 조회(`gh api .../permissions`) 실패", "PR 없는 local 브랜치를 "태그 박고 삭제"로 결정", "새 브랜치 이름이 로컬에 이미 있음", "…원격(GitHub)에 이미 있음", "suffix 10회…" (263~269줄)
- 분류: B (같은 파일, 같은 층)
- 근거: 정리표 칸에 본문 §1-c, §3, §엣지 — 이름 충돌의 판정과 이유가 다시 적혀 있음. 확정 정책은 "정리표는 § 참조만".
- 제안: 축약안. 처리 칸을 짧은 결론과 § 참조로 줄인다 — 팀원 행 → "묻지 않고 진행 (§1-c)", 태그 행 → "태그 후 삭제 (§3)". "working tree 변경이 새 작업과 무관 → stash 권장" 행은 본문에 없는 내용이라 그대로.

#### payload/.claude/skills/done-task/SKILL.md

**항목 4**
- 위치: 절차 2-b "`git log origin/main..HEAD --format=%s | grep`…"와 2-c "변경이 주석·문구 한 줄처럼 자잘하면…"
- 분류: [모순] (스킬층 ↔ 상시층)
- 근거: 양쪽 원문 —
  - 템플릿·루트 AGENTS §브랜치: "done-task는 simplify 판단을 스스로 한다 — `src/`를 고친 브랜치면 스킬 안에서 `/simplify`를 먼저 돌리고 ship으로 넘어간다."
  - done-task 2-b: "하나라도 있으면 → 4로 (이미 검토함)" / 2-c: "자잘하면 … 스킵으로 정하고 4로"
  - 상시층은 src를 고치면 무조건 돌린다고 읽히고, 스킬은 이미 검토했거나 자잘하면 건너뛴다.
- 제안: 수정안. 상시층 문장을 정확하게 다시 쓴다(이동이 아니라 문구 수정). 예: "`src/`를 고친 브랜치면 스킬이 기준대로 `/simplify`를 먼저 돌릴지 정하고 ship으로 넘어간다."

#### payload/.claude/skills/ship-task/SKILL.md

**항목 5**
- 위치: §1-0 "**소프트 (원격이 이미 있을 때)**: **위에서 정한 gh 계정**이 표와 다를 때…막지 말고 §4 완료 보고에 한 줄 남긴다"
- 분류: [모순] (스킬층 ↔ 루트 상시층)
- 근거: 양쪽 원문 —
  - 루트 `AGENTS.md` §소유와 계정: "push·PR 전에 gh가 도는 계정(`gh api user --jq .login`)이 표와 일치하는지 대조하고, 다르면 진행하지 않고 멈춰 보고한다 (`ship-task` §1-0 검문이 이 표를 읽는다)."
  - ship-task: "로컬 전환으로는 못 고치니 막지 말고 §4 완료 보고에 한 줄 남긴다".
  - `grep -n "멈춰 보고" AGENTS.md` → 11줄. `grep -n "막지 말고" ship-task` → 63줄.
- 제안: 수정안(사람 결정 필요). 루트 AGENTS 문장을 "원격이 없을 때는 멈추고, 이미 있으면 ship-task §1-0 기준을 따른다"로 고치거나, 개인 소유 저장소는 하드로 멈추는 게 맞다면 그 뜻을 AGENTS 쪽에 정확히 적는다.

**항목 6**
- 위치: §1-0 소프트 규칙 안의 "— 로컬 전환이라 되돌리기 쉽고, §4 완료 보고에…"
- 분류: [모순] (같은 파일 안 + 참조층)
- 근거: 같은 절 하드 ②의 근거 "토큰을 안 걸면 CLI 활성 계정은 전역이라 다른 소유의 프로젝트를 오가면 바뀌어 있다" / `docs/account-check.md` 원칙 ② "전환은 컴퓨터 전체에 걸리는 전역 설정이라". `gh auth switch`는 전역인데 여기서는 "로컬 전환"이라 부름.
- 제안: 수정안. "로컬 전환이라 되돌리기 쉽고" → "다시 전환하면 되돌릴 수 있고(전역 설정이라 다른 프로젝트에도 걸린다)". 규칙(전환한 뒤 진행)은 그대로.

**항목 7**
- 위치: "**이 스킬의 호출자는 메인 세션의 done-task 스킬이다** — 사용자의 ship 신호를 받은…" (27줄)
- 분류: B (같은 파일, 같은 층)
- 근거: 같은 파일 11줄 "메인 세션의 `done-task` 스킬이 부르는 내부 스킬이다"와 17줄 "호출 경로는 사용자 ship 신호 → done-task → 이 스킬이다… done-task가 simplify 판단을 끝낸 뒤 이 스킬을 부른다"가 이미 같은 말. 이 문단에만 있는 정보가 없음.
- 제안: 삭제.

**항목 8**
- 위치: 네 군데 — "**사용자의 ship 신호 = 승인, 호출은 done-task가 대행**…"(29줄) / §2-b 끝 "초안이 곧 확정본이다 (사용자의 ship 신호가 이미 승인…"(329줄) / §사용자 응대 톤 "PR title·body는 별도 확인 없이 초안 그대로 사용…"(513줄) / 안 하는 것 "❌ PR title·body 별도 확인…"(574줄)
- 분류: B (같은 파일, 같은 층)
- 근거: "ship 신호가 승인이라 PR 제목·본문은 초안 그대로"가 네 번 나옴. 19줄까지 치면 다섯 번.
- 제안: 축약안. 29줄은 그대로(정본). 329줄 → "초안이 곧 확정본이다 (§호출 인자 아래 승인 규칙) — 바로 §2.5로". 513줄은 해당 문장을 뺀다. 574줄 → "❌ PR title·body 별도 확인 — 29줄 승인 규칙".

**항목 9**
- 위치: "**호출 경로는 사용자 ship 신호 → done-task → 이 스킬이다.**…"와 "**호출 이후의 [결정 필요]는 메인 세션(done-task)이 판단한다.**…" (17·19줄)
- 분류: B (스킬층 fork 본문 ↔ 상시층·done-task) — 의도 확인 필요
- 근거: 17줄은 템플릿 §브랜치 "done-task는 **사용자가 화면을 확인하고 보내라고 한 뒤에만** 부른다…"와 같음. 19줄은 done-task 5번과 같음. 이 스킬은 `context: fork`라서 메인에게 하는 이 말은 git-flow 에이전트만 읽음.
- 제안: 의도 확인 뒤 축약안. git-flow 에이전트에게 필요한 건 "이 스킬이 돌 때는 이미 승인이 끝난 상태"라는 사실 한 줄뿐.

**항목 10**
- 위치: §4 완료 보고의 오너 경로(442~450줄)와 팀원 경로(473~481줄) 두 템플릿 머리 부분 "[§1-0 계정 검문에서 남길 줄이 있으면…", "✓ [§1.6 판정 결과 한 줄…", "✓ [§1.8 스모크를 돌렸으면…"
- 분류: B (같은 파일, 같은 층)
- 근거: 두 경로 템플릿에 계정 검문 줄 4종, §1.6 판정 2종, 스모크 2종이 글자 그대로 두 번 들어 있음.
- 제안: 축약안. "공통 머리줄" 블록을 한 번만 두고, 두 경로 템플릿은 "[공통 머리줄]"로 시작.

**항목 11**
- 위치: 엣지 케이스 표 행 "simplify 재호출 감지", "simplify 표식 뒤에 `src/**`가 또 바뀜", "`/simplify`가 검토했는데 고칠 게 없었음", "`supabase/migrations/`에 새 파일 없음"부터 "`git rev-parse main origin/main`의 두 sha가 다름"까지 (531~549줄) / 안 하는 것 "❌ simplify 게이트 재발동 — 표식 이후…"(573줄), "❌ 자동 경로에서 리베이스 — origin/main 동기화는…"(582줄)
- 분류: B (같은 파일, 같은 층)
- 근거: 정리표와 목록 칸에 §1.5, §1.6, §1.7, §1.8, §2.5, §3-d의 판정과 이유가 다시 적혀 있음. 582줄의 "예행 검사가 보는 최종 상태와 실제 동작이 어긋나…"는 §1.6과 `docs/git-workflow.md` §8.3에 이미 있음.
- 제안: 축약안. 표 처리 칸은 "결론 + (§x)"만. 582줄 → "❌ 자동 경로에서 리베이스 — 합치기로만 한다 (§1.6)". 본문에 없는 내용이 있는 행(523~526, 529~530 — "이미 PR 있음", "push 후 PR 생성 실패", "squash merge 시 conflict", "branch protection", working tree 두 행)은 그대로.

#### payload/.claude/skills/rewind-task/SKILL.md

**항목 12**
- 위치: §4-b (A) "이 상태에서는 auto-wip-commit 훅이 "이미 대기 중인 파일이 있으면 건드리지 않는다"는 규칙 때문에 **다음 턴 자동 저장이 멈춘다.**"(236줄) / §5 "대기 상태로 두면 다음 턴 자동 임시 저장(wip 커밋)이 건너뛰어져."(286줄) / 연관: "되살린 파일은 **커밋 대기 상태(staged)로 남는다.**"(235줄), 안 하는 것 "❌ 자동 커밋 — (A) 방법으로 되살린 파일은 대기 상태로 남긴다"(333줄)
- 분류: D
- 근거: `payload/.claude/hooks/auto-wip-commit.sh` 33~39줄 주석 "staged 파일 가드 제거 (2026-08-01) … stage 상태와 무관하게 변경 전부를 wip 커밋에 담는다". 코드도 362줄에서 무조건 `git add -A`. `grep -n "staged" auto-wip-commit.sh` 결과는 가드 제거 주석과 `git restore --staged`(시크릿 제외용)뿐. 지금은 되살린 파일이 턴이 끝날 때 훅이 자동으로 커밋함.
- 제안: 수정안(사람 결정 필요). 236·286줄의 "자동 저장이 멈춘다/건너뛰어져" 삭제 → "이 턴이 끝나면 훅이 되살린 파일을 wip 커밋으로 박는다 — 싫으면 백업 태그로 되돌린다". 235·333줄은 결정에 따라.

**항목 13**
- 위치: §사용자 응대 톤 "톤은 AGENTS.md의 응답·문서 작성 원칙을 따름(친근한 반말, 조어 금지, 전문용어는 `번역(외국어 표기)`로 풀어 쓰기)" (294줄)
- 분류: B (스킬층 ↔ 상시층) — 의도 확인 필요
- 근거: 괄호 안은 템플릿 §응답·문서 작성의 요약. 형제 스킬은 참조만 함: new-task 254줄 "톤은 `AGENTS.md 응답·문서 작성`을 따름", ship-task 513줄도 같음. 서브 에이전트는 AGENTS.md를 자동으로 받음.
- 제안: 축약안. 괄호를 지워 형제 스킬과 같은 한 줄로.

**항목 14**
- 위치: "이 스킬은 `context: fork`로 … 결정 지점은 [결정 필요] 반환 → 메인이 사용자에게 확인 → **사용자가 직접**…" (16줄)
- 분류: B (스킬층 fork 본문 ↔ 상시층) — 의도 확인 필요
- 근거: 메인에게 하는 말("메인이 사용자에게 확인")이 fork 본문에 있어 git-flow 에이전트만 읽음. "사용자 전용"은 템플릿 §브랜치 "`/rewind-task`만 사용자 전용이다"와 같음. 같은 파일 안에서도 안 하는 것 "❌ Claude 자동 invoke — `disable-model-invocation: true`"(337줄)와 겹침.
- 제안: 의도 확인 뒤 축약안. 337줄을 지우고 16줄 하나로.

**항목 15**
- 위치: 엣지 케이스 표 "현재 브랜치가 main", "되감으려는 브랜치가 이미 GitHub에 올라가 있음", "후보가 20개 넘음" 행(305·309·313줄)과 안 하는 것 "❌ 강제 밀어넣기(force push) — 어떤 경우에도 안 함"(331줄)
- 분류: B (같은 파일, 같은 층)
- 근거: 표 칸이 §1-c, §4-b (C), §2-a 본문을 다시 적은 것. 331줄은 §사용자 응대 톤 "**강제 밀어넣기(force push)를 절대 권하지 않는다.**"(298줄)와 겹침.
- 제안: 축약안. 표 칸은 "(§1-c)"처럼 § 참조만. "브랜치에 wip이 0개 → §2-b 전환" 행은 본문에 없는 내용이라 그대로.

#### payload/.claude/hooks/auto-wip-commit.sh

**항목 16**
- 위치: 머리 주석 "# 커밋 메시지: wip: <last user msg 힌트> — <파일1>, <파일2> 외 N개 (+X -Y)" (17줄)
- 분류: D (주석과 코드가 안 맞음)
- 근거: `grep -n "shortstat\|(+X -Y)"` 결과: 17줄 주석과 383줄 `stat_line=$(git diff --cached --shortstat …)`. 실제 형식은 `(N files changed, X insertions(+), Y deletions(-))`. rewind-task 112줄도 이 형식.
- 제안: 수정안. 주석을 "… 외 N개 (N files changed, X insertions(+), Y deletions(-))"로.

**항목 17**
- 위치: 머리 주석 Skip 조건 "#   3. 변경 없음            → 빈 커밋 방지" (10줄)
- 분류: D
- 근거: 같은 파일 342~359줄(6번)에서 변경이 없어도 `/simplify` 턴이면 `git commit --allow-empty -m "wip: /simplify — 변경 없음"`으로 빈 커밋을 만듦. 72~77줄 이력 주석도 이걸 도입했다고 적음.
- 제안: 수정안. "3. 변경 없음 → `/simplify` 턴이 아니면 커밋 안 함 (6번)".

#### payload/.claude/hooks/no-main-push.sh
해당 항목 없음. 주석의 `docs/git-workflow.md` 참조는 `ls payload/docs`, `ls docs` 둘 다에 있는 것 확인.

#### payload/.claude/settings-hooks.json
해당 항목 없음. 등록된 두 훅 파일이 있고, `project-init/SKILL.md` 108·116줄이 이 파일을 병합 원본으로 부르는 것 확인.

#### payload/.github/workflows/ci.yml

**항목 18**
- 위치: "# Supabase 환경 변수(NEXT_PUBLIC_SUPABASE_URL 등) 없이 확인 완료:" / "# src/lib/supabase.ts는 함수 호출 시점에만 값을 읽고…어디서도 import되지 않아" (39~42줄)
- 분류: D
- 근거: 한 프로젝트의 한 시점 스냅샷이 payload에 남은 것. `ls payload/src` → No such file or directory. `grep -rn "src/lib/supabase" payload` → 이 주석 한 줄뿐. 하네스 6단계(`6-2-backend-auth.md` 167줄)는 `lib/supabase/`에 `proxy.ts`·`client.ts`·`server.ts` 세 파일을 받아 쓰게 해서, 6단계 이후 프로젝트에서 "supabase.ts 파일 / 어디서도 import 안 됨 / env 없이 빌드 통과"가 성립한다는 보장이 없음.
- 제안: 수정안(사람 결정 필요). "5단계까지는 Supabase 클라이언트를 import하는 코드가 없어 env 없이 빌드가 통과한다(실측 당시 기준). 6단계 이후 빌드가 env를 요구하면 자리표시자 env를 여기 추가한다"처럼 조건으로 다시 쓴다. 실측 사실 자체는 지우지 않는다.

#### payload/docs/git-workflow.md

**항목 19**
- 위치: §1 "- **`done-task`**: 안에서 simplify 판단을 먼저 하고 … — 네가 부르는 이름은 여전히 done-task뿐이다." (23줄)
- 분류: [모순] (같은 문서 안 + 상시층)
- 근거: 같은 문서 33줄 "`done-task`는 **네가 "보내줘"라고 말한 뒤에만** 부른다" / 템플릿 §브랜치 "`/new-task`·`/done-task`는 클로드가 직접 호출한다". 23줄은 사용자가 done-task를 직접 부르는 것처럼 읽힘.
- 제안: 수정안. "— 네가 부르는 이름은 여전히 done-task뿐이다" → "— 네가 알아둘 이름은 done-task뿐이다".

**항목 20**
- 위치: §3 "이제 PR마다 CI(자동 검사 — push된 코드가 빌드·린트를 통과하는지 GitHub이 자동으로 돌려보는 것)가 돌고" (106줄)
- 분류: B (같은 문서, 같은 층)
- 근거: §1 24줄에 같은 풀이가 글자 그대로 있음. 전문용어 풀이는 처음 나올 때 한 번이면 됨.
- 제안: 삭제(106줄의 괄호 풀이만). "이제 PR마다 CI가 돌고"로.

### 확신 없어 뺀 것

- **auto-wip-commit.sh 55~57줄 "ship-task의 simplify 게이트(직전 커밋 제목에 "simplify"가 있는지로 판정)"**: 지금 게이트 기준(맨 앞 `/simplify` 표식 정규식)과 다르지만, 날짜가 붙은 이력 항목이라 당시 상태를 적은 것이라 D로 안 올림.
- **auto-wip-commit.sh 20~92줄 수정 이력 전체를 `docs/design-notes.md`로 옮기기**: `docs/eval-scenarios.md` 24번이 "수정 이력 주석 2026-09-05 항목"을 직접 가리킴. 전부 실사고 원문이라 각 문서에 남는다는 정책에 해당.
- **ship-task §1.5 "왜 재발동이 없나 (2026-08-20)"를 참조층으로 옮기기(G)**: "사고가 두 번 났다"는 실사고 기록이라 이동 후보에서 뺌.
- **ship-task 388·498·501줄 "`/done-task` 재호출해줘"**: 사용자에게 done-task를 직접 치라고 안내하는 문구지만, 직접 치는 것 자체가 명시적 ship 신호라 "클로드가 호출한다"와 모순은 아님.
- **rewind-task 307줄 "`git branch -D`는 … 못 살린다"와 new-task 135줄 "되살릴 방법이 사실상 없으니"**: HEAD reflog에는 남을 수 있어 과장된 면이 있으나 안전 쪽으로 쓴 문구고 저장소 상태 문제가 아님.
- **태그 이름 규칙이 셋인 것** (new-task `archive/`, rewind-task `rewind-backup/`, git-workflow §6 예시 `backup/before-revert-`): 용도가 달라 모순으로 안 봄.
- **git-workflow §1 31·33줄과 템플릿 §브랜치 53·55줄의 겹침**: 사람이 읽는 참조 문서용으로 일부러 둔 설명이라 판단.
- **ship-task §1.7 순서 규칙 두 줄과 템플릿 "배포와 마이그레이션은 서로 안 기다린다"(106~109줄), ci.yml 주석의 겹침**: 층마다 쓰임새(fork 실행 중 판정, 상시 안내, CI 주석)가 달라 의도된 이중 배치로 봄.
- **ship-task §3-d "…를 하는 이유" 불릿 5개(E 후보)**: 본문에 이유가 적혀 있어 E 기준상 제외.
- **git-workflow §6.2 reflog 기본 보존 기간(90일/30일)의 A 여부**: 사용자가 읽는 문서라 AI 지시문 기준인 A를 적용하지 않음.
- **done-task 2-a "src 폴더가 없는 프로젝트면 코드 폴더로 대체"와 ship-task §1.5 `grep '^src/'` 고정**: ship-task 쪽은 안전망이라 기준이 좁아도 모순은 아님.

### 사람이 정해야 할 것

1. **계정 불일치 때 멈출지 여부 (항목 5)**: 루트 AGENTS의 "다르면 멈춘다"와 ship-task의 "원격이 이미 있으면 막지 않고 보고"가 맞선다. 개인 소유 저장소에서도 ship-task 기준을 따를지, 루트만 하드로 멈출지.
2. **rewind-task (A) 방식의 의도 (항목 12)**: 훅이 되살린 파일을 턴 끝에 자동 커밋하는 지금 동작을 받아들일지. 받아들이면 스킬 문구만 고침. "커밋은 사용자 몫"을 지키려면 훅이나 스킬 쪽 장치가 필요.
3. **done-task 3번의 `git add -A && git commit`**: 이 수동 커밋은 auto-wip-commit 훅의 시크릿 파일 제외 안전망을 거치지 않음(훅 12~15줄). 선택지: 같은 제외를 스킬에도 적는다 / 제외된 경로만 add한다 / 지금대로.
4. **fork 스킬 본문 안에 메인에게 하는 말 (항목 2·9·14)**: fork 에이전트의 맥락 설명으로 남길지, 상시층·done-task에 이미 있으니 지울지.
5. **ci.yml의 env 없는 빌드 주석 (항목 18)**: 조건문으로 다시 쓸지. 아니면 6단계 이후 프로젝트에서 env 없이 빌드가 실제로 통과하는지 먼저 확인.
6. **new-task·rewind-task에 GH_TOKEN 로더 적용 (항목 1)**: `allowed-tools` 추가까지 포함해 적용할지.

### 규칙 인덱스 (판정 없이)

> 기준 문서 `AGENTS.md`·`payload/AGENTS.md.template`은 대조용으로 읽음. 그 둘의 인덱스는 상시층이라 여기서는 뺌.

#### payload/.claude/skills/new-task/SKILL.md
- fork(git-flow, sonnet)로 실행, 결정 지점은 [결정 필요]로 반환한 뒤 args에 결정을 담아 재호출.
- 호출은 클로드가 직접. main에서 작업 요청이 오면 묻지 않고 부름. [결정 필요]는 클로드가 판단해 재호출. 되살릴 수 없는 선택은 애매하면 보존 쪽.
- §호출 인자(`$ARGUMENTS`) 섹션은 삭제 금지. 진입 가정: git repo. done-task 직후 사용과 첫 사용 둘 다 정상.
- §1: 1-a detached HEAD면 중단 / 1-b 워킹트리 더러우면 args 결정 적용, 없으면 [결정 필요](커밋·stash·중단) / 1-c 현재 브랜치 PR 미머지면 권한 조회 — 팀원(admin·maintain 둘 다 false)이거나 조회 실패면 묻지 않고 진행하고 §5에 PR 대기 줄, 브랜치 보존; 팀장이면 "그래도 진행" 지시 없을 때 [결정 필요]; main이면 1-c 건너뜀.
- §2: `git switch main` + `git pull origin main` 생략 금지. switch 실패·pull 충돌이면 중단.
- §3: `git remote prune origin` 후 로컬 브랜치마다 머지된 PR 조회. 머지된 PR 브랜치는 자동 삭제(`-D`, 원격도). 미머지 PR 브랜치는 보존, 명시 지시 때만 강제 삭제. PR 없는 로컬 브랜치는 [결정 필요](보존·삭제·`archive/` 태그 후 삭제).
- §4: 4-a args 없으면 [결정 필요], 명시 패턴이면 그대로 / 4-b type은 키워드 표(feat·fix·chore·harness·refactor·content·docs), topic은 kebab-case 30자 이하 / 4-c 생성 전 로컬·원격 이름 충돌 확인(출력 유무로 판정), 충돌 시 `-2`~`-11`, 다 겹치면 [결정 필요] / 시작 sha 보고.
- §5 준비 완료 보고 형식. 톤은 AGENTS.md §응답·문서 작성. 엣지 케이스 표 10행. 호출 패턴 6종.
- 안 하는 것: PR 자동 머지, commit·push 자동화(1-b (a) 지시만 예외), 다른 base, 생성 전 확인받기, PR 없는 브랜치 자동 삭제, 미머지 브랜치 자동 삭제.

#### payload/.claude/skills/done-task/SKILL.md
- 메인 세션에서 돎. 사용자가 "보내줘"라고 한 뒤에만 클로드가 부름. git 작업은 ship-task에 넘김. 몫은 simplify 판단 하나.
- 1 main·detached면 중단 / 2-a `git diff origin/main...HEAD --stat -- src` 비면 4로(src 없으면 코드 폴더) / 2-b 표식 커밋 있으면 4로 / 2-c 자잘하면 스킵하고 4로, 그 외 3으로.
- 3 Skill 도구로 simplify 실행·반영 후 같은 턴에 직접 커밋(`wip: /simplify — 요약`, 변경 없으면 `--allow-empty`). 이유: 훅은 턴 끝에 커밋, 표식이 게이트 정규식과 맞아야.
- 4 ship-task 호출(args 그대로 + 스킵이면 "스킵") / 5 [결정 필요]면 판단해 ship-task 재호출(done-task 재호출 금지), 사실 확인 필요 결정은 사용자에게 / 6 완료 보고 그대로 전달.
- 안 하는 것: push·PR·머지 직접, simplify 여부 묻기. simplify [결정 필요]가 돌아오면 3번 하고 재호출.

#### payload/.claude/skills/ship-task/SKILL.md
- 내부 스킬. fork(git-flow, sonnet). 흐름: simplify 게이트 → 조건부 합치기 → 마이그레이션 게이트 → 스모크 게이트 → push → PR → (권한 있으면) CI 대기 → squash → 원격 삭제. 오너는 squash까지, 팀원은 PR까지.
- 호출 경로 ship 신호 → done-task → 이 스킬. 이후 [결정 필요]는 메인 판단. `$ARGUMENTS` 삭제 금지. ship 신호가 곧 승인, PR 제목·본문은 초안 그대로. squash는 GitHub에서.
- §1-0 계정 검문: AGENTS.md에 소유 표 있을 때만. 모든 gh 명령에 `env GH_TOKEN="$(sed … .env.cli)"` 로더. 토큰 있으면 그 계정을 표와 대조, 전역 활성 계정은 안 봄. 없으면(폴백) `gh auth status`로 대조 + 토큰 방식 권고 줄. `git push`는 SSH라 토큰과 무관. 하드 ① 원격 주소가 표 소유자 저장소인가 ② 원격 새로 만들 때 계정 다르면 [결정 필요]. 소프트(원격 있음): 토큰이 다른 계정이면 막지 않고 보고 / 폴백이고 표 계정 등록돼 있으면 전환 후 진행 / 등록 안 됐거나 작성자 다르면 진행하고 보고.
- §1: 1-a main·detached 중단 / 1-b fetch 후 `origin/main..HEAD` 비면 중단 / 1-c 워킹트리 더러우면 args, 없으면 [결정 필요].
- §1.5 simplify 게이트: src 변경 있을 때만. 표식 두 형태(`wip: /simplify` 시작, `chore: simplify 반영` 정확히)만 인정. 없으면 [결정 필요], fork 안에서 simplify 실행 안 함. 재발동 없음(사고 2회).
- §1.6 조건부 동기화: 뒤처졌으면 `merge-tree` 예행 → 충돌 없으면 `merge --no-edit`, 있으면 [결정 필요]. 리베이스·force push 금지. "동기화 없이 진행" 지시면 건너뛰고 경고.
- §1.7 마이그레이션 게이트: 더하는 건 먼저 밀고 머지, 없애는 건 머지·배포 뒤. diff 비면 통과, 지시 있으면 통과, 없으면 [결정 필요]. supabase 명령 직접 실행 안 함.
- §1.8 스모크 게이트: `smoke` 스크립트 없으면 skip. 실패하면 [결정 필요].
- §2 PR 정보: 제목 70자 이하 type 접두사 없음, Summary·Test plan 템플릿 + 서명. 초안이 곧 확정본.
- §2.5 역할 판별: admin·maintain이면 오너, push만이면 팀원(오너를 리뷰어로). 조회 실패면 팀원. "머지까지"/"PR까지만" 지시로 강제.
- §3: push(`-u`) → PR 생성(실패면 기존 PR) → 오너만 `gh pr checks --watch` 후 머지, 실패면 PR 유지 / 검사 없으면 20초 뒤 재확인 후 머지 / `gh pr merge --squash --delete-branch`, 성공 판정은 PR 상태(MERGED) / 뒷정리(원격 삭제 확인, main switch, `pull --ff-only`, 로컬 `-D`, `fetch --prune`, sha 일치 확인), 실패해도 중단 안 함.
- §4 완료 보고 템플릿(오너·팀원·CI 실패). 엣지 케이스 33행. 호출 패턴 11종. 안 하는 것 목록.

#### payload/.claude/skills/rewind-task/SKILL.md
- wip 커밋 하나로 되돌아감. 후보 제시 → 방법 선택 → 백업 태그 → 실행. fork. [결정 필요]는 사용자가 직접 재호출(`disable-model-invocation`). `$ARGUMENTS` 삭제 금지.
- §1: 1-a detached 중단 / 1-b 워킹트리 / 1-c main 위: PR 지시면 §2-b, main 커밋 무르기면 `git revert` 안내 후 중단, 지시 없으면 [결정 필요].
- §2: fetch(실패 시 로컬 기준). 2-a `origin/main..HEAD` 최근 20개 표(#, 커밋번호, 언제, 힌트, 파일·증감). 2-b PR 번호 → `fetch origin pull/<N>/head:recover-<N>` → `origin/main..recover-<N>` 목록.
- §3 방법 (A) 파일 하나 (B) 새 가지 (C) 통째로 → [결정 필요]. §4-a 백업 태그 `rewind-backup/<브랜치>-<날짜시각>` 필수(원격 push 안 함). 4-b (A) `checkout <커밋> -- <파일>` 자동 커밋 안 함 / (B) `switch -c` / (C) `ls-remote` 확인 후 원격 있으면 [결정 필요], 없으면 `reset --hard`.
- §5 완료 보고. 톤: 커밋 목록은 표로, force push 절대 권하지 않음. 엣지 13행. 호출 패턴 7종.
- 안 하는 것: force push, main 되감기, 자동 커밋, 태그 원격 push, 기존 태그·브랜치 삭제, 시점 자동 판단, 자동 invoke, 브랜치 생성·PR·머지.

#### payload/.claude/hooks/auto-wip-commit.sh
- Stop 훅. 매 응답 끝에 wip 커밋. push 안 함. 폴더는 stdin cwd → CLAUDE_PROJECT_DIR → pwd. main·detached·merge/rebase/cherry-pick 중이면 skip.
- 변경 없으면 커밋 안 함(단 `/simplify` 턴이면 빈 표식). 시크릿 패턴 파일만 staging에서 뺌(`.example`·`.sample`·`.template` 예외). 시크릿뿐이면 skip + `.gitignore` 안내. `git add -A`(staged 가드 제거).
- 힌트: 최근 user 메시지 10개 거슬러 찾음, 태그 제거. 우선순위 슬래시 명령 > 재호출 안내문 폴백 > Skill simplify tool_use > 평문. 60자. 메시지 형식 `wip: <힌트> — <파일 3개> 외 N개 (<shortstat>)`. 실패해도 exit 0. 수정 이력 주석 7건.

#### payload/.claude/hooks/no-main-push.sh
- PreToolUse(Bash). main 직접 push 차단(명시·`*:main`·`refs/heads/main`·`--delete main`). refspec 없으면 대상 폴더 현재 브랜치가 main일 때 차단. 대상 폴더는 `-C`·`--git-dir`·`--work-tree` → stdin cwd → CLAUDE_PROJECT_DIR. 전역 옵션 건너뛰고 서브커맨드 판정. force push 전면 차단. 셸 구분자로 나눠 첫 토큰이 git인 명령만. 배포 CLI 차단은 범위 밖. exit 2.

#### payload/.claude/settings-hooks.json
- PreToolUse Bash → no-main-push.sh / Stop → auto-wip-commit.sh.

#### payload/.github/workflows/ci.yml
- main PR·push에서. `package-lock.json` 없으면 Node 단계 건너뜀. Node 24, `npm ci`·lint·build. Supabase env 없이 빌드 통과(주석). 밀린 마이그레이션 감지는 main push 때만, Secrets 3개 없으면 skip, 감지만 하고 안 밈, timeout 5분, `--output-format json` 필수, 해석 실패면 실패, 밀린 게 있으면 `db push --linked` 안내하며 실패.

#### payload/docs/git-workflow.md
- §1 new-task → 작업 → done-task 순환. new-task는 main에서만, 클로드가 부름. done-task는 "보내줘" 뒤에만. main 머지 = Vercel 배포. §2 squash 이유·작업 단위(§2.5). §3 main 직접 push 금지(훅은 Claude Bash만), 비공개 무료 플랜은 브랜치 보호 불가(403). §4~§7 되돌리기(wip 찾기, refs/pull, 방법 셋, main은 `git revert`, 잃어버린 커밋 순서 refs/pull→reflog→fsck→태그, PR 없는 브랜치 `-D`가 유일한 영구 손실 지점, 서비스 복구는 Vercel Instant Rollback 먼저). §8 팀(협업자 구조, 역할 표, 팀장 머지는 관례, `merge-tree` 예행, 리베이스 버린 이유, 충돌 해결 순서, 원격 이름 충돌, 팀원 사이클).

---

## 2회차 — 운영 스킬 4 + 에이전트 5 + rules 2 + 템플릿 2 + account-check + README

### 요약

**정독한 파일 (15개, 전부 읽음)**
- `payload/.claude/skills/project-init/SKILL.md` (278줄), `harness-diet/SKILL.md` (99줄), `transfer-ownership/SKILL.md` (154줄), `deep-research/SKILL.md` (175줄)
- `payload/.claude/agents/delegation-integrator.md` (111줄), `git-flow.md` (14줄), `harness-auditor.md` (64줄), `user-scenario-writer.md` (224줄), `ux-writing-reviewer.md` (115줄)
- `payload/.claude/rules/markdown-style.md` (35줄), `security-baseline.md` (128줄)
- `payload/.claude/templates/sources-template.md` (31줄), `status-template.md` (25줄)
- `payload/docs/account-check.md` (63줄), `README.md` (345줄)
- 기준 문서 `AGENTS.md`·`payload/AGENTS.md.template`도 먼저 읽음.

**분류별 항목 수 (총 31건)**

| 분류 | 건수 |
|---|---|
| A 일반 지식 중복 | 3 |
| B 중복 서술 | 9 |
| C 죽은 참조 | 1 |
| D 낡은 사실 | 5 |
| E 세부 과잉 | 0 |
| F 발동 불가 | 1 |
| G 층 이동 | 0 |
| [모순] | 12 |

**공통 확인 결과**
- **앵커:** 문서 안 앵커를 스크립트로 전수 대조. project-init 14개, transfer-ownership 26개, deep-research 25개, README 55개 모두 헤더와 맞고 죽은 앵커 0개.
- **교차 참조:** 아래 참조는 전부 실제로 있음 — `6-0-backend-prep.md`의 §2·§4·§4.1 / `6-2-backend-auth.md` §11 / `ship-task` §1-0 / design-brief의 §2 「보이스 앤 톤」·§3 「문자 그대로」 (`1-user-story.md` 348·370줄) / `.dc.html`, 리액트 마이그레이션 / git-flow를 쓰는 스킬 셋 (`agent: git-flow`가 new-task·ship-task·rewind-task에 있음).
- **Grok 잔재:** `grep -rni "grok\|CLAUDE.md.template" payload README.md AGENTS.md` 결과 0건.

### 파일별 항목

#### payload/.claude/skills/project-init/SKILL.md

**P1**
- 위치: "하네스는 **파일 복사로 배포**한다. builder-harness 저장소가 원본(SoT, Source of Truth — …)" (8줄)
- 분류: A
- 근거: AI 지시문 안에 풀이 괄호가 셋 있음. 「SoT, Source of Truth — 정답이 되는…」, 「mirror — 거울처럼 같은 모양」, 「clone(내려받기)」. 사람용 풀이는 README §3.3에 똑같이 있음.
- 제안: 삭제. 괄호 안 풀이만 빼고 본문 문장은 그대로.

**P2**
- 위치: "git status --porcelain -- .claude docs/git-workflow.md .github/workflows/ci.yml" (173줄)
- 분류: [모순]
- 근거: 같은 파일 184줄은 덮어쓸 하네스 소유물에 account-check.md를 넣음. 그런데 미커밋 검사 명령에는 account-check.md가 빠져 있음.
  - 184줄: 「`payload/docs/*` ↔ `docs/git-workflow.md`·`docs/account-check.md`」
  - 173줄 명령: account-check.md 없음
  - README 276줄도 「이 검사는 저 세 자리에만 해당한다」로 똑같이 빠짐.
  - 실행 결과: `ls payload/docs` → `account-check.md git-workflow.md`
- 제안: 수정안. 세 곳을 같이 고침 — 173줄 명령에 `docs/account-check.md` 추가 / README 276줄의 세 자리를 네 자리로 / 260줄 마무리 보고 괄호에 account-check.md 추가.

**P3**
- 위치: "**main에 서 있으면** — 동기화 모드는 main에서 멈추니(1단계)" (267줄)
- 분류: [모순]
- 근거: 같은 파일 167줄은 main에서 멈추지 않고 브랜치를 열어 계속 감. 「main이면 `/new-task`를 직접 호출해 작업 브랜치를 연 뒤 동기화를 이어간다」
- 제안: 수정안. 「동기화 모드는 1단계에서 작업 브랜치를 먼저 여니, 이 갈래는 신규 적용 직후에만 해당한다」

**P4**
- 위치: "첫 적용은 main에서 하는 게 정상이다." (267줄). README 203줄 「이 첫 적용만은 main에서 바로 한다」도 같은 문제.
- 분류: [모순]
- 근거: AGENTS.md 37줄과 템플릿 54줄: 「`/project-init`·`/simplify`처럼 **파일을 바꾸는 스킬도 예외 없이** 브랜치를 먼저 연 뒤에 돈다.」
- 제안: 수정안. 어느 쪽 규칙 문장을 다시 쓸지는 사람 몫 (§사람 결정 2).

**P5**
- 위치: "❌ 하네스 원본 저장소를 프로젝트에서 고치기 — … 복사본을 고쳐봐야 다음 동기화에서 충돌로 잡힌다" (277줄)
- 분류: [모순]
- 근거: 세 문서가 로컬 수정의 결과를 서로 다르게 말함.
  - 템플릿 75줄 (상시 로드): 「다음 동기화 때 덮어써진다. 여기서 고치면 그 수정은 조용히 사라진다.」
  - harness-diet 25줄: 「다음 동기화가 덮어쓴다」
  - project-init 205줄의 실제 절차: 옛 버전과 다르면 「충돌로 보고 사용자에게 묻는다」
- 제안: 수정안. 템플릿과 harness-diet 문장을 절차에 맞춰 「다음 동기화 때 충돌로 잡혀 원본으로 교체할지 묻게 되고, 교체하면 사라진다」로.

**P6**
- 위치: "**gh 인증은 이 프로젝트의 발급 토큰으로 맞춘다** — … **전역 활성 계정 전환은 쓰지 않는다** — 전환은 컴퓨터 전체에 걸려…" (89줄)
- 분류: B (스킬층 ↔ 참조 문서)
- 근거: account-check.md 원칙 ②와 gh 항목에 같은 내용. 이 줄 끝에 이미 「계정 절차·서비스별 함정은 account-check.md에 있다」고 가리킴.
- 제안: 의도 확인 필요. 지우는 쪽이면 축약안 「표의 GitHub 계정 토큰을 `.env.cli`에 `GH_TOKEN=`으로 두게 안내하고 `.gitignore`를 확인한다 — 이유·이행 폴백은 account-check.md gh 항목」.

#### payload/.claude/skills/harness-diet/SKILL.md

**H1**
- 위치: "**시작 전 브랜치 확인** — 파일을 바꾸기 전에 지금 어느 브랜치인지 먼저 본다." (12~18줄)
- 분류: B (상시 로드층 ↔ 스킬층)
- 근거: AGENTS.md·템플릿 §브랜치 「`git branch --show-current`를 실제로 돌린다 … main일 때만 `/new-task`부터다」와 겹침. transfer-ownership 12줄, project-init 161~167줄도 같은 패턴.
- 제안: 의도 확인 필요. 상시 로드 규칙을 스킬 안에서 다시 떠올리게 하려고 일부러 둔 것일 수 있음.

**H2**
- 위치: "호출 프롬프트에 반드시 담을 것:" 1~4 (56~61줄)
- 분류: [모순] (빠진 항목형)
- 근거: AGENTS.md 위임 절 「위임 지시서마다 「재위임 금지: …」 한 줄을 반드시 넣어 넘긴다」. 이 스킬의 「반드시 담을 것」 넷에는 그 줄이 없어 넷이면 충분하다고 읽힐 수 있음.
- 제안: 수정안. 5번으로 「재위임 금지 한 줄」 추가.

#### payload/.claude/skills/transfer-ownership/SKILL.md

**T1**
- 위치: "Aside repl에서 세션 폴더에 쓰고(`await fs.writeFile(path.join(pwd, 이름), 값)` — **`/private/tmp`는 거부된다**)" (42줄)
- 분류: [모순]
- 근거: account-check.md 59줄은 정반대 — 「`aside repl`에는 파일 쓰기(`fs`)와 `getByPlaceholder` 같은 이름 로케이터가 없다 — CSS 로케이터와 `console.log` 출력만 쓴다」. 두 줄 다 grep으로 확인.
- 제안: 수정안. 어느 쪽이 지금 실측과 맞는지 사람이 확인한 뒤 한쪽을 고침 (§사람 결정 5).

**T2**
- 위치: "**비밀번호·일회용 코드(OTP)·패스키는 사람 몫이다.** 이메일 인증 코드만 Aside ④가 읽어 넣는다." (91줄)
- 분류: [모순]
- 근거: 비밀번호를 누가 넣는지가 account-check.md와 다름.
  - account-check 원칙 ④ (13줄): 「로그인·재로그인 자체는 에이전트가 한다 — 사람은 일회용 코드(OTP)·패스키 입력만 맡는다」
  - account-check 52줄: 「비밀번호는 Aside의 암호화 금고가 저장·자동 채움」
- 제안: 수정안. 「OTP·패스키는 사람 몫이다(비밀번호는 금고 자동 채움 — 에이전트는 비밀번호 값을 직접 다루지 않는다)」처럼 한쪽으로.

**T3**
- 위치: "**스모크 검사는 시드 순수 상태를 가정한다**([§10]) — 로컬 QA 데이터가 남아 있으면 순위·집계가 어긋난다." (103줄)와 154줄
- 분류: B (같은 파일)
- 근거: 154줄 §10에 같은 문장이 한 번 더 나옴.
- 제안: 축약안. 103줄에서 「— 로컬 QA 데이터가…」 절만 빼고 §10 링크는 남김. 실측 사실은 §10에 원문 그대로.

**T4**
- 위치: "**저장소를 옮기면 호스팅 Git 연결이 끊긴다** — 새 소유에 호스팅 GitHub 앱을 설치하고…" (84줄)와 152줄. 78줄에도 같은 사실.
- 분류: B (같은 파일)
- 근거: §10 152줄이 84줄 앞부분과 거의 같은 문장.
- 제안: 축약안. 84줄은 규칙(재설치·계정 대조)을 남기고 사실 부분은 「([§10])」 참조로. 152줄 원문은 그대로.

**T5**
- 위치: "**gh는 환경변수 토큰(`GH_TOKEN`)이 저장된 자격 증명보다 우선한다**(실측: `gh help environment`)" (153줄)
- 분류: B (스킬층 ↔ 참조 문서)
- 근거: account-check.md 34줄에 같은 실측. 이 파일 10줄의 자기 원칙 「베껴 적지 않고 가리킨다」와도 부딪힘.
- 제안: 의도 확인 필요. 가리키기로 정하면 「gh 토큰 우선순위·폴백은 account-check.md gh 항목」 한 줄로. 실측 원문은 account-check에 남음.

#### payload/.claude/skills/deep-research/SKILL.md

**R1**
- 위치: "지시서에 공통으로 넣는 다섯 줄:" (83~89줄)
- 분류: [모순] (빠진 항목형)
- 근거: 조사 에이전트는 웹 조회를 하는 위임인데, AGENTS.md·템플릿 69줄 「웹 조회·브라우저·외부 CLI처럼 밖으로 요청이 나가는 일이면 「같은 실패 2회면 멈추고 보고, 401·403·404는 재시도 금지 …」를 넣는다」. 다섯 줄에는 재위임 금지만 있고 재시도 한도가 없음.
- 제안: 수정안. 6번째 줄로 재시도 한도 문구 추가. §4.5 검증자 지시서에도 똑같이.

**R2**
- 위치: 풀이 괄호 세 개 — "스키마(schema — 결과가 지켜야 할 형식 규격)" (49줄) / "**맹검(盲檢 — 눈을 가리고 하는 검사)**" (79줄) / "요청 한도(rate limit — 정해진 시간에 쓸 수 있는 횟수 제한)" (119줄)
- 분류: A
- 근거: AI 지시문 안의 용어 풀이 괄호. 맹검은 바로 뒤 문장이 이미 뜻을 정해 줌.
- 제안: 삭제. 괄호 안 풀이만.

#### payload/.claude/agents/delegation-integrator.md

**DI1**
- 위치: "`.claude/skills/<대상>-delegation/`" (산출물 구조, 49줄)
- 분류: [모순]
- 근거: 두 모드 모두에서 기준 문서와 부딪힘.
  - 원본 모드: 루트 AGENTS.md 「스킬·에이전트·rules 수정은 `payload/.claude/`에 하고, 루트 `.claude/`에 … 동기화」
  - 프로젝트 모드: 템플릿 75줄 「이 프로젝트의 `.claude/` 안 파일은 `/project-init`이 … 복사해 온 사본이라 … 고치지 않는다」
  - 이 에이전트는 두 모드 모두 `.claude/skills/`에 바로 씀.
- 제안: 수정안. 산출 경로를 모드별로 정함 (§사람 결정 3).

#### payload/.claude/agents/harness-auditor.md

**A1**
- 위치: "**경위·설계 이력의 이동 목적지는 `docs/design-notes.md`다.**" (50줄)
- 분류: C (프로젝트 모드 한정)
- 근거: 원본 저장소에는 있지만 payload에는 없어 프로젝트로 복사되지 않음. harness-diet는 프로젝트 모드도 지원하니 그때는 없는 파일을 가리킴.
  - `ls docs/design-notes.md` → 있음 / `ls payload/docs/design-notes.md` → `No such file or directory` / `ls payload/docs` → `account-check.md git-workflow.md`
- 제안: 수정안. 「원본 모드면 `docs/design-notes.md`, 프로젝트 모드면 `[하네스 제안]`으로 넘긴다」

#### payload/.claude/agents/user-scenario-writer.md

**U1**
- 위치: "반대편의 완결된 여정은 다음 단계 (InformationArchitecture)가 화면 인벤토리로 채우는 몫이라" (61~63줄)
- 분류: D
- 근거: 1단계 다음은 IA가 아니라 2단계 Mockup. 반대편 역할도 2단계 기능 목록에서 먼저 훑음.
  - README 142줄: 「UserStory · Mockup · MarketResearch · InformationArchitecture…」
  - idea-to-mvp/SKILL.md 6줄: 「2단계(Mockup)까지 했다면 3단계(MarketResearch)부터」
  - `grep 반대편 2-mockup.md` → 64줄 「반대편 역할 | 양면 시장이면 공급 쪽의 등록·수정·정산·응대 전부」
- 제안: 수정안. 「반대편의 완결된 여정은 뒤 단계(기능 목록·화면 인벤토리)가 채우는 몫이라」

**U2**
- 위치: "**판올림 연계 표기 금지** — 이 문서가 `-v2`, `-v3`처럼 버전을 올려 쌓여도…" (171~177줄)
- 분류: B (상시 ↔ 에이전트)
- 근거: 템플릿 46줄 「판올림 문서는 매 판이 완결된 한 편이다」와 규칙·근거 문장이 거의 같음. README 314줄에 따르면 서브 에이전트는 AGENTS.md를 자동으로 받음(2026-08-19 실측).
- 제안: 의도 확인 필요.

**U3**
- 위치: "(근거: 문서용 반말 규칙이 서비스 문구까지 스며들어, 작가가 서비스 톤을…" (113~115줄)
- 분류: B
- 근거: 템플릿 43줄 「(근거: 문서용 반말 규칙이 서비스 문구까지 스며들어, 작가 에이전트가…)」과 같은 사고 원문이 층을 달리해 두 번.
- 제안: 의도 확인 필요. 사고 원문이라 어느 쪽도 삭제로 올리지 않음.

**U4**
- 위치: 풀이 괄호 두 개 — "보이스 앤 톤 (voice & tone — 브랜드가 말하는 성격과 자리별 말투)" (37~38줄) / "**결정 대장(ledger — 확정된 결정을 날짜와 함께 쌓아 두는 장부)**" (103줄)
- 분류: A
- 제안: 삭제. 괄호 안 풀이만.

#### payload/.claude/rules/security-baseline.md

**S1**
- 위치: `paths:` 프런트매터 (4~9줄), description 「auth·API·업로드·supabase 코드를 만지면 로드된다」
- 분류: F
- 근거: 가짜 App Router + `src/` 트리에서 bash globstar로 글롭을 실제로 돌림.
  - 걸린 것: `src/app/api/users/route.ts`, `src/app/auth/callback/route.ts`, `src/middleware.ts`, `src/lib/supabase/middleware.ts`, `src/app/actions/upload.ts`, `src/components/upload-form.tsx`, `supabase/*`
  - **어느 글롭에도 안 걸린 것:** `src/proxy.ts`, `src/lib/supabase/client.ts`, `src/lib/supabase/server.ts`, `src/app/login/page.tsx`, `src/app/signup/page.tsx`, `src/app/(auth)/login/page.tsx`, `src/components/ImageUpload.tsx`, `src/app/upload/page.tsx`, `src/app/actions.ts`
  - 결정적 근거는 하네스 자신의 `6-2-backend-auth.md` 167~173줄. 공식 참조 구현을 `lib/supabase/`의 `proxy.ts`(「미들웨어 정본」)·`client.ts`·`server.ts`로 받으라고 하는데, 셋 다 이 rule을 발동시키지 못함.
  - `supabase/**/*`는 루트 기준이라 `src/lib/supabase/`에 안 닿음. `**/middleware*`는 `proxy.ts`를 못 잡음.
- 제안: 수정안. 글롭 추가 — `'**/proxy*'` / `'**/supabase/**/*'` (또는 `'src/lib/supabase/**/*'`) / `'**/*[Uu]pload*'` / `'**/login/**/*'`, `'**/signup/**/*'`, `'**/(auth)/**/*'`. 정확한 목록은 사람이 확정 (§사람 결정 4).

**S2**
- 위치: "영역별 상세 룰이 필요해지면 `.claude/rules/`에 별도 파일로 추가." (42줄)
- 분류: [모순]
- 근거: DI1과 같은 구조. 프로젝트 모드: 템플릿 75줄은 하네스 사본 폴더에서 규칙(rules)을 고치지 말고 문안으로 넘기라고 함. 원본 모드: AGENTS.md는 수정 위치가 `payload/.claude/`.
- 제안: 수정안. 「필요해지면 하네스 저장소 `payload/.claude/rules/`에 추가한다 (프로젝트에서는 문안으로 사용자에게 준다)」

#### payload/docs/account-check.md

**AC1**
- 위치: "대시보드 실측 함정 다섯(쓴 시점 기준):" (40줄)
- 분류: D
- 근거: 바로 아래 하위 항목이 일곱 개. `sed -n 40,47p payload/docs/account-check.md | grep -c "^  - "` → `7`
- 제안: 수정안. 「다섯」→「일곱」, 또는 개수를 빼고 「대시보드 실측 함정(쓴 시점 기준):」.

**AC2**
- 위치: "| 낮음 | 페이지·목록 읽기 | 3회, 실패하면 「확인 못 함」으로 적고 넘어간다 |" (23줄)
- 분류: [모순]
- 근거: 같은 실패의 허용 횟수가 세 곳에서 다름.
  - 같은 파일 26줄: 「**똑같은 응답이 두 번이면 거기서 멈춘다.**」
  - AGENTS.md·템플릿 69줄 (상시 로드): 「같은 실패 2회면 멈추고 보고」 (원칙 ⑥ 인용)
  - 표 낮음 등급: 3회
- 제안: 수정안. 「3회」가 「서로 다른 실패를 포함해 3회까지, 같은 응답은 2회면 멈춘다」는 뜻인지 표에 적어서 규칙 문장을 정확하게 다시 씀. 상시 로드층 문구는 그대로.

**AC3**
- 위치: "**여러 계정을 등록해 두고 전환하는 CLI(gh 등)도 예외가 아니다** — … **환경변수 토큰은 저장된 자격 증명보다 우선하므로…** 아직 토큰을 안 만든 옛 프로젝트만 임시로…" (원칙 ②, 9줄 뒷부분)
- 분류: B (같은 파일)
- 근거: 같은 파일 gh 항목 34줄(실측 인용 붙음)과 37줄(이행 폴백)이 같은 내용을 더 자세히 말함. 9줄 스스로도 「(자세한 것은 아래 gh 항목)」이라고 적음.
- 제안: 축약안. 원칙 ②에는 「gh처럼 계정 전환이 되는 CLI도 전환하지 않고 발급 토큰을 CLI 전용 파일에 둔다 — 아래 gh 항목」만. 명령문(알린다)은 37줄에 원문 그대로 남음.

**AC4**
- 위치: "**④ 브라우저 작업(…)은 소유별 프로필에서 하고, 표의 계정으로 대조한다** — **프로필 하나에는 한 소유…**" (13줄 앞 네 문장)와 55줄 "**프로필마다 비밀번호 금고와 Aside 로그인을…사용자 몫이다.**"
- 분류: B (상시 ↔ 참조 문서)
- 근거: 템플릿 35줄(상시 로드)과 거의 한 글자도 안 다르게 같음.
- 제안: 의도 확인 필요. 상시 로드층은 옮기지 않는 게 정책. 줄이기로 정하면 account-check 쪽을 「(프로필 원칙은 AGENTS.md 「소유와 계정」)」 참조로.

#### README.md

**RM1**
- 위치: §4 표 "| 횡단 스킬 | `deep-research` | …" 주변 (140~157줄)
- 분류: D
- 근거: payload에 있는 `transfer-ownership` 스킬이 표에 없음. `ls payload/.claude/skills` → 10개 중 transfer-ownership 포함 / `grep -n "transfer-ownership" README.md` → 0건
- 제안: 수정안. 「| 횡단 스킬 | `transfer-ownership` | 프로젝트 소유를 다른 소유로 옮김 — 저장소·DB·호스팅·로그인 앱·AI 키를 순서대로 이전하고 계정 표를 다시 씀 |」 행 추가.

**RM2**
- 위치: "소유 답으로는 계정 명부([§5.1](#51-하네스-저장소-내려받기))에서 그쪽 계정 세트를 읽어" (193줄)
- 분류: D
- 근거: §5.1에는 계정 명부가 없음. 오히려 「하네스에는 아무 계정도 적혀 있지 않고」. 실제 절차인 project-init 88줄은 사용자에게 물어서 받음. `grep -n "명부" README.md` → 193줄 하나뿐.
- 제안: 수정안. 「소유 답과 함께 서비스별 계정을 물어 같은 파일의 「소유와 계정」 표를 채운다 (모르는 칸은 `(확인 필요)`)」

**RM3**
- 위치: "다음 셋 중 하나라도 안 맞으면 `/project-init`이 **동기화를 시작하지 않고**" (245줄)
- 분류: D
- 근거: project-init 36~50줄은 네 가지를 검증. 넷째는 「HEAD와 origin/main이 다름 → … 중단한다」이고 README에는 빠짐.
- 제안: 수정안. 「넷 중」으로 바꾸고 「로컬 원본이 원격 main과 같은 커밋이어야 한다」 추가.

**RM4**
- 위치: "4. **`/clear`** — 방금 동기화로 스킬 파일 자체도 바뀌었는데, 지금 세션은 아직 옛 버전을 쓰고 있다." (268줄). 292줄 「다만 **지금 열려 있는 세션에는 안 들어온다.**」도 같은 문제.
- 분류: [모순]
- 근거: 세 곳이 반영 시점을 다르게 말함.
  - project-init 150줄: 「동기화 때는 `.claude/`가 이미 있어 껐다 켜지 않아도 이 세션에서 바로 잡힌다」
  - project-init 269줄: 「**지금 세션에서도 바뀐 스킬·훅이 바로 잡히니 따로 할 일 없다**」
  - README 안에서도 209줄 「스킬 본문은 부를 때마다 읽어서 고치면 다음 호출부터 바로 반영되고, 에이전트 정의는 새 세션부터다」와 129줄 「고치면 바로 반영된다」가 268·292줄과 부딪힘.
- 제안: 수정안. 실측으로 확인한 뒤 한쪽으로 (§사람 결정 1).

### 확신 없어 뺀 것

- **project-init 275~276줄 「안 하는 것」의 AGENTS.md·CLAUDE.md 줄:** 본문 §3·§4의 규칙 요약이지만 「안 하는 것」은 경계 목록이지 정리표가 아니라서 B로 안 올림.
- **project-init 112줄 「이번에 들어오는 것 중 설명이 필요한 둘」:** README §5.3과 겹쳐 E 후보. 8번 마무리 안내 재료라 뺌.
- **project-init 150줄 「/reload-plugins … 하네스 자체는 플러그인이 아니다」:** 실측 성격(「터미널 실행 전용 — 데스크톱 앱엔 없다」)이라 뺌.
- **project-init 167줄 「`auto-wip-commit`(턴이 끝날 때마다…)」:** 사용자 대상 설명이라 풀이 허용 자리.
- **project-init 216줄 「예를 들어 `/idea-to-mvp`가 7단계로 개편되면…」:** 「왜 대조하나」 예시라 E 제외 조건.
- **project-init 88줄과 템플릿 31줄의 「`(확인 필요)` 칸은 6-0에서 확정되면 채운다」:** 표를 만드는 절차 안에서 꼭 필요한 문장.
- **harness-diet 54줄 「메인이 여러 에이전트를 동시에 띄우는 건 재위임이 아니라 정상이다」:** 바로 병렬로 띄우는 자리라 헷갈림을 막는 문장.
- **harness-diet 34줄 「발동 시 로드층 — … rules/. 그 스킬·에이전트가 발동할 때만 읽힌다」:** rules는 경로가 맞을 때 읽혀 표현이 조금 부정확하나 층 분류 결과는 맞아 D로 안 올림.
- **delegation-integrator description 「각 <대상>-delegation 스킬이 담당」:** `ls payload/.claude/skills | grep delegation` 0건이나 앞으로 만들 스킬의 일반 이름이라 C 아님.
- **security-baseline 128줄 「겹쳐 쌓기(defense in depth — …)」:** [공식] 딱지 문장 안이라 A 금지 조건.
- **account-check 36줄 「토큰 권한(스코프 — …)」:** 사람용인지 AI 지시문인지 경계가 애매.
- **ux-writing-reviewer, git-flow, markdown-style, 두 템플릿:** 걸리는 항목 없음. ux-writing-reviewer의 design-brief §2·§3 참조, `.dc.html`, 리액트 마이그레이션 grep 확인 / markdown-style의 `**/*.md` 글롭은 `docs/a.md`·`mvp/user-story.md`·`README.md`에 모두 걸림.
- **G 0건:** 이번 회차에는 `references/`가 있는 스킬이 없음. user-scenario-writer 121~124줄 「(실사례: 브리프가 없던 시절…)」은 실사고 원문 정책에 따라 이동 후보에서 뺌.

### 사람이 정해야 할 것

1. **반영 시점의 정답 (RM4):** 동기화 뒤 스킬·훅이 이 세션에서 바로 잡히는지, `/clear`나 재시작이 필요한지 실측 필요. 결과에 따라 project-init 150·269줄이나 README 129·209·268·292줄 한쪽을 고침.
2. **첫 적용의 브랜치 규칙 (P4):** 「예외」 딱지 없이 규칙 문장 자체를 다시 써야 함. (a) AGENTS 쪽: 「`/new-task`가 있는 저장소에서는 파일을 바꾸는 스킬도 브랜치를 먼저 연다」 / (b) project-init 신규 모드가 `git switch -c` 같은 방법으로 직접 브랜치를 열게 바꾸기.
3. **하네스 소유 폴더에 새 파일을 만드는 에이전트와 rule의 목적지 (DI1·S2):** 원본 모드는 `payload/`로, 프로젝트 모드는 문안 전달로 가야 하는지. 추가로 — 프로젝트에서 새로 만든 스킬을 동기화가 「원본에서 사라짐 → 삭제」로 오판하지 않는지 / 1단계 미커밋 검사(`.claude` 전체)에 막히지 않는지.
4. **security-baseline의 `paths` 확정 목록 (S1):** `proxy.ts`와 `lib/supabase/` 추가는 거의 확실. 로그인·가입 페이지, `(auth)` 라우트 그룹, `*Upload*` 컴포넌트까지 넓힐지는 rule 로드 비용과 맞바꾸는 판단.
5. **Aside repl에서 파일을 쓸 수 있는지 (T1):** transfer-ownership(`fs.writeFile` 가능, `/private/tmp` 거부)과 account-check(`fs` 없음) 중 어느 쪽이 지금 실측과 맞는지.
6. **비밀번호 입력의 주체 (T2):** 금고 자동 채움을 쓰는 에이전트인지 사람인지.
7. **재시도 한도의 해석 (AC2):** 낮음 등급 「3회」와 「같은 응답 2회면 멈춤」의 관계.
8. **모드 판별 기준 (project-init 62줄):** 「`CLAUDE.md`가 이미 있거나 → 동기화 모드」는 하네스와 상관없이 자기 CLAUDE.md를 가진 프로젝트도 동기화 모드로 보냄. 그 경우 인터뷰를 건너뛰고 「옛 구조 CLAUDE.md 이행」 경로를 탐. 판별을 `.claude/harness-version` 하나로만 할지. 이 판별 때문에 신규 모드 2단계의 「이미 있고 내용이 그 한 줄이면」 갈래에는 사실상 도달할 수 없음.
9. **층이 다른 중복을 둘지 줄일지 (P6·H1·T5·U2·U3·AC4):** 상시 로드 ↔ 스킬·에이전트 ↔ 참조 문서 사이의 같은 문장을 의도한 이중 배치로 둘지 한 번에 정하면 여섯 항목이 한꺼번에 풀림.
10. **delegation-integrator의 「사용자 확인을 받고 설치」 (규칙 5·8):** 서브 에이전트라 도중에 사용자와 대화할 수 없음. git-flow처럼 「멈추고 [결정 필요]로 반환 → 재호출」 방식으로 바꿀지.

### 규칙 인덱스 (판정 없이)

#### project-init/SKILL.md
- 하네스는 파일 복사로 배포한다. builder-harness가 원본이고 `payload/`가 프로젝트 루트의 미러다. 이미 적용된 프로젝트에서 다시 돌리면 동기화 모드.
- 전제 확인: 프로젝트 루트에서 실행하는가, git repo인가(아니면 `git init -b main` 제안), 원본 위치를 아는가. 원본 찾기 순서: `~/dev/builder-harness` → 사용자에게 경로 질문 → clone 제안. 스탬프 `repo=`가 clone 주소보다 먼저(fork 대비).
- 원본 검증 네 단계 필수: main 브랜치, 커밋 안 된 변경 없음, `pull --ff-only`, HEAD와 origin/main 일치. 하나라도 어긋나면 중단. 통과하면 12자리 sha 기록.
- 모드 판별: `CLAUDE.md`나 `.claude/harness-version`이 있으면 동기화, 없으면 신규.
- 신규 1단계: 세 가지 질문(서비스 이름·한 줄 정의, 타겟, 소유). 2단계: `CLAUDE.md`는 정확히 `@AGENTS.md` 한 줄. 3단계 AGENTS.md: 없으면 템플릿 복사해 빈칸 채움, 구조 수정 없음, 방법론 설명 없음, 「소유와 계정」 표는 물어서 채우고 모르는 칸은 `(확인 필요)`. gh 인증은 `.env.cli` `GH_TOKEN`. 커밋 작성자는 로컬 git 설정도 같이(Vercel BLOCKED 실사고). AGENTS.md가 이미 있으면 덮어쓰지 않고 마커 구역 없을 때만 끝에 덧붙임. `nextjs-agent-rules` 구역 불변.
- 신규 4단계: `payload/` 통째 복사(예외 `AGENTS.md.template`·`settings-hooks.json`), 훅 `chmod +x`. 5단계 hooks 블록 병합(기존 키 보존, 같은 스크립트 하나만). 6단계 `mvp/`·`docs/` 생성. 7단계 스탬프. 8단계 마무리 안내.
- 동기화: payload에서 온 파일은 하네스 소유물, AGENTS.md만 예외, CLAUDE.md도 소유물. 1단계 main이면 `/new-task` 직접 호출, 하네스 소유 경로에 미커밋 변경 있으면 멈춤. 2단계 같으면 넘어감/없으면 복사/사라졌으면 확인받고 삭제/다르면 판별. `settings.json`은 hooks만. 3단계 옛 버전과 같으면 조용히 교체, 다르면 충돌로 묻기. 4단계 AGENTS.md 마커 구역 안 공용 문구만 대조, 병합 기본, 진짜 충돌은 묻기. CLAUDE.md가 한 줄이 아니면 옛 내용 보여주고 옮길 안 내고 확인받고 줄임. 5·6단계 폴더 보정, 스탬프 갱신. 7단계 세 갈래 보고.
- 안 하는 것: 앱 스캐폴딩, repo 생성·push, AGENTS.md 무단 덮어쓰기, CLAUDE.md 무단 삭제, 프로젝트에서 하네스 고치기, settings.json hooks 밖 키.

#### harness-diet/SKILL.md
- 범위는 검토와 보고서까지. 실패 모드는 지우면 안 될 걸 지우는 것. 시작 전 브랜치 확인. 모드 판별(payload → 원본 / harness-version → 프로젝트, `[하네스 제안]`). 층 셋. 회차 2,000줄. 상시 로드층은 매 회차 기준 문서. harness-auditor 층 감사 모드 병렬. 호출 프롬프트 필수 넷. 대충한 신호 셋. 보고서 `docs/harness-diet-review.md` 덮어쓰기, 머리 항목 넷. 교차 검토 모드 한 번. 사람 결정 우선순위 목록. 철칙 셋. 안 하는 것 넷.

#### transfer-ownership/SKILL.md
- 저장소·DB·호스팅·로그인 앱·AI 키를 함께 옮김. 평상시 규칙은 account-check·6-0이 정하고 이 스킬은 가리킴. 시작 전 브랜치 확인. ⚠ 시점 기준. Aside 역할 넷. 비밀값은 대화에 안 남김. 0단계 계정 표는 옛 상태로만, 프로필 라벨은 사용자에게 받음. 1단계 읽기 전용 계획표 + 부작용 셋 + 승인. 2단계 순서 DB → 저장소 → 호스팅 → 로그인 앱 → AI 키, 단계마다 네 묶음, 임시 멤버 패턴, GitHub 앱 재설치, 토큰 API 검증 후 배선표 전체 설치, 쓰기 직전 계정 검문. 3단계 카카오·비밀번호·OTP·패스키는 사람, 옛 토큰 폐기 보류. 4단계 PR 하나로 검증, 화면 판정은 사람. 5단계 표 전면 재작성, 명부 문안, 메모리 갱신. 6단계 되감기. 안 하는 것. §10 실측 11건.

#### deep-research/SKILL.md
- 반박 시도 후 살아남은 것만 출처와 보고. 내장 워크플로 없는 환경 대비. 더하는 것 둘(CalCal 실사고). 파일 안 만듦. 실행 경로 판별 셋. 깊이 계약 표. 요금제·한도 먼저 묻기. 「예산상 생략」 표기. 수렴 기준. 4.1 각도 3~5개. 4.2 맹검 + 지시서 공통 다섯 줄. 4.3 원문 fetch 대조. 4.4 검증 우선순위 부재 > 수치 > 단일 출처. 4.5 검증자 2~3명, 판정 셋. 4.6 비평 에이전트. 4.7 메인이 직접 씀. §5 스크립트 구조. §6 보고서 형식. §7 실측 메모.

#### delegation-integrator.md
- 조사 → 설치 → 위임 테스트 → 스킬 작성 통합 엔지니어. 최상위 규칙 여덟. 산출 위치 `.claude/skills/<대상>-delegation/`. 워크플로 5단계.

#### git-flow.md
- new-task·ship-task·rewind-task fork 실행. 직접 실행, 위임 안 함. 결정 지점에서 [결정 필요] 반환. 인자에 결정 있으면 통과. 파괴적 명령 최소. 완료 보고 형식 그대로.

#### harness-auditor.md
- 읽기 전용, 재위임 금지. 모드 둘. 판정 분류 A~G와 [모순]. 흔들리면 「확신 없어 뺀 것」. 확정 정책 다섯. 반환 형식 다섯 부분.

#### user-scenario-writer.md
- 영화 시나리오형 유저 스토리. 입력 넷(양면이면 다섯), 빠지면 가정. 세계관·정서 한 줄. 필수 구조. 「화면 묘사를 읽는 법」 끝에. design-brief 읽기 전용, 결함은 멈추고 보고. 출력 표기 관례. 작법 규칙. 판올림 연계 표기 금지. BX 판정 기준. 마무리 섹션. 저장 규칙(`mvp/user-story.md`, 판올림, 제자리 덮어쓰기 지시 예외). 최종 메시지 다섯.

#### ux-writing-reviewer.md
- UI 카피 교정, 직접 Edit. 원칙 서열: 토스 8원칙 > 보이스 앤 톤 > 메커닉. design-brief §2·§3 읽기. 톤 미확정이면 유지하고 보고. 보이스/톤 위반 구분. 화면 SoT 양쪽 동기화. 수정 금지 목록. 출력 표. 8원칙·에러 원칙·톤 메커닉·금지 표현. self-check 11개.

#### markdown-style.md (`paths: **/*.md`)
- 목차는 `## 목차` 아래 앵커 번호 리스트 + 빈 줄 + `---`. 앵커는 GitHub 슬러그. 구분자 한 줄 나열 금지. `§`는 본문 참조용.

#### security-baseline.md (`paths`: api, auth, middleware, upload, supabase)
- 근거 등급. 1부 모든 배포 환경 노출, attack surface 없으면 적용 0. 영역별 baseline. 2부 Supabase + Next.js, 기본 비공개, grant + policy 두 겹, 정책 모양 다섯 줄, 권한 이름으로 묻기, anon execute, 하지 말 것 아홉, 최종 판정은 DB 정책.

#### sources-template.md / status-template.md
- `last_verified`·`update_cadence`, 소스 등급, 테스트 힌트, scope / 선정 방식, 환경, T1~T3 결과 표, 미해결 이슈.

#### account-check.md
- 읽는 때 셋. ① 리소스 생성마다 검문. ② CLI 인증 두 종류, 토큰은 계정당 하나, `.env.cli`, gh 전환 안 함, 환경변수 우선. ③ 배포 플랫폼은 커밋 작성자로 판정. ④ 소유별 프로필, 서비스 간 연결 양쪽 대조, 로그인은 에이전트·OTP·패스키만 사람, 2FA 멈춤. ⑤ 한 번만 보이는 값 즉시 확보. ⑥ 막히면 멈춤, 등급 표, 401·403·404 금지. 서비스별: gh, SSH 키, Vercel(함정 목록), Supabase, 맥 키체인, 카카오, 브라우저 콘솔, Aside(함정 목록).

#### README.md
- 대상·7단계·설계 원칙. §1 앱/터미널 차이. §2 빠른 시작. §3 하네스·스킬·서브에이전트·훅, 복사 배포 장점. §4 스킬·에이전트·훅 표. §5 clone·적용·생성 파일·팀원·막히는 것. §6 업데이트 세 걸음, §6.1~6.4. §7 새 버전 흐름, 버전 번호, 저장소 구조.

---

## 3회차 — design-system 스킬 전체 + idea-to-mvp 총론·1단계·2단계

### 요약

**정독한 파일 (10개, 빠짐없이)**
- `payload/.claude/skills/design-system/SKILL.md` + `references/` 6개: `bootstrap-project.md`, `common-patterns.md`, `component-taxonomy.md`, `font-loading.md`, `layout-frames.md`, `naming-taxonomy.md`
- `payload/.claude/skills/idea-to-mvp/SKILL.md`, `references/1-user-story.md`, `references/2-mockup.md`
- 기준 문서: `AGENTS.md`, `payload/AGENTS.md.template`
- 판정 근거 확인용으로 grep·ls만 한 파일(정독 대상 아님): 3·5·6-x·7단계 문서 헤더, `agents/user-scenario-writer.md` 헤더·§출력, `project-init/SKILL.md`, `docs/`.

**기계 검사 결과**: 10개 파일의 목차 앵커와 상대 경로 `.md` 링크를 파이썬 스크립트로 전부 대조 — 끊긴 것 0건. 본문 `§` 참조도 헤더와 대조 — 끊긴 것은 아래 C 2건뿐.

**분류별 항목 수**

| A | B | C | D | E | F | G | [모순] |
|---|---|---|---|---|---|---|---|
| 10 | 14 | 2 | 2 | 0 | 0 (rules 없음) | 4 | 9 |

### 파일별 항목

#### design-system/SKILL.md

**1.**
- 위치: 「**시작 전 브랜치 확인** — 파일을…」 (L27-33)
- 분류: B (상시 로드 `AGENTS.md` §브랜치 ↔ 스킬층)
- 근거: AGENTS.md에 「`git branch --show-current`를 실제로 돌린다 … main일 때만 `/new-task`부터다」가 이미 있음. 여기선 명령만 `git rev-parse --abbrev-ref HEAD`로 다름. `grep -ln "시작 전 브랜치 확인" */SKILL.md` 결과 같은 블록이 스킬 4개에 있음(harness-diet, design-system, idea-to-mvp, transfer-ownership).
- 제안: 수정안. 층이 달라 의도 확인 필요. 남긴다면 명령을 AGENTS.md와 같은 `git branch --show-current`로.

**2.**
- 위치: 「크기 예산(size budget — 영역마다…」 (L20)
- 분류: A
- 근거: AI 지시문 안의 용어 풀이. 같은 정의가 `layout-frames.md` §1 용어표에 있음.
- 제안: 삭제. 「셸 + 영역 + 크기 예산(size budget)」까지만.

**3.**
- 위치: 「층별 실제 파일 경로 · import 순서 · 프로젝트 고유 예외…」 (L36)
- 분류: [모순]
- 근거: SKILL.md: 「층별 실제 파일 경로 · import 순서 · 프로젝트 고유 예외(함정 토큰 등) · 컴포넌트 인벤토리 위치」 / `bootstrap-project.md` §5: 「…컴포넌트 인벤토리 위치 / 프로젝트 고유 예외·함정 토큰 / 철칙 요약 / **적용 규칙 요약**」 / 템플릿 §디자인 시스템 연결 정보: 「토큰 3층 경로·부품 인벤토리 위치·프로젝트 함정·**적용 규칙 요약**」. SKILL.md 목록에만 「적용 규칙 요약」이 빠짐 — 실사고 뒤 넣은 핵심 항목.
- 제안: 수정안. 목록을 반복하지 말고 「`bootstrap-project.md` §5 항목」을 가리키게. 아니면 최소한 「적용 규칙 요약」 추가.

**4.**
- 위치: `## 결정 트리` 전체 (L47-67)
- 분류: B (스킬층 ↔ 참조층)
- 근거: 「새 UI 요소」 1~4번은 `component-taxonomy.md` §5 결정 트리 ①~④와 거의 같음 / 「새 화면」 1번과 ⚠️ 줄은 `layout-frames.md` §2.1 표·철칙과 같음 / 「값」 4번 「그때만 foundation 확장 검토 (드묾, 신중히)」는 `naming-taxonomy.md` §6과 같음.
- 제안: 의도 확인 필요. 허브(SKILL)는 늘 먼저 로드되니 줄인다면 `component-taxonomy.md` §5를 지우는 쪽이 후보.

**5.**
- 위치: 「**새 프로젝트에 도입할 때** — [bootstrap-project.md]…」 (L106)
- 분류: B (색인이 본문을 반복)
- 근거: 「어느 문서를 언제 읽나」 색인에 bootstrap §1의 사유와 §3·§4가 무엇을 읽는지가 통째로 반복.
- 제안: 축약안 「bootstrap-project.md를 순서대로 따른다 — 도중에 읽을 참조 문서는 절차 안에서 안내한다」. 의도 확인 필요.

#### design-system/references/bootstrap-project.md

**6.**
- 위치: 「특정 도구 하나에 국한된 문제가 아니다 — 목업 생성 도구는…」 (L30-31)
- 분류: B (같은 파일)
- 근거: 바로 위 L24-25와 같은 주장. 설명문.
- 제안: 삭제. 그 한 문장만.

**7.**
- 위치: §5 목록 「- 층별 파일 경로와 import 순서 …」 (L95-99)
- 분류: [모순]
- 근거: `layout-frames.md` §6 「프레임 인벤토리(셸 종류·영역·예산)와 화면 패턴 목록은 각 프로젝트 문서에 기록한다 (위치는 프로젝트 AGENTS.md 참조)」. 그런데 bootstrap §5 adapter 목록에도 §4에도 프레임 인벤토리 위치를 AGENTS.md에 적으라는 줄이 없음.
- 제안: 수정안. §5 목록에 「프레임 인벤토리·화면 패턴 목록 위치」 한 줄 추가.

#### design-system/references/common-patterns.md

**8.**
- 위치: 「**로그인하지 않은 사람에게도 목록을 보여줍니다.** 커뮤니티 19곳 중…」 (L41)
- 분류: [모순]
- 근거: L21 「37곳(커머스 19 · 게시판 커뮤니티 **18**)」 / L28 「게시판 커뮤니티 … **18곳** 관찰」 / L37 「**18곳** 중 0곳」 / L41 「커뮤니티 **19곳** 중 막은 곳은 1곳뿐」. SNS 3곳이 합계 37에 안 들어간 점도 설명 없음.
- 제안: 수정안. 실측 값이라 AI가 고치면 안 됨. 원래 조사 기록으로 사람이 확인 (§사람 결정 4).

#### design-system/references/component-taxonomy.md

**9.**
- 위치: 「회귀(regression — 고쳤던 문제가 다시 생기는 것)」 (L82)
- 분류: A
- 제안: 삭제. 「회귀(regression)」까지만.

#### design-system/references/font-loading.md

**10.**
- 위치: 「자체 호스팅(self-hosting) — 내 서버에서 직접 내려주는 것 — 한다」 (L7)
- 분류: A
- 제안: 삭제. 「조각화된 폰트를 자체 호스팅(self-hosting)한다」로.

**11.**
- 위치: 「이걸 **조각화(subsetting) — 폰트를 글자 범위별로…」 (L26-27)
- 분류: A
- 근거: 앞 문장 「90개 남짓한 조각으로 잘라 두는 것」과 같은 말을 되풀이.
- 제안: 축약안 「해법은 폰트를 90개 남짓한 조각으로 잘라 두는 것, 곧 조각화(subsetting)다.」

#### design-system/references/layout-frames.md

**12.**
- 위치: §1 용어표 비고 칸 세 곳 — 「"예산"=돈이 아니라…」 / 「조판 용어(책 제본 쪽 안쪽 여백…)에서 온 모바일 UI 관행어」 / 「자동차 크롬 트림 유래(겉을 두르는 마감)」
- 분류: A
- 근거: 어원 풀이일 뿐 행동을 바꾸지 않음. 뜻 정의와 「브라우저 이름 아님」 같은 뜻 가르기는 남김.
- 제안: 삭제. 어원 구절만.

**13.**
- 위치: 「컨테이너 쿼리(container query, 화면 전체 폭이 아니라…」 (L153-154)
- 분류: A
- 근거: 앞 구절 「기준은 뷰포트가 아니라 자기가 차지한 공간이다」와 같은 말. 같은 문단의 「뷰포트(화면 전체 폭)」, §3.2의 「엣지-투-엣지(화면 끝까지)」도 같은 성격.
- 제안: 축약안 「기본 수단은 컨테이너 쿼리(container query)다.」

**14.**
- 위치: 「변형 셸에서 화면 전체의 토큰을 비례 조정할 땐 자기참조 calc()…」 (L67-70)
- 분류: B (참조 ↔ 참조)
- 근거: `naming-taxonomy.md` §2 「화면/섹션 단위로 토큰을 비례 조정할 때 … 자기참조 calc()」가 같은 코드와 원리 설명을 가짐.
- 제안: 축약안. 이쪽 코드 블록을 지우고 한 줄로. 별 모양 설계 때문에 참조 문서끼리 가리킬 수 없어 §사람 결정 6.

**15.**
- 위치: 「--safe-bottom: env(safe-area-inset-bottom, 0px);」 (L143)
- 분류: [모순]
- 근거: `grep -rn "safe-bottom\|space-bottom-safe" payload` → `layout-frames.md:143: --safe-bottom` / `naming-taxonomy.md:62: … --space-screen-x · --space-bottom-safe | … 거터·안전영역은 레거시로 --space- 접두 유지`. 같은 안전영역 토큰의 이름이 두 개.
- 제안: 수정안. 한 이름으로 통일 (§사람 결정 3).

#### design-system/references/naming-taxonomy.md

**16.**
- 위치: 용어표 「foundation(1층) | 원시 재료…」~「component(3층)…」 (L10-12)
- 분류: B (스킬층 ↔ 참조층)
- 근거: SKILL.md L14-16의 토큰 계층 정의와 거의 같은 문장.
- 제안: 의도 확인 필요. 참조 문서가 혼자 읽혀도 되게 하려고 둔 것일 수 있음.

**17.**
- 위치: 용어표 「ramp(램프) | …」, 「alias(별칭) | …」 (L13-14)
- 분류: A
- 근거: 일반 디자인 시스템 용어를 AI 지시문 안에서 풀이.
- 제안: 두 행 삭제.

**18.**
- 위치: 「사진·이미지 위 캡션을 제외한 모든 텍스트는 14px 아래로…」 (L76-77)
- 분류: [모순]
- 근거: 여기: 「**사진·이미지 위 캡션**을 제외한 모든 텍스트는 14px 아래로 내려가지 않는다」 / 같은 파일 §6.4: 「`/* 캡션 전용 — 본문 바닥선 아래 값 */`」 (캡션 전반이 바닥선 아래 값을 쓴다는 전제) / `1-user-story.md` §4.3 브리프 §9: 「**캡션(부가 설명 글자)**을 빼면 14px 이상」. 예외 범위가 「이미지 위 캡션」과 「캡션 전반」으로 갈림.
- 제안: 수정안. 예외 범위를 하나로 정해 세 곳을 맞춤 (§사람 결정 2).

**19.**
- 위치: 「(근거: idea-to-mvp `2-mockup.md` — 목업 단계 실사용 검증에서…)」 (L80-82)
- 분류: G
- 근거: 규칙이 어디서 왔는지 적은 설계 이력. 규칙 문장은 이 괄호 없이도 섬.
- 제안: 이동안. 괄호 전문을 `docs/design-notes.md`의 design-system 항목으로.

**20.**
- 위치: §3 「canvas(뷰포트의 배경색 — 웹에선 body background…)」와 「canvas ≠ gutter: …」 (L107, L114-115)
- 분류: B (참조 ↔ 참조)
- 근거: `layout-frames.md` §1 용어표의 canvas·gutter 정의와 겹침.
- 제안: 의도 확인. 별 모양이라 각 문서가 혼자 읽히게 둔 것일 가능성.

**21.**
- 위치: §5 「동심원 규칙(SKILL.md 참조): 컨테이너 안 요소는 `max(0px, …)`」 (L135)
- 분류: B (스킬층 ↔ 참조층)
- 근거: SKILL.md 「동심원 radius 규칙」과 같은 공식. 이미 「SKILL.md 참조」라고 가리킴.
- 제안: 축약안 「동심원 규칙은 SKILL.md 참조.」 의도 확인 필요.

#### idea-to-mvp/SKILL.md

**22.**
- 위치: 「**시작 전 브랜치 확인** — 파일을…」 (L8-14)
- 분류: B (상시 로드 ↔ 스킬층)
- 제안: 1번과 같음.

**23.**
- 위치: 「(`이전 결론 → 이번 결론` 섹션을 산출물 머리에 박는 건 6단계부터 — §2.2)」 (L74)
- 분류: [모순]
- 근거: 같은 파일 §2.2(L142) 「**① `이전 결론 → 이번 결론` 체인은 7단계 전용**이다 … 1~6단계는 … 이 체인을 돌리지 않는다」. grep: `grep -n "이전 결론" 6-*.md` 0건 / `5-frontend-build.md:113` 「그 체인은 7단계 `launch-plan.md`에서 처음 시작한다」.
- 제안: 수정안. 「6단계부터」→「7단계에서만」.

**24.**
- 위치: §1.4 「**반영 위치**: 바뀐 방향은 옛 단계 문서를 고치지 않고 현재(또는 되돌아간) 단계 산출물의 `이전 결론 → 이번 결론` 섹션에…」 (L94) / §2.1 「**중복 금지**: … 지금 단계 산출물의 `이전 결론 → 이번 결론` 섹션에 새로 적는다 (§2.2)」 (L136)
- 분류: [모순]
- 근거: L142 「1~6단계는 … 이 체인을 돌리지 않는다」 / L193 「6단계 안에서 피봇이 나오면 바뀐 내용은 코드에 직접 넣는다 … `backend-build.md`의 `# 빌드 중 발견` 또는 `mvp/adr.md`에 한 줄로」. 1~6단계에서 방향이 바뀌었을 때 어디에 적는지를 두 곳이 다르게 말함.
- 제안: 수정안. 「1~6단계에서 방향이 바뀌면 옛 단계 문서를 고치지 않는다. 코드와 현재 단계 산출물에 반영하고, 이유는 `mvp/adr.md`(또는 6단계면 `backend-build.md` `# 빌드 중 발견`)에 적는다. 문장으로 못 박는 건 7단계 `이전 결론 → 이번 결론`(§2.2)이다」

**25.**
- 위치: 「(예: MarketResearch의 *경쟁자* 항목 → user-story.md의 *현재의 대안과 불편함* 대조)」 (L221)
- 분류: D
- 근거: 확인 질문·표시를 쓰는 단계는 L142·L220대로 6-3과 7뿐. `grep -nE "확인 질문|🔵|🟡|버린 내용" 3-market-research.md` → 무관한 1건만. 3단계는 이 절차를 쓰지 않음.
- 제안: 수정안. 예시를 실제로 쓰는 단계(예: `6-3-backend-deploy.md` §2.7의 매핑)로 바꾸거나 지움.

**26.**
- 위치: 「목업(mockup — 겉모습만 흉내 낸 화면 견본)」 (L46) / 「차별화 축(axis — …)」 (L52) / 「결정 대장(ledger — …)」 (L128, L234에 두 번)
- 분류: A
- 제안: 삭제. 풀이 부분만. 사용자 눈에 닿는 브리프 머리 선언문(`1-user-story.md` §4.1)의 풀이는 대상 아님.

**27.**
- 위치: 「이 자리에 둔 이유는 두 가지다 — 하나, 1↔2 순환에서…」~「…더 기다릴 이유도 없다.」, 「AI 빌더 시대엔 뒤에 이어질 화면 만들기(4·5단계)가 이미 싸서…맞다.」 (L52)
- 분류: G (스킬층 → `docs/design-notes.md`)
- 근거: 3단계를 이 자리에 둔 설계 이유. 규칙은 이 문장들 없이도 섬. 같은 파일 §2.1 표 3행과 `2-mockup.md` §3.1에도 「게이트 아님·유저 자율」 반복.
- 제안: 이동안. 규칙 문장은 남기고 이유 두 문장만. 의도 확인 필요. (4회차 G-1은 같은 문장을 `3-market-research.md` 도입부로 내리는 안 — 목적지가 둘이니 사람 결정.)

**28.**
- 위치: §2.1 표 1행 산출물 칸 「**산출물 두 개.** ① `user-story.md`(UX 서사의 SoT) — 필수 입력(…)…」 (L128)
- 분류: B (정리표가 본문 반복, 스킬층 ↔ 참조층)
- 근거: `1-user-story.md` §1·§2.2·§4.3 내용이 표 칸에 통째로.
- 제안: 축약안 「① `user-story.md`(UX 서사의 SoT) ② `design-brief.md`(화면 문구·미감·UI 패턴의 SoT, 결정 대장). 둘이 어긋나면 브리프가 이긴다. 구성은 `1-user-story.md` §1·§4」

**29.**
- 위치: §2.1 표 6행 references 칸 「순서대로 `6-0-backend-prep.md`(계정·키·…) → …」 (L133)
- 분류: B (같은 파일)
- 근거: §1.3 L75가 6-0~6-3의 내용과 순서를 이미 안내하고 「순서는 이 줄과 파일명이 안내한다」고 정본 선언.
- 제안: 축약안 「`6-0`~`6-3` (순서·내용은 §1.3)」

**30.**
- 위치: §3 「**같은 산출물을 다시 쓸 땐 덮어쓰지 않고 `-v2`를 붙여 쌓는다**」 (L230) + 「**또 하나의 예외** — …」 (L232), 「**명시적 예외** — …」 (L234)
- 분류: [모순] (예외 딱지로 규칙 덧댐)
- 근거: 규칙 문장(L230 「다시 쓸 땐 무조건 -v2」)을 L232가 「판올림은 … 단계를 건너 다시 쓸 때만이다」로 뒤집음. 첫 번째 예외에 「또 하나의」가 붙음. 같은 단계 안 재위임 동작도 `1-user-story.md`와 어긋남(31번).
- 제안: 수정안. 「판올림(`-v2`)은 단계를 건너 다시 쓸 때만 한다 — 2단계에서 되돌아와 스토리를 다시 받을 때(`1-user-story.md` §2.6). 같은 단계 안에서 다듬는 재위임은 같은 파일에 덮어쓴다(`1-user-story.md` §2.5). `design-brief.md`는 판올림 대상이 아니라 결정 대장이다 — 아래.」 §2.4 리뷰 반영을 덮어쓰기에 넣을지는 §사람 결정 1.

#### idea-to-mvp/references/1-user-story.md

**31.**
- 위치: 「**§2.5 스토리보드 반복만 예외** — 그때는 지시서에…」 (L158)
- 분류: [모순] (30번의 짝)
- 근거: 여기 「이미 `mvp/user-story.md`가 있으면 에이전트 자체 규칙대로 `user-story-v2.md`처럼 버전을 올려 저장된다 … **§2.5 스토리보드 반복만 예외**」 / SKILL.md L232 「판올림은 … **단계를 건너 다시 쓸 때**만이다」. 이대로면 §2.4 「수정 요청이 오면 … 에이전트 재위임으로 반영」과 §2.1 재실행 보완은 1단계 안인데도 `-v2`가 생김. `user-scenario-writer.md:210-213`은 지시서에 제자리 덮어쓰기가 없으면 판올림.
- 제안: 수정안. 30번 결정을 따라 예외 목록을 「같은 단계 안의 재위임(§2.4·§2.5)」으로 넓히거나 SKILL 문장을 좁힘.

**32.**
- 위치: 「…그래서 둘 다 2단계 왕복이 수렴할 때까지 살아 있는 산출물이다 (§2.5).」 (L39)
- 분류: C
- 근거: `git show 8a0ee98`에서 「-### 2.5 목업에서 되돌아온 경우 / +### 2.5 스토리보드로 검토하기 … / +### 2.6 목업에서 되돌아온 경우」 확인. 2단계에서 되돌아오는 절은 이제 §2.6.
- 제안: 수정안. `(§2.5)`→`(§2.6)`.

**33.**
- 위치: §3.1 「보다가 결함이 드러나면 §2.5로 되돌아온다.」 (L232)
- 분류: C
- 근거: 32번과 같은 커밋 근거.
- 제안: 수정안. `§2.5로`→`§2.6으로`.

**34.**
- 위치: §5 「**흐름**: 필수 입력과 실제 경험 받기(§2.2) → 브리프 초판 + 에이전트 위임(§2.3) → 결과 리뷰와 브리프 반영(§2.4).」 (L454)
- 분류: D
- 근거: 커밋 8a0ee98이 §2.5 스토리보드 검토 반복을 넣었는데 흐름 줄은 §2.4에서 끝남. 체크리스트 L227에는 §2.5가 들어가 있음.
- 제안: 수정안. 끝에 「→ 스토리보드 검토 반복(§2.5)」 추가.

**35.**
- 위치: 「로그라인(logline — 서비스의 정서를 담은 한 줄 요약)」 (L162)
- 분류: A
- 제안: 삭제. 「로그라인(logline)」까지만.

**36.**
- 위치: 「**매 판 현재 확정 상태 그대로 적는다** — 판올림(`-v2`)한 판에도…」 (L320)
- 분류: B (상시 로드 템플릿 ↔ 참조층)
- 근거: 템플릿 L46 「판올림 문서는 매 판이 완결된 한 편이다 …」와 같은 규칙(에이전트 §작법 규칙에도).
- 제안: 의도 확인 필요. 입력 섹션 템플릿 바로 옆에 둔 이중 배치일 가능성.

#### idea-to-mvp/references/2-mockup.md

**37.**
- 위치: 「**이 단계 이름이 목업(Mockup)인 이유** — 업계에서…」 (L8)
- 분류: G (→ `docs/design-notes.md`)
- 근거: 일반 용어 구분과 단계 이름을 정한 이력. 행동은 안 바뀜.
- 제안: 이동안. 문단 전체. 의도 확인 필요.

**38.**
- 위치: 「옛날엔 다듬을수록 피드백이 겉모습(색·간격)으로 쏠리는 것…」~「…(§4.2).」 (L10 뒷부분)
- 분류: G (→ `docs/design-notes.md`)
- 근거: 정책이 바뀐 경위. 결정 문장(사용자 확정 2026-08-29, 시각 왕복 허용, 브리프를 스펙으로 입힘, 「피드백 오염은 기획자 본인이 감수하는 리스크」)은 이 문장들 없이도 섬. 「눌어붙음이 성립하지 않는다」는 §4.2 L279에도.
- 제안: 이동안. 「옛날엔 … 막았는데, 눌어붙음은 이제 성립하지 않는다 — … (§4.2).」만 옮기고 결정 문장은 남김.

**39.**
- 위치: 「**로그라인**(logline — …)」 (L44)
- 분류: A
- 제안: 삭제. 풀이만.

**40.**
- 위치: §3.1 「**목업 캔버스는 넘기지 않는다.** 뒤 단계는 이 캔버스를 입력으로…」 (L192)
- 분류: B (같은 파일)
- 근거: §4.2 L278-279 「SoT가 아니다」, 「이후 단계가 입력으로 쓰지 않는다 …」와 같은 말.
- 제안: 축약안 「**목업 캔버스는 넘기지 않는다** (§4.2).」

**41.**
- 위치: 「**입력 파일은 에이전트가 읽는다**: … 메인은 미리 읽지 않고 지시서만 넘긴다.」 (L98)
- 분류: [모순] (상시 로드 템플릿 ↔ 참조층)
- 근거: 템플릿 L67 「**부를 때만 들어오는 자료는 메인이 읽고, 걸러서 넘긴다** — 스킬 본문과 `mvp/` 기획 문서는 자동 주입이 아니라서 서브 에이전트에게 안 보인다. … 에이전트에게 "스킬을 먼저 읽어라"고 시키지 않는다」 / 여기: 에이전트가 `mvp/` 문서 셋을 직접 읽고 `/design` 스킬도 직접 호출. `design-brief.md`는 템플릿이 말하는 「규칙 자료」에 해당할 수 있음.
- 제안: §사람 결정 5. 캔버스 입력은 규칙 자료가 아니라 입력 데이터라고 보면 괜찮음. 그렇다면 한쪽 문장에 그 구분을 명시. (4회차 「확신 없어 뺀 것」의 5 §2.2.2 판단과 같은 쟁점.)

**42.**
- 위치: §2.5 「**고치는 자리가 둘로 갈린다 (재시드 규칙).**」 (L149-153)
- 분류: B (2단계 문서 ↔ 5단계 문서)
- 근거: `5-frontend-build.md` §2.2.5(L184-190)와 세 줄이 거의 글자 그대로 같음. 5단계 쪽에만 실사고 줄: 「**재시드 지시에는 "지금 캔버스의 최종 상태를 처음부터 다시 읽어라"를 명시한다.** 실제 사고가 있었다 … 토큰 7건·문구 8건이 어긋났고」
- 제안: 의도 확인. 단계 문서마다 따로 로드되니 중복은 설계일 수 있음. 2단계 재시드에도 같은 사고가 날 수 있으니 그 한 줄을 넣을지는 §사람 결정 7.

### 확신 없어 뺀 것

- **design-system SKILL.md L10 「hex·px 하드코딩 금지」**: 철칙 1·2, 안티패턴 표와 겹치나 명령문이고 첫머리 요약.
- **design-system SKILL.md 안티패턴 표**의 「카드로 감싸기」·「`on-` 토큰」 행: 빠른 참조용 금지 목록이라 뺌. 「글자 크기를 계속 줄여…」 행의 링크에 `§2`를 붙이는 건 무해한 보완.
- **font-loading.md §6 「(하네스에 "화면 검증은 사람 몫"이라는 원칙이 따로 있는데…)」**: 두 규칙이 충돌해 보이는 걸 미리 막는 문장.
- **font-loading.md §1 「원리」 절 전체**: 일반 지식에 가까우나 「90개 남짓」은 §6 관문 수치의 근거.
- **naming-taxonomy.md 용어표의 `on-` 토큰 행**: 한 줄 정의와 §4 포인터.
- **idea-to-mvp SKILL.md 「진실의 원천(SoT — Source of Truth)」 풀이**: 문서 전체에서 쓰는 약어를 처음 정의하는 자리.
- **idea-to-mvp SKILL.md §3의 design-brief 불릿 셋**: SKILL이 「판올림 예외」를 선언하는 자리라 의도적 배치.
- **2-mockup.md L124-125 위계 규칙**(굵기·명도 3단): 외부 `/design` 에이전트가 design-system을 못 읽어서 옮겨 적은 설계.
- **2-mockup.md L167 「자율 재작업은 최대 2회」, L100 재위임 금지 줄**: 실사고로 생긴 지시서 의무.
- **1-user-story.md §3.1 L234**: references 골격(§3.1 핸드오프 필수)에 따른 자리.
- **2-mockup.md L74 「1단계 객체 이름」**: 「스토리에서 쓴 이름」이라는 뜻으로 읽혀 뺌.
- **`/design` 스킬 존재 여부**: payload `skills/`에 없음. 바깥 플러그인이나 내장 스킬로 보여 C 아님.

### 사람이 정해야 할 것

1. **판올림 경계 (30·31번)**: 1단계 안에서 §2.4 리뷰 반영 재위임 때 `-v2`인지 제자리 덮어쓰기인지. 정해져야 SKILL §3과 `1-user-story.md` L158을 하나로 다시 씀.
2. **캡션 예외 범위 (18번)**: 14px 바닥선의 예외가 「사진·이미지 위 캡션」뿐인지 「캡션 전반」인지. `naming-taxonomy.md` §2, §6.4, 브리프 템플릿 §9 세 곳 반영.
3. **안전영역 토큰 이름 (15번)**: `--safe-bottom`과 `--space-bottom-safe` 중 하나.
4. **실측 수치 (8번)**: 커뮤니티 표본 18곳/19곳, SNS 3곳 포함 여부를 원래 조사 기록으로 확인. AI가 고치면 안 됨.
5. **목업 캔버스 입력을 누가 읽나 (41번)**: 템플릿 「메인이 읽고 걸러서 넘긴다」와 2단계 「에이전트가 직접 읽는다」 중 어느 쪽. 입력 데이터와 규칙 자료를 가르는 기준을 문장으로 박을지도.
6. **별 모양 설계와 같은 층 중복의 충돌 (14·20번)**: 참조 문서끼리 가리킬 수 없으니 같은 내용을 양쪽에 두는 걸 허용할지, 한쪽만 남기고 SKILL을 거쳐 안내할지.
7. **2단계 재시드 사고 방지 줄 (42번)**: 5단계에만 있는 「최종 상태를 처음부터 다시 읽어라」 줄을 2단계에도 넣을지.
8. **common-patterns.md의 독자**: 이 문서만 해요체이고 나머지 참조 문서는 평서체. 사용자에게 보여줄 문서가 아니면 톤을 형제 문서에 맞출지, 보여줄 문서면 용어 풀이 규칙을 적용할지.
9. **G 이동 4건 (19·27·37·38번)**: 모두 `docs/design-notes.md`(루트 전용)로 옮기는 안. 옮기면 프로젝트 사본에서는 경위가 사라짐. 그래도 되는지.

### 규칙 인덱스 (판정 없이)

#### design-system/SKILL.md
- 모든 시각 값은 CSS 변수(토큰)로만. hex·px 하드코딩 금지. 토큰 3층. 조립 계층 frame/pattern/screen. 시작 전 브랜치 확인. 프로젝트 AGENTS.md adapter 확인, 없으면 bootstrap. 철칙 0~4(기존 컴포넌트 우선, semantic만 참조, 원시 값은 semantic 안에서만, foundation read-only, 로딩 순서 1→2→3). 새 화면은 frame-first(재사용/변형/독립). 새 UI 요소: 인벤토리 동의어 검색 → 재사용 또는 `--modifier` → 없으면 역할 분류·범용/전용 판정 후 생성 → 등록. 값: semantic 먼저, 없으면 추가, foundation 확장은 원료 없을 때만. 안티패턴 17개. 동심원 radius. 어느 문서를 언제 읽나 7갈래.

#### bootstrap-project.md
- 적용 프로젝트에선 복사 없이 바로 씀, 도입은 §0~§6. §0 외부 목업 이식(프레임 래퍼 한 겹, 가짜 크롬 삭제·`env(safe-area-inset-*)`, `display: none` 전수 수색, 폰트 조각화·이미지 최적화, 반응형 계약, 인라인 스타일 §3 전제, 원본 로컬 보관·추적 해제). §1 3층 구조, foundation read-only, semantic 골격 복사·배선, 폰트 선정, `@import` 순서. §2 범용 컴포넌트 코드째 복사. §3 인벤토리 새로 작성. §4 셸·영역·예산 → frame-budget 토큰, canvas·gutter, 하단 요소, 세 칸. §5 AGENTS.md adapter(경로·import 순서, 인벤토리 위치, 예외·함정 토큰, 철칙 요약, 적용 규칙 요약). §6 다크모드 대비.

#### common-patterns.md
- [표준]/[실측] 표기. §1 실측 근거(2026-09, 37곳). §1.1 유형별 최상단 차례. §1.2 최상단 1·2번은 탐색 진입점, 커뮤니티엔 자동 배너 없음, 커머스 도는 배너는 관례, 커뮤니티 홈 형태 선택, 밀도/여백, 비로그인에도 목록. §1.3 프로젝트가 정할 것. §2 접근성 9개. §3 isComposing 가드, 제목 칸 엔터. §4 자주 빼먹는 곳. §5 컴포저 8개. §6 에디터 9개 + 한국 게시판 관례. §7 프로젝트가 정할 것.

#### component-taxonomy.md
- 분류는 범용 고정, 어휘는 프로젝트 사전. §1 역할 6가지. §2 범용은 업계 표준 영어명, 전용은 자유 + 등록 필수. §3 정본 이름 + 동의어. §4 BEM. §5 결정 트리. §6 개념 단위 등록, 코드가 진실, 한 줄 형식, 머리 주석이 정본, 변경 이력 안 적음, 문서가 이기는 자리 셋, 「지금 쓰는 곳 없음」. §7 이식성.

#### font-loading.md
- §1~§3 프레임워크 무관, §4~§6 Next.js. 조각화 + `unicode-range`. FOUT/CLS 구분. 패밀리는 foundation, 별칭은 semantic. `next/font/google` `subsets: ["latin"]` + `preload: false`. npm 패키지는 `globals.css` `@import`, `next/font/local` 안 씀. CDN `<link>` 금지. OS 폴백 유지. 한 파일에 모음. §6 3관문. 에이전트가 직접 끝까지 확인.

#### layout-frames.md
- 새 CSS 파일 안 만듦. §1 용어 정의 9개. §2 절차. §2.1 셸 공통/변형/독립, 판정 기준, 공유 셸 수정 조건, 승격, 등록, 자기참조 calc(). §2.2 세 칸, 본문만 스크롤, 안전영역, 붙여 띄우기 조건, 새 셸은 세 칸(Cheklist 2026-09-05). §3.1 카드 vs 행. §3.2 여백 한 겹, 방식 A/B. §4.1 canvas. §4.2 gutter. §4.3 `viewport-fit=cover`. §5 브레이크포인트·컨테이너 쿼리. §6 인벤토리 위치.

#### naming-taxonomy.md
- 기존 토큰 불변, 신규만 문법. 용어표. §1 문법·대원칙. §2 유형표 16행, typography 두 갈래, 14px 바닥선, px 점진 이관, 자기참조 calc(), space vs layout. §3 표면 위계. §4 `on-`. §5 radius 위계·동심원. §6 추가 절차 5단계.

#### idea-to-mvp/SKILL.md
- 현재 단계 판별 후 references 읽기. 시작 전 브랜치 확인. §1.1 한 프로젝트 한 아이디어, 화면부터, 통과 기준은 7단계 실측, 3단계는 참고, 1~6은 다듬는 자리, 6·7 얇게, Production 범위 밖, RN. §1.2 단계 판별 규칙. §1.3 references 골격, 6단계 순서·재진입, 톤, 코드명 금지, 초안 모드 우선, 옛 단계 내용 §2.2. §1.4 인터뷰 코칭. §1.5 인터뷰/초안 모드, 안전판 4개. §2.1 산출물 기록성, 릴레이 표, 중복 금지. §2.2 최신 SoT, 체인 7단계 전용, 확인 질문·표시, 화면 SoT 이동, 영역별 SoT, 코드 우선, 6단계 피봇, 단계별 적용. §3 위치, 판올림, design-brief, 앱 코드 한 벌, 캔버스 gitignore, 한 레포. §3.1 ADR. §3.2 `/clear`. §3.3 어휘 swap. §4 진입 평가·건너뜀.

#### 1-user-story.md
- 게이트 아님. §1 두 파일, 변경 주기 분리(실측 v8), 브리프가 이김, 1↔2 살아 있음. §2.1 왜 스토리부터. §2.2 입력 4개(4번은 넣으면→나온다), 미리 채우기, 코칭 4개, 양면 시장, 실제 경험 원문, AI 보완 제안, 확정 전 위임 금지. §2.3 브리프 초판, 위임 필수 (a)~(g), -v2/예외. §2.4 반환 5개 중 3개, 브리프 반영, 어긋남 판정. §2.5 ChatGPT 스토리보드 반복, 제자리 덮어쓰기. §2.6 목업에서 되돌아옴, 얼림. §3 체크리스트 10개, §3.1 핸드오프. §4 정본 선언, 입력 섹션, 브리프 템플릿 10절. §5 톤·흐름·함정.

#### 2-mockup.md
- 게이트 아님. 이름 이유. 보여주는 상대 상승(2026-08-29). §1 feature-list 하나, 캔버스는 도구. §2.1 진입. §2.2 초안 모드, 씨앗 목록, 역할×단계 격자, 세 덩어리, 화면 없는 기능, 기능 한 줄 쓰는 법, 범위 결정. §2.3 외부 능력 확인. §2.4 위임 하나, 지시서 필수, `mvp/mockup/`, 아트보드 규칙, 지시 골자, 링크·`가정` 행. §2.5 사람이 봄, 재시드 규칙, 3갈래 라우팅, 수렴, 재작업 2회. §3 체크리스트 12개, §3.1. §4 위치·템플릿·캔버스 5불. §5 톤.

---

## 4회차 — idea-to-mvp 3·4·5단계 + 6-0·6-1

### 요약

**정독한 파일** (전부 읽음)
- 기준 문서: `AGENTS.md`, `payload/AGENTS.md.template`
- 이번 회차 (참조층): `payload/.claude/skills/idea-to-mvp/references/3-market-research.md`, `4-information-architecture.md`, `5-frontend-build.md`, `6-0-backend-prep.md`, `6-1-backend-db.md`
- 참조 확인용으로만 연 파일: SKILL.md 40~119·124~160·226~262행, `docs/account-check.md` 5~60행, `deep-research/SKILL.md` 60~66행, 그 밖에 grep만 한 파일들.

**분류별 항목 수**

| 분류 | 개수 |
|---|---|
| A | 7 |
| B | 20 (같은 층 14, 층이 달라 의도 확인 6) |
| C | 2 |
| D | 4 |
| E | 0 |
| F | 0 (rules 없음) |
| G | 1 |
| [모순] | 8 |

**요약 검사:** 5개 파일 목차 앵커 전부 살아 있음. 파이썬으로 GitHub 슬러그를 만들어 대조 — `dead anchors: []` × 5.

### 파일별 항목

#### 3-market-research.md

**3-1**
- 위치: §2.5 「각 axis × **사이드 모드 적합도**」 (189행). 같은 개념이 §3 체크리스트, §4.1 표 `사이드 모드 적합도` 열, §5.5 「모드·동기별 적용 차이」에도.
- 분류: D
- 근거: `grep -rn '풀타임\|사이드 모드\|모드·동기' payload docs AGENTS.md`를 이 파일 밖에서 돌리면 0건. `git log -S '풀타임'`: `operator_mode: 풀타임 창업 | 직장 사이드 | …` 정의가 3a6e872(#87)에서 삭제됨. 기준 개념은 없어졌는데 쓰는 쪽만 남음.
- 제안: 수정안. 열을 없애거나 「실행 난이도」처럼 현재 정의된 말로. §5.5는 모드 구분 없이 다시 씀. 대체 기준은 사람이 정함(§사람 결정 1).

**3-2**
- 위치: §2.7 「이 4개(구 "빌더 가드레일")는」 (212행)
- 분류: D
- 근거: `grep -rn '빌더 가드레일' payload` 결과 이 줄 하나뿐.
- 제안: 괄호 삭제. 이력으로 남기려면 `docs/design-notes.md`.

**3-3**
- 위치: §2.2 「deep-research는 **하네스 횡단 스킬**이다 … 요금제·남은 한도 확인 … 여기서 똑같이 묻지 않는다」 (61행) ↔ 분기 「고한도 요금제(예: Claude Max 20x) + 사용량 여유 → `/deep-research` 호출 / … / 그 외 요금제 → 라이트 정찰이 기본」 (65~67행)
- 분류: [모순]
- 근거: 분기하려면 요금제와 한도를 알아야 하는데 바로 위에서 「묻지 않는다」. `deep-research/SKILL.md` 62행이 이미 물음. 두 번 묻거나 근거 없이 분기하게 됨.
- 제안: 수정안. 「라이트 정찰이 기본이다. 사용자가 더 깊게 보길 원하면 `/deep-research`를 부른다 — 요금제·한도 확인과 깊이 합의는 그 스킬이 한다.」

**3-4**
- 위치: §1 「**왜 그래도 이 조사를 하나** — 게이트가 아니라고 조사 자체가」 (36행)
- 분류: B (같은 파일)
- 근거: 바로 위 「뒤 단계 전체의 정찰 겸함」과 뜻이 같음. §2.1-2, §2.5 끝, §3 도입, §3.1에도 반복.
- 제안: 삭제. 「뒤 단계 전체의 정찰 겸함」 한 줄을 정본으로.

**3-5**
- 위치: §2.2 인용 블록 「**정찰이 못 보는 것**: 이 정찰이 보는 건」 (87행)
- 분류: B (같은 파일)
- 근거: 뒤쪽 절반이 57행 「단, 이 0번 줄의 신뢰도는 낮다 …」 문단과 겹침.
- 제안: 축약안 「정찰이 보는 건 밖으로 드러난 대체재까지다. 혼자 만들어 쓰는 임시방편은 검색에 안 잡히니 0번 줄(위)로 메운다. 정찰은 빈틈 가설 생성기일 뿐이다.」

**3-6**
- 위치: §2.2 「사용자가 *경쟁자 없다*고 우길 때: AI가 한 번 더」 (126행)
- 분류: B (같은 파일)
- 근거: §6 응대 톤에 같은 규칙, §6 쪽이 더 완결(§2.4.1로 이어짐).
- 제안: §2.2 쪽 줄 삭제.

**3-7**
- 위치: 풀이 괄호 3건 — §2.2 「_false positive(경쟁자 아닌데 잘못 잡힌 것)_」(125행), §2.4 「해자는 성 둘레에 파 놓은 물길이다 — 후발주자가 쉽게 못 건너는 장벽.」(149행), 해자 표 「(schlep — 하기 싫지만 쌓이면 해자가 되는 고된 노동)」(155행)
- 분류: A
- 제안: 풀이 부분 삭제. 용어는 남김.

#### 4-information-architecture.md

**4-1**
- 위치: §2.1 「이 단계의 입력은 어디까지나 유저 스토리와 기능 목록 둘이다 (SKILL.md §1.1)」 (49행)
- 분류: [모순]
- 근거: 같은 파일 description 「세 입력」과 §1 「**입력은 셋이고 역할이 다르다.**」(user-story·feature-list·design-brief)와 어긋남. SKILL.md §2.1 표도 「스토리(동선)+기능 목록(완전성)+브리프(형태 결정 근거)」. 인용한 SKILL.md §1.1에는 「입력은 둘」 문장이 없음.
- 제안: 수정안. 「3단계 조사는 게이트가 아니라 건너뛸 수 있고, 이 단계의 입력은 §1의 세 문서다.」

**4-2**
- 위치: §4.3 「5단계 캔버스 프롬프트(§2.2.3)가 이 표를 근거로」 (157행)
- 분류: C
- 근거: 이 문서에 §2.2.3이 없음(§2.2는 「일곱 갈래 훑기」). 실제로는 `5-frontend-build.md` 「#### 2.2.3 호출 지시」.
- 제안: 수정안. 「5단계 캔버스 프롬프트(`5-frontend-build.md` §2.2.3)」

**4-3**
- 위치: §3.1 「**이 문서의 수명**: 5단계에서 두 번 쓰이고 끝난다」 (121행)
- 분류: B (참조 ↔ 참조)
- 근거: `5-frontend-build.md` §2.5.6 둘째 줄과 같은 규칙. 적용 시점이 5단계라 4단계 AI에게는 불필요.
- 제안: 축약안 「이 문서는 5단계 마이그레이션이 끝나면 1세대 기록으로 얼린다 (`5-frontend-build.md` §2.5.6).」

**4-4**
- 위치: 풀이 괄호 8건 — 「정보 구조(IA, information architecture — …)」(31행), 「**로그라인**(logline — …)」(47행), 「딥링크(deep link — …)」(68행), 「**① 객체 지도**(OOUX, object-oriented UX — …)」(77행), 「네비게이션 구조(navigation — …)」·「스택(stack — …)」·「모달(modal — …)」·「브레이크포인트(breakpoint — …)」(86행)
- 분류: A
- 근거: 사용자에게 전하라고 인용한 「설명 골자」(53행)에는 풀이가 없으니 제외 대상 아님.
- 제안: 풀이 부분 삭제.

#### 5-frontend-build.md

**5-1**
- 위치: §2.4.1 끝 「**AGENTS.md 자체는 지우지 않는다** — Next가」 (270행)
- 분류: D
- 근거: `git show 492b732`: 이 문단 바로 앞의 「⚠️ Next.js 16 — CLAUDE.md를 멋대로 바꿔치기한다」 경고 세 줄이 #133에서 삭제됨. 「자체는」이 대비하던 대상이 사라짐. 프로젝트 AGENTS.md는 이제 우리 규칙의 정본이라 「Next가 관리하는 정상 파일이라 그대로 둔다」는 틀도 어긋남.
- 제안: 수정안. 「스캐폴딩·첫 `next dev` 뒤 AGENTS.md에 Next 구역(`<!-- BEGIN:nextjs-agent-rules -->`)이 붙어도 지우지 않는다 — 우리 규칙은 `<!-- BEGIN:project-rules -->` 구역에 있으니 서로의 구역을 건드리지 않는다.」

**5-2**
- 위치: §2.4.2 「`.env.example`에 Supabase URL·anon key 자리를」 (276행)
- 분류: D
- 근거: `payload/AGENTS.md.template` 131행 「예전 `anon`은 **Publishable key** … 로 이름이 바뀌었다」, `6-0` §4 장부도 「Publishable·Secret 키」. `6-1` §4 「Supabase 공개 키(anon key)」도 마찬가지.
- 제안: 수정안. 「Supabase URL·공개 키(Publishable key, 옛 anon) 자리」. 6-1 §4도 같이.

**5-3**
- 위치: §5 「**5단계에서 DB까지 붙이자고 할 때**: … 지금은 붙일 자리(프로젝트·환경변수)만 잡아두고」 (541행)
- 분류: [모순]
- 근거: §2.4.2 「이 단계에서 Supabase는 **환경변수 자리만 비워서 잡아둔다** — 프로젝트는 아직 만들지 않는다」. §3·§4도 「프로젝트 생성은 6-0에서」. §5만 「프로젝트」를 이 단계에 잡아두는 것처럼.
- 제안: 수정안. 「지금은 붙일 자리(환경변수 이름·클라이언트 초기화 코드)만 잡아두고」

**5-4**
- 위치: §2.6 첫 배포 체크리스트 「`vercel git connect` → "Connected" 확인」 (454행) ↔ `6-0` §3.3 「`vercel git connect` 명령은 깃허브 앱 권한이 없으면 실패하니, 대시보드에서 직접 연결한다.」 (93행)
- 분류: [모순] (참조 ↔ 참조)
- 근거: 기본 경로가 반대(5는 CLI 우선, 6-0은 대시보드 우선). 실패 처방도 다름 — 5 「GitHub 앱의 저장소 접근 목록에 추가」, 6-0 「대시보드 Connect에서 앱 권한 허용」. `docs/account-check.md` Vercel 항목과 `docs/eval-scenarios.md` #34는 5쪽 처방과 맞음.
- 제안: 수정안. 6-0 §3.3을 「`vercel git connect`가 실패하면 원인은 대부분 저장소 접근 목록 누락이다 — 처방은 `5-frontend-build.md` §2.6 체크리스트」로. 기본 경로는 §사람 결정 2.

**5-5**
- 위치: §2.5.8 「관문 ③만은 예외로, 사용자 노출 문구가 바뀐 라운드에만」 (433행)
- 분류: B (같은 파일)
- 근거: 관문 ③ 둘째 줄(426행)을 반복. 「예외」 딱지로 규칙 덧대기.
- 제안: 수정안. 굵은 제목을 「**관문은 1회성이 아니다 — 관문 ①②는 코드가 바뀔 때마다, ③은 사용자 노출 문구가 바뀐 라운드마다 배포 전에 다시 돌린다**」로, 433행 끝 문장 삭제.

**5-6**
- 위치: §2.7 절차 3 「디자인 시스템 감사와 코드 품질 리뷰는 1회성이 아니다 — 고칠 때마다」 (481행)
- 분류: B (같은 파일)
- 제안: 축약안 「3. 코드를 고쳤으면 배포 전에 §2.5.8 관문을 다시 돌린다 (재실행 기준은 거기).」

**5-7**
- 위치: §3 체크리스트 「**디자인 시스템 감사 통과** (§2.5.8 관문 ① — *검사 공정*) — grep으로 확인: 3층 hex·rgb 0건…」 (502행)
- 분류: B (정리표가 본문 반복) + 어긋남
- 근거: 본문 관문 ①은 검사 여섯(5 「엔터로 확정하는 칸에 한글 조합 가드」, 6 「하단에 붙는 것이 안전 영역을 비웠는가」 포함). 체크리스트는 5·6을 빠뜨림. 해당 줄에서 `isComposing`·`safe-area` 0건.
- 제안: 수정안 「**디자인 시스템 감사 통과** (§2.5.8 관문 ①) — 여섯 검사 전부 재검사까지 0건.」

**5-8**
- 위치: §1 「**'프로토타입'이 붙은 두 이름을 섞지 않는다**」 (16행)
- 분류: B (같은 파일)
- 근거: 바로 위 「**용어 세 개를 섞지 않는다**」 목록이 이미 정의.
- 제안: 삭제. 필요하면 「문서에서는 항상 수식어를 달고 쓴다」 한 구절만 위 목록 끝에.

**5-9**
- 위치: §2.1 「**끝나면 같이 볼 사람이 있는지도 미리 한 번 짚어 둔다**」 (109행)
- 분류: B (같은 파일)
- 근거: 뒷부분이 §2.7 도입과 같음.
- 제안: 축약안 「끝나면 같이 볼 사람이 있는지 미리 한 번 짚어 둔다 — 비의무 (§2.7).」

**5-10**
- 위치: §2.3 끝 「**캔버스는 마이그레이션까지가 쓰임이다.**」 (201행)
- 분류: B (같은 파일)
- 근거: §2.5.6 첫 줄과 같음.
- 제안: 삭제. §2.5.6이 정본.

**5-11**
- 위치: §2.4 「**스택 자체는 이후 에스컬레이션·재논의 대상이 아니다**」 (234행) + 「**고정 범위는 5단계에서 끝나지 않는다.**」 (236행)
- 분류: B (같은 파일)
- 근거: 두 문단 모두 「6단계에서도 다시 고르지 않는다」. §2.4.1 5번도 같음.
- 제안: 축약안. 234행 끝 「— 한 번 정하면 끝까지 고정이고, 6단계에서도 다시 고르지 않는다」를 지우고 236행 문단으로 합침.

**5-12**
- 위치: 도입 「AI 빌더 시대엔 화면 만드는 비용이 거의 0에 가깝다」 (6행). 4번 파일 도입 「거르기는 마지막 단계(MvpLaunch)의 광고 실측에서 한 번만 한다」(6행)도.
- 분류: B (참조 ↔ SKILL.md 발동 시 로드층)
- 근거: SKILL.md §1.1 46행·54행과 같음.
- 제안: 의도 확인 필요.

**5-13**
- 위치: §1 「**2단계 캔버스가 목업, 이 단계 캔버스가 프로토타입인 이유** — 업계에서 목업(mockup)은」 (18행)
- 분류: A
- 근거: 업계 용어 일반 지식에 이름을 붙인 이유. 용어 정의는 바로 위 목록에 있음.
- 제안: 삭제. 보존하려면 `docs/design-notes.md`. (3회차 37번과 짝.)

**5-14**
- 위치: 풀이 괄호 11건 — 「**워킹 프로토타입(working prototype — …)**」(14행), 「로컬스토리지(localStorage — …)」(14행), 「**로그라인**(logline — …)」(101행), 「검색 노출(SEO — …)」(238행), 「RLS(행 단위 보안 규칙)」(278행), 「**관문(gate — …)**」(344행), 「컨테이너 쿼리(container query — …)」(375행), 「첫 번들(bundle — …)」(417행), 「이벤트 리스너(event listener — …)」(419행), 「색인 제외(noindex — …)」(456행), 「시드(seed — …)」(465행)
- 분류: A
- 근거: §2.1 「설명 골자」와 §5에서 사용자에게 하라고 인용한 대사에는 풀이가 없으니 제외 대상 아님.
- 제안: 풀이 부분 삭제.

#### 6-0-backend-prep.md

**6-0-1**
- 위치: §5 「배치 질문(§1.4)으로 한 번에 묻는다」 (192행)
- 분류: C
- 근거: 이 문서 §1에는 하위 절이 없어 §1.4가 없음. 뜻한 곳은 SKILL.md 「### 1.4 인터뷰 코칭 원칙」(86행).
- 제안: 수정안 「배치 질문(SKILL.md §1.4)」

**6-0-2**
- 위치: §3.2 「**[AI]** 생성 직후 `link` … → `db push` … → 시드 데이터 넣기 →」 (87행)
- 분류: [모순] (참조 ↔ 상시 로드층)
- 근거: 템플릿 「클라우드에 시드 넣기」 121행 「**시드 데이터: Supabase 대시보드 SQL 편집기에 `seed.sql`을 붙여넣어 돌린다.** 관리자 키로는 임의 SQL 실행이 안 되므로 CLI로는 못 한다.」 6-0은 이 일을 터미널 명령 몫인 [AI] 연쇄 안에 넣음.
- 제안: 수정안. 「… → `db push` → 시드 데이터는 AGENTS.md 「클라우드에 시드 넣기」 절차대로(대시보드 SQL 편집기 — [Aside]) → …」. 「CLI로는 못 한다」가 지금도 맞는지는 §사람 결정 3.

**6-0-3**
- 위치: §3.6 「**[사람]** `gh`·`vercel`·`docker`의 인증이 전부 소유자 것인지」 (129행)
- 분류: [모순] (같은 파일)
- 근거: (1) 같은 문장 뒷부분이 「`gh`·`vercel`·`supabase`는 전부 …」라 목록이 다름. (2) 몫이 [사람]인데 §5-2 「**AI가 명령으로 실제로 확인한다**」, §6 첫 항목 「AI가 CLI 자체 조회 명령으로 확인」.
- 제안: 수정안 「**[AI]** `gh`·`vercel`·`supabase` 인증이 전부 프로젝트 CLI 전용 파일의 발급 토큰이고 표의 계정 것인지 §2 방식대로 다시 확인한다.」

**6-0-4**
- 위치: §3.5 「**[사람]** … 결제 수단과 월 지출 상한을 같이 설정한다. `.env.local`에만 넣는다.」 (122행)
- 분류: [모순] (같은 파일)
- 근거: 바로 다음 줄 「**[AI]** Vercel 환경변수로 등록한다」, §4 장부 「AI 제공사 키 | … | `.env.local` + Vercel」. 「에만」이 부딪힘.
- 제안: 수정안 「로컬에서는 `.env.local`에 넣는다 (CLI 전용 파일·커밋되는 파일에 두지 않는다).」

**6-0-5**
- 위치: §2 「다르면 그 문서의 인증 규칙대로 맞춘다 — **gh를 포함해 전부** 소유자 계정의」 (43행)
- 분류: B (같은 파일)
- 근거: 바로 아래 표 「계정이 다르면」 행(49행)과 같음.
- 제안: 축약안. 43행을 「다르면 아래 표 「계정이 다르면」 행대로 맞춘다.」로. 표의 행에 이유가 붙어 있으니 그쪽을 남김.

**6-0-6**
- 위치: §3.4 「**[사람]** 로컬에서 소셜 로그인 버튼을 쓰려면 로컬 콜백(」 (117행)
- 분류: B (같은 파일)
- 근거: 콜백 등록 방식은 109~110행과, `.env` 자리는 §4.1 배선표와 같음.
- 제안: 축약안 「**[사람]** 로컬 소셜 로그인을 쓰려면 위 방식대로 로컬 콜백을 등록하고, 로컬용 앱 값을 §4.1 배선표 로컬 자리에 넣는다 — 없으면 로컬 소셜 로그인 버튼이 동작하지 않는다.」

**6-0-7**
- 위치: §2 「**화면 작업은 표가 지정한 프로필로 한다.** 프로필 하나에는」 (53행)
- 분류: B (참조 ↔ 상시 로드층)
- 근거: 템플릿 「소유와 계정」 35줄 문단과 거의 한 글자씩 같음. `docs/account-check.md` 원칙 ④와도. 6-0이 읽힐 때 템플릿은 항상 로드됨.
- 제안: 의도 확인 필요. 줄인다면 「화면 작업 프로필 규칙은 AGENTS.md 「소유와 계정」 그대로다 — 여기선 §2 표 마지막 행으로 대조만 한다.」

**6-0-8**
- 위치: §4 「**이 장부와 계정 표는 답하는 질문이 다르다**」 (148행)
- 분류: B (참조 ↔ 상시 로드층)
- 근거: 템플릿 33행 「**이 표가 답하는 건 「누구의 계정인가」 하나다.** …」와 같음.
- 제안: 의도 확인 필요. 줄인다면 「정본은 이 서식을 채워 옮긴 `mvp/backend-build.md`이고, 여기 표는 서식이다.」만.

**6-0-9**
- 위치: 풀이 괄호 3건 — 「리드타임(lead time — …)」(34행), 「리전(region — …)」(84행), 「비교 테스트(eval — …)」(123행)
- 분류: A
- 근거: 사용자에게 보여줄 체크리스트는 §5-1이 「그 프로젝트의 말로 풀어서」 새로 쓰라고 함.
- 제안: 풀이 부분 삭제.

#### 6-1-backend-db.md

**6-1-1**
- 위치: §3.4 「깔고 나서 한 번 로그인해 둔다.」 (148행)
- 분류: [모순] (참조 ↔ 참조·docs)
- 근거: `6-0` §3.3 「**[Aside]** CLI 인증은 발급 토큰으로 한다」. `docs/account-check.md` Vercel 항목 「CLI 인증은 발급 토큰으로 한다(로그인 갈아타기 금지 — 원칙 ②)」. `vercel login`은 컴퓨터 전체 로그인 세션이라 금지 대상.
- 제안: 수정안 「인증은 6-0 §3.3대로 발급 토큰을 CLI 전용 파일에 두고 넘긴다 — `vercel login`으로 전역 로그인하지 않는다.」

**6-1-2**
- 위치: §1 「이 단계에서 새로 생기는 화면은 동의 온보딩 하나뿐이다 (§2.3 범위 가드)」 (54행). §2.3 셋째 줄(100행)도.
- 분류: B (같은 파일)
- 근거: 첫 문장은 §2.3 첫 줄(98행)과, 둘째는 §1 목록과 서로 반복.
- 제안: 축약안. 54행은 「…다시 오는 일이다 (§2.3).」에서 끝냄. 100행 삭제(§1이 정본).

**6-1-3**
- 위치: §4.3 「DB 비밀번호는 대시보드에서 다시 볼 수 없고 재설정만 되니, 재설정했으면」 (216행)
- 분류: B (참조 ↔ 참조)
- 근거: `6-0` §3.2(85행)와 §4 장부 첫 행에 같은 규칙. 앞 문장(EAUTHQUERY 사고 기록과 우회법)은 실측이라 건드리지 않음.
- 제안: 축약안. 이 한 문장만 「비밀번호를 바꿨으면 `6-0` §4 장부의 「갱신 시 같이 바꿀 곳」대로 Secret도 갱신한다.」

**6-1-4**
- 위치: §2.4 「**로컬(도커)이 개발과 마이그레이션 검증을 맡고**」(108행), §3.2 「**프로젝트 개발 의존성(`--save-dev`)으로 깔고 `npx`로 부른다.**」(136행), §4.1 대시보드 금지, §4.3 ① 래퍼 규칙(224~235행), §4.6 「더하는 마이그레이션 → 먼저 밀고 나서 머지 / 없애는 마이그레이션 → 머지해서 배포된 뒤에 민다」(292~293행)
- 분류: B (참조 ↔ 상시 로드층 템플릿 「이 프로젝트가 쓰는 도구」·「로컬 DB 리셋」, `ship-task` §1.7)
- 근거: 템플릿 101~114행과 `ship-task/SKILL.md` 214~220행에 같은 규칙. 6-1 쪽에는 사고 기록(`public_eggs`)과 이유가 붙음.
- 제안: 의도 확인 필요. 줄이더라도 사고와 이유는 남기고 규칙 문장만 다듬음.

**6-1-5**
- 위치: §4 「**보안 baseline**: auth·API·업로드·`supabase/` 코드를 만지면」 (184행)
- 분류: B (참조 ↔ rules 자동 로드층)
- 근거: `security-baseline.md` 머리말과 헤더 목차를 개수까지 옮겨 적음. 지금은 맞지만(grep 106행 「하지 말 것 아홉」 확인) 규칙이 바뀌면 조용히 어긋남.
- 제안: 축약안 「auth·API·업로드·`supabase/` 코드를 만지면 `.claude/rules/security-baseline.md`가 자동 로드된다 — 광고로 모르는 사람이 실제로 들어오는 코드라 전부 지킨다.」

**6-1-6**
- 위치: §4.7 「**더하기(`create`·`add`)는 되돌리기 쉽다**」·「**지우기(`drop column`·`drop table`)는 못 되돌린다**」 (327~328행)
- 분류: A
- 근거: 명령이 아니라 설명이고 DB 일반 지식. 백업 규칙은 위 문단에 따로.
- 제안: 두 줄 삭제. 셋째 줄은 「확신 없어 뺀 것」.

**6-1-7**
- 위치: 풀이 괄호 14건 — 「로컬스토리지(localStorage — …)」(6행), 「스테이징(staging — …)」(108행), 「드리프트(drift — …)」(112행), 「스왑(swap — …)」(163행), 「publication(…)」·「storage 버킷(…)」(198행), 「`search_path`(…)」(202행), 「트리거 함수(…)」(204행), 「시그니처(signature — …)」(208행), 「래퍼(wrapper — …)」(226행), 「`security definer` 함수(…)」·「`auth.uid()`(…)」(247행), 「Secret(비밀값 — …)」(305행), 「시점 복구(PITR, Point In Time Recovery — …)」(319행)
- 분류: A
- 제안: 풀이 부분 삭제.

#### G [층 이동]

**G-1**
- 위치: `SKILL.md` §1.1 52행 「이 자리에 둔 이유는 두 가지다 — 하나, 1↔2 순환에서」 ↔ `3-market-research.md` 도입 「**왜 2단계 바로 뒤에 조사하나** — 두 가지다.」 (8행)
- 분류: G (SKILL.md 발동 시 로드층 → 참조층)
- 근거: 두 곳이 같은 이유 두 개와 「조사에 필요한 입력 … 더 기다릴 이유도 없다」를 거의 같은 문장으로. 이 이유는 3단계에 들어갔을 때만 필요.
- 제안: 이동안. SKILL.md에는 규칙만 남김. 「이 자리에 둔 이유는 … 더 기다릴 이유도 없다」와 끝 문장 「AI 빌더 시대엔 … 유저 자율을 넓히는 쪽이 맞다」는 3-market-research 도입부로 내림. 3쪽에 없는 구절(끝 문장)은 그대로 붙여 넣어 **한 글자도 잃지 않게**. (3회차 27번은 같은 문장을 `docs/design-notes.md`로 보내는 안 — 목적지 결정 필요.)

### 확신 없어 뺀 것

- **5 §2.2.3의 경위 두 문단** (「과거엔 "문구는 네가 짓지 말고…"」, 「내비게이션 형태를 못 박지 않았던 것도…」): 설계 이력이 섞여 design-notes 후보로 보이나 사고 원문이고 되돌림을 막는 문장. 옮길지는 §사람 결정 6.
- **5 §2.4의 「장기 그림 / 언제 / 무엇으로」 문단**: 이유가 있고, 「앱도 만들자」 답의 근거이며, SKILL.md §1.1이 이 절을 지목.
- **5 §2.5.1 Vercel 플러그인 설치 세부**: 사용자 안내 내용이고 잘못된 안내를 막음.
- **5 §2.2.2 「에이전트가 … 셋을 전문 그대로 읽어」 ↔ AGENTS.md 「부를 때만 들어오는 자료는 메인이 읽고, 걸러서 넘긴다」**: AGENTS.md가 「대상 vs 규칙 자료」를 나눠 두었고 세 파일은 호출 입력(대상)이며 「요약하면 잘린 만큼 화면이 빠진다」는 이유도 있어 모순에서 뺌. (3회차 41번은 같은 쟁점을 [모순]으로 올림 — 판단이 갈리니 사람 결정.)
- **5 §2.7 「(`SKILL.md` 피봇 규칙)」**: 절 번호 없는 약한 참조지만 죽은 참조는 아님.
- **6-0 「`docs/account-check.md` 「서비스별 함정」」**: 실제 헤더는 「서비스별 확인·전환·함정」. 찾아갈 수 있어 C에서 뺌.
- **6-0 §3 참고 상자 「gh는 등록된 계정이 둘이면 …(§2 [실측])」**: 실측 사실이라 어떤 삭제 항목에도 안 올림.
- **6-1 §4.7 「마이그레이션 파일을 git에서 되돌려도 이미 실행된 DB는 안 바뀐다」**: 일반 지식이지만 초보 사용자 함정.
- **3 §2.4.1 「목 좋은 길목인데…」 비유와 「why now」**: 사용자에게 설명할 때 쓰이고 뒤쪽은 판단 항목 목록.
- **3 §2.2 「고한도 요금제(예: Claude Max 20x)」**: 요금제 이름이 바뀔 수 있으나 「예:」 표기이고 3-3을 고치면 함께 사라짐.
- **4 §2.2 일곱 갈래 표의 「딥링크」 등 표 안 풀이**: A 묶음(4-4)에 넣었으나 표를 사용자에게 그대로 보여줄 가능성이 있다면 빼야 함.

### 사람이 정해야 할 것

1. **3단계 「사이드 모드 적합도」를 무엇으로 바꿀지** (3-1): operator_mode가 없어졌으니 열을 없앨지 「실행 난이도」 같은 새 기준으로 바꿀지.
2. **Vercel 깃 연동의 기본 경로** (5-4): CLI `vercel git connect` 기본 + 실패 시 접근 목록 추가인지, 대시보드 Connect 기본인지. 5와 6-0을 한쪽으로.
3. **클라우드 시드의 정식 경로** (6-0-2): 템플릿 「관리자 키로는 임의 SQL 실행이 안 되므로 CLI로는 못 한다」가 지금 Supabase CLI에서도 맞는지 실측 필요. 결과에 따라 템플릿(상시 로드층)과 6-0 중 어느 쪽을 고칠지.
4. **층이 다른 중복을 유지할지** (5-12, 6-0-7, 6-0-8, 6-1-4, 6-1-5): 의도한 강조로 둘지 포인터로 줄일지.
5. **6-0 §3.4 마지막 줄 「로그인 상태가 필요한 흐름을 로컬에서 반복 검증할 때는」(admin API 세션)의 자리**: 6-0은 「사람이 브라우저에서 해야 하는 일」인데 이 줄은 테스트 기법. `grep 'admin API' 6-2 6-3` 0건이라 유일한 거처. 6-2로 옮길지.
6. **5 §2.2.3 경위 두 문단의 설계 이력 부분**을 `docs/design-notes.md`로 옮길지.

### 규칙 인덱스 (판정 없이)

#### 3-market-research.md
- 게이트 아님, 계속·중단은 유저 몫, 거르는 자리는 7단계. 2단계 직후 조사 이유. 목표 4개. §2.1 진입·설명. 입력 둘, 캔버스는 입력 아님. 기존 문서 보완. 소스 셋. 0번 경쟁자. deep-research가 요금제·한도 처리. 본/라이트 정찰 분기, 라이트 기본. 라이트 정찰 방식. 캐는 것 다섯. 정찰 한계. 표본 정직성. 질문 서식. 결과 처리. Step 2~6(WebFetch 보강, 강도 등급·해자 체크, 「없음」 의심 절차, 차별화 축 9개·YC 점수, YC 4인 시뮬, 요약). §3 체크리스트 7항목. §3.1. §4. §5 예시. §6 톤.

#### 4-information-architecture.md
- 입력 셋, 게이트 아님, 읽어 가는 순간 1↔2 동결. 목표. 입력 역할. 빠진 화면 드러내기. §2.1 진입. §2.2 일곱 갈래. §2.3 초안 모드 6개 절. 기능 목록 대조 1:1 아님. §2.4 O/X·미룬 화면 버튼 표. §2.5 보고, 재작업 2회. §3 체크리스트 9항목. §3.1 핸드오프·문서 수명. §4.1 인벤토리 7칸·홈 유형·ID 대조·고아 화면. §4.2 상태 매트릭스. §4.3 미룬 화면 표. §5 톤.

#### 5-frontend-build.md
- 게이트 아님, 앱 코드는 6단계가 이어받음. 용어 셋. 목표 네 스텝. 입력 세 개 역할. 캔버스는 입력 아님. 안 하는 것. 절별 작업 모드. §2.1 진입. §2.2 위임 하나, 지시서 필수, `mvp/prototype/`. §2.2.1 폭. §2.2.2 전문 읽기. §2.2.3 지시 골자. §2.2.4 전수 대조. §2.2.5 `/design` 재시드. §2.3 사람이 봄. §2.4 스택(React 웹 기본, RN, Expo 조건, 고정). §2.4.1 core 표·버전 조사·AGENTS.md 공존. §2.4.2 Supabase 자리만. §2.5 마이그레이션(플러그인, 원본 역할, design-system 방법론, 데이터 층 `lib/storage.ts`, 스코프·에스컬레이션, SoT는 코드, 관문 셋). §2.6 배포(git 연동 정본, 체크리스트, noindex, 클릭 확인). §2.7 같이 보기(비의무). §3 체크리스트 21항목. §4. §5 톤 11항목.

#### 6-0-backend-prep.md
- 계정은 코드보다 먼저(사고). §1 목표·안 하는 것. §2 소유 답, 확인 표 다섯 행, 프로필, 쓰기 직전 재확인, 회사·개인 판정은 사람, 답 없으면 리소스 안 만듦, 잘못된 리소스 처리. §3 몫 표기, Aside 범위, 비밀값 절차, 카카오 [사람], 토큰 이름. §3.1~3.7 서비스별(저장소, Supabase, Vercel, 소셜 로그인, AI 키, Docker, 도메인). 참고 실측 상자. §4 장부(위치·정본·7행·갱신 짝·폐기 전 묻기). §4.1 배선표. §5 체크리스트·명령 확인. §6 완료 기준 10항목.

#### 6-1-backend-db.md
- 6단계 개요, 첫 코드 하위 단계. §1 목표·SoT·안 하는 것 7. §2.1 진입·재진입. §2.2 순서 1~5, 스키마 요약 대화 승인. §2.3 범위 가드. §2.4 환경 2단, 스테이징 없음. §3.1~3.5 도구(Docker, Supabase CLI, gh, Vercel CLI, 하드웨어). §4 RLS 필수·security-baseline. §4.1 마이그레이션 파일. §4.2 search_path·트리거·revoke·시그니처. §4.3 검증 흐름·래퍼·검증 시점. §4.4 클라우드 재확인. §4.5 실데이터 실패. §4.6 마이그레이션 순서·CI·Secret. §4.7 백업·PITR. §4.8 클라우드 리셋 구간.

---

## 5회차 — idea-to-mvp 6-2·6-3·7단계

### 요약

**정독한 파일** (빠진 것 없음)
- 기준 문서: `AGENTS.md`, `payload/AGENTS.md.template`
- 이번 회차: `payload/.claude/skills/idea-to-mvp/references/6-2-backend-auth.md`, `6-3-backend-deploy.md`, `7-mvp-launch.md`
- C 확인용으로 필요한 부분만 연 파일: SKILL.md §1.1·§1.3~1.5·§2.2·§3·§4, 6-0 §4, 5-frontend §2.6, 4-IA 인벤토리 표, security-baseline.md 본문, `payload/.github/workflows/ci.yml`, project-init SKILL.md, agents·skills·hooks 목록

**분류별 항목 수**

| 분류 | 수 | 내역 |
|---|---|---|
| A | 6 | 6-2: 2, 6-3: 4 |
| B | 15 | 같은 층 삭제 후보 6, 층이 달라 의도 확인 9 |
| C | 0 | 목차 앵커 41개와 `§` 참조 전수 대조, 죽은 것 없음 |
| D | 2 | |
| E | 0 | |
| F | 0 | rules 없음. 글롭 실측 결과는 D-1에 |
| G | 0 | 세 파일 모두 참조층이라 내릴 층 없음 |
| [모순] | 6 | |

### 파일별 항목

#### 6-2-backend-auth.md

**[모순]-1**
- 위치: §11.1 규칙 3 「함수를 만들면 실행 권한을…」 (207줄)
- 분류: [모순]
- 근거: 6-2 「함수를 만들면 실행 권한을 모두에게서 회수하고 `authenticated`에만 다시 준다.」 / security-baseline.md 2부 「⚠ 공개 정책이 판정 함수를 타면 `anon`에도 `grant execute` [실측 1건]」 → 「공개 정책이 판정 함수를 타면 `anon`에도 execute를 연다.」 6-2대로만 하면 실측 사고(공개 목록 전체가 안 보임)가 재현됨.
- 제안: 수정안 「함수를 만들면 실행 권한을 모두에게서 회수하고, 그 함수를 타는 정책의 대상 역할에만 다시 준다 — 보통 `authenticated`, 공개 정책이 타면 `anon`까지 (`security-baseline.md` 2부).」

**[모순]-2**
- 위치: §6 표 「브라우저 저장소 | 이 단계에서 걷어내는…」 (124줄)
- 분류: [모순]
- 근거: §6 「이 단계에서 걷어내는 중이다. 남겨 두면 걷어낸 것이 되살아난다」 / §13 ④ 「URL이 아니라 브라우저 저장소에 맡겼다가 콜백 이후 한 지점에서만 복구」 / §13 ⑤ 「`localStorage`나 짧은 만료를 건 쿠키를 쓴다.」 6-3 §3 「로컬스토리지 저장 경로 제거 확인 — 폴백으로도 남아 있지 않음」과 겹치면 AI가 §13의 OAuth 왕복용 임시 보관까지 지울 수 있음.
- 제안: 수정안. §6 표 오른쪽 칸을 「동의는 오래 남아야 하는 기록인데, 이 단계는 브라우저에 오래 쌓는 저장 경로를 걷어낸다」로.

**D-1**
- 위치: 서두 인용문 「코드를 만지면 자동으로 로드되니…」 (21줄)
- 분류: D
- 근거: security-baseline.md `paths` 글롭을 Next.js App Router + `src/` 샘플 트리에 `bash -O globstar`로 돌린 결과:
  ```
  **/api/**/*    → src/app/api/events/route.ts
  **/auth/**/*   → src/app/auth/callback/route.ts
  **/middleware* → src/middleware.ts
  **/upload*     → (없음)
  supabase/**/*  → supabase/migrations/001_init.sql, supabase/tests/rls.test.sql
  ```
  안 걸린 파일: `src/proxy.ts`, `src/lib/supabase/server.ts`, `src/lib/supabase/client.ts`, `src/app/(auth)/login/page.tsx`, `src/app/login/page.tsx`. §10이 받아오는 세 파일이 바로 「하지 말 것」 ②③④⑨가 걸리는 파일인데 규칙이 자동 로드되지 않음. (2회차 S1과 같은 발견.)
- 제안: 수정안. 고칠 곳은 security-baseline의 `paths`(§사람 결정 1). 글롭을 안 고친다면 이 줄을 「`supabase/` 폴더(정책·마이그레이션)를 만지면 자동으로 로드된다」로 좁힘.

**B-1**
- 위치: 서두 「⚠ 여기 적힌 외부 도구(Supabase 등)의…」 (25줄)
- 분류: B (상시 로드층 ↔ 참조층)
- 근거: 템플릿 「규칙이 낡았을 때」와 뜻이 겹침. 6-2에만 있는 내용은 「[공식]일수록 더, [우리 결정]·[실측]은 그대로 지킨다」와 「따라 하기 *전에* 확인」. 강도도 조금 다름(템플릿 「문안을 준다」, 6-2 「보고한다」).
- 제안: 축약안. 공통부는 「AGENTS.md 「규칙이 낡았을 때」대로 하되」로 줄이고 등급별 차이 문장만.

**B-2**
- 위치: §2 「⚠ 이 절도 한국 기준이고…」 (72줄)
- 분류: B (같은 파일)
- 근거: 18줄 서두 인용문이 §1~9 전체를 덮고 목차보다 앞이라 항상 읽힘. §9 표에도 법률 검토 표시.
- 제안: 삭제.

**A-1**
- 위치: §3 표 3행 「(nullable — 값이 없어도 되는 칸)」 (88줄)
- 분류: A
- 제안: 삭제 「비어도 되게(nullable) 만든다」만.

**A-2**
- 위치: §8 「트리거(trigger — 표에 값이…)」 (137줄)
- 분류: A
- 제안: 삭제 「트리거(trigger)」만.

#### 6-3-backend-deploy.md

**[모순]-3**
- 위치: §4.1 템플릿 `# 배포 정보` 블록 「- URL: ... / - 배포 방식:」 (218~220줄). §3 「`backend-build.md` 작성됨」(181줄)도.
- 분류: [모순]
- 근거: 6-0 §4 146줄 「아래 표를 채워서 `backend-build.md`의 "배포 정보" 아래에 옮겨 둔다.」 / 148줄 「`mvp/backend-build.md` 쪽이 정본이고, 여기 표는 서식이다.」 / 6-3 §4.1 `# 배포 정보`에는 URL과 배포 방식 두 줄뿐 / 181줄 나열에 장부 없음. 비밀값 장부의 정본 자리가 산출물 서식에 없음.
- 제안: 수정안. §4.1 `# 배포 정보` 아래에 `## 비밀값 장부 (서식: 6-0-backend-prep.md §4)` 한 줄, 181줄 나열에 「비밀값 장부」.

**[모순]-4**
- 위치: §2.3 기본 세트 표 「**색인 제외 상태** — 아직 공개 전인 5단계…」 (84줄)
- 분류: [모순]
- 근거: §2.3 「아직 공개 전인 5단계 상태면 켜져 있어야 | 공개하는 날 이 테스트를 뒤집는다」 / §2.2 2번 「5단계에서 걸어둔 색인 제외를 여기서 푼다… 공개할 페이지만 열고 운영 콘솔·개인 전용 화면은 계속 막아둔다」 / §3 173줄. 스모크 도입 시점엔 이미 「공개 허용, 비공개 제외」 상태여야 함.
- 제안: 수정안. 표 행을 「**색인 제외 범위** — 공개 페이지는 색인 허용, 운영 콘솔·개인 전용 화면은 색인 제외 | §2.2 2번이 연 범위와 짝 — 한쪽만 고치면 걸린다」로, 174줄 「색인 제외」→「색인 제외 범위」.

**B-3**
- 위치: 서두 「6단계 도중에 다시 들어왔다면 §3 체크리스트를…」 (8줄)
- 분류: B (같은 파일)
- 근거: §3 163줄과 같은 말. SKILL.md §1.3도 재진입을 6-3으로 보냄.
- 제안: 삭제. 8줄의 두 번째 문장만.

**B-4**
- 위치: §5 「**빌드 중**: 잘게 확인 요청 금지…」 (246줄)
- 분류: B (같은 파일)
- 근거: §1 35줄과 §2.1 48줄이 같은 행동을 정함. §5는 응대 톤 절인데 이 줄엔 사용자 문구가 없음.
- 제안: 삭제.

**B-5**
- 위치: §2.6 끝 「백엔드 연동·베타 공유·계측·배포가 모두 끝나면…」 (143줄)
- 분류: B (같은 파일)
- 근거: §1 33줄과 §3 163줄과 같음. 실제 관문은 §3.
- 제안: 삭제.

**B-6**
- 위치: 서두 「⚠ 여기 적힌 외부 도구(Vercel·Supabase·Next.js 등)의…」 (10줄)
- 분류: B (상시 로드층 ↔ 참조층)
- 근거: 템플릿 「규칙이 낡았을 때」와 겹침. 6-3에만 있는 내용은 「[실측] 숫자는 다시 재되 교훈은 지킨다」.
- 제안: 축약안. B-1과 같은 방식.

**B-7**
- 위치: §2.7 첫 문단 「이 단계 산출물에 옛 문서 내용을 근거로…」 (147줄)
- 분류: B (스킬층 ↔ 참조층)
- 근거: SKILL.md §2.2 절차를 다시 쓴 문단. SKILL.md §2.2 「단계별 적용」 「references는 §2.2 절차를 *그대로* 사용. 단계별로 추가 박는 것: 매핑… 표시 판정 적용 예시 1~2개」 — 보강 범위를 넘음.
- 제안: 축약안 「SKILL.md §2.2 확인 질문·표시를 그대로 쓴다. 걸러진 내용은 §4.1 템플릿 끝 버린 내용 목록에.」 매핑 표와 예시는 그대로.

**B-8**
- 위치: §2.6 1번 「(`security-baseline.md`는 *쓸 때* 지키는 규칙이고…)」 (137줄)
- 분류: B (상시 로드층 ↔ 참조층)
- 근거: 템플릿 검증 절과 거의 글자 그대로 같음.
- 제안: 축약안. 괄호만 삭제.

**B-9**
- 위치: §2.4 끝 「**사용자가 직접 클릭하며 검증한다** — AI가 Playwright…」 (108줄)
- 분류: B (상시 로드층 ↔ 참조층)
- 근거: 템플릿 「화면 검증은 사람 몫이다」와 같은 뜻. 같은 파일 §1 35줄·§2.6 3번에도.
- 제안: 축약안 「사용자가 직접 클릭하며 검증한다 (SKILL.md §1.5 사람 몫).」

**B-10**
- 위치: §3 「마이그레이션이 든 PR을 머지했다고 자동으로 올라가지 않는다.」 (167줄)
- 분류: B (상시 로드층 ↔ 참조층)
- 근거: 템플릿 「마이그레이션은 자동으로 안 올라간다 — …」와 같음. 체크 항목 자체는 남김.
- 제안: 축약안. 설명 문장만 삭제.

**A-3**
- 위치: §2.2 1번 「(OG — 링크를 카톡·슬랙에…)」 (54줄)
- 분류: A
- 제안: 삭제 「공유 미리보기(OG)」만.

**A-4**
- 위치: §2.3 「(smoke test — 크게 깨진 데가…)」 (67줄)
- 분류: A
- 제안: 삭제 「스모크 테스트(smoke test)」만.

**A-5**
- 위치: §2.5.1 「(Runtime Logs, 서버 실행 중 발생한…)」 (129줄)
- 분류: A
- 근거: 메뉴 이름 「Runtime Logs」는 찾아갈 위치라 남김.
- 제안: 삭제 「런타임 로그(Runtime Logs)」만.

**A-6**
- 위치: §2.6 「스켈레톤(skeleton — 본문이 오기 전…)」 (135줄)
- 분류: A
- 근거: 같은 문단의 실측 값과 내부 상수 경고는 건드리지 않음.
- 제안: 삭제 「스켈레톤(skeleton)」만.

#### 7-mvp-launch.md

**D-2**
- 위치: §3 「비밀값 장부(`6-0-backend-prep.md` §4)의 만료일을…」 (145줄)
- 분류: D
- 근거: 채워진 장부가 아니라 빈 서식을 가리킴. `6-0-backend-prep.md:146` 「아래 표를 채워서 `backend-build.md`의 "배포 정보" 아래에 옮겨 둔다」 / `:148` 「`mvp/backend-build.md` 쪽이 정본이고, 여기 표는 서식이다」. 이대로면 7단계 AI는 예시 행만 있는 빈 서식을 열게 됨.
- 제안: 수정안 「비밀값 장부(`mvp/backend-build.md` 「배포 정보」 아래 — 서식은 `6-0-backend-prep.md` §4)」. [모순]-3을 먼저 고쳐야 가리키는 자리가 생김.

**[모순]-5**
- 위치: §2.2 「에러 로그(6단계에서 확보한 관측 수단 — `backend-build.md` 배포 정보 참조)」 (104줄)
- 분류: [모순]
- 근거: 6-3 §4.1 `# 배포 정보` 템플릿은 URL과 배포 방식뿐. 6-3 §3 177줄 「에러 로그 확인 수단 확보 (§2.5.1) — 최소 Vercel 런타임 로그 확인 방법 숙지」 — 적으라는 말이 없음.
- 제안: 수정안. 6-3 §4.1 `# 배포 정보`에 `- 에러 확인 위치: (예: Vercel Runtime Logs / Sentry 프로젝트)` 한 줄, 177줄을 「…확인 방법을 `backend-build.md` 배포 정보에 적음」으로.

**[모순]-6**
- 위치: §2.1 채널 계획 「6단계에서 검색 노출을 켰으면(…)」 (90줄)
- 분류: [모순]
- 근거: 7은 켜지 않았을 수도 있다는 조건문인데 6-3 §3 173줄(필수) 「검색 노출 기본 세트 + curl 판정 통과… 5단계 색인 제외를 공개 페이지만 풀었고」.
- 제안: 수정안 「6단계에서 검색 노출을 켰으니(`6-3-backend-deploy.md` §2.2) 검색으로 들어오는 사람이 생긴다.」

**B-11**
- 위치: §2.1 「계측 이벤트 *정의*만은 예외 없이 **코드**…」 (70줄 가운데)
- 분류: B (같은 파일)
- 근거: 34줄, 74줄, 68줄, 템플릿 181줄에 같은 말.
- 제안: 삭제. 70줄의 그 한 문장만.

**B-12**
- 위치: §2 단계 시작 ③ 「`launch-plan.md` 머리에 `# 이전 결론 → 이번 결론`을 적는다…」 (38줄)
- 분류: B (같은 파일)
- 근거: §2.1.1 3번(63줄)과 같은 내용.
- 제안: 축약안 「`launch-plan.md` 머리의 `# 이전 결론 → 이번 결론`은 §2.1.1 3번에서 채운다.」

**B-13**
- 위치: §2.1 「옛 문서에서 가져오는 내용은 SKILL.md §2.2 검토 절차를…」 (70줄 첫 문장)
- 분류: B (스킬층 ↔ 참조층)
- 근거: B-7과 같음. 예시(1단계 불편함 → 확인 질문 4번)는 스킬이 허용한 보강이라 남김.
- 제안: 축약안 「옛 문서에서 가져오는 내용(…)은 SKILL.md §2.2 확인 질문·표시를 그대로 거친다.」 뒤에 예시만.

**B-14**
- 위치: 서두 「사람을 구해 앉혀놓고 묻는 인터뷰는…」 (6줄)
- 분류: B (스킬층 ↔ 참조층)
- 근거: SKILL.md §1.1 「사람을 구해 앉혀놓고 묻는 인터뷰는 *말*이라 … 행동이라 거짓말을 못 한다」와 거의 같은 문장. 스킬 본문은 7을 읽기 전에 항상 로드.
- 제안: 축약안. 첫 문장 「이 단계는 말이 아니라 행동으로 가설을 판정하는 이 스킬의 유일한 통과 기준이다」만.

**B-15**
- 위치: §2.3 go 갈래 「이 하네스의 범위 밖 (매출 스케일업·운영 자동화·다채널…)」 (114줄)
- 분류: B (스킬층 ↔ 참조층)
- 근거: SKILL.md §1.1 「Production은 이 스킬의 범위 밖 — …」와 같음. 바로 아래 「"production 졸업"은 사업 단계 얘기지 인프라 얘기가 아니다」는 7에만 있으니 남김.
- 제안: 축약안. 괄호만 삭제.

### 확신 없어 뺀 것

- **6-3 §2.2 4번 「**스트리밍**(화면 뼈대를 먼저 보내고…)」 풀이** — 다음 문장이 이 풀이에 기댐. 함정의 원리 설명.
- **6-3 §2.3 「5단계에는 테스트를 쓰지 않는다 — …」** — 5-frontend에서 grep 0건. 이 결정은 이 문서에만. 설계 경위지만 G는 스킬↔참조 사이만.
- **6-3 §2.1 「에스컬레이션: 명세와 모순 발견·…」** — SKILL.md §1.5와 겹치지만 「외부 서비스 추가」 6단계 전용 조건.
- **6-3 §2.5 「이벤트 정의는 코드에만 둔다」 ↔ 7 §1 SoT 문장** — 읽는 단계가 달라 로드 시점이 다름.
- **6-3 §2.1 「1부 외부 도달 baseline(…)」 나열** — 목차 수준 요약.
- **6-2 §11 「이 표도 RLS 예외 없음」 ↔ §11.3 ①** — 몇 글자라 이득 없음.
- **7 서두 「숫자를 보고 나서 기준을 정하면 창업자 뇌는…」, 「소액 광고의 한계를 알고 쓴다」** — §6에서 사용자 설득 근거로 쓰임.
- **7 §3 마지막 「frontmatter `status: confirmed`」** — 어느 파일인지 안 적힘. 문맥으로 launch-retro. 「launch-retro.md」를 붙이는 게 낫지만 오작동 사례 확인 못 함.
- **7 실패 갈래 표의 「온보딩」이 6단계·5단계 행 둘 다** — 동의 온보딩과 랜딩 온보딩을 다르게 가리키는 것일 수 있음.
- **세 파일의 frontmatter `description`이 긴 설명** — references는 파일명으로 부르기 때문에 description이 쓰이는지 확인 못 함.

### 사람이 정해야 할 것

1. **security-baseline `paths`를 넓힐지** (D-1) — `'**/proxy*'`·`'**/lib/supabase/**'` 추가인지, 6-2 설명을 좁힐지. (2회차 §사람 결정 4와 같은 결정.)
2. **6단계 중간 배포의 경로** — 6-3 §2.2 끝 「연동이 끝나면 배포해 링크를 갱신한다… 재배포하면 된다」. 배포 정본은 git 연동(main 머지 = 자동 프로덕션, 5-frontend §2.6)이고 머지는 사용자 확인 뒤 `/done-task`로만. 베타 공유용 중간 배포를 main 머지로 할지 미리보기 배포로 할지 문서가 말하지 않음. CLI 수동 배포로 오해될 여지.
3. **라우트 정적 검사를 CI에 어떻게 붙일지** — 6-3 §2.3 「라우트 정적 검사는 CI에서 돈다」인데 `ci.yml`에는 `npm ci`·`lint`·`build`·밀린 마이그레이션 감지뿐. lint·build 스크립트에 넣으라는 뜻인지 CI 단계를 따로 두라는 뜻인지. pgTAP는 6-2 §12가 「CI에 아직 없다」고 적어 D 아님.
4. **광고 계정(Meta·네이버 등)을 「소유와 계정」 표에 넣을지** — 7 §2.2 「집행(광고 계정 세팅·게시)은 사용자가」. 템플릿 표와 account-check 모두 광고 계정 행 없음(`광고|Meta|네이버` grep 0건).
5. **6-3 [모순]-3과 7 [모순]-5의 수정 방향** — `backend-build.md` 템플릿 「배포 정보」에 비밀값 장부와 에러 확인 위치를 넣을지, 7의 포인터를 6-0·6-3 본문으로 돌릴지. 앞쪽 안이 6-0 §4 기존 지시와 맞음.
6. **(참고) SKILL.md §1.3 「6단계부터」 ↔ §2.2 「7단계 전용」** — 3회차 23번과 같은 발견. 6-3에는 이 섹션이 없어 §2.2 쪽과 맞음.

### 규칙 인덱스

#### 6-2-backend-auth.md
- 문서 구성(앞 §1~9 법·흐름, 뒤 §10~13 기술). 법률 자문 아님, 한국 기준, 법 조문 번호 안 적음. Supabase + Next.js 고정. 권한 규칙은 security-baseline 2부. 근거 등급 셋. 외부 도구 시점 기준. §1 필수/선택 가르기. §2 필수만이면 고지문 한 줄, 동의 간주 표현 금지. §3 체크박스 분리, nullable, 마이그레이션 반영. §4 소셜 로그인은 가입·로그인 못 가름. §5 흐름(기존 바로 로그인, 신규 온보딩), design-system 따름, 클라우드 확인. §6 체크박스 기억 자리 둘 다 막힘. §7 동의 증적 책임. §8 가입 트리거. §9 약관·처리방침 두 페이지, 사실대로, 법률 검토 표시. §10 공식 참조 구현 받기(①②③), 경로 시점, 코드가 정본. §11 역할 표(enum, `user_roles`, RLS), 규칙 1~4, 바깥 계약 고정. §11.2 미루는 것. §11.3 ①~⑤. §12 pgTAP 최소 셋, 정체성 전환, 42501 vs 빈 결과, 테스트가 기록, CI 미연결. §13 ①~⑥ 세션·리다이렉트.

#### 6-3-backend-deploy.md
- 6단계 완료 체크리스트·산출물 스펙 여기. 외부 도구 시점 기준. §1 목표·초안 모드·범위 가드. §2.1 로컬스토리지 → Supabase, 코드 삭제, security-baseline, 에스컬레이션. §2.2 SEO ①~⑤(기본 세트, 색인 제외 풀기, 200/404, `loading.tsx` 함정, curl 판정), 재배포. §2.3 스모크 테스트(6단계 도입, 기본 세트 7행, `node:test`, CI 한계, 라우트 정적 검사, 손 확인 두 번째면 테스트로). §2.4 베타 공유(선택, 치명 결함 확인, 사람 클릭). §2.5 계측 5종·채널 구분·전용 이벤트·Supabase 테이블·RLS·정의는 코드. §2.5.1 Runtime Logs. §2.6 리전, 스켈레톤, ①~⑤(security-review, PR 워크플로, 클릭, 결제·환불, 재작업 2회). §2.7 옛 내용 검토·매핑·예시. §3 체크리스트 19항목. §3.1. §4 산출물·템플릿·frontmatter. §5 톤·구조 변경·범위 압박·완료 안내.

#### 7-mvp-launch.md
- 유일한 판정 단계, 행동으로 판정. 기준 동결. 채널 이중. §1 목표·SoT. §2 단계 시작 ①②③, 재실행. §2.1 launch-plan 확정 전 광고 금지. §2.1.1 확정 4개(후보 생성, 순서대로 확인, 형식, 이전 결론→이번 결론, AGENTS.md 정의 줄). 모드(초안/인터뷰). 옛 문서 §2.2 절차. 퍼널 ①~④(go 선 표, 예산·기간, 채널 계획, 동결). §2.2 소재·카피 초안, 집행은 사용자, 발품, 측정 기간 룰. §2.3 판정 자료 초안, 판정은 사람, 3분기, 실패 갈래 표, Use·Love·Pay. §3 체크리스트 9항목. §4 두 템플릿. §5 예시 4쌍. §6 톤.

---

## 6회차 — 교차 검토 (보고서만 읽음)

읽은 파일: 이 보고서 하나. 원문 지시 문서는 열지 않았다. 표기법: `회차:항목` (예 `2:S1`, `4:6-1-5`), 회차별 사람 결정은 `회차:결N`.

결과: 층 간 중복 13묶음 / 층 간 모순 후보 11건 / 서로 안 가리키는 흩어짐 13건 / 사람 결정 37개 → 27개 (따로 정할 필요 없는 것 1개).

### 1. 층 간 중복

- **X1. 「시작 전 브랜치 확인」 블록** — `2:H1`, `3:1`, `3:22`. 상시층 ↔ 스킬 4개. transfer-ownership 블록은 2회차 인덱스에만 있고 판정 안 됨. 명령이 `git rev-parse`로 다른 건 design-system에서만 확인 — 나머지 셋은 원문 확인 필요.
- **X2. 「⚠ 외부 도구 시점 기준」 문단** — `5:B-1`, `5:B-6` ↔ 템플릿 「규칙이 낡았을 때」. transfer-ownership에도 있는데 2회차에서 판정 안 됨.
- **X3. fork 스킬 본문 안에 메인에게 하는 말** — `1:2`, `1:9`, `1:14`, `1:13`.
- **X4. CLI 인증은 발급 토큰으로, 전역 전환 금지, 환경변수 우선** — `2:P6`, `2:T5`, `2:AC3`, `4:6-0-5`. 상시·스킬·docs·참조 네 층.
- **X5. 브라우저 프로필 원칙** — `2:AC4`, `4:6-0-7`. 거의 글자 그대로인 세 벌(템플릿 35·account-check ④·6-0 §2 53)을 두 회차가 쌍으로만 봄.
- **X6. 판올림 문서는 매 판이 완결본** — `2:U2`, `3:36` ↔ 템플릿 46. 세 벌.
- **X7. 마이그레이션 순서와 「자동으로 안 올라간다」** — 1회차 「확신 없어 뺀 것」(ship-task §1.7 ↔ 템플릿 ↔ ci.yml), `4:6-1-4`, `5:B-10`. 네 벌 + ci 주석. 회차마다 판정이 다름(Y6).
- **X8. security-baseline 자동 로드 조건 재서술** — `4:6-1-5`, `5:B-8`, `5:D-1`. 세 곳 다 「auth·API·업로드·supabase 코드를 만지면 로드된다」인데 `2:S1`·`5:D-1` 글롭 실측에서 `lib/supabase/`와 `proxy.ts`는 안 걸림.
- **X9. SKILL §2.2 확인 질문·표시 절차 재서술** — `5:B-7`, `5:B-13`. `3:25`(SKILL 예시를 6-3 §2.7로)와 맞물림 — 3:25를 먼저 고침.
- **X10. 「게이트 아님, 거르기는 7단계에서만」** — `3:27`, `4:3-4`, `4:5-12`, `5:B-14`, `5:B-15`. 허브와 단계 문서 전부에 퍼짐.
- **X11. 「캔버스는 다음 단계 입력이 아니다」와 캔버스 수명** — `3:40`, `4:4-3`, `4:5-10`.
- **X12. 같은 용어 풀이 괄호 반복 (A 26건)** — 로그라인 네 벌(`3:35`, `3:39`, `4:4-4`, `4:5-14`) / 결정 대장(`2:U4`, `3:26`) / 컨테이너 쿼리(`3:13`, `4:5-14`) / 로컬스토리지(`4:5-14`, `4:6-1-7`) / 트리거(`4:6-1-7`, `5:A-2`).
- **X13. 단계 이름 유래 문단** — `3:37`, `4:5-13`. 짝인데 분류가 갈림(Y5).

### 2. 층 간 모순 후보

- **Y1. 목업 캔버스 입력을 누가 읽나 — 판정 반대.** `3:41` [모순] vs 4회차 「확신 없어 뺀 것」(5 §2.2.2). 4회차 근거 「대상 입력 vs 규칙 자료」는 템플릿 문장과 맞음. 2-mockup L98이 `design-brief.md`(규칙 자료 성격)까지 에이전트가 읽게 하는지 원문 확인 필요.
- **Y2. SKILL 「6단계부터」 vs 「7단계 전용」 — 같은 발견.** `3:23`과 `5:결6`. 판정 같아 결정 불필요. 짝인 `3:24` 수정안이 가리키는 `backend-build.md` `# 빌드 중 발견` 섹션이 6-3 §4.1 템플릿에 있는지 확인 필요(`5:[모순]-3` 참조).
- **Y3. security-baseline paths — 같은 실측인데 분류만 다름.** `2:S1` F, `5:D-1` D. `4:6-1-5` 축약안은 글롭 결정(통합 6번) 뒤에 적용. `1:18`도 같은 6-2 §10 세 파일을 근거로 삼음.
- **Y4. 「이 자리에 둔 이유」 G 이동 목적지 충돌.** `3:27` design-notes vs `4:G-1` 3-market-research. 3:27안의 문제: design-notes는 payload에 없어 프로젝트 사본에서 사라짐(`2:A1`) / G 정의가 「스킬↔참조 사이」인데 docs/는 그 층이 아님. G-1안은 정의 안이고 3-market-research에 거의 같은 이유가 이미 있어 사실상 B 정리.
- **Y5. 이름 유래 문단 분류가 갈림.** `3:37` G vs `4:5-13` A. 같은 처리가 맞음.
- **Y6. 마이그레이션 순서 중복 판정이 셋으로 갈림.** 1회차 「의도된 이중 배치」로 뺌 / `4:6-1-4` B 의도 확인 / `5:B-10` B 삭제 제안.
- **Y7. docs ↔ 상시층 겹침 판정이 갈림.** 1회차는 git-workflow ↔ 템플릿을 「사람용 참조」로 뺌 / `2:AC4`는 account-check ↔ 템플릿을 B로. account-check는 AI가 읽는 절차서, git-workflow는 사람용이라 기준이 달라도 될 수 있음.
- **Y8. SoT 풀이 판정이 갈림.** `2:P1` A(삭제) vs 3회차 「첫 정의라 남김」. project-init이 SoT를 계속 쓰는지 확인 필요.
- **Y9. ci.yml 수정안과 5단계 수정안의 전제 충돌.** `1:18`안 「5단계까지는 Supabase 클라이언트를 import하는 코드가 없어 env 없이 빌드 통과」 vs `4:5-3`안 「붙일 자리(환경변수 이름·**클라이언트 초기화 코드**)만 잡아두고」. 5-3대로면 1:18 전제가 깨질 수 있음. 5 §2.4.2 원문 확인 후 한쪽에 맞춤.
- **Y10. gh 계정 전환 허용 여부.** ship-task §1-0 소프트 「폴백이고 표 계정이 등록돼 있으면 전환 후 진행」(`1:6`은 「로컬」 표현만 고침) vs 루트 AGENTS 「전역 활성 계정 전환은 쓰지 않는다」·account-check ② 「gh 전환 안 함」. `2:AC3`의 「옛 프로젝트만 임시로…」 폴백이 이 전환을 허용하는 문장이면 모순 아님 — 원문 확인 필요.
- **Y11. 판올림 예외의 수정 범위.** `3:30`·`3:31` 수정안은 SKILL과 1-user-story만 고침. user-scenario-writer 저장 규칙 210~213(「제자리 덮어쓰기 지시가 없으면 판올림」)도 같이 고쳐야 함.
- **(참고) `4:6-1-3` 축약안의 포인터** — 6-0 §4 「갱신 시 같이 바꿀 곳」을 가리키는데 `5:D-2`는 「6-0 §4는 빈 서식」이라 함. 규칙 열을 가리키는 거면 서식으로도 충분할 수 있음.

### 3. 서로 안 가리키는 흩어짐

- **Z1. 비밀값 장부의 정본 자리** — 6-0 §4 「backend-build 배포 정보 아래로」 vs 받는 쪽 6-3 §4.1·§3에 장부 없음. 7 §3·6-1 §4.3은 빈 서식을 가리킴(`5:[모순]-3`, `5:D-2`).
- **Z2. 에러 확인 위치** — 7 §2.2는 backend-build를 가리키는데 6-3 §2.5.1·§3에 적으라는 말 없음(`5:[모순]-5`).
- **Z3. 판올림 규칙 네 벌** — 템플릿 46 · SKILL §3 · 1-user-story L158·L320 · user-scenario-writer. 에이전트 규칙을 가리키는 건 L158뿐.
- **Z4. CLI 발급 토큰 인증** — 루트 AGENTS · account-check ②/gh/Vercel · project-init 89 · transfer-ownership 153 · ship-task §1-0 · 6-0 §2·§3.3 · 6-1 §3.4. new-task·rewind-task에는 로더 자체가 없음(`1:1`).
- **Z5. 브라우저 프로필 세 벌** — 템플릿 35 · account-check ④ · 6-0 §2 53. 서로 안 가리킴.
- **Z6. 색인 제외(noindex)의 수명** — 거는 곳 5 §2.6, 푸는 곳 6-3 §2.2. 6-3 §2.3·§3과 7 §2.1도 전제. 5 §2.6이 6-3을 가리키는지 확인 필요.
- **Z7. 로컬스토리지 걷어내기 범위** — 5 §2.5 · 6-2 §6·§13 · 6-3 §2.1·§3. 6-3 §3 「폴백으로도 남아 있지 않음」이 6-2 §13 OAuth 임시 보관 예외를 가리키지 않음. `5:[모순]-2`는 6-2만 고치는 안 — 6-3 쪽에도 한 줄 필요할 수 있음.
- **Z8. 스모크 테스트** — ship-task §1.8 · 6-3 §2.3 · ci.yml · transfer-ownership §10. ship-task → 6-3 참조는 확인됨. 반대 방향과 transfer-ownership → 6-3은 확인 필요.
- **Z9. 클라우드 시드** — 템플릿 · 6-0 §3.2 · 6-1 §4.8 · transfer-ownership §10. 6-0이 템플릿을 안 가리킴(`4:6-0-2`).
- **Z10. Supabase 키 이름 (Publishable vs anon)** — 템플릿 131 ↔ 5 §2.4.2 · 6-1 §4(`4:5-2`). 6-2 §10·6-3 표기는 확인 필요.
- **Z11. security-baseline 로드 조건 설명** — 네 곳(6-1 §4 · 6-2 서두 · 6-3 §2.1·§2.6 · 템플릿 검증 절)이 규칙 파일 frontmatter를 가리키지 않고 각자 요약. 글롭이 바뀌면 조용히 어긋남.
- **Z12. `docs/design-notes.md`** — 원본 저장소에만 있는데 payload 에이전트(harness-auditor)와 이동안 7건(`3:19·27·37·38`, `4:3-2·5-13·결6`)이 목적지로 씀.
- **Z13. 재시도 한도 줄 의무** — 템플릿 69·account-check ⑥이 요구. 빠진 곳: deep-research(`2:R1`), harness-diet(`2:H2`). 3-market-research 라이트 정찰·WebFetch, 2-mockup §2.3, transfer-ownership Aside 작업에도 있는지 확인 필요.

### 4. 사람 결정 통합 목록 (결정 하나가 푸는 항목이 많은 순)

**1. 층이 다른 중복을 둘지 줄일지** — 합침 `1:결4`, `2:결9`, `3:결6`, `4:결4`
- 풀리는 항목: `1:2·9·13·14` / `2:P6·H1·T5·U2·U3·AC4` / `3:1·4·5·14·16·20·21·22·36·42` / `4:5-12·6-0-7·6-0-8·6-1-4·6-1-5` / `5:B-1·B-6·B-7·B-8·B-9·B-10·B-13·B-14·B-15` / Y6·Y7 / X1~X11
- 추천: 상시층이나 스킬 허브에 있는 규칙은 아래층에서 § 포인터 한 줄로 줄임. 사고 원문·실측·그 층에만 있는 조건은 남김. fork 스킬 본문 안의 메인 대상 문장은 지움. 참조끼리 겹치는 건 용어 정의만 양쪽에 허용하고 규칙과 코드는 한쪽에만.

**2. AI 지시문의 풀이 괄호와 사용자 노출 글의 경계** — 합침 `3:결8`, 4회차 「확신 없어 뺀 것」의 4 §2.2 표
- 풀리는 항목: `2:P1·R2·U4` / `3:2·9·10·11·12·13·17·26·35·39` / `4:3-7·4-4·5-14·6-0-9·6-1-7` / `5:A-1~A-6` / Y8
- 추천: 스킬·에이전트·references 본문은 풀이를 일괄 삭제. 「설명 골자」처럼 사용자에게 그대로 전하라고 표시된 대사와 표만 예외. common-patterns는 평서체로.

**3. `design-notes.md` 목적지와 G의 경계** — 합침 `3:결9`, `4:결6`
- 풀리는 항목: `2:A1`, `3:19·27·37·38`, `4:3-2·5-13·G-1`, Y4·Y5, Z12
- 추천: 원본 전용 이력은 design-notes로. 27번은 G-1안(3-market-research에 병합) 채택. harness-auditor 정책에 「원본 모드 한정, 프로젝트 모드는 `[하네스 제안]`」. `4:결6`(5 §2.2.3 경위)은 되돌림을 막는 문장이라 남김.

**4. CLI 인증과 계정 검문 기준** — 합침 `1:결1`, `1:결6`
- 풀리는 항목: `1:1·5·6`, Y10, Z4, `4:6-0-3·6-0-5·6-1-1`. X4 포인터 방향도 정해짐.
- 추천: new-task·rewind-task에 ship-task §1-0과 같은 로더(`allowed-tools` 포함). 루트 AGENTS 「다르면 멈춘다」는 ship-task §1-0 하드/소프트 기준으로 다시 써서 기준 하나로.

**5. `backend-build.md` 「배포 정보」 서식** — 합침 `5:결5`
- 풀리는 항목: `5:[모순]-3·D-2·[모순]-5`, `4:6-0-8·6-1-3` 방향, Z1·Z2
- 추천: 6-3 §4.1 템플릿에 비밀값 장부와 에러 확인 위치를 넣음. 6-0 §4 기존 지시와 맞음.

**6. security-baseline `paths` 확정** — 합침 `2:결4`, `5:결1`
- 풀리는 항목: `2:S1`, `5:D-1`, `4:6-1-5` 적용 순서, Y3, Z11
- 추천: `**/proxy*`와 `**/lib/supabase/**/*`는 확정. 로그인·가입·`(auth)`·`*Upload*`는 로드 비용을 보고 보류.

**7. 판올림 경계** — 합침 `3:결1`
- 풀리는 항목: `3:30·31`, `2:U2` 일부, Y11, Z3
- 추천: 같은 단계 안 재위임(§2.4·§2.5)은 제자리 덮어쓰기, 단계를 건너 되돌아올 때만 `-v2`. SKILL §3, 1-user-story, user-scenario-writer 저장 규칙 세 곳 동시에.

**8. 프로젝트 모드에서 하네스 소유 폴더에 새 파일 만들기** — 합침 `2:결3`
- 풀리는 항목: `2:DI1·S2·P5`, `2:A1` 일부
- 추천: 원본 모드는 `payload/`에, 프로젝트 모드는 문안으로 사용자에게.

**9. ci.yml 두 건** — 합침 `1:결5`, `5:결3`
- 풀리는 항목: `1:18`, Y9, Z8
- 추천: 1:18은 조건문으로 다시 쓰되 5 §2.4.2 원문 확인 후 `4:5-3` 문구와 맞춤. 라우트 정적 검사는 CI 단계를 따로 두지 말고 `lint` 스크립트 안에(ci.yml은 하네스 소유물이라 프로젝트가 못 고침).

**10. 첫 적용 때의 브랜치 규칙** — 합침 `2:결2`
- 풀리는 항목: `2:P3·P4`, README 203줄
- 추천: (a)안. AGENTS 문장을 「`/new-task`가 설치된 저장소에서는 파일을 바꾸는 스킬도 브랜치를 먼저 연다」로.

**11. 재시도 한도 해석** — 합침 `2:결7`
- 풀리는 항목: `2:AC2`, `2:R1` 문구, Z13
- 추천: 낮음 등급 「3회」 칸에 「서로 다른 시도 합계 3회, 같은 응답이 2회면 멈춤」 명시.

**12. Vercel 깃 연동 기본 경로와 6단계 중간 배포 경로** — 합침 `4:결2`, `5:결2`
- 풀리는 항목: `4:5-4`, 6-3 §2.2 중간 배포
- 추천: CLI `vercel git connect` 기본, 실패하면 저장소 접근 목록에 추가(account-check·eval #34와 일치). 중간 배포도 main 머지(`/done-task`, 사용자 확인 뒤)로만, CLI 수동 배포 안 함 명시.

**13. 목업 캔버스 입력을 누가 읽나** — 합침 `3:결5`
- 풀리는 항목: `3:41`, 4회차 「확신 없어 뺀 것」(5 §2.2.2), Y1
- 추천: 모순 아닌 걸로 정리. 템플릿은 그대로, 2-mockup L98과 5 §2.2.2에 「호출 입력이라 에이전트가 전문으로 읽는다」 구절만 추가.

**14. 훅과 수동 커밋의 상호작용** — 합침 `1:결2`, `1:결3`
- 풀리는 항목: `1:12`, done-task 3번
- 추천: 훅이 되살린 파일을 자동 커밋하는 지금 동작은 받아들이고 스킬 문구만(백업 태그가 있음). done-task 3번에는 훅과 같은 시크릿 제외 적용.

**15. 반영 시점의 정답 [실측 필요]** — 합침 `2:결1`
- 풀리는 항목: `2:RM4` (project-init 150·269줄, README 129·209·268·292줄)
- 추천: 동기화 직후 새 스킬 호출과 훅 동작을 한 번 재서 기록한 뒤 한쪽으로.

**16. 클라우드 시드를 CLI로 넣을 수 있나 [실측 필요]** — 합침 `4:결3`
- 풀리는 항목: `4:6-0-2`, Z9
- 추천: 실측 전까지 6-0이 템플릿 절차(대시보드 SQL 편집기)를 가리키게.

**17. Aside repl에서 fs로 파일을 쓸 수 있나 [실측 필요]** — 합침 `2:결5`
- 풀리는 항목: `2:T1`
- 추천: 실측 결과에 맞춰 transfer-ownership이나 account-check 한쪽만.

**18. 커뮤니티 표본 18곳/19곳, SNS 3곳 포함 여부 [실측 필요 — 원래 조사 기록]** — 합침 `3:결4`
- 풀리는 항목: `3:8`
- 추천: AI는 숫자를 고치지 않음. 사람이 조사 기록으로 확정.

**19. 비밀번호 입력의 주체** — 합침 `2:결6` — 풀림 `2:T2`. 추천: account-check 기준(금고 자동 채움)으로 transfer-ownership을 고침.

**20. 14px 바닥선의 캡션 예외 범위** — 합침 `3:결2` — 풀림 `3:18`. 추천: 좁은 쪽(「사진·이미지 위 캡션」만). §6.4 주석과 브리프 §9를 맞춤.

**21. 안전영역 토큰 이름** — 합침 `3:결3` — 풀림 `3:15`. 추천: `--space-bottom-safe` (표에 「레거시로 `--space-` 접두 유지」 명시돼 있음).

**22. 2단계 재시드에 사고 방지 줄을 넣을지** — 합침 `3:결7` — 풀림 `3:42`. 추천: 넣음.

**23. 3단계 「사이드 모드 적합도」** — 합침 `4:결1` — 풀림 `4:3-1`. 추천: 열 삭제. 정의 없는 새 기준을 만들지 않음.

**24. 6-0 §3.4 admin API 세션 줄의 자리** — 합침 `4:결5`. 추천: 6-2 §13(세션 절)로 원문 그대로 이동.

**25. 광고 계정을 「소유와 계정」 표에 넣을지** — 합침 `5:결4`. 추천: 7 §2.2에 「광고 계정을 만들면 표에 행을 추가한다」 한 줄만.

**26. delegation-integrator의 「사용자 확인 후 설치」** — 합침 `2:결10`. 추천: 멈추고 [결정 필요] 반환 → 재호출 방식으로.

**27. 모드 판별 기준** — 합침 `2:결8`. 추천: `.claude/harness-version` 하나로만.

**따로 정할 필요 없는 것: `5:결6`** — `3:23`과 같은 발견. 3:23 수정안 그대로 적용.

**37개 대응표**

| 회차 | 결정 번호 → 통합 번호 |
|---|---|
| 1회차 | 1→4, 2→14, 3→14, 4→1, 5→9, 6→4 |
| 2회차 | 1→15, 2→10, 3→8, 4→6, 5→17, 6→19, 7→11, 8→27, 9→1, 10→26 |
| 3회차 | 1→7, 2→20, 3→21, 4→18, 5→13, 6→1, 7→22, 8→2, 9→3 |
| 4회차 | 1→23, 2→12, 3→16, 4→1, 5→24, 6→3 |
| 5회차 | 1→6, 2→12, 3→9, 4→25, 5→5, 6→결정 불필요 |

### 확신 없어 뺀 것

- **「재작업 최대 2회」가 2-mockup, 4-IA, 6-3에 반복된 것:** 단계 문서마다 따로 읽히고 명령문이면서 실사고로 생긴 의무라 중복 묶음에서 뺌.
- **계측 이벤트 정의는 코드에만(6-3 ↔ 7 ↔ 템플릿):** 5회차가 「로드 시점이 다르다」고 이미 판정.
- **재시드 규칙(2-mockup ↔ 5):** 3:42가 이미 회차 경계를 넘어 잡음.

---

## 7회차 — 결정과 반영 (2026-09-28, 사용자 위임 「최선의 방안을 정해 실행」)

6회차 통합 목록 27개에 대한 결정. 실측이 필요했던 넷 중 셋은 공식 문서·최근 실측·「최신 확인」 지침으로 갈음했고, 하나(18)는 보류.

| # | 결정 | 비고 |
|---|---|---|
| 1 | 상시층·스킬 허브 규칙은 아래층에서 § 포인터 한 줄로. 사고 원문·실측·그 층에만 있는 조건은 남김. fork 본문 속 메인 대상 문장은 삭제. | 「시작 전 브랜치 확인」 블록은 **남기고** 명령만 `git branch --show-current`로 통일(스킬 실행 시점 되새김) |
| 2 | AI 지시문 속 풀이 괄호 일괄 삭제. 사용자 대사·「설명 골자」·README는 제외. | common-patterns 해요체는 **보류**(실측 문서를 통째로 다시 쓰는 위험) |
| 3 | 원본 전용 이력만 `docs/design-notes.md`로. 「이 자리에 둔 이유」는 3-market-research에 병합. harness-auditor에 「원본 모드 한정」 명시. | 5 §2.2.3 경위는 남김 |
| 4 | new-task·rewind-task에 GH_TOKEN 로더 + `allowed-tools`. 루트 AGENTS 「다르면 멈춰 보고」→ ship-task §1-0 갈래(원격 새로 만들 때 멈춤·있으면 보고)를 가리키게. | Y10은 폴백(토큰 없는 옛 프로젝트) 한정이라 모순 아님 |
| 5 | 6-3 §4.1 `# 배포 정보`에 비밀값 장부·에러 확인 위치 추가. 7·6-1 포인터를 `mvp/backend-build.md`로. | |
| 6 | security-baseline `paths`에 `**/proxy*`·`**/lib/supabase/**/*`만 추가. 로그인·가입·`(auth)`·`*Upload*`는 보류. | 로드 조건을 옮겨 적은 세 곳은 「정확한 목록은 그 파일 `paths`」로 |
| 7 | 판올림은 단계를 건너 되돌아올 때만(§2.6). 같은 단계 안 재위임(§2.4·§2.5)은 제자리 덮어쓰기. 에이전트 저장 규칙은 「지시서가 정한다, 없고 파일이 있으면 멈춰 보고」. | SKILL §3·1-user-story·user-scenario-writer 셋 동시 |
| 8 | 원본 모드는 `payload/`, 프로젝트 모드는 문안 전달. | DI1·S2 |
| 9 | ci.yml 주석은 조건문으로(5 §2.4.2와 맞춤). 라우트 정적 검사는 `lint` 스크립트에. | |
| 10 | 「`/new-task`가 있는 저장소에서는 파일을 바꾸는 스킬도 브랜치를 먼저 연다」. 첫 적용은 「아직 안 들어와 있어서 main」 사실 서술. | 「예외」 딱지 없음 |
| 11 | 낮음 등급: 「서로 다른 시도 합계 3회, 같은 응답 2회면 멈춤」. | |
| 12 | Vercel은 CLI `vercel git connect` 기본, 실패 시 접근 목록. 6단계 중간 배포도 PR 머지(`/done-task`)로만. | |
| 13 | 모순 아님 — `mvp/` 세 파일은 호출 입력(대상). 2-mockup·5 §2.2.2에 그 구분 한 구절. | |
| 14 | 훅의 자동 커밋을 받아들여 rewind 문구만 수정. done-task 3번엔 「시크릿 파일 보이면 멈춤」 한 줄. | |
| 15 | 스킬은 다음 호출부터, 에이전트·훅은 새 세션부터(훅 설정 스냅샷 — 공식 문서, 최신 확인), AGENTS는 컴팩션·`/clear`부터. | 실측 대신 공식 문서 근거 |
| 16 | 6-0이 템플릿 절차(대시보드 SQL)를 가리키고, 「`db push --include-seed` 같은 옵션은 공식 문서로 최신 확인」. | 템플릿 사실은 그대로 |
| 17 | transfer-ownership 쪽(세션 폴더 쓰기 가능·`/private/tmp` 거부)이 더 최근·구체적 실측 → account-check를 그쪽에 맞춤 + 「최신 확인」. | |
| 18 | **보류.** 숫자를 건드리지 않음 — 원 조사 대화가 압축돼 복원 불가. 사용자가 조사 기록으로 확정. | common-patterns L21·L41 |
| 19 | account-check 기준(금고 자동 채움, 에이전트는 값을 안 다룸)으로 transfer-ownership 수정. | |
| 20 | 예외는 「사진·이미지 위 캡션」만. naming §6.4 주석 예시·브리프 §9 맞춤. | |
| 21 | `--space-bottom-safe`. | |
| 22 | 2-mockup 재시드에 「최종 상태를 처음부터 다시 읽어라」 추가(사고 기록은 5단계에 그대로). | |
| 23 | 「사이드 모드 적합도」 열 삭제, §5.5는 모드 구분 없이. | |
| 24 | admin API 세션 줄을 6-2 §13으로 원문 이동. | |
| 25 | 7 §2.2에 「광고 계정을 만들면 표에 행 추가」 한 줄. | |
| 26 | delegation-integrator는 [결정 필요] 반환 방식. | |
| 27 | 모드 판별은 `.claude/harness-version` 하나로. | |

건너뛴 것: 3회차 5번(허브 색인의 bootstrap 참조 — 설계로 봄), 3회차 16·17·20(별 모양 설계라 용어 정의 양쪽 허용), 4회차 6-1-4(사고 기록 붙은 정본이라 6-1 유지, 6-3 쪽만 축약), 2회차 U3(사고 원문).

반영 실행: `payload/`만 고치는 서브 에이전트 5개(opus) 병렬 — A git 흐름+AGENTS·템플릿 / B 운영 스킬·에이전트·rules·account-check·README / C design-system / D idea-to-mvp SKILL·1~4·user-scenario-writer / E 5~7. 이후 메인이 design-notes 추가, 루트 미러 동기화, 잔재 grep.

### 반영 결과 (같은 날)

- 다섯 에이전트 모두 결정 항목을 반영했고, 「보고서 인용이 파일에 없어 건너뛴 항목」은 0건. 헤더 변경은 3-market-research §5.5 하나(목차·외부 참조 0건 확인)뿐이고, 목차 앵커 대조는 전 파일 죽은 링크 0건.
- 메인 추가 수정: layout-frames 풀이 2건, ship-task 「로컬 전환」 표현과 smoke test 풀이, ci.yml 「여기 추가한다」 주체(하네스 원본), README 265줄 `/clear` 이유·§5.3 「앞의 여섯」, 3-market-research 3-3 문장의 중복 꼬리, 6-1 PITR 풀이.
- `docs/design-notes.md`에 옮긴 경위 넷 추가(14px 규칙 출처 · 목업/프로토타입 이름 유래(2·5단계) · 시각 다듬기 허용 경위 · 「빌더 가드레일」 옛 이름).
- 루트 `.claude/`·`docs/` 미러 동기화 완료(`diff -rq` 차이 0).
- 잔재 grep: 지운 문구·옛 이름 전부 0건. 남은 것은 다른 뜻의 정상 사용(ship-task·idea-to-mvp의 「예외 없이」 2건, 훅·fork 스킬의 `git rev-parse --abbrev-ref HEAD` — detached HEAD 감지용)과 일부러 둔 1-user-story §4.1 선언문의 ledger 풀이.
- 분량: 보고서 제외 `.md`·`.sh`·`.yml` 합계 main 16,953줄 → 16,945줄. 줄 수는 거의 같다 — 이번 다이어트의 효과는 분량이 아니라 **모순 39건·죽은 참조·낡은 사실 23건 해소**와 규칙 발동 구멍(security-baseline paths, gh 토큰 로더) 메움이다. A(풀이 괄호) 삭제로 줄어든 만큼 포인터·로더·장부 칸이 늘었다.
- 보류 2건: common-patterns 커뮤니티 표본 18/19곳(사용자 조사 기록 대조), common-patterns 해요체.
