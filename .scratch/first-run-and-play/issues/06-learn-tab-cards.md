# Learn tab: bordered rows and a real starting-point button

Status: done
Type: task

Bordered rows for path and focused practice. Before the first completed lesson,
the starting-point card sits under the recommendation with a button; after it,
it becomes a bordered row at the bottom.

## Outcome (2026-09-25)

- Learn rows use the shared `TapCardLabel` (bordered, icon, chevron); the path row is
  `learn-path`.
- Until any node is cleared, a panel under the recommendation holds the explanation
  and a bordered `SecondaryCTAButton` (`placement-start`). Afterwards it becomes the
  `placement-row` card at the end of "내 방식으로 연습".
- Test: `testStartingPointLeadsUntilTheFirstLessonThenMovesBelowPractice`.
