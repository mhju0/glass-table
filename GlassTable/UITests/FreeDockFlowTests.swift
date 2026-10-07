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
            for _ in 0..<5 where prose.frame.maxY > body.frame.maxY || prose.frame.minY < body.frame.minY {
                let delta = prose.frame.maxY > body.frame.maxY
                    ? min(100, max(24, prose.frame.maxY - body.frame.maxY + 8))
                    : -min(100, max(24, body.frame.minY - prose.frame.minY + 8))
                let startY = delta > 0
                    ? min(body.frame.maxY - 5, max(body.frame.minY + 5, prose.frame.minY - 5))
                    : body.frame.maxY - 5
                let start = body.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: body.frame.width * 0.97, dy: startY - body.frame.minY))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -delta)),
                            withVelocity: .slow, thenHoldForDuration: 0.5)
            }
            XCTAssertGreaterThanOrEqual(prose.frame.minY, body.frame.minY - 0.5)
            XCTAssertLessThanOrEqual(prose.frame.maxY, body.frame.maxY + 0.5)
            let nextAtProse = next.frame
            let first = prose.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "You · won")).firstMatch
            let last = prose.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Alex · won")).firstMatch
            XCTAssertTrue(first.exists && last.exists)
            XCTAssertGreaterThan(last.frame.maxY - first.frame.minY, prose.frame.height,
                                 "The real three-winner fixture must overflow the bounded viewport")
            let before = last.frame.minY
            prose.swipeUp()
            XCTAssertLessThan(last.frame.minY, before, "The bounded prose must scroll at \(category)")
            XCTAssertLessThanOrEqual(last.frame.maxY, prose.frame.maxY + 0.5)
            XCTAssertEqual(next.frame.minY, nextAtProse.minY, accuracy: 0.5,
                           "Scrolling winner prose must not move the actions")
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "result-prose-scrolled-\(category)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            for _ in 0..<5 where next.frame.maxY > body.frame.maxY || next.frame.minY < body.frame.minY {
                let delta = next.frame.maxY > body.frame.maxY
                    ? min(100, max(24, next.frame.maxY - body.frame.maxY + 8))
                    : -min(100, max(24, body.frame.minY - next.frame.minY + 8))
                let startY = min(body.frame.maxY - 5, max(body.frame.minY + 5, next.frame.minY - 5))
                let start = body.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: body.frame.width * 0.97, dy: startY - body.frame.minY))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -delta)),
                            withVelocity: .slow, thenHoldForDuration: 0.5)
            }
            XCTAssertGreaterThanOrEqual(next.frame.minY, body.frame.minY - 0.5)
            XCTAssertLessThanOrEqual(next.frame.maxY, body.frame.maxY + 0.5)
            let nextCapture = XCTAttachment(screenshot: app.screenshot())
            nextCapture.name = "result-next-control-\(category)"
            nextCapture.lifetime = .keepAlways
            add(nextCapture)
            XCTAssertTrue(next.isHittable)
            let lastAction = app.buttons["free-change-table"]
            for _ in 0..<20 where lastAction.frame.maxY > body.frame.maxY || lastAction.frame.minY < body.frame.minY {
                let delta = lastAction.frame.maxY > body.frame.maxY
                    ? min(100, max(24, lastAction.frame.maxY - body.frame.maxY + 8))
                    : -min(100, max(24, body.frame.minY - lastAction.frame.minY + 8))
                let startY = min(body.frame.maxY - 5, max(body.frame.minY + 5, lastAction.frame.minY - 5))
                let start = body.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: body.frame.width * 0.97, dy: startY - body.frame.minY))
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -delta)),
                            withVelocity: .slow, thenHoldForDuration: 0.5)
            }
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
                var visible = false
                for _ in 0..<8 {
                    let viewport = scroll.frame
                    let frame = slot.frame
                    if frame.minY >= viewport.minY, frame.maxY <= viewport.maxY {
                        visible = true
                        break
                    }
                    scroll.swipeUp()
                }
                XCTAssertTrue(visible, "\(code) \(phase) \(slot.identifier): \(slot.frame), viewport \(scroll.frame)")
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
