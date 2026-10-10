// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class LearningFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLessonTeachesThenTransfersBeforeOpeningTheCourse() {
        let app = firstLessonApp()
        app.launch()

        func tap(_ id: String) {
            let element = app.buttons[id]
            XCTAssertTrue(element.waitForExistence(timeout: 15), id)
            for _ in 0..<20 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable, id)
            element.tap()
        }
        XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 15))
        tap("firstLesson.start")
        XCTAssertTrue(app.staticTexts["firstLesson.teachPair.heading"].waitForExistence(timeout: 5))
        tap("firstLesson.next")
        for index in 1...5 {
            XCTAssertTrue(app.staticTexts["비교 \(index)/5"].waitForExistence(timeout: 5))
            tap("firstLesson.choice.0")
            XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].waitForExistence(timeout: 5))
            tap("firstLesson.next")
            if index == 2 {
                XCTAssertFalse(app.buttons["firstLesson.finish"].exists)
                tap("firstLesson.continueGuide")
            }
        }
        tap("firstLesson.next")
        tap("firstLesson.moreRules")
        for title in ["포커는 팟을 가져가는 게임이에요", "블라인드를 내고 카드 2장을 받아요",
                      "카드가 나올 때마다 베팅해요", "7장 중 가장 좋은 5장만 세요"] {
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), title)
            tap("firstLesson.next")
        }
        XCTAssertEqual(app.buttons["firstLesson.finish"].label, "족보 보기")
        tap("firstLesson.finish")

        // The hand-ranks lesson comes before the course's first node.
        XCTAssertTrue(app.descendants(matching: .any)["basics.rank.pair"].waitForExistence(timeout: 10))
        let royal = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "1, 로열 플러시,"
        )).firstMatch
        XCTAssertFalse(royal.exists)
        let ranks = app.buttons["basics.rank-order"]
        revealLearning(ranks, in: app)
        ranks.tap()
        revealLearning(royal, in: app)
        let basicsNext = app.buttons["basics.next"]
        XCTAssertTrue(basicsNext.waitForExistence(timeout: 5))
        XCTAssertTrue(basicsNext.isHittable)
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(basicsNext.frame.minY, window.minY + 60)
        XCTAssertLessThanOrEqual(basicsNext.frame.maxY, window.maxY - 20)
        print("BASICS_FIXED_FOOTER: \(basicsNext.frame), window=\(window)")
        basicsNext.tap()
        app.buttons["basics.choice.straight"].tap()
        let basicsVerdict = app.descendants(matching: .any)["basics.verdict"]
        XCTAssertTrue(basicsVerdict.waitForExistence(timeout: 5))
        XCTAssertTrue(basicsVerdict.label.contains("플러시가 이겨요"))
        app.buttons["basics.finish"].tap()
        XCTAssertTrue(app.buttons["guided-hand-invitation-continue"].waitForExistence(timeout: 10))
        app.buttons["guided-hand-invitation-continue"].tap()

        let firstStep = app.descendants(matching: .any)["walkthrough-step-0"]
        XCTAssertTrue(firstStep.waitForExistence(timeout: 10))
        XCTAssertTrue(firstStep.label.contains("누가 이길까요?"))
    }

    func testLearnSuggestsBasicsUntilFinishedAndClosingKeepsIt() {
        let app = firstLessonApp()
        app.launch()
        XCTAssertTrue(app.buttons["안내 건너뛰기"].waitForExistence(timeout: 15))
        app.buttons["안내 건너뛰기"].tap()

        let start = app.buttons["learn-basics-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        XCTAssertTrue(app.staticTexts["한 쌍은 높은 카드보다 강해요"].waitForExistence(timeout: 5))
        app.buttons["basics.close"].tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Closing early must not mark the lesson finished.")
    }

    func testFirstLessonMarksAWrongPickAndTheRightAnswer() {
        let app = firstLessonApp()
        app.launch()
        XCTAssertTrue(app.buttons["시작하기"].waitForExistence(timeout: 15))
        startWarmUp(in: app)
        XCTAssertTrue(firstButton(prefix: "상대 카드", in: app).waitForExistence(timeout: 5))
        firstButton(prefix: "상대 카드", in: app).tap()

        let verdict = app.descendants(matching: .any)["firstLesson.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertTrue(verdict.label.contains("다시"))
        XCTAssertTrue(firstElement(prefix: "상대 카드", in: app).label.contains("선택한 답, 틀렸어요"))
        XCTAssertTrue(firstElement(prefix: "내 카드", in: app).label.contains("정답"))
    }

    func testSkippingFirstLessonDoesNotShowItAgain() {
        let app = firstLessonApp()
        let environment = app.launchEnvironment
        app.launch()
        XCTAssertTrue(app.buttons["안내 건너뛰기"].waitForExistence(timeout: 15))
        app.buttons["안내 건너뛰기"].tap()
        XCTAssertTrue(app.tabBars.buttons["설정"].waitForExistence(timeout: 10))

        app.terminate()
        app.launchEnvironment = environment
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["설정"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["어느 쪽이 이길까요?"].exists)
    }

    func testFirstLessonCanBeOpenedAndClosedFromSettings() {
        let app = firstLessonApp()
        app.launch()
        XCTAssertTrue(app.buttons["안내 건너뛰기"].waitForExistence(timeout: 15))
        app.buttons["안내 건너뛰기"].tap()
        app.tabBars.buttons["설정"].tap()
        let replay = app.buttons.matching(NSPredicate(
            format: "label CONTAINS %@", "첫 포커 결정 다시 보기"
        )).firstMatch
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()
        XCTAssertTrue(app.staticTexts["Glass Table에 오신 걸 환영해요"].waitForExistence(timeout: 5))
        app.buttons["firstLesson.close"].tap()
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
    }

    func testInterruptedFirstLessonRestartsWithoutRecordingAnAnswer() {
        let app = firstLessonApp()
        let environment = app.launchEnvironment
        app.launch()
        XCTAssertTrue(app.buttons["시작하기"].waitForExistence(timeout: 15))
        startWarmUp(in: app)
        XCTAssertTrue(firstButton(prefix: "내 카드", in: app).waitForExistence(timeout: 5))
        firstButton(prefix: "내 카드", in: app).tap()
        XCTAssertTrue(app.descendants(matching: .any)["firstLesson.verdict"].waitForExistence(timeout: 5))
        app.terminate()

        app.launchEnvironment = environment
        app.launch()
        XCTAssertTrue(app.staticTexts["Glass Table에 오신 걸 환영해요"].waitForExistence(timeout: 10))
        app.buttons["안내 건너뛰기"].tap()
        app.tabBars.buttons["기록"].tap()
        app.buttons["records-details"].tap()
        let empty = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "아직 기록이 없어요")).firstMatch
        for _ in 0..<12 where !empty.exists { app.swipeUp() }
        XCTAssertTrue(empty.waitForExistence(timeout: 10))
    }

    func testGuideRequiresRetrievalBeforeExplanation() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_DEMO_SETTINGS": "1", "GT_DEMO_GUIDE": "1",
                                 "GT_DEMO_GUIDE_PAGE": "1"]
        app.launch()
        let answer = app.buttons["네, 보드만 쓸 수도 있어요"]
        XCTAssertTrue(answer.waitForExistence(timeout: 15))
        let next = app.buttons["다음 이야기"]
        XCTAssertFalse(next.isEnabled)
        answer.tap()
        XCTAssertTrue(app.staticTexts["맞아요"].waitForExistence(timeout: 3))
        XCTAssertTrue(next.isEnabled)
        next.tap()
        XCTAssertTrue(app.staticTexts["족보는 위에서부터 강해요"].waitForExistence(timeout: 3))
    }

    /// A sheet would close on a downward swipe and leave the tabs peeking above it;
    /// every activity entry is full screen and leaves only through its Close control.
    func testActivitiesOpenFullScreenAndCloseOnlyFromClose() {
        for entry in [["GT_DEMO_NODE": "u2-potOdds"], ["GT_DEMO_FREEPLAY": "1"], ["GT_DEMO_REVIEW": "1"]] {
            let app = XCUIApplication()
            app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
            app.launchEnvironment = entry.merging(["GT_TEST_STORE_ID": UUID().uuidString,
                                                   "GT_TEST_FIRST_LESSON": "0"]) { current, _ in current }
            app.launch()
            let close = app.buttons["닫기"]
            XCTAssertTrue(close.waitForExistence(timeout: 15), "\(entry)")
            let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
            top.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
            XCTAssertTrue(close.waitForExistence(timeout: 3) && close.isHittable,
                          "A downward swipe must not dismiss \(entry)")
            XCTAssertFalse(app.tabBars.buttons["배우기"].isHittable, "\(entry) must cover the tabs")
            close.tap()
            XCTAssertTrue(app.tabBars.buttons["배우기"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.tabBars.buttons["배우기"].isHittable, "\(entry) must close from Close")
            app.terminate()
        }
    }

    func testIndependentLessonReachesSummaryAfterThreeAnswers() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_DEMO_SEED": "1", "GT_DEMO_NODE": "u2-potOdds"]
        app.launch()
        for number in 1...3 {
            XCTAssertTrue(app.staticTexts["\(number)/3"].waitForExistence(timeout: 10))
            let submit = app.buttons["확인"]
            XCTAssertTrue(submit.waitForExistence(timeout: 5))
            submit.tap()
            let next = app.buttons["다음 문제"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            next.tap()
        }
        XCTAssertTrue(app.buttons["완료"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["다음 문제"].exists)
    }

    func testPotMathTableRequiresTheFullReplayThenRevealsOptionalArithmetic() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question",
                                 "GT_DEMO_POT_PLAYERS": "4"]
        app.launch()

        let table = app.descendants(matching: .any)["pot-table-replay"]
        XCTAssertTrue(table.waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS %@", "플레이어 A"
        )).firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS %@", "플레이어 B"
        )).firstMatch.exists)
        app.buttons["이전 행동"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS %@", "총"
        )).firstMatch.exists,
                      "The active seat should distinguish a raise target from chips added now.")
        let choices = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        ))
        XCTAssertEqual(choices.count, 3)
        XCTAssertFalse(choices.firstMatch.isEnabled)
        XCTAssertTrue(app.staticTexts["마지막 행동까지 넘기면 답을 고를 수 있어요."].exists)
        app.buttons["다음 행동"].tap()
        XCTAssertTrue(choices.firstMatch.isEnabled)
        choices.firstMatch.tap()

        let calculation = app.buttons["계산 보기"]
        XCTAssertTrue(calculation.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "블라인드: 1 + 2"
        )).firstMatch.exists)
        calculation.tap()

        let arithmetic = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@",
            "블라인드: 1 + 2 = 3칩", "플레이어 A 레이즈:"
        )).firstMatch
        XCTAssertTrue(arithmetic.waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "pot-math-stepwise-reveal"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))
    }

    func testPotMathFirstEntryExplainsWhyHowAndBlindRoles() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "intro",
                                 "GT_DEMO_POT_PLAYERS": "3"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["pot-math-intro"]
            .waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["왜 배우나요?"].exists)
        XCTAssertTrue(app.staticTexts["어떻게 푸나요?"].exists)
        XCTAssertTrue(app.staticTexts["SB와 BB"].exists)
        app.buttons["문제 풀기"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["pot-table-replay"]
            .waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        )).firstMatch.isEnabled,
                       "The first entry begins at the blind posts instead of exposing the final state.")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS %@", "1칩 먼저 내요"
        )).firstMatch.exists)
    }

    func testPotMathAX5CanReachChoiceRevealAndNextAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question",
                                 "GT_DEMO_POT_PLAYERS": "4"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["pot-table-replay"]
            .waitForExistence(timeout: 15))
        let choice = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        )).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        for _ in 0..<8 where !choice.isHittable { app.swipeUp() }
        XCTAssertTrue(choice.isHittable, "AX5 must be able to scroll from the full seat list to an answer.")
        choice.tap()

        let calculation = app.buttons["계산 보기"]
        for _ in 0..<8 where !calculation.isHittable { app.swipeUp() }
        XCTAssertTrue(calculation.isHittable)
        calculation.tap()
        let next = app.buttons["다음 문제"]
        for _ in 0..<8 where !next.isHittable { app.swipeUp() }
        XCTAssertTrue(next.isHittable, "The expanded arithmetic must not trap the next action below the viewport.")
    }

    /// Pot-math choices live in the bottom answer sheet, below the replay, like every
    /// other question.
    func testPotMathChoicesSitInTheBottomSheet() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question"]
        app.launch()
        let sheet = app.descendants(matching: .any)["answer-sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 15))
        let choice = sheet.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        )).firstMatch
        XCTAssertTrue(choice.exists, "Choices belong to the answer sheet")
        XCTAssertTrue(choice.isHittable)
        XCTAssertGreaterThan(choice.frame.minY, app.windows.firstMatch.frame.height * 0.6)
    }

    /// The answer sheet ends where the system's sheets do: on iOS 26 it floats just above
    /// the screen's bottom edge, with no dead band between the last choice and the home
    /// indicator.
    func testAnswerSheetLeavesNoDeadBandUnderTheLastChoice() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Pre-26 sheets stay attached") }
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question"]
        app.launch()
        let sheet = app.descendants(matching: .any)["answer-sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 15))
        let choices = sheet.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        )).allElementsBoundByIndex
        let lastChoiceBottom = try XCTUnwrap(choices.map(\.frame.maxY).max())
        let screenBottom = app.windows.firstMatch.frame.maxY
        XCTAssertLessThanOrEqual(screenBottom - lastChoiceBottom, 40,
                                 "A floating sheet keeps 8 pt margin + 20 pt padding under its content")
    }

    func testLessonTitleStartsJustUnderTheCloseChevronOnTheContentEdge() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question"]
        app.launch()
        let title = app.staticTexts["팟에 든 칩 세기"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        let close = app.buttons["닫기"].firstMatch
        XCTAssertTrue(close.exists)
        // The 44 pt target reaches 12 pt past the edge the glyph and the title share.
        XCTAssertEqual(title.frame.minX - close.frame.minX, 12, accuracy: 2,
                       "The chevron glyph lines up with the title's left edge")
        XCTAssertLessThanOrEqual(title.frame.minY - close.frame.minY, 40,
                                 "The title starts just under the chevron, not under a 44 pt bar")
    }

    func testPotMathKeepsItsInstructionAndHeightAtTheLastAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question"]
        app.launch()
        let sheet = app.descendants(matching: .any)["answer-sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 15))
        let height = sheet.frame.height
        let next = app.buttons["다음 행동"]
        for _ in 0..<12 where next.exists && next.isEnabled { next.tap() }
        XCTAssertFalse(next.exists && next.isEnabled, "Stepped to the last action")
        XCTAssertTrue(app.staticTexts["이제 답을 고를 수 있어요."].exists,
                      "The instruction line unlocks in place at the last action")
        XCTAssertEqual(sheet.frame.height, height, accuracy: 1)
    }

    func testHintPopoverFitsItsTextAndHasOneWayOut() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_NODE": "u1-showdown",
                                 "GT_DEMO_STAGE": "together"]
        app.launch()
        let hint = app.buttons["힌트"]
        XCTAssertTrue(hint.waitForExistence(timeout: 15))
        hint.tap()
        let surface = app.descendants(matching: .any)["guided-hint"].firstMatch
        let cue = app.descendants(matching: .any)["guided-hint-cue"].firstMatch
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertTrue(surface.exists)
        XCTAssertGreaterThanOrEqual(cue.frame.minY, surface.frame.minY)
        XCTAssertLessThanOrEqual(cue.frame.maxY, surface.frame.maxY)
        XCTAssertFalse(app.buttons["문제로 돌아가기"].exists, "The X is the only close control")
        let close = app.buttons["힌트 닫기"]
        XCTAssertEqual(app.buttons.matching(identifier: "힌트 닫기").count, 1)
        XCTAssertTrue(close.isHittable)
        XCTAssertGreaterThanOrEqual(close.frame.width, 44)
        XCTAssertGreaterThanOrEqual(close.frame.height, 44)
        print("Hint sheet cue=\(cue.frame), surface=\(surface.frame), close=\(close.frame)")
        attachLearning(app, name: "hint-native-sheet-text-and-close")
        close.tap()
        XCTAssertFalse(close.waitForExistence(timeout: 2))
        XCTAssertTrue(hint.isHittable)
    }

    func testOpponentDetailShowsItsPokerTermsWithoutADisclosure() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_TAB": "play", "GT_DEMO_PLAY_SETUP": "1",
                                 "GT_DEMO_OPPONENT": "tag"]
        app.launch()
        let terms = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "VPIP")).firstMatch
        XCTAssertTrue(terms.waitForExistence(timeout: 15), "VPIP and PFR are on screen without a tap")
        XCTAssertTrue(app.buttons["스타일 목록"].exists, "Pushed from the style list, the leading edge steps back")
    }

    func testPotMathChoiceCommitsExactlyOnceBeforeNext() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        let storeID = UUID().uuidString
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question"]
        app.launch()
        let choice = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        )).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 15))
        choice.tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_TAB": "records"]
        app.launch()
        app.buttons["records-details"].tap()
        let record = recordedLearningRow("팟에 든 칩 세기", in: app)
        XCTAssertTrue(record.label.contains("17문제"), record.label)
        print("POT_MATH_PERSISTED_RECORD: \(record.label)")
    }

    /// Numeric seat totals require explicit consent; the restored answer stays recorded.
    func testPotTotalsHelpAsksFirstAndMarksTheAnswer() {
        let app = XCUIApplication()
        let arguments = ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchArguments += arguments
        let environment = ["GT_TEST_STORE_ID": UUID().uuidString,
                           "GT_DEMO_SEED": "1",
                           "GT_DEMO_NODE": "u1-potMath",
                           "GT_DEMO_POT_STATE": "question"]
        app.launchEnvironment = environment
        app.launch()
        let genericPaidMentions = app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS %@", "낸 칩"
        )).allElementsBoundByIndex.map(\.label)
        print("POT_INITIAL_PAID_MENTIONS: \(genericPaidMentions)")
        let paid = app.descendants(matching: .any).matching(NSPredicate(
            format: "label MATCHES %@", ".*낸 칩 [0-9]+.*"
        )).firstMatch
        let showTotals = app.buttons["pot-show-totals"]
        XCTAssertTrue(showTotals.waitForExistence(timeout: 15))
        XCTAssertFalse(paid.exists)

        showTotals.tap()
        let alert = app.alerts["합계를 볼까요?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["직접 세기"].tap()
        XCTAssertFalse(paid.exists, "Declining keeps the totals hidden")

        showTotals.tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["합계 보기"].tap()
        XCTAssertTrue(paid.waitForExistence(timeout: 5))
        XCTAssertFalse(showTotals.exists)

        let choice = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        )).firstMatch
        choice.tap()
        XCTAssertFalse(app.descendants(matching: .any)["solved-with-help"].exists)
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = arguments
        app.launchEnvironment = ["GT_TEST_STORE_ID": environment["GT_TEST_STORE_ID"]!,
                                 "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        let resume = app.buttons["레슨 이어서 하기"]
        XCTAssertTrue(resume.waitForExistence(timeout: 15))
        resume.tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.descendants(matching: .any)["solved-with-help"].exists,
                       "A restored answer keeps its factual feedback without public help categorization")
    }

    /// Every graded question can reopen its skill's explanation, with the approved
    /// position rule and a worked example on a different spot.
    func testGradedQuestionReopensTheExplanationAndAnExample() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-position"]
        app.launch()
        let explain = app.buttons["drill-explain"]
        XCTAssertTrue(explain.waitForExistence(timeout: 15))
        explain.tap()
        XCTAssertTrue(app.staticTexts["누가 먼저 행동할까요?"].waitForExistence(timeout: 5))
        let rule = app.descendants(matching: .any)["explain-rule-example"]
        XCTAssertTrue(rule.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "공용 카드 전에는 BB가 마지막이에요."
        )).firstMatch.exists)
        let example = app.buttons["explain-example"]
        for _ in 0..<6 where !example.isHittable { app.swipeUp() }
        example.tap()
        XCTAssertTrue(app.descendants(matching: .any)["walkthrough-step-0"]
            .waitForExistence(timeout: 5))
    }

    /// At the largest text the one-row seat strip cannot grow, so the action order shown
    /// with the answer is written out as a sentence too.
    func testPositionAnswerSpellsOutTheActionOrderAtTheLargestText() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-position"]
        app.launch()
        let order = app.staticTexts["position-seat-sentence"]
        XCTAssertTrue(order.waitForExistence(timeout: 15))
        let choice = app.buttons.matching(NSPredicate(format: "label IN %@", ["0", "A"])).firstMatch
        for _ in 0..<6 where !choice.isHittable { app.swipeUp() }
        choice.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@ AND label CONTAINS %@",
            "position-seat-sentence", "UTG", "→"
        )).firstMatch.waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Changing the language mid-example returns to the same step, not the start.
    /// The saved preference can be either language from an earlier run, so the test
    /// switches to whichever one is not current.
    func testLanguageSwitchKeepsTheWorkedExampleStep() {
        let app = XCUIApplication()
        // No language launch argument: it would pin the preference against the switch.
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_NODE": "u1-showdown",
                                 "GT_DEMO_BEAT": "0"]
        app.launch()
        func button(_ ko: String, _ en: String) -> XCUIElement {
            app.buttons.matching(NSPredicate(format: "label IN %@", [ko, en])).firstMatch
        }
        XCTAssertTrue(app.descendants(matching: .any)["walkthrough-step-0"]
            .waitForExistence(timeout: 15))
        button("다음", "Next").tap()
        XCTAssertTrue(app.descendants(matching: .any)["walkthrough-step-1"]
            .waitForExistence(timeout: 5))
        // Relaunch without the demo hook, which would reopen step 0 on every appear.
        let storeID = app.launchEnvironment["GT_TEST_STORE_ID"]!
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        let tabs = app.tabBars.buttons
        XCTAssertTrue(tabs.element(boundBy: 3).waitForExistence(timeout: 15))
        tabs.element(boundBy: 3).tap()
        let wasKorean = tabs["설정"].exists
        let languagePicker = app.buttons["settings-language"]
        for _ in 0..<12 where !languagePicker.isHittable { app.swipeUp() }
        languagePicker.tap()
        app.buttons[wasKorean ? "language-english" : "language-korean"].tap()
        XCTAssertTrue(tabs[wasKorean ? "Learn" : "배우기"].waitForExistence(timeout: 5))
        tabs.element(boundBy: 0).tap()
        let resume = button("레슨 이어서 하기", "Resume lesson")
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        resume.tap()
        XCTAssertTrue(app.descendants(matching: .any)["walkthrough-step-1"]
            .waitForExistence(timeout: 5), "The example must not restart after a language change")

        // Leave the shared preference in English, where other suites expect it.
        if !wasKorean {
            button("닫기", "Close").tap()
            tabs.element(boundBy: 3).tap()
            for _ in 0..<12 where !languagePicker.isHittable { app.swipeUp() }
            languagePicker.tap()
            app.buttons["language-english"].tap()
            XCTAssertTrue(tabs["Learn"].waitForExistence(timeout: 5))
        }
    }

    func testDueReviewIsFiniteAndMovesBetweenConcepts() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_DEMO_SEED": "1", "GT_DEMO_REVIEW": "1"]
        app.launch()
        XCTAssertTrue(app.staticTexts["복습 1/2"].waitForExistence(timeout: 10))
        if app.buttons["답 입력"].exists {
            app.buttons["답 입력"].tap()
            app.buttons["숫자 0"].tap()
            app.buttons["입력 완료"].tap()
        }
        app.buttons["확인"].tap()
        let next = app.buttons["다음 문제"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()
        XCTAssertTrue(app.staticTexts["복습 2/2"].waitForExistence(timeout: 5))
        let positionChoice = app.buttons.matching(NSPredicate(
            format: "label IN %@", ["0", "UTG", "UTG+1", "MP", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
        )).firstMatch
        XCTAssertTrue(positionChoice.waitForExistence(timeout: 5))
        positionChoice.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()
        XCTAssertTrue(app.buttons["학습으로 돌아가기"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["복습 3/2"].exists)
    }

    func testHeadsUpExerciseKeepsPublishedPolicyAndChartGrading() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_DEMO_TABLE": "tag"]
        app.launch()
        XCTAssertTrue(app.buttons["table-fold"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "시작 패는 앱 차트와 비교해요"
        )).firstMatch.exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "필요 에퀴티"
        )).firstMatch.exists)
        let policy = app.buttons["table-policy"]
        XCTAssertTrue(policy.waitForExistence(timeout: 5))
        policy.tap()
        XCTAssertTrue(app.staticTexts["선별형 전략과 레인지"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["table-policy-range-summary"].exists)
        XCTAssertTrue(app.staticTexts["포스트플랍 기본 · 상대가 먼저 행동할 때"].exists)
        app.buttons["닫기"].tap()
        let fold = app.buttons["table-fold"]
        XCTAssertTrue(fold.waitForExistence(timeout: 10))
        fold.tap()
        XCTAssertTrue(app.descendants(matching: .any)["table-verdict"].waitForExistence(timeout: 5))
        app.buttons["table-continue"].tap()
        XCTAssertTrue(app.buttons["다음 핸드"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["table-review-decisions"].exists || app.descendants(matching: .any)["table-review-decisions"].exists)
        XCTAssertFalse(app.buttons["핸드 시작"].exists)
    }

    func testDefendRevealShowsTheSelectedHandBeforeTheFullChart() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_NODE": "u8-defend",
                                 "GT_DEMO_REVEAL": "1"]
        app.launch()

        let evidence = app.descendants(matching: .any)["defend-selected-evidence"]
        XCTAssertTrue(evidence.waitForExistence(timeout: 15))
        XCTAssertTrue(evidence.isHittable,
                      "The selected hand and action should lead the reveal at normal text size.")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "label IN %@", ["차트와 일치해요", "차트와 달라요"]
        )).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["근접"].exists,
                       "Chart adjacency may affect progression internally, but must not imply low EV cost.")
    }

    func testCountDrillRequiresAnIntentionalNumberIncludingZero() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_NODE": "u1-combos"]
        app.launch()

        let submit = app.buttons["확인"]
        XCTAssertTrue(submit.waitForExistence(timeout: 15))
        XCTAssertFalse(submit.isEnabled)
        XCTAssertFalse(app.staticTexts["8개"].exists)
        app.buttons["답 입력"].tap()
        app.buttons["숫자 1"].tap()
        app.buttons["숫자 2"].tap()
        XCTAssertTrue(app.staticTexts["12개"].exists)
        app.buttons["마지막 숫자 지우기"].tap()
        app.buttons["마지막 숫자 지우기"].tap()
        XCTAssertTrue(app.staticTexts["숫자를 입력하세요"].exists)
        app.buttons["숫자 0"].tap()
        app.buttons["입력 완료"].tap()
        XCTAssertTrue(app.buttons["확인"].isEnabled)
        submit.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "내 답 0개"
        )).firstMatch.waitForExistence(timeout: 5))
        app.buttons["다음 문제"].tap()
        XCTAssertTrue(app.buttons["답 입력"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["확인"].isEnabled)
    }

    func testOutsHeroCardsAreFullyVisibleBeforeOpeningNumberEntry() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_NODE": "u2-outs"]
        app.launch()

        let hero = app.descendants(matching: .any)["three-region-hero-cards"]
        let question = app.staticTexts["리버에 나를 이기게 해주는 카드는 몇 장인가요?"]
        XCTAssertTrue(hero.waitForExistence(timeout: 15))
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(hero.frame.maxY, question.frame.minY,
                                 "The collapsed number input must leave both hero cards fully above the action sheet.")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "outs-collapsed-count-entry-hero-cards-visible"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testPathOpensAtRequestedLateCurrentNode() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_TAB": "learn",
                                 "GT_TEST_FIRST_LESSON": "0",
                                 "GT_TEST_PATH_CURRENT_NODE": "u8-defend"]
        app.launch()

        let path = app.buttons["learn-path"]
        XCTAssertTrue(path.waitForExistence(timeout: 15))
        path.tap()
        let node = app.buttons["lesson-u8-defend"]
        XCTAssertTrue(node.waitForExistence(timeout: 15))
        XCTAssertTrue(node.isHittable,
                      "Opening the list should scroll to a late suggested lesson once.")
        for _ in 0..<10 { app.swipeDown() }
        XCTAssertTrue(app.staticTexts["전체 레슨"].isHittable)
        app.tabBars.buttons["플레이"].tap()
        app.tabBars.buttons["배우기"].tap()
        XCTAssertTrue(app.staticTexts["전체 레슨"].isHittable,
                      "Returning to the path must preserve the learner's scroll position instead of jumping again.")
    }

    func testExactAnswerSurvivesRelaunchBeforeNext() {
        verifyCommittedAnswer(node: "u2-potOdds", title: "콜하려면 얼마나 자주 이겨야 할까요?", submit: "확인")
    }

    func testIntervalAnswerSurvivesRelaunchBeforeNext() {
        verifyCommittedAnswer(node: "u2-equitySense", title: "끝까지 가면 이길 가능성", submit: "확인")
    }

    func testEVDecisionSurvivesRelaunchBeforeNext() {
        verifyCommittedAnswer(node: "u6-evLoss", title: "더 나은 선택과의 차이", submit: "폴드")
    }

    func testGuidedAnswerDoesNotCreateAssessedProgress() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        let storeID = UUID().uuidString
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_NODE": "u2-potOdds",
                                 "GT_DEMO_STAGE": "together"]
        app.launch()
        XCTAssertTrue(app.buttons["확인"].waitForExistence(timeout: 10))
        app.buttons["확인"].tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_TAB": "records"]
        app.launch()
        app.buttons["records-details"].tap()
        let empty = app.staticTexts["아직 기록이 없어요. 한 문제를 풀면 답변 수와 다음 복습 시점을 여기에서 확인할 수 있어요."]
        for _ in 0..<12 where !empty.exists { app.swipeUp() }
        XCTAssertTrue(empty.waitForExistence(timeout: 10))
    }

    func testNextDoesNotDoubleRecordAndNextQuestionStillCounts() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        let storeID = UUID().uuidString
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_NODE": "u2-potOdds"]
        app.launch()
        XCTAssertTrue(app.buttons["확인"].waitForExistence(timeout: 10))
        app.buttons["확인"].tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))
        app.buttons["다음 문제"].tap()
        XCTAssertTrue(app.staticTexts["2/3"].waitForExistence(timeout: 5))
        app.buttons["확인"].tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_TAB": "records"]
        app.launch()
        app.buttons["records-details"].tap()
        let record = recordedLearningRow("콜하려면 얼마나 자주 이겨야 할까요?", in: app)
        XCTAssertTrue(record.label.contains("2문제"), record.label)
        print("NEXT_PERSISTED_RECORD: \(record.label)")
        attachLearning(app, name: "next-persists-exactly-two-answers")
    }

    private func verifyCommittedAnswer(node: String, title: String, submit: String) {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        let storeID = UUID().uuidString
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_NODE": node]
        app.launch()
        let control = app.buttons[submit]
        XCTAssertTrue(control.waitForExistence(timeout: 15))
        control.tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 15))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_TAB": "records"]
        app.launch()
        let details = app.buttons["records-details"]
        revealLearning(details, in: app)
        details.tap()
        let recorded = recordedLearningRow(title, in: app)
        XCTAssertTrue(recorded.label.contains("1문제"), "The revealed answer must be saved before Next: \(recorded.label)")
        print("COMMITTED_PERSISTED_RECORD \(node): \(recorded.label)")
        attachLearning(app, name: "committed-before-next-\(node)")
    }

    private func recordedLearningRow(_ title: String, in app: XCUIApplication) -> XCUIElement {
        let row = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@", "\(title)."
        )).firstMatch
        revealLearning(row, in: app)
        print("RECORD_ROW: id=\(row.identifier), label=\(row.label), frame=\(row.frame)")
        return row
    }

    private func revealLearning(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        for _ in 0..<30 {
            let window = app.windows.firstMatch.frame
            let scroll = app.scrollViews.firstMatch.frame
            let top = max(window.minY + 60, scroll.minY)
            let bottom = min(window.maxY - 20,
                             app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame.minY : scroll.maxY)
            let frame = element.frame
            if frame.minY >= top - 0.5, frame.maxY <= bottom + 0.5, element.isHittable { return }
            let delta = max(-180, min(180, (top + bottom) / 2 - frame.midY))
            let start = app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: 25, dy: (top + bottom) / 2))
            start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)),
                        withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTFail("Could not reach \(element.label): \(element.frame)")
    }

    private func attachLearning(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The warm-up is the first task after the welcome.
    private func startWarmUp(in app: XCUIApplication) {
        app.buttons["시작하기"].tap()
        XCTAssertTrue(app.staticTexts["어느 쪽이 이길까요?"].waitForExistence(timeout: 5))
    }

    private func firstLessonApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "1"]
        return app
    }

    private func firstButton(prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func firstElement(prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }
}
