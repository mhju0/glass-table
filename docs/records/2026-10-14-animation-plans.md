# Animation audit plans 001-003

- **Date:** 2026-10-14
- **Kind:** audit
- **Originals:** `plans/README.md`, `plans/001-board-cards-enter-near-full-size.md`, `plans/002-skill-glyph-accent-settles-quickly.md`, `plans/003-hand-typed-curves-use-motion-tokens.md` (tracked: `git show f5c5e22:plans/<file>`)
- **Asked by / for:** written by the `improve-animations` audit at commit `9664c0a`

## What it was
Three self-contained implementation plans from an animation audit. Execution order 003,
002 (uses 003's `GT.Motion.fade`), 001 (independent). All three marked DONE.

## Findings and decisions
- 001 MEDIUM, physicality: on scripted tables (every `TableSurface` without
  `freeVisuals`: guided hand, walkthroughs, lesson tables) new board cards grew from 60%
  (`TableSurface.swift:440-444`). Target: insertion `.scale(scale: 0.92)` + opacity,
  removal unchanged; do not touch the `freeVisuals` flip branch or callers (they already
  use `withAnimation(reduceMotion ? nil : GT.Motion.change)`). Done when no board-card
  insertion scales below 0.9.
- 002 LOW, easing: `SkillGlyph` accent (lesson session list, `NodeSessionView.swift:1064`)
  animated from 0.6 scale over 450ms after a 150ms delay, 600ms total every visit. Target:
  `GT.Motion.fade`, no delay, start at 0.9; keep the Reduce Motion branch and the
  `settled`-driven dot (1.4) and equity bar. Done when SkillGlyph has no hand-typed curve
  or `.delay`.
- 003 LOW, tokens: four hand-typed curves (0.15 ease-in-out `TableSurface.swift:294`; 0.2
  ease-out with `duration: 0` for Reduce Motion `FreeTableHandCoachView.swift:57`; 0.15/0.22
  ease-out `FreeTableView.swift:446`; raw 0.22 timing curve `PotMathLessonView.swift:63`).
  Added `GT.Motion.fade = timingCurve(0.23, 1, 0.32, 1, duration: 0.2)` and
  `GT.Motion.move = timingCurve(0.77, 0, 0.175, 1, duration: 0.22)`; the pot lesson keeps
  0.22 because a `Task.sleep(220ms)` depends on it. Left alone on purpose:
  `FirstLessonView.swift:1071` `.easeOut(duration: 1.2)` glow (deliberate slow pulse).
  Done when only `Theme.swift` and that line hold hand-typed curves.
- Feel checks for all three: Debug ▸ Slow Animations in the simulator, plus Reduce Motion.

## Outcome
Plans added in `691d76d`; implemented in `4405ec7` (003), `15d4575` (002), `0a12f4a`
(001). The plan files' "Commit: 9664c0a" field is the audit base, not the fix commit.
Shipped in build 29 (source `5de390c`).

## Still open
Nothing.
