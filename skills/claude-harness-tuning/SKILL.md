---
name: claude-harness-tuning
description: 룰·절차·지식을 Claude Code 하네스(CLAUDE.md · .claude/rules/ · .claude/skills/ · .claude/agents/) 어디에 어떻게 박을지 결정 + 작성 기준. **새 하네스 파일 추가 전·기존 파일 수정 전 우선 호출**. 트리거 예 "이 룰 어디 넣을까", "skill로 만들까 rule로 만들까", retro에서 새 룰 codify 결정, 기존 파일 분량 부풀어서 분리·축약 판단, "Claude가 자꾸 룰 위배" 신호.
disable-model-invocation: true
---

# Claude Code 하네스 튜닝 표준

하네스 파일(CLAUDE.md·rules·skills·agents)에 뭘 박을지·어디 박을지·어떻게 박을지를 결정하는 스킬. **파일을 직접 수정하기 전에 먼저 이 스킬로 위치를 결정**하는 게 전제.

이 SKILL.md는 진입점·결정·navigation만 담는다. **상세 작성 기준은 [references/](references/) 안의 위치별 파일** 참조 (progressive disclosure).

## 하네스 위치 이원화 — 플러그인 vs 프로젝트

하네스는 두 곳에 나뉜다. 위치 결정 전에 먼저 이 분기를 탄다:

- **builder-harness 플러그인 repo** (`~/dev/builder-harness`) — 스킬(`skills/`)·에이전트(`agents/`)·훅(`hooks/`). **모든 프로젝트에 적용될 내용**은 여기 — 플러그인 repo에서 수정·커밋하면 다른 프로젝트에 전파된다. 새 프로젝트용 CLAUDE.md·rules **템플릿**도 여기(`skills/project-init/templates/`).
- **각 프로젝트 로컬** — `CLAUDE.md`·`.claude/rules/`. 플러그인이 못 싣는 파일이라 프로젝트마다 존재(`project-init` 스킬이 템플릿 복사). **이 프로젝트에만 해당하는 내용**(도메인 룰·스택 룰·진행 상황)은 여기.

판단 기준: "다음 프로젝트에서도 똑같이 적용되나?" — 예 → 플러그인 repo / 아니오 → 프로젝트 로컬.

## 진입 흐름

1. **무엇을 박을지 명확화** — 한 줄로 정리. (예: "PR 머지 후 브랜치 정리 절차", "디자인 토큰 명명 룰", "WCAG AA 기준")
2. **결정 표**(§0)로 위치 후보 좁히기.
3. **공통 원칙** — [references/principles.md](references/principles.md) 적용 가능한지 확인 (codify 가치, redundant LLM 상식 아닌지).
4. 위치 확정 → 해당 references 파일 읽고 작성:
   - **CLAUDE.md** → [references/claude-md.md](references/claude-md.md)
   - **`.claude/rules/`** → [references/rules.md](references/rules.md)
   - **`.claude/skills/`** → [references/skills.md](references/skills.md)
   - **`.claude/agents/`** → [references/agents.md](references/agents.md)
5. 작성 후 해당 references의 **변경 시 점검 ✅** 통과.
6. **needs_review 게이트**(§2) 발동 여부 확인.

## 0. 결정 표 — 어디에 넣을지

| 종류                                 | 위치          | 로드 시점                                                    | 적합한 내용                                                                                               | 부적합한 내용                                            |
| ------------------------------------ | ------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **CLAUDE.md**                        | 프로젝트 루트 | 매 세션 시작 시 **전체 로드**                                | 매 세션 필수 — 빌드 명령·핵심 컨벤션·금지 사항·"항상 X" 룰                                                | 특정 영역에서만 쓰는 룰·긴 절차·도메인 디테일            |
| **`.claude/rules/<topic>.md`**       | 프로젝트      | `paths` 매칭 파일 read 시 (lazy) 또는 매 세션 (paths 없으면) | 특정 영역(스택·테스트·보안 등) 룰 — 해당 파일 작업 시에만 필요                                            | 매 세션 필요한 룰 → CLAUDE.md / 다단계 절차 → skill      |
| **`.claude/skills/<name>/SKILL.md`** | 프로젝트      | invoke 시점 (Claude 자동 또는 `/<name>`)                     | 다단계 절차·작업·체크리스트·invoke 가능한 task                                                            | 매 세션 적용 룰 → CLAUDE.md                              |
| **`.claude/agents/<name>.md`**       | 프로젝트      | delegate 매칭 또는 명시 호출 시점 (별도 컨텍스트 윈도우)     | 단일 책임 task를 별도 컨텍스트에서 처리 — 검색·리뷰·디버그 등 main 대화를 floods 안 시키고 summary만 받기 | 매 세션 적용 룰 → CLAUDE.md / 다단계 사용자 절차 → skill |

**원칙**: 컨텍스트는 자원 — 자주 안 쓰는 내용은 lazy-load 위치에. CLAUDE.md는 **최후 수단**.

## 1. 변경 트리거 — 이 스킬을 다시 호출하는 시점

- CLAUDE.md / rules / skills / agents **새 파일 추가** 시 → 어디 넣을지 결정
- 기존 파일 **분량이 부풀** 때 → 분리·축약 판단
- "Claude가 자꾸 룰 위배" 신호 → CLAUDE.md 비대 검토
- 룰·skill·agent이 **동작 안 함** → description·paths·tools·model 점검
- 사이클 retrospective에서 **새 룰 codify 결정** → 어디에 박을지

## 2. needs_review 게이트와의 관계

이 스킬의 적용으로 생성·수정되는 하네스 파일 자체는 **needs_review 아님** — 코딩 표준이라 자유롭게 갱신. 단 다음은 게이트 발동:

- CLAUDE.md `needs_review` 항목 추가/제거 (정책 변경)
- skill·agent에 외부 명령·시크릿 호출 추가
- agent `permissionMode` 변경 (`bypassPermissions`·`auto` 등 권한 상승)
- 룰·skill·agent이 hooks 동작에 영향 (`.claude/hooks/**` 또는 `.claude/settings.json` 변경)

## 안 하는 것 (의도적)

- ❌ 자동으로 하네스 파일 수정 — 위치·내용 결정만, 실제 작성은 사용자 확인 후
- ❌ 기존 파일 일괄 리팩터 — 트리거된 파일 하나씩
- ❌ `.claude/hooks/`·`.claude/settings.json` 변경 — CLAUDE.md `needs_review` 룰에 따라 사용자 명시 승인 필수
- ❌ **builder-harness 플러그인의 기존 skill(`idea-to-mvp` 등) 자체의 절차·로직 업데이트** — 이 스킬은 "이 내용을 어디(CLAUDE.md/rules/skills/agents)에 넣을지 애매할 때" 위치를 정하는 용도다. 프로젝트 진행 중 새로 튀어나온 룰·지식을 codify할 위치를 정할 때 쓴다. 이미 `builder-harness` repo 안 특정 skill 파일(예: `skills/idea-to-mvp/references/4-prototype.md`)을 고쳐야 함이 명확한 경우 — 즉 위치가 하나도 안 애매한 경우 — 는 이 스킬을 거치지 말고 그 파일을 바로 수정한다.
