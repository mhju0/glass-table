import SwiftUI
import GlassTableDrills

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
}

private struct LeadsWithTermsKey: EnvironmentKey {
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
        case .playRegularly: language.text("가끔 쳐요", "Plays sometimes")
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
