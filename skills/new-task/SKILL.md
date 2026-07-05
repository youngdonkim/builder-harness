---
name: new-task
description: PR 머지 후 작업 단위 전환 — main 싱크 + 옛 feature 브랜치 정리(local·remote) + 새 feature 브랜치 자동 생성. 사용자 의도(args 또는 follow-up)에서 type·topic을 Claude가 추론. "다음 작업 시작", "새 브랜치 만들어줘", "PR 머지했어 다음 가자" 등에 사용.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *)
---

# new-task

사용자 대신 브랜치 단위별로 작업 단위 전환을 안전하게 자동화하는 스킬.

## 진입 전 가정

- 프로젝트 루트 디렉토리는 git repo임
- 사용 시나리오 둘 다 OK:
  - **일반 사용**: 직전 브랜치 작업이 PR로 정리된 상태 (`done-task` 직후)
  - **첫 사용**: main 위에서 새 프로젝트 첫 작업 시작 — 옛 브랜치 0개도 정상 동작 (엣지 케이스 표 참조)

## 실행 흐름

### 1. 안전 검사 (실패 시 사용자 안내 후 중단)

```bash
# 1-a. 현재 브랜치 확인
git rev-parse --abbrev-ref HEAD
```

- **브랜치에 안 묶인 상태 (detached HEAD)** → 중단. "지금 어느 브랜치에도 위치하지 않고 과거 커밋한 파일들을 보고 있어. 이 스킬은 특정 브랜치를 정리하고 새 브랜치를 만들어서 작업을 전환하는 도구라, 어느 브랜치에서 시작할지 알려줘" 안내.

```bash
# 1-b. working tree 깨끗한가?
git status --porcelain
```

- **비어있지 않으면** 사용자한테 안내: "지금 브랜치에 커밋되지 않은 변경(수정·추가·삭제된 파일)이 남아 있어. 이 스킬은 깨끗한 상태에서 새 브랜치로 전환하는 도구라, 이 변경을 먼저 정리해야 해. 어떻게 할까?
  - (a) 지금 변경을 커밋하고 진행
  - (b) 임시 보관소에 넣어두고 진행 (`git stash` — 나중에 다시 꺼낼 수 있어)
  - (c) 중단 — 직접 정리할게"

```bash
# 1-c. 현재 feature 브랜치라면 PR 상태 확인
gh pr status 2>/dev/null || true
```

- 현재 브랜치의 PR이 **미머지**면 경고: "지금 브랜치의 PR(코드 합치기 요청)이 아직 머지되지 않았어 (#번호·URL). 이 브랜치를 떠나면 작업이 main에 들어가지 않은 채로 남아. 이 스킬은 작업 끝난 브랜치에서 새 브랜치로 전환하는 도구라 확인 필요해 — 정말 떠날까? (예/아니오)"
- main이면 skip.

### 2. main 싱크

```bash
git switch main
git pull origin main
```

- pull 충돌 발생 시 (드물지만 다른 컴퓨터에서 push했을 가능성) → 중단 후 사용자에게 안내: "main 최신 가져오기(pull)에 충돌이 났어. 이 스킬은 깨끗한 main 위에서 새 브랜치를 시작하는 도구라, 충돌을 먼저 해결해야 진행 가능해. 해결하고 다시 호출해줘."

### 3. 옛 브랜치 정리

```bash
# remote에서 사라진 브랜치 prune
git remote prune origin

# local feature 브랜치 list
git branch --format='%(refname:short)' | grep -v '^main$'
```

각 local feature 브랜치에 대해:

```bash
# 그 브랜치의 PR 상태 조회
gh pr list --head <branch> --state merged --json number,state,url --limit 1
```

- 응답에 머지된 PR 있으면 → **삭제 대상**
- 사용자에게 안내: "이미 머지된 PR이 있는데 local 컴퓨터에는 그 옛 브랜치가 사본으로 남아 있어 (GitHub에서 머지해도 local 사본은 자동 안 지워짐):
  - branch-A (PR #N 머지됨, URL)
  - branch-B (PR #M 머지됨, URL)
    이 스킬은 옛 브랜치 사본을 정리하고 새 브랜치를 만드는 도구라, 위 사본들을 지워도 될까? (예/아니오)"
- 확인 OK → `git branch -D <name>` (squash merge는 force delete 필수).
- remote에 같은 브랜치 남아있으면 `git push origin --delete <name>` 추가 제안.

**미머지 PR 있는 브랜치**:

- 보존 (사용자가 추후 머지 가능성).
- 명시적으로 사용자가 "버려도 돼" 했을 때만 force delete.

**PR 없는 local 브랜치** (예: 로컬에서만 만든 실험 브랜치):

- 자동 삭제 X — 사용자에게 안내: "local에만 있는 (PR이 없는) 브랜치를 찾았어: branch-X. 이건 임시 실험용일 가능성이 있어 자동 삭제하지 않아. 어떻게 할까? (보존/삭제)"

### 4. 새 브랜치 자동 생성

#### 4-a. 사용자 의도 수집

- **args에 있으면** 사용:
  - `/new-task hero 영역 다시 디자인` → "hero 영역 다시 디자인"
  - `/new-task feat hero-redesign` → 명시적 type·topic 패턴이면 그대로 사용 (skip 4-b)
- **args 없으면** 한 줄 물어봄:
  ```
  다음 작업이 뭐야? (한 줄로)
  ```

#### 4-b. type·topic 추론 (Claude)

**type 추론 키워드** (deploy.md SoT):

| 의도 키워드                                                                       | type       |
| --------------------------------------------------------------------------------- | ---------- |
| 새 기능·추가·신규·페이지·컴포넌트                                                 | `feat`     |
| 버그·에러·깨짐·안 됨·고치기                                                       | `fix`      |
| CI·deps·설정·환경·정리                                                            | `chore`    |
| `CLAUDE.md` · `.claude/**` (rules·skills·agents·hooks) 하네스 파일 변경·생성·갱신 | `harness`  |
| 리팩터·구조 개선·이름 변경·정합                                                   | `refactor` |
| `src/content/**` 카피·글·콘텐츠 변경                                              | `content`  |
| `docs/` 사람 읽는 문서 추가·수정                                                  | `docs`     |

애매하면 가장 가까운 것 선택, 사용자가 다르면 수정 요청 가능.

**topic 생성 규칙**:

- kebab-case 명사구
- 30자 이하 (긴 의도는 핵심 키워드만 압축)
- 한글 의도 → 영문 키워드로 번역 (`헤더 색깔 변경` → `header-color-change`)
- 모호한 표현 제거 (`다시`, `좀`, `더` 등)

#### 4-c. 생성·보고

```bash
git switch -c "${type}/${topic}"
```

생성 후 사용자에게 알림: `✓ feat/hero-redesign 새 브랜치 생성 (main 최신 기반). 이름 다르게 할까?` — 한 줄 확인. 사용자가 수정 요청하면 `git branch -m <new-name>`으로 변경.

#### 엣지 — 이름 충돌

이미 같은 이름 브랜치 있으면 suffix 붙여 재시도 (`feat/hero-redesign-2`). 사용자에게 알림: "같은 이름 브랜치가 이미 있어서 `feat/hero-redesign-2`로 만들었어. 다른 이름 원하면 알려줘."

### 5. 준비 완료 보고

```
✓ 새 브랜치: <type>/<topic>
✓ 시작 시점: main 최신 (commit <short-sha>)
✓ 작업 중 자동 임시 저장 활성 (auto-wip-commit 훅 — feature 브랜치에서 매 turn 변경이 wip 커밋으로 박혀)

다음 작업 알려줘.
```

## 사용자 응대 톤

톤은 `CLAUDE.md 대화 스타일`을 따름. 이 스킬 고유: 안전 검사 결과는 한 번에 모아서 보고, 결정 요청은 한 번에 하나씩.

## 엣지 케이스

| 상황                                                      | 처리                                              |
| --------------------------------------------------------- | ------------------------------------------------- |
| 현재 브랜치가 이미 main                                   | step 1·3 skip, step 2(pull)·4(생성)만             |
| working tree 변경이 새 작업과 무관 (예: 환경 설정 잔여물) | stash 옵션 권장                                   |
| PR이 머지 안 됐는데 새 작업 가야 함                       | 사용자 명시 OK 받고 진행. 옛 브랜치 삭제 X (보존) |
| 머지된 local 브랜치 0개                                   | step 3 skip                                       |
| 새 브랜치 이름 충돌 (이미 같은 이름 있음)                 | 사용자에게 알리고 새 이름 받기                    |

## 호출 패턴

- `/new-task` — args 없음. step 4-a에서 "다음 작업이 뭐야?" 물어봄
- `/new-task <자연어 의도>` — 의도 텍스트에서 type·topic 추론
  - 예: `/new-task hero 영역 sticky note 색깔 바꾸기` → `content/hero-sticky-note-color`
- `/new-task <type> <topic>` — 명시적 패턴이면 그대로 사용 (의도 파싱 skip)
  - 예: `/new-task feat hero-redesign` → `feat/hero-redesign` 그대로

명시적 패턴 감지: `$0`이 valid type 목록 중 하나 + `$1`이 kebab-case면 명시 패턴, 아니면 전체를 자연어로 처리.

## 안 하는 것 (의도적)

- ❌ PR 자동 머지 — 사용자가 직접 또는 GitHub UI에서 결정
- ❌ commit·push — 새 브랜치 만들기만, 작업 내용 commit은 별개
- ❌ 다른 base 브랜치 지원 — main 전제. 다른 base 필요하면 별 스킬
- ❌ Claude 자동 invoke — `disable-model-invocation: true`로 차단
- ❌ 브랜치 생성 전 type·topic 확인 받기 — 자동 생성 후 사후 수정 받음 (마찰 최소화)
