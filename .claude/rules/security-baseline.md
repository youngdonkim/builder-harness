---
name: security-baseline
description: 외부 도달 위협 모델(preview·공유 링크·봇·검색엔진은 전부 외부 노출) + Supabase 권한 baseline(기본 비공개·grant와 정책 두 겹·정책 모양·금지 목록). auth·API·업로드·supabase 코드를 만지면 로드된다.
paths:
  - '**/api/**/*'
  - '**/auth/**/*'
  - '**/middleware*'
  - '**/upload*'
  - 'supabase/**/*'
---

# 보안 baseline

규칙마다 **근거 등급**을 붙였다. 나중에 뒤집고 싶을 때 어디를 다시 봐야 하는지 보이게 하려는 것이다.

| 표시 | 뜻 | 뒤집으려면 |
|---|---|---|
| **[공식]** | 공급자 공식 문서가 시키거나 금지한 것 | 공식 문서가 바뀌었는지 확인 |
| **[우리 결정]** | 맞고 틀림이 없고 우리가 골라 정한 것 | 팀이 다시 정하면 됨 |
| **[실측 1건]** | 실제로 한 번 겪어서 아는 것 | 재현되는지 다시 확인 |

## 1부 — 외부 도달

preview URL·공유 링크·봇 prefetch·검색엔진·우연한 ID 추측 — 모든 deploy 환경에서 외부 도달 가능. preview = prod 동일 노출. **"내부 베타라 안전" 가정은 위협 모델 불일치**. `NODE_ENV === 'development'`는 로컬에서만 true. **[공식]**

### attack surface 분기

이 사이클이 가진 attack surface에 따라 적용 룰 0~다수:

- **없음** (정적 사이트·외부 link redirect만) → 적용 0
- **있음** (사용자 데이터·인증·업로드·DB·API) → prototype부터 baseline 박음. mvp 진화 시 자연 흡수.

### 영역별 baseline

- **인증·세션**: http-only cookie, secure flag (prod), CSRF 토큰 **[공식]**
- **민감정보**: 응답에서 user 객체 외 빼기, secret은 env var (코드 X) **[공식]**
- **업로드**: 크기·MIME 타입·확장자 검증, 저장 경로 격리 **[공식]**
- **API**: rate limit, input validation, error 메시지에 stack·sql 노출 X **[공식]**

**권한(authz)은 여기 없다 — 2부다.** Supabase에선 endpoint마다 검사하는 게 아니라 **DB 정책이 판정**한다.

영역별 상세 룰이 필요해지면 `.claude/rules/`에 별도 파일로 추가.

## 2부 — Supabase 권한

전제: **Supabase + Next.js 고정 스택** 기준이다.

### 기본 비공개 — 새 표는 아무도 못 읽는 상태로 시작 **[우리 결정]**

공개는 표마다 명시적으로 연다.

```sql
grant select on 새표 to anon;                                                          -- 출입증
create policy ..._read_public on 새표 for select to anon, authenticated using (true);  -- 열쇠
```

이유는 **실수의 방향**이다.

- 기본 비공개 → 실수하면 **"안 보인다"** → 바로 티 난다
- 기본 공개 → 실수하면 **"다 보인다"** → 아무도 모른다

번거로운 것이 요점이다. 표를 열 때마다 "이거 정말 공개해도 되나?"를 한 번 묻게 된다.

### 권한은 두 겹 — grant와 policy 둘 다 **[공식]**

- **grant** = "이 역할이 이 동작을 할 수 있나"
- **policy** = "그중 어느 행에 적용되나"

**노출하는 모든 표에 둘 다 설정한다.** 정책만 걸고 grant를 회수하지 않으면 `anon`한테 insert 길이 그대로 열려 있다.

### 정책 모양 다섯 줄 **[공식 — 벤치마크 포함]**

**이 다섯은 어겨도 에러가 안 난다. 조용히 느려질 뿐이라 아무도 모른다** — 그래서 규칙으로 박는다.

| # | 규칙 | 효과 |
|---|---|---|
| ① | 함수는 `select`로 감싼다 — `(select auth.uid())` | 11,000ms → 10ms |
| ② | `to authenticated`를 항상 붙인다 | 170ms → 0.1ms 미만 |
| ③ | 정책이 거르는 컬럼에 인덱스를 만든다 | 100배 |
| ④ | `for all` 금지 — SELECT·INSERT·UPDATE·DELETE 4개로 쪼갠다 (SELECT는 `using`만, INSERT는 `with check`만) | 불필요한 검사 제거 |
| ⑤ | 권한 표 조회는 `security definer` 함수로 감싼다 | 178,000ms → 12ms |

### 정책은 신분이 아니라 권한 이름으로 묻는다 **[우리 결정]**

```sql
using ( (select has_role('operator')) )        -- ❌ 문에 신분을 쓴다
using ( (select authorize('reports.resolve')) ) -- ✅ 문에 권한을 쓴다
```

지금은 둘이 똑같이 동작한다. 갈리는 건 나중에 **"검토자도 신고를 처리한다"**가 될 때다 — 신분을 쓴 정책은 **전부** 고쳐야 하고, 권한을 쓴 정책은 **판정 함수만** 고치면 된다.

역할 표·판정 함수를 실제로 만드는 절차는 `idea-to-mvp` 6단계의 `6-mvp-build-auth-authz.md` §2에 있다.

### ⚠ 공개 정책이 판정 함수를 타면 `anon`에도 `grant execute` **[실측 1건]**

정책이 이런 모양이면:

```sql
using ( 공개조건 or (select authorize('...')) )
```

**Postgres는 `or`의 평가 순서를 보장하지 않는다.** 비로그인 조회에서도 판정 함수가 평가될 수 있고, execute 권한이 없으면 그 자리에서 오류가 나 **공개 목록 전체가 안 보인다.**

→ 공개 정책이 판정 함수를 타면 `anon`에도 execute를 연다. 함수 안에서 비로그인은 어차피 `false`가 된다.

### 하지 말 것 여덟 **[전부 공식이 명시적으로 금지]**

| # | 하지 말 것 | 어기면 |
|---|---|---|
| ① | `@supabase/auth-helpers-nextjs` 사용 | 폐기된 패키지 |
| ② | 쿠키를 `get`/`set`/`remove`로 다루기 | `getAll`/`setAll`만 쓴다 |
| ③ | 서버에서 `getSession()`을 인가 근거로 쓰기 | 쿠키는 위조된다 — `getClaims()`를 쓴다 |
| ④ | `createServerClient`와 `getClaims()` 사이에 코드 넣기 | 무작위 로그아웃 버그 |
| ⑤ | `user_metadata`로 권한 판단 | 사용자가 직접 고칠 수 있다 |
| ⑥ | secret key(구 `service_role`)를 브라우저에 노출 | RLS를 통째로 통과 |
| ⑦ | refresh token reuse interval(10초) 변경 | 갱신이 깨진다 |
| ⑧ | 인증이 든 응답을 ISR·CDN이 캐시하게 두기 | 남의 세션이 다른 사람에게 나간다 |

### 앱 코드 검사는 겹쳐 쌓기지 최종 판정이 아니다 **[공식]**

앱에서 권한을 확인하지 말라는 말이 아니다. 공식이 시키는 건 **겹쳐 쌓기(defense in depth — 방어를 여러 겹 두기)**다. 다만 **판정은 DB 정책이 한다** — 앱 검사가 유일한 문이 되면 그 문을 안 거치는 경로에서 통째로 뚫린다.
