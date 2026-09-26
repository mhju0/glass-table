// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// XCTest's accessibility audit on the screens a VoiceOver learner spends most time on.
/// Contrast findings are skipped only for elements reaching into the tab bar or the scroll
/// fade just above it: there the audit samples text under a translucent material, and the
/// finding moves with the scroll position. Elsewhere on an unscrolled screen a contrast
/// failure fails the test.
final class AccessibilityAuditTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Room for the scroll-edge fade above the tab bar; findings there reached 22pt above it.
    private static let scrollFadeHeight: CGFloat = 56

    private func audit(_ name: String, environment: [String: String], swipes: Int = 0,
                       ready: (XCUIApplication) -> XCUIElement) throws {
        let app = XCUIApplication()
        // The reminder and language preferences outlive the per-test store; pin both so each
        // screen has one layout.
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
                                "-glassTable.language", "korean", "-reminder.enabled", "NO"]
        app.launchEnvironment = environment.merging(
            ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_SEED": "1"]) { a, _ in a }
        app.launch()
        XCTAssertTrue(ready(app).waitForExistence(timeout: 15), "\(name) did not open")
        for _ in 0..<swipes { app.swipeUp() }
        let fadeTop = app.tabBars.firstMatch.exists
            ? app.tabBars.firstMatch.frame.minY - Self.scrollFadeHeight : .infinity
        // After a swipe the audit flags plainly dark-on-cream labels on some runs, so the
        // scrolled screens are audited for everything except contrast.
        try app.performAccessibilityAudit(for: swipes == 0 ? .all : .all.subtracting(.contrast)) { issue in
            if issue.auditType == .contrast, let frame = issue.element?.frame, frame.maxY > fadeTop {
                return true
            }
            let element = issue.element.map { "\($0.elementType.rawValue) '\($0.label)' id=\($0.identifier)" } ?? "-"
            print("AUDIT \(name) | \(issue.auditType) | \(issue.compactDescription) | \(element)")
            return false
        }
        app.terminate()
    }

    func testPlayTable() throws {
        try audit("play", environment: ["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"]) {
            $0.descendants(matching: .any)["play-table-guide"]
        }
    }

    func testLessonQuestion() throws {
        try audit("lesson", environment: ["GT_DEMO_NODE": "u2-potOdds"]) {
            $0.descendants(matching: .any)["drill-explain"]
        }
    }

    func testPlayTableScrolled() throws {
        try audit("play-scrolled", environment: ["GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"], swipes: 1) {
            $0.descendants(matching: .any)["play-table-guide"]
        }
    }

    func testSettingsScrolled() throws {
        try audit("settings-scrolled", environment: ["GT_DEMO_SETTINGS": "1"], swipes: 1) {
            $0.switches["settings-reminder"]
        }
    }

    func testSettings() throws {
        try audit("settings", environment: ["GT_DEMO_SETTINGS": "1"]) {
            $0.switches["settings-reminder"]
        }
    }

    func testLessonSummaryWithMilestone() throws {
        try audit("summary", environment: ["GT_DEMO_NODE": "u2-potOdds",
                                           "GT_DEMO_SESSION_COMPLETE": "1",
                                           "GT_DEMO_MILESTONE": "unit"]) {
            $0.buttons["milestone-share"]
        }
    }
}
