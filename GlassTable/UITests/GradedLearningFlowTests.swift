import XCTest

final class GradedLearningFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(ax: Bool = false, postflop: Bool = false, steps: Int? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-glassTable.language", "english", "-appAppearance", "dark"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                ax ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_TABLE": "tag"]
        if postflop {
            app.launchEnvironment["GT_DEMO_TABLE_STEP"] = "1"
            app.launchEnvironment["GT_DEMO_TABLE_CONTINUE"] = "1"
        }
        if let steps { app.launchEnvironment["GT_DEMO_TABLE_STEP"] = String(steps) }
        app.launch()
        XCTAssertTrue(app.buttons["table-chart"].waitForExistence(timeout: 15))
        return app
    }

    func testNormalFeedbackAndSummaryKeepBothHandsFullyVisible() {
        for (steps, action) in [(2, "table-continue"), (10, "table-next-hand")] {
            let app = launch(steps: steps)
            let footer = app.scrollViews["table-footer-scroll"]
            let next = app.buttons[action]
            XCTAssertTrue(next.waitForExistence(timeout: 10))
            XCTAssertTrue(next.isHittable)
            for identifier in ["table-hero-cards", "table-opponent-cards"] {
                let cards = app.descendants(matching: .any)[identifier]
                XCTAssertTrue(cards.exists)
                XCTAssertGreaterThanOrEqual(cards.frame.minY, app.buttons["Back to Play"].frame.maxY - 1,
                                            "Both hands must clear the navigation bar, fixture step \(steps)")
                XCTAssertLessThanOrEqual(cards.frame.maxY, footer.frame.minY + 1,
                                         "Both hands must fit above the decision footer, fixture step \(steps)")
            }
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "graded-normal-visible-cards-step-\(steps)"
            capture.lifetime = .keepAlways
            add(capture)
            next.tap()
            app.terminate()
        }
    }

    private func reach(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.windows.firstMatch.frame.minX)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.windows.firstMatch.frame.maxX)
    }

    func testNormalPreflopFooterHugsControlsAndBothHandsFit() {
        let app = launch()
        let footer = app.scrollViews["table-footer-scroll"]
        let measurement = app.descendants(matching: .any)["table-footer-measured-height"]
        XCTAssertTrue(measurement.waitForExistence(timeout: 5))
        let ready = expectation(for: NSPredicate { object, _ in
            guard let element = object as? XCUIElement else { return false }
            let values = (element.value as? String ?? "").split(separator: ",").compactMap { Double($0) }
            return values.count == 3 && values[0] > 0 && values[1] > 0
        }, evaluatedWith: measurement)
        wait(for: [ready], timeout: 5)
        let viewportValues = (measurement.value as? String ?? "").split(separator: ",").compactMap { Double($0) }
        XCTAssertEqual(viewportValues.count, 3)
        guard viewportValues.count == 3 else { return }
        let contentHeight = viewportValues[0]
        XCTAssertGreaterThan(contentHeight, 0)
        XCTAssertEqual(viewportValues[1], contentHeight, accuracy: 1,
                       "The native footer viewport must hug its preflop controls")
        print("graded footer: content=\(contentHeight), nativeViewport=\(viewportValues[1]), bottomSafeArea=\(viewportValues[2]), scrollAXFrame=\(footer.frame)")
        for identifier in ["table-hero-cards", "table-opponent-cards"] {
            let cards = app.descendants(matching: .any)[identifier]
            XCTAssertTrue(cards.exists)
            XCTAssertGreaterThanOrEqual(cards.frame.minY, app.buttons["Back to Play"].frame.maxY - 1)
            XCTAssertLessThanOrEqual(cards.frame.maxY, footer.frame.minY + 1)
        }
        for identifier in ["table-fold", "table-passive", "table-aggressive"] {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.isHittable)
            XCTAssertEqual(button.frame.height, 87, accuracy: 1)
        }
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "graded-normal-preflop-footer-and-cards"
        capture.lifetime = .keepAlways
        add(capture)
    }

    func testChartBeforeCommitDoesNotRevealOwnHandRecommendation() {
        let app = launch()
        app.buttons["table-chart"].tap()
        XCTAssertTrue(app.staticTexts["Starting-hand chart"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists)
        let guide = app.buttons["table-chart-reading-guide"]
        XCTAssertTrue(guide.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "The diagonal from AA to 22")).firstMatch.exists)
        guide.tap()
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "The diagonal from AA to 22")).firstMatch.exists)
        XCTAssertFalse(app.descendants(matching: .any)["defend-selected-evidence"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["table-fold"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["table-verdict"].exists)
    }

    func testHandEndingFoldGetsFeedbackBeforeSummaryAndChartEvidenceAfterCommit() {
        let app = launch()
        app.buttons["table-fold"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["table-verdict"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["table-takeaway"].exists)
        XCTAssertFalse(app.buttons["table-next-hand"].exists)
        app.buttons["table-chart"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["defend-selected-evidence"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        app.buttons["table-continue"].tap()
        XCTAssertTrue(app.buttons["table-next-hand"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["table-chart"].exists)
    }

    func testPreflopCallFeedbackNamesItsStreetPriceAndOpener() {
        let app = launch()
        app.buttons["table-passive"].tap()
        let verdict = app.descendants(matching: .any)["table-verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your last choice · Before the flop"].exists)
        XCTAssertTrue(verdict.label.contains("Your choice: Call 3bb"), verdict.label)
        XCTAssertTrue(verdict.label.contains("Chart · vs "), verdict.label)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Opponent · ")).firstMatch.exists)
    }

    func testFinishedHandOffersChangeOpponentById() {
        let app = launch()
        app.buttons["table-fold"].tap()
        app.buttons["table-continue"].tap()
        XCTAssertTrue(app.buttons["table-next-hand"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["table-change-opponent"].exists)
    }

    func testAXPostflopChartIsExplicitlyAStartingHandReference() {
        let app = launch(ax: true, postflop: true)
        let chart = app.buttons["table-chart"]
        reach(chart, app: app)
        chart.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "does not advise decisions after the shared cards")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        let passive = app.buttons["table-passive"]
        let ready = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: passive)
        wait(for: [ready], timeout: 30)
        reach(passive, app: app)
        passive.tap()
        let next = app.buttons["table-continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        reach(next, app: app)
        next.tap()
        XCTAssertTrue(app.buttons["table-policy"].exists)
    }

    func testChartGuideOpensOnlyTheFirstTime() {
        let app = launch()
        let guideText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "The diagonal from AA to 22")).firstMatch
        app.buttons["table-chart"].tap()
        XCTAssertTrue(guideText.waitForExistence(timeout: 5), "The first chart opens with its reading guide")
        app.buttons["Close"].tap()
        app.buttons["table-chart"].tap()
        XCTAssertTrue(app.buttons["table-chart-reading-guide"].waitForExistence(timeout: 5))
        XCTAssertFalse(guideText.exists, "A later chart starts with the guide folded")
    }

    func testPreflopReviewExplainsTheOpenersRuleForThisHand() {
        let app = launch()
        app.buttons["table-fold"].tap()
        let takeaway = app.staticTexts["table-takeaway"]
        XCTAssertTrue(takeaway.waitForExistence(timeout: 5))
        XCTAssertTrue(takeaway.label.contains("raises first with about"), takeaway.label)
        XCTAssertTrue(takeaway.label.contains("by strength"), takeaway.label)
    }

    func testReviewLeadsWithTheVerdictBeforeItsReferences() {
        let app = launch()
        app.buttons["table-fold"].tap()
        let verdict = app.descendants(matching: .any)["table-verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        let chart = app.buttons["table-chart"]
        let details = app.buttons["table-decision-details"]
        XCTAssertTrue(chart.exists)
        XCTAssertTrue(details.exists)
        XCTAssertLessThanOrEqual(verdict.frame.maxY, chart.frame.minY, "The verdict comes before the references")
        XCTAssertLessThanOrEqual(app.staticTexts["table-takeaway"].frame.maxY, details.frame.minY)
    }
}
