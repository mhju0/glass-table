import XCTest

final class GuidedHandFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testEnglishLearnBridgeWrongAnswerBackReplayAndPlay() { exercise(korean: false, ax: false) }
    func testKoreanLearnBridgeAX5() { exercise(korean: true, ax: true) }

    private func exercise(korean: Bool, ax: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString]
        app.launchArguments = ["-glassTable.language", korean ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        func tap(_ id: String) {
            let button = app.buttons[id]
            XCTAssertTrue(button.waitForExistence(timeout: 15))
            for _ in 0..<12 where !button.isHittable { app.swipeUp() }
            XCTAssertTrue(button.isHittable)
            button.tap()
        }
        func page(_ value: Int) {
            XCTAssertTrue(app.staticTexts["guided-hand-page-\(value)"].waitForExistence(timeout: 5))
        }
        tap("learn-guided-hand")
        page(0)
        tap("guided-hand-next")
        page(1)
        tap("guided-hand-choice-2")
        let feedback = app.staticTexts["guided-hand-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        let wrongFeedback = feedback.label
        tap("guided-hand-next")
        tap("guided-hand-previous")
        XCTAssertEqual(feedback.label, wrongFeedback)
        tap("guided-hand-next")
        for (pageIndex, answer) in [(2,0),(3,2),(4,0),(5,0)] {
            page(pageIndex)
            tap("guided-hand-choice-\(answer)")
            tap("guided-hand-next")
        }
        page(6)
        tap("guided-hand-less-help")
        page(0)
        tap("guided-hand-next")
        for (pageIndex, answer) in [(1,1),(2,0),(3,2),(4,0),(5,1)] {
            page(pageIndex)
            tap("guided-hand-choice-\(answer)")
            tap("guided-hand-next")
        }
        page(6)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = korean ? "guided-hand-ko-ax5-review" : "guided-hand-en-review"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        tap("guided-hand-play")
        XCTAssertTrue(app.tabBars.buttons[korean ? "플레이" : "Play"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons[korean ? "플레이" : "Play"].isSelected)
        XCTAssertFalse(app.buttons["guided-hand-close"].exists)
    }
}

final class RestoredLessonParityFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testPositionDirectAndResumedUseNumberedLoop() { exercise(range: false) }
    func testRangeDirectAndResumedKeepComparisonEvidence() { exercise(range: true) }

    private func exercise(range: Bool) {
        let app = XCUIApplication()
        let store = UUID().uuidString
        app.launchArguments = ["-glassTable.language", "english"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": range ? "u4-rangeRead" : "u1-position"]
        app.launch()
        func reach(_ element: XCUIElement) {
            XCTAssertTrue(element.waitForExistence(timeout: 15))
            for _ in 0..<16 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable)
        }
        if range {
            let start = app.buttons["range-start-medium"]
            reach(start); start.tap()
            let submit = app.buttons["Check answer"]
            reach(submit); submit.tap()
        } else {
            XCTAssertTrue(app.descendants(matching: .any)["position-boxed-loop"].waitForExistence(timeout: 15))
            let choice = app.buttons.matching(NSPredicate(format: "label IN %@", ["A","B","0","1","2","3","4","5","6","7"])).firstMatch
            reach(choice); choice.tap()
        }
        let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch
        XCTAssertTrue(completion.waitForExistence(timeout: 15))
        let identifier = range ? "range-difference-list" : "position-boxed-loop"
        XCTAssertTrue(app.descendants(matching: .any)[identifier].exists)
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        let resume = app.buttons["Resume lesson"]
        reach(resume); resume.tap()
        let evidence = app.descendants(matching: .any)[identifier].firstMatch
        reach(evidence)
        if range {
            XCTAssertTrue(app.staticTexts["Fill: answer · outline: your estimate"].exists)
        } else {
            XCTAssertTrue(app.buttons["position-terms-toggle"].exists)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = range ? "restored-range-comparison" : "restored-numbered-position"
        attachment.lifetime = .keepAlways
        add(attachment)
        reach(completion)
        app.terminate()
    }
}
