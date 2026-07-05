# builder-harness

AI 빌더(혼자 AI로 며칠~몇 주에 작동하는 걸 만들어 시장 반응으로 검증하는 사람)를 위한 **Claude Code 하네스 플러그인**. 아이디어 검증부터 MVP 런치까지 **idea-to-mvp 7단계** 한 흐름을 스킬·서브에이전트·훅으로 제공한다.

**설계 원칙**: 빌드는 AI가 거의 공짜로 해주니 — 팀·투자자에게 설명하려는 무거운 문서(ceremony)는 버리고, 빌더 자신이 뭘 만들고 뭘 안 만들지 정하는 최소 전략 + AI가 정확히 빌드하게 만드는 구체 명세만 남긴다.

## 구성

| 종류 | 이름 | 역할 |
|---|---|---|
| 단계 스킬 | `idea-to-mvp` | 7단계: IdeaValidation · MarketResearch · ScreenDesign · Prototype · ProtoRetro · MvpBuild · MvpLaunch (통과 기준 4개) |
| 횡단 스킬 | `project-init` | 새 프로젝트에 하네스 적용 — CLAUDE.md 뼈대 + rules 템플릿 복사 |
| 횡단 스킬 | `claude-harness-tuning` | 하네스 파일 어디에 박을지 결정 + 작성 기준 |
| 횡단 스킬 | `done-task` | WIP 커밋 → push → PR → merge → 원격 브랜치 삭제 한 흐름 |
| 횡단 스킬 | `new-task` | main 싱크 + 옛 브랜치 정리 + 새 feature 브랜치 생성 |
| 서브에이전트 | `ux-writing-reviewer` | UI 카피를 UX writing 원칙 대조 후 직접 교정 |
| 훅 | `no-main-push` | main 직접 push 차단 (PR 워크플로 강제) |
| 훅 | `auto-wip-commit` | 응답 종료마다 feature 브랜치에 wip 자동 커밋 |

## 설치

```
# 로컬 개발 중 (이 repo가 로컬에 있을 때)
/plugin marketplace add ~/dev/builder-harness

# 또는 GitHub에서
/plugin marketplace add <owner>/builder-harness

/plugin install builder-harness@builder-harness
```

새 프로젝트에서 첫 세팅:

```
/builder-harness:project-init
```

→ CLAUDE.md 뼈대 + `.claude/rules/` 템플릿이 프로젝트에 복사된다 (플러그인이 CLAUDE.md·rules를 직접 못 싣기 때문).

## 업데이트 흐름

1. 어느 프로젝트에서든 하네스 개선점 발견 → **이 repo에서** 수정·커밋 (`claude-harness-tuning` 스킬로 위치·작성 기준 결정)
2. 다른 프로젝트에서 `/plugin marketplace update builder-harness` → 새 버전 반영
3. 수정 직후 같은 세션에서 바로 쓰려면 `/reload-plugins`

버전은 `plugin.json`에 명시하지 않는다 — git 커밋 SHA가 버전이 되어 커밋마다 새 버전으로 잡힘 (도그푸딩용). 외부 배포 시점에 명시 버전으로 전환.

## 구조

```
.claude-plugin/
  plugin.json        # 플러그인 선언
  marketplace.json   # 이 repo 자체가 마켓플레이스 (source: "./")
skills/              # 단계·횡단 스킬
agents/              # 서브에이전트
hooks/               # hooks.json + 스크립트
skills/project-init/templates/   # 새 프로젝트에 복사되는 CLAUDE.md·rules 템플릿
```
