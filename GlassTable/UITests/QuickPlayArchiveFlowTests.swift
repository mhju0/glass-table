import XCTest

final class QuickPlayArchiveFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishArchiveAllTenHandsAndCoachControls() { archiveFlow("en", ax: false) }
    func testKoreanArchiveAllTenHandsAndCoachControls() { archiveFlow("ko", ax: false) }
    func testEnglishAXArchiveAllTenHandsAndCoachControls() { archiveFlow("en", ax: true) }
    func testKoreanAXArchiveAllTenHandsAndCoachControls() { archiveFlow("ko", ax: true) }

    private func archiveFlow(_ language: String, ax: Bool) {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
            "GT_DEMO_LANGUAGE": language, "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
            "GT_DEMO_QUICK_REVIEW": "1", "GT_DEMO_REDUCE_MOTION": "1"]
        app.launch()
        let menu = app.buttons["free-game-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 20))
        menu.tap()
        app.buttons[language == "ko" ? "게임 돌아보기" : "Game review"].tap()
        let coverage = app.staticTexts["quick-game-coverage"]
        XCTAssertTrue(coverage.waitForExistence(timeout: 5))
        XCTAssertTrue(coverage.label.contains("1–10"), coverage.label)
        XCTAssertTrue(app.staticTexts["quick-game-retention"].exists)
        let headline = app.staticTexts["quick-game-headline"]
        XCTAssertTrue(headline.exists)
        XCTAssertTrue(headline.label.contains(language == "ko" ? "전체 선택" : "decisions"))
        capture(app, "\(language)-\(ax ? "ax5" : "large")-game-metrics")
        let scroll = app.scrollViews["quick-game-scroll"]
        for hand in [1, 10] {
            let button = app.buttons["archive-hand-\(hand)"]
            reveal(button, scroll: scroll)
            capture(app, "\(language)-\(ax ? "ax5" : "large")-archive-hand-\(hand)")
            button.tap()
            XCTAssertTrue(app.staticTexts["coach-progress"].waitForExistence(timeout: 5))
            let next = app.buttons["coach-next"].exists ? app.buttons["coach-next"] : app.buttons["coach-done"]
            XCTAssertTrue(next.isHittable)
            XCTAssertLessThanOrEqual(next.frame.maxY, app.windows.firstMatch.frame.maxY - 20)
            let coachScroll = app.scrollViews["coach-scroll"]
            let tail = app.staticTexts["coach-verdict"]
            for _ in 0..<12 {
                if tail.isHittable, tail.frame.maxY <= next.frame.minY { break }
                coachScroll.swipeUp()
            }
            XCTAssertTrue(next.isHittable, "Primary control must stay reachable while content scrolls")
            XCTAssertTrue(tail.isHittable)
            XCTAssertLessThanOrEqual(tail.frame.maxY, next.frame.minY)
            capture(app, "\(language)-\(ax ? "ax5" : "large")-coach-hand-\(hand)")
            app.buttons["coach-close"].tap()
            XCTAssertTrue(coverage.waitForExistence(timeout: 5))
        }
        app.terminate()
        app.launch()
        XCTAssertTrue(menu.waitForExistence(timeout: 20))
        menu.tap()
        app.buttons[language == "ko" ? "게임 돌아보기" : "Game review"].tap()
        XCTAssertTrue(coverage.waitForExistence(timeout: 5))
        XCTAssertTrue(coverage.label.contains("1–10"), "Cold restart must retain all ten hands")
    }

    private func reveal(_ element: XCUIElement, scroll: XCUIElement) {
        for _ in 0..<25 {
            if element.isHittable, element.frame.minY >= scroll.frame.minY,
               element.frame.maxY <= scroll.frame.maxY { return }
            scroll.swipeUp()
        }
        XCTFail("Archived hand is not fully reachable")
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
