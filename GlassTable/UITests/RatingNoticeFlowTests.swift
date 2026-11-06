// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest

/// D59: App Store Korea opens with the GRAC notice for at least three seconds and
/// Settings carries the rating table; other storefronts see neither.
final class RatingNoticeFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(region: String, korean: Bool = true, ax: Bool = false,
                        hold: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += korean
            ? ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
            : ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-glassTable.language", "english"]
        if ax {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString, "GT_DEMO_SEED": "1",
                                 "GT_DEMO_SETTINGS": "1", "GT_DEMO_RATING_REGION": region]
        if hold { app.launchEnvironment["GT_DEMO_RATING_HOLD"] = "1" }
        app.launch()
        return app
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testKoreaShowsTheNoticeForThreeSecondsThenTheRatingTable() {
        let app = launch(region: "KOR")
        let launched = Date()
        let notice = app.descendants(matching: .any)["rating-notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: notice)
        wait(for: [gone], timeout: 8)
        // launch() returns once the first frame is up, about 0.7 s into the notice's
        // three seconds (KoreanRatingTests pins the duration itself).
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(launched), 2.0)

        let row = app.buttons["settings-rating"]
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        let number = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
                                  "등급분류번호", "CC-NM-261105-006")).firstMatch
        XCTAssertTrue(number.waitForExistence(timeout: 5))
        attach(app, name: "rating-table-ko")
    }

    func testKoreanNoticeCarriesTheWarning() {
        let app = launch(region: "KOR", hold: true)
        let notice = app.descendants(matching: .any)["rating-notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertTrue(notice.label.contains("19세 미만의 청소년은 이용할 수 없습니다"))
        attach(app, name: "rating-notice-ko")
    }

    func testEnglishInKoreaShowsTheEnglishWarning() {
        let app = launch(region: "KOR", korean: false, hold: true)
        let notice = app.descendants(matching: .any)["rating-notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertTrue(notice.label.contains("rated 19"))
        attach(app, name: "rating-notice-en")
    }

    func testNoticeFitsAtTheLargestTextSize() {
        let app = launch(region: "KOR", ax: true, hold: true)
        let notice = app.descendants(matching: .any)["rating-notice"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertTrue(app.windows.firstMatch.frame.contains(notice.frame))
        attach(app, name: "rating-notice-ko-ax5")
    }

    func testOtherStorefrontsSeeNoNoticeAndNoRatingRow() {
        let app = launch(region: "USA", korean: false)
        XCTAssertFalse(app.descendants(matching: .any)["rating-notice"].waitForExistence(timeout: 2))
        let responsible = app.buttons["settings-responsible"]
        for _ in 0..<6 where !responsible.isHittable { app.swipeUp() }
        XCTAssertTrue(responsible.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["settings-rating"].exists)
    }
}
