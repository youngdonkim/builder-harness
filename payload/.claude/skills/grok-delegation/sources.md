# sources.md — grok-delegation 소스 정의 (delegation-integrator가 읽는 파일)

last_verified: 2026-08-18
update_cadence: 2w

## 공식 소스 (1순위)
<!-- 갱신 시 반드시 fetch. 코드/커맨드 정의는 raw URL 권장. -->
- 저장소: 미확인 — delegation-integrator가 조사해서 채울 것
- 커맨드/브릿지 정의(플래그 진실 소스): 로컬 경로 `~/.claude/plugins/cache/xai-grok-build/grok-build/<버전>/scripts/grok-bridge.mjs` (현재 확인된 버전 0.2.1) — 원격 raw URL 미확인 (delegation-integrator가 조사해서 채울 것)
- 공식 문서: 미확인 — delegation-integrator가 조사해서 채울 것

## 준공식 소스 (2순위)
- 릴리즈/커밋 로그: 미확인 — delegation-integrator가 조사해서 채울 것

## 커뮤니티 소스 (3순위, 게시일 필수 확인)
- 미확인 — delegation-integrator가 조사해서 채울 것

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
