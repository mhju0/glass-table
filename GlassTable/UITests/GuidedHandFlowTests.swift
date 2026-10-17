import XCTest

final class GuidedHandFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testEnglishLearnBridgeWrongAnswerBackReplayAndPlay() { exercise(korean: false, ax: false) }
    func testKoreanLearnBridgeAX5() { exercise(korean: true, ax: true) }

    private func exercise(korean: Bool, ax: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0"]
        app.launchArguments = ["-glassTable.language", korean ? "korean" : "english",
                               "-UIPreferredContentSizeCategoryName",
                               ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        func tap(_ id: String) {
            let button = app.buttons[id]
            XCTAssertTrue(button.waitForExistence(timeout: 15))
            for _ in 0..<12 where !button.isHittable { app.swipeUp() }
            XCTAssertTrue(button.isHittable)
            button.tap()
        }
        func stage(_ name: String) {
            XCTAssertTrue(app.staticTexts["guided-hand-stage-\(name)"].waitForExistence(timeout: 5), name)
        }
        tap("learn-guided-hand")
        stage("seats"); tap("guided-hand-next")
        stage("blinds"); tap("guided-hand-next")
        stage("preflop")
        // Giving up asks first and can be taken back.
        tap("guided-hand-fold")
        XCTAssertTrue(app.staticTexts["guided-hand-fold-question"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["guided-hand-call"].exists)
        tap("guided-hand-fold-cancel")
        tap("guided-hand-call")
        stage("flop")
        XCTAssertFalse(app.buttons["guided-hand-fold"].exists, "Nothing to match, so giving up is not offered.")
        tap("guided-hand-raise")
        stage("turn"); tap("guided-hand-call")
        stage("river"); tap("guided-hand-check")
        stage("showdown"); tap("guided-hand-next")
        stage("summary")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = korean ? "guided-hand-ko-ax5-review" : "guided-hand-en-review"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        tap("guided-hand-replay")
        stage("seats"); tap("guided-hand-next"); tap("guided-hand-next")
        tap("guided-hand-fold"); tap("guided-hand-fold-confirm")
        stage("summary")
        tap("guided-hand-play")
        XCTAssertTrue(app.tabBars.buttons[korean ? "플레이" : "Play"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons[korean ? "플레이" : "Play"].isSelected)
        XCTAssertFalse(app.buttons["guided-hand-close"].exists)
    }
}

final class RestoredLessonParityFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testPositionDirectAndResumedUseNumberedLoop() { exercise(range: false, korean: false, ax: false) }
    func testRangeDirectAndResumedKeepComparisonEvidence() { exercise(range: true, korean: false, ax: false) }
    func testKoreanAXPositionDirectAndResumedUseNumberedLoop() { exercise(range: false, korean: true, ax: true) }
    func testKoreanAXRangeDirectAndResumedKeepComparisonEvidence() { exercise(range: true, korean: true, ax: true) }

    private func exercise(range: Bool, korean: Bool, ax: Bool) {
        let app = XCUIApplication()
        let store = UUID().uuidString
        app.launchArguments = ["-glassTable.language", korean ? "korean" : "english",
                               "-UIPreferredContentSizeCategoryName",
                               ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": range ? "u4-rangeRead" : "u1-position"]
        app.launch()
        func reach(_ element: XCUIElement) {
            for _ in 0..<20 {
                if element.exists && element.isHittable { return }
                let drillScroll = app.scrollViews[ax ? "drill-accessibility-scroll" : "drill-content-scroll"].firstMatch
                if drillScroll.exists { drillScroll.swipeUp() }
                else { app.swipeUp() }
            }
            XCTAssertTrue(element.waitForExistence(timeout: 3), "Missing after scrolling: \(element.identifier)")
            XCTAssertTrue(element.isHittable, "Unreachable after scrolling: \(element.identifier)")
        }
        if range {
            let choice = app.buttons["range-estimate-choice-0"]
            reach(choice); choice.tap()
        } else {
            XCTAssertTrue(app.descendants(matching: .any)["position-boxed-loop"].waitForExistence(timeout: 15))
            let choice = app.buttons.matching(NSPredicate(format: "label IN %@", ["A","B","0","1","2","3","4","5","6","7"])).firstMatch
            reach(choice); choice.tap()
        }
        let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch
        XCTAssertTrue(completion.waitForExistence(timeout: 15))
        let identifier = range ? "range-difference-list" : "position-boxed-loop"
        XCTAssertTrue(app.descendants(matching: .any)[identifier].exists)
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume); resume.tap()
        let evidence = app.descendants(matching: .any)[identifier].firstMatch
        reach(evidence)
        if range {
            XCTAssertTrue(app.staticTexts[korean ? "색: 정답 · 테두리: 선택한 답" : "Fill: answer · outline: your estimate"].exists)
        } else {
            let terms = app.buttons["position-terms-toggle"]
            let scroll = app.scrollViews[ax ? "drill-accessibility-scroll" : "drill-content-scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 5))
            for _ in 0..<16 where !terms.exists || !terms.isHittable { scroll.swipeUp() }
            reach(terms)
            terms.tap()
            XCTAssertEqual(terms.label, korean ? "용어 접기" : "Hide terms")
            terms.tap()
            XCTAssertEqual(terms.label, korean ? "포커 용어 보기" : "Show poker terms")
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(korean ? "ko" : "en")-\(ax ? "ax5" : "normal")-" + (range ? "restored-range-comparison" : "restored-numbered-position")
        attachment.lifetime = .keepAlways
        add(attachment)
        reach(completion)
        app.terminate()
    }
}

final class BasicsGuidedHandInvitationTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testEnglishFirstRunBasicsOffersHandAndContinuesLessons() { exercise(korean: false, ax: false, chooseHand: false) }
    func testKoreanFirstRunBasicsOffersReachableHandAX5() { exercise(korean: true, ax: true, chooseHand: true) }
    /// Swiping the invitation away chooses neither option, so no lesson may open.
    func testKoreanSwipingTheInvitationAwayStaysOnLearn() {
        exercise(korean: true, ax: false, chooseHand: false, swipeAway: true)
    }

    private func exercise(korean: Bool, ax: Bool, chooseHand: Bool, swipeAway: Bool = false) {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "1", "GT_TEST_FIRST_PLACEMENT": "0"]
        app.launchArguments = ["-glassTable.language", korean ? "korean" : "english",
                               "-UIPreferredContentSizeCategoryName",
                               ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        func tap(_ element: XCUIElement) {
            XCTAssertTrue(element.waitForExistence(timeout: 15))
            for _ in 0..<16 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable)
            element.tap()
        }
        tap(app.buttons["firstLesson.start"])
        tap(app.buttons["firstLesson.next"])
        for _ in 0..<5 {
            tap(app.buttons["firstLesson.choice.0"])
            tap(app.buttons["firstLesson.next"])
        }
        tap(app.buttons["firstLesson.next"])
        tap(app.buttons["firstLesson.finish"])
        XCTAssertTrue(app.buttons["basics.close"].waitForExistence(timeout: 10))
        tap(app.buttons["basics.next"])
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "basics.choice.")).firstMatch
        tap(choice)
        tap(app.buttons["basics.check-next"])
        tap(app.buttons["basics.kicker.choice.mine"])
        tap(app.buttons["basics.finish"])
        XCTAssertTrue(app.staticTexts["guided-hand-invitation"].waitForExistence(timeout: 10))
        let continueLessons = app.buttons["guided-hand-invitation-continue"]
        XCTAssertEqual(continueLessons.label, korean ? "레슨 계속하기" : "Continue lessons")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = korean ? "post-basics-invitation-ko-ax5" : "post-basics-invitation-en-normal"
        attachment.lifetime = .keepAlways
        add(attachment)
        if swipeAway {
            let title = app.staticTexts["guided-hand-invitation"]
            title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.05,
                       thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
            XCTAssertTrue(app.buttons["lesson-u1-showdown"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.descendants(matching: .any)["walkthrough-step-0"].waitForExistence(timeout: 4),
                           "Closing the invitation without choosing must not start a lesson.")
            XCTAssertFalse(app.staticTexts["guided-hand-invitation"].exists)
            return
        }
        tap(app.buttons[chooseHand ? "guided-hand-invitation-start" : "guided-hand-invitation-continue"])
        if chooseHand {
            XCTAssertTrue(app.staticTexts["guided-hand-stage-seats"].waitForExistence(timeout: 10))
            tap(app.buttons["guided-hand-close"])
            XCTAssertTrue(app.buttons["lesson-u1-showdown"].waitForExistence(timeout: 10))
        } else {
            let firstStep = app.descendants(matching: .any)["walkthrough-step-0"]
            XCTAssertTrue(firstStep.waitForExistence(timeout: 10))
            XCTAssertTrue(firstStep.label.hasPrefix(korean ? "누가 이길까요?" : "Who wins?"),
                          "The new player's stored next lesson is the showdown lesson.")
            tap(app.buttons["walkthrough-next"])
            let secondStep = app.descendants(matching: .any)["walkthrough-step-1"]
            XCTAssertTrue(secondStep.waitForExistence(timeout: 5))
            tap(app.buttons[korean ? "닫기" : "Close"])
            let resume = app.buttons["learn-continue"]
            tap(resume)
            XCTAssertTrue(secondStep.waitForExistence(timeout: 10),
                          "Continue lessons opened a real node session and saved its walkthrough position.")
            XCTAssertFalse(app.buttons["guided-hand-close"].exists)
        }
        XCTAssertFalse(app.staticTexts["guided-hand-invitation"].exists)
    }
}
