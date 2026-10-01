// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

@main
struct GlassTableApp: App {
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system

    private var resolvedLanguage: LearningLanguage {
        #if DEBUG
        if let code = ProcessInfo.processInfo.environment["GT_DEMO_LANGUAGE"],
           let selected = LearningLanguage(rawValue: code) { return selected }
        #endif
        return language.resolved
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .disclosureGroupStyle(GTDisclosureStyle())
                .preferredColorScheme(appearance.colorScheme)
                .environment(\.learningLanguage, resolvedLanguage)
                .environment(\.locale, Locale(identifier: resolvedLanguage.rawValue))
        }
    }
}
