# reference.md — 그록 브리지 플래그·명령 목록

`grok-bridge.mjs`는 grok-build 플러그인이 들고 있는 파일이다. 아래 줄 번호는 확인 당시 버전(0.2.1) 기준.

경로: `~/.claude/plugins/cache/xai-grok-build/grok-build/<버전>/scripts/grok-bridge.mjs`

| 항목 | 뜻 | 검증 상태 | 출처 |
|---|---|---|---|
| `--prompt-file <경로>` | 지시서를 파일로 넘긴다. 브리지가 파일을 읽어 문자열로 그록에 전달 | [검증됨] | `grok-bridge.mjs` 592~593줄(파일을 읽어 문자열로 넘김), 738줄 valueOptions |
| 따옴표 씌운 heredoc(`<<'GROKEOF'`) 입력 | 지시서를 파이프로 흘려 넣는다. 짧고 한 번만 돌릴 것에 적합 | [검증됨] | `grok-bridge.mjs` 439줄이 piped stdin을 받음. 실사용 검증: 역따옴표·`$HOME`·따옴표가 한 글자도 안 깨지고 그대로 전달됨 |
| `--write` | 붙이면 쓰기 허용, 안 붙이면 읽기 전용 샌드박스 | [검증됨] | `grok-bridge.mjs` 455줄 `sandbox: write ? undefined : "read-only"`. 실사용 검증: 안 붙이고 한 줄 고치기 → `Operation not permitted`로 실패 / 붙이면 메인 폴더에 바로 씀 / 안 붙이고 큰 작업 → 서브 에이전트 워크트리에 씀 |
| `--background` | 뒤에서 돌린다 | [검증됨] | `grok-bridge.mjs` 739줄 booleanOptions |
| `--resume` | `--resume-last`의 별칭이고 인자를 안 받는다 | [검증됨] (한계도 실사용 확인) | `grok-bridge.mjs` 751줄 `const resumeLast = Boolean(options["resume-last"] \|\| options.resume)`. 한계 실사용 검증: 세션이 끊기면 `No previous Grok Build delegate session was found`로 죽는다 |
| `--cwd <경로>` | 작업 디렉토리 지정 | [미검증] | `grok-bridge.mjs` 738줄 valueOptions |
| `--fresh` | 새 세션으로 시작 | [미검증] | `grok-bridge.mjs` 739줄 booleanOptions |
| `--model <이름>` | 모델 지정 | [미검증] | `grok-bridge.mjs` 738줄 valueOptions |
| `--effort <값>` | 사고량(effort) 지정 | [미검증] | `grok-bridge.mjs` 738줄 valueOptions |
| `grok-build:grok-delegate` 에이전트 | 플러그인이 제공하는 위임 서브 에이전트 | [동작안함] | 600초에 잘려 결과를 못 받아옴 |

**주의** — 브리지 `--help`(81줄)에는 `--prompt-file`이 빠져 있다. 하네스가 아니라 xai-grok-build 플러그인 파일이라 여기서 고칠 수 없다. `--help`만 보고 "그런 플래그 없다"고 판단하면 안 된다.

## 셸 argv 한도 실측

명령줄 인자로 지시서를 넣지 말라는 건 **길이 때문이 아니다.**

- `getconf ARG_MAX` = 1,048,576 bytes (약 1MB)
- 실제로 쓴 지시서 중 제일 큰 것 = 18,437 bytes

한도의 2%도 안 쓴다. 문제는 길이가 아니라 셸이 역따옴표·`$변수`를 해석해 내용을 조용히 바꿔버리는 것이다.
