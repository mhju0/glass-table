# App Store preparation: v1.0 (2)

> **2026-09-14: preparation for user testing, not submitted.** The research-led
> revamp is under verification. User feedback, signed-device testing, current
> screenshots, App Store Connect metadata, age-rating answers and regional
> distribution requirements still need final review. The practice table depicts
> simulated betting with bb stakes, without real money or purchasable currency.

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
| Availability | Decide after current regional-rating review; not yet confirmed |
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

9개 단원, 18개 개념. 쇼다운 읽기와 팟 계산에서 시작해 팟 오즈, 아웃,
에퀴티 감각, EV, 콤보, 레인지 표기법, RFI 차트, 레인지 리드, 보드 텍스처,
히트 프리퀀시, 레인지 어드밴티지, EV 손실, 액션 리드, 디펜드 차트, 최소 방어 빈도까지.
새 개념은 언제나 천천히(단계별 풀이)로 시작하고, 복습은 간격 반복으로
자동 예약됩니다. 한 번의 복습은 최대 5개 개념을 한 문제씩 풀어요.

테이블 — 전략이 공개된 상대:

Nit · TAG · LAG · 콜링 스테이션 · 매니악 중 상대를 골라 헤즈업 한 핸드를
플레이하세요. 상대의 전략은 표로 공개되어 있고, 행동할 때마다 남은
레인지가 화면에서 좁혀집니다. 내 결정 하나하나가 bb 단위로 채점되고,
핸드가 끝나면 실제 결과와 버린 EV를 나란히 보여줍니다.

모든 문제는 "결정 → 공개 → 채점" 루프로 진행됩니다. 먼저 스스로 답을
정하고, 그다음 정확한 수치와 그 출처를 확인하세요. 추정 문제는 90% 구간을
함께 답해 그 구간에 정답이 들어온 비율과 답변 수를 확인합니다.

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

The course: 9 units, 18 concepts — from reading a showdown through pot odds,
outs, equity sense, EV, combos, range notation, opening charts, range reads,
board texture, hit frequency, range advantage, EV-loss decisions, action
reads, the defend chart and minimum defense frequency. New concepts open with a step-by-step worked
example; review is scheduled by spaced repetition. Each review session asks one question for up to five due concepts.

The table: play heads-up hands against a chosen archetype (Nit, TAG, LAG,
calling station, maniac). The opponent's strategy is a published table, its
range visibly narrows as it acts, and every decision is priced in big blinds
— with the hand summary showing net result and EV burned side by side.

Every spot runs a decide → reveal → grade loop: commit to your answer first,
then see the exact numbers and where they came from. Estimation questions
also take a 90% interval. Records show how often those intervals contained the
answer and how many responses contributed to the measurement.

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

## Age rating questionnaire (must be completed on the final build)

Use the live [Apple questionnaire](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)
and [current regional definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions).
Do not translate old age tiers into new ones or select answers to target a lower rating.
The educational purpose does not remove the table's simulated betting content.

| Question | Answer | Rationale |
|---|---|---|
| Violence (cartoon/realistic), horror, sexual content, nudity, profanity, drugs/alcohol/tobacco, medical info | None | Absent from the app |
| Simulated Gambling | **Pending final-build assessment** | The table repeatedly depicts betting. The historic M1 Infrequent/Mild answer is obsolete. |
| Real-money gambling / contests | No | Free study tool, no money in or out |
| Unrestricted web access | No | No networking at all |
| User-generated content / communication | No | None |
| In-app purchases | No | None |

**Record after answering:** actual global rating = ____; Korean regional rating
and any registration requirement = ____; approved distribution territories = ____.
Do not submit while those decisions are unresolved.

## App Privacy (nutrition label)

**Data Not Collected** — answer "No, we do not collect data from this app."
There is no automatic progress transmission, networking SDK, analytics or account.
The user can deliberately export a backup through Files or compose feedback in
their mail app. The privacy manifest declares no tracking, no collected data,
and no directly used required-reason API categories found in the source scan.
Validate the signed archive's privacy report before uploading.

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
- No demo account is needed. The course unlocks as lessons are completed;
  every drill is also available through 자유 연습 without those gates.
- Preflop grading uses declared training charts. Postflop EV uses the disclosed
  checkdown approximation. This is not a full-game solver or live-play assistant.

## Screenshots

The historical iPhone 6.9" set (1320×2868, from iPhone 17 Pro Max simulator), reused for
both locales: `docs/store-assets/ko-0[1-5]-*.png` — 오늘, 길, 테이블, a graded
reveal, 기록. **Re-captured 2026-08-07** against the current UI, replacing the
M1 set (home / outs reveal / pot-odds / stats / glossary), which was two design
generations old.

Regenerate with `GT_SIM="iPhone 17 Pro Max" tools/uisweep.sh`, then copy
`today`, `path`, `table-hand`, `drill-evloss-call` and `records` out of the
timestamped folder. The order is the pitch: what you open daily → the course
behind it → the graded hand that is the differentiator → the reveal showing
where a number came from → progress and calibration.

These are raw frames with no caption layer. If App Store Connect ends up
wanting captioned marketing shots, that is a separate pass.
