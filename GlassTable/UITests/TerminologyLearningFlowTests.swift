import XCTest

final class TerminologyLearningFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishComparisonKeepsBothSeatIdentitiesAfterRestore() { comparison("en", ax: false) }
    func testKoreanAXComparisonKeepsBothSeatIdentitiesAfterRestore() { comparison("ko", ax: true) }

    func testCountQuestionNamesTheSameSeatAsTheDiagram() {
        let app = launch("en", node: "u1-position", ax: false)
        let seat = app.descendants(matching: .any)["position-seat-CO"].firstMatch
        XCTAssertTrue(seat.waitForExistence(timeout: 15))
        XCTAssertTrue(seat.label.contains("CO · Before dealer"), seat.label)
        let prompt = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Your seat: CO · Before dealer")).firstMatch
        XCTAssertTrue(prompt.exists)
        XCTAssertFalse(app.staticTexts["position-action-order"].exists, "The question must not show its action order")
        let answer = app.buttons["3"]
        reach(answer, in: app)
        answer.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(seat.exists)
        XCTAssertTrue(app.staticTexts["position-action-order"].exists)
        attach(app, "position-count-term-and-meaning")
    }

    func testKoreanAXSharpCountsOnlyMarkedPlayersWithTheirSeatCodes() {
        let app = launch("ko", node: "u1-position.3", ax: true)
        let me = app.descendants(matching: .any)["position-seat-BTN"].firstMatch
        XCTAssertTrue(me.waitForExistence(timeout: 15))
        XCTAssertTrue(me.label.contains("나 · BTN · 딜러"), me.label)
        for code in ["LJ", "CO"] {
            let seat = app.descendants(matching: .any)["position-seat-\(code)"].firstMatch
            XCTAssertTrue(seat.label.contains("참여 · \(code)"), seat.label)
        }
        XCTAssertFalse(app.staticTexts["position-action-order"].exists)
        XCTAssertFalse(app.buttons["position-terms-toggle"].exists)
        let enter = app.buttons["답 입력"]
        reach(enter, in: app)
        enter.tap()
        let zero = app.buttons["숫자 0"]
        reach(zero, in: app)
        zero.tap()
        let done = app.buttons["입력 완료"]
        reach(done, in: app)
        done.tap()
        let check = app.buttons["확인"]
        reach(check, in: app)
        check.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(me.exists)
        XCTAssertFalse(app.staticTexts["position-action-order"].exists, "A partial table never claims all eight remain")
        attach(app, "position-sharp-AX-seat-identities")
    }

    private func comparison(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let store = UUID().uuidString
        let app = launch(language, node: "u1-position.2", ax: ax, store: store)
        let first = "A · BB · " + (ko ? "큰 블라인드" : "Big blind")
        let second = "B · CO · " + (ko ? "딜러 앞 자리" : "Before dealer")
        let a = app.buttons["position-choice-0"], b = app.buttons["position-choice-1"]
        XCTAssertTrue(a.waitForExistence(timeout: 15))
        XCTAssertEqual(a.label, first)
        XCTAssertEqual(b.label, second)
        for (code, identity) in [("BB", first), ("CO", second)] {
            let seat = app.descendants(matching: .any)["position-seat-\(code)"].firstMatch
            XCTAssertTrue(seat.exists)
            XCTAssertEqual(seat.label, identity)
        }
        XCTAssertFalse(app.staticTexts["position-action-order"].exists)
        XCTAssertFalse(app.buttons["position-terms-toggle"].exists)
        reach(a, in: app)
        a.tap() // Original index 0 remains A/BB, which loses to B/CO after the flop.
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        let verdict = app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@ AND label CONTAINS %@",
            ko ? "선택한 답:" : "Your answer:", first, second)).firstMatch
        XCTAssertTrue(verdict.exists, "The reveal must keep the original A/B answer mapping")
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0",
                                 "GT_DEMO_LEVEL": "playRegularly"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume, in: app)
        resume.tap()
        XCTAssertTrue(completion(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(verdict.exists)
        XCTAssertEqual(app.descendants(matching: .any)["position-seat-BB"].firstMatch.label, first)
        XCTAssertEqual(app.descendants(matching: .any)["position-seat-CO"].firstMatch.label, second)
        attach(app, "\(language)-\(ax ? "AX5" : "large")-restored-position-identities")
    }

    private func launch(_ language: String, node: String, ax: Bool, store: String = UUID().uuidString) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", language == "ko" ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0",
                                 "GT_DEMO_NODE": node, "GT_DEMO_LEVEL": "playRegularly"]
        app.launch()
        return app
    }

    private func completion(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'drill-completion-'")).firstMatch
    }
    private func reach(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable, element.identifier)
    }
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
