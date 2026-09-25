# Hybrid mock verification

The first report below records the previous three-to-six-player revision.
The latest three/four-player revision and its hash are recorded at the end.

Date: 2026-09-23
Baseline: `85dcfcf`
Scope: local browser mock, not native app delivery
Frozen HTML SHA-256: `c6b7fe01b10ac12ba1fb4800001fcd709533f6feb3c36f6513c690234c3b4b43`

## Automated source/model check

Command: `node .scratch/pot-calculation-redesign/hybrid.test.cjs`

```text
PASS: 3 players, 6 actions, 37 chips; order, prefixes, fold, raises and choices
PASS: 4 players, 7 actions, 43 chips; order, prefixes, fold, raises and choices
PASS: 5 players, 8 actions, 49 chips; order, prefixes, fold, raises and choices
PASS: 6 players, 9 actions, 55 chips; order, prefixes, fold, raises and choices
PASS: 2 inline scripts parse; copy and dependency checks
```

Tests run the actual pure model extracted from the HTML, not a parallel fixture
implementation. Each prefix preserves participants, legal clockwise turns,
nonnegative additions, full raise sizes, call targets and retained folded chips.
Each scenario has exactly three distinct positive choices and one correct choice.
The last frame is a real call, not an extra stop frame revealing the result early.

## Browser interaction evidence

| Interaction | Result | Observed outcome |
|---|---|---|
| First introduction | PASS | Why/how copy visible; starts with SB post and no answer choices |
| Returning introduction | PASS | Direct question entry; full introduction remains replayable |
| Participant selectors | PASS | All four change the rendered players and amounts |
| Full six-player replay | PASS | Nine real actions, correct actor each frame, aggregate pot always `?` |
| Previous / final jump / restart | PASS | Intermediate frames hide choices; final jump restores three choices |
| Choice and confirmation | PASS | Selection retains keyboard focus; empty confirmation disabled |
| Incorrect answers, all counts | PASS | Neutral correct total, no claim about the learner's mistake |
| Correct answers, all counts | PASS | Matching totals 37/43/49/55 and success wording |
| Calculation disclosure | PASS | Closed after answer; opens actual per-player equation on request |
| Retry | PASS | Clears the committed answer and allows a new selection |
| New example | PASS | Six-player answer advances to a fresh three-player example |
| Help | PASS | Opens, traps Tab, closes by button/Escape; Escape restores trigger focus |
| Help at 200% | PASS | Entire dialog and close control fit 375×812 viewport |
| Console | PASS | Captured warning/error log empty |

## Layout evidence

Rendered three-, four-, five- and six-player tables were inspected at normal
text on the compact viewport. At 200%, contributions reflow into one ordered
column; representative seats, feedback, calculation and controls were inspected.
The final DOM geometry matrix covers every count at both sizes:

| Players | Body text | Horizontal overflow | Clipped app elements | Seats outside table | App targets under 44px |
|---|---|---:|---:|---:|---:|
| 3 | 16px / 32px | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| 4 | 16px / 32px | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| 5 | 16px / 32px | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| 6 | 16px / 32px | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |

Viewport override: 375×812, reset after testing. The browser's scrollbar occupies
part of the available width. Normal-layout clockwise seat positions remain fixed
through replay; large text prioritizes readable source order over a spatial map.

## Design and accessibility gate

- PASS, copy/honesty: no em dashes, marketing statistics, testimonials, proficiency
  claims or unlabeled live-data claims. The examples are marked as mock fixtures.
- PASS, functionality: recorded click-through above covers rendered controls;
  all data is local and synchronous. Network loading/empty/error states and
  theme toggles are not applicable; no artificial loading states were added.
- PASS, contrast: measured muted `#c2cbc3` on `#20372c` 7.68:1, ivory on surface
  14.36:1, ink on mint 10.28:1, error text on surface 8.02:1. Control edges tested
  at 3.43:1 and 3.57:1, answer edges 5.01:1, table boundary 3.17:1.
- PASS, keyboard: visible mint focus, retained selected control, focused feedback,
  trapped modal and Escape restoration tested. Status wording supplements color.
- PASS, mobile: no clipping or horizontal overflow in the eight-case matrix;
  controls remain in normal scrolling flow, with at least 44px hit areas.
- PASS, purpose: felt, typography, contained seats, contribution hierarchy,
  current-actor marker and optional detail have explicit reasons in `spec.md`.
  No decorative gradients, unrelated icons, continuous animation or stock art.
- PASS, liveliness/quality: ENERGY 1 / RHYTHM 2 / MOTION 1 follows DESIGN.md.
  The table is the focal point, mint marks active state, and structural spacing
  separates the situation, sequence and answer. This is a poker lesson rather
  than a generic dashboard. Changes use source edits, not rewrite scripts.

## Preservation and limits

Original `index.html` SHA-256 remains
`087d593bf24e845f90abbc8bce7fda1ab850024444f454b5ced340788453bc6e`.
No Swift, engine, progression, phone data, installation, GitHub or release changes.
Native Dynamic Type, VoiceOver, generator coverage, side pots/all-in behavior and
App Store readiness remain unverified and outside this mock. This pass validates
the authored interaction for critique, not learning efficacy or native delivery.

## Simplified revision verification, 2026-09-23

Frozen HTML SHA-256:
`47a45875825eff78b1a8a41093d8495ff2fe4a90628d8a67168024a6666668c2`

`node .scratch/pot-calculation-redesign/hybrid.test.cjs` passed:

- Three players: six actions, 37 chips; four players: seven actions, 43 chips.
- Legal clockwise order, full raises, prefix sums, folded contributions and
  exactly one correct answer among three unique choices.
- Unsupported participant counts rejected; both inline scripts parse.
- Every rendered frame has one active seat, no removed text panels, a hidden
  aggregate pot and answer choices only at the stopping frame.
- Stubbed-DOM motion test verifies transform/opacity, 220ms duration and both
  system/review reduced-motion guards. This does not establish animation feel.

| Browser check | Result | Evidence |
|---|---|---|
| Load and console | PASS | Rendered content; captured warnings/errors empty |
| First intro / replay intro | PASS | Blind-first entry; full introduction replay works |
| Returning intro | PASS | Direct entry to final question |
| Three/four selectors and question selector | PASS | Correct seats and three choices |
| Previous / next | PASS | Four-player full replay; backward hides choices; next restores them |
| Correct / incorrect, both counts | PASS | 37/43-chip feedback; no inferred error diagnosis |
| Confirm / retry | PASS | Empty confirm disabled; retry clears answer; keyboard Enter works |
| Calculation disclosure | PASS | Three-player equation expands to 1 + 18 + 18 = 37 |
| New example | PASS | Cycles three to four and four to three |
| Help | PASS | Button close, Tab trap, Escape and restored trigger focus |
| Enlarged help | PASS | At 375×812, dialog bounds y94..718 |
| Reduced-motion toggle | PASS | Static caption/amount update; no decorative chip remains |
| Keyboard next | PASS | Advances blind action without chip movement |
| Text-size toggle | PASS | 16px to 32px and back; ordered single-column seats |

Final geometry at 375×812, all three/four-player normal/200% combinations:
zero horizontal overflow, clipped app elements, out-of-table seats or app targets
under 44px. Normal and enlarged screenshots were visually inspected. The browser
viewport override was reset after verification. No native Dynamic Type or
physical VoiceOver result is implied. The 220ms transient motion was not captured
mid-flight; timing/curve/reduced guards have source and stubbed-DOM evidence.

Design gate for this revision:

- PASS, hard gate: source copy/dependency tests and click-through above; unchanged
  verified palette. Enlarged labels remain readable. New mint action text against
  seat surface measures 8.65:1 using the skill contrast checker. Local synchronous
  fixtures have no network loading/error state; no fabricated loading was added.
- PASS, purpose: one actor caption replaces redundant prose; chip movement links
  contribution and center without moving readable content. No new decorative art,
  gradients, marketing claims, remote libraries or dead controls.
- PASS, liveliness: energy 1 / rhythm 2 / local motion 2, documented in DESIGN.md.
  The table remains the focal point and the active seat uses the mint accent.
- PASS, craft: source patches only; matching Korean voice and existing identity;
  motion alternatives and mobile geometry checked. Intro/help retain terminology.

Original `index.html` hash remains unchanged at
`087d593bf24e845f90abbc8bce7fda1ab850024444f454b5ced340788453bc6e`.
Changed this turn: hybrid HTML, its tests/spec/evidence, DESIGN.md and handoff.
No native source, installation, progress data, commit, push or GitHub change.
