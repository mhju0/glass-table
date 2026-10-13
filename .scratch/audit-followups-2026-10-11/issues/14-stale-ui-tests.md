# 14 — The 48 UI tests that fail without my changes

Type: research
Status: resolved

## Question

Why do 48 UI tests fail identically on the unmodified commit `19f2d10`, and
what should be done with them?

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/ui-tests-48-failing-on-19f2d10.txt` (iPhone 17, baseline),
`evidence/ui-tests-41-failing-on-12-mini.txt` (the same 48 re-run at HEAD
`cbeadfe` on the iPhone 12 mini simulator: 48 run, 41 failed, 7 passed).

Verified:

- 7 of the 48 pass on the 12 mini and fail only on the iPhone 17:
  `AccessibilityAuditTests/testPlayTable`, both `ChartFirstUseFlowTests`, both
  `DeviceFeedbackSettingsTests`, `LearningFlowTests/testLanguageSwitchKeepsTheWorkedExampleStep`
  and `…/testPotMathTableRequiresTheFullReplayThenRevealsOptionalArithmetic`.
- 41 fail on both phones.
- `testDueReviewIsFiniteAndMovesBetweenConcepts` taps a "확인" button
  (`LearningFlowTests.swift:641`); the screen at failure shows three answer
  buttons `lesson-choice-10/12/14` and no "확인". Answer buttons with that
  identifier arrived in `8804aff` (2026-10-07).
- `GradedDockFlowTests.swift:34` expects the label "Raise"; the app says
  "Raise again".
- `FinalPresentationVerificationTests.swift:66` looks for `range-start-medium`;
  no source file contains that identifier.
- `LearningFlowTests.swift:892` and `:132` expect the old opening
  ("어느 쪽이 이길까요?" straight after "시작하기"; the old welcome sentence); the
  opening was rebuilt in `7549a32` (2026-10-11).

Inferred grouping of the 41 (from the failing line of each; only the cases
above were traced to the screen):

- A, about 17: wait for a "확인 / Check answer / Enter answer" button on
  questions that are now answered by tapping a choice (`BeginnerReleaseTests`
  244, 335, 361, 438; `LearningFlowTests` 207, 641, 713, 797, 815, 839×2;
  `RestoredPresentationTests` ×4; `AccessibilityFlowTests` 151, 363).
- B, about 5: old opening guide (`LearningFlowTests` 132, 892×2;
  `AccessibilityFlowTests` 122, 179).
- C, about 8: changed wording or identifiers (`GradedDockFlowTests` 34;
  `BeginnerReleaseTests` 385; `LearningFlowTests` 283, 544;
  `FinalPresentationVerificationTests` ×4).
- D, about 11: measurements at the largest text size that may be real layout
  problems, not outdated tests: free-table seats not fully on screen
  (`AccessibilityFlowTests` 68×3, 80), result text taller than its panel
  (`FreeDockFlowTests` 114), help tabs off the left edge
  (`FreeTableBackFlowTests` 246×2), pot caption not tappable
  (`FreeTableMotionFlowTests` 254), lesson title 43 pt under the close button
  where 40 is allowed (`LearningFlowTests` 385), plus
  `AccessibilityFlowTests` 347 and `LearningFlowTests` 565.

Unknown: whether each group-D failure is a real fault a learner would hit.
Several of those screens (free table, graded table, lesson help) change in the
final pass anyway.

Options:

1. In the final pass: update groups A–C to the current app; check each group-D
   failure on screen and fix the app where it is a real fault, the test where
   it is not; make the 7 phone-size-dependent tests and the 16 Bilingual tests
   pass on both phones, and use the full UI suite on both as the final gate.
2. As 1 for A–C and D, but keep one phone per suite (document which).
3. Delete the 41 and keep only tests that pass today.
4. Leave them for a separate task after this pass.

Recommendation: option 1.

## Decision

Decision (owner, 2026-10-12): option 1. Update groups A–C, check each group-D failure on screen and fix app or test accordingly, make the phone-size-dependent and Bilingual tests pass on both phones, and gate the final pass on the full UI suite on both.

## Comments
