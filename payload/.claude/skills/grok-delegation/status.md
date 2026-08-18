# status.md — grok-delegation 수명주기 상태 (delegation-integrator가 읽고 씀)

## 선정된 연동 방식
- 방식: grok-build 브리지 직접 호출 (`grok-bridge.mjs run`)
- 선정일: 2026-08-18
- 근거: 이 저장소에서 실사용으로 검증된 유일한 경로
- 검토했던 대안: `grok-build:grok-delegate` 에이전트 — 600초 절단으로 결과를 못 받아와 탈락

## 환경
- CLI: 설치됨 (버전 미확인)
- 플러그인: 설치됨, xai-grok-build 0.2.1
- 인증: 미확인

## 테스트 결과
| 테스트 | 결과 | 실행일 | 비고 |
|---|---|---|---|
| T1 읽기 전용 위임 | 미실행(정식 테스트) | | |
| T2 쓰기 위임 | 미실행(정식 테스트) | | `--write` 유무에 따른 동작은 실사용으로 확인됨 — 없으면 `Operation not permitted` 또는 서브 에이전트 워크트리에 씀 |
| T3 고급 기능 | 미실행(정식 테스트) | | `--resume`의 한계가 실사용으로 확인됨 — 세션이 끊기면 `No previous Grok Build delegate session was found` |

## 미해결 이슈
- 정식 T1~T3 테스트가 스크래치 디렉토리에서 실행되지 않았다. delegation-integrator로 한 번 돌려야 한다.

## 이력
- 2026-08-18: CLAUDE.md에 쌓여 있던 그록 규칙을 스킬로 옮겨 초기화
