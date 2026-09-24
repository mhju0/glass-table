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

- Green felt identifies the poker table; surrounding panels adapt between warm paper and charcoal. System is the default appearance, with Light and Dark overrides in Settings.
- Amber identifies the next action and selected state. Correctness has separate semantic colors, words and symbols; answer choices remain equal-weight before commitment.
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

### Physical-device feedback, approved 2026-09-19

The opponent's cards, shared board, and learner's cards occupy centered upper,
middle, and lower regions. Subtle boundaries identify ownership without requiring
the learner to repeatedly read labels. Use 상대 카드 / 공용 카드 / 내 카드.

Card faces use consistent geometry across teaching and practice: separate rank and
monochrome suit areas, one rank size including 10, and consistent suit placement.
Highlight with an inset border and contrast, not scale. Card ownership is not a
reason to enlarge a hand relative to the board.

Hints belong to stable header chrome. Opening a hint must not reflow the question
or cards. Reserve real space for answers and explanations; scroll when needed,
never cover the learner's cards or shrink teaching text to make it fit.

Pot calculation identifies the participants and each action's actor. Distinguish
the total raised to from the chips added now. Show the actual stopping point in
the action sequence, and explain the calculation in readable steps after the
learner answers. Do not expose the resulting pot before commitment.

Use 따라 배우기 for a worked guide and 무승부 for a tied answer. Questions and
explanations align left; short answer labels and action buttons align centrally.
Share title/body styles, spacing, and button geometry across guide and practice
panels. Validate on the iPhone 12 mini and with accessibility text sizes.

### Familiar card faces, approved 2026-09-19

Use full upright playing-card faces with large corner rank/suit indices and an
inverted opposite-corner index. Familiar pip patterns and court artwork connect
the lesson to a physical deck; larger indices make recognition the first task,
without asking a beginner to count pips. Preserve identical card footprints across
ownership regions and a single index font size including 10. Keep red/black suit
encoding and the warm paper surface. Central artwork must leave the indices clear.
This supersedes the small centered horizontal rank/suit treatment above.

Keep lesson cards separate and upright. Overlap and perspective from casino apps
would make direct card comparisons harder. Do not enlarge the card footprint to
compensate for weak internal hierarchy. Render and inspect representative lessons
at compact iPhone size before delivery.

### Simplified card faces, revised 2026-09-19

The user rejected pip patterns, court illustrations and mirrored indices after
seeing the rendered app. Superseding the previous card-face direction, show one
large top-center rank and one large centered suit below. All ranks, including 10
and J/Q/K, share the same fixed font size and layout. Keep card dimensions and
red/black suit encoding consistent. No repeated suit decorations or artwork.

### Beginner-accessible depth, approved 2026-09-23

Welcome people who do not yet know poker's vocabulary or table sequence, while
retaining serious ranges, EV and advanced concepts as the learning destination.
Do not promise that completing the app makes someone a professional player.
Introduce a term beside its plain meaning; abbreviations alone are insufficient
on a beginner's first encounter. Brief, replayable lesson introductions explain
why the skill matters and what the learner will do. Returning learners get a
short reminder and direct access to practice, not a repeated mandatory lecture.

For pot calculation, pursue a table-led layout with integrated player contribution
areas and a user-paced action sequence. Keep amounts inside the table boundary,
distinguish amounts added from totals raised to, and retain folded players' paid
chips. Verify different participant counts rather than tuning only one fixture.
At large text sizes, readable ordered contributions take precedence over squeezing
every seat into a fixed diagram.

Use plausible calculation errors to construct incorrect options, but do not infer
the learner's reasoning from the selected number. Default feedback states the
correct result neutrally and offers the actual calculation on demand. This does
not remove explanations or the requirement that grading be inspectable.

The table/tray hybrid is currently a local mock under
`.scratch/pot-calculation-redesign/hybrid.html`, pending visual critique. This
direction does not establish app-wide introductions or native delivery.

### Pot replay simplification, approved 2026-09-23

Limit the current mock to three or four players. Show one question and one short
action caption inside the active seat, alongside its cumulative contribution.
Remove the separate context paragraph, clockwise transcript and action counter.
Progress marks and previous/next controls carry sequence; introductions and help
carry terminology. Keep the stopping point distinct from a settled betting round.

For this mock, motion 2 is a narrow functional exception: a 220ms chip movement
connects a pointer-triggered contribution to the center. Never move the numbers
or magnify the seat. Keyboard and reduced-motion use static updates. This is a
local prototype refinement, not a change to the installed app.

### Palette comparison, under review 2026-09-23

The owner found the mock's green-on-green hierarchy difficult to read and asked
for researched alternatives. The local mock now compares charcoal/amber,
slate/blue and paper/pine with semantic surface, text, action and feedback roles.
Chip totals remain neutral; green no longer fills the entire recommended screen.
Charcoal/amber is the agent recommendation, not an approved app-wide replacement.
Research and measured contrast are in
`.scratch/pot-calculation-redesign/palette-research.md`. Native styling is unchanged.

### Native pot lesson and adaptive appearance, delivered 2026-09-23

This supersedes the pending-native and palette-review status above. The approved
green-table/amber direction is implemented with warm neutral light surfaces and
charcoal dark surfaces. Keep table/card colors fixed and pair adaptive text with
its actual background. Light mode uses darker amber for white button labels;
dark mode uses pale amber with dark labels. See the
[delivery record](docs/specs/2026-09-23-pot-appearance.md) for verified coverage.

The native pot lesson uses three/four-player trays, one active-seat action caption,
previous/next controls and three shuffled answers. A first-entry introduction
explains why, how, and SB/BB; calculation help stays available. Larger text uses
ordered contribution rows and stacked answers in one scrolling lesson. A correct
answer never receives advance visual emphasis. Feedback offers the actual
arithmetic without claiming to know why an incorrect option was chosen.

The 220ms chip movement is decorative: amounts update immediately, backward/fold
steps stay static, and Reduce Motion suppresses the flight. Broader lesson-intro
coverage remains future work, not a consequence of shipping the pot introduction.

### Consistent learning/table direction, approved 2026-09-23

The owner approved a follow-up after testing the installed app. This direction
supersedes the exposed contribution totals and variable table/reveal layout above;
it is a design requirement, not a claim of native implementation.

Use full-screen lessons with clear exit and resume. Keep a shared wide green
rectangular table and consistent card geometry wherever seating/actions matter.
Keep table bounds stable through answers and explanations; let surrounding text
scroll rather than shrinking it. Charts and card-only tasks need not use a table.

Pot replay advances by tap. Original action amounts remain reviewable; calculated
contribution totals require a hint or answer reveal. Assisted completion counts
as practice, not unaided accuracy. Correct and incorrect feedback share one
layout below the unchanged question/table, with optional calculation steps.

Every mode needs a skippable, reopenable visual worked example with everyday
language and definitions at first use. In Play, show hidden cards, folds and the
central pot visually while preserving actual information boundaries.
The [approved spec](.scratch/consistent-learning-table/spec.md) and
[teaching plan](.scratch/consistent-learning-table/teaching-plan.md) record the
decisions, scope, evidence requirements and implementation limits.

### Bilingual line parity, owner rule 2026-09-24

This applies to the whole app, not only the prototype. A screen should look the
same in Korean and English; switching language must not change its layout.

- At the default text size on a compact 375pt iPhone, each heading, paragraph,
  note, button and label wraps to the same number of lines in both languages.
  When they differ, rewrite toward the shorter version rather than padding.
- A wrapped block's last line fills at least half its width. Rewrite or trim
  copy instead of leaving one word or syllable, such as 요., on its own line.
- Blocks that share a line count end at similar widths (within 25% of the width).
- Korean breaks only between words (어절), never inside one; English never
  breaks inside a word. Do not shrink text, stretch spacing or truncate to fit.
- Larger Dynamic Type sizes reflow naturally. There, the rules are no in-word
  breaks and no clipped text; matching line counts is not required
  (owner confirmed 2026-09-24; fitting every size would shorten default copy).
- Fit copy by measuring the rendered text, not by counting characters. The
  prototype's `audit-lines.cjs` shows the method; for native, the Vision OCR
  audit in `.scratch/consistent-learning-table/native-audit/` is the check.
