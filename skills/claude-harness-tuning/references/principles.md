# 공통 — context engineering 원칙

CLAUDE.md·rules·skills·agents 네 위치 모두 공통.

| 원칙                            | 의미                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| **High-signal tokens**          | 빼도 모르는 줄은 즉시 삭제. 토큰당 의사결정 영향력 최대화.   |
| **Lazy > Eager**                | 매 세션 vs 매칭 read vs invoke — 가능한 한 늦은 단계로 미룸. |
| **Specificity**                 | "코드 깨끗히" X / "API handler는 `src/api/` 아래" O          |
| **Single SoT**                  | 같은 룰이 두 파일에 있으면 충돌 위험 — 한 곳에서만.          |
| **No redundancy with LLM 상식** | LLM이 아는 표준 패턴은 박지 마.                              |

## 1. Codify 가치 판단 — 박을지 말지

LLM은 표준 지식 다 학습돼 있지만 **매번 결정 동일 X** (sampling·context 의존). codify 가치 = adherence + spec lock + grounding + audit trail. 다만 *redundancy with LLM 상식*은 noise.

**✅ codify 하는 케이스**:

| 케이스                              | 예                                                           |
| ----------------------------------- | ------------------------------------------------------------ |
| 우리 프로젝트의 _수준_ 선택         | WCAG AA vs AAA, P95 응답 ≤ 1s                                |
| 표준 _수치_ lock                    | LCP ≤ 2.5s · INP ≤ 200ms · CLS ≤ 0.1                         |
| 표준끼리 충돌 시 우선순위·trade-off | a11y vs perf 충돌 시 a11y 우선                               |
| 비명백한 함정·gotcha                | preview = prod 노출, `git checkout <SHA>`는 detached HEAD    |
| 우리 프로젝트만의 컨벤션            | branch 네이밍 `harness-md/<topic>`, squash merge 전용        |
| stage·환경별 정밀도 차이            | design token: prototype 방향만 / mvp 정량 / prod full system |

**❌ codify 안 하는 케이스** (LLM 자율에 맡김):

| 케이스                                                         | 이유                          |
| -------------------------------------------------------------- | ----------------------------- |
| 표준 그대로 따르는 일반 룰 (HTTPS·UTF-8·HTML 시맨틱·camelCase) | LLM 100% 동일 적용. noise.    |
| 자명한 모범 사례 ("clean code 작성", "이름 의미 있게")         | 토큰 낭비                     |
| 자주 바뀌는 정보 (의존성 버전·날짜·인물명)                     | 룰 stale 위험 → ADR·README로  |
| 표준을 *그대로 적용*하고 세부는 LLM 해석 OK                    | 한 줄로 충분 ("WCAG AA 적용") |

**Frame shift**: codify = *수동적 기록*이 아니라 _프로젝트의 능동적 spec_. "LLM은 자격증 있는 의사, codify는 _우리 병원 진료 매뉴얼_" — 자명한 의학 지식은 매뉴얼에 안 적고, 우리 결정만 적는다.

## 2. LLM sampling 경계 — 반복 가능성

LLM은 _같은 입력에 다른 출력_ 가능 (temperature·sampling). 룰로 *결정의 경계*를 잡아 일관성 보장.

| 기법                      | 적용                                                                                |
| ------------------------- | ----------------------------------------------------------------------------------- |
| **Output schema 명시**    | "JSON 응답: `{status: 'ok' \| 'fail', reason: string}`" 같이 구조 박기              |
| **Verification step**     | LLM이 만든 결과를 *다른 단계*에서 schema·테스트로 검증 (예: build·lint·typecheck)   |
| **Temperature/seed**      | 자동화 스크립트·재현 필요한 곳은 temperature 0 권장 (대화는 그대로 OK)              |
| **Idempotent operations** | 같은 작업 두 번 실행해도 결과 동일 (재시도 안전)                                    |
| **결정 명시**             | "후보 X·Y·Z 중 X 선택, 이유" 같이 _선택과 이유_ 함께 출력 → 다음 invoke가 같은 결정 |

## 3. 외부 의존성 fallback

agent·skill이 외부 서비스(MCP·API·플러그인)에 의존할 때 fail 처리 명시:

- **Graceful degradation** — 외부 down 시 기본 동작은? (예: WebFetch 실패 시 사용자에게 알리고 캐시 결과 또는 수동 입력 요청)
- **Timeout·retry** — 명시. 무한 대기 금지.
- **명확한 에러 메시지** — "외부 서비스 X 도달 실패. fallback: Y" 식
- **사이드이펙트 없는 retry** — POST·결제 등은 idempotency key

## 4. 비유·예시 정책 — LLM 룰엔 비유 기본 X

비유는 *사람*에게 정착되지만 LLM 추론엔 보통 추가 신호 X (학습된 패턴 매칭 우선). Anthropic prompt engineering 실험: **few-shot examples > 추상 비유**.

| 위치                                                 | 비유 정책                                 |
| ---------------------------------------------------- | ----------------------------------------- |
| `.claude/rules/`·`.claude/skills/` (LLM이 매번 읽음) | 기본 X. *frame shift 필요*한 경우만 한 줄 |
| `CLAUDE.md` voice·대화 톤                            | OK (사람도 읽음)                          |
| `planning/docs/`·`README.md` (사람용)                | 자유                                      |

**예시 선택 원칙**:

1. specific value — magic byte·timing·외울 수 없는 정량
2. non-standard pattern — LLM 직관과 어긋나는 흐름
3. 1~2줄 ❌/✅ 대조 — 흔한 함정과 정답

→ "Use examples, not analogies" — 명시적 ❌/✅ 짝이 비유보다 강한 신호.

## 5. Codify 시점 — 4 Layer × 사이클 단계

언제·어디서 codify할지 4 Layer로 매핑. 사이클 진행 중 또는 코드·디자인 작업 중 LLM이 자동 trigger 인지하도록.

| Layer            | 무엇                                          | codify 시점·위치                                                          | 절차                                    |
| ---------------- | --------------------------------------------- | ------------------------------------------------------------------------- | --------------------------------------- |
| **1. Universal** | 플랫폼·스택 무관 baseline (위협 모델·UX·a11y) | 스킬 작성 시점 — 스킬 references                                          | (사이클 전 박힘)                        |
| **2. Platform**  | web/mobile/cli 분기                           | 스킬 references 플랫폼 분기 질문 셋                                       | (스킬 안)                               |
| **3. Stack**     | Astro·Next·Flutter 등 stack 특화              | **6단계 Architecture 직후** — `.claude/rules/{kind}-{stack}.md` 자동 생성 | LLM이 공식 docs 조사·정리               |
| **4. Project**   | 우리 사이클에서 발견한 패턴                   | **retro 3분류 판정 통과 후** codify (또는 즉시 spot fix)                  | retro에서 룰화 / spot fix / 코멘트 분류 |

스킬은 Layer 1·2만 박고, 3·4는 프로젝트 안에 분리 — 스킬을 다른 프로젝트에 빌릴 때 1·2는 그대로 통하고 3·4는 그 프로젝트 환경에 맞게 새로 생성.
