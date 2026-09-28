---
name: github-connect
description: 이 컴퓨터에서 이 프로젝트가 GitHub에 올라갈 수 있는 상태를 만든다 — git·gh 설치 확인, GitHub 계정, gh 인증 토큰(.env.cli), 계정 검문, HTTPS push 통로, 원격 저장소 생성, 첫 push까지 순서대로. 이미 된 단계는 건너뛰어 언제 다시 돌려도 안전하고, 사람 몫이 나오면 그 한 단계만 화면·버튼 이름 그대로 안내하고 멈췄다가 "됐어"에 이어간다. project-init 신규 적용 끝에서 자동으로 불린다. 트리거 예 "깃헙 연결해줘", "깃헙에 올려줘", "/github-connect".
---

# github-connect — 이 프로젝트를 GitHub에 잇기

목표는 하나다: **이 컴퓨터에서 이 프로젝트가 GitHub에 올라갈 수 있는 상태.** 끝나면 `new-task`(`git pull origin main`)와 `ship-task`(push·PR)가 바로 돈다.

메인 세션에서 돈다(fork 아님) — 중간에 사람 몫이 끼어 있어 사용자와 말을 주고받아야 해서다.

## 공통 규칙

- **역할 표시** — 각 단계에 **[AI]**(터미널 명령), **[Aside]**(브라우저 에이전트가 화면에서 하는 일), **[사람]**(가입·로그인·2FA·권한 창 클릭처럼 사람만 되는 일)을 붙였다. 뜻은 idea-to-mvp `6-0-backend-prep.md` §3과 같다.
- **재실행 안전** — 단계마다 먼저 「이미 됐나」를 확인하고, 됐으면 건너뛴다. 그래서 언제 다시 불러도 된다. 마무리 보고에 한 일과 건너뛴 일을 나눠 적는다.
- **사람 몫은 한 번에 한 단계** — 그 단계만 화면 이름·버튼 이름 그대로 안내하고 멈춘다. 사용자가 "됐어"라고 하면 그 단계를 [AI]가 다시 확인한 뒤 다음으로 간다. 여러 단계를 한꺼번에 떠넘기지 않는다.
- **비밀값은 대화에 남기지 않는다** — 토큰 값을 화면에 출력하지 않고, 셸 안에서 바로 파일로 보낸다. 사용자에게는 "채팅창에 붙여넣지 마 — 대화 기록에 남아"라고 분명히 말한다.
- **실패 한도** — `docs/account-check.md` 원칙 ⑥을 따른다. 로그인·가입·2FA·인증 코드는 1회 실패면 멈추고 사람에게. 토큰 발급은 2회. 401·403·404는 재시도하지 않고 원인을 바꾼다.
- **전역 설정은 건드리지 않는다** — `git config --global`, `gh auth switch`를 쓰지 않는다. 같은 컴퓨터에 소유가 다른 프로젝트가 있을 수 있다(`docs/account-check.md` 원칙 ②).
- **윈도우** — 클로드 코드 윈도우판은 명령을 Git Bash에서 돌린다. 아래 명령(`sed`·`env`·`export` 포함)과 하네스 훅도 Git Bash에서 돌 것으로 보이지만 실측은 아직 없다 — 막히면 그 자리에서 멈추고 보고한다.

### 토큰 로더 — 두 가지 형태

토큰은 프로젝트 루트의 깃 미추적 파일 `.env.cli`에 `GH_TOKEN=...` 한 줄로 둔다. 부를 때마다 같은 셸 호출 안에서 읽어 넘긴다(환경변수는 다음 Bash 호출로 안 넘어간다).

```bash
# gh 명령
env GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)" gh <명령>

# 원격과 통신하는 git 명령 (push·pull·fetch·ls-remote)
export GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)"; git <명령>
```

*git에 `env` 형태를 쓰지 않는 이유*: `no-main-push` 훅은 명령 조각마다 첫 낱말이 `git`일 때만 검사한다. `env GH_TOKEN=... git push ...`로 쓰면 첫 낱말이 `env`라 훅이 push를 아예 못 보고 지나간다. `export ...; git push ...`는 `;`에서 조각이 나뉘어 훅이 `git push`를 그대로 검사한다. 괄호로 감싸지도 않는다(`(... git push origin main)`은 마지막 낱말이 `main)`이 되어 검사를 빠져나간다).

## 진행 순서

| 단계 | 이미 됐나 (확인) | 안 됐으면 | 역할 |
|---|---|---|---|
| ① git | `git --version` 성공 | 설치 | [AI]·[사람] |
| ② gh | `gh --version` 성공 | 설치 | [AI]·[사람] |
| ③ GitHub 계정 | ④가 이미 됐거나, 사용자가 "있어" | 가입 안내 | [사람] (Aside는 화면만 열어 줌) |
| ④ 토큰 | `.env.cli` 토큰으로 `gh api user` 성공 | 1순위 gh 로그인 → 2순위 Aside 발급 → 3순위 사람이 붙여넣기 | [AI]·[Aside]·[사람] |
| ⑤ 계정 검문 | (매번 한다) | — | [AI] |
| ⑥ push 통로 | 로컬 도우미 설정이 아래와 같음 | 로컬 git 설정 | [AI] |
| ⑦ 원격 저장소 | `git remote get-url origin` 성공 | `gh repo create` | [AI] |
| ⑧ 첫 push | 원격 main = 로컬 main | `git push -u origin main` | [AI] |

시작 전에 프로젝트 루트가 git 저장소인지 본다(`git rev-parse --show-toplevel`). 아니면 멈추고 하네스 적용(`project-init`)부터 하자고 안내한다 — 저장소를 만드는 `git init -b main`은 project-init 몫이다.

### ① git 확인·설치

[AI] `git --version`. 되면 건너뛴다.

없으면 "git(코드 변경 이력을 저장하는 도구)을 설치해도 될까?" 한 번 묻고, 허락받으면:

- **맥** — [AI] `xcode-select --install` → [사람] 뜨는 창에서 「설치」를 누르고 사용권 계약에 「동의」. 끝나면 "됐어"라고 말해 달라고 한다. 맥은 `git --version`만 쳐도 이 창이 먼저 뜰 수 있다 — 그 창이면 그대로 설치하면 된다.
- **윈도우** — [AI] `winget install --id Git.Git -e` → [사람] "이 앱이 디바이스를 변경하도록 허용하시겠어요?" 창에서 「예」. 클로드 코드 윈도우판은 Git for Windows(Git Bash)가 있어야 돌아서 보통 이미 깔려 있다(최신 확인 — 쓴 시점 기준).

설치 뒤 `git --version`으로 다시 확인한다. 윈도우에서 새로 깔았는데 인식이 안 되면 앱을 껐다 켜 달라고 한다(명령 경로가 새 창에서만 잡힌다).

### ② gh 확인·설치

gh는 GitHub을 터미널에서 다루는 공식 도구(GitHub CLI)다. [AI] `gh --version`. 되면 건너뛴다.

없으면 "gh를 설치해도 될까?" 묻고, 허락받으면:

- **맥, brew 있음** (`brew --version` 성공) — [AI] `brew install gh`
- **맥, brew 없음** — brew를 새로 들이지 않는다. [사람] `https://cli.github.com` 에서 「Download for Mac」 → 받은 `.pkg` 파일을 열어 「계속」 → 「설치」 → 맥 로그인 비밀번호 입력. 끝나면 "됐어".
- **윈도우** — [AI] `winget install --id GitHub.cli -e` → [사람] 권한 창에서 「예」. 인식이 안 되면 앱을 껐다 켠다.

설치 뒤 `gh --version`으로 다시 확인한다.

### ③ GitHub 계정

④가 이미 돼 있으면(토큰이 살아 있으면) 건너뛴다. 아니면 묻는다 — "GitHub 계정 있어?" 프로젝트 `AGENTS.md` 「소유와 계정」 표의 GitHub 행에 값이 있으면 "표에는 <계정>으로 적혀 있는데, 이 계정으로 할 거지?"로 묻는다.

없으면 가입은 **항상 [사람]**이다. 자동 가입은 하지 않는다 — 가입 자동화는 계정 제재로 이어진다(`docs/account-check.md` 원칙 ⑥).

- **Aside가 있으면** (`command -v aside` 성공) — [Aside]가 표의 「브라우저 작업 프로필」로 `https://github.com/signup` 화면만 열어 준다. [사람] 이메일 → 비밀번호 → 사용자 이름(username) → 사람 확인 퍼즐 → 메일로 온 코드 입력까지 직접 채운다.
- **Aside가 없으면** — 주소(`https://github.com/signup`)를 주고 사용자가 자기 브라우저에서 한다.

가입·로그인이 한 번 실패하면 다시 시도하지 않고 멈춰서 무엇이 떴는지 사용자에게 묻는다. 끝나면 사용자 이름을 받아 둔다(⑤에서 표와 대조).

### ④ 토큰 — `.env.cli`의 `GH_TOKEN`

**확인** — `.env.cli`에 `GH_TOKEN=` 줄이 있고 아래 명령이 계정 이름을 답하면 건너뛴다. 401(토큰 죽음)이면 같은 토큰으로 다시 부르지 않고 새로 받는다.

```bash
env GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)" gh api user --jq .login
```

**먼저 할 것** — `.env.cli`가 커밋되지 않게 한다: `git check-ignore -q .env.cli`가 실패하면 `.gitignore`에 `.env.cli` 한 줄을 넣는다.

**토큰에 필요한 권한(스코프 — 토큰이 할 수 있는 일의 범위)** — `repo`·`workflow`·`read:org`. 근거는 `docs/account-check.md` gh 항목(실측 2026-09-29): gh 로그인의 기본 스코프는 `repo`·`read:org`·`gist`뿐이고, 하네스가 올리는 `.github/workflows/ci.yml`을 push하려면 `workflow`가 따로 있어야 한다.

아래 셋을 순서대로 시도한다. 앞 길이 막히면 다음 길로 간다.

#### 1순위 [AI] gh 로그인으로 토큰 꺼내기

1. [AI] 로그인 전에 이 컴퓨터에 저장된 gh 계정 목록을 적어 둔다 — 7번에서 로그아웃할지 가르는 값이다.
   ```bash
   env -u GH_TOKEN gh auth status 2>&1
   ```
2. [AI] 로그인 명령을 **백그라운드로** 띄운다(Bash `run_in_background`) — 사람이 승인할 때까지 기다리는 명령이라 앞에서 돌리면 코드를 못 보여준다.
   ```bash
   env -u GH_TOKEN gh auth login --web --git-protocol https --skip-ssh-key --scopes workflow
   ```
   클로드 코드의 셸은 대화형이 아니라서 gh가 "Git 자격 증명을 설정할까?"를 묻지 않고 넘어간다 — 전역 git 설정을 안 건드리는 대신 `workflow` 스코프도 자동으로 안 붙으니 `--scopes workflow`를 꼭 단다(gh 소스 실측 2026-09-29).
3. [AI] 출력에서 일회용 코드(`XXXX-XXXX`)와 주소(`https://github.com/login/device`)를 읽어 사용자에게 보여준다.
4. [사람] 안내 (Aside가 있으면 [Aside]가 표의 프로필로 주소를 열어 준다):
   - 주소를 연다 → GitHub 로그인 화면이 나오면 로그인(비밀번호·2FA는 사람 몫).
   - 「Device Activation」 화면에서 로그인된 계정 이름이 표의 계정인지 본다 → 코드 8자리 입력 → 「Continue」.
   - 권한 승인 화면에서 「Authorize github」 (버튼 이름은 최신 확인).
   - 끝나면 "됐어".
5. [AI] 백그라운드 명령이 `Logged in as <계정>`으로 끝났는지 본다. 코드 입력·승인이 한 번 실패했으면 다시 띄우지 않고 멈춰 사람에게 묻는다.
6. [AI] 토큰을 **화면에 찍지 않고** `.env.cli`로 바로 보낸다. 다른 줄(다른 서비스 토큰)은 그대로 둔다.
   ```bash
   login=<5번의 계정>
   { grep -v '^GH_TOKEN=' .env.cli 2>/dev/null; printf 'GH_TOKEN=%s\n' "$(env -u GH_TOKEN gh auth token --hostname github.com --user "$login")"; } > .env.cli.tmp && mv .env.cli.tmp .env.cli && chmod 600 .env.cli
   env GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)" gh api user --jq .login   # "$login"과 같아야 한다
   ```
7. [AI] **1번 목록에 이 계정이 없었으면** 저장된 로그인 세션을 지운다.
   ```bash
   env -u GH_TOKEN gh auth logout --hostname github.com --user "$login"
   ```
   로그아웃은 이 컴퓨터의 저장본만 지우고 토큰을 폐기하지 않는다(`gh auth logout --help` 실측) — `.env.cli`의 사본은 그대로 살아 있다. 세션을 남겨 두면 전역 활성 계정이 이 계정으로 바뀐 채라, 토큰 없는 다른 프로젝트가 조용히 이 계정으로 돈다. **1번 목록에 이미 있던 계정이면 지우지 않는다** — 사용자가 원래 쓰던 세션이다. 이때 로그인 전 활성 계정이 다른 계정이었으면 "전역 활성 계정이 <계정>으로 바뀌었어"를 마무리 보고에 남긴다.

**2순위로 넘어가는 경우** — 브라우저 승인이 안 되거나, 회사 조직 정책이 GitHub CLI 앱을 막아 조직 저장소가 403으로 안 보일 때.

#### 2순위 [Aside] 화면에서 개인 접근 토큰 발급

Aside가 없으면 "브라우저 에이전트(Aside)를 설치해도 될까?" 묻고, 허락받으면 맥·리눅스는 `curl -fsSL https://releases.aside.com/install.sh | bash`로 설치한 뒤 `aside guide`를 읽고 쓴다. **윈도우는 설치 방법이 확인되지 않았다** — 윈도우에서 Aside가 없으면 3순위로 간다.

1. [Aside] 표의 「브라우저 작업 프로필」로 github.com을 열고, 화면에 로그인된 계정을 표와 대조한다(`docs/account-check.md` 원칙 ④). 로그인·2FA가 필요하면 [사람].
2. [Aside] Settings → Developer settings → Personal access tokens → Tokens (classic) → 「Generate new token (classic)」 (바로 가는 주소 `https://github.com/settings/tokens/new`).
   - Note(이름): **용도·기기로 짓는다** — 예 `gh-cli-<기기 이름>`. 프로젝트 이름을 붙이지 않는다 — 소유 계정당 하나를 여러 프로젝트가 나눠 쓰는 토큰이라, 프로젝트가 끝났을 때 남이 쓰는 토큰을 지우게 된다(`6-0-backend-prep.md` §3).
   - Expiration(만료): 사용자에게 묻는다. 만료를 두면 날짜를 마무리 보고에 적는다 — 6단계 준비에서 비밀값 장부로 옮긴다.
   - Select scopes: `repo`, `workflow`, `read:org`. 고른 표시가 화면에 다 뜬 것을 확인한 뒤 만든다.
   - classic으로 만든다 — gh 도움말이 세분화 토큰(fine-grained)은 자원 범위 때문에 헷갈리는 동작을 낼 수 있다고 적고 있다.
3. 비밀값 절차 넷(`6-0-backend-prep.md` §3): 화면에서 읽어 **세션 폴더의 임시 파일로만** 저장(대화에 값 출력 금지 — 읽는 방법은 `docs/account-check.md` Aside 함정) → 그 값으로 `gh api user`를 한 번 불러 유효한지 확인 → `.env.cli`의 `GH_TOKEN=` 줄로 설치(1순위 6번과 같은 방식, 다른 줄 보존) → 임시 파일 삭제.
4. **값을 못 읽었으면 그 토큰을 살려 두지 않는다** — 같은 화면에서 즉시 「Delete」로 폐기한 뒤 다시 발급한다(원칙 ⑤). 발급이 2번 실패하면 멈추고 보고한다.

#### 3순위 [사람] 직접 발급해 파일에 붙여넣기

1. [AI] `.env.cli`에 빈 `GH_TOKEN=` 줄을 준비한다(다른 줄은 그대로).
   ```bash
   { grep -v '^GH_TOKEN=' .env.cli 2>/dev/null; echo 'GH_TOKEN='; } > .env.cli.tmp && mv .env.cli.tmp .env.cli && chmod 600 .env.cli
   ```
2. [사람] 순서대로 안내한다 (한 번에 한 화면씩):
   1. 브라우저에서 `https://github.com/settings/tokens/new` 를 연다(로그인 화면이 나오면 로그인).
   2. 「Note」 칸에 `gh-cli-<기기 이름>`.
   3. 「Expiration」에서 기간을 고른다.
   4. 「Select scopes」에서 `repo`, `workflow`, `read:org` 세 칸을 체크.
   5. 맨 아래 「Generate token」.
   6. 초록 상자에 뜬 `ghp_`로 시작하는 값을 복사 — 이 화면을 벗어나면 다시 안 보여준다.
3. [AI] 편집기로 파일을 열어 준다 — 맥 `open -e .env.cli`, 윈도우 `notepad .env.cli`.
4. [사람] `GH_TOKEN=` 바로 뒤에 붙여넣고 저장 → "됐어". **채팅창에는 붙여넣지 마 — 대화 기록에 남아.**
5. [AI] 확인 명령으로 검증한다. 실패하면 앞뒤 공백·따옴표가 끼지 않았는지 한 번만 봐 달라고 하고, 그래도 안 되면 그 토큰을 지우고 다시 발급하게 한다.

### ⑤ 계정 검문

[AI] 토큰이 답하는 계정을 프로젝트 `AGENTS.md` 「소유와 계정」 표의 GitHub 행과 대조한다.

```bash
env GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)" gh api user --jq .login
```

- **같다** → 다음으로.
- **표가 비어 있거나 `(확인 필요)`** → "GitHub 계정을 <계정>으로 표에 적을게, 맞지?"로 확인받은 뒤 채운다. 이메일은 사용자에게 받는다.
- **다르다** → 멈추고 사용자에게 알린다. 저장소를 만들지 않는다(원칙 ①). 토큰이 다른 계정 것이면 ④로 표의 계정 토큰을 새로 받고, 표가 틀렸으면 사용자가 표를 고친다.

### ⑥ push 통로 — HTTPS + 토큰

SSH 대신 HTTPS + 토큰으로 통일한다. 설정은 **이 저장소의 로컬 git 설정에만** 한다.

**확인** — 아래 출력이 정확히 두 줄(빈 줄, `!gh auth git-credential`)이면 건너뛴다.

```bash
git config --local --get-all credential.helper
```

**설정**:

```bash
git config --local --unset-all credential.helper 2>/dev/null
git config --local credential.helper ''
git config --local --add credential.helper '!gh auth git-credential'
```

- 빈 값 줄은 「위에서 물려받은 도우미 목록을 여기서 비운다」는 표시다 — 전역에 걸린 맥 키체인·윈도우 자격 증명 관리자가 저장해 둔 다른 계정 비밀번호를 먼저 내밀지 못하게 한다.
- gh 도우미는 환경변수 `GH_TOKEN`을 읽는다(실측 2026-09-29) — 그래서 push는 늘 위 「토큰 로더」의 git 형태로 부른다.
- **원격 주소가 ssh 형식**(`git@github.com:`·`ssh://`)인 옛 프로젝트면, https로 바꿀지 사용자에게 한 번 묻는다. 바꾸면 `git remote set-url origin https://github.com/<주인>/<저장소>.git`. 안 바꾸면 SSH 검문(`docs/account-check.md` 「GitHub SSH 키」)을 그대로 따른다.

### ⑦ 원격 저장소

**확인** — `git remote get-url origin`이 성공하면 만들지 않는다. 주소가 표 소유자의 저장소를 가리키는지만 보고, 다르면 멈춘다.

없으면:

1. 저장소 이름은 폴더 이름이 기본(`basename "$(git rev-parse --show-toplevel)"`), 주인은 표의 GitHub 계정(회사 조직이 주인이면 그 조직), **비공개가 기본**이다 — 공개는 사용자가 공개로 하자고 말했을 때만.
2. "GitHub에 `<주인>/<이름>` 비공개 저장소를 만들게" 하고 한 번 보여준다. 이름을 바꾸자고 하면 따른다.
3. [AI] 만들기 직전에 ⑤ 대조를 같은 걸음에서 한 번 더 하고 만든다.
   ```bash
   env GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)" gh repo create <주인>/<이름> --private --source=. --remote=origin
   git remote get-url origin   # https://github.com/... 이어야 한다
   ```
   주소가 ssh 형식으로 붙었으면(gh 전역 설정의 영향) `git remote set-url origin https://github.com/<주인>/<이름>.git`로 바꾼다.
4. 같은 이름 저장소가 이미 있다고 실패하면 다시 시도하지 않는다 — 그 저장소에 이을지, 다른 이름으로 만들지 사용자에게 묻는다.
5. `--push`는 붙이지 않는다 — push는 ⑧에서 훅이 보는 형태로 한다.

### ⑧ 첫 push

**확인** — 올릴 게 없거나 이미 올라가 있으면 건너뛴다.

```bash
git rev-parse --verify -q main                    # 비면 로컬 main에 커밋이 없다 → 건너뜀
export GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)"; git ls-remote --heads origin main   # 원격 main의 sha
```

원격 main sha가 로컬 main과 같으면 건너뛴다.

**이 push는 하네스 첫 적용의 부트스트랩 예외다** — "main에 직접 push하지 않는다"의 유일한 예외로, 프로젝트 `AGENTS.md` 브랜치 절에 적혀 있다. 예외가 되는 건 **원격 main이 없거나, GitHub에서 저장소를 만들 때 생긴 첫 커밋(README·.gitignore·LICENSE)뿐일 때**만이다. 원격 main에 이미 이 프로젝트의 작업 이력이 있으면 예외가 아니다 — 멈추고 브랜치 흐름(`/new-task` → `/done-task`)으로 안내한다.

- **원격 main 없음** →
  ```bash
  export GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)"; git push -u origin main
  ```
- **원격에 GitHub이 만든 첫 커밋이 있음** → 먼저 그 위로 올린 뒤 push한다. 충돌이 나면 `git rebase --abort`로 되돌리고 멈춰 보고한다. 강제 push(force push)는 하지 않는다.
  ```bash
  export GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)"; git pull --rebase origin main
  export GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli 2>/dev/null)"; git push -u origin main
  ```

**`no-main-push` 훅에 막히면 우회하지 않는다.** project-init 직후 같은 세션에서는 훅이 아직 안 잡혀 그대로 올라간다. 앱을 껐다 켠 뒤 따로 불렀다면 훅이 이 push를 막는다 — 다른 명령 형태(`env` 앞붙이기, `gh repo create --push` 등)로 피해 가지 말고 [사람]에게 한 줄을 맡긴다: 터미널 앱을 열어 `cd <프로젝트 경로>` 뒤 아래를 붙여넣게 한다. 토큰 값이 화면에 안 나오는 형태라 그대로 붙여넣어도 된다.

```bash
export GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env.cli)"; git push -u origin main
```

push가 `refusing to allow an OAuth App to create or update workflow` 류로 거부되면 토큰에 `workflow` 스코프가 없는 것이다 — 같은 push를 되풀이하지 말고 ④로 돌아가 스코프를 갖춘 토큰으로 바꾼다.

## 마무리 보고

사용자에게 알린다:

- **단계별 결과** — ①~⑧마다 「했음 / 이미 돼 있어 건너뜀 / 사람이 함」. 토큰은 몇 순위 길로 받았는지, 만료일이 있으면 그 날짜.
- **원격 주소** — `https://github.com/<주인>/<이름>` (비공개/공개).
- **남길 경고** — 전역 활성 계정이 바뀌었으면 그 사실, 표와 다른 점이 있었으면 그 내용.
- **project-init 신규 적용에서 불렸으면 재시작 안내를 붙인다** (project-init 마무리 안내와 합쳐 한 번만): 지금 열린 세션에는 새 스킬·훅·에이전트가 아직 안 잡힌다 — 새 파일이라서가 아니라 `.claude/` 폴더가 방금 처음 생겨 지금 세션의 감시 대상이 아니라서다. **앱을 껐다 켜야** 잡힌다 — 껐다 켜도 대화는 안 날아간다(대화를 버리는 `/clear`와는 다르다). 다시 켠 뒤부터는 작업마다 `/new-task`로 브랜치를 열고 `/done-task`로 합치는 흐름이다.

## 안 하는 것 (의도적)

- ❌ GitHub 자동 가입·로그인 반복 — 가입은 늘 사람, 로그인 실패는 1회면 멈춘다 (원칙 ⑥)
- ❌ 토큰 값을 대화·화면에 출력 — 셸 안에서 파일로만 보낸다
- ❌ 전역 설정 변경 — `git config --global`, `gh auth switch`, 전역 `gh auth setup-git`
- ❌ 공개 저장소 기본 생성 — 사용자가 말했을 때만 공개
- ❌ 강제 push, 훅 우회 — 막히면 사람에게 한 줄을 맡긴다
- ❌ 부트스트랩이 아닌 main push — 원격 main에 작업 이력이 있으면 브랜치 흐름으로
