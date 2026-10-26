import XCTest

final class LearningReferenceFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ environment: [String: String], korean: Bool = false,
                        ax: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-glassTable.language", korean ? "korean" : "english",
                               "-appAppearance", korean ? "dark" : "light",
                               "-UIPreferredContentSizeCategoryName",
                               ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = environment.merging(["GT_TEST_STORE_ID": UUID().uuidString,
            "GT_TEST_FIRST_LESSON": "0", "GT_TEST_FIRST_PLACEMENT": "0"]) { value, _ in value }
        app.launch()
        return app
    }

    private func reach(_ element: XCUIElement, app: XCUIApplication,
                       scroll: XCUIElement? = nil, upward: Bool = true) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        for _ in 0..<12 where !element.isHittable {
            if upward { (scroll ?? app).swipeUp() }
            else { (scroll ?? app).swipeDown() }
        }
        XCTAssertTrue(element.isHittable)
    }

    private func reachLookup(_ button: XCUIElement, app: XCUIApplication,
                             scroll: XCUIElement, footer: XCUIElement) {
        XCTAssertTrue(button.waitForExistence(timeout: 15))
        XCTAssertTrue(scroll.exists)
        XCTAssertTrue(footer.exists)
        let close = app.buttons["guide-close"].exists ? app.buttons["guide-close"] : app.buttons["Close"].firstMatch
        func viewport() -> CGRect {
            let visible = scroll.frame.intersection(app.windows.firstMatch.frame)
            let top = max(visible.minY, close.frame.maxY + 8)
            let bottom = min(visible.maxY, footer.frame.minY - 8)
            return CGRect(x: visible.minX, y: top, width: visible.width, height: max(0, bottom - top))
        }
        for _ in 0..<24 {
            let visible = viewport()
            let target = button.frame
            if target.minY >= visible.minY, target.maxY <= visible.maxY, button.isHittable { return }
            XCTAssertGreaterThan(visible.height, 44, "No scrollable viewport: \(visible)")
            let moveDown = target.minY < visible.minY
            let origin = scroll.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: visible.midX - scroll.frame.minX,
                dy: visible.minY + visible.height * (moveDown ? 0.3 : 0.7) - scroll.frame.minY))
            let end = origin.withOffset(CGVector(dx: visible.midX - scroll.frame.minX,
                dy: visible.minY + visible.height * (moveDown ? 0.7 : 0.3) - scroll.frame.minY))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        let visible = viewport()
        XCTAssertGreaterThanOrEqual(button.frame.minY, visible.minY, "Target \(button.frame), viewport \(visible)")
        XCTAssertLessThanOrEqual(button.frame.maxY, visible.maxY, "Target \(button.frame), viewport \(visible)")
        XCTAssertTrue(button.isHittable)
    }

    private struct GuideViewport: CustomStringConvertible {
        let scroll: CGRect
        let close: CGRect
        let footer: CGRect

        static func framesMatch(_ a: CGRect, _ b: CGRect, accuracy: CGFloat) -> Bool {
            abs(a.minX - b.minX) <= accuracy && abs(a.minY - b.minY) <= accuracy
                && abs(a.width - b.width) <= accuracy && abs(a.height - b.height) <= accuracy
        }

        func matches(_ other: Self, accuracy: CGFloat) -> Bool {
            Self.framesMatch(scroll, other.scroll, accuracy: accuracy)
                && Self.framesMatch(close, other.close, accuracy: accuracy)
                && Self.framesMatch(footer, other.footer, accuracy: accuracy)
        }

        var description: String { "scroll=\(scroll), close=\(close), footer=\(footer)" }
    }

    private struct GuideReadingGeometry: CustomStringConvertible {
        let viewport: GuideViewport
        let contentAnchor: CGRect

        func isStable(comparedTo other: Self) -> Bool {
            viewport.matches(other.viewport, accuracy: 0.25)
                && GuideViewport.framesMatch(contentAnchor, other.contentAnchor, accuracy: 0.25)
        }

        var description: String { "\(viewport), contentAnchor=\(contentAnchor)" }
    }

    // The tested term is deliberately absent: readiness must not wait for its expected position.
    private func settledGuideGeometry(_ app: XCUIApplication, footerID: String,
                                      contentAnchorID: String,
                                      restoring viewport: GuideViewport? = nil) -> GuideReadingGeometry? {
        var previous: GuideReadingGeometry?
        var settled: GuideReadingGeometry?
        var observations: [String] = []
        let start = ProcessInfo.processInfo.systemUptime
        let wanted: Set<String> = ["guide-content", "guide-close", footerID, contentAnchorID, "glossary-close"]
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let sampleStart = ProcessInfo.processInfo.systemUptime
            guard let root = try? app.snapshot() else {
                observations.append("\(sampleStart - start): snapshot failed; elapsed: \(ProcessInfo.processInfo.systemUptime - sampleStart)s")
                previous = nil
                return false
            }
            let snapshotCost = ProcessInfo.processInfo.systemUptime - sampleStart
            var found: [String: [XCUIElementSnapshot]] = [:]
            var pending: [XCUIElementSnapshot] = [root]
            while let node = pending.popLast() {
                if wanted.contains(node.identifier) { found[node.identifier, default: []].append(node) }
                pending.append(contentsOf: node.children)
            }
            guard found["glossary-close"] == nil else {
                observations.append("\(sampleStart - start): lookup still presented; snapshot: \(snapshotCost)s")
                previous = nil
                return false
            }
            func element(_ id: String, type: XCUIElement.ElementType) -> XCUIElementSnapshot? {
                let matches = found[id, default: []].filter { $0.elementType == type }
                return matches.count == 1 ? matches[0] : nil
            }
            guard let scroll = element("guide-content", type: .scrollView),
                  let close = element("guide-close", type: .button),
                  let footer = element(footerID, type: .button),
                  let anchor = element(contentAnchorID, type: .staticText) else {
                let counts = wanted.sorted().map { "\($0)=\(found[$0, default: []].count)" }.joined(separator: ", ")
                observations.append("\(sampleStart - start): missing or ambiguous guide elements: \(counts); snapshot: \(snapshotCost)s")
                previous = nil
                return false
            }
            let current = GuideReadingGeometry(
                viewport: GuideViewport(scroll: scroll.frame, close: close.frame, footer: footer.frame),
                contentAnchor: anchor.frame)
            let frames = [scroll.frame, close.frame, footer.frame, anchor.frame]
            guard frames.allSatisfy({ !$0.isEmpty && !$0.isNull && !$0.isInfinite
                && [$0.minX, $0.minY, $0.width, $0.height].allSatisfy(\.isFinite) }) else {
                observations.append("\(sampleStart - start): invalid geometry: \(current); snapshot: \(snapshotCost)s")
                previous = nil
                return false
            }
            let stable = previous.map { current.isStable(comparedTo: $0) } ?? false
            let restored = viewport.map { current.viewport.matches($0, accuracy: 1) } ?? true
            observations.append("\(sampleStart - start): \(current); snapshot: \(snapshotCost)s; stable: \(stable); restored: \(restored)")
            previous = current
            guard stable, restored else { return false }
            func hittable(_ name: String, element: XCUIElement) -> Bool {
                let queryStart = ProcessInfo.processInfo.systemUptime
                let result = element.isHittable
                observations.append("\(ProcessInfo.processInfo.systemUptime - start): \(name).isHittable=\(result); query: \(ProcessInfo.processInfo.systemUptime - queryStart)s")
                return result
            }
            let scrollHittable = hittable("guide-content", element: app.scrollViews["guide-content"])
            let closeHittable = hittable("guide-close", element: app.buttons["guide-close"])
            let footerHittable = hittable(footerID, element: app.buttons[footerID])
            guard scrollHittable, closeHittable, footerHittable else { return false }
            settled = current
            return true
        }, object: nil)
        guard XCTWaiter.wait(for: [expectation], timeout: 5) == .completed else {
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            let geometry = XCTAttachment(string: "Deadline: 5s; elapsed: \(elapsed)s; restoring: \(String(describing: viewport))\n"
                + observations.joined(separator: "\n"))
            geometry.name = "guide-readiness-geometry"; geometry.lifetime = .keepAlways; add(geometry)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "guide-readiness-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "guide-readiness-screen"; screenshot.lifetime = .keepAlways; add(screenshot)
            return nil
        }
        let geometry = XCTAttachment(string: "Settled within 5s; elapsed: \(ProcessInfo.processInfo.systemUptime - start)s; restoring: \(String(describing: viewport))\n"
            + observations.joined(separator: "\n"))
        geometry.name = "guide-readiness-geometry"; geometry.lifetime = .keepAlways; add(geometry)
        return settled
    }

    func testGlossarySearchAliasesAndNoResults() {
        for (korean, ax) in [(false, false), (true, false), (false, true), (true, true)] {
            let app = launch(["GT_DEMO_SETTINGS": "1", "GT_DEMO_GLOSSARY": "1"], korean: korean, ax: ax)
            let search = app.textFields["glossary-search"]
            XCTAssertTrue(search.waitForExistence(timeout: 15))
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "glossary-search-\(korean ? "ko" : "en")-\(ax ? "AX5" : "large")"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            search.tap(); search.typeText("3bet\n")
            let entry = app.buttons["glossary-entry-three-bet"]
            XCTAssertTrue(entry.waitForExistence(timeout: 5))
            entry.tap()
            XCTAssertTrue(app.descendants(matching: .any)["glossary-detail-three-bet"].waitForExistence(timeout: 5))
            let all = app.buttons["glossary-all"]
            reach(all, app: app)
            all.tap()
            XCTAssertEqual(search.value as? String, "3bet")
            app.buttons["glossary-clear"].tap()
            search.tap(); search.typeText("zznotaword987\n")
            XCTAssertTrue(app.staticTexts["glossary-no-results"].waitForExistence(timeout: 5))
            app.buttons["glossary-clear"].tap()
            search.tap(); search.typeText("EV\n")
            XCTAssertTrue(app.buttons["glossary-entry-ev"].waitForExistence(timeout: 5))
            app.buttons["glossary-close"].tap()
            XCTAssertTrue(search.waitForNonExistence(timeout: 5), "Closing the glossary must dismiss search")
            app.terminate()
        }
    }

    private func cards(_ app: XCUIApplication) -> [String] {
        app.descendants(matching: .any)["three-region-hero-cards"]
            .descendants(matching: .any).allElementsBoundByIndex.map(\.label)
    }

    func testContextLookupReturnsToUnchangedDraftAndAnswer() {
        let app = launch(["GT_DEMO_NODE": "u2-outs.3"])
        let question = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'drill-question-'" )).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 15))
        let questionID = question.identifier
        let questionLabel = question.label
        let originalCards = cards(app)
        XCTAssertFalse(originalCards.isEmpty)
        let entry = app.buttons["Enter answer"]
        reach(entry, app: app)
        entry.tap()
        app.buttons["Digit 1"].tap(); app.buttons["Digit 2"].tap()
        app.buttons["Done entering"].tap()
        XCTAssertTrue(app.buttons["12 cards"].exists)
        let chip = app.buttons["drill-term-lookup"]
        let content = app.scrollViews["drill-content-scroll"]
        reachLookup(chip, app: app, scroll: content, footer: app.descendants(matching: .any)["answer-sheet"])
        chip.tap()
        XCTAssertTrue(app.descendants(matching: .any)["glossary-detail-outs"].waitForExistence(timeout: 5))
        app.buttons["glossary-close"].tap()
        XCTAssertEqual(question.identifier, questionID)
        XCTAssertEqual(question.label, questionLabel)
        XCTAssertEqual(cards(app), originalCards)
        XCTAssertTrue(app.buttons["12 cards"].exists)
        XCTAssertFalse(app.buttons["Next question"].exists, "A word lookup must not submit an answer")
        let check = app.buttons["Check answer"]
        reach(check, app: app)
        check.tap()
        let next = app.buttons["Next question"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        let revealID = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'graded-sheet-'" )).firstMatch.identifier
        XCTAssertFalse(revealID.isEmpty)
        let revealedText = app.descendants(matching: .any)[revealID]
            .staticTexts.allElementsBoundByIndex.map(\.label)
        let revealedCards = cards(app)
        reachLookup(chip, app: app, scroll: content, footer: app.descendants(matching: .any)[revealID])
        chip.tap()
        XCTAssertTrue(app.descendants(matching: .any)["glossary-detail-outs"].waitForExistence(timeout: 5))
        app.buttons["glossary-close"].tap()
        XCTAssertTrue(next.exists)
        XCTAssertTrue(app.descendants(matching: .any)[revealID].exists)
        XCTAssertEqual(app.descendants(matching: .any)[revealID]
            .staticTexts.allElementsBoundByIndex.map(\.label), revealedText)
        XCTAssertEqual(cards(app), revealedCards)

        // The completed lesson shows that self-directed lookup kept every answer
        // independent, including the question opened before its answer.
        for _ in 0..<2 {
            reach(next, app: app)
            next.tap()
            let answer = app.buttons["Enter answer"]
            reach(answer, app: app)
            answer.tap()
            app.buttons["Digit 0"].tap()
            app.buttons["Done entering"].tap()
            let submit = app.buttons["Check answer"]
            reach(submit, app: app)
            submit.tap()
            XCTAssertTrue(next.waitForExistence(timeout: 10))
        }
        reach(next, app: app)
        next.tap()
        let firstMark = app.descendants(matching: .any)["summary-mark-0"]
        XCTAssertTrue(firstMark.waitForExistence(timeout: 10))
        for index in 0...2 {
            let mark = app.descendants(matching: .any)["summary-mark-\(index)"]
            XCTAssertTrue(mark.exists)
            XCTAssertFalse(mark.label.contains("With the hint"))
        }
    }

    func testGuideAllTopicsAndLookupAreReachableAtLargestText() {
        let app = launch(["GT_DEMO_SETTINGS": "1", "GT_DEMO_GUIDE": "1"], ax: true)
        let scroll = app.scrollViews["guide-content"]
        let topics = ["lessons", "steps", "passing", "help", "challenges-review", "progress", "tables"]
        for (index, topic) in topics.enumerated() {
            let heading = app.staticTexts["guide-topic-\(topic)"]
            XCTAssertTrue(heading.waitForExistence(timeout: 10))
            let footerID = app.buttons["guide-previous"].exists ? "guide-previous" : "guide-next"
            let footer = app.buttons[footerID]
            let close = app.buttons["guide-close"]
            XCTAssertGreaterThanOrEqual(heading.frame.minY, max(scroll.frame.minY, close.frame.maxY) + 7,
                                       "A new topic must begin below the chrome: \(heading.frame)")
            XCTAssertLessThanOrEqual(heading.frame.maxY, min(scroll.frame.maxY, footer.frame.minY),
                                    "A new topic's heading must be visible before scrolling: \(heading.frame)")
            let links = app.buttons.matching(identifier: "guide-topic-terms")
            if links.count == 0 {
                let hierarchy = XCTAttachment(string: app.debugDescription)
                hierarchy.name = "guide-\(topic)-missing-term-buttons"
                hierarchy.lifetime = .keepAlways
                add(hierarchy)
            }
            XCTAssertGreaterThan(links.count, 0)
            let link = links.element(boundBy: links.count - 1)
            reachLookup(link, app: app, scroll: scroll, footer: footer)
            XCTAssertLessThanOrEqual(link.frame.maxY, footer.frame.minY - 8)
            let contentAnchorID = "guide-\(topic)-paragraph-0"
            guard let before = settledGuideGeometry(app, footerID: footerID,
                                                    contentAnchorID: contentAnchorID) else {
                XCTFail("The guide must settle before recording its reading position")
                return
            }
            let linkBeforeLookup = link.frame
            let linkLabelBeforeLookup = link.label
            link.tap()
            XCTAssertTrue(app.buttons["glossary-all"].waitForExistence(timeout: 5))
            app.buttons["glossary-close"].tap()
            XCTAssertTrue(app.staticTexts["guide-topic-\(topic)"].exists)
            guard settledGuideGeometry(app, footerID: footerID, contentAnchorID: contentAnchorID,
                                       restoring: before.viewport) != nil else {
                XCTFail("The lookup must dismiss and the guide viewport must settle")
                return
            }
            XCTAssertEqual(link.label, linkLabelBeforeLookup, "Lookup must return to the same term")
            XCTAssertEqual(link.frame.minY, linkBeforeLookup.minY, accuracy: 1,
                           "Closing a lookup must retain the current topic's reading position")
            XCTAssertTrue(app.buttons["guide-next"].isEnabled)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "guide-AX5-\(topic)-terms-reachable"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            if index > 0 { XCTAssertTrue(app.buttons["guide-previous"].isHittable) }
            if index == topics.count - 1 { XCTAssertEqual(app.buttons["guide-next"].label, "Done") }
            app.buttons["guide-next"].tap()
        }
        XCTAssertTrue(app.buttons["guide-next"].waitForNonExistence(timeout: 5), "Done must dismiss the guide")
        XCTAssertTrue(app.staticTexts["Settings"].firstMatch.waitForExistence(timeout: 5))
    }
}
