# Native amount-control behavior

- **Date:** 2026-10-20 · **Kind:** feature notes / verification
- **Asked by / for:** owner approved the next Apple-alignment scope before any merge
  or TestFlight release: adopt more native control and presentation behavior.

## Findings and decisions

- Existing menus, dialogs, sheets and navigation already use native SwiftUI
  presentations. Retained them and the app's custom chrome, felt, cards, colors and
  10-point shapes; no broad Liquid Glass redesign or chart zoom.
- Replaced the free-table amount buttons' custom repeat task and release latch with
  [`buttonRepeatBehavior(.enabled)`](https://developer.apple.com/documentation/swiftui/view/buttonrepeatbehavior(_:)).
  Apple documents support for ordinary/custom `ButtonStyle`, not automatic support
  for custom `PrimitiveButtonStyle`; the latter and its supporting types were removed.
  The native API is available from iOS 17, not exclusive to iOS 26.
- Retained explicit active-scene/enabled action guards, disabled limits and independent
  amount bounds. A hold only changes the uncommitted amount; confirmation stays explicit.
- Preserved the 0.97 press scale and Reduce Motion handling using `GTPress`; pressed
  content now also dims to 0.78, consistent with the app's other buttons.
- Native cadence replaces the old 400/100 ms schedule. The old 0.9-second test hold
  produced one action; a two-second hold exercises multiple actions without asserting
  Apple's exact repeat delay or interval.
- Four critical amount-control tests now join the focused PR gate. Its budget grows
  from 45 to 50 minutes for the added checks and observed 39–42 minute existing runs.
  No package, grade, replay, persisted-key, build/version or release changes.

## Verification

- Based on scope-1 head `89bd57d`; final source, independent review and cloud CI are
  linked from [PR #58](https://github.com/mhju0/glass-table/pull/58).
- Fresh iPhone 17 / iOS 26.5: all ten `FreeRaiseFlowTests` passed, 177.685 seconds.
  Covers one-chip taps, repeat/release, both bounds, early and post-repeat drag-away,
  AX pan cancellation, presets, cancel/reopen, background return and explicit commit.
  Result: `/tmp/gt-native-repeat-normal-fresh.xcresult`.
- Supplemental actual active-hold interruption passed, 19.450 seconds. Settings was
  launched while an eight-second press remained active; timestamped screenshot and
  test state show backgrounding before gesture return. Resume remained stable, next
  tap changed one chip, reopen reset the draft, and hero/pot remained unchanged.
  Evidence: `/tmp/gt-native-repeat-interruption.xcresult`,
  `/tmp/gt-native-repeat-external-launch.log`, `/tmp/gt-native-settings-during-hold.png`.
- Actual system Reduce Motion: five representative checks passed, 87.597 seconds,
  including hold/limits/commit, both lifecycle checks, KO AX title and EN AX pan.
  Result: `/tmp/gt-native-repeat-rm.xcresult`. No debug Reduce Motion override.
- Root inspected normal idle/held frames and the Settings-during-hold screenshot.
  Normal frames: `/tmp/gt-native-normal-idle.png`, `/tmp/gt-native-normal-held.png`.
  Reduce Motion frames: `/tmp/gt-native-rm-idle.png`, `/tmp/gt-native-rm-held.png`.
  System Reduce Motion was restored off (readback 0); only the created simulator was
  deleted. Temporary helpers were removed and the generated project refreshed.
- A stale running UI-test process executed old methods despite an updated installed
  binary. That run was rejected; terminating/uninstalling the runner produced the
  authoritative ten-test run above. Temporary verification helpers are not delivered.

## Still open

- Physical-device feel/VoiceOver/haptics and minimum-iOS-17 runtime remain unverified.
  Simulator interactions do not establish measured performance or hardware acceptance.
- No merge, TestFlight upload or phone installation is included.
