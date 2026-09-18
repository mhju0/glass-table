# App Store preparation: v1.0 (2)

> **2026-09-18: preparation for user testing, not submitted.** The benchmark
> refinements passed the full app/UI suite and unsigned device Release bundle
> checks. See [delivery evidence](specs/2026-09-18-benchmark-delivery.md). User
> feedback, signed-device testing, current store screenshots, App Store Connect
> metadata, age-rating answers and regional requirements remain release gates. The practice table depicts
> simulated betting with bb stakes, without real money or purchasable currency.

Single source of truth for everything entered into App Store Connect.
Field limits: name 30, subtitle 30, keywords 100, promotional text 170,
description 4000 characters.

## App record

| Field | Value |
|---|---|
| Name (Korean) | 포커 배우기 — Glass Table |
| Name (English metadata) | Poker Lessons — Glass Table |
| Primary language | Korean |
| Bundle ID | com.michaelju.glasstable |
| SKU | glass-table-ios |
| Price | Free |
| Availability | US and Korea prioritized; final territories pending regional-rating review |
| Category | Education (primary), Games – Card (secondary) |
| Support URL | https://github.com/mhju0/glass-table |
| Privacy policy URL | https://mhju0.github.io/glass-table/privacy-policy.html |
| Copyright | 2026 Michael Ju |

## Korean (primary) metadata

**부제 (subtitle):** 홀덤 기초부터 확률과 판단 연습까지

**프로모션 텍스트:** 카드를 읽고, 직접 답을 고르고, 이유를 확인해요. 홀덤 기초부터 확률과 레인지까지 한 단계씩 연습하세요.

**키워드 초안:** 홀덤,레인지,팟오즈,에퀴티,EV,아웃,MDF,수학,연습,훈련,차트

업로드 전에 실제 키워드 필드의 바이트 제한과 중복을 확인하세요.

**설명:**

포커 배우기 — Glass Table은 홀덤의 규칙과 판단을 연습하는 한국어 학습 앱입니다.
카드를 읽는 기초부터 확률, 레인지, 콜과 폴드의 근거까지 차근차근 배워요.

한 단계씩 배우기

9개 단원에서 18개 개념을 다뤄요. 새 개념은 풀이를 보고, 도움을 받아 풀고,
혼자 답해 보는 순서로 익혀요. 원하는 개념은 자유 연습에서 바로 골라도 돼요.

배운 내용 다시 풀기

복습할 때가 된 개념을 오늘 화면에서 알려드려요. 한 번에 최대 5개 개념을
한 문제씩 풀며 배운 내용을 확인해요.

테이블에서 판단 연습하기

서로 다른 전략을 쓰는 연습 상대와 한 핸드씩 플레이해요. 답을 고른 뒤
공개된 훈련 차트와 계산 가정에 따른 설명을 확인할 수 있어요.
측정 가능한 상황에서는 결정의 EV와 실제 핸드 결과를 구분해 보여줘요.

내 기록 확인하기

답한 문제 수와 복습 일정을 확인해요. 확률 추정 문제에서는 내가 제시한
범위에 정답이 들어온 비율을 볼 수 있어요. 기록은 기기에 저장되며 파일로
백업하고 다시 가져올 수 있어요.

현재 버전은 광고, 계정, 인앱 결제 없이 이용할 수 있어요. 학습은 오프라인에서
가능해요. 개인정보 처리방침이나 피드백 링크를 열면 외부 앱으로 이동해요.

실제 돈이나 경품을 걸지 않아요. 테이블에는 학습을 위한 가상 베팅이 포함돼요.
이 앱은 전문 선수 자격이나 수익을 보장하지 않아요.

## English (U.S.) metadata

**Subtitle:** Poker practice in Korean

English metadata describes a Korean-language app. Do not advertise English
lessons until the full curriculum, feedback and help content are localized and
reviewed. The Home Screen display name remains Glass Table. Store name availability
has not been reserved or verified in App Store Connect.

**Promotional text:** Read the cards, choose an answer, and understand the reason. Practice Hold’em fundamentals, probability and ranges with Korean lessons.

**Keywords draft:** holdem,texas,ranges,odds,equity,EV,outs,MDF,trainer,study,charts

**Description:**

Poker Lessons — Glass Table teaches Hold’em fundamentals and decision-making in
Korean. The app interface and lessons are in Korean.

Work through nine units and eighteen concepts, from reading a hand to probability,
ranges and the reasoning behind a call or fold. New concepts begin with a worked
example, followed by supported practice and independent questions. Free practice
lets you choose a concept directly.

Return to scheduled reviews from Today. Each review session covers up to five due
concepts, one question at a time.

Practice hands against training opponents with different published strategies.
After choosing an action, review feedback based on the disclosed charts and
calculation assumptions. Where measured, decision EV is shown separately from the
actual hand outcome.

See answer counts, review dates and how often your estimated intervals contained
the answer. Progress stays on your device and can be exported and imported as a
backup file.

This version has no ads, accounts or in-app purchases. Lessons work offline.
Privacy-policy and feedback links open external apps.

The practice table includes simulated betting. There is no real-money wagering or
prize. This learning tool does not certify professional ability or guarantee profit.

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
| Unrestricted web access | No | Only fixed policy/support destinations; no unrestricted browser |
| User-generated content / communication | No | None |
| In-app purchases | No | None |

For South Korea, Apple currently requires a **Rating Classification Number (RCN)**
for frequent/intense simulated gambling. Confirm the final questionnaire and
territories before scheduling release; education categorization does not waive this.

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
reveal, 기록. **Captured 2026-08-07** against the pre-revamp UI, replacing the
M1 set (home / outs reveal / pot-odds / stats / glossary), which was two design
generations old.

Regenerate with `GT_SIM="iPhone 17 Pro Max" tools/uisweep.sh`, then copy
`today`, `path`, `table-hand`, `drill-evloss-call` and `records` out of the
timestamped folder. The order is the pitch: what you open daily → the course
behind it → the graded hand that is the differentiator → the reveal showing
where a number came from → progress and calibration.

The 2026-09-14 verification sweep and refreshed README images document the revamp; the store set above remains historical and must be replaced after user feedback.

These are raw frames with no caption layer. If App Store Connect ends up
wanting captioned marketing shots, that is a separate pass.

## Distribution gates

### Enrollment and territory decisions, 2026-09-18

The owner intends to enroll as an individual. Use the legal personal name and an
Apple Account with two-factor authentication; the legal name becomes the public
seller name. No studio name or organization enrollment is needed for this route.
Apple lists USD 99 per membership year, with local pricing shown at enrollment.
The owner reviews the agreement and pays personally. [Enrollment requirements](https://developer.apple.com/programs/enroll/)

US and Korea are priority storefronts, not confirmed eligible territories. Korea's
simulated-gambling/RCN assessment remains unresolved and is a release gate. Candidate
additional markets are Canada, UK, Australia, New Zealand and selected Asian
storefronts; check the final app's regional requirements before enabling each.
There is no assumed universally easy first-release country set. Defer EU rollout
for now per the owner's preference. No App Store Connect availability was changed.

The current implementation phase covers the benchmark learning and presentation
improvements. Accounts and purchases remain absent. A free introductory unit plus
one-time course unlock is a proposal for a later implementation phase, not shipped
functionality or an active offer; update all free/pricing claims before that phase
is released.

- Install a signed Release candidate on a physical iPhone and test interrupted
  lessons, backup import/export, relaunch, Dynamic Type and VoiceOver.
- Validate the signed archive and privacy report in Xcode Organizer. The local
  unsigned archive checks do not validate distribution entitlements or App Review.
- Publish the reviewed privacy policy draft: the live policy was reachable on
  2026-09-14 but still showed the older July text.
- Review third-party notices (Pretendard OFL and FSRS MIT) in Settings and archive.
- Korean is the declared app language; English metadata does not imply an English UI.
