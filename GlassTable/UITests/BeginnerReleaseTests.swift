import XCTest

final class BeginnerReleaseTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func app() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "0"]
        return app
    }

    func testThreeTabsAndPlacementRemainOptional() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Learn"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.tabBars.buttons["Play"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progress"].exists)
        XCTAssertEqual(app.tabBars.buttons.count, 3)
        app.swipeUp()
        app.buttons["Find a starting point"].tap()
        XCTAssertTrue(app.buttons["Start without the check"].waitForExistence(timeout: 5))
        app.buttons["Start without the check"].tap()
        app.tabBars.buttons["Progress"].tap()
        XCTAssertFalse(app.staticTexts["100%"].exists)
        app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.buttons["Full learning path"].exists
                      || app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Full learning path")).firstMatch.exists)
    }

    func testOpponentDetailsDoNotMoveTheChoices() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        let cautious = app.buttons["opponent-nit"]
        XCTAssertTrue(cautious.waitForExistence(timeout: 5))
        let original = cautious.frame
        cautious.tap()
        XCTAssertTrue(app.buttons["opponent-start"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(cautious.waitForExistence(timeout: 5))
        XCTAssertEqual(cautious.frame.minY, original.minY, accuracy: 2)
        app.buttons["opponent-tag"].tap()
        XCTAssertTrue(app.buttons["opponent-start"].waitForExistence(timeout: 5))
        app.buttons["opponent-start"].tap()
        XCTAssertTrue(app.staticTexts["Your turn"].waitForExistence(timeout: 10)
                      || app.staticTexts["Review this hand"].exists)
    }

    func testLanguageSwitchKeepsTheOpenPlacementQuestion() {
        let app = app()
        app.launchEnvironment["GT_DEMO_PLACEMENT"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["I'm new to poker"].waitForExistence(timeout: 15))
        app.buttons["I'm new to poker"].tap()
        XCTAssertTrue(app.staticTexts["1 of 3 · Take your time"].exists)
        app.buttons["language-menu"].firstMatch.tap()
        app.buttons["한국어"].tap()
        XCTAssertTrue(app.staticTexts["1 / 3 · 천천히 생각해도 좋아요"].waitForExistence(timeout: 5))
        app.buttons["language-menu"].firstMatch.tap()
        app.buttons["English"].tap()
        XCTAssertTrue(app.staticTexts["1 of 3 · Take your time"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["I'm new to poker"].exists)
    }

    func testCommittedAdvancedLessonResumesTheSameAnswer() {
        let app = app()
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u2-potOdds"
        app.launch()
        let submit = app.buttons["Check answer"]
        XCTAssertTrue(submit.waitForExistence(timeout: 15))
        submit.tap()
        let saved = app.staticTexts.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "saved-answer-potOdds/"
        )).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        let answerID = saved.identifier
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        XCTAssertTrue(app.buttons["Resume lesson"].waitForExistence(timeout: 15))
        app.buttons["Resume lesson"].tap()
        XCTAssertTrue(app.staticTexts[answerID].waitForExistence(timeout: 5))
        let next = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch
        scrollTo(next, in: app)
        next.tap()
        XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 5))
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    func testChartExplorerReachesOwnHandAtLargestTextSize() {
        let app = app()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["GT_DEMO_TABLE"] = "tag"
        app.launchEnvironment["GT_DEMO_TABLE_STEP"] = "1"
        app.launchEnvironment["GT_DEMO_TABLE_CHART"] = "1"
        app.launch()
        let enlarge = app.buttons["Enlarge and explore hands"]
        XCTAssertTrue(enlarge.waitForExistence(timeout: 15))
        scrollTo(enlarge, in: app)
        enlarge.tap()
        let own = app.buttons["chart-cell-76o"]
        XCTAssertTrue(own.waitForExistence(timeout: 5))
        XCTAssertTrue(own.isHittable)
        XCTAssertGreaterThanOrEqual(own.frame.height, 44)
        XCTAssertGreaterThanOrEqual(own.frame.width, 44)
        own.tap()
        XCTAssertTrue(app.staticTexts["chart-explorer-selection"].label.contains("76o"))
        app.buttons["Return to my hand"].tap()
        XCTAssertTrue(own.isHittable)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "chart-explorer-english-ax5"; capture.lifetime = .keepAlways
        add(capture)
    }

    func testQuestionDraftSurvivesRelaunchWithoutAnAnswer() {
        let app = app()
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u1-combos"
        app.launch()
        XCTAssertTrue(app.buttons["Enter answer"].waitForExistence(timeout: 15))
        app.buttons["Enter answer"].tap()
        app.buttons["Digit 4"].tap()
        app.buttons["Digit 3"].tap()
        app.buttons["Done entering"].tap()
        // Leaving the lesson flushes pending input without grading it.
        app.buttons["Close"].firstMatch.tap()
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        XCTAssertTrue(app.buttons["Resume lesson"].waitForExistence(timeout: 15))
        app.buttons["Resume lesson"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "43")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "saved-answer-")).firstMatch.exists)
    }

    func testPracticeHandSettlesAndNextHandSurvivesRelaunch() {
        let app = app()
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        app.launchEnvironment["GT_DEMO_PRACTICE"] = "1"
        app.launchEnvironment["GT_DEMO_TAB"] = "play"
        app.launch()
        let fold = app.buttons["Fold · leave this hand"]
        XCTAssertTrue(fold.waitForExistence(timeout: 15))
        scrollTo(fold, in: app)
        fold.tap()
        XCTAssertTrue(app.staticTexts["Review this hand"].waitForExistence(timeout: 10))
        let next = app.buttons["Next hand"]
        scrollTo(next, in: app)
        next.tap()
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_TAB": "play"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Hand 2"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["practice-table"].exists)
    }

    func testCallFoldFixtureOpensThatConceptNotAMixedCheckpoint() {
        let app = app()
        app.launchEnvironment["GT_DEMO_CONCEPT"] = "callFold"
        app.launch()
        XCTAssertTrue(app.staticTexts["Call or fold"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "drill-question-callFold/"
        )).firstMatch.exists)
    }

    func testEquityCardsFitAboveAnswerSheetOnCompactPhone() {
        let app = app()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launchEnvironment["GT_DEMO_LANGUAGE"] = "en"
        app.launchEnvironment["GT_DEMO_CONCEPT"] = "equitySense"
        app.launch()

        let hero = app.otherElements["equity-hero-cards"]
        let opponent = app.otherElements["equity-opponent-cards"]
        let board = app.otherElements["equity-board-cards"]
        let question = app.staticTexts["If both hands reach the end, how often do you win?"]
        XCTAssertTrue(app.buttons["Check answer"].waitForExistence(timeout: 15))
        XCTAssertTrue(hero.exists && opponent.exists && board.exists && question.exists)
        // ActionSheet places its question 12 + 4 + 13 points below the sheet edge.
        let answerSheetTop = question.frame.minY - 29
        for region in [hero, opponent, board] {
            XCTAssertTrue(region.isHittable, "\(region.identifier) must be visible before answering")
            XCTAssertLessThan(region.frame.maxY, answerSheetTop,
                              "\(region.identifier) must stay above the answer sheet")
        }
        XCTAssertLessThanOrEqual(board.frame.maxX, app.frame.maxX)
        XCTAssertGreaterThanOrEqual(board.frame.minX, app.frame.minX)
    }
}
