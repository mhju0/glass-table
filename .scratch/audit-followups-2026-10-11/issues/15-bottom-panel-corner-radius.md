# 15 — Bottom panel is rounded far more than the buttons inside it

Type: research
Status: resolved

## Question

Owner (2026-10-12): the big bottom rectangle holding the choices is rounded much
more than the buttons inside it, which looks awkward and inconsistent. The
buttons' roundness is the amount they like. Check across the app and fix.

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/bottom-panel-radius-opening.jpg`,
`evidence/bottom-panel-radius-free-table.jpg` — real renders from a throwaway
copy of HEAD (repo untouched), iPhone 17, light, normal text.

- One component draws every bottom panel: `ActionSheet`
  (`GlassTable/Sources/DesignSystem/Components.swift:642`). It is used by eight
  screens: opening guide, Hold'em basics, concept drills, concept explain,
  walkthrough, pot-count lesson, free table, graded table.
- On iOS 26 at normal text sizes its shape is `ConcentricRectangle` with a
  minimum of `GT.Radius.sheet` (28) (`Components.swift:715`): the corner follows
  the phone's own screen corner, about 54 pt on iPhone 17, and differs by
  device.
- The buttons inside use `GT.Radius.control` (14) and sit 20 pt in
  (`GT.Space.sheet`, `Theme.swift:58, 64`). Corners look nested when
  outer = inner + gap = 34; at 54 the panel is rounder than the buttons imply.
- The app's own scale is tile 8, control 14, panel 20, sheet 28
  (`Theme.swift:62-67`); the table felt uses 32 (`TableSurface.swift:69`).
- On older iOS and at accessibility text sizes the panel already uses 28 on the
  top corners only (`Components.swift:723`), so the mismatch is specific to the
  floating iOS 26 panel.

Options (one change in `ActionSheet`, applies to all eight screens):

1. Fixed 34: exactly nested with the buttons (14 + 20) and close to the felt's 32.
2. Fixed 28: the existing sheet token; slightly tighter than nested.
3. Leave it following the phone's corner.

Recommendation: option 1.

Not checked: other rounded containers that are not `ActionSheet` (system
`.sheet` presentations, cards) — those use the 20/28 tokens or the system shape.

## Comments

## Decision

Decision (owner, 2026-10-12): option 1. The floating bottom panel uses a fixed corner radius of 34 on every screen.
