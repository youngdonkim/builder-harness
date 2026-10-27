# issue.ts — 이슈 제목·본문 (안전 처리)

- 놓을 곳: `src/lib/qa-feedback/issue.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/issue.ts`
- 참고 구현에서 바꾼 점: 보낸 사람 칸을 방식별로(`QaReporterInfo` — auth는 계정·팀, anon은 「보낸 사람」 한 줄) · 기계용 묶음에 `mode` · 팀 개념이 없으면 「팀」 줄 생략 · 시간대를 상수로(`formatKst` → `formatIssueTime`)
- 어댑터: `tz-lang` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 제목·코드 블록·인라인 코드·주석 JSON·그림 주소 검사 — 단위 시험이 지킨다
- 의존: `server-only`

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
import "server-only";
/**
 * QA 피드백 — 이슈 제목·본문 만들기. 순수 함수만 둔다(환경변수·네트워크 없음). 단위 시험: issue.test.mjs (`npm run test:qa`).
 * 바깥에서 온 글(사용자 글·주소·UA·팀 이름·브랜치 이름)은 마크다운으로 그려지지 않게 넣는다:
 *  - 사용자 글 → 한 줄로 다듬은 뒤 코드 블록. 글에 든 가장 긴 백틱 줄보다 하나 더 긴 울타리를 써서 블록이 깨지지 않게.
 *  - 표 칸 → 인라인 코드. 백틱·`|`·`\`·줄바꿈을 지운다(칸이 깨지거나 코드가 일찍 끝나지 않게).
 *  - 제목 → 코드를 못 쓰니 `@`·`#` 뒤에 보이지 않는 띄움 문자(U+200B)를 넣어 멘션·이슈 번호 연결을 끊는다.
 *  - 기계용 묶음(HTML 주석) → JSON의 `<`·`>`를 \u003c·\u003e로 바꿔 `-->`가 끼지 못하게. 사용자 글은 넣지 않는다.
 *  - 캡처 그림 주소 → GitHub 응답에서 받은 것만, 모양을 검사한 뒤에만 그림으로 건다.
 * 보낸 사람 칸은 방식마다 다르다 — 로그인 방식(auth)은 계정·팀, 로그인 없는 방식(anon)은 「보낸 사람」 한 줄(IP는 어디에도 안 넣는다).
 * 이슈 본문은 개발자가 읽는 글이라 서비스 화면 문구 규칙과 별개다.
 */
import type { QaClientMeta } from "./shared";

export type QaDeploy = { env: string; sha: string; ref: string; deploymentId: string; clientStale: boolean };

/** 팀(워크스페이스) — 지금 팀원일 때만 서버가 읽어 온다 */
export type QaTeam = { id: string; name: string; myName: string | null };

/**
 * 보낸 사람 — reporter.ts가 정한다(화면이 보낸 값은 쓰지 않는다).
 * auth의 team: 객체 = 찾음 · null = 팀 개념은 있는데 못 찾음(「—」) · 칸 없음(undefined) = 팀 개념이 없는 프로젝트(줄 생략)
 */
export type QaReporterInfo = { mode: "anon" } | { mode: "auth"; userId: string; team?: QaTeam | null };

/** 이슈 본문에 필요한 것 — server.ts의 QaReport에서 이미지 바이트만 뺀 모양 */
export type QaIssueInput = {
  text: string;
  meta: QaClientMeta;
  userAgent: string;
  serverTime: string;
  host: string;
  reporter: QaReporterInfo;
  deploy: QaDeploy;
};

/**
 * 캡처가 어떻게 됐나 — 본문의 그림 자리에 쓴다. 캡처가 실패해도 이슈는 만든다.
 * uploaded: 캡처 저장소에 올림 · upload-failed: 받았지만 못 올림 · capture-failed: 화면에서 못 찍음
 * dropped: 형식·크기가 맞지 않아 버림 · none: 캡처 없음
 */
export type QaShotState =
  | { kind: "uploaded"; imageUrl: string; path: string; bytes: number }
  | { kind: "upload-failed"; bytes: number }
  | { kind: "capture-failed" }
  | { kind: "dropped" }
  | { kind: "none" };

// [ADAPTER:tz-lang] 이슈의 시각 기준(시간대)과 표시 이름. 기본값은 서울
const TIME_ZONE = "Asia/Seoul";
const TIME_ZONE_LABEL = "한국";
// [/ADAPTER:tz-lang]

const ZWSP = "\u200b";
const TITLE_HEAD = 40;

/** 줄바꿈·제어 문자를 띄어쓰기 하나로 */
function oneLine(value: string): string {
  return value.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]+/g, " ").replace(/\s+/g, " ").trim();
}

/** 제목 — `[QA] {글 앞 40자}`. 멘션·이슈 번호가 안 걸리게 `@`·`#` 뒤를 끊는다 */
export function issueTitle(text: string): string {
  const chars = [...oneLine(text)];
  const head = chars.length > TITLE_HEAD ? `${chars.slice(0, TITLE_HEAD).join("")}…` : chars.join("");
  return `[QA] ${head.replace(/([@#])/g, `$1${ZWSP}`) || "(빈 글)"}`;
}

/** 코드 블록 — 울타리는 글에 든 가장 긴 백틱 줄보다 하나 더 길게(최소 3) */
export function codeBlock(text: string, lang = "text"): string {
  const longest = Math.max(0, ...[...text.matchAll(/`+/g)].map((m) => m[0].length));
  const fence = "`".repeat(Math.max(3, longest + 1));
  return `${fence}${lang}\n${text}\n${fence}`;
}

/** 표 칸 인라인 코드 — 백틱·`|`·`\`·줄바꿈을 지우고 감싼다. 비면 「—」 */
export function inlineCode(value: string, max = 300): string {
  const clean = [...oneLine(value).replace(/[`|\\]/g, "")].slice(0, max).join("").trim();
  return clean ? `\`${clean}\`` : "—";
}

/** 기계용 묶음 — 사람 눈엔 안 보이는 HTML 주석. `<`·`>`를 이스케이프해 주석이 일찍 끝나지 않게 */
export function metaComment(data: Record<string, unknown>): string {
  const safe = JSON.stringify(data).replace(/</g, "\\u003c").replace(/>/g, "\\u003e");
  return `<!-- qa-meta ${safe} -->`;
}

const timeFormatter = new Intl.DateTimeFormat("sv-SE", {
  timeZone: TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hour12: false,
});

/** 서버 시각 형식(「2026-10-22 08:31:05」, TIME_ZONE 기준) */
export function formatIssueTime(date: Date): string {
  return timeFormatter.format(date);
}

const SHA_RE = /^[0-9a-f]{7,40}$/i;
const REPO_RE = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
/** 캡처 그림 주소 — GitHub가 돌려준 html_url(+?raw=true)만 그림으로 건다. 괄호·공백·따옴표가 끼면 안 건다 */
const IMAGE_URL_RE = /^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\/blob\/[A-Za-z0-9_./-]+\.jpg\?raw=true$/;

/** 화면 시각 — ISO면 TIME_ZONE으로 바꿔 보여 준다(휴대폰 시계가 틀린 경우가 보이게). 아니면 그대로 코드 칸에 */
function clientTimeCell(clientTime: string): string {
  const time = Date.parse(clientTime);
  return Number.isFinite(time) && /^\d{4}-\d{2}-\d{2}T/.test(clientTime) ? formatIssueTime(new Date(time)) : inlineCode(clientTime, 40);
}

function shotSection(shot: QaShotState): string {
  switch (shot.kind) {
    case "uploaded":
      return IMAGE_URL_RE.test(shot.imageUrl) ? `![화면 캡처](${shot.imageUrl})` : "> 캡처 실패 — 저장한 주소가 이상해서 걸지 않았어요";
    case "upload-failed":
      return "> 캡처 실패 — 캡처 저장소에 올리지 못했어요";
    case "capture-failed":
      return "> 캡처 실패 — 화면에서 찍지 못했어요";
    case "dropped":
      return "> 캡처 실패 — 형식·크기가 맞지 않아 버렸어요";
    case "none":
      return "> 캡처 없음";
  }
}

/** 보낸 사람 줄 — 방식마다 다르다 */
function reporterRows(reporter: QaReporterInfo): [string, string][] {
  if (reporter.mode === "anon") return [["보낸 사람", "로그인 없는 방식 — 이름은 남긴 말 앞부분을 보세요"]];
  const { team } = reporter;
  const rows: [string, string][] = [
    ["계정", `${inlineCode(reporter.userId, 60)}${team?.myName ? ` (팀에서 부르는 이름: ${inlineCode(team.myName, 40)})` : ""}`],
  ];
  if (team !== undefined) rows.push(["팀", team ? `${inlineCode(team.name, 60)} (${inlineCode(team.id, 60)})` : "—"]);
  return rows;
}

/** 이슈 본문 — issueRepo는 커밋 링크용(`owner/repo`) */
export function issueBody(input: QaIssueInput, shot: QaShotState, issueRepo: string): string {
  const { meta, deploy, reporter } = input;
  const vp = meta.viewport;

  const device = [meta.device ? inlineCode(meta.device, 40) : "", inlineCode(input.userAgent, 300)].filter(Boolean).join(" · ");
  const shaCell =
    SHA_RE.test(deploy.sha) && REPO_RE.test(issueRepo)
      ? `[${deploy.sha.slice(0, 7)}](https://github.com/${issueRepo}/commit/${deploy.sha})`
      : inlineCode(deploy.sha, 40);
  const deployCell = [
    inlineCode(deploy.env, 20),
    inlineCode(deploy.ref, 100),
    shaCell,
    deploy.clientStale ? `**화면이 옛 배포** (화면 ${inlineCode(meta.buildId, 100)})` : "화면 버전 같음",
  ].join(" · ");

  const rows: [string, string][] = [
    ["화면", inlineCode(`${input.host}${meta.path}`, 400)],
    ["기기", device],
    ["화면 크기", `${vp.width}×${vp.height} · 배율 ${vp.dpr} · 확대 ${vp.zoom} · 스크롤 ${vp.scrollY}`],
    ...reporterRows(reporter),
    ["시각", `${inlineCode(input.serverTime, 40)} (${TIME_ZONE_LABEL}) · 휴대폰 ${clientTimeCell(meta.clientTime)}`],
    ["배포", deployCell],
  ];

  const machine = metaComment({
    v: 1,
    mode: reporter.mode,
    path: meta.path,
    host: input.host,
    device: meta.device,
    ua: input.userAgent.slice(0, 300),
    viewport: vp,
    userId: reporter.mode === "auth" ? reporter.userId : null,
    teamId: reporter.mode === "auth" ? (reporter.team?.id ?? null) : null,
    serverTime: input.serverTime,
    clientTime: meta.clientTime,
    env: deploy.env,
    sha: deploy.sha,
    ref: deploy.ref,
    deploymentId: deploy.deploymentId,
    clientBuildId: meta.buildId,
    clientStale: deploy.clientStale,
    shot: shot.kind,
    shotPath: shot.kind === "uploaded" ? shot.path : null,
  });

  return [
    "### 남긴 말",
    codeBlock(input.text),
    "",
    shotSection(shot),
    "",
    "| 항목 | 값 |",
    "|---|---|",
    ...rows.map(([k, v]) => `| ${k} | ${v} |`),
    "",
    machine,
    "",
  ].join("\n");
}

/** 캡처 파일 경로 — `2026/10/22/<무작위 id>.jpg`. 날짜는 TIME_ZONE 기준, 이름은 서버가 만든 추측 불가능한 id */
export function shotPath(now: Date, randomId: string): string {
  const [date] = formatIssueTime(now).split(" ");
  return `${date.replace(/-/g, "/")}/${randomId}.jpg`;
}
```
