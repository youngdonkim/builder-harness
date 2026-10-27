# gate.ts — 3번 터치 감지를 켜도 되나 — 로그인 방식

- 놓을 곳: `src/lib/qa-feedback/gate.ts` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: **로그인 방식만** — 로그인 없는 방식이면 gate.anon.ts.md를 같은 자리에
- 출처: sangsiki-quiugi@5e9aa46 `src/components/system/QaFeedback.tsx`의 로그인 확인 부분
- 참고 구현에서 바꾼 점: 프로젝트 자체 훅 대신 Supabase 세션 조회 + `onAuthStateChange`를 기본값으로
- 어댑터: `auth-client` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: —
- 의존: React, 프로젝트의 브라우저 로그인 클라이언트

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```ts
/**
 * QA 피드백 — 3번 터치 감지를 켜도 되나: **로그인 방식**.
 * 두 방식이 갈리는 화면 쪽 자리는 이 파일 하나다(서버 쪽은 reporter.ts). 스위치(QA_FEEDBACK)는 QaFeedback.tsx가 먼저 본다.
 * 로그인이 확인돼야 켜고, 로그아웃하면 끈다 — 서버도 로그인을 다시 확인하니(401) 이건 화면에서 헛걸음을 줄이는 몫이다.
 */
import { useEffect, useState } from "react";
// [ADAPTER:auth-client] 브라우저 쪽 로그인 상태. 기본값: Supabase(@/lib/supabase/client의 createClient — Supabase 공식 Next.js 예제 모양). 프로젝트에 로그인 상태 훅이 있으면 그걸 쓴다
import { createClient } from "@/lib/supabase/client";
// [/ADAPTER:auth-client]

/** 지금 방식 — reporter.ts와 같아야 한다 */
export const QA_REPORTER_MODE: "anon" | "auth" = "auth";

/** 감지를 켜도 되나 — 로그인돼 있을 때만 참 */
export function useQaReady(): boolean {
  const [signedIn, setSignedIn] = useState(false);
  useEffect(() => {
    // [ADAPTER:auth-client] 지금 로그인돼 있나 + 바뀔 때마다 알림
    const supabase = createClient();
    let alive = true;
    void supabase.auth.getSession().then(({ data }) => {
      if (alive) setSignedIn(Boolean(data.session));
    });
    const { data } = supabase.auth.onAuthStateChange((_event, session) => setSignedIn(Boolean(session)));
    return () => {
      alive = false;
      data.subscription.unsubscribe();
    };
    // [/ADAPTER:auth-client]
  }, []);
  return signedIn;
}
```
