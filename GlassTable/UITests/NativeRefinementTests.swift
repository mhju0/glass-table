import XCTest

final class NativeRefinementTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func application(_ code: String = "en", activity: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0"]
        if let activity {
            app.launchEnvironment["GT_DEMO_ACTIVITY"] = activity
            app.launchEnvironment["GT_DEMO_TAB"] = "records"
        }
        return app
    }

    func testRecordedDatesIncludeWrongAndHelpedAnswersButExcludeHelpOnlyAndFutureDates() {
        for code in ["ko", "en"] {
            for (fixture, days) in [("help-only", 0), ("wrong", 1), ("helped", 1), ("sparse-future", 1)] {
                let app = application(code, activity: fixture)
                app.launch()
                XCTAssertTrue(app.staticTexts["records-completion"].waitForExistence(timeout: 15))
                let cells = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "records-day-"))
                XCTAssertEqual(cells.count, 7)
                let marker = code == "ko" ? "연습 기록 있음" : "Practice recorded"
                XCTAssertEqual(cells.allElementsBoundByIndex.filter { $0.label.contains(marker) }.count, days, fixture)
                XCTAssertFalse(app.staticTexts["With help"].exists)
                XCTAssertFalse(app.staticTexts["도움 받음"].exists)
                app.terminate()
            }
        }
    }

    func testFourthDateUsesTheSameDateCellAndWaitsForTodaysRecordedAnswer() {
        for (fixture, flame) in [("before-fourth", false), ("four-days", true)] {
            let app = application(activity: fixture)
            app.launch()
            XCTAssertTrue(app.staticTexts["records-completion"].waitForExistence(timeout: 15))
            let today = app.descendants(matching: .any).matching(NSPredicate(
                format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@", "records-day-", "Today, ")).firstMatch
            XCTAssertTrue(today.exists)
            XCTAssertEqual(today.label.contains("4 consecutive practice days"), flame)
            XCTAssertFalse(app.staticTexts["Streak protection"].exists)
            app.terminate()
        }
    }

    func testRecordsContinuationOpensLearnAndFullCompletionHasTheRealDenominator() {
        let app = application(activity: "completed")
        app.launch()
        let completion = app.staticTexts["records-completion"]
        XCTAssertTrue(completion.waitForExistence(timeout: 15))
        XCTAssertEqual(completion.label, "10 of 10 main lessons passed")
        app.buttons["records-continue"].tap()
        XCTAssertTrue(app.tabBars.buttons["Learn"].isSelected)
    }

    func testLessonSummaryNamesTheTopicWithoutPublicHelpCounts() {
        for code in ["ko", "en"] {
            let app = application(code)
            app.launchEnvironment["GT_DEMO_NODE"] = "u1-showdown"
            app.launchEnvironment["GT_DEMO_SESSION_COMPLETE"] = "1"
            app.launch()
            XCTAssertTrue(app.staticTexts[code == "ko" ? "레슨 통과" : "Lesson passed"].waitForExistence(timeout: 15))
            XCTAssertTrue(app.staticTexts[code == "ko" ? "누가 이길까요?" : "Who wins?"].exists)
            XCTAssertFalse(app.descendants(matching: .any)["summary-helped"].exists)
            XCTAssertFalse(app.staticTexts["All answers were on target"].exists)
            app.terminate()
        }
    }

    /// Owner, 2026-10-14: under the pass mark the lesson offers a retry with new cards,
    /// the explanation and a way on, never the plain next-lesson button.
    func testLessonUnderThePassMarkOffersARetryAndAWayOn() {
        for code in ["ko", "en"] {
            let app = application(code)
            app.launchEnvironment["GT_DEMO_NODE"] = "u2-outs"
            app.launchEnvironment["GT_DEMO_SESSION_COMPLETE"] = "1"
            app.launchEnvironment["GT_DEMO_SESSION_MARKS"] = "rww"
            app.launch()
            XCTAssertTrue(app.staticTexts[code == "ko" ? "아직 통과 전이에요" : "Not passed yet"].waitForExistence(timeout: 15))
            XCTAssertTrue(app.staticTexts[code == "ko" ? "3문제 중 1문제를 맞혔어요. 통과하려면 2문제가 필요해요."
                                                       : "You got 1 of 3 right. You need 2 to pass."].exists)
            for id in ["summary-retry", "summary-explain", "summary-go-on", "summary-done"] {
                XCTAssertTrue(app.buttons[id].exists, id)
            }
            XCTAssertFalse(app.buttons["summary-next-lesson"].exists)
            app.terminate()
        }
    }

    func testFinishedHandHelpOffersReviewWithoutAnObsoletePrice() {
        let app = application()
        app.launchEnvironment.merge(["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1",
                                    "GT_DEMO_FREE_PHASE": "result-review", "GT_DEMO_FREE_BACK": "hint"], uniquingKeysWith: { _, new in new })
        app.launch()
        let review = app.buttons["free-finished-help-review"]
        XCTAssertTrue(review.waitForExistence(timeout: 15))
        XCTAssertFalse(app.descendants(matching: .any)["free-math-need"].exists)
        review.tap()
        XCTAssertTrue(app.descendants(matching: .any)["free-decision-review"].waitForExistence(timeout: 5))
    }
    func testLargeTextActionRowsAreReadableAndReachableInBothLanguages() {
        for code in ["ko", "en"] {
            let app = application(code)
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            app.launchEnvironment.merge(["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1", "GT_DEMO_PLAYERS": "2"], uniquingKeysWith: { _, new in new })
            app.launch()
            let fold = app.buttons["free-fold"]
            XCTAssertTrue(fold.waitForExistence(timeout: 15))
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: fold)
            waitForExpectations(timeout: 20)
            let call = app.buttons["free-call"]
            let raise = app.buttons["free-raise"]
            for control in [fold, call, raise] {
                XCTAssertGreaterThan(control.frame.width, app.frame.width * 0.65)
                XCTAssertGreaterThanOrEqual(control.frame.height, 44)
            }
            XCTAssertLessThan(fold.frame.maxY, call.frame.minY)
            XCTAssertLessThan(call.frame.maxY, raise.frame.minY)
            let dock = app.scrollViews["free-dock-content"]
            func reveal(_ control: XCUIElement) {
                for _ in 0..<12 {
                    if control.isHittable && control.frame.maxY <= app.frame.maxY - 20 { return }
                    if control.frame.minY < dock.frame.minY { dock.swipeDown() }
                    else { dock.swipeUp() }
                }
                XCTAssertTrue(control.isHittable)
            }
            reveal(raise)
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "readable-action-rows-AX5-\(code)"; shot.lifetime = .keepAlways; add(shot)
            raise.tap()
            let cancel = app.buttons["free-raise-cancel"]
            XCTAssertTrue(cancel.waitForExistence(timeout: 5))
            cancel.tap()
            reveal(fold)
            fold.tap()
            XCTAssertTrue(app.buttons["free-next-hand"].waitForExistence(timeout: 20))
            app.terminate()
        }
    }

    func testRecordsContinueClearsTheTabBarAtLargeTextInBothLanguages() {
        for code in ["ko", "en"] {
            let app = application(code, activity: "completed")
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            app.launch()
            let button = app.buttons["records-continue"]
            XCTAssertTrue(button.waitForExistence(timeout: 15))
            let tabs = app.tabBars.firstMatch
            for _ in 0..<12 {
                if button.isHittable && button.frame.maxY < tabs.frame.minY { break }
                app.swipeUp()
            }
            XCTAssertTrue(button.isHittable)
            XCTAssertLessThan(button.frame.maxY, tabs.frame.minY)
            button.tap()
            XCTAssertTrue(app.tabBars.buttons[code == "ko" ? "배우기" : "Learn"].isSelected)
            app.terminate()
        }
    }

    func testDetailedRecordsDoNotCategorizeHelpUse() {
        let app = application(activity: "helped")
        app.launch()
        let details = app.buttons["records-details"]
        XCTAssertTrue(details.waitForExistence(timeout: 15))
        details.tap()
        for _ in 0..<8 {
            if app.staticTexts["Practice over time"].exists { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Practice over time"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "With help")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Independent")).firstMatch.exists)
    }

}
