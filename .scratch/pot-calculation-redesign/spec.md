# Pot calculation design exploration

Status: shipped natively in `b8fe193` (see `docs/specs/2026-09-23-pot-appearance.md`); kept as design history
Date: 2026-09-22
Baseline: `85dcfcf`

## Boundary

Three interactive visual proposals, not a production implementation. The owner
will critique the mocks before any SwiftUI, grading, curriculum, persistence or
app-wide introduction change. Nothing is deployed or pushed for this exploration.

## Observed problem

`PotMathDrill` in `ConceptDrillView.swift:339-404` initializes the answer at 10,
uses one-chip stepper changes, and presents actions as text rows. A 43-chip answer
therefore needs 33 increment taps. This is interaction effort unrelated to the
skill being taught. The course has show/together/solo examples; free practice
opens the shared drill directly. Existing introductions do not consistently
orient someone entering a mode.

## Design read

A calm Korean beginner lesson within Glass Table's felt, mint and warm-ivory
identity. ENERGY 1 / RHYTHM 2 / MOTION 1. Preserve Pretendard, equal-weight answer
choices, visible tap controls and readable scrolling. Rebuild the representation
of the situation, not just the appearance of the action list.

| Direction | What changes | Strength | Cost |
|---|---|---|---|
| Table replay | Player positions and user-paced action states replace the ledger | Connects an action to chips entering the pot | More navigation and memory than a simultaneous view |
| Contribution trays | Group all chips by the player who committed them | Makes double-counting and ownership easier to inspect | Less like following a live hand |
| One decision | A before/after problem isolates the latest contribution | Low initial cognitive load and explicit learning target | Supplies an intermediate pot; not equivalent to independent full-hand counting |

All directions include introduction, question, selection, confirmation and
specific feedback. Three options have equal styling before commitment. A wrong
answer gets an explanation of the relevant arithmetic, without claiming to know
the learner's thoughts. A repeated question after feedback is practice, not fresh
mastery evidence.

## Authored mock fixtures

The 43-chip scenario follows the existing generator's legal action shapes, not
an observed record of the owner's question:

1. SB posts 1 and BB posts 2.
2. A raises to 6 from zero.
3. B calls 6.
4. BB raises to 18, adding 16 because 2 is already committed.
5. A calls 12 because A already committed 6.
6. Stop here. B has not responded again. No future action is counted.

Total: `1 + 2 + 6 + 6 + 16 + 12 = 43`.
By player: `SB 1 + BB 18 + A 18 + B 6 = 43`.
Before A's final call: 31. Required extra call: `18 - 6 = 12`.

Plausible distractors: 45 double-counts BB's initial 2; 49 adds 18 for A's final
call instead of 12. In the focused final-action proposal, 37 adds 6 instead of 12.
These are misconception hypotheses, not empirically measured common-error rates.
For the follow-on half-pot task, `43 × 50% = 21.5`, rounded to 22 under the existing
engine rule. 21 truncates; 43 returns the whole pot. Explicitly state rounding.

A separate worked example uses `1 + 2 + 4 + 4 = 11`. It does not solve the test
question before the learner commits.

## Introduction pattern for later app-wide consideration

First visit: name the skill, show why it matters, show what to do, and offer one
short worked example before independent practice. Returning visit: a compact
purpose/method reminder plus a replayable introduction, with a direct practice
action. Guided learning, independent practice, review and mixed checkpoints must
be identified honestly; showing a solution cannot earn independent mastery.

This pattern is demonstrated only for pot calculation now. Applying it to every
lesson/mode remains a separate implementation decision after the owner critiques
the mockups. A long mandatory tutorial on every entry is not proposed.

## Research and limits

- [Apple onboarding guidance](https://developer.apple.com/design/human-interface-guidelines/onboarding): short, optional instruction placed near the relevant interface. Applied here as replayable context, not a blocking lecture.
- [IES learning guide](https://ies.ed.gov/ncee/wwc/PracticeGuide/1): combine graphics and verbal explanation, alternate worked examples with practice, and use retrieval. These are general learning recommendations, not a poker-specific efficacy result.
- [CMU assessment guidance](https://www.cmu.edu/teaching/assessment/assesslearning/creatingexams.html): one unambiguous answer, plausible misconception-based distractors, short equally formed alternatives, and varied answer position. Multiple choice reduces input effort but measures recognition differently from generating an answer unaided.

For production, generate distractors deterministically from the actual spot,
reject duplicate/negative/correct alternatives, and balance their positions.
Do not reinterpret old typed-answer mastery as equivalent without reviewing the
progression consequences. The mock does not change any progress data.

## Critique prompts

- Can you identify whose chips moved without reading a transcript?
- Is it clear whether the question asks for the entire pot or the extra call?
- Does the introduction give enough context without delaying you?
- After a wrong choice, can you explain the correction in your own words?
- Which direction would you want to repeat for several questions?

## Readiness boundary

The deliverable is a browser prototype with app-shaped content. Native Dynamic
Type, VoiceOver, SwiftUI navigation, real generator coverage, progress compatibility
and device acceptance require implementation and verification after selection.
Visual polish alone does not establish App Store readiness.

## Approved revision, 2026-09-23

The owner approved the table-led hybrid recommendation and broader
beginner-accessible direction. Preserve advanced depth, but explain vocabulary,
roles, action order, why the skill matters and how to answer at first encounter.
Step is not the main question format; it may inform optional future teaching.
Keep this round as a mock, not a native implementation.

`hybrid.html` combines contained player contribution trays with a table layout,
one current-actor marker and a replayable action sequence. The first introduction
starts at the blind posts; returning entry can go directly to the question.
The diagram does not display the aggregate pot before commitment. Wrong feedback
states the actual total without diagnosing the selected distractor; the calculation
is available through a disclosure. The original `index.html` is preserved.

### Fixture coverage and correctness

The four authored examples use clockwise seats after the dealer: SB, BB, then
one through four non-blind players. SB posts 1, BB posts 2, the first non-blind
raises to 6, remaining non-blinds call 6, SB folds, BB raises to 18 by adding 16,
and the opener calls 12. Stop on that last real action, not a separate frame
that would expose the completed total before hiding it again.

| Players | Final contributions, clockwise | Pot | Actual actions |
|---|---|---:|---:|
| 3 | 1, 18, 18 | 37 | 6 |
| 4 | 1, 18, 18, 6 | 43 | 7 |
| 5 | 1, 18, 18, 6, 6 | 49 | 8 |
| 6 | 1, 18, 18, 6, 6, 6 | 55 | 9 |

Three-player betting is settled; the other examples stop with earlier callers
still to respond. A folded SB's 1 remains in the pot. Public rules cross-check:
[PokerStars Hold'em rules](https://www.pokerstars.com/poker/games/texas-holdem/)
and [beginner rules](https://www.pokerstars.com/poker/learn/lesson/texas-holdem-rules/)
describe blind positions, compulsory posts and clockwise preflop action.

The current Swift generator has four/five participants and no explicit fold
action. Three/six-player fixtures and the visible SB fold are prototype coverage,
not claims about current native generation. All-in, side pots and postflop
sequences are outside this mock. Production work must reconcile the generator,
presentation and grading rather than transplant these authored examples.

### Visual rationale

- Felt and Pretendard preserve Glass Table's established identity.
- Integrated contribution areas tie each amount to its player without a second
  duplicate tray panel. Room inside the border prevents amounts crossing it.
- Wide two-column perimeter seats preserve readable amounts; large text uses a
  one-column order rather than shrinking labels or cropping them.
- Mint identifies the current actor and selected answer, never the correct
  option in advance. Plain labels carry meaning independently of color.
- One caption and manual controls preserve chronology without autoplay or an
  accumulating transcript. A current-actor marker avoids misleading arrows when
  the layout reflows.
- Optional calculation detail keeps correction brief without making it opaque.

## Approved simplification revision, 2026-09-23

Supersedes the five/six-player mock scope above; that coverage is historical.
The owner preferred the three/four-player composition and asked for less text.
The updated hybrid supports only those two counts, with the same 37/43-chip
fixtures. It removes the context paragraph, clockwise line, action counter and
separate explanation panel. One short caption sits inside the highlighted seat;
the cumulative contribution remains separate from the amount added this move.
Previous/next buttons and progress marks retain manual chronological review.
The four-player stop names B's next response, not a completed betting round.

Motion serves spatial consistency: one decorative chip travels to the center
on a pointer-triggered forward contribution. WAAPI animates only transform and
opacity for 220ms with cubic-bezier(0.77,0,0.175,1). Rerenders cancel it; keyboard,
backward steps, folds and reduced-motion do not trigger it. Seat captions reserve
space rather than moving the layout. Active text is .8rem for readability.
The local motion dial is 2; felt identity, energy 1 and rhythm 2 remain unchanged.

This revision is implemented and browser-checked for critique, not approved native
delivery. See the appended revision evidence in `hybrid-verification.md`.
