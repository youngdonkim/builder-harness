# server.ts — 서버 검사 · 연속 제출 막기 · 배포 정보 · 내보내기

- 놓을 곳: `src/lib/qa-feedback/server.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/server.ts`
- 참고 구현에서 바꾼 점: 연속 제출 키를 `userId` → `rateKey`(reporter.ts가 줌)로 · 인스턴스 전체 한 시간 60번 상한 추가 · 팀 찾기(`teamIdFromPath`)를 reporter.auth로 옮김 · 보낸 사람 타입(QaWho·QaIdentifyFn·QaDetailsFn)을 여기 둠
- 어댑터: `rate-limit` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 제출을 센 뒤에 GitHub를 부르는 순서, 로그 금지 항목
- 의존: `server-only`

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
import "server-only";
/**
 * QA 피드백 — 서버 전용 도우미. 라우트 src/app/api/qa-feedback/route.ts만 쓴다.
 *  - 스위치: 서버 환경변수 QA_FEEDBACK이 "on"일 때만 켜진다(없거나 다른 값이면 꺼짐 — 빠뜨리면 꺼진 쪽으로).
 *  - 화면이 보낸 정보는 정해 둔 칸만 꺼내고 칸마다 길이를 자른다. 보낸 사람·배포는 화면 값을 믿지 않고 서버가 정한다.
 *  - 「보낸 사람이 누구인가」는 reporter.ts가 정한다(로그인 없는 방식 / 로그인 방식). 여기는 두 방식이 같다.
 *  - 연속 제출 막기는 서버 메모리 — 함수 인스턴스마다 따로 세서 완전하지 않다. 마지막 벽은 GitHub 쪽 한도.
 *    **제출을 센 뒤에 GitHub를 부른다** — 그래서 토큰 문제로 실패한 제출도 30초 1번에 들어가고, 바로 다시 누르면 「조금 뒤에」가 떠 원인이 가려진다. 실패하면 서버 로그부터 본다.
 *  - 보내기는 deliverQaReport() 하나 — 캡처 커밋 → 이슈 만들기(github.ts). GitHub 설정이 없으면 로그만 남긴다.
 *  - 로그에는 글 내용·이미지·계정 id·팀 이름·IP·토큰·이슈 번호·주소를 남기지 않는다.
 */
import type { NextRequest } from "next/server";
import { createQaIssue, qaGithubConfig, QaGithubError, uploadQaShot } from "./github";
import { issueBody, issueTitle, shotPath, type QaDeploy, type QaIssueInput, type QaReporterInfo, type QaShotState } from "./issue";
import { cleanLine, maskPath, QA_META_MAX_BYTES, QA_SHOT_MAX_BYTES, QA_TEXT_MAX, type QaClientMeta } from "./shared";

export function qaFeedbackOn(): boolean {
  return process.env.QA_FEEDBACK === "on";
}

/* ── 보낸 사람 (reporter.ts가 이 모양을 채운다) ── */

/** 요청을 보낸 사람 — rateKey는 연속 제출을 셀 열쇠(로그인 방식 `user:<id>`, 로그인 없는 방식 `ip:<해시>`) */
export type QaWho = { rateKey: string; userId: string | null };
/** 누구인가 — null이면 401(로그인 방식에서 로그인이 없거나 탈퇴한 경우) */
export type QaIdentifyFn = (request: NextRequest) => Promise<QaWho | null>;
/** 이슈에 적을 보낸 사람 정보 — 글·주소를 읽은 뒤에 부른다(팀을 주소에서 찾으므로) */
export type QaDetailsFn = (who: QaWho, meta: QaClientMeta) => Promise<QaReporterInfo>;

/* ── 연속 제출 막기 — 같은 보낸 사람 30초에 1번·하루 20번 + 인스턴스 전체 한 시간 60번 ── */

// [ADAPTER:rate-limit] 보통 그대로 둔다. 같은 와이파이의 테스터들이 IP 하나를 나눠 쓰면(로그인 없는 방식) 실측 뒤 늘릴 수 있다
const GAP_MS = 30_000;
const DAY_MS = 24 * 60 * 60 * 1000;
const DAY_MAX = 20;
const HOUR_MS = 60 * 60 * 1000;
/** 인스턴스 전체 상한 — 보낸 사람을 바꿔 가며(IP를 바꿔 가며) 쏟아 넣는 것을 GitHub 한도(분당 80·시간당 500) 앞에서 끊는다 */
const HOUR_MAX_ALL = 60;
// [/ADAPTER:rate-limit]
const sentByKey = new Map<string, number[]>();
let sentAll: number[] = [];

/** 넘었으면 참. 넘지 않았으면 이번 제출을 센다(GitHub를 부르기 전에 세므로 실패한 제출도 들어간다) */
export function qaRateLimited(rateKey: string, now: number): boolean {
  sentAll = sentAll.filter((t) => now - t < HOUR_MS);
  const recent = (sentByKey.get(rateKey) ?? []).filter((t) => now - t < DAY_MS);
  const last = recent[recent.length - 1];
  if ((last !== undefined && now - last < GAP_MS) || recent.length >= DAY_MAX || sentAll.length >= HOUR_MAX_ALL) {
    sentByKey.set(rateKey, recent);
    return true;
  }
  recent.push(now);
  sentByKey.set(rateKey, recent);
  sentAll.push(now);
  return false;
}

/* ── 내용 검사 ── */

/** 한 줄 글 — 줄바꿈·제어 문자 지우고 앞뒤 정리. 비었거나 200자를 넘으면 null */
export function parseText(value: FormDataEntryValue | null): string | null {
  if (typeof value !== "string") return null;
  const text = cleanLine(value);
  const length = [...text].length;
  return length >= 1 && length <= QA_TEXT_MAX ? text : null;
}

const clip = (v: unknown, max: number) => (typeof v === "string" ? cleanLine(v).slice(0, max) : "");
const num = (v: unknown, max: number) => (typeof v === "number" && Number.isFinite(v) ? Math.min(Math.max(v, 0), max) : 0);

/** 화면이 보낸 정보 — 4KB 넘거나 JSON이 아니면 빈 값으로 본다(글은 그대로 받는다) */
export function parseMeta(value: FormDataEntryValue | null): QaClientMeta {
  let raw: Record<string, unknown> = {};
  if (typeof value === "string" && new TextEncoder().encode(value).length <= QA_META_MAX_BYTES) {
    try {
      const parsed: unknown = JSON.parse(value);
      if (parsed && typeof parsed === "object") raw = parsed as Record<string, unknown>;
    } catch {
      // 버린다
    }
  }
  const vp = (raw.viewport && typeof raw.viewport === "object" ? raw.viewport : {}) as Record<string, unknown>;
  return {
    path: maskPath(typeof raw.path === "string" ? raw.path : "/"),
    device: clip(raw.device, 40),
    viewport: {
      width: Math.round(num(vp.width, 10_000)),
      height: Math.round(num(vp.height, 10_000)),
      dpr: num(vp.dpr, 10),
      zoom: num(vp.zoom, 20),
      scrollY: Math.round(num(vp.scrollY, 1_000_000)),
    },
    clientTime: clip(raw.clientTime, 40),
    buildId: clip(raw.buildId, 100),
    shotFailed: raw.shotFailed === true,
  };
}

export type QaShot = { bytes: Uint8Array; note: "ok" } | { bytes: null; note: "none" | "dropped" };

/** 캡처 — JPEG(앞 3바이트 FF D8 FF)이고 2MB 이하일 때만. 아니면 캡처만 버린다. 화면이 보낸 종류·이름은 믿지 않는다 */
export async function parseShot(value: FormDataEntryValue | null): Promise<QaShot> {
  if (!value || typeof value === "string") return { bytes: null, note: "none" };
  if (value.size === 0) return { bytes: null, note: "none" };
  if (value.size > QA_SHOT_MAX_BYTES) return { bytes: null, note: "dropped" };
  const bytes = new Uint8Array(await value.arrayBuffer());
  if (bytes[0] !== 0xff || bytes[1] !== 0xd8 || bytes[2] !== 0xff) return { bytes: null, note: "dropped" };
  return { bytes, note: "ok" };
}

/* ── 서버가 채우는 정보 ── */

/** 배포 버전 — Vercel 시스템 환경변수(실행 중에도 읽힘). 로컬엔 없어서 「로컬」·「dev」. 화면 배포 id와 다르면 「화면이 옛 배포」 */
export function deployInfo(clientBuildId: string): QaDeploy {
  const deploymentId = process.env.VERCEL_DEPLOYMENT_ID ?? "dev";
  return {
    env: process.env.VERCEL_ENV ?? "로컬",
    sha: process.env.VERCEL_GIT_COMMIT_SHA ?? "dev",
    ref: process.env.VERCEL_GIT_COMMIT_REF ?? "dev",
    deploymentId,
    clientStale: Boolean(clientBuildId) && clientBuildId !== deploymentId,
  };
}

/** 이슈 하나에 들어갈 것 전부 — 캡처는 캡처 저장소로, 나머지는 이슈 본문(issue.ts)으로 */
export type QaReport = QaIssueInput & { shot: QaShot };

/** 캡처가 어떻게 됐나 (올리기 전) — 버림이 먼저, 그다음 화면에서 못 찍음 */
function shotStateWithoutUpload(report: QaReport): QaShotState {
  if (report.shot.note === "dropped") return { kind: "dropped" };
  return report.meta.shotFailed ? { kind: "capture-failed" } : { kind: "none" };
}

/**
 * 받은 신고를 내보낸다 — ① 캡처가 있으면 캡처 저장소에 커밋(실패해도 이슈는 만들고 본문에 「캡처 실패」) ② 이슈 만들기 + 라벨.
 * GitHub 설정(토큰 둘·저장소 둘) 중 하나라도 없으면 이슈를 만들지 않고 「이렇게 만들 뻔했어요」만 로그에 남긴다(로컬 기본·1차 실측).
 * 「만들 뻔」 로그에는 가린 주소·기기·화면 크기·배포만 — 글 내용·계정 id·팀·IP·이미지는 넣지 않는다.
 * 이슈 만들기가 실패하면 던진다 → 라우트가 failed(502)로 답한다.
 */
export async function deliverQaReport(report: QaReport): Promise<void> {
  const shotBytes = report.shot.note === "ok" ? report.shot.bytes.length : 0;
  let github: ReturnType<typeof qaGithubConfig>;
  try {
    github = qaGithubConfig();
  } catch (error) {
    // 저장소 이름 모양이 틀림 — 메시지엔 환경변수 이름만 있다
    console.error("[qa-feedback] GitHub 설정이 잘못됐어요", error instanceof Error ? error.message : "");
    throw error;
  }
  if ("missing" in github) {
    console.info(
      "[qa-feedback] 이슈를 만들 뻔했어요 (GitHub 설정 없음)",
      JSON.stringify({
        missing: github.missing,
        mode: report.reporter.mode,
        textLength: [...report.text].length,
        path: report.meta.path,
        device: report.meta.device,
        viewport: report.meta.viewport,
        shot: report.shot.note === "ok" ? { bytes: shotBytes } : { state: shotStateWithoutUpload(report).kind },
        deploy: { env: report.deploy.env, sha: report.deploy.sha.slice(0, 7), ref: report.deploy.ref, clientStale: report.deploy.clientStale },
      }),
    );
    return;
  }
  const { config } = github;

  let shot: QaShotState = shotStateWithoutUpload(report);
  let shotLog: Record<string, unknown> = { state: shot.kind };
  if (report.shot.note === "ok") {
    const path = shotPath(new Date(), crypto.randomUUID());
    const upload = await uploadQaShot(config, path, report.shot.bytes);
    shot = upload.ok ? { kind: "uploaded", imageUrl: upload.imageUrl, path, bytes: shotBytes } : { kind: "upload-failed", bytes: shotBytes };
    shotLog = { state: shot.kind, status: upload.status, bytes: shotBytes };
  }

  try {
    const issue = await createQaIssue(config, issueTitle(report.text), issueBody(report, shot, config.issueRepo));
    console.info("[qa-feedback] 이슈를 만들었어요", JSON.stringify({ issue: issue.status, label: issue.label, shot: shotLog }));
  } catch (error) {
    const status = error instanceof QaGithubError ? error.status : -1;
    // 404면 먼저 토큰이 조직 승인 대기(Pending)인지 본다 — 비공개 저장소는 권한이 없으면 존재를 숨겨 404로 답한다
    console.error("[qa-feedback] 이슈를 만들지 못했어요", JSON.stringify({ issue: status, shot: shotLog }));
    throw error;
  }
}
```
