import XCTest

final class GradedLearningFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(ax: Bool = false, postflop: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-glassTable.language", "english", "-appAppearance", "dark"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_TABLE": "tag"]
        if postflop {
            app.launchEnvironment["GT_DEMO_TABLE_STEP"] = "1"
            app.launchEnvironment["GT_DEMO_TABLE_CONTINUE"] = "1"
        }
        app.launch()
        XCTAssertTrue(app.buttons["table-chart"].waitForExistence(timeout: 15))
        return app
    }

    private func reach(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.windows.firstMatch.frame.minX)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.windows.firstMatch.frame.maxX)
    }

    func testChartBeforeCommitDoesNotRevealOwnHandRecommendation() {
        let app = launch()
        app.buttons["table-chart"].tap()
        XCTAssertTrue(app.staticTexts["Starting-hand chart"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["table-fold"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["table-verdict"].exists)
    }

    func testHandEndingFoldGetsFeedbackBeforeSummaryAndChartEvidenceAfterCommit() {
        let app = launch()
        app.buttons["table-fold"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["table-verdict"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["table-takeaway"].exists)
        XCTAssertFalse(app.buttons["table-next-hand"].exists)
        app.buttons["table-chart"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["defend-selected-evidence"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        app.buttons["table-continue"].tap()
        XCTAssertTrue(app.buttons["table-next-hand"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["table-chart"].exists)
    }

    func testAXPostflopChartIsExplicitlyAStartingHandReference() {
        let app = launch(ax: true, postflop: true)
        let chart = app.buttons["table-chart"]
        reach(chart, app: app)
        chart.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "does not advise decisions after the shared cards")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        let passive = app.buttons["table-passive"]
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: passive)
        wait(for: [ready], timeout: 30)
        reach(passive, app: app)
        passive.tap()
        let next = app.buttons["table-continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        reach(next, app: app)
        next.tap()
        XCTAssertTrue(app.buttons["table-policy"].exists)
    }
}
