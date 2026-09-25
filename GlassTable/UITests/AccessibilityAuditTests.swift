// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// XCTest's accessibility audit on the screens a VoiceOver learner spends most time on.
/// Contrast is left out: the audit samples text scrolled under the translucent tab bar,
/// and the finding moves with the scroll position rather than staying on one element.
final class AccessibilityAuditTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func audit(_ name: String, environment: [String: String], swipes: Int = 0,
                       ready: (XCUIApplication) -> XCUIElement) throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launchEnvironment = environment.merging(
            ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_SEED": "1"]) { a, _ in a }
        app.launch()
        XCTAssertTrue(ready(app).waitForExistence(timeout: 15), "\(name) did not open")
        for _ in 0..<swipes { app.swipeUp() }
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast)) { issue in
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
