# Implement the full-screen shell and shared table visuals

Status: in-progress
Type: task
Blocked by: 01

Use the approved prototype to replace lesson/practice sheet presentation and
share table/card components across applicable modes. Preserve Close/Back, resume,
hidden information and each mode's model. Support three/four-player pot examples
and existing position seat counts without changing curriculum to suit a diagram.

Acceptance: native UI tests for entry/exit/resume, measured stable table bounds,
card/fold/pot-state checks, and compact bilingual light/dark/AX5 screenshots with
scroll interactions. Do not claim browser checks establish SwiftUI behavior.

## Comments

2026-09-24: Owner scheduled this next (with 02, 03 and 04). Unblocked by 01.

2026-09-24: Full-screen shell, pot table and Play table done on
`feat/shared-learning-table` (see verification.md). Remaining: EN/light
screenshots, measured table bounds, and deciding whether heads-up `TableView`
joins the shared table.
