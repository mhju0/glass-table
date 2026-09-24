# Audit question screens for bottom-anchored choices and tappable styling

Status: done
Type: task

Check every screen where the learner answers or taps: choices in the bottom
sheet, content above; every tappable element is a filled button or a bordered
card with a chevron. List offenders with file:line before changing them.

## Audit (2026-09-25)

Question screens without bottom-anchored choices:
- `ConceptDrillView.swift` `PotMathDrill`: choices and verdict were inline in the
  scroll. Now on `DrillShell` (bottom sheet, verdict tint). Test
  `testPotMathChoicesSitInTheBottomSheet` failed before, passes after.
- `PlacementView.swift`: answers were inline under the prompt. Now anchored to the
  bottom of a viewport-height column (scrolls at AX sizes), as bordered cards.
- Left as is: `LearningGuideView` retrieval questions sit inline above the fixed
  next/previous bar. They are part of a reading page, not a graded question.

Plain-text tappables converted:
- `LearningGuideView.swift:74` 이전 이야기 → `SecondaryCTAButton`
- `PlacementView.swift:55` 아직 잘 모르겠어요 → bordered answer card;
  `:59` 확인 없이 시작하기 → `SecondaryCTAButton`
- `NodeSessionView.swift:865` 다른 개념 고르기 → `SecondaryCTAButton`
- `ConceptDrillView.swift` 저장 다시 시도 ×4 → `SecondaryCTAButton`
- `ProgressFileFeedback.swift:20` 다시 저장 → bordered capsule
- `PotMathLessonView.swift:27` 계산 방법 → bordered capsule with ? icon
- All six `DisclosureGroup`s → `GTDisclosureStyle` (bordered heading row, turning
  chevron, expanded/collapsed value), applied once in `GlassTableApp`.

Exempt on purpose: nav-bar chrome (닫기, 건너뛰기, 안내 건너뛰기), system
alerts/dialogs, Settings grouped rows, and 새로 시작하기 on the recovery screen
(a last-resort reset should stay quiet).
