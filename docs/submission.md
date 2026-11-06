# App Store preparation: v1.0 (4)

> **2026-11-06: store copy rewritten for build 38** (owner approved). The name is
> "Glass Table" in both languages, matching the GRAC title. Review notes and the
> screenshot plan below still describe the older nine-unit path; rewrite them before
> entering anything into App Store Connect.

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
| Name (Korean) | Glass Table |
| Name (English metadata) | Glass Table |
| Primary language | Korean |
| Bundle ID | com.michaelju.glasstable |
| SKU | glass-table-ios |
| Price | Free |
| Availability | US and Korea prioritized; final territories pending regional-rating review |
| Category | Education (primary), Games – Card (secondary) |
| Support URL | https://mhju0.github.io/glass-table/support.html |
| Privacy policy URL | https://mhju0.github.io/glass-table/privacy-policy.html |
| Copyright | 2026 Michael Ju |

## Korean (primary) metadata

**부제 (subtitle):** 처음 배우는 홀덤, 판단까지 연습

**프로모션 텍스트:** 추천 레슨을 따라가거나 원하는 기술을 골라 연습하세요. 컴퓨터 셋과 가상 칩으로 한 판을 끝까지 치고, 무슨 일이 있었는지 돌아볼 수 있어요.

**키워드:** 홀덤,포커,배우기,팟오즈,아웃,레인지,확률,시작패,연습,공부

**설명:**

Glass Table은 홀덤을 처음 배우는 사람을 위한 학습 앱이에요. 누가 이기는지부터 시작해 시작 패, 상대 읽기, 팟과 확률까지 직접 판단하며 배워요.

네 갈래로 배우기
기본기, 시작 패, 상대 읽기, 가격과 확률의 네 트랙에 더 깊이 보고 싶을 때 여는 선택 트랙이 있어요. 다음 레슨을 추천해 드리지만 잠긴 레슨은 없어요. 어디서 시작할지 모르겠다면 시간 제한 없는 시작점 확인을 해 보세요.

짧은 레슨과 복습
레슨은 세 문제, 기술 하나만 따로 연습할 때는 다섯 문제예요. 다시 볼 때가 된 기술은 복습으로 돌아오고, 트랙 끝 도전은 배운 기술을 섞어서 물어요.

테이블에서 한 판씩
나와 컴퓨터 셋이 가상 칩 40개로 10핸드를 치는 빠른 게임이 기본이에요. 두세 명 테이블과 100칩 긴 테이블도 고를 수 있어요. 끝난 핸드는 행동, 칩 이동과 결과를 그대로 보여 줘요. 별도의 일대일 연습은 공개된 차트와 계산 가정으로 선택을 채점해요.

내 기록
공부한 판단 수와 능숙 단계에 이른 기술 수, 이번 주 기록을 보여 줘요. 쉬는 날이 있어도 불이익은 없어요. 기록은 기기에만 저장되고 파일로 내보내고 가져올 수 있어요.

설정에서 한국어와 영어를 바로 바꿀 수 있어요. 계정, 광고, 분석 도구, 인앱 결제가 없고 오프라인에서 모두 동작해요.

실제 돈이나 경품을 걸지 않아요. 연습 테이블에는 학습용 가상 베팅이 포함돼요. 이 앱은 실력이나 수익을 보장하지 않아요.

## English (U.S.) metadata

**Subtitle:** Learn Hold'em, decide for real

**Promotional text:** Follow a suggested lesson or pick any skill. Play a full hand with virtual chips against three computers, then look back at what happened.

**Keywords:** holdem,poker,learn,lessons,pot odds,outs,ranges,starting hands,practice,trainer

**Description:**

Glass Table teaches No-Limit Hold'em to people starting from zero. Begin with who wins a hand, then work up to starting hands, reading opponents, and the pot and your chances, making the decisions yourself.

Four tracks
The basics, Starting hands, Reading opponents, and Price and chance, plus an optional Go deeper track. The app suggests a next lesson, but nothing is locked. Not sure where to begin? Take the untimed starting-point check.

Short lessons, spaced review
A lesson is three questions; practising one skill is five. Skills come back for review when they are due, and each track ends with a challenge that mixes what you learned.

A hand at a time
The default quick game is you and three computers, 40 virtual chips, 10 hands. Two- and three-player tables and a longer 100-chip table are also available. A finished hand shows the actions, chip movement and result as they happened. A separate heads-up exercise grades choices against a published chart and stated calculation assumptions.

Your record
See decisions studied, skills that reached Strong, and this week's practice. Missed days carry no penalty. Progress stays on your device and can be exported and imported as a file.

Switch between English and Korean in Settings. No accounts, ads, analytics or in-app purchases, and everything works offline.

No real money or prizes. The practice table includes simulated betting for learning. The app does not certify skill or promise winnings.

## Age rating questionnaire (must be completed on the final build)

Use the live [Apple questionnaire](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)
and [current regional definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions).
Do not translate old age tiers into new ones or select answers to target a lower rating.
The educational purpose does not remove the table's simulated betting content.

| Question | Answer | Rationale |
|---|---|---|
| Violence (cartoon/realistic), horror, sexual content, nudity, profanity, drugs/alcohol/tobacco, medical info | None | Absent from the app |
| Simulated Gambling | **Frequent** (D58) | The free and graded tables depict betting on almost every screen. The historic M1 Infrequent/Mild answer is obsolete. |
| Real-money gambling / contests | No | Free study tool, no money in or out |
| Unrestricted web access | No | Only fixed policy/support destinations; no unrestricted browser |
| User-generated content / communication | No | None |
| In-app purchases | No | None |

For South Korea, Apple currently requires a **Rating Classification Number (RCN)**
for frequent/intense simulated gambling. Confirm the final questionnaire and
territories before scheduling release; education categorization does not waive this.
GRAC rated the app 청소년이용불가 · 사행성 on 2026-11-05: RCN **`CC-NM-261105-006`**.
Enter it under Age Rating → Add RCN ("Not permitted for use by juveniles"). All
territories launch together once it is entered (D58). App Store Korea users see the
GRAC launch notice and Settings → 등급 정보 (D59).

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

The iPhone 6.9" set (1320×2868, iPhone 17 Pro Max simulator on iOS 26.5, light
appearance, default text size), one per locale, **captured 2026-10-12** from
`feat/audit-followups`: `docs/store-assets/{ko,en}-0[1-5]-*.png` — Learn, a
pot-odds lesson question, a four-seat hand on your turn, the hand review with
its action history, and Progress. It replaces the August set, which showed the
old Today/Path navigation.

Capture recipe, run once per language:

```sh
GT_SIM="iPhone 17 Pro Max" GT_APPEARANCE=light GT_CONTENT_SIZE=large GT_LANGUAGE=ko \
  tools/uisweep.sh --screen learn --screen drill-potodds --screen play-hand \
  --screen play-review --screen records
```

The frames land in `.uisweep/<run>/large/`; copy them to `docs/store-assets/`
as `01-learn`, `02-lesson`, `03-play`, `04-review`, `05-progress` with the
language prefix. Retake after any change to those five screens, and read each
image for its on-screen copy before submitting.

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
