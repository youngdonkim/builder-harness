---
name: done-task
description: 현재 feature 브랜치를 main에 ship. 메인 세션에서 simplify 판단 → (필요 시 /simplify) → ship-task(git-flow fork)에 위임까지 한 번에. 사용자가 "보내줘"라고 한 뒤에만 클로드가 부른다.
---

# done-task

메인 세션에서 돈다. git 작업(push·PR·머지·브랜치 정리)은 직접 하지 않고 `ship-task`에 넘긴다.
이 스킬의 몫은 딱 하나 — ship 전에 simplify를 거칠지 판단하고, 거친다면 여기서 끝내는 것.

## 호출 인자

이번 호출의 인자: **$ARGUMENTS**

비어 있으면 인자 없이 호출된 것. 자연어 의도와 ship-task 결정 지시가 담길 수 있다 — 4번에서 그대로 넘긴다.

## 절차

1. `git branch --show-current`를 돌린다. main이거나 detached HEAD면 중단하고 사용자에게 안내한다 — ship할 브랜치가 아니다.
2. **simplify 판단** — 아래 셋을 순서대로 본다.
   - a. `git diff origin/main...HEAD --stat -- src` (src 폴더가 없는 프로젝트면 코드 폴더로 대체). 비어 있으면 → 4로 (코드 변경 없음, 게이트 대상 아님).
   - b. `git log origin/main..HEAD --format=%s | grep -E '^(wip: /simplify( |$)|chore: simplify 반영$)'`. 하나라도 있으면 → 4로 (이미 검토함).
   - c. 변경이 주석·문구 한 줄처럼 자잘하면(diff --stat 기준 몇 줄 이내, 로직 없음) → 스킵으로 정하고 4로. 그 외 → 3으로.
3. Skill 도구로 `simplify`를 실행하고 나온 지적을 반영한다. 끝나면 **이 턴 안에서 직접 커밋한다** —
   `git add -A && git commit -m "wip: /simplify — <한 줄 요약>"`.
   고칠 게 없어 변경이 없으면 `git commit --allow-empty -m "wip: /simplify — 변경 없음"`.
   (이유: auto-wip-commit 훅은 턴이 끝날 때 커밋한다. 같은 턴에서 바로 ship-task를 부르면 그 시점엔 working tree가 더러워서 ship-task §1 안전 검사에 걸린다. 그리고 표식 제목 형식은 ship-task §1.5 게이트의 정규식과 맞아야 한다.)
4. Skill 도구로 `ship-task`를 호출한다. args = 이 스킬이 받은 인자 그대로 + (2-c에서 스킵했으면) "스킵".
5. ship-task가 [결정 필요]를 돌려주면 판단해 결정을 args에 담아 **ship-task를** 재호출한다 (done-task를 다시 부르지 않는다 — simplify 판단은 이미 끝났다). 사실 확인이 필요한 결정(마이그레이션 종류 등)은 지어내지 말고 사용자에게 묻는다.
6. ship-task의 완료 보고를 그대로 사용자에게 전한다.

## 안 하는 것

- git push·PR·머지를 직접 하지 않는다. 전부 ship-task 몫.
- simplify 판단을 사용자에게 묻지 않는다 — 기준(2번)대로 스스로 정한다. 사용자가 이미 ship을 승인한 뒤라서다.
- ship-task가 다시 simplify [결정 필요]를 돌려주는 일은 정상 흐름에선 없다. 돌아오면 2번 판단이 빠진 것이니 3번을 수행하고 재호출한다.
