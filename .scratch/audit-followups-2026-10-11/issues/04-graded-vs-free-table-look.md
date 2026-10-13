# 04 — Graded table and free table look different

Type: research
Status: resolved

## Question

Why do the graded (heads-up) table and the free table look like two different
apps, and should they be unified?

## Answer (findings, 2026-10-11; decided)

Evidence: `evidence/seats-2-3-4-and-graded.jpg` (rightmost tile is the graded table).

- Two renderers. `TableSurface` (green felt, seat tiles, pot chips in the
  centre) is used only by `FreeTableView.swift:301` and
  `PotMathLessonView.swift:46`. The graded table (`TableView.swift`) draws its
  own layout: no felt, opponent as a label with two card backs, large shared
  cards, "팟 13.1bb" as text, my cards centred.
- Units differ too: graded shows bb, free shows chips (queue item 11).
- This is already an approved decision that was never finished:
  `.scratch/consistent-learning-table/spec.md` (2026-09-23), decision 2, asks
  for one green table with seats, cards and pot in predictable places, and
  line 134 records that the two screens "use separate renderers today".
  Its ticket `issues/02-native-shell-table.md` is still `in-progress`.
- The spec also fixes a limit (line 112): sharing visuals must not merge the
  two poker policies or add an EV grade to the four-seat table.

Options:

1. Finish the approved work: draw the graded table with `TableSurface` (felt,
   opponent seat top-left, learner bottom-right, pot in the centre), keeping
   its chart/checkdown grading untouched.
2. Leave the graded table as it is and close the old ticket as won't-do.

Recommendation: option 1, done as its own step in the final pass because it
is the largest item in this list (the graded table has its own UI tests and
sweep screens `table-*`).

## Comments

- 2026-10-11 (Claude): owner said the graded table need not share the free
  table's UI and likes the large cards; still undecided, asked for app-accurate
  mocks. Built real renders in a throwaway copy of HEAD (repo untouched):
  A = as now, B = same layout on green felt, C = felt + seat panels + pot chips.
  Sheets: `evidence/graded-variants-postflop-{dark,light}.jpg`,
  `graded-variants-preflop-dark.jpg`, `graded-variants-after-answer-dark.jpg`.
  The seats-on-felt version (first mock, small cards) is out.
  In C the compact after-answer state stretches the panels full width and
  would need its own design.

## Decision

Decision (owner, 2026-10-12): variant B. Keep the graded table's layout and large cards; put the table area on the same green felt as free play (background and text colours only). No seat panels, no pot chips. The old consistent-learning-table ticket 02 is satisfied to this extent only.
