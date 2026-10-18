// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// Steps (D53): a skill's later steps are lessons of their own, shown on Learn as
/// pips and in the marked row's tag, and opened straight into their questions with
/// one line on what is new. The words Learn, Apply and Sharp never appear.
final class StepLevelsTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testKOListShowsStepsPassed() { listShowsSteps("ko", ax: false) }
    func testENListShowsStepsPassed() { listShowsSteps("en", ax: false) }
    func testKOAXListShowsStepsPassed() { listShowsSteps("ko", ax: true) }
    func testENAXListShowsStepsPassed() { listShowsSteps("en", ax: true) }
    func testKOStepTwoOpensOnItsQuestionsAndResumesMarked() { stepTwo("ko", ax: false) }
    func testENStepTwoOpensOnItsQuestionsAndResumesMarked() { stepTwo("en", ax: false) }
    func testKOAXStepTwoOpensOnItsQuestionsAndResumesMarked() { stepTwo("ko", ax: true) }
    func testKOStepThreePotMathIsTyped() { stepThreePotMath("ko", ax: false) }
    func testENStepThreePotMathIsTyped() { stepThreePotMath("en", ax: false) }
    func testENAXStepThreePotMathIsTyped() { stepThreePotMath("en", ax: true) }

    /// The demo learner holds 숙달 in showdown and 능숙 in pot math, so the upgrade
    /// rule marks three and two of their steps.
    private func listShowsSteps(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = launch(language, ax: ax, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_SEED": "1",
                                            "GT_DEMO_TAB": "learn"])
        let showdown = app.buttons["lesson-u1-showdown"]
        XCTAssertTrue(showdown.waitForExistence(timeout: 15))
        XCTAssertTrue(showdown.label.contains(ko ? "3단계 중 3단계 통과" : "3 of 3 steps passed"), showdown.label)
        let potMath = app.buttons["lesson-u1-potMath"]
        XCTAssertTrue(potMath.label.contains(ko ? "3단계 중 2단계 통과" : "2 of 3 steps passed"), potMath.label)
        // 익숙 in position marks only its first step.
        let position = app.buttons["lesson-u1-position"]
        XCTAssertTrue(position.label.contains(ko ? "3단계 중 1단계 통과" : "1 of 3 steps passed"), position.label)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-learn-steps")
    }

    private func stepTwo(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let store = UUID().uuidString
        let app = launch(language, ax: ax, ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0",
                                            "GT_TEST_FIRST_PLACEMENT": "0", "GT_DEMO_NODE": "u2-callFold.2"])
        // No walkthrough: the skill was taught at its first step.
        XCTAssertTrue(app.staticTexts["1/3"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.descendants(matching: .any)["walkthrough-step-0"].exists)
        let line = app.staticTexts["drill-step-line"]
        XCTAssertTrue(line.exists)
        XCTAssertEqual(line.label, ko ? "2단계 · 필요한 몫만 보여요" : "Step 2 · Only the price is shown")
        let numbers = app.staticTexts["callfold-lesson-numbers"]
        XCTAssertTrue(numbers.exists)
        XCTAssertTrue(numbers.label.hasPrefix(ko ? "콜에 필요한 몫" : "The call needs"), numbers.label)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step2-callfold")
        let fold = app.buttons[ko ? "폴드" : "Fold"]
        for _ in 0..<8 where !fold.isHittable { app.swipeUp() }
        fold.tap()
        XCTAssertTrue(app.buttons[ko ? "다음 문제" : "Next question"].waitForExistence(timeout: 10))
        // Relaunch without the demo hook, which would reopen the lesson on every appear.
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        XCTAssertTrue(resume.waitForExistence(timeout: 15))
        for _ in 0..<16 where !resume.isHittable { app.swipeUp() }
        let row = app.buttons["lesson-u2-callFold"]
        XCTAssertTrue(row.label.contains(ko ? "진행 중 · 2단계" : "In progress · Step 2"), row.label)
        XCTAssertTrue(row.label.contains(ko ? "3단계 중 0단계 통과" : "0 of 3 steps passed"), row.label)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-learn-step2-in-progress")
        resume.tap()
        XCTAssertTrue(app.staticTexts["drill-step-line"].waitForExistence(timeout: 10),
                      "Continue reopens the second step, not the first")
    }

    private func stepThreePotMath(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = launch(language, ax: ax, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                            "GT_DEMO_NODE": "u1-potMath.3", "GT_DEMO_POT_STATE": "question"])
        let line = app.staticTexts["drill-step-line"]
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        XCTAssertEqual(line.label, ko ? "3단계 · 플랍 베팅까지, 직접 입력" : "Step 3 · Through the flop, typed")
        // Typed, not picked: no answer choices at the third step.
        let entry = app.descendants(matching: .any)["pot-typed-entry"]
        for _ in 0..<8 where !entry.exists { app.swipeUp() }
        XCTAssertTrue(entry.exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pot-answer-'")).firstMatch.exists)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-potmath")
    }

    // MARK: Helpers

    private func launch(_ language: String, ax: Bool, _ environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", language == "ko" ? "korean" : "english"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    /// Owner default 3: the step names are for code and docs only.
    private func assertNoStepNames(_ app: XCUIApplication) {
        for name in ["Learn ·", "Apply", "Sharp"] {
            let match = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
            XCTAssertFalse(match.exists, name)
        }
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
