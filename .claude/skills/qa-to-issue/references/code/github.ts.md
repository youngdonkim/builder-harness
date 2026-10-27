# github.ts — 캡처 커밋 + 이슈 생성 + 라벨

- 놓을 곳: `src/lib/qa-feedback/github.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/github.ts`
- 참고 구현에서 바꾼 점: 라벨 이름을 환경변수 `GITHUB_QA_LABEL`(비면 `qa`)로 · 요청 머리글 이름을 어댑터로
- 어댑터: `gh-user-agent` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 토큰 둘을 저장소마다 따로 쓰기, 시간 제한, 409만 한 번 더, 라벨이 빠지면 붙이기 재호출
- 의존: `server-only`

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
import "server-only";
/**
 * QA 피드백 — GitHub 호출. server.ts의 deliverQaReport()만 쓴다.
 *  - GitHub API로는 이슈에 그림을 직접 첨부할 수 없다 → 캡처는 **별도 비공개 캡처 저장소**에 커밋하고(Contents API), 이슈 본문에서 그 주소를 그림으로 건다.
 *    비공개 저장소의 그림은 그 저장소 권한이 있는 사람에게만 보인다(공개 버킷처럼 「주소만 알면 누구나」가 아니다).
 *  - 토큰 둘: 이슈용(코드 저장소 하나 · Issues 쓰기만)·캡처용(캡처 저장소 하나 · Contents 쓰기만). 저장소마다 자기 토큰만 쓴다.
 *    코드 저장소에 Contents 쓰기 토큰을 두지 않는 이유 — main 보호 규칙이 없으면 그 토큰이 샐 때 main에 바로 밀려 실서비스까지 배포된다.
 *  - 토큰 둘·저장소 둘 중 하나라도 없으면 설정 없음(로컬 기본) → 부르는 쪽이 이슈를 만들지 않고 로그만 남긴다.
 *  - 요청마다 시간 제한. 이슈 쪽 실패(한도 429·403 포함)는 다시 시도하지 않는다 — 캡처 커밋의 409(동시 쓰기 충돌)만 한 번 더.
 *  - 토큰·응답 본문은 로그에도, 사용자 응답에도 넣지 않는다. 바깥으로 내보내는 건 상태 코드뿐.
 *  - 비공개 저장소는 권한이 없으면 존재를 숨겨 404로 답한다 — 조직 토큰이 승인 대기(Pending)일 때도 404다.
 */

const API = "https://api.github.com";
const API_VERSION = "2022-11-28";
/** GitHub가 요구하는 요청 머리글 — 누가 부르는지 알아볼 이름 */
const USER_AGENT = "my-app-qa-feedback"; // [ADAPTER:gh-user-agent] `<저장소 이름>-qa-feedback`
/** 라벨 이름 기본값 — GITHUB_QA_LABEL이 비면 이것 */
const DEFAULT_LABEL = "qa";
/** 시간 제한 — 함수 전체(maxDuration 30초) 안에 들도록: 캡처 6초 × 최대 2번 + 이슈 10초 + 라벨 5초 */
const SHOT_TIMEOUT_MS = 6_000;
const ISSUE_TIMEOUT_MS = 10_000;
const LABEL_TIMEOUT_MS = 5_000;

const REPO_RE = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const ENV_NAMES = ["GITHUB_QA_ISSUE_TOKEN", "GITHUB_QA_SHOTS_TOKEN", "GITHUB_QA_REPO", "GITHUB_QA_SHOTS_REPO"] as const;

export type QaGithubConfig = { issueToken: string; shotsToken: string; issueRepo: string; shotsRepo: string; label: string };

/** 설정 읽기 — 없으면 빠진 이름들(값은 안 돌려줌). 저장소 이름이 `owner/repo` 모양이 아니면 던진다(잘못 넣은 설정은 실패로 드러나게) */
export function qaGithubConfig(): { config: QaGithubConfig } | { missing: string[] } {
  const missing = ENV_NAMES.filter((name) => !process.env[name]?.trim());
  if (missing.length > 0) return { missing };
  const issueRepo = process.env.GITHUB_QA_REPO!.trim();
  const shotsRepo = process.env.GITHUB_QA_SHOTS_REPO!.trim();
  for (const [name, value] of [["GITHUB_QA_REPO", issueRepo], ["GITHUB_QA_SHOTS_REPO", shotsRepo]] as const) {
    if (!REPO_RE.test(value)) throw new QaGithubError(`${name}가 owner/repo 모양이 아니에요`, 0);
  }
  const label = process.env.GITHUB_QA_LABEL?.trim().slice(0, 50) || DEFAULT_LABEL;
  return {
    config: {
      issueToken: process.env.GITHUB_QA_ISSUE_TOKEN!.trim(),
      shotsToken: process.env.GITHUB_QA_SHOTS_TOKEN!.trim(),
      issueRepo,
      shotsRepo,
      label,
    },
  };
}

/** GitHub 실패 — status는 HTTP 상태 코드(연결 실패·시간 초과는 0). 메시지에 토큰·응답 본문을 넣지 않는다 */
export class QaGithubError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
    this.name = "QaGithubError";
  }
}

type GithubResponse = { status: number; data: Record<string, unknown> | null };

async function githubRequest(token: string, method: "POST" | "PUT", path: string, body: unknown, timeoutMs: number): Promise<GithubResponse> {
  try {
    const res = await fetch(`${API}${path}`, {
      method,
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${token}`,
        "X-GitHub-Api-Version": API_VERSION,
        "Content-Type": "application/json",
        "User-Agent": USER_AGENT,
      },
      body: JSON.stringify(body),
      cache: "no-store",
      signal: AbortSignal.timeout(timeoutMs),
    });
    let data: Record<string, unknown> | null = null;
    try {
      const parsed: unknown = await res.json();
      if (parsed && typeof parsed === "object") data = parsed as Record<string, unknown>;
    } catch {
      // 본문 없음
    }
    return { status: res.status, data };
  } catch {
    return { status: 0, data: null };
  }
}

/** `owner/repo` + 경로 조각을 API 경로로 (조각마다 인코딩) */
function repoPath(repo: string, ...rest: string[]): string {
  const [owner, name] = repo.split("/");
  return ["", "repos", owner, name, ...rest].map((part, i) => (i === 0 ? part : encodeURIComponent(part))).join("/");
}

export type QaShotUpload = { ok: true; status: number; imageUrl: string } | { ok: false; status: number };

/**
 * 캡처 커밋 — 캡처 저장소 기본 브랜치에 `filePath`로 새 파일(기본 브랜치가 있어야 하므로 저장소는 README를 넣어 만든다).
 * 409(동시 쓰기 충돌)면 한 번만 다시. 커밋 메시지엔 경로만 — 사용자 글은 넣지 않는다.
 * 그림 주소는 응답의 html_url(`https://github.com/…/blob/<기본 브랜치>/…`)에 `?raw=true`를 붙인다.
 */
export async function uploadQaShot(config: QaGithubConfig, filePath: string, bytes: Uint8Array): Promise<QaShotUpload> {
  const path = repoPath(config.shotsRepo, "contents", ...filePath.split("/"));
  const body = { message: `qa: 화면 캡처 ${filePath}`, content: Buffer.from(bytes).toString("base64") };
  let res = await githubRequest(config.shotsToken, "PUT", path, body, SHOT_TIMEOUT_MS);
  if (res.status === 409) res = await githubRequest(config.shotsToken, "PUT", path, body, SHOT_TIMEOUT_MS);
  if (res.status !== 201 && res.status !== 200) return { ok: false, status: res.status };
  const content = res.data?.content as Record<string, unknown> | undefined;
  const htmlUrl = typeof content?.html_url === "string" ? content.html_url : "";
  const imageUrl = htmlUrl.startsWith("https://github.com/") ? `${htmlUrl}?raw=true` : `https://github.com/${config.shotsRepo}/blob/main/${filePath}?raw=true`;
  return { ok: true, status: res.status, imageUrl };
}

export type QaIssueResult = { status: number; label: "included" | number };

/**
 * 이슈 만들기 + 라벨. GitHub 문서상 푸시 권한이 없으면 라벨을 조용히 버리므로, 응답에 라벨이 없으면 「라벨 붙이기」를 한 번 더.
 * 라벨 붙이기가 실패해도 이슈는 이미 있으니 성공으로 본다. 이슈 만들기가 실패하면 QaGithubError.
 */
export async function createQaIssue(config: QaGithubConfig, title: string, body: string): Promise<QaIssueResult> {
  const res = await githubRequest(config.issueToken, "POST", repoPath(config.issueRepo, "issues"), { title, body, labels: [config.label] }, ISSUE_TIMEOUT_MS);
  if (res.status !== 201) throw new QaGithubError("이슈를 만들지 못했어요", res.status);
  const labels = Array.isArray(res.data?.labels) ? res.data.labels : [];
  const hasLabel = labels.some((l) => (typeof l === "string" ? l : (l as { name?: unknown })?.name) === config.label);
  if (hasLabel) return { status: res.status, label: "included" };
  const number = res.data?.number;
  if (typeof number !== "number") return { status: res.status, label: 0 };
  const labelRes = await githubRequest(config.issueToken, "POST", repoPath(config.issueRepo, "issues", String(number), "labels"), { labels: [config.label] }, LABEL_TIMEOUT_MS);
  return { status: res.status, label: labelRes.status };
}
```
