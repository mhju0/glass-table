import XCTest

final class WelcomeFirstFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func app(korean: Bool = false, ax: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-glassTable.language", korean ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "1", "GT_TEST_FIRST_PLACEMENT": "1"]
        return app
    }

    private func tap(_ id: String, in app: XCUIApplication) {
        let element = app.buttons[id]
        _ = element.waitForExistence(timeout: 5)
        for _ in 0..<10 where !element.exists || !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.exists, id)
        XCTAssertTrue(element.isHittable, id)
        element.tap()
    }

    private func retrySave(in app: XCUIApplication) {
        let buttons = app.buttons.matching(identifier: "Retry save")
        XCTAssertTrue(buttons.firstMatch.waitForExistence(timeout: 5))
        let matches = buttons.allElementsBoundByIndex
        print("OPENING_RETRY_MATCHES: \(matches.map { "frame=\($0.frame), enabled=\($0.isEnabled), hittable=\($0.isHittable)" })")
        guard let visibleRetry = matches.first(where: { $0.isHittable }) else {
            XCTFail("The visible save notice must offer a hittable Retry control.\n\(app.debugDescription)")
            return
        }
        visibleRetry.tap()
    }

    private func begin(_ app: XCUIApplication) {
        app.launch()
        XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 15))
        tap("firstLesson.start", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["firstLesson.teachPair.heading"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["placement.level.newToPoker"].exists)
        tap("firstLesson.next", in: app)
        XCTAssertTrue(app.staticTexts["firstLesson.question"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["firstLesson.help"].exists)
    }

    private func checkpoint(_ app: XCUIApplication) {
        begin(app)
        tap("firstLesson.choice.1", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].waitForExistence(timeout: 5))
        tap("firstLesson.next", in: app)
        tap("firstLesson.help", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].label.contains("together") || app.descendants(matching: .any)["firstLesson.verdict"].label.contains("함께"))
        tap("firstLesson.next", in: app)
        XCTAssertTrue(app.buttons["firstLesson.continueGuide"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["firstLesson.finish"].exists)
    }

    func testEnglishDefaultStartsWithTeachingNotPlacement() { begin(app()) }
    func testKoreanAX5DefaultStartsWithTeachingNotPlacement() { begin(app(korean: true, ax: true)) }

    func testCheckpointStopRelaunchAndResumeKeepsGuideUnfinished() {
        let app = app()
        checkpoint(app)
        tap("firstLesson.stop", in: app)
        XCTAssertTrue(app.buttons["learn-resume-opening"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["learn-resume-opening"].waitForExistence(timeout: 15))
        tap("learn-resume-opening", in: app)
        XCTAssertTrue(app.buttons["firstLesson.continueGuide"].waitForExistence(timeout: 5))
        tap("firstLesson.previous", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].label.contains("together"))
        tap("firstLesson.next", in: app)
        tap("firstLesson.continueGuide", in: app)
        for _ in 0..<3 {
            tap("firstLesson.help", in: app)
            tap("firstLesson.next", in: app)
        }
        tap("firstLesson.next", in: app)
        tap("firstLesson.finish", in: app)
        XCTAssertTrue(app.buttons["basics.close"].waitForExistence(timeout: 5), "Resume completion follows the promised hand-ranks destination.")
    }

    func testWrongAnswerAndBackSurviveInterruption() {
        let app = app()
        begin(app)
        tap("firstLesson.choice.1", in: app)
        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        let label = verdict.label
        app.terminate(); app.launch()
        XCTAssertTrue(verdict.waitForExistence(timeout: 15))
        XCTAssertEqual(verdict.label, label)
        tap("firstLesson.next", in: app)
        tap("firstLesson.previous", in: app)
        XCTAssertEqual(verdict.label, label)
    }

    func testExperiencedBypassDoesNotCompleteGuide() {
        let app = app()
        app.launch()
        tap("firstLesson.bypass", in: app)
        XCTAssertTrue(app.buttons["learn-resume-opening"].waitForExistence(timeout: 5))
        tap("learn-resume-opening", in: app)
        XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 5))
    }

    func testOptionalPreferenceReturnsToCheckpoint() {
        let app = app()
        checkpoint(app)
        tap("firstLesson.preference", in: app)
        tap("firstLesson.preference.knowRules", in: app)
        XCTAssertTrue(app.buttons["firstLesson.continueGuide"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["firstLesson.preference"].exists)
        XCTAssertFalse(app.buttons["firstLesson.finish"].exists)
    }

    func testReplayKeepsPendingGuideAndHasNoPreferenceWrite() {
        let app = app()
        begin(app)
        tap("firstLesson.choice.1", in: app)
        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        let originalVerdict = verdict.label
        let originalReason = app.staticTexts["firstLesson.reason"].label
        tap("firstLesson.next", in: app)
        tap("firstLesson.help", in: app)
        tap("firstLesson.next", in: app)
        tap("firstLesson.stop", in: app)
        app.tabBars.buttons["Settings"].tap()
        let replay = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Replay the first decision")).firstMatch
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        for _ in 0..<10 where !replay.isHittable { app.swipeUp() }
        replay.tap()
        tap("firstLesson.start", in: app)
        tap("firstLesson.next", in: app)
        for _ in 0..<2 {
            tap("firstLesson.help", in: app)
            tap("firstLesson.next", in: app)
        }
        XCTAssertTrue(app.buttons["firstLesson.continueGuide"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["firstLesson.preference"].exists)
        tap("firstLesson.close", in: app)
        app.tabBars.buttons["Learn"].tap()
        tap("learn-resume-opening", in: app)
        XCTAssertTrue(app.buttons["firstLesson.continueGuide"].waitForExistence(timeout: 5))
        for _ in 0..<3 { tap("firstLesson.previous", in: app) }
        XCTAssertEqual(verdict.label, originalVerdict)
        XCTAssertEqual(app.staticTexts["firstLesson.reason"].label, originalReason)
    }

    func testFailedAnswerRetryRestoresRevealAndBack() {
        let app = app()
        app.launchEnvironment["GT_TEST_OPENING_SAVE_FAILURE"] = "answer"
        begin(app)
        tap("firstLesson.choice.1", in: app)
        XCTAssertTrue(app.staticTexts["Progress was not saved"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["firstLesson.verdict"].exists)
        retrySave(in: app)
        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        let label = verdict.label
        tap("firstLesson.next", in: app)
        tap("firstLesson.previous", in: app)
        XCTAssertEqual(verdict.label, label)
        app.terminate(); app.launch()
        XCTAssertTrue(verdict.waitForExistence(timeout: 15))
        XCTAssertEqual(verdict.label, label)
    }

    func testFailedChoiceReplacingHelpRetryKeepsCommittedChoice() {
        let app = app()
        begin(app)
        tap("firstLesson.help", in: app)
        tap("firstLesson.previous", in: app)
        app.terminate()
        app.launchEnvironment["GT_TEST_OPENING_SAVE_FAILURE"] = "answer"
        app.launch()
        tap("firstLesson.choice.1", in: app)
        XCTAssertTrue(app.staticTexts["Progress was not saved"].waitForExistence(timeout: 5))
        retrySave(in: app)
        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertFalse(verdict.label.contains("together"))
        let label = verdict.label
        tap("firstLesson.next", in: app)
        tap("firstLesson.previous", in: app)
        XCTAssertEqual(verdict.label, label)
        app.terminate(); app.launch()
        XCTAssertTrue(verdict.waitForExistence(timeout: 15))
        XCTAssertEqual(verdict.label, label)
    }

    func testFailedResumedCompletionRetryOpensPromisedBasics() { failedCompletion(resumed: true) }
    func testFailedFirstRunCompletionRetryOpensPromisedBasics() { failedCompletion(resumed: false) }

    private func failedCompletion(resumed: Bool) {
        let app = app()
        app.launchEnvironment["GT_TEST_OPENING_SAVE_FAILURE"] = "completion"
        checkpoint(app)
        tap("firstLesson.continueGuide", in: app)
        for _ in 0..<3 {
            tap("firstLesson.help", in: app)
            tap("firstLesson.next", in: app)
        }
        tap("firstLesson.next", in: app)
        if resumed {
            tap("firstLesson.skip", in: app)
            tap("learn-resume-opening", in: app)
        }
        tap("firstLesson.finish", in: app)
        XCTAssertTrue(app.staticTexts["Progress was not saved"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["basics.close"].exists)
        retrySave(in: app)
        XCTAssertTrue(app.buttons["basics.close"].waitForExistence(timeout: 10))
        tap("basics.close", in: app)
        XCTAssertTrue(app.buttons["learn-path"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["learn-resume-opening"].exists)
    }

    func testFailedCheckpointDismissalRetryReachesLearnWithResume() {
        let app = app()
        app.launchEnvironment["GT_TEST_OPENING_SAVE_FAILURE"] = "dismissal"
        checkpoint(app)
        tap("firstLesson.stop", in: app)
        XCTAssertTrue(app.staticTexts["Progress was not saved"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["learn-path"].exists)
        retrySave(in: app)
        XCTAssertTrue(app.buttons["learn-resume-opening"].waitForExistence(timeout: 10))
        tap("learn-resume-opening", in: app)
        XCTAssertTrue(app.buttons["firstLesson.continueGuide"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["firstLesson.finish"].exists)
    }

    func testCorrectAnswerExplainsRealCards() {
        let app = app()
        begin(app)
        tap("firstLesson.choice.0", in: app)
        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertTrue(verdict.label.contains("You got it"))
        XCTAssertTrue(app.staticTexts["firstLesson.reason"].exists)
    }
}
