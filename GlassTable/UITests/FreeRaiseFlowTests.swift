import XCTest

final class FreeRaiseFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func app(code: String = "en", ax: Bool = false, phase: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"]
        if let phase { app.launchEnvironment["GT_DEMO_FREE_PHASE"] = phase }
        app.launch()
        if phase == nil {
            let raise = app.buttons["free-raise"]
            XCTAssertTrue(raise.waitForExistence(timeout: 15))
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: raise)
            waitForExpectations(timeout: 20)
            raise.tap()
        }
        XCTAssertTrue(app.buttons["free-raise-confirm"].waitForExistence(timeout: 15))
        return app
    }

    func testOneChipTapHoldLimitsCancelAndOddCommit() {
        let app = app()
        let dock = app.otherElements["free-dock"]
        let height = dock.frame.height
        app.buttons["free-raise-cancel"].tap()
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        app.buttons["free-raise"].tap()
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        let amount = app.staticTexts["free-raise-amount"]
        let minus = app.buttons["free-raise-minus"]
        let plus = app.buttons["free-raise-plus"]
        XCTAssertEqual(amount.label, "Raise to 4")
        XCTAssertFalse(minus.isEnabled)
        plus.tap()
        XCTAssertEqual(amount.label, "Raise to 5")
        let before = amount.label
        plus.press(forDuration: 0.15, thenDragTo: app.buttons["free-table-help"])
        XCTAssertEqual(amount.label, before, "Leaving the adjustment target cancels")
        plus.press(forDuration: 2)
        XCTAssertGreaterThan(Int(amount.label.split(separator: " ").last ?? "0") ?? 0, 6, "Holding repeats at system cadence")
        let held = amount.label
        print("NATIVE_REPEAT hold2s before=\(before) held=\(held)")
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        XCTAssertEqual(amount.label, held, "Release stops repeat")
        let heldValue = Int(held.split(separator: " ").last ?? "0") ?? 0
        plus.tap()
        XCTAssertEqual(amount.label, "Raise to \(heldValue + 1)", "A new quick tap adjusts exactly once after a hold")
        app.buttons["free-raise-preset-4"].tap()
        XCTAssertEqual(app.buttons["free-raise-confirm"].label, "All in 100")
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        XCTAssertFalse(plus.isEnabled)
        minus.tap()
        XCTAssertEqual(amount.label, "Raise to 99")
        plus.press(forDuration: 0.9)
        XCTAssertEqual(amount.label, "Raise to 100")
        XCTAssertFalse(plus.isEnabled)
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        XCTAssertEqual(amount.label, "Raise to 100", "The held limit stops without another adjustment")
        app.buttons["free-raise-cancel"].tap()
        XCTAssertTrue(app.buttons["free-fold"].exists)
        app.buttons["free-raise"].tap()
        for _ in 0..<3 { plus.tap() }
        XCTAssertEqual(amount.label, "Raise to 7")
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        app.buttons["free-raise-confirm"].tap()
        XCTAssertFalse(app.buttons["free-raise-confirm"].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        let settled = app.buttons["free-next-hand"]
        let fold = app.buttons["free-fold"]
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: fold)
        waitForExpectations(timeout: 15)
        XCTAssertTrue(fold.exists || settled.exists)
    }

    func testDraggingAwayAfterRepeatStopsAndLowerLimitHolds() {
        let app = app(phase: "raise-open")
        let amount = app.staticTexts["free-raise-amount"]
        let plus = app.buttons["free-raise-plus"]
        let hero = app.otherElements["practice-0"]
        let pot = app.descendants(matching: .any)["table-pot"]
        XCTAssertTrue(hero.exists)
        XCTAssertTrue(pot.exists)
        let heroBefore = hero.label, potBefore = pot.label
        XCTAssertFalse(heroBefore.isEmpty)
        XCTAssertFalse(potBefore.isEmpty)
        plus.press(forDuration: 2, thenDragTo: app.buttons["free-table-help"],
                   withVelocity: .slow, thenHoldForDuration: 0.6)
        let afterExit = amount.label
        XCTAssertGreaterThan(Int(afterExit.split(separator: " ").last ?? "0") ?? 0, 5,
                             "Repeat started before the finger left the adjustment")
        print("NATIVE_REPEAT drag-away held=\(afterExit)")
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        XCTAssertEqual(amount.label, afterExit, "Leaving the button stops an active repeat")
        XCTAssertFalse(app.buttons["free-table-back-close"].exists)
        XCTAssertEqual(hero.label, heroBefore)
        XCTAssertEqual(pot.label, potBefore)
        app.buttons["free-raise-cancel"].tap()
        app.buttons["free-raise"].tap()
        XCTAssertEqual(amount.label, "Raise to 4")
        plus.tap()
        XCTAssertEqual(amount.label, "Raise to 5")
        let minus = app.buttons["free-raise-minus"]
        minus.press(forDuration: 2)
        XCTAssertEqual(amount.label, "Raise to 4")
        XCTAssertFalse(minus.isEnabled)
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        XCTAssertEqual(amount.label, "Raise to 4", "The lower limit stops without another adjustment")
        plus.tap()
        XCTAssertEqual(amount.label, "Raise to 5", "A new tap still adjusts exactly once")
        XCTAssertEqual(hero.label, heroBefore)
        XCTAssertEqual(pot.label, potBefore)
        capture(app, name: "native-repeat-drag-away-and-lower-limit")
    }

    func testBackgroundAndReopeningDoNotReviveReleasedRepeat() {
        let app = app(phase: "raise-open")
        let amount = app.staticTexts["free-raise-amount"]
        let plus = app.buttons["free-raise-plus"]
        plus.press(forDuration: 2)
        let held = amount.label
        XCTAssertGreaterThan(Int(held.split(separator: " ").last ?? "0") ?? 0, 5)
        let hero = app.otherElements["practice-0"].label
        let pot = app.descendants(matching: .any)["table-pot"].label
        XCTAssertFalse(hero.isEmpty)
        XCTAssertFalse(pot.isEmpty)
        XCUIDevice.shared.press(.home)
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        app.activate()
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        XCTAssertEqual(amount.label, held)
        let heldValue = Int(held.split(separator: " ").last ?? "0") ?? 0
        plus.tap()
        XCTAssertEqual(amount.label, "Raise to \(heldValue + 1)")
        app.buttons["free-raise-cancel"].tap()
        app.buttons["free-raise"].tap()
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        XCTAssertEqual(amount.label, "Raise to 4", "Reopening does not revive an earlier hold")
        XCTAssertEqual(app.otherElements["practice-0"].label, hero)
        XCTAssertEqual(app.descendants(matching: .any)["table-pot"].label, pot)
        XCTAssertFalse(app.buttons["free-next-hand"].exists)
        capture(app, name: "native-repeat-background-and-reopened-amount")
    }

    func testFacingRaiseKeepsFiveAndDuplicatePresets() {
        let app = app(phase: "raise-facing")
        XCTAssertEqual(app.staticTexts["free-raise-amount"].label, "Raise to 6")
        for index in 0..<5 { XCTAssertTrue(app.buttons["free-raise-preset-\(index)"].exists) }
        XCTAssertEqual(app.buttons["free-raise-preset-1"].label, "12, 3×")
        XCTAssertEqual(app.buttons["free-raise-preset-3"].label, "12, Pot")
        app.buttons["free-raise-preset-1"].tap()
        XCTAssertEqual(app.staticTexts["free-raise-amount"].label, "Raise to 12")
        app.buttons["free-raise-preset-3"].tap()
        XCTAssertEqual(app.staticTexts["free-raise-amount"].label, "Raise to 12")
    }

    func testShortStackKeepsIllegalPresetsDimmed() {
        let app = app(phase: "raise-short-stack")
        for index in 0..<4 {
            let preset = app.buttons["free-raise-preset-\(index)"]
            XCTAssertTrue(preset.exists)
            XCTAssertFalse(preset.isEnabled)
        }
        XCTAssertTrue(app.buttons["free-raise-preset-4"].isEnabled)
        XCTAssertFalse(app.buttons["free-raise-minus"].isEnabled)
        XCTAssertFalse(app.buttons["free-raise-plus"].isEnabled)
        XCTAssertEqual(app.buttons["free-raise-confirm"].label, "All in 3")
    }

    func testRaiseAXPanFromAdjustmentCancelsStepAndScrolls() {
        let app = app(ax: true, phase: "raise-open")
        let body = app.scrollViews["free-dock-content"]
        let plus = app.buttons["free-raise-plus"]
        reveal(plus, in: body)
        let amount = app.staticTexts["free-raise-amount"]
        let before = amount.label
        let presets = app.scrollViews["free-raise-presets"]
        let beforeY = presets.frame.minY
        let start = plus.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 24)),
                    withVelocity: .slow, thenHoldForDuration: 0.5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(amount.label, before, "A vertical pan within the adjustment target cancels its step")
        XCTAssertGreaterThan(presets.frame.minY, beforeY + 5, "The outer dock scroll receives the pan")
        capture(app, name: "raise-AX-pan-from-plus-cancels-and-scrolls")
        reveal(plus, in: body)
        plus.tap()
        XCTAssertEqual(amount.label, "Raise to 5", "The next tap works after scroll cancellation")
    }

    func testRaiseAXENHelpPillStaysInsideTheDock() {
        let app = app(code: "en", ax: true, phase: "raise-open")
        let dock = app.otherElements["free-dock"]
        let pill = app.buttons["free-table-help"]
        let word = pill.staticTexts["Decision help"]
        XCTAssertTrue(word.exists)
        let right = min(dock.frame.maxX, app.windows.firstMatch.frame.maxX)
        XCTAssertGreaterThanOrEqual(pill.frame.minX, dock.frame.minX - 0.5)
        XCTAssertLessThanOrEqual(pill.frame.maxX, right + 0.5, "The help pill must not run off the dock: \(pill.frame), dock \(dock.frame)")
        XCTAssertLessThanOrEqual(word.frame.maxX, right + 0.5)
        XCTAssertLessThan(word.frame.height, 70, "Hint must stay one complete line")
        // On narrower phones the pill beside the back arrow runs off the dock, so it has its own row.
        XCTAssertGreaterThanOrEqual(pill.frame.minY, app.buttons["free-raise-cancel"].frame.maxY - 0.5,
                                    "The help pill sits under the back button at AX sizes")
        capture(app, name: "raise-AX-en-help-pill")
    }

    func testRaiseAXKOTitleShowsEveryLine() {
        let app = app(code: "ko", ax: true, phase: "raise-open")
        let amount = app.staticTexts["free-raise-amount"]
        XCTAssertTrue(amount.exists)
        // "99칩까지 레이즈" wraps to two lines at AX5.
        let body = app.scrollViews["free-dock-content"]
        let presets = app.scrollViews["free-raise-presets"]
        reveal(presets, in: body)
        let allIn = app.buttons["free-raise-preset-4"]
        for _ in 0..<8 where allIn.frame.maxX > presets.frame.maxX + 0.5 {
            let from = presets.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            from.press(forDuration: 0.1, thenDragTo: from.withOffset(CGVector(dx: -120, dy: 0)),
                       withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        allIn.tap()
        let minus = app.buttons["free-raise-minus"]
        reveal(minus, in: body)
        minus.tap()
        XCTAssertTrue(amount.label.contains("99"), amount.label)
        reveal(amount, in: body)
        let clip = app.scrollViews["free-raise-amount-scroll"]
        if clip.exists {
            XCTAssertLessThanOrEqual(amount.frame.height, clip.frame.height + 0.5,
                                     "The raise title must not hide lines in a fixed-height box: \(amount.frame), box \(clip.frame)")
        }
        XCTAssertLessThanOrEqual(amount.frame.maxY, app.staticTexts["free-raise-context"].frame.minY + 0.5,
                                 "The raise title must end above the context line")
        capture(app, name: "raise-AX-ko-title-every-line")
    }

    func testRaiseAXKOFifthPresetAndCommitReachable() { verifyAX(code: "ko") }
    func testRaiseAXENFifthPresetAndCommitReachable() { verifyAX(code: "en") }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ element: XCUIElement, in scroll: XCUIElement) {
        let windowBottom = XCUIApplication().frame.maxY
        func visibleBounds() -> CGRect {
            scroll.frame.intersection(CGRect(x: 0, y: 0, width: XCUIApplication().frame.width,
                                           height: windowBottom - 20))
        }
        for _ in 0..<8 {
            let viewport = visibleBounds()
            let frame = element.frame
            if frame.minY >= viewport.minY, frame.maxY <= viewport.maxY { break }
            let delta = frame.maxY > viewport.maxY
                ? min(100, max(24, frame.maxY - viewport.maxY + 8))
                : -min(100, max(24, viewport.minY - frame.minY + 8))
            let presets = XCUIApplication().scrollViews["free-raise-presets"]
            let gaps = [presets.frame.maxY + 6, presets.frame.minY - 6]
            let startY = gaps.first { $0 >= viewport.minY + 8 && $0 <= windowBottom - 68 }
                ?? min(windowBottom - 68, max(viewport.minY + 8, frame.minY - 6))
            let start = scroll.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: viewport.width * 0.5, dy: startY - scroll.frame.minY))
            print("Raise reveal before=\(frame), viewport=\(viewport), startY=\(startY), delta=\(delta)")
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -delta)),
                        withVelocity: .slow, thenHoldForDuration: 0.5)
        }
        XCTAssertGreaterThanOrEqual(element.frame.minY, visibleBounds().minY - 0.5)
        XCTAssertLessThanOrEqual(element.frame.maxY, visibleBounds().maxY + 0.5)
    }

    private func verifyAX(code: String) {
        let app = app(code: code, ax: true, phase: "raise-open")
        XCTAssertTrue(app.staticTexts["free-raise-amount"].exists)
        let amount = app.staticTexts["free-raise-amount"]
        let context = app.staticTexts["free-raise-context"]
        XCTAssertFalse(app.scrollViews["free-raise-amount-scroll"].exists, "At AX sizes the title grows instead of scrolling")
        XCTAssertLessThanOrEqual(amount.frame.maxY, context.frame.minY + 0.5)
        capture(app, name: "raise-AX-\(code)-amount-every-line")
        let contextScroll = app.scrollViews["free-raise-context-scroll"]
        capture(app, name: "raise-AX-\(code)-context-first-line")
        for _ in 0..<5 where context.frame.maxY > contextScroll.frame.maxY { contextScroll.swipeUp() }
        XCTAssertLessThanOrEqual(context.frame.maxY, contextScroll.frame.maxY + 0.5)
        capture(app, name: "raise-AX-\(code)-context-last-line")
        let presets = app.scrollViews["free-raise-presets"]
        let body = app.scrollViews["free-dock-content"]
        reveal(presets, in: body)
        let allIn = app.buttons["free-raise-preset-4"]
        for _ in 0..<6 where allIn.frame.minX < presets.frame.minX || allIn.frame.maxX > presets.frame.maxX {
            presets.swipeLeft()
        }
        XCTAssertGreaterThanOrEqual(allIn.frame.minX, presets.frame.minX - 0.5)
        XCTAssertLessThanOrEqual(allIn.frame.maxX, presets.frame.maxX + 0.5)
        XCTAssertGreaterThanOrEqual(allIn.frame.minY, body.frame.minY - 0.5)
        XCTAssertLessThanOrEqual(allIn.frame.maxY, body.frame.maxY + 0.5)
        XCTAssertTrue(allIn.isHittable)
        capture(app, name: "raise-AX-\(code)-fifth-preset-full")
        allIn.tap()
        let commit = app.buttons["free-raise-confirm"]
        reveal(commit, in: body)
        XCTAssertTrue(commit.isHittable)
        XCTAssertTrue(commit.label.contains(code == "ko" ? "올인" : "All in"))
        print("Raise AX \(code): preset=\(allIn.frame), commit=\(commit.frame), body=\(body.frame)")
        capture(app, name: "raise-AX-\(code)-commit-full")
        let dockHeight = app.otherElements["free-dock"].frame.height
        app.buttons["free-raise-minus"].tap()
        XCTAssertTrue(commit.label.contains("99"))
        print("Raise AX ordinary99 \(code): commit=\(commit.frame), body=\(body.frame)")
        reveal(commit, in: body)
        XCTAssertEqual(app.otherElements["free-dock"].frame.height, dockHeight, accuracy: 0.5)
        capture(app, name: "raise-AX-\(code)-ordinary99-commit-full")
        reveal(amount, in: body)
        XCTAssertLessThanOrEqual(amount.frame.maxY, context.frame.minY + 0.5)
        capture(app, name: "raise-AX-\(code)-ordinary99-amount-every-line")
        reveal(contextScroll, in: body)
        contextScroll.swipeDown()
        capture(app, name: "raise-AX-\(code)-ordinary99-context-first-line")
        for _ in 0..<5 where context.frame.maxY > contextScroll.frame.maxY { contextScroll.swipeUp() }
        XCTAssertLessThanOrEqual(context.frame.maxY, contextScroll.frame.maxY + 0.5)
        capture(app, name: "raise-AX-\(code)-ordinary99-context-last-line")

        app.buttons["free-raise-cancel"].tap()
        XCTAssertTrue(app.buttons["free-fold"].exists)
    }
}
