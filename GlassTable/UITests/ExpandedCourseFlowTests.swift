// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableDrills
import XCTest

final class ExpandedCourseFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPossibleHandsOffersBothReviewsAndContinuesToRiverCards() {
        let app = launch(.f6)
        attach(app, "hands-policy-en-light")
        finish(.f6, in: app)
        XCTAssertTrue(button("review-unit", app).exists)
        XCTAssertTrue(button("review", app).exists)
        attach(app, "hands-review-en-light")
        tap("done", app)
        XCTAssertTrue(element("lesson", app).waitForExistence(timeout: 12))
        XCTAssertEqual(element("lesson", app).label, TableCourseLesson.g1.title(in: .english))
        attach(app, "winning-river-en-light")
    }

    func testRangeEquityReachesAnswerAndEvidenceBelowTheFold() throws {
        let app = launch(.g6, appearance: "dark")
        tap("next", app)
        let question = try XCTUnwrap(TableCourseUnit.winningCards.activities(for: .g6).first { !$0.isExample })
        assertActivity(question, in: app)
        let answer = try XCTUnwrap(question.correctChoice)
        tap("choice-\(answer)", app)
        attach(app, "winning-range-question-en-dark")
        tap("submit", app)
        XCTAssertTrue(element("feedback", app).exists)
        attach(app, "winning-range-feedback-en-dark")
    }

    func testBreakEvenIsAnExplicitAnswerAtTheThreshold() {
        let app = launch(.h7, language: .korean, accessible: true)
        let content = TableCourseUnit.priceChance.activities(for: .h7)
        for activity in content {
            assertActivity(activity, in: app)
            if let answer = activity.correctChoice {
                tap("choice-\(answer)", app)
                tap("submit", app)
                XCTAssertTrue(element("feedback", app).exists)
                if activity.choices(in: .english)[answer] == "Break even" {
                    attach(app, "price-break-even-ko-dark-ax5")
                    let heading = app.staticTexts["table-course-feedback-title"]
                    XCTAssertTrue(heading.exists)
                    XCTAssertGreaterThanOrEqual(heading.frame.minY, button("close", app).frame.maxY)
                    XCTAssertLessThan(heading.frame.maxY, button("next", app).frame.minY)
                }
            } else {
                attach(app, "price-example-ko-dark-ax5")
            }
            tap("next", app)
        }
        XCTAssertTrue(element("results", app).exists)
        XCTAssertFalse(element("retry-score", app).exists)
    }

    func testCapstoneIsRecommendedAndCanReturnThroughCoachToFreePlay() {
        let app = launch(nil, coreBefore: .capstone)
        let proposed = app.buttons["learn-table-capstone"]
        XCTAssertTrue(proposed.waitForExistence(timeout: 15))
        XCTAssertTrue(proposed.isHittable)
        XCTAssertTrue(app.buttons["learn-table-combinations"].exists)
        XCTAssertGreaterThan(app.buttons["learn-table-turns"].frame.minY, proposed.frame.minY)
        attach(app, "core-recommendation-en-light")

        app.terminate()
        app.launchEnvironment["GT_DEMO_TABLE_COURSE"] = "i6"
        app.launch()
        XCTAssertTrue(button("close", app).waitForExistence(timeout: 15))
        attach(app, "capstone-intro-en-light")
        finish(.i6, in: app, capture: ["I6-04": "capstone-river-en-light",
                                       "I6-05": "capstone-showdown-en-light"])
        XCTAssertTrue(button("review", app).exists)
        attach(app, "capstone-complete-en-light")
        tap("coach", app)
        let close = app.buttons["coach-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["coach-example"].exists)
        XCTAssertTrue(app.staticTexts["Pot 3 · 2 to call"].exists)
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Break-even equity")).firstMatch.exists)
        attach(app, "capstone-coach-en-light")
        close.tap()
        XCTAssertTrue(element("results", app).waitForExistence(timeout: 10))
        tap("done", app)
        XCTAssertTrue(app.buttons["play-quick"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.staticTexts["learn-course-complete"].exists
                      || app.descendants(matching: .any)["learn-course-complete"].exists)
    }

    func testOptionalWeightedCombosResumesDraftAndRetriesTheSameItem() throws {
        let app = launch(.j4, language: .korean, accessible: true)
        attach(app, "combos-weights-ko-dark-ax5")
        tap("next", app)
        let content = TableCourseUnit.combinations.activities(for: .j4).filter { !$0.isExample }
        let first = try XCTUnwrap(content.first)
        let right = try XCTUnwrap(first.correctChoice)
        let wrong = (right + 1) % first.optionCount
        tap("choice-\(wrong)", app)
        app.terminate()
        app.launch()
        assertActivity(first, in: app)
        XCTAssertTrue(button("submit", app).isEnabled)
        tap("submit", app)
        attach(app, "combos-feedback-ko-dark-ax5")
        tap("next", app)
        for activity in content.dropFirst() { answer(activity, in: app) }
        XCTAssertTrue(element("retry", app).exists)
        assertActivity(first, in: app)
        answer(first, in: app)
        XCTAssertTrue(element("results", app).exists)
        XCTAssertTrue(element("retry-score", app).exists)
    }

    private func launch(_ lesson: TableCourseLesson?, language: LearningLanguage = .english,
                        accessible: Bool = false, coreBefore: TableCourseUnit? = nil, appearance: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_TEST_FIRST_PLACEMENT": "0", "GT_DEMO_LANGUAGE": language.rawValue]
        if let lesson { app.launchEnvironment["GT_DEMO_TABLE_COURSE"] = lesson.rawValue }
        if let coreBefore { app.launchEnvironment["GT_DEMO_CORE_PATH"] = coreBefore.rawValue }
        app.launchArguments = ["-appAppearance", appearance ?? (language == .english ? "light" : "dark"),
                               "-UIPreferredContentSizeCategoryName",
                               accessible ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        if lesson != nil { XCTAssertTrue(button("close", app).waitForExistence(timeout: 15)) }
        return app
    }

    private func finish(_ lesson: TableCourseLesson, in app: XCUIApplication, capture: [String: String] = [:]) {
        for activity in lesson.unit.activities(for: lesson) {
            assertActivity(activity, in: app)
            if let name = capture[activity.id] { attach(app, name) }
            if activity.isExample { tap("next", app) } else { answer(activity, in: app) }
        }
        XCTAssertTrue(element("results", app).exists)
        tap("next", app)
        XCTAssertTrue(button("done", app).exists)
    }

    private func answer(_ activity: TableCourseActivity, in app: XCUIApplication) {
        assertActivity(activity, in: app)
        guard let answer = activity.correctChoice else { return XCTFail(activity.id) }
        tap("choice-\(answer)", app)
        tap("submit", app)
        XCTAssertTrue(element("feedback", app).exists)
        tap("next", app)
    }

    private func assertActivity(_ activity: TableCourseActivity, in app: XCUIApplication) {
        let target = element("activity-\(activity.id)", app)
        XCTAssertTrue(target.exists || target.waitForExistence(timeout: 10), activity.id)
    }

    private func tap(_ suffix: String, _ app: XCUIApplication) {
        let target = button(suffix, app)
        XCTAssertTrue(target.exists || target.waitForExistence(timeout: 8), suffix)
        if !["next", "submit", "done"].contains(suffix) {
            let scroll = app.scrollViews["table-course-scroll"]
            let top = button("close", app).frame.maxY
            let dock = ["submit", "next", "done"].map { button($0, app) }.first { $0.exists }
            let bottom = dock?.frame.minY ?? scroll.frame.maxY
            for _ in 0..<12 {
                let middle = target.frame.midY
                if target.isHittable && middle > top && middle < bottom { break }
                if middle < top { scroll.swipeDown() } else { scroll.swipeUp() }
            }
        }
        XCTAssertTrue(target.isHittable, suffix)
        target.tap()
    }

    private func button(_ suffix: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons["table-course-\(suffix)"]
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
