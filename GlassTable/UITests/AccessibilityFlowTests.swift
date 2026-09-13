// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class AccessibilityFlowTests: XCTestCase {
    private let accessibilityXXXL = [
        "-UIPreferredContentSizeCategoryName",
        "UICTContentSizeCategoryAccessibilityXXXL",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEquityAnswerCanBeSubmittedAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_SEED": "1",
            "GT_DEMO_NODE": "u2-equitySense",
        ])

        XCTAssertTrue(app.staticTexts["쇼다운까지 갔을 때 내가 이길 확률은?"]
            .waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["상대"].exists)

        let submit = app.buttons["확인"]
        XCTAssertTrue(scrollUntilHittable(submit, in: app),
                      "The full equity input and submit action must remain reachable at AX XXXL.")
        submit.tap()

        let next = app.buttons["다음 문제"]
        XCTAssertTrue(scrollUntilHittable(next, in: app),
                      "The equity reveal and its advance action must remain reachable at AX XXXL.")
    }

    func testShowdownWalkthroughAdvancesAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u1-showdown",
            "GT_DEMO_BEAT": "0",
        ])

        XCTAssertTrue(app.descendants(matching: .any)["7단계 중 1단계"]
            .waitForExistence(timeout: 15))

        for step in 1...7 {
            let title = step == 7 ? "이해했어요" : "다음"
            let advance = app.buttons[title]
            XCTAssertTrue(scrollUntilHittable(advance, in: app),
                          "Walkthrough step \(step) must expose its advance action at AX XXXL.")
            advance.tap()
        }

        XCTAssertTrue(app.staticTexts["함께 풀기"].waitForExistence(timeout: 10),
                      "Completing all seven beats should reach guided practice.")
    }

    func testTableFoldReachesSummaryAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
        ])

        let fold = app.buttons["폴드, 0bb"]
        XCTAssertTrue(scrollUntilHittable(fold, in: app),
                      "The preflop fold action must remain reachable below the table context at AX XXXL.")
        fold.tap()

        XCTAssertTrue(app.staticTexts["결과와 결정은 따로 봐요"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["프리플랍 결정은 공개된 디펜드 차트와 비교했어요. EV 손실은 측정하지 않았어요."]
            .waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "EV 손실은 0bb예요"
        )).firstMatch.exists)
        let nextHand = app.buttons["다음 핸드"]
        XCTAssertTrue(scrollUntilHittable(nextHand, in: app),
                      "The complete hand summary must remain scrollable at AX XXXL.")
    }

    private func launch(environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = accessibilityXXXL
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication,
                                     maximumSwipes: Int = 12) -> Bool {
        guard element.waitForExistence(timeout: 15) else { return false }
        for _ in 0...maximumSwipes {
            if element.exists, element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }
}
