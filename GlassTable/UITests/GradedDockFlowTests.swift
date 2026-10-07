// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class GradedDockFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ language: String = "en", postflop: Bool = false, ax: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_LANGUAGE": language,
                                 "GT_DEMO_TABLE": postflop ? "station" : "tag"]
        if postflop {
            app.launchEnvironment["GT_DEMO_TABLE_STEP"] = "1"
            app.launchEnvironment["GT_DEMO_TABLE_CONTINUE"] = "1"
        }
        app.launch()
        XCTAssertTrue(app.buttons["table-fold"].waitForExistence(timeout: 20))
        return app
    }

    private func noAnswer(_ app: XCUIApplication) {
        XCTAssertFalse(app.buttons["free-table-help"].exists)
        XCTAssertFalse(app.buttons["free-review"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "You chose")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Best choice")).firstMatch.exists)
    }

    func testPreflopThreeSlotsCommitExactChartChoice() {
        let app = launch()
        let fold = app.buttons["table-fold"], call = app.buttons["table-passive"], raise = app.buttons["table-aggressive"]
        XCTAssertEqual(fold.label, "Fold")
        XCTAssertEqual(raise.label, "Raise")
        XCTAssertTrue(call.label.hasPrefix("Call, "))
        for button in [call, raise] {
            XCTAssertEqual(button.frame.width, fold.frame.width, accuracy: 1)
            XCTAssertEqual(button.frame.height, 87, accuracy: 1)
        }
        noAnswer(app)
        raise.tap()
        XCTAssertTrue(app.buttons["계속"].waitForExistence(timeout: 1) || app.buttons["Continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "chart")).firstMatch.exists)
    }

    func testCheckedToPreservesEverySizeAndGrading() {
        let app = launch(postflop: true)
        let bet = app.buttons["table-aggressive"]
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: bet)
        wait(for: [ready], timeout: 30)
        let fold = app.buttons["table-fold"], check = app.buttons["table-passive"]
        XCTAssertFalse(fold.isEnabled)
        XCTAssertEqual(check.label, "Check")
        XCTAssertEqual(bet.label, "Bet")
        XCTAssertEqual(bet.frame.width, fold.frame.width, accuracy: 1)
        noAnswer(app)
        bet.tap()
        XCTAssertTrue(app.scrollViews["table-bet-sizes"].waitForExistence(timeout: 5))
        let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "table-bet-size-"))
        XCTAssertEqual(choices.count, 5)
        for price in ["33%", "50%", "75%", "100%", "150%"] { XCTAssertTrue(app.buttons["table-bet-size-\(price)"].exists) }
        noAnswer(app)
        let last = app.buttons["table-bet-size-150%"]
        for _ in 0..<10 where !last.isHittable { app.scrollViews["table-bet-sizes"].swipeUp() }
        XCTAssertTrue(last.isHittable)
        last.tap()
        let verdict = app.descendants(matching: .any)["table-verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 10))
        XCTAssertTrue(verdict.label.contains("Your choice: Bet"))
        XCTAssertTrue(verdict.label.contains("Model choice:"))
    }

    func testAXKOSizingChoiceFullyReachable() { sizingReach("ko") }
    func testAXENSizingChoiceFullyReachable() { sizingReach("en") }

    private func sizingReach(_ language: String) {
        let app = launch(language, postflop: true, ax: true)
        let bet = app.buttons["table-aggressive"]
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: bet)
        wait(for: [ready], timeout: 30)
        for _ in 0..<12 where !bet.isHittable { app.swipeUp() }
        XCTAssertTrue(bet.isHittable)
        bet.tap()
        let row = app.scrollViews["table-accessibility-scroll"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "table-bet-size-"))
        XCTAssertEqual(choices.count, 5)
        let last = app.buttons["table-bet-size-150%"]
        for _ in 0..<16 {
            let viewport = row.frame.intersection(app.windows.firstMatch.frame.insetBy(dx: 0, dy: 60))
            if last.frame.minY >= viewport.minY && last.frame.maxY <= viewport.maxY { break }
            row.swipeUp()
        }
        let viewport = row.frame.intersection(app.windows.firstMatch.frame.insetBy(dx: 0, dy: 60))
        XCTAssertGreaterThanOrEqual(last.frame.minY, viewport.minY - 1)
        XCTAssertLessThanOrEqual(last.frame.maxY, viewport.maxY + 1)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(language)-AX-graded-last-size"; attachment.lifetime = .keepAlways; add(attachment)
        print("\(language) graded size last=\(last.frame), viewport=\(viewport)")
        last.tap()
        XCTAssertTrue(app.buttons[language == "ko" ? "계속" : "Continue"].waitForExistence(timeout: 10))
    }
}
