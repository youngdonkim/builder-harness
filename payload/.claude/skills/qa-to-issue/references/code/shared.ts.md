# shared.ts — 한도 · 한 줄 다듬기 · 주소 가리기

- 놓을 곳: `src/lib/qa-feedback/shared.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/lib/qa-feedback/shared.ts`
- 참고 구현에서 바꾼 점: 비밀 경로 규칙을 정규식 목록(SECRET_PATHS)으로 일반화
- 어댑터: `mask-rules` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 크기·길이 한도(요청 4MB·캡처 2MB·메타 4KB·글 200자 — Vercel 함수 요청 본문 한도 4.5MB 아래)
- 의존: 없음

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
/**
 * QA 피드백 — 화면과 서버가 같이 쓰는 제한값·글 다듬기·주소 가리기 (docs/qa-feedback.md).
 * 기능을 뺄 땐 src/lib/qa-feedback/ 폴더째 지운다.
 */

/** 한 줄 글 최대 글자 수 */
export const QA_TEXT_MAX = 200;
/** 요청 전체 크기 상한 — 넘으면 본문을 읽기 전에 413 (Vercel 함수 요청 본문 한도 4.5MB 아래) */
export const QA_REQUEST_MAX_BYTES = 4 * 1024 * 1024;
/** 캡처 상한 — 넘으면 캡처만 버리고 글은 보낸다 */
export const QA_SHOT_MAX_BYTES = 2 * 1024 * 1024;
/** 화면이 보낸 정보(meta JSON) 상한 */
export const QA_META_MAX_BYTES = 4 * 1024;
/** 주소 칸 최대 글자 수 */
export const QA_PATH_MAX = 300;

/** 줄바꿈·제어 문자를 지우고 앞뒤 공백을 정리한다 (한 줄 글·주소처럼 바깥에서 온 글) */
export function cleanLine(value: string): string {
  return value.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]+/g, " ").replace(/\s+/g, " ").trim();
}

// [ADAPTER:mask-rules] 이슈에 남기면 안 되는 주소 조각 — 초대·비밀번호 재설정·공유 링크의 코드, 로그인 콜백의 code 등. 프로젝트 주소 규칙에 맞춰 고친다
/** 이름이 이것인 주소 값(쿼리)은 *** 로 바꾼다 */
const SECRET_PARAMS = new Set(["code", "token"]);
/** 이 모양의 경로 조각은 *** 로 가린다 — 첫 번째 괄호까지는 남기고 그 뒤 한 칸을 가린다 */
const SECRET_PATHS: RegExp[] = [/^(\/invite\/)[^/]+/];
// [/ADAPTER:mask-rules]

/**
 * 이슈에 남길 주소 — 비밀 경로 조각은 ***로 가리고, 비밀 쿼리 값은 ***로 바꾼다. `#` 뒤는 처음부터 받지 않는다.
 * 앱 안 주소(/로 시작)가 아니면 "/"로 본다.
 */
export function maskPath(pathWithSearch: string): string {
  const raw = cleanLine(pathWithSearch).slice(0, QA_PATH_MAX * 2);
  if (!raw.startsWith("/") || raw.startsWith("//")) return "/";
  let url: URL;
  try {
    url = new URL(raw, "https://qa.invalid");
  } catch {
    return "/";
  }
  let path = url.pathname;
  for (const pattern of SECRET_PATHS) path = path.replace(pattern, "$1***");
  for (const key of [...url.searchParams.keys()]) {
    if (SECRET_PARAMS.has(key.toLowerCase())) url.searchParams.set(key, "***");
  }
  const search = url.searchParams.toString();
  return `${path}${search ? `?${search}` : ""}`.slice(0, QA_PATH_MAX);
}

/** 화면이 보내는 정보 — 서버는 이 칸만 꺼내 쓰고 나머지는 버린다. 보낸 사람 정보는 화면에서 받지 않는다(서버가 정한다) */
export type QaClientMeta = {
  /** 가린 주소 (pathname + search) */
  path: string;
  /** 기기 한 줄 (예: "아이폰·아이패드 홈 화면 앱") */
  device: string;
  /** 화면 크기·배율·확대·스크롤 */
  viewport: { width: number; height: number; dpr: number; zoom: number; scrollY: number };
  /** 화면 시각 (ISO) */
  clientTime: string;
  /** 화면이 받은 배포 id (NEXT_PUBLIC_BUILD_ID) */
  buildId: string;
  /** 캡처를 못 했다 (실패·시간 초과) */
  shotFailed: boolean;
};

/** 3번째 터치 순간 화면이 모은 정보 — 캡처 결과(shotFailed)는 보낼 때 채운다 */
export type QaCollectedMeta = Omit<QaClientMeta, "shotFailed">;

/** 서버 응답 — 이슈 번호·주소는 돌려주지 않는다 */
export type QaFeedbackResult = { kind: "sent" } | { kind: "too-many" } | { kind: "signed-out" } | { kind: "failed" };
```
