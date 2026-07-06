---
name: project-init
description: 새 프로젝트에 builder-harness 하네스 적용 — CLAUDE.md 뼈대 + .claude/rules/ 템플릿 복사 + planning/ 구조 생성. 트리거 예 "새 프로젝트 시작하자", "하네스 적용해줘", "이 repo에 하네스 세팅", 플러그인 설치 직후 첫 세팅.
---

# project-init — 새 프로젝트에 하네스 적용

플러그인은 스킬·에이전트·훅만 실어 나른다. **CLAUDE.md와 `.claude/rules/`는 플러그인이 못 싣는 파일**이라, 이 스킬이 템플릿을 프로젝트에 복사해 하네스 적용을 완성한다.

## 전제 확인

1. **현재 폴더가 프로젝트 루트인가** — 새 프로젝트의 최상위 폴더에서 실행해야 한다. 이미 `CLAUDE.md`가 있으면 덮어쓰지 말고 사용자에게 확인.
2. **git repo인가** — 아니면 `git init -b main` 제안 (done-task·new-task·훅 모두 git 전제).

## 진행 순서

### 1. 아이디어 인터뷰 (2~3질문)

사용자에게 묻는다 — 이미 대화에서 나왔으면 생략:

- 프로젝트명 (repo명과 같아도 됨)
- 아이디어 한 줄 — **누구(타겟)를 위한 무엇**
- 현재 상태 — 완전 새 아이디어인지, 이미 검증 일부 진행했는지

### 2. CLAUDE.md 생성

이 스킬 폴더의 [templates/CLAUDE.md.template](templates/CLAUDE.md.template)을 프로젝트 루트에 `CLAUDE.md`로 복사하고 `{{...}}` placeholder를 1번 답으로 채운다. 템플릿 구조(idea-to-mvp 모델·스타일·검증 섹션)는 **수정하지 않고 그대로** — 하네스 표준이다. 프로젝트 고유 내용만 placeholder에 들어간다.

### 3. rules 복사

[templates/rules/](templates/rules/)의 모든 파일을 프로젝트의 `.claude/rules/`로 복사한다 (폴더 없으면 생성). 현재 포함: `threat-model.md` (외부 도달 위협 모델 — 6단계 MvpBuild부터 실질 작동), `markdown-style.md` (마크다운 목차는 중첩 리스트로 — `**/*.md` 편집 시 트리거).

### 4. planning 구조 생성

```
planning/mvp/          # 단계 산출물 (market-research.md 등이 단계 진행하며 생김)
docs/                  # 사람이 읽는 문서 (Claude 자동 로드 X)
```

빈 폴더는 git이 추적 안 하므로 `.gitkeep` 넣기.

### 5. 마무리 안내

사용자에게 알린다:

- 하네스 스킬·에이전트·훅은 플러그인에서 자동 로드 — 이 repo에 복사 안 됨. 하네스 개선은 하네스 repo(`~/dev/builder-harness`)에서.
- 훅 2개가 자동 작동: `no-main-push`(main 직접 push 차단), `auto-wip-commit`(응답 끝날 때마다 feature 브랜치에 wip 커밋).
- 다음 단계: `/builder-harness:idea-to-mvp`로 1단계 IdeaValidation 시작. (이미 검증 일부 진행한 프로젝트면 해당 단계부터.)

## 안 하는 것 (의도적)

- ❌ 앱 스캐폴딩(`package.json`·`src/`) 생성 — 그건 6단계 MvpBuild 영역
- ❌ GitHub repo 생성·push — 사용자가 원할 때 별도로
- ❌ 기존 CLAUDE.md 무단 덮어쓰기
