# Implementation reconciliation of device feedback (build 18)

- **Date:** 2026-10-08
- **Kind:** audit
- **Originals:** `docs/audits/2026-10-08-implementation-reconciliation/` (index.html, ledger.json, 28 screenshots in `assets/`, reconciliation-mobile.png), `.scratch/implementation-reconciliation-2026-10-08/` (build_report.py, ledger.json identical to the docs copy) (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner; check whether the 28 device-testing comments (from `.scratch/device-feedback-2026-10-07/feedback.json`), 20 earlier decisions D01-D20 and 26 five-perspective recommendations P01-P26 were really reflected in the native app.

## What it was
Read-only source reconciliation at repo head `7471843` (production source `49d9b01`). No app source changed, no native tests rerun, no phone data reset. "Implemented" meant the matching source path exists, never that every state or device passed. Headline: the redesign was substantial but not complete; earlier reports overstated completion by counting code presence and optional extras.

## Findings and decisions
- Totals: 18/28 comments source-implemented, 10/28 partial.
- Implemented: C001 welcome-first onboarding, C003 wrong-answer row alignment, C005 cumulative pot walkthrough with blinds, C006 replay controls/compact hint, C009 help example completion, C012 Chen score math optional, C014 compact reopenable cue, C015 your/correct answer rows, C016 Defend header, C018 Defend seeds cover Fold/Call/Re-raise across 3 questions, C019 curriculum order (showdown and turn cards before pot/percentages), C020 one-tap beginner answers (advanced calibration keeps manual entry by design), C023 Free Play help labels, C024 localized short player names, C025 ten-hand recap with exact denominators, C026 mid-hand end/new game, C027 completion-first Progress, C028 compact Settings with sound/haptic switches.
- Partial: C002 (varied hand types only behind an optional wrap-up button), C004 (narrator-voice audit unfinished; restored views keep raw terms and equity-as-win-chance), C007/C010 (restored position answers still show acronym strip and capped text), C008 (no full app-wide back/close audit), C011 (unexplained shorthand such as 3벳 on direct entry), C013 (Defend direct questions skip the chart primer), C017 (no optional "try without the chart" invitation), C021 (restored outs use individual card lists), C022 (guide variety mostly suit/player swaps and three fixed boards).
- Gaps for the next version:
  - G01 (C002/C022) make the main intro require trips/straight/flush comparisons, each explained, with skip and Previous.
  - G02 (C011/C013/P05/P25) teach chart reading and define 3-bet, bb, call/raise on first direct/graded entry.
  - G03 (C022) genuinely different repeated-guide questions with bounded repeat avoidance; never mutate a saved question.
  - G04 (C004/C007/C010/C021/D03) bring restored screens to the new components without changing grades or stored bytes.
  - G05 (D02/C011) equity wording must be wins plus share of ties in both languages ("How often do you win?" and Korean walkthrough were wrong); grading unchanged.
  - G06 (C008/C009) route-by-route Back/Close/edge-back acceptance on every help wrapper.
  - G07 (D16/P14) one complete beginner path compare -> pot -> call/check -> guided hand -> independent review.
  - G08 (D17/D18/P03/P04/P08/P09) sign-off matrix EN/KO x light/dark, mini normal/AX5, long values, restore, errors, scrolling, VoiceOver, physical feedback.
- D01-D20 dispositions: implemented/preserved D05, D06, D07, D08, D09, D11 (live), D12, D13, D14, D15, D19, D20; partial D01, D02, D03, D04, D10, D16; validation pending D17, D18.
- P01-P26: implemented P01, P02, P19, P22 (live), P23 (copy); preserved P06, P10, P16, P24; partial P05, P07, P12, P14, P21, P25; validation pending P03, P04, P08, P09; portfolio/non-app work P11, P13, P15, P17, P20; not done P18 (60-90 s walkthrough video), P26 (study with 5-8 no-poker beginners split KO/EN, cannot be replaced by fixtures).
- Approved decisions to keep (owner, earlier): bottom primary actions, calm felt/cards, one success confirmation, voluntary chart use, no public helped/solo labels, factual recap with no invented bluff/luck claims, reopenable hints instead of disappearing guidance. Legacy TodayView unused, not a regression.
- Screenshots: 7 screens (welcome, positions guide, guide pair wrong, defend chart, graded chart, progress, settings) x EN/KO x light/dark, native fixtures captured at `25e5218`, normal text; they showed current layout only, not verification.

## Outcome
Audit only; no code shipped from it. Evidence boundary it recorded: build-18 had 468 Drills tests, 121 app unit tests, targeted UI passes and 140 fixture frames; mini installs succeeded but first-run screens were not visually observed. `docs/build-history.md` later notes this ledger is "not a current completion verdict". Whether G01-G08 were closed by later work is not stated in these sources [Unknown].

## Still open
- G01-G08 as listed, as of 2026-10-08 (later status [Unknown] from these sources).
- P18 walkthrough recording and P26 real no-poker beginner study.
