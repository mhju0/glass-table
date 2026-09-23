# Verify the complete learning release and preserve phone progress

Status: ready-for-human
Type: task
Original dependencies (satisfied): 02, 03, 04, 05, 06
Remaining human gates: beginner comprehension and physical VoiceOver
Risk: Class 3

Run integrated package/app/UI tests and KO/EN × light/dark × normal/AX5 coverage.
Inspect screenshots and exercise real controls on compact and larger screens.
Freeze the candidate for independent review, repair findings and refreeze.

Acceptance: no unresolved release-blocking findings; owner/adult-beginner
comprehension feedback addressed; in-place iPhone 12 mini installation with
preserved progress and app launch verified. Report spoken VoiceOver, iOS 17 and
distribution/App Store status separately. Update delivery/handoff records only
with completed work and exact evidence. No store submission implicit in this ticket.

## Technical delivery, 2026-09-23

The combined release passed 41 model XCTest, six appearance Swift Testing and
43 app UI tests on the Mini simulator, three focused compact-equity UI tests,
two Release smoke UI tests, 348 Drills XCTest plus 22 Swift Testing, 91 Engine
Release XCTest and 20 tooling tests. The 256-capture Mini matrix covered
KO/EN, light/dark and normal/AX5; eight compact-equity captures were refreshed.
The exact runtime candidate received independent Class-3 acceptance. Release
1.0 (4) was installed in place and launched on iPhone 12 mini; schema-1 progress
and migration recovery bytes were preserved, and relaunch readback passed.
See the [delivery record](../../../docs/specs/2026-09-23-beginner-native-release.md).

Human acceptance still covers adult-beginner comprehension and physical
VoiceOver. Minimum iOS 17 and signed distribution/App Store checks remain open.
