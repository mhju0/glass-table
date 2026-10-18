import XCTest

final class FreeDockFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func tableApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_LANGUAGE": "en",
                                 "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"]
        app.launch()
        let fold = app.buttons["free-fold"]
        XCTAssertTrue(fold.waitForExistence(timeout: 15))
        let ready = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: fold)
        wait(for: [ready], timeout: 20)
        return app
    }

    func testFixedSlotsCancelPressAndPreserveHeightThroughRaiseAndFold() {
        let app = tableApp()
        let dock = app.descendants(matching: .any)["free-dock"]
        let fold = app.buttons["free-fold"]
        let call = app.buttons["free-call"]
        let raise = app.buttons["free-raise"]
        XCTAssertEqual(fold.label, "Give up, Fold")
        XCTAssertEqual(call.label, "Add 2, Call")
        XCTAssertEqual(raise.label, "Increase, Raise")
        XCTAssertEqual(fold.frame.height, 87, accuracy: 0.5)
        XCTAssertEqual(call.frame.height, 87, accuracy: 0.5)
        XCTAssertEqual(raise.frame.height, 87, accuracy: 0.5)
        XCTAssertLessThan(fold.frame.midX, call.frame.midX)
        XCTAssertLessThan(call.frame.midX, raise.frame.midX)
        let height = dock.frame.height
        fold.press(forDuration: 0.2, thenDragTo: app.buttons["free-table-help"])
        XCTAssertTrue(fold.isEnabled, "Sliding off must cancel the action")
        XCTAssertFalse(app.buttons["free-next-hand"].exists)
        raise.tap()
        XCTAssertTrue(app.buttons["free-raise-cancel"].waitForExistence(timeout: 5))
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        app.buttons["free-raise-cancel"].tap()
        fold.tap()
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        let skip = app.buttons["free-skip-result"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        XCTAssertTrue(app.buttons["free-next-hand"].waitForExistence(timeout: 15))
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "fixed-height-result"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCheckingKeepsDisabledFoldSlot() {
        let app = tableApp()
        let deadline = Date().addingTimeInterval(45)
        while Date() < deadline {
            let check = app.buttons["free-check"]
            if check.exists && check.isEnabled { break }
            if app.buttons["free-next-hand"].exists { break }
            let call = app.buttons["free-call"]
            if call.exists && call.isEnabled {
                call.tap()
                RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            } else {
                RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            }
        }
        let check = app.buttons["free-check"]
        XCTAssertTrue(check.exists && check.isEnabled)
        XCTAssertEqual(check.label, "Pass, Check")
        XCTAssertTrue(app.buttons["free-fold"].exists)
        XCTAssertFalse(app.buttons["free-fold"].isEnabled)
        XCTAssertTrue(app.buttons["free-raise"].exists)
    }

    func testMathPillOpensExistingPreflopPanel() {
        let app = tableApp()
        let math = app.buttons["free-table-help"]
        XCTAssertTrue(math.label.contains("Decision help"))
        math.tap()
        XCTAssertTrue(app.descendants(matching: .any)["free-table-help-sheet"].waitForExistence(timeout: 5))
    }

    func testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes() {
        for category in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(en)", "-glassTable.language", "english",
                                   "-UIPreferredContentSizeCategoryName", category]
            app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
                "GT_DEMO_FREE_PHASE": "result-tie"]
            app.launch()
            let next = app.buttons["free-next-hand"]
            XCTAssertTrue(next.waitForExistence(timeout: 15))
            let body = app.scrollViews["free-result-body"]
            XCTAssertTrue(app.staticTexts["free-table-net"].exists)
            let nextBefore = next.frame
            let prose = app.scrollViews["free-result-prose"]
            bring(prose, into: body)
            XCTAssertGreaterThanOrEqual(prose.frame.minY, body.frame.minY - 0.5)
            XCTAssertLessThanOrEqual(prose.frame.maxY, body.frame.maxY + 0.5)
            next.waitForStableFrame()
            let nextAtProse = next.frame
            let first = prose.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "You · won")).firstMatch
            let last = prose.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Alex · won")).firstMatch
            XCTAssertTrue(first.exists && last.exists)
            XCTAssertGreaterThan(last.frame.maxY - first.frame.minY, prose.frame.height,
                                 "The real three-winner fixture must overflow the bounded viewport")
            let before = last.frame.minY
            for _ in 0..<12 where last.frame.maxY > prose.frame.maxY + 0.5 {
                let travel = max(24, min(prose.frame.height - 30, last.frame.maxY - prose.frame.maxY + 8))
                prose.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).slowDrag(by: CGVector(dx: 0, dy: -travel))
                last.waitForStableFrame()
            }
            XCTAssertLessThan(last.frame.minY, before, "The bounded prose must scroll at \(category)")
            XCTAssertLessThanOrEqual(last.frame.maxY, prose.frame.maxY + 0.5)
            next.waitForStableFrame()
            XCTAssertEqual(next.frame.minY, nextAtProse.minY, accuracy: 0.5,
                           "Scrolling winner prose must not move the actions")
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "result-prose-scrolled-\(category)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            bring(next, into: body)
            XCTAssertGreaterThanOrEqual(next.frame.minY, body.frame.minY - 0.5)
            XCTAssertLessThanOrEqual(next.frame.maxY, body.frame.maxY + 0.5)
            let nextCapture = XCTAttachment(screenshot: app.screenshot())
            nextCapture.name = "result-next-control-\(category)"
            nextCapture.lifetime = .keepAlways
            add(nextCapture)
            XCTAssertTrue(next.isHittable)
            let lastAction = app.buttons["free-change-table"]
            bring(lastAction, into: body)
            XCTAssertTrue(lastAction.isHittable)
            XCTAssertGreaterThanOrEqual(lastAction.frame.minY, body.frame.minY - 0.5)
            XCTAssertLessThanOrEqual(lastAction.frame.maxY, body.frame.maxY + 0.5,
                                     "The full last result action remains reachable")
            print("Result reach \(category): body=\(body.frame), prose=\(prose.frame), last=\(lastAction.frame), initialNext=\(nextBefore)")
            let lastCapture = XCTAttachment(screenshot: app.screenshot())
            lastCapture.name = "result-last-controls-\(category)"
            lastCapture.lifetime = .keepAlways
            add(lastCapture)
            app.terminate()
        }
    }


    /// Drags the result body slowly until `target` sits fully inside it, waiting for each
    /// drag to settle. Drags run at the body's trailing margin so the prose scroll inside
    /// it does not take the pan.
    private func bring(_ target: XCUIElement, into body: XCUIElement) {
        for _ in 0..<30 {
            target.waitForStableFrame()
            let frame = target.frame, viewport = body.frame
            if frame.minY >= viewport.minY - 0.5, frame.maxY <= viewport.maxY + 0.5 { return }
            let up = frame.maxY > viewport.maxY
            let distance = up ? frame.maxY - viewport.maxY + 8 : viewport.minY - frame.minY + 8
            // A 24pt drag that starts just above Next hand tapped it on a GitHub runner (the
            // recording shows the press, then the demo's "Couldn't apply" alert). Longer
            // drags from the same spot scrolled cleanly, so move at least 60pt when the
            // target still fits; the loop corrects any overshoot.
            let floor = max(24, min(60, viewport.height - frame.height - 16))
            let amount = max(floor, min(viewport.height - 60, distance + 2))
            let startY = up ? min(viewport.maxY - 5, max(viewport.minY + 5, frame.minY - 5)) : viewport.minY + 5
            body.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: viewport.width * 0.97, dy: startY - viewport.minY))
                .slowDrag(by: CGVector(dx: 0, dy: up ? -amount : amount))
        }
        target.waitForStableFrame()
    }

    private func fixtureApp(phase: String?, code: String = "en", accessibility: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language",
                               code == "ko" ? "korean" : "english"]
        if accessibility {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
            "GT_TEST_FIRST_LESSON": "0", "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"]
        if let phase { app.launchEnvironment["GT_DEMO_FREE_PHASE"] = phase }
        app.launch()
        XCTAssertTrue(app.buttons["free-fold"].waitForExistence(timeout: 15))
        return app
    }

    func testNormalSlotWidthsAndCentersStayFixedForCallAndAllIn() {
        var baseline: [CGRect] = []
        for phase in [nil, "all-in-call", "short-all-in"] as [String?] {
            let app = fixtureApp(phase: phase)
            let slots = [app.buttons["free-fold"], app.buttons["free-call"], app.buttons["free-raise"]]
            XCTAssertTrue(slots[1].waitForExistence(timeout: 5))
            let frames = slots.map(\.frame)
            print("Free dock normal slots \(phase ?? "call"): \(frames)")
            if baseline.isEmpty { baseline = frames }
            for (index, frame) in frames.enumerated() {
                XCTAssertEqual(frame.width, baseline[index].width, accuracy: 0.5)
                XCTAssertEqual(frame.midX, baseline[index].midX, accuracy: 0.5)
                XCTAssertEqual(frame.height, 87, accuracy: 0.5)
            }
            app.terminate()
        }
    }

    func testAXKODockSlotsAndBarsRemainReachable() { verifyAXDock(code: "ko") }
    func testAXENDockSlotsAndBarsRemainReachable() { verifyAXDock(code: "en") }

    private func verifyAXDock(code: String) {
        for phase in ["computer", "dealing", "runout", "all-in-call", "short-all-in"] {
            let app = fixtureApp(phase: phase, code: code, accessibility: true)
            let scroll = app.scrollViews["free-dock-content"]
            XCTAssertTrue(scroll.exists)
            if code == "en" {
                let math = app.buttons["free-table-help"].staticTexts["Decision help"]
                XCTAssertTrue(math.exists)
                XCTAssertLessThan(math.frame.height, 70, "Hint must stay one complete word")
            }
            let middle = app.buttons["free-call"].exists ? app.buttons["free-call"] : app.buttons["free-check"]
            let slots = [app.buttons["free-fold"], middle, app.buttons["free-raise"]]
            for slot in slots {
                XCTAssertLessThanOrEqual(slot.frame.height, scroll.frame.height,
                                         "A complete action slot must fit inside the dock viewport")
                var visible = false
                for _ in 0..<8 {
                    let viewport = scroll.frame
                    let frame = slot.frame
                    if frame.minY >= viewport.minY, frame.maxY <= viewport.maxY {
                        visible = true
                        break
                    }
                    let travelLimit = min(80, viewport.height / 2 - 8)
                    let delta = frame.minY < viewport.minY
                        ? -min(travelLimit, max(24, viewport.minY - frame.minY + 8))
                        : min(travelLimit, max(24, frame.maxY - viewport.maxY + 8))
                    print("Free dock AX drag \(code) \(phase) \(slot.identifier): slot=\(frame), viewport=\(viewport), delta=\(delta)")
                    let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    start.press(forDuration: 0.05,
                                thenDragTo: start.withOffset(CGVector(dx: 0, dy: -delta)),
                                withVelocity: .slow, thenHoldForDuration: 0.5)
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                }
                XCTAssertTrue(visible, "\(code) \(phase) \(slot.identifier): \(slot.frame), viewport \(scroll.frame)")
                print("Free dock AX reachable \(code) \(phase) \(slot.identifier): slot=\(slot.frame), viewport=\(scroll.frame)")
                if phase == "all-in-call", slot.identifier == "free-fold" {
                    let capture = XCTAttachment(screenshot: app.screenshot())
                    capture.name = "AX-dock-\(code)-\(phase)-fold-fully-visible"
                    capture.lifetime = .keepAlways
                    add(capture)
                    let hierarchy = XCTAttachment(string: app.debugDescription)
                    hierarchy.name = "AX-dock-\(code)-\(phase)-fold-hierarchy"
                    hierarchy.lifetime = .keepAlways
                    add(hierarchy)
                }
            }
            print("Free dock AX \(code) \(phase): slots=\(slots.map(\.frame)), viewport=\(scroll.frame)")
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "AX-dock-\(code)-\(phase)-full-slots"
            capture.lifetime = .keepAlways
            add(capture)
            app.terminate()
        }
    }

}
