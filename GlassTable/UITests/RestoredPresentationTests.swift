// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class RestoredPresentationTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testKONormalSavedPanels() { restoredPanels("ko", ax: false) }
    func testENNormalSavedPanels() { restoredPanels("en", ax: false) }
    func testKOAXSavedPanels() { restoredPanels("ko", ax: true) }
    func testENAXSavedPanels() { restoredPanels("en", ax: true) }

    private func restoredPanels(_ language: String, ax: Bool) {
        for node in ["u2-potOdds", "u6-evLoss", "u1-potMath"] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                                   "-glassTable.language", language == "ko" ? "korean" : "english"]
            if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
            let store = UUID().uuidString
            app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_SEED": "1", "GT_DEMO_NODE": node]
            if node == "u1-potMath" { app.launchEnvironment["GT_DEMO_POT_STATE"] = "question" }
            app.launch()
            if node == "u1-potMath" {
                let next = app.buttons[language == "ko" ? "다음 행동" : "Next action"]
                XCTAssertTrue(next.waitForExistence(timeout: 15))
                for _ in 0..<12 where next.exists && next.isEnabled { reach(next, app: app); next.tap() }
                let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "pot-answer-")).firstMatch
                reach(choice, app: app); choice.tap()
            } else {
                let submit = node == "u6-evLoss" ? app.buttons[language == "ko" ? "폴드" : "Fold"] : app.firstLessonChoice
                reach(submit, app: app); submit.tap()
            }
            let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch
            XCTAssertTrue(completion.waitForExistence(timeout: 15))
            let answerID = completion.identifier.replacingOccurrences(of: "drill-completion-", with: "saved-answer-")
            app.terminate()
            app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0"]
            app.launch()
            let resume = app.buttons[language == "ko" ? "레슨 이어서 하기" : "Resume lesson"]
            reach(resume, app: app); resume.tap()
            XCTAssertTrue(app.staticTexts[answerID].waitForExistence(timeout: 10))
            attach(app, "\(language)-\(ax ? "AX" : "large")-restored-\(node)-context")
            if node == "u1-potMath" {
                let calculation = app.buttons[language == "ko" ? "계산 보기" : "See the calculation"]
                reach(calculation, app: app); calculation.tap()
            }
            reach(completion, app: app)
            attach(app, "\(language)-\(ax ? "AX" : "large")-restored-\(node)-explanation")
            app.terminate()
        }
    }

    private func reach(_ element: XCUIElement, app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable, "Unreachable \(element.identifier): \(element.frame)")
    }
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
