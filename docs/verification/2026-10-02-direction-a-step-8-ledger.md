# Direction A Step 8 command and failure ledger

These are executed commands and failed attempts, preserved verbatim. Corrected outcomes are described in the [verification report](2026-10-02-free-table-direction-a.md). No single green whole-suite invocation is claimed. Logs and xcresults remain local under `.build/direction-a/step8/`.

## Commands

```sh
xcodegen generate > .build/direction-a/step8/xcodegen.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/focused-native.xcresult -only-testing:GlassTableUITests/FinalPresentationVerificationTests -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsLastRowAndOtherTabsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsKOLastRowAndOtherTabsStayReachableAtAccessibilityXXXL test > .build/direction-a/step8/focused-native.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/focused-native-2.xcresult -only-testing:GlassTableUITests/FinalPresentationVerificationTests -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsLastRowAndOtherTabsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsKOLastRowAndOtherTabsStayReachableAtAccessibilityXXXL test > .build/direction-a/step8/focused-native-2.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/range-native-3.xcresult -only-testing:GlassTableUITests/FinalPresentationVerificationTests/testRangeReadKOLargeBottomAndComparisonReachable -only-testing:GlassTableUITests/FinalPresentationVerificationTests/testRangeReadENLargeBottomAndComparisonReachable -only-testing:GlassTableUITests/FinalPresentationVerificationTests/testRangeReadKOAXBottomAndComparisonReachable -only-testing:GlassTableUITests/FinalPresentationVerificationTests/testRangeReadENAXBottomAndComparisonReachable test > .build/direction-a/step8/range-native-3.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/final-focused.xcresult -only-testing:GlassTableUITests/FinalPresentationVerificationTests/testRangeReadENLargeBottomAndComparisonReachable -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsLastRowAndOtherTabsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsKOLastRowAndOtherTabsStayReachableAtAccessibilityXXXL test > .build/direction-a/step8/final-focused.log 2>&1
xcodegen generate > .build/direction-a/step8/final-xcodegen.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build > .build/direction-a/step8/final-build.log 2>&1
swift test --package-path GlassTableDrills > .build/direction-a/step8/final-drills.log 2>&1
xcrun simctl uninstall 736DFAB0-A3EB-4A2C-85BB-88B302D42D21 com.michaelju.glasstable > .build/direction-a/step8/final-uninstall.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/final-full.xcresult -skip-testing:GlassTableUITests/UXAuditCrawl test > .build/direction-a/step8/final-full.log 2>&1

xcrun xcresulttool export attachments --path .build/direction-a/step8/final-focused.xcresult --output-path .build/direction-a/step8/final-focused-native > .build/direction-a/step8/final-focused-export.log 2>&1
xcrun simctl boot 736DFAB0-A3EB-4A2C-85BB-88B302D42D21 > .build/direction-a/step8/final-boot.log 2>&1
xcrun simctl bootstatus 736DFAB0-A3EB-4A2C-85BB-88B302D42D21 -b >> .build/direction-a/step8/final-boot.log 2>&1
xcrun simctl uninstall 736DFAB0-A3EB-4A2C-85BB-88B302D42D21 com.michaelju.glasstable > .build/direction-a/step8/final-uninstall-2.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/final-full.xcresult -skip-testing:GlassTableUITests/UXAuditCrawl test > .build/direction-a/step8/final-full.log 2>&1

xcrun xcresulttool export attachments --path .build/direction-a/step8/final-full.xcresult --output-path .build/direction-a/step8/full-native > .build/direction-a/step8/full-export.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/affected-final.xcresult -only-testing:GlassTableUITests/AccessibilityFlowTests/testFreeTableEN2SeatsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/AccessibilityFlowTests/testFreeTableEN3SeatsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/AccessibilityFlowTests/testFreeTableEN4SeatsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/AccessibilityFlowTests/testFreeTableKO2SeatsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/AccessibilityFlowTests/testFreeTableKO3SeatsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/AccessibilityFlowTests/testFreeTableKO4SeatsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/AccessibilityFlowTests/testReminderAndMilestoneShareStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/BeginnerReleaseTests/testPracticeTableHidesOpponentCardsAndShowsThePot -only-testing:GlassTableUITests/BeginnerReleaseTests/testTableSetupGivesEachComputerItsOwnStyle -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsLastRowAndOtherTabsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/BeginnerReleaseTests/testSettingsKOLastRowAndOtherTabsStayReachableAtAccessibilityXXXL -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXENMathRulesReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXKOMathRulesReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXENExpandedPolicyEndReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testSettledReviewChanceAndResponsiveTabs -only-testing:GlassTableUITests/FreeTableBackFlowTests/testManualCardRevealDoesNotAddReviewEquity test > .build/direction-a/step8/affected-final.log 2>&1

xcrun xcresulttool export attachments --path .build/direction-a/step8/affected-final.xcresult --output-path .build/direction-a/step8/affected-native > .build/direction-a/step8/affected-export.log 2>&1
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,id=736DFAB0-A3EB-4A2C-85BB-88B302D42D21' CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath .build/direction-a/step8/back-final.xcresult -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXENMathRulesReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXKOMathRulesReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXENExpandedPolicyEndReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable -only-testing:GlassTableUITests/FreeTableBackFlowTests/testSettledReviewChanceAndResponsiveTabs -only-testing:GlassTableUITests/FreeTableBackFlowTests/testManualCardRevealDoesNotAddReviewEquity test > .build/direction-a/step8/back-final.log 2>&1

xcrun xcresulttool export attachments --path .build/direction-a/step8/back-final.xcresult --output-path .build/direction-a/step8/back-final-native > .build/direction-a/step8/back-final-export.log 2>&1

xcrun xcresulttool export attachments --path .build/direction-a/step8/back-final.xcresult --output-path .build/direction-a/step8/back-final-native > .build/direction-a/step8/back-final-export.log 2>&1

xcrun xcresulttool export attachments --path .build/direction-a/step8/back-final.xcresult --output-path .build/direction-a/step8/back-final-native > .build/direction-a/step8/back-final-export.log 2>&1
```

# Step 8 failures and rejected evidence

All failed native invocations and corrected test-only assertions are retained below. Final passing outcomes are recorded separately; the initial whole suite was not green. Root inspection errors are preserved in root-inspection-errors.txt. Worker source lookup returned:
```text
rg: GlassTable/Sources/RootView.swift: No such file or directory (os error 2)
```
Correct source found at Screens/RootView.swift; no product change.

## Initial focused gate: seven test-only failures

Exact assertion diagnostics:
```text
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/BeginnerReleaseTests.swift:253: error: -[GlassTableUITests.BeginnerReleaseTests testSettingsKOLastRowAndOtherTabsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed - Version frame=(76.0, 1812.260416666666, 72.66666666666666, 50.33333333333326), tabbar=(0.0, 791.0, 402.0, 83.0)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/BeginnerReleaseTests.swift:253: error: -[GlassTableUITests.BeginnerReleaseTests testSettingsLastRowAndOtherTabsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed - Version frame=(76.0, 2761.148111979166, 147.66666666666666, 50.333333333332575), tabbar=(0.0, 791.0, 402.0, 83.0)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:56: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadENAXBottomAndComparisonReachable] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:56: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadENLargeBottomAndComparisonReachable] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:56: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadKOAXBottomAndComparisonReachable] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:56: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadKOLargeBottomAndComparisonReachable] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:18: error: -[GlassTableUITests.FinalPresentationVerificationTests testSuggestedBasicsCTAOpensCourseInBothLanguagesAtAX5] : XCTAssertTrue failed
```
Settings traversal exhausted only 1600 pt of a longer page. RangeRead actually graded; saved hierarchy exposes `range-difference-list` on StaticText (2BD3FD66... line300 and 1E84CCBA... line300), not otherElements; legend is StaticText too. English FirstLesson skip uses actual copy `Skip guide`, not guessed `Skip introduction`. No app defect or source change.

## Second focused gate

Three methods passed (both Settings and bilingual Basics); four RangeRead test-helper assertions failed:
```text
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:107: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadENAXBottomAndComparisonReachable] : failed - Full bounds unavailable: Check answer, frame=(38.0, 792.0, 326.0, 89.33331298828125), scroll=(0.0, 0.0, 402.0, 873.9999999999999)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:59: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadENLargeBottomAndComparisonReachable] : XCTAssertTrue failed - Row 2. A2o excluded, K2o excluded, Q2o excluded, J2o excluded, T2o excluded, 92o excluded, 82o excluded, 72o excluded, 62o excluded, 52o excluded, 42o excluded, 32o excluded, 22 excluded
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:59: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadKOAXBottomAndComparisonReachable] : XCTAssertTrue failed - 2 행. A2o 제외, K2o 제외, Q2o 제외, J2o 제외, T2o 제외, 92o 제외, 82o 제외, 72o 제외, 62o 제외, 52o 제외, 42o 제외, 32o 제외, 22 제외
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:59: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadKOLargeBottomAndComparisonReachable] : XCTAssertTrue failed - 2 행. A2o 제외, K2o 제외, Q2o 제외, J2o 제외, T2o 제외, 92o 제외, 82o 제외, 72o 제외, 62o 제외, 52o 제외, 42o 제외, 32o 제외, 22 제외
```
Bottom comparison row can validly contain only excluded hands, so answer-word assertion was overstrict. Fresh comparison query plus actual comparison summary establishes transition. EN AX Check answer traversal stalled under center-column gestures; failed screenshot 24E5B0A2... preserved. Changed test drag path to the card gutter x25 (between outer18 and inner38); bounds remain strict and navigation-bar maxY is respected. No app change.

## Third focused gate

EN AX, KO AX and KO large passed. EN large failed native frame bounds by0.14678955pt (under one rendered pixel):
```text
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FinalPresentationVerificationTests.swift:110: error: -[GlassTableUITests.FinalPresentationVerificationTests testRangeReadENLargeBottomAndComparisonReachable] : failed - Full bounds unavailable: Missed · 10 kinds, ATo KTo QTo J9o 98o 75s 55 54s 44 33, frame=(18.0, 485.1468200683594, 253.33331298828125, 33.333282470703125), scroll=(0.0, 132.0, 402.0, 387.33333333333326)
```
Failed PNG AB0A2D27... measured last opaque text pixel y1545, sheet stroke first y1555:10px/3=3.333pt clear. Exact ROI/RGB and raw native bounds in range-rounding-measurements.json. Root authorized maximum one-rendered-pixel(1/scale=.333pt) native frame tolerance; no app/layout change.

Pixel probe emitted diagnostic warning:
```text
<stdin>:3: DeprecationWarning: Image.Image.getdata is deprecated and will be removed in Pillow 14 (2027-10-15). Use get_flattened_data instead.
```

Final sequence preparation stopped after successful generic build/Drills when the owned test simulator was Shutdown (uninstall exit149):
```text
An error was encountered processing the command (domain=com.apple.CoreSimulator.SimError, code=405):
Unable to lookup in current state: Shutdown
```
Only owned device was booted explicitly; fresh uninstall and whole test gate retried. No test had started, no assertions skipped.

Premature full-test log inspection before that preparation error was noticed:
```text
rg: .build/direction-a/step8/final-full.log: IO error for operation on .build/direction-a/step8/final-full.log: No such file or directory (os error 2)
```

## Whole final gate — corrected early diagnosis

Early progress mistakenly described line73 as Fold.isHittable. Numbered current source proves line73 is the opponent hidden-card wording assertion; Fold.isHittable is line80. Six flows stop at practice-1 before reaching later seats/Fold. Step6 spoke actual arrived count as `뒷면 카드 2장` / `2 face-down cards`; the old tests expect spelled-out `두 장` / `two`. The Fold/capped-dock diagnosis is superseded; no product defect or Fold traversal correction inferred. Full failed-seat label will be retained with revised assertion. Current whole run continues to inventory every failure before any test edit.

## Whole tracked suite: exit 65, 123 passed / 11 failed

```text
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/AccessibilityFlowTests.swift:73: error: -[GlassTableUITests.AccessibilityFlowTests testFreeTableEN2SeatsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/AccessibilityFlowTests.swift:73: error: -[GlassTableUITests.AccessibilityFlowTests testFreeTableEN3SeatsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/AccessibilityFlowTests.swift:73: error: -[GlassTableUITests.AccessibilityFlowTests testFreeTableEN4SeatsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/AccessibilityFlowTests.swift:73: error: -[GlassTableUITests.AccessibilityFlowTests testFreeTableKO2SeatsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/AccessibilityFlowTests.swift:73: error: -[GlassTableUITests.AccessibilityFlowTests testFreeTableKO3SeatsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/AccessibilityFlowTests.swift:73: error: -[GlassTableUITests.AccessibilityFlowTests testFreeTableKO4SeatsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/BeginnerReleaseTests.swift:504: error: -[GlassTableUITests.BeginnerReleaseTests testPracticeTableHidesOpponentCardsAndShowsThePot] : XCTAssertTrue failed - Computer 1, Selective, 99 chips left, 1 committed, 2 face-down cards
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/BeginnerReleaseTests.swift:256: error: -[GlassTableUITests.BeginnerReleaseTests testSettingsKOLastRowAndOtherTabsStayReachableAtAccessibilityXXXL] : XCTAssertTrue failed - Version frame=(76.0, 2703.5937499999995, 72.66666666666666, 50.33333333333394), tabbar=(0.0, 791.0, 402.0, 83.0)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/BeginnerReleaseTests.swift:131: error: -[GlassTableUITests.BeginnerReleaseTests testTableSetupGivesEachComputerItsOwnStyle] : XCTAssertTrue failed - Computer 2, Very aggressive, 98 chips left, 2 committed, 2 face-down cards
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FreeTableBackFlowTests.swift:276: error: -[GlassTableUITests.FreeTableBackFlowTests testAXENMathRulesReachable] : failed - Unreachable target free-table-policy-toggle: (20.0, 838.3333333333334, 362.0, 182.33333333333348), scroll (20.0, 651.9999999999995, 362.0, 202.0)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FreeTableBackFlowTests.swift:129: error: -[GlassTableUITests.FreeTableBackFlowTests testAXKOExpandedPolicyEndReachable] : XCTAssertTrue failed
```

Inspection polling typo (corrected immediately; no test effect):
```text
SyntaxError: unmatched ')'
```

## Affected gate: exit 65, 13 passed / 4 budget failures
```text
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FreeTableBackFlowTests.swift:279: error: -[GlassTableUITests.FreeTableBackFlowTests testAXENExpandedPolicyEndReachable] : failed - Unreachable target free-table-policy-toggle: (20.0, 1140.0, 362.0, 182.33333333333348), scroll (20.0, 651.9999999999998, 362.0, 201.9999999999999)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FreeTableBackFlowTests.swift:279: error: -[GlassTableUITests.FreeTableBackFlowTests testAXENMathRulesReachable] : failed - Unreachable target free-table-policy-toggle: (20.0, 1140.0, 362.0, 182.33333333333348), scroll (20.0, 651.9999999999998, 362.0, 201.9999999999999)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FreeTableBackFlowTests.swift:279: error: -[GlassTableUITests.FreeTableBackFlowTests testAXKOExpandedPolicyEndReachable] : failed - Unreachable target free-table-policy-toggle: (20.0, 729.333333333333, 362.0, 132.66666666666652), scroll (20.0, 620.0, 362.0, 234.33333333333348)
/Users/michaelju/Workspace/Projects/glass-table/GlassTable/UITests/FreeTableBackFlowTests.swift:279: error: -[GlassTableUITests.FreeTableBackFlowTests testAXKOMathRulesReachable] : failed - Unreachable target free-table-policy-toggle: (20.0, 729.333333333333, 362.0, 132.66666666666652), scroll (20.0, 620.0, 362.0, 234.33333333333348)
```
Gutter movement was measured at 110 pt per traversal; 24 iterations exhausted before the policy reached the unchanged bounds. The helper budget is now 40, with the existing 240-second method deadline.

## Final bounded back-helper gate

back-final.xcresult saved TEST SUCCEEDED, exit 0: six methods passed; no failures. No app-source, bounds or timeout change was needed.
