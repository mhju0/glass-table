# Native refinement and restrained encouragement

2026-10-06 · Design proposal following owner approval of the 20 before/after
comparisons. This document and the linked HTML are design artifacts; native
implementation and native acceptance remain outstanding.

## Owner refinement — completion and optional continuity

The owner approved A Focus, practice-date dots and inline short reasons from
`refinement.html`. The completion-focused addendum is
`.build/uxaudit-review-b15/completion.html`.

This update supersedes the public helped/independent split proposed below:
- Everyday summary and Records lead with finished practice and completed lessons.
  Do not show helped counts, solo denominators or a warning about using help.
  Help remains freely available. After a committed answer, show the actual result
  and a factual explanation; never present completion as accuracy or proficiency.
- Retain existing assistance metadata, saved answers, review and proficiency rules
  during presentation implementation. Removal of the public distinction does not
  itself authorize rewriting historical data or awarding mastery for help use.
  Future removal of the internal distinction is a separate learning-model decision.
- Recommended continuity detail: a small static amber flame in today's existing
  date cell only after a recorded answer on the fourth consecutive local date;
  keep it on subsequent qualifying dates. Before today's answer, use an outlined
  dot even if the preceding three dates are recorded. It does not grow or animate.
  Date cells retain fixed geometry; use an SF Symbol natively, not an emoji.
- Any committed recorded lesson/practice answer qualifies regardless of help or
  correctness. Opening the app or only opening help does not qualify. This proposal
  uses distinct recorded practice dates, not the existing due-queue/freeze streak.
  An incomplete lesson may record a practice date; a completed-lesson count requires
  actual completion. Free table is excluded until activity evidence is designed.
- Gaps return to neutral dates with an ordinary continuation. No loss warning,
  urgency, freeze count, earned currency or notification. Screen-reader copy says
  the date, recorded status and consecutive practice count, not merely “fire.”
- Native acceptance must exercise help-only, helped committed answer, wrong answer,
  interrupted lesson, repeated answers same day, midnight/timezone/DST, imported
  sparse dates and future records. Existing recovery/history bytes remain intact.

Earlier paragraphs describing public split counts and the existing study streak
are retained as proposal history; this refinement controls the new casual overview.
Native implementation, count derivation and native verification remain pending.

## Intent

Make the approved beginner direction feel like Glass Table on iOS. Recognize
specific effort and results without daily obligations, exaggerated praise or
claims that a short session proves poker ability. Keep Korean 해요체 and equally
natural adult English. Records remains the destination; no new Profile tab.

## Native translation of the approved comparisons

- D01, D11, D19: preserve the current shared table, fixed card geometry, seat
  ownership and hidden information. Keep native Fold/Call/Raise geometry;
  explain their meaning above or on demand rather than reducing button type
  size to fit HTML labels. At accessibility sizes stack reachable controls.
- D02, D03, D05, D14, D15: use existing explanation and disclosure components.
  Short everyday labels lead; grading basis, equity/tie meaning, model limits
  and actual counts remain readable. Rank rules and rarity remain separate.
- D04, D10, D12, D13, D16: retain NavigationStack, existing lesson rows, placement
  semantics and the four-tab structure. One recommended next step leads; all
  appropriate choices remain available. No new setting or onboarding branch
  merely to accommodate a mockup.
- D06, D09, D17: hints occupy reserved chrome or an established native sheet.
  The question and card/table region stay stable. Surrounding content scrolls;
  do not reserve fixed-height paragraphs or cover cards with feedback.
- D07, D08: add encouragement to existing Records and session summaries, with
  supported/independent practice clearly separated. Existing deep reports remain
  available below the beginner overview.
- D18: use GT fonts, semantic colors, radii, spacing, chrome, button styles and
  press feedback. Native font metrics replace HTML geometry. Preserve System
  appearance and light/dark overrides; do not add a second visual system.
- D20 is a report clarification, not an app screen or new feature.

Use existing FeltCTAButton, SecondaryCTAButton, ChromeButton/ChromeTextButton,
gtCard/gtInset and native disclosure/menu controls as appropriate. SF Symbols
support labels; correctness always has words as well as a symbol/color. One
primary navigation action per surface; answer alternatives remain equal-weight.
Reduced Motion preserves immediate status and removes optional movement.

Apple references: [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback),
[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons),
[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).
The recommendation to keep feedback inline follows Apple's preference to
integrate status into the interface; the exact copy and hierarchy below are
Glass Table design decisions, not Apple requirements.

## Encouragement hierarchy

1. After a committed answer: actual outcome, one explanatory sentence, next
   action. Encouragement must never replace the answer or its grading basis.
2. After a session: recognize completing practice, report independent and
   supported results separately, offer one useful next step.
3. In Records: completed work and recent practice days first, with a visible
  continuation. Detailed performance and the existing study streak are secondary.

The meaningful reward is visible, durable work: a completed lesson or track,
practice recorded, and an available next step. Use the existing milestone
system for genuine transitions. No XP, reward currency, paid protection,
lost lives, expiry countdowns, celebratory takeover or automatic notifications.

## Copy examples and conditions

| State | Korean | English | Condition |
| --- | --- | --- | --- |
| Correct hand comparison | 맞아요. 한 쌍은 높은 카드보다 강해요. | That's right. A pair beats a high card. | Only after commitment; explanation matches the actual hand |
| Close estimate | 근접했어요. 실제 값과 비교해 봐요. | Close. Compare your estimate with the result. | Actual near grade; do not label it fully correct |
| Incorrect answer | 가장 좋은 다섯 장을 다시 비교해 봐요. | Let's compare the strongest five cards. | Relevant to a hand-comparison task; use another skill-specific prompt elsewhere |
| Repeated difficulty | 예제를 함께 보고, 다른 패로 다시 해봐요. | Try a worked example, then another hand. | Offer help without claiming to know the cause of errors |
| Finished practice | 오늘 연습을 마쳤어요. | Practice complete. | Finished activity, even if every independent answer was incorrect |
| Returning | 다시 오셨네요. 이어서 배워볼까요? | Welcome back. Pick up where you left off. | Recorded prior activity and a genuine saved/recommended continuation |
| Recent activity | 최근 7일 동안 3일 연습했어요. | You practised on 3 of the last 7 days. | Unique recorded calendar days; illustrative number replaced by actual data |
| More practice | 오늘 6문제를 연습했어요. 지난 연습일엔 3문제를 풀었어요. | You practised 6 questions today; 3 on your previous practice day. | Both days exist; volume, not improvement in ability |

Keep one contextual sentence per surface. Use deterministic conditions rather
than random praise. Repeated mistakes do not make the tone louder. Do not infer
the learner's reasoning, persistence, feelings or expertise from an answer.
An all-wrong summary still shows the actual result and offers a worked example.
Help is a valid practice choice; it is not silently counted as independent success.

For an absent learner prefer a neutral welcome and a continuation. Do not show
how many days they were away as a rebuke. If no prior activity exists, use the
new-learner prompt rather than a welcome-back message.
If older history proves prior learning but has no reliable activity date, show
an ordinary continuation without claiming how long the learner was away.

## Data rules

Current implementation references: `Screens/RecordsView.swift` (matching lanes,
seven-day windows and timing guards), `Screens/NodeSessionView.swift` (helped/solo
summary and easier-lesson offer), `Progression/ReviewQueue.swift` (streak credit),
`Progression/LearningProgress.swift` (daily aggregates), and `Milestones.swift`
(earned transitions). Screen/milestone paths are under `GlassTable/Sources`;
progression paths are under `GlassTableDrills/Sources/GlassTableDrills`.

- Compute practice days from distinct DailyPracticeKey.day values with total > 0
  in the last seven local calendar dates. Include recorded helped practice and
  say so in a short methodology disclosure. Do not count opening the app, unrecorded
  walkthroughs or free-table hands as lesson practice.
- Use DayKey calendar comparisons, not 86,400-second subtraction. Exclude
  future-dated records from current windows. Do not reconstruct pre-tracking
  days from lifetime totals; retain detailedTrackingStartedAt disclosure.
- The existing streak qualifies a committed answer when the due queue is empty
  or the answered concept is due; incorrect and helped answers can qualify too.
  Label it study activity and disclose that rule rather than promising credit
  for every practice day or claiming uninterrupted attendance.
  Preserve stored streak/freeze semantics; the new activity overview does not
  redefine streak credit or create a new streak record.
- Count completion through existing node/track rules. Saved hidden lessons
  remain intact; choose visible-course denominators deliberately and label them.
- Never turn increased answer volume into an accuracy or learning improvement
  claim. Default encouragement uses activity/completion facts.
- If a future performance sentence is added, compare the same concept, mode,
  format version, language and assistance condition, using independent answers
  for independent accuracy. Show numerator/denominator and periods. Define and
  test a conservative minimum before enabling such copy; this proposal does not
  activate an unvalidated accuracy threshold or change existing timing rules.
- Existing timing comparisons require at least ten eligible correct answers and
  three eligible days in each seven-day window. Do not weaken that guard to obtain
  an encouraging message; deduplicate dates when deriving a new multi-lane metric.
- No persistence schema changes are necessary for the proposed activity overview.
  Any later new milestone/acknowledgement storage needs a separate persistence
  design and independent integrity review. Do not reset, re-grade or rewrite history.

## Acceptance before native delivery

Render actual SwiftUI in KO/EN × light/dark on compact iPhone and larger screens,
normal and AX5. Measure default text parity under DESIGN.md, including paragraphs,
button labels and dynamic numbers. AX5 reflows naturally with no truncation or
font reduction. Verify actual scroll, tap targets, dismissal/resume, VoiceOver
reading order, repeated feedback and reduced motion.

Exercise zero history, one answer, all incorrect, all helped, mixed results,
repeated difficult lessons, session resume/relaunch, completed track, return after
a break, language changes, multiple practice lanes on the same date, midnight,
DST/timezone changes, future clock records and older imported history. Verify
unchanged grading, milestone credit and persistence/recovery bytes. Progress
derived counts require unit tests for distinct-day aggregation and window edges;
copy-only native edits need proportionate render/interaction checks.

The HTML addendum demonstrates tone and hierarchy only. Its sample counts are
fictional and it does not establish native layout, Dynamic Type or learning outcomes.
