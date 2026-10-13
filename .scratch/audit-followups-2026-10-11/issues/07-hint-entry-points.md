# 07 — Lessons: overlapping hint entry points

Type: research
Status: resolved

## Question

In a lesson's "함께 풀기" (try together) step there are several ways to get
help. Are they redundant, and does the hint sheet hide what the learner needs?

## Answer (findings, 2026-10-12; decided)

Evidence: `evidence/hint-entry-points.jpg` (sweep
`.uisweep/20261012-010804-0tn4Xz`, screens `guided-showdown`, `guided-potodds`).

- Two help controls with the same lightbulb icon are on screen at once:
  - "힌트" pill, top right (`NodeSessionView.swift:358`). Opens a bottom sheet
    titled "풀이 순서" with a one-sentence cue (`:622`).
  - "푸는 방법" row above the cards (`LessonLearningUI.swift:36-50`,
    `ConceptDrillView.swift:414, 432`). Expands in place with the concept's
    longer how-to text.
- In English both are called "How to work it out"
  (`NodeSessionView.swift:595`, `LessonLearningUI.swift:46`).
- A third control, an info icon opening the concept explanation, appears when
  the drill has an explain concept (`ConceptDrillView.swift:397-399`); it is not
  shown in these two captures.
- The hint sheet is at least 220 pt tall from the bottom
  (`NodeSessionView.swift:588`), so while open it covers the answer buttons and,
  on shorter phones or longer cues, the lower cards. Not captured: the sweep has
  no hook that opens the sheet.
- Separate observation: the question is asked twice with different wording
  ("누가 이길까요?" as the title, "누가 이겼나요?" above the answers).

Options:

1. One help control: keep the in-place "푸는 방법" row, remove the "힌트" pill and
   its sheet, and put the pill's one-sentence cue as the first line of the
   expanded row. Nothing is ever covered.
2. Keep the "힌트" pill and remove the row.
3. Leave as is, but give the two different names in English.

Recommendation: option 1. Cost: UI tests that use the `guided-hint` sheet
(found in 4 UI test files) need updating.

## Comments

## Decision

Decision (owner, 2026-10-12): option 1. Keep the in-place "푸는 방법" row, remove the "힌트" pill and sheet, lead the expanded row with the one-sentence cue. The doubled question wording ("누가 이길까요?" / "누가 이겼나요?") was raised but not decided.
