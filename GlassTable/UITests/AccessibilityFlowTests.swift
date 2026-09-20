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
        XCTAssertTrue(app.staticTexts["상대 카드"].exists)

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

    func testGuidedHintFloatsWithoutMovingTheQuestionAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u1-showdown",
            "GT_DEMO_STAGE": "together",
        ])

        let title = app.staticTexts["쇼다운"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        let frameBeforeHint = title.frame

        let hint = app.buttons["힌트"]
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        XCTAssertTrue(hint.isHittable)
        hint.tap()

        XCTAssertTrue(app.staticTexts["풀이 순서"].waitForExistence(timeout: 5))
        let closeHint = app.buttons["힌트 닫기"]
        XCTAssertTrue(closeHint.waitForExistence(timeout: 5))
        XCTAssertTrue(closeHint.isHittable)
        closeHint.tap()

        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.frame.origin.x, frameBeforeHint.origin.x, accuracy: 1)
        XCTAssertEqual(title.frame.origin.y, frameBeforeHint.origin.y, accuracy: 1,
                       "Opening and closing a hint must not push the drill header")

        let answer = app.buttons["내가 이김"]
        XCTAssertTrue(scrollUntilHittable(answer, in: app),
                      "The answer area must remain reachable after dismissing the hint")
        answer.tap()
        XCTAssertTrue(scrollUntilHittable(app.buttons["다음 문제"], in: app))
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

    func testTableHeroCardsCanBeFullyExposedAboveTabBarAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
        ])

        let hero = app.otherElements["table-hero-cards"]
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 15))
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertTrue(scrollUntilFullyVisible(hero, above: tabBar, in: app),
                      "Both fixed-size hero cards must fit wholly above the real tab bar at AX XXXL.")
        XCTAssertGreaterThanOrEqual(hero.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(hero.frame.maxY, tabBar.frame.minY)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "table-hero-cards-fully-visible-ax5"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDefendRevealExposesSelectedEvidenceAndChartRowsAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u8-defend",
            "GT_DEMO_REVEAL": "1",
        ])

        let evidence = app.descendants(matching: .any)["defend-selected-evidence"]
        XCTAssertTrue(evidence.waitForExistence(timeout: 15))
        XCTAssertTrue(scrollUntilHittable(evidence, in: app),
                      "The hand and its chart action must be reachable before the full grid at AX XXXL.")
        let chartRow = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "A 행.", "AKs"
        )).firstMatch
        XCTAssertTrue(chartRow.waitForExistence(timeout: 5),
                      "VoiceOver must receive the chart's hand-by-hand actions, not one generic label.")
    }

    func testEVRevealLeadsWithRangeEvidenceAndLossEquationAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u6-evLoss",
            "GT_DEMO_REVEAL": "1",
        ])

        let summary = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@", "오픈 ·", "콤보"
        )).firstMatch
        XCTAssertTrue(scrollUntilHittable(summary, in: app),
                      "The exact opponent range used for grading must be readable at AX XXXL.")
        let disclaimer = app.staticTexts["리버에서 어떻게 좁혔는지는 아직 안 따져요"]
        XCTAssertTrue(scrollUntilHittable(disclaimer, in: app))
        let gridRow = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "A 행.", "AKs"
        )).firstMatch
        XCTAssertTrue(gridRow.waitForExistence(timeout: 5))
        let evidenceAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidenceAttachment.name = "ev-range-evidence-ax5"
        evidenceAttachment.lifetime = .keepAlways
        add(evidenceAttachment)
        let equation = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@", "최선 EV", "= 손실"
        )).firstMatch
        XCTAssertTrue(scrollUntilHittable(equation, in: app),
                      "The chosen and best EVs must remain readable as a subtraction at AX XXXL.")
        let equationAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        equationAttachment.name = "ev-loss-equation-ax5"
        equationAttachment.lifetime = .keepAlways
        add(equationAttachment)
    }

    func testCountKeypadCanOpenAndCollapseAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_NODE": "u2-outs",
        ])

        let answer = app.buttons["답 입력"]
        XCTAssertTrue(scrollUntilHittable(answer, in: app))
        answer.tap()
        let zero = app.buttons["숫자 0"]
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(zero, in: app))
        zero.tap()
        let done = app.buttons["입력 완료"]
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(done, in: app))
        let expandedAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        expandedAttachment.name = "count-keypad-expanded-ax5"
        expandedAttachment.lifetime = .keepAlways
        add(expandedAttachment)
        done.tap()

        let hero = app.descendants(matching: .any)["three-region-hero-cards"]
        XCTAssertTrue(scrollBackwardUntilHittable(hero, in: app))
        XCTAssertTrue(app.buttons["0장"].exists)
        let collapsedAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        collapsedAttachment.name = "count-entry-collapsed-after-done-ax5"
        collapsedAttachment.lifetime = .keepAlways
        add(collapsedAttachment)
    }

    func testPolicyReferenceCaveatsRemainReachableAtAccessibilityXXXL() {
        let app = launch(environment: [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_TABLE": "tag",
            "GT_DEMO_TABLE_POLICY": "1",
        ])

        XCTAssertTrue(app.navigationBars["TAG 전략과 레인지"].waitForExistence(timeout: 15))
        let limits = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "벳은 남은 스택보다"
        )).firstMatch
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(limits, in: app))
        let preflop = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "프리플랍은 이 표와 별개예요"
        )).firstMatch
        XCTAssertTrue(scrollForwardUntilMaterializedAndHittable(preflop, in: app))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "table-policy-caveats-ax5"
        attachment.lifetime = .keepAlways
        add(attachment)
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

        XCTAssertTrue(app.staticTexts["쇼다운 · 따라 배우기"].waitForExistence(timeout: 10))
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

    private func scrollUntilFullyVisible(_ element: XCUIElement, above obstruction: XCUIElement,
                                         in app: XCUIApplication,
                                         maximumSwipes: Int = 12) -> Bool {
        for _ in 0...maximumSwipes {
            let frame = element.frame
            if frame.minY >= app.frame.minY, frame.maxY <= obstruction.frame.minY {
                return true
            }
            app.swipeUp()
        }
        let frame = element.frame
        return frame.minY >= app.frame.minY && frame.maxY <= obstruction.frame.minY
    }

    private func scrollForwardUntilMaterializedAndHittable(_ element: XCUIElement,
                                                            in app: XCUIApplication,
                                                            maximumSwipes: Int = 12) -> Bool {
        for _ in 0...maximumSwipes {
            if element.exists, element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }

    private func scrollBackwardUntilHittable(_ element: XCUIElement, in app: XCUIApplication,
                                              maximumSwipes: Int = 12) -> Bool {
        for _ in 0...maximumSwipes {
            if element.exists, element.isHittable { return true }
            app.swipeDown()
        }
        return element.exists && element.isHittable
    }

    private func firstButton(prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }
}
