# 003 — Hand-typed curves use GT.Motion tokens

- **Status**: TODO
- **Commit**: 9664c0a
- **Severity**: LOW
- **Category**: Cohesion & tokens
- **Estimated scope**: 4 files, ~6 lines

## Problem

All app motion goes through `GT.Motion.press` / `GT.Motion.change` except a few curves typed
in place, each slightly different (0.15 ease-in-out, 0.2 ease-out, 0.22 ease-out, a raw
0.22 timing curve). One also passes `duration: 0` for Reduce Motion instead of `nil`,
which still opens an animation transaction.

```swift
// GlassTable/Sources/DesignSystem/Theme.swift:68-71 — current
enum Motion {
    static let press = Animation.interactiveSpring(response: 0.22, dampingFraction: 0.9)
    static let change = Animation.interactiveSpring(response: 0.34, dampingFraction: 0.9)
}
// GlassTable/Sources/DesignSystem/TableSurface.swift:294
.animation(.easeInOut(duration: 0.15), value: seat.status)
// GlassTable/Sources/Screens/FreeTableHandCoachView.swift:57
withAnimation(.easeOut(duration: reduceMotion ? 0 : 0.2)) { page += delta }
// GlassTable/Sources/Screens/FreeTableView.swift:446
.animation(.easeOut(duration: reduceMotion ? 0.15 : 0.22), value: showHelp)
// GlassTable/Sources/Screens/PotMathLessonView.swift:63
withAnimation(.timingCurve(0.77, 0, 0.175, 1, duration: 0.22)) {
```

## Target

Two new tokens beside the springs:

```swift
enum Motion {
    static let press = Animation.interactiveSpring(response: 0.22, dampingFraction: 0.9)
    static let change = Animation.interactiveSpring(response: 0.34, dampingFraction: 0.9)
    /// Fades and entrances: strong ease-out.
    static let fade = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)
    /// A chip or card travelling across the table: strong ease-in-out.
    static let move = Animation.timingCurve(0.77, 0, 0.175, 1, duration: 0.22)
}
```

- `TableSurface.swift:294` → `.animation(GT.Motion.fade, value: seat.status)` (colour/state
  change, kept under Reduce Motion as before).
- `FreeTableHandCoachView.swift:57` → `withAnimation(reduceMotion ? nil : GT.Motion.fade) { page += delta }`.
- `FreeTableView.swift:446` → `.animation(GT.Motion.fade, value: showHelp)` (its transition
  is already opacity-only under Reduce Motion).
- `PotMathLessonView.swift:63` → `withAnimation(GT.Motion.move) {` — duration stays 0.22,
  which the `Task.sleep(for: .milliseconds(220))` at line ~70 depends on. Do not change it.

## Steps

1. Add `fade` and `move` to `GT.Motion` in `Theme.swift` exactly as above.
2. Make the four replacements above.

## Boundaries

- Do NOT touch `FirstLessonView.swift:1071` (`.easeOut(duration: 1.2)` glow): a deliberate
  slow attention pulse.
- Do NOT touch `SkillGlyph.swift` here (plan 002).
- Do NOT change the springs.

## Verification

- **Mechanical**: app builds; `grep -rn "easeOut(\|easeInOut(\|timingCurve(" GlassTable/Sources`
  returns only `Theme.swift` and `FirstLessonView.swift:1071`.
- **Feel check**: in the free table, open and close the help panel; open the hand coach and
  page forward/back; step through the pot-math lesson and watch the chip slide. All should
  feel as before or slightly snappier; nothing should lag.
