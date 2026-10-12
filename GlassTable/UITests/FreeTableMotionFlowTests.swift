import XCTest

final class FreeTableMotionFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ kind: String, start: String? = nil, slow: Bool = false,
                        reduced: Bool = false, language: String = "en", ax: Bool = false,
                        frozen: Bool = false, fraction: Double = 0) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-glassTable.language", language == "ko" ? "korean" : "english"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
            "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1", "GT_DEMO_FREE_MOTION": kind,
            "GT_DEMO_FREE_MOTION_MANUAL": "1"]
        if let start { app.launchEnvironment["GT_DEMO_FREE_MOTION_START"] = start }
        if slow { app.launchEnvironment["GT_DEMO_FREE_MOTION_SPEED"] = "0.1" }
        if reduced { app.launchEnvironment["GT_DEMO_REDUCE_MOTION"] = "1" }
        if frozen { app.launchEnvironment["GT_DEMO_FREE_MOTION_FREEZE"] = "1" }
        app.launchEnvironment["GT_DEMO_FREE_MOTION_FRACTION"] = String(fraction)
        print("MOTION_CAPTURE launch kind=\(kind) start=\(start ?? "beginning") slow=\(slow) reduced=\(reduced) ax=\(ax) epoch=\(Date().timeIntervalSince1970)")
        app.launch()
        XCTAssertTrue(app.buttons["motion-start"].waitForExistence(timeout: 20))
        return app
    }
    private func value(_ app: XCUIApplication) -> String {
        app.otherElements["practice-table"].value as? String ?? ""
    }
    private func wait(_ app: XCUIApplication, prefix: String, timeout: TimeInterval = 60) {
        let table = app.otherElements["practice-table"]
        expectation(for: NSPredicate(format: "value BEGINSWITH %@", prefix), evaluatedWith: table)
        waitForExpectations(timeout: timeout)
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.55))
        print("MOTION_CAPTURE screenshot name=\(name) epoch=\(Date().timeIntervalSince1970) projection=\(value(app))")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func start(_ app: XCUIApplication) {
        print("MOTION_CAPTURE start-request epoch=\(Date().timeIntervalSince1970)")
        app.buttons["motion-start"].tap()
        print("MOTION_CAPTURE start-return epoch=\(Date().timeIntervalSince1970)")
    }
    private func assertSettledMoney(_ app: XCUIApplication, stacks: String) {
        let fields = value(app).components(separatedBy: "#")[0].components(separatedBy: "|")
        XCTAssertEqual(fields.first, "finished")
        XCTAssertGreaterThanOrEqual(fields.count, 6)
        guard fields.count >= 6 else { return }
        XCTAssertEqual(fields[3], stacks)
        XCTAssertEqual(fields[4], "0", "No pot remains after visual settlement")
        XCTAssertEqual(fields[5], "0", "No transfer remains in flight")
        for seat in 0..<stacks.components(separatedBy: ",").count {
            XCTAssertFalse(app.otherElements["practice-\(seat)"].label.contains("committed"),
                           "A settled table has no unswept front pile")
        }
    }
    private func assertFrozenPause(_ app: XCUIApplication) {
        let table = app.otherElements["practice-table"]
        expectation(for: NSPredicate { [weak app] _, _ in
            guard let app else { return false }
            let parts = self.value(app).components(separatedBy: "#")
            let paused = parts.first { $0.hasPrefix("paused=") }?.dropFirst(7)
            let resumed = parts.first { $0.hasPrefix("resumed=") }?.dropFirst(8)
            return paused?.isEmpty == false && paused == resumed
        }, evaluatedWith: table)
        waitForExpectations(timeout: 5)
        let parts = value(app).components(separatedBy: "#")
        let paused = parts.first { $0.hasPrefix("paused=") }?.dropFirst(7)
        let resumed = parts.first { $0.hasPrefix("resumed=") }?.dropFirst(8)
        XCTAssertFalse(paused?.isEmpty ?? true)
        XCTAssertEqual(paused, resumed, "Background preserves exact phase cursor, credits and consumed cues")
    }

    func testInitialDealAndPublicMath() {
        let app = launch("deal-4")
        app.buttons["free-table-help"].tap()
        XCTAssertFalse(app.otherElements["free-math-hand"].exists)
        capture(app, "initial-Math-before-hero-disclosure")
        app.buttons["free-table-back-close"].tap()
        start(app)
        wait(app, prefix: "finished")
        XCTAssertTrue(app.buttons["free-fold"].isEnabled)
        capture(app, "initial-deal-complete")
        app.buttons["free-table-help"].tap()
        XCTAssertTrue(app.otherElements["free-math-hand"].exists)
        capture(app, "initial-Math-after-hero-disclosure")
    }
    func testNormalShowdownAndFoldOnlyPrivacy() {
        for kind in ["normal", "fold"] {
            let app = launch(kind)
            start(app)
            wait(app, prefix: "finished")
            XCTAssertTrue(app.buttons["free-next-hand"].exists)
            if kind == "fold" {
                let opponent = app.otherElements["practice-1"]
                XCTAssertTrue(opponent.label.contains("face-down"), opponent.label)
            }
            assertSettledMoney(app, stacks: kind == "fold" ? "[99, 101]" : "[96, 99, 96, 109]")
            capture(app, "\(kind)-visually-settled")
            app.terminate()
        }
    }
    func testNextHandFromShowdownKeepsOldPilesSwept() {
        let app = launch("normal", start: "settle")
        start(app)
        assertSettledMoney(app, stacks: "[96, 99, 96, 109]")
        print("MOTION_CAPTURE next-hand-request epoch=\(Date().timeIntervalSince1970)")
        app.buttons["free-next-hand"].tap()
        XCTAssertFalse(app.otherElements["practice-0"].label.contains("committed"),
                       "The new hero is UTG and has no new blind pile")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "next-hand-clear-dealer-with-old-piles-swept"
        attachment.lifetime = .keepAlways; add(attachment)
        wait(app, prefix: "finished")
        capture(app, "next-hand-new-blinds-and-hero-deal-complete")
    }
    func testMathKeepsCompletedCallPriceDuringAllInFlight() {
        let app = launch("sidepots", start: "action", slow: true)
        app.buttons["free-table-help"].tap()
        let need = app.otherElements["free-math-need"]
        XCTAssertTrue(need.waitForExistence(timeout: 5))
        let before = need.label
        XCTAssertTrue(before.contains("40%"), before)
        start(app)
        let fields = value(app).components(separatedBy: "#")[0].components(separatedBy: "|")
        XCTAssertTrue(fields[0].hasPrefix("action"))
        XCTAssertGreaterThan(Int(fields[5]) ?? 0, 0, "Chips are visibly in transit")
        XCTAssertEqual(need.label, before, "Need still uses the completed action checkpoint")
        capture(app, "Math-completed-call-price-during-hero-allin-flight")
    }
    func testRunoutRefundSidePotsAndOddSplit() {
        for kind in ["runout", "refund", "sidepots", "odd"] {
            let app = launch(kind, start: kind == "runout" ? "reveal" : "winners")
            XCTAssertFalse(app.buttons["free-next-hand"].exists)
            start(app)
            wait(app, prefix: "finished")
            XCTAssertTrue(app.buttons["free-next-hand"].exists)
            let endings = ["runout": "[0, 200]", "refund": "[255, 0, 97, 48]",
                           "sidepots": "[400, 0, 0, 0]", "odd": "[100, 99, 101, 100]"]
            assertSettledMoney(app, stacks: endings[kind]!)
            capture(app, "\(kind)-exact-settlement")
            app.terminate()
        }
    }
    func testBackgroundDuringChipFlightResumesWithoutReset() {
        let app = launch("sidepots", start: "refund", slow: true)
        let before = value(app)
        start(app)
        RunLoop.current.run(until: Date().addingTimeInterval(0.7))
        capture(app, "refund-in-flight-before-background")
        XCUIDevice.shared.press(.home)
        RunLoop.current.run(until: Date().addingTimeInterval(4))
        app.activate()
        assertFrozenPause(app)
        let resumed = value(app)
        XCTAssertNotEqual(resumed, before)
        XCTAssertTrue(resumed.hasPrefix("refund") || resumed.hasPrefix("award"), resumed)
        capture(app, "refund-resumed-at-cursor")
        wait(app, prefix: "finished", timeout: 90)
        XCTAssertTrue(app.buttons["free-next-hand"].exists)
        assertSettledMoney(app, stacks: "[400, 0, 0, 0]")
        capture(app, "refund-resume-settled-once")
    }
    func testBackgroundDuringAwardsAndNextHandRefill() {
        let app = launch("sidepots", start: "award", slow: true)
        start(app)
        RunLoop.current.run(until: Date().addingTimeInterval(0.7))
        capture(app, "award-in-flight-before-background")
        XCUIDevice.shared.press(.home)
        RunLoop.current.run(until: Date().addingTimeInterval(4))
        app.activate()
        assertFrozenPause(app)
        wait(app, prefix: "finished", timeout: 90)
        assertSettledMoney(app, stacks: "[400, 0, 0, 0]")
        capture(app, "award-resume-settled")
        app.buttons["free-next-hand"].tap()
        wait(app, prefix: "finished", timeout: 60)
        XCTAssertFalse(app.buttons["free-next-hand"].exists)
        capture(app, "next-hand-clear-refill-dealer-and-deal")
    }
    func testYourTurnFeedbackDoesNotRepeatAfterBackground() {
        let app = launch("deal-3")
        start(app)
        wait(app, prefix: "finished")
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        let before = value(app).components(separatedBy: "#feedback=").last
        XCUIDevice.shared.press(.home)
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        app.activate()
        assertFrozenPause(app)
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        XCTAssertEqual(value(app).components(separatedBy: "#feedback=").last, before)
        capture(app, "your-turn-resume-no-duplicate-feedback")
    }
    func testReduceMotionCompletesSameMoney() {
        let app = launch("sidepots", start: "winners", reduced: true)
        start(app)
        wait(app, prefix: "finished")
        XCTAssertTrue(app.buttons["free-next-hand"].exists)
        assertSettledMoney(app, stacks: "[400, 0, 0, 0]")
        capture(app, "Reduce-Motion-same-final-money")
    }
    func testAXRefundFlightHasRealSeatDestination() {
        let app = launch("sidepots", start: "refund", slow: true, ax: true)
        start(app)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        capture(app, "AX-refund-from-pot-towards-hero-seat")
        wait(app, prefix: "finished", timeout: 90)
        capture(app, "AX-refund-sidepots-visually-settled")
    }
    func testAXDealtControlsAndMathReachableAcrossSeatsAndLanguages() {
        for language in ["ko", "en"] {
            for seats in 2...4 {
                let app = launch("deal-\(seats)", language: language, ax: true)
                start(app)
                wait(app, prefix: "finished")
                let scroll = app.scrollViews["free-dock-content"]
                let raise = app.buttons["free-raise"]
                for _ in 0..<6 {
                    let viewport = scroll.frame.intersection(app.frame)
                    if viewport.intersection(raise.frame).height >= raise.frame.height - 0.5 { break }
                    scroll.swipeUp()
                }
                XCTAssertTrue(raise.isEnabled)
                XCTAssertTrue(raise.isHittable)
                XCTAssertEqual(scroll.frame.intersection(app.frame).intersection(raise.frame).height,
                               raise.frame.height, accuracy: 0.5, "The full action label is visible")
                capture(app, "AX-\(language)-\(seats)-dealt-action-controls-full")
                scroll.swipeDown()
                let math = app.buttons["free-table-help"]
                XCTAssertTrue(math.isHittable)
                math.tap()
                XCTAssertTrue(app.otherElements["free-math-hand"].waitForExistence(timeout: 5))
                let close = app.buttons["free-table-back-close"]
                XCTAssertTrue(close.isHittable)
                close.tap()
                XCTAssertTrue(app.buttons["free-raise"].exists)
                app.terminate()
            }
        }
    }
    func testAXNamedPotsAndAggregateTotalFullyReadableAfterTableScroll() {
        for language in ["ko", "en"] {
            for pot in [2, 0] {
                let app = launch("sidepots", start: "award(\(pot),", language: language,
                                 ax: true, frozen: true, fraction: 0.5)
                let caption = app.otherElements["table-pot"]
                let scroll = app.scrollViews.element(boundBy: 0)
                let dock = app.descendants(matching: .any)["free-dock"]
                // The table shows through only above the dock; a swipe from the middle of
                // its frame can land on the dock instead.
                var viewport = CGRect.zero
                for _ in 0..<20 {
                    viewport = scroll.frame.intersection(app.frame)
                    viewport.size.height = min(viewport.maxY, dock.frame.minY) - viewport.minY
                    if viewport.intersection(caption.frame).height >= caption.frame.height - 0.5 { break }
                    let delta = min(80, max(-80, caption.frame.midY - viewport.midY))
                    let from = app.coordinate(withNormalizedOffset: .zero)
                        .withOffset(CGVector(dx: viewport.midX, dy: viewport.midY))
                    from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: 0, dy: -delta)),
                               withVelocity: .slow, thenHoldForDuration: 0.5)
                }
                XCTAssertTrue(caption.isHittable)
                XCTAssertEqual(viewport.intersection(caption.frame).height,
                               caption.frame.height, accuracy: 0.5)
                let amount = pot == 2 ? "18" : "100"
                let total = pot == 2 ? "308" : "100"
                XCTAssertTrue(caption.label.contains(amount), caption.label)
                XCTAssertTrue(caption.label.contains(language == "ko" ? "전체 \(total)칩" : "Total \(total)"), caption.label)
                capture(app, "AX-\(language)-pot\(pot)-named-amount-and-total-full")
                app.terminate()
            }
        }
    }
}
