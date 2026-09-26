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

    func testFourTabsAndPlacementRemainOptional() {
        let app = app()
        app.launch()
        let tabs = app.tabBars.buttons
        let learn = tabs["Learn"]
        let play = tabs["Play"]
        let progress = tabs["Progress"]
        let settings = tabs["Settings"]
        XCTAssertTrue(learn.waitForExistence(timeout: 15))
        XCTAssertEqual(tabs.count, 4)
        XCTAssertTrue(play.exists && progress.exists && settings.exists)
        XCTAssertLessThan(learn.frame.midX, play.frame.midX)
        XCTAssertLessThan(play.frame.midX, progress.frame.midX)
        XCTAssertLessThan(progress.frame.midX, settings.frame.midX)
        XCTAssertGreaterThanOrEqual(settings.frame.width, 44)
        XCTAssertGreaterThanOrEqual(settings.frame.height, 44)
        XCTAssertFalse(app.buttons["language-menu"].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "Settings").count, 1,
                       "Settings should only be a tab, not a top button")
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

    func testStartingPointLeadsUntilTheFirstLessonThenMovesBelowPractice() {
        let app = app()
        app.launch()
        let path = app.buttons["learn-path"]
        XCTAssertTrue(path.waitForExistence(timeout: 15))
        let card = app.buttons["placement-start"]
        XCTAssertTrue(card.exists, "Before any lesson, the starting-point check is a real button")
        XCTAssertLessThan(card.frame.minY, path.frame.minY)
        XCTAssertFalse(app.buttons["placement-row"].exists)
        app.terminate()

        app.launchEnvironment["GT_TEST_STORE_ID"] = UUID().uuidString
        app.launchEnvironment["GT_TEST_PATH_CURRENT_NODE"] = "u1-potMath"
        app.launch()
        XCTAssertTrue(path.waitForExistence(timeout: 15))
        let row = app.buttons["placement-row"]
        scrollTo(row, in: app)
        XCTAssertTrue(row.exists)
        XCTAssertFalse(app.buttons["placement-start"].exists)
        XCTAssertGreaterThan(row.frame.minY, path.frame.minY)
        row.tap()
        XCTAssertTrue(app.buttons["Start without the check"].waitForExistence(timeout: 5))
    }

    func testPlayHomeOffersTwoModesAboveTheTabBar() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        let free = app.buttons["play-free"]
        let graded = app.buttons["play-graded"]
        XCTAssertTrue(free.waitForExistence(timeout: 5))
        XCTAssertTrue(free.label.contains("Free table"), free.label)
        XCTAssertTrue(graded.label.contains("Graded 1:1 practice"), graded.label)
        XCTAssertTrue(free.isHittable && graded.isHittable)
        XCTAssertLessThan(graded.frame.maxY, app.tabBars.firstMatch.frame.minY,
                          "Both mode cards must clear the tab bar without scrolling")
        let midline = app.windows.firstMatch.frame.midY
        XCTAssertLessThanOrEqual(free.frame.maxY, midline, "The screen's midline falls between the two cards")
        XCTAssertGreaterThanOrEqual(graded.frame.minY, midline, "The screen's midline falls between the two cards")
    }

    func testTableHabitsShowAProgressLineAndKeepTheEvidenceOneTapDown() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Progress"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Progress"].tap()
        let headline = app.staticTexts["Not enough hands yet"]
        for _ in 0..<4 where !headline.exists { app.swipeUp() }
        XCTAssertTrue(headline.exists)
        XCTAssertTrue(app.staticTexts["0 of 100 hands · 0 of 5 days"].exists)
        let fine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Describes preflop play"))
        XCTAssertFalse(fine.firstMatch.exists, "Thresholds stay out of the way until asked for")
        app.buttons["records-style-details"].tap()
        XCTAssertTrue(fine.firstMatch.waitForExistence(timeout: 5))
    }

    func testTableSetupGivesEachComputerItsOwnStyle() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        app.buttons["play-free"].tap()
        XCTAssertTrue(app.staticTexts["Set up the table"].waitForExistence(timeout: 5))
        let seats = (1...3).map { app.buttons["seat-style-\($0)"] }
        XCTAssertTrue(seats.allSatisfy(\.exists))
        XCTAssertEqual(Set(seats.map(\.label)).count, 3, "Default computers should play three different styles")

        seats[1].tap()
        app.buttons["Very aggressive"].firstMatch.tap()
        XCTAssertTrue(app.buttons["seat-style-2"].label.contains("Very aggressive"), app.buttons["seat-style-2"].label)

        app.buttons["style-guide"].tap()
        let cautious = app.buttons["opponent-nit"]
        XCTAssertTrue(cautious.waitForExistence(timeout: 5))
        cautious.tap()
        XCTAssertTrue(app.staticTexts["Starting habits"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["table-start"].waitForExistence(timeout: 5))

        app.buttons["table-start"].tap()
        closeTableGuide(in: app)
        XCTAssertTrue(app.staticTexts["Your turn"].waitForExistence(timeout: 10)
                      || app.staticTexts["Review this hand"].exists)
        let table = app.descendants(matching: .any)["practice-table"]
        let second = table.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Computer 2 · ")).firstMatch
        XCTAssertTrue(second.label.contains("Very aggressive"), second.label)
    }

    func testSettingsListsProblemGamblingHelplines() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        let row = app.buttons["settings-responsible"]
        for _ in 0..<4 where !row.isHittable { app.swipeUp() }
        row.tap()
        XCTAssertTrue(app.staticTexts["Play responsibly"].waitForExistence(timeout: 5))
        let korea = app.descendants(matching: .any)["helpline-kr"]
        let us = app.descendants(matching: .any)["helpline-us"]
        XCTAssertTrue(korea.label.contains("1336"), korea.label)
        XCTAssertTrue(us.label.contains("1-800-GAMBLER"), us.label)
    }

    func testTwoPlayerTableSeatsOneComputer() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        app.buttons["play-free"].tap()
        XCTAssertTrue(app.buttons["seat-style-3"].waitForExistence(timeout: 5))
        app.buttons["2 players"].tap()
        XCTAssertTrue(app.buttons["player-count-2"].isSelected)
        XCTAssertFalse(app.buttons["player-count-4"].isSelected)
        XCTAssertTrue(app.buttons["seat-style-1"].exists)
        XCTAssertFalse(app.buttons["seat-style-2"].exists)
        app.buttons["table-start"].tap()
        closeTableGuide(in: app)
        let table = app.descendants(matching: .any)["practice-table"]
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Two-player practice"].exists)
        func seat(_ n: Int) -> XCUIElement {
            table.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@", "Computer \(n) · ")).firstMatch
        }
        XCTAssertTrue(seat(1).exists)
        XCTAssertFalse(seat(2).exists)
        XCTAssertFalse(seat(3).exists)
    }

    func testLanguageSwitchInSettingsKeepsTheSavedLesson() {
        let app = app()
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u2-potOdds"
        app.launch()
        XCTAssertTrue(app.buttons["Check answer"].waitForExistence(timeout: 15))
        app.buttons["Close"].firstMatch.tap()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertFalse(app.buttons["language-menu"].exists)
        app.buttons["language-korean"].tap()
        XCTAssertTrue(app.tabBars.buttons["설정"].isSelected)
        app.tabBars.buttons["배우기"].tap()
        app.buttons["레슨 이어서 하기"].tap()
        XCTAssertTrue(app.buttons["확인"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1/5"].exists)
        app.buttons["닫기"].firstMatch.tap()
        app.tabBars.buttons["설정"].tap()
        app.buttons["language-english"].tap()
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Learn"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Learn"].tap()
        app.buttons["Resume lesson"].tap()
        XCTAssertTrue(app.buttons["Check answer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1/5"].exists)
    }

    func testLearningPathAndHeadsUpExerciseKeepBackNavigation() {
        let app = app()
        app.launch()
        let path = app.buttons.matching(NSPredicate(
            format: "label CONTAINS %@", "Full learning path"
        )).firstMatch
        XCTAssertTrue(path.waitForExistence(timeout: 15))
        path.tap()
        XCTAssertTrue(app.staticTexts["Learning path"].waitForExistence(timeout: 5))
        let pathBack = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(pathBack.isHittable)
        pathBack.tap()
        XCTAssertTrue(path.waitForExistence(timeout: 5))

        app.tabBars.buttons["Play"].tap()
        let headsUp = app.buttons["play-graded"]
        XCTAssertTrue(headsUp.waitForExistence(timeout: 5))
        headsUp.tap()
        let tableBack = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(tableBack.waitForExistence(timeout: 5))
        XCTAssertTrue(tableBack.isHittable)
        tableBack.tap()
        XCTAssertTrue(headsUp.waitForExistence(timeout: 5))
    }

    func testSettingsLastRowAndOtherTabsStayReachableAtAccessibilityXXXL() {
        let app = app()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let tabs = app.tabBars.buttons
        XCTAssertTrue(tabs["Settings"].waitForExistence(timeout: 15))
        tabs["Settings"].tap()
        let version = app.staticTexts["Version"]
        for _ in 0..<14 where !version.isHittable { app.swipeUp() }
        XCTAssertTrue(version.isHittable, "The last Settings row must clear the tab bar")
        for title in ["Learn", "Play", "Progress", "Settings"] {
            let tab = tabs[title]
            XCTAssertTrue(tab.isHittable)
            tab.tap()
            XCTAssertTrue(tab.isSelected)
        }
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

    func testGradedRevealSheetIsTintedByItsVerdict() {
        let app = app()
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u2-potOdds"
        app.launch()
        let submit = app.buttons["Check answer"]
        XCTAssertTrue(submit.waitForExistence(timeout: 15))
        submit.tap()
        let sheet = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "graded-sheet-"
        )).firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        let verdicts = ["graded-sheet-spotOn": "Exact", "graded-sheet-close": "Close",
                        "graded-sheet-off": "Review this one"]
        let expected = try? XCTUnwrap(verdicts[sheet.identifier])
        XCTAssertNotNil(expected, "Unexpected sheet identifier \(sheet.identifier)")
        let verdict = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@", expected ?? "-"
        )).firstMatch
        XCTAssertTrue(verdict.exists, "The tint must match the verdict shown")
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

    /// The first table explains what each part shows once; the info button reopens it.
    func testFirstTableExplainsItselfOnceAndReopens() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        app.buttons["play-free"].tap()
        XCTAssertTrue(app.buttons["table-start"].waitForExistence(timeout: 5))
        app.buttons["table-start"].tap()
        let close = app.buttons["play-table-guide-close"]
        XCTAssertTrue(app.staticTexts["How to read the table"].waitForExistence(timeout: 10))
        for title in ["Your cards", "Opponents' cards", "Shared cards", "The pot",
                      "Whose turn", "What each action costs"] {
            XCTAssertTrue(app.staticTexts[title].exists, title)
        }
        for _ in 0..<6 where !close.isHittable { app.swipeUp() }
        close.tap()
        let reopen = app.buttons["play-table-guide"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["How to read the table"].exists)

        app.terminate()
        app.launchEnvironment["GT_DEMO_TAB"] = "play"
        app.launch()
        XCTAssertTrue(reopen.waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["How to read the table"].exists, "The guide shows only once")
        reopen.tap()
        XCTAssertTrue(app.staticTexts["How to read the table"].waitForExistence(timeout: 5))
    }

    private func closeTableGuide(in app: XCUIApplication) {
        let close = app.buttons["play-table-guide-close"]
        guard close.waitForExistence(timeout: 10) else { return }
        for _ in 0..<6 where !close.isHittable { app.swipeUp() }
        close.tap()
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

    /// Play uses the shared table: opponents hold face-down cards, the learner's cards
    /// are face up, and the known pot sits in the middle.
    func testPracticeTableHidesOpponentCardsAndShowsThePot() {
        let app = app()
        app.launchEnvironment["GT_DEMO_PRACTICE"] = "1"
        app.launchEnvironment["GT_DEMO_TAB"] = "play"
        app.launch()
        XCTAssertTrue(app.buttons["Fold · leave this hand"].waitForExistence(timeout: 15))
        let table = app.descendants(matching: .any)["practice-table"]
        for seat in 1...3 {
            let label = table.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@", "Computer \(seat) · ")).firstMatch
            XCTAssertTrue(label.exists, "Computer \(seat) seat")
            XCTAssertTrue(label.label.contains("two face-down cards"), label.label)
        }
        let you = table.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "You,")).firstMatch
        XCTAssertTrue(you.exists)
        XCTAssertFalse(you.label.contains("face-down"), you.label)
        let pot = table.descendants(matching: .any)["table-pot"]
        XCTAssertTrue(pot.exists)
        XCTAssertTrue(pot.label.hasPrefix("Pot, ") && pot.label.hasSuffix(" chips"), pot.label)
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
        let question = app.staticTexts["How often do you win at showdown?"]
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
