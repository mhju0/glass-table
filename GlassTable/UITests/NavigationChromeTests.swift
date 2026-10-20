import XCTest

final class NavigationChromeTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishLightNavigationControls() { exercise(korean: false, accessibility: false) }
    func testKoreanDarkAXNavigationControls() { exercise(korean: true, accessibility: true) }

    private func launch(_ environment: [String: String], korean: Bool,
                        accessibility: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", korean ? "(ko)" : "(en)",
                               "-glassTable.language", korean ? "korean" : "english",
                               "-appAppearance", korean ? "dark" : "light",
                               "-UIPreferredContentSizeCategoryName", accessibility
                               ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = environment.merging([
            "GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
            "GT_TEST_FIRST_PLACEMENT": "0", "GT_DEMO_SEED": "1"
        ]) { value, _ in value }
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func exercise(korean: Bool, accessibility: Bool) {
        let suffix = korean ? "ko-dark-AX5" : "en-light-large"
        var app = launch(["GT_DEMO_FIRST_LESSON": "pot"], korean: korean,
                         accessibility: accessibility)
        let skip = app.buttons["firstLesson.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 15))
        XCTAssertTrue(skip.isHittable)
        XCTAssertGreaterThanOrEqual(skip.frame.height, 44)
        capture(app, "navigation-lesson-\(suffix)")
        print("NAVIGATION_TEXT_HOLD epoch=\(Date().timeIntervalSince1970) mode=\(suffix)")
        skip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 2, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.6)))
        XCTAssertTrue(skip.exists, "Dragging away cancels the navigation text action")
        skip.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: skip)
        waitForExpectations(timeout: 10)
        app.terminate()

        app = launch(["GT_DEMO_SETTINGS": "1", "GT_DEMO_GLOSSARY": "1"],
                     korean: korean, accessibility: accessibility)
        let close = app.buttons["glossary-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 15))
        XCTAssertEqual(close.label, korean ? "닫기" : "Close")
        XCTAssertGreaterThanOrEqual(close.frame.width, 44)
        XCTAssertGreaterThanOrEqual(close.frame.height, 44)
        let closeFrame = close.frame
        capture(app, "navigation-glossary-\(suffix)")
        print("NAVIGATION_GLYPH_HOLD epoch=\(Date().timeIntervalSince1970) mode=\(suffix)")
        let closeCenter = close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        closeCenter.press(forDuration: 2, thenDragTo: closeCenter.withOffset(CGVector(dx: 200, dy: 0)))
        XCTAssertTrue(close.exists, "Dragging away cancels sheet dismissal")
        let list = app.scrollViews["glossary-list"]
        XCTAssertTrue(list.exists)
        let first = app.buttons["glossary-entry-chip"]
        XCTAssertTrue(first.exists)
        let firstY = first.frame.minY
        list.swipeUp()
        XCTAssertNotEqual(first.frame.minY, firstY, "The list remains scrollable below the navigation bar")
        XCTAssertEqual(close.frame, closeFrame)
        XCTAssertTrue(close.isHittable)
        capture(app, "navigation-glossary-scrolled-\(suffix)")
        close.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: close)
        waitForExpectations(timeout: 10)
        app.terminate()

        app = launch(["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
                      "GT_DEMO_FREE_PHASE": "raise-open"], korean: korean,
                     accessibility: accessibility)
        let menu = app.buttons["free-game-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 15))
        let hero = app.otherElements["practice-0"]
        let pot = app.descendants(matching: .any)["table-pot"]
        XCTAssertTrue(hero.exists)
        XCTAssertTrue(pot.exists)
        let originalHero = hero.label, originalPot = pot.label
        XCTAssertFalse(originalHero.isEmpty)
        XCTAssertFalse(originalPot.isEmpty)
        capture(app, "navigation-free-\(suffix)")
        menu.tap()
        let endGame = app.buttons[korean ? "게임 마치기" : "End game"]
        XCTAssertTrue(endGame.waitForExistence(timeout: 5))
        let newGame = app.buttons[korean ? "새 게임 시작" : "Start new game"]
        XCTAssertTrue(newGame.exists)
        capture(app, "navigation-menu-open-\(suffix)")
        let dismissal = CGPoint(x: app.frame.minX + 2, y: app.frame.midY)
        XCTAssertFalse(endGame.frame.union(newGame.frame).insetBy(dx: -10, dy: -10).contains(dismissal))
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 2, dy: app.frame.height / 2)).tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: endGame)
        waitForExpectations(timeout: 5)
        app.buttons["free-raise-cancel"].tap()
        XCTAssertTrue(app.buttons["free-raise"].exists)
        XCTAssertEqual(hero.label, originalHero)
        XCTAssertEqual(pot.label, originalPot)
        XCTAssertFalse(app.buttons["free-next-hand"].exists)
        let tableClose = app.buttons[korean ? "닫기" : "Close"].firstMatch
        XCTAssertTrue(tableClose.isHittable)
        tableClose.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: menu)
        waitForExpectations(timeout: 10)
        app.terminate()

        app = launch(["GT_DEMO_TAB": "play"], korean: korean, accessibility: accessibility)
        let quick = app.buttons["play-quick"]
        XCTAssertTrue(quick.waitForExistence(timeout: 15))
        for _ in 0..<8 where !quick.isHittable { app.swipeUp() }
        XCTAssertTrue(quick.isHittable)
        quick.tap()
        let back = app.buttons[korean ? "플레이로" : "Back to Play"]
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        capture(app, "navigation-back-\(suffix)")
        back.tap()
        XCTAssertTrue(quick.waitForExistence(timeout: 10))
        XCTAssertFalse(back.exists)
    }
}
