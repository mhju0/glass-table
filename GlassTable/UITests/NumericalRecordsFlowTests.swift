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
        for _ in 0..<5 {
            if details.isHittable && details.frame.maxY < app.windows.firstMatch.frame.maxY - 100 { break }
            app.swipeUp()
        }
        details.tap()
        let streak = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label BEGINSWITH %@",
            code == "ko" ? "연속 일수" : "Day streak", "0")).firstMatch
        for _ in 0..<5 {
            if streak.exists && streak.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(streak.waitForExistence(timeout: 5))
        XCTAssertTrue(streak.label.contains("0"), streak.label)
        capture(app, name: "records-streak-\(code)-\(appearance)")
        let row = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@",
            code == "ko" ? "콜하려면 얼마나 자주 이겨야 할까요?" : "How often must I win to call?",
            code == "ko" ? "5문제" : "5 answers")).firstMatch
        for _ in 0..<8 {
            if row.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(row.exists)
        let nowLabel = code == "ko" ? "지금 복습" : "review now"
        XCTAssertFalse(row.label.contains(nowLabel), row.label)
        let tomorrow = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@",
            code == "ko" ? "가능한 두 장 조합" : "Possible two-card hands",
            code == "ko" ? "5문제" : "5 answers")).firstMatch
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
