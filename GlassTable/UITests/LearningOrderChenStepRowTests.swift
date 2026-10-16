// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// D48 lesson order on the path, the Chen score rule card, and Previous/Next on the
/// shared 36/64 step row.
final class LearningOrderChenStepRowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ language: String, ax: Bool = false, _ environment: [String: String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
                               "-glassTable.language", language == "ko" ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_LANGUAGE": language].merging(environment) { $1 }
        app.launch()
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, up: Bool = false) {
        for _ in 0..<20 where !element.isHittable { up ? app.swipeDown() : app.swipeUp() }
        XCTAssertTrue(element.isHittable, element.debugDescription)
    }

    // MARK: Task 1 · order

    func testPathListsTheLessonsInTheSuggestedOrder() { pathOrder(ax: false) }
    func testPathListsTheLessonsInTheSuggestedOrderAX5() { pathOrder(ax: true) }

    private func pathOrder(ax: Bool) {
        let app = launch("en", ax: ax, ["GT_DEMO_TAB": "path"])
        let order = ["u1-showdown", "u1-position", "u3-rfi", "u8-defend", "u4-rangeRead", "u7-actionRead",
                     "u2-outs", "u1-potMath", "u2-equitySense", "u2-potOdds", "u2-callFold"]
        let first = app.buttons["lesson-\(order[0])"]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        attach(app, "path-top-\(ax ? "AX5" : "L")")
        XCTAssertTrue(first.label.hasPrefix("Who wins"), first.label)
        // Rows of a plain stack keep their frames off screen, so order is read in one pass.
        let tops = order.map { app.buttons["lesson-\($0)"].frame.minY }
        XCTAssertEqual(tops, tops.sorted(), "\(zip(order, tops).map { "\($0) \($1)" })")
        for track in ["basics", "startingHands", "readingOpponents", "priceAndChance"] {
            XCTAssertTrue(app.descendants(matching: .any)["track-\(track)"].exists, track)
        }
        let basics = app.descendants(matching: .any)["track-basics"].frame.minY
        let reading = app.descendants(matching: .any)["track-readingOpponents"].frame.minY
        let price = app.descendants(matching: .any)["track-priceAndChance"].frame.minY
        XCTAssertLessThan(basics, reading)
        XCTAssertLessThan(reading, price)
    }

    // MARK: Task 2 · Chen rule card

    func testChenRuleCardSimpleEnglish() { chen("en", level: "newToPoker", ax: false) }
    func testChenRuleCardSimpleKorean() { chen("ko", level: "newToPoker", ax: false) }
    func testChenRuleCardRegularEnglish() { chen("en", level: "playRegularly", ax: false) }
    func testChenRuleCardRegularKoreanAX5() { chen("ko", level: "playRegularly", ax: true) }
    func testChenRuleCardSimpleEnglishAX5() { chen("en", level: "newToPoker", ax: true) }

    private func chen(_ language: String, level: String, ax: Bool) {
        let app = launch(language, ax: ax, ["GT_DEMO_NODE": "u3-rfi", "GT_DEMO_BEAT": "2", "GT_DEMO_LEVEL": level])
        let title = language == "ko" ? "점수 계산법" : "How the score works"
        let disclosure = app.buttons[title]
        XCTAssertTrue(disclosure.waitForExistence(timeout: 15), "The rule card sits behind a disclosure")
        let card = app.descendants(matching: .any)["chen-rule-card"]
        XCTAssertFalse(card.exists, "Closed until asked for")
        scrollTo(disclosure, in: app)
        disclosure.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let source = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Bill Chen")).firstMatch
        XCTAssertTrue(source.exists)
        let limit = language == "ko" ? "차트용으로 패를 줄 세우는 점수예요. 이길 확률이 아니에요."
            : "It sorts hands for the chart. It is not your chance of winning."
        let closing = app.staticTexts[limit]
        XCTAssertTrue(closing.exists)
        let yours = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@",
                                                           language == "ko" ? "내 패 " : "Your hand ")).firstMatch
        XCTAssertTrue(yours.exists)
        scrollTo(yours, in: app)
        attach(app, "chen-\(level)-\(language)-\(ax ? "AX5" : "L")")
        scrollTo(closing, in: app)
        attach(app, "chen-\(level)-\(language)-\(ax ? "AX5" : "L")-end")
        XCTAssertTrue(app.buttons["walkthrough-next"].exists)
    }

    // MARK: Task 3 · step row

    private func assertStepRow(previous: XCUIElement, next: XCUIElement, ax: Bool,
                               file: StaticString = #filePath, line: UInt = #line) {
        if ax {
            XCTAssertLessThanOrEqual(previous.frame.maxY, next.frame.minY + 1, "Stacked, Previous on top",
                                     file: file, line: line)
        } else {
            XCTAssertEqual(previous.frame.midY, next.frame.midY, accuracy: 2, "One row", file: file, line: line)
            XCTAssertLessThan(previous.frame.width, next.frame.width * 0.7, "Previous is the narrow one",
                              file: file, line: line)
            XCTAssertLessThan(previous.frame.maxX, next.frame.minX, file: file, line: line)
        }
    }

    func testWalkthroughStepRow() { walkthrough(ax: false) }
    func testWalkthroughStepRowAX5() { walkthrough(ax: true) }

    private func walkthrough(ax: Bool) {
        let app = launch("en", ax: ax, ["GT_DEMO_NODE": "u3-rfi", "GT_DEMO_BEAT": "0"])
        let next = app.buttons["walkthrough-next"]
        let previous = app.buttons["walkthrough-previous"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        XCTAssertFalse(previous.exists, "No Previous on the first step")
        scrollTo(next, in: app)
        next.tap()
        XCTAssertTrue(previous.waitForExistence(timeout: 5))
        scrollTo(previous, in: app)
        XCTAssertTrue(next.isHittable || { scrollTo(next, in: app); return next.isHittable }())
        assertStepRow(previous: previous, next: next, ax: ax)
        attach(app, "steprow-walkthrough-\(ax ? "AX5" : "L")")
        previous.tap()
        XCTAssertTrue(app.descendants(matching: .any)["walkthrough-step-0"].waitForExistence(timeout: 5))
    }

    func testLearningGuideStepRow() { guide(ax: false) }
    func testLearningGuideStepRowAX5() { guide(ax: true) }

    private func guide(ax: Bool) {
        let app = launch("en", ax: ax, ["GT_DEMO_SETTINGS": "1", "GT_DEMO_GUIDE": "1"])
        let next = app.buttons["guide-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["guide-previous"].exists, "No Previous on the first page")
        app.terminate()
        let second = launch("en", ax: ax, ["GT_DEMO_SETTINGS": "1", "GT_DEMO_GUIDE": "1", "GT_DEMO_GUIDE_PAGE": "2"])
        let previous = second.buttons["guide-previous"]
        let secondNext = second.buttons["guide-next"]
        XCTAssertTrue(previous.waitForExistence(timeout: 15))
        XCTAssertTrue(previous.isHittable)
        XCTAssertTrue(secondNext.isHittable)
        assertStepRow(previous: previous, next: secondNext, ax: ax)
        attach(second, "steprow-guide-\(ax ? "AX5" : "L")")
    }
}
