# Native beginner UX refinement

Approved direction is recorded in [the delivery spec](../specs/2026-10-06-approved-native-ux-delivery.md). This is a local native build, not an App Store release.

The implementation preserves the felt, paper cards, restrained amber, native navigation, grading, review scheduling, saved progress schema and recovery behavior. Records derives completion and calendar dates without changing persisted state. Public summaries do not divide users by help use. The first session compares two hands, explains the committed answer and introduces a second hand before broader rules.

The compact-device visual review found fragmented accessibility-size action labels. Those controls now stack as full-width rows. Normal-size action heights remain 87 points. Expanded rank-reference rows are checked by their distinct spoken rank numbers and names; SwiftUI propagates the enclosing disclosure identifier to its rows. The English completion sentence was shortened to avoid inserting a question-shaped topic into a sentence.

## Evidence ledger

- Drills: 385 XCTest and 64 Swift Testing tests passed, including 14 new read-only activity-model cases. Calendar/DST, duplicate help/language lanes, future dates, gaps and completion denominators are covered. Log: `/tmp/gt-practice-activity-drills-tests.log`.
- App units: 70 XCTest and 38 Swift Testing tests passed in the native acceptance run. 90 affected UI methods have passing outcomes across the acceptance run and focused reruns. The initial acceptance run had 11 failures from stale test assumptions; the final ledger resolves all 11. This is not one clean full-suite run. Logs and per-method outcomes are retained in `.build/native-device/ui-outcomes.json` and the local HTML report evidence folder.
- Native captures: 36 compact-device states × Korean/English × light/dark × normal/AX5 = 288 retained frames; affected frames and iOS system-banner captures replaced. Larger iPhone17/iOS27 spot checks cover Learn, guided hand, Records and actions. Two automatic table captures were unusable (menu/blank), retained as failed evidence; actual two/four-player entry and bilingual AX action interaction separately passed on iOS27.
- Report: 20 native comparisons and 26 approved perspective comments, all 8 selectors checked at 390px without missing images/overflow; 1440px anchors/layout checked; final browser console clear.
- Release: device build 1.0(16), development signed for team XGY8UN2NYW. Bundle checks exclude debug fixture hooks, validate privacy declarations, languages, fonts and required notices. This does not establish distribution eligibility.
- Engine source did not change. The Engine release-test gate is not triggered by this presentation-only delivery and new Drills read model.

The original Learn inset finding was corrected: Suggested-next semibold 13 is the first visible text and already matches its inset. Only real Hint/skill-card role mismatches were changed.

## Limits

Screenshots and synthetic activity fixtures establish presentation for those states. They do not establish novice comprehension, transfer to poker outside the app, long-term motivation, physical VoiceOver order or haptic feel. Minimum iOS 17 and distribution checks remain open. Help retains its existing internal accuracy/mastery/review semantics; that metadata is not a public completion category.

The authorized iPhone 12 mini received a clean uninstall/reinstall of the development-signed Release 1.0 (16). Installed metadata confirms build 16; launch succeeded and a physical screenshot shows the Korean first-run starting-point screen. No phone progress was copied to the Mac and no phone-progress backup was created. Device metadata and the actual screenshot are retained in the local HTML report evidence folder, separately from simulator fixtures.
