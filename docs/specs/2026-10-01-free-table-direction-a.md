# Free table "Direction A" and app-wide spacing — delivery spec

Status: approved by the owner on 2026-10-01. This file is the source of truth for the
build. Earlier exploration pages (local, gitignored, for visuals only) are listed in
§12; where they disagree with this file, this file wins.

Scope is presentation only: SwiftUI views, design tokens, copy, motion and haptics.
**No engine change, no `progression.json` schema change.** If a step seems to need
either, stop and ask.

---

## 0. Starting state (verified 2026-10-01)

- Branch `feat/audit-fixes-table-focus`, HEAD `33e5384` ("full-screen free table with
  paced replay, haptics and landscape"), not pushed. Several things that commit added
  are reversed by this spec: the full-screen table, landscape, and the ⓘ guide button.
- Untracked and **not part of this work**: `tools/uxaudit/`,
  `GlassTable/UITests/UXAuditCrawl.swift`, `docs/records/2026-09-30-uxaudit-codex-review.md`,
  `tools/line-parity/.build-ocr-lines`. Don't edit,
  stage or delete them.
- The agent handoff has uncommitted appended entries describing this design
  work. Commit it together with this spec in step 0.

## 1. Spacing and corner rules (whole app)

Measured on the current app (simulator screenshot at 3×): the dock pads 20 pt, but the
visible gap above its title reads **25 pt** against 21 left / 19.5 right / 20 bottom;
the floating sheet's corner is **≈46 pt** while the buttons sitting in its corners
round at 14 pt, so the diagonal corner gap is ≈15 pt against 20 at the sides; the
table felt sits 16 pt from the screen edge while the floating dock sits 8 pt.

- **R1 Equal visible inset.** The gap from a container's edge to the first ink is the
  same on all four sides. The top padding is reduced by the empty space above the
  first line's capitals, and that amount **depends on the font size** (Pretendard,
  scaled by Dynamic Type through `relativeTo:`). Today a single constant
  `GT.Space.leading = 2` (`Theme.swift`) corrects every size; it is right for ~13 pt
  text and ~4 pt short for a 22 pt title. Replace it with a per-font correction (for
  example from `UIFont(name:size:)` `ascender − capHeight` at the scaled size, or a
  first-baseline alignment guide). Verify by measuring screenshots, not by reasoning.
- **R2 One content edge.** Within a container the title, controls and rows start on
  one line. In the dock the title's left edge equals Fold's left edge (already true).
- **R3 Left = right.** Trailing controls (pills, chevrons, toggles, checkmarks) end at
  the same inset the leading text starts at.
- **R4 Corners never tighter than sides.** An element sitting in a container's corner
  gets an outer corner radius of `containerRadius − inset` on the corner side(s). If
  that is smaller than the element's normal radius, keep the normal radius. On iOS 26
  the floating dock is concentric with the display (`ConcentricRectangle` in
  `ActionSheet`, `Components.swift`); its corner children (Fold's bottom-leading and
  Raise's bottom-trailing corners) must be concentric too (≈26 pt today). Other corners
  of those buttons and the middle button keep 14. On iOS 17–25 the dock attaches with
  square bottom corners, so R4 doesn't apply to its bottom row.
- **R5 Few values.** Insets: page edge 18 (`GT.Space.edge`), card 16, sheet/dock 20,
  seat box 10. Radii: 8 (chips, tiles), 14 (`GT.Radius.control`: buttons, inputs),
  20 (`GT.Radius.panel`: cards), 28 (`GT.Radius.sheet`), or concentric per R4. Add an
  8 pt token if needed. Replace these literals:
  - 12/13 → 14 or 8: `CountEntryView.swift:33,50`, `DefendGridView.swift:107`,
    `TableView.swift:585,702`, `ConceptDrillView.swift:1980,2313`,
    `LearningGuideView.swift:39`
  - 15/16 → 14 or 20: `Components.swift:212,285,864,954`, `CountEntryView.swift:67,77`,
    `TableView.swift:494`, `WalkthroughView.swift:203,342`, `LearningGuideView.swift:26`,
    `MilestoneShareCard.swift:74`
  - ~220 literal `.padding(n)` calls exist (most in `ConceptDrillView`, `TableView`,
    `FirstLessonView`, `Components`, `SettingsView`). Convert only a container's
    **inner padding** to tokens. Leave gaps between sibling items alone.

## 2. Table layout (`FreeTableView`, `TableSurface`)

- **Portrait only.** Remove landscape: `OrientationDelegate`
  (`DesignSystem/TableFeedback.swift`), its `@UIApplicationDelegateAdaptor` in
  `GlassTableApp.swift`, the `setLandscapeAllowed` calls in `FreeTableView`, the
  landscape entries in `project.yml` (`UISupportedInterfaceOrientations`, plus the
  comment above it), and the compact-height "wide" layout in `FreeTableView`. Edit
  `project.yml`, never the generated `Info.plist` or `.xcodeproj`.
- **Natural height.** The felt returns to its natural height (no full-screen stretch).
  The felt's outer left/right edges line up with the floating dock's (8 pt from the
  screen on iOS 26). The top chrome stays on the 18 pt page edge.
- **Seats, you bottom-right, clockwise:**
  - 2 players: you `.bottomTrailing`, computer `.topLeading`.
  - 3 players: you `.bottomTrailing`, C1 `.topLeading`, C2 `.topTrailing`;
    `.bottomLeading` shows a faint outlined empty seat labelled **빈 자리 / Empty seat**.
  - 4 players: you `.bottomTrailing`, C1 `.bottomLeading`, C2 `.topLeading`,
    C3 `.topTrailing`.
  Today it is `.bottomLeading`-first (`FreeTableView.swift` `seat(_:table:frame:)`).
  The doc comment there must change too.
- **Your seat, the "paper" seat.** Cream fill `#F3EDE0`, border `#E5DCC8`, ink
  `#1D221F`, secondary ink `#5D625B` (fixed in both appearances, like the felt). Your
  hole cards are drawn at **1.2×** (43 pt tall versus 36). When it's your turn the
  border is the acting gold. Gold never marks "you".
- **Seat box (every seat):** three lines, fixed height, inset 10 on all sides (R1).
  1. Name and dealer disc, e.g. **컴퓨터 2 / Computer 2** or **나 / You**. The style is
     **no longer part of the name** (`FreeTableView.seatName(_:table:)` appends it today).
  2. One status slot, priority: **won** (`+54`, gold) › **thinking** (`생각 중… /
     Thinking…`, gold) › **this street's last action** (`콜 6`, `체크`, `폴드`, `벳 10`,
     `18까지 레이즈`, `올인 76`; reuse `FreeTableWords` and shorten if a string doesn't
     fit one line) › **style** (`style.beginnerTitle(in:)`, muted). The action stays up
     until the next street starts, then the style comes back. Your seat has no style;
     its slot is blank until you act. Text changes crossfade 150 ms; the line never
     moves.
  3. Cards on the leading side; **chip count at the bottom-trailing corner**, a chip
     glyph plus the stack, tabular digits. At 0 it reads **올인 / All in** in the acting
     gold. Chips committed this round sit on the felt in front of the seat, not in the
     box, so the old "남은 칩 N · 낸 칩 N" line goes.
  Add an optional stack field to `TableSeat` rather than reusing `detail`, so other
  `TableSurface` callers (e.g. `PotMathLessonView`) keep working. At accessibility
  sizes the stacked layout (`ViewThatFits`) puts the chips on their own last line,
  trailing-aligned. Nothing truncates in either language.
- **Cards.** One drawing for every table card: `PlayingCardView` proportions (width
  0.72·h, rank 0.34·h, suit 0.38·h, corner 0.07·h). Board and computer seats 36 pt,
  yours 43 pt. Card faces stay fixed-size under Dynamic Type. **One card back**: the
  `PlayingCardView(faceDown:)` spade back. Remove `TableCardBack` (its only use is
  `TableSurface.swift` `cards(_:)`).
- **Chrome.** Remove the ⓘ (`info.circle`, identifier `play-table-guide`). The guide
  content moves into the dock's Rules tab (§4). The title stays
  "네 명 · N번째 핸드 / Four players · Hand N" (두 명 / 세 명 for 2 and 3).

## 3. The dock, front face (`ActionSheet` content in `FreeTableView`)

- **Height.** The dock's height is set once from its tallest face (front, raise, back),
  measured at the real 20 pt insets, and does not change between faces or turns. (A
  "136 pt" figure in the exploration pages was mock scale; don't use it.) At
  accessibility sizes the dock may grow; never truncate and never use
  `minimumScaleFactor` on its text.
- **Buttons stay their original size:** 87 pt tall, near-square. Removing the
  status sub-line must not make them taller; the freed space goes to the table.
- **Title row:** title + the Math pill on the trailing side (R2, R3). No second line,
  except these two cases, shown in amber under the title:
  - call puts you all in: **남은 칩 전부로 콜해요 / Calling puts you all in**
  - short all-in, no re-raise: **올인이 작아서 다시 올릴 수 없어요 / Their all-in was
    short, so no re-raise**
  Title by state: **내 차례 / Your turn** · **컴퓨터 N 차례 / Computer N's turn** ·
  **카드를 나눠요 / Dealing** · **끝까지 펼쳐요 / Running it out** (all-in run-out) ·
  hand over → result face (existing net chips, 다음 핸드, 이번 핸드 보기).
- **Three fixed slots, never removed, never reordered:**
  1. **폴드 / Fold**, centred single label. Dimmed when not legal (the engine doesn't
     offer fold when nothing is owed — keep that behaviour).
  2. **체크 / Check** (centred) or **콜 / Call** with the price on a second line
     (**6칩 / 6**). If calling is all your chips: **올인 / All in** + **14칩 / 14**.
  3. **레이즈 / Raise** or **벳 / Bet**, centred single label, no amount. Dimmed when
     raising isn't legal.
  A button without a number is a single centred label (the old empty price line made
  Fold sit high). Keep the coloured underline bars (grey / amber / green). During a
  computer's turn all three show what you'll be able to do, dimmed and not tappable.
- **One tap acts.** Fold, Check and Call commit on finger-up (press highlight on touch
  down, scale 0.97; sliding off cancels). No confirm step. Raise/Bet opens the raise
  face.
- After you fold, a small link **결과로 넘기기 / Skip to result** plays the rest of the
  hand at 3× speed.

## 4. Raise face and back face

**Raise face** (crossfade swap, not the flip; ‹ returns to the front):
1. ‹ · the amount (large) with a small line under it · Math pill.
   - Postflop, first to bet: **9칩 벳 / Bet 9**, small: **스택에서 9 · 팟의 50% /
     9 from your stack · 50% of pot**.
   - Postflop, raising: **24칩까지 레이즈 / Raise to 24**, same small line.
   - Preflop: **6칩까지 레이즈 / Raise to 6**, small: **스택에서 6 · 3BB / 6 from
     your stack · 3 BB**.
2. Five presets in one row (each shows its chip amount underneath):
   - postflop: **⅓ · ½ · ¾ · 팟/Pot · 올인/All in** (the app's sizing menu,
     `docs/decisions.md` D13, and the sizes the computers use in `PostflopPolicy`)
   - preflop, no raise yet: **2BB · 2.5BB · 3BB · 4BB · 올인** (big blind = 2 chips)
   - preflop, facing a raise: **2.5× · 3× · 4×** the current raise-to, **팟 · 올인**
   Amounts: first to bet, `bet = round(f × pot)`. Facing a bet, with `C` = your amount
   to call and `P' = pot + C`, `raise-to = currentBet + round(f × P')`. Pot = f 1.0.
   A preset below the minimum raise or above your stack is dimmed (never removed). Two
   presets that resolve to the same amount both stay and both select it.
3. **− · commit · +**. Steps of one big blind (2 chips), clamped to the minimum and to
   all-in; holding repeats after 400 ms; each step is a `tick`. At a limit the button
   dims (no haptic). The commit button uses the app's primary button style and names
   the result: **9칩 벳 / Bet 9**, **24칩까지 레이즈 / Raise to 24**, **올인 94 / All in
   94** (all-in uses the heavy commit haptic). **No slider** (D13; and the free table's
   any-whole-amount rule, D45, is covered by − / +).
The engine already accepts any whole amount from the minimum raise to all-in
(`PracticeTableState.apply`, `legalActions`). Don't change it.

**Back face (the flip).** The Math pill flips the dock on its X axis (450 ms ease-out,
top edge first; Reduce Motion → 150 ms crossfade). Tabs: **계산 · 이번 핸드 · 규칙 /
Math · This hand · Rules**; ↻ flips back. The existing `FreeTableHelpSheet` /
`FreeTableHelpTab` (`.hint, .hand, .rules`) and the slide-up sheet are replaced by
this; "힌트 / Hint" is renamed **계산 / Math** on the table only. (The lessons' own
"힌트" pill in `NodeSessionView` stays.)

- **계산 / Math: numbers, no sentences, no formulas.**
  - Three tiles in a row: **팟 / Pot** (felt green `#153D33`, light text) ·
    **콜 / Call** (amber, bg `#F5E6C8`, value `#6B4300`, label `#8A5500`) ·
    **필요 승률 / Need to win** (white, border `#E3DAC7`) showing e.g. **25%** with a
    2×2 dot square, filled dots in gold `#B37A12` for "1 in N" (N = 2…6, nearest; hide
    the dots past 1 in 6). With nothing to call: Call **0**, Need **—**.
  - Under the tiles, one strip: **내 패 / Hand** + made hand (`Q 원페어 / Pair of
    queens`); preflop the two cards + a pill **상위 18% / Top 18%**.
  - Values come from `PracticeDecisionFacts` (`GlassTableDrills/.../PracticeTable/
    PracticeReplay.swift`): `pot`, `toCall`, `requiredEquityPercent`, `madeHand`,
    `startingHand`, `startingHandTopPercent`.
  - Colours above are for the light dock; derive dark-appearance values from the
    existing adaptive tokens and keep text contrast ≥ 4.5:1.
  - **Level 2 (outs, next-card %) is deferred.** The engine's
    `countOuts(hero:villain:board:)` needs the opponent's hand and would leak hidden
    cards. Don't use it at the table and don't add an engine helper in this build;
    report it as open.
- **이번 핸드 / This hand:** the existing hand history, plus one line per computer: its
  style and the same one-sentence habit as the setup screen.
- **규칙 / Rules:** the existing `PlayTableGuideList` and the "how the computers choose"
  disclosure. The guide copy changes from "왼쪽 아래 자리가 나예요" to bottom-right,
  the cream seat (`PlayView.swift` ~line 165, both languages).
- **After the hand — 핸드 돌아보기 / Hand review:** one row per decision of yours that
  faced a bet: street, a green bar of your real chance, a gold tick at the needed %,
  and both numbers. Real chance = `exactEquityHeadsUp(hero:villain:board:)` at that
  point, **only when exactly one opponent was live and their cards were shown at
  showdown**. Otherwise the row shows "—". Never show this before the hand ends.

## 5. Gold, paper and the rest of the app

- **Gold outline = now** (the seat acting, the current step). **Gold fill = your pick
  or the primary button.** **Paper (cream) = you.** Gold hue is already one family:
  `GT.tableSeatActive #F3CA87` on felt, `GT.cta` (#8A5500 light / #EDC17F dark) on
  paper.
- `ConceptDrillView.swift:1077` and `:1689`: "your position" chip filled with
  `GT.cta` → paper treatment (cream fill, dark ink).
- `PotMathLessonView.swift:143`: current replay step capsule filled `GT.cta` → gold
  outline on the current step, ink fill for finished steps.
- Graded table (`TableView.swift`): same dock front (title row without the sub-line,
  three fixed slots, centred labels) and the one card back. Keep its grading rule: the
  correct choice is never revealed before the user commits; no Math flip before commit.
- Korean copy: follow `docs/glossary.md` (벳 is the action word; 플랍). Current
  "베팅" strings: `FirstLessonView.swift:365,413,414,447,471,521`,
  `NodeSessionView.swift:630,636`, `TableView.swift:471`, `OpponentPickerView.swift:77`.
  Change the ones that name the action; for the generic "betting round" sense, follow
  the glossary and list any you're unsure about in your report.

## 6. Motion and haptics

Haptic vocabulary (one meaning each; at most one haptic per 150 ms; on collision keep
the higher rank: your turn > commit > won > card > chip > tick):

| Name | SwiftUI | Means |
|---|---|---|
| tick | `.selection` | a control changed: flip, tab, preset, − / + |
| chip | `.impact(weight: .light, intensity: 0.5)` | a computer puts chips in (all-in: intensity 0.8) |
| card | `.impact(flexibility: .soft, intensity: 0.5)` | a shared card lands; a hand revealed at showdown; your two cards flip up |
| your turn | `.impact(flexibility: .rigid, intensity: 0.75)` | the buttons unlock for you, once per decision |
| commit | `.impact(weight: .medium, intensity: 0.8)`; all-in `.heavy` | your action is locked in |
| won | `.success` | you win or share a pot. Losing gets no haptic. |

Checks, folds and blinds by computers get no haptic. Replace `TableHaptics`
(UIKit generators in `TableFeedback.swift`) with `.sensoryFeedback` tied to the state
change that causes each one.

Timings (the replay loop is `FreeTableView.startReplay()`, beats in `Beat`):
- Computer think time: **650 ms (2 players), 550 ms (3), 500 ms (4)** (today a flat 650).
- Fold: cards slide 8 pt to centre and fade to 45%, 250 ms. Check: tag pops, 150 ms.
  Call/bet/raise: chips slide to the front of the seat, 280 ms, stack counts down.
  All-in: 350 ms; the tag stays for the hand.
- Blinds: SB then BB, 180 ms apart, 250 ms each. Hole cards: from centre, clockwise
  from the SB, two rounds, 60 ms stagger, 220 ms flight; yours flip when both land.
- Between streets: bets sweep to the pot together, 300 ms + 150 ms pause. Flop: three
  cards, each 220 ms flight + 180 ms flip, 90 ms apart, after a 300 ms pause.
  Turn/river: 300 ms pause + 400 ms.
- Uncalled bet: slides back, tag **반환 N / Returned N**, 300 ms. All-in run-out:
  live hands flip first, then 600 ms between cards. Showdown: last aggressor first,
  then clockwise, 350 ms apart. Winner: winning five lift 5 pt with a gold edge, rest
  dim; pot slides 450 ms. Split pot: equal piles fly together; odd chip to the first
  winner clockwise from the button, labelled +1. Side pots: separate piles
  (메인 팟 / 사이드 팟), paid last-created first, 450 ms each, 250 ms apart.
- Next hand: board and cards clear 300 ms, button slides (spring response 0.4,
  damping 1.0), blinds, deal. A busted seat counts up to 100 with "+100 채움 / +100
  refill", 400 ms.
- Reduce Motion: no flights, flips or lifts; short crossfades; the existing ×0.5 pause
  scale stays.
- Backgrounding mid-hand pauses the replay; returning continues from the last shown
  step.
- Not in this build: a "fast table" setting (doesn't exist today).

## 7. Accessibility identifiers and tests

Keep: `free-fold`, `free-check`, `free-call`, `free-raise`, `free-raise-cancel`,
`free-raise-confirm`, `free-table-status`, `free-table-help` (now the Math pill),
`free-next-hand`, `free-review`, `free-change-table`, `free-table-net`,
`practice-table`. `free-table-help-sheet` becomes the back face (keep the id on it).
`play-table-guide` goes away with the ⓘ; update `BeginnerReleaseTests.swift` (~lines
382–428, guide close/reopen → Rules tab) and `AccessibilityAuditTests.swift` (~48, 60).
Fixed slots mean `free-fold` exists while disabled; tests that wait for it must wait for
`isEnabled`. VoiceOver: each seat reads name, status and stack; the dimmed buttons say
why they're unavailable.

## 8. Build order (one commit per step, Conventional Commits, explicit paths)

0. `docs:` commit this spec + the agent handoff.
1. Spacing foundation: per-font top correction, radius tokens, R4 helper; apply to
   `ActionSheet` and card containers. Measure the dock and two cards before/after.
2. Table layout (§2).
3. Dock front (§3).
4. Raise face (§4).
5. Flip + back face + hand review (§4).
6. Motion and haptics (§6).
7. App-wide pass (§1 R5 literals, §5).
8. Verify (§9) and update the agent handoff.

## 9. Verification (from AGENTS.md)

```sh
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO test
swift test --package-path GlassTableDrills
tools/uisweep.sh --screen freeplay   # also play-hand, play-hand-2, play-hand-3, play-guide
tools/uisweep.sh                      # full sweep before the last commit
```

- Sweep defaults to large and AX5; inspect both. Check 2, 3 and 4 players, Korean and
  English. Language persists in the simulator; uninstall the app before English runs.
- UI tests: if a run is slow, add `-test-timeouts-enabled YES
  -maximum-test-execution-time-allowance 240`.
- Haptics can't be judged in the simulator; list them for an on-device check.
- `swift test -c release --package-path GlassTableEngine` only if the engine changed
  (it shouldn't).

## 10. Rules that still apply

- Don't reveal a correct choice before the user commits. Grades and reveals describe
  the same spot.
- Keep both Swift packages free of UIKit/SwiftUI.
- Offline, no accounts, analytics, ads or purchases. Chips have no value.
- Card-face glyphs fixed-size; ordinary text follows Dynamic Type; use `KO` helpers for
  particles on dynamic text.
- Never `git add .`; never force-push; never push to `main`; don't commit generated
  files, the untracked audit tooling, or secrets. Don't add or change a LICENSE.

## 11. Stop and ask if

- a change needs the engine, `progression.json`, or a new persisted setting;
- a rule here conflicts with a test that encodes a deliberate product rule;
- a string can't fit one line in one language without shrinking;
- anything in this file contradicts the code in a way that changes behaviour.

## 12. Visual references (local only, gitignored; this file wins)

- `.build/freeplay-direction-a/index.html`: round 2, motion catalogue and seat layouts.
  Superseded there: the "grow the dock" raise panel with a slider, the status sub-line,
  "내 차례예요" wording.
- `.build/freeplay-direction-a-2/index.html`: round 3, seat box, cards, gold.
- `.build/freeplay-direction-a-3/index.html`: round 4, buttons, raise, Math tiles.
  Its docks use 10–11 pt insets (mock scale); use §1 instead.
- `.build/freeplay-final/index.html`: spacing rules with measurements.

## 13. Owner-approved exceptions (2026-10-01)

- At accessibility text sizes, exact dock titles may wrap instead of shrinking or
  being shortened. Apply the same treatment to the table chrome when needed.
- Keep the native concentric dock/control corners. The measured step 1 candidate
  has 19.235 pt minimum corner clearance versus 20 pt at its straight sides; the
  owner accepts this 0.765 pt R4 exception. Do not replace it with a custom curve.
- At accessibility sizes, action buttons may grow to fit full scaled labels and
  prices, including wrapped Korean prices; normal-size buttons remain 87 pt.
- Raise − / + uses one-chip steps instead of two, so every legal whole amount is
  reachable. Holding and limit behavior otherwise follow §4.
- Fix the Drills Facts made-hand evaluation call to use the existing engine
  `bestHandOfAny` for five-to-seven cards, with regression tests. No engine changes.
- Correct short-call Math using publicly contestable pot amounts instead of the
  raw pot-plus-call denominator. Include short-call/refund regression coverage.
  These four recommendations were explicitly approved by the owner on 2026-10-01.

- Math odds use N dots in two columns for 1 in N (N = 2–6), with one filled
  dot. The 1-in-4 case remains a 2×2 square. This replaces the contradictory
  fixed 2×2 requirement for other denominators; the owner explicitly approved it.
- At AX5, the three Math tiles stay in one horizontally scrollable row, each
  wide enough for full text and an unsplit percentage. Normal-size Math remains
  three tiles across. The owner explicitly approved this accessibility layout.
