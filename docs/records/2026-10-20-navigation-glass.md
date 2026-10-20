# Restrained navigation glass

- **Date:** 2026-10-20 · **Kind:** verification
- **Asked by / for:** owner approved scope 3 before merge/release and selected
  restrained glass on navigation controls, preserving felt, cards, colors and 10-point shapes.
- **Originals:** local simulator captures/results under `/tmp/gt-glass-*`; temporary,
  not tracked. Permanent behavior checks are in `NavigationChromeTests.swift`.

## Findings and decisions

- Explicit navigation roles apply static regular iOS 26 Liquid Glass to Close/Back,
  top-bar text actions and the free-table menu tile. Inline glyphs and amount/action
  controls retain their opaque surfaces. No domain, persistence, replay or grade changes.
- Preserved 40-point drawn / 44-point tappable geometry, the opaque chrome strip,
  alignment, Dynamic Type and existing press/cancellation behavior. No interactive
  glass, morphing, new gesture recognizers, settings or dependencies.
- Earlier systems, Reduce Transparency and increased contrast select the existing
  opaque treatment. Reduce Motion retains opacity feedback without scale.
- Initial pressed navigation text measured 3.77:1. A navigation-only 0.95 pressed
  opacity preserves the palette and yields 5.60:1 in light glass, 8.97:1 in dark AX5,
  4.68:1 with actual Reduce Transparency, and 6.24:1 with actual Increase Contrast.
  Root independently sampled solid glyph cores/backgrounds in source-matching PNGs
  using sRGB luminance. These are sampled states, not an exhaustive contrast audit.
- An optional GlassEffectContainer suppressed glyph press feedback. Same-harness
  baseline/candidate direct holds isolated the regression; removing only the container
  restored the existing dim/scale response. Retained independent surfaces, with no
  measured performance claim. GTChromeBar and GTPress remain unchanged from scope 2.
- Sources: [Apple adoption](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass),
  [custom glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views),
  [WCAG text contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).

## Outcome

- Separate branch `feat/liquid-glass-20261020`, stacked above unchanged PR #58 at
  `9d3bd633`; exact frozen review and full CI are tracked in the scope-3 PR.
- Fresh iPhone 17 / iOS 26.5 native baseline and final frames: English/light/normal
  and Korean/dark/AX5, lesson/glossary/free table. Both permanent interaction flows
  passed (111.065 seconds total): text/glyph drag cancellation, sheet scroll/close,
  stable close frame, menu open/dismiss, unchanged hand after raise cancellation,
  table close and setup Back. Initial harness failures were corrected without
  weakening behavior: horizontal sheet cancellation avoids native sheet pan;
  menu dismissal uses a verified outside margin rather than an obscured AX title.
- Evidence: `/tmp/gt-glass-navigation-final.{log,xcresult,mp4}`;
  `/tmp/gt-glass-final-manifest.json`; final held frames use
  `/tmp/gt-glass-navigation-final-pressed-*`. Baseline manifest:
  `/tmp/gt-glass-baseline-manifest.json`.
- Actual system Increase Contrast (61.035s), Reduce Motion (82.659s, full English
  interaction flow) and Reduce Transparency (62.767s) all passed, zero failures.
  Transparency and contrast were enabled independently with the other off, each
  restored afterward. Evidence: `/tmp/gt-glass-system-accessibility.{log,xcresult,mp4}`
  and `/tmp/gt-glass-system-accessibility-attachments/manifest.json`.
- Existing title/close alignment passed (6.138s); final reset-all passed (36.153s),
  with actual UI readback of all three settings off. Temporary Settings/direct-hold
  helpers were archived outside the repo and removed; XcodeGen regenerated successfully.
  Only the created disposable simulator was deleted. Evidence:
  `/tmp/gt-glass-cleanup-geometry.{log,xcresult}` and its attachment manifest.
- Added both navigation flows and existing chrome/title alignment regression to PR CI
  (22 focused cases total). Timeout 50→55 minutes preserves all existing gates.
- No merge, version/build bump, TestFlight upload or phone installation.

## Still open

- No pre-iOS-26 runtime is installed locally; availability fallback is source-checked
  and its opaque expression exercised through actual accessibility settings.
- Physical-device feel, VoiceOver, haptics and measured frame rate remain unverified.
