# Device interaction and accessibility polish

- **Date:** 2026-10-20 · **Kind:** verification
- **Asked by / for:** owner approved scope 4 before merge/TestFlight, and explicitly
  selected preserving the connected iPhone's progress during candidate installation.
- **Originals:** `/tmp/gt-interaction-*` local logs, screenshots, xcresults and traces;
  temporary artifacts, not tracked. Separate audit record retains failures/limits.

## Findings and decisions

- Real VoiceOver exposed a redundant decorative magnifier stop before glossary
  search. Hide only that image from accessibility; retain the labelled search field.
- From the actual Settings invoker, VoiceOver Close returned to the Settings heading
  in KO AX5 and EN normal. A separate ten-poll/five-second check stayed there.
  Bind VoiceOver focus to the glossary button and restore it in sheet `onDismiss`;
  reset the transient binding before reopening. No timer, global focus rule or new
  persisted key. Existing appearance, grading, replay and progress semantics remain.
- AdjustmentButtons mixed English labels with Korean increase/decrease verbs.
  Localize those verbs in English; preserve Korean labels, geometry and callbacks.
  Update the existing slider reversal selector to the corrected label.
- Real-device VoiceOver uses public Xcode 27 `XCUIVoiceOverService`; Debug test stores
  isolate question/interaction checks. This is distinct from Release profiling.
  Before/after utterances and focused-control activation are captured; direct
  element taps are not used to conceal incorrect VoiceOver focus.
- Physical device: iPhone 12 mini / iOS 27.0.1, Xcode 27.1. Signed Release update
  installed without uninstalling; existing in-progress lesson remained visible.
  No progress files exported or copied off-device. Initial VoiceOver state was off; restore after checks.
- Initial automation attempt timed out at Apple's passcode prompt. Owner entered it;
  subsequent authorized runs proceeded. Synthetic keyboard Escape did not dismiss
  the sheet; that failure is retained separately from actual Close/gesture outcomes.

## Verification

- Preliminary Release 4-cycle glossary open/scroll/close run passed. Synchronized
  Animation Hitches trace: 51.643s, 1,350 frame-lifetime events, two app hitches of
  16.67ms. This is a bounded observation, not an FPS or before/after improvement claim.
- Trace also contains 46 potential delays over 33ms. Independent full-stack analysis
  found 34 intervals dominated by XCTest snapshots; 4,973/5,990 samples (83%) contain
  explicit XCTest/AX snapshot ancestry. First 318.63ms interval is mostly native sheet
  presentation/layer-shadow work, not an attributed glossary-row bottleneck.
  No lazy-layout/concurrency optimization justified by these measurements.
- Trace app was Release with magnifier fix, before focus fix; binary SHA256
  `c7cf733551e71f3a49bfe4abbc208c130440e30dc9061fdfa84837ed4225d1a3`.
  `/tmp/gt-interaction-device-release-profiled.{log,xcresult,trace}` and exported XML.
- Physical table/menu VoiceOver passed (96.577s); reached visible facts/actions and
  face-down opponents. Raw glossary before-fix/after-fix focus logs remain separate.
- Compact baseline: 25/25 interaction cases passed (1,028.288s), including 10 amount,
  6 bilingual seat-count, AX onboarding/Range Read, glossary search and preserved
  drafts/reveals, Progress and slider checks.
- Final physical 10/10 passed (357.327s): four amount/hold/background/pan cases,
  normal showdown/privacy, both navigation flows, EN normal + KO AX5 VoiceOver
  two consecutive focused-button open/close cycles, and new-label slider reversal.
  Focus returned to the invoker each time; moving onward stayed there without a
  later focus steal. Initial physical RM/RT/contrast/VoiceOver readback all off;
  VoiceOver restored off. Loaded Debug image SHA256
  `0809f7de33536459cb80af2e0c2a6faad4f699e1b9f356778abad8a538bf26dd`.
  `/tmp/gt-interaction-device-final-interactions.{log,xcresult}` and attachments.
- Automated manual-scrub window timed out and restored VoiceOver off. Owner later
  replied “Yes closed right now,” confirming manual dismissal; this is owner-reported,
  not a captured automation assertion or focus-return trace. Subsequent device
  readback confirmed VoiceOver disabled. Preserve the original timeout separately.
- Final Release four-cycle navigation passed (64.522s); settled Learn still showed
  the original in-progress lesson. Release binary SHA256
  `8ab27635cafefc1d5d0e947edaf335e0f837daa0e96faeb9915e185bc1254a0b`.
  Final-profiler PID lookup failed while that run was active; earlier trace is a
  separate configuration, not an exact-final performance or improvement claim.
  `/tmp/gt-interaction-source-manifest.json` binds source blobs and loaded images.
- Final simulator invoker/search checks (four language/text variants), corrected-label
  slider reversal and bilingual precision changes passed. Temporary precision helper
  initially misparsed Korean numeric speech; corrected parser passed (30.533s),
  retaining draft assertions. Original failing job remains in final-normal results.
- Final simulator actual-system checks passed: Reduce Motion 4/4 (86.815s),
  Reduce Transparency 3/3 (73.986s), increased contrast 3/3 (71.158s). Separate
  final Settings readback confirmed all three restored off (35.111s).
- Full CI and exact frozen independent review are tracked in the PR.
- Sources: [Apple audits](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app),
  [responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness),
  [VoiceOver gestures](https://support.apple.com/en-au/guide/iphone/iph3e2e2281/ios).

## Still open

- See `2026-10-20-accessibility-audit-followup.md` for strict audit failures and
  unlocated diagnostic flags. No universal accessibility/VoiceOver/haptic clearance.
- No pre-iOS-26 runtime; synthetic device input does not establish subjective feel.
- No merge, build-number bump, TestFlight upload or App Store submission.
