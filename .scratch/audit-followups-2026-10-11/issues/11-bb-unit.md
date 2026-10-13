# 11 — bb unit in advanced lessons and the graded table

Type: research
Status: resolved

## Question

Beginner screens count in chips; advanced lessons and the graded table count in
bb. Is that a problem, and what should change?

## Answer (findings, 2026-10-12; decided)

- Chips: opening guide, Hold'em basics, pot counting, the pot-odds lesson
  (capture `evidence/hint-entry-points.jpg`, "팟 10칩"), and the free table.
- bb, often with decimals (13.1bb, 5.6bb): EV call, call/fold, range advantage,
  EV loss, defend drills (`ConceptDrillView.swift`: `EVCallDrill`,
  `CallFoldDrill`, `RangeAdvantageDrill`, `EVLossDrill`, `DefendDrill`), the
  graded table (`TableView.swift:336`), Records, and the Drills package
  (`Table.swift`, `EVLoss.swift`, `Estimation.swift`, `RangeRead.swift`).
- bb is explained in at least eight places with three different sentences:
  "빅 블라인드 한 개만큼의 칩" (`TableView.swift:92, 191`,
  `ConceptExplainView.swift:113`, `LessonLearningUI.swift:183`),
  "빅블라인드 1개를 기준으로 한 단위" (`GradedTableLearningUI.swift:27, 30`),
  "빅 블라인드를 1로 보는 단위" (`LearningGuideView.swift:142, 184`).
- The study guide's pot-odds example is written in bb
  (`LearningGuideView.swift:142, 184`) although the pot-odds lesson itself
  uses chips.
- Spelling varies between "빅 블라인드" and "빅블라인드" in source.

Options:

1. Keep both units, tidy the seam: one explanation sentence and one spelling
   everywhere; study-guide examples for chip-based lessons in chips; the first
   bb lesson opens with the explanation once.
2. Convert everything to chips. Large change: decimal bb amounts, grading copy
   and the Drills package would all need new numbers and tests.
3. Leave as is.

Recommendation: option 1.

## Comments

## Decision

Decision (owner, 2026-10-12): option 1. Keep chips and bb; one explanation sentence everywhere ("bb는 빅 블라인드 한 개만큼의 칩이에요"), one spelling ("빅 블라인드"), study-guide examples for chip-based lessons in chips, and the first bb lesson opens with the explanation once.
