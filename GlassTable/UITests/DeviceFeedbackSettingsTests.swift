import XCTest

final class DeviceFeedbackSettingsTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testEnglishLightFeedbackPreferencesPersist() { exercise("en", "light", false) }
    func testKoreanDarkFeedbackPreferencesPersistAX5() { exercise("ko", "dark", true) }
    private func exercise(_ code: String, _ appearance: String, _ ax: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_SETTINGS": "1"]
        app.launchArguments = ["-AppleLanguages", code == "ko" ? "(ko)" : "(en)",
                               "-appAppearance", appearance]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        let sound = app.switches["settings-sound"]
        let haptics = app.switches["settings-haptics"]
        XCTAssertTrue(sound.waitForExistence(timeout: 15))
        let expectedSound = (sound.value as? String) == "1" ? "0" : "1"
        let expectedHaptics = (haptics.value as? String) == "1" ? "0" : "1"
        for element in [sound, haptics] {
            XCTAssertTrue(element.waitForExistence(timeout: 15))
            for _ in 0..<12 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable)
            element.tap()
        }
        XCTAssertEqual(sound.value as? String, expectedSound)
        XCTAssertEqual(haptics.value as? String, expectedHaptics)
        app.terminate()
        app.launch()
        XCTAssertTrue(sound.waitForExistence(timeout: 15))
        XCTAssertEqual(sound.value as? String, expectedSound)
        XCTAssertEqual(haptics.value as? String, expectedHaptics)
        let picker = app.buttons["settings-language"]
        for _ in 0..<12 where !picker.isHittable { app.swipeUp() }
        XCTAssertTrue(picker.isHittable)
        picker.tap()
        app.buttons["language-english"].tap()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 5))
        // The Settings body itself re-renders, not only the tab label.
        XCTAssertTrue(app.staticTexts["Play & feedback"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["플레이와 피드백"].exists)
        picker.tap()
        app.buttons["language-korean"].tap()
        XCTAssertTrue(app.tabBars.buttons["설정"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["플레이와 피드백"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Play & feedback"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways
        attachment.name = "settings-\(code)-\(appearance)-\(ax ? "ax5" : "normal")"; add(attachment)
        app.terminate()
    }
}
