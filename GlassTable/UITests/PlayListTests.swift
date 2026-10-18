// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// Play is a list like Learn (owner, 2026-10-18, P2·A with D2·c/D2·d pictures): the open
/// table alone under "Continue", then the three ways to start, then "Look back", and
/// "About the styles" as a link at the bottom.
final class PlayListTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testENNoOpenTableListsTheModesWithoutContinue() { empty("en") }
    func testKONoOpenTableListsTheModesWithoutContinue() { empty("ko") }
    func testENOpenQuickGameShowsItsHandAndCards() { openQuick("en", ax: false) }
    func testKOOpenQuickGameShowsItsHandAndCards() { openQuick("ko", ax: false) }
    func testENAXOpenQuickGameStacksAndReachesEveryRow() { openQuick("en", ax: true) }
    func testKOAXOpenQuickGameStacksAndReachesEveryRow() { openQuick("ko", ax: true) }
    func testENEachRowOpensItsDestination() { destinations("en") }
    func testKOEachRowOpensItsDestination() { destinations("ko") }
    func testENLongTableBetweenHandsShowsNoCards() { longBetweenHands("en") }
    func testKOLongTableBetweenHandsShowsNoCards() { longBetweenHands("ko") }

    private func empty(_ language: String) {
        let ko = language == "ko"
        let app = launch(language, ax: false, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                               "GT_DEMO_TAB": "play"])
        let quick = app.buttons["play-quick"]
        XCTAssertTrue(quick.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts[ko ? "플레이" : "Play"].exists)
        XCTAssertFalse(app.buttons["play-continue"].exists, "No open table, no Continue row")
        XCTAssertFalse(app.staticTexts[ko ? "이어하기" : "Continue"].exists)
        XCTAssertTrue(app.staticTexts[ko ? "새 테이블 시작" : "Start a new table"].exists)
        XCTAssertEqual(quick.label, ko ? "빠른 게임, 각자 40칩. 10핸드 뒤에 끝나요."
                                       : "Quick game, 40 chips each. Ends after 10 hands.")
        let long = app.buttons["play-long"]
        XCTAssertEqual(long.label, ko ? "긴 테이블, 각자 100칩. 그만할 때까지 계속해요."
                                      : "Long table, 100 chips each. Keeps going until you stop.")
        let graded = app.buttons["play-graded"]
        XCTAssertEqual(graded.label, ko ? "1:1 채점 연습, 상대 한 명. 고른 행동이 얼마나 좋았는지 봐요."
                                        : "Graded 1:1 practice, One opponent. See how good each choice was.")
        XCTAssertLessThan(quick.frame.maxY, long.frame.minY + 1)
        XCTAssertLessThan(long.frame.maxY, graded.frame.minY + 1)
        XCTAssertFalse(app.buttons["play-quick-history"].exists, "Nothing saved, nothing to look back on")
        XCTAssertFalse(app.staticTexts[ko ? "돌아보기" : "Look back"].exists)
        let styles = app.buttons["play-style-guide"]
        XCTAssertTrue(styles.exists)
        XCTAssertEqual(styles.label, ko ? "스타일 자세히 보기" : "About the styles")
        XCTAssertLessThan(graded.frame.maxY, styles.frame.minY)
        attach(app, "\(language)-large-play-empty")
    }

    private func openQuick(_ language: String, ax: Bool) {
        let ko = language == "ko"
        let app = launch(language, ax: ax, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                            "GT_DEMO_TAB": "play", "GT_DEMO_PLAY_OPEN": "6"])
        let row = app.buttons["play-continue"]
        XCTAssertTrue(row.waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts[ko ? "이어하기" : "Continue"].exists)
        // Six hands are played first; a hand that settles before the learner acts is skipped too.
        let hand = handNumber(row.label, ko: ko)
        XCTAssertGreaterThanOrEqual(hand, 7, row.label)
        XCTAssertTrue(row.label.hasPrefix(ko ? "빠른 게임 · 4명, 핸드 \(hand)/10. 여기서는 채점하지 않아요."
                                              : "Quick game · 4 players, Hand \(hand) of 10. No grading here."), row.label)
        XCTAssertTrue(row.label.contains(ko ? "내 카드 " : "Your cards: "), "A dealt hand names its cards: \(row.label)")
        let action = app.buttons["play-continue-action"]
        XCTAssertTrue(action.exists)
        XCTAssertEqual(action.label, ko ? "이어서, 빠른 게임 · 4명" : "Continue, Quick game · 4 players")
        // The open table leads; the ways to start a new one follow it.
        XCTAssertLessThan(row.frame.maxY, app.buttons["play-quick"].frame.minY)
        let window = app.windows.firstMatch.frame
        if ax {
            XCTAssertGreaterThan(action.frame.width, window.width * 0.6, "At AX sizes the action spans the row")
            XCTAssertGreaterThan(action.frame.minY, row.frame.minY, "At AX sizes the action sits under the text")
        } else {
            XCTAssertTrue(row.isHittable && action.isHittable)
            XCTAssertLessThan(action.frame.maxY, app.tabBars.firstMatch.frame.minY)
        }
        attach(app, "\(language)-\(ax ? "ax5" : "large")-play-open")
        let history = app.buttons["play-quick-history"]
        reveal(history, in: app)
        XCTAssertTrue(history.label.hasPrefix(ko ? "게임 돌아보기, 저장된 게임 1개." : "Game review, 1 saved game."),
                      history.label)
        let styles = app.buttons["play-style-guide"]
        reveal(styles, in: app)
        XCTAssertLessThan(history.frame.maxY, styles.frame.minY)
        XCTAssertLessThan(styles.frame.maxY, app.tabBars.firstMatch.frame.minY + 1, "The last link clears the tab bar")
        attach(app, "\(language)-\(ax ? "ax5" : "large")-play-open-bottom")
    }

    private func destinations(_ language: String) {
        let ko = language == "ko"
        let app = launch(language, ax: false, ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                               "GT_DEMO_TAB": "play", "GT_DEMO_PLAY_OPEN": "6"])
        let row = app.buttons["play-continue"]
        XCTAssertTrue(row.waitForExistence(timeout: 30))
        let table = app.descendants(matching: .any)["practice-table"]
        let hand = handNumber(row.label, ko: ko)

        // Continue: the open table, from the row and from its action.
        for id in ["play-continue", "play-continue-action"] {
            app.buttons[id].tap()
            closeTableGuide(in: app)
            XCTAssertTrue(table.waitForExistence(timeout: 10), id)
            XCTAssertTrue(app.staticTexts[ko ? "네 명 · 핸드 \(hand)/10" : "Four players · Hand \(hand) of 10"].exists,
                          "The row opens the same table, at the same hand")
            app.buttons[ko ? "닫기" : "Close"].firstMatch.tap()
            XCTAssertTrue(row.waitForExistence(timeout: 5))
        }

        // Graded 1:1 practice pushes the graded table.
        app.buttons["play-graded"].tap()
        let back = app.buttons[ko ? "플레이로" : "Back to Play"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        // Game review opens the saved games.
        let history = app.buttons["play-quick-history"]
        reveal(history, in: app)
        history.tap()
        XCTAssertTrue(app.staticTexts["quick-game-coverage"].waitForExistence(timeout: 5))
        app.buttons["quick-game-close"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        // About the styles opens the style guide.
        let styles = app.buttons["play-style-guide"]
        reveal(styles, in: app)
        styles.tap()
        XCTAssertTrue(app.buttons["opponent-nit"].waitForExistence(timeout: 5))
        app.buttons[ko ? "닫기" : "Close"].firstMatch.tap()
        XCTAssertTrue(styles.waitForExistence(timeout: 5))

        // Starting a new table while one is open asks first; cancelling keeps it.
        reveal(app.buttons["play-quick"], in: app)
        app.buttons["play-quick"].tap()
        let confirm = app.buttons[ko ? "새 게임 시작" : "Start new game"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        // iOS 26 shows this dialog as a popover with no Cancel button; tapping outside cancels.
        let cancel = app.buttons[ko ? "취소" : "Cancel"]
        if cancel.exists { cancel.tap() }
        else if app.otherElements["PopoverDismissRegion"].exists { app.otherElements["PopoverDismissRegion"].tap() }
        else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.1)).tap() }
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.buttons["game-length-quick"].exists)
        XCTAssertTrue(row.exists, "Cancelling keeps the open table")

        // Long table: confirming ends the open table and sets up a long one.
        app.buttons["play-long"].tap()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.buttons["game-length-long"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game-length-long"].isSelected, "The row's length is chosen")
        app.buttons[ko ? "플레이로" : "Back to Play"].tap()
        XCTAssertTrue(app.buttons["play-quick"].waitForExistence(timeout: 5))
        XCTAssertFalse(row.exists, "The ended table is no longer open")

        // Quick game: no open table, so setup opens straight away with quick chosen.
        app.buttons["play-quick"].tap()
        XCTAssertTrue(app.buttons["game-length-quick"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game-length-quick"].isSelected)
        XCTAssertFalse(app.buttons["game-length-long"].isSelected)
    }

    /// A settled hand waits for the next deal, so the row shows no cards to name.
    private func longBetweenHands(_ language: String) {
        let ko = language == "ko"
        let store = UUID().uuidString
        let app = launch(language, ax: false, ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0",
                                               "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"])
        let fold = app.buttons["free-fold"]
        let enabled = expectation(for: NSPredicate(format: "exists == true AND isEnabled == true"), evaluatedWith: fold)
        wait(for: [enabled], timeout: 20)
        fold.tap()
        XCTAssertTrue(app.buttons["free-next-hand"].waitForExistence(timeout: 20))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_TAB": "play"]
        app.launch()
        let row = app.buttons["play-continue"]
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        XCTAssertEqual(row.label, ko ? "긴 테이블 · 4명, 1번째 핸드. 여기서는 채점하지 않아요."
                                     : "Long table · 4 players, Hand 1. No grading here.")
        XCTAssertFalse(app.buttons["play-quick-history"].exists, "A long table saves no games to review")
        attach(app, "\(language)-large-play-long-between-hands")
    }

    // MARK: Helpers

    /// The hand number the Continue row names, or 0.
    private func handNumber(_ label: String, ko: Bool) -> Int {
        let pattern = ko ? "핸드 ([0-9]+)/10" : "Hand ([0-9]+) of 10"
        guard let match = label.range(of: pattern, options: .regularExpression) else { return 0 }
        return Int(label[match].filter(\.isNumber).dropLast(2)) ?? 0
    }

    private func launch(_ language: String, ax: Bool, _ environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", language == "ko" ? "korean" : "english"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        let tabTop = app.tabBars.firstMatch.frame.minY
        for _ in 0..<12 {
            if element.exists, element.isHittable, element.frame.maxY <= tabTop { return }
            app.swipeUp()
        }
        XCTFail("\(element) is not reachable above the tab bar")
    }

    private func closeTableGuide(in app: XCUIApplication) {
        let close = app.buttons["free-table-back-close"]
        guard close.waitForExistence(timeout: 3) else { return }
        for _ in 0..<6 where !close.isHittable { app.swipeUp() }
        close.tap()
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
