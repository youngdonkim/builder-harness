# CLAUDE.md 작성 기준

매 세션 시작 시 **전체 로드**되는 파일. 길수록 어드히어런스 ↓ — **최후 수단**으로 사용.

## 1. 핵심 룰 (공식 docs 직역)

- **분량 < 200줄 목표.** 길수록 어드히어런스(adherence) ↓. 안 따르기 시작하면 "파일이 비대해서 룰이 묻혔다"는 신호.
- **삭제 테스트**: 매 줄에 _"이 줄을 빼면 Claude가 실수할까?"_ — No면 즉시 삭제. (공식 best-practices)
- **구체 > 추상**: "코드 잘 작성" ❌ / "`npm test` 커밋 전 실행" ✅
- **충돌 룰 회피**. 두 룰 충돌 시 Claude가 임의 선택.

## 2. ✅ 넣을 것 vs ❌ 빼야 할 것

CLAUDE.md 한정 항목 (공통 codify ✅/❌는 [principles.md §1](principles.md#1-codify-가치-판단--박을지-말지) 참조):

| ✅ Include                                     | ❌ Exclude                |
| ---------------------------------------------- | ------------------------- |
| Claude가 못 추론하는 Bash 명령 (커스텀 script) | 상세 API 문서 (링크만)    |
| 테스트 명령·선호 runner                        | 긴 설명·튜토리얼          |
| Repo 매너 (브랜치 네이밍·PR 컨벤션)            | 파일별 코드베이스 설명    |
| 개발 환경 quirk (필요 env var 등)              | 코드 읽으면 알 수 있는 것 |

## 3. 강조 패턴

- `IMPORTANT` / `YOU MUST` emphasis → 어드히어런스 ↑. **남용 금지** (모든 게 IMPORTANT면 아무것도 IMPORTANT 아님).
- "Claude가 자꾸 룰 위배" = CLAUDE.md가 너무 길어 룰이 묻힘 → 가지 치기.

## 4. 위치·hierarchy 핵심

- CLAUDE.md는 4 위치 (사용자 전역 / 프로젝트 / 프로젝트 개인 / 모노레포 서브) 모두 **concatenate** — 덮어쓰기 X.
- 영역별 다른 룰은 **nested CLAUDE.md 대신 path-scoped `.claude/rules/`** (의도 명확).
- `@path` import는 _조직화 목적만_ — launch 시 풀 로드라 컨텍스트 절약 X. 진짜 lazy는 `.claude/rules/` paths.
- 로드 순서·`CLAUDE.local.md` worktree 동작·conflict 처리 상세 → `docs/claude-config-hierarchy.md`.

## 5. 변경 시 점검 ✅

- [ ] < 200줄?
- [ ] 매 줄 "빼도 Claude 실수할까?" 통과?
- [ ] 다른 곳(rules·skill)으로 옮길 수 있는 절차·도메인 정보 없나?
- [ ] 충돌·중복 없나? (특히 nested CLAUDE.md vs 상위 CLAUDE.md)
- [ ] 새 항목이 진짜 "매 세션 필요"한가? (No면 rules로)
- [ ] 개인용·로컬용이면 `CLAUDE.local.md`에 넣고 `.gitignore` 체크?
