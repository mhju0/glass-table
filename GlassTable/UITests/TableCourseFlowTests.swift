// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class TableCourseFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testTurnsRestoresDraftRepeatsExactMissAndOpensCumulativeReview() {
        let app = launch("c9")
        attach(app, "turns-worked-en-light")
        tap("next", app)
        let first = element("activity-C9-01", app)
        XCTAssertTrue(first.exists)
        let wrong = app.buttons.matching(identifier: "table-course-choice-0").firstMatch
        tap("choice-0", app)
        app.terminate()
        app.launch()
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["table-course-submit"].isEnabled)
        let originalAnswer = wrong.label
        tap("submit", app)
        XCTAssertTrue(element("feedback", app).waitForExistence(timeout: 6))
        attach(app, "turns-feedback-en-light")
        tap("next", app)
        for _ in 0..<4 { answer(0, app) }
        XCTAssertTrue(element("retry", app).exists)
        XCTAssertTrue(first.exists)
        XCTAssertEqual(wrong.label, originalAnswer)
        for _ in 0..<5 where element("retry", app).exists { answer(0, app) }
        XCTAssertTrue(element("results", app).exists)
        tap("next", app)
        tap("review", app)
        XCTAssertTrue(app.staticTexts["course-review-scope"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["course-review-scope"].label, "Review everything so far")
        attach(app, "turns-cumulative-review-en-light")
    }

    func testChipReplayAndGuidedHandReachExistingCoach() {
        let replay = launch("d6", language: "ko", ax: true)
        tap("next", replay)
        XCTAssertTrue(element("activity-D6-replay-preflop", replay).exists)
        tap("next", replay)
        XCTAssertTrue(element("activity-D6-replay-flop", replay).exists)
        attach(replay, "chips-flop-ko-dark-ax5")
        replay.terminate()
        replay.launch()
        XCTAssertTrue(element("activity-D6-replay-flop", replay).waitForExistence(timeout: 15))
        tap("next", replay)
        tap("next", replay)
        tap("next", replay)
        XCTAssertTrue(element("activity-D6-01", replay).exists)
        XCTAssertFalse(element("feedback", replay).exists)
        tap("choice-0", replay)
        tap("submit", replay)
        XCTAssertTrue(element("feedback", replay).exists)
        attach(replay, "chips-pot-reveal-ko-dark-ax5")
        tap("next", replay)
        for amount in [6, 77, 10, 6] {
            let answer = replay.buttons.matching(NSPredicate(
                format: "identifier BEGINSWITH %@ AND label == %@", "table-course-choice-", "칩 \(amount)개"
            )).firstMatch
            XCTAssertTrue(answer.exists)
            reveal(answer, in: replay)
            answer.tap()
            tap("submit", replay)
            tap("next", replay)
        }
        XCTAssertTrue(element("results", replay).exists)
        tap("next", replay)
        XCTAssertEqual(replay.buttons["table-course-done"].label, "안내 핸드 연습")
        tap("done", replay)
        XCTAssertTrue(element("activity-D-table-01", replay).waitForExistence(timeout: 10))
        replay.terminate()

        let guide = launch("d-table")
        attach(guide, "guided-flop-en-light")
        for index in [0, 2, 1] {
            tap("choice-\(index)", guide)
            XCTAssertTrue(guide.buttons["table-course-choice-\(index)"].isSelected)
            XCTAssertFalse(element("feedback", guide).exists, "Selecting a seat must wait for Check answer.")
        }
        attach(guide, "guided-choices-en-light")
        tap("submit", guide)
        tap("next", guide)
        answer(1, guide)
        answer(2, guide)
        XCTAssertTrue(element("results", guide).exists)
        tap("next", guide)
        tap("coach", guide)
        let close = guide.buttons["coach-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        XCTAssertTrue(guide.staticTexts["coach-example"].exists)
        XCTAssertFalse(guide.staticTexts["coach-verdict"].exists)
        attach(guide, "guided-coach-en-light")
        close.tap()
        XCTAssertTrue(element("results", guide).waitForExistence(timeout: 10))
        tap("done", guide)
        XCTAssertTrue(element("activity-E1-example", guide).waitForExistence(timeout: 10))
    }

    func testStartingHandChartAndChoicesReachableWithKoreanLargeText() {
        let app = launch("e4", language: "ko", ax: true)
        XCTAssertTrue(element("activity-E4-example", app).exists)
        let chart = element("chart", app)
        XCTAssertTrue(chart.exists)
        let scroll = app.scrollViews["table-course-scroll"]
        for _ in 0..<5 {
            let dock = app.buttons["table-course-next"]
            if chart.frame.minY + 70 < dock.frame.minY { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(chart.isHittable)
        attach(app, "starting-chart-ko-dark-ax5")
        tap("next", app)
        XCTAssertTrue(element("activity-E4-01", app).exists)
        XCTAssertFalse(element("feedback", app).exists)
        XCTAssertFalse(app.buttons["table-course-submit"].isEnabled)
        tap("choice-1", app)
        tap("submit", app)
        XCTAssertTrue(element("feedback", app).exists)
        attach(app, "starting-feedback-ko-dark-ax5")
        tap("show-chart", app)
        let hand = app.staticTexts["table-course-highlighted-cell"]
        XCTAssertTrue(hand.exists)
        XCTAssertEqual(hand.label, "72o")
        XCTAssertTrue(hand.isHittable)
        let dock = app.buttons["table-course-next"]
        XCTAssertLessThan(hand.frame.maxY, dock.frame.minY, "The revealed cell should be above the footer.")
        attach(app, "starting-revealed-cell-ko-dark-ax5")
    }

    private func launch(_ lesson: String, language: String = "en", ax: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_TABLE_COURSE": lesson, "GT_DEMO_LANGUAGE": language]
        app.launchArguments = ["-appAppearance", language == "ko" ? "dark" : "light",
                               "-UIPreferredContentSizeCategoryName",
                               ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        XCTAssertTrue(app.buttons["table-course-close"].waitForExistence(timeout: 15))
        return app
    }

    private func answer(_ index: Int, _ app: XCUIApplication) {
        tap("choice-\(index)", app)
        tap("submit", app)
        tap("next", app)
    }

    private func tap(_ suffix: String, _ app: XCUIApplication) {
        let target = app.buttons["table-course-\(suffix)"]
        XCTAssertTrue(target.waitForExistence(timeout: 6), suffix)
        if !["submit", "next", "done"].contains(suffix) { reveal(target, in: app) }
        XCTAssertTrue(target.isHittable, suffix)
        target.tap()
    }

    private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews["table-course-scroll"]
        let chrome = app.buttons["table-course-close"]
        let dock = ["submit", "next", "done"].map { app.buttons["table-course-\($0)"] }.first { $0.exists }
        for _ in 0..<10 {
            let frame = target.frame
            let top = chrome.frame.maxY
            let bottom = dock.map { $0.frame.minY - 8 } ?? app.frame.maxY
            if target.isHittable && frame.minY >= top && frame.maxY <= bottom { return }
            if frame.minY < top { scroll.swipeDown() } else { scroll.swipeUp() }
        }
        XCTFail("Control never entered the lesson viewport: \(target.debugDescription)")
    }

    private func element(_ suffix: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "table-course-\(suffix)").firstMatch
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
