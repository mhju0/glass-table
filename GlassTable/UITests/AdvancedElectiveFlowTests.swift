// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableDrills
import XCTest

final class AdvancedElectiveFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testBothElectivesOpenFromLearn() {
        let app = launch(nil, language: .english)
        for (unit, firstLesson) in [(TableCourseUnit.expectedValue, TableCourseLesson.k1), (.boardPatterns, .l1)] {
            let entry = app.buttons["learn-table-\(unit.rawValue)"]
            XCTAssertTrue(entry.exists)
            for _ in 0..<18 where !entry.isHittable { app.swipeUp() }
            XCTAssertTrue(entry.isHittable, unit.rawValue)
            entry.tap()
            XCTAssertTrue(button("close", app).waitForExistence(timeout: 12))
            XCTAssertEqual(element("lesson", in: app).label, firstLesson.title(in: .english))
            button("close", app).tap()
            XCTAssertTrue(entry.waitForExistence(timeout: 10))
        }
    }

    func testDefenseFrequencyResumesAndRepeatsTheExactMiss() throws {
        let app = launch(.k5, language: .english)
        attach(app, "defense-model-en-light")
        let content = TableCourseUnit.expectedValue.activities(for: .k5)
        for _ in content.prefix(while: \.isExample) { tap("next", app) }
        let questions = content.filter { !$0.isExample }
        let first = try XCTUnwrap(questions.first)
        let right = try XCTUnwrap(first.correctChoice)
        tap("choice-\((right + 1) % first.optionCount)", app)
        app.terminate()
        app.launch()
        XCTAssertTrue(activity(first, in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(button("submit", app).isEnabled)
        tap("submit", app)
        attach(app, "defense-feedback-en-light")
        tap("next", app)
        for item in questions.dropFirst() {
            XCTAssertTrue(activity(item, in: app).exists)
            try answer(item, in: app)
            tap("next", app)
        }
        XCTAssertTrue(element("retry", in: app).exists)
        XCTAssertTrue(activity(first, in: app).exists)
        attach(app, "defense-retry-en-light")
        try answer(first, in: app)
        tap("next", app)
        XCTAssertTrue(element("results", in: app).exists)
        XCTAssertTrue(element("retry-score", in: app).exists)
    }

    func testWorkedBoardDistributionsAreReachableInEnglish() {
        let app = launch(.l3, language: .english)
        let plots = app.descendants(matching: .any).matching(identifier: "table-course-distribution")
        XCTAssertEqual(plots.count, 2)
        let firstPlot = plots.element(boundBy: 0)
        let lastPlot = plots.element(boundBy: 1)
        let viewportTop = button("close", app).frame.maxY
        let viewportBottom = button("next", app).frame.minY
        let viewport = scroll(in: app)
        let dragStart = viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        let dragEnd = viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        for _ in 0..<10 where lastPlot.frame.maxY > viewportBottom {
            dragStart.press(forDuration: 0.05, thenDragTo: dragEnd, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTAssertGreaterThan(firstPlot.frame.minY, viewportTop)
        XCTAssertLessThan(lastPlot.frame.maxY, viewportBottom)
        attach(app, "range-board-worked-en-light")
    }

    func testBoardComparisonRevealsTwoDistributionsAtKoreanAX5() throws {
        let app = launch(.l3, language: .korean, accessibilitySize: true)
        let content = TableCourseUnit.boardPatterns.activities(for: .l3)
        let worked = try XCTUnwrap(content.first)
        XCTAssertTrue(worked.isExample)
        XCTAssertTrue(activity(worked, in: app).exists)
        let plots = app.descendants(matching: .any).matching(identifier: "table-course-distribution")
        XCTAssertEqual(plots.count, 2)
        for _ in 0..<8 {
            let chart = plots.firstMatch
            if chart.frame.minY > button("close", app).frame.maxY,
               chart.frame.minY + 90 < button("next", app).frame.minY { break }
            scroll(in: app).swipeUp()
        }
        attach(app, "range-board-worked-ko-dark-ax5")
        tap("next", app)

        let question = try XCTUnwrap(content.first { !$0.isExample })
        XCTAssertTrue(activity(question, in: app).exists)
        XCTAssertTrue(app.staticTexts["보드 A"].exists)
        XCTAssertTrue(app.staticTexts["보드 B"].exists)
        XCTAssertFalse(element("feedback", in: app).exists)
        XCTAssertEqual(plots.count, question.evidence.distributions.count)
        try answer(question, in: app)
        XCTAssertTrue(app.staticTexts["table-course-feedback-title"].exists)
        let revealedPlots = try XCTUnwrap(question.revealedEvidence).distributions
        XCTAssertEqual(revealedPlots.count, 2)
        XCTAssertEqual(plots.count, revealedPlots.count)
        attach(app, "range-board-feedback-ko-dark-ax5")
    }

    private func launch(_ lesson: TableCourseLesson?, language: LearningLanguage,
                        accessibilitySize: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
            "GT_TEST_FIRST_PLACEMENT": "0", "GT_DEMO_LANGUAGE": language.rawValue,
        ]
        if let lesson { app.launchEnvironment["GT_DEMO_TABLE_COURSE"] = lesson.rawValue }
        app.launchArguments = [
            "-appAppearance", language == .korean ? "dark" : "light",
            "-UIPreferredContentSizeCategoryName",
            accessibilitySize ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL",
        ]
        app.launch()
        if lesson != nil { XCTAssertTrue(button("close", app).waitForExistence(timeout: 15)) }
        return app
    }

    private func answer(_ activity: TableCourseActivity, in app: XCUIApplication) throws {
        tap("choice-\(try XCTUnwrap(activity.correctChoice))", app)
        tap("submit", app)
        XCTAssertTrue(element("feedback", in: app).exists)
    }

    private func tap(_ suffix: String, _ app: XCUIApplication) {
        let target = button(suffix, app)
        XCTAssertTrue(target.exists || target.waitForExistence(timeout: 8), suffix)
        if suffix.hasPrefix("choice") {
            let viewportTop = button("close", app).frame.maxY
            let viewportBottom = button("submit", app).frame.minY
            for _ in 0..<12 {
                let y = target.frame.midY
                if target.isHittable && y > viewportTop && y < viewportBottom { break }
                if y < viewportTop { scroll(in: app).swipeDown() } else { scroll(in: app).swipeUp() }
            }
        }
        XCTAssertTrue(target.isHittable, suffix)
        target.tap()
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement { app.scrollViews["table-course-scroll"] }

    private func button(_ suffix: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons["table-course-\(suffix)"]
    }

    private func element(_ suffix: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "table-course-\(suffix)").firstMatch
    }

    private func activity(_ activity: TableCourseActivity, in app: XCUIApplication) -> XCUIElement {
        element("activity-\(activity.id)", in: app)
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
