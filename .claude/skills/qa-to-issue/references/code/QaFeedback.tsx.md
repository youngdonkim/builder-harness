# QaFeedback.tsx — 3번 연속 터치 감지 · 캡처 시작 · 창 열기

- 놓을 곳: `src/components/qa-feedback/QaFeedback.tsx` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/components/system/QaFeedback.tsx`
- 참고 구현에서 바꾼 점: 로그인 확인(`getCurrentUser`·`useData`)을 `gate.ts`의 `useQaReady()`로 뺌 · 토스트를 sonner 기본값으로 · 미리 받아 둔 캡처 코드가 있으면 3번째 터치 순간 바로 부름(창이 그려지기 전에 자리를 재도록) · 문구를 `QA_COPY` 키로
- 어댑터: `copy`, `toast` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 판정값 상수(TAP_COUNT·TAP_GAP_MS·TAP_SPREAD_PX·MOVE_PX·SCRIM_GUARD_MS)와 다시 세기 규칙 — 아이폰·PC 실측값
- 의존: `next/dynamic`, React

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```tsx
"use client";
/**
 * QA 피드백 — 빈 곳을 3번 연속 터치(PC는 세 번 클릭)하면 화면을 찍고 한 줄 창을 연다.
 * 공통 layout에 한 번 깐다(화면에 그리는 것은 창뿐). 끄려면 Vercel 환경변수 QA_FEEDBACK을 지우고 다시 배포한다.
 *  - 스위치가 꺼진 빌드(NEXT_PUBLIC_QA_FEEDBACK ≠ "1")면 아무것도 안 그리고 아무것도 안 듣는다.
 *  - 감지를 켜는 조건은 gate.ts의 useQaReady() — 로그인 없는 방식은 늘, 로그인 방식은 로그인이 확인된 뒤.
 *  - 길게 누르기는 쓰지 않는다 — 아이폰 사파리는 빈 곳을 길게 눌러도 가까운 글자를 선택하려 해서(약 0.5초) 누르기가 취소된다.
 *  - 빈 곳 판정은 press.ts(누르는 요소·그림·창·글자 줄 위는 건너뜀). 터치 하나 = 빈 곳에서 시작해 MOVE_PX 안에서 끝난 눌렀다 뗌.
 *    터치 사이가 TAP_GAP_MS를 넘거나 첫 터치에서 TAP_SPREAD_PX보다 멀어지거나 스크롤·두 손가락·다른 곳 누르기가 끼면 처음부터 다시 센다.
 *  - 3번째 터치를 뗀 순간: 정보를 적고 캡처를 시작한 뒤 창을 연다 — 창이 생기기 전 화면이 찍히도록, 미리 받아 둔 캡처 코드가 있으면 그 자리에서 바로 부른다.
 *    그 터치를 따라오는 click이 창을 바로 닫지 않게 SCRIM_GUARD_MS 동안 닫기를 무시한다.
 *  - 캡처 코드(modern-screenshot)·창은 동적 import — 첫 화면 번들에 안 들어간다. 감지가 켜지면 브라우저가 한가할 때 미리 받아 둔다.
 *  - 이 판정값들은 아이폰·PC 실측으로 정한 값이다. 프로젝트마다 바꾸지 않는다.
 */
import dynamic from "next/dynamic";
import { useEffect, useRef, useState } from "react";
import { collectMeta, QA_FEEDBACK_ENABLED } from "@/lib/qa-feedback/client";
import { useQaReady } from "@/lib/qa-feedback/gate";
import { isEmptySpot } from "@/lib/qa-feedback/press";
import type { QaCollectedMeta } from "@/lib/qa-feedback/shared";
// [ADAPTER:toast] 성공 알림(창을 닫고 띄움). 기본값: shadcn의 sonner(layout에 <Toaster />가 있어야 함)
import { toast } from "sonner";
// [/ADAPTER:toast]
// [ADAPTER:copy] 화면 문구 묶음 자리 — 키 목록은 스킬 wiring.md. 문구는 프로젝트 보이스 앤 톤으로 정하고 사람이 확정한다
import { QA_COPY } from "@/lib/copy";
// [/ADAPTER:copy]

const QaFeedbackSheet = dynamic(() => import("./QaFeedbackSheet"), { ssr: false });

type CaptureModule = typeof import("@/lib/qa-feedback/capture");

/** 열려면 이만큼 연속으로 터치 */
const TAP_COUNT = 3;
/** 터치와 터치 사이(손 뗀 때부터 다음 손 뗀 때까지) 이 시간 안이어야 연속 (ms) */
const TAP_GAP_MS = 400;
/** 첫 터치 지점에서 이만큼까지는 같은 자리로 본다 — 손가락 오차 (화면 좌표 — CSS 토큰과 무관) */
const TAP_SPREAD_PX = 30;
/** 누른 채 이만큼 움직이면 스크롤하려는 것으로 보고 그 터치는 세지 않는다 (화면 좌표) */
const MOVE_PX = 10;
/** 창을 연 직후 닫기를 무시하는 시간 — 3번째 터치를 따라오는 click이 창을 닫지 않게 */
const SCRIM_GUARD_MS = 400;

type Opened = { meta: QaCollectedMeta; shot: Promise<Blob | null>; guardUntil: number };

/** 빈 곳에 닿아 있는 중인 손가락(마우스) */
type Down = { pointerId: number; x: number; y: number };
/** 지금까지 센 연속 터치 */
type Taps = { count: number; x: number; y: number; lastUpAt: number };

export function QaFeedback() {
  if (!QA_FEEDBACK_ENABLED) return null;
  return <QaFeedbackOn />;
}

function QaFeedbackOn() {
  const ready = useQaReady();
  const [opened, setOpened] = useState<Opened | null>(null);
  const openedRef = useRef(false);
  const captureRef = useRef<CaptureModule | null>(null);

  useEffect(() => {
    openedRef.current = opened !== null;
  }, [opened]);

  // 감지가 켜지면 브라우저가 한가할 때 캡처 코드·창을 미리 받아 둔다 — 첫 3번 터치가 느리지 않게
  useEffect(() => {
    if (!ready) return;
    const prefetch = () => {
      void import("@/lib/qa-feedback/capture").then((m) => {
        captureRef.current = m;
      });
      void import("./QaFeedbackSheet");
    };
    if ("requestIdleCallback" in window) {
      const id = window.requestIdleCallback(prefetch, { timeout: 5000 });
      return () => window.cancelIdleCallback(id);
    }
    const id = setTimeout(prefetch, 2000);
    return () => clearTimeout(id);
  }, [ready]);

  useEffect(() => {
    if (!ready) return;
    let down: Down | null = null;
    let taps: Taps | null = null;

    const reset = () => {
      down = null;
      taps = null;
    };

    const open = () => {
      reset();
      window.getSelection()?.removeAllRanges(); // 세 번 터치에 생긴 글자 선택이 캡처에 찍히지 않게
      const meta = collectMeta();
      // 미리 받아 둔 캡처 코드가 있으면 지금 바로 부른다 — 창이 그려지기 전에 자리를 재도록
      const loaded = captureRef.current;
      const shot = (loaded ? loaded.captureViewport() : import("@/lib/qa-feedback/capture").then((m) => m.captureViewport())).catch(() => null);
      setOpened({ meta, shot, guardUntil: Date.now() + SCRIM_GUARD_MS });
    };

    const onDown = (e: PointerEvent) => {
      if (!e.isPrimary) {
        reset(); // 두 손가락(확대)
        return;
      }
      down = null;
      if (openedRef.current) {
        taps = null;
        return;
      }
      if (e.pointerType === "mouse" && e.button !== 0) return;
      if (!isEmptySpot(e.target, e.clientX, e.clientY)) {
        taps = null; // 다른 곳을 누르면 처음부터
        return;
      }
      down = { pointerId: e.pointerId, x: e.clientX, y: e.clientY };
    };
    const onMove = (e: PointerEvent) => {
      if (!down || e.pointerId !== down.pointerId) return;
      if (Math.hypot(e.clientX - down.x, e.clientY - down.y) > MOVE_PX) reset(); // 스크롤·드래그
    };
    const onUp = (e: PointerEvent) => {
      if (!down || e.pointerId !== down.pointerId) return;
      const now = Date.now();
      const { x, y } = down;
      down = null;
      const continued =
        taps !== null && now - taps.lastUpAt <= TAP_GAP_MS && Math.hypot(x - taps.x, y - taps.y) <= TAP_SPREAD_PX;
      taps = continued && taps ? { ...taps, count: taps.count + 1, lastUpAt: now } : { count: 1, x, y, lastUpAt: now };
      if (taps.count >= TAP_COUNT) open();
    };

    const passive = { passive: true, capture: true } as const;
    const onScroll = () => reset();
    const onHidden = () => {
      if (document.visibilityState === "hidden") reset();
    };
    document.addEventListener("pointerdown", onDown, passive);
    document.addEventListener("pointermove", onMove, passive);
    document.addEventListener("pointerup", onUp, passive);
    document.addEventListener("pointercancel", reset, passive); // 브라우저가 스크롤 등을 가져갔다
    window.addEventListener("scroll", onScroll, passive);
    document.addEventListener("visibilitychange", onHidden);
    return () => {
      reset();
      document.removeEventListener("pointerdown", onDown, passive);
      document.removeEventListener("pointermove", onMove, passive);
      document.removeEventListener("pointerup", onUp, passive);
      document.removeEventListener("pointercancel", reset, passive);
      window.removeEventListener("scroll", onScroll, passive);
      document.removeEventListener("visibilitychange", onHidden);
    };
  }, [ready]);

  if (!opened) return null;
  return (
    <QaFeedbackSheet
      meta={opened.meta}
      shot={opened.shot}
      onClose={() => {
        if (Date.now() < opened.guardUntil) return;
        setOpened(null);
      }}
      onSent={() => {
        setOpened(null);
        toast.success(QA_COPY.sent); // [ADAPTER:toast] 프로젝트 토스트 부르는 모양으로
      }}
    />
  );
}
```
