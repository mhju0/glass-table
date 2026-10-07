import XCTest

final class DeviceFeedbackLessonTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testEnglishLightPositionExampleFinishes() { example("en", "light", false) }
    func testKoreanDarkPositionExampleFinishesAX5() { example("ko", "dark", true) }
    private func example(_ code: String, _ appearance: String, _ ax: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_SEED": "1",
                                 "GT_DEMO_NODE": "u1-position", "GT_DEMO_EXPLAIN": "1"]
        app.launchArguments = ["-glassTable.language", code == "ko" ? "korean" : "english", "-appAppearance", appearance]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        tap(app.buttons["explain-example"], app)
        XCTAssertTrue(app.buttons["walkthrough-next"].waitForExistence(timeout: 8))
        snapshot(app, "position-intro-\(code)-\(appearance)")
        tap(app.buttons["walkthrough-next"], app)
        tap(app.buttons["walkthrough-previous"], app)
        for _ in 0..<40 {
            let next = app.buttons["walkthrough-next"]
            if next.label == (code == "ko" ? "예시 마치기" : "Finish example") {
                snapshot(app, "position-last-\(code)-\(appearance)")
                tap(next, app)
                XCTAssertTrue(app.buttons["explain-example"].waitForExistence(timeout: 5))
                snapshot(app, "position-return-\(code)-\(appearance)")
                app.terminate()
                return
            }
            if !next.isEnabled { tap(app.buttons["walkthrough-reveal"], app) }
            tap(next, app)
        }
        XCTFail("Worked example did not return to its explanation")
    }
    private func tap(_ element: XCUIElement, _ app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        for _ in 0..<12 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
        element.tap()
    }
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let item = XCTAttachment(screenshot: app.screenshot()); item.name = name; item.lifetime = .keepAlways; add(item)
    }
}
