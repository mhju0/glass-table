import XCTest

final class FreePlayQuestFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testWinningResultWithholdsBestFiveUntilAnswerIncludingResume() {
        let app = launch("en", reduced: false, questFixture: "winner")
        join(app)
        settle(app)
        let surface = app.otherElements["practice-table"]
        XCTAssertEqual(surface.value as? String, "winnerCards=0")
        capture(app, "winner-unanswered-normal")

        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GT_DEMO_PRACTICE")
        app.launchEnvironment["GT_DEMO_REDUCE_MOTION"] = "1"
        app.launch()
        resume(app)
        XCTAssertEqual(surface.value as? String, "winnerCards=0")
        capture(app, "winner-unanswered-resume-reduced")

        app.buttons["free-quest"].tap()
        let answer = app.buttons["free-quest-choice-1"]
        wait(answer)
        answer.tap()
        wait(app.staticTexts["free-quest-feedback"])
        XCTAssertEqual(app.staticTexts["free-quest-progress"].label, "Correct answers 1/2")
        app.buttons["free-progress-close"].tap()
        XCTAssertEqual(surface.value as? String, "winnerCards=5")
        capture(app, "winner-answered-highlight")
    }

    func testQuickHistorySkipsOnlyTheOpenedCurrentHand() {
        let app = launch("en", reduced: true, questFixture: "quick")
        join(app)
        settle(app)
        relaunchAtPlay(app)
        openHistory(app)
        app.buttons["quick-game-close"].tap()
        resume(app)
        XCTAssertEqual(app.buttons["free-quest"].label, "Answer quest")
        app.buttons["Close"].tap()
        openHistory(app)
        openFirstArchivedHand(app)
        wait(app.staticTexts["coach-progress"])
        app.buttons["coach-close"].tap()
        app.buttons["quick-game-close"].tap()
        resume(app)
        XCTAssertEqual(app.buttons["free-quest"].label, "Quest 0/2")
    }

    func testRecapRetryOpensTheRequestedReview() {
        let app = launch("en", reduced: true, questFixture: "winner", failsReviewSave: true)
        join(app)
        settle(app)
        let review = app.buttons["free-review"]
        review.tap()
        _ = retryButton(app)
        XCTAssertFalse(app.buttons["free-review-decisions"].exists)
        XCTAssertFalse(review.isEnabled)
        retryButton(app).tap()
        wait(app.buttons["free-review-next-hand"])
        capture(app, "recap-open-after-save-retry")
        app.buttons["free-progress-close"].tap()
        XCTAssertEqual(app.buttons["free-quest"].label, "Quest 0/2")
    }

    func testQuickHistoryRetryOpensTheRequestedHand() {
        let app = launch("ko", reduced: true, questFixture: "quick", failsReviewSave: true)
        join(app)
        settle(app)
        relaunchAtPlay(app)
        openHistory(app)
        openFirstArchivedHand(app)
        _ = retryButton(app, label: "다시 저장")
        XCTAssertFalse(app.staticTexts["coach-progress"].exists)
        openFirstArchivedHand(app)
        retryButton(app, label: "다시 저장").tap()
        wait(app.staticTexts["coach-progress"])
        capture(app, "ko-archive-open-after-save-retry")
        app.buttons["coach-close"].tap()
        app.buttons["quick-game-close"].tap()
        resume(app)
        XCTAssertEqual(app.buttons["free-quest"].label, "퀘스트 0/2")
    }

    func testLeavingFailedReviewKeepsTheQuestionAfterGeneralRetry() {
        let app = launch("en", reduced: true, questFixture: "winner", failsReviewSave: true)
        join(app)
        settle(app)
        relaunchAtPlay(app)
        resume(app)
        app.buttons["free-review"].tap()
        _ = retryButton(app)
        app.buttons["Close"].tap()
        retryButton(app).tap()
        resume(app)
        XCTAssertEqual(app.buttons["free-quest"].label, "Answer quest")
        XCTAssertFalse(app.buttons["free-review-next-hand"].exists)
        XCTAssertEqual(app.otherElements["practice-table"].value as? String, "winnerCards=0")
    }

    func testLeavingFailedQuickHistoryKeepsTheQuestionAfterGeneralRetry() {
        let app = launch("en", reduced: true, questFixture: "quick", failsReviewSave: true)
        join(app)
        settle(app)
        relaunchAtPlay(app)
        openHistory(app)
        openFirstArchivedHand(app)
        _ = retryButton(app)
        app.buttons["quick-game-close"].tap()
        retryButton(app).tap()
        resume(app)
        XCTAssertEqual(app.buttons["free-quest"].label, "Answer quest")
        XCTAssertFalse(app.staticTexts["coach-progress"].exists)
    }

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

    private func launch(_ language: String, reduced: Bool, opensFixture: Bool = true,
                        questFixture: String? = nil, failsReviewSave: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))",
                               "-AppleLocale", language == "ko" ? "ko_KR" : "en_US"]
        app.launchEnvironment = [
            "GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
            "GT_DEMO_LANGUAGE": language, "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
            "GT_DEMO_PLAYERS": "2", "GT_DEMO_REDUCE_MOTION": reduced ? "1" : "0"
        ]
        if !opensFixture { app.launchEnvironment.removeValue(forKey: "GT_DEMO_PRACTICE") }
        if let questFixture { app.launchEnvironment["GT_TEST_FREE_PLAY_REVIEW"] = questFixture }
        if failsReviewSave { app.launchEnvironment["GT_TEST_FREE_PLAY_REVIEW_SAVE_FAILURE"] = "1" }
        app.launch()
        return app
    }

    private func resume(_ app: XCUIApplication) {
        let row = app.buttons["play-continue"]
        for _ in 0..<5 where !row.isHittable { app.swipeDown() }
        wait(row)
        row.tap()
        let closeGuide = app.buttons["free-table-back-close"]
        if closeGuide.waitForExistence(timeout: 2) { closeGuide.tap() }
        wait(app.buttons["free-next-hand"])
    }

    private func relaunchAtPlay(_ app: XCUIApplication) {
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GT_DEMO_PRACTICE")
        app.launch()
        wait(app.buttons["play-continue"])
    }

    private func openHistory(_ app: XCUIApplication) {
        let history = app.buttons["play-quick-history"]
        for _ in 0..<4 where !history.isHittable { app.swipeUp() }
        wait(history)
        history.tap()
        wait(app.buttons["quick-game-close"])
    }

    private func openFirstArchivedHand(_ app: XCUIApplication) {
        let hand = app.buttons["archive-hand-1"]
        let scroll = app.scrollViews["quick-game-scroll"]
        for _ in 0..<6 where !hand.isHittable { scroll.swipeUp() }
        wait(hand)
        hand.tap()
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

    private func retryButton(_ app: XCUIApplication, label: String = "Retry save") -> XCUIElement {
        let candidates = app.buttons.matching(identifier: label)
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            candidates.allElementsBoundByIndex.contains(where: \.isHittable)
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 20), .completed)
        return candidates.allElementsBoundByIndex.first(where: \.isHittable) ?? candidates.firstMatch
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
}
