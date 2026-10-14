# 002 — Skill glyph accent settles quickly

- **Status**: DONE
- **Commit**: 9664c0a
- **Severity**: LOW
- **Category**: Easing & duration
- **Estimated scope**: 1 file, 2 lines (+ token from plan 003)
- **Depends on**: 003 (uses `GT.Motion.fade`). If 003 is not done, do 003's step 1 first.

## Problem

Each concept glyph in the lesson session list (`NodeSessionView.swift:1064`) animates its
accent in from 60% scale over 450 ms after a 150 ms delay. The list is opened often, and
the 600 ms total plays every time, so the icon keeps "arriving" after the reader has
already moved on. Large scale-in also breaks the physicality rule (never start below 0.9).

```swift
// GlassTable/Sources/DesignSystem/SkillGlyph.swift:17-20 — current
.onAppear {
    if reduceMotion { settled = true }
    else { withAnimation(.easeOut(duration: 0.45).delay(0.15)) { settled = true } }
}
```

```swift
// GlassTable/Sources/DesignSystem/SkillGlyph.swift:100-102 — current
private func accent(_ view: some View) -> some View {
    view.opacity(settled ? 1 : 0).scaleEffect(settled ? 1 : 0.6)
}
```

## Target

No delay, the shared 200 ms strong ease-out `GT.Motion.fade`
(`Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)`), accent starting at 90%.

```swift
else { withAnimation(GT.Motion.fade) { settled = true } }
...
view.opacity(settled ? 1 : 0).scaleEffect(settled ? 1 : 0.9)
```

## Steps

1. `SkillGlyph.swift:19`: replace `.easeOut(duration: 0.45).delay(0.15)` with `GT.Motion.fade`.
2. `SkillGlyph.swift:101`: change `0.6` to `0.9`.

## Boundaries

- Do NOT change the `settled`-driven position dot (`1.4` scale) or equity bar width; they
  follow the same animation and need no edit.
- Keep the Reduce Motion branch.

## Verification

- **Mechanical**: app builds.
- **Feel check**: open a lesson's session list with Slow Animations on. The accent fades in
  with the glyph, with no pause before it starts, and never visibly grows from small.
- **Done when**: SkillGlyph has no hand-typed curve and no `.delay`.
