---
name: done-task
description: 현재 feature 브랜치의 WIP 커밋들을 GitHub에 push → PR 생성 → squash merge → remote 브랜치 자동 삭제.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *)
---

# done-task

현재 브랜치의 WIP 커밋들을 PR 흐름으로 main에 ship하는 스킬. **push → PR 생성 → squash merge → remote 브랜치 삭제** 한 흐름.

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
- main에 push 권한 있음 (PR로 머지하니 직접 push 권한 불필요)

## 실행 흐름

### 1. 안전 검사 (실패 시 사용자 안내 후 중단)

```bash
# 1-a. 현재 브랜치 확인
git rev-parse --abbrev-ref HEAD
```

- **main 브랜치** → 중단. "지금 main 브랜치 위에 있어. 이 스킬은 feature 브랜치를 main으로 ship하는 도구라, 먼저 작업한 feature 브랜치로 이동해야 해."
- **브랜치에 안 묶인 상태 (detached HEAD)** → 중단. "지금 어느 브랜치에도 위치하지 않고 과거 커밋한 파일들을 보고 있어. 이 스킬은 feature 브랜치를 main으로 ship하는 도구라, 어느 feature 브랜치를 ship할지 알려줘."

```bash
# 1-b. main 대비 새 commit 있는가
git log main..HEAD --oneline | head -1
```

- 비어 있으면 → 중단. "지금 브랜치에 main 대비 새 변경이 없어. 이 스킬은 새 변경을 main으로 ship하는 도구라, 작업이 끝난 게 맞는지 확인 필요해."

```bash
# 1-c. working tree 깨끗한가
git status --porcelain
```

- 비어 있지 않으면 안내: "커밋되지 않은 변경(수정·추가·삭제된 파일)이 남아 있어. 이 스킬은 *커밋된 wip*만 ship하는 도구라, 변경을 먼저 정리해야 해. 어떻게 할까?
  - (a) 지금 변경을 커밋하고 진행 (메시지 받음)
  - (b) 임시 보관소에 넣어두고 진행 (`git stash` — 나중에 다시 꺼낼 수 있어)
  - (c) 중단 — 직접 정리할게"

### 2. PR 정보 수집

#### 2-a. 자동 추출 (AI 단독)

```bash
# diff 요약
git diff main...HEAD --stat
git log main..HEAD --oneline
git log main..HEAD --pretty=format:'%s' | head -30
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
- Test plan은 _셀러가 브라우저로 직접 확인할 항목_ — Claude는 브라우저 검증 안 함 (CLAUDE.md §검증).
- 카피 룰: CLAUDE.md `## 대화 스타일`·`ux-writing-reviewer` 에이전트 (있으면) 따름.

#### 2-c. 사용자 확인

초안을 보여주고 한 줄 확인: "PR title·body 초안 짜봤어. 이대로 ㄱㄱ? 수정할까?"

사용자 수정 요청 시 손봐서 재확인.

### 3. 실행 — push + PR 생성 + squash merge + remote 삭제

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

#### 3-c. squash merge + remote 브랜치 삭제

```bash
gh pr merge <N> --squash --delete-branch
```

- 성공 시 다음 단계로.
- 머지 실패 (conflict·branch protection·CI 미통과 등) → 중단 + 사용자에게 stdout + PR URL 보고: "GitHub에서 직접 해결한 다음 다시 호출해줘."

### 4. 완료 보고

```
✓ PR #<N> 생성 + squash merge 완료
✓ main에 1개 commit으로 합쳐짐 (제목: "<PR title> (#N)")
✓ remote의 <branch> 자동 삭제됨
✓ PR 페이지에 wip <count>개 archaeology 보존: <PR URL>

다음 작업은 /new-task로 새 브랜치 만들어서 진행해줘.
팁: 작업은 *한 PR로 묶을 수 있는 내용 단위*로 끊는 게 좋아 — 너무 큰 단위는
리뷰·되돌리기·history 추적 어려움. 자세한 가이드·예시는 docs/git-workflow.md §2.5.
```

## 사용자 응대 톤

톤은 `CLAUDE.md 대화 스타일`을 따름. 이 스킬 고유: 안전 검사 결과는 한 번에 모아서 보고, 결정 요청은 한 번에 하나씩. PR title·body 확인은 _명시 ㄱㄱ_ 받기 — _흐름 cover로 머지 진행 금지_ (CLAUDE.md `## Git 명령어` 정신 — destructive 액션 명시 확인).

## 엣지 케이스

| 상황                                        | 처리                                                               |
| ------------------------------------------- | ------------------------------------------------------------------ |
| 이미 그 브랜치에 PR이 있음                  | 새로 안 만들고 기존 PR 사용. 새 commit 있으면 push만 추가 후 merge |
| push 후 PR 생성 실패                        | push는 유지. GitHub UI에서 직접 만들라고 안내                      |
| squash merge 시 conflict                    | GitHub UI에서 conflict 해결 후 머지하라고 안내                     |
| branch protection 룰 (CI 통과 필요 등)      | 정상 동작 — merge 실패 시 사유 그대로 보고                         |
| 사용자 working tree 변경이 _이번 작업 일부_ | (a) 옵션으로 추가 commit하고 진행 권장                             |
| 사용자 working tree 변경이 _별개_           | (b) stash 권장                                                     |

## 호출 패턴

- `/done-task` — args 없음. PR title·body는 자동 추출(branch명·diff·wip 메시지)만으로 초안 후 사용자 확인.
- `/done-task <자연어 의도>` — 자연어를 *사용자의 핵심 강조 hint*로 받음. Claude가 자동 추출 + hint 종합해 초안 짬. hint가 _title 그 자체가 되는 건 아님_ — 다른 변경도 함께 묶어서 종합 title 만듦. 예: `/done-task 다크모드 토글 추가` → "다크모드 토글 + 색 토큰 정리" 식으로 종합.
- 최종 title·body는 §2-c 사용자 확인 단계에서 수정 가능.

## 안 하는 것 (의도적)

- ❌ main 싱크·옛 브랜치 정리·새 브랜치 생성 — 그건 `new-task` 스킬
- ❌ Claude 자동 invoke — `disable-model-invocation: true`
- ❌ stage·commit 자동화 — *현재 commit된 wip*만 ship. 추가 변경은 사용자가 commit 또는 §1-c (a) 옵션 선택
- ❌ 다른 base 브랜치 — main 전제
- ❌ merge commit·rebase merge — **squash 전용** (wip archaeology 보존 + main 깨끗을 위해)
- ❌ local squash (`git reset --soft` 후 1 commit) — wip archaeology 손실. _GitHub squash가 best of both worlds_
- ❌ force push — 안전한 push만
