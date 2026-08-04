# App Store submission — v1.0 (1)

> **Status (2026-08-04): stale in one load-bearing place — re-review before
> resuming.** This doc was written for the M1 five-drill build and submission
> is paused for dogfood. The revamp added the 테이블: simulated betting
> gameplay with bb stakes (no real money, no purchasable currency). The
> age-rating rationale below ("no betting gameplay") therefore **no longer
> describes the app**; the Simulated Gambling answer, the review notes and
> likely the KR rating path must be reassessed (see `open-questions.md` #11 —
> counsel before the betting-table submission was always the plan). The
> screenshots are also the M1 set. Descriptive metadata (subtitle, promo,
> keywords, descriptions) has been refreshed to the current app.

Single source of truth for everything entered into App Store Connect.
Field limits: name 30, subtitle 30, keywords 100, promotional text 170,
description 4000 characters.

## App record

| Field | Value |
|---|---|
| Name (both locales) | Glass Table |
| Primary language | Korean |
| Bundle ID | com.michaelju.glasstable |
| SKU | glass-table-ios |
| Price | Free |
| Availability | All territories |
| Category | Education (primary), Games – Card (secondary) |
| Support URL | https://github.com/mhju0/glass-table |
| Privacy policy URL | https://mhju0.github.io/glass-table/privacy-policy.html |
| Copyright | 2026 Michael Ju |

## Korean (primary) metadata

**부제 (subtitle):** 레인지 · EV · 상대 읽기 훈련

**프로모션 텍스트:** 레인지와 EV로 생각하는 홀덤. 단계별 코스로 기초를 다지고,
전략이 공개된 상대와 한 핸드씩 결정을 bb로 채점받으세요.

**키워드:** 포커,홀덤,레인지,팟오즈,에퀴티,EV,아웃,MDF,포커수학,연습,훈련,차트

**설명:**

Glass Table은 노리밋 홀덤을 레인지(range)와 EV로 생각하는 법을 훈련하는
무료 학습 앱입니다.

길 — 단계별 코스:

8개 단원, 18개 개념. 쇼다운 읽기와 팟 계산에서 시작해 팟 오즈, 아웃,
에퀴티 감각, EV, 콤보, 레인지 표기법, RFI 차트, 레인지 리드, 보드 텍스처,
히트 프리퀀시, 레인지 어드밴티지, EV 손실, 액션 리드, 디펜드 차트까지.
새 개념은 언제나 천천히(단계별 풀이)로 시작하고, 복습은 간격 반복으로
자동 예약됩니다.

테이블 — 전략이 공개된 상대:

Nit · TAG · LAG · 콜링 스테이션 · 매니악 중 상대를 골라 헤즈업 한 핸드를
플레이하세요. 상대의 전략은 표로 공개되어 있고, 행동할 때마다 남은
레인지가 화면에서 좁혀집니다. 내 결정 하나하나가 bb 단위로 채점되고,
핸드가 끝나면 실제 결과와 버린 EV를 나란히 보여줍니다.

모든 문제는 "결정 → 공개 → 채점" 루프로 진행됩니다. 먼저 스스로 답을
정하고, 그다음 정확한 수치와 그 출처를 확인하세요. 추정 문제는 90% 구간을
함께 답해 과신 여부(캘리브레이션)까지 추적합니다.

이런 분을 위해 만들었습니다:
• 감이 아니라 근거로 결정하고 싶은 진지한 아마추어
• 팟 오즈와 필요 에퀴티 변환을 자동으로 만들고 싶은 분
• 이론 책·영상으로 배운 개념을 손에 익히고 싶은 분

특징:
• 완전 무료 — 광고, 인앱 결제, 계정 없음
• 완전 오프라인 — 네트워크 연결과 데이터 수집이 전혀 없음
• 진행 기록(스트릭, 정답률)은 기기에만 저장
• 한국어/영어 병기 용어집 내장

Glass Table은 학습 도구입니다. 실제 돈이 오가는 도박 기능은 없습니다.

## English (U.S.) metadata

**Subtitle:** Ranges, EV & reading opponents

**Promotional text:** Think in ranges and EV. A guided course plus hands
against opponents whose strategies are published — every decision graded in
big blinds.

**Keywords:** poker,holdem,texas,ranges,pot odds,equity,EV,outs,MDF,trainer,study,charts

**Description:**

Glass Table is a free study app that trains you to think about No-Limit
Hold'em in ranges and EV.

The course: 8 units, 18 concepts — from reading a showdown through pot odds,
outs, equity sense, EV, combos, range notation, opening charts, range reads,
board texture, hit frequency, range advantage, EV-loss decisions, action
reads and the defend chart. New concepts open with a step-by-step worked
example; review is scheduled by spaced repetition.

The table: play heads-up hands against a chosen archetype (Nit, TAG, LAG,
calling station, maniac). The opponent's strategy is a published table, its
range visibly narrows as it acts, and every decision is priced in big blinds
— with the hand summary showing net result and EV burned side by side.

Every spot runs a decide → reveal → grade loop: commit to your answer first,
then see the exact numbers and where they came from. Estimation questions
also take a 90% interval, so the app tracks whether you're overconfident —
not just whether you're right.

Built for:
• Serious-minded amateurs who want reasons, not vibes
• Players who want pot-odds-to-required-equity conversion to become automatic
• Anyone drilling the concepts they learned from books and videos

Features:
• Completely free — no ads, no in-app purchases, no account
• Fully offline — zero networking, zero data collection
• Progress (streaks, accuracy) stays on your device
• Built-in bilingual (Korean/English) glossary

Glass Table is a study tool. It contains no real-money gambling.

## Age rating questionnaire (answers of record)

Strategy per `decisions.md` §7: honest answers, study-tool build, expected
12+/KR-15 or lower on the self-rating track. (Apple's revised global
age-rating tiers read 13+/16+/18+ — if the live questionnaire shows those,
"12+" here means the lowest non-18+ tier and "17+" means 18+/top tier.)

| Question | Answer | Rationale |
|---|---|---|
| Violence (cartoon/realistic), horror, sexual content, nudity, profanity, drugs/alcohol/tobacco, medical info | None | Absent from the app |
| Simulated Gambling | **Infrequent/Mild** *(M1 answer — MUST be reassessed: the 테이블 adds simulated betting gameplay with bb stakes, no real money)* | M1 rationale ("no betting gameplay") no longer holds. Honest re-answer required; likely Frequent/Intense → higher tier. See the status banner and `open-questions.md` #11 |
| Real-money gambling / contests | No | Free study tool, no money in or out |
| Unrestricted web access | No | No networking at all |
| User-generated content / communication | No | None |
| In-app purchases | No | None |

**Record after answering:** actual computed rating = ____ (expected 12+ /
KR-15 or lower). If 17+/KR-19: STOP before submitting; trigger the
contingency in spec §4 (GRAC direct review follow-up).

## App Privacy (nutrition label)

**Data Not Collected** — answer "No, we do not collect data from this app."
True because: no networking, no analytics, no accounts; progress JSON never
leaves the device.

## Review notes (entered at submission)

Glass Table is a free educational study tool for No-Limit Hold'em poker
mathematics, aimed at Korean-speaking players (UI is Korean-first).

- No real-money gambling, no purchasable currency, and nothing to win or lose
  outside a study session. The app contains a guided curriculum of poker-math
  drills and a practice table where hands are played against rule-based
  training opponents with big-blind units used as the unit of account.
  *(M1's "no simulated betting gameplay" phrasing was removed — the practice
  table does depict betting; describe it honestly at resubmission.)*
- Fully offline: no account, no login, no in-app purchases, no ads, no data
  collection.
- No demo account is needed; all content is available on first launch.

## Screenshots

One iPhone 6.9" set (1320×2868, from iPhone 17 Pro Max simulator), reused for
both locales: `docs/store-assets/ko-0[1-5]-*.png` — home, outs reveal,
pot-odds question, stats, glossary. **Stale (M1 UI): re-capture the full set
before resuming** — the current app's 길/오늘/테이블/기록 look nothing like
these. `tools/uisweep.sh` on an iPhone 17 Pro Max simulator produces the raw
frames.
