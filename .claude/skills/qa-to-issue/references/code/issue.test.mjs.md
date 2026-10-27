# issue.test.mjs — 이슈 본문 단위 시험 (`npm run test:qa`)

- 놓을 곳: `src/lib/qa-feedback/issue.test.mjs` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/issue.test.mjs`
- 참고 구현에서 바꾼 점: 두 방식 본문 사례 추가(anon: 계정·팀 줄 없음, userId null) · 팀 개념 없음 사례 추가
- 어댑터: 없음 — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 안전 처리 시험 전부. 시간대 어댑터(tz-lang)를 바꿨으면 마지막 시험의 기대 날짜·시각만 그 시간대로 고친다
- 의존: Node 22.18 이상(.ts를 바로 읽음), `server-only`

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```````js
// QA 피드백 이슈 본문 만들기 단위 시험 — `npm run test:qa`
// issue.ts는 server-only라 react-server 조건으로 불러온다(package.json 스크립트가 넣어 줌). Node 22.18+ 타입 지우기로 .ts를 바로 읽는다.
import assert from "node:assert/strict";
import { test } from "node:test";
import { codeBlock, formatIssueTime, inlineCode, issueBody, issueTitle, metaComment, shotPath } from "./issue.ts";

const ZWSP = "\u200b";

const TEAM = { id: "3a7e0000-0000-4000-8000-000000000001", name: "기획팀", myName: "민지" };
const authInput = {
  text: "버튼을 눌러도 안 넘어가요",
  meta: {
    path: "/today/quiz?team=3a7e0000-0000-4000-8000-000000000001",
    device: "아이폰·아이패드 홈 화면 앱",
    viewport: { width: 390, height: 844, dpr: 3, zoom: 1, scrollY: 420 },
    clientTime: "2026-10-21T23:31:02.000Z",
    buildId: "dpl_abc",
    shotFailed: false,
  },
  userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X)",
  serverTime: "2026-10-22 08:31:05",
  host: "my-app.vercel.app",
  reporter: { mode: "auth", userId: "9f1c0000-0000-4000-8000-000000000002", team: TEAM },
  deploy: { env: "preview", sha: "3c928a3aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", ref: "feat/qa-feedback", deploymentId: "dpl_abc", clientStale: false },
};
const anonInput = { ...authInput, text: "민수: 버튼을 눌러도 안 넘어가요", reporter: { mode: "anon" } };
const uploaded = {
  kind: "uploaded",
  imageUrl: "https://github.com/my-org/my-app-qa-shots/blob/main/2026/10/22/0b6d0000-0000-4000-8000-000000000003.jpg?raw=true",
  path: "2026/10/22/0b6d0000-0000-4000-8000-000000000003.jpg",
  bytes: 10240,
};
const REPO = "my-org/my-app";

/** 본문에서 코드 블록·인라인 코드·HTML 주석을 뺀 「그려지는 글」 */
function renderedProse(body) {
  return body
    .replace(/(`{3,})text\n[\s\S]*?\n\1/g, "")
    .replace(/`[^`\n]*`/g, "")
    .replace(/<!--[\s\S]*?-->/g, "");
}

function machineMeta(body) {
  return JSON.parse(/<!-- qa-meta (.*) -->/.exec(body)[1]);
}

test("제목: [QA] + 앞 40자, 넘으면 …", () => {
  assert.equal(issueTitle("버튼을 눌러도 안 넘어가요"), "[QA] 버튼을 눌러도 안 넘어가요");
  const long = "가".repeat(50);
  assert.equal(issueTitle(long), `[QA] ${"가".repeat(40)}…`);
  assert.equal(issueTitle("가".repeat(40)), `[QA] ${"가".repeat(40)}`);
});

test("제목: 멘션·이슈 번호를 끊는다", () => {
  const title = issueTitle("@someone #12 봐 주세요");
  assert.equal(title, `[QA] @${ZWSP}someone #${ZWSP}12 봐 주세요`);
  assert.doesNotMatch(title, /@[A-Za-z0-9]/);
  assert.doesNotMatch(title, /#\d/);
});

test("제목: 줄바꿈·제어 문자를 지운다", () => {
  assert.equal(issueTitle("첫 줄\n둘째 줄\t끝"), "[QA] 첫 줄 둘째 줄 끝");
});

test("코드 블록: 글 속 백틱보다 울타리가 길다", () => {
  assert.equal(codeBlock("그냥 글"), "```text\n그냥 글\n```");
  const block = codeBlock("이거 ``` 닫고 ![x](https://evil.example/a.png) ````` 끝");
  assert.ok(block.startsWith("``````text\n"), block);
  assert.ok(block.endsWith("\n``````"), block);
});

test("인라인 코드: 백틱·파이프·줄바꿈을 지우고 감싼다, 비면 —", () => {
  assert.equal(inlineCode("a`b|c\nd"), "`abc d`");
  assert.equal(inlineCode("``"), "—");
  assert.equal(inlineCode(""), "—");
});

test("기계용 묶음: --> 가 끼어도 주석이 일찍 끝나지 않는다", () => {
  const comment = metaComment({ path: "/x?a=--><img src=x>" });
  assert.equal(comment.match(/-->/g).length, 1);
  assert.ok(comment.endsWith(" -->"));
  assert.doesNotMatch(comment.slice(4, -3), /[<>]/);
  const json = comment.slice("<!-- qa-meta ".length, -" -->".length);
  assert.equal(JSON.parse(json).path, "/x?a=--><img src=x>");
});

test("본문(로그인 방식): 모양", () => {
  const body = issueBody(authInput, uploaded, REPO);
  assert.ok(body.startsWith("### 남긴 말\n```text\n버튼을 눌러도 안 넘어가요\n```\n"));
  assert.ok(body.includes(`![화면 캡처](${uploaded.imageUrl})`));
  assert.ok(body.includes("| 화면 | `my-app.vercel.app/today/quiz?team=3a7e0000-0000-4000-8000-000000000001` |"));
  assert.ok(body.includes("| 화면 크기 | 390×844 · 배율 3 · 확대 1 · 스크롤 420 |"));
  assert.ok(body.includes("| 계정 | `9f1c0000-0000-4000-8000-000000000002` (팀에서 부르는 이름: `민지`) |"));
  assert.ok(body.includes("| 팀 | `기획팀` (`3a7e0000-0000-4000-8000-000000000001`) |"));
  assert.ok(body.includes("2026-10-22 08:31:02"), "휴대폰 시각은 이슈 시간대로");
  assert.ok(body.includes(`[3c928a3](https://github.com/${REPO}/commit/${authInput.deploy.sha})`));
  assert.ok(body.includes("화면 버전 같음"));
  const meta = machineMeta(body);
  assert.equal(meta.v, 1);
  assert.equal(meta.mode, "auth");
  assert.equal(meta.shot, "uploaded");
  assert.equal(meta.shotPath, uploaded.path);
  assert.equal(meta.userId, authInput.reporter.userId);
  assert.equal(meta.teamId, TEAM.id);
});

test("본문(로그인 없는 방식): 계정·팀 줄 없이 「보낸 사람」 한 줄, 기계용 묶음 userId는 null", () => {
  const body = issueBody(anonInput, uploaded, REPO);
  assert.ok(body.includes("| 보낸 사람 | 로그인 없는 방식 — 이름은 남긴 말 앞부분을 보세요 |"));
  assert.doesNotMatch(body, /\| 계정 \|/);
  assert.doesNotMatch(body, /\| 팀 \|/);
  assert.ok(body.includes("| 기기 | `아이폰·아이패드 홈 화면 앱` · "));
  const meta = machineMeta(body);
  assert.equal(meta.mode, "anon");
  assert.equal(meta.userId, null);
  assert.equal(meta.teamId, null);
  for (const line of body.split("\n").filter((l) => l.startsWith("| ") && !l.startsWith("| 항목"))) {
    assert.equal(line.split("|").length, 4, `표 칸이 깨지지 않아야 함: ${line}`);
  }
});

test("본문: 사용자 글의 멘션·이슈 번호·그림·링크·HTML·주석이 그려지는 글로 새지 않는다", () => {
  const nasty = "@someone #12 ![t](https://evil.example/t.png) [링크](https://evil.example) <img src=x> <details> --> ``` 끝";
  for (const input of [authInput, anonInput]) {
    const body = issueBody({ ...input, text: nasty }, uploaded, REPO);
    const prose = renderedProse(body);
    assert.doesNotMatch(prose, /@someone/);
    assert.doesNotMatch(prose, /#12/);
    assert.doesNotMatch(prose, /evil\.example/);
    assert.doesNotMatch(prose, /<img|<details/);
    const outsideBlock = body.replace(/(`{3,})text\n[\s\S]*?\n\1/g, "");
    assert.equal(outsideBlock.match(/-->/g).length, 1, "코드 블록 밖의 주석 끝은 맨 끝 하나뿐");
    assert.ok(body.includes(`\`\`\`\`text\n${nasty}\n\`\`\`\``), "백틱 3개가 든 글은 4개 울타리");
  }
});

test("본문: 주소·UA·팀 이름·브랜치에 끼운 마크다운도 코드 칸에 갇힌다", () => {
  const input = {
    ...authInput,
    meta: { ...authInput.meta, path: "/today?x=`|![a](https://evil.example/p.png)", device: "@someone" },
    userAgent: "UA `| @mention #3 <script>",
    reporter: { mode: "auth", userId: authInput.reporter.userId, team: { id: TEAM.id, name: "@팀 #9 `x`", myName: "![n](https://evil.example/n.png)" } },
    deploy: { ...authInput.deploy, ref: "feat/@who#1", sha: "not-a-sha)](https://evil.example)" },
  };
  const body = issueBody(input, uploaded, REPO);
  const prose = renderedProse(body);
  assert.doesNotMatch(prose, /evil\.example/);
  assert.doesNotMatch(prose, /@someone|@mention|@팀|@who/);
  assert.doesNotMatch(prose, /#3|#9|#1/);
  assert.doesNotMatch(prose, /<script/);
  for (const line of body.split("\n").filter((l) => l.startsWith("| ") && !l.startsWith("| 항목"))) {
    assert.equal(line.split("|").length, 4, `표 칸이 깨지지 않아야 함: ${line}`);
  }
});

test("본문: 캡처 상태별 문구 — 캡처가 실패해도 이슈 본문은 만든다", () => {
  assert.ok(issueBody(authInput, { kind: "upload-failed", bytes: 1 }, REPO).includes("> 캡처 실패 — 캡처 저장소에 올리지 못했어요"));
  assert.ok(issueBody(authInput, { kind: "capture-failed" }, REPO).includes("> 캡처 실패 — 화면에서 찍지 못했어요"));
  assert.ok(issueBody(authInput, { kind: "dropped" }, REPO).includes("> 캡처 실패 — 형식·크기가 맞지 않아 버렸어요"));
  assert.ok(issueBody(anonInput, { kind: "none" }, REPO).includes("> 캡처 없음"));
  const bad = issueBody(authInput, { ...uploaded, imageUrl: "https://evil.example/x.jpg" }, REPO);
  assert.doesNotMatch(bad, /evil\.example/);
  assert.ok(bad.includes("> 캡처 실패"));
});

test("본문: 팀 못 찾음은 「—」, 팀 개념 없음은 줄 생략, 옛 배포 표시", () => {
  const notFound = issueBody({ ...authInput, reporter: { mode: "auth", userId: "u1", team: null } }, { kind: "none" }, REPO);
  assert.ok(notFound.includes("| 팀 | — |"));
  const noTeams = issueBody({ ...authInput, reporter: { mode: "auth", userId: "u1" } }, { kind: "none" }, REPO);
  assert.doesNotMatch(noTeams, /\| 팀 \|/);
  assert.ok(noTeams.includes("| 계정 | `u1` |"));
  const stale = issueBody({ ...authInput, deploy: { ...authInput.deploy, clientStale: true } }, { kind: "none" }, REPO);
  assert.ok(stale.includes("**화면이 옛 배포** (화면 `dpl_abc`)"));
});

test("캡처 경로: 이슈 시간대 날짜 폴더 + id.jpg", () => {
  // 기본 시간대(서울) 기준: 2026-10-21 23:30 UTC = 2026-10-22 08:30 KST — 시간대를 바꿨으면 기대값도 바꾼다
  assert.equal(shotPath(new Date("2026-10-21T23:30:00Z"), "abc"), "2026/10/22/abc.jpg");
  assert.equal(formatIssueTime(new Date("2026-10-21T23:31:05Z")), "2026-10-22 08:31:05");
});
```````
