#!/bin/bash
# no-main-push.sh — PreToolUse(Bash) guard
#
# main 브랜치에 직접 push 차단. PR 워크플로 우회 방지.
#
# 차단 대상:
#   - git push to main (PR 워크플로 우회 차단)
#       - 명령어에 main이 명시된 경우 (예: git push origin main)
#       - 현재 브랜치가 main인 상태의 모든 git push (gap 봉쇄)
#
# 정밀화: shell separator(&&, ||, ;, |, &)로 sub-command 분리 후
# 각 sub-command의 첫 토큰이 git일 때만 검사.
# → commit message 등 quote 안 텍스트의 우연한 매칭 회피.
#
# 인프라 deploy CLI 차단은 본 훅 범위 밖. 일반적으로 PR 머지 후
# 인프라(Vercel·Netlify·CloudFlare Pages·GitHub Pages 등)가 자동 deploy를
# 트리거하므로, main push 차단 = deploy 우회 차단의 본질.
#
# 자세히: .claude/rules/deploy.md · docs/git-workflow.md

set -euo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# shell separator로 sub-command 분리
NORMALIZED=$(printf '%s' "$COMMAND" | sed -E 's/(&&|\|\||;|\| |&[^&])/\n/g')

block_reason=""
while IFS= read -r sub; do
  # leading/trailing 공백 제거
  sub_trimmed=$(printf '%s' "$sub" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  [ -z "$sub_trimmed" ] && continue

  # 첫 토큰
  first=$(printf '%s' "$sub_trimmed" | awk '{print $1}')

  if [ "$first" = "git" ]; then
    # main 명시 패턴
    if printf '%s' "$sub_trimmed" | grep -qE 'git +push( +[^ ]+)* +(origin +)?main([: ]|$)|git +push( +[^ ]+)* +main:main'; then
      block_reason="main-push"
      break
    fi
    # 현재 브랜치가 main인 상태의 모든 git push 차단 (gap 봉쇄)
    if printf '%s' "$sub_trimmed" | grep -qE '^git +push( |$)'; then
      current_branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
      if [ "$current_branch" = "main" ]; then
        block_reason="main-push"
        break
      fi
    fi
  fi
done <<EOF
$NORMALIZED
EOF

if [ "$block_reason" = "main-push" ]; then
  cat >&2 <<'MSG'
BLOCKED: main branch 직접 push 금지.

이유: 모든 변경은 PR 워크플로를 거쳐야 함 (CI 통과 게이트).
feature branch → push -u → PR → CI → merge 흐름 사용.

자세히: docs/git-workflow.md
MSG
  exit 2
fi

exit 0
