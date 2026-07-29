---
name: project-init
description: 새 프로젝트에 builder-harness 하네스 적용 — CLAUDE.md 뼈대 + .claude/rules/ 템플릿 복사 + mvp/ 산출물 폴더·docs/git-workflow.md·CI 워크플로 생성. 이미 적용된 프로젝트에서 재실행하면 복사본을 최신 템플릿과 비교해 동기화. 트리거 예 "새 프로젝트 시작하자", "하네스 적용해줘", "이 repo에 하네스 세팅", 플러그인 설치 직후 첫 세팅, "하네스 템플릿 최신으로 맞춰줘", "플러그인 업데이트했으니 동기화".
---

# project-init — 새 프로젝트에 하네스 적용

플러그인은 스킬·에이전트·훅만 실어 나른다. **CLAUDE.md와 `.claude/rules/`는 플러그인이 못 싣는 파일**이라, 이 스킬이 템플릿을 프로젝트에 복사해 하네스 적용을 완성한다. 이미 하네스가 적용된 프로젝트에서 재실행하면, 신규 복사 대신 복사본을 최신 템플릿과 비교해 갱신하는 동기화 모드로 동작한다.

## 전제 확인

1. **현재 폴더가 프로젝트 루트인가** — 새 프로젝트의 최상위 폴더에서 실행해야 한다.
2. **git repo인가** — 아니면 `git init -b main` 제안 (done-task·new-task·훅 모두 git 전제).

## 모드 판별

프로젝트 루트에 `CLAUDE.md`가 이미 있으면 이미 하네스가 적용된 프로젝트다 → **동기화 모드**(아래 [동기화 모드 절차](#동기화-모드-절차))로 진행한다. 없으면 **신규 적용 모드**(아래 [진행 순서](#진행-순서-신규-적용-모드))로 진행한다.

## 진행 순서 (신규 적용 모드)

### 1. 아이디어 인터뷰 (2~3질문)

사용자에게 묻는다 — 이미 대화에서 나왔으면 생략:

- 프로젝트명 (repo명과 같아도 됨)
- 아이디어 한 줄 — **누구(타겟)를 위한 무엇**
- 현재 상태 — 완전 새 아이디어인지, 이미 검증 일부 진행했는지

### 2. CLAUDE.md 생성

이 스킬 폴더의 [templates/CLAUDE.md.template](templates/CLAUDE.md.template)을 프로젝트 루트에 `CLAUDE.md`로 복사하고 `{{...}}` placeholder를 1번 답으로 채운다. 템플릿 구조(작업 원칙 + 디자인 시스템 adapter 자리 + 앱 개발 컨벤션 자리)는 **수정하지 않고 그대로** — 하네스 표준이다. **idea-to-mvp 방법론 설명은 CLAUDE.md에 넣지 않는다** — 방법론은 스킬 발동 중에만 필요하고 스킬이 전부 관리한다. CLAUDE.md는 만드는 제품(앱)과 사용자 취향의 자리다.

### 3. rules 복사

[templates/rules/](templates/rules/)의 모든 파일을 프로젝트의 `.claude/rules/`로 복사한다 (폴더 없으면 생성). 현재 포함: `threat-model.md` (외부 도달 위협 모델 — 5단계 MvpBuild부터 실질 작동), `markdown-style.md` (마크다운 목차는 중첩 리스트로 — `**/*.md` 편집 시 트리거).

### 4. mvp 구조 생성

```
mvp/                   # 단계 산출물 (market-research.md 등이 단계 진행하며 생김)
docs/                  # 사람이 읽는 문서 (Claude 자동 로드 X)
```

### 5. 문서·CI 템플릿 복사

- [templates/docs/git-workflow.md](templates/docs/git-workflow.md)를 프로젝트의 `docs/git-workflow.md`로 복사한다 — `no-main-push`·`auto-wip-commit` 훅과 `new-task`·`done-task`·`rewind-task` 스킬이 따르는 워크플로를 사람이 읽게 정리해둔 문서다.
- [templates/.github/workflows/ci.yml](templates/.github/workflows/ci.yml)을 프로젝트의 `.github/workflows/ci.yml`로 복사한다 — lint + build를 도는 CI로, `done-task`가 머지 전에 이 통과를 기다린다.

### 6. 플러그인 자동 갱신 설정 (선택)

사용자에게 묻는다 — "플러그인 자동 갱신을 켤까?" 켜면 Claude Code 세션을 새로 열 때마다 하네스 최신본을 자동 확인한다. 이 설정은 프로젝트의 `.claude/settings.json`에 저장되고 **repo에 커밋**되므로, 이 repo를 클론하는 팀원 전원에게도 똑같이 적용된다. 트레이드오프도 함께 안내한다 — 하네스 main에 깨진 커밋이 들어가면 팀 전체 다음 세션에 바로 전파된다.

동의하면 프로젝트의 `.claude/settings.json`에 아래 `extraKnownMarketplaces` 항목을 병합한다 (파일이 없으면 새로 만들고, 있으면 기존 키 — 특히 `enabledPlugins` — 를 보존한 채 추가):

```json
"extraKnownMarketplaces": {
  "builder-harness": {
    "source": { "source": "github", "repo": "youngdonkim/builder-harness" },
    "autoUpdate": true
  }
}
```

팀원 각자는 처음 한 번 Claude Code의 마켓플레이스 신뢰 확인을 통과해야 적용된다.

### 7. 마무리 안내

사용자에게 알린다:

- 훅 2개가 자동 작동: `no-main-push`(main 직접 push 차단), `auto-wip-commit`(응답 끝날 때마다 feature 브랜치에 wip 커밋). 뭔가 잘못돼서 되돌리고 싶으면 `/rewind-task` 스킬을 쓴다.
- 다음 단계: `/idea-to-mvp`로 1단계 UserStory 시작. (이미 검증 일부 진행한 프로젝트면 해당 단계부터.) 스킬 이름은 입력창 자동완성에 뜨는 짧은 형태로 안내한다 — 긴 정식 이름(`/builder-harness:idea-to-mvp`)은 자동완성에 나타나지 않는다.

## 동기화 모드 절차

`CLAUDE.md`가 이미 있는 프로젝트에서는 신규 복사 대신, 프로젝트에 적용된 복사본을 최신 템플릿과 비교해 갱신한다.

### 1. 비교 대상 diff

템플릿에서 복사되는 파일을 전부 비교한다:

- `templates/rules/*` ↔ `.claude/rules/*`
- `templates/docs/git-workflow.md` ↔ `docs/git-workflow.md`
- `templates/.github/workflows/ci.yml` ↔ `.github/workflows/ci.yml`

파일마다 세 갈래로 처리한다:

- **동일** → 넘어간다.
- **프로젝트에 없음** (템플릿에 새로 추가된 파일) → 그대로 복사한다.
- **다름** → 무단 덮어쓰기 금지. 어떤 파일이 어떻게 달라졌는지 변경 요지를 한 줄씩 모아 보여주고, 갱신할지 사용자에게 확인한다 — 프로젝트에서 의도적으로 커스텀했을 수 있어서다. 사용자가 갱신을 선택하면 템플릿으로 교체하고, 커스텀 유지를 선택하면 그대로 두고 마무리 보고에 남긴다.

### 2. CLAUDE.md는 동기화 대상 아님

`CLAUDE.md`는 프로젝트 고유 내용({{placeholder}}가 채워진 산출물)이라 템플릿과 다른 게 정상이므로 비교 대상에서 제외한다. 다만 템플릿의 *구조*(섹션 골격)가 크게 바뀐 경우에만 "구조가 달라졌는데 맞출까?"라고 안내한다.

### 3. mvp/·docs/ 보정

`mvp/`·`docs/` 폴더는 신규 모드와 동일하게, 없으면 채운다. `.claude/settings.json`에 `extraKnownMarketplaces.builder-harness`가 없으면, 신규 모드의 "플러그인 자동 갱신 설정" 단계와 동일하게 자동 갱신을 켤지 물어보고 반영한다.

### 4. 마무리 보고

다음 네 갈래로 요약해 보고한다: 갱신됨 / 새로 복사됨 / 커스텀 유지됨 / 전부 최신.

갱신·복사한 파일의 커밋은 그 프로젝트의 git 워크플로(feature 브랜치 → PR)를 따르도록 안내한다.

## 안 하는 것 (의도적)

- ❌ 앱 스캐폴딩(`package.json`·`src/`) 생성 — 그건 5단계 MvpBuild 영역
- ❌ GitHub repo 생성·push — 사용자가 원할 때 별도로
- ❌ 기존 CLAUDE.md 무단 덮어쓰기
- ❌ 동기화 모드에서 diff 없이 일괄 덮어쓰기 — 다른 파일은 반드시 사용자 확인 후 교체
