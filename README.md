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

## 설치 — 프로젝트 스코프 (프로젝트마다 선택 설치)

아래 절차는 전부 **사용자가 직접** 실행한다 — Claude Code가 알아서 해주지 않는다. 명령을 입력하는 곳은 둘 중 하나이며, 아래 각 단계에 어느 쪽인지 명시했다:

- **터미널** — `claude`를 아직 실행하지 않은 상태에서, 평소 쓰는 셸(zsh 등)에 그대로 입력하는 명령. `claude plugin ...` 형태.
- **Claude Code 세션 프롬프트** — 터미널에서 `claude`를 실행해 대화형 세션에 들어간 뒤, 그 안의 채팅 입력창에 치는 `/`로 시작하는 슬래시 명령.

이 하네스는 **쓰고 싶은 프로젝트에만** 설치한다 (`--scope project`). 모든 프로젝트에 자동 적용되는 user 스코프는 쓰지 않는다 — 하네스와 무관한 프로젝트에서 훅(main push 차단·자동 wip 커밋)이 작동하는 걸 막기 위해서다.

**1) 마켓플레이스 등록 — 컴퓨터에 한 번만** (등록 정보는 `~/.claude` 전역에 저장):

터미널에서:
```
# GitHub에서 (다른 사람 — 이 컴퓨터에 없어도 됨)
claude plugin marketplace add youngdonkim/builder-harness

# 로컬 개발 중 (하네스 자체를 고칠 때 — 이 repo가 로컬 클론에 있을 때)
claude plugin marketplace add ~/dev/builder-harness
```

또는 이미 열려 있는 Claude Code 세션 프롬프트에서 (동작은 동일):
```
/plugin marketplace add youngdonkim/builder-harness
/plugin marketplace add ~/dev/builder-harness
```

**2) 플러그인 설치 — 쓰려는 프로젝트 폴더 기준으로**:

터미널에서 (그 프로젝트 폴더로 이동 후):
```
cd <프로젝트 경로>
claude plugin install builder-harness@builder-harness --scope project
```

또는 그 프로젝트 폴더에서 `claude`로 세션을 연 뒤, 프롬프트에 `/plugin install builder-harness@builder-harness` 입력 → 스코프 선택지에서 `project` 선택.

**3) 새 프로젝트 첫 세팅 — 그 프로젝트의 Claude Code 세션 프롬프트에서**:

```
/builder-harness:project-init
```

→ CLAUDE.md 뼈대 + `.claude/rules/` 템플릿이 프로젝트에 복사된다 (플러그인이 CLAUDE.md·rules를 직접 못 싣기 때문).

## 업데이트 흐름

업데이트는 두 단계다 — **마켓플레이스 갱신은 컴퓨터에 한 번, 플러그인 갱신은 프로젝트마다**.

1. 어느 프로젝트에서든 하네스 개선점 발견 → **이 repo에서** 수정·커밋·push (`claude-harness-tuning` 스킬로 위치·작성 기준 결정)
2. **마켓플레이스 갱신 — 아무 경로에서나, 컴퓨터에 한 번**. 새 버전을 받아만 두는 단계라 아직 어떤 프로젝트에도 영향 없음:
   ```
   claude plugin marketplace update builder-harness
   ```
3. **플러그인 갱신 — 새 버전을 쓸 프로젝트 안에서 각각**:
   ```
   cd <프로젝트 경로>
   claude plugin update builder-harness@builder-harness --scope project
   ```
   이 명령을 실행한 프로젝트만 새 버전으로 올라가고, 실행하지 않은 프로젝트는 기존 버전에 머문다. 스코프가 헷갈리면 그 프로젝트에서 `claude plugin list`로 `Scope:` 값을 확인해 그대로 넣는다 — 안 맞으면 "not found"/"not installed" 에러.
4. **적용 시점**: 지금 떠 있는 세션엔 반영 안 되고 **다음에 새로 여는 세션부터** 적용된다("Restart to apply changes"). 인터랙티브 세션 안이라면 `/reload-plugins`로 즉시 반영 가능.

**자동 갱신**을 원하면 프로젝트 `.claude/settings.json`의 `extraKnownMarketplaces.builder-harness`에 `"autoUpdate": true`를 추가 — 세션 시작 시 자동으로 최신본을 확인한다 (third-party 마켓플레이스는 기본값이 꺼짐). 이 경우도 방금 반영된 걸 같은 세션에서 바로 쓰려면 `/reload-plugins`는 그대로 필요.

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
