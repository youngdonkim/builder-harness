# 배선 — 흩어진 한두 줄 묶음

코드 견본(`code/*.md`)을 놓은 뒤, 프로젝트 여기저기에 한두 줄씩 넣는 것들이다. 줄마다 「이미 있나」를 먼저 보고 없을 때만 넣는다.

## 목차

1. [next.config — 스위치와 배포 id](#1-nextconfig--스위치와-배포-id)
2. [공통 layout — 한 줄](#2-공통-layout--한-줄)
3. [전역 CSS — 두 번 톡 확대 끄기](#3-전역-css--두-번-톡-확대-끄기)
4. [package.json — 의존·시험 스크립트](#4-packagejson--의존시험-스크립트)
5. [.env.example — 이름만](#5-envexample--이름만)
6. [middleware/proxy matcher 확인](#6-middlewareproxy-matcher-확인)
7. [화면 문구 키](#7-화면-문구-키)
8. [처리방침 4줄 — 뜻](#8-처리방침-4줄--뜻)
9. [비밀값 장부 3행](#9-비밀값-장부-3행)
10. [프로젝트 기록 docs/qa-feedback.md](#10-프로젝트-기록-docsqa-feedbackmd)
11. [부품 목록 한 줄](#11-부품-목록-한-줄)

---

## 1. next.config — 스위치와 배포 id

`next.config.ts`(또는 `.mjs`)의 `env`에 넣는다. `env`가 없으면 만든다.

```ts
env: {
  // 지금 화면이 어느 배포에서 왔는지 — QA 이슈의 「화면이 옛 배포」 판정에 쓴다. 이미 있으면 넣지 않는다
  NEXT_PUBLIC_BUILD_ID: process.env.VERCEL_DEPLOYMENT_ID ?? "dev",
  // QA 피드백(빈 곳 3번 연속 터치 → 한 줄 → GitHub 이슈)을 켤까 — 서버 환경변수 QA_FEEDBACK=on일 때만 켬(없거나 다른 값이면 꺼짐).
  // 빌드 때 박히는 값이라 QA_FEEDBACK을 바꾸면 다시 배포해야 한다. 서버 라우트도 꺼지면 404 (docs/qa-feedback.md)
  NEXT_PUBLIC_QA_FEEDBACK: process.env.QA_FEEDBACK === "on" ? "1" : "",
},
```

- 스위치는 서버 환경변수 하나(`QA_FEEDBACK`)가 정본이다. 화면 쪽은 이 줄이 빌드 때 옮겨 받고, 서버 라우트는 요청마다 `process.env.QA_FEEDBACK`을 다시 본다 — 그래서 하나로 화면과 서버 주소가 함께 꺼진다.
- `VERCEL_DEPLOYMENT_ID`·`VERCEL_ENV`·`VERCEL_GIT_COMMIT_SHA`·`VERCEL_GIT_COMMIT_REF`는 Vercel 시스템 환경변수다. 로컬엔 없어서 「dev」·「로컬」로 나온다.

## 2. 공통 layout — 한 줄

```tsx
import { QaFeedback } from "@/components/qa-feedback/QaFeedback";
// …
<QaFeedback />
```

- **로그인 없는 방식**: 앱 전체가 공유하는 layout(보통 `src/app/layout.tsx`)의 `<body>` 안.
- **로그인 방식**: 로그인 뒤 화면들이 공유하는 layout. 운영자 화면 셸은 범위 밖(필요하면 같은 한 줄을 더 붙인다).
- 성공 알림을 띄우므로 토스트가 작동하는 자리여야 한다 — shadcn이면 같은 트리 어딘가에 `<Toaster />`(sonner)가 있어야 한다. 없으면 `npx shadcn@latest add sonner` 후 루트 layout에 `<Toaster />`.
- 화면에 그리는 것은 창뿐이라 자리(위·아래)는 상관없다.

## 3. 전역 CSS — 두 번 톡 확대 끄기

전역 CSS(Tailwind 프로젝트면 `globals.css`)에 넣는다. 이미 `html`에 같은 값이 있으면 넣지 않는다.

```css
@layer base {
  html {
    /* 두 번 톡 확대만 끈다(빈 곳 3번 터치 QA 피드백이 확대로 새지 않게) — 두 손가락 확대·스크롤은 그대로 */
    touch-action: manipulation;
  }
}
```

- 아이폰은 같은 자리를 빠르게 두 번 톡 하면 확대해 버린다. 이 줄은 그것만 끈다.
- **뷰포트 meta(`maximum-scale=1`·`user-scalable=no`)로 확대를 막지 않는다** — 글자를 키워 봐야 하는 사람이 못 키운다(접근성).

## 4. package.json — 의존·시험 스크립트

```bash
npm install modern-screenshot
npm install server-only   # 이미 있으면 건너뛴다
```

`scripts`에 한 줄:

```json
"test:qa": "node --conditions=react-server --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --test src/lib/qa-feedback/issue.test.mjs"
```

- `issue.ts`가 `server-only`라 react-server 조건으로 불러온다. 시험이 `.ts`를 바로 import하므로 **Node 22.18 이상**이어야 한다(타입 지우기). 프로젝트에 vitest 등이 이미 있으면 그 틀로 옮겨도 된다.
- 하네스 CI(`.github/workflows/ci.yml`)는 하네스 소유 파일이라 고치지 않는다 — 이 시험은 SKILL.md 4.3에서 AI가 돌린다.

## 5. .env.example — 이름만

값은 절대 적지 않는다.

```bash
# QA 피드백(빈 곳 3번 연속 터치 → 한 줄 → GitHub 이슈) 스위치: on일 때만 켜짐, 비우면 꺼짐(화면·서버 라우트 함께). 바꾸면 다시 배포. 정식 공개 전 Production에서 지운다
QA_FEEDBACK=
# QA 피드백 GitHub 연결(서버 전용 — NEXT_PUBLIC 금지). 넷 중 하나라도 비면 이슈를 만들지 않고 서버 로그만 남긴다(로컬 기본값)
# 이슈용 세분화 토큰: 코드 저장소 하나 · Issues 쓰기만. 캡처용 세분화 토큰: 캡처 저장소 하나 · Contents 쓰기만
GITHUB_QA_ISSUE_TOKEN=
GITHUB_QA_SHOTS_TOKEN=
# 저장소 이름(비밀 아님, owner/repo 모양): 이슈가 생기는 저장소 · 캡처 그림을 커밋하는 비공개 저장소
GITHUB_QA_REPO=
GITHUB_QA_SHOTS_REPO=
# (선택) 라벨 이름 — 비우면 qa
GITHUB_QA_LABEL=
```

## 6. middleware/proxy matcher 확인

- **로그인 방식**: `/api/qa-feedback`이 로그인 세션 갱신(middleware 또는 Next 16의 proxy)을 **거쳐야 한다** — matcher의 제외 목록에 이 주소가 없는지 본다. 빠져 있으면 서버가 로그인을 못 읽어 401만 난다.
- **로그인 없는 방식**: middleware가 없을 수 있다. 있으면 이 주소를 막거나 다른 곳으로 돌리지 않는지만 본다.

## 7. 화면 문구 키

견본은 `@/lib/copy`의 `QA_COPY`를 부른다. 프로젝트의 문구 모음 자리에 아래 키로 만든다(자리가 다르면 import 경로를 고친다). **문구는 `mvp/design-brief.md`의 보이스 앤 톤으로 AI가 초안을 쓰고 「가정」 표시를 단 뒤, `ux-writing-reviewer`를 거쳐 사람이 확정한다.**

| 키 | 자리 | 메모 |
|---|---|---|
| `title` | 창 제목 | |
| `label` | 입력칸 라벨 | 라벨은 따로 단다 — 예시 문구(placeholder)를 라벨 대신 쓰지 않는다 |
| `placeholder` | 입력칸 안 예시 | |
| `help` | 입력칸 위 안내 한 줄 | **무엇이 함께 가는지**(화면 사진·기기 정보) 알리는 줄 — 개인정보 알림을 겸하니 빼지 않는다 |
| `count(n, max)` | 글자 수 | 함수 — 예: `` (n, max) => `${n} / ${max}` `` |
| `send` | 보내기 버튼 | |
| `sendEmpty` | 빈 글일 때 잠긴 버튼 | |
| `sending` | 보내는 중(버튼 잠김) | |
| `sent` | 성공 토스트 | 창을 닫고 띄움 |
| `failed` | 실패 — 창 안 오류 줄 | 토스트로 띄우지 않는다. 창을 닫지 않고 쓴 글을 남긴다 |
| `tooMany` | 너무 자주 보냄(429) | 실패 직후 다시 눌러도 이게 뜬다 — 원인은 서버 로그로 본다 |
| `signedOut` | 로그인이 풀림(401) | 로그인 없는 방식에선 안 쓰이지만 **처음부터 만들어 둔다**(전환 때 문구 작업이 따로 안 생기게) |

## 8. 처리방침 4줄 — 뜻

처리방침의 네 절에 한 줄씩. 아래는 **뜻**이다 — 문장은 처리방침의 기존 말투로 쓴다. **머지 전에 사람이 확정한다.** 법적으로 충분한지(국외 보관 고지 등)는 이 스킬이 판단하지 않는다 — 사람·회사가 확인한다.

| 절 | 넣을 뜻 | 방식별 |
|---|---|---|
| 모으는 정보 | 화면 빈 곳을 세 번 눌러 앱 문제를 알려 주면, 남긴 한 줄 · 그 순간의 화면 사진 · 기기·브라우저 정보 · 보던 화면 주소를 함께 받는다 | 로그인 방식이면 「계정 식별자」를 더한다 |
| 쓰는 곳 | 알려 준 앱 문제를 찾아 고치는 데만 쓴다 | |
| 보관 기간 | 앱 문제 신고(한 줄·화면 사진)는 서비스를 정식으로 공개하기 전에 모두 지운다 | |
| 맡기는 곳 | GitHub: 앱 문제 신고 보관 (미국 서버) | 「이 밖의 다른 곳에 주지 않는다」 같은 문장이 있으면 이 줄이 없을 때 사실과 어긋난다 |
| 맡기는 곳(야간 자가 수정) | Anthropic: 앱 문제 신고(글·화면 사진)를 AI로 읽어 고치는 데 씀 (미국) | 필요한지 사람이 정한다 |

**처리방침 화면이 아직 없는 프로젝트(대개 idea-to-mvp 5단계)** — 창 안 안내 줄(`help`)과 테스터 사전 안내(`human-setup.md` 「테스터 안내」)로 대신하고, `docs/qa-feedback.md`에 「처리방침이 생기면 4줄 넣기」를 남긴다. 6단계에서 처리방침 페이지를 만들 때(`6-2-backend-auth.md` §9) 같이 넣는다.

## 9. 비밀값 장부 3행

서식은 idea-to-mvp `6-0-backend-prep.md` §4. **값은 적지 않는다.** `mvp/backend-build.md`가 있으면 그 장부에, 없으면(5단계) `docs/qa-feedback.md`의 「비밀값」 절에 같은 서식으로 두고 6단계에서 장부가 생길 때 옮긴다 — `backend-build.md`를 미리 만들면 idea-to-mvp가 6단계를 끝난 것으로 잘못 판별한다.

| 비밀값 | 만든 곳 | 저장된 곳 | 다시 볼 수 있나 | 만료일 | 갱신 시 같이 바꿀 곳 |
|---|---|---|---|---|---|
| QA 이슈용 GitHub 토큰 `GITHUB_QA_ISSUE_TOKEN` (토큰 이름) | GitHub (발급 계정) → Fine-grained tokens (Resource owner, 코드 저장소 하나, Issues 쓰기) — (발급일, 승인자) | Vercel env Production·Preview(Secret) + 비밀 보관처 | 아니요 — 재발급만 | (발급 때 정한 날) | Vercel env Production·Preview ↔ 비밀 보관처 (로컬 실측 때만 `.env.local`) |
| QA 캡처용 GitHub 토큰 `GITHUB_QA_SHOTS_TOKEN` (토큰 이름) | 같은 화면 (캡처 저장소 하나, Contents 쓰기) — (발급일, 승인자) | 위와 같음 | 아니요 — 재발급만 | (발급 때 정한 날) | 위와 같음 |
| QA 피드백 설정값 `QA_FEEDBACK`·`GITHUB_QA_REPO`·`GITHUB_QA_SHOTS_REPO`(·`GITHUB_QA_LABEL`) | 사람이 정함 — 비밀 아님 | Vercel env Production·Preview | (넣은 Type에 따라 — CLI로 넣으면 다시 못 봄) | 없음 — **정식 공개 전 `QA_FEEDBACK`을 지우고 다시 배포** | Vercel env |

## 10. 프로젝트 기록 docs/qa-feedback.md

깐 프로젝트에 짧게 남긴다(사람이 읽는 문서라 ~입니다 체). 스킬을 다시 부를 때 이 문서와 `QA_REPORTER_MODE`로 상태를 읽는다.

```markdown
# QA 피드백

빈 곳을 3번 연속 터치하면 한 줄 창이 뜨고, 보내면 화면 캡처가 붙은 GitHub 이슈가 생깁니다. `/qa-to-issue` 스킬로 깔았습니다.

## 지금 상태
- 방식: 로그인 없는 방식(anon) / 로그인 방식(auth) — (깐 날짜, 전환한 날짜)
- 켜진 환경: Production · Preview (`QA_FEEDBACK=on`)
- 이슈 저장소: owner/repo · 캡처 저장소: owner/repo-qa-shots (비공개) · 라벨: qa · qa-fixed · qa-blocked

## 실측 결과
(날짜 — 아이폰 스크롤 안 함/중간/맨 아래 · PC · GitHub 웹/모바일 앱에서 그림 · 아직 안 본 것)

## 야간 자가 수정
- 루틴: (이름) · id (비밀 아닌 식별자) · 상태 켜짐/꺼짐(날짜)
- 실행 시각: (cron, UTC) = (현지 시각·요일) · 리뷰어: (GitHub 계정)
- 아침 미리보기: alias(고정 미리보기 주소) / PR 미리보기 그대로 · DB 줄: 있음/없음

## 끄는 법
`/qa-to-issue`를 불러 「끄기」라고 하면 야간 루틴과 `QA_FEEDBACK`(Production·Preview)을 끄고 정리까지 안내합니다. 정식 공개(광고) 전에 끕니다.

## 어댑터 결정
(adapters.md 표를 채운 결과 — 아이디 · 이 프로젝트에서 정한 값)

## 남은 일
- (처리방침이 없으면) 처리방침이 생기면 QA 4줄 넣기
- (로그인 없는 방식이면) 로그인이 붙으면 `/qa-to-issue`로 로그인 방식 전환

## 비밀값
(장부가 아직 없을 때만 — 9번 서식 3행)

## 코드까지 지울 때
`src/components/qa-feedback/` · `src/lib/qa-feedback/` · `src/app/api/qa-feedback/` 폴더, layout의 `<QaFeedback />` 한 줄, next.config의 `NEXT_PUBLIC_QA_FEEDBACK` 줄, 전역 CSS의 `touch-action` 줄, 문구 묶음의 `QA_COPY`, package.json의 `modern-screenshot`·`test:qa`, `.env.example`의 QA 줄. DB 마이그레이션은 없습니다.
```

## 11. 부품 목록 한 줄

프로젝트에 부품 목록 문서가 있으면(예: `docs/components.md`, 또는 `AGENTS.md` 디자인 시스템 adapter의 부품 목록) `QaFeedbackSheet` — 「QA 피드백 한 줄 창(아래에서 올라오는 창 + 입력칸 + 버튼, 기존 부품 조합)」 한 줄을 더한다. 없으면 건너뛴다.
