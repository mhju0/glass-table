// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class AccessibilityFlowTests: XCTestCase {
    private let accessibilityXXXL = [
        "-UIPreferredContentSizeCategoryName",
        "UICTContentSizeCategoryAccessibilityXXXL",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEquityAnswerCanBeSubmittedAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_SEED": "1",
            "GT_DEMO_NODE": "u2-equitySense",
        ])

        XCTAssertTrue(app.staticTexts["쇼다운까지 갔을 때 내가 이길 확률은?"]
            .waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["상대"].exists)

        let submit = app.buttons["확인"]
        XCTAssertTrue(scrollUntilHittable(submit, in: app),
                      "The full equity input and submit action must remain reachable at AX XXXL.")
        submit.tap()

        let next = app.buttons["다음 문제"]
        XCTAssertTrue(scrollUntilHittable(next, in: app),
                      "The equity reveal and its advance action must remain reachable at AX XXXL.")
    }

    func testShowdownWalkthroughAdvancesAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u1-showdown",
            "GT_DEMO_BEAT": "0",
        ])

        XCTAssertTrue(app.descendants(matching: .any)["7단계 중 1단계"]
            .waitForExistence(timeout: 15))

        for step in 1...7 {
            let title = step == 7 ? "이해했어요" : "다음"
            let advance = app.buttons[title]
            XCTAssertTrue(scrollUntilHittable(advance, in: app),
                          "Walkthrough step \(step) must expose its advance action at AX XXXL.")
            advance.tap()
        }

        XCTAssertTrue(app.staticTexts["함께 풀기"].waitForExistence(timeout: 10),
                      "Completing all seven beats should reach guided practice.")
    }

    func testTableFoldReachesSummaryAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
        ])

        let fold = app.buttons["폴드, 0bb"]
        XCTAssertTrue(scrollUntilHittable(fold, in: app),
                      "The preflop fold action must remain reachable below the table context at AX XXXL.")
        fold.tap()

        XCTAssertTrue(app.staticTexts["결과와 결정은 따로 봐요"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["프리플랍 결정은 공개된 디펜드 차트와 비교했어요. EV 손실은 측정하지 않았어요."]
            .waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "EV 손실은 0bb예요"
        )).firstMatch.exists)
        let nextHand = app.buttons["다음 핸드"]
        XCTAssertTrue(scrollUntilHittable(nextHand, in: app),
                      "The complete hand summary must remain scrollable at AX XXXL.")
    }

    func testFirstLessonReachesCourseAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_TEST_FIRST_LESSON": "1",
        ])

        XCTAssertTrue(app.staticTexts["어느 쪽이 이길까요?"].waitForExistence(timeout: 15))
        let exampleAnswer = firstButton(prefix: "내 카드", in: app)
        XCTAssertTrue(scrollUntilHittable(exampleAnswer, in: app),
                      "The guided hand choice must remain reachable at AX XXXL.")
        exampleAnswer.tap()

        let tryTransfer = app.buttons["다른 카드로 풀어보기"]
        XCTAssertTrue(scrollUntilHittable(tryTransfer, in: app),
                      "The first explanation and transfer action must remain reachable at AX XXXL.")
        tryTransfer.tap()

        XCTAssertTrue(app.staticTexts["같은 규칙으로 골라보세요"].waitForExistence(timeout: 10))
        let transferAnswer = firstButton(prefix: "상대 카드", in: app)
        XCTAssertTrue(scrollUntilHittable(transferAnswer, in: app),
                      "The transfer hand choice must remain reachable at AX XXXL.")
        transferAnswer.tap()

        let seeIntroduction = app.buttons["앱 둘러보기"]
        XCTAssertTrue(scrollUntilHittable(seeIntroduction, in: app),
                      "The transfer explanation must remain scrollable at AX XXXL.")
        seeIntroduction.tap()

        XCTAssertTrue(app.staticTexts["이렇게 한 결정씩 배워요"].waitForExistence(timeout: 10))
        let beginCourse = app.buttons["첫 레슨 시작"]
        XCTAssertTrue(scrollUntilHittable(beginCourse, in: app),
                      "The introduction and course entry must remain reachable at AX XXXL.")
        beginCourse.tap()

        XCTAssertTrue(app.staticTexts["쇼다운 · 천천히"].waitForExistence(timeout: 10))
    }

    private func launch(environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = accessibilityXXXL
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication,
                                     maximumSwipes: Int = 12) -> Bool {
        guard element.waitForExistence(timeout: 15) else { return false }
        for _ in 0...maximumSwipes {
            if element.exists, element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }

    private func firstButton(prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }
}
