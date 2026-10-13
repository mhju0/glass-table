# 03 — Free table: lopsided seats at 2 and 3 players

Type: research
Status: resolved

## Question

Why does the table look off-balance with 2 or 3 players, and how should seats sit?

## Answer (findings, 2026-10-11; decided)

Evidence: `evidence/seats-2-3-4-and-graded.jpg` (sweep `.uisweep/20261011-200838-2jdX4x`).

- Seats are placed on a fixed 2×2 grid and the learner is always bottom-right
  (`FreeTableView.swift:320-324`). With 2 players the opponent is top-left and
  the learner bottom-right, leaving two empty corners on a diagonal. With 3,
  bottom-left is empty.
- `TableSurface` already supports a bottom-centre seat
  (`TableSurface.swift:97-102`; used by `PotMathLessonView.swift:102`). There
  is no top-centre place.
- Seat place also drives the bet-chip offset, fold motion and corner shape
  (`TableSurface.swift:253-256, 296, 366-385`), so moving seats touches the
  motion screens (`play-motion-2`, `play-motion-3`).

Options:

1. Centre the learner at 2 and 3 players (bottom-centre). At 2, the opponent
   sits top-centre (new place); at 3, the two opponents stay top-left and
   top-right. 4 players unchanged.
2. Keep the learner bottom-right at every table size so "my seat" never moves,
   and accept the empty corners.

Recommendation: option 1.

## Decision

Decision (owner, 2026-10-11): option 2. The learner stays bottom-right at every table size for consistency; no seat changes. Mocks of option 1 kept in `evidence/mock-seats-*.jpg`.

## Comments
