# QaFeedbackIntro.tsx — 첫 화면에서 한 번 뜨는 안내

- 놓을 곳: `src/components/qa-feedback/QaFeedbackIntro.tsx` (`src/` 없이 `app/`이 루트에 있는 프로젝트면 `src/`를 빼고 같은 경로)
- 방식: 두 방식 공통 (「한 번만」의 기억 키가 다르다 — 로그인 없는 방식은 늘 `anon`이라 이 기기에 한 번, 로그인 방식은 계정 id라 이 기기·이 계정에 한 번. 값은 gate.ts의 `useQaUserId()`)
- 출처: (참고 구현에 없음 — 이 하네스에서 새로 씀)
- 참고 구현에서 바꾼 점: —
- 어댑터: `copy`, `intro-mount`, `intro-ui` — 뜻과 채우는 법은 `../adapters.md`
- 손대지 않는 곳: 스위치가 켜지고 `useQaUserId()`가 값을 줄 때만(로그인 방식은 로그인일 때만) · 「한 번만」은 이 기기의 localStorage에 `useQaUserId()` 값을 넣은 키로 · 저장소를 못 읽거나 못 쓰면 안 띄움 · 어떻게 닫든(「알겠어요」·창 밖·Esc) 봤음으로 기억함 · 미리보기는 `inert`·`aria-hidden`·`pointer-events-none`·`select-none` 틀 안의 `QaFeedbackFields mode="preview"` — 보내기·캡처 코드를 import하지 않는다
- 의존: React, 디자인 시스템 부품

아래 코드 블록 안 전체를 그대로 옮긴 뒤 `[ADAPTER:…]` 자리만 이 프로젝트 것으로 바꾸고 표시 주석을 지운다. 다 깐 뒤 `grep -rn "\[ADAPTER:" src`가 0건이어야 한다.

```tsx
"use client";
/**
 * QA 피드백 — 첫 화면에서 한 번만 뜨는 안내(로그인 방식이면 가입·첫 로그인 뒤 첫 화면).
 * 화면 3번 터치는 숨은 동작이라 알려 주지 않으면 아무도 쓰지 않는다. 그래서 처음 한 번만, 실제 창을 줄여 그린 미리보기와 함께 알린다.
 *  - 첫 화면(어댑터 intro-mount)에만 둔다 — 가입 흐름(온보딩 화면)이 있으면 거기엔 두지 않아 그 도중에 끼어들지 않는다.
 *  - 스위치(QA_FEEDBACK)가 꺼졌거나 useQaUserId()가 null(로그인 방식에서 로그인 전)이면 아무것도 안 그린다.
 *  - 「한 번만」은 이 기기에만 기억한다 — localStorage, 키에 useQaUserId() 값. 로그인 없는 방식은 늘 "anon"이라 기기당 한 번,
 *    로그인 방식은 계정 id라 같은 기기의 다른 계정은 다시 본다.
 *    읽기·쓰기가 안 되는 환경(사생활 보호 창·막힌 저장소)이면 안 띄운다 — 매번 뜨는 것보다 안 뜨는 쪽이 낫다.
 *  - 「알겠어요」·창 밖 누르기·Esc 어느 쪽으로 닫아도 「봤음」으로 기억한다 — 이미 본 안내가 다시 뜨면 피드백 기능 인상이 나빠진다.
 *  - 미리보기는 보기 전용 — inert·aria-hidden·pointer-events none 틀 안에 QaFeedbackFields mode="preview".
 *    눌러도 입력·제출이 안 되고, 화면 읽기 프로그램은 읽지 않는다(같은 내용은 안내 글이 말로 전한다). 보내기·캡처 코드는 이 파일에 없다.
 */
import { useEffect, useState } from "react";
import { QA_FEEDBACK_ENABLED } from "@/lib/qa-feedback/client";
import { useQaUserId } from "@/lib/qa-feedback/gate";
import { QaFeedbackFields } from "./QaFeedbackFields";
// [ADAPTER:intro-ui] 안내를 담는 창 부품. 기본값: shadcn Dialog + Button. 프로젝트에 안내용 창(또는 아래에서 올라오는 창) 부품이 따로 있으면 그걸 쓴다
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
// [/ADAPTER:intro-ui]
// [ADAPTER:copy] 화면 문구 묶음 자리 — 키 목록은 스킬 wiring.md
import { QA_COPY } from "@/lib/copy";
// [/ADAPTER:copy]

const SEEN_PREFIX = "qa-feedback:intro-seen:";
const PROBE_KEY = "qa-feedback:intro-probe";

/** 이 계정이 이 기기에서 안내를 봤나. 저장소를 못 쓰면 「봤다」로 본다(안 띄우는 쪽) */
function seenOrUnavailable(userId: string): boolean {
  try {
    if (window.localStorage.getItem(SEEN_PREFIX + userId) === "1") return true;
    // 읽기는 되는데 쓰기가 막힌 환경이면 「알겠어요」를 기억하지 못해 매번 뜬다 — 미리 써 보고 안 되면 안 띄운다
    window.localStorage.setItem(PROBE_KEY, "1");
    window.localStorage.removeItem(PROBE_KEY);
    return false;
  } catch {
    return true;
  }
}

function rememberSeen(userId: string): void {
  try {
    window.localStorage.setItem(SEEN_PREFIX + userId, "1");
  } catch {
    // 기억하지 못해도 이번엔 닫는다
  }
}

export function QaFeedbackIntro() {
  if (!QA_FEEDBACK_ENABLED) return null;
  return <QaFeedbackIntroOn />;
}

function QaFeedbackIntroOn() {
  const userId = useQaUserId();
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!userId) {
      setOpen(false);
      return;
    }
    setOpen(!seenOrUnavailable(userId));
  }, [userId]);

  if (!userId || !open) return null;
  return (
    // [ADAPTER:intro-ui] 어떻게 닫든(「알겠어요」·창 밖·Esc) 「봤음」으로 기억한다
    <Dialog
      open
      onOpenChange={(next) => {
        if (next) return;
        rememberSeen(userId);
        setOpen(false);
      }}
    >
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{QA_COPY.introTitle}</DialogTitle>
          {/* 설명은 하나로 — 창 부품이 설명 id를 하나만 잇는다. 보이는 입구를 두지 않았으면 introEntry를 빈 글로 둔다 */}
          <DialogDescription>
            {QA_COPY.introTap}
            {QA_COPY.introEntry ? (
              <>
                <br />
                {QA_COPY.introEntry}
              </>
            ) : null}
          </DialogDescription>
        </DialogHeader>
        {/* 보기 전용 미리보기 — 입력·제출·포커스·화면 읽기 모두 막는다. data-qa-ignore: 여기서 3번 터치를 세지 않게 */}
        <div
          inert
          aria-hidden="true"
          data-qa-ignore
          className="pointer-events-none select-none rounded-lg border bg-background p-4 scale-90"
        >
          <p className="mb-1 font-medium">{QA_COPY.title}</p>
          <p className="mb-4 text-sm text-muted-foreground">{QA_COPY.help}</p>
          <QaFeedbackFields mode="preview" />
        </div>
        <DialogFooter>
          <Button
            onClick={() => {
              rememberSeen(userId);
              setOpen(false);
            }}
          >
            {QA_COPY.introOk}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
    // [/ADAPTER:intro-ui]
  );
}
```
