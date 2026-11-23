// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class UnitAFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPrivateCardsResumeAndRetrySameDeal() {
        let app = launch(start: "1")
        XCTAssertTrue(activity("A1-example", app).exists)
        attach(app, "unit-a-private-cards-en-light")
        tap("next", app)

        let first = activity("A1-01", app)
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let original = cards(in: app)
        XCTAssertFalse(original.isEmpty)
        XCTAssertFalse(element("explanation", app).exists)
        XCTAssertFalse(button("submit", app).isEnabled)
        tap("choice-1", app)
        reopen(app)
        XCTAssertTrue(first.exists)
        XCTAssertEqual(cards(in: app), original)
        XCTAssertFalse(element("explanation", app).exists)
        XCTAssertTrue(button("submit", app).isEnabled)
        tap("submit", app)
        XCTAssertEqual(element("feedback", app).label, "Take another look")
        let explanation = element("explanation", app).label

        reopen(app)
        XCTAssertEqual(element("explanation", app).label, explanation)
        XCTAssertFalse(button("submit", app).exists)
        tap("next", app)
        for correct in [1, 1, 0] { answer(correct, in: app) }

        XCTAssertEqual(element("phase", app).label, "Try the missed question again")
        XCTAssertTrue(first.exists)
        XCTAssertEqual(cards(in: app), original)
        XCTAssertFalse(element("explanation", app).exists)
        XCTAssertFalse(button("submit", app).isEnabled)
        attach(app, "unit-a-exact-retry-en-light")
        answer(0, in: app)
        XCTAssertEqual(element("first-score", app).label, "3 of 4 correct")
        XCTAssertEqual(element("retry-score", app).label, "1 of 1 correct")
        tap("next", app)
        XCTAssertTrue(activity("A2-example", app).exists)
        for suit in ["Hearts", "Diamonds", "Clubs", "Spades"] {
            XCTAssertTrue(app.staticTexts[suit].exists)
        }
        attach(app, "unit-a-rank-and-suit-en-light")
    }

    func testStageControlsRevealSharedCardsInOrder() {
        let app = launch(start: "streets")
        XCTAssertTrue(activity("A4-preflop", app).exists)
        let board = element("cards-shared", app)
        XCTAssertEqual(board.value as? String, "No cards yet")
        let privateCards = element("cards-mine", app).value as? String
        XCTAssertNotNil(privateCards)
        attach(app, "unit-a-preflop-en-light")

        var previous: [String] = []
        for (stage, count) in [("flop", 3), ("turn", 4), ("river", 5)] {
            tap("next", app)
            XCTAssertTrue(activity("A4-\(stage)", app).exists)
            XCTAssertEqual(element("cards-mine", app).value as? String, privateCards)
            let visible = spokenCards(board)
            XCTAssertEqual(visible.count, count)
            XCTAssertEqual(Array(visible.prefix(previous.count)), previous)
            previous = visible
            if stage == "flop" || stage == "river" { attach(app, "unit-a-\(stage)-en-light") }
        }
        tap("next", app)
        XCTAssertTrue(activity("A4-01", app).exists)
    }

    func testFoldEndingHidesCardsAndShowdownRevealsAtAX5() {
        let fold = launch(start: "endings")
        tap("next", fold)
        XCTAssertTrue(activity("A5-branch", fold).exists)
        XCTAssertFalse(element("cards-opponent", fold).exists)
        tap("choice-0", fold)
        tap("submit", fold)
        XCTAssertEqual(element("feedback", fold).label, "This hand has ended")
        XCTAssertFalse(element("cards-opponent", fold).exists)
        XCTAssertEqual(spokenCards(element("cards-shared", fold)).count, 3)
        attach(fold, "unit-a-fold-en-light")
        tap("next", fold)
        XCTAssertTrue(activity("A5-01", fold).exists)
        for index in [1, 0, 1, 0] { answer(index, in: fold) }
        XCTAssertEqual(element("title", fold).label, "Checkpoint results")
        XCTAssertEqual(element("first-score", fold).label, "4 of 4 correct")
        tap("next", fold)
        XCTAssertEqual(element("title", fold).label, "Unit complete")
        XCTAssertEqual(element("first-score", fold).label, "4 of 4 correct")
        XCTAssertTrue(element("earlier-a1", fold).label.contains("First answers 2/4"))
        XCTAssertTrue(element("earlier-a4", fold).exists)
        attach(fold, "unit-a-complete-en-light")
        fold.terminate()

        let showdown = launch(start: "endings", english: false, largeText: true)
        tap("next", showdown)
        XCTAssertTrue(activity("A5-branch", showdown).exists)
        XCTAssertFalse(element("cards-opponent", showdown).exists)
        tap("choice-1", showdown)
        tap("submit", showdown)
        XCTAssertEqual(element("feedback", showdown).label, "핸드 종료")
        XCTAssertEqual(spokenCards(element("cards-opponent", showdown)).count, 2)
        XCTAssertEqual(spokenCards(element("cards-shared", showdown)).count, 5)
        XCTAssertTrue(button("next", showdown).isHittable)
        reveal(element("explanation", showdown), in: showdown)
        attach(showdown, "unit-a-showdown-ko-dark-ax5")
        tap("next", showdown)
        XCTAssertTrue(activity("A5-01", showdown).exists)
        XCTAssertFalse(element("explanation", showdown).exists)
        tap("choice-0", showdown)
        reopen(showdown)
        XCTAssertTrue(activity("A5-01", showdown).exists)
        XCTAssertTrue(button("submit", showdown).isEnabled)
        reveal(button("choice-0", showdown), in: showdown)
        attach(showdown, "unit-a-checkpoint-ko-dark-ax5")
    }

    private func launch(start: String, english: Bool = true, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_UNIT_A": start, "GT_DEMO_LANGUAGE": english ? "en" : "ko"]
        app.launchArguments = ["-appAppearance", english ? "light" : "dark",
                               "-UIPreferredContentSizeCategoryName",
                               largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        XCTAssertTrue(button("close", app).waitForExistence(timeout: 15))
        return app
    }

    private func reopen(_ app: XCUIApplication) {
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GT_DEMO_UNIT_A")
        app.launch()
        let row = app.buttons["learn-unit-a"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        for _ in 0..<5 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.isHittable)
        row.tap()
        XCTAssertTrue(button("close", app).waitForExistence(timeout: 10))
    }

    private func answer(_ index: Int, in app: XCUIApplication) {
        tap("choice-\(index)", app)
        tap("submit", app)
        tap("next", app)
    }

    private func tap(_ name: String, _ app: XCUIApplication) {
        let target = button(name, app)
        XCTAssertTrue(target.waitForExistence(timeout: 6), name)
        if name.hasPrefix("choice-") { reveal(target, in: app) }
        XCTAssertTrue(target.isHittable, name)
        target.tap()
    }

    private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews["unit-a-scroll"]
        let submit = button("submit", app)
        let dock = submit.exists ? submit : button("next", app)
        let top = button("close", app).frame.maxY
        let bottom = dock.frame.minY
        func reachable() -> Bool {
            target.isHittable && target.frame.midY > top && target.frame.midY < bottom
        }
        for _ in 0..<8 where !reachable() {
            if target.frame.midY < top { scroll.swipeDown() } else { scroll.swipeUp() }
        }
        XCTAssertTrue(reachable(), target.debugDescription)
    }

    private func cards(in app: XCUIApplication) -> [String] {
        ["mine", "shared", "opponent", "example"].compactMap { role in
            let cardGroup = element("cards-\(role)", app)
            return cardGroup.exists ? cardGroup.value as? String : nil
        }
    }

    private func spokenCards(_ group: XCUIElement) -> [String] {
        (group.value as? String)?.components(separatedBy: ", ")
            .filter { $0 != "highlighted" && $0 != "강조" } ?? []
    }

    private func activity(_ id: String, _ app: XCUIApplication) -> XCUIElement {
        element("activity-\(id)", app)
    }

    private func button(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons["unit-a-\(name)"]
    }

    private func element(_ name: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "unit-a-\(name)").firstMatch
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
