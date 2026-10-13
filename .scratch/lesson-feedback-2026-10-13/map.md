# Lesson feedback, 2026-10-13 (owner, build 24 on iPhone 12 mini)

Branch `feat/lesson-feedback-clarity`. Mocks: https://claude.ai/artifact/9GBTnNb66MwufA7B19rG7e

## Done in `456b9ca`

1. Best five reads most important card first (`bestFiveCards`): made part, then kickers high to low; straights top down, wheel ace last.
2. Lesson and guide hole cards show high card first (`ThreeRegionCardTable`).
3. Outs answer: groups shown open (no toggles), strongest hand first, cards ace first. Same in the saved-answer view. Worked-example card grids also ace first (`BeatScript.byRank`).
4. Rule of 2 is explained in the sentence that first names it (outs worked example, both languages).
5. Hint box ("푸는 방법"): own header and content with equal padding; the last line no longer touches the bottom edge.
6. Pot worked example: 12pt between the choice row and the Previous/Finish row; secondary buttons are now the same height as primary ones app-wide.

## Done after the owner chose F2 and S1 (2026-10-13)

7. F2 in "A hand together" and the pot worked example: the choice buttons stay in place after an answer; the pick turns green or red with an icon, the right answer is marked green after a miss, the rest are locked (dashed). The bottom panel takes the verdict's tint and outline and holds "맞아요 / That's right" or "아쉬워요 / Not quite", the reason and Next. Next is on screen from the start, disabled until answered. Haptic and sound via `AppFeedback.answer`.
8. S1: pot example steps and the outs answer groups are white cards with a thin border; the current step has the gold outline. Explanation boxes inside a graded verdict are white with the verdict's colour as the edge (`gtExplanation(band:)`); the EV comparison box is white with a neutral edge. The hint stays grey.
9. The pot example no longer shows a second card that only repeated the last step's title.
10. At accessibility sizes an answered choice row keeps only the marked choices.

Limits: at AX5 the pot example's pinned panel still covers most of the screen on its last step (it did before answering already). A marked three-choice button wraps "24 chips" onto two lines on the 12 mini.

## Owner's answers to the open questions (2026-10-13): 1A, 1C, 2A, 3A

Mocks: https://claude.ai/artifact/8aPmc5HftjZcezcpN6TkYs

11. 1A, EV-loss lesson: a choice that lost any value shows amber ± "Near best" with the review sound instead of a green check (`EVLossReveal.shownBand`, live and saved). The stored band and progress are unchanged: a loss up to 0.5bb is still `.spotOn`.
12. 1C, "An opponent raised" lesson: one step off the chart stays amber and now plays the review sound, not the success one. Other lessons' `.close` answers still play the success sound (not asked).
13. 2A: `GT.Radius.panel` is 10, the same as controls, so cards, the hint, panels and buttons share one corner. Two 14pt boxes in the drills follow. Playing cards, pills and small grid cells keep their own shape.
14. 3A: the Play table, its hand review and the hand coach show hole cards high card first (`highCardFirst`); the table state keeps the dealt order.

## Near miss is wrong (owner, 2026-10-14)

15. Only an exact answer counts as correct. A near miss (amber, including an EV-loss choice that gave up any value) adds to the answer total but not to the correct count, adds to the miss streak, is scheduled as a hard review, counts as missed on the lesson result, goes under "Near" in Records, and plays the review sound in every lesson. Records now says "exact N%". Rule: `GradeBand.counted(evLoss:)`, `RoundAnswer.countedBand`. Stored bands are unchanged so saved answers still validate. Counts saved before this build are not recomputed.

Not decided: a lesson is marked cleared once every question is answered, right or wrong (`ProgressionModel.commitNodeAnswer`). The owner said only correct answers should count toward clearing; no pass mark has been chosen, so this is unchanged.
