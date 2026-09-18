# Glass Table design direction

Approved 2026-09-14: Warm temperature, autonomous revamp decisions, relevant skills applied throughout implementation and verification.

## Purpose

Help a learner make one poker decision, understand its reason, and retrieve that skill again later. This is a Korean-first offline study product. Its visual identity comes from a quiet felt table and readable playing cards, not casino rewards or artificial competition.

## Learner perspective

Judge each flow from the learner's starting knowledge and intent. A person should
understand the situation, act without guessing how the interface works, learn why
the answer was right or wrong, and apply that reasoning to a different hand.
Consider confusion, interruption, accessibility and returning after a long break.
Completion counts and visual polish are supporting evidence, not proof of learning.

## Structure and behavior

Use the user's Toss principles for structure: one screen goal, one primary navigation action, minimal required input, vertical flow, and visible controls. Use Apple principles for behavior: immediate press feedback, native interruptible springs, stable spatial relationships, Dynamic Type and reduced motion. When elaborate motion conflicts with a simple flow, choose the simple flow.

Answer alternatives are deliberately equal-weight. Fold/call/raise are possible answers, not competing navigation CTAs. Never style an option to reveal the answer before commitment. Secondary information belongs in a sheet or disclosed section; the assumptions necessary to interpret a grade must still be visible when it is explained.

## Temperature and expression

Warm: friendly Korean 해요체, specific encouragement, calm corrections. Say what the person accomplished and what to do next. Do not infer broad expertise from a short session. Avoid exaggerated praise, streak pressure, mascots, confetti and decorative motion.

Energy 1 / rhythm 2 / motion 1. Use strong hierarchy and purposeful spacing. Different tasks should have different compositions, while the same kind of action should always behave the same way.

## Decision rationale

- Dark felt retains the physical poker-table context and keeps card faces prominent; this is a deliberate single appearance, with system sheets matching it.
- One mint accent identifies the next action and selected state. Correctness additionally uses words and symbols.
- Paper cards remain distinct from app panels because the cards are the object of study.
- Retain the bundled Pretendard Korean fonts for continuity and legibility; ordinary text scales, card-face drawings remain fixed-size with spoken labels.
- Use semantic spacing/radius/motion tokens. Flatten supporting content; reserve raised surfaces for an active task or answer area.
- Let answers and explanations scroll at accessibility sizes; controls must remain reachable without shrinking the person's chosen text size.
- Prefer native sheets/navigation over bespoke gestures. All primary paths work with visible taps. Sliders have tap alternatives.
- Motion acknowledges a press or a changed relationship; no loops, timed waits or decorative pulses.

## Educational grounding

See [research foundation](docs/specs/2026-09-13-revamp-research.md) and [baseline audit](docs/specs/2026-09-13-design-audit.md). Preserve independent retrieval before answers, gradual removal of support, delayed reviews, mixed checkpoints, explanatory feedback and honest measurements. The exact session lengths and tier thresholds are product heuristics, not validated professional-poker standards.

## Verification

### Copy and typography refinement, 2026-09-18

The first experience is a short, real card decision before an explanation of the
app. Give enough context to answer, explain the compared hands after commitment,
then offer a different example. Skipping and replay remain available. Guided
onboarding does not establish proficiency or mastery.

Write calm, direct Korean 해요체. Lead with the situation and action; introduce
technical terms beside their meaning. Feedback identifies the cards or reasoning
that matter. Buttons state their action. Review generated explanations, errors,
empty states and accessibility labels as carefully as headings.

At standard text sizes, revise copy or available width to remove awkward dangling
words and make short headings feel balanced. Do not justify paragraphs by stretching
spaces, shrink body text, or truncate teaching content to fit a preferred shape.
Use deliberate line breaks sparingly for short static headings; dynamic values and
accessibility sizes must reflow naturally. Keep shared leading edges, consistent
text/icon baselines, semantic line spacing and distinct paragraph spacing.

The approved store naming is 포커 배우기 — Glass Table in Korean and Poker Lessons —
Glass Table in English metadata. The Home Screen name stays Glass Table. English
metadata must explicitly describe the Korean-language lessons until full English
content is implemented and reviewed.

Build and test behavior, then inspect rendered screens on normal and compact iPhones and at accessibility text sizes. Exercise the real UI with XCTest, not only screenshot launch hooks. Preserve prior JSON progress and recovery behavior. An independent frozen-candidate review is required for progression integrity changes. Store submission follows the user's own testing and feedback.
