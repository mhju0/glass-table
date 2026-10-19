# Existing motion alignment with Apple's guidance

- **Date:** 2026-10-20 · **Kind:** feature notes / verification
- **Asked by / for:** owner approved scope 1: refine existing motion while retaining
  the layout, visual identity, native presentation and teaching behavior.

## Findings and decisions

- Reference: Apple's [Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion)
  and [iOS 26 adoption guidance](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).
  Favor brief, purposeful feedback, direct manipulation, optional movement and cancellation.
  Apple does not prescribe one universal animation duration for this app.
- Added missing Reduce Motion handling to choice-enabled feedback, river selection,
  seat-status feedback and the free-play help dock. Shared board insertion keeps an
  opacity-only transition under Reduce Motion, replacing its normal 0.92 scale entrance.
- Range Read's grid follows width/top-exclusion slider changes without implicit springs.
- Removed the first-lesson verdict's one-shot 1.2-second shadow fade and its local state.
  Persistent verdict text, border, glyph and accessible labels remain.
- Retained shared timing tokens, existing press feedback, the guarded short skill-glyph
  entrance, native presentation and instructional replay timing/cancellation. No Liquid
  Glass redesign, geometry/color changes, new settings, domain/package or persisted-key edits.

## Verification

- Product/permanent-test candidate: `3dc9023`, based on released-main docs head `41cb265`.
  Independent root source review accepted the bounded Class-1 presentation changes.
- Fresh iPhone 17/iOS 26.5 simulator and derived data: build-for-testing passed;
  119 XCTest + 46 Swift Testing app tests passed.
- All ten normal-motion target scenarios passed across focused runs: first lesson
  EN normal/KO AX5, guided board/replay EN normal/KO AX5, Outs KO/EN selection reversals,
  Range Read continuous drag/reversal, help reversals, initial-deal privacy and
  background chip-flight resume. New test setup/grid-sampling errors were corrected;
  no product fix or weakened behavior assertion was required by those reruns.
- Actual system Reduce Motion enabled through Settings, switch value 1 and simulator
  setting verified. All nine affected UI checks passed (368.060 seconds), without
  `GT_DEMO_REDUCE_MOTION`: lesson, guided KO AX5, Outs KO/EN, slider/help reversals,
  pot replay controls, showdown/fold privacy/settlement and background feedback.
- Evidence: `/tmp/gt-motion-normal.mp4`, `/tmp/gt-motion-normal-timeline.json`,
  `/tmp/gt-motion-system-rm.mp4`, `/tmp/gt-motion-system-rm.xcresult` and attachments.
  Root inspected sampled verdict/river frames; recordings establish captured interaction,
  not measured performance or physical-device feel. No before/after baseline video.
- Temporary Settings harness is verification-only and is not part of the product/tests.
  Initial cloud CI `39287743826` passed 14 of 15 focused UI tests. Its new slider test
  incorrectly assumed a normalized screen coordinate restored an exact stepped value:
  iOS 26.2 produced 20 → 67 → 22 rather than 20 → 67 → 20. The regression check now
  distinguishes gesture reversal from exact restoration using the existing ±1 controls;
  final grid/value, question identity and uncommitted-state assertions remain exact.
  Corrected checks passed on iOS 26.5 with normal motion (20 → 67 → 12, eight
  increments back to 20) and system Reduce Motion (20 → 68 → 13, seven increments
  back to 20). Results: `/tmp/gt-motion-portability-normal.xcresult` and
  `/tmp/gt-motion-portability-rm.xcresult`. Exact iOS 26.2 coverage remains a CI check.
  Published-branch cloud results are available in the PR's checks and
  [CI branch view](https://github.com/mhju0/glass-table/actions/workflows/ci.yml?query=branch%3Afix%2Fios-motion-20261020).

## Still open

- Physical-device motion/haptics, measured frame rate and minimum-iOS runtime were not
  verified. This is a source refinement; no build/version bump, merge, TestFlight upload
  or phone reinstall is included. Latest released app remains 1.0 (36).
