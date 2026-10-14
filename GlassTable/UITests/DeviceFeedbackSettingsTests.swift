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
        for (element, expected) in [(sound, expectedSound), (haptics, expectedHaptics)] {
            XCTAssertTrue(element.waitForExistence(timeout: 15))
            for _ in 0..<12 where !element.isHittable { app.swipeUp() }
            XCTAssertTrue(element.isHittable)
            element.tap()
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: element)
            let outcome = XCTWaiter.wait(for: [changed], timeout: 10)
            if outcome != .completed { capture(app, name: "switch-\(element.identifier)-unchanged") }
            XCTAssertEqual(outcome, .completed, "A single tap must change \(element.identifier) to \(expected)")
        }
        XCTAssertEqual(sound.value as? String, expectedSound)
        XCTAssertEqual(haptics.value as? String, expectedHaptics)
        app.terminate()
        app.launch()
        let foreground = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.state == .runningForeground
        }, object: app)
        let foregroundOutcome = XCTWaiter.wait(for: [foreground], timeout: 15)
        if foregroundOutcome != .completed { capture(app, name: "relaunch-not-foreground") }
        XCTAssertEqual(foregroundOutcome, .completed)
        let relaunchedSound = app.switches["settings-sound"]
        let relaunchedHaptics = app.switches["settings-haptics"]
        XCTAssertTrue(relaunchedSound.waitForExistence(timeout: 15))
        XCTAssertEqual(relaunchedSound.value as? String, expectedSound)
        XCTAssertEqual(relaunchedHaptics.value as? String, expectedHaptics)
        chooseLanguage("english", tab: "Settings", app: app)
        chooseLanguage("korean", tab: "설정", app: app)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways
        attachment.name = "settings-\(code)-\(appearance)-\(ax ? "ax5" : "normal")"; add(attachment)
        app.terminate()
    }

    private func chooseLanguage(_ option: String, tab: String, app: XCUIApplication) {
        let picker = app.descendants(matching: .any).matching(identifier: "settings-language").firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 15))
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 15))
        let scrollFrame = scroll.frame.intersection(app.frame)
        let top = scrollFrame.minY + 8
        let bottom = min(scrollFrame.maxY, app.tabBars.firstMatch.frame.minY) - 8
        func fullyVisible() -> Bool {
            let frame = picker.frame
            return !frame.isEmpty && frame.minY >= top && frame.maxY <= bottom
                && frame.minX >= scrollFrame.minX && frame.maxX <= scrollFrame.maxX
        }
        for _ in 0..<12 {
            if fullyVisible() { break }
            let upward = picker.frame.maxY > bottom
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.7 : 0.4))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.4 : 0.7))
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        if !fullyVisible() || !picker.isHittable { capture(app, name: "menu-trigger-unreachable") }
        XCTAssertTrue(fullyVisible(), "Language menu must be fully inside its scroll viewport")
        XCTAssertTrue(picker.isHittable)
        picker.tap()
        let choice = app.descendants(matching: .any).matching(identifier: "language-\(option)").firstMatch
        let appeared = choice.waitForExistence(timeout: 10)
        if !appeared { capture(app, name: "menu-\(option)-missing") }
        XCTAssertTrue(appeared, "A single menu tap must expose language-\(option)")
        choice.tap()
        XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 5))
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "\(name)-hierarchy"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
