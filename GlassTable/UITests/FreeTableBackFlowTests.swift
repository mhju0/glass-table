// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

final class FreeTableBackFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ language: String = "en", ax: Bool = false, phase: String = "raise-open", players: Int = 4, back: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ko" ? "ko_KR" : "en_US"]
        if ax { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_LANGUAGE": language, "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
                                 "GT_DEMO_FREE_PHASE": phase, "GT_DEMO_PLAYERS": "\(players)"]
        if let back { app.launchEnvironment["GT_DEMO_FREE_BACK"] = back }
        app.launch()
        XCTAssertTrue(app.buttons[back == nil ? "free-table-help" : "free-table-back-close"].waitForExistence(timeout: 15))
        return app
    }

    func testChartSuggestionStaysHiddenUntilTheLearnerAsks() {
        let app = launch()
        app.buttons["free-raise-cancel"].tap()
        app.buttons["free-table-help"].tap()
        let show = app.buttons["free-hint-show"]
        XCTAssertTrue(show.waitForExistence(timeout: 5))
        let hint = app.descendants(matching: .any)["free-hint"]
        XCTAssertFalse(hint.exists, "No suggestion before the learner asks for one")
        let content = app.scrollViews["free-back-content"]
        for _ in 0..<4 where !show.isHittable { content.swipeUp() }
        show.tap()
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        XCTAssertTrue(hint.label.contains("The beginner chart suggests"))
        XCTAssertFalse(show.exists)
    }

    func testMathFlipRulesAndAllFacesKeepHeight() {
        let app = launch()
        app.buttons["free-raise-cancel"].tap()
        let dock = app.descendants(matching: .any)["free-dock"]
        let height = dock.frame.height
        app.buttons["free-table-help"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["free-math-tiles"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["free-fold"].exists)
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        app.buttons["free-back-rules"].tap()
        XCTAssertTrue(app.staticTexts["Your cards"].waitForExistence(timeout: 5))
        app.buttons["free-back-hand"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["free-table-history"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["free-decision-review"].exists)
        app.buttons["free-table-back-close"].tap()
        XCTAssertTrue(app.buttons["free-fold"].waitForExistence(timeout: 5))
        app.buttons["free-raise"].tap()
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        app.buttons["free-table-help"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["free-math-tiles"].waitForExistence(timeout: 5))
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        attach(app, "normal-math-from-raise")
    }

    func testFlopMathShowsMadeHandWithoutCrash() {
        let app = launch(phase: "raise-postflop")
        app.buttons["free-table-help"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["free-math-hand"].waitForExistence(timeout: 5))
        attach(app, "flop-math")
    }

    func testAXKOMathRulesReachable() { axReach("ko") }
    func testAXENMathRulesReachable() { axReach("en") }

    func testReviewThisHandWalksThroughEveryDecisionThenTheShowdown() {
        let app = launch(phase: "result-review")
        app.buttons["free-review"].tap()
        let progress = app.staticTexts["coach-progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertTrue(progress.label.hasPrefix("Step 1 of "), progress.label)
        let pages = Int(progress.label.replacingOccurrences(of: "Step 1 of ", with: "")) ?? 0
        XCTAssertGreaterThanOrEqual(pages, 2, "At least one decision and the ending")
        XCTAssertFalse(app.buttons["coach-back"].exists)
        for page in 1..<pages {
            XCTAssertEqual(progress.label, "Step \(page) of \(pages)")
            XCTAssertTrue(app.staticTexts["What you had"].exists)
            XCTAssertTrue(app.staticTexts["The beginner chart says"].exists)
            let verdict = app.staticTexts["coach-verdict"]
            for _ in 0..<6 where !verdict.exists { app.swipeUp() }
            XCTAssertTrue(verdict.exists)
            XCTAssertTrue(["Good:", "Fine:", "Risky:"].contains { verdict.label.hasPrefix($0) }, verdict.label)
            attach(app, "hand-coach-step-\(page)")
            app.buttons["coach-next"].tap()
        }
        XCTAssertTrue(app.staticTexts["How it ended"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["coach-verdict"].exists)
        attach(app, "hand-coach-ending")
        app.buttons["coach-back"].tap()
        XCTAssertEqual(progress.label, "Step \(pages - 1) of \(pages)")
        app.buttons["coach-next"].tap()
        app.buttons["coach-done"].tap()
        XCTAssertTrue(app.buttons["free-next-hand"].waitForExistence(timeout: 5))
    }

    func testSettledReviewChanceAndResponsiveTabs() {
        let app = launch(phase: "result-review")
        app.buttons["free-table-help"].tap()
        app.buttons["free-back-hand"].tap()
        let review = app.descendants(matching: .any)["free-decision-review"]
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "free-decision-demo-review-two-"))
        guard let first = rows.allElementsBoundByIndex.first, let last = rows.allElementsBoundByIndex.last else {
            XCTFail("No decision rows in settled review: \(app.debugDescription)"); return
        }
        reveal(last, app: app, scroll: app.scrollViews["free-back-content"], windowBottomInset: 28)
        let ready = expectation(for: NSPredicate(format: "label CONTAINS %@ AND NOT label CONTAINS %@", "Chance", "—"), evaluatedWith: last)
        wait(for: [ready], timeout: 20)
        print("review scroll viewport=\(app.scrollViews["free-back-content"].frame), dock=\(app.descendants(matching: .any)["free-dock"].frame)")
        reveal(first, app: app, scroll: app.scrollViews["free-back-content"], windowBottomInset: 28)
        attach(app, "river-review-first-row")
        reveal(last, app: app, scroll: app.scrollViews["free-back-content"], windowBottomInset: 28)
        attach(app, "river-review-last-row")
        app.buttons["free-back-rules"].tap()
        XCTAssertTrue(app.staticTexts["Your cards"].waitForExistence(timeout: 5))
        app.buttons["free-back-hand"].tap()
        XCTAssertTrue(review.waitForExistence(timeout: 5))
    }

    func testPreflopEquityWorkKeepsTabsResponsiveOnLeaveAndReopen() {
        let app = launch(phase: "result-all-in", players: 2)
        app.buttons["free-table-help"].tap()
        app.buttons["free-back-hand"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["free-decision-review"].waitForExistence(timeout: 5))
        for index in 0..<2 {
            let start = Date()
            app.buttons["free-back-rules"].tap()
            XCTAssertTrue(app.staticTexts["Your cards"].waitForExistence(timeout: 5))
            let elapsed = Date().timeIntervalSince(start)
            print("preflop background tab cycle \(index): \(elapsed) seconds")
            XCTAssertLessThan(elapsed, 5)
            app.buttons["free-back-hand"].tap()
            XCTAssertTrue(app.descendants(matching: .any)["free-decision-review"].waitForExistence(timeout: 5))
        }
        attach(app, "preflop-background-responsive")
    }

    func testManualCardRevealDoesNotAddReviewEquity() {
        let app = launch(phase: "result-fold", players: 2)
        app.buttons["free-table-help"].tap()
        app.buttons["free-back-hand"].tap()
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "free-decision-demo-fold-review-"))
        let row = rows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let before = row.label
        XCTAssertTrue(before.contains("Chance —"), before)
        let toggle = app.switches["free-review-folded"]
        reveal(toggle, app: app, scroll: app.scrollViews["free-back-content"])
        toggle.tap()
        XCTAssertEqual(row.label, before)
        attach(app, "manual-reveal-chance-unchanged")
    }

    func testAXKOExpandedPolicyEndReachable() { policyEndReach("ko") }
    func testAXENExpandedPolicyEndReachable() { policyEndReach("en") }

    private func policyEndReach(_ language: String) {
        let app = launch(language, ax: true, players: 4)
        app.buttons["free-table-help"].tap()
        let tabs = app.scrollViews["free-back-tabs"]
        let outer = app.scrollViews["free-dock-content"]
        reveal(tabs, app: app, scroll: outer)
        let rules = app.buttons["free-back-rules"]
        for _ in 0..<5 where rules.frame.maxX > tabs.frame.maxX + 0.5 { tabs.swipeLeft() }
        rules.tap()
        let body = app.scrollViews["free-back-content"]
        let policy = app.buttons["free-table-policy-toggle"]
        reveal(policy, app: app, scroll: body)
        policy.tap()
        let text = language == "ko"
            ? "컴퓨터는 각 베팅 라운드에 벳하거나 올리는 행동을 한 번만 해요. 그 뒤에는 콜하거나 체크해요. 사람의 벳 횟수를 제한하는 규칙은 아니에요."
            : "Each computer bets or raises at most once per betting round. After that, it calls or checks. This is a bot policy, not a limit on your raises."
        let end = app.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
        XCTAssertTrue(end.waitForExistence(timeout: 5))
        for bottomEdge in [false, true] {
            var unchanged = 0
            for _ in 0..<90 {
                let frame = end.frame, viewport = body.frame, window = app.windows.firstMatch.frame
                let top = max(130, viewport.minY), bottom = min(window.maxY - 20, viewport.maxY)
                let height = min(60, frame.height)
                let edgeTop = bottomEdge ? frame.maxY - height : frame.minY
                let edgeBottom = edgeTop + height
                let aligned = edgeTop >= top - 0.5 && edgeBottom <= bottom + 0.5
                if aligned { break }
                let difference = bottomEdge ? edgeBottom - bottom : edgeTop - top
                let downward = difference < 0
                let distance = abs(difference)
                let amount = min(bottom - top - 60, max(24, distance + 2))
                let startY = downward ? top + 30 : min(bottom - 30, window.maxY - 80)
                let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: window.midX, dy: startY))
                let delta = downward ? amount : -amount
                start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)),
                            withVelocity: .slow, thenHoldForDuration: 0.2)
                unchanged = abs(end.frame.minY - frame.minY) < 0.5 ? unchanged + 1 : 0
                XCTAssertLessThan(unchanged, 3, "No policy scroll progress: \(end.frame), viewport \(body.frame)")
            }
            let frame = end.frame, viewport = body.frame, window = app.windows.firstMatch.frame
            let edgeTop = bottomEdge ? frame.maxY - min(60, frame.height) : frame.minY
            XCTAssertGreaterThanOrEqual(edgeTop, max(130, viewport.minY) - 0.5)
            XCTAssertLessThanOrEqual(edgeTop + min(60, frame.height), min(window.maxY - 20, viewport.maxY) + 0.5)
            print("\(language) expanded policy paragraph=\(frame), body=\(viewport), end=\(bottomEdge)")
            attach(app, "\(language)-AX-expanded-policy-\(bottomEdge ? "last" : "first")-portion")
        }
    }

    private func axReach(_ language: String) {
        let app = launch(language, ax: true)
        let dock = app.descendants(matching: .any)["free-dock"]
        let height = dock.frame.height
        let outer = app.scrollViews["free-dock-content"]
        let cancel = app.buttons["free-raise-cancel"]
        reveal(cancel, app: app, scroll: outer)
        cancel.tap()
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        let help = app.buttons["free-table-help"]
        reveal(help, app: app, scroll: outer)
        help.tap()
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        let body = app.scrollViews["free-back-content"]
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        let row = app.descendants(matching: .any)["free-math-tiles"]
        reveal(row, app: app, scroll: body)
        for id in ["pot", "call"] {
            let tile = app.descendants(matching: .any)["free-math-\(id)"]
            XCTAssertGreaterThanOrEqual(tile.frame.minX, row.frame.minX - 0.5)
            XCTAssertLessThanOrEqual(tile.frame.maxX, row.frame.maxX + 0.5)
        }
        let need = app.descendants(matching: .any)["free-math-need"]
        for _ in 0..<6 where need.frame.maxX > row.frame.maxX + 0.5 { row.swipeLeft() }
        XCTAssertGreaterThanOrEqual(need.frame.minX, row.frame.minX - 0.5)
        XCTAssertLessThanOrEqual(need.frame.maxX, row.frame.maxX + 0.5)
        XCTAssertTrue(need.label.contains("40%"), need.label)
        attach(app, "\(language)-AX-full-need-percent")
        let hand = app.descendants(matching: .any)["free-math-hand"]
        reveal(hand, app: app, scroll: body)
        attach(app, "\(language)-AX-math-hand")
        let tabs = app.scrollViews["free-back-tabs"]
        reveal(tabs, app: app, scroll: app.scrollViews["free-dock-content"])
        for id in ["hint", "hand", "rules"] {
            let tab = app.buttons["free-back-\(id)"]
            // A full swipe runs to the end of the row and pushes the middle tab off the left.
            for _ in 0..<12 where tab.frame.maxX > tabs.frame.maxX + 0.5 {
                let from = tabs.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
                let delta = max(40, min(160, tab.frame.maxX - tabs.frame.maxX + 12))
                from.press(forDuration: 0.1, thenDragTo: from.withOffset(CGVector(dx: -delta, dy: 0)),
                           withVelocity: .slow, thenHoldForDuration: 0.3)
            }
            XCTAssertGreaterThanOrEqual(tab.frame.minX, tabs.frame.minX - 0.5)
            XCTAssertLessThanOrEqual(tab.frame.maxX, tabs.frame.maxX + 0.5)
        }
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        attach(app, "\(language)-AX-complete-tabs")
        app.buttons["free-back-rules"].tap()
        let policy = app.buttons["free-table-policy-toggle"]
        reveal(policy, app: app, scroll: body)
        attach(app, "\(language)-AX-rules-policy")
        XCTAssertTrue(policy.isHittable)
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        policy.tap()
        let close = app.buttons["free-table-back-close"]
        reveal(close, app: app, scroll: app.scrollViews["free-dock-content"])
        close.tap()
        XCTAssertTrue(app.buttons["free-table-help"].waitForExistence(timeout: 5))
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        let raise = app.buttons["free-raise"]
        reveal(raise, app: app, scroll: outer)
        raise.tap()
        XCTAssertTrue(app.buttons["free-raise-confirm"].waitForExistence(timeout: 5))
        XCTAssertEqual(dock.frame.height, height, accuracy: 0.5)
        let commit = app.buttons["free-raise-confirm"]
        reveal(commit, app: app, scroll: outer)
        attach(app, "\(language)-AX-stable-shell-raise-commit")
    }

    func testAXKOCreamSeatGuideReadable() { creamGuideReach("ko") }
    func testAXENCreamSeatGuideReadable() { creamGuideReach("en") }

    private func creamGuideReach(_ language: String) {
        let app = launch(language, ax: true, back: "rules")
        let body = app.scrollViews["free-back-content"]
        let text = language == "ko"
            ? "크림색 자리가 나예요. 내 카드 두 장은 나만 볼 수 있고, 상대는 못 봐요."
            : "The cream seat is yours. Only you can see your two cards; others can't."
        let detail = app.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        let window = app.windows.firstMatch.frame
        let top = max(130, body.frame.minY), bottom = min(window.maxY - 20, body.frame.maxY)
        XCTAssertGreaterThanOrEqual(detail.frame.minY, top - 0.5)
        print("\(language) cream guide first detail=\(detail.frame), body=\(body.frame)")
        attach(app, "\(language)-AX-cream-guide-first-portion")
        for index in 0..<20 where detail.frame.maxY > bottom + 0.5 {
            let delta = max(-60, min(-24, bottom - detail.frame.maxY - 2))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: window.midX, dy: bottom - 60))
            start.press(forDuration: 0.5, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)),
                        withVelocity: .slow, thenHoldForDuration: 0.5)
            print("\(language) cream guide portion\(index) detail=\(detail.frame)")
            attach(app, "\(language)-AX-cream-guide-middle-\(index)")
        }
        XCTAssertLessThanOrEqual(detail.frame.maxY, bottom + 0.5)
        XCTAssertGreaterThan(detail.frame.maxY, top + 40)
        print("\(language) cream guide detail=\(detail.frame), body=\(body.frame)")
        attach(app, "\(language)-AX-cream-guide-last-portion")
    }

    private func reveal(_ target: XCUIElement, app: XCUIApplication, scroll: XCUIElement, windowBottomInset: CGFloat = 20) {
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        let window = app.windows.firstMatch.frame
        for _ in 0..<60 {
            let frame = target.frame
            let top = max(130, scroll.frame.minY)
            let bottom = min(window.maxY - windowBottomInset, scroll.frame.maxY)
            if frame.minY >= top - 0.5 && frame.maxY <= bottom + 0.5 { return }
            print("reveal \(target.identifier): target=\(frame), viewport=\(top)...\(bottom)")
            let startY = min(bottom - 50, window.maxY - 80)
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: max(25, scroll.frame.minX + 5), dy: startY))
            let delta: CGFloat = frame.maxY > bottom
                ? max(-120, min(-24, bottom - frame.maxY - 2))
                : min(120, max(24, top - frame.minY + 2))
            start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: delta)),
                        withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        attach(app, "unreachable-\(target.identifier)")
        XCTFail("Unreachable target \(target.identifier): \(target.frame), scroll \(scroll.frame)")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
