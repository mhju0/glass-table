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

## Awaiting owner

- C. Which screen is "the fold example"? Candidates: defend lesson one-step miss shows amber `.close` and the success haptic; the EV-loss lesson shows green "Near best" with a check when the learner folds and calling was 0.2bb better.
- D. One corner radius for everything, or keep 20 for cards/hint and 10 for controls.
- E. Sort hole cards on the Play table too?
