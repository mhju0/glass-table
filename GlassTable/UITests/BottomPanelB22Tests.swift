import XCTest

final class BottomPanelB22Tests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishLightHint() { verify(code: "en", theme: "light", large: false) }
    func testEnglishDarkHint() { verify(code: "en", theme: "dark", large: false) }
    func testKoreanLightHint() { verify(code: "ko", theme: "light", large: false) }
    func testKoreanDarkHint() { verify(code: "ko", theme: "dark", large: false) }
    func testEnglishLightLargeHint() { verify(code: "en", theme: "light", large: true) }
    func testEnglishDarkLargeHint() { verify(code: "en", theme: "dark", large: true) }
    func testKoreanLightLargeHint() { verify(code: "ko", theme: "light", large: true) }
    func testKoreanDarkLargeHint() { verify(code: "ko", theme: "dark", large: true) }

    private func verify(code: String, theme: String, large: Bool) {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english",
                               "-appAppearance", theme]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_NODE": "u1-showdown", "GT_DEMO_STAGE": "together"]
        app.launch()
        let hint = app.buttons[code == "ko" ? "힌트" : "Hint"]
        XCTAssertTrue(hint.waitForExistence(timeout: 20))
        hint.tap()
        let cue = app.descendants(matching: .any)["guided-hint-cue"].firstMatch
        let close = app.buttons[code == "ko" ? "힌트 닫기" : "Close hint"]
        XCTAssertTrue(cue.waitForExistence(timeout: 8))
        let settled = NSPredicate { _, _ in
            close.exists && close.isHittable && close.frame.width >= 44 && close.frame.height >= 44
        }
        let settleResult = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: settled, object: nil)], timeout: 5)
        if settleResult != .completed {
            let diagnostic = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            diagnostic.name = "hint-close-geometry-\(code)-\(theme)"
            diagnostic.lifetime = .keepAlways
            add(diagnostic)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        XCTAssertEqual(settleResult, .completed, "The sheet must settle with a full-size close target")
        XCTAssertTrue(close.isHittable)
        XCTAssertGreaterThanOrEqual(close.frame.width, 44)
        XCTAssertGreaterThanOrEqual(close.frame.height, 44)
        let sheet = app.descendants(matching: .any)["guided-hint"].firstMatch
        XCTAssertTrue(sheet.exists)
        if !large {
            XCTAssertLessThan(sheet.frame.height, app.frame.height * 0.5,
                              "A brief hint should not occupy half the screen")
        }
        XCTAssertGreaterThanOrEqual(cue.frame.minY, sheet.frame.minY)
        XCTAssertLessThanOrEqual(cue.frame.maxY, sheet.frame.maxY + 1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "compact-hint-\(code)-\(theme)-\(large ? "AX5" : "normal")"
        attachment.lifetime = .keepAlways
        add(attachment)
        close.tap()
        XCTAssertFalse(close.waitForExistence(timeout: 2))
        XCTAssertTrue(hint.isHittable)
    }
}
