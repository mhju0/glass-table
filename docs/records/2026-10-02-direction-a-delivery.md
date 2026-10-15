# Direction A delivery report (free table redesign and support pages)

- **Date:** 2026-10-02
- **Kind:** report
- **Originals:** `docs/reports/2026-10-02-direction-a-delivery.html` (standalone HTML with three embedded native PNGs), `docs/reports/2026-10-02-direction-a-delivery/` (verification.md, desktop.png, mobile.png) (tracked: `git show f5c5e22:<path>`)
- **Asked by / for:** owner; a delivery record for the approved Direction A native redesign (Steps 0-8) plus the separately published support contact and bilingual public pages.

## What it was
Local HTML delivery report summarising the Direction A free-table redesign (nine local commits on `feat/free-table-direction-a`), its test evidence and limits, the support/privacy publication (PR #10) and the physical iPhone 12 mini install of build 14. `verification.md` records how the HTML itself was checked.

## Findings and decisions
- Redesign scope: portrait seating (you bottom-right in cream; gold marks the acting seat, your selection or the primary commit), one card back (spades), fixed three-slot action dock (Fold, Check/Call, Raise/Bet) that keeps its height across decision, raise and Math faces. Your cards 43 pt, other table cards 36 pt. AX5 uses stacked seats with you first.
- Raise face: five presets, hold-to-repeat one-chip -/+ so every legal whole amount is reachable, explicit named commit. Fold/Check/Call commit on release.
- Math face (계산 · 이번 핸드 · 규칙 / Math · This hand · Rules) replaces the help sheet and uses public facts only; review equity appears after the hand only when one live opponent's cards were shown at showdown. Preflop fixture shows 40% required equity.
- Motion/haptics: paced deals, chip movement, refunds, all-in runout, settlement; Reduce Motion uses short crossfades; background/resume does not replay stale feedback.
- Named Korean bet actions use 벳; 14 remaining 베팅 occurrences (rounds/process wording in LearningGuideView, FirstLessonView, FreeTableView, TableView, PlacementView, OpponentPickerView) were retained verbatim for owner review; historical docs not rewritten.
- Preserved: engine, progression schema and saved settings unchanged; decide-before-reveal kept; offline, no accounts/analytics/ads/real money.
- Step 1 dock insets (top/left/right/bottom, pt): normal 25.67/21.67/20.33/20.33 -> 20.33/21.67/20/20; AX5 50/23.33/20/64 -> 20.33/23.33/20/20. Korean Learn cards: recommendation top 16.00 -> 16.00 pt, starting-point top 16.67 -> 15.67 pt.
- Owner-approved exceptions (spec section 13): concentric dock corners keep 19.235 pt minimum clearance vs 20 pt sides (0.765 pt exception); AX5 dock titles may wrap and action buttons may grow (normal buttons 87 pt); odds shown as N dots in two columns for 1 in N (1-in-4 stays 2x2); AX5 Math keeps three tiles in one horizontally scrollable row.
- Corrections with regression tests: Drills Facts evaluates 5-7 card made hands via existing `bestHandOfAny`; short-call Math uses publicly contestable pot amounts.
- Deferred: Math outs and next-card percentages (helper needs opponent's hidden hand); fast-table setting.
- Test evidence: Drills 398 (363 XCTest + 35 Swift Testing); app unit 99 (61 XCTest + 38 Swift Testing); 134 unique UI methods each with a passing outcome across full run plus bounded reruns; 544 accepted frames (136 scenes x two language/appearance pairs x large/AX5; 540 originals + 4 replacement slots).
- No single green whole-suite UI run is claimed: initial full UI run exited 65 with 11 failures (8 stale spelled-out hidden-card counts, 1 old 베팅 selector, 2 traversal assumptions) = 123/134; affected gate 13/17 (four AX Rules checks exhausted 24 short drags, helpers raised to 40 drags within the unchanged 240 s deadline); final six-method gate 6/6. Step 8 changed only test helpers, no product source.
- An EN normal RangeRead frame exceeded the dock bound by 0.1468 pt (under one 3x pixel); test now allows at most one rendered pixel.
- Screenshot provenance: embedded images are accepted KO/light large Step 7 sweep frames; they prove layout only, not motion or haptics. Matrix pairs KO+light and EN+dark (not a full cross product). Four EN/AX5 replacements used warm relaunch; unseeded PotMath-three question identity is unestablished. Debug result-review frames prove review copy, not production settlement.
- Timing: observed runout mean 597.1 ms at ~70 ms capture tolerance; dealer spring response 0.4 / damping 1 (no exact 0.4 s settling promise). Verified on Xcode 27 / iOS 27 Simulator only.
- Product source fingerprint, unchanged through Step 8: `b4e1aea94cc08f5bbd459cfa718670806c644434c55032e828ab6bcfe08334ff`.
- Support: separate patch changed four files on published main `79ce374` (Settings, privacy policy, submission URLs, new bilingual support page). Support asks for app version, iPhone model and what happened; policy distinguishes local records, exports, OS backups and voluntary email; app transmits no developer data. Published-main XcodeGen, generic build and 67 app units passed; Pages run 36976488804 and app CI 36976489966 succeeded. Public pages: https://mhju0.github.io/glass-table/support.html and privacy-policy.html, checked at 1280x900 and 390x844 with no overflow or errors. No email was sent.
- Physical haptic checklist left for the owner: selection tick on flip/tab/preset/-+ change (silent when unchanged or at limits); computer chip impact 0.5, all-in 0.8; card impact 0.5; rigid 0.75 once when your decision unlocks; medium commit 0.8, all-in heavy; success on winning/sharing, losing silent; at least 150 ms between events; priority your turn > commit > won > card > chip > tick.
- Report self-check (verification.md): Playwright at 1280x900 and 390x844, scrollWidth equals clientWidth, all 6 anchors and 4 expanders work, 20 relative links returned 200, zero final console errors (a 404 favicon was fixed with an empty data favicon); desktop.png/mobile.png are previews of the HTML only.

## Outcome
- Commits: 6dc95b6 (spec), 22bb963 (spacing), a52b094 (portrait table), dd348cb (dock), 3f6b61b (raise), 5513364 (Math/review), 03a0c56 (motion/haptics), bea4773 (app-wide presentation), 7c21f20 (final verification). Support patch 46e6ff5, publication record b0c0e35; support commit df927d8 merged via PR #10 as 8e808ca. Report committed as f3bb670.
- At report time the redesign branch was unpushed; 7c21f20 is now an ancestor of `main` (checked 2026-10-15).
- Build 1.0 (14) signed Release installed in place on iPhone 12 mini (iOS 27.0.1) from code at b0c0e35; the 4,114-byte progress backup was byte-identical before install, after install and after launch; ready Learn screen observed (an earlier white launch frame was rejected).

## Still open
- Physical haptic feel (checklist above), real VoiceOver, older-runtime (iOS 17) rendering were unverified at report time.
- Owner review of the 14 retained 베팅 occurrences.
- Math outs/next-card percentages and fast-table setting deferred.
- No App Store submission was part of this delivery. Whether later work closed these items is not stated in these sources [Unknown].
