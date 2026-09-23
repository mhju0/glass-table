// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class LearningFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLessonTeachesThenTransfersBeforeOpeningTheCourse() {
        let app = firstLessonApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["어느 쪽이 이길까요?"].waitForExistence(timeout: 15))
        firstButton(prefix: "내 카드", in: app).tap()
        XCTAssertTrue(app.staticTexts["맞았어요"].waitForExistence(timeout: 5))
        app.buttons["다른 카드로 풀어보기"].tap()
        XCTAssertTrue(app.staticTexts["같은 규칙으로 골라보세요"].waitForExistence(timeout: 5))
        firstButton(prefix: "상대 카드", in: app).tap()
        XCTAssertTrue(app.staticTexts["방금 배운 규칙을 다른 카드에도 적용했어요."].waitForExistence(timeout: 5))
        app.buttons["앱 둘러보기"].tap()
        XCTAssertTrue(app.staticTexts["이렇게 한 결정씩 배워요"].waitForExistence(timeout: 5))
        app.buttons["첫 레슨 시작"].tap()
        XCTAssertTrue(app.staticTexts["쇼다운 · 따라 배우기"].waitForExistence(timeout: 10))
    }

    func testSkippingFirstLessonDoesNotShowItAgain() {
        let app = firstLessonApp()
        let environment = app.launchEnvironment
        app.launch()
        XCTAssertTrue(app.buttons["건너뛰기"].waitForExistence(timeout: 15))
        app.buttons["건너뛰기"].tap()
        XCTAssertTrue(app.buttons["설정"].waitForExistence(timeout: 10))

        app.terminate()
        app.launchEnvironment = environment
        app.launch()
        XCTAssertTrue(app.buttons["설정"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["어느 쪽이 이길까요?"].exists)
    }

    func testFirstLessonCanBeOpenedAndClosedFromSettings() {
        let app = firstLessonApp()
        app.launch()
        XCTAssertTrue(app.buttons["건너뛰기"].waitForExistence(timeout: 15))
        app.buttons["건너뛰기"].tap()
        app.buttons["설정"].tap()
        let replay = app.buttons.matching(NSPredicate(
            format: "label CONTAINS %@", "첫 포커 결정 다시 보기"
        )).firstMatch
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()
        XCTAssertTrue(app.staticTexts["어느 쪽이 이길까요?"].waitForExistence(timeout: 5))
        app.buttons["firstLesson.close"].tap()
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
    }

    func testInterruptedFirstLessonRestartsWithoutRecordingAnAnswer() {
        let app = firstLessonApp()
        let environment = app.launchEnvironment
        app.launch()
        XCTAssertTrue(firstButton(prefix: "내 카드", in: app).waitForExistence(timeout: 15))
        firstButton(prefix: "내 카드", in: app).tap()
        XCTAssertTrue(app.staticTexts["맞았어요"].waitForExistence(timeout: 5))
        app.terminate()

        app.launchEnvironment = environment
        app.launch()
        XCTAssertTrue(app.staticTexts["어느 쪽이 이길까요?"].waitForExistence(timeout: 10))
        app.buttons["건너뛰기"].tap()
        app.tabBars.buttons["기록"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "아직 기록이 없어요"
        )).firstMatch.waitForExistence(timeout: 10))
    }

    func testGuideRequiresRetrievalBeforeExplanation() {
        let app = XCUIApplication()
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

    func testIndependentLessonReachesSummaryAfterFiveAnswers() {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_DEMO_SEED": "1", "GT_DEMO_NODE": "u2-potOdds"]
        app.launch()
        for number in 1...5 {
            XCTAssertTrue(app.staticTexts["\(number)/5"].waitForExistence(timeout: 10))
            let submit = app.buttons["확인"]
            XCTAssertTrue(submit.waitForExistence(timeout: 5))
            submit.tap()
            let next = app.buttons["다음 문제"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            next.tap()
        }
        XCTAssertTrue(app.buttons["길로 돌아가기"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["다음 문제"].exists)
    }

    func testPotMathTableRequiresTheFullReplayThenRevealsOptionalArithmetic() {
        let app = XCUIApplication()
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
        app.launchArguments = ["-UIPreferredContentSizeCategoryName",
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

    func testPotMathChoiceCommitsExactlyOnceBeforeNext() {
        let app = XCUIApplication()
        let storeID = UUID().uuidString
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID,
                                 "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-potMath",
                                 "GT_DEMO_POT_STATE": "question",
                                 "GT_DEMO_POT_PLAYERS": "3"]
        app.launch()
        let choice = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "pot-answer-"
        )).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 15))
        choice.tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = []
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_TAB": "records"]
        app.launch()
        let record = app.descendants(matching: .any).matching(NSPredicate(
            // GT_DEMO_SEED starts 팟 계산 at 16 answers. This committed choice must
            // add exactly one before Next, not reset the fixture or record twice.
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "팟 계산.", "17문제"
        )).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 10))
    }

    func testDueReviewIsFiniteAndMovesBetweenConcepts() {
        let app = XCUIApplication()
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
        XCTAssertTrue(app.buttons["오늘로 돌아가기"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["복습 3/2"].exists)
    }

    func testOpponentSelectionStartsAnAnswerableHand() {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_DEMO_TAB": "table"]
        app.launch()
        let tag = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "TAG")).firstMatch
        XCTAssertTrue(tag.waitForExistence(timeout: 10))
        tag.tap()
        let start = app.buttons["핸드 시작"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "프리플랍 판정은 디펜드 차트 기준"
        )).firstMatch.exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "필요 에퀴티"
        )).firstMatch.exists)
        let policy = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@", "상대 전략과 레인지 보기"
        )).firstMatch
        XCTAssertTrue(policy.waitForExistence(timeout: 5))
        policy.tap()
        XCTAssertTrue(app.navigationBars["TAG 전략과 레인지"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["table-policy-range-summary"].exists)
        XCTAssertTrue(app.staticTexts["포스트플랍 기본 · 상대가 먼저 행동할 때"].exists)
        app.buttons["닫기"].tap()
        let fold = app.buttons["폴드, 0bb"]
        XCTAssertTrue(fold.waitForExistence(timeout: 10))
        fold.tap()
        XCTAssertTrue(app.buttons["다음 핸드"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "EV 손실은 측정하지 않았어요.")).firstMatch.exists)
        XCTAssertFalse(app.buttons["핸드 시작"].exists)
    }

    func testDefendRevealShowsTheSelectedHandBeforeTheFullChart() {
        let app = XCUIApplication()
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
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_TAB": "path",
                                 "GT_TEST_PATH_CURRENT_NODE": "u8-defend"]
        app.launch()

        let node = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@", "디펜드 차트"
        )).firstMatch
        XCTAssertTrue(node.waitForExistence(timeout: 15))
        XCTAssertTrue(node.isHittable,
                      "Opening the path should expand and scroll to a late current lesson once.")
        for _ in 0..<10 { app.swipeDown() }
        XCTAssertTrue(app.staticTexts["배움의 길"].isHittable)
        app.tabBars.buttons["오늘"].tap()
        app.tabBars.buttons["길"].tap()
        XCTAssertTrue(app.staticTexts["배움의 길"].isHittable,
                      "Returning to the path must preserve the learner's scroll position instead of jumping again.")
    }

    func testExactAnswerSurvivesRelaunchBeforeNext() {
        verifyCommittedAnswer(node: "u2-potOdds", title: "팟 오즈", submit: "확인")
    }

    func testIntervalAnswerSurvivesRelaunchBeforeNext() {
        verifyCommittedAnswer(node: "u2-equitySense", title: "에퀴티 감각", submit: "확인")
    }

    func testEVDecisionSurvivesRelaunchBeforeNext() {
        verifyCommittedAnswer(node: "u6-evLoss", title: "EV 손실", submit: "폴드")
    }

    func testGuidedAnswerDoesNotCreateAssessedProgress() {
        let app = XCUIApplication()
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
        XCTAssertTrue(app.staticTexts["아직 기록이 없어요. 한 문제를 풀면 답변 수와 다음 복습 시점이 여기에 쌓여요."]
            .waitForExistence(timeout: 10))
    }

    func testNextDoesNotDoubleRecordAndNextQuestionStillCounts() {
        let app = XCUIApplication()
        let storeID = UUID().uuidString
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_NODE": "u2-potOdds"]
        app.launch()
        XCTAssertTrue(app.buttons["확인"].waitForExistence(timeout: 10))
        app.buttons["확인"].tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))
        app.buttons["다음 문제"].tap()
        XCTAssertTrue(app.staticTexts["2/5"].waitForExistence(timeout: 5))
        app.buttons["확인"].tap()
        XCTAssertTrue(app.buttons["다음 문제"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": storeID, "GT_DEMO_TAB": "records"]
        app.launch()
        let record = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "팟 오즈.", "2문제"
        )).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 10))
    }

    private func verifyCommittedAnswer(node: String, title: String, submit: String) {
        let app = XCUIApplication()
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
        let recorded = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", title + ".", "1문제"
        )).firstMatch
        XCTAssertTrue(recorded.waitForExistence(timeout: 10), "The revealed answer must be saved before Next.")
    }

    private func firstLessonApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "1"]
        return app
    }

    private func firstButton(prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }
}
