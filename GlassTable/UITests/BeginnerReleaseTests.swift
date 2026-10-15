import XCTest

final class BeginnerReleaseTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func app() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-glassTable.language", "english"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "0"]
        return app
    }

    func testLearnOffersLessonsWithoutAnExperienceQuestion() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.buttons["learn-basics-start"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["learn-level"].exists)
        app.buttons["learn-path"].tap()
        let first = app.buttons["lesson-u1-showdown"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(first.isEnabled)
    }

    func testPokerTermsSwitchPutsTheTermFirst() {
        let plain = app()
        plain.launchEnvironment["GT_DEMO_TAB"] = "path"
        plain.launch()
        let row = plain.buttons["lesson-u1-showdown"]
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        XCTAssertTrue(row.label.hasPrefix("Who wins?"), row.label)
        plain.terminate()

        let terms = app()
        terms.launchArguments += ["-glassTable.pokerTerms", "YES"]
        terms.launchEnvironment["GT_DEMO_TAB"] = "path"
        terms.launch()
        let termRow = terms.buttons["lesson-u1-showdown"]
        XCTAssertTrue(termRow.waitForExistence(timeout: 15))
        XCTAssertTrue(termRow.label.hasPrefix("Showdown"), termRow.label)
        terms.terminate()

        let settings = app()
        settings.launchArguments += ["-glassTable.pokerTerms", "YES"]
        settings.launchEnvironment["GT_DEMO_TAB"] = "settings"
        settings.launch()
        let toggle = settings.switches["settings-poker-terms"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 15))
        XCTAssertEqual(toggle.value as? String, "1")
    }

    func testFourTabsWithoutExperienceQuestion() {
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
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Find a starting point")).firstMatch.exists,
                       "The starting-point check no longer lives on Learn")
        settings.tap()
        let recheck = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Recheck your starting point")).firstMatch
        app.swipeUp()
        XCTAssertFalse(recheck.exists)
        app.tabBars.buttons["Progress"].tap()
        XCTAssertFalse(app.staticTexts["100%"].exists)
        app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.buttons["learn-path"].exists)
    }

    func testOpeningGuideResumesWithoutMandatoryPlacement() {
        let app = app()
        app.launchEnvironment["GT_TEST_FIRST_LESSON"] = "1"
        app.launchEnvironment["GT_TEST_FIRST_PLACEMENT"] = "1"
        app.launchArguments += ["-glassTable.language", "english"]
        app.launch()
        XCTAssertTrue(app.buttons["firstLesson.start"].waitForExistence(timeout: 15))
        app.buttons["firstLesson.start"].tap()
        XCTAssertTrue(app.staticTexts["firstLesson.teachPair.heading"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["placement.level.newToPoker"].exists, "The default start teaches before any optional preference")
        app.buttons["firstLesson.next"].tap()
        XCTAssertTrue(app.staticTexts["firstLesson.question"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["firstLesson.question"].waitForExistence(timeout: 15), "The saved guide resumes its current example")
        XCTAssertFalse(app.buttons["placement.level.newToPoker"].exists)
        let skipLesson = app.buttons["firstLesson.skip"]
        skipLesson.tap()
        let path = app.buttons["learn-path"]
        XCTAssertTrue(path.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["learn-basics-start"].exists, "A new player is pointed at the basics")
        app.swipeUp()
        XCTAssertFalse(app.buttons["placement-start"].exists)
        XCTAssertFalse(app.buttons["placement-row"].exists)
        app.terminate()

        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_TEST_PATH_CURRENT_NODE": "u1-potMath"]
        app.launch()
        XCTAssertTrue(path.waitForExistence(timeout: 15))
        app.swipeUp()
        XCTAssertFalse(app.buttons["placement-row"].exists)
        XCTAssertFalse(app.buttons["placement-start"].exists)
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
        app.buttons["records-details"].tap()
        let headline = app.staticTexts["Not enough hands yet"]
        for _ in 0..<4 where !headline.exists { app.swipeUp() }
        XCTAssertTrue(headline.exists)
        XCTAssertTrue(app.staticTexts["0 of 100 hands · 0 of 5 days"].exists)
        let fine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Describes preflop play"))
        XCTAssertFalse(fine.firstMatch.exists, "Thresholds stay out of the way until asked for")
        let styleDetails = app.buttons.matching(NSPredicate(format: "label == %@", "How this works")).firstMatch
        scrollTo(styleDetails, in: app)
        styleDetails.tap()
        XCTAssertTrue(fine.firstMatch.waitForExistence(timeout: 5))
    }

    func testTableSetupGivesEachComputerItsOwnStyle() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        app.buttons["play-free"].tap()
        let title = app.staticTexts["Set up the table"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        // The app's own Back control, with the title starting clear below it.
        let back = app.buttons["Back to Play"]
        XCTAssertTrue(back.exists)
        XCTAssertFalse(app.navigationBars.firstMatch.exists, "The system bar's glass back button is gone")
        XCTAssertGreaterThanOrEqual(title.frame.minY, back.frame.maxY - 1)
        XCTAssertEqual(app.staticTexts["player-count-detail"].label, "You + 3 computers")
        let seats = (1...3).map { app.buttons["seat-style-\($0)"] }
        XCTAssertTrue(seats.allSatisfy(\.exists))
        XCTAssertEqual(seats.map(\.label), ["Tom's style, Just for fun", "Mike's style, Just for fun",
                                            "Alex's style, Just for fun"], "A first table is a friendly one")

        seats[1].tap()
        app.buttons["Very aggressive"].firstMatch.tap()
        XCTAssertTrue(app.buttons["seat-style-2"].label.contains("Very aggressive"), app.buttons["seat-style-2"].label)

        app.buttons["style-guide"].tap()
        let cautious = app.buttons["opponent-nit"]
        XCTAssertTrue(cautious.waitForExistence(timeout: 5))
        let casual = app.descendants(matching: .any)["opponent-casual"]
        XCTAssertTrue(casual.exists, "The guide lists the default style the seat menu offers")
        XCTAssertTrue(casual.label.contains("Just for fun (default)"), casual.label)
        XCTAssertLessThan(casual.frame.minY, cautious.frame.minY)
        cautious.tap()
        XCTAssertTrue(app.staticTexts["Starting habits"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["table-start"].waitForExistence(timeout: 5))

        app.buttons["table-start"].tap()
        closeTableGuide(in: app)
        waitForYourTurnOrResult(in: app)
        let table = app.descendants(matching: .any)["practice-table"]
        let second = table.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Mike,")).firstMatch
        XCTAssertTrue(second.exists)
        XCTAssertTrue(second.label.contains("2 face-down cards"), second.label)
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
        XCTAssertEqual(app.staticTexts["player-count-detail"].label, "You + 1 computer")
        XCTAssertFalse(app.buttons["player-count-4"].isSelected)
        XCTAssertTrue(app.buttons["seat-style-1"].exists)
        XCTAssertFalse(app.buttons["seat-style-2"].exists)
        app.buttons["table-start"].tap()
        closeTableGuide(in: app)
        let table = app.descendants(matching: .any)["practice-table"]
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Two players · Hand 1 of 10"].exists)
        func seat(_ n: Int) -> XCUIElement {
            table.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@", ["Tom", "Mike", "Alex"][n - 1] + ",")).firstMatch
        }
        XCTAssertTrue(seat(1).exists)
        XCTAssertFalse(seat(2).exists)
        XCTAssertFalse(seat(3).exists)
    }

    private func chooseLanguage(_ value: String, in app: XCUIApplication) {
        let picker = app.buttons["settings-language"]
        for _ in 0..<12 where !picker.isHittable { app.swipeUp() }
        XCTAssertTrue(picker.isHittable)
        picker.tap()
        app.buttons["language-\(value)"].tap()
    }

    func testLanguageSwitchInSettingsKeepsTheSavedLesson() {
        let app = app()
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        // A language launch argument would pin the preference against the switch, so
        // the saved preference is set to English through Settings first.
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["GT_DEMO_SETTINGS"] = "1"
        app.launch()
        chooseLanguage("english", in: app)
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment["GT_DEMO_SETTINGS"] = nil
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u2-potOdds"
        app.launch()
        XCTAssertTrue(app.firstLessonChoice.waitForExistence(timeout: 15))
        app.buttons["Close"].firstMatch.tap()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertFalse(app.buttons["language-menu"].exists)
        chooseLanguage("korean", in: app)
        XCTAssertTrue(app.tabBars.buttons["설정"].isSelected)
        app.tabBars.buttons["배우기"].tap()
        app.buttons["레슨 이어서 하기"].tap()
        XCTAssertTrue(app.firstLessonChoice.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1/3"].exists)
        app.buttons["닫기"].firstMatch.tap()
        app.tabBars.buttons["설정"].tap()
        chooseLanguage("english", in: app)
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Learn"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Learn"].tap()
        app.buttons["Resume lesson"].tap()
        XCTAssertTrue(app.firstLessonChoice.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1/3"].exists)
    }

    func testLearningPathAndHeadsUpExerciseKeepBackNavigation() {
        let app = app()
        app.launch()
        let path = app.buttons["learn-path"]
        XCTAssertTrue(path.waitForExistence(timeout: 15))
        path.tap()
        XCTAssertTrue(app.staticTexts["All lessons"].waitForExistence(timeout: 5))
        let pathBack = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(pathBack.isHittable)
        pathBack.tap()
        XCTAssertTrue(path.waitForExistence(timeout: 5))

        app.tabBars.buttons["Play"].tap()
        let headsUp = app.buttons["play-graded"]
        XCTAssertTrue(headsUp.waitForExistence(timeout: 5))
        headsUp.tap()
        let tableBack = app.buttons["Back to Play"]
        XCTAssertTrue(tableBack.waitForExistence(timeout: 5))
        XCTAssertTrue(tableBack.isHittable)
        tableBack.tap()
        XCTAssertTrue(headsUp.waitForExistence(timeout: 5))
    }

    func testSettingsLastRowAndOtherTabsStayReachableAtAccessibilityXXXL() { settingsLastRow(code: "en") }
    func testSettingsKOLastRowAndOtherTabsStayReachableAtAccessibilityXXXL() { settingsLastRow(code: "ko") }

    private func settingsLastRow(code: String) {
        let app = app()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let tabs = app.tabBars.buttons
        let titles = code == "ko" ? ["배우기", "플레이", "기록", "설정"] : ["Learn", "Play", "Progress", "Settings"]
        XCTAssertTrue(tabs[titles[3]].waitForExistence(timeout: 15))
        tabs[titles[3]].tap()
        let version = app.staticTexts[code == "ko" ? "버전" : "Version"]
        XCTAssertTrue(version.waitForExistence(timeout: 10))
        let values = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", #"[0-9]+(?:\.[0-9]+)* \([0-9]+\)"#))
        XCTAssertEqual(values.count, 1, "The displayed app version and build value")
        let value = values.firstMatch
        var visible = false
        for _ in 0..<40 {
            let scroll = app.scrollViews.firstMatch.frame
            let top = max(scroll.minY, app.frame.minY + 60)
            let bottom = app.tabBars.firstMatch.frame.minY
            if min(version.frame.minY, value.frame.minY) >= top, max(version.frame.maxY, value.frame.maxY) <= bottom, version.isHittable { visible = true; break }
            print("Version traversal \(code): label=\(version.frame), value=\(value.frame), viewport=\(top)...\(bottom)")
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 25, dy: app.frame.midY))
            start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -min(220, max(40, max(version.frame.maxY, value.frame.maxY) - bottom)))), withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        XCTAssertTrue(visible, "Version frame=\(version.frame), tabbar=\(app.tabBars.firstMatch.frame)")
        print("Version full bounds \(code): frame=\(version.frame), value=\(value.label) \(value.frame), scroll=\(app.scrollViews.firstMatch.frame), tabbar=\(app.tabBars.firstMatch.frame)")
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "settings-version-full-AX5-\(code)"; capture.lifetime = .keepAlways; add(capture)
        for title in titles {
            let tab = tabs[title]
            XCTAssertTrue(tab.isHittable); tab.tap(); XCTAssertTrue(tab.isSelected)
        }
    }

    func testCommittedAdvancedLessonResumesTheSameAnswer() {
        let app = app()
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u2-potOdds"
        app.launch()
        let submit = app.firstLessonChoice
        XCTAssertTrue(submit.waitForExistence(timeout: 15))
        submit.tap()
        // In-session the live reveal stays; the saved answer is drawn after a relaunch.
        let live = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "drill-completion-potOdds/"
        )).firstMatch
        XCTAssertTrue(live.waitForExistence(timeout: 5))
        let answerID = live.identifier.replacingOccurrences(of: "drill-completion-", with: "saved-answer-")
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        XCTAssertTrue(app.buttons["Resume lesson"].waitForExistence(timeout: 15))
        app.buttons["Resume lesson"].tap()
        XCTAssertTrue(app.staticTexts[answerID].waitForExistence(timeout: 5))
        let next = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch
        scrollTo(next, in: app)
        next.tap()
        XCTAssertTrue(app.staticTexts["2/3"].waitForExistence(timeout: 5))
    }

    func testGradedRevealSheetIsTintedByItsVerdict() {
        let app = app()
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        app.launchEnvironment["GT_DEMO_NODE"] = "u2-potOdds"
        app.launch()
        let submit = app.firstLessonChoice
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

    func testPlayGradeNamesTheChoiceAndItsReferenceBelowTheHand() {
        let app = app()
        app.launchEnvironment["GT_DEMO_TABLE"] = "tag"
        app.launchEnvironment["GT_DEMO_TABLE_STEP"] = "2"
        app.launch()
        let verdict = app.descendants(matching: .any)["table-verdict"].firstMatch
        XCTAssertTrue(verdict.waitForExistence(timeout: 15))
        XCTAssertTrue(verdict.label.contains("Your choice:"), verdict.label)
        XCTAssertTrue(verdict.label.contains("Model choice:") || verdict.label.contains("Chart · vs "),
                      verdict.label)
        XCTAssertTrue(app.descendants(matching: .any)["table-takeaway"].firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["table-decision-details"].firstMatch.exists)
        let hero = app.otherElements["table-hero-cards"]
        XCTAssertLessThanOrEqual(hero.frame.maxY, verdict.frame.minY,
                                 "The answer panel must leave the hero cards uncovered")
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
        let selection = app.staticTexts["chart-explorer-selection"]
        XCTAssertTrue(selection.label.contains("My hand 76o"))
        let back = app.buttons["Back to my hand"]
        XCTAssertFalse(back.exists, "The return button appears only while another hand is inspected")
        app.buttons["chart-cell-77"].tap()
        XCTAssertTrue(selection.label.contains("Looking at 77"))
        XCTAssertTrue(own.label.hasPrefix("Your hand"))
        back.tap()
        XCTAssertTrue(selection.label.contains("My hand 76o"))
        XCTAssertTrue(own.isHittable)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "chart-explorer-english-ax5"; capture.lifetime = .keepAlways
        add(capture)
    }

    func testQuestionDraftSurvivesRelaunchWithoutAnAnswer() {
        let app = app()
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        app.launchEnvironment["GT_DEMO_SEED"] = "1"
        // Typed entry, the only input with a draft, is the top level's.
        app.launchEnvironment["GT_DEMO_LEVEL"] = "playRegularly"
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
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_LEVEL": "playRegularly"]
        app.launch()
        XCTAssertTrue(app.buttons["Resume lesson"].waitForExistence(timeout: 15))
        app.buttons["Resume lesson"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "43")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "saved-answer-")).firstMatch.exists)
    }

    func testQuickGameIsTheDefaultAndEndsAfterTenHands() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        app.buttons["play-free"].tap()
        XCTAssertTrue(app.buttons["game-length-quick"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game-length-quick"].isSelected)
        XCTAssertEqual(app.staticTexts["game-length-detail"].label,
                       "40 chips each · ends after 10 hands or when you run out · blinds 1 and 2 chips")
        app.buttons["game-length-long"].tap()
        XCTAssertEqual(app.staticTexts["game-length-detail"].label,
                       "100 chips each · plays on · blinds 1 and 2 chips")
        app.buttons["game-length-quick"].tap()
        app.buttons["2 players"].tap()
        app.buttons["table-start"].tap()
        closeTableGuide(in: app)
        XCTAssertTrue(app.staticTexts["Two players · Hand 1 of 10"].waitForExistence(timeout: 10))

        let next = app.buttons["free-next-hand"]
        let done = app.buttons["free-new-game"]
        let deadline = Date().addingTimeInterval(240)
        while !done.exists, Date() < deadline {
            if !tapFirstReady(["free-next-hand", "free-fold", "free-check"], in: app) {
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            }
        }
        XCTAssertTrue(done.exists, "The quick game ends by itself")
        XCTAssertFalse(next.exists)
        XCTAssertFalse(app.buttons["free-change-table"].exists)
        let line = app.staticTexts["free-game-over"]
        XCTAssertTrue(line.exists)
        XCTAssertTrue(line.label.hasPrefix("You finished "), line.label)
        XCTAssertTrue(line.label.contains(" of 2 with "), line.label)
        done.tap()
        XCTAssertTrue(app.buttons["table-start"].waitForExistence(timeout: 5), "A new game returns to setup")
    }

    /// Reads the screen once and taps by position, so a control that leaves while
    /// the computers act cannot fail the query between two looks.
    private func tapFirstReady(_ ids: [String], in app: XCUIApplication) -> Bool {
        guard let root = try? app.snapshot() else { return false }
        var ready: [String: CGRect] = [:]
        var pending: [XCUIElementSnapshot] = [root]
        while let node = pending.popLast() {
            if node.elementType == .button, node.isEnabled, !node.frame.isEmpty, ids.contains(node.identifier) {
                ready[node.identifier] = node.frame
            }
            pending.append(contentsOf: node.children)
        }
        guard let frame = ids.compactMap({ ready[$0] }).first else { return false }
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
        return true
    }

    /// First-use Rules explain the table once and can be reopened manually.
    func testFirstTableExplainsItselfOnceAndDoesNotRepeat() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Play"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Play"].tap()
        app.buttons["play-free"].tap()
        XCTAssertTrue(app.buttons["table-start"].waitForExistence(timeout: 5))
        app.buttons["table-start"].tap()
        let close = app.buttons["free-table-back-close"]
        XCTAssertTrue(app.staticTexts["Your cards"].waitForExistence(timeout: 10))
        let guide = app.scrollViews["free-back-content"]
        let firstUse = XCTAttachment(screenshot: app.screenshot())
        firstUse.name = "actual-first-use-Rules-clipped"
        firstUse.lifetime = .keepAlways
        add(firstUse)
        for title in ["Your cards", "Opponents' cards", "Shared cards", "The pot",
                      "Whose turn", "What each action costs"] {
            let item = app.staticTexts[title]
            for _ in 0..<12 where !item.isHittable { guide.swipeUp() }
            XCTAssertTrue(item.exists, title)
        }
        close.tap()
        let table = app.descendants(matching: .any)["practice-table"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["play-table-guide"].exists)
        XCTAssertFalse(app.staticTexts["Your cards"].exists)

        app.terminate()
        app.launchEnvironment["GT_DEMO_TAB"] = "play"
        app.launch()
        // Play opens on its landing; the table in progress is one tap away.
        let resume = app.buttons["play-free"]
        XCTAssertTrue(resume.waitForExistence(timeout: 15))
        XCTAssertTrue(resume.label.hasPrefix("Continue the free table"), resume.label)
        resume.tap()
        XCTAssertTrue(table.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Your cards"].exists, "The guide shows only once")
        XCTAssertFalse(app.buttons["play-table-guide"].exists)
        app.buttons["free-table-help"].tap()
        XCTAssertTrue(app.buttons["free-back-rules"].waitForExistence(timeout: 5))
        app.buttons["free-back-rules"].tap()
        XCTAssertTrue(app.staticTexts["Your cards"].waitForExistence(timeout: 5))
        app.buttons["free-table-back-close"].tap()
        XCTAssertTrue(table.waitForExistence(timeout: 5))

    }

    /// The free table replays the computers' moves before the turn comes back, so the
    /// buttons open a moment after the screen appears.
    private func waitForYourTurnOrResult(in app: XCUIApplication) {
        let status = app.descendants(matching: .any)["free-table-status"]
        let next = app.buttons["free-next-hand"]
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            if next.exists || (status.exists && status.label.hasPrefix("Your turn")) { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail("Neither the learner's turn nor the result appeared: \(status.label)")
    }

    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 20) {
        let enabled = expectation(for: NSPredicate(format: "exists == true AND isEnabled == true"),
                                  evaluatedWith: element)
        wait(for: [enabled], timeout: timeout)
    }

    private func closeTableGuide(in app: XCUIApplication) {
        let close = app.buttons["free-table-back-close"]
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
        let fold = app.buttons["free-fold"]
        waitUntilEnabled(fold)
        fold.tap()
        let next = app.buttons["free-next-hand"]
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["free-review"].exists)
        next.tap()
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_TAB": "play"]
        app.launch()
        let resume = app.buttons["play-free"]
        XCTAssertTrue(resume.waitForExistence(timeout: 15))
        XCTAssertTrue(resume.label.contains("hand 2"), resume.label)
        resume.tap()
        XCTAssertTrue(app.staticTexts["Four players · Hand 2"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["practice-table"].exists)
    }

    /// Play uses the shared table: opponents hold face-down cards, the learner's cards
    /// are face up, and the known pot sits in the middle.
    func testPracticeTableHidesOpponentCardsAndShowsThePot() {
        let app = app()
        app.launchEnvironment["GT_DEMO_PRACTICE"] = "1"
        app.launchEnvironment["GT_DEMO_TAB"] = "play"
        app.launch()
        waitUntilEnabled(app.buttons["free-fold"])
        let table = app.descendants(matching: .any)["practice-table"]
        for seat in 1...3 {
            let label = table.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@", ["Tom", "Mike", "Alex"][seat - 1] + ",")).firstMatch
            XCTAssertTrue(label.exists, "Seat \(seat) is named")
            XCTAssertTrue(label.label.contains("2 face-down cards"), label.label)
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
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == %@", "Call or fold?")).firstMatch.waitForExistence(timeout: 15))
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
        let question = app.staticTexts["At showdown, what percentage is your wins plus your share of ties?"]
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "lesson-estimate-choice-")).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 15))
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
