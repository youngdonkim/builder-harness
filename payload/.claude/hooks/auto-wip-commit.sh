#!/bin/bash
# auto-wip-commit.sh — Stop hook
#
# Claude 응답이 끝날 때마다 자동으로 변경된 파일을 wip 커밋으로 저장.
# 푸시는 안 함. main 브랜치에선 작동 안 함.
#
# Skip 조건 (안전 우선):
#   1. 현재 브랜치 = main   → PR 워크플로 강제, 자동 커밋이 main 오염 금지
#   2. merge/rebase 진행 중 → conflict marker가 wip 커밋에 섞이는 사고 방지
#   3. 변경 없음            → 빈 커밋 방지
#
# 시크릿 파일 처리 (skip이 아니라 제외):
#   커밋 전체를 포기하지 않는다 — .env 등 시크릿 패턴에 걸리는 파일만 staging에서
#   빼고 나머지는 그대로 wip 커밋한다. .gitignore 불완전 시 마지막 안전망.
#   (.env.example/.sample/.template처럼 값 없는 예시 템플릿은 예외 — 정상 커밋 대상)
#
# 커밋 메시지: wip: <last user msg 힌트> — <파일1>, <파일2> 외 N개 (+X -Y)
# 푸시: 절대 안 함 (push는 사용자 명시 지시 시에만)
#
# 힌트 추출 관련 버그 수정 (2026-07-27):
#   - cut -c가 로케일 미설정 시 바이트 단위로 잘라 한글이 깨지던 문제 → UTF-8 로케일 지정,
#     없으면 바이트 컷 후 불완전한 멀티바이트 꼬리 제거로 방어.
#   - 마지막 user 메시지가 task-notification 등 하네스 생성 블록이면 그걸 힌트로 쓰던 문제
#     → 뒤에서부터 최대 10개까지 거슬러 올라가며 진짜 사람 입력을 찾음.
#
# 작업 폴더 판별 버그 수정 (2026-07-31):
#   - CLAUDE_PROJECT_DIR만 보고 cd하던 문제. 이 변수는 세션이 시작된 폴더로 고정된
#     값이라, 세션이 그 뒤 다른 폴더로 옮겨 앉아도 안 따라온다.
#     → 세션이 실제로 앉은 폴더 기준으로 판별해야 하므로, stdin JSON의
#       cwd(세션의 현재 작업 폴더)를 최우선으로 쓰고, 없을 때만
#       CLAUDE_PROJECT_DIR → pwd 순으로 폴백.
#
# staged 파일 가드 제거 (2026-08-01):
#   "staged 파일이 있으면 사용자가 수동으로 부분 stage 해둔 것"이라는 가정이 틀렸다.
#   Claude가 도구로 실행한 git mv·git add도 똑같이 stage를 만들어서 사용자 의도와
#   구분이 안 된다. 세션 중 git mv 한 번만 써도 그 뒤로 매 턴 조용히 skip되어
#   세션이 끝날 때까지 wip 커밋이 하나도 안 쌓이는 사고가 실제로 났다.
#   → staged 파일 가드를 없애고 stage 상태와 무관하게 변경 전부를 wip 커밋에 담는다.
#     어차피 뒤에서 git add -A로 전부 staging하므로 잃는 게 없다.
#
# 시크릿 안전망 수정 (2026-08-02):
#   (가) 예외 패턴이 정확히 .env.example/.sample/.template 세 이름만 봐서
#     .env.local.example처럼 중간에 환경 이름이 끼는 흔한 형태가 의심 파일로 잡혔다.
#   (나) 의심 파일이 하나라도 있으면 exit 0으로 wip 커밋 전체를 포기하던 문제.
#     한 프로젝트에서 .env.local.example이 생긴 시점부터 매 턴 wip 커밋이 전부
#     조용히 skip되어 며칠치 작업이 미커밋으로 쌓이는 사고가 실제로 났다.
#   → 예외를 .example/.sample/.template로 "끝나는" 이름 전체로 넓히고,
#     걸린 파일만 add 뒤 staging에서 빼고 나머지는 그대로 커밋하도록 바꿨다.
#
# 슬래시 명령 힌트 살리기 (2026-08-05):
#   슬래시 명령 턴의 사용자 메시지는 <command-name>·<command-message>·<command-args>
#   태그 뭉치인데, strip_harness_tags()가 이걸 전부 하네스 산물로 보고 지워버려서
#   빈 문자열이 됐다. 그러면 호출부 루프가 "하네스 산물이네" 하고 더 뒤로 거슬러
#   올라가 그 전 턴(직전 주제)의 진짜 사람 메시지를 힌트로 집어 갔다. 그 결과
#   /simplify를 돌린 턴의 커밋 제목에 "simplify"라는 단어가 안 들어가서,
#   done-task의 simplify 게이트(직전 커밋 제목에 "simplify"가 있는지로 판정)가
#   이미 실행된 걸 못 알아보고 계속 막아 왕복이 반복되는 사고가 났다.
#   → 슬래시 명령은 쓰레기가 아니라 사용자가 실제로 친 진짜 의도이므로,
#     명령 이름(+인자)을 뽑는 extract_slash_command()를 추가하고 후보를 훑는
#     루프에서 strip_harness_tags보다 먼저 시도하도록 했다.

set -uo pipefail

# Stop hook input
INPUT=$(cat)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")

# 세션의 현재 작업 폴더 = stdin의 cwd (세션이 실제로 앉은 폴더까지 따라옴).
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

# 3. 변경 없으면 skip
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  exit 0
fi

# 4. 시크릿 패턴 검사 — staging 대상 파일 중 위험 패턴에 걸리는 파일 목록만 구한다.
#    여기서 커밋을 포기하지 않는다 — 의심 파일만 나중에(6번) staging에서 뺀다.
#    단 .example/.sample/.template로 끝나는 이름(값 없는 예시 템플릿)은 예외로 뺀다.
#    끝을 보는 이유: .env.local.example처럼 중간에 환경 이름이 끼는 형태가 흔해서
#    정확히 .env.example 등 세 이름만 보면 놓친다.
candidate_files=$(git status --porcelain | sed -E 's/^...//' | awk -F ' -> ' '{print $NF}')
suspicious=$(printf '%s\n' "$candidate_files" \
  | grep -iE '(^\.env$|/\.env$|^\.env\.|/\.env\.|\.key$|\.pem$|secret|credentials\.json$|id_rsa|id_ed25519)' \
  | grep -ivE '\.(example|sample|template)$' \
  || true)

# 5. 사람이 실제로 친 마지막 메시지에서 힌트 추출 (transcript 있을 때만)
#    - system-reminder 태그뿐 아니라 task-notification/local-command-stdout 같은
#      하네스가 만들어 낸 블록도 "type: user" 문자열 메시지로 섞여 들어온다.
#      그런 걸 힌트로 쓰면 </task-notification> 같은 쓰레기가 커밋 메시지에 박히므로
#      뒤에서부터 거슬러 올라가며 하네스 산물이 아닌 메시지를 찾는다.

# 알려진 하네스 블록 태그 제거 + 줄바꿈 공백화 + 공백 정규화.
# (제거 후에도 '<'로 시작하거나 비어 있으면 호출부에서 하네스 산물로 판단)
strip_harness_tags() {
  printf '%s' "$1" \
    | awk 'BEGIN{RS=""} {
        gsub(/<system-reminder>[^<]*<\/system-reminder>/, "");
        gsub(/<task-notification>[^<]*<\/task-notification>/, "");
        gsub(/<local-command-stdout>[^<]*<\/local-command-stdout>/, "");
        gsub(/<local-command-caveat>[^<]*<\/local-command-caveat>/, "");
        gsub(/<command-name>[^<]*<\/command-name>/, "");
        gsub(/<command-message>[^<]*<\/command-message>/, "");
        gsub(/<command-args>[^<]*<\/command-args>/, "");
        print
      }' \
    | tr '\n' ' ' \
    | sed -E 's/  +/ /g; s/^ +//; s/ +$//'
}

# 슬래시 명령 턴이면 명령 이름(+인자)을 힌트로 뽑는다. <command-message>는
# "simplify is running…" 같은 안내문일 뿐 사용자 의도가 아니므로 쓰지 않는다.
# 이름이 없으면(슬래시 명령 턴이 아니면) 빈 출력에 실패(1)를 반환한다.
extract_slash_command() {
  local flat name args
  # 메시지에 줄바꿈이 섞여 있으면 sed가 줄 단위로만 봐서 태그를 놓치므로 먼저 눕힌다.
  flat=$(printf '%s' "$1" | tr '\n' ' ')
  name=$(printf '%s' "$flat" | sed -nE 's/.*<command-name>([^<]*)<\/command-name>.*/\1/p')
  name=$(printf '%s' "$name" | sed -E 's/^ +//; s/ +$//')
  [ -z "$name" ] && return 1
  case "$name" in
    /*) ;;
    *) name="/$name" ;;
  esac
  args=$(printf '%s' "$flat" | sed -nE 's/.*<command-args>([^<]*)<\/command-args>.*/\1/p')
  args=$(printf '%s' "$args" | sed -E 's/^ +//; s/ +$//')
  if [ -n "$args" ]; then
    printf '%s %s' "$name" "$args"
  else
    printf '%s' "$name"
  fi
  return 0
}

# 최소 환경(로케일 미설정)에서도 문자 단위 컷이 되도록 시스템에 설치된 UTF-8 로케일을 하나 찾는다.
pick_utf8_locale() {
  local avail cand
  avail=$(locale -a 2>/dev/null)
  for cand in C.UTF-8 en_US.UTF-8 en_GB.UTF-8 ko_KR.UTF-8 POSIX.UTF-8; do
    printf '%s\n' "$avail" | grep -qx "$cand" && { printf '%s' "$cand"; return 0; }
  done
  return 1
}

# UTF-8 로케일을 못 찾아 바이트 단위로 자른 경우, 끝에 남은 불완전한 멀티바이트
# 시퀀스(글자가 중간에 잘린 것)를 찾아 통째로 잘라낸다 — 깨진 바이트만은 안 남기려는 최후 방어.
trim_incomplete_utf8_tail() {
  local s="$1" len i pos b ord need_len=0 start=-1 max_back=4
  len=${#s}
  [ "$len" -lt "$max_back" ] && max_back=$len
  for (( i = 0; i < max_back; i++ )); do
    pos=$(( len - 1 - i ))
    b="${s:pos:1}"
    ord=$(printf '%d' "'$b")
    if (( (ord & 0xC0) != 0x80 )); then
      start=$pos
      if (( (ord & 0x80) == 0 )); then need_len=1
      elif (( (ord & 0xE0) == 0xC0 )); then need_len=2
      elif (( (ord & 0xF0) == 0xE0 )); then need_len=3
      elif (( (ord & 0xF8) == 0xF0 )); then need_len=4
      else need_len=1
      fi
      break
    fi
  done
  if [ "$start" -ge 0 ]; then
    local have_len=$(( len - start ))
    (( have_len < need_len )) && s="${s:0:start}"
  fi
  printf '%s' "$s"
}

hint=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # JSONL을 스트림으로 읽어 type=user, content가 string인 메시지 최근 10개를
  # NUL이 아닌 구분자(RS, \x1e)로 이어 붙인다 — 메시지 내부 줄바꿈은 보존해야 해서
  # 줄 단위 tail로는 메시지 경계를 못 나눈다.
  sep=$'\x1e'
  joined=$(jq -n -j --arg sep "$sep" '
    [inputs | select(.type == "user" and (.message.content | type == "string")) | .message.content] as $all
    | ($all[-10:] // []) | join($sep)
  ' "$TRANSCRIPT_PATH" 2>/dev/null)

  raw=""
  if [ -n "$joined" ]; then
    # read는 IFS 설정과 무관하게 개행에서 한 줄을 끊어버리므로 -d ''로 그 동작을 끄고
    # \x1e만 구분자로 쓴다 — 메시지 내부의 진짜 줄바꿈이 잘리는 걸 막기 위함.
    IFS=$'\x1e' read -r -d '' -a _candidates <<< "$joined"
    # 뒤(최신)에서부터 앞으로 훑으며 하네스 산물이 아닌 첫 메시지를 찾는다.
    # 슬래시 명령 턴이면 명령 이름을 우선 힌트로 쓰고, 아니면 기존대로
    # strip_harness_tags 결과가 비어있지 않고 '<'로 시작하지 않을 때 그걸 쓴다.
    for (( idx = ${#_candidates[@]} - 1; idx >= 0; idx-- )); do
      if slash=$(extract_slash_command "${_candidates[idx]}"); then
        raw="$slash"
        break
      fi
      cleaned=$(strip_harness_tags "${_candidates[idx]}")
      if [ -n "$cleaned" ] && [[ "$cleaned" != "<"* ]]; then
        raw="$cleaned"
        break
      fi
    done
  fi

  if [ -n "$raw" ]; then
    utf8_locale=$(pick_utf8_locale 2>/dev/null || true)
    if [ -n "$utf8_locale" ]; then
      hint=$(printf '%s' "$raw" | LC_ALL="$utf8_locale" cut -c1-60)
    else
      hint=$(printf '%s' "$raw" | cut -c1-60)
      hint=$(trim_incomplete_utf8_tail "$hint")
    fi
  fi
fi

# 6. add + commit — 의심 파일만 빼고 나머지는 그대로 커밋
git add -A 2>/dev/null

# 4번에서 걸린 의심 파일만 staging에서 뺀다. 파일명에 공백이 있어도 깨지지 않게
# 한 줄씩 처리한다. git restore --staged는 새로 추가된 파일이면 추적 안 함 상태로,
# 수정된 파일이면 수정 상태로 되돌린다 — 어느 쪽이든 그 파일만 커밋에서 빠지고
# 작업 내용(워킹 트리)은 그대로 남는다.
if [ -n "$suspicious" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && git restore --staged -- "$f" 2>/dev/null
  done <<< "$suspicious"
fi

# 뺀 뒤 staging이 비었으면(의심 파일뿐이었으면) 커밋할 게 없으니 안내만 남기고 종료
if git diff --cached --quiet 2>/dev/null; then
  echo "[auto-wip] 시크릿 패턴 파일뿐이라 커밋할 변경 없음 — skip:" >&2
  printf '  %s\n' $suspicious >&2
  echo "[auto-wip] .gitignore 점검 후 수동 처리 필요" >&2
  exit 0
fi

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
  if [ -n "$suspicious" ]; then
    echo "[auto-wip] 시크릿 패턴 파일은 빼고 커밋함:" >&2
    printf '  %s\n' $suspicious >&2
    echo "[auto-wip] .gitignore 점검 후 수동 처리 필요" >&2
  fi
else
  echo "[auto-wip] 커밋 실패 (pre-commit hook 등) — 사용자 확인 필요" >&2
fi

exit 0
