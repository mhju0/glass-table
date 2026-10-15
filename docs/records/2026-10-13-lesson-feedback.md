# Lesson feedback on build 24, and "a near miss is wrong"

- **Date:** 2026-10-13 (to 2026-10-14)
- **Kind:** feature notes
- **Originals:** `.scratch/lesson-feedback-2026-10-13/map.md` (tracked: `git show f5c5e22:.scratch/lesson-feedback-2026-10-13/map.md`)
- **Asked by / for:** owner, feedback on build 24 on the iPhone 12 mini; branch `feat/lesson-feedback-clarity`

## What it was
The item list for the owner's lesson feedback, the mocks and picks that followed, and
the later rule that only an exact answer counts. Mocks:
https://claude.ai/artifact/9GBTnNb66MwufA7B19rG7e (round 1),
https://claude.ai/artifact/8aPmc5HftjZcezcpN6TkYs (open questions).

## Findings and decisions
Direct fixes, `456b9ca`:
1. Best five reads most important card first (`bestFiveCards`): made part, then kickers
   high to low; straights top down, wheel ace last.
2. Lesson and guide hole cards show high card first (`ThreeRegionCardTable`).
3. Outs answer: groups open (no toggles), strongest hand first, cards ace first; same in
   the saved-answer view. Worked-example grids ace first (`BeatScript.byRank`).
4. Rule of 2 explained in the sentence that first names it (outs example, both languages).
5. Hint box ("푸는 방법"): own header, equal padding; last line no longer touches the edge.
6. Pot worked example: 12pt between choice row and Previous/Finish row; secondary
   buttons now the same height as primary ones app-wide.

Owner chose F2 and S1 (2026-10-13), `a3a4d16`:
7. F2 in "A hand together" and the pot example: choices stay in place after an answer;
   the pick turns green or red with an icon, the right answer is marked green after a
   miss, the rest lock (dashed). The bottom panel takes the verdict tint and outline and
   holds "맞아요 / That's right" or "아쉬워요 / Not quite", the reason and Next. Next is on
   screen from the start, disabled until answered. Haptic and sound via `AppFeedback.answer`.
8. S1: pot example steps and outs groups are white cards with a thin border; current step
   has the gold outline. Explanation boxes inside a verdict are white with the verdict
   colour as edge (`gtExplanation(band:)`); EV comparison box white with neutral edge.
   Hint stays grey.
9. Pot example no longer shows a second card repeating the last step's title.
10. At accessibility sizes an answered choice row keeps only the marked choices.

Owner's answers to the open questions (2026-10-13): 1A, 1C, 2A, 3A, `a469449`:
11. 1A, EV-loss lesson: a choice that lost any value shows amber ± "Near best" with the
    review sound (`EVLossReveal.shownBand`, live and saved). Stored band and progress
    unchanged: a loss up to 0.5bb is still `.spotOn`.
12. 1C, "An opponent raised": one step off the chart stays amber and plays the review
    sound. Other lessons' `.close` answers still played success (not asked).
13. 2A: `GT.Radius.panel` is 10, same as controls; two 14pt drill boxes follow. Playing
    cards, pills and small grid cells keep their own shape.
14. 3A: Play table, its hand review and the hand coach show hole cards high card first
    (`highCardFirst`); table state keeps the dealt order.

Near miss is wrong (owner, 2026-10-14), `a31472e`:
15. Only an exact answer counts as correct. A near miss (amber, including an EV-loss
    choice that gave up any value) adds to the answer total but not the correct count,
    adds to the miss streak, is scheduled as a hard review, counts as missed on the lesson
    result, goes under "Near" in Records, and plays the review sound in every lesson.
    Records says "exact N%". Rule: `GradeBand.counted(evLoss:)`, `RoundAnswer.countedBand`.
    Stored bands unchanged so saved answers still validate. Counts saved before this
    build are not recomputed.

## Outcome
Items 1-15 shipped in build 25 (source `a31472e` plus bump). The undecided pass mark
below was settled in build 27: a lesson or challenge passes with two in three questions
answered alone and exactly right (per `docs/build-history.md`).

## Still open
Limits recorded at build time:
- At AX5 the pot example's pinned panel still covers most of the screen on its last step
  (it did before answering too).
- A marked three-choice button wraps "24 chips" onto two lines on the 12 mini.
- Map's undecided item (now resolved by build 27, kept for history): a lesson was marked
  cleared once every question was answered, right or wrong (`ProgressionModel.commitNodeAnswer`).
