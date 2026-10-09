import XCTest

final class FirstLessonFeedbackFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishGuideCompletesFiveRequiredComparisons() { exercise(english: true, accessibility: false) }
    func testKoreanGuideCompletesFiveRequiredComparisonsAX5() { exercise(english: false, accessibility: true) }

    private func exercise(english: Bool, accessibility: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "1"]
        app.launchArguments = ["-glassTable.language", english ? "english" : "korean"]
        if accessibility {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let start = app.buttons["firstLesson.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        start.tap()
        func tap(_ element: XCUIElement) {
            XCTAssertTrue(element.waitForExistence(timeout: 5))
            for _ in 0..<10 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable)
            element.tap()
        }
        let hero = app.buttons["firstLesson.choice.0"]
        let villain = app.buttons["firstLesson.choice.1"]
        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        let next = app.buttons["firstLesson.next"]
        // A fresh test store starts rotation at zero, with the hero winning.
        tap(villain)
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        let initialVerdict = verdict.label
        tap(next)
        tap(app.buttons["firstLesson.previous"])
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertEqual(verdict.label, initialVerdict, "Previous restores the committed wrong answer.")
        tap(next)
        for index in 2...5 {
            let progress = app.staticTexts[english ? "Comparison \(index)/5" : "비교 \(index)/5"]
            XCTAssertTrue(progress.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["firstLesson.rule"].exists)
            tap(hero)
            XCTAssertTrue(verdict.waitForExistence(timeout: 5))
            for _ in 0..<10 where !next.isHittable { app.swipeUp() }
            XCTAssertTrue(next.isHittable)
            XCTAssertLessThanOrEqual(next.frame.maxY, app.windows.firstMatch.frame.maxY)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "first-guide-required-\(english ? "en" : "ko-ax5")-\(index)"
            attachment.lifetime = .keepAlways
            add(attachment)
            tap(next)
        }
        // The five required comparisons lead to actions, then the wrap-up.
        tap(next)
        XCTAssertTrue(app.buttons["firstLesson.finish"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["firstLesson.moreComparisons"].exists)
        tap(app.buttons["firstLesson.finish"])
        XCTAssertTrue(app.buttons["basics.close"].waitForExistence(timeout: 5))
    }
}
