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
        XCTAssertTrue(app.staticTexts["쇼다운 · 천천히"].waitForExistence(timeout: 10))
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

    func testDueReviewIsFiniteAndMovesBetweenConcepts() {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_DEMO_SEED": "1", "GT_DEMO_REVIEW": "1"]
        app.launch()
        XCTAssertTrue(app.staticTexts["복습 1/2"].waitForExistence(timeout: 10))
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
        let fold = app.buttons["폴드, 0bb"]
        XCTAssertTrue(fold.waitForExistence(timeout: 10))
        fold.tap()
        XCTAssertTrue(app.buttons["다음 핸드"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "EV 손실은 측정하지 않았어요.")).firstMatch.exists)
        XCTAssertFalse(app.buttons["핸드 시작"].exists)
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
