# 사람 몫

SKILL.md 4.2에서 읽는다. 점검표에서 ❌인 것만, **한 번에 한 단계** 안내하고 멈춘다. "됐습니다"를 받으면 [AI]가 확인하고 다음으로. 사람에게 보여 주는 문구(인용 블록)는 ~입니다 체.

> ⚠ 화면 위치·칸·버튼 이름은 2026-10 기준이다. 다르면 지금 화면을 따르게 하고, 이 문서를 고쳐야 한다고 보고한다.

## 목차

1. [경고 두 개 — 먼저](#1-경고-두-개--먼저)
2. [계정 대조](#2-계정-대조)
3. [캡처 저장소와 라벨](#3-캡처-저장소와-라벨)
4. [토큰 두 개](#4-토큰-두-개)
   - [4.1 토큰 승인 요청 견본](#41-토큰-승인-요청-견본)
5. [AI(Claude)가 저장소에 들어올 수 있게 허락](#5-aiclaude가-저장소에-들어올-수-있게-허락)
   - [5.1 앱 승인 요청 견본](#51-앱-승인-요청-견본)
6. [Vercel](#6-vercel)
7. [나머지 — 메일·보관·처리방침·테스터](#7-나머지--메일보관처리방침테스터)
8. [실패할 때](#8-실패할-때)

---

## 1. 경고 두 개 — 먼저

> 토큰 값은 이 대화창에 붙여 넣지 마세요. 대화 기록에 남습니다. 화면에 한 번만 보이니 복사해서 바로 Vercel 칸과 비밀 보관처에 넣으시면 됩니다.

> 설정 화면 캡처를 보여 주실 때 키·토큰·시크릿이 보이면 가리고 올려 주세요.

## 2. 계정 대조

- 브라우저의 GitHub 로그인 계정 = `AGENTS.md` 「소유와 계정」 표의 GitHub 계정인지 확인받는다.
- Claude(claude.ai) 로그인 계정이 프로젝트 소유(회사/개인)와 맞는지 확인받는다 — 야간 루틴이 그 계정에 묶인다.
- 갈래([AI]가 SKILL.md 4.1에서 읽은 값): 저장소 주인이 조직이고 내 역할이 `admin`이 아니면 4.1·5.1 승인 요청이 필요하다. 개인 저장소면 건너뛴다.

## 3. 캡처 저장소와 라벨

[AI] 있는지 먼저 본다: `gh repo view <주인>/<프로젝트>-qa-shots --json visibility,defaultBranchRef`, `gh label list --repo <코드 저장소> --search qa`. 없는 것만 "제가 만들까요?"라고 묻는다.

| 만들 것 | AI가 만들 때(허락 뒤) | 사람이 만들 때 |
|---|---|---|
| 캡처 저장소(비공개, README 포함) | `gh repo create <주인>/<이름> --private --add-readme --description "QA 피드백 화면 캡처 (비공개)"` — 조직 설정상 실패하면 재시도 말고 사람 몫 | GitHub → **New repository** → **Private** → **Add a README file** 체크 → **Create repository** |
| 라벨 `qa` | `gh label create qa --repo <코드 저장소> --description "QA 피드백 (화면 3번 터치)" --color FBCA04` | 코드 저장소 → **Issues** → **Labels** → **New label** |
| 라벨 `qa-fixed` | `gh label create qa-fixed … --description "야간 QA 수정: 고침(머지 대기)" --color 0E8A16` | 같음 |
| 라벨 `qa-blocked` | `gh label create qa-blocked … --description "야간 QA 수정: 못 고침(사람 답 필요)" --color B60205` | 같음 |

> README를 꼭 넣어 주세요. 기본 브랜치가 있어야 캡처를 저장할 수 있습니다.

> 이슈를 볼 분들이 캡처 저장소에도 읽기 권한이 있어야 이슈 안에서 그림이 보입니다.

`qa` 대신 다른 이름을 썼으면 환경변수 `GITHUB_QA_LABEL`에 같은 이름을 넣는다.

## 4. 토큰 두 개

> GitHub 오른쪽 위 프로필 → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**. 아래 표대로 두 번 만드세요.

| 칸 | 이슈용 | 캡처용 |
|---|---|---|
| Token name | `<프로젝트>-qa-issue` | `<프로젝트>-qa-shots` |
| Description | `QA 피드백 — <코드 저장소>에 qa 이슈를 만듦 (Issues 쓰기만)` | `QA 피드백 — <캡처 저장소>에 화면 캡처를 저장 (Contents 쓰기만)` |
| Resource owner | 저장소 주인(조직이면 조직) | 같음 |
| Expiration | 허용되는 최대(조직은 예: 366일) — **만료일을 알려 주세요** | 같음 |
| Repository access | **Only select repositories** → 코드 저장소 **하나만** | **Only select repositories** → 캡처 저장소 **하나만** |
| Repository permissions | **Issues → Read and write** 하나만 | **Contents → Read and write** 하나만 |
| Account·Organization permissions | 주지 않음 | 주지 않음 |
| Request message (승인이 필요할 때만 보임) | 4.1 견본 | 4.1 견본 |

→ **Generate token** → 값을 6절 Vercel과 비밀 보관처에 바로 넣는다. [AI]는 토큰 **이름과 만료일만** 받는다.

- 하나로 두 저장소를 고르지 않는다 — 코드 저장소에 Contents 쓰기가 생긴다(`why.md` 4절).
- 조직 승인 전까지 토큰은 **Pending**이고, 그동안 GitHub는 **404**로 거절한다.

### 4.1 토큰 승인 요청 견본

다섯 가지를 담는다. 사용자가 고쳐 쓰게 한다.

> `<코드 저장소>`의 QA 피드백용 GitHub 토큰 두 개 승인을 부탁드립니다.
> 1. **무엇** — 테스터가 앱에서 남긴 한 줄 피드백을 GitHub 이슈로 등록합니다(이슈용 `<토큰 이름>`, 캡처 저장용 `<토큰 이름>`).
> 2. **권한** — 이슈용은 `<코드 저장소>` 하나에 Issues 쓰기만, 캡처용은 `<캡처 저장소>` 하나에 Contents 쓰기만입니다. 코드는 쓸 수 없습니다.
> 3. **왜 막혔나** — 승인 전까지 토큰이 대기 상태라 기능이 동작하지 않습니다.
> 4. **어디서** — 조직 Settings → Personal access tokens → Pending requests.
> 5. **끊기** — 같은 화면에서 언제든 취소할 수 있고, 만료일은 `<날짜>`입니다.

## 5. AI(Claude)가 저장소에 들어올 수 있게 허락

야간 루틴은 이 허락(Claude GitHub 앱)으로만 저장소에 들어온다 — 사람 컴퓨터의 `gh` 로그인은 클라우드에서 못 쓴다.

> 브라우저에서 `https://github.com/apps/claude` → **Install**(이미 있으면 **Configure**) → 설치할 곳: 저장소 주인(조직이면 조직) → **Only select repositories** → 코드 저장소와 캡처 저장소 **두 개만** → **Install**(조직 일반 멤버면 **Authorize & Request**).

> 미리 알려 드립니다: 이 허락에는 GitHub Actions·워크플로·웹훅을 바꿀 권한이 함께 묶여 있고 뺄 수 없습니다. 그래서 밤 작업 지시문에 「`.github/` 폴더는 고치지 않는다」를 넣어 막습니다. AI는 PR까지만 하고 머지·배포는 사람이 승인합니다.

- 조직 일반 멤버면 소유자 승인이 필요하다: 조직 **Settings** → **Third-party Access** 아래 **GitHub Apps** → **Pending installation requests** → **Review** → **Approve**.
- 직통 주소 `https://github.com/organizations/<조직>/settings/installations`는 **소유자가 아니면 404**다(주소가 틀린 게 아니다).
- claude.ai 화면에선 연결 안내가 따로 안 뜬다 — 위 GitHub 앱 페이지로 바로 간다.

### 5.1 앱 승인 요청 견본

> `<조직>`의 저장소 두 개에 AI(Claude)가 들어올 수 있게 허락을 부탁드립니다.
> 1. **무엇** — 테스터가 남긴 QA 이슈를 밤마다 AI가 고쳐 PR로 올립니다.
> 2. **범위** — `<코드 저장소>`와 `<캡처 저장소>` 두 개만입니다.
> 3. **AI는 PR까지만** — 머지·배포는 다음 날 사람이 확인하고 승인해야 일어납니다.
> 4. **끊기** — 조직 Settings → GitHub Apps → Claude → **Configure**에서 저장소를 빼거나 **Uninstall**할 수 있습니다.
> 승인: 조직 Settings → Third-party Access 아래 GitHub Apps → Pending installation requests.

## 6. Vercel

1. **배포 보호 확인** — Vercel 프로젝트 → **Settings** → **Deployment Protection**에서 지금 값을 확인받는다. 미리보기에 Vercel 로그인이 걸려 있으면 테스터는 실서비스 주소로 들어온다.
2. **환경변수 — 여섯 개 전부, Production·Preview 둘 다.**

> Vercel → 프로젝트 → **Settings** → **Environments** → **Production** 줄 → **Add** → 이름·값 → **Type** 고르기 → **Environments** 드롭다운에서 **Production·Preview** 둘 다 체크 → 저장. 넣은 뒤 다시 배포해야 적용됩니다.

| 이름 | 값 | Type |
|---|---|---|
| `QA_FEEDBACK` | `on` | Config |
| `GITHUB_QA_REPO` | 코드 저장소 `owner/repo` | Config |
| `GITHUB_QA_SHOTS_REPO` | 캡처 저장소 `owner/repo` | Config |
| `GITHUB_QA_LABEL` | (`qa`가 아닐 때만) | Config |
| `GITHUB_QA_ISSUE_TOKEN` | 이슈용 토큰 | **Secret** |
| `GITHUB_QA_SHOTS_TOKEN` | 캡처용 토큰 | **Secret** |

- 비밀 아닌 넷은 묻고 AI가 `vercel env add <이름> production` / `preview`로 넣어도 된다(실패 2회면 사람 몫). CLI로 넣으면 다시 볼 수 없는 값(Sensitive)으로 저장된다(이벤트 알리미 실측).
- 토큰은 사람이 화면에서, 또는 **사람의 터미널에서** `npx vercel env add GITHUB_QA_ISSUE_TOKEN production`(값 묻는 칸에 붙여 넣기 — 대화창 아님), `preview`로 한 번 더.
- 토큰이 승인 대기면 승인 뒤 넣는다. 그동안 배포돼도 이슈 대신 서버 로그(「이슈를 만들 뻔했어요」)만 남는다.
- 옛 길 「Settings → Environment Variables」는 낡았다.
- [AI] 확인: `vercel env ls`로 **이름만**.

## 7. 나머지 — 메일·보관·처리방침·테스터

1. **메일 알림** — 야간 PR의 리뷰 요청 메일이 알림이다.
   > GitHub → **Settings** → **Notifications** → **Default notifications email** 확인, **Participating, @mentions and custom**의 **Email** 체크.
2. **비밀 보관처** — 토큰 두 개 사본과 만료일을 비밀번호 관리자 등에 둔다(Vercel Secret은 다시 못 본다). 로컬 `.env.local`엔 넣지 않는다(시험으로 누른 게 진짜 이슈가 되지 않게).
3. **처리방침** — QA 4줄(`code/wiring.md` 8절) + 「AI 제공사(Anthropic, 미국)가 앱 문제 신고를 읽어 고치는 데 씀」 한 줄이 필요한지 사람이 정한다. 법적 판단은 하지 않는다. 처리방침이 없으면 문서 「남은 일」에 적는다.
4. **(anon) 테스터 안내 견본** — 링크를 보낼 때 함께:
   > - 이 주소는 테스트용입니다. 다른 곳에 올리지 말아 주세요.
   > - 이상한 점이 있으면 화면의 빈 곳(글자·버튼·그림이 없는 곳)을 빠르게 세 번 눌러 주세요.
   > - 글 앞에 이름을 써 주세요(예: `민수: 버튼이 안 눌려요`).
   > - 보내면 화면 사진과 기기 정보가 함께 갑니다. 남에게 보이면 안 되는 것이 화면에 있으면 보내지 말아 주세요.
   > - 연달아 보내면 「조금 뒤에 다시」가 뜰 수 있습니다(30초에 한 번).

## 8. 실패할 때

**화면 문구보다 서버 로그 먼저** — 실패도 30초 한도에 세서, 다시 누르면 「조금 뒤에」만 떠 원인이 가려진다. [AI] Vercel 함수 로그에서 `[qa-feedback]` 줄을 본다(`vercel logs <배포 주소>` 또는 대시보드 **Logs**).

| 로그·증상 | 뜻 | 할 일 |
|---|---|---|
| `이슈를 만들 뻔했어요` + `missing` | 환경변수가 빠졌거나 넣고 재배포 안 함 | 6절 이름 확인 → 재배포 |
| `GitHub 설정이 잘못됐어요` | 저장소 이름이 `owner/repo` 모양이 아님 | 값 확인 |
| `issue: 404`(또는 캡처 `status: 404`) | **먼저 토큰 Pending** → 그다음 Repository access·Resource owner | 4.1 승인 확인. 재시도 금지 |
| `issue: 401` | 토큰이 틀림·만료·폐기 | 재발급 → 6절 |
| `issue: 403`·`429` | 권한 부족 또는 GitHub 한도 | 권한 확인, 한도면 기다림(재시도 금지) |
| `label: "included"` 또는 `200` | 성공(200은 라벨 붙이기를 한 번 더 불러 붙임) | 없음 |
| `label`이 그 밖의 숫자 | 이슈는 생김, 라벨만 실패 | 라벨 확인(3절) |
| `shot.state: "upload-failed"` | 캡처 저장만 실패 | 캡처용 토큰·캡처 저장소 기본 브랜치 |
| 로그 없음 + 화면 403 | 같은 출처 검사(anon은 Origin 머리글 필수) | 어느 브라우저·주소였는지 묻는다 |
| 창이 안 뜸 | `QA_FEEDBACK`이 빌드에 안 들어감(재배포 안 함, 또는 Config 타입) | 재배포 → 안 되면 Secret으로 다시 |
| 야간 루틴 403 `repo_access_denied` | Claude 앱 설치·승인 전 | 반복 말고 5절 → 승인 뒤 한 번만 |
