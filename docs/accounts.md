# 계정 명부

프로젝트 소유(개인/회사)별로 **어느 계정으로 외부 서비스를 만드는지** 적어 둔 명부다. `/project-init`이 소유 답을 받으면 여기서 그 세트를 읽어 프로젝트 `AGENTS.md`의 「소유와 계정」 표를 채운다. 값 자체(비밀번호·키·시크릿)는 절대 여기 적지 않는다 — 계정 이름과 이메일뿐이다.

이 파일은 `payload/` 바깥이라 프로젝트에 복사되지 않는다. 프로젝트에는 자기 소유자의 세트만 들어간다.

**성격: 사람이 관리하는 데이터 파일이다** — 템플릿(placeholder 채워 복사되는 것)도, 그냥 참고 문서도 아니다. 값 갱신은 사람이 직접 하고, AI는 `project-init`(표 채울 때)과 idea-to-mvp `6-0-backend-prep.md`(계정 대조·확정 문안 만들 때)가 경로를 콕 집어 지시하는 시점에 읽는다. docs/에 있어서 매 세션 자동 로드되지는 않지만, 스킬이 명시 경로로 읽으니 필요한 순간엔 반드시 열린다.

## 개인

| 서비스 | 계정 | 확인 명령 |
|---|---|---|
| GitHub | `youngdonkim` (ydkim108@gmail.com) | `gh auth status` |
| Google (GCP 콘솔·OAuth) | ydkim108@gmail.com | 콘솔 오른쪽 위 프로필 |
| 카카오 developers | (확인 필요) | developers.kakao.com 오른쪽 위 프로필 |
| Supabase 조직 | (확인 필요) | `npx supabase orgs list` |
| Vercel 팀·계정 | (확인 필요) | `vercel whoami` |
| AI 제공사 키 | (확인 필요) | 각 콘솔 프로필 |

## 회사

| 서비스 | 계정 | 확인 명령 |
|---|---|---|
| GitHub | `kyd-allianceinternet` (kimyoungdon@allianceinternet.co.kr) | `gh auth status` |
| Google (GCP 콘솔·OAuth) | kimyoungdon@allianceinternet.co.kr | 콘솔 오른쪽 위 프로필 |
| 카카오 developers | (확인 필요) | developers.kakao.com 오른쪽 위 프로필 |
| Supabase 조직 | (확인 필요) | `npx supabase orgs list` |
| Vercel 팀·계정 | (확인 필요) | `vercel whoami` |
| AI 제공사 키 | (확인 필요) | 각 콘솔 프로필 |

## 계정 바꾸는 법 (CLI는 하나만 기억한다)

- **gh** — 계정을 여러 개 등록해 두고 전환한다: `gh auth login`(추가) → `gh auth switch --user <계정>`. 프로젝트를 옮겨 다닐 때마다 `gh auth status`의 Active account를 본다.
- **Vercel** — `vercel login`은 마지막 로그인만 남는다. 프로젝트 폴더의 `.vercel/project.json`이 어느 팀(orgId)에 묶였는지가 정본이고, 명령마다 `--scope <팀>`으로 못 박을 수 있다.
- **Supabase** — `npx supabase login`도 덮어쓰기다. 맥은 `security find-generic-password -s "Supabase CLI"`로 지금 누구인지 본다. 프로젝트 `supabase/.temp/project-ref`가 어느 조직 것인지가 정본.
- **브라우저 콘솔(Google·카카오·Supabase 대시보드)** — 아이디가 아니라 **오른쪽 위 프로필의 이메일**로 판단한다. 여러 계정이 동시에 로그인돼 있으면 마지막에 쓴 계정이 기본으로 열린다 — 콘솔 주소의 `authuser=` 값이나 프로필 전환으로 바꾼다.
