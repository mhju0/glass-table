import XCTest

final class WelcomeFirstFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func app(korean: Bool = false, ax: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", korean ? "(ko)" : "(en)",
                               "-AppleLocale", korean ? "ko_KR" : "en_US",
                               "-glassTable.language", korean ? "korean" : "english"]
        if ax {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "1", "GT_TEST_FIRST_PLACEMENT": "1"]
        return app
    }

    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<8 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
        element.tap()
    }

    private func start(_ app: XCUIApplication, name: String) {
        app.launch()
        XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["placement.level.newToPoker"].exists)
        attach(app, name: name + "-welcome")
        tap(app.buttons["firstLesson.start"], in: app)
        XCTAssertTrue(app.buttons["placement.level.newToPoker"].waitForExistence(timeout: 5))
        attach(app, name: name + "-placement")
    }

    private func assertExample(_ app: XCUIApplication, korean: Bool) {
        XCTAssertTrue(app.staticTexts[korean ? "어느 쪽이 이길까요?" : "Which hand wins?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["firstLesson.welcome"].exists)
        XCTAssertFalse(app.buttons["placement.level.newToPoker"].exists)
    }

    func testEnglishNewPlayerNormal() { optionalRoute(korean: false, ax: false, route: "placement.level.newToPoker") }
    func testKoreanNewPlayerAX5() { optionalRoute(korean: true, ax: true, route: "placement.level.newToPoker") }
    func testKoreanSkipNormal() { optionalRoute(korean: true, ax: false, route: "placement.skip") }
    func testEnglishCloseAX5() { optionalRoute(korean: false, ax: true, route: "placement.close") }

    private func optionalRoute(korean: Bool, ax: Bool, route: String) {
        let app = app(korean: korean, ax: ax)
        let name = "\(korean ? "ko" : "en")-\(ax ? "ax5" : "normal")"
        start(app, name: name)
        tap(app.buttons[route], in: app)
        assertExample(app, korean: korean)
        attach(app, name: name + "-example")
        tap(app.buttons["firstLesson.skip"], in: app)
        XCTAssertTrue(app.buttons["learn-path"].waitForExistence(timeout: 5))
        app.terminate()
    }

    func testCompletedCheckKeepsSuggestionUntilContinue() {
        let app = app()
        start(app, name: "en-completed-check")
        tap(app.buttons["placement.level.knowRules"], in: app)
        tap(app.buttons["Two aces"], in: app)
        tap(app.buttons["6 chips"], in: app)
        tap(app.buttons["25%"], in: app)
        XCTAssertTrue(app.staticTexts["How about starting here?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["firstLesson.welcome"].exists)
        attach(app, name: "en-check-suggestion")
        tap(app.buttons["placement.continue"], in: app)
        assertExample(app, korean: false)
        app.terminate()
    }

    func testInterruptedJourneyRelaunchAndSettingsRoutes() {
        let app = app()
        start(app, name: "en-interrupted")
        tap(app.buttons["placement.level.knowRules"], in: app)
        app.terminate()
        start(app, name: "en-unsaved-check-relaunch")
        tap(app.buttons["placement.skip"], in: app)
        assertExample(app, korean: false)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 15))
        tap(app.buttons["firstLesson.start"], in: app)
        assertExample(app, korean: false)
        tap(app.buttons["firstLesson.skip"], in: app)
        XCTAssertTrue(app.buttons["learn-path"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GT_TEST_FIRST_LESSON")
        app.launchEnvironment.removeValue(forKey: "GT_TEST_FIRST_PLACEMENT")
        app.launch()
        XCTAssertTrue(app.buttons["learn-path"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["firstLesson.welcome"].exists)
        tap(app.tabBars.buttons["Settings"], in: app)
        let replay = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Replay the first decision")).firstMatch
        tap(replay, in: app)
        XCTAssertTrue(app.staticTexts["firstLesson.welcome"].waitForExistence(timeout: 5))
        tap(app.buttons["firstLesson.start"], in: app)
        assertExample(app, korean: false)
        tap(app.buttons["firstLesson.close"], in: app)
        let recheck = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Recheck your starting point")).firstMatch
        tap(recheck, in: app)
        XCTAssertTrue(app.buttons["placement.level.newToPoker"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["firstLesson.welcome"].exists)
        tap(app.buttons["placement.close"], in: app)
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 5))
        app.terminate()
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
