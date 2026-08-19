# sources.md — grok-delegation 소스 정의 (delegation-integrator가 읽는 파일)

last_verified: 2026-08-19
update_cadence: 2w

## 공식 소스 (1순위)
<!-- 갱신 시 반드시 fetch. 코드/커맨드 정의는 raw URL 권장. -->
- 저장소: https://github.com/xai-org/grok-build-plugin-cc (fetch 200, 2026-08-19. 로컬 클론 `~/tools/grok-build-plugin-cc`가 마켓플레이스 소스)
- 커맨드/브릿지 정의(플래그 진실 소스): 로컬 경로 `~/.claude/plugins/cache/xai-grok-build/grok-build/<버전>/scripts/grok-bridge.mjs` (현재 확인된 버전 0.2.1)
  - 원격 raw: https://raw.githubusercontent.com/xai-org/grok-build-plugin-cc/main/plugins/grok-build/scripts/grok-bridge.mjs (fetch 200, 2026-08-19)
  - spawn 로직: https://raw.githubusercontent.com/xai-org/grok-build-plugin-cc/main/plugins/grok-build/scripts/lib/grok.mjs (fetch 200, 2026-08-19)
- 공식 문서 (grok CLI):
  - 헤드리스·출력 형식: https://docs.x.ai/build/cli/headless-scripting (fetch 성공, 2026-08-19)
  - 서브 에이전트: https://docs.x.ai/build/features/subagents (fetch 성공, 2026-08-19 — 병렬 출력·동시성 제한은 미기재)
- grok CLI 플래그 진실 소스: `grok --help` 로컬 출력 (문서보다 플래그가 많다 — `--no-subagents`, `streaming-messages-json` 등은 help에만 있음)

## 준공식 소스 (2순위)
- 플러그인 커밋 로그: `gh api repos/xai-org/grok-build-plugin-cc/commits` (로컬 검증 2026-08-19 — 최신 92b76a6, 2026-08-04)
- 플러그인 이슈: `gh api "repos/xai-org/grok-build-plugin-cc/issues?state=all"` (로컬 검증 2026-08-19)
- CLI 체인지로그: https://x.ai/build/changelog — WebFetch 403 (봇 차단). 실재는 검색 결과로만 확인, 내용은 아래 커뮤니티 미러로 대체
- CLI 버전 확인: `grok update --check --json` (로컬 검증 2026-08-19)

## 커뮤니티 소스 (3순위, 게시일 필수 확인)
- CLI 릴리스 노트 미러: https://releasebot.io/updates/xai/grok-build (fetch 성공 2026-08-19, 버전별 날짜 표기 있음)

## 소프트 인증 체크 (인증 여부 확인용 경량 명령)
```
grok inspect
```

## 테스트 힌트 (T1~T3 실행 시 도메인 특이사항)
- T1(읽기): `--write` 없이 호출 — 브리지가 읽기 전용 샌드박스로 띄운다
- T2(쓰기): `--write` 필요 (동작·검증 상태는 reference.md)
- T3(고급): `--background`(뒤에서 돌리기), `--resume`(직전 세션 이어붙이기)
- 자동화 공통: 지시서는 `--prompt-file` 또는 따옴표 씌운 heredoc으로 넘긴다 (명령줄 인자 금지)

## scope
- 포함: 위임/리뷰 커맨드, 플래그, 설치 절차, 모드 선택 기준
- 제외: 모델 성능 비교, 요금
