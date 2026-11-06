// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
@testable import GlassTable

final class KoreanRatingTests: XCTestCase {
    private func defaults() -> UserDefaults {
        let name = "KoreanRatingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testTheStorefrontDecidesAndTheRegionOnlyStandsInBeforeIt() {
        XCTAssertTrue(KoreanRating.applies(storefront: "KOR", region: "US"))
        XCTAssertFalse(KoreanRating.applies(storefront: "USA", region: "KR"))
        XCTAssertTrue(KoreanRating.applies(storefront: nil, region: "KR"))
        XCTAssertFalse(KoreanRating.applies(storefront: nil, region: "US"))
        XCTAssertFalse(KoreanRating.applies(storefront: nil, region: nil))
    }

    func testTheCachedStorefrontOutranksTheDeviceRegion() {
        let defaults = defaults()
        let korea = Locale(identifier: "ko_KR")
        XCTAssertTrue(KoreanRating.showsLaunchNotice(defaults: defaults, locale: korea, environment: [:]))
        defaults.set("USA", forKey: KoreanRating.storefrontKey)
        XCTAssertFalse(KoreanRating.showsLaunchNotice(defaults: defaults, locale: korea, environment: [:]))
        defaults.set("KOR", forKey: KoreanRating.storefrontKey)
        XCTAssertTrue(KoreanRating.showsLaunchNotice(defaults: defaults, locale: Locale(identifier: "en_US"),
                                                     environment: [:]))
    }

    func testUITestLaunchesSkipTheNoticeUnlessTheyPinARegion() {
        let defaults = defaults()
        let korea = Locale(identifier: "ko_KR")
        let store = ["GT_TEST_STORE_ID": UUID().uuidString]
        XCTAssertFalse(KoreanRating.showsLaunchNotice(defaults: defaults, locale: korea, environment: store))
        XCTAssertTrue(KoreanRating.isKorea(defaults: defaults, locale: korea, environment: store))
        var pinned = store
        pinned["GT_DEMO_RATING_REGION"] = "KOR"
        XCTAssertTrue(KoreanRating.showsLaunchNotice(defaults: defaults, locale: Locale(identifier: "en_US"),
                                                     environment: pinned))
        pinned["GT_DEMO_RATING_REGION"] = "USA"
        XCTAssertFalse(KoreanRating.showsLaunchNotice(defaults: defaults, locale: korea, environment: pinned))
    }

    func testTheNoticeMatchesTheGRACDecision() {
        XCTAssertEqual(KoreanRating.classificationNumber, "CC-NM-261105-006")
        XCTAssertEqual(KoreanRating.decisionDate, "2026. 11. 05.")
        XCTAssertGreaterThanOrEqual(KoreanRating.noticeSeconds, 3)
        XCTAssertTrue(KoreanRating.warning(in: .korean).contains("19세 미만의 청소년은 이용할 수 없습니다"))
        XCTAssertTrue(KoreanRating.warning(in: .english).contains("rated 19"))
    }
}
