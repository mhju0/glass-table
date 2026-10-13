# 05 — Range advantage shows 59.6% and 59.1%

Type: research
Status: resolved

## Question

Why does the range-advantage reveal show 59.6% in one place and 59.1% in another?

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/range-advantage-two-numbers.jpg` (sweep
`.uisweep/20261011-200838-2jdX4x`, screen `drill-rangeadv-reveal`, seed 1).

- Not a calculation error. They are two different quantities that happen to be
  close on this board: 59.1% is the opener's win rate (the answer); 59.6% is the
  share of the opener's range in the strongest made-hand group, printed as the
  bar's headline by `BucketBarView.swift:37` ("페어 이상 N%").
- Neither number says what it measures: the answer row is labelled only "정답",
  and the bar headline sits above it in larger type.
- The same bar segment has two names on this paired board (10 10 A): the
  headline calls it "페어 이상" and the legend calls it "투페어 이상", both 59.6%.
- The "선택한 답 55%" in the capture is the sweep's injected demo answer
  (`tools/uisweep.sh:172`, `GT_DEMO_REVEAL=55`), not a real choice.

Options:

1. Name both numbers: answer row "오프너 승률 59.1%"; bar headline and legend
   use one name for the same group.
2. As 1, and drop the bar headline on this drill's reveal so the answer is the
   only large percentage; the legend keeps the group shares.
3. Leave as is.

Recommendation: option 2.

## Comments

## Decision

Decision (owner, 2026-10-12): option 2. Label the answer as the opener's win rate, use one name for the same bar group in headline and legend, and remove the bar headline on this drill's reveal.
