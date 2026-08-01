---
name: threat-model
description: 외부 도달 위협 모델 — preview URL·공유 링크·봇 prefetch·검색엔진은 모든 deploy 환경에서 외부 노출. 인증·민감정보·업로드·API 영역 baseline.
paths:
  - 'src/api/**/*'
  - 'src/auth/**/*'
  - 'app/api/**/*'
  - 'app/auth/**/*'
  - '**/middleware*'
  - '**/upload*'
---

# 외부 도달 위협 모델

preview URL·공유 링크·봇 prefetch·검색엔진·우연한 ID 추측 — 모든 deploy 환경에서 외부 도달 가능. preview = prod 동일 노출. **"내부 베타라 안전" 가정은 위협 모델 불일치**. `NODE_ENV === 'development'`는 로컬에서만 true.

## attack surface 분기

이 사이클이 가진 attack surface에 따라 적용 룰 0~다수:

- **없음** (정적 사이트·외부 link redirect만) → 적용 0
- **있음** (사용자 데이터·인증·업로드·DB·API) → prototype부터 baseline 박음. mvp 진화 시 자연 흡수.

## 영역별 baseline

- **인증·세션**: http-only cookie, secure flag (prod), CSRF 토큰, OAuth state 검증
- **권한 (authz)**: endpoint별 권한 검사, IDOR 회피 (UUID·소유자 검증)
- **민감정보**: 응답에서 user 객체 외 빼기, secret은 env var (코드 X)
- **업로드**: 크기·MIME 타입·확장자 검증, 저장 경로 격리
- **API**: rate limit, input validation, error 메시지에 stack·sql 노출 X

영역별 상세 룰이 필요해지면 `.claude/rules/`에 별도 파일로 추가.
