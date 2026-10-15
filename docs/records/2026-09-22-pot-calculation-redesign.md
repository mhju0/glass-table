# Pot calculation redesign mocks and palette comparison

- **Date:** 2026-09-22 (to 2026-09-23)
- **Kind:** research
- **Originals:** `.scratch/pot-calculation-redesign/` — `spec.md`, `verification.md`, `hybrid-verification.md`, `palette-research.md`, `index.html`, `hybrid.html`, `hybrid.test.cjs`, `palette.test.cjs`, `current-screen.png` (tracked: `git show f5c5e22:.scratch/pot-calculation-redesign/<file>`)
- **Asked by / for:** owner; browser mocks to critique before any native work. `DESIGN.md` lines ~143 and ~167 link `hybrid.html` and `palette-research.md`

## What it was
Three interactive HTML directions for the pot-counting lesson (`index.html`), then an
owner-approved table/tray hybrid (`hybrid.html`) with tests, then a palette comparison.
Baseline `85dcfcf`. `current-screen.png` was the uisweep `drill-potmath` capture
proving the old stepper screen.

## Findings and decisions
- Observed problem: `PotMathDrill` (`ConceptDrillView.swift:339-404`) started the answer
  at 10 with a one-chip stepper and listed actions as text; a 43-chip answer needed 33
  taps. Free practice opened the drill with no orientation.
- Directions: Table replay (actions on seats; connects action to chips, more navigation),
  Contribution trays (chips grouped by player; easy to check double-counting, less like a
  live hand), One decision (before/after of the last contribution; low load, but supplies
  an intermediate pot). All: intro, question, selection, confirmation, specific feedback,
  three equal-weight choices.
- Fixture (43 chips): SB 1, BB 2, A raises to 6, B calls 6, BB raises to 18 (adds 16), A
  calls 12, stop. `1+2+6+6+16+12 = 43`; by player `1+18+18+6`. Distractors (hypotheses,
  not measured): 45 double-counts BB's 2; 49 adds 18 instead of 12; 37 adds 6 instead of
  12. Half-pot `43 x 50% = 21.5 → 22` under the engine rule; 21 truncates.
- Owner approved the table-led hybrid and the broader beginner-accessible direction
  (2026-09-23): explain vocabulary, roles, action order, why and how at first encounter;
  stepper is not the main format. Hybrid: contribution trays inside the table, one
  current-actor marker, replayable actions, aggregate pot hidden before commitment,
  neutral wrong feedback with the calculation behind a disclosure.
  Fixtures 3-6 players: pots 37/43/49/55 over 6/7/8/9 actions; the folded SB's 1 stays
  in the pot.
- Owner simplification (2026-09-23): only 3/4 players (37/43); one short caption inside
  the active seat; removed context paragraph, clockwise line, action counter and
  explanation panel. Motion 2 exception: one decorative chip travels to the centre on a
  pointer-triggered forward step, WAAPI transform/opacity, 220ms,
  cubic-bezier(0.77,0,0.175,1); never on keyboard, backward, fold or reduced motion.
- Palette: owner found green-on-green hard to read. Compared Charcoal+Amber
  (`#17191c`/`#2b2e32`, table `#153d33`, text `#f4f0e6`, accent `#edc17f`; agent
  recommendation), Slate+Blue, Paper+Pine. Min text contrast 7.44 / 6.61 / 4.62:1;
  min boundary 3.47 / 3.93 / 3.16:1; `palette.test.cjs` passed 75 token pairs. Sources:
  Atlassian colour roles, Radix scales, WCAG 2.2 contrast.
- Verification (browser only): `node hybrid.test.cjs` passed (legal clockwise order, full
  raises, folded chips, one correct of three unique choices, no early-reveal frame);
  375x812 at normal and 200% text: zero overflow, clipping or targets under 44px; console
  clean. Mid-flight motion not captured. HTML hashes: `index.html`
  `087d593b…bc6e`, final hybrid `47a45875…68c2`, palette candidate `bc0fc463…45dd`.
- Research cited: Apple onboarding (short, optional, near the UI), IES practice guide
  (worked examples alternating with practice), CMU assessment guidance (plausible
  misconception distractors, varied answer position). Production should generate
  distractors from the actual spot, reject duplicate/negative/correct ones and balance
  positions.

## Outcome
Native delivery `b8fe193` (2026-09-23, `docs/specs/2026-09-23-pot-appearance.md`):
green table with amber actions, warm light / charcoal dark surfaces, 3/4-player trays,
one active-seat caption, previous/next, three shuffled answers, first-entry intro. Mocks
kept as design history in `ac25165`.

## Still open
Mock-scope limits, never addressed by the mocks: native Dynamic Type and VoiceOver,
generator-wide distractor coverage, side pots/all-in and postflop sequences. The Swift
generator then had 4/5 participants and no explicit fold, so mock fixtures were not
claims about native generation.
