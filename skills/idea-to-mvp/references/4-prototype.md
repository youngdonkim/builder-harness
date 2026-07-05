---
name: 4-prototype
description: 프로토타입 완성하기 단계 가이드. 3단계에서 확정한 screen-design + market-research 최종 서비스 기획 요약 내용 + **두 전문가 렌즈(경험·사용성)**를 Claude Design에 *처음부터* 입력 → **zip 핸드오프 패키지**(reference HTML + README 설계도 + 디자인 토큰 + 컴포넌트 소스)를 받아 옴 → Claude Code(여기)는 zip 받아 저장 + 사용자 테스트 준비 + 자산·예외만 보정. zip 전체는 다음 MvpBuild(6단계) 빌드의 입력. idea-to-mvp SKILL.md §2의 4번 단계.
---

이 단계는 **사용자가 Claude Design으로 고품질 프로토타입을 만들어 오게 *안내*하고, 받은 zip 핸드오프 패키지를 저장해 *사용자 테스트로 검증*하는 단계**다. 빌드·디자인 수정은 **Claude Design**(외부 도구)이 SoT — 디자인을 픽셀·컴포넌트 단위로 이해·수정하는 건 Claude Design이 가장 잘한다. Claude Code(여기)는 *안내·수령·테스트 준비·자산 예외*만 한다.

**핵심 분업** — Claude Design = *주방*(요리를 다 함), Claude Code(여기) = *냉장고+검수대*(받아 보관·시연, 자산 예외만 손봄):
- **Claude Design** = 디자인·화면·동작을 *완성*해 zip 패키지로 내보냄. 큰 수정도 여기서 (재호출 → 새 zip).
- **Claude Code(여기)** = zip 받아 압축 해제 → 사용자 테스트 준비 + *자산·예외 미세 보정*(거의 없음) + zip 전체를 *MvpBuild(6단계)로 넘김*.

**디자인 품질은 *사후 점검*이 아니라 *설계 입력*으로 확보한다.** §2.1의 **두 전문가 렌즈**(Accenture Song 경험 전략 · Apple Senior UX Researcher 사용성)를 Claude Design 호출 *프롬프트에 처음부터* 넣어 그 렌즈로 디자인하게 한다 — 다 만든 뒤 까는 것보다 산출 품질이 높다.

## 1. 단계 목표

- **완성 프로토타입 = Claude Design이 내보낸 zip 패키지** (현재 ver 폴더 `prototype-ver-{N}/`에 압축 해제). 패키지 안에는 보통:
  - **reference HTML** (예: `reference/{service}.html` — *파일명은 가변*, README가 진입 파일을 지정) — 브라우저로 더블클릭하면 그대로 도는 *작동 데모이자 시각 정답지*. (React·Babel을 브라우저 안에서 실행 — 외부 의존·빌드 없이 열림.)
  - **README** — 화면·레이아웃·토큰·동작을 글로 정밀 기술한 *설계도* (+ 대상 환경 이식 가이드·TDS 같은 디자인 시스템 매핑 방향). **MVP 빌드의 핵심 입력.**
  - **`src/tokens/*.css`, `styles.css`** — 디자인 토큰 (색·타이포·간격·radius). MVP에서 그대로 이식.
  - **`src/components/`** — 컴포넌트 소스(.jsx 등) + 타입. MVP 빌드용 참고 구현.
  - **`design-system.html`** — *있을 수도, 없을 수도* 있다. 있으면 시각 정답지 보조로 참조.
- **첫 ver**: 사용자가 외부 Claude Design에서 §2.1 input 3개(screen-design + market-research 요약 + 두 렌즈 블록)로 호출 → **zip 다운로드** → Claude Code(여기)로 가져옴.
- **이후 ver-N**: 큰 방향을 바꿀 때만 Claude Design 재호출(새 zip). 자잘한 예외 보정은 현재 ver 폴더 reference HTML에서 in-place (거의 없음).
- **프로토타입은 사용자 테스트용** — 출시 코드가 아니다. 본격 빌드는 다음 MvpBuild(6단계)에서 *이 zip을 입력으로* 진행.

**SoT 책임**: SKILL.md §2.1 SoT 매트릭스에 따라 prototype이 SoT인 영역:
- 시각 디자인·layout·컴포넌트·완성 프로토타입 화면 + 디자인 토큰·룰 — `prototype-ver-{N}/` zip 패키지 (진입점 = reference HTML, 설계도 = README, 토큰 = `src/tokens/`)
- **ver-1이 생기는 순간부터 상태(빈·로딩·에러)·전환 명세까지 화면 영역 전체의 SoT가 이 zip으로 승격**된다 (SKILL.md §2.3 "화면 SoT의 코드 승격"). `screen-design.md`는 ver-1의 *입력*이었을 뿐 — 이후 화면이 바뀌면 `screen-design.md`를 고치는 게 아니라 §2.2대로 코드(새 ver 또는 in-place)로 반영하고, 아이디어·가설이 바뀐 부분만 `proto-retro.md` 진입 스냅샷에 새로 적는다.

## 2. 진행 절차

### 2.1 ver-1 — Claude Design 호출 input 준비 + zip 받아 저장

> **이 단계 진입 전**: 사용자가 **외부** [Claude Design](https://support.claude.com/en/articles/14604416-get-started-with-claude-design)에서 호출·디자인 생성·zip 다운로드까지 처리해 옴. Claude Code(여기)는 *호출에 관여하지 않는다*. 이 단계는 **zip 받아 온 뒤**부터 시작하지만, 호출 *전*에 input 3개를 준비해 안내한다.

**외부 Claude Design에 들고 갈 input — 3개** (사용자가 진입 *전*에 준비):

1. `planning/mvp/screen-design.md` — **단일 SoT**. 전 화면 명세(진입·내용·행동·전환·상태·데이터)·플로우·핵심 시나리오 + *검증화면에서 다듬은 최종 카피까지 통합된 상태* (3-screen-design.md §3.1.1 sync 절차). Claude Design 메인 입력 — 명세한 화면을 그대로 디자인, 카피는 그대로 사용.
2. **최신 진입 스냅샷** — 최종 아이디어·비목표·검증 가설·북극성 (무엇·왜·누구·스코프·톤). `screen-design.md` 머리 스냅샷이 원문이거나, `변경 없음`이면 `planning/mvp/market-research.md` §최종 서비스 기획 요약 내용 (SKILL.md §2.3).
3. **두 전문가 렌즈 블록** (아래 §2.1.1 — 복붙). *처음부터* 이 렌즈로 디자인하라는 설계 원칙.

디자인 시스템·토큰은 Claude Design이 위 input에서 *스스로 생성*해 zip에 담는다 — 별도 brand 입력 없음.

> **🔁 검증화면(`wireframes/`)은 input으로 들고 가지 않는다**. 검증화면은 *3단계(ScreenDesign) 안 작업 비계*. 핸드오프 직전에 검증화면 카피가 `screen-design.md`로 일괄 sync되어 `screen-design.md` 자체가 *시각 단서 0 + 최신 카피 보존*된 단일 텍스트 SoT가 된다 (3-screen-design.md §2.5 와이어프레임 가드와 같은 메커니즘).

#### 2.1.1 두 전문가 렌즈 — Claude Design 프롬프트에 복붙

> *사후 점검이 아니라 설계 원칙으로 넣는다.* Claude Design 프롬프트 끝에 "아래 두 전문가 렌즈로 화면을 설계하라"고 붙이고 두 표를 그대로 전달. 프로젝트 무관 baseline(Layer 1)이라 다른 프로젝트에도 그대로 빌려 쓴다 — "예" 칸만 그 프로젝트 것으로 바꾼다.

**렌즈 1 — Accenture Song (경험·전략)**
> 최적화 대상: 거래가 아니라 *사람의 순간과 감정*. "기능 많은 화면"이 아니라 "한 사람이 가장 불안한 순간을 통과하게".

| 원칙 | 디자인 지시 | 예 (집내비) |
| --- | --- | --- |
| 페르소나 한 명 | 인구통계("20~30대") 말고 *가장 불안한 한 명의 순간*을 위해 설계 | 첫 자취 '지오' — 역량 0·불안 100 |
| 메타포 일관 | 제품이 내비면 *다음 한 걸음*만. 전체 지도·단계 나열 금지 | 12단계 나열 X, "지금 할 1개"만 크게 |
| Hero moment <60초 | 첫 세션에 *손에 잡히는 가치* 하나 즉시 | "30초 호구 체크" or "오늘 할 일 1개" |
| 복리 hook | 첫 세션에 "어, 이거 몰랐네" 하나 심기 → 재방문 씨앗 | 월세 세액공제·확정일자 같은 잠재가치 |
| 톤 | 친구·주치의. 진단서·전문용어 금지(불가피하면 즉시 풀이) | "혼자 헤매지 마" |

**렌즈 2 — Apple Senior UX Researcher (사용성·인터랙션)**
> 최적화 대상: *생각하게 만들지 마라(self-evident)*. 명료함 > 기능. 설명서 없이 첫 사용자가 통과.

| 원칙 | 디자인 지시 | 예 (집내비) |
| --- | --- | --- |
| 화면당 주행동 1개 | 가장 중요한 게 가장 크고 먼저. 나머지는 뒤로 | "다음 할 일" 1개 + 전체경로는 접기 |
| 점진적 노출 | 한 번에 다 보여주지 말고 *필요한 순간에* (렌즈1 메타포와 상호보강) | 단계는 도달했을 때 펼쳐짐 |
| 모든 상태 설계 | 빈·로딩·에러·성공 화면까지 — 빈 화면 방치 금지 | "후보 없어"도 안내 카드로 |
| 즉각 피드백 | 모든 탭·입력에 눈에 보이는 반응 | 저장됨 ✓·링크 저장됨 |
| Deference | 장식·chrome 최소, 정보가 주인공 | — |
| 물리 제약 | 엄지 도달 영역 + 터치타깃 ≥44pt | 하단 주행동 버튼 |
| 접근성 | 명도대비 확보 + *색에만 의존하는 신호 금지*(색맹) + 큰 글자 대응 | 위험을 빨강"만" 표시 X — 아이콘·텍스트 병행 |

**Claude Code(여기)에서 하는 일**:
1. 사용자가 받아 온 **zip**을 `planning/mvp/prototype-ver-1/` 폴더에 **압축 해제** (zip 내부 구조를 그대로 유지).
2. README를 읽어 **진입 reference HTML 파일명**을 확인 (파일명 가변 — 서비스명일 수도, `Prototype.html`일 수도).
3. 사용자가 브라우저로 그 reference HTML을 **더블클릭으로 열어** 시각·플로우 **직접 클릭 검증** (서버·빌드 불필요).
4. 피드백 받아 — 큰 변경이면 §2.2-A(Claude Design 재호출), 자잘한 예외면 §2.2-B(in-place 보정).

**프로토타입 정밀도 가드** — Claude Design 산출물을 *프로토타입 수준*으로 둔다 (최종 시각·코드 lock은 MVP에서):
- screen-design 화면 명세의 데이터 필드 + 최종 서비스 기획 요약 내용 첫 베타 케이스로 placeholder 데이터 고정
- 다크모드·다국어·반응형 디테일은 프로토타입 범위 밖
- 목적은 *플로우·구성 + 첫인상 검증*이지 *최종 시각·코드 결정*이 아님

### 2.2 수정이 필요할 때 — 대부분 Claude Design, 예외만 여기서

Claude Design이 디자인을 SoT로 완성하므로 **여기서 다듬을 일은 거의 없다.** 수정이 필요하면:

| 변경 종류 | 처리 |
|---|---|
| **A. 구조·디자인·동작 변경** (layout·컴포넌트·플로우·큰 수정·렌즈 미반영분) | **Claude Design 재호출** → 새 zip 받아 `prototype-ver-{N}/`에 압축 해제 (새 ver). *기본 경로.* |
| **B. 예외 미세 보정** (Claude Design이 못 하는 자잘한 것 — 특정 이미지 교체·자산 삽입) | 현재 ver 폴더 reference HTML에서 **in-place 편집**. 거의 없음. |

**SoT 판정**: 가장 큰 N의 `prototype-ver-{N}/` 폴더가 현재 SoT. 진입점은 그 안 reference HTML, 설계도는 README. 이전 ver 폴더는 history.

#### 🔧 예외 보정 시 — reference HTML 직접 편집 (최소만)

reference HTML(= Claude Design standalone)은 **React + Babel을 브라우저에서 런타임 컴파일하는 번들**이다. *자산 삽입 같은 예외*만 손대고, 디자인·구조 변경은 §2.2-A로 보낸다. 실전 요령:

- **요소 찾기**: 개발자도구 XPath는 안 통한다(JS가 런타임에 그림). **컴포넌트명·화면 카피·`className`으로 텍스트 검색**해 편집. 코드는 minify 안 됨.
- **이스케이프**: 코드가 JS 문자열로 들어가 `</`·`"`가 escape되어 보일 수 있음. 삽입 코드는 **작은따옴표만** 써서 충돌 회피.
- **자산 삽입**: 투명 webp 등은 **base64 인라인** (reference HTML 자급자족 유지 — 외부 파일 참조 X). 색으로 안 떼지는 배경은 rembg(Python 배경 제거 라이브러리) 같은 도구로 처리.
- **검증**: **사용자가 직접 브라우저로 연다** (`open <file>`). Claude는 자동 도구로 *검증·사인오프* 하지 않는다 (CLAUDE.md 검증 룰). 단 디자인 *리뷰*가 필요하면 렌즈는 §2.1.1대로 Claude Design 호출에 *처음부터* 넣는 게 정석 — 사후 리뷰 루프를 여기서 돌리지 않는다.

**왜 예외만 손보나** — 프로토타입은 *사용자 테스트용*이고 Claude Design이 디자인을 SoT로 완성한다. 여기서 코드를 크게 고치면 (1) 사용자 테스트 데이터가 *복제 품질*에 오염되고 (2) 어차피 MVP에서 새로 빌드하니 *버려지는 중간물*이 된다. 큰 변경은 Claude Design 재호출이 깔끔하다.

## 3. 완료 체크리스트

다음이 모두 충족되어야 다음 단계(Retro)로 진입.

- [ ] **현재 SoT ver 폴더**(`prototype-ver-{N}/`)에 zip 패키지가 압축 해제돼 있음:
  - [ ] **reference HTML** — 브라우저로 더블클릭하면 외부 의존 없이 열려 작동 (진입 파일은 README가 지정, 파일명 가변)
  - [ ] **README** — 설계도 (MVP 빌드 입력)
  - [ ] **`src/tokens/`·컴포넌트 소스** — MVP 빌드용 (zip에 포함된 대로)
- [ ] **screen-design 전 화면 명세가 화면으로 구현됨** — 명세한 화면 누락 0, 각 화면의 상태·전환이 시각화됨. 시나리오↔화면 추적 가능.
- [ ] **두 렌즈가 반영됨** — Claude Design 호출에 §2.1.1 렌즈를 넣었고, 결과 화면이 렌즈 원칙(주행동 1개·점진 노출·hero moment·접근성 등)을 위배하지 않음. 위배 시 §2.2-A 재호출.
- [ ] (사용자 검증) 사람이 브라우저로 reference HTML을 클릭하며 검토 완료.

체크리스트 미충족 시 SKILL.md §4 단계 진입 평가 정책에 따라 사용자에게 선택지 제시.

## 4. 산출물 스펙

위치: `planning/mvp/prototype-ver-{N}/` (버전별 폴더, 단일 `prototype.md` 파일 없음). Claude Design zip을 **압축 해제한 구조 그대로** 보관.

```
planning/mvp/
├── market-research.md
├── screen-design.md
├── wireframes/                    ← 3단계(ScreenDesign) 검증 화면 (와이어프레임 비계)
├── prototype-ver-1/              ← 첫 zip 패키지 압축 해제
│   ├── README(.md)               ← 설계도 (화면·토큰·동작 + 이식·TDS 매핑) — MVP 입력
│   ├── reference/{service}.html  ← 진입 데모·정답지 (파일명 가변 — README가 지정)
│   ├── design-system.html        ← (있을 수도 / 없을 수도) 시각 정답지 보조
│   ├── src/tokens/*.css, styles.css
│   ├── src/components/           ← 컴포넌트 소스(.jsx) + 타입
│   └── ...(zip에 담긴 나머지)
├── prototype-ver-2/             ← 다시 받은 버전 (Claude Design 재호출 시)
│   └── ...
├── prototype-ver-N/             ← 현재 SoT (가장 큰 N)
│   └── ...
└── proto-retro.md
```

**파일 명명 / 구조 원칙**:
- **zip 내부 구조·파일명을 그대로 유지** — Claude Design이 정한 대로. 진입 reference HTML 파일명은 *가변*이니 하드코딩하지 말고 **README로 진입 파일을 확인**한다.
- `design-system.html`은 zip에 **있을 수도 없을 수도** 있다 — 있으면 시각 정답지 보조로 쓰고, 없으면 reference HTML + README + `src/tokens/`가 그 역할.

## 5. MvpBuild(6단계)로의 핸드오프

이 zip 패키지가 **다음 MvpBuild(6단계) 빌드의 핵심 입력**이다. README(설계도) + reference HTML(정답지) + `src/tokens/`(토큰) + `src/components/`(참고 구현)이 다 들어 있어, MVP에서 *어떤 환경*(plain HTML/CSS/JS · Next.js/Vite · Vue · SwiftUI · 토스 TDS 등)으로도 정확히 구현할 수 있다 — README가 설계도, reference HTML이 픽셀 정답지.

ProtoRetro(통과 기준③)의 go/no-go 판정으로 이어진다: go면 같은 스킬의 6단계 MvpBuild가 이 `prototype-ver-{N}/` 패키지를 base로 실서비스 빌드(스택 결정·이식 방식은 6-mvp-build.md §2.2), no-go(다른 아이디어)면 새 프로젝트에서 처음부터.

## 6. 사용자 응대 톤 + 코칭

- **톤**: SKILL.md §1.3대로 반말·친근·짧게.
- **ver-1 진입 안내 (호출 *전*)**: "Claude Design 호출할 때 세 개 넣어 — `screen-design.md`, `market-research.md`의 최종 서비스 기획 요약, 그리고 §2.1.1 *두 전문가 렌즈 블록*. 렌즈는 *처음부터* 넣어야 디자인이 그 기준으로 나와 — 다 만든 뒤 고치는 것보다 훨씬 잘 나옴."
- **ver-1 진입 안내 (호출 *후*)**: "zip 받아 왔지? `prototype-ver-1/`에 풀게 — README 보고 진입 화면(reference HTML) 찾아서, 브라우저로 더블클릭해서 클릭해보고 피드백 줘."
- **이 단계의 목적 짚기**: 사용자가 "여기서 막 고치자" 하면 — "디자인 수정은 Claude Design이 제일 잘해. 여기선 *사용자한테 보여주고 반응 보는 게* 일이야. 큰 수정·디자인 변경은 Claude Design 재호출이 깔끔하고, 진짜 코드는 6단계(실서비스 빌드)에서 이 zip 보고 새로 지어."
- **렌즈 미반영 발견 시**: "이 화면 주행동이 여러 개라 첫 사용자가 헤매겠어 — 렌즈 위배야. Claude Design에 '주행동 1개·나머지 접기'로 다시 요청하자 (§2.2-A)."
- **수정 분기 안내**: 큰 변경/디자인 → "Claude Design 재호출이 깔끔해 — 새 zip 받아 오면 `prototype-ver-{N+1}/`로 풀게" / 자잘한 자산 예외 → "이건 reference HTML에서 바로 손볼게 (§2.2 편집 가이드대로)".
- **검증 화면과 헷갈리지 않게**: "아까 화면 설계 단계(3단계)에서 화면 만들었잖아?" 하면 — "그건 동선 맞나 보려고 와이어프레임으로 짠 비계고, 이번엔 Claude Design이 디자인까지 입혀 완성한 zip을 받아 와 사용자 테스트하는 거야."
- **사용자 검증 안내**: "브라우저로 열어서 클릭해보고 피드백 줘. 내가 Playwright 같은 자동 도구로 *검증·사인오프* 안 함" — `CLAUDE.md` "검증" 룰 따름.
