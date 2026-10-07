import XCTest

final class FirstLessonFeedbackFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishGuidePreviousAndOptionalComparisons() { exercise(english: true, accessibility: false) }
    func testKoreanGuidePreviousAndOptionalComparisonsAX5() { exercise(english: false, accessibility: true) }

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
        let hero = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", english ? "My cards" : "내 카드")).firstMatch
        let villain = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", english ? "Opponent's cards" : "상대 카드")).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 5))
        hero.tap()
        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        let initialVerdict = verdict.label
        app.buttons[english ? "Try different cards" : "다른 카드로 풀어보기"].tap()
        app.buttons["firstLesson.previous"].tap()
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertEqual(verdict.label, initialVerdict, "Previous must restore the committed local answer.")
        app.buttons[english ? "Try different cards" : "다른 카드로 풀어보기"].tap()
        XCTAssertTrue(villain.waitForExistence(timeout: 5))
        let edge = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 3, dy: 250))
        edge.press(forDuration: 0.1, thenDragTo: edge.withOffset(CGVector(dx: 210, dy: 0)))
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertEqual(verdict.label, initialVerdict)
        app.buttons[english ? "Try different cards" : "다른 카드로 풀어보기"].tap()
        villain.tap()
        app.buttons["firstLesson.next"].tap()
        app.buttons["firstLesson.next"].tap()
        let more = app.buttons["firstLesson.moreComparisons"]
        for _ in 0..<8 where !more.isHittable { app.swipeUp() }
        XCTAssertTrue(more.isHittable)
        more.tap()
        for index in 1...3 {
            XCTAssertTrue(app.staticTexts[english ? "More practice \(index)/3" : "추가 연습 \(index)/3"].waitForExistence(timeout: 5))
            XCTAssertTrue(hero.isHittable)
            hero.tap()
            XCTAssertTrue(verdict.waitForExistence(timeout: 5))
            let next = app.buttons["firstLesson.next"]
            XCTAssertTrue(next.isHittable)
            XCTAssertLessThanOrEqual(next.frame.maxY, app.windows.firstMatch.frame.maxY)
            // Let the reveal scroll and card pulse settle before visual evidence.
            Thread.sleep(forTimeInterval: 1.3)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "first-guide-comparison-\(english ? "en" : "ko-ax5")-\(index)"
            attachment.lifetime = .keepAlways
            add(attachment)
            next.tap()
        }
        XCTAssertTrue(app.buttons["firstLesson.finish"].waitForExistence(timeout: 5))
    }
}
