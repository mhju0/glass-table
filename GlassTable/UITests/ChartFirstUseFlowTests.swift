import XCTest
import GlassTableDrills

final class ChartFirstUseFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(concept: String? = nil, korean: Bool = false, ax: Bool = false,
                        invitation: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-glassTable.language", korean ? "korean" : "english",
                               "-appAppearance", korean ? "light" : "dark",
                               "-UIPreferredContentSizeCategoryName",
                               ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_LEVEL": "newToPoker"]
        if let concept { app.launchEnvironment["GT_DEMO_CONCEPT"] = concept }
        else { app.launchEnvironment["GT_DEMO_TABLE"] = "tag" }
        if invitation { app.launchEnvironment["GT_TEST_DEFEND_CHART_INVITATION"] = "1" }
        app.launch()
        return app
    }

    private func reach(_ element: XCUIElement, app: XCUIApplication) {
        let axScroll = app.scrollViews["drill-accessibility-scroll"]
        let contentScroll = app.scrollViews["drill-content-scroll"]
        let scroll = axScroll.exists ? axScroll : contentScroll
        for _ in 0..<16 where !element.isHittable {
            if scroll.exists {
                if element.exists, element.frame.maxY <= scroll.frame.minY { scroll.swipeDown() }
                else { scroll.swipeUp() }
            } else { app.swipeUp() }
        }
        XCTAssertTrue(element.isHittable)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.windows.firstMatch.frame.maxX + 1)
    }

    func testDirectBeginnerChartDefinesActionsBeforeCommit() {
        for korean in [false, true] {
            let app = launch(concept: "defend", korean: korean, ax: korean)
            let primer = app.descendants(matching: .any)["defend-chart-primer"].firstMatch
            XCTAssertTrue(primer.waitForExistence(timeout: 15))
            let definition = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
                korean ? "3벳이라고도 해요" : "also called a 3-bet")).firstMatch
            XCTAssertTrue(definition.exists, "The first primer must start expanded.")
            reach(definition, app: app)
            XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists)
            let action = app.buttons[korean ? "다시 올리기" : "Raise again"]
            reach(action, app: app)
            action.tap()
            XCTAssertTrue(app.descendants(matching: .any)["defend-selected-evidence"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testOptionalInvitationFoldsChartAndKeepsReopeningAvailable() {
        let app = launch(concept: "defend", invitation: true)
        let invitation = app.descendants(matching: .any)["defend-chart-invitation"]
        XCTAssertTrue(invitation.waitForExistence(timeout: 15))
        let fold = app.buttons["defend-chart-try-folded"]
        reach(fold, app: app)
        fold.tap()
        XCTAssertFalse(invitation.exists)
        let toggle = app.buttons["defend-practice-chart-toggle"]
        XCTAssertEqual(toggle.label, "Show chart")
        toggle.tap()
        XCTAssertEqual(toggle.label, "Hide chart")
        XCTAssertFalse(invitation.exists)
        XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists)
    }

    func testKeepingChartDismissesInvitationWithoutFolding() {
        let app = launch(concept: "defend", korean: true, ax: true, invitation: true)
        let keep = app.buttons["defend-chart-keep-open"]
        XCTAssertTrue(keep.waitForExistence(timeout: 15))
        reach(keep, app: app)
        keep.tap()
        XCTAssertFalse(app.descendants(matching: .any)["defend-chart-invitation"].exists)
        XCTAssertEqual(app.buttons["defend-practice-chart-toggle"].label, "차트 접기")
    }

    func testThreeCorrectCommitsOfferOneOptionalInvitation() {
        for korean in [false, true] {
            let app = launch(concept: "defend", korean: korean, ax: korean)
            let invitation = app.descendants(matching: .any)["defend-chart-invitation"]
            for index in 2...4 {
                let question = app.staticTexts["drill-question-defend/1706/\(index)"]
                XCTAssertTrue(question.waitForExistence(timeout: 15))
                XCTAssertFalse(invitation.exists, "The invitation must wait for three correct commits.")
                let correct = DefendSpotGenerator.spot(baseSeed: 0x6AA, index: index).correct
                let label: String
                switch correct {
                case .fold: label = korean ? "폴드" : "Fold"
                case .call: label = korean ? "콜" : "Call"
                case .threeBet: label = korean ? "다시 올리기" : "Raise again"
                }
                let choice = app.buttons[label]
                reach(choice, app: app)
                choice.tap()
                XCTAssertTrue(app.staticTexts[korean ? "차트와 일치해요" : "Matches the chart"].waitForExistence(timeout: 5))
                let next = app.buttons["drill-completion-defend/1706/\(index)"]
                XCTAssertTrue(next.waitForExistence(timeout: 5))
                reach(next, app: app)
                XCTAssertTrue(next.isEnabled, "Each real answer must be saved before advancing.")
                next.tap()
            }
            XCTAssertTrue(app.staticTexts["drill-question-defend/1706/5"].waitForExistence(timeout: 5))
            XCTAssertTrue(invitation.exists)
            let fold = app.buttons["defend-chart-try-folded"]
            XCTAssertTrue(fold.exists)
            XCTAssertTrue(app.buttons["defend-chart-keep-open"].exists)
            reach(fold, app: app)
            fold.tap()
            XCTAssertFalse(invitation.exists)
            let toggle = app.buttons["defend-practice-chart-toggle"]
            reach(toggle, app: app)
            XCTAssertEqual(toggle.label, korean ? "차트 보기" : "Show chart")
            toggle.tap()
            XCTAssertEqual(toggle.label, korean ? "차트 접기" : "Hide chart")
            XCTAssertFalse(invitation.exists)
            XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists)
            app.terminate()
        }
    }

    func testGradedChartStartsExpandedAndRemembersCollapseOnReopen() {
        let app = launch()
        let chart = app.buttons["table-chart"]
        XCTAssertTrue(chart.waitForExistence(timeout: 15))
        chart.tap()
        let text = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "The diagonal from AA to 22")).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        app.buttons["table-chart-reading-guide"].tap()
        XCTAssertFalse(text.exists)
        app.buttons["Close"].tap()
        chart.tap()
        XCTAssertFalse(text.exists)
        XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists)
    }

    func testEquityQuestionIncludesShareOfTies() {
        for korean in [false, true] {
            let app = launch(concept: "equitySense", korean: korean, ax: korean)
            let question = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
                korean ? "무승부에서 나눈 몫" : "wins plus your share of ties")).firstMatch
            XCTAssertTrue(question.waitForExistence(timeout: 15))
            reach(question, app: app)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
                korean ? "둘이 비기면 50%" : "two-player tie as 50%")).firstMatch.exists)
            app.terminate()
        }
    }
}
