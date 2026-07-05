# `.claude/rules/<topic>.md` 작성 기준

`paths` 매칭 파일 read 시점에 lazy load되는 path-scoped 룰. **CLAUDE.md를 부풀리지 않고 영역별 룰 분리**가 핵심.

## 1. Frontmatter — 필수

```yaml
---
name: <topic>
description: <한 줄 — 룰의 범위와 적용 시점. 다른 세션에서 관련성 판단 근거가 됨>
paths:
  - "glob/pattern/**/*.ext"
  - "specific/file.json"
---
```

- **`name`**: 파일명과 동일(확장자 제외).
- **`description`**: 1~2줄. 룰이 다루는 것 + 언제 적용 명시. 짧고 구체적.
- **`paths`**: glob 패턴 list. **반드시 넣어라** — 없으면 매 세션 자동 로드 → 컨텍스트 낭비.

## 2. path-scoped vs 무조건 로드

| paths 필드 | 로드 시점                          | 권장                                               |
| ---------- | ---------------------------------- | -------------------------------------------------- |
| 있음       | 매칭 파일 read 시 (lazy)           | ✅ 기본                                            |
| 없음       | 매 세션 launch 시 (CLAUDE.md 동급) | ⚠️ 신중히 — "CLAUDE.md에 박는 게 낫지 않은가" 자문 |

## 3. Glob 패턴 가이드 (공식)

| 패턴                    | 매칭                    |
| ----------------------- | ----------------------- |
| `**/*.ts`               | 모든 디렉토리의 TS 파일 |
| `src/**/*`              | src/ 아래 전체          |
| `*.md`                  | 루트 markdown만         |
| `src/api/**/*.{ts,tsx}` | 확장자 alternation      |

**작성 균형**: 너무 좁으면 룰 매칭 놓침 / 너무 넓으면 노이즈. 의심되면 좁게 시작 → 사용하며 넓힘.

## 4. 내용 작성

[principles.md](principles.md) (공통 원칙)과 [§4 비유·예시 정책](principles.md#4-비유예시-정책--llm-룰엔-비유-기본-x) 그대로 적용. 핵심:

- 원칙·heuristics 먼저, 코드 예시는 default로 깔지 마.
- 표준 컨벤션·LLM이 이미 아는 패턴은 박지 마.
- 예시는 §4의 3 케이스 (specific value · non-standard pattern · ❌/✅ 대조)에만.

## 5. 변경 시 점검 ✅

- [ ] frontmatter `name`·`description`·`paths` 셋 다 있나?
- [ ] `paths`가 충분히 좁아서 lazy load 효과 있나?
- [ ] description이 다른 세션에서 관련성 판단에 충분히 구체적?
- [ ] CLAUDE.md에 박는 게 더 맞는 내용 아닌가? (매 세션 필요 → CLAUDE.md)
- [ ] 다단계 절차 아닌가? (절차면 skill)
