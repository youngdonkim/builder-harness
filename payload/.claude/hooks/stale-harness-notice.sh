#!/bin/bash
# stale-harness-notice.sh — SessionStart hook
#
# 이 프로젝트에 적용된 builder-harness 파일들이 원본(SoT)보다 뒤처졌으면 알려준다.
# 알리기만 하고 갱신은 절대 자동으로 하지 않는다.
#
# 언제 도는지: SessionStart 가 걸리는 모든 순간 — 새 세션(startup) 뿐 아니라
# /clear·compact·이어하기(resume) 까지 전부. 출처를 startup 으로 좁혀 두면
# 데스크톱 앱에서 옛 대화를 이어하기로 며칠씩 쓰는 사람은 새 세션을 안 여니까
# 아무리 뒤처져도 알림을 영영 못 보는 구멍이 생긴다.
#
# 대신 같은 (적용 커밋, 원격 커밋) 조합에 대해 6시간에 한 번만 알린다 — 출처를
# 안 가리는 만큼 /clear 할 때마다 같은 말이 뜨면 잔소리가 되기 때문이다.
#
# 대조 방법:
#   적용된 버전 = 프로젝트의 .claude/harness-version 스탬프 파일의 commit= 값
#   최신 버전   = git ls-remote 로 가져온 원격 main 의 커밋 번호 (40자리)
#   적용된 값이 원격 값의 앞부분과 같으면 최신, 다르면 뒤처진 것.
#
# 스탬프 파일 형식 (project-init 이 하네스를 적용·동기화할 때 기록한다):
#   repo=youngdonkim/builder-harness
#   commit=<적용한 하네스 커밋 sha 12자리 이상>
#   date=<YYYY-MM-DD>
#
# 조용히 넘어가는 경우 (전부 종료 코드 0, 출력 한 글자도 없음):
#   1. stdin 이 비었거나 깨진 JSON     → 상황을 모르면 아무 말도 안 함
#   2. jq 또는 git 이 없음             → 대조할 수단 자체가 없음
#   3. 스탬프 파일이 없음              → 하네스가 적용된 프로젝트가 아님
#   4. commit= 값이 12자리 이상 16진수가 아님
#                                      → unknown 같은 값은 커밋 번호가 아니라
#                                        대조 불가
#   5. 원격 조회 실패 (네트워크 없음, 저장소 주소 이상 등)
#                                      → 오프라인일 때 잔소리 안 함
#   6. 최신임                          → 최신일 때는 아무것도 안 보여줌
#   7. 같은 뒤처짐을 6시간 안에 이미 알렸음
#                                      → 같은 말을 반복하지 않음
#
# 세션마다 네트워크를 치지 않도록 결과를 6시간 캐시한다. 같은 파일에 마지막으로
# 알린 시각도 같이 적어 두고, 그걸로 6시간 스로틀(throttle — 같은 알림이 너무 자주
# 뜨지 않게 간격을 두는 것)을 건다.
#   위치: ${TMPDIR:-/tmp}/claude-bh-stale-check
#   내용: <확인시각(epoch)> <그때 적용돼 있던 커밋> <원격 커밋> <마지막 알림 시각(epoch)>
#         (한 줄)
#   네 번째 칸이 없거나 숫자가 아니면 0 으로 본다 — 이 칸이 없던 옛 캐시도 그대로 읽힌다.
#   적용된 커밋이 그때와 다르면 (= 방금 동기화했으면) 캐시를 버리고 새로 확인한다.
#   원격 커밋이 달라져도 (= 그 사이 새 버전이 나왔으면) 새 뒤처짐이라 다시 알린다.
#   date +%s 를 못 얻는 비정상 환경이면 스로틀을 포기하고 알리는 쪽으로 간다 —
#   한 번 더 알리는 게 영영 못 알리는 것보다 안전하다.
#
# 저장소 주소는 스탬프 파일의 repo= 에서 읽는다. 포크해서 쓰는 사람이 있을 수
# 있어 하드코딩하지 않고, 못 읽거나 이상하면 원본 주소로 대체한다.
#
# 제한 시간은 settings-hooks.json 의 timeout(10초)이 건다.
# macOS 에 기본으로 없는 timeout 명령은 쓰지 않는다.

set -uo pipefail

CACHE_FILE="${TMPDIR:-/tmp}/claude-bh-stale-check"
CACHE_TTL=21600      # 6시간 — 원격에 다시 물어보기까지의 간격
NOTIFY_INTERVAL=21600 # 6시간 — 같은 뒤처짐을 다시 알리기까지의 간격
FALLBACK_REPO="youngdonkim/builder-harness"
STAMP_REL=".claude/harness-version"

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

# 스탬프 파일에서 key= 값 한 줄 읽기 — 앞뒤 공백과 CR 은 털어낸다
stamp_value() {
  local key="$1" line
  line=$(grep -m1 "^[[:space:]]*${key}[[:space:]]*=" "$STAMP" 2>/dev/null || echo "")
  [ -n "$line" ] || return 0
  line="${line#*=}"
  line="${line%$'\r'}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s' "$line"
}

# 캐시 한 줄 쓰기 — 확인 시각을 모르면 아예 안 쓴다. 쓰다 실패해도 그냥 넘어간다
write_cache() {
  [ -n "$CHECK_TIME" ] || return 0
  printf '%s %s %s %s\n' "$CHECK_TIME" "$INSTALLED" "$REMOTE" "$LAST_NOTIFIED" >"$CACHE_FILE" 2>/dev/null || true
}

# 대조에 필요한 도구가 없으면 조용히 종료
command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

# 1. stdin 확인 — 비었거나 깨진 JSON 이면 상황을 모르는 것이니 조용히 종료
#    source(startup·clear·compact·resume)는 보지 않는다. 어느 쪽이든 똑같이
#    확인하고, 반복 알림은 아래 스로틀이 막는다.
INPUT=$(cat)
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")

# 2. 스탬프 파일 찾기 — 세션의 현재 작업 폴더 기준.
#    CLAUDE_PROJECT_DIR 은 세션 시작 폴더에 고정된 값이라 폴백으로만 쓴다.
#    작업 폴더(워크트리)에서 열린 세션도 자기 체크아웃 안의 스탬프를 읽으면 된다.
BASE_DIR=""
for d in "$HOOK_CWD" "${CLAUDE_PROJECT_DIR:-}" "$(pwd)"; do
  if [ -n "$d" ] && [ -d "$d" ]; then
    BASE_DIR="$d"
    break
  fi
done
[ -n "$BASE_DIR" ] || exit 0

STAMP=""
if [ -r "${BASE_DIR}/${STAMP_REL}" ]; then
  STAMP="${BASE_DIR}/${STAMP_REL}"
else
  # git 저장소 최상단도 한 번 본다 (하위 폴더에서 세션을 연 경우)
  top=$(cd "$BASE_DIR" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "")
  if [ -n "$top" ] && [ -r "${top}/${STAMP_REL}" ]; then
    STAMP="${top}/${STAMP_REL}"
  fi
fi

# 3. 스탬프가 없으면 하네스가 적용된 프로젝트가 아니다 — 조용히 종료
[ -n "$STAMP" ] || exit 0

INSTALLED=$(stamp_value commit)

# 4. 커밋 번호가 아니면 대조할 수 없다
is_commit_id "$INSTALLED" || exit 0

NOW=$(date +%s 2>/dev/null || echo "")
is_number "$NOW" || NOW=""

# 5. 캐시 읽기 — 유효하고 적용된 커밋이 그때와 같으면 네트워크를 건너뛴다
#    마지막 알림 시각(네 번째 칸)은 TTL 과 상관없이 읽어둔다. 칸이 없던 옛 캐시는 0.
REMOTE=""
FROM_CACHE=0
CHECK_TIME=""
cache_time=""
cache_installed=""
cache_remote=""
cache_notified=""
if [ -r "$CACHE_FILE" ]; then
  read -r cache_time cache_installed cache_remote cache_notified <"$CACHE_FILE" 2>/dev/null || true
  if [ -n "$NOW" ] && is_number "$cache_time" && [ "$cache_installed" = "$INSTALLED" ] && is_commit_id "$cache_remote"; then
    age=$((NOW - cache_time))
    if [ "$age" -ge 0 ] && [ "$age" -lt "$CACHE_TTL" ]; then
      REMOTE="$cache_remote"
      FROM_CACHE=1
      CHECK_TIME="$cache_time"
    fi
  fi
fi
is_number "$cache_notified" || cache_notified=0

# 6~8. 캐시가 없으면 원격에 물어본다
if [ -z "$REMOTE" ]; then
  REPO=$(stamp_value repo)
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

# 이 (적용 커밋, 원격 커밋) 조합을 마지막으로 알린 시각.
# 조합이 달라졌으면 (동기화했거나 그 사이 새 버전이 나왔거나) 새 뒤처짐이라 0 부터 다시.
LAST_NOTIFIED=0
if [ "$cache_installed" = "$INSTALLED" ] && [ "$cache_remote" = "$REMOTE" ]; then
  LAST_NOTIFIED="$cache_notified"
fi

# 결과를 캐시에 남긴다 — 실패해도 그냥 넘어간다
[ -n "$CHECK_TIME" ] || CHECK_TIME="$NOW"
[ "$FROM_CACHE" -eq 1 ] || write_cache

# 9. 앞부분이 같으면 최신 — 아무 말 없이 종료
case "$REMOTE" in
  "$INSTALLED"*) exit 0 ;;
esac

# 10. 뒤처졌다 — 다만 같은 뒤처짐을 6시간 안에 이미 알렸으면 다시 말하지 않는다.
#     시계를 못 읽는 비정상 환경(NOW 가 빈 값)이면 스로틀을 포기하고 알린다.
if [ -n "$NOW" ] && [ "$LAST_NOTIFIED" -gt 0 ]; then
  since=$((NOW - LAST_NOTIFIED))
  if [ "$since" -ge 0 ] && [ "$since" -lt "$NOTIFY_INTERVAL" ]; then
    exit 0
  fi
fi
if [ -n "$NOW" ]; then
  LAST_NOTIFIED="$NOW"
  write_cache
fi

# 11. 사용자에게 알리고, Claude 도 옛 버전이라는 걸 알게 한다
REMOTE_SHORT="${REMOTE:0:12}"

SYSTEM_MESSAGE="⚠️ 이 프로젝트에 적용된 하네스가 원본보다 뒤처졌어 (적용 ${INSTALLED} / 최신 ${REMOTE_SHORT}).
하네스 로컬 저장소를 pull한 뒤 이 프로젝트에서 '하네스 동기화해줘'라고 하면 돼 — 앱 재시작은 필요 없어."

ADDITIONAL_CONTEXT="이 프로젝트에 적용된 builder-harness 파일들이 원본보다 뒤처져 있다 (적용 ${INSTALLED}, 최신 ${REMOTE_SHORT}). 지금 로드된 스킬·에이전트·훅은 옛 버전이므로, 최신 문서와 동작이 다를 수 있다는 점을 감안해서 답하라. 사용자가 원하면 하네스 로컬 저장소를 pull한 뒤 project-init 스킬의 동기화 모드로 최신화하면 된다."

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
