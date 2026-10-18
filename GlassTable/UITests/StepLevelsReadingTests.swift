// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// Steps (D53) for the seat and reading skills: position, RFI, defend, range read and
/// action read. Each later step opens on its own questions under one line on what is
/// new; the step names never appear.
final class StepLevelsReadingTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testKOStepThreePositionIsTyped() { positionTyped("ko", ax: false) }
    func testENStepThreePositionIsTyped() { positionTyped("en", ax: false) }
    func testKOAXStepThreePositionIsTyped() { positionTyped("ko", ax: true) }
    func testENAXStepThreePositionIsTyped() { positionTyped("en", ax: true) }
    func testKOStepThreeRFIAsksForTheFirstSeat() { rfiFirstSeat("ko", ax: false) }
    func testENStepThreeRFIAsksForTheFirstSeat() { rfiFirstSeat("en", ax: false) }
    func testKOAXStepThreeRFIAsksForTheFirstSeat() { rfiFirstSeat("ko", ax: true) }
    func testENAXStepThreeRFIAsksForTheFirstSeat() { rfiFirstSeat("en", ax: true) }
    func testKOStepThreeDefendHidesTheOpeningWidth() { defendWidth("ko", ax: false) }
    func testENAXStepThreeDefendHidesTheOpeningWidth() { defendWidth("en", ax: true) }
    func testKOStepThreeRangeReadOffersFourChoices() { rangeRead("ko", ax: false) }
    func testENAXStepThreeRangeReadOffersFourChoices() { rangeRead("en", ax: true) }
    func testENStepThreeActionReadHidesTheOpponent() { actionRead("en", ax: false) }
    func testKOAXStepThreeActionReadHidesTheOpponent() { actionRead("ko", ax: true) }

    private func positionTyped(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = open("u1-position.3", language, ax: ax)
        assertStepLine(app, ko ? "3단계 · 남은 사람만 세서, 직접 입력" : "Step 3 · Only players still in, typed")
        let entry = app.descendants(matching: .any)["position-typed-entry"]
        for _ in 0..<8 where !entry.exists { app.swipeUp() }
        XCTAssertTrue(entry.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
            ko ? "그중 내 뒤에" : "of them act after you")).firstMatch.exists)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-position")
    }

    private func rfiFirstSeat(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = open("u3-rfi.3", language, ax: ax)
        assertStepLine(app, ko ? "3단계 · 어느 자리부터 여는 패인가요" : "Step 3 · The first seat that opens it")
        // The seat is the answer, so no seat is given and raise-or-fold is not asked.
        XCTAssertFalse(app.staticTexts[ko ? "내 자리" : "Your seat"].exists)
        let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'rfi-first-seat-'"))
        let first = choices.firstMatch
        for _ in 0..<8 where !first.isHittable { app.swipeUp() }
        XCTAssertEqual(choices.count, 4)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-rfi")
        first.tap()
        let next = app.buttons[ko ? "다음 문제" : "Next question"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-rfi-reveal")
    }

    private func defendWidth(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let two = open("u8-defend.2", language, ax: ax)
        assertStepLine(two, ko ? "2단계 · 밴드 경계에 걸친 패" : "Step 2 · Hands at a band's edge")
        XCTAssertTrue(two.staticTexts["defend-opening-width"].exists, "The second step still gives the width")
        two.terminate()
        let app = open("u8-defend.3", language, ax: ax)
        assertStepLine(app, ko ? "3단계 · 여는 폭 안내 없이" : "Step 3 · No opening width given")
        XCTAssertFalse(app.staticTexts["defend-opening-width"].exists)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-defend")
    }

    private func rangeRead(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = open("u4-rangeRead.3", language, ax: ax)
        assertStepLine(app, ko ? "3단계 · 콜만, 모르는 상대, 보기 넷" : "Step 3 · Calls only, unknown opponent, four choices")
        let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'range-estimate-choice-'"))
        for _ in 0..<8 where !choices.firstMatch.exists { app.swipeUp() }
        XCTAssertEqual(choices.count, 4)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-rangeread")
    }

    private func actionRead(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = open("u7-actionRead.3", language, ax: ax)
        assertStepLine(app, ko ? "3단계 · 더 가까운 보기, 모르는 상대" : "Step 3 · Closer choices, unknown opponent")
        let opponent = app.staticTexts["action-read-opponent"]
        XCTAssertTrue(opponent.exists)
        XCTAssertTrue(opponent.label.hasPrefix(ko ? "모르는 상대" : "Unknown opponent"), opponent.label)
        assertNoStepNames(app)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-step3-actionread")
    }

    // MARK: Helpers

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

    private func assertStepLine(_ app: XCUIApplication, _ expected: String) {
        let line = app.staticTexts["drill-step-line"]
        XCTAssertTrue(line.waitForExistence(timeout: 15))
        XCTAssertEqual(line.label, expected)
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
