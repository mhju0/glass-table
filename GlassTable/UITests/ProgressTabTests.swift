// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// The Progress tab (owner's pick R3·G, 2026-10-18): two numbers that only grow, a week
/// line that never shows 0, one refresh card, and a welcome back after time away.
final class ProgressTabTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func application(_ code: String, activity: String?, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english"]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_TAB": "records"]
        if let activity { app.launchEnvironment["GT_DEMO_ACTIVITY"] = activity }
        return app
    }

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[id]
    }

    /// Scrolls until the element sits fully above the tab bar.
    private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(target.waitForExistence(timeout: 15))
        let limit = app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame.minY : app.frame.maxY
        for _ in 0..<14 {
            if target.isHittable, target.frame.maxY <= limit { return }
            app.swipeUp()
        }
        XCTAssertTrue(target.isHittable)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    /// No streak, and no bare zero, anywhere on the tab.
    private func assertNoZeroOrStreak(in app: XCUIApplication, _ code: String) {
        let texts = app.staticTexts.allElementsBoundByIndex.map(\.label)
        XCTAssertFalse(texts.contains("0"), "\(texts)")
        for word in ["Day streak", "연속 일수", "streak"] {
            XCTAssertFalse(texts.contains { $0.contains(word) }, "\(word) in \(texts)")
        }
    }

    func testTodayLeadsWithGrowingNumbersTheWeekAndOneRefresh() {
        for code in ["en", "ko"] {
            let app = application(code, activity: "progress-today")
            app.launch()
            let decisions = element("progress-decisions", in: app)
            XCTAssertTrue(decisions.waitForExistence(timeout: 15))
            XCTAssertTrue(decisions.label.hasPrefix("412 "), decisions.label)
            let strong = element("progress-strong", in: app)
            XCTAssertTrue(strong.label.hasPrefix("5 "), strong.label)
            XCTAssertTrue(strong.label.contains(code == "ko" ? "숙달 1개" : "1 Mastered"), strong.label)
            XCTAssertEqual(element("progress-week", in: app).label, code == "ko" ? "이번 주 · 1일 연습" : "This week · 1 day")
            let refresh = element("progress-refresh", in: app)
            XCTAssertTrue(refresh.exists)
            XCTAssertTrue(app.staticTexts[code == "ko" ? "다시 볼 때예요" : "Ready for a refresh"].exists)
            XCTAssertFalse(element("progress-welcome-back", in: app).exists)
            let first = element("progress-skill-showdown", in: app)
            let due = element("progress-skill-potMath", in: app)
            XCTAssertLessThan(first.frame.minY, due.frame.minY, "Strongest first")
            XCTAssertTrue(due.label.contains(code == "ko" ? "다시 볼 때예요" : "Ready for a refresh"), due.label)
            assertNoZeroOrStreak(in: app, code)
            capture(app, "progress-today-\(code)")
            let journal = app.staticTexts[code == "ko" ? "결정 500개까지 88개" : "500 decisions: 88 to go"]
            reveal(journal, in: app)
            capture(app, "progress-today-journal-\(code)")
            app.terminate()
        }
    }

    func testRefreshStartsTheReview() {
        let app = application("en", activity: "progress-today")
        app.launch()
        let start = app.buttons["progress-refresh-start"]
        reveal(start, in: app)
        start.tap()
        // The review opens on the due skill's short intro, then its first question.
        let tryQuestion = app.buttons["Try a question"]
        XCTAssertTrue(tryQuestion.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Count the pot"].exists)
        tryQuestion.tap()
        XCTAssertTrue(app.staticTexts["Review 1/1"].waitForExistence(timeout: 10))
    }

    func testAfterTimeAwayItWelcomesBackWithoutAResetOrAZero() {
        for code in ["en", "ko"] {
            let app = application(code, activity: "progress-away")
            app.launch()
            let welcome = element("progress-welcome-back", in: app)
            XCTAssertTrue(welcome.waitForExistence(timeout: 15))
            XCTAssertTrue(app.staticTexts[code == "ko" ? "다시 오셨네요. 기록은 그대로예요." : "Welcome back. Your progress is kept."].exists)
            XCTAssertTrue(app.staticTexts[code == "ko" ? "기술 3개를 가볍게 다시 볼 수 있어요." : "3 skills are ready for a quick refresh."].exists)
            XCTAssertTrue(app.buttons["progress-refresh-start"].exists)
            XCTAssertTrue(element("progress-decisions", in: app).label.hasPrefix("412 "))
            XCTAssertTrue(element("progress-strong", in: app).label.hasPrefix("5 "))
            XCTAssertEqual(element("progress-week", in: app).label,
                           code == "ko" ? "새로운 한 주예요. 한 문제면 시작이에요." : "A new week. One question gets you going.")
            assertNoZeroOrStreak(in: app, code)
            capture(app, "progress-away-\(code)")
            app.terminate()
        }
    }

    func testNothingDueIsAllCaughtUpAndLeadsOnToLearn() {
        for code in ["en", "ko"] {
            let app = application(code, activity: "completed")
            app.launch()
            let caughtUp = element("progress-caught-up", in: app)
            XCTAssertTrue(caughtUp.waitForExistence(timeout: 15))
            XCTAssertTrue(app.staticTexts[code == "ko" ? "모두 복습했어요" : "All caught up"].exists)
            XCTAssertTrue(element("progress-decisions", in: app).label.hasPrefix("1 "))
            XCTAssertEqual(element("progress-strong", in: app).label,
                           code == "ko" ? "첫 능숙 단계가 다음이에요" : "Your first Strong skill is next")
            assertNoZeroOrStreak(in: app, code)
            capture(app, "progress-caught-up-\(code)")
            app.buttons["records-continue"].tap()
            XCTAssertTrue(app.tabBars.buttons[code == "ko" ? "배우기" : "Learn"].isSelected)
            app.terminate()
        }
    }

    func testFreshInstallShowsAStartInsteadOfZeros() {
        for code in ["en", "ko"] {
            let app = application(code, activity: nil)
            app.launch()
            XCTAssertTrue(element("progress-start", in: app).waitForExistence(timeout: 15))
            XCTAssertFalse(element("progress-decisions", in: app).exists)
            XCTAssertFalse(element("progress-week", in: app).exists)
            assertNoZeroOrStreak(in: app, code)
            capture(app, "progress-fresh-\(code)")
            app.terminate()
        }
    }

    /// Progress is not a capped part: at AX5 the numbers, bars and actions stack and
    /// stay reachable above the tab bar.
    func testLargestTextKeepsNumbersBarsAndActionsReachable() {
        for code in ["en", "ko"] {
            for activity in ["progress-today", "progress-away"] {
                let app = application(code, activity: activity, largeText: true)
                app.launch()
                let decisions = element("progress-decisions", in: app)
                XCTAssertTrue(decisions.waitForExistence(timeout: 15))
                XCTAssertTrue(decisions.label.hasPrefix("412 "))
                capture(app, "progress-ax5-\(activity)-\(code)")
                reveal(app.buttons["progress-refresh-start"], in: app)
                let strong = element("progress-strong", in: app)
                XCTAssertGreaterThan(strong.frame.minY, decisions.frame.minY, "The two numbers stack")
                let bar = element("progress-skill-showdown", in: app)
                reveal(bar, in: app)
                XCTAssertGreaterThan(bar.frame.width, app.frame.width * 0.8)
                capture(app, "progress-ax5-\(activity)-skills-\(code)")
                reveal(app.buttons["records-details"], in: app)
                app.terminate()
            }
        }
    }
}
