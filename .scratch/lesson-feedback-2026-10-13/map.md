# Lesson feedback, 2026-10-13 (owner, build 24 on iPhone 12 mini)

Branch `feat/lesson-feedback-clarity`. Mocks: https://claude.ai/artifact/9GBTnNb66MwufA7B19rG7e

## Done in `456b9ca`

1. Best five reads most important card first (`bestFiveCards`): made part, then kickers high to low; straights top down, wheel ace last.
2. Lesson and guide hole cards show high card first (`ThreeRegionCardTable`).
3. Outs answer: groups shown open (no toggles), strongest hand first, cards ace first. Same in the saved-answer view. Worked-example card grids also ace first (`BeatScript.byRank`).
4. Rule of 2 is explained in the sentence that first names it (outs worked example, both languages).
5. Hint box ("푸는 방법"): own header and content with equal padding; the last line no longer touches the bottom edge.
6. Pot worked example: 12pt between the choice row and the Previous/Finish row; secondary buttons are now the same height as primary ones app-wide.

## Awaiting owner

- A. How to mark right/wrong in "A hand together" and worked examples (mocks F1–F3). Today both are neutral text with no colour, haptic or sound.
- B. Grey boxes (mocks S1–S2).
- C. Which screen is "the fold example"? Candidate: defend lesson one-step miss shows amber `.close` and the success haptic.
- D. One corner radius for everything, or keep 20 for cards/hint and 10 for controls.
- E. Sort hole cards on the Play table too?
