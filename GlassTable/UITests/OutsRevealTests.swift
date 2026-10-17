// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// The outs answer (owner, 2026-10-17): both seven-card rows with a river dealt, then the
/// winning rivers in one row per kind of hand. A tap deals that river into both rows.
/// Spot: OutsSpotGenerator(24500, 4), A♥ J♥ against 6♦ K♦ on 5♠ 9♣ Q♥ K♥, 15 outs.
final class OutsRevealTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testKOTapRewritesRowsWithoutScrolling() { tapRewritesRows("ko") }
    func testENTapRewritesRowsWithoutScrolling() { tapRewritesRows("en") }

    private func tapRewritesRows(_ language: String) {
        let ko = language == "ko"
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", ko ? "ko_KR" : "en_US",
                               "-glassTable.language", ko ? "korean" : "english"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_NODE": "u2-outs", "GT_DEMO_OUTS_SPOT": "24500:4"]
        app.launch()

        let choice = app.buttons["lesson-choice-15"]
        XCTAssertTrue(choice.waitForExistence(timeout: 15))
        XCTAssertFalse(why(app).exists, "Never before the answer is locked in")
        for _ in 0..<6 where !choice.isHittable { app.swipeUp() }
        choice.tap()

        // The first winning card starts picked, so the rows are never empty.
        XCTAssertTrue(why(app).waitForExistence(timeout: 10))
        XCTAssertEqual(why(app).label, ko ? "내 로열 플러시가 상대 K 원 페어를 이겨요."
                                          : "Your royal flush beats the opponent's pair of Ks.")
        XCTAssertEqual(app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'outs-group-'")).count, 4)
        XCTAssertEqual(app.buttons["reveal-sheet-toggle"].label, ko ? "설명 펼치기" : "Show explanation",
                       "The answer sheet opens folded")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label IN %@",
            ["대표 카드로 비교", "Compare a representative"])).firstMatch.exists)

        // 9♥ is a flush for me and gives the opponent two pair: both rows change.
        let nine = app.buttons["outs-river-9h"]
        XCTAssertTrue(nine.isHittable, "Every river card is on the first screen")
        nine.tap()
        let flushWhy = ko ? "내 A 하이 플러시가 상대 K 투 페어를 이겨요."
                          : "Your A-high flush beats the opponent's two pair, K high."
        XCTAssertTrue(why(app).waitForLabel(flushWhy), why(app).label)
        XCTAssertTrue(label(app, 0).label.contains(ko ? "K 투 페어" : "wo pair, K high"), label(app, 0).label)
        XCTAssertTrue(label(app, 1).label.contains(ko ? "A 하이 플러시" : "A-high flush"), label(app, 1).label)
        assertOnScreen(app)
        attach(app, "\(language)-large-outs-9h")

        // A♠ makes my pair of aces in another group.
        app.buttons["outs-river-As"].tap()
        XCTAssertTrue(why(app).waitForLabel(ko ? "내 A 원 페어가 상대 K 원 페어를 이겨요."
                                               : "Your pair of As beats the opponent's pair of Ks."), why(app).label)
        assertOnScreen(app)
        attach(app, "\(language)-large-outs-As")
    }

    private func why(_ app: XCUIApplication) -> XCUIElement { app.staticTexts["outs-why"] }

    private func label(_ app: XCUIApplication, _ index: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "outs-row-label-\(index)").firstMatch
    }

    /// Both rows, the line and every river card sit above the answer sheet without scrolling.
    private func assertOnScreen(_ app: XCUIApplication) {
        let screen = app.windows.firstMatch.frame
        let sheetTop = app.buttons["reveal-sheet-toggle"].frame.minY
        var elements = [why(app), label(app, 0)]
        elements += (0..<2).map { app.descendants(matching: .any)["outs-row-cards-\($0)"] }
        elements += app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'outs-river-'")).allElementsBoundByIndex
        XCTAssertEqual(elements.count, 4 + 15)
        for element in elements {
            XCTAssertTrue(element.isHittable || element.elementType != .button, element.identifier)
            XCTAssertGreaterThanOrEqual(element.frame.minY, screen.minY, element.identifier)
            XCTAssertLessThanOrEqual(element.frame.maxY, sheetTop, "\(element.identifier) under the sheet")
            XCTAssertLessThanOrEqual(element.frame.maxX, screen.maxX, element.identifier)
        }
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private extension XCUIElement {
    func waitForLabel(_ text: String, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", text), object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
