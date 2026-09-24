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

## 2026-09-25: First run, Play/Learn redesign, 2–4 player tables (autonomous)

- Branch `feat/shared-learning-table`, not pushed. Owner chose on two research
  pages (first run; Play/Learn), then delegated the rest while away. Owner-facing
  record of every decision and why: [`decision-history.md`](decision-history.md).
- Commits: `4aac931` first-run guide; `ff691fe` verdict-tinted sheets; `5b63deb`
  Play home with two mode cards and per-seat table setup; `bda2056` bordered Learn
  rows, starting-point card steps down after the first lesson; `fdf6ca3` pot
  answers in the bottom sheet, app-wide tap-rule audit (`TapCardLabel`,
  `GTDisclosureStyle`); `5e689ca` 2/3/4-player free tables (`seatCount =
  styles.count + 1`, heads-up blind rule, four-seat deal pinned by fingerprint).
- Line-parity audit of all screens changed this session (iPhone 12 mini, KO/EN,
  large): 10 violations found and fixed by copy rewrites (Play, setup, Learn,
  first lesson, three style descriptions); 0 remain. AX5 check found the first
  lesson's ✓/✗ badge covering the card title; at accessibility sizes it now sits
  above the title.
- Exemptions from the tap rule (nav chrome, alerts, Settings rows, recovery
  "새로 시작하기", the guide's inline retrieval questions) are listed in
  `.scratch/first-run-and-play/issues/03-bottom-choice-audit.md`.
- Open: push to `main` held until the owner confirms in their own words; issues
  03/04 above; the setup's segmented control is low-contrast in dark mode.
- Next: owner tries the installed build and confirms the push.
