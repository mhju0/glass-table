import XCTest

final class DeviceFeedbackBoundsTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testEnglishAXDefendChoicesStayWithinScreen() { defend("en", "light") }
    func testKoreanAXDefendChoicesStayWithinScreen() { defend("ko", "dark") }

    private func defend(_ code: String, _ appearance: String) {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1", "GT_DEMO_NODE": "u8-defend",
                                 "GT_DEMO_LEVEL": "newToPoker"]
        app.launchArguments = ["-glassTable.language", code == "ko" ? "korean" : "english",
                               "-appAppearance", appearance,
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let title = app.staticTexts[code == "ko" ? "상대가 먼저 올렸어요" : "An opponent raised"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        assertWithinScreen(title, app)
        let call = app.buttons[code == "ko" ? "콜" : "Call"].firstMatch
        for _ in 0..<16 where !call.isHittable { app.swipeUp() }
        XCTAssertTrue(call.isHittable)
        assertWithinScreen(call, app)
        let before = XCTAttachment(screenshot: app.screenshot())
        before.name = "defend-ax5-choices-\(code)"; before.lifetime = .keepAlways; add(before)
        call.tap()
        let next = app.buttons[code == "ko" ? "다음 문제" : "Next question"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        for _ in 0..<16 where !next.isHittable { app.swipeUp() }
        XCTAssertTrue(next.isHittable)
        assertWithinScreen(next, app)
        let after = XCTAttachment(screenshot: app.screenshot())
        after.name = "defend-ax5-verdict-\(code)"; after.lifetime = .keepAlways; add(after)
        app.terminate()
    }

    private func assertWithinScreen(_ element: XCUIElement, _ app: XCUIApplication,
                                    file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.windows.firstMatch.frame.minX, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.windows.firstMatch.frame.maxX, file: file, line: line)
    }
}
