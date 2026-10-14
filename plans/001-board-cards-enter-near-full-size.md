# 001 — Board cards enter near full size

- **Status**: TODO
- **Commit**: 9664c0a
- **Severity**: MEDIUM
- **Category**: Physicality & origin
- **Estimated scope**: 1 file, 1 line

## Problem

When the flop, turn or river is dealt on the scripted tables (guided hand, walkthroughs,
lesson tables — every `TableSurface` without `freeVisuals`), each new board card grows
from 60% of its size. Cards are physical objects; a card that balloons from a small dot
reads as a pop-up, not a card landing on felt, and it happens on every street of every
hand.

```swift
// GlassTable/Sources/DesignSystem/TableSurface.swift:440-444 — current
ForEach(center.board, id: \.self) {
    TableCard(card: $0)
        .transition(.asymmetric(insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .opacity))
}
```

The transition is driven by callers that already use
`withAnimation(reduceMotion ? nil : GT.Motion.change)` (e.g.
`GlassTable/Sources/Screens/GuidedHandView.swift:503`), so Reduce Motion already shows no
scale. Nothing else needs to change.

## Target

Start at 92% size plus opacity. Removal unchanged.

```swift
// target
.transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity),
                        removal: .opacity))
```

## Repo conventions to follow

- Motion tokens live in `GlassTable/Sources/DesignSystem/Theme.swift:68-71` (`GT.Motion`).
  The driving animation is `GT.Motion.change`; do not change it.

## Steps

1. In `GlassTable/Sources/DesignSystem/TableSurface.swift`, inside `centerGroup`, change
   `.scale(scale: 0.6)` to `.scale(scale: 0.92)` on the `TableCard` insertion transition.

## Boundaries

- Do NOT touch the `freeVisuals` branch above it (flip animation, lines ~429-437).
- Do NOT change the removal transition or any caller.
- If the code does not match the excerpt, STOP and report.

## Verification

- **Mechanical**: the app builds (`xcodebuild ... build`), and `GuidedHandFlowTests` pass.
- **Feel check**: open the guided hand, call preflop, and watch the flop arrive. Slow
  animations in the simulator (Debug ▸ Slow Animations). Confirm the cards fade in at almost
  full size and settle, without visibly growing from small. Turn on Reduce Motion and
  confirm the card simply appears.
- **Done when**: no board-card insertion uses a scale below 0.9.
