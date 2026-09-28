# Agent handoff

## Through 2026-09-24 — condensed 2026-09-25

The full entries are in [the 09-25 archive](handoff-archive/2026-09-25-before-autonomous-session.md)
and, for older work, [the 09-23 archive](handoff-archive/2026-09-23-before-combined-release.md).

- Shipped: combined beginner release (Learn / Play / Progress, 18 open concepts,
  optional placement, KO/EN, schema 2); Settings as the fourth tab; full-screen
  activities and the shared `TableSurface` ("Refined" look); bilingual line parity
  rule (`DESIGN.md`) with the native OCR audit in
  `.scratch/consistent-learning-table/native-audit/`; `KO.wordJoined`.
- Device: 2026-09-24 the owner asked for a fresh start. All app data was backed
  up to `.build/device-backups/20260924-before-reset/`, then 1.0 (8) installed
  clean. Restoring means copying those files back. Do not reset phone progress
  otherwise. An earlier worktree cleanup lost ignored evidence under `.build/`;
  archive before removing worktrees.
- Still open:
  - human/distribution gates: physical VoiceOver, minimum iOS 17, novice
    comprehension, signed distribution/Store validation, store screenshots,
    age rating/territories; save latency for very large histories;
  - two Position intro leaks awaiting review (expanded order line, highlighted
    button seat in the intro example table);
  - `KO.wordJoined` does not cover `Text("…")` literals or `Button`/`Label` titles;
  - shared table height (328 × 240/280) is a provisional readability tradeoff;
    the graded heads-up `TableView` and the Position strip keep their own renderers;
  - consistent-learning-table issues 03 (first-use explanations for all modes)
    and 04 (assisted attempts count as practice).
- `.scratch/pot-calculation-redesign/` is untracked on purpose (unrelated).

## 2026-09-25 — condensed 2026-09-27

Full entries: [the 09-27 archive](handoff-archive/2026-09-27-before-answer-pattern.md).

- Shipped: first-run guide, verdict-tinted sheets, Play home with 2–4 player tables,
  the Hold'em basics lesson, release roadmap (`docs/ROADMAP.md`) and small fixes.
- Still open: Phase 1 release work (counsel, Gmail, privacy and
  support pages, enrolment) is owner work.

## 2026-09-26 — condensed 2026-09-28

Full entries: [the 09-28 archive](handoff-archive/2026-09-28-before-spacing-rules.md).

- Shipped: explanations and assisted help (issues 03/04), rating prompt, daily reminder
  and share card, the device/AX5 sweep matrix and `AccessibilityAuditTests`, free
  practice in English, Progress fine print, the Play midline, whole-word large text,
  KO/EN parity rewrites, the contrast changes, builds 11 and 12, PR #7 merged to `main`.
- Proposal evidence from the removed `../glass-table-proposal` worktree is archived at
  `.build/archive/glass-table-proposal-uisweep`.
- Still open: the real notification permission dialog, notification delivery, share sheet
  and review dialog are unverified (system UI); VoiceOver hand pass postponed by the owner;
  after a swipe on Play the audit sometimes reports screen-wide findings with no element
  (scrolled audits skip contrast and Dynamic Type; cause not found).

## 2026-09-27: One answer pattern across lessons (build 13, branch `fix/lesson-answer-panel`)

- Owner picked option A from the answer-reveal mockups and asked for it everywhere
  (decision-history). A lesson answered in-session now keeps its live reveal:
  `ConceptDrillView` shows `RestoredDrillView` only for an answer saved before a
  relaunch. `RestoredDrillView` is rebuilt on `DrillShell` + `ActionSheet`; the showdown
  replay draws the same centred table with the winning five lit.
- `DrillShell` pins content to the top. On reveal it scrolls the drill's
  `revealEvidenceStart()` mark to the top, or to the end when a drill has no mark. Defend, EV loss and notation add their grid or range below the question
  instead of re-laying it out. The first lesson keeps the question and adds the marked
  hands below; its explanation moved into the sheet.
- `ActionSheet` folds when graded: tap the handle (`reveal-sheet-toggle`) or drag it.
  Content hides under `RevealDetail` / `\.revealCollapsed`. `VerdictRow` takes optional
  titles, used for the chart and EV verdicts.
- Audit method: a temporary UI test (not committed) answered the first question of all
  19 lessons with `GT_DEMO_NODE` and saved question / answer / folded screenshots at
  `large` on iPhone 16e.
- Open, reported, not fixed: hard-coded Korean particles after Latin seat names read
  "BTN는" (should be "BTN은"); `KO.endsInConsonant` treats Latin as a vowel. Sites:
  `Position.swift`, `DefendDrill.swift`, `RangeDrills.swift`, `Beats.swift`,
  `ConceptDrillView.swift`, `RestoredDrillView.swift`.
- Tests: full UI suite on iPhone 16e, 127 passed. `testShowdownWalkthroughAdvancesAtAccessibilityXXXL`
  also fails on unmodified `main` on that simulator (at step 7 the button is still "다음");
  CI passed it on its own device. Not investigated.

## 2026-09-27: Play grades like the lessons; Bold Text (branch `fix/lesson-answer-panel`)

- Resolved since the last entry: Korean particles after Latin seat names, digits and
  hand names now follow how they are read (`KO.finalSound`, commit 1739ab7).
- Play: `TableView.turnReveal` uses `VerdictRow` with the lesson words. `evPrices` and
  the chart button sit in `RevealDetail`. `sheetBand` tints the `ActionSheet` or the AX
  card only while a turn is graded and the hand is not over. At AX sizes `priceRow`
  puts its tag above the row, which fixes 최/선 and 내/선/택 breaking one syllable per line.
- Bold Text: `GT.title/semibold/body` read `UIAccessibility.isBoldTextEnabled` and step
  one Pretendard weight up. `Pretendard-ExtraBold.otf` is added: v1.309, from the same
  release as the bundled weights; its Bold is byte-identical. `GT.fixed` card glyphs
  stay Bold. `Font.custom("Pretendard").weight(_)` was tried: SwiftUI does not apply
  Bold Text to a custom family.
- Limit (open, by choice): the fonts are built when a view is built. A live toggle
  therefore reaches only views that redraw; reopening the app makes it consistent.
  An `.id(legibilityWeight)` rebuild would reset in-progress state such as a table hand,
  and above `RootView` it would create a second `ProgressionModel`.
- `tools/uisweep.sh` takes `GT_BOLD_TEXT=1`: it writes
  `com.apple.Accessibility EnhancedTextLegibilityEnabled` on the disposable simulator.
  A full bold sweep on the iPhone 16e (large + AX5) showed no mid-word breaks.
- Next: owner decides on merging to `main` and on a build 14 phone install.

## 2026-09-28: Floating sheets, light-mode contrast, hint pill (branch `feat/sheet-refresh`)

- Owner picked 1A/2B/3C/5A from the sheet-fixes options page (decision-history).
- `ActionSheet`: floats on iOS 26 (8 pt margin, `ConcentricRectangle` with a 28 pt
  minimum for Home-button screens); attached with 8 pt bottom padding on iOS 17–18 and at
  AX sizes. Grabber only when `band != nil`. The card reaches into the bottom inset only
  when that inset is the window's home indicator alone; under a tab bar (Play) it floats
  above the bar. `ignoresSafeArea` did not work from inside the screens' stacks, so the
  inset is measured with `onGeometryChange` and **rounded**: unrounded, it jittered and
  re-laid out ~1,750 times a second, which hung every UI query.
- Light mode: `felt` #EBE6DB (muted text 4.82:1), `cardFace` white, new `cardEdge` at 1 pt;
  dark mode unchanged. Hint pill `.fixedSize()`.
- New UI test `testAnswerSheetLeavesNoDeadBandUnderTheLastChoice` (old code: 56 pt, fails).
  Full suite on iPhone 16e (iOS 26): 71/72 UI pass; the known AX walkthrough failure remains.
- Open: the iOS 17–18 attached path is compiled but not seen. Xcode 27's CLI refuses to
  download any iOS 18 runtime; the owner needs to fetch it via Xcode Settings → Components
  or developer.apple.com, then `xcodebuild -importPlatform`.
- Open (carried): the handoff still names `../glass-table-proposal` for the proposal
  evidence; it was archived to `.build/archive/glass-table-proposal-uisweep`.

## 2026-09-28: Spacing rules R1–R4 (branch `feat/spacing-rules`)

- Owner approved R1–R4 and 1A–5A from the spacing audit (decision-history).
- Shared chrome: `gtChrome(leading:trailing:)` hides the system bar and puts a
  `GTChromeBar` in a top `safeAreaInset` with a felt strip behind it. `ChromeButton` puts
  its glyph on the content edge (18 page, 20 sheet via `gtSheetSurface()`); the bar's
  −9 pt bottom lets the title start 12 pt under the glyph. `safeAreaBar` was tried: its
  soft edge faded sheet titles and `.hard` clipped them, so it is not used.
- Insets: `GT.Space.edge/card/sheet`, `gtInset(_:)` (top = side, minus 2 pt leading) and
  `gtContentEdge()`. The drill header's ⓘ overhangs its row (−12 pt), so the header sits
  the same with or without it; the guided hint pill is 28 pt inside a 44 pt target.
- Hint popover: a ScrollView whose ideal height is the measured content. Its own frame
  reports the felt watermark's overflow, so the test measures `app.popovers`.
- Four new UI tests fail on the old code. Full suite on iPhone 16e: 75/76, the known
  AX walkthrough failure remains. Full light sweep on 12 mini (large + AX5) inspected.
- Resolved: the proposal evidence path (see the 09-26 summary above).
- Left alone on purpose: the Play landing's midline gap (`MidlineSplitLayout`).
- Open (carried): iOS 17–18 attached-sheet path still unseen (runtime download needed).

## 2026-09-28: iOS 27 launch freeze (branch `feat/spacing-rules`)

- Owner's iPhone 12 mini (iOS 27.0) opened to an unresponsive app; two watchdog reports
  (0x8BADF00D) showed the main thread in `AG::Graph::print_cycle` via
  `UIKitStatusBarBridge` ← `UIWindow.safeAreaInsets` ← `ActionSheet.reach` ← `body`.
- Fix: `RootView` measures its bottom safe-area inset and passes it down as
  `\.homeIndicatorInset`; `ActionSheet` no longer reads UIKit windows in `body`.
- Not reproduced on the iOS 27 simulator (Release build + the phone's own data ran at
  0% CPU), so the device is the only proof; check it after install.
- Next: intro redesign option A (owner chose it with all recommendations: "이렇게
  배워요" folds into the wrap-up, 족보 stays as 홀덤 기초 ladder + check, split-pot line).

## 2026-09-28: First-run guide follows one hand (option A)

- `FirstLessonView` steps: welcome → pot, blinds, actions, flow, bestFive (1–5/6) →
  warm-ups → wrapUp (6/6). Demo hooks `GT_DEMO_FIRST_LESSON=pot|blinds|actions|flow|
  best|wrap-up`; sweep screens renamed to match. `HoldemBasics.hole/board` is now the
  guide's hand (A♠K♥ on K♦7♣2♥9♠Q♥, a pair of kings leaving 7♣ 2♥ out).
- `HoldemBasicsView` keeps only ladder and check (1–2/2); the deal stepper is gone.
- Saved progress is untouched: `firstLessonCompleted` and `basicsLessonCompleted` keep
  their meaning.
