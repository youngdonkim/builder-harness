# QaFeedbackSheet.tsx — 한 줄 입력 창

- 놓을 곳: `src/components/qa-feedback/QaFeedbackSheet.tsx` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: sangsiki-quiugi@5e9aa46 `src/components/system/QaFeedbackSheet.tsx`
- 참고 구현에서 바꾼 점: 자체 Sheet·TextField·Button을 shadcn Sheet·Input·Label·Button 기본값으로 · 엔터 보내기에 한글 조합 가드(isComposing) · 첫 초점을 `onOpenAutoFocus`로 입력칸에 · 문구를 `QA_COPY` 키로
- 어댑터: `copy`, `ui-open-guard`, `ui-sheet` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 캡처 3초 기다림 · 실패는 창 안 오류 줄(토스트 아님) · 「무엇이 함께 가는지」 안내 줄
- 의존: 디자인 시스템 부품

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```tsx
"use client";
/**
 * QA 피드백 한 줄 창 — QaFeedback이 빈 곳 3번 연속 터치 뒤 연다. next/dynamic으로만 불린다.
 * 디자인 시스템의 아래에서 올라오는 창 + 입력칸 + 버튼을 그대로 쓴다 — 새 CSS는 최소로. 캡처 미리보기는 보여 주지 않고 안내 한 줄만
 * (무엇이 함께 가는지 알리는 줄 — 개인정보 알림을 겸하니 빼지 않는다).
 * 보낼 때 캡처가 아직이면 최대 3초 기다리고, 실패·시간 초과면 글만 보낸다(이슈에 「캡처 실패」).
 * 실패는 토스트가 아니라 창 안 오류 줄로 — 창을 닫지 않고 쓴 글을 남긴다.
 * 입력칸에서 엔터로 보낼 때 한글 조합 중(isComposing) 엔터는 무시한다 — 마지막 글자가 두 번 들어가는 문제.
 * 아이폰은 터치 이벤트 안에서 연 창이 아니면 자판이 저절로 안 올라올 수 있다 — 입력칸에 초점만 두고, 안 올라오면 한 번 눌러 쓰게 둔다(실측 필요).
 */
import { useRef, useState } from "react";
import { sendQaFeedback } from "@/lib/qa-feedback/client";
import { QA_TEXT_MAX, type QaCollectedMeta } from "@/lib/qa-feedback/shared";
// [ADAPTER:ui-sheet] 디자인 시스템 부품. 기본값: shadcn Sheet·Input·Label·Button. 클래스는 프로젝트 토큰 규칙(design-system)대로, 하단 안전 영역은 프로젝트 셸 규칙대로
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet";
// [/ADAPTER:ui-sheet]
// [ADAPTER:copy] 화면 문구 묶음 자리 — 키 목록은 스킬 wiring.md
import { QA_COPY } from "@/lib/copy";
// [/ADAPTER:copy]

/** 보낼 때 캡처를 기다리는 최대 시간 */
const SHOT_WAIT_MS = 3000;
const INPUT_ID = "qa-feedback-text";
const ERROR_ID = "qa-feedback-error";

function waitShot(shot: Promise<Blob | null>): Promise<Blob | null> {
  return Promise.race([shot.catch(() => null), new Promise<null>((resolve) => setTimeout(() => resolve(null), SHOT_WAIT_MS))]);
}

export default function QaFeedbackSheet({ meta, shot, onClose, onSent }: {
  meta: QaCollectedMeta;
  /** 3번째 터치 순간 시작한 캡처 (실패하면 null) */
  shot: Promise<Blob | null>;
  /** 닫기 — 연 직후 잠깐은 QaFeedback이 무시한다(3번째 터치의 click) */
  onClose: () => void;
  onSent: () => void;
}) {
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const empty = text.trim().length === 0;

  async function send() {
    if (empty || busy) return;
    setBusy(true);
    setError(null);
    const blob = await waitShot(shot);
    const result = await sendQaFeedback({ text: text.trim(), meta: { ...meta, shotFailed: !blob }, shot: blob });
    setBusy(false);
    if (result.kind === "sent") {
      onSent();
      return;
    }
    setError(result.kind === "too-many" ? QA_COPY.tooMany : result.kind === "signed-out" ? QA_COPY.signedOut : QA_COPY.failed);
  }

  return (
    // [ADAPTER:ui-open-guard] 열린 채로 두고(open), 닫기 요청만 onClose로 넘긴다 — QaFeedback이 연 직후 닫기를 무시해도 창이 그대로 남는다(실측 필요)
    <Sheet open onOpenChange={(next) => (next ? undefined : onClose())}>
      <SheetContent
        side="bottom"
        onOpenAutoFocus={(e) => {
          // 창은 열리면 첫 버튼(닫기)에 초점을 준다 — 입력칸으로 옮긴다
          e.preventDefault();
          inputRef.current?.focus();
        }}
      >
        <SheetHeader>
          <SheetTitle>{QA_COPY.title}</SheetTitle>
          <SheetDescription>{QA_COPY.help}</SheetDescription>
        </SheetHeader>
        <div className="grid gap-4 px-4 pb-4">
          <div className="grid gap-2">
            <Label htmlFor={INPUT_ID}>{QA_COPY.label}</Label>
            <Input
              ref={inputRef}
              id={INPUT_ID}
              placeholder={QA_COPY.placeholder}
              value={text}
              maxLength={QA_TEXT_MAX}
              enterKeyHint="send"
              aria-invalid={error ? true : undefined}
              aria-describedby={error ? ERROR_ID : undefined}
              onChange={(e) => {
                setText(e.target.value);
                if (error) setError(null);
              }}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.nativeEvent.isComposing) {
                  e.preventDefault();
                  void send();
                }
              }}
            />
            <div className="flex justify-between gap-2 text-sm">
              <p id={ERROR_ID} role="alert" className="text-destructive">
                {error}
              </p>
              <p className="text-muted-foreground">{QA_COPY.count([...text].length, QA_TEXT_MAX)}</p>
            </div>
          </div>
          <Button disabled={empty || busy} aria-busy={busy} onClick={() => void send()}>
            {busy ? QA_COPY.sending : empty ? QA_COPY.sendEmpty : QA_COPY.send}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
    // [/ADAPTER:ui-open-guard]
  );
}
```
