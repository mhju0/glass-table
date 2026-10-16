// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

@main
struct GlassTableApp: App {
    var body: some Scene {
        WindowGroup {
            LanguageRoot()
        }
    }
}

/// Reads the language inside a view rather than on the App, so a language change
/// re-renders through ordinary view invalidation; the iOS 27 beta left the Settings
/// screen in the old language with the App-level read. RootView keeps its identity,
/// so its state survives a language switch.
private struct LanguageRoot: View {
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system

    private var resolvedLanguage: LearningLanguage {
        #if DEBUG
        if let code = ProcessInfo.processInfo.environment["GT_DEMO_LANGUAGE"],
           let selected = LearningLanguage(rawValue: code) { return selected }
        #endif
        return language.resolved
    }

    var body: some View {
        RootView()
            .disclosureGroupStyle(GTDisclosureStyle())
            .environment(\.learningLanguage, resolvedLanguage)
            .environment(\.locale, Locale(identifier: resolvedLanguage.rawValue))
    }
}
