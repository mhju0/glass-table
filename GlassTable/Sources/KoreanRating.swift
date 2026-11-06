// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import StoreKit
import GlassTableDrills

/// The GRAC rating for Korea (D59): 청소년이용불가, content descriptor 사행성.
/// Korean law asks for the rating and the descriptor on the launch screen and a
/// rating table inside the app; both appear only for App Store Korea users.
enum KoreanRating {
    static let classificationNumber = "CC-NM-261105-006"
    static let decisionDate = "2026. 11. 05."
    /// GRAC: shown on the launch screen for at least three seconds.
    static let noticeSeconds: Double = 3
    /// The App Store country StoreKit last reported, kept for the next launch.
    static let storefrontKey = "rating.storefrontCountry"

    static func warning(in language: LearningLanguage) -> String {
        language.text("이 게임물은 청소년이용불가 게임물로 19세 미만의 청소년은 이용할 수 없습니다.",
                      "This game is rated 19. Those under 19 years old are prohibited from playing.")
    }

    static func descriptorNote(in language: LearningLanguage) -> String {
        language.text("베팅과 배당을 모사하는 홀덤 연습이 포함되어 있습니다. 실제 돈이나 경품은 걸지 않습니다.",
                      "Includes Hold'em practice that simulates betting and payouts. No real money or prizes.")
    }

    /// Korea when the App Store country is Korea; before StoreKit has answered once,
    /// when the device region is Korea.
    static func applies(storefront: String?, region: String?) -> Bool {
        if let storefront { return storefront == "KOR" }
        return region == "KR"
    }

    static func isKorea(defaults: UserDefaults = .standard, locale: Locale = .current,
                        environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        #if DEBUG
        // GT_DEMO_RATING_REGION=KOR|USA pins the storefront for tests and screenshots.
        if let pinned = environment["GT_DEMO_RATING_REGION"] { return pinned == "KOR" }
        #endif
        return applies(storefront: defaults.string(forKey: storefrontKey), region: locale.region?.identifier)
    }

    /// Whether this launch opens with the rating notice. UI tests skip it unless they
    /// pin a region, so their own launches are not held for three seconds.
    static func showsLaunchNotice(defaults: UserDefaults = .standard, locale: Locale = .current,
                                  environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        #if DEBUG
        if environment["GT_TEST_STORE_ID"] != nil, environment["GT_DEMO_RATING_REGION"] == nil { return false }
        #endif
        return isKorea(defaults: defaults, locale: locale, environment: environment)
    }

    /// GT_DEMO_RATING_HOLD=1 keeps the notice up for screenshots and content checks.
    static var holdsNotice: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["GT_DEMO_RATING_HOLD"] != nil
        #else
        return false
        #endif
    }

    /// Asks StoreKit for the App Store country and keeps it for the next launch.
    static func refreshStorefront(defaults: UserDefaults = .standard,
                                  environment: [String: String] = ProcessInfo.processInfo.environment) async {
        #if DEBUG
        if environment["GT_TEST_STORE_ID"] != nil || environment["GT_DEMO_RATING_REGION"] != nil { return }
        #endif
        if let code = await Storefront.current?.countryCode { defaults.set(code, forKey: storefrontKey) }
    }
}
