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
        // One help control: the in-place row. The pill and its sheet are gone.
        let row = app.buttons[code == "ko" ? "푸는 방법" : "How to work it out"]
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons[code == "ko" ? "힌트" : "Hint"].exists)
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.isHittable)
        XCTAssertGreaterThanOrEqual(row.frame.height, 44)
        row.tap()
        let cue = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", code == "ko" ? "가장 높은 5장 조합을 만들고" : "Make each player's best five-card hand."
        )).firstMatch
        XCTAssertTrue(cue.waitForExistence(timeout: 8), "The row opens with the one-sentence cue")
        XCTAssertFalse(app.descendants(matching: .any)["guided-hint"].firstMatch.exists,
                       "Help opens in place, never as a sheet over the answers")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "help-row-\(code)-\(theme)-\(large ? "AX5" : "normal")"
        attachment.lifetime = .keepAlways
        add(attachment)
        row.tap()
        XCTAssertFalse(cue.waitForExistence(timeout: 2), "The same row closes it")
    }
}
