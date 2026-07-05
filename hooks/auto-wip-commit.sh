#!/bin/bash
# auto-wip-commit.sh — Stop hook
#
# Claude 응답이 끝날 때마다 자동으로 변경된 파일을 wip 커밋으로 저장.
# 푸시는 안 함. main 브랜치에선 작동 안 함.
#
# Skip 조건 (안전 우선):
#   1. 현재 브랜치 = main           → PR 워크플로 강제, 자동 커밋이 main 오염 금지
#   2. merge/rebase 진행 중         → conflict marker가 wip 커밋에 섞이는 사고 방지
#   3. 이미 staged 파일 존재        → 사용자 수동 작업(부분 stage 등) 의도 보호
#   4. 변경 없음                    → 빈 커밋 방지
#   5. 시크릿 패턴 파일 staging 대상 → .gitignore 불완전 시 마지막 안전망
#
# 커밋 메시지: wip: <last user msg 힌트> — <파일1>, <파일2> 외 N개 (+X -Y)
# 푸시: 절대 안 함 (push는 사용자 명시 지시 시에만)
#
# 자세히: .claude/rules/deploy.md

set -uo pipefail

# Stop hook input
INPUT=$(cat)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# git repo 아니면 조용히 종료
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# 1. main branch 가드
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$current_branch" = "main" ] || [ -z "$current_branch" ]; then
  echo "[auto-wip] main branch 또는 detached HEAD — skip" >&2
  exit 0
fi

# 2. merge/rebase 진행 중 가드
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || echo ".git")
if [ -f "$GIT_DIR/MERGE_HEAD" ] || [ -f "$GIT_DIR/REBASE_HEAD" ] \
   || [ -d "$GIT_DIR/rebase-merge" ] || [ -d "$GIT_DIR/rebase-apply" ] \
   || [ -f "$GIT_DIR/CHERRY_PICK_HEAD" ]; then
  echo "[auto-wip] merge/rebase/cherry-pick 진행 중 — skip" >&2
  exit 0
fi

# 3. staged 파일 가드 (사용자 수동 stage 의도 보호)
if [ -n "$(git diff --cached --name-only 2>/dev/null)" ]; then
  echo "[auto-wip] staged 파일 감지 — skip (사용자 수동 커밋 의도 보호)" >&2
  exit 0
fi

# 4. 변경 없으면 skip
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  exit 0
fi

# 5. 시크릿 패턴 검사 — staging 대상 파일에 위험 패턴 있으면 abort
candidate_files=$(git status --porcelain | sed -E 's/^...//' | awk -F ' -> ' '{print $NF}')
suspicious=$(printf '%s\n' "$candidate_files" | grep -iE '(^\.env$|/\.env$|^\.env\.|/\.env\.|\.key$|\.pem$|secret|credentials\.json$|id_rsa|id_ed25519)' || true)
if [ -n "$suspicious" ]; then
  echo "[auto-wip] 시크릿 패턴 파일 감지 — skip:" >&2
  printf '  %s\n' $suspicious >&2
  echo "[auto-wip] .gitignore 점검 후 수동 처리 필요" >&2
  exit 0
fi

# 6. 마지막 user 메시지에서 힌트 추출 (transcript 있을 때만)
hint=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # JSONL — type=user, content가 string인 메시지의 마지막 것
  raw=$(jq -r 'select(.type == "user" and (.message.content | type == "string")) | .message.content' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1)
  if [ -n "$raw" ]; then
    # system-reminder 태그 블록 제거 + 줄바꿈 공백화 + 공백 정규화 + 60자 컷
    hint=$(printf '%s' "$raw" \
      | awk 'BEGIN{RS=""} {gsub(/<system-reminder>[^<]*<\/system-reminder>/, ""); print}' \
      | tr '\n' ' ' \
      | sed -E 's/  +/ /g; s/^ +//; s/ +$//' \
      | cut -c1-60)
  fi
fi

# 7. add + commit
git add -A 2>/dev/null

# 변경 통계
stat_line=$(git diff --cached --shortstat 2>/dev/null | sed -E 's/^ +//; s/ +$//')

# 대표 파일 3개 (basename)
file_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
file_list=$(git diff --cached --name-only 2>/dev/null | head -3 | awk -F/ '{print $NF}' | paste -sd ', ' -)
extra=""
if [ "$file_count" -gt 3 ]; then
  extra=" 외 $((file_count - 3))개"
fi

# 메시지 조립
if [ -n "$hint" ]; then
  msg="wip: ${hint} — ${file_list}${extra} (${stat_line})"
else
  msg="wip: ${file_list}${extra} (${stat_line})"
fi

# 커밋 (실패해도 Claude는 막지 않음 — exit 0)
if git commit -m "$msg" >/dev/null 2>&1; then
  echo "[auto-wip] 커밋: $msg" >&2
else
  echo "[auto-wip] 커밋 실패 (pre-commit hook 등) — 사용자 확인 필요" >&2
fi

exit 0
