# 어댑터 — 프로젝트마다 바꾸는 자리

코드 견본(`code/*.md`) 안에서 `[ADAPTER:아이디]`로 표시한 자리의 정본이다. SKILL.md 단계 1 「적용 전 확인」에서 AI가 이 표를 **프로젝트 코드·설정을 읽어 먼저 채우고**, 못 찾은 칸만 사용자에게 묻는다. 채운 표는 코딩 위임 지시서에 그대로 넘기고, 다 깐 뒤 프로젝트 `docs/qa-feedback.md` 「어댑터 결정」에 남긴다.

- **표시 모양** — 블록은 `// [ADAPTER:아이디] 설명` … `// [/ADAPTER:아이디]`, 한 줄짜리는 줄 끝 주석. 블록 안에는 참고 구현(Next.js·Supabase·shadcn) 코드가 **기본값**으로 들어 있다 — 하네스 고정 스택이면 대개 그대로 맞는다.
- **이름 끝 `?`** (`team?`) — 그 개념이 없는 프로젝트는 블록째 지운다.
- **방식 열** — 공통 / auth만(로그인 방식) / anon만(로그인 없는 방식). 고른 방식에 안 쓰이는 행은 건너뛴다.
- **다 깐 뒤** 표시 주석은 모두 지운다 — `grep -rn "\[ADAPTER:" src`가 0건이어야 끝이다. 각 파일 머리 주석에 「이 프로젝트에서 바꾼 점」을 한 줄 남긴다.
- **방식(anon/auth)은 어댑터가 아니다** — `reporter.ts`·`gate.ts`에 어느 견본을 놓느냐로 정한다(SKILL.md 「두 방식」).

## 목차

1. [어댑터 표](#1-어댑터-표)
2. [바꾸지 않는 것](#2-바꾸지-않는-것)

---

## 1. 어댑터 표

| 아이디 | 방식 | 견본 속 자리 | 기본값(참고 구현) | 이 프로젝트에서 바꿀 것 · AI가 찾는 방법 | 없으면 |
|---|---|---|---|---|---|
| `paths` | 공통 | 모든 견본의 「놓을 곳」 | `src/` 아래, `@/` = `src/` | `tsconfig.json`의 `paths`에서 `@/*`가 가리키는 곳 확인. `src/`가 없으면 `src/`를 뺀 같은 경로 | — |
| `auth-server` | auth만 | `reporter.auth` 맨 위 import + `identifyReporter` 블록 | Supabase `@/lib/supabase/server`의 `createClient()` → `auth.getClaims()`의 `sub`, `profiles.withdrawn_at`이 있으면 null(401) | 프로젝트의 서버 로그인 확인 방식. `src/lib/supabase/server.ts`·`auth.getClaims`·`auth.getUser` 검색. 탈퇴 표시 칸 이름이 다르면 그 칸으로, 없으면 profiles 조회 두 줄을 지운다 | (auth를 고를 수 없다 — anon) |
| `auth-client` | auth만 | `gate.auth` import + `useQaReady` 블록 | Supabase `@/lib/supabase/client`의 `createClient()` → `getSession()` + `onAuthStateChange` | 화면 쪽 로그인 상태. 프로젝트에 로그인 상태 훅이 있으면 그걸 쓴다 | 같음 |
| `team?` | auth만 | `reporter.auth`의 `team:` 한 줄 + 아래 팀 블록 | `members`·`teams` 표, `profiles.last_team_id`, 주소의 `?team=`·`/teams/{id}`, 「팀에서 부르는 이름」(`members.display_name`) | 팀·워크스페이스·조직 개념이 있으면 그 표·주소 규칙으로. 팀 이름은 지금 팀원일 때만 읽히게(RLS) — 서버 비밀 키를 쓰지 않는다 | `team:` 줄·팀 블록·`QaTeam` import·인자의 `meta`를 지운다. 이슈에서 「팀」 줄이 빠진다 |
| `client-ip` | anon만 | `reporter.anon` `clientIp()` | `x-forwarded-for` 첫 값(Vercel) | Vercel이면 그대로. Vercel이 이 머리글을 덮어써 위조를 막는지는 **실측 필요** — 확인되면 그대로, 아니면 Vercel 전용 머리글이나 `@vercel/functions`의 IP 도우미로 | Vercel 밖이면 스킬이 멈추고 보고 |
| `ui-sheet` | 공통 | `QaFeedbackSheet` 부품 import·클래스 | shadcn `Sheet`(side bottom)·`Input`·`Label`·`Button`, 클래스 `grid gap-4 px-4 pb-4`·`text-sm`·`text-destructive`·`text-muted-foreground` | `src/components/ui/`에 있는 부품. 없으면 `npx shadcn@latest add sheet input label button`. 클래스는 design-system 토큰 규칙(대괄호 임의 값 금지 등)대로, 하단 안전 영역은 프로젝트 셸 규칙대로. 새 CSS는 최소로 | — |
| `ui-open-guard` | 공통 | `QaFeedbackSheet`의 `<Sheet open onOpenChange>`·`onOpenAutoFocus` | 열린 채(`open`)로 두고 닫기 요청만 `onClose`로 → `QaFeedback`이 연 직후 0.4초는 무시. 첫 초점은 입력칸으로 | 쓰는 창 부품이 「닫기 요청」을 어디로 알리는지, 첫 초점을 어떻게 정하는지에 맞춘다. Radix 계열이면 기본값 그대로. **3번째 터치를 따라오는 click이 창을 바로 닫지 않는지 실측 필요** | — |
| `toast` | 공통 | `QaFeedback`의 `toast` import·`toast.success(...)` | shadcn `sonner` | 프로젝트 토스트. layout에 `<Toaster />`가 있어야 한다 | `npx shadcn@latest add sonner` |
| `copy` | 공통 | 두 컴포넌트의 `QA_COPY` import | `@/lib/copy`의 `QA_COPY` (키 12개 — `code/wiring.md` 7절) | 프로젝트 문구 모음 자리. 문구는 `mvp/design-brief.md` 보이스 앤 톤으로 AI가 초안 → `ux-writing-reviewer` → 사람 확정 | 문구 모음이 없으면 `src/lib/copy.ts`를 만들어 `QA_COPY`만 둔다 |
| `mount` | 공통 | `code/wiring.md` 2절 layout 한 줄 | 사용자 앱 셸 layout | anon: 루트 layout(`src/app/layout.tsx`). auth: 로그인 뒤 화면들이 공유하는 layout | — |
| `overlay-selector` | 공통 | `press.ts` `SKIP` | `[role=dialog], [role=alertdialog], [data-qa-ignore]` | 「열린 창 위에선 세지 않음」 선택자. 프로젝트 창·시트 부품이 role=dialog를 다는지 확인. **실측 필요** | — |
| `exclude-selectors` | 공통 | `capture.ts` `EXCLUDE` | `[role=dialog], [data-slot$="-overlay"], [data-radix-popper-content-wrapper], [data-sonner-toaster], nextjs-portal, [data-qa-ignore], iframe[id^="__SANDBOX__"]` | 창·창 배경·떠 있는 메뉴·토스트 선택자만 프로젝트 것으로. `nextjs-portal`(Next 개발 표시)·`[data-qa-ignore]`·`__SANDBOX__`(라이브러리 임시 iframe)는 그대로. **캡처에 창 배경이 찍히지 않는지 실측 필요** | — |
| `mask-rules` | 공통 | `shared.ts` `SECRET_PARAMS`·`SECRET_PATHS` | 쿼리 `code`·`token`, 경로 `/invite/{코드}` | 초대·비밀번호 재설정·공유 링크처럼 주소에 비밀 코드가 들어가는 경로와 쿼리 이름. `src/app` 폴더의 `[code]`·`[token]` 같은 동적 경로, 로그인 콜백의 `code` 검색. `#` 뒤는 처음부터 안 보낸다 | 경로 규칙이 없으면 `SECRET_PATHS`를 빈 배열로 |
| `device-line` | 공통 | `client.ts` `deviceLine()` | UA·`display-mode: standalone` 기반 최소 판별(아이폰·아이패드 / 안드로이드 / PC, 앱 안 브라우저 / 홈 화면 앱 / 브라우저) | 프로젝트에 기기 판별 도우미가 있으면 그걸 쓴다. 이슈에서 개발자가 읽는 값이라 서비스 문구 규칙과 별개 | 기본값 그대로 |
| `build-id` | 공통 | `code/wiring.md` 1절 | `NEXT_PUBLIC_BUILD_ID: VERCEL_DEPLOYMENT_ID ?? "dev"` | next.config에 이미 있으면 넣지 않는다 | 넣는다 |
| `api-helpers` | 공통 | `route.ts`의 `NO_STORE`·`json`·`sameOrigin` | 견본 안에 실려 있음 | 프로젝트에 같은 도우미가 있으면 import하고 블록을 지운다 — 단 `sameOrigin`은 `requireOrigin`(Origin 머리글이 없으면 거절 — 로그인 없는 방식에 필요)을 지켜야 한다 | 견본 그대로 |
| `gh-user-agent` | 공통 | `github.ts` `USER_AGENT` | `my-app-qa-feedback` | `<저장소 이름>-qa-feedback` | — |
| `tz-lang` | 공통 | `issue.ts` `TIME_ZONE`·`TIME_ZONE_LABEL` | `Asia/Seoul` · `한국` | 이슈의 시각 기준. 바꾸면 `issue.test.mjs` 마지막 시험의 기대값도 그 시간대로 고친다. 이슈 본문은 개발자가 읽는 글이라 한국어 그대로 둔다 | 기본값 그대로 |
| `rate-limit` | 공통 | `server.ts` `GAP_MS`·`DAY_MAX`·`HOUR_MAX_ALL` | 같은 보낸 사람 30초 1번·하루 20번, 인스턴스 전체 한 시간 60번 | 보통 그대로. 같은 와이파이의 테스터들이 IP 하나를 나눠 쓰면(anon) 실측 뒤 늘린다 | — |

**견본 밖에서 확인하는 것** (어댑터 표시는 없지만 단계 1에서 같이 본다)

- **스택** — Next.js App Router(`src/app` 또는 `app` 폴더)와 Vercel(`.vercel/project.json` 또는 Vercel 대시보드의 git 연동). 아니면 깔지 않고 멈춰 보고한다 — 서버 주소·스위치 옮기는 줄·배포 정보·IP 머리글·요청 본문 한도가 모두 다시 짜야 하는 자리다.
- **middleware/proxy matcher** — `code/wiring.md` 6절.
- **전역 CSS 위치** — `code/wiring.md` 3절.
- **처리방침 자리** — 처리방침 문구가 있는 파일·페이지. 없으면 `code/wiring.md` 8절 끝.
- **Node 판** — `node --version` 22.18 이상(단위 시험). 아니면 사용자에게 알리고, 시험은 판을 올린 뒤 돌린다.
- **부품 목록 문서** — `code/wiring.md` 11절.

## 2. 바꾸지 않는 것

아래는 실기기·실측으로 정한 값이거나 보안 장치라 프로젝트마다 바꾸지 않는다. 바꾸고 싶은 이유가 생기면 고치기 전에 사용자에게 근거(`why.md`)와 함께 묻는다.

- 3번 터치 판정값 — 3번 · 각 사이 400ms · 첫 터치에서 30px · 누른 채 10px 넘게 움직이면 그 터치 무효 · 창을 연 뒤 400ms 닫기 무시
- `capture.ts`의 `EXCLUDE` 밖 전부(아이폰 대응 4종·안쪽 스크롤 칸·글꼴·상한)
- 서버 확인 순서 — 스위치 404 → 같은 출처 403 → 크기 413 → 누구인가 401(auth만) → 연속 제출 429 → 내용 400
- 크기 한도 — 요청 4MB · 캡처 2MB · 메타 4KB · 글 200자
- 이슈 본문 안전 처리(`issue.ts` + 단위 시험)
- 로그 금지 항목 — 글 내용 · 이미지 · 계정 id · 팀 이름 · IP · 토큰 · 이슈 번호·주소
- 토큰 둘 분리(이슈용 Issues 쓰기 / 캡처용 Contents 쓰기) · 캡처는 별도 비공개 저장소
- 환경변수 이름 `QA_FEEDBACK`·`GITHUB_QA_ISSUE_TOKEN`·`GITHUB_QA_SHOTS_TOKEN`·`GITHUB_QA_REPO`·`GITHUB_QA_SHOTS_REPO`·`GITHUB_QA_LABEL`
- 폴더·주소 이름 `src/lib/qa-feedback/`·`src/components/qa-feedback/`·`/api/qa-feedback`, 방식 상수 `QA_REPORTER_MODE`
