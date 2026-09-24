# Prototype verification

Date: 2026-09-22
Scope: browser interaction proposals only; no production app implementation

## Baseline and evidence

- Baseline main: `85dcfcf`.
- Fresh existing-app capture: `tools/uisweep.sh --screen drill-potmath` on the
  disposable iPhone 12 mini simulator, normal and AX5 text. Both images inspected.
  Raw evidence: `.uisweep/20260922-215440-1KUuwg/`; normal capture copied here as
  `current-screen.png`. The physical iPhone and its progress were not touched.
- Read-only engine/UI audit confirmed the initial value 10 and one-chip stepper,
  existing course worked examples, and direct entry from free practice.
- Fixture arithmetic: `1 + 2 + 6 + 6 + 16 + 12 = 43`; contributions by player
  `1 + 18 + 18 + 6 = 43`; last action `31 + 12 = 43`; half-pot `21.5 → 22`.
- Distractors are authored misconception hypotheses, not measured user behavior.

## Contrast measurements

Measured with the antislop-human contrast checker. Normal-text threshold 4.5:1.

| Foreground / background | Ratio | Result |
|---|---:|---|
| Muted `#c2cbc3` / raised surface `#1c3026` | 8.42:1 | PASS |
| Ivory `#f7f4ec` / surface `#16261e` | 14.36:1 | PASS |
| Ink `#09140f` / mint `#6fd3a0` | 10.28:1 | PASS |
| Error `#f1a69a` / surface `#16261e` | 8.02:1 | PASS |
| Mint `#6fd3a0` / surface `#16261e` | 8.65:1 | PASS |

The prescribed prototype picker is review chrome, not proposed native app UI.

## Browser pass

Final HTML SHA-256:
`087d593bf24e845f90abbc8bce7fda1ab850024444f454b5ced340788453bc6e`

| Check | Result | Evidence |
|---|---|---|
| Three distinct directions | PASS | Spatial replay, simultaneous player trays, guided last-action quantities visually inspected |
| Intro and returning entry | PASS | Worked example expands; short returning reminder and full-intro replay work |
| Replay integrity | PASS | Intermediate frames hide choices; final-frame jump works; unacted players say so |
| Answer interaction | PASS | Equal-weight choices, selection before confirmation, disabled empty confirmation |
| Specific feedback | PASS | Exercised 45 double-count, 49 extra-call, 37 under-call and 21 rounding corrections |
| Completion | PASS | Correct answer → half-pot question → completion exercised in all three directions |
| Keyboard/focus | PASS | Choice focus retained, feedback heading focused, help traps Tab and Escape restores trigger |
| Compact layout | PASS | Inspected 375×812 viewport; reachable scrolling controls without app-content horizontal overflow |
| 200% text | PASS | All three question layouts inspected; body text measured 32px; no app-content horizontal overflow |
| Control targets | PASS | App question controls measured at least 44px; picker is separate review chrome |
| Runtime errors | PASS | Browser warning/error log empty after interactions |
| Scope | PASS | Production Swift, engine, progression and device data unchanged |

Visual review corrected an inaccurate double-count explanation, an intermediate
replay/answer mismatch, lost keyboard focus, missing returning intro, misleading
not-yet-acted player labels, and a cramped action caption before handoff.
The prototype and accessibility skills shaped equal-weight choices, restrained
motion, measured contrast, responsive reflow and explicit non-shipping boundaries.

## Review boundary

Native Dynamic Type, physical VoiceOver, generator-wide distractor coverage,
progress compatibility and App Store acceptance are not established by HTML
prototypes. The owner must critique/select a direction before implementation.
