// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills
import GlassTableEngine

@main
struct GlassTableApp: App {
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system

    init() {
        #if DEBUG
        // GT_DEMO_SHOWDOWN_SPOT=Kc6d,5d3h,Qc6sKdJh3d deals every showdown question
        // from these cards: yours, the opponent's, the board.
        let parts = ProcessInfo.processInfo.environment["GT_DEMO_SHOWDOWN_SPOT"]?
            .split(separator: ",").compactMap { Card.parse(String($0)) } ?? []
        if parts.count == 3, parts[0].count == 2, parts[1].count == 2, parts[2].count == 5 {
            ShowdownSpotGenerator.demoSpot = ShowdownSpot(hero: parts[0], villain: parts[1], board: parts[2])
        }
        #endif
    }

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
                .environment(\.learningLanguage, resolvedLanguage)
                .environment(\.locale, Locale(identifier: resolvedLanguage.rawValue))
        }
    }
}
