# Entry routes: first-use explanations and help (issues 03 and 04)

Date: 2026-09-26. Every route below reaches the 18 concepts through the same views,
so one row per route covers all of them. "Test" names the check that proves it.

| Route | Worked example | Explain control | Solving help (pot totals) | Test |
| --- | --- | --- | --- | --- |
| Lesson, first visit | Purpose line on step 0; the last value step is covered until tapped | On every graded question | Marks the lesson question | `WalkthroughPracticeTests` (18 concepts, KO/EN, 5 seeds); `testShowdownWalkthroughAdvancesAtAccessibilityXXXL` |
| Lesson, returning | Skipped (concept already seen) | Yes | Yes | `testGradedQuestionReopensTheExplanationAndAnExample` |
| Single-skill practice | Its own show step, same covered value | Yes, after the intro | Refused in the "together" step; marks graded questions | `testRoundHelpIsPracticeWithoutAccuracyScheduleOrTiming` |
| Review | None (mixed concepts) | Yes | Marks the review question; concept stays due | `testReviewHelpLeavesTheConceptDue` |
| Records replay (천천히) | Purpose line and covered value | n/a (it is the example) | n/a | `WalkthroughPracticeTests` |
| Resume / relaunch | Saved show step returns | Yes | Stored flag keeps totals and the "Solved with help" label | `testPotTotalsHelpAsksFirstAndMarksTheAnswer` |
| Language change | Saved show step returns, no replay | Yes | Stored flag is language-free | `testLanguageSwitchKeepsTheWorkedExampleStep` |
| Play, four-seat table | Table guide shows once, info button reopens | n/a | n/a (not graded) | `testFirstTableExplainsItselfOnceAndReopens` |
| Graded heads-up exercise | Existing policy reference | n/a | n/a | unchanged |
| Placement check | None | n/a | n/a (never awards progress) | unchanged |

## Help rules as built

- Only pot counting offers solving help in 1.0 ("합계 보기 / Show totals"). It asks
  first; declining shows nothing and records nothing.
- Explain, "How to count", worked examples and Back/Replay never mark help.
- A helped answer: daily history "with help"; streak counts; no accuracy, miss
  streak, FSRS, timing or mastery evidence; new spot seeds move.
- Summaries (lesson, practice, review) count help separately and do not promise a
  review date for skills answered only with help.
