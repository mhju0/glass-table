// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// Learn is the lesson list (owner, 2026-10-17, variant A2): one marked row, no
/// suggestion card, "All lessons" or "Practice one skill" entries, and a passed
/// lesson's "연습" opens that skill's five-question round.
final class LearnListTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testKONewLearnerIsMarkedOnHoldemBasics() { newLearner("ko") }
    func testENNewLearnerIsMarkedOnHoldemBasics() { newLearner("en") }
    func testKOSeededListMarksNextAndPracticesAPassedLesson() { seeded("ko", ax: false) }
    func testENSeededListMarksNextAndPracticesAPassedLesson() { seeded("en", ax: false) }
    func testKOAXSeededListMarksNextAndPracticesAPassedLesson() { seeded("ko", ax: true) }
    func testKOLessonLeftPartWayIsMarkedInProgress() { inProgress("ko") }
    func testENLessonLeftPartWayIsMarkedInProgress() { inProgress("en") }
    func testKOLessonPlayedOutOfOrderKeepsTheMark() { outOfOrder("ko") }
    func testENLessonPlayedOutOfOrderKeepsTheMark() { outOfOrder("en") }
    func testKOEveryLessonPassedLeadsToPractice() { allPassed("ko") }
    func testENEveryLessonPassedLeadsToPractice() { allPassed("en") }

    private func newLearner(_ language: String) {
        let ko = language == "ko"
        let app = launch(language, ax: false, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                               "GT_TEST_FIRST_PLACEMENT": "0"])
        let start = app.buttons["learn-basics-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        XCTAssertTrue(start.isHittable)
        XCTAssertEqual(start.label, ko ? "시작, 홀덤 기초" : "Start, Hold'em basics")
        let row = app.buttons["path-basics"]
        XCTAssertTrue(row.label.contains(ko ? "여기서 시작" : "Start here"), row.label)
        // Hold'em basics leads the list while it is the marked row.
        XCTAssertLessThan(row.frame.maxY, app.buttons["lesson-u1-showdown"].frame.minY)
        assertOneMark(app)
        assertNoRemovedEntries(app, ko: ko)
        attach(app, "\(language)-large-learn-new")
    }

    private func seeded(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = launch(language, ax: ax, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_SEED": "1", "GT_DEMO_TAB": "learn"])
        let review = app.buttons["learn-review"]
        XCTAssertTrue(review.waitForExistence(timeout: 15))
        if !ax {
            // The marked row is on the first screen, so the list does not scroll past the reviews.
            XCTAssertTrue(review.isHittable)
        }
        // The due count follows the clock, so only the wording is pinned.
        let pattern = ko ? #"^복습 \d+개가 준비됐어요, 시작$"# : #"^\d+ reviews are ready, Start$"#
        XCTAssertNotNil(review.label.range(of: pattern, options: .regularExpression), review.label)
        assertOneMark(app)
        let next = app.buttons["lesson-u3-rfi"]
        XCTAssertTrue(next.label.contains(ko ? "다음" : "Next"), next.label)
        let start = app.buttons["learn-start"]
        reach(start, app: app)
        XCTAssertTrue(start.label.hasPrefix(ko ? "시작, " : "Start, "), start.label)
        XCTAssertGreaterThanOrEqual(start.frame.minY, next.frame.minY, "The filled action belongs to the marked row")
        // D47 stays on a lesson tried but not passed.
        XCTAssertTrue(app.buttons["lesson-u2-equitySense"].label.contains(ko ? "통과 전 · 최고 1/3" : "Not passed · best 1/3"))
        assertNoRemovedEntries(app, ko: ko)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-learn-seeded")

        let practice = app.buttons["practice-position"]
        for _ in 0..<12 where !practice.isHittable { app.swipeDown() }
        XCTAssertTrue(practice.isHittable)
        XCTAssertTrue(practice.label.hasPrefix(ko ? "연습, " : "Practice, "), practice.label)
        practice.tap()
        XCTAssertTrue(app.staticTexts["1/5"].waitForExistence(timeout: 10), "Straight into a five-question round")
        XCTAssertFalse(app.buttons["skill-position"].exists, "Not the skill picker")
        attach(app, "\(language)-\(ax ? "AX5" : "large")-learn-practice-round")
        app.buttons[ko ? "드릴 바꾸기" : "Change skill"].tap()
        app.buttons[ko ? "닫기" : "Close"].firstMatch.tap()
        XCTAssertTrue(practice.waitForExistence(timeout: 10))
        for _ in 0..<12 where !practice.isHittable { app.swipeDown() }
        XCTAssertTrue(practice.label.hasPrefix(ko ? "연습 이어서, " : "Continue practice, "), practice.label)
    }

    private func inProgress(_ language: String) {
        let ko = language == "ko"
        let store = UUID().uuidString
        let app = launch(language, ax: false, ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0",
                                               "GT_DEMO_NODE": "u1-showdown", "GT_DEMO_BEAT": "0"])
        XCTAssertTrue(app.descendants(matching: .any)["walkthrough-step-0"].waitForExistence(timeout: 15))
        app.buttons.matching(NSPredicate(format: "label == %@", ko ? "다음" : "Next")).firstMatch.tap()
        let step1 = app.descendants(matching: .any)["walkthrough-step-1"]
        XCTAssertTrue(step1.waitForExistence(timeout: 5))
        // Relaunch without the demo hook, which would reopen the lesson on every appear.
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        XCTAssertTrue(resume.waitForExistence(timeout: 15))
        XCTAssertTrue(resume.isHittable)
        XCTAssertTrue(resume.label.hasPrefix(ko ? "이어서, " : "Continue, "), resume.label)
        let row = app.buttons["lesson-u1-showdown"]
        XCTAssertTrue(row.label.contains(ko ? "진행 중" : "In progress"), row.label)
        XCTAssertFalse(app.buttons["learn-basics-start"].exists, "The open lesson outranks the basics suggestion")
        assertOneMark(app)
        XCTAssertNil(row.label.range(of: #"\d+/\d+"#, options: .regularExpression), "No question count on a row")
        attach(app, "\(language)-large-learn-in-progress")
        resume.tap()
        XCTAssertTrue(step1.waitForExistence(timeout: 10), "Continue reopens the saved lesson where it was left")
    }

    /// D52: a new learner who goes straight to a late lesson and finishes it is followed
    /// there, not sent back to Hold'em basics or the first lesson. Not passed, that
    /// lesson stays marked; passed, the next lesson after it is.
    private func outOfOrder(_ language: String) {
        let ko = language == "ko"
        let store = UUID().uuidString
        let app = launch(language, ax: false, ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0",
                                               "GT_TEST_FIRST_PLACEMENT": "0", "GT_DEMO_NODE": "u2-potOdds"])
        for number in 1...3 {
            XCTAssertTrue(app.staticTexts["\(number)/3"].waitForExistence(timeout: 15))
            XCTAssertTrue(app.firstLessonChoice.waitForExistence(timeout: 5))
            app.firstLessonChoice.tap()
            let next = app.buttons[ko ? "다음 문제" : "Next question"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            next.tap()
        }
        let done = app.buttons["summary-done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        let passed = app.staticTexts[ko ? "레슨 통과" : "Lesson passed"].exists
        done.tap()
        // Relaunch without the demo hook, which would reopen the lesson on every appear.
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        let start = app.buttons["learn-start"]
        reach(start, app: app)
        let marked = app.buttons[passed ? "lesson-u2-callFold" : "lesson-u2-potOdds"]
        XCTAssertTrue(marked.label.contains(ko ? "다음" : "Next"), "passed: \(passed), \(marked.label)")
        XCTAssertGreaterThanOrEqual(start.frame.minY, marked.frame.minY, "The filled action belongs to the marked row")
        XCTAssertLessThanOrEqual(start.frame.minY, marked.frame.maxY, "The filled action belongs to the marked row")
        XCTAssertFalse(app.buttons["learn-basics-start"].exists, "Not sent back to Hold'em basics")
        assertOneMark(app)
        attach(app, "\(language)-large-learn-out-of-order-\(passed ? "passed" : "not-passed")")
    }

    /// D38: with nothing left to mark, the list still leads somewhere.
    private func allPassed(_ language: String) {
        let ko = language == "ko"
        // Every node before u9-mdf passed: all track lessons, the optional track included.
        let app = launch(language, ax: false, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                               "GT_TEST_PATH_CURRENT_NODE": "u9-mdf"])
        let done = app.buttons["learn-all-done"]
        XCTAssertTrue(done.waitForExistence(timeout: 15))
        XCTAssertTrue(done.isHittable)
        XCTAssertTrue(done.label.hasPrefix(ko ? "모든 레슨을 마쳤어요" : "You've passed every lesson"), done.label)
        XCTAssertTrue(["learn-continue", "learn-start", "learn-basics-start"].allSatisfy { !app.buttons[$0].exists },
                      "Nothing is marked")
        attach(app, "\(language)-large-learn-all-done")
        done.tap()
        XCTAssertTrue(app.buttons["skill-showdown"].waitForExistence(timeout: 10), "Opens the practice skill picker")
    }

    // MARK: Helpers

    private func launch(_ language: String, ax: Bool, _ environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", language == "ko" ? "korean" : "english"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    /// Exactly one filled action on the list.
    private func assertOneMark(_ app: XCUIApplication) {
        let marks = ["learn-continue", "learn-start", "learn-basics-start"].filter { app.buttons[$0].exists }
        XCTAssertEqual(marks.count, 1, "\(marks)")
    }

    private func assertNoRemovedEntries(_ app: XCUIApplication, ko: Bool) {
        XCTAssertFalse(app.buttons["learn-path"].exists)
        for text in ko ? ["한 가지 집중 연습", "전체 레슨", "다음 추천"] : ["Practice one skill", "All lessons", "Suggested next"] {
            XCTAssertFalse(app.staticTexts[text].exists, text)
        }
    }

    private func reach(_ element: XCUIElement, app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable, "Unreachable \(element.identifier): \(element.frame)")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
