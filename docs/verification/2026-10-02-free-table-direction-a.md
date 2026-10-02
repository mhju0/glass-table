# Direction A verification — 2026-10-02

Steps 0–7 implement the approved redesign. Step 8 adds outcome checks and records final verification. All 134 tracked UI methods have passing outcomes across the complete invocation and bounded affected reruns; the original full invocation was not green.

The redesign remains on `feat/free-table-direction-a`; it has not been pushed. The approved spec and its §13 exceptions govern the implementation. Engine, progression schema and saved settings are unchanged. The two owner-approved Drills Facts corrections shipped in Step 5. Math outs and fast-table settings are deferred.

The final screenshot matrix has 136 scenes × Korean/English × large/AX5 = 544 frames. Korean uses light appearance and English dark appearance; this is not a complete language-by-appearance cross product. Additional focused captures cover relevant dark Korean cases. Initial sweep frames prove initial presentation only; native UI interactions separately establish scrolling, selection, confirmation, restoration and replay behavior.

Screenshots using a raw debug result fixture can retain final-street commitments. They establish review text and public board-prefix content, not production settlement. Production replay settlement is covered by dedicated motion and native tests. The normal wrong-answer introduction deliberately scrolls to the result; its question title is available by scrolling upward. Settings rows may pass beneath the native translucent tab bar while scrolling; final outcome tests verify that both Version label and value can fully clear it.

Execution uses Xcode 27 and iOS 27 Simulator. The deployment target is iOS 17 and compilation covers availability, but older-runtime rendering, real VoiceOver operation and physical haptic feel remain unverified. Native XCTest PNGs and recordings substitute for unavailable GUI automation. Recorded visual timing carries capture tolerance; source/unit timing is distinguished from directly observed timing.

Owner phone checks:

- Selection tick when the flip, tab, preset or −/+ changes; unchanged presets and controls at their limits remain silent.
- Light computer-chip impact at intensity 0.5, increased to 0.8 for all-in. Computer checks, folds and blinds remain silent.
- Soft card impact at 0.5 for public-card landing, showdown reveal and hero-card flip.
- Rigid impact at 0.75 once when the learner's decision unlocks.
- Medium commit at 0.8; all-in commit uses heavy impact with the same gold button treatment.
- Success when winning or sharing a pot; losses remain silent.
- Collision spacing is at least 150 ms, with priority your turn > commit > won > card > chip > tick. Background/resume must not replay stale feedback.

Remaining 베팅 strings (14):

| File and lines | Meaning retained |
|---|---|
| FirstLessonView.swift:413,414,447,471,521 | Betting rounds and street timeline |
| LearningGuideView.swift:108 | Street/round timeline |
| LearningGuideView.swift:121,123,131,132 | Additional/later betting assumptions and process |
| FreeTableView.swift:1593 | Explicit betting-round bot policy |
| TableView.swift:509 | No later betting under checkdown approximation |
| PlacementView.swift:114 | No additional betting assumption |
| OpponentPickerView.swift:77 | General betting situation |

Named bet actions use 벳. Additional/later/general-process wording is retained as a qualified terminology judgment; it does not name the current bet action. Historical documents remain unchanged.

Exact commands and failed attempts are retained in `.build/direction-a/step8/commands.txt` and `failures.md`; outcomes and screenshot manifests are retained beside them. These ignored local artifacts accompany this tracked verification summary.

Implementation commits, in approved order:

0. 6dc95b6 — spec and initial handoff
1. 22bb963 — spacing foundation
2. a52b094 — portrait table layout
3. dd348cb — fixed action dock
4. 3f6b61b — raise controls
5. 5513364 — Math and hand review
6. 03a0c56 — motion and haptics
7. bea4773 — app-wide presentation
8. Final verification and handoff (this commit)

Step 1 dock visible top/left/right/bottom insets (pt), measured at 3×:
normal 25.67/21.67/20.33/20.33 → 20.33/21.67/20/20;
AX5 50/23.33/20/64 → 20.33/23.33/20/20. Left text bearings are
qualified separately. Native concentric minimum corner clearance19.235pt vs
20pt sides is the owner-approved0.765pt exception.

Accepted screenshot provenance: KOlight .uisweep/20261002-115839-2PM5GT;
ENdark .uisweep/20261002-124710-B9rQF7; four ENAX replacements
.uisweep/20261002-133209-R58n44. Source fingerprint
b4e1aea94cc08f5bbd459cfa718670806c644434c55032e828ab6bcfe08334ff.
540 accepted originals +4 replacement slots; all rejected originals preserved.
Unseeded PotMath-three retains original scene/player arguments; generated
question identity is unestablished. This is a capture workaround, not a verified
product cold-launch fix.

Commands/results and failed attempts are retained in .build/direction-a/step1
through step8 reports, command ledgers and failure logs. Those local artifacts
are ignored by Git; they are not public hosted evidence. Videos distinguish
source timing from approximate observed rendering: face-on runout intervals
mean597.1ms at approximately70ms capture tolerance. SwiftUI dealer spring is
configured response0.4/damping1; SDK settling duration0.6s is not an exact
0.4s endpoint promise.

Final focused interactions accepted before the whole suite:
RangeRead KOlarge34.637s, KOAX87.810s, ENAX114.530s; ENlarge final36.442s.
All four use real Check answer and Next→2/5, with complete last-row, legend
and difference-list visibility. Root inspected all21 successful first-three-case
PNGs plus ENnormal failed-boundary PNG; final ENnormal seven PNGs accepted.
ENnormal detail native frame exceeds dock minY0.14678955pt, below one rendered
pixel(.333pt); visible ink clears the painted dock stroke3.333pt. Test frame
bounds permit at most1/rendered scale; no product change.
Basics bilingualAX recommendation button fully visible and opens actual course,
27.205s; root inspected four screenshots. Final whole Version label AND value
bounds: KO bottoms770.927/769.094pt, EN749.481/770.981pt, tabbar791pt;
KO58.038s/EN67.452s. Final focused3tests pass161.931s; final Version images accepted. Root inspected36 successful focused PNGs, including repeated Settings captures.

First native attempts failed due to bounded traversal/element-type/copy and
row-semantic assumptions. These are corrected test failures, preserved verbatim
in .build/direction-a/step8/failures.md, rather than product regressions hidden
by a passing retry. No source fix was needed.

Whole tracked invocation: 99 app units passed; 134 tracked UI methods executed,
123 passed and 11 failed (exit 65). Only the deliberately excluded, untracked
UXAuditCrawl was skipped. Eight failures were stale spelled-out hidden-card
counts, one was the old Korean action word 베팅, and two were insufficient or
intercepted traversal helpers. The preliminary Fold diagnosis was corrected:
numbered source showed the failure was hidden-card copy, and the repaired tests
retain and pass the original Fold interactions.

The affected 17-method gate passed 13 and failed four AX Rules traversals after
24 short drags. Logs and failure screenshots show positive scrolling progress;
the helper now allows 40 drags with unchanged complete-control bounds and
240-second deadline. Both whole Version rows passed after the reminder/share
predecessor, and all eight hidden-card-copy checks passed. Final six-helper gate passed 6/6 (exit 0): EN expanded policy 218.961 s,
EN Math/Rules 117.195 s, KO expanded policy 167.504 s, KO Math/Rules
103.248 s, manual reveal 23.058 s and settled review 40.060 s. All remain
under the unchanged 240-second deadline. The per-method outcome map contains
134 unique passing outcomes and preserves each invocation history.

No product source changed during Step 8. The accepted 544-frame Step 7 matrix
therefore remains applicable to the identical source fingerprint above. The
new focused native checks add scroll/reveal/Next/tab-navigation evidence.

Root inspected all 17 final back-face PNGs, including full originals of both
policy controls and final paragraph portions. First/last portions complement
each other; no claim that the entire AX paragraph fits one viewport. Also
inspected all 22 affected seat/rotation captures, both full Version captures
and four failed-budget PNGs. Final images: `.build/direction-a/step8/`
`back-final-native/manifest.json`, `affected-native/manifest.json` and
`native-review-manifest.json`. Root review notes and contacts are retained there.

Final checks: `xcodegen generate`, generic simulator `xcodebuild … build`,
`swift test --package-path GlassTableDrills` all pass; Drills 363 XCTest +
35 Swift Testing = 398. Whole `xcodebuild … test` passes app units
61 XCTest + 38 Swift Testing = 99; UI 123/134 initially pass, repaired
affected gate 13/17, final back helper 6/6. No failing tracked method remains.
Only excluded untracked UXAuditCrawl is skipped; no audit tool was changed.
The exact commands and all failures are reproduced in the companion
[Step 8 command and failure ledger](2026-10-02-direction-a-step-8-ledger.md).
