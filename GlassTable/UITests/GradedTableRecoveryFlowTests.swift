import XCTest

final class GradedTableRecoveryFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(postflop: Bool = false, ax: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-glassTable.language", "english", "-appAppearance", "dark",
                               "-UIPreferredContentSizeCategoryName",
                               ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_TABLE": postflop ? "station" : "tag",
                                 "GT_TEST_TABLE_SAVE_FAILURE": "1"]
        if postflop {
            app.launchEnvironment["GT_DEMO_TABLE_STEP"] = "1"
            app.launchEnvironment["GT_DEMO_TABLE_CONTINUE"] = "1"
        }
        app.launch()
        XCTAssertTrue(app.buttons["table-passive"].waitForExistence(timeout: 20))
        return app
    }

    private func value(_ app: XCUIApplication) -> String {
        app.descendants(matching: .any)["table-recovery-state"].value as? String ?? ""
    }

    private func cards(_ app: XCUIApplication) -> [String] {
        app.descendants(matching: .any)["table-hero-cards"]
            .descendants(matching: .any).allElementsBoundByIndex.map(\.label)
    }

    private func reach(_ button: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews["table-accessibility-scroll"].exists
            ? app.scrollViews["table-accessibility-scroll"] : app.scrollViews["table-footer-scroll"]
        for _ in 0..<8 where !button.isHittable { scroll.swipeUp() }
        XCTAssertTrue(button.isHittable)
    }

    private func checkRetry(postflop: Bool, ax: Bool = false) {
        let app = launch(postflop: postflop, ax: ax)
        let passive = app.buttons["table-passive"]
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: passive)
        waitForExpectations(timeout: 30)
        reach(passive, in: app)
        passive.tap()

        XCTAssertTrue(app.staticTexts["Progress was not saved"].waitForExistence(timeout: 5))
        let verdict = app.descendants(matching: .any)["table-verdict"]
        XCTAssertTrue(verdict.exists)
        let originalVerdict = verdict.label
        let originalCards = cards(app)
        XCTAssertFalse(originalCards.isEmpty)
        let localCount = postflop ? 2 : 1
        XCTAssertEqual(value(app), "\(localCount),0")
        XCTAssertFalse(app.buttons["table-continue"].isEnabled)
        XCTAssertTrue(app.buttons["Back to Play"].isEnabled)
        let retry = app.buttons["Retry save"]
        XCTAssertTrue(retry.isHittable)
        retry.tap()

        XCTAssertFalse(app.staticTexts["Progress was not saved"].exists)
        XCTAssertEqual(value(app), "\(localCount),1")
        XCTAssertEqual(verdict.label, originalVerdict)
        // Retry writes the pending state; it must not deal or replay a table action.
        XCTAssertEqual(cards(app), originalCards)
        let next = app.buttons["table-continue"]
        reach(next, in: app)
        XCTAssertTrue(next.isEnabled)
        next.tap()
        expectation(for: ready, evaluatedWith: passive)
        waitForExpectations(timeout: 30)
        reach(passive, in: app)
        passive.tap()
        XCTAssertEqual(value(app), "\(localCount + 1),2")
        XCTAssertTrue(verdict.exists)
        XCTAssertFalse(app.staticTexts["Progress was not saved"].exists)
    }

    func testPreflopSaveFailureFreezesAndRetryContinuesSameHandOnce() {
        checkRetry(postflop: false)
    }

    func testPostflopSaveFailureFreezesAndRetryContinuesSameHandOnce() {
        checkRetry(postflop: true)
    }

    func testLargestTextSaveFailureKeepsBackAndRetryAvailable() {
        checkRetry(postflop: false, ax: true)
    }

    func testHandEndingSaveFailureBlocksAdvanceUntilRetryThenNextHandCountsOnce() {
        let app = launch()
        app.buttons["table-fold"].tap()
        XCTAssertTrue(app.staticTexts["Progress was not saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(value(app), "1,0")
        let verdict = app.descendants(matching: .any)["table-verdict"].label
        let originalCards = cards(app)
        XCTAssertFalse(app.buttons["table-continue"].isEnabled)
        XCTAssertFalse(app.buttons["table-next-hand"].exists)
        XCTAssertFalse(app.buttons["table-change-opponent"].exists)

        app.buttons["Retry save"].tap()
        XCTAssertEqual(value(app), "1,1")
        XCTAssertEqual(app.descendants(matching: .any)["table-verdict"].label, verdict)
        XCTAssertEqual(cards(app), originalCards)
        let next = app.buttons["table-continue"]
        reach(next, in: app)
        next.tap()
        let newHand = app.buttons["table-next-hand"]
        XCTAssertTrue(newHand.waitForExistence(timeout: 5))
        reach(newHand, in: app)
        XCTAssertTrue(newHand.isEnabled)
        newHand.tap()
        XCTAssertEqual(value(app), "0,1")
        let fold = app.buttons["table-fold"]
        XCTAssertTrue(fold.waitForExistence(timeout: 5))
        reach(fold, in: app)
        fold.tap()
        XCTAssertEqual(value(app), "1,2")
        XCTAssertFalse(app.staticTexts["Progress was not saved"].exists)
    }
}
