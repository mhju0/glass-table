# Changelog

Notable changes to the Glass Table app. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions are tagged
`vMAJOR.MINOR.PATCH` (TestFlight-only builds as `-beta.N`).

## [Unreleased]

### Changed — drill screens stopped recomputing per render (2026-08-09)
- **A `spot` held in a computed property regenerated itself on every read**, and a
  `body` reads it five to nine times. The generators are not cheap — 액션 리드
  narrows a range per attempt and EV 손실 prices an equity per candidate — so
  each render ran the whole rejection loop again, on the main thread. Bound once
  per render instead: 액션 리드 769µs → 86µs, EV 손실 758µs → 153µs, 콜/폴드
  178µs → 36µs, 아웃 135µs → 45µs (release; a debug build is worse).
- **레인지 어드밴티지 built both bucket bars inside `body`**, so two passes over a
  range's combos ran on every render while the reveal was up. They depend only
  on the spot, so they now come back from the same detached task that already
  samples the equity — off the main thread, once per spot.
- **레인지 리드's chip row cut a fresh range per chip.** `isSaturated(atWidth:)`
  builds a `shaped(width:)` internally, and the row asked it up to eight times a
  frame while the width slider moved. One cut is now shared across the row
  (`isSaturated(in:)`): 451µs → 57µs per frame.
- No visual change: 56 of 58 swept screens are pixel-identical to the previous
  build, and the two that differ are a card fade-in caught mid-animation, which
  reproduces run-to-run on an unchanged build.

### Changed — engine performance (2026-08-08)
- **`madeHand` was 5× more expensive than the evaluator it wraps** — 5.4µs
  against `evaluate7`'s 1.0µs. `straightCompletingRanks` asked "does this
  complete a straight" once per rank, and each ask built a fresh array and a
  fresh `Set`; `drawOrAir` then read only `.isEmpty` off the list it allocated.
  Straight detection is now five `AND`s on a rank bitmask, and the bucket
  classifier is allocation-free: **47× on a flop, 15× on a river**.
- **`eval5` packs rank multiplicities four bits at a time into one `UInt64`**,
  which retires the 15-slot scratch buffer, its zeroing loop, and the
  52-iteration tiebreak sweep (now one mask per multiplicity). `evaluate7` 2.9×.
- **`exactEquityHeadsUp` built a deck it could not use on a complete board** — a
  9-card `Set` plus a 52-card filter, to set up two evaluations. That is the
  path `equityVsRange` walks once per villain combo, and hero's key is constant
  across them besides. River hand-vs-range **12×**.
- The Monte-Carlo paths reuse their card buffers instead of allocating three
  arrays per iteration; `rangeEquity` no longer rebuilds a 48-card pool per
  sample, ×8,000. `rangeEquity` 2.6×, `rangeOnBoard` 11×.
- Same algorithm and the same integer keys throughout — only constant factors
  changed. The release gate proves it: **92 engine tests 284s → 128s**, 316
  drills tests 4.8s → 0.7s, none of them touched.

### Fixed — accessibility (2026-08-07)
- **Card ranks truncated to "…" at the accessibility text sizes**, because the
  face used a Dynamic-Type font inside a fixed card frame. 쇼다운 asked who won
  above nine blank cards and the table could not be read — the app was
  unplayable at exactly the settings that ask for help. Card faces now opt out
  of scaling (`GT.fixed`); VoiceOver already announced each card and still does.
  Scaling was never an option: five cards at 3× need ~715pt of a 393pt screen
  (decisions.md §H).
- The drills' 자리 strip and the table's 스트리트 strip stop scaling at
  `.xxLarge` instead of breaking `UTG+1` across three lines — both are one-row
  diagrams that only work whole.

### Changed — UI review pass (2026-08-07)
- **테이블 actions are priced and separated by kind.** Fold / call / raise were
  one string each at one weight; the verb now sits over the amount in tabular
  digits, so the three prices form a column. A 3pt rule under each marks *what
  kind of money* it commits (gold call, green wager, neutral fold) and
  deliberately never marks which is better — the screen grades that choice.
- **The reveal leads with the lesson.** "최선은 폴드" moves from 12pt grey to the
  headline and the severity becomes a pill; the EV loss now sits in a two-row
  comparison against the best line, so −4.1bb is a subtraction the user can
  check rather than a verdict.
- **Three screens stopped stacking from the top.** 테이블, the 천천히 walkthrough
  and `DrillShell` (shared by all 18 drills) pinned their content to the
  viewport height, so the slack that used to pool as bare felt above the sheet
  — measured 18–41% of the screen — is now distributed around the content.
- **팟 moved to the board** as a proportional 팟/콜 strip with the division
  spelled out. It also rounds to printed precision *before* dividing; the old
  arithmetic printed 13.1 + 5.6 under a total of 18.8.
- **길 inverted its weight.** A cleared node was the brightest, largest thing on
  screen while the next step was a hollow ring. Cleared nodes are now small mint
  discs on a continuous rail, only the live node keeps the full badge and a
  glass card, mastery moved into chips, and unit headers gained a progress bar.
  The serpentine indent is gone — it read as a dependency tree, and a unit is a
  sequence.
- **The streak is drawn with SF Symbols**, not 🔥/🛡 — the last two emoji used as
  icons anywhere in the app.
- Tab-bar clearance is one `@ScaledMetric` safe-area inset instead of four
  copies of `.padding(.bottom, 96)`.

### Added — the revamp (branch `revamp/r1-progression-shell`, 2026-08-03/04)
- **Progression shell (R1)**: the app became a course. Three tabs — 오늘 (one
  next step, daily set, calibration), 길 (a linear path of units and boss
  nodes, FSRS-scheduled review), 기록 (mastery per concept, calibration detail).
  Every new concept opens with a 천천히 walkthrough (보여주기 → 함께 풀기 → 혼자),
  estimation drills collect a point + 90% interval scored by the Winkler rule.
- **Charts (R2)**: 레인지 표기법 and RFI 차트 drills; derived 8-max opening
  ranges with the derivation and benchmarks disclosed in-app.
- **Range read (R3)**: 레인지 리드 — width + shape read of an archetype's
  action, graded by combo overlap, revealed as a two-channel comparison grid.
- **Board texture (R4-S1)**: 히트 프리퀀시 and 레인지 어드밴티지 — what share
  of a range hit the flop, and whose range a flop favours, as stacked bucket
  bars over an exact combo-level classification.
- **EV-loss grading (R4-S2)**: 「EV 손실」 — a river call scored by what it cost
  in bb against a *stated* range, decisions.md §D bands (최선/부정확/실수), and
  기록's rolling per-hand EV loss.
- **Postflop policy (R4-S3)**: 「액션 리드」 — each archetype's postflop play as
  a printable bucket table, deterministic so an observed bet or check inverts
  into the exact surviving range, shown as before/after bars.
- **테이블 (R4-S4)**: fourth tab. A whole heads-up hand against a chosen
  archetype, every postflop decision priced off-thread under the disclosed
  checkdown model, summary showing net result and EV burned side by side.
- **Hero preflop (R5)**: the table deals any two cards; fold/call/3-bet is
  graded against a derived defend chart (3벳/콜 bands scaled to the opener's
  width), with the three-band grid one tap away. The bot answers 3-bets with a
  character-scaled top slice of his opening range and never 4-bets (stated).
- **디펜드 차트 drill (R5b)**: unit 8 trains the same chart the table grades
  with; ordinal three-way grading (one band off = 근접).

### Changed — the revamp
- Glass became an opaque colour and the app pinned to one (dark) appearance:
  every surface boundary now clears WCAG 1.4.11's 3:1, measured off real
  screenshots (decisions.md §G has the numbers and the reasoning).
- Nav-bar controls are drawn by the app (chevrons, not words), replacing the
  iOS 26 Liquid Glass capsule that re-tinted while sheets settled.
- The M1 per-drill home is replaced by the path; 자유 연습 keeps every drill
  reachable without limits.

### Added
- Home redesign: felt-gradient backdrop, serif masthead with suit rules,
  drill grid with per-mode explanations (2026-07-23)
- 설정 screen (용어집/통계/개인정보 처리방침/버전), plus 첫 핸드 다시 보기
- 첫 핸드: first-run onboarding as one authored hand (AhKh vs QsQd on
  Qh7h2s3c) that asks each of the five drills' own questions in the order the
  hand asks them, guess-before-explanation throughout. Auto-plays once on first
  launch, skippable at any beat, re-enterable from home and 설정. Replaces the
  3분 시작 가이드 text screen (2026-07-25)
- Every drill header carries a permanent one-verb subtitle, and every reveal a
  용어 chip that opens the glossary scrolled to that drill's term
- Outs reveal leads with the natural frequency (남은 44장 중 7장), rule-of-2
  percent subordinate and labelled 근사

### Changed
- New app icon: 4×4 equity-heatmap range grid with the four suits on the
  pair diagonal in card colors (replaces the percent-on-disc mark, 2026-07-24)
- Drill sessions resume where you left off (`progress.total`) instead of
  repeating spot 0 every visit
- 콜/폴드 answer buttons are equal weight (no visual bias toward calling)
- MDF reveal now derives the formula instead of asserting it: alpha = 100 − MDF
  is villain's bluff break-even, so the explanation says whose price it is
- Every reveal opens with a verdict banner instead of a small pill beside grey
  text: 정확 collapses to one number, 근접/빗나감 expand to 내 답 → 정답 with the
  gap named (2 차이 / 8%p 차이). Icon (✓ / ± / ✕), text, structure and color all
  carry the result, so it survives greyscale and color blindness. Band inks
  darkened to reach WCAG AA on their own tints (they measured 3.08–4.17:1)
- Portrait-only; consistent hidden toolbar backgrounds; 🔥 shows only with a
  live streak everywhere

### Fixed
- Card labels never wrap rank/suit vertically and never touch the card edge
