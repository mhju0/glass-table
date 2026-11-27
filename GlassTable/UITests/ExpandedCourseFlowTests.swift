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
                selectFullyVisibleChoice(answer, in: app)
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

    func testCapstoneIsRecommendedAndContinuesThroughCoachToIndependentAnalysis() {
        let landing = launch(nil, coreBefore: .capstone)
        let proposed = landing.buttons["learn-table-capstone"]
        XCTAssertTrue(proposed.waitForExistence(timeout: 15))
        XCTAssertTrue(proposed.isHittable)
        XCTAssertTrue(landing.buttons["learn-table-combinations"].exists)
        XCTAssertGreaterThan(landing.buttons["learn-table-turns"].frame.minY, proposed.frame.minY)
        attach(landing, "core-recommendation-en-light")
        proposed.tap()
        XCTAssertTrue(element("activity-I1-example", landing).waitForExistence(timeout: 12))
        landing.terminate()

        let app = launch(.i6, coreBefore: .capstone)
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
        XCTAssertTrue(element("lesson", app).waitForExistence(timeout: 10))
        XCTAssertEqual(element("lesson", app).label, TableCourseLesson.n1.title(in: .english))
        XCTAssertFalse(app.staticTexts["learn-course-complete"].exists)
    }

    func testAllInLessonsOpenFromLessonsAndResumeExactDraftAndReview() throws {
        let app = launch(nil, coreBefore: .allIns)
        let row = app.buttons["learn-table-allIns"]
        XCTAssertTrue(row.waitForExistence(timeout: 12) && row.isHittable)
        row.tap()
        let lessons = TableCourseUnit.allIns
        let questions = lessons.activities(for: .d7)
        tap("next", app)
        let first = questions[1]
        assertActivity(first, in: app)
        tap("choice-0", app)
        tap("close", app)
        app.terminate()
        app.launch()
        XCTAssertTrue(row.waitForExistence(timeout: 12) && row.isHittable)
        row.tap()
        assertActivity(first, in: app)
        XCTAssertTrue(button("choice-0", app).isSelected)
        XCTAssertFalse(element("feedback", app).exists)
        tap("submit", app)
        XCTAssertTrue(element("feedback", app).exists)
        tap("next", app)
        for question in questions.dropFirst(2) { answer(question, in: app) }
        XCTAssertTrue(element("retry", app).exists)
        assertActivity(first, in: app)
        XCTAssertFalse(button("submit", app).isEnabled)
        answer(first, in: app)
        XCTAssertEqual(element("first-score", app).label, "3 of 4 correct")
        XCTAssertEqual(element("retry-score", app).label, "1 of 1 correct")
        tap("next", app)
        finish(.d8, in: app)
        XCTAssertTrue(element("review-upcoming", app).exists)
        XCTAssertFalse(button("spaced-review", app).exists)
        XCTAssertEqual(button("done", app).label, "Try the guided hand")
        tap("done", app)
        XCTAssertTrue(element("activity-D-table-01", app).waitForExistence(timeout: 10))
        tap("close", app)
        openCourseReviewHub(app)
        XCTAssertTrue(app.staticTexts["course-review-spaced-upcoming"].exists)
        XCTAssertFalse(app.buttons["course-review-spaced-mastery"].exists)

        app.terminate()
        app.launchEnvironment["GT_TEST_COURSE_DAY_OFFSET"] = "1"
        app.launch()
        openCourseReviewHub(app)
        let fresh = app.buttons["course-review-spaced-mastery"]
        XCTAssertTrue(fresh.waitForExistence(timeout: 10) && fresh.isHittable)
        fresh.tap()
        XCTAssertEqual(app.staticTexts["course-review-scope"].label, "Review with fresh questions")
        XCTAssertEqual(app.staticTexts["course-review-step"].label, "Question 1 of 2")
        let question = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier MATCHES %@", "course-review-activity-D[78]-spaced-01"
        )).firstMatch
        XCTAssertTrue(question.exists)
        let firstID = question.identifier
        app.buttons["course-review-close"].tap()
        app.terminate()
        app.launch()
        openCourseReviewHub(app)
        app.buttons["course-review-resume"].tap()
        XCTAssertTrue(app.descendants(matching: .any)[firstID].waitForExistence(timeout: 10))

    }

    func testOutOfOrderAllInsDoneOpensChipLessonThroughLearn() {
        let app = launch(.d8, language: .korean)
        // Seed the second all-in lesson only. Use Learn to open the draft without its prerequisite.
        tap("close", app)
        let row = app.buttons["learn-table-allIns"]
        let path = app.scrollViews.firstMatch
        for _ in 0..<12 where !row.isHittable { path.swipeUp() }
        XCTAssertTrue(row.exists && row.isHittable)
        row.tap()
        finish(.d8, in: app)
        tap("done", app)
        XCTAssertTrue(element("activity-D1-example", app).waitForExistence(timeout: 10))
    }

    private func openCourseReviewHub(_ app: XCUIApplication) {
        let row = app.buttons["learn-course-review"]
        let path = app.scrollViews.firstMatch
        for _ in 0..<10 where !row.isHittable { path.swipeUp() }
        XCTAssertTrue(row.exists && row.isHittable)
        row.tap()
        XCTAssertTrue(app.scrollViews["course-review-hub"].waitForExistence(timeout: 10))
    }

    func testIndependentHandKeepsKoreanAX5PriceEvidenceAndChoicesReachable() throws {
        let app = launch(nil, language: .korean, accessible: true, coreBefore: .independentHands)
        let row = app.buttons["learn-table-independentHands"]
        XCTAssertTrue(row.waitForExistence(timeout: 12) && row.isHittable)
        row.tap()
        let lesson = TableCourseUnit.independentHands.activities(for: .n1)
        assertActivity(lesson[0], in: app)
        attach(app, "independent-example-ko-dark-ax5")
        tap("next", app)
        assertActivity(lesson[1], in: app)
        XCTAssertFalse(element("feedback", app).exists)
        let right = try XCTUnwrap(lesson[1].correctChoice)
        tap("choice-\(right)", app)
        XCTAssertEqual(button("choice-\(right)", app).label, "폴드의 EV가 높아요")
        tap("submit", app)
        XCTAssertTrue(element("feedback", app).exists)
        attach(app, "independent-reveal-ko-dark-ax5")
        tap("close", app)
        XCTAssertTrue(row.waitForExistence(timeout: 10) && row.isHittable)
        row.tap()
        assertActivity(lesson[1], in: app)
        XCTAssertTrue(element("feedback", app).exists)
    }

    func testKoreanCapstoneScoresAnUnseenHandAfterUngradedSynthesis() {
        let app = launch(.n3, language: .korean)
        for activity in TableCourseUnit.independentHands.activities(for: .n3) {
            assertActivity(activity, in: app)
            if activity.isExample {
                XCTAssertFalse(button("submit", app).exists)
                tap("next", app)
            } else {
                if activity.id == "N3-v2-05" {
                    XCTAssertEqual(element("activity-N3-v2-05", app).label, "처음 보는 핸드의 턴 판단")
                    XCTAssertFalse(element("feedback", app).exists)
                }
                answer(activity, in: app)
            }
        }
        XCTAssertEqual(element("first-score", app).label, "5개 중 5개 정답")
        XCTAssertFalse(element("retry-score", app).exists)
    }

    func testCoreCompletionStaysEarnedAndStudyContinuesThroughExactAndFreshReview() throws {
        let app = launch(nil, coreBefore: .readHands)
        let core = app.descendants(matching: .any)["learn-course-complete"]
        XCTAssertTrue(core.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["learn-journey-complete"].exists)
        let row = app.buttons["learn-table-readHands"]
        XCTAssertTrue(row.waitForExistence(timeout: 10) && row.isHittable)
        XCTAssertTrue(row.label.contains("Read hands street by street"))
        attach(app, "journey-recommendation-en")
        row.tap()
        let activities = TableCourseUnit.readHands.activities(for: .r1)
        for activity in activities {
            assertActivity(activity, in: app)
            if activity.isExample {
                tap("next", app)
            } else if activity.id == "R1-02" {
                let correct = try XCTUnwrap(activity.correctChoice)
                tap("choice-\((correct + 1) % activity.optionCount)", app)
                tap("submit", app)
                tap("next", app)
            } else {
                answer(activity, in: app)
            }
        }
        let miss = try XCTUnwrap(activities.first { $0.id == "R1-02" })
        XCTAssertTrue(element("retry", app).exists)
        assertActivity(miss, in: app)
        button("close", app).tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(core.waitForExistence(timeout: 10))
        XCTAssertTrue(row.isHittable)
        row.tap()
        XCTAssertTrue(element("retry", app).exists)
        assertActivity(miss, in: app)
        XCTAssertFalse(button("submit", app).isEnabled)
        answer(miss, in: app)
        XCTAssertEqual(element("first-score", app).label, "5 of 6 correct")
        XCTAssertEqual(element("retry-score", app).label, "1 of 1 correct")
        XCTAssertTrue(button("next", app).isHittable)
        tap("weak-review", app)
        XCTAssertTrue(app.staticTexts["course-review-scope"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["course-review-scope"].label, "Review missed topics on new hands")
        XCTAssertEqual(app.staticTexts["course-review-coverage"].label, "Hands practised 0/2")
        XCTAssertEqual(app.staticTexts["course-review-step"].label, "Question 1 of 2")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "course-review-activity-JR-range-"
        )).firstMatch.exists)
        attach(app, "journey-fresh-review-en")
    }

    func testKoreanFreshFinalCaseKeepsCoreCreditAndOpensNewCompletion() {
        let app = launch(.s11, language: .korean, coreBefore: .decideHands)
        let first = element("activity-S11-01", app)
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertFalse(element("activity-S11-example", app).exists)
        finish(.s11, in: app)
        XCTAssertEqual(element("first-score", app).label, "6개 중 6개 정답")
        XCTAssertFalse(element("retry-score", app).exists)
        XCTAssertTrue(button("free-play", app).exists)
        attach(app, "journey-final-result-ko")
        tap("done", app)
        XCTAssertTrue(app.descendants(matching: .any)["learn-journey-complete"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["learn-course-complete"].exists)
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

    private func selectFullyVisibleChoice(_ answer: Int, in app: XCUIApplication) {
        let choice = button("choice-\(answer)", app)
        let submit = button("submit", app)
        let scroll = app.scrollViews["table-course-scroll"]
        XCTAssertTrue(choice.waitForExistence(timeout: 8))
        let top = max(scroll.frame.minY, button("close", app).frame.maxY)
        let bottom = min(scroll.frame.maxY, submit.frame.minY)
        func isFullyVisible() -> Bool {
            let frame = choice.frame
            return frame.minY >= top && frame.maxY <= bottom && choice.isHittable
        }
        for _ in 0..<12 {
            if isFullyVisible() { break }
            if choice.frame.minY < top { scroll.swipeDown() } else { scroll.swipeUp() }
        }
        XCTAssertTrue(isFullyVisible(), "The answer must be clear of the lesson header and footer")
        choice.tap()
        XCTAssertTrue(choice.isSelected, "The answer tap must register before submitting")
        XCTAssertTrue(submit.isEnabled)
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
