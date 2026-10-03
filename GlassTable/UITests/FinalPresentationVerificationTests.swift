// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class FinalPresentationVerificationTests: XCTestCase {
    private lazy var pixelTolerance = 1 / XCUIScreen.main.screenshot().image.scale

    override func setUpWithError() throws { continueAfterFailure = false }

    func testRangeReadKOLargeBottomAndComparisonReachable() { rangeRead(code: "ko", ax: false) }
    func testRangeReadENLargeBottomAndComparisonReachable() { rangeRead(code: "en", ax: false) }
    func testRangeReadKOAXBottomAndComparisonReachable() { rangeRead(code: "ko", ax: true) }
    func testRangeReadENAXBottomAndComparisonReachable() { rangeRead(code: "en", ax: true) }

    func testSuggestedBasicsCTAOpensCourseInBothLanguagesAtAX5() {
        for code in ["ko", "en"] {
            let app = application(code: code, ax: true)
            app.launchEnvironment["GT_TEST_FIRST_LESSON"] = "1"
            app.launch()
            let skip = app.buttons[code == "ko" ? "안내 건너뛰기" : "Skip guide"]
            XCTAssertTrue(skip.waitForExistence(timeout: 15))
            skip.tap()
            let start = app.buttons["learn-basics-start"]
            XCTAssertTrue(start.waitForExistence(timeout: 10))
            reveal(start, app: app, ax: true, tabs: true)
            capture("basics-start-AX5-\(code)")
            start.tap()
            XCTAssertTrue(app.descendants(matching: .any)["basics.rank.royal"].waitForExistence(timeout: 10))
            capture("basics-course-opened-AX5-\(code)")
            app.terminate()
        }
    }

    private func application(code: String, ax: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0"]
        return app
    }

    private func rangeRead(code: String, ax: Bool) {
        let app = application(code: code, ax: ax)
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u4-rangeRead"
        app.launch()
        // Below "Plays sometimes" the chart follows a first answer in words.
        let start = app.buttons["range-start-medium"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        XCTAssertFalse(app.otherElements.matching(NSPredicate(
            format: "label BEGINSWITH %@", code == "ko" ? "2 행." : "Row 2.")).firstMatch.exists)
        start.tap()
        let prefix = code == "ko" ? "2 행." : "Row 2."
        let rows = app.otherElements.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(rows.count, 1, "One learner grid, not a hidden duplicate")
        let learner = rows.firstMatch
        XCTAssertFalse(learner.label.contains(code == "ko" ? "정답과 내 답" : "the answer and my choice"))
        reveal(learner, app: app, ax: ax)
        capture("range-learner-bottom-\(code)-\(ax)")
        let submit = app.buttons[code == "ko" ? "확인" : "Check answer"]
        reveal(submit, app: app, ax: ax, content: false)
        submit.tap()
        let difference = app.staticTexts["range-difference-list"]
        XCTAssertTrue(difference.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1, "The learner grid is replaced by one comparison grid")
        let comparedRows = app.otherElements.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
        let comparison = comparedRows.firstMatch
        let summary = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", code == "ko" ? "레인지 비교 표." : "Range comparison.")).firstMatch
        XCTAssertTrue(summary.exists, "The one visible grid has comparison semantics after grading")
        reveal(comparison, app: app, ax: ax)
        capture("range-comparison-bottom-\(code)-\(ax)")
        for title in code == "ko" ? ["맞음", "놓침", "넘침"] : ["Both", "Missed", "Extra"] {
            let key = app.staticTexts.matching(NSPredicate(format: "label == %@", title)).firstMatch
            XCTAssertTrue(key.exists, title)
            reveal(key, app: app, ax: ax)
            capture("range-legend-\(title)-\(code)-\(ax)")
        }
        let details = app.staticTexts.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "range-difference-list", code == "ko" ? "종류" : "kinds"))
        XCTAssertGreaterThan(details.count, 0)
        for i in 0..<details.count {
            reveal(details.element(boundBy: i), app: app, ax: ax)
            capture("range-difference-\(i)-\(code)-\(ax)")
        }
        let next = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch
        reveal(next, app: app, ax: ax, content: false)
        capture("range-next-\(code)-\(ax)")
        next.tap()
        XCTAssertTrue(app.staticTexts["2/3"].waitForExistence(timeout: 10))
        app.terminate()
    }

    private func reveal(_ element: XCUIElement, app: XCUIApplication, ax: Bool,
                        tabs: Bool = false, content: Bool = true) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        for _ in 0..<30 {
            let scroll = app.scrollViews.firstMatch
            var top = max(app.frame.minY + 60, scroll.frame.minY)
            if app.navigationBars.firstMatch.exists { top = max(top, app.navigationBars.firstMatch.frame.maxY) }
            var bottom = min(app.frame.maxY - 20, scroll.frame.maxY)
            if tabs { bottom = min(bottom, app.tabBars.firstMatch.frame.minY) }
            if !ax && !tabs && content {
                let sheet = app.otherElements.matching(NSPredicate(format: "identifier == 'answer-sheet' OR identifier BEGINSWITH 'graded-sheet-' ")).firstMatch
                if sheet.exists { bottom = min(bottom, sheet.frame.minY) }
            }
            if !content && !ax { top = app.frame.minY + 60; bottom = app.frame.maxY - 20 }
            let frame = element.frame
            if frame.minY >= top - pixelTolerance, frame.maxY <= bottom + pixelTolerance, element.isHittable {
                print("Final reach \(element.identifier) \(element.label.prefix(35)): frame=\(frame), visible=\(top)...\(bottom), pixelTolerance=\(pixelTolerance)")
                return
            }
            let delta = min(100, max(-100, frame.midY - (top + bottom) / 2))
            let startY = min(app.frame.maxY - 80, max(top + 30, (top + bottom) / 2))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 25, dy: startY))
            let end = start.withOffset(CGVector(dx: 0, dy: -delta))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        capture("failed-reach")
        XCTFail("Full bounds unavailable: \(element.label), frame=\(element.frame), scroll=\(app.scrollViews.firstMatch.frame)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
