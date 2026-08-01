---
name: done-task
description: 현재 feature 브랜치의 WIP 커밋들을 GitHub에 push → PR 생성 → squash merge → remote 브랜치 자동 삭제.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *)
context: fork
agent: git-flow
---

# done-task

현재 브랜치의 WIP 커밋들을 PR 흐름으로 main에 ship하는 스킬. **(코드 변경 시 simplify 게이트) → (조건부 리베이스) → push → PR 생성 → (머지 권한 있을 때만) CI 대기 → squash merge → remote 브랜치 삭제** 한 흐름.

이 저장소는 팀 작업 저장소다 — 팀원들이 각자 복제본이 아니라 이 저장소에 직접 협업자(collaborator)로 브랜치를 올린다. 그래서 머지 권한은 사람마다 다르다: 팀장(오너)은 지금처럼 squash merge까지 자동으로 하고, 머지 권한이 없는 팀원은 PR 생성까지만 하고 멈춘다. 자세한 판별 방법은 §2.5.

이 스킬은 `context: fork`로 git-flow 서브에이전트(sonnet)에서 격리 실행된다 — 메인 세션 토큰 절약 목적. 실행 중 사용자 질문이 불가능하므로 결정 지점은 [결정 필요] 반환 → 메인이 사용자에게 확인 → **사용자가 직접** 결정을 args에 담아 슬래시 명령으로 재호출하는 프로토콜을 쓴다. (`disable-model-invocation: true`라 AI는 이 스킬을 재호출할 수 없다 — 재호출 입력은 반드시 사용자 몫. 예외적으로 급할 땐 메인 세션이 git-flow 에이전트를 직접 호출해 SKILL.md 절차 + 결정을 프롬프트로 넘겨 실행하는 우회가 가능하다.)

## 호출 인자

이번 호출의 인자: **$ARGUMENTS**

위가 비어 있으면 인자 없이 호출된 것. 인자에는 작업 의도와 [결정 필요]에 대한 결정 지시가 자연어로 담긴다 — 해석은 §호출 패턴. (fork 실행 시 호출 인자는 위 자리표시자를 치환해 전달된다 — 이 섹션이 이 스킬의 인자 수신 지점이므로 삭제 금지.)

**호출 = ship 승인**: 이 스킬 호출 자체가 ship(푸시·PR 생성·(머지 권한 있으면) 머지까지) 승인이다 — PR 제목·body는 AI 초안 그대로 사용, 별도 확인 없음 (사용자가 정한 규칙). 머지 권한이 없으면 애초에 승인해도 머지가 안 되니, 이 경우 승인의 범위는 자연히 PR 생성까지로 줄어든다 (§2.5).

설계 원칙: wip 커밋은 *사용자 의도의 archaeology layer*라 PR 페이지에 보존, main은 squash로 1개 commit만. 자세한 근거는 다음 단락.

### 왜 GitHub squash인가 (local squash 아님)

- main `git log` = squash 1개 (깨끗) ← LLM first lookup
- PR 페이지 Commits 탭 = wip 30+ 보존 ← LLM drill-down용 archaeology
- auto-wip-commit 훅이 *사용자 프롬프트 일부*를 wip 메시지로 박음 → wip이 *의도 timeline*이라 손실 가치 큼
- 그래서 _local squash 후 PR_ 안 함. *GitHub squash merge*가 best of both worlds.

## 진입 전 가정

- 프로젝트 루트가 git repo
- 현재 브랜치는 feature 브랜치 (main 아님)
- 의미 있는 작업이 wip 커밋으로 누적된 상태
- 내 브랜치를 push할 권한은 있음 (PR로 올리니 main 직접 push 권한은 불필요)
- main으로 **머지**할 권한은 사람마다 다를 수 있음 — 오너·메인테이너면 있고, 일반 팀원(쓰기 권한만)이면 없음. 이 스킬은 강제하지 않고 GitHub 저장소 설정(협업자 권한)을 그대로 따른다 — 저장소가 비공개+무료 플랜이면 GitHub이 브랜치 보호 규칙 자체를 지원하지 않으므로, "머지는 팀장이 한다"는 건 이 스킬이 지키는 관례이지 GitHub이 막아주는 강제 규칙이 아니다. 판별 방법은 §2.5.

## 실행 흐름

### 1. 안전 검사 (실패 시 사용자 안내 후 중단)

```bash
# 1-a. 현재 브랜치 확인
git rev-parse --abbrev-ref HEAD
```

- **main 브랜치** → 중단. "지금 main 브랜치 위에 있어. 이 스킬은 feature 브랜치를 main으로 ship하는 도구라, 먼저 작업한 feature 브랜치로 이동해야 해."
- **브랜치에 안 묶인 상태 (detached HEAD)** → 중단. "지금 어느 브랜치에도 위치하지 않고 과거 커밋한 파일들을 보고 있어. 이 스킬은 feature 브랜치를 main으로 ship하는 도구라, 어느 feature 브랜치를 ship할지 알려줘."

```bash
# 1-b. origin/main 최신화 후, 그 대비 새 commit 있는가
# (로컬 main이 아니라 origin/main 기준 — 팀 작업이라 로컬 main은 금방 뒤처짐.
#  여기서 최신화해두면 §1.6 리베이스 판단·§2 PR 정보 수집도 같은 fetch 결과를 그대로 씀)
git fetch origin main
git log origin/main..HEAD --oneline | head -1
```

- 비어 있으면 → 중단. "지금 브랜치에 main 대비 새 변경이 없어. 이 스킬은 새 변경을 main으로 ship하는 도구라, 작업이 끝난 게 맞는지 확인 필요해."

```bash
# 1-c. working tree 깨끗한가
git status --porcelain
```

- 비어 있지 않으면 args에 결정 지시(예: "변경은 커밋하고 진행")가 있으면 그대로 적용하고 계속. 없으면 **[결정 필요] 반환**:
  ```
  [결정 필요] 커밋되지 않은 변경(수정·추가·삭제된 파일)이 남아 있어.
  이 스킬은 *커밋된 wip*만 ship하는 도구라, 변경을 먼저 정리해야 해.

  선택지:
  (a) 지금 변경을 커밋하고 진행 (메시지 필요)
  (b) 임시 보관소에 넣어두고 진행 (`git stash` — 나중에 다시 꺼낼 수 있어)
  (c) 중단 — 직접 정리할게

  재호출 예시: `/done-task 변경은 커밋하고 진행` / `/done-task stash하고 진행`
  ```

### 1.5 simplify 게이트 (코드 변경이 있을 때만)

ship 전에 코드 품질 정리(`simplify` 스킬 — 재사용·단순화·효율·계층 리뷰 후 수정 적용)를 거치는 관문.
**원칙: simplify가 코드를 고쳤으면 그 상태로 바로 ship하지 않는다 — 사람 검증 후 재호출로 이어간다.**
**권장 순서: 코드 작업 → `/simplify` → `/done-task`** — 게이트에 걸리면 왕복이 한 번 더 들므로, 미리 돌리고 부르는 게 빠르다.

```bash
# 코드 파일 변경 여부 (src/** 기준 — 문서·설정만이면 게이트 skip)
# origin/main 기준 (§1-b에서 이미 fetch해뒀음)
git diff origin/main...HEAD --name-only | grep '^src/' | head -1
```

- **코드 변경 없음** (docs·.claude·설정만) → 게이트 skip, §2로.
- **직전 커밋이 simplify 반영분** (`git log -1 --format=%s`에 `simplify` 포함) → 이미 게이트 통과한 재호출. skip, §2로.
- **args에 "스킵" 류 지시 있음** → 게이트 skip, §2로.
- **코드 변경 있고 args에 지시 없음** → **[결정 필요] 반환** (fork 안에서 simplify 스킬을 직접 실행하지 않는다 — 스킬 호출은 메인 세션 몫):
  ```
  [결정 필요] src 코드 변경이 있어. ship 전에 simplify(재사용·단순화·효율 리뷰)를 거칠지 결정 필요해.

  선택지:
  ① 메인 세션에서 /simplify 돌린 뒤 재호출
  ② 스킵하고 바로 ship

  재호출 예시: `/done-task 스킵`

  팁: 다음부터는 코드 작업 마치고 /simplify를 먼저 돌린 뒤 /done-task를 불러줘 —
  그러면 이 왕복 없이 한 번에 ship돼.
  ```

> 근거: 유저가 브라우저로 검증한 코드와 main에 들어가는 코드가 달라지면 안 됨 — 화면 검증은
> 사람 몫이고 Claude가 스스로 결과를 승인하지 않는다는 원칙. simplify 수정분도 예외 없이 사람 눈을 거친다.

### 1.6 조건부 리베이스

팀 작업이라 내가 작업하는 동안 다른 사람 PR이 먼저 main에 들어갈 수 있다. origin/main이 내 브랜치보다 앞서 있으면, 안전할 때만 리베이스(rebase — 내 브랜치의 커밋들을 최신 origin/main 위로 다시 쌓는 것)하고, 위험하면 아예 시작하지 않는다.

```
origin/main이 내 브랜치보다 앞서 있나? (git rev-list --count HEAD..origin/main)
  아니오 (0) → 리베이스 없이 §2로
  예 (0보다 큼) ↓
    → 이미 push한 브랜치인가? (git ls-remote --exit-code --heads origin <branch>)
    → 충돌 예행 검사 (git merge-tree --write-tree origin/main HEAD — 작업 트리는 안 건드리는 모의 병합)

    아직 push 전
       ├ 충돌 없음 → git rebase origin/main 실행 후 §2로
       └ 충돌 있음 → [결정 필요]로 멈춤. 리베이스를 시작하지 않는다

    이미 push함 (push 여부가 먼저다 — 이 갈래에선 충돌 있어도 멈추지 않는다)
       ├ 충돌 없음 → 리베이스 생략하고 §2로
       └ 충돌 있음 → 리베이스 생략하고 §2로 (완료 보고 §4에 충돌 경고 남김 — 근거는 아래 핵심 규칙 3번)
```

**핵심 규칙:**

1. **이미 push한 브랜치는 절대 리베이스하지 않는다.** 리베이스는 커밋을 전부 새로 쓴다(모든 sha가 바뀜) — push된 브랜치를 리베이스하면 강제 push(force push)가 필요해지는데, 이 워크플로는 force push를 안 쓴다. 이 규칙은 충돌 여부와 무관하다 — 이미 push했으면 충돌이 있든 없든 리베이스 자체를 안 한다.
2. **아직 push 전인데 충돌이 있으면 리베이스를 시작조차 하지 않는다.** 이 스킬은 fork로 격리 실행돼 중간에 사용자에게 물어볼 수 없다. 리베이스 도중 충돌이 나면 저장소가 "리베이스 진행 중"인 어중간한 상태로 반환돼버린다. 그래서 손대기 전에 예행 검사로 먼저 걸러내고, 이 경우만 [결정 필요]로 멈춘다.
3. **이미 push함 + 충돌 있음이어도 여기서 멈추지 않는다.** 규칙 1 때문에 이 조합은 애초에 리베이스 대상이 아니다. 그렇다고 [결정 필요]로 멈춰봐야 done-task가 달리 할 수 있는 게 없다 — push된 브랜치는 리베이스가 불가능하고(강제 push가 필요해지는데 이 워크플로가 금지함), 사용자에게 물어볼 수도 없는 fork 실행이다. PR을 올려두면 GitHub이 머지 시점에 충돌을 알려주므로, 리베이스 생략하고 그냥 진행하는 게 낫다 — 대신 완료 보고(§4)에 경고를 남긴다.

```bash
# origin/main이 앞서 있는지 (0보다 크면 앞섬 — 뒤 명령들 모두 origin/main이 앞서 있을 때만 실행)
git rev-list --count HEAD..origin/main

# 이미 push했는지 (exit 0 = 원격에 있음 = push됨, exit 2 = 없음 = 아직 push 전)
# 이 명령이 네트워크 문제 등으로 실패하면 "이미 push함"으로 보수적으로 판정해서 리베이스를 생략한다
git ls-remote --exit-code --heads origin "$(git rev-parse --abbrev-ref HEAD)"

# 충돌 예행 검사 — exit 0 = 충돌 없음(병합 결과 tree sha만 출력), exit 1 = 충돌
# (충돌 시 tree sha 뒤에 stage 1/2/3 항목과 "충돌 (내용): ..." 메시지가 같이 출력됨.
#  충돌 파일 목록만 뽑으려면: 위 출력을 `awk -F'\t' 'NF>1 {print $2}' | sort -u`)
git merge-tree --write-tree origin/main HEAD
```

- **아직 push 전 + 충돌 없음** → `git rebase origin/main` 실행. 성공하면 §2로.
- **아직 push 전 + 충돌 있음** → **[결정 필요] 반환**:
  ```
  [결정 필요] origin/main이 내 브랜치보다 앞서 있고, 합치면(또는 리베이스하면) 충돌이 나.
  이 스킬은 충돌 상태로 리베이스를 시작하지 않아 (중간에 멈추면 저장소가 어중간해지니까).

  충돌 파일: <merge-tree로 뽑은 파일 목록>

  선택지:
  ① 로컬에서 머지(merge)로 충돌 풀고 재호출 —
     `git merge origin/main` → 충돌난 파일 고치기 → `git add <파일>` → `git commit` → 다시 `/done-task` 호출
     (리베이스 대신 머지를 쓰는 이유: 이 저장소는 매 턴 wip 커밋이 쌓여서 브랜치 하나에 커밋이 많아 —
     리베이스는 커밋을 하나씩 다시 쌓기 때문에 충돌 난 파일을 건드린 커밋마다 멈춰서 같은 충돌을
     여러 번 풀어야 해. 머지는 두 갈래를 한 번에 붙여서 한 번만 풀면 돼. 마지막엔 어차피 squash로
     다 뭉치니까 병합 커밋 하나 끼는 건 결과에 안 남아. 머지 후 재호출하면 내 브랜치가 origin/main을
     전부 품게 돼서, §1.6 판정에서 "앞서 있나?" 검사가 0이 되어 리베이스 단계는 자연히 건너뛰어.)
  ② 리베이스 없이 그냥 PR 올리고 GitHub에서 충돌 해결 (머지 시점에 GitHub이 충돌을 알려줌)
  ③ 굳이 한 줄로 깔끔한 기록(선형 기록)을 원하면 로컬에서 직접 리베이스 —
     `git rebase origin/main` → 충돌난 파일 고치기 → `git add <파일>` → `git rebase --continue` → 다시 `/done-task` 호출

  재호출 예시: `/done-task 머지로 진행` (① 선택 시) / `/done-task 리베이스 없이 진행` (② 선택 시)
  ```
- **이미 push함 + 충돌 없음** → 리베이스 생략하고 §2로.
- **이미 push함 + 충돌 있음** → 리베이스 생략하고 §2로 진행하되, 완료 보고(§4)에 경고를 남긴다.
  여기서 멈추지 않는 이유(핵심 규칙 3번): push된 브랜치는 리베이스하면 강제 push가 필요해지는데 이 워크플로가
  그걸 금지하고, 그렇다고 여기서 멈춰봐야 done-task가 달리 할 수 있는 게 없다. PR을 올려두면 GitHub이
  머지 시점에 충돌을 알려주므로 진행하는 게 낫다. 경고 문구엔 **`git rebase`를 권하지 않는다** — 이미 push된
  브랜치라 강제 push가 필요해져서 이 워크플로 규칙을 어기게 된다. 미리 풀고 싶으면 `git merge origin/main`을
  쓰라고 안내한다.

### 2. PR 정보 수집

#### 2-a. 자동 추출 (AI 단독)

```bash
# diff 요약 (origin/main 기준 — §1-b에서 이미 최신화했고, §1.6에서 리베이스했다면 그 위에서 계산됨)
git diff origin/main...HEAD --stat
git log origin/main..HEAD --oneline
git log origin/main..HEAD --pretty=format:'%s' | head -30
```

- 브랜치명 → type·topic 분리 (예: `feat/dark-mode-toggle` → type=`feat`, topic=`dark-mode-toggle`)
- 변경 파일 list + 추가/삭제 라인
- wip 커밋 메시지 list (사용자 의도 fragment 추출)

#### 2-b. PR title·body 초안 (AI 단독)

자동 추출 데이터로 초안 작성:

- **title**: 70자 이하. 주요 변경을 자연어로 압축. type prefix는 _PR title에는 안 박음_ (브랜치명에 있고 squash 후 main commit 메시지에 `(#N)`으로 묶임)
  - 예: `다크모드 토글 추가 + 색 토큰 정리`
- **body 템플릿**:

```markdown
## Summary

- [bullet 1: 가장 큰 변경 + 왜]
- [bullet 2]
- [bullet 3]

## Test plan

- [ ] [수동 검증 항목 1]
- [ ] [수동 검증 항목 2]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- Summary는 _결정·이유_ 위주. 파일 list 나열 X.
- Test plan은 _사용자가 브라우저로 직접 확인할 항목_ — Claude는 브라우저 검증 안 함 (화면 검증은 사람 몫이라는 원칙).
- 카피 룰: CLAUDE.md `## 대화 스타일`·`ux-writing-reviewer` 에이전트 (있으면) 따름.

초안이 곧 확정본이다 (호출 = ship 승인 — 별도 확인 없이 바로 §2.5로 진행).

### 2.5 역할 판별 — 머지까지 할지, PR까지만 할지

이 저장소는 팀원들이 협업자(collaborator)로 직접 브랜치를 올리는 구조라, 사람마다 main 머지 권한이 다르다. 설정 파일 없이 GitHub 권한 조회로 판별한다.

```bash
# 저장소 경로는 하드코딩하지 말고 매번 조회
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
gh api repos/$REPO --jq '.permissions'
```

- **`admin` 또는 `maintain`이 `true`** → 오너/메인테이너 경로. §3을 지금까지처럼 끝까지(머지 포함) 실행.
- **`admin`·`maintain`은 `false`고 `push`만 `true`** → 팀원 경로. §3에서 PR 생성까지만 하고 멈춘다(머지 안 함).
  - 이 경우 오너를 리뷰어로 지정한다. 오너는 `gh repo view --json owner --jq .owner.login`으로 구한다.
- **조회 자체가 실패함** (네트워크 오류 등) → **안전한 쪽 = 팀원 경로**로 판정하고, 조회가 실패해서 보수적으로 처리했다는 사실을 완료 보고에 남긴다. 머지는 되돌리기 번거로운 작업이라, 권한이 확인 안 되면 안 하는 쪽을 택한다.
- **args에 "머지까지" 류 지시** → 위 판정과 상관없이 오너/메인테이너 경로로 진행 (주로 권한 조회가 실패했지만 실제로는 머지 권한이 있는 걸 아는 경우에 씀).
- **args에 "머지하지 마" / "PR까지만" 류 지시** → 위 판정과 상관없이 팀원 경로로 진행 (오너라도 이번엔 리뷰를 먼저 받고 싶을 때 씀).
- args 지시가 실제 권한과 안 맞으면(예: 팀원인데 "머지까지" 지시) §3-d의 `gh pr merge`가 권한 오류로 실패할 뿐이니 위험하지 않다 — 그 경우는 §3-d의 실패 처리를 그대로 따른다.

### 3. 실행 — push + PR 생성 + (§2.5 판정에 따라) squash merge + remote 삭제

#### 3-a. push

```bash
# 첫 push면 -u 추가
git push -u origin <current-branch>
# 이미 tracking 있으면
git push origin <current-branch>
```

- push 실패 (force 충돌·권한 등) → 중단 + 사용자에게 stdout 그대로 보고.

#### 3-b. PR 생성

```bash
gh pr create --title "..." --body "$(cat <<'EOF'
...
EOF
)"
```

- 생성 성공 시 PR 번호·URL 보고.
- 실패 시 (이미 PR 존재 등) → `gh pr view --json number,url` 로 기존 PR 가져와서 사용. 새로 안 만듦.
- **팀원 경로일 때만** (§2.5) — PR 생성 뒤에 오너를 리뷰어로 지정한다:
  ```bash
  gh pr edit <N> --add-reviewer <OWNER>
  ```
  이건 best-effort다 — 권한·설정 문제로 실패해도 PR 생성 자체는 그대로 유지하고, 리뷰어 지정만 실패했다는 사실을 완료 보고에 남긴다. 여기서 중단하지 않는다.

#### 3-c. CI 대기 — **오너/메인테이너 경로만** (§2.5)

팀원 경로면 이 단계도 건너뛰고 바로 §4 팀원용 완료 보고로 간다 (팀원은 애초에 머지를 안 하니 CI를 기다릴 필요가 없음).

머지 전에 CI(자동 검사 — push된 코드가 빌드·린트를 통과하는지 GitHub이 자동으로 돌려보는 것)가 끝날 때까지 기다린다.

```bash
gh pr checks <N> --watch --interval 10
```

- **통과 (exit 0)** → 3-d로 진행해서 머지.
- **실패** → 머지하지 않고 중단. 실패한 검사 이름과 PR URL을 사용자에게 보고하고, "고쳐서 push하면 CI가 다시 돌아, 그 뒤 `/done-task` 재호출"이라고 안내한다. PR은 지우지 않고 그대로 둔다.
- **검사가 하나도 없음** (gh가 "no checks reported" 류 메시지로 종료) → push·PR 생성 직후엔 GitHub이 검사(check run)를 등록하는 데 몇 초 걸릴 수 있어서, 곧 CI가 붙을 PR인데 등록이 늦어 이렇게 나온 것일 수도 있다. 바로 검사 없음으로 단정하지 말고 **20초 기다렸다가 `gh pr checks <N> --watch --interval 10`을 한 번 더 실행**한다.
  - 재시도에서 검사가 잡히면 위 통과/실패 분기를 그대로 따른다.
  - 재시도에서도 "no checks reported"면 그때 비로소 이 PR엔 CI가 안 붙어 있거나(워크플로 적용 전 브랜치 등) 적용이 안 된 상황으로 확정하고, 기다리지 않고 3-d로 진행해서 머지한다. 대신 완료 보고(§4)에 "이 PR엔 CI 검사가 안 붙어 있었어" 한 줄을 남긴다.

#### 3-d. squash merge + remote 브랜치 삭제 — **오너/메인테이너 경로만** (§2.5)

팀원 경로면 이 단계를 건너뛰고 바로 §4 팀원용 완료 보고로 간다.

```bash
# --subject 로 §2-b 확정 PR 제목을 명시 → 커밋이 1개뿐이어도 main에 wip 메시지 대신 PR 제목이 박힘
# (미지정 시 gh는 단일 커밋 PR에서 그 커밋 메시지를 squash 제목으로 써버려 main이 지저분해짐)
# --delete-branch 는 머지 뒤 원격 브랜치를 지우고, 로컬도 main으로 옮겨 앉은 뒤 그 브랜치를 치운다
gh pr merge <N> --squash --delete-branch --subject "<PR title> (#<N>)"
```

**머지 여부는 종료코드가 아니라 PR 상태로 판정한다.** 명령이 0이 아닌 코드로 끝나도 서버 쪽 머지는 성공했을 수 있어서다 — 머지는 GitHub에서 이미 끝났는데 그 뒤 로컬 정리에서 걸려 넘어지면, 종료코드만 보고 "머지 실패"로 잘못 읽게 된다:

```bash
gh pr view <N> --json state,mergedAt --jq '.state'
```

- `MERGED` → **성공이다.** 명령이 실패했더라도 그대로 다음 단계로 간다. 명령 쪽 오류 메시지는 §4 보고에 참고로만 한 줄 남긴다.
- `OPEN`·`CLOSED` → 진짜 실패다. 중단하고 사용자에게 stdout + PR URL 보고: "GitHub에서 직접 해결한 다음 다시 호출해줘." (conflict·branch protection·CI 미통과·**권한 부족** 등. 권한 부족으로 실패한 거면 애초에 팀원 경로였어야 하는 상황이니, PR은 그대로 두고 팀원용 보고에 준해 안내)

머지가 확인되면 **원격 브랜치와 로컬 브랜치가 치워졌는지 확인한다.** `--delete-branch`가 이미 지웠거나 저장소 설정이 "머지된 브랜치 자동 삭제"면 그냥 넘어간다 (없는 브랜치를 지우려 하면 오류가 난다):

```bash
git ls-remote --heads origin <branch>        # 출력이 있으면 원격에 아직 살아있다
git push origin --delete <branch>            # 살아있을 때만

git rev-parse --abbrev-ref HEAD              # main이면 로컬 브랜치까지 정리된 것
```

로컬 브랜치가 남아 있으면 여기서 억지로 지우지 않는다 — 세션이 아직 그 브랜치 위에 있으면 지울 수 없다. 남은 건 다음 `/new-task`가 정리한다 (§안 하는 것). 어느 쪽인지는 §4 보고에 적는다.

### 4. 완료 보고

**오너/메인테이너 경로** (머지까지 완료):

```
✓ CI 통과 확인 후 머지함 [검사가 아예 없었으면: "○ 이 PR엔 CI 검사가 안 붙어 있었어"]
✓ PR #<N> 생성 + squash merge 완료
✓ main에 1개 commit으로 합쳐짐 (제목: "<PR title> (#N)")
✓ remote의 <branch> 삭제됨 [§3-d에서 gh 명령이 오류를 냈지만 PR 상태가 MERGED였으면 한 줄 덧붙임:
  "○ gh 명령은 <오류 요약>로 끝났는데, 머지 자체는 성공이라 그대로 진행했어"]
✓ 로컬도 정리됨 — 지금 main 위에 있어 [로컬 브랜치가 남았으면 대신: "○ 로컬 브랜치 <branch>는
  남아 있어(세션이 아직 그 위에 있어서 못 지워) — 다음 /new-task 때 정리돼"]
✓ wip 커밋 <count>개가 PR 페이지에 그대로 남아 있어 — 브랜치가 지워져도 되살릴 수 있어:
  `git fetch origin pull/<N>/head:recover-<N>`
  (그중 특정 시점으로 돌아가고 싶으면 /rewind-task 써도 돼)

다음 작업은 /new-task로 새 브랜치 만들어서 진행해줘.
팁: 작업은 *한 PR로 묶을 수 있는 내용 단위*로 끊는 게 좋아 — 너무 큰 단위는
리뷰·되돌리기·history 추적 어려움. 자세한 가이드·예시는 docs/git-workflow.md §2.5.
```

**팀원 경로** (PR 생성까지, 머지는 오너 몫):

```
✓ PR #<N> 생성 완료 — <PR URL>
✓ 리뷰어로 <OWNER> 지정함 [지정 실패 시: "✗ 리뷰어 자동 지정은 실패했어(권한·설정 문제로 보임) —
  PR 페이지에서 직접 지정해줘"]
○ 머지는 안 했어 — 이 저장소에서 main 머지는 팀장(오너) 몫이라, 여기서 멈춰.
  브랜치 <branch>는 아직 살아 있고, 오너가 리뷰 후 머지하면 자동으로 정리돼.

머지되고 나면 로컬 정리는 /new-task로 하면 돼 (main 싱크 + 이 브랜치 정리 + 새 브랜치).
```

**CI 실패로 중단** (오너/메인테이너 경로, §3-c):

```
✗ CI 실패로 머지 안 하고 멈췄어
✗ 실패한 검사: <검사 이름 목록>
PR은 그대로 있어 — <PR URL>

고쳐서 push하면 CI가 다시 돌아. 그 뒤 다시 /done-task 호출해줘.
```

(권한 조회가 실패해서 보수적으로 팀원 경로를 택한 경우, 위 보고 앞에 "권한 조회가 안 돼서 안전하게 팀원 경로로 처리했어 — 실제로 머지 권한이 있으면 `/done-task 머지까지`로 재호출해줘." 한 줄을 덧붙인다.)

(§1.6에서 "이미 push함 + 충돌 있음"으로 판정돼 리베이스를 생략하고 진행한 경우, 위 보고에 다음 경고 줄을 덧붙인다:
"⚠️ origin/main과 충돌이 있을 수 있어 — 리베이스는 생략했어(이미 push된 브랜치라 강제 push가 필요해져서).
머지 시점에 GitHub이 충돌을 알려줄 거야. 미리 풀고 싶으면 `git merge origin/main`으로 해결해줘
(`git rebase`는 쓰지 마 — 강제 push가 필요해짐).")

## 사용자 응대 톤

톤은 `CLAUDE.md 대화 스타일`을 따름. 이 스킬 고유: 결정이 필요하면 진행을 멈추고 [결정 필요] 보고로 반환한다 (fork 실행이라 실행 중 질문 불가). 안전 검사 결과는 반환 보고에 모아서. PR title·body는 _호출 = ship 승인_ 모델이라 별도 확인 없이 초안 그대로 사용 — destructive 액션(push·merge)의 승인은 스킬 호출 그 자체다.

## 엣지 케이스

| 상황                                                    | 처리                                                                     |
| ------------------------------------------------------- | ------------------------------------------------------------------------ |
| `gh pr merge`가 0이 아닌 코드로 끝남                    | 종료코드로 판정하지 않는다. `gh pr view --json state`가 `MERGED`면 성공으로 보고 그대로 진행 (§3-d) |
| 머지는 됐는데 로컬 브랜치가 안 지워짐                   | 정상. 세션이 그 브랜치 위에 있으면 gh가 못 지운다. 억지로 안 지우고 §4 보고에 남김 — 다음 `/new-task`가 정리 |
| 이미 그 브랜치에 PR이 있음                              | 새로 안 만들고 기존 PR 사용. 새 commit 있으면 push만 추가 후 (오너 경로면) merge |
| push 후 PR 생성 실패                                    | push는 유지. GitHub UI에서 직접 만들라고 안내                            |
| squash merge 시 conflict                                | GitHub UI에서 conflict 해결 후 머지하라고 안내                           |
| branch protection 룰 (CI 통과 필요 등)                  | 정상 동작 — merge 실패 시 사유 그대로 보고 (단, 저장소가 비공개+무료 플랜이면 브랜치 보호 규칙 자체를 걸 수 없음, API 403) |
| CI 실패 (§3-c, 오너/메인테이너 경로)                    | 머지하지 않고 중단. 실패한 검사 이름 + PR URL 보고, "고쳐서 push하면 CI가 다시 돌아, 그 뒤 재호출" 안내. PR은 그대로 둠 |
| CI 검사가 하나도 없음 (§3-c)                            | 검사 등록이 늦었을 수 있으니 20초 기다렸다가 한 번 더 확인. 그래도 없으면 CI가 아직 없거나 적용 전인 상황으로 확정 — 바로 머지 진행, 완료 보고에 "이 PR엔 CI 검사가 안 붙어 있었어" 한 줄 남김 |
| 사용자 working tree 변경이 _이번 작업 일부_             | (a) 옵션으로 추가 commit하고 진행 권장 ([결정 필요] 반환에 명시)         |
| 사용자 working tree 변경이 _별개_                       | (b) stash 권장 ([결정 필요] 반환에 명시)                                 |
| simplify 재호출 감지                                    | 직전 커밋 메시지에 `simplify` 포함이면 게이트 skip → 바로 ship           |
| 권한 조회(`gh api repos/.../permissions`) 실패          | 안전한 쪽 = 팀원 경로로 처리, 조회 실패 사실을 완료 보고에 남김 (§2.5)   |
| 팀원 계정 (`push`만 `true`)                             | push + PR 생성까지만, 오너를 리뷰어로 지정, 머지는 안 함 (§2.5)          |
| 리뷰어 자동 지정 실패 (팀원 경로)                       | PR 생성 자체는 유지, 리뷰어 지정 실패만 완료 보고에 남김                 |
| origin/main이 앞서 있음 + 리베이스 충돌 없음 + push 전    | `git rebase origin/main` 실행 후 진행 (§1.6)                             |
| origin/main이 앞서 있음 + 리베이스 충돌 없음 + 이미 push함 | 리베이스 생략, GitHub이 머지 시점에 알아서 합침 (§1.6)                 |
| origin/main이 앞서 있음 + 리베이스 충돌 있음 + push 전    | [결정 필요]로 멈춤, 리베이스 시작 안 함 (§1.6)                           |
| origin/main이 앞서 있음 + 리베이스 충돌 있음 + 이미 push함 | 멈추지 않고 리베이스 생략한 채 진행, 완료 보고에 충돌 경고 남김 (§1.6)  |
| 이미 push한 브랜치                                      | 충돌 여부와 상관없이 리베이스 자체를 안 함 (force push 회피, §1.6)       |

## 호출 패턴

- `/done-task` — args 없음. PR title·body는 자동 추출(branch명·diff·wip 메시지)만으로 초안 짜서 바로 ship.
- `/done-task <자연어 의도>` — 자연어를 *사용자의 핵심 강조 hint*로 받음. Claude가 자동 추출 + hint 종합해 초안 짬. hint가 _title 그 자체가 되는 건 아님_ — 다른 변경도 함께 묶어서 종합 title 만듦. 예: `/done-task 다크모드 토글 추가` → "다크모드 토글 + 색 토큰 정리" 식으로 종합.
- `/done-task 스킵` — §1.5 simplify 게이트 [결정 필요]에 대한 결정. 코드 변경 있어도 simplify 없이 바로 ship.
- `/done-task 변경은 커밋하고 진행` — §1-c working tree [결정 필요]에 대한 결정을 담아 재호출.
- `/done-task 머지로 진행` — §1.6 리베이스 충돌 [결정 필요]에 대한 결정. 사용자가 로컬에서 `git merge origin/main`으로 충돌을 이미 풀었을 때 씀.
- `/done-task 리베이스 없이 진행` — §1.6 리베이스 충돌 [결정 필요]에 대한 결정. 리베이스 없이 그냥 PR 올림.
- `/done-task 머지까지` — §2.5 권한 판정과 상관없이 오너/메인테이너 경로로 진행 (권한 조회가 실패했지만 실제로 머지 권한이 있는 걸 알 때 씀).
- `/done-task 머지하지 마` / `/done-task PR까지만` — §2.5 권한 판정과 상관없이 팀원 경로로 진행 (오너라도 이번엔 리뷰부터 받고 싶을 때 씀).

## 안 하는 것 (의도적)

- ❌ main 싱크·옛 브랜치 정리·새 브랜치 생성 — 그건 `new-task` 스킬 (§3-d에서 `--delete-branch`가 치우지 못하고 남은 로컬 브랜치도 마찬가지)
- ❌ Claude 자동 invoke — `disable-model-invocation: true`
- ❌ stage·commit 자동화 — *현재 commit된 wip*만 ship. 추가 변경은 사용자가 commit 또는 §1-c (a) 옵션 선택.
- ❌ simplify 스킬 직접 실행 — fork 안에서 안 함. §1.5에서 [결정 필요] 반환만 하고, 실제 `/simplify` 실행·검증·커밋(`chore: simplify 반영`)은 메인 세션 몫
- ❌ PR title·body 별도 확인 — 호출 자체가 ship 승인이라 초안 그대로 사용 (사용자가 정한 규칙)
- ❌ 다른 base 브랜치 — main 전제
- ❌ merge commit·rebase merge — **squash 전용** (wip archaeology 보존 + main 깨끗을 위해)
- ❌ local squash (`git reset --soft` 후 1 commit) — wip archaeology 손실. _GitHub squash가 best of both worlds_
- ❌ force push — 안전한 push만
- ❌ 이미 push한 브랜치 리베이스 — force push가 필요해지므로 절대 안 함 (§1.6)
- ❌ 충돌 있는 상태로 리베이스 시작 — `git merge-tree`로 먼저 예행 검사하고, 충돌 있으면 [결정 필요]로 멈춤 (§1.6)
- ❌ 머지 권한 없는데 머지 강행 — `push`만 있고 `admin`·`maintain`이 없으면 PR 생성까지만 (§2.5)
- ❌ 브랜치 보호 규칙으로 강제 — 저장소가 비공개+무료 플랜이면 GitHub 브랜치 보호 규칙 자체를 걸 수 없음(API 403). "머지는 오너만"은 이 스킬이 지키는 관례일 뿐, GitHub이 막아주는 강제 규칙이 아니다
