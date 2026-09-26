# Hold'em basics lesson

Status: ready-for-agent (owner approved the order on 2026-09-25: "start in order and do all
one through six"). Roadmap Phase 2, item 1.

## Problem

A true beginner meets 쇼다운 (compare two hands) before anything explains how a hand of
Hold'em is dealt or what beats what. The only ranking list is a text block on page 3 of
the Settings guide (`LearningGuideView`).

## What ships

A short, ungraded lesson, **홀덤 기초 / Hold'em basics**, that comes before 쇼다운.

1. **How a hand is dealt.** Two private cards, then the shared cards one street at a time
   (flop 3, turn 1, river 1), with a betting round before each and after the river. The
   learner taps to deal each street.
2. **Best five of seven.** One worked seven-card example. The engine (`bestFiveCards`,
   `bestHand`) marks the five cards that play and names the hand.
3. **The hand-ranking ladder.** Ten rows, strongest first: royal flush, straight flush,
   four of a kind, full house, flush, straight, three of a kind, two pair, one pair,
   high card. Each has a five-card example and **how often it is the best hand in seven
   cards**. The percentages come from `GlassTableEngine.HandFrequency`; its release test
   recounts all 133,784,560 seven-card sets with the engine's evaluator. The page states
   the rarer the hand, the stronger it is, and that suits never rank.
4. **One check question** (choices in the bottom sheet, verdict tint like the first
   lesson): "Flush or straight, which wins?" → flush. Wrong answers explain; the learner
   can retry. It is practice, not assessment.

## Rules

- No grade, no answer record, no streak, no mastery, no review schedule. Finishing writes
  one optional marker, `ProgressState.basicsLessonCompleted` (decodeIfPresent; older files
  read as "not yet").
- Where it appears:
  - Learn's "Suggested next" shows it while it is unfinished, no node is cleared, there is
    no placement recommendation, and there is nothing to resume or review.
  - The first-run guide's last button opens it (if unfinished) instead of 쇼다운.
  - The learning path lists it above unit 1, always open, with a check once finished.
- Closing is always allowed and keeps nothing half-done (the lesson is four pages).
- KO/EN line parity at the default size; card faces fixed size; AX5 without clipping.

## Out of scope

Changing the Settings guide text; graded hand-ranking drills; new concepts or nodes.

## Verification

- Engine: `HandFrequencyTests` (release) — exact counts and royal split.
- Drills: `ProgressState` round-trips `basicsLessonCompleted`; old JSON decodes to `nil`.
- App: model test for the marker; UI test opening the lesson from Learn and finishing it.
- Screens: uisweep `basics-*` at large and AX5, KO and EN; parity OCR on the mini.
