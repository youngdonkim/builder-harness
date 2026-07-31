#!/bin/bash
# stale-plugin-notice.sh — SessionStart hook
#
# builder-harness 플러그인이 최신이 아니면 세션이 시작될 때 한 번 알려준다.
# 알리기만 하고 갱신은 절대 자동으로 하지 않는다.
#
# 대조 방법:
#   설치된 버전 = $CLAUDE_PLUGIN_ROOT 의 마지막 폴더 이름 (12자리 커밋 번호)
#   최신 버전   = git ls-remote 로 가져온 원격 main 의 커밋 번호 (40자리)
#   설치된 값이 원격 값의 앞부분과 같으면 최신, 다르면 뒤처진 것.
#
# 조용히 넘어가는 경우 (전부 종료 코드 0, 출력 한 글자도 없음):
#   1. source 가 startup 이 아님       → /clear·compact·resume 마다 같은 알림이
#                                        반복되면 소음이라 안 띄움
#   2. stdin 이 비었거나 깨진 JSON     → 상황을 모르면 아무 말도 안 함
#   3. jq 또는 git 이 없음             → 대조할 수단 자체가 없음
#   4. CLAUDE_PLUGIN_ROOT 가 비었음    → 플러그인으로 실행된 게 아님
#   5. 마지막 폴더 이름이 12자리 이상 16진수가 아님
#                                      → unknown·1.0.0 같은 값은 커밋 번호가
#                                        아니라서 대조 불가
#   6. 원격 조회 실패 (네트워크 없음, 저장소 주소 이상 등)
#                                      → 오프라인일 때 잔소리 안 함
#   7. 최신임                          → 최신일 때는 아무것도 안 보여줌
#
# 뒤처졌을 때 안내는 두 갈래로 갈린다. 자동 갱신이 실제로 도는 환경이면 가만 둬도
# 곧 알아서 받아오니 기다리라고만 하고, 안 도는 환경이면 직접 올리라고 안내한다.
# "데스크톱 앱이냐 터미널이냐"로 가르지 않고 자동 갱신이 도는 조건 자체를 본다:
#
#   자동 갱신이 돈다 =
#       (DISABLE_AUTOUPDATER 가 비었음 OR FORCE_AUTOUPDATE_PLUGINS 가 안 비었음)
#     AND known_marketplaces.json 의 builder-harness.autoUpdate 가 true
#
#   (가) 꺼져 있음 → 직접 올리라고 두 명령을 안내
#   (나) 켜져 있음 → 10분 안에 알아서 받아온다고 안내, 계속 보이면 그때 직접
#
# 환경변수를 못 읽거나 autoUpdate 를 못 읽으면 꺼진 것(가)으로 본다.
# 안내를 안 주고 영영 뒤처지는 것보다 한 번 더 알려주는 쪽이 안전하다.
#
# 세션마다 네트워크를 치지 않도록 결과를 6시간 캐시한다.
#   위치: ${TMPDIR:-/tmp}/claude-bh-stale-check
#   내용: <확인시각(epoch)> <그때 설치돼 있던 커밋> <원격 커밋>  (한 줄)
#   설치된 커밋이 그때와 다르면 (= 사용자가 방금 갱신했으면) 캐시를 버리고 새로 확인한다.
#
# 저장소 주소는 ~/.claude/plugins/known_marketplaces.json 에서 읽는다.
# 포크해서 쓰는 사람이 있을 수 있어 하드코딩하지 않고, 못 읽으면 원본 주소로 대체한다.
#
# 제한 시간은 hooks.json 의 timeout(10초)이 건다.
# macOS 에 기본으로 없는 timeout 명령은 쓰지 않는다.

set -uo pipefail

CACHE_FILE="${TMPDIR:-/tmp}/claude-bh-stale-check"
CACHE_TTL=21600 # 6시간
FALLBACK_REPO="youngdonkim/builder-harness"
MARKETPLACES="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/known_marketplaces.json"

# 숫자로만 이뤄졌는지
is_number() {
  case "$1" in
    '' | *[!0-9]*) return 1 ;;
  esac
  return 0
}

# 커밋 번호로 볼 수 있는지 — 12자리 이상 소문자 16진수
is_commit_id() {
  case "$1" in
    '' | *[!0-9a-f]*) return 1 ;;
  esac
  [ "${#1}" -ge 12 ]
}

# owner/repo 형태이고 주소에 넣어도 안전한 글자만 쓰는지
is_safe_repo() {
  local owner name
  case "$1" in
    */*) : ;;
    *) return 1 ;;
  esac
  owner="${1%%/*}"
  name="${1#*/}"
  [ -n "$owner" ] && [ -n "$name" ] || return 1
  case "$owner" in
    *[!A-Za-z0-9._-]*) return 1 ;;
  esac
  case "$name" in
    *[!A-Za-z0-9._-]*) return 1 ;;
  esac
  return 0
}

# 자동 갱신이 실제로 도는 환경인지 — 조건 두 가지를 다 만족해야 켜진 것으로 본다
#   1) 자동 갱신기가 살아 있음: DISABLE_AUTOUPDATER 가 비었거나,
#      비어 있지 않더라도 FORCE_AUTOUPDATE_PLUGINS 로 되살렸거나
#      (두 변수는 훅 프로세스가 Claude Code 에서 그대로 물려받는다)
#   2) 이 마켓플레이스가 자동 갱신 대상임: autoUpdate 가 true
# 하나라도 확인이 안 되면 꺼진 것으로 판정한다 (안내를 주는 쪽이 안전하다)
is_autoupdate_on() {
  local auto_update
  if [ -n "${DISABLE_AUTOUPDATER:-}" ] && [ -z "${FORCE_AUTOUPDATE_PLUGINS:-}" ]; then
    return 1
  fi
  [ -r "$MARKETPLACES" ] || return 1
  auto_update=$(jq -r '.["builder-harness"].autoUpdate // false' "$MARKETPLACES" 2>/dev/null || echo "")
  [ "$auto_update" = "true" ]
}

# 대조에 필요한 도구가 없으면 조용히 종료
command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

# 1. stdin 에서 source 꺼내기 — 깨진 JSON 이어도 빈 값이 되고 그대로 종료
INPUT=$(cat)
SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null || echo "")

# 2. 세션이 처음 열릴 때만 확인한다
[ "$SOURCE" = "startup" ] || exit 0

# 3~4. 설치된 버전 구하기
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
[ -n "$PLUGIN_ROOT" ] || exit 0
INSTALLED=$(basename "$PLUGIN_ROOT" 2>/dev/null || echo "")

# 5. 커밋 번호가 아니면 대조할 수 없다
is_commit_id "$INSTALLED" || exit 0

NOW=$(date +%s 2>/dev/null || echo "")
is_number "$NOW" || NOW=""

# 6. 캐시 확인 — 유효하고 설치된 커밋이 그때와 같으면 네트워크를 건너뛴다
REMOTE=""
FROM_CACHE=0
if [ -n "$NOW" ] && [ -r "$CACHE_FILE" ]; then
  cache_time=""
  cache_installed=""
  cache_remote=""
  read -r cache_time cache_installed cache_remote <"$CACHE_FILE" 2>/dev/null || true
  if is_number "$cache_time" && [ "$cache_installed" = "$INSTALLED" ] && is_commit_id "$cache_remote"; then
    age=$((NOW - cache_time))
    if [ "$age" -ge 0 ] && [ "$age" -lt "$CACHE_TTL" ]; then
      REMOTE="$cache_remote"
      FROM_CACHE=1
    fi
  fi
fi

# 7~9. 캐시가 없으면 원격에 물어본다
if [ -z "$REMOTE" ]; then
  REPO=""
  if [ -r "$MARKETPLACES" ]; then
    REPO=$(jq -r '.["builder-harness"].source.repo // empty' "$MARKETPLACES" 2>/dev/null || echo "")
  fi
  is_safe_repo "$REPO" || REPO="$FALLBACK_REPO"

  # 자격 증명을 물어보느라 멈추지 않게 하고 (GIT_TERMINAL_PROMPT·GIT_ASKPASS),
  # 연결이 늘어져도 5초 안에 포기하게 한다 (http.lowSpeed*).
  remote_out=$(
    GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= \
      git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=5 \
      ls-remote "https://github.com/${REPO}.git" refs/heads/main 2>/dev/null || echo ""
  )
  read -r REMOTE _rest <<<"$remote_out" 2>/dev/null || true

  # 못 가져왔으면 (오프라인 등) 조용히 종료
  is_commit_id "$REMOTE" || exit 0
fi

# 결과를 캐시에 남긴다 — 실패해도 그냥 넘어간다
if [ "$FROM_CACHE" -eq 0 ] && [ -n "$NOW" ]; then
  printf '%s %s %s\n' "$NOW" "$INSTALLED" "$REMOTE" >"$CACHE_FILE" 2>/dev/null || true
fi

# 10. 앞부분이 같으면 최신 — 아무 말 없이 종료
case "$REMOTE" in
  "$INSTALLED"*) exit 0 ;;
esac

# 11. 뒤처졌다 — 사용자에게 알리고, Claude 도 옛 버전이라는 걸 알게 한다
#     자동 갱신이 도는 환경이면 기다리라고만 하고, 안 도는 환경이면 직접 올리라고 한다
REMOTE_SHORT="${REMOTE:0:12}"

if is_autoupdate_on; then
  # (나) 자동 갱신이 켜져 있다 — 가만 둬도 곧 받아온다
  SYSTEM_MESSAGE="ℹ️ builder-harness 플러그인이 최신이 아니야 (설치 ${INSTALLED} / 최신 ${REMOTE_SHORT}).
자동 갱신이 켜져 있으니 세션이 시작되고 10분 안에 알아서 받아올 거야. 받아오면
/reload-plugins 를 치라는 알림이 뜨고, 안 쳐도 다음 세션부터 적용돼.
그래도 계속 이 알림이 보이면 아래 두 명령으로 직접 올리면 돼:
  claude plugin marketplace update builder-harness
  claude plugin update builder-harness@builder-harness --scope project"

  AUTOUPDATE_NOTE="이 환경은 자동 갱신이 켜져 있어서 곧 최신 버전을 받아올 것이다."
else
  # (가) 자동 갱신이 꺼져 있다 — 직접 올리지 않으면 계속 뒤처진 채로 남는다
  SYSTEM_MESSAGE="⚠️ builder-harness 플러그인이 최신이 아니야 (설치 ${INSTALLED} / 최신 ${REMOTE_SHORT}).
이 환경은 자동 갱신이 꺼져 있어서 직접 올려야 해. 터미널에서 아래 두 명령을 순서대로 실행해:
  claude plugin marketplace update builder-harness
  claude plugin update builder-harness@builder-harness --scope project
그 뒤 이 폴더로 새 대화 세션을 열면 적용돼."

  AUTOUPDATE_NOTE="이 환경은 자동 갱신이 꺼져 있어서 사용자가 직접 올려야 한다."
fi

ADDITIONAL_CONTEXT="builder-harness 플러그인이 뒤처져 있다 (설치 ${INSTALLED}, 최신 ${REMOTE_SHORT}). 지금 로드된 스킬·에이전트·훅은 옛 버전이므로, 최신 문서와 동작이 다를 수 있다는 점을 감안해서 답하라. ${AUTOUPDATE_NOTE}"

# JSON 은 jq 로 만든다 — 줄바꿈·따옴표가 섞여도 항상 올바른 JSON 이 나온다
jq -n \
  --arg msg "$SYSTEM_MESSAGE" \
  --arg ctx "$ADDITIONAL_CONTEXT" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      systemMessage: $msg,
      additionalContext: $ctx
    }
  }' 2>/dev/null || exit 0

exit 0
