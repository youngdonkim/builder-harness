# `.claude/skills/<name>/SKILL.md` 작성 기준

invoke 시점(Claude 자동 또는 `/<name>`)에 본문 로드. 다단계 절차·체크리스트·workflow 묶음. 본문은 한 번 invoke되면 **세션 끝까지 컨텍스트에 남음** → 본체는 슬림하게, 디테일은 `references/`로.

## 1. Frontmatter — 필수·선택 (공식 전체)

```yaml
---
name: <skill-name>           # 소문자·숫자·하이픈, 64자 이하 (생략 시 디렉토리명)
description: <key use case 먼저, 그다음 트리거 단서>
when_to_use: <부가 트리거 문구>          # 선택
argument-hint: "[issue-number]"          # 선택 — autocomplete 인자 힌트
arguments: [issue, branch]               # 선택 — $name 치환용 명명 인자 (positional)
disable-model-invocation: true           # 선택 — Claude 자동 호출 차단 (default false)
user-invocable: false                    # 선택 — `/` 메뉴 숨김 (default true)
allowed-tools: Read Grep Bash            # 선택 — space-separated 또는 YAML list
paths: ["glob/**/*.ts"]                  # 선택 — comma-separated 또는 YAML list, 매칭 파일 작업 시에만 활성화
model: sonnet                            # 선택 — turn 한정 모델 override (sonnet/opus/haiku/inherit)
effort: medium                           # 선택 — turn 한정 effort (low/medium/high/xhigh/max)
context: fork                            # 선택 — forked subagent 컨텍스트에서 실행
agent: Explore                           # 선택 — context: fork 시 subagent type (Explore/Plan/general-purpose/커스텀)
hooks: { PostToolUse: [...] }            # 선택 — 스킬 lifecycle 한정 hooks
shell: bash                              # 선택 — `!` 명령 셸 (bash default / powershell)
---
```

- **`name`**: 소문자·숫자·하이픈, 64자 이하. 생략 시 디렉토리명.
- **`description`**: 가장 중요. Claude가 이 텍스트만 보고 자동 invoke 결정. **key use case 먼저** 박아라.
- **`description` + `when_to_use` 합쳐 1,536자 cap** (공식, `maxSkillDescriptionChars`로 조정 가능). 초과 시 잘림.
- **`disable-model-invocation`**: deploy·commit 등 부수효과 워크플로 → 사용자만 `/name`으로 invoke. **subagent preload도 차단**.
- **`user-invocable: false`**: `/` 메뉴 숨김. 백그라운드 지식(legacy system 설명 등) → Claude만 자동 사용.
- **`context: fork` + `agent`**: 스킬을 별도 subagent context에서 실행. SKILL.md 본문이 그 subagent의 task가 됨. 메인 대화 컨텍스트 절약·격리 효과. ⚠️ explicit task가 있는 스킬만 — 가이드라인만 있는 스킬은 의미 없음.
- **`model`·`effort`**: turn 한정 override. 다음 prompt부터 세션 기본으로 복귀. settings에 저장 X.
- **`paths`**: comma-separated string 또는 YAML list. 매칭 파일 작업 시에만 자동 활성화.
- **`shell: powershell`**: 인라인 `` !`cmd` `` 실행을 powershell로. `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` 필요.

## 2. 분량 — SKILL.md < 500줄 (공식 권장)

- skill 본체는 invoke 후 **세션 끝까지 컨텍스트에 남음**.
- 500줄 넘으면 supporting file (`references/*.md`) 로 분리.

### Auto-compaction 동작 (공식, 정정판)

- compaction 시 **각 invoke된 스킬의 first 5,000 tokens** 만 유지.
- 재첨부 스킬 전체가 **combined budget 25,000 tokens** 공유.
- **최근 invoke된 스킬부터** 채우고, 오래된 스킬은 budget 소진 시 **drop**.

→ 한 세션에서 스킬 여러 개 invoke 시 오래된 건 compaction 후 사라질 수 있음. 필요하면 **재invoke**.

## 3. Progressive disclosure (공식)

- SKILL.md = 진입점·navigation.
- 상세 절차·예시·reference data → `references/*.md`로 분리해서 lazy read.
- 실행 스크립트 → `scripts/` (Bash 호출, 컨텍스트에 안 들어옴).
- `${CLAUDE_SKILL_DIR}` 변수 사용 → 스킬 위치 무관(personal/project/plugin) 스크립트 경로 참조 가능.

## 4. invoke 패턴 결정 표 (공식 표 일치)

| 케이스                                                            | 설정                             | 사용자 invoke | Claude invoke | 컨텍스트 적재                              |
| ----------------------------------------------------------------- | -------------------------------- | :-----------: | :-----------: | ------------------------------------------ |
| Claude 자동 + 사용자 수동 둘 다                                   | (default)                        |      ✅       |      ✅       | description 항상 / invoke 시 본문 로드     |
| 부수효과 있는 워크플로 (deploy·send-message 등) — 사용자만 invoke | `disable-model-invocation: true` |      ✅       |      ❌       | description **미적재** / invoke 시 본문 로드 |
| 백그라운드 지식 (legacy system 설명 등) — Claude만 자동 사용      | `user-invocable: false`          |      ❌       |      ✅       | description 항상 / invoke 시 본문 로드     |

## 5. 동적 컨텍스트 주입 (공식)

skill 본문에 다음 형태 → invoke 시점에 shell 실행 결과를 본문에 inline. Claude는 명령이 아닌 **결과**를 받음.

```markdown
인라인:  !`git diff HEAD`

여러 줄:
```!
node --version
npm --version
git status --short
```
```

- 인라인 `!`는 **줄 시작 또는 whitespace 직후**에만 인식 (`KEY=!``cmd``` 같은 형태는 literal 처리).
- substitution은 **1회**만 적용 — 명령 출력이 또 placeholder를 만들어도 재해석 X.
- `disableSkillShellExecution: true` 설정 시 모든 `!` 실행이 `[shell command execution disabled by policy]`로 치환 (managed settings에서 유용).

## 6. String 치환 변수 (공식)

| 변수                   | 의미                                                              |
| ---------------------- | ----------------------------------------------------------------- |
| `$ARGUMENTS`           | 전체 인자 문자열                                                  |
| `$ARGUMENTS[N]` / `$N` | 0-based 위치 인자 (`$0`이 첫 인자)                                |
| `$<name>`              | frontmatter `arguments:`에 선언된 명명 인자                        |
| `${CLAUDE_SESSION_ID}` | 현재 세션 ID — 로그·세션별 파일 작성용                            |
| `${CLAUDE_EFFORT}`     | 현재 effort level — 스킬이 effort에 따라 동작 조정할 때           |
| `${CLAUDE_SKILL_DIR}`  | SKILL.md 위치 — bash injection에서 스킬 번들 스크립트 참조용      |

인자는 shell-style quoting: `/skill "hello world" second` → `$0` = `hello world`, `$1` = `second`.

## 7. 위치 hierarchy (공식)

| 위치       | 경로                                            | 적용 범위               |
| ---------- | ----------------------------------------------- | ----------------------- |
| Enterprise | managed settings 참조                           | 조직 전체               |
| Personal   | `~/.claude/skills/<name>/SKILL.md`              | 모든 프로젝트           |
| Project    | `.claude/skills/<name>/SKILL.md`                | 해당 프로젝트만         |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`               | plugin enabled 영역     |

- 같은 이름 충돌 시 **enterprise > personal > project**.
- Plugin은 `plugin-name:skill-name` namespace로 분리 → 충돌 X.
- 프로젝트 스킬은 **`.claude/skills/`가 시작 디렉토리부터 repo root까지 상향 자동 탐색**. 모노레포는 nested `.claude/skills/`도 on-demand 로딩.

## 8. 권한·visibility 제어

### 8.1 `Skill()` permission rules

`.claude/settings.json`에서 스킬 invoke를 권한 룰로 제어:

```text
# 전체 차단
deny: ["Skill"]

# 특정 스킬만 허용
allow: ["Skill(commit)", "Skill(review-pr *)"]

# 특정 스킬만 차단
deny: ["Skill(deploy *)"]
```

문법: `Skill(name)` exact / `Skill(name *)` prefix + 인자.

### 8.2 `skillOverrides` — 외부 스킬 visibility 조정

`.claude/settings.local.json`에서 스킬별 visibility 조정. **SKILL.md 자체를 수정 못 하는 경우**(shared repo·MCP 제공 스킬) 사용:

```json
{
  "skillOverrides": {
    "legacy-context": "name-only",
    "deploy": "off"
  }
}
```

| 값                      | Claude에 listing            | `/` 메뉴 |
| ----------------------- | --------------------------- | -------- |
| `"on"` (default)        | 이름 + description          | ✅       |
| `"name-only"`           | 이름만                      | ✅       |
| `"user-invocable-only"` | 숨김                        | ✅       |
| `"off"`                 | 숨김                        | ❌       |

`/skills` 메뉴에서 `Space`로 cycle, `Enter`로 저장. Plugin 스킬은 `skillOverrides` 영향 X — `/plugin`으로 관리.

### 8.3 Listing budget — description 잘림 방지

스킬 description listing은 **모델 context window의 1%** budget (기본). 초과 시 적게 invoke된 스킬의 description부터 drop.

조정:
- `skillListingBudgetFraction` (`.claude/settings.json`) — 예: `0.02` = 2%
- `SLASH_COMMAND_TOOL_CHAR_BUDGET` (env) — 고정 char 수
- `maxSkillDescriptionChars` — 개별 entry 1,536자 cap 조정
- `skillOverrides`로 priority 낮은 스킬을 `"name-only"`로 → 다른 스킬 budget 확보

`/doctor` 명령으로 budget overflow 여부·영향 받은 스킬 확인.

## 9. Skill + subagent 결합 (공식)

두 방향:

| 방향                          | system prompt        | task                | 추가 로드                                |
| ----------------------------- | -------------------- | ------------------- | ---------------------------------------- |
| 스킬 `context: fork`          | agent type 시스템    | SKILL.md 본문       | CLAUDE.md (Explore·Plan은 skip)          |
| Subagent `skills:` preload    | subagent 본문        | Claude delegate 메시지 | preload된 스킬 전체 + CLAUDE.md          |

- `context: fork` + `agent: Explore` → 스킬 본문이 read-only 탐색 task로 forked execution. 메인 대화 격리.
- subagent에서 스킬 preload → 작은 컨텍스트 agent에 reference material 강제 inject. 자세히는 [agents.md](agents.md) 참조.

## 10. 변경 시 점검 ✅

- [ ] `description`에 key use case 먼저 박았나? (Claude 자동 invoke 판단 핵심)
- [ ] `description` + `when_to_use` 합쳐 < 1,536자?
- [ ] SKILL.md < 500줄? 초과 시 `references/`로 분리?
- [ ] 부수효과 있는 workflow면 `disable-model-invocation: true`?
- [ ] `references/`는 SKILL.md에서 link로 navigate 가능?
- [ ] 스크립트는 `${CLAUDE_SKILL_DIR}` 사용해서 위치 무관 경로?
- [ ] `context: fork`면 본문이 실제 task 형태? (가이드라인만이면 의미 없음)
- [ ] CLAUDE.md·rules에 박는 게 더 맞는 내용 아닌가? (매 세션·매 파일 필요면 그쪽)
