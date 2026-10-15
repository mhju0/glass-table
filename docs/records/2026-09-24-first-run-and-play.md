# First run, answer feedback, thumb reach, Play setup and Learn

- **Date:** 2026-09-24 (to 2026-09-25)
- **Kind:** spec notes
- **Originals:** `.scratch/first-run-and-play/spec.md`, `.scratch/first-run-and-play/issues/01..06-*.md` (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner decisions saved through the decision forms of two research pages

## What it was
A spec plus six issues, all marked done, turning two owner-approved research pages into
work: first-run feedback, bottom-anchored choices, Play home and setup, 2/3-player tables
and Learn tab cards. `docs/decision-history.md` cites issues 01-06 and the spec as evidence.

## Findings and decisions
Owner decisions (spec):
- First run (research https://claude.ai/artifact/GtEjHzej3EBAdBHpcxwb6y): feedback C (tint
  the picked answer and result panel, ✓/✗ and words, one glow pulse, success/error haptic);
  bottom choices on every question screen; two welcome screens (welcome, how it works)
  before two labelled warm-up hands; wording A: "시작 안내 · 워밍업 1/2" / "안내 건너뛰기"
  ("Getting started · Warm-up 1/2" / "Skip guide").
- Play and Learn (research https://claude.ai/artifact/V5KZHG2vvdfanBK2xDwNG8): per-seat
  opponent styles with a mixed default; Play home with two mode cards (free table, graded
  1:1), graded 1:1 stays in Play; 2/3-player tables as a later step; Learn shows the
  starting-point card on top until the first completed lesson; anything tappable is a
  filled button or bordered card, app-wide.
- Derived rules: look at the top, decide at the bottom. Green/red mean right/wrong only;
  amber means the learner's own selection. Colour never carries a verdict alone.

Issues:
- 01 First-run guide: welcome and how-it-works before warm-up 1/2 and 2/2; choices and
  result in the bottom sheet; pick shows ✓/✗ 내 답, after a miss the winner shows ✓ 정답;
  sheet tinted by grade. Acceptance: UI tests for order, wrong-pick marking, skip, replay
  and AX5 reachability; KO dark screenshots at large and AX5.
- 02 Tint every graded reveal sheet (and the AX card) by band across RevealSheet,
  PotMath, EVLoss and Defend (`VerdictRow` already had ✓/±/✗, words, haptic).
- 03 Bottom-choice audit (2026-09-25): `PotMathDrill` moved onto `DrillShell` (test
  `testPotMathChoicesSitInTheBottomSheet` failed before, passed after); `PlacementView`
  answers anchored to the bottom of a viewport-height column as bordered cards.
  `LearningGuideView` retrieval questions left inline (reading page, not graded).
  Plain-text tappables converted: 이전 이야기, 확인 없이 시작하기, 다른 개념 고르기, 저장 다시
  시도 x4 → `SecondaryCTAButton`; 아직 잘 모르겠어요 → bordered card; 다시 저장 and 계산 방법
  → bordered capsules; all six `DisclosureGroup`s → `GTDisclosureStyle`. Exempt on
  purpose: nav-bar chrome, system alerts, Settings rows, and 새로 시작하기 on the recovery
  screen (a last-resort reset should stay quiet).
- 04 Play home and setup: headline plus `TapCardLabel` cards `play-free` and
  `play-graded`; `TableSetupView` with three seat rows and a `Menu` style chip
  (`seat-style-1…3`, default 신중형 / 콜 위주형 / 공격형), style guide sheet, `table-start`
  at the bottom; seats and hand review name each style; "다른 상대 고르기" became
  "테이블 바꾸기". Saved table format already stored three styles, so no schema change.
- 05 2/3-player tables (owner chose after 04; done with delegated autonomy):
  `PracticeTableState` seats `styles.count + 1`. Heads-up: button posts the small blind
  and acts first preflop; big blind acts first after the flop. No new save fields; a
  four-seat deal is byte-identical (`fourSeatDealIsUnchanged`). 인원 control 2/3/4
  (default 4). Tests `PracticeTableSeatCountTests`, `testTwoPlayerTableSeatsOneComputer`.
- 06 Learn rows use `TapCardLabel` (`learn-path`). Until any node is cleared, a panel
  under the recommendation holds `placement-start`; afterwards it becomes the
  `placement-row` card. Test `testStartingPointLeadsUntilTheFirstLessonThenMovesBelowPractice`.

## Outcome
Shipped 2026-09-25: `4aac931` (01), `ff691fe` (02), `fdf6ca3` (03), `5b63deb` (04),
`5e689ca` (05), `bda2056` (06). Later superseded in parts: the warm-up opening by the
experience-first and brand openings (builds 20-22), the casual default style (see the
2026-10-15 screenshot audit record).

## Still open
Nothing.
