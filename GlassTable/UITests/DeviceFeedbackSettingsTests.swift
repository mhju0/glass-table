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
        // Switch away from the launch language and back, so each test covers both
        // directions without a relaunch.
        let english = code == "en"
        switchLanguage(toEnglish: !english, in: app)
        switchLanguage(toEnglish: english, in: app)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways
        attachment.name = "settings-\(code)-\(appearance)-\(ax ? "ax5" : "normal")"; add(attachment)
        app.terminate()
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.lifetime = .keepAlways
        shot.name = name; add(shot)
    }

    private struct Words {
        let tabs: [String], settings: String, learn: String
        static let english = Words(tabs: ["Learn", "Play", "Progress", "Settings"],
                                   settings: "Play & feedback",
                                   learn: "More to try")
        static let korean = Words(tabs: ["배우기", "플레이", "기록", "설정"],
                                  settings: "플레이와 피드백",
                                  learn: "더 해보기")
    }

    /// The whole app follows the switch at once: the tab bar, the Settings screen and
    /// a screen on another tab, with no relaunch.
    private func switchLanguage(toEnglish: Bool, in app: XCUIApplication,
                                file: StaticString = #filePath, line: UInt = #line) {
        let now = toEnglish ? Words.english : Words.korean
        let old = toEnglish ? Words.korean : Words.english
        let name = toEnglish ? "en" : "ko"
        let picker = app.buttons["settings-language"]
        for _ in 0..<12 where !picker.isHittable { app.swipeUp() }
        XCTAssertTrue(picker.isHittable, file: file, line: line)
        picker.tap()
        app.buttons[toEnglish ? "language-english" : "language-korean"].tap()
        // Look first, then assert, so a stale screen is still captured.
        let settingsSwitched = app.staticTexts[now.settings].waitForExistence(timeout: 5)
        capture("settings-after-switch-to-\(name)", app)
        let tabs = app.tabBars.buttons
        tabs.element(boundBy: 0).tap()
        let learnSwitched = app.staticTexts[now.learn].waitForExistence(timeout: 5)
        capture("learn-after-switch-to-\(name)", app)
        XCTAssertTrue(settingsSwitched, "Settings did not switch to \(name)", file: file, line: line)
        XCTAssertTrue(learnSwitched, "Learn did not switch to \(name)", file: file, line: line)
        XCTAssertFalse(app.staticTexts[old.learn].exists, file: file, line: line)
        for (label, stale) in zip(now.tabs, old.tabs) {
            XCTAssertTrue(tabs[label].exists, "Tab \(label) missing after switching to \(name)",
                          file: file, line: line)
            XCTAssertFalse(tabs[stale].exists, file: file, line: line)
        }
        tabs.element(boundBy: 3).tap()
        XCTAssertTrue(app.staticTexts[now.settings].waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertFalse(app.staticTexts[old.settings].exists, file: file, line: line)
    }
}
