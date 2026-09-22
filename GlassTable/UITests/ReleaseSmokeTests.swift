// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// Runs without demo hooks, including when the app is compiled in Release.
final class ReleaseSmokeTests: XCTestCase {
    func testLaunchAndOpenStudyGuideWithoutDemoHooks() {
        let app = XCUIApplication()
        app.launch()
        if app.buttons["건너뛰기"].waitForExistence(timeout: 3) {
            app.buttons["건너뛰기"].tap()
        }
        XCTAssertTrue(app.buttons["설정"].waitForExistence(timeout: 15))
        app.buttons["설정"].tap()
        let guide = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "공부 방법")).firstMatch
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()
        XCTAssertTrue(app.staticTexts["한 번에 한 가지씩 배워요"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["다음 이야기"].isEnabled)
    }

    func testResponsiveLaunchMeasurement() {
        let app = XCUIApplication()
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)], options: options) {
            app.launch()
        }
    }
}
