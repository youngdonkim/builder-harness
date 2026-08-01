#!/usr/bin/env python3
"""
idea-to-mvp phase runner.
Reads planning/cycles/{cycle-label}/build/index.json, finds the next pending phase,
spawns a Claude Code session with the phase prompt, and updates status.

Usage: python3 run-phases.py <cycle-label>
Example: python3 run-phases.py prototype
"""

import itertools
import json
import os
import signal
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

from _utils import find_project_root, resolve_gh_env, is_external_error

ROOT = find_project_root()
CYCLES_DIR = ROOT / "planning" / "cycles"

KST = timezone(timedelta(hours=9))

COMMIT_MSG_TEMPLATE = "feat({cycle_label}): phase {phase_num} — {phase_name}"
RUNNER_COMMIT_MSG_TEMPLATE = "chore({cycle_label}): phase {phase_num} output + timestamps"
SPINNER_CHARS = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Exit codes
EXIT_SUCCESS = 0
EXIT_ERROR = 1
EXIT_BLOCKED = 2
EXIT_NEEDS_REVIEW = 3


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

def now_iso() -> str:
    return datetime.now(KST).strftime("%Y-%m-%dT%H:%M:%S%z")


def load_index(index_file: Path) -> dict:
    with open(index_file, "r") as f:
        return json.load(f)


def save_index(index_file: Path, data: dict):
    with open(index_file, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def find_next_phase(index: dict) -> Optional[dict]:
    for phase in index["phases"]:
        if phase["status"] == "pending":
            return phase
    return None


def get_last_actionable_phase(index: dict) -> Optional[dict]:
    """가장 최근에 in_progress·error·blocked·needs_review로 끝난 phase."""
    actionable = {"in_progress", "error", "blocked", "needs_review"}
    for phase in reversed(index["phases"]):
        if phase["status"] in actionable:
            return phase
    return None


def get_cycle_label() -> str:
    if len(sys.argv) < 2:
        print("Usage: python3 run-phases.py <cycle-label>")
        print("Example: python3 run-phases.py prototype")
        sys.exit(EXIT_ERROR)
    return sys.argv[1]


def get_build_dir(cycle_label: str) -> Path:
    cycle_dir = CYCLES_DIR / cycle_label
    if not cycle_dir.is_dir():
        print(f"ERROR: Cycle directory not found: {cycle_dir}")
        sys.exit(EXIT_ERROR)
    build_dir = cycle_dir / "build"
    if not build_dir.is_dir():
        print(f"ERROR: Build directory not found: {build_dir}")
        print(f"Hint: Build plan(6단계)부터 진행해 build/ 생성 후 실행.")
        sys.exit(EXIT_ERROR)
    return build_dir


def load_phase_prompt(build_dir: Path, phase_num: int) -> str:
    phase_file = build_dir / f"phase{phase_num}.md"
    if not phase_file.exists():
        print(f"ERROR: {phase_file} not found")
        sys.exit(EXIT_ERROR)
    return phase_file.read_text()


# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

def git_run(*args, env: Optional[dict] = None) -> subprocess.CompletedProcess:
    run_env = {**os.environ, **env} if env else None
    return subprocess.run(
        ["git", *args], cwd=str(ROOT), capture_output=True, text=True, env=run_env
    )


def git_ensure_branch(cycle_label: str):
    branch = f"feat-{cycle_label}"

    r = git_run("rev-parse", "--abbrev-ref", "HEAD")
    if r.returncode != 0:
        print(f"ERROR: git not available or not a git repo.\n{r.stderr.strip()}")
        sys.exit(EXIT_ERROR)
    current = r.stdout.strip()

    if current == branch:
        return  # already on the branch (resume)

    r = git_run("rev-parse", "--verify", branch)
    if r.returncode == 0:
        r = git_run("checkout", branch)
    else:
        r = git_run("checkout", "-b", branch)

    if r.returncode != 0:
        print(f"ERROR: Failed to checkout branch '{branch}'.")
        print(f"  {r.stderr.strip()}")
        print("Hint: stash or commit your changes first.")
        sys.exit(EXIT_ERROR)

    print(f"  Branch: {branch}")


def git_commit_planning(cycle_label: str, gh_env: dict[str, str]):
    """Commit planning/ files (cycle artifacts) before phase execution."""
    git_run("add", "planning/")

    if git_run("diff", "--cached", "--quiet").returncode == 0:
        return

    msg = f"docs({cycle_label}): cycle planning artifacts"
    r = git_run("commit", "-m", msg, env=gh_env if gh_env else None)
    if r.returncode == 0:
        print(f"  ✓ {msg}")
    else:
        print(f"  WARN: planning commit failed: {r.stderr.strip()}")


def git_commit_phase(cycle_label: str, phase_num: int, phase_name: str, gh_env: dict[str, str]) -> bool:
    """Two-step commit: Claude fallback (if needed) + runner housekeeping."""
    output_file = f"planning/cycles/{cycle_label}/build/phase{phase_num}-output.json"
    index_file = f"planning/cycles/{cycle_label}/build/index.json"

    commit_env = gh_env if gh_env else None

    # --- Step 1: Claude fallback commit (code changes Claude didn't commit) ---
    git_run("add", "-A")
    git_run("reset", "HEAD", "--", output_file)
    git_run("reset", "HEAD", "--", index_file)

    if git_run("diff", "--cached", "--quiet").returncode != 0:
        msg = COMMIT_MSG_TEMPLATE.format(
            cycle_label=cycle_label, phase_num=phase_num, phase_name=phase_name
        )
        r = git_run("commit", "-m", msg, env=commit_env)
        if r.returncode != 0:
            print(f"  WARN: fallback commit failed: {r.stderr.strip()}")

    # --- Step 2: Runner housekeeping commit (output + timestamps) ---
    git_run("add", "-A")
    if git_run("diff", "--cached", "--quiet").returncode != 0:
        msg = RUNNER_COMMIT_MSG_TEMPLATE.format(
            cycle_label=cycle_label, phase_num=phase_num
        )
        r = git_run("commit", "-m", msg, env=commit_env)
        if r.returncode != 0:
            print(f"  WARN: housekeeping commit failed: {r.stderr.strip()}")
            return False

    return True


# ---------------------------------------------------------------------------
# Spinner
# ---------------------------------------------------------------------------

class Spinner:
    def __init__(self, message: str):
        self._message = message
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._spin, daemon=True)
        self._start_time = 0.0

    def _spin(self):
        chars = itertools.cycle(SPINNER_CHARS)
        while not self._stop.is_set():
            elapsed = int(time.monotonic() - self._start_time)
            sys.stderr.write(f"\r{next(chars)} {self._message} [{elapsed}s]")
            sys.stderr.flush()
            self._stop.wait(0.1)
        sys.stderr.write("\r" + " " * (len(self._message) + 20) + "\r")
        sys.stderr.flush()

    def __enter__(self):
        self._start_time = time.monotonic()
        self._thread.start()
        return self

    def __exit__(self, *_):
        self._stop.set()
        self._thread.join()

    @property
    def elapsed(self) -> float:
        return time.monotonic() - self._start_time


# ---------------------------------------------------------------------------
# Preamble & phase execution
# ---------------------------------------------------------------------------

def build_preamble(project_name: str, cycle_label: str) -> str:
    commit_example = COMMIT_MSG_TEMPLATE.format(
        cycle_label=cycle_label, phase_num="N", phase_name="<phase-name>"
    )
    index_path = f"planning/cycles/{cycle_label}/build/index.json"
    return f"""당신은 {project_name} 프로젝트의 개발자입니다. 현재 사이클은 {cycle_label}입니다. 아래 phase의 작업을 수행하세요.

중요한 규칙:
1. 작업 전에 반드시 사이클 산출물(planning/cycles/{cycle_label}/intent.md, prd.md, architecture.md, data-model.md, design/)을 읽고 전체 설계를 이해하세요.
2. 이전 phase에서 작성된 코드를 꼼꼼히 읽고, 기존 코드와의 일관성을 유지하세요.
3. AC 검증을 직접 수행하고, 통과/실패에 따라 /{index_path}을 업데이트하세요.
4. 불필요한 파일이나 코드를 추가하지 마세요. phase에 명시된 것만 작업하세요.
5. 기존 테스트를 깨뜨리지 마세요.
6. AC 통과 후, index.json 업데이트까지 완료했다면, 모든 변경사항을 아래 형식으로 커밋하세요:
   {commit_example}
7. 작업 중 사용자 개입이 반드시 필요한 상황(API key 제공, 외부 서비스 인증, 수동 설정 등)이 발생하여 직접 해결이 불가능하다면:
   - /{index_path}의 해당 phase status를 "blocked"로 변경하세요.
   - "blocked_reason" 필드에 사유를 구체적으로 기록하세요.
   - "unblock_action" 필드에 사용자가 따라할 단계를 기록하세요.
   - 작업을 즉시 중단하세요. 해결을 시도하지 마세요.
8. AC 통과 후, phase 작업 내용에 다음 중 하나라도 해당되면 status를 "completed" 대신 "needs_review"로 변경하세요:
   - 인증·권한·암호화 코드 신규/변경
   - 외부 API 키·시크릿 신규 사용
   - DB 스키마 변경 (컬럼 추가/제거/타입 변경, 마이그레이션 파일)
   - 외부 API 호출 신규 추가 (특히 비용·사용자 데이터 외부 전송)
   - 비결정성(타임존·시스템 시간·무작위 시드) 의존
   - sudo·root·OS 권한·파일시스템 외부 영역 접근
   needs_review로 마킹할 때는 다음 필드도 기록:
   - "review_reasons": 위 카테고리 중 해당하는 것들 (배열)
   - "review_summary": 사람이 봐야 할 핵심 변경 한두 줄 요약
   - "review_files": 검토 대상 파일 경로 배열

아래는 이번 phase의 상세 내용입니다:

"""


def run_phase(build_dir: Path, phase: dict, preamble: str, gh_env: dict[str, str]) -> dict:
    phase_num = phase["phase"]
    phase_name = phase["name"]
    prompt_content = load_phase_prompt(build_dir, phase_num)

    full_prompt = preamble + prompt_content

    output_file = build_dir / f"phase{phase_num}-output.json"

    cmd = [
        "claude",
        "-p",
        "--dangerously-skip-permissions",
        "--output-format", "json",
        full_prompt,
    ]

    proc = subprocess.Popen(
        cmd,
        cwd=str(ROOT),
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env={**os.environ, **gh_env} if gh_env else None,
        start_new_session=True,
    )

    timed_out = False
    try:
        stdout, stderr = proc.communicate(timeout=3600)
        returncode = proc.returncode
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass
        try:
            stdout, stderr = proc.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            stdout, stderr = "", ""
        returncode = proc.returncode if proc.returncode is not None else -9
    finally:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass

    output_data = {
        "phase": phase_num,
        "name": phase_name,
        "exitCode": returncode,
        "stdout": stdout,
        "stderr": stderr,
        "timedOut": timed_out,
        "external": is_external_error(stdout or "", stderr or "", returncode),
    }

    with open(output_file, "w") as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    if timed_out:
        print(f"\n  WARN: Phase {phase_num} timed out after 60 minutes (process group terminated)")
    elif returncode != 0:
        if output_data["external"]:
            print(f"\n  WARN: Phase {phase_num} external error (Claude/network) — exit code {returncode}")
        else:
            print(f"\n  WARN: Claude exited with code {returncode}")
        print(f"  stderr: {(stderr or '')[:500]}")

    return output_data


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    cycle_label = get_cycle_label()
    build_dir = get_build_dir(cycle_label)
    index_file = build_dir / "index.json"

    if not index_file.exists():
        print(f"ERROR: {index_file} not found")
        sys.exit(EXIT_ERROR)

    index = load_index(index_file)
    project_name = index.get("project", "idea-to-mvp")
    total_phases = index.get("totalPhases", len(index["phases"]))
    pending_count = sum(1 for p in index["phases"] if p["status"] == "pending")
    gh_user = index.get("gh_user")
    gh_env = resolve_gh_env(gh_user)

    # --- Header ---
    print(f"\n{'='*60}")
    print(f"  idea-to-mvp Phase Runner")
    print(f"  Cycle: {cycle_label} | Phases: {total_phases} | Pending: {pending_count}")
    if gh_user:
        print(f"  GitHub: {gh_user}")
    print(f"{'='*60}")

    # --- Error / blocked / needs_review check on resume ---
    last = get_last_actionable_phase(index)
    if last and last["status"] == "error":
        external_tag = " [external]" if last.get("error_message", "").startswith("[external]") else ""
        print(f"\n  ✗ Phase {last['phase']} ({last['name']}) failed{external_tag}.")
        if "error_message" in last:
            print(f"  Error: {last['error_message']}")
        print(f"  사용자가 수정 후 status를 'pending'으로 리셋하면 재개됩니다.")
        sys.exit(EXIT_ERROR)
    if last and last["status"] == "blocked":
        print(f"\n  ⏸ Phase {last['phase']} ({last['name']}) is blocked.")
        if "blocked_reason" in last:
            print(f"  Reason: {last['blocked_reason']}")
        if "unblock_action" in last:
            print(f"  Action: {last['unblock_action']}")
        print(f"  외부 조건 해제 후 status를 'pending'으로 리셋하면 재개됩니다.")
        sys.exit(EXIT_BLOCKED)
    if last and last["status"] == "needs_review":
        print(f"\n  🔍 Phase {last['phase']} ({last['name']}) needs review.")
        if "review_summary" in last:
            print(f"  Summary: {last['review_summary']}")
        if "review_reasons" in last:
            print(f"  Reasons: {', '.join(last['review_reasons'])}")
        print(f"  사용자 검토 후 status를 'completed'로 변경하거나, 재작업이 필요하면 'pending'으로 리셋하세요.")
        sys.exit(EXIT_NEEDS_REVIEW)

    # --- Git branch + planning commit ---
    git_ensure_branch(cycle_label)
    git_commit_planning(cycle_label, gh_env)

    # --- Preamble ---
    preamble = build_preamble(project_name, cycle_label)

    # --- Timestamps ---
    if "created_at" not in index:
        index["created_at"] = now_iso()
        save_index(index_file, index)

    # --- Phase loop ---
    while True:
        index = load_index(index_file)
        phase = find_next_phase(index)

        if phase is None:
            print("\n  All phases completed!")
            break

        phase_num = phase["phase"]
        phase_name = phase["name"]
        done_count = sum(1 for p in index["phases"] if p["status"] == "completed")

        # Mark in_progress with started_at
        ts_start = now_iso()
        for p in index["phases"]:
            if p["phase"] == phase_num:
                p["status"] = "in_progress"
                if "started_at" not in p:
                    p["started_at"] = ts_start
                save_index(index_file, index)
                break

        # Run with spinner
        with Spinner(f"Phase {phase_num}/{total_phases - 1} ({done_count} done): {phase_name}") as sp:
            output_data = run_phase(build_dir, phase, preamble, gh_env)
            elapsed = int(sp.elapsed)

        # Re-read index.json to check what Claude did
        fresh_index = load_index(index_file)
        status = None
        for p in fresh_index["phases"]:
            if p["phase"] == phase_num:
                status = p.get("status", "in_progress")
                break
        status = status or "in_progress"

        ts_end = now_iso()

        # external error tag injection for error_message
        if status == "error" and output_data.get("external"):
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    msg = p.get("error_message", "")
                    if not msg.startswith("[external]"):
                        p["error_message"] = f"[external] {msg}" if msg else "[external] Claude/network error"
                    break

        if status == "error":
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    p["failed_at"] = ts_end
                    break
            save_index(index_file, fresh_index)
            external_tag = ""
            err_msg = ""
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    err_msg = p.get("error_message", "")
                    if err_msg.startswith("[external]"):
                        external_tag = " [external]"
                    break
            print(f"  ✗ Phase {phase_num}: {phase_name} failed [{elapsed}s]{external_tag}")
            if err_msg:
                print(f"    Error: {err_msg}")
            git_commit_phase(cycle_label, phase_num, phase_name, gh_env)
            sys.exit(EXIT_ERROR)

        if status == "blocked":
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    p["blocked_at"] = ts_end
                    break
            save_index(index_file, fresh_index)
            reason = ""
            unblock = ""
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    reason = p.get("blocked_reason", "unknown")
                    unblock = p.get("unblock_action", "")
                    break
            print(f"  ⏸ Phase {phase_num}: {phase_name} blocked [{elapsed}s]")
            print(f"    Reason: {reason}")
            if unblock:
                print(f"    Action: {unblock}")
            git_commit_phase(cycle_label, phase_num, phase_name, gh_env)
            sys.exit(EXIT_BLOCKED)

        if status == "needs_review":
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    p.setdefault("review_at", ts_end)
                    break
            save_index(index_file, fresh_index)
            summary = ""
            reasons = []
            files = []
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    summary = p.get("review_summary", "")
                    reasons = p.get("review_reasons", [])
                    files = p.get("review_files", [])
                    break
            print(f"  🔍 Phase {phase_num}: {phase_name} needs review [{elapsed}s]")
            if summary:
                print(f"    Summary: {summary}")
            if reasons:
                print(f"    Reasons: {', '.join(reasons)}")
            if files:
                print(f"    Files: {', '.join(files[:5])}{' …' if len(files) > 5 else ''}")
            git_commit_phase(cycle_label, phase_num, phase_name, gh_env)
            sys.exit(EXIT_NEEDS_REVIEW)

        if status == "completed":
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    p["completed_at"] = ts_end
                    break
            save_index(index_file, fresh_index)
            git_commit_phase(cycle_label, phase_num, phase_name, gh_env)
            print(f"  ✓ Phase {phase_num}: {phase_name} completed [{elapsed}s]")

        elif status == "in_progress":
            # Claude didn't update status — treat as error
            print(f"  ✗ Phase {phase_num}: {phase_name} — status still 'in_progress' after execution")
            print("    Claude did not update index.json. Marking as error.")
            for p in fresh_index["phases"]:
                if p["phase"] == phase_num:
                    p["status"] = "error"
                    p["error_message"] = "Claude did not update index.json status"
                    p["failed_at"] = ts_end
                    if output_data.get("external"):
                        p["error_message"] = "[external] " + p["error_message"]
                    break
            save_index(index_file, fresh_index)
            sys.exit(EXIT_ERROR)

    # --- All phases done ---
    index = load_index(index_file)
    index["completed_at"] = now_iso()
    save_index(index_file, index)

    # Final commit
    git_run("add", "-A")
    if git_run("diff", "--cached", "--quiet").returncode != 0:
        msg = f"chore({cycle_label}): mark cycle build completed"
        r = git_run("commit", "-m", msg, env=gh_env if gh_env else None)
        if r.returncode == 0:
            print(f"  ✓ {msg}")
        else:
            print(f"  WARN: final commit failed: {r.stderr.strip()}")

    # Push branch to remote
    branch = f"feat-{cycle_label}"
    r = git_run("push", "-u", "origin", branch)
    if r.returncode != 0:
        print(f"\n  WARN: git push failed: {r.stderr.strip()}")
        print(f"  로컬 commit은 완료. 수동으로 push 필요.")
    else:
        print(f"  ✓ Pushed to origin/{branch}")

    print(f"\n{'='*60}")
    print(f"  Cycle {cycle_label}: all phases completed!")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
