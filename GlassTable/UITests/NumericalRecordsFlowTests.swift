import XCTest

final class NumericalRecordsFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEnglishLightRecords() { records(code: "en", appearance: "light") }
    func testEnglishDarkRecords() { records(code: "en", appearance: "dark") }
    func testKoreanLightRecords() { records(code: "ko", appearance: "light") }
    func testKoreanDarkRecords() { records(code: "ko", appearance: "dark") }

    private func records(code: String, appearance: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-glassTable.language", code == "ko" ? "korean" : "english", "-appAppearance", appearance]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_ACTIVITY": "records-time", "GT_DEMO_TAB": "records"]
        app.launch()
        let details = app.buttons["records-details"]
        XCTAssertTrue(details.waitForExistence(timeout: 15))
        details.tap()
        let streak = app.descendants(matching: .any)["records-day-streak"]
        XCTAssertTrue(streak.waitForExistence(timeout: 5))
        XCTAssertTrue(streak.label.contains("0"), streak.label)
        capture(app, name: "records-streak-\(code)-\(appearance)")
        let row = app.descendants(matching: .any)["record-potOdds"]
        for _ in 0..<8 {
            if row.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(row.exists)
        let nowLabel = code == "ko" ? "지금 복습" : "review now"
        XCTAssertFalse(row.label.contains(nowLabel), row.label)
        let tomorrow = app.descendants(matching: .any)["record-combos"]
        XCTAssertTrue(tomorrow.label.contains(code == "ko" ? "내일 복습" : "review tomorrow"), tomorrow.label)

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Detailed records must stay expanded after scene refresh")
        XCTAssertFalse(row.label.contains(nowLabel), row.label)
        capture(app, name: "records-time-\(code)-\(appearance)")
        app.terminate()
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
