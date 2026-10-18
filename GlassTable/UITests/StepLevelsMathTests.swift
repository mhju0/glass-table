// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// The later steps of the number skills (D53): outs typed at the third step, pot odds
/// with a player who already called, and four EV choices that stack at accessibility
/// sizes. The words Learn, Apply and Sharp never appear.
final class StepLevelsMathTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testKOStepThreeOutsIsTyped() { stepThreeOuts("ko", ax: false) }
    func testENStepThreeOutsIsTyped() { stepThreeOuts("en", ax: false) }
    func testKOAXStepThreeOutsIsTyped() { stepThreeOuts("ko", ax: true) }
    func testENAXStepThreeOutsIsTyped() { stepThreeOuts("en", ax: true) }
    func testKOStepThreePotOddsShowsTheEarlierCall() { stepThreePotOdds("ko", ax: false) }
    func testENStepThreePotOddsShowsTheEarlierCall() { stepThreePotOdds("en", ax: false) }
    func testKOAXStepThreePotOddsShowsTheEarlierCall() { stepThreePotOdds("ko", ax: true) }
    func testENAXStepThreePotOddsShowsTheEarlierCall() { stepThreePotOdds("en", ax: true) }
    func testKOStepTwoEVHasFourChoices() { stepTwoEV("ko", ax: false) }
    func testENStepTwoEVHasFourChoices() { stepTwoEV("en", ax: false) }
    func testKOAXStepTwoEVHasFourChoices() { stepTwoEV("ko", ax: true) }
    func testENAXStepTwoEVHasFourChoices() { stepTwoEV("en", ax: true) }

    private func stepThreeOuts(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = open("u2-outs.3", language, ax: ax)
        let line = app.staticTexts["drill-step-line"]
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        XCTAssertEqual(line.label, ko ? "3단계 · 함정이 있는 아웃, 직접 입력" : "Step 3 · Outs with a catch, typed")
        // Typed, not picked: the count entry, and no answer choices.
        let entry = app.buttons[ko ? "답 입력" : "Enter answer"]
        let digit = app.buttons[ko ? "숫자 0" : "Digit 0"]
        for _ in 0..<8 where !entry.exists && !digit.exists { app.swipeUp() }
        XCTAssertTrue(entry.exists || digit.exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'lesson-choice-'")).firstMatch.exists)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-outs")
    }

    private func stepThreePotOdds(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = open("u2-potOdds.3", language, ax: ax)
        let line = app.staticTexts["drill-step-line"]
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        XCTAssertEqual(line.label, ko ? "3단계 · 먼저 콜한 사람이 있어요" : "Step 3 · Someone has already called")
        let called = app.staticTexts["potodds-earlier-call"]
        XCTAssertTrue(called.exists)
        XCTAssertTrue(called.label.hasPrefix(ko ? "다른 한 명이 먼저" : "Another player has already called"), called.label)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-potodds")
        assertFourChoices(app, matching: "lesson-choice-", stacked: ax)
    }

    private func stepTwoEV(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = open("u2-evCall.2", language, ax: ax)
        let line = app.staticTexts["drill-step-line"]
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        XCTAssertEqual(line.label, ko ? "2단계 · 더 다양한 벳 크기" : "Step 2 · More bet sizes")
        assertNoStepNames(app)
        assertFourChoices(app, matching: "lesson-estimate-choice-", stacked: ax)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step2-evcall")
    }

    // MARK: Helpers

    /// Four choices, side by side at normal sizes and one under another at AX sizes.
    private func assertFourChoices(_ app: XCUIApplication, matching prefix: String, stacked: Bool) {
        let query = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
        for _ in 0..<10 where query.count < 4 || !query.element(boundBy: 3).isHittable { app.swipeUp() }
        XCTAssertEqual(query.count, 4)
        let frames = (0..<4).map { query.element(boundBy: $0).frame }
        if stacked {
            XCTAssertEqual(Set(frames.map { Int($0.minX) }).count, 1, "\(frames)")
            XCTAssertEqual(Set(frames.map { Int($0.minY) }).count, 4, "\(frames)")
        } else {
            XCTAssertEqual(Set(frames.map { Int($0.minY) }).count, 1, "\(frames)")
        }
        attach(app, "choices-\(prefix)\(stacked ? "AX5" : "large")")
    }

    private func open(_ node: String, _ language: String, ax: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", language == "ko" ? "korean" : "english"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_TEST_FIRST_PLACEMENT": "0", "GT_DEMO_NODE": node]
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
