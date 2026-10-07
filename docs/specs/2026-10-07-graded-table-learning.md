# Graded table learning refresh

## Purpose and scope

The owner requested a full presentation refresh of the graded heads-up exercise:
less explanation before acting, essential information on the table, a learning
opportunity after every decision, and an optional chart available throughout.
This changes the graded screen, not the free table or its coaching rules.

The table keeps the opponent, latest action, round, cards, pot and amount to call.
Before the flop there is no five-card placeholder board. Range counts and policy
tables remain in the opponent reference rather than competing with the cards.
The picker starts the selected style directly; its brief introduction explains
the exercise and scoring assumptions without requiring the statistics sheet.

Every committed decision shows the selected action, the chart/model action and
one factual takeaway. A hand-ending decision receives feedback before the hand
summary. Continue reaches either the next decision or that summary. The summary
keeps the factual result and a reminder to distinguish result from decision,
with full decision review behind a disclosure.

## Decisions and invariants

- Calm native presentation (energy 1, rhythm 1, motion 1) focuses attention on the
  cards and choice. Existing felt, card, ink and action tokens preserve app identity
  across light and dark appearances.
- Normal-size actions stay at the bottom. The footer limits its content height and
  scrolls longer explanations. AX sizes use one continuous scroll and stacked
  action buttons so labels have room without font shrinking.
- Chart and opponent-rule buttons appear above actions, sizing choices, feedback
  and summary. The starting-hand chart explicitly excludes postflop advice.
- Before a preflop decision is committed, the chart receives no selected hand or
  hole-card preview. After commit, the existing selected-hand evidence can appear.
  Exploring the general chart remains optional.
- Chart feedback is chart agreement, never an estimate of EV loss. Postflop
  feedback is explicitly model-relative and retains the no-later-betting assumption.
  The optional explanation discloses sampling, excluded fees and bb units.
- EV details show model and chosen absolute average values, with their nonnegative
  difference. Zero-loss decisions can inspect the same evidence.
- Generator seeds, dealer, available actions, bet fractions, grading thresholds,
  detached option preparation and stale-node guard are unchanged. No engine,
  package, progression or persistence changes.

## Verification handoff

Worker static checks: `swiftc -frontend -parse` over both changed source files and
the four affected UI-test files passed; `git diff --check` passed. No app build,
simulator command or device operation was run by this worker because the root owns
the shared simulator and delivery gate. Parsing is not a type-check or runtime proof.

Added `GradedLearningFlowTests` checks the precommit chart withholding its selected
hand recommendation, postcommit chart evidence, hand-ending feedback before summary,
postflop reference wording and AX action/continue reachability. Existing graded
assertions in GradedDockFlowTests, AccessibilityFlowTests and LearningFlowTests now
follow the new feedback-before-summary flow and stable identifiers.

Root must build/type-check and run these tests, inspect KO/EN normal/AX5 light/dark
frames, exercise expanded decision and summary details, close/reopen references,
and verify all five bet sizes. Existing capture hooks remain:
`GT_DEMO_TABLE`, `GT_DEMO_TABLE_STEP`, `GT_DEMO_TABLE_CONTINUE`,
`GT_DEMO_TABLE_CHART`, `GT_DEMO_TABLE_POLICY`, `GT_DEMO_TABLE_SIZES`.
Physical VoiceOver and beginner comprehension remain separate evidence gaps.
