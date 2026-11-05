# QaFeedbackFields.tsx — 한 줄 창의 안쪽(입력칸·버튼) · 보기 전용 미리보기

- 놓을 곳: `src/components/qa-feedback/QaFeedbackFields.tsx` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통
- 출처: (참고 구현의 `QaFeedbackSheet.tsx` 안쪽을 떼어 냄 — 이 하네스에서 새로 나눔)
- 참고 구현에서 바꾼 점: 창 겉틀(Sheet)·초점 가두기 없이 안쪽만. `mode: "live"`는 한 줄 창이, `mode: "preview"`는 첫 안내(`QaFeedbackIntro`)가 쓴다
- 어댑터: `copy`, `ui-sheet` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 미리보기는 입력·제출이 안 되는 모양(읽기 전용·값 비움·`tabIndex={-1}`·버튼 잠금·`onClick` 없음) — 바깥 틀의 `inert`·`aria-hidden`과 겹으로 막는다. 이 파일은 보내기·캡처 코드를 import하지 않는다
- 의존: 디자인 시스템 부품

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```tsx
"use client";
/**
 * QA 피드백 한 줄 창의 안쪽 — 입력칸·글자 수·오류 줄·보내기 버튼. 창 겉틀은 없다(겉틀은 QaFeedbackSheet).
 *  - live: QaFeedbackSheet가 쓴다. 값·바뀜·보내기는 부르는 쪽이 넘긴다 — 이 파일은 서버를 부르지 않는다.
 *  - preview: QaFeedbackIntro가 「이런 창이 뜬다」를 보여 주려고 쓴다. 입력·제출이 절대 안 되게 그린다 —
 *    입력칸은 읽기 전용·값 비움(예시 문구만 보임)·tabIndex -1, 버튼은 잠금·tabIndex -1·onClick 없음, 오류 줄 없음.
 *    바깥 틀이 inert·aria-hidden·pointer-events none을 한 겹 더 건다(QaFeedbackIntro). 그래서 캡처·서버 요청이 일어날 길이 없다.
 *  - 미리보기와 실제 창의 id가 겹치지 않게 mode마다 id를 따로 쓴다.
 */
import type { RefObject } from "react";
import { QA_TEXT_MAX } from "@/lib/qa-feedback/shared";
// [ADAPTER:ui-sheet] 디자인 시스템 부품. 기본값: shadcn Input·Label·Button. 클래스는 프로젝트 토큰 규칙(design-system)대로
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
// [/ADAPTER:ui-sheet]
// [ADAPTER:copy] 화면 문구 묶음 자리 — 키 목록은 스킬 wiring.md
import { QA_COPY } from "@/lib/copy";
// [/ADAPTER:copy]

type LiveProps = {
  mode: "live";
  inputRef: RefObject<HTMLInputElement | null>;
  text: string;
  busy: boolean;
  error: string | null;
  onTextChange: (next: string) => void;
  onSubmit: () => void;
};
type PreviewProps = { mode: "preview" };

export function QaFeedbackFields(props: LiveProps | PreviewProps) {
  if (props.mode === "preview") return <PreviewFields />;
  const { inputRef, text, busy, error, onTextChange, onSubmit } = props;
  const empty = text.trim().length === 0;
  const inputId = "qa-feedback-text";
  const errorId = "qa-feedback-error";
  return (
    <div className="grid gap-4 px-4 pb-4">
      <div className="grid gap-2">
        <Label htmlFor={inputId}>{QA_COPY.label}</Label>
        <Input
          ref={inputRef}
          id={inputId}
          placeholder={QA_COPY.placeholder}
          value={text}
          maxLength={QA_TEXT_MAX}
          enterKeyHint="send"
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? errorId : undefined}
          onChange={(e) => onTextChange(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.nativeEvent.isComposing) {
              e.preventDefault();
              onSubmit();
            }
          }}
        />
        <div className="flex justify-between gap-2 text-sm">
          <p id={errorId} role="alert" className="text-destructive">
            {error}
          </p>
          <p className="text-muted-foreground">{QA_COPY.count([...text].length, QA_TEXT_MAX)}</p>
        </div>
      </div>
      <Button disabled={empty || busy} aria-busy={busy} onClick={onSubmit}>
        {busy ? QA_COPY.sending : empty ? QA_COPY.sendEmpty : QA_COPY.send}
      </Button>
    </div>
  );
}

/** 보기 전용 — 값 비움·읽기 전용·포커스 안 감·버튼 잠금. 바꾸는 함수·보내는 함수를 받지도 연결하지도 않는다 */
function PreviewFields() {
  const inputId = "qa-feedback-preview-text";
  return (
    <div className="grid gap-4">
      <div className="grid gap-2">
        <Label htmlFor={inputId}>{QA_COPY.label}</Label>
        <Input id={inputId} placeholder={QA_COPY.placeholder} value="" readOnly tabIndex={-1} />
        <div className="flex justify-end gap-2 text-sm">
          <p className="text-muted-foreground">{QA_COPY.count(0, QA_TEXT_MAX)}</p>
        </div>
      </div>
      <Button type="button" disabled tabIndex={-1}>
        {QA_COPY.sendEmpty}
      </Button>
    </div>
  );
}
```
