// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// D54 (owner's Option B): dense table parts grow to AX3 and stop; explanation text
/// beside them keeps growing to AX5.
final class LargestTextCapTests: XCTestCase {
    private let ax3 = "UICTContentSizeCategoryAccessibilityXL"
    private let ax5 = "UICTContentSizeCategoryAccessibilityXXXL"

    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ size: String, code: String = "en", phase: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english",
                               "-UIPreferredContentSizeCategoryName", size]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_TEST_FIRST_LESSON": "0",
                                 "GT_DEMO_TAB": "play", "GT_DEMO_PRACTICE": "1"]
        if let phase { app.launchEnvironment["GT_DEMO_FREE_PHASE"] = phase }
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        let found = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(found.waitForExistence(timeout: 15), "Missing \(id)")
        return found
    }

    private struct RaiseHeights { let title, pill, amount, context: CGFloat }

    private func raiseHeights(_ size: String, code: String) -> RaiseHeights {
        let app = launch(size, code: code, phase: "raise-open")
        XCTAssertTrue(app.buttons["free-raise-confirm"].waitForExistence(timeout: 15))
        let heights = RaiseHeights(title: element(app, "free-table-title").frame.height,
                                   pill: element(app, "free-table-help").frame.height,
                                   amount: element(app, "free-raise-amount").frame.height,
                                   context: element(app, "free-raise-context").frame.height)
        app.terminate()
        return heights
    }

    private func verifyRaiseHeader(code: String) {
        let at3 = raiseHeights(ax3, code: code)
        let at5 = raiseHeights(ax5, code: code)
        XCTAssertEqual(at5.title, at3.title, accuracy: 0.5, "The top-bar title stops growing at AX3")
        XCTAssertEqual(at5.pill, at3.pill, accuracy: 0.5, "The Decision help pill stops growing at AX3")
        XCTAssertEqual(at5.amount, at3.amount, accuracy: 0.5, "The raise title stops growing at AX3")
        XCTAssertGreaterThan(at5.context, at3.context + 5, "The explanation under the raise title keeps growing")
    }

    func testRaiseHeaderStopsAtAX3English() { verifyRaiseHeader(code: "en") }
    func testRaiseHeaderStopsAtAX3Korean() { verifyRaiseHeader(code: "ko") }

    private func dockHeights(_ size: String) -> (facts: CGFloat, pot: CGFloat) {
        let app = launch(size)
        let raise = app.buttons["free-raise"]
        XCTAssertTrue(raise.waitForExistence(timeout: 15))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: raise)
        waitForExpectations(timeout: 20)
        let heights = (element(app, "free-turn-facts").frame.height, element(app, "table-pot").frame.height)
        app.terminate()
        return heights
    }

    func testTurnFactsAndPotStopAtAX3() {
        let at3 = dockHeights(ax3)
        let at5 = dockHeights(ax5)
        XCTAssertEqual(at5.facts, at3.facts, accuracy: 0.5, "To call and Pot stop growing at AX3")
        XCTAssertEqual(at5.pot, at3.pot, accuracy: 0.5, "The pot label stops growing at AX3")
    }
}
