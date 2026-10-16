import SwiftUI
import GlassTableDrills
import GlassTableEngine

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, korean, english
    static let storageKey = "glassTable.language"
    var id: String { rawValue }
    var resolved: LearningLanguage {
        switch self {
        case .system: .preferred(in: Locale.preferredLanguages)
        case .korean: .korean
        case .english: .english
        }
    }
    var title: String {
        switch self {
        case .system: resolved.text("기기 설정", "System")
        case .korean: "한국어"
        case .english: "English"
        }
    }
}

/// The saved language choice, owned once by `RootView`. Settings writes it here and
/// the root injects the resolved language, so a switch re-renders every screen at once.
/// The App used to inject it inside `WindowGroup`: on iOS 27 the App body re-runs with
/// the new value, but the open window keeps the environment it was created with.
@Observable
@MainActor
final class LanguageSettings {
    private let defaults: UserDefaults
    var preference: AppLanguage {
        didSet { defaults.set(preference.rawValue, forKey: AppLanguage.storageKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preference = defaults.string(forKey: AppLanguage.storageKey)
            .flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    var resolved: LearningLanguage {
        #if DEBUG
        if let code = ProcessInfo.processInfo.environment["GT_DEMO_LANGUAGE"],
           let selected = LearningLanguage(rawValue: code) { return selected }
        #endif
        return preference.resolved
    }
}

private struct LearningLanguageKey: EnvironmentKey {
    static let defaultValue: LearningLanguage = .korean
}

extension EnvironmentValues {
    var learningLanguage: LearningLanguage {
        get { self[LearningLanguageKey.self] }
        set { self[LearningLanguageKey.self] = newValue }
    }

    /// Poker terms lead and plain words follow. Off by default for newer players.
    var leadsWithTerms: Bool {
        get { self[LeadsWithTermsKey.self] }
        set { self[LeadsWithTermsKey.self] = newValue }
    }

    /// Questions are asked the simpler way: counts before percentages, chips rather
    /// than big blinds, and the full chart one tap away. On below "Plays regularly".
    var simpleQuestions: Bool {
        get { self[SimpleQuestionsKey.self] }
        set { self[SimpleQuestionsKey.self] = newValue }
    }
}

private struct LeadsWithTermsKey: EnvironmentKey {
    static let defaultValue = false
}

private struct SimpleQuestionsKey: EnvironmentKey {
    static let defaultValue = false
}

enum PokerTerms {
    /// Unset until the learner flips the switch; until then their level decides.
    static let storageKey = "glassTable.pokerTerms"

    static func lead(choice: Bool?, level: PlacementSelfReport) -> Bool {
        choice ?? level.leadsWithTerms
    }
}

extension PlacementSelfReport {
    func levelName(in language: LearningLanguage) -> String {
        switch self {
        case .newToPoker: language.text("처음 배워요", "New player")
        case .knowRules: language.text("규칙은 알아요", "Knows the rules")
        case .playRegularly: language.text("자주 쳐요", "Plays regularly")
        }
    }
}

/// A skill's everyday name and its poker term, in the order this learner reads them.
func skillNames(_ concept: Concept, language: LearningLanguage,
                termsLead: Bool) -> (lead: String, tag: String) {
    let plain = ConceptIntroduction.make(concept, language: language).title
    let term = concept.term(in: language)
    return termsLead ? (term, plain) : (plain, term)
}

func rangeMatchTitle(_ band: GradeBand, language: LearningLanguage) -> String {
    switch band {
    case .spotOn: language.text("많은 패가 맞아요", "Many hands match")
    case .close: language.text("맞은 패와 빠진 패를 봐요", "Some hands match")
    case .off: language.text("빠진 패와 더 고른 패를 비교해요", "Compare missing and extra hands")
    }
}

func practiceFeedbackTitle(_ concept: Concept, band: GradeBand, language: LearningLanguage) -> String? {
    if concept == .rangeRead { return rangeMatchTitle(band, language: language) }
    guard [.showdown, .potMath, .position, .outs, .combos, .rangeNotation].contains(concept) else { return nil }
    switch band {
    case .spotOn: return language.text("맞아요", "That's right")
    case .close: return language.text("근접했어요", "Close")
    case .off: return nil
    }
}
