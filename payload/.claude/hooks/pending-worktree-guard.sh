#!/bin/bash
# pending-worktree-guard.sh — Stop hook
#
# `new-task`가 새 작업 폴더(워크트리)를 만든 뒤, 세션이 실제로 그 폴더로
# 옮겨 앉았는지 확인하는 안전망.
#
# 왜 필요한가:
#   `new-task`는 context: fork로 돌아서 워크트리를 만들 수만 있고, 세션을 그
#   폴더로 옮기는 EnterWorktree 호출은 메인 세션 몫이다. 그런데 fork 결과는
#   <local-command-stdout> 블록으로 메인 세션에 도착하고, 하네스는 그 블록에
#   "명령 출력에 반응하지 말라"는 주의문을 붙인다. 그래서 보고 안의
#   "메인 세션이 할 일"이 통째로 무시되고 세션이 메인 폴더(main)에 그대로
#   남는 일이 실제로 생겼다. 그 상태로 작업하면 변경이 main 작업 폴더에 쌓이고,
#   auto-wip-commit은 main에서 skip이라 자동 저장도 안 된다.
#
# 동작:
#   1. `new-task`가 워크트리를 만들면서 인계 표식을 남긴다 (§4-c):
#        git config --local builderharness.pendingworktree "<session_id>:<절대경로>"
#   2. 이 훅이 응답이 끝날 때마다 표식을 확인한다.
#      - 세션이 이미 그 폴더에 앉아 있으면 → 표식 지우고 통과
#      - 아직 안 옮겼으면 → exit 2로 한 번 막고, EnterWorktree를 호출하라고 알림
#      - 그 알림을 받고도(stop_hook_active=true) 여전히 안 옮겼으면 → 표식을
#        지우고 통과. 무한 반복으로 세션을 가두지 않기 위함이다
#
# 다른 세션 것을 건드리지 않는 이유:
#   표식은 저장소 공용 config에 저장돼 모든 작업 폴더가 같은 값을 본다. 그래서
#   표식에 적힌 session_id가 지금 세션과 다르면 손대지 않고 그냥 통과한다.
#   이게 없으면 세션 B가 세션 A의 새 폴더로 끌려 들어가, 한 폴더에 세션 둘이
#   앉는 상황(이 하네스가 폴더를 나눠 막으려는 바로 그 사고)이 벌어진다.
#   session_id를 못 구해 표식이 ":<경로>" 꼴로 저장됐다면 주인을 알 수 없으므로
#   막지 않고 표식만 지운다 (안전 우선 — 오작동보다 안 걸리는 쪽을 택한다).

set -uo pipefail

INPUT=$(cat)
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")

# 세션의 현재 작업 폴더 = stdin의 cwd (EnterWorktree로 옮겨 앉은 폴더까지 따라옴).
# CLAUDE_PROJECT_DIR은 세션 시작 폴더에 고정된 값이라 폴백으로만 쓴다.
PROJECT_DIR=""
for d in "$HOOK_CWD" "${CLAUDE_PROJECT_DIR:-}" "$(pwd)"; do
  if [ -n "$d" ] && [ -d "$d" ]; then
    PROJECT_DIR="$d"
    break
  fi
done
[ -n "$PROJECT_DIR" ] || exit 0
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# git repo 아니면 조용히 종료
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

MARKER_KEY="builderharness.pendingworktree"
marker=$(git config --local --get "$MARKER_KEY" 2>/dev/null || echo "")
[ -n "$marker" ] || exit 0

clear_marker() {
  git config --local --unset "$MARKER_KEY" >/dev/null 2>&1 || true
}

# "<session_id>:<절대경로>" — 경로에 :가 있을 수 있으니 첫 :에서만 자른다.
marker_session="${marker%%:*}"
marker_path="${marker#*:}"

# 주인을 모르는 표식은 막지 않고 정리만 한다
if [ -z "$marker_session" ]; then
  echo "[pending-worktree] session_id 없는 표식 — 막지 않고 정리만 함" >&2
  clear_marker
  exit 0
fi

# 다른 세션의 인계 표식이면 손대지 않는다 (지우지도 않는다 — 주인이 아직 써야 함)
if [ -n "$SESSION_ID" ] && [ "$marker_session" != "$SESSION_ID" ]; then
  exit 0
fi

# 폴더가 이미 사라졌으면 지난 표식이다
if [ -z "$marker_path" ] || [ ! -d "$marker_path" ]; then
  clear_marker
  exit 0
fi

# 심볼릭 링크·상대 표기 차이를 없앤 실제 경로로 비교 (macOS에 realpath가 없을 수 있어 cd+pwd -P 사용)
resolve() { (cd "$1" 2>/dev/null && pwd -P) || printf '%s' "$1"; }
here=$(resolve "$PROJECT_DIR")
there=$(resolve "$marker_path")

# 이미 옮겨 앉았으면 인계 완료
if [ "$here" = "$there" ]; then
  clear_marker
  exit 0
fi

# 한 번 알렸는데도 안 옮겼으면 포기하고 통과 (무한 반복 방지)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  echo "[pending-worktree] 알림 후에도 세션이 안 옮겨짐 — 표식 정리하고 통과" >&2
  clear_marker
  exit 0
fi

cat >&2 <<MSG
BLOCKED: 새 작업 폴더로 세션을 아직 안 옮겼다.

/new-task가 만든 작업 폴더:
  $there
지금 세션이 앉아 있는 폴더:
  $here

지금 바로 이걸 호출해라:
  EnterWorktree(path: "$there")

이걸 건너뛰면 앞으로의 모든 편집이 옛 폴더에 쌓이고, 메인 폴더라면
브랜치가 main이라 auto-wip-commit의 자동 저장도 걸리지 않는다.

옮기지 않는 게 맞다고 판단했다면 그 이유를 사용자에게 한 줄로 알리고 그대로 진행해라
— 이 알림은 한 번만 뜬다.
MSG
exit 2
