import XCTest

final class ReviewTeachingFollowupTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testSharpPotMathNamesTheFlopAtTheExistingBetStep() {
        let app = launch(node: "u1-potMath.3", regular: false, extra: ["GT_DEMO_POT_STATE": "question"])
        let current = app.staticTexts["pot-active-action"]
        XCTAssertTrue(current.waitForExistence(timeout: 15))
        XCTAssertTrue(current.label.contains("Flop"), current.label)
        let previous = app.buttons["pot-previous-action"]
        reach(previous, in: app)
        previous.tap() // final call -> first flop bet; no new indexed replay action
        XCTAssertTrue(current.label.contains("Bets"), current.label)
        XCTAssertTrue(current.label.contains("Flop"), current.label)
        let transition = current.label
        previous.tap() // first flop bet -> final preflop call
        XCTAssertTrue(current.label.contains("Preflop"), current.label)
        XCTAssertFalse(current.label.contains("paid chips stay"), current.label)
        app.buttons["pot-next-action"].tap()
        XCTAssertTrue(current.label.contains("Flop"), current.label)
        XCTAssertEqual(current.label, transition, "Returning to the same saved index replays the same action")
        attach(app, "sharp-potmath-flop-transition")
    }

    func testSimpleSharpActionReadKeepsItsAssumptionAfterRelaunch() { actionAssumption(regular: false) }
    func testAdvancedSharpActionReadKeepsItsAssumptionAfterRelaunch() { actionAssumption(regular: true) }

    func testRangeSliderReversesWithoutCommittingOrChangingTheQuestion() throws {
        let app = launch(node: "u4-rangeRead", regular: true)
        let slider = app.sliders["Range width"]
        reach(slider, in: app)
        let opponent = app.staticTexts["range-read-opponent"].label
        let rows = app.otherElements.matching(NSPredicate(format: "label BEGINSWITH %@", "Row "))
        XCTAssertEqual(rows.count, 13)
        let before = rows.allElementsBoundByIndex.map(\.label)
        func widthValue() throws -> Int {
            let text = try XCTUnwrap(slider.value as? String)
            let number = try XCTUnwrap(text.split(separator: " ").first)
            return try XCTUnwrap(Int(number))
        }
        let value = try XCTUnwrap(slider.value as? String)
        let initialWidth = try widthValue()
        print("MOTION_SLIDER frame=\(slider.frame) value=\(value)")
        let start = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.23, dy: 0.5))
        let end = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        start
            .press(forDuration: 0.05,
                   thenDragTo: end,
                   withVelocity: .slow, thenHoldForDuration: 0)
        print("MOTION_SLIDER dragged-value=\(slider.value as? String ?? "nil")")
        let widerWidth = try widthValue()
        let widerRows = rows.allElementsBoundByIndex.map(\.label)
        XCTAssertGreaterThan(widerWidth, initialWidth)
        XCTAssertNotEqual(widerRows, before,
                          "The range grid follows the slider's changed estimate")
        let returnPoint = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        end.press(forDuration: 0.05, thenDragTo: returnPoint,
                  withVelocity: .slow, thenHoldForDuration: 0)
        print("MOTION_SLIDER reversed-value=\(try widthValue())")
        XCTAssertLessThan(try widthValue(), widerWidth)
        XCTAssertNotEqual(rows.allElementsBoundByIndex.map(\.label), widerRows,
                          "The grid follows the reversed drag")
        // A frame coordinate is not an exact stepped value on every iOS release.
        // Restore with the same ±1 controls available to the learner.
        for _ in 0..<77 {
            let current = try widthValue()
            if current == initialWidth { break }
            app.buttons[current > initialWidth ? "Decrease Range width" : "Increase Range width"].tap()
        }
        XCTAssertEqual(slider.value as? String, value)
        XCTAssertEqual(rows.allElementsBoundByIndex.map(\.label), before,
                       "Restoring the original estimate restores the same range")
        XCTAssertEqual(app.staticTexts["range-read-opponent"].label, opponent)
        XCTAssertFalse(app.descendants(matching: .any)["range-difference-list"].exists,
                       "Dragging is not an answer commitment")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "drill-completion-")).firstMatch.exists)
        attach(app, "range-slider-reversed-before-commit")
    }

    func testSharpRangeReadKeepsItsAssumedOpponentAfterRelaunch() {
        let store = UUID().uuidString
        let app = launch(node: "u4-rangeRead.3", regular: false, store: store)
        let opponent = app.staticTexts["range-read-opponent"]
        XCTAssertTrue(opponent.waitForExistence(timeout: 15))
        XCTAssertTrue(opponent.label.hasPrefix("This exercise assumes"), opponent.label)
        let premise = opponent.label
        let choice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'range-estimate-choice-'")).firstMatch
        reach(choice, in: app)
        choice.tap()
        let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'drill-completion-'")).firstMatch
        XCTAssertTrue(completion.waitForExistence(timeout: 15))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume, in: app)
        resume.tap()
        XCTAssertTrue(opponent.waitForExistence(timeout: 15))
        XCTAssertEqual(opponent.label, premise)
        XCTAssertTrue(completion.exists)
        attach(app, "restored-range-read-assumption")
    }

    private func actionAssumption(regular: Bool) {
        let store = UUID().uuidString
        let app = launch(node: "u7-actionRead.3", regular: regular, store: store)
        let opponent = app.staticTexts["action-read-opponent"]
        XCTAssertTrue(opponent.waitForExistence(timeout: 15))
        XCTAssertTrue(opponent.label.hasPrefix("This exercise assumes"), opponent.label)
        let policy = app.staticTexts["action-read-policy"]
        XCTAssertTrue(policy.exists)
        XCTAssertTrue(policy.label.hasPrefix("Model rule"), policy.label)
        let premise = opponent.label, rule = policy.label
        let answer = regular ? app.buttons["Check answer"]
            : app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'lesson-estimate-choice-'")).firstMatch
        reach(answer, in: app)
        answer.tap()
        let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'drill-completion-'")).firstMatch
        XCTAssertTrue(completion.waitForExistence(timeout: 15))
        app.terminate()
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_TEST_FIRST_PLACEMENT": "0", "GT_DEMO_LEVEL": regular ? "playRegularly" : "newToPoker"]
        app.launch()
        let resume = app.buttons["learn-continue"]
        reach(resume, in: app)
        resume.tap()
        XCTAssertTrue(opponent.waitForExistence(timeout: 15))
        XCTAssertEqual(opponent.label, premise)
        XCTAssertEqual(policy.label, rule)
        XCTAssertTrue(completion.exists)
        attach(app, regular ? "advanced-restored-action-assumption" : "simple-restored-action-assumption")
    }

    private func launch(node: String, regular: Bool, store: String = UUID().uuidString,
                        extra: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-glassTable.language", "english"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": store, "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0",
                                 "GT_DEMO_NODE": node, "GT_DEMO_LEVEL": regular ? "playRegularly" : "newToPoker"]
            .merging(extra) { _, new in new }
        app.launch()
        return app
    }

    private func reach(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable, element.identifier)
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
