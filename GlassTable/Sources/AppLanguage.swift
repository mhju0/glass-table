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
}
