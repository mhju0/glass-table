# Teaching and screen plan

Date: 2026-09-23
Status: Design proposal implementing the approved spec; not native delivery.

## One question screen

Read this as an adult beginner learning screen with green felt, paper cards,
neutral surroundings and amber actions. Energy 1 / rhythm 2 / motion 1.

The vertical order is: compact exit/help controls, one question, the visual,
replay controls when needed, then choices or feedback. Supporting explanations
never insert themselves above the visual after an answer. The viewport is full
screen; content may scroll. Full-screen does not mean every paragraph must fit
without scrolling.

The table uses the available width with an approximately 2:1 green center.
Seat anchors stay consistent within a participant-count variant. Three- and
four-player pot questions use the same outer bounds. Position needs an eight-seat
variant as well; use compact seat markers and a readable selected-seat explanation
outside the felt instead of cramming eight paragraphs inside it. At accessibility
sizes, readable text takes precedence over preserving an exact aspect ratio.

Keep short identity/card markers on the table. Put long actions in a dedicated
caption area associated with the active seat. Its normal-size space accommodates
the longest supplied localized action, not a speculative empty half-screen.
Measure the bounds across real copy and reveal states. At larger text sizes the
caption can grow and the page scrolls, without covering cards or controls.

## First use, help and return visits

- Each mode opens with a concrete example, a one-sentence purpose and a visible
  way to skip. The example shows the thing being taught, not a prose card above
  an unrelated diagram. Example and independent question use different spots.
- The learner performs one small action in the example: follow a seat, select
  a card, or expose one calculation. The explanation names what changed.
- A visible explanation control reopens the guide. A definition explains a term
  without solving the current question. A solving hint warns that this attempt
  will count as practice with help before exposing calculated information.
- Returning learners resume the saved question or start practice. Do not replay
  the mandatory introduction just because they changed language or appearance.
- Review and mixed questions retain accessible explanations even when they skip
  first-use onboarding. No entry route depends on remembering an earlier guide.

## All-concept coverage

These are proposed teaching treatments, not a claim of completed localized copy.
The concept inventory matches `Progression/Concept.swift` and the existing
`ConceptIntroduction.make` switch in `LearningLanguage.swift`.

| Concept | Plain-language entry, Korean / English | Visual example and necessary explanation |
| --- | --- | --- |
| showdown | 누가 이길까요? / Who wins? | Highlight the best five cards for each player; show that shared cards belong to both and a tie can split the pot. |
| potMath | 가운데 칩은 모두 몇 개일까요? / How many chips are in the middle? | Tap through blinds, calls, raises and a fold. Explain mandatory starting chips before SB/BB; distinguish raise-to from extra chips. |
| position | 누가 먼저 행동할까요? / Who acts first? | Mark the dealer button and follow the next eligible player; compare before/after shared cards. Define early/late by order, not screen height. |
| combos | 가능한 두 장은 몇 가지일까요? / How many two-card hands are possible? | Expand a hand type into actual cards; cross out a visible card. Explain pair, same suit and different suits before AA/AKs/AKo. |
| potOdds | 따라가려면 얼마나 자주 이겨야 할까요? / How often must you win to call? | Separate chips already in the pot from the call; visually join them to form the denominator. Define call as matching the current bet. |
| outs | 어떤 카드가 나오면 이길까요? / Which next cards make you win? | Compare candidate unseen final cards. Distinguish improving your cards from actually beating the shown opponent. |
| equitySense | 끝까지 가면 내 몫은 얼마나 될까요? / What share would you win at the end? | Show wins and split pots in a labeled worked example; explain estimate and uncertainty interval before the two answer controls. |
| evCall | 같은 콜을 반복하면 어떨까요? / What if you made this call repeatedly? | Show winning gain and losing cost, weighted by chance. Define average value and units; a single result is not the average. |
| callFold | 따라갈까요, 포기할까요? / Call or fold? | Compare winning chance with the price of continuing. Explain that folding loses the chance to win this pot, not an additional bet. |
| rangeNotation | 이 표기는 어떤 카드일까요? / Which cards does this label mean? | Expand shorthand into upright card examples. Explain s/o and pairs before introducing grouped notation. |
| rfi | 아무도 들어오지 않았다면? / What if nobody has entered yet? | Show folded seats and your turn; locate your cards in the published practice chart. The chart is this exercise's policy, not a universal command. |
| rangeRead | 상대에게 어떤 카드가 남을까요? / What could the opponent still hold? | Start with a labeled set of possible hands and remove cards that cannot occur. Explain range as several possible hands, not a prediction of one hand. |
| hitFrequency | 이 보드와 맞는 패는 얼마나 될까요? / How many hands connect with this board? | Highlight hands meeting the stated pair-or-better condition; distinguish fraction of the range from chance to win. |
| rangeAdvantage | 어느 쪽 카드 묶음이 유리할까요? / Which set of hands is favored? | Compare two disclosed ranges on the same board. Explain average equity rather than only pointing to the strongest single hand. |
| evLoss | 어느 선택이 평균적으로 더 나을까요? / Which choice is better on average? | Compare call/fold values and show best minus chosen after answering. Keep exact-best separate from almost-best language. |
| actionRead | 이 행동 뒤에는 어떤 패가 남을까요? / What hands remain after this action? | Apply one row of the published opponent policy. Highlight retained hands and explain that the inference follows this practice opponent's rules. |
| defend | 상대가 먼저 올렸다면? / What if someone raised first? | Locate the learner's hand on the defend chart; introduce fold/call/raise again in plain language. Make the chart's grading role explicit. |
| mdf | 너무 자주 포기하면 어떻게 될까요? / What happens if you fold too often? | Use a labeled pot/bet example to explain overall continuation frequency. State that this is not an instruction for every individual hand. |

Four-seat Play also needs a brief guide: your two cards, hidden opponent cards,
shared cards, money in the middle, whose turn it is, and what each action costs.
Show folds by changing the hand state, not only adding a text log. The graded
heads-up exercise needs its own chart/checkdown disclosure. Shared appearance
must not imply that these modes share a grading model.

## Pot practice state contract

1. Start with no actions applied. Advance one action per tap; Back and Replay
   revisit public information without changing assistance status.
2. Show action amounts, but no calculated contribution totals or numerical pot
   answer before commitment. Decorative chip stacks must not encode the hidden
   total by denomination or count. In Play, where the pot is public, show its
   actual total and label the visual chips consistently.
3. At the final event, make three equally styled choices available. The stopping
   point may precede a completed betting round; do not invent extra actions.
4. A totals hint marks the current attempt as assisted even if later dismissed.
   Exit/resume must not clear that flag. Post-answer steps do not retroactively
   change an independently completed attempt.
5. Replace choices with result, a short factual explanation and Show the steps.
   Keep the question and table bounds. Correct, incorrect and assisted states
   share geometry; wording communicates the difference.

## Progress integrity implementation notes

Existing `DailyPracticeKey.assisted` and `ProgressionModel.record` provide
separate assisted evidence and exclude assisted attempts from independent
progress updates. Some session commit paths constrain assistance differently.
Do not assume a new hint button can simply set one Boolean in every route.

Before native implementation, trace each route through answer commit and resume.
Preserve existing records and distinguish practice completion from mastery/review
credit. Persistent-state changes require Class-3 planning and independent frozen
candidate review. The browser prototype demonstrates feedback only; it must not
claim to validate native storage, migration or scheduling.

## Delivery sequence

1. Review an interactive prototype covering pot, position, combos and Play in
   Korean/English, light/dark and compact/large-text layouts.
2. Implement the shared native presentation and table/card components without
   changing poker calculations. Verify bounds across question/reveal variants.
3. Complete all-concept explanations and entry-route coverage. Add assistance
   handling with storage and progression review, rather than a UI-only patch.
4. Run native interaction, package and visual checks. Install on the iPhone only
   when native work is approved and verified; preserve on-device progress.

## Review limits

Browser prototypes can establish layout intent and interaction comprehension,
not SwiftUI behavior, actual Dynamic Type or physical VoiceOver support. Review
the native implementation again on compact iPhone hardware before claiming those.
