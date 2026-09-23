// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

@main
struct GlassTableApp: App {
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
