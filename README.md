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

아래 절차는 전부 **사용자가 직접** 실행한다 — Claude Code가 알아서 해주지 않는다. 명령을 치는 곳은 둘 중 하나다:

- **터미널** — Claude Code를 켜기 전, 컴퓨터의 명령어 창(터미널 앱)에 그대로 쳐 넣는 명령. `claude plugin ...`로 시작한다.
- **Claude Code 세션** — 터미널에서 `claude`를 실행해 채팅 화면이 뜬 다음, 그 채팅창 안에 쳐 넣는 명령. `/`로 시작한다.

아래 각 단계에 어느 쪽 명령인지 표시해뒀다.

**스코프(scope)**란 이 플러그인을 어디까지 적용할지 정하는 설정이다. 이 하네스는 항상 **쓰고 싶은 프로젝트 딱 하나에만(`--scope project`)** 설치한다 — 컴퓨터의 모든 프로젝트에 자동으로 적용되는 방식(user 스코프)은 쓰지 않는다. 이유: 이 하네스에는 자동으로 작동하는 규칙이 2개 있는데(main 브랜치에 바로 올리는(push) 걸 막고, 답변이 끝날 때마다 커밋을 자동으로 만든다), 이 규칙이 하네스와 상관없는 다른 프로젝트에서까지 걸리면 곤란하기 때문이다.

**1) 마켓플레이스 등록 — 컴퓨터에 딱 한 번만 하면 된다**

"마켓플레이스 등록"이란 **"이 플러그인이 어디 있는지 Claude Code에게 미리 알려주는 것"**이다. 한 번 등록해두면 그 정보가 `~/.claude` 폴더에 저장되고, 이후 어떤 프로젝트에서든 이 플러그인을 설치할 수 있게 된다.

"어디 있는지"를 알려주는 방법이 두 가지 있다. **이 둘은 같은 걸 두 번 하는 게 아니라, 이 문서를 읽는 사람의 역할에 따라 하나만 고르는 것**이다:

- **역할 A. 플러그인 사용자** — 이 하네스를 가져다 쓰기만 하는 사람. 하네스 코드를 고칠 일이 없다. **대부분이 여기에 해당한다.**

  → **GitHub 주소**로 등록한다. GitHub는 이 플러그인의 원본 코드가 올라가 있는 인터넷 사이트다. 이 방법을 쓰면 자기 컴퓨터에 미리 받아둘 파일이 아무것도 없다 — Claude Code가 인터넷에서 알아서 가져온다.

  터미널에서:
  ```
  claude plugin marketplace add youngdonkim/builder-harness
  ```

- **역할 B. 하네스 개발자** — 이 builder-harness 저장소 자체를 만들고 고치는 사람. 곧 이 저장소의 관리자이거나, 저장소를 자기 컴퓨터에 내려받아(clone) 그 안의 파일을 직접 수정하는 기여자다.

  → **저장소를 내려받아 둔 폴더의 경로**로 등록한다. 이렇게 하면 개발자가 파일을 고칠 때마다 그 수정 내용이 곧바로 반영된다 — GitHub에 올릴(push) 때까지 기다릴 필요가 없다.

  터미널에서 (`~/dev/builder-harness`는 예시 — 각자 저장소를 내려받은 실제 폴더 경로로 바꾼다):
  ```
  claude plugin marketplace add ~/dev/builder-harness
  ```

정리하면 — **플러그인을 쓰기만 할 사람은 역할 A의 명령 하나만 실행하면 끝**이고, 역할 B는 이 하네스를 직접 개발·수정하는 사람 전용이다.

터미널 대신 이미 열려 있는 Claude Code 세션에서 등록하고 싶다면, 위 명령 앞의 `claude `를 빼고 `/`를 붙이면 된다 (동작은 똑같다):
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

업데이트는 두 단계다 — **마켓플레이스 갱신은 컴퓨터에 한 번, 플러그인 갱신은 프로젝트마다**. 아래 1번은 하네스 개발자(역할 B)가 하는 일이고, 2번부터는 새 버전을 받아 쓰려는 사람(역할 A·B 모두)이 자기 컴퓨터에서 하는 일이다.

1. **(하네스 개발자)** 어느 프로젝트에서든 하네스 개선점 발견 → **이 저장소에서** 수정·커밋·push (`claude-harness-tuning` 스킬로 위치·작성 기준 결정)
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
4. **적용 시점**: 지금 이미 열려 있는 Claude Code 세션에는 반영되지 않고, **다음에 새로 여는 세션부터** 적용된다("Restart to apply changes"). 지금 세션에 바로 반영하고 싶다면 그 세션 안에서 `/reload-plugins`를 치면 된다.

**자동 갱신**을 원하면 프로젝트의 `.claude/settings.json` 파일에서 `extraKnownMarketplaces.builder-harness` 항목에 `"autoUpdate": true`를 추가한다 — 그러면 Claude Code 세션을 새로 열 때마다 자동으로 최신본을 확인한다. (이 저장소처럼 Anthropic이 아니라 개인·커뮤니티가 만든 마켓플레이스는 기본적으로 이 자동 확인이 꺼져 있어서, 켜고 싶으면 직접 설정해야 한다.) 이 경우도 방금 받아온 걸 지금 열린 세션에서 바로 쓰려면 `/reload-plugins`는 그대로 쳐야 한다.

버전 번호는 `plugin.json`에 따로 적지 않는다 — 커밋할 때마다 자동으로 생기는 고유 값(커밋 해시)이 버전 역할을 해서, 커밋 하나하나가 전부 새 버전으로 인식된다. 만든 사람이 직접 매일 써보면서 바로바로 고치는 중이라 이렇게 해뒀다(이런 방식을 "도그푸딩"이라고도 부른다). 나중에 다른 사람들에게 정식으로 배포할 때는 버전 번호를 정해서 관리하는 방식으로 바꿀 것이다.

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
