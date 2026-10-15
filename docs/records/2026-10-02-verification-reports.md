# Verification reports: Direction A, iPhone install, support pages, native refinement

- **Date:** 2026-10-02 (to 2026-10-06)
- **Kind:** verification
- **Originals:** `docs/verification/2026-10-02-free-table-direction-a.md`, `docs/verification/2026-10-02-direction-a-step-8-ledger.md`, `docs/verification/2026-10-02-iphone-install.md`, `docs/verification/2026-10-02-support-publication.md`, `docs/verification/2026-10-06-native-refinement.md` (tracked: `git show f5c5e22:<path>`). Their local evidence under `.build/direction-a/` (step1-step8, iphone-install, support) and `.build/native-device/` was ignored by git and is not preserved there.
- **Asked by / for:** owner; verification records for the approved Direction A free-table redesign (spec and its section 13 exceptions), the support-contact publication and the 2026-10-06 native beginner UX refinement (spec `docs/specs/2026-10-06-approved-native-ux-delivery.md`).

## What it was
Five text records of what was tested, what failed and what was accepted, written at delivery time. The Step 8 ledger preserved every command and failed assertion verbatim; the others summarize outcomes and limits.

## Findings and decisions
Direction A free-table redesign (branch `feat/free-table-direction-a`, unpushed at the time):
- Implementation commits: 6dc95b6 spec, 22bb963 spacing, a52b094 portrait table, dd348cb fixed action dock, 3f6b61b raise controls, 5513364 Math and hand review (includes two owner-approved Drills Facts corrections), 03a0c56 motion and haptics, bea4773 app-wide presentation, then Step 8 verification. Engine, progression schema and saved settings unchanged. Math outs and fast-table settings deferred.
- Screenshot matrix: 136 scenes x KO/EN x large/AX5 = 544 frames (KO light, EN dark only; not a full language x appearance cross product); 540 accepted originals + 4 EN AX replacements.
- Whole suite was not green: 134 UI methods, 123 passed / 11 failed (exit 65). 8 failures were stale spelled-out hidden-card counts ("두 장"/"two" vs actual "뒷면 카드 2장"/"2 face-down cards"), 1 old Korean action word 베팅, 2 traversal helpers. Affected 17-method rerun 13/17 (four AX Rules traversals ran out of 24 drags at ~110 pt each; budget raised to 40, 240 s deadline unchanged); final helper gate 6/6. All 134 methods have a passing outcome across invocations; no single green whole-suite run is claimed. No product source changed in Step 8; all failures were test assumptions.
- Earlier focused failures: Settings traversal exhausted 1600 pt; RangeRead element-type/copy assumptions (actual copy "Skip guide"). EN large detail frame exceeded the dock by 0.14678955 pt (< one rendered pixel); root (agent) authorized at most 1/scale = 0.333 pt frame tolerance; visible ink cleared the dock stroke by 3.333 pt.
- Owner-approved exception: dock corner clearance 19.235 pt vs 20 pt sides (0.765 pt). Dock insets went from normal 25.67/21.67/20.33/20.33 to 20.33/21.67/20/20 and AX5 50/23.33/20/64 to 20.33/23.33/20/20.
- Haptics spec for owner phone check: selection tick on flip/tab/preset/-/+ changes; computer chip impact 0.5 (0.8 all-in); card impact 0.5; rigid 0.75 when decision unlocks; commit 0.8, all-in heavy; success on win/split, losses silent; at least 150 ms spacing with priority your turn > commit > won > card > chip > tick.
- 14 remaining 베팅 strings kept as round/process wording (FirstLessonView 413,414,447,471,521; LearningGuideView 108,121,123,131,132; FreeTableView 1593; TableView 509; PlacementView 114; OpponentPickerView 77); named bet actions use 벳; uncertain cases left for owner review.
- Final checks: Drills 363 XCTest + 35 Swift Testing = 398; app units 61 XCTest + 38 Swift Testing = 99. Runout interval mean 597.1 ms (~70 ms capture tolerance). Run on Xcode 27 / iOS 27 simulator.

iPhone 12 mini install (2026-10-02):
- Release build of `b0c0e35`, installed in place as 1.0 (14), iOS 27.0.1. progression.json copied read-only before and after; all three copies byte-identical (4114 bytes); no reset. Phone screenshot showed the Learn landing with saved lesson; an earlier white launch frame was rejected. (This in-place, data-preserving install predates the later AGENTS.md rule that reinstalls start fresh and that phone progress is not copied off-device.)

Support contact and public pages (2026-10-02):
- PR #10 published four files (SettingsView.swift, docs/privacy-policy.md, docs/submission.md, new docs/support.html): support commit df927d8, merged main 8e808ca, redesign cherry-pick 46e6ff5. Settings feedback link points at the MJ Apps support address; subject "Glass Table 피드백" unchanged.
- Support page has no forms, scripts, analytics or remote fonts. Pages deployment 36976488804 succeeded; support.html and privacy-policy.html returned 200 and matched source after normalization (one false mismatch from smart apostrophes). 67 app-unit tests passed. GitHub CI was still running at the snapshot, not claimed.

Native beginner UX refinement (2026-10-06):
- Drills 385 XCTest + 64 Swift Testing (14 new activity-model cases); app units 70 XCTest + 38 Swift Testing; 90 affected UI methods passing across acceptance run plus reruns (initial run had 11 stale-assumption failures; not one clean run).
- 36 states x KO/EN x light/dark x normal/AX5 = 288 frames; AX action labels now stack as full-width rows; normal action height 87 pt.
- Release 1.0 (16) development-signed; clean uninstall/reinstall on the iPhone 12 mini showed the Korean first-run screen; no phone progress copied.

## Outcome
Direction A was verified locally (later merged history not covered here [Unknown]); builds 14 and 16 installed on the owner's iPhone 12 mini; support and privacy pages live at mhju0.github.io/glass-table via PR #10.

## Still open
- As of these reports: iOS 17 runtime rendering, real VoiceOver, physical haptic feel, novice comprehension and distribution eligibility were unverified.
- Owner phone checks of the haptic events listed above.
- Owner review of the uncertain 베팅 general/process strings.
- Unseeded PotMath-three capture workaround: generated question identity unestablished, not a verified cold-launch fix.
