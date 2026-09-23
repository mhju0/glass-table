# App Store preparation: v1.0 (4)

> **2026-09-23: local dogfood build, not submitted.** Release 1.0 (4) was installed
> in place and launched on the owner's iPhone 12 mini. Schema-1 progress migrated
> to schema 2 with its original nine answers, two concepts, one node and streak
> preserved; the original bytes were retained in a migration copy and the saved
> state survived relaunch. See the
> [combined delivery](specs/2026-09-23-beginner-native-release.md). Adult-beginner
> comprehension, physical VoiceOver, iOS 17, signed distribution validation,
> current store screenshots, App Store Connect metadata, age rating and regional
> requirements remain release gates.

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

**프로모션 텍스트:** 배우기에서 다음 연습을 추천받거나 원하는 주제를 골라요. 플레이에서는 컴퓨터 상대와 한 판씩 연습하고, 끝난 뒤 실제 결과를 살펴볼 수 있어요.

**키워드 초안:** 홀덤,레인지,팟오즈,에퀴티,EV,아웃,MDF,수학,연습,훈련,차트

업로드 전에 실제 키워드 필드의 바이트 제한과 중복을 확인하세요.

**설명:**

포커 배우기 — Glass Table은 홀덤의 규칙과 판단을 연습하는 한국어 학습 앱입니다.
카드를 읽는 기초부터 확률, 레인지, 콜과 폴드의 근거까지 차근차근 배워요.

한 단계씩 배우기

9개 단원에서 18개 개념을 다뤄요. 새 개념은 왜 배우는지와 풀이 예시부터
살펴본 뒤, 도움을 받거나 혼자 연습할 수 있어요. 다음 단원을 추천해 드리지만
원하는 주제는 언제든 열어 볼 수 있어요. 시작점을 모르겠다면 계정 없이 짧은
선택형 확인을 해 볼 수 있어요. 이 결과가 숙달 기록을 대신하지는 않아요.

배운 내용 다시 풀기

복습할 때가 된 개념을 배우기 화면에서 알려드려요. 한 번에 최대 5개 개념을
한 문제씩 풀며 배운 내용을 확인해요. 자유 연습은 다섯 문제씩 진행돼요.

테이블에서 판단 연습하기

플레이 탭에서는 나와 컴퓨터 셋이 가상 칩으로 연습해요. 끝난 핸드의 행동,
칩 이동과 결과를 사실 그대로 확인할 수 있어요. 별도의 판단 연습에서는
답을 고른 뒤 공개된 훈련 차트와 계산 가정에 따른 설명을 볼 수 있어요.
네 명이 하는 칩 연습의 각 행동에 EV 점수를 붙이지는 않아요.

내 기록 확인하기

답한 문제 수와 복습 일정을 확인해요. 비슷한 문제끼리 최근 기록을 비교하고,
충분한 연습 기록이 있을 때만 답변 시간이나 플레이 습관 요약을 보여줘요.
기록은 기기에 저장되며 파일로 백업하고 다시 가져올 수 있어요.

설정에서 한국어와 영어를 바로 바꿀 수 있어요. 두 언어 모두 같은 학습과
연습을 제공해요.

현재 버전은 광고, 계정, 인앱 결제 없이 이용할 수 있어요. 학습은 오프라인에서
가능해요. 개인정보 처리방침이나 피드백 링크를 열면 외부 앱으로 이동해요.

실제 돈이나 경품을 걸지 않아요. 테이블에는 학습을 위한 가상 베팅이 포함돼요.
이 앱은 전문 선수 자격이나 수익을 보장하지 않아요.

## English (U.S.) metadata

**Subtitle:** Learn poker, one decision

The Korean/English native interface, all eighteen concepts, generated feedback
and help are included in Release 1.0 (4). The Home Screen display name remains
Glass Table. Store name availability has not been reserved or verified in App
Store Connect.

**Promotional text:** Follow a suggested lesson or choose your own. Practise hands against computers, then see the actions, chips and outcome.

**Keywords draft:** holdem,texas,ranges,odds,equity,EV,outs,MDF,trainer,study,charts

**Description:**

Poker Lessons — Glass Table teaches Hold’em fundamentals and decision-making in
English and Korean. Switch languages in Settings without losing your place.

The open nine-unit path covers eighteen concepts, from reading a hand to
probability, ranges and the reasoning behind a call or fold. New concepts begin
with a short explanation and example. Take a suggested next lesson or choose any
topic directly. An optional untimed starting-point check suggests where to begin.

Return to scheduled reviews from Learn. Each review session covers up to five due
concepts, one question at a time. Free practice uses five-question rounds.

Play four-seat chip practice against three computer opponents. A finished hand
shows the actions, chip movement and result. A separate heads-up lesson grades
decisions against disclosed charts and calculation assumptions. Four-seat actions
do not receive an EV grade.

See answer counts, review dates and comparable recent results. Optional response
time and play-habit summaries appear only with enough suitable evidence. Progress
stays on your device and can be exported and imported as a backup file.

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
their mail app. The privacy manifest declares no tracking or collected data and
lists UserDefaults and system boot time as locally used required-reason APIs.
Validate the signed archive's privacy report before uploading.

## Review notes (entered at submission)

Glass Table is a free educational study tool for No-Limit Hold'em poker
mathematics, with complete Korean and English interfaces. Reading simplicity is
for adult beginners; the app is not child-targeted.

- No real-money gambling, no purchasable currency, and nothing to win or lose
  outside a study session. The app contains a guided curriculum of poker-math
  drills, a four-seat practice table with whole virtual chips and 1/2-chip
  blinds, and a separate graded heads-up exercise expressed in big blinds.
  Both table modes depict simulated betting. Review this wording against the
  final build before entering it into App Store Connect.
- Fully offline: no account, no login, no in-app purchases, no ads, no data
  collection.
- No demo account is needed. All nine units and eighteen concepts are open;
  Learn suggests a next step without granting credit for skipped lessons. The
  optional offline check suggests a starting point without mastery credit.
- Preflop grading uses declared training charts. Postflop EV uses the disclosed
  checkdown approximation in the separate heads-up lesson. Four-seat table
  practice gives a factual hand review, without per-action EV grades or FSRS
  credit. This is not a full-game solver or live-play assistant.

## Screenshots

The historical iPhone 6.9" set (1320×2868, from iPhone 17 Pro Max simulator), reused for
both locales: `docs/store-assets/ko-0[1-5]-*.png` — 오늘, 길, 테이블, a graded
reveal, 기록. **Captured 2026-08-07** against the pre-revamp UI, replacing the
M1 set (home / outs reveal / pot-odds / stats / glossary), which was two design
generations old.

The former capture recipe used `today`, `path`, `table-hand`,
`drill-evloss-call` and `records`. It belongs to the August set and is no
longer a current submission recipe. The revised set should show actual Learn,
Play, Progress, an open lesson and a factual four-seat review; choose the final
sequence only after reviewing the captured frames in both locales.

The 2026-09-23 combined release has new README images and a 256-capture Mini
language/appearance/text-size sweep; neither is a submitted App Store set. The
August store images above depict the older Today/navigation flow and must be
replaced with current Learn/Play/Progress screens before submission. Capture
final store sizes and locales from the approved candidate, then review each image
for actual on-screen copy and content.

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

The combined native implementation covers the beginner learning and table
practice changes. Accounts and purchases remain absent. A free introductory unit plus
one-time course unlock is a proposal for a later implementation phase, not shipped
functionality or an active offer; update all free/pricing claims before that phase
is released.

- Release 1.0 (4) was installed in place on iPhone 12 mini with migration and
  relaunch preservation verified. Still test interrupted lessons and backup
  import/export on device, plus physical Dynamic Type and spoken VoiceOver.
- Validate the signed archive and privacy report in Xcode Organizer. The local
  unsigned archive checks do not validate distribution entitlements or App Review.
- Publish the reviewed privacy policy draft: the live policy was reachable on
  2026-09-14 but still showed the older July text.
- Review third-party notices (Pretendard OFL and FSRS MIT) in Settings and archive.
- Korean remains the primary App Store language; Release 1.0 (4) has a complete
  English interface as well. Verify both metadata sets in App Store Connect.
