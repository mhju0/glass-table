// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableDrills
import XCTest

final class CourseReviewFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEmptyReviewLeadsToTheFirstLesson() {
        let app = launch(sample: "empty", english: false, largeText: true)
        XCTAssertTrue(element("empty", app).exists)
        XCTAssertFalse(button("all", app).exists)
        XCTAssertFalse(button("unit-a", app).exists)
        XCTAssertFalse(button("unit-b", app).exists)
        attach(app, "course-review-empty-ko-dark-ax5")
        tap("start-lesson", app)
        XCTAssertTrue(app.buttons["unit-a-close"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["unit-a-activity-A1-example"].exists)
    }

    func testPartialUnitOffersOnlyStudiedLessonsAndPreservesThePausedLesson() {
        let app = launch(sample: "partial")
        XCTAssertTrue(button("unit-a", app).label.contains("6 skills studied"))
        XCTAssertFalse(button("unit-b", app).exists)
        XCTAssertTrue(button("lesson-a1", app).exists)
        XCTAssertTrue(button("lesson-a2", app).exists)
        XCTAssertFalse(button("lesson-a3", app).exists)
        attach(app, "course-review-partial-en-light")

        tap("unit-a", app)
        XCTAssertEqual(element("scope", app).label, "Unit A review")
        XCTAssertEqual(element("set", app).label, "Set 1 of 2")
        tap("choice-0", app)
        tap("close", app)
        let unit = app.buttons["learn-unit-a"]
        XCTAssertTrue(unit.waitForExistence(timeout: 10))
        bringIntoView(unit, in: app)
        unit.tap()
        XCTAssertTrue(app.buttons["unit-a-close"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["unit-a-activity-A3-example"].exists)
    }

    func testLessonReviewUsesOneScopeAndThreeQuestions() {
        let app = launch(sample: "partial")
        tap("lesson-a1", app)
        XCTAssertEqual(element("scope", app).label, "Your cards and shared cards")
        XCTAssertEqual(element("step", app).label, "Question 1 of 3")
        XCTAssertEqual(element("set", app).label, "Set 1 of 1")
        XCTAssertEqual(element("coverage", app).label, "Answered 0/3")
        attach(app, "course-review-lesson-en-light")
    }

    func testCumulativeReviewRestoresExactMissAndCoversBothSets() throws {
        let app = launch(sample: "all")
        XCTAssertTrue(button("all", app).label.contains("9 skills studied"))
        XCTAssertTrue(button("unit-a", app).label.contains("7 skills studied"))
        XCTAssertTrue(button("unit-b", app).label.contains("2 skills studied"))
        XCTAssertFalse(button("lesson-a4", app).exists)
        XCTAssertFalse(button("lesson-b3", app).exists)
        attach(app, "course-review-all-en-light")
        tap("all", app)
        XCTAssertEqual(element("set", app).label, "Set 1 of 2")
        XCTAssertEqual(element("step", app).label, "Question 1 of 5")
        XCTAssertEqual(element("coverage", app).label, "Skills practised 0/9")
        let firstID = activityID(app)
        let (firstSkill, firstActivity) = try activity(named: firstID)
        let firstCards = evidence(app)
        let displayedCards = firstActivity.learner + firstActivity.board
            + (firstActivity.opponent.isEmpty ? [] : firstActivity.opponent + firstActivity.board)
        XCTAssertEqual(firstCards, displayedCards.map { $0.spoken(in: .english) }.sorted())
        XCTAssertFalse(button("submit", app).isEnabled)
        let correct = try XCTUnwrap(firstActivity.correctChoice)
        let wrong = try XCTUnwrap(firstActivity.choices(in: .english).indices.first { $0 != correct })

        tap("choice-\(wrong)", app)
        XCTAssertEqual(element("coverage", app).label, "Skills practised 0/9")
        reopen(app)
        XCTAssertEqual(activityID(app), firstID)
        XCTAssertEqual(evidence(app), firstCards)
        XCTAssertTrue(button("choice-\(wrong)", app).isSelected)
        XCTAssertTrue(button("submit", app).isEnabled)
        XCTAssertFalse(element("feedback", app).exists)
        XCTAssertEqual(element("coverage", app).label, "Skills practised 0/9")
        attach(app, "course-review-restored-draft-en-light")
        tap("submit", app)
        XCTAssertEqual(element("feedback", app).label, "Not quite")
        XCTAssertEqual(element("coverage", app).label, "Skills practised 1/9")
        let explanation = element("explanation", app).label
        reopen(app)
        XCTAssertEqual(element("explanation", app).label, explanation)
        XCTAssertFalse(button("submit", app).exists)
        XCTAssertEqual(element("coverage", app).label, "Skills practised 1/9")
        tap("next", app)

        var uniqueTopics = Set([firstSkill])
        var firstSetUnits = Set([firstSkill.isUnitA])
        for index in 2...5 {
            XCTAssertEqual(element("step", app).label, "Question \(index) of 5")
            let (skill, question) = try activity(named: activityID(app))
            XCTAssertTrue(uniqueTopics.insert(skill).inserted)
            firstSetUnits.insert(skill.isUnitA)
            try answerCorrectly(question, in: app)
        }
        XCTAssertEqual(firstSetUnits, Set([true, false]))
        XCTAssertEqual(element("step", app).label, "Correction 1 of 1")
        XCTAssertEqual(activityID(app), firstID)
        XCTAssertEqual(evidence(app), firstCards)
        XCTAssertFalse(element("feedback", app).exists)
        XCTAssertEqual(element("coverage", app).label, "Skills practised 5/9")
        attach(app, "course-review-exact-retry-en-light")
        try answerCorrectly(firstActivity, in: app)
        XCTAssertEqual(element("title", app).label, "Set complete")
        XCTAssertEqual(element("coverage", app).label, "Skills practised 5/9")
        XCTAssertEqual(element("first-score", app).label, "4 of 5 correct")
        XCTAssertEqual(element("retry-score", app).label, "1 of 1 correct")
        attach(app, "course-review-set-one-en-light")

        tap("next", app)
        XCTAssertEqual(element("set", app).label, "Set 2 of 2")
        for index in 1...4 {
            XCTAssertEqual(element("step", app).label, "Question \(index) of 4")
            let (skill, question) = try activity(named: activityID(app))
            XCTAssertTrue(uniqueTopics.insert(skill).inserted)
            try answerCorrectly(question, in: app)
        }
        XCTAssertEqual(uniqueTopics.count, 9)
        XCTAssertEqual(element("title", app).label, "Set complete")
        XCTAssertEqual(element("coverage", app).label, "Skills practised 9/9")
        tap("next", app)
        XCTAssertEqual(element("title", app).label, "Review complete")
        XCTAssertEqual(element("coverage", app).label, "9 skills practised")
        XCTAssertEqual(element("first-score", app).label, "8 of 9 correct")
        XCTAssertEqual(element("retry-score", app).label, "1 of 1 correct")
        attach(app, "course-review-complete-en-light")
        tap("done", app)
        XCTAssertTrue(button("all", app).waitForExistence(timeout: 5))
        XCTAssertFalse(button("resume", app).exists)
    }

    private func launch(sample: String, english: Bool = true, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_COURSE_REVIEW": sample, "GT_DEMO_LANGUAGE": english ? "en" : "ko"]
        app.launchArguments = ["-appAppearance", english ? "light" : "dark",
                               "-UIPreferredContentSizeCategoryName",
                               largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        XCTAssertTrue(button("close", app).waitForExistence(timeout: 15))
        return app
    }

    private func reopen(_ app: XCUIApplication) {
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GT_DEMO_COURSE_REVIEW")
        app.launch()
        let row = app.buttons["learn-course-review"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        bringIntoView(row, in: app)
        row.tap()
        tap("resume", app)
    }

    private func answerCorrectly(_ activity: CourseReviewActivity, in app: XCUIApplication) throws {
        let answer = try XCTUnwrap(activity.correctChoice)
        tap("choice-\(answer)", app)
        tap("submit", app)
        let feedback = element("feedback", app)
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertEqual(feedback.label, "Correct")
        tap("next", app)
    }

    private func activity(named identifier: String) throws -> (CourseReviewSkill, CourseReviewActivity) {
        let key = identifier.dropFirst("course-review-activity-review-".count)
        let split = try XCTUnwrap(key.lastIndex(of: "-"))
        let skill = try XCTUnwrap(CourseReviewSkill(rawValue: String(key[..<split])))
        let number = try XCTUnwrap(Int(key[key.index(after: split)...]))
        let activity = try XCTUnwrap(CourseReviewContent.activity(for: skill, variant: number - 1))
        XCTAssertEqual(identifier, "course-review-activity-\(activity.id)")
        return (skill, activity)
    }

    private func activityID(_ app: XCUIApplication) -> String {
        let question = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "course-review-activity-")).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        return question.identifier
    }

    private func evidence(_ app: XCUIApplication) -> [String] {
        element("cards", app).descendants(matching: .any).matching(
            NSPredicate(format: "label MATCHES %@", "(2|3|4|5|6|7|8|9|10|J|Q|K|A) of (clubs|diamonds|hearts|spades)"))
            .allElementsBoundByIndex.map(\.label).sorted()
    }

    private func tap(_ name: String, _ app: XCUIApplication) {
        let target = button(name, app)
        XCTAssertTrue(target.waitForExistence(timeout: 6), name)
        if name.hasPrefix("choice-") {
            let scroller = app.scrollViews["course-review-scroll"]
            let dock = button("submit", app)
            let top = button("close", app).frame.maxY
            let bottom = dock.frame.minY
            for _ in 0..<8 {
                let middle = target.frame.midY
                if target.isHittable && middle > top && middle < bottom {
                    target.tap()
                    return
                }
                if middle < top { scroller.swipeDown() } else { scroller.swipeUp() }
            }
            XCTFail("Choice never entered the review viewport: \(target.debugDescription)")
        } else {
            bringIntoView(target, in: app)
            target.tap()
        }
    }

    private func bringIntoView(_ target: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !target.isHittable { app.swipeUp() }
        XCTAssertTrue(target.isHittable, target.debugDescription)
    }

    private func button(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons["course-review-\(name)"]
    }

    private func element(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "course-review-\(name)").firstMatch
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
