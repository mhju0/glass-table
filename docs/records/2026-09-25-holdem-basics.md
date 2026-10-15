# Hold'em basics lesson

- **Date:** 2026-09-25
- **Kind:** spec notes
- **Originals:** `.scratch/holdem-basics/spec.md` (tracked: `git show f5c5e22:.scratch/holdem-basics/spec.md`)
- **Asked by / for:** owner approved the order on 2026-09-25 ("start in order and do all one through six"); Roadmap Phase 2, item 1

## What it was
Spec for a short ungraded lesson, **홀덤 기초 / Hold'em basics**, placed before 쇼다운.
Problem: a true beginner met showdown before anything explained how a hand is dealt or
what beats what; the only ranking list was text on page 3 of the Settings guide
(`LearningGuideView`).

## Findings and decisions
Four pages:
1. How a hand is dealt: two private cards, then flop 3, turn 1, river 1, with a betting
   round before each street and after the river. The learner taps to deal each street.
2. Best five of seven: one worked seven-card example; the engine (`bestFiveCards`,
   `bestHand`) marks the five cards that play and names the hand.
3. Hand-ranking ladder: ten rows, strongest first (royal flush ... high card), each with a
   five-card example and how often it is the best hand in seven cards. Percentages come
   from `GlassTableEngine.HandFrequency`; its release test recounts all 133,784,560
   seven-card sets. The page says rarer is stronger and suits never rank.
4. One check question in the bottom sheet with verdict tint: "Flush or straight, which
   wins?" (flush). Wrong answers explain; retry allowed. Practice, not assessment.

Rules:
- No grade, answer record, streak, mastery or review schedule. Finishing writes one
  optional marker, `ProgressState.basicsLessonCompleted` (decodeIfPresent; older files
  read as "not yet").
- Placement: Learn's "Suggested next" shows it while unfinished, no node is cleared, no
  placement recommendation, nothing to resume or review. The first-run guide's last
  button opens it (if unfinished) instead of 쇼다운. The path lists it above unit 1,
  always open, with a check once finished.
- Closing is always allowed and keeps nothing half-done. KO/EN line parity at default
  size; card faces fixed size; AX5 without clipping.
- Out of scope: Settings guide text, graded hand-ranking drills, new concepts or nodes.
- Verification plan: engine `HandFrequencyTests` (release, exact counts and royal split);
  Drills round-trip of `basicsLessonCompleted` and old JSON decoding to `nil`; app model
  test and UI test from Learn to finish; uisweep `basics-*` at large and AX5, KO/EN,
  parity OCR on the mini.

## Outcome
Shipped in `c8abfd0` (2026-09-25). Later changes: build 24 (`2543ad3`) shows all ten
hands at once with "1 in N hands"; build 27/28 moved Previous beside the action and hid
the lone Previous before the answer (see the clickable-controls record).

## Still open
Nothing.
