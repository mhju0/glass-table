# Consistent learning and table experience

Date: 2026-09-23
Status: Approved product decisions; local interactive prototype ready for review.
Native implementation has not started for this follow-up.

## Approval record

The owner approved all recommendations in two clarification rounds. This file
records that agreement, not a claim that the installed app implements it.
Keep earlier delivery records as history. This decision supersedes conflicting
presentation and pot-replay choices for the next implementation.

## Feedback that prompted this work

The owner reported partial-screen lessons, shifting pot-question layouts,
visible contribution totals that reduce the exercise to addition, unclear or
missing position explanations, wasted introduction space, unexplained combo
hand types, and inconsistent table visuals between learning and Play.
They requested simple language, alignment, symmetry, consistent table size,
visible cards/fold states and central pot chips. Image 81 was referenced but
was not attached to this clarification exchange. Its pixels were not audited.

## Approved decisions

1. Open lessons and practice questions full-screen with a clear exit control.
   Preserve the learner's place on exit. Optional definitions and small help
   panels may remain overlays. This gives the activity the available screen.
2. Use a wide, softly rounded green rectangular table, approximately 2:1,
   not eight cells. Keep seats, cards and the pot in predictable locations.
   Keep the table's size and position stable across question, answer and reveal.
   At large text sizes, allow surrounding content to scroll rather than squeeze.
3. In pot questions, show each action's amount but hide calculated per-player
   contribution totals until a hint or the answer reveal. Do not make recall of
   disappearing numbers part of the test. Teach money added versus a raise-to
   amount. Preserve three answer choices and conceal the correct answer before
   commitment, except where the learner explicitly requests help.
4. Give every mode a short first-use visual worked example: what to figure out,
   an example, then the learner's turn. Make it skippable and reopenable.
   Returning learners proceed to practice. Explain positions and hand-type
   notation where introduced; the glossary must not be a prerequisite.
5. Share a table component wherever seating and actions matter, including pot
   calculation, position and Play. Use matching card components elsewhere;
   do not force charts and card-only lessons onto a table. Show opponents'
   face-down cards, clear folded states and central pot chips in Play.
   Do not reveal opponents' hidden card faces.
6. Learning replay advances on tap, with Back and Replay controls. Highlight
   the acting player with one short nearby action description. Avoid parallel
   instruction blocks and automatic pacing that the learner must keep up with.
7. Revealing calculated totals before answering marks the attempt as completed
   with help. Count it as practice, not an unaided correct answer. Replaying
   the original actions alone is not help. Offer encouragement without claiming
   independent success.
8. After answering, keep the table and question in place. Replace the answer
   area with a short result and one factual explanation. Offer Show the steps
   for the full breakdown. Correct and incorrect answers use the same layout;
   do not insert a new top banner, border or rearranged table. Explain the
   calculation, not an assumed reason the learner selected a wrong answer.

## Existing constraints retained

### Player-panel geometry feedback, 2026-09-23

The owner rejected mismatched player/table curves and inconsistent border
alignment. The prototype now uses one 10px inset from the table's inner edge;
each outside-facing panel corner uses the table radius minus border and inset
(32 - 3 - 10 = 19px). Inward-facing corners remain 10px. Removed the redundant
inner rail. Active and inactive borders both occupy 2px so highlighting does not
change geometry. Apply this shared geometry to every table-based mode.

### Table material and polish direction, approved 2026-09-24

The owner found the aligned diagram flat and asked for a finished, cohesive look
without decoration. Approved direction: the rail and felt are the table; seats
are areas of it; only cards, chips and the dealer button cast shadows.

- Rail: keep the 3px border so 32 - 3 - 10 = 19px stays exact; make it darker
  than the felt with a faint concentric inner edge.
- Seats: darker than felt, resting 2px border close to the fill, active changes
  only the border colour to amber. Folded seats drop the dashed border and use
  neutral status text; amber is reserved for actions.
- Chips: ivory with dark slate edge marks, one fixed-height stack in every
  state so its size never hints at the pot total.
- Cards: one 26 x 36 table card size for hands and board, a small shadow instead
  of a grey outline. Card backs are solid deep slate with a cream inset line
  (owner accepted the agent's pick over oxblood, which is too close to suit red).
- Board and pot form one centred group; the unrevealed pot label reads 팟 / Pot.
  Seat name and status sit on separate lines and wrap only between words.
- Dealer button is a fixed-size disc beside the seat name.
- Seats widen to half the table minus inset and an 8px half-gap; the centre
  group sits between seat rows, so this fits 26px hand cards beside the name.

The prototype exposes both versions through the Design review control
(`?design=refined`). The refined visuals still await the owner's review;
native implementation remains gated on approval.

### Bilingual line parity, owner rule 2026-09-24

The owner made KO/EN line parity an app-wide rule (recorded in `DESIGN.md`):
same line count at the default size, last line at least half full, similar end
width, and no in-word breaks. The prototype applies it on the Refined side
only, through a before/after copy table (`REVISED` in `app.js`), so the
comparison stays honest. The combos title now uses the glossary term Hand combos.
`compare.html` shows Current and Refined as two synced phones.

### Retained product constraints

- Adult learning app with everyday language, offline and without accounts.
- Korean and English, light and dark appearances, Dynamic Type support.
- Green table, amber actions and neutral surrounding surfaces.
- Open lesson access with recommendations, not new progression locks.
- Four-seat Play remains separate from graded heads-up learning. Sharing visual
  components does not merge their poker policies or introduce an EV grade.
- Preserve progress, saved sessions and recovery bytes. Do not retroactively
  relabel historical independent attempts as assisted.

## Current-source findings

Read-only investigation, not a complete runtime audit:

- `GlassTable/Sources/Screens/RootView.swift`: Learn nodes and free practice
  open through sheet presentation. This explains the partial-screen shell.
- `GlassTable/Sources/Screens/PotMathLessonView.swift`: pot replay uses distinct
  three/four-player heights and visible running contribution totals.
- `GlassTable/Sources/Screens/ConceptDrillView.swift`: answer/reveal branches
  differ. New pot questions after the first can initialize at the final action.
  Layout stability needs runtime measurement, not just source inspection.
- `GlassTable/Sources/Screens/NodeSessionView.swift` and
  `GlassTableDrills/Sources/GlassTableDrills/LearningLanguage.swift`: guided and
  free-practice introduction content already exists. Standalone drill views
  do not independently provide the same introduction flow. Audit every entry
  path and actual explanation quality rather than assuming all copy is absent.
- `GlassTable/Sources/Screens/PlayView.swift` and
  `GlassTable/Sources/Screens/TableView.swift`: four-seat Play and graded heads-up
  use separate renderers today. Position questions also include eight-seat
  content; the earlier four-player cap for pot examples must not silently
  remove position curriculum. Resolve responsive seat variants during design.

## Acceptance checks for the implementation

- Exercise lesson, free-practice, review and resume entry paths. Verify full
  screen, exit, saved position and reachable help for every applicable mode.
- Inventory all concepts and modes with their first-use example, why/how copy,
  notation explanation, skip and reopen behavior. Include position and combos.
- Compare pot screens before/after correct, incorrect and assisted answers;
  include short/long localized text and three/four-player examples. Measure
  table bounds and inspect alignment. Avoid giant empty placeholders used only
  to disguise layout shifts.
- Verify hidden contribution totals remain hidden in visual and accessibility
  output until help/reveal. Pot graphics must not disclose the answer early.
- Exercise forward, back and replay. Preserve readable action amounts without
  revealing cumulative totals; check raise-to versus added-chip calculations.
- Verify assisted practice separately from unaided accuracy, including save,
  exit, resume and relaunch. Review mastery/review-credit effects before coding;
  use existing guided-practice semantics where suitable and document the mapping.
- Check active, folded, all-in and showdown states in Play. Preserve hidden
  information and model correctness while changing the renderer.
- Inspect iPhone 12 mini layouts in both languages, both appearances, normal
  and AX5 text. Exercise scrolling and controls; screenshots alone are not proof
  of reachability. Check VoiceOver labels and reduced-motion behavior.
- Record implementation commits, actual tests and remaining gaps separately.
  No build, device install or runtime verification occurred in this docs step.

## Next step

The product-direction interview is settled. Prepare the shared layout and
mode-by-mode teaching plan using these decisions. Resolve any newly discovered
product tradeoff explicitly; do not reopen approved choices without new evidence.
The first interactive prototype is in `prototype/`. See `teaching-plan.md` for
all-concept coverage and `verification.md` for browser evidence and limits.
Its taller shared table proportion is provisional and needs visual review;
the approximate 2:1 preference has not been silently replaced as a final decision.
