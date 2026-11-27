import XCTest

final class FreePlayQuestFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishPlaySetupAndFoldCountTowardSession() {
        let app = launch("en", reduced: true, opensFixture: false)
        wait(app.buttons["play-long"])
        app.buttons["play-long"].tap()
        wait(app.buttons["player-count-2"])
        app.buttons["player-count-2"].tap()
        wait(app.buttons["table-start"])
        app.buttons["table-start"].tap()
        let helpClose = app.buttons["free-table-back-close"]
        if helpClose.waitForExistence(timeout: 2) { helpClose.tap() }
        join(app)
        let fold = app.buttons["free-fold"]
        wait(fold)
        fold.tap()
        let next = app.buttons["free-next-hand"]
        wait(next)
        count(app, "1 hand played")
        XCTAssertEqual(app.buttons["free-quest"].label, "Quest 0/2")
        capture(app, "en-normal-setup-fold")
        next.tap()
        XCTAssertTrue(app.staticTexts["free-table-title"].label.contains("Hand 2"))
    }

    func testEnglishMotionSkipReviewAndImmediateNextHand() {
        let app = launch("en", reduced: false)
        join(app)
        let firstControl = playable(app)
        let position = firstControl.frame
        firstControl.tap()
        let nextControl = playable(app)
        XCTAssertEqual(nextControl.frame.midX, position.midX, accuracy: 1)
        XCTAssertEqual(nextControl.frame.maxY, position.maxY, accuracy: 1)
        settle(app)
        count(app, "1 hand played")
        let quest = app.buttons["free-quest"]
        XCTAssertEqual(quest.label, "Answer quest")
        quest.tap()
        let skip = app.buttons["free-quest-skip"]
        wait(skip)
        capture(app, "en-quest-before-answer")
        skip.tap()
        XCTAssertTrue(app.staticTexts["You skipped this hand."].exists)
        app.buttons["free-progress-close"].tap()
        let review = app.buttons["free-review"]
        wait(review)
        review.tap()
        let next = app.buttons["free-review-next-hand"]
        wait(next)
        capture(app, "en-recap-with-next-hand")
        next.tap()
        XCTAssertTrue(app.staticTexts["free-table-title"].label.contains("Hand 2"))
        count(app, "1 hand played")
    }

    func testKoreanReduceMotionAnswerRepeatTapAndReopen() {
        let app = launch("ko", reduced: true)
        join(app)
        settle(app)
        count(app, "마친 핸드 1개")
        let quest = app.buttons["free-quest"]
        XCTAssertEqual(quest.label, "퀘스트 답하기")
        quest.tap()
        let choice = app.buttons["free-quest-choice-0"]
        wait(choice)
        capture(app, "ko-reduced-quest-before-answer")
        choice.doubleTap()
        wait(app.staticTexts["free-quest-feedback"])
        let progress = app.staticTexts["free-quest-progress"].label
        XCTAssertEqual(progress, "맞힌 횟수 1/2")
        XCTAssertFalse(choice.exists)
        app.buttons["free-progress-close"].tap()
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GT_DEMO_PRACTICE")
        app.launch()
        let resume = app.buttons["play-continue"]
        wait(resume)
        resume.tap()
        let guideClose = app.buttons["free-table-back-close"]
        if guideClose.waitForExistence(timeout: 2) { guideClose.tap() }
        count(app, "마친 핸드 1개")
        app.buttons["free-quest"].tap()
        XCTAssertEqual(app.staticTexts["free-quest-progress"].label, progress)
        XCTAssertTrue(app.staticTexts["free-quest-feedback"].exists)
        app.buttons["free-progress-close"].tap()
        let next = app.buttons["free-next-hand"]
        wait(next)
        capture(app, "ko-reduced-restored-result")
        next.doubleTap()
        XCTAssertTrue(app.staticTexts["free-table-title"].label.contains("2번째 핸드"))
        // Seed 97's small blind folds on hand two without a learner action.
        count(app, "마친 핸드 2개")
        XCTAssertEqual(app.buttons["free-quest"].label, "퀘스트 1/2")
        capture(app, "ko-reduced-next-bot-fold")
    }

    private func launch(_ language: String, reduced: Bool, opensFixture: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))",
                               "-AppleLocale", language == "ko" ? "ko_KR" : "en_US"]
        app.launchEnvironment = [
            "GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
            "GT_DEMO_LANGUAGE": language, "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
            "GT_DEMO_PLAYERS": "2", "GT_DEMO_REDUCE_MOTION": reduced ? "1" : "0"
        ]
        if !opensFixture { app.launchEnvironment.removeValue(forKey: "GT_DEMO_PRACTICE") }
        app.launch()
        return app
    }

    private func join(_ app: XCUIApplication) {
        let quest = app.buttons["free-quest"]
        wait(quest)
        quest.tap()
        let join = app.buttons["free-quest-join"]
        wait(join)
        join.tap()
        wait(app.staticTexts["free-quest-progress"])
        app.buttons["free-progress-close"].tap()
    }

    private func playable(_ app: XCUIApplication) -> XCUIElement {
        let enabled = NSPredicate(format: "identifier IN %@ AND enabled == true", ["free-check", "free-call"])
        let action = app.buttons.matching(enabled).firstMatch
        wait(action)
        return action
    }

    private func settle(_ app: XCUIApplication) {
        let result = app.buttons["free-next-hand"]
        let action = app.buttons.matching(NSPredicate(format: "identifier IN %@ AND enabled == true",
                                                      ["free-check", "free-call"])).firstMatch
        for _ in 0..<12 {
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                result.exists || action.exists
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 25), .completed)
            if result.exists { return }
            action.tap()
        }
        XCTFail("Heads-up hand did not settle")
    }

    private func count(_ app: XCUIApplication, _ label: String) {
        let element = app.staticTexts["free-session-count"]
        wait(element)
        XCTAssertEqual(element.label, label)
    }

    private func wait(_ element: XCUIElement, timeout: TimeInterval = 20) {
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            element.exists && element.isEnabled && element.isHittable
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: timeout), .completed, "Unreachable: \(element)")
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
}
