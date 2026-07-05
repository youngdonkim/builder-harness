# `.claude/agents/<name>.md` 작성 기준

서브에이전트는 **별도 컨텍스트 윈도우**에서 단일 책임 task를 처리. side task가 main 대화를 검색 결과·로그·파일 내용으로 flood할 때 위임 → **summary만 받음**. 또는 같은 worker를 반복 spawn할 때 정의.

## 1. 위치·우선순위

| 위치                         | 범위                | git 공유  | 우선순위 |
| ---------------------------- | ------------------- | --------- | -------- |
| `.claude/agents/<name>.md`   | 프로젝트            | ✅ commit | 3 (기본) |
| `~/.claude/agents/<name>.md` | 사용자 전역         | ❌        | 4        |
| 플러그인 `agents/`           | plugin enabled 영역 | (plugin)  | 5        |

재귀 스캔 OK (`agents/review/security.md` 같은 nested 폴더). `name` 중복 금지 — 같은 scope에서 충돌 시 임의 1개 유지·경고 없음.

## 2. Frontmatter — 필수·선택

```yaml
---
name: <agent-name>           # 필수. kebab-case. 파일명과 달라도 됨.
description: <delegate 트리거>  # 필수. Claude가 이걸 보고 delegate 결정.
tools: Read, Grep, Glob       # 선택. omit = 부모 conversation 도구 상속.
disallowedTools: Write, Edit  # 선택. 상속 list에서 제거.
model: sonnet                 # 선택. sonnet/opus/haiku/inherit (default inherit).
maxTurns: 10                  # 선택. agentic turn 상한 (Bash 등 부수효과 도구 시 권장).
skills: [name1]               # 선택. 시작 시 preload (전체 내용 inject).
memory: project               # 선택. user/project/local — 세션 간 학습.
isolation: worktree           # 선택. 임시 git worktree에서 실행 (격리).
permissionMode: default       # 선택. default/acceptEdits/plan 등.
color: blue                   # 선택. UI 색 (transcript·task list).
---
```

- 필수: `name`·`description`. 나머지 선택.
- 본문 (frontmatter 다음) = **system prompt**. agent는 이 prompt + 환경 메타(cwd 등)만 받음 — Claude Code 전체 시스템 프롬프트 X.

## 3. `description` — routing 핵심

Claude가 이 텍스트만 보고 delegate 여부 결정. skill `description`과 같은 원칙 (1,536자 cap, key use case 먼저). 추가:

- **"Use proactively after X" 패턴**이 자동 invoke trigger로 강함 (공식 권장).
- 부수효과·input/output 형태 명시.

## 4. 도구 + 모델 — 최소 권한·cost 제어

| 케이스              | 설정                                        |
| ------------------- | ------------------------------------------- |
| Read-only 검색·분석 | `tools: Read, Grep, Glob` + `model: haiku`  |
| 코드 리뷰·분석      | `tools: Read, Grep, Glob` + `model: sonnet` |
| Write 강제 차단     | `disallowedTools: Write, Edit`              |
| Bash 등 부수효과    | 명시 allow + `maxTurns` 조이기              |
| 복잡 추론·아키텍처  | `model: opus`                               |

원칙: read-only agent면 Write·Edit 절대 X. 작은 모델 fit이면 _서브 task당_ 비용 큰 절감 (main이 opus여도 sub는 haiku 가능).

## 5. 본문 + invoke

본문 = system prompt — **짧고 단일 책임**. role + task 절차 + 결과 형식. skill처럼 `references/`·`scripts/` 분리 X (skill 전용 패턴).

invoke 3 케이스:

1. Claude 자동 delegate — `description` 매칭 task 만났을 때
2. 사용자 자연어 — "Use the &lt;name&gt; agent to ..."
3. Agent tool 명시 — `Agent(subagent_type="<name>")`

## 6. 변경 시 점검 ✅

- [ ] `name`·`description` 둘 다 있나?
- [ ] `description`이 routing trigger·input·output 명시?
- [ ] `tools` 최소 권한? (read-only면 Write·Edit 차단)
- [ ] `model`이 task 복잡도에 맞나? (단순 검색에 opus는 낭비)
- [ ] 본문 system prompt가 짧고 단일 책임?
- [ ] 부수효과 도구 있으면 `maxTurns` 박혔나?
- [ ] CLAUDE.md·rules·skill에 박는 게 더 맞지 않나? (절차 user-invoke = skill, 항시 룰 = rules)

> ⚠️ 이 파일의 공식 docs 검증은 아직 안 했음 — `tools` separator(공백 vs 콤마), `isolation`·`memory`·`permissionMode`의 정확한 값 집합, hooks 필드 등은 공식 docs 추가 확인 권장. skills.md 검증은 완료(2026-05).
