import XCTest

final class NumericalRevealFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishLightReveals() { reveals(code: "en", appearance: "light") }
    func testEnglishDarkReveals() { reveals(code: "en", appearance: "dark") }
    func testKoreanLightReveals() { reveals(code: "ko", appearance: "light") }
    func testKoreanDarkReveals() { reveals(code: "ko", appearance: "dark") }

    private func application(code: String, appearance: String, environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english", "-appAppearance", appearance]
        app.launchEnvironment = environment.merging(["GT_TEST_STORE_ID": UUID().uuidString,
            "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_SEED": "1"]) { _, value in value }
        return app
    }

    private func reveals(code: String, appearance: String) {
        let app = application(code: code, appearance: appearance, environment: ["GT_DEMO_CONCEPT": "callFold"])
        app.launch()
        let call = app.buttons[code == "ko" ? "콜" : "Call"].firstMatch
        XCTAssertTrue(call.waitForExistence(timeout: 20))
        XCTAssertTrue(call.isHittable)
        call.tap()
        let explanation = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
            code == "ko" ? "무승부 몫을 포함한 팟 지분" : "Your share of the pot, including ties")).firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 10))
        let next = app.buttons[code == "ko" ? "다음 문제" : "Next question"].firstMatch
        for _ in 0..<5 {
            if next.isHittable && explanation.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(explanation.isHittable)
        XCTAssertTrue(next.isHittable)
        XCTAssertTrue(next.isEnabled)
        capture(app, name: "call-fold-reveal-\(code)-\(appearance)")
        next.tap()
        XCTAssertTrue(call.waitForExistence(timeout: 10))
        app.terminate()

        let example = application(code: code, appearance: appearance,
            environment: ["GT_DEMO_NODE": "u2-evCall", "GT_DEMO_BEAT": "3"])
        example.launch()
        let check = example.buttons["walkthrough-next"]
        XCTAssertTrue(check.waitForExistence(timeout: 20))
        XCTAssertEqual(check.label, code == "ko" ? "예시 확인" : "Check example")
        check.tap()
        let detail = example.staticTexts.matching(NSPredicate(format: "label CONTAINS %@",
            code == "ko" ? "콜이에요." : "on average.")).firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
        XCTAssertEqual(check.label, code == "ko" ? "다음" : "Next")
        XCTAssertTrue(check.isHittable)
        capture(example, name: "ev-example-explanation-\(code)-\(appearance)")
        check.tap()
        XCTAssertTrue(example.staticTexts[code == "ko" ? "이번 판의 결과는 상관없어요" : "One result does not change it"].waitForExistence(timeout: 5))
        example.terminate()
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
