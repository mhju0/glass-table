// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct RootView: View {
    private let spot = OutsSpotGenerator.spot(baseSeed: 1, index: 0)
    var body: some View {
        VStack(spacing: 8) {
            Text("Glass Table").font(.largeTitle.bold())
            Text("Sample spot: \(spot.outCount) outs")
            Text(spot.hero.map(\.description).joined(separator: " ")
                 + "  vs  " + spot.villain.map(\.description).joined(separator: " "))
                .monospaced()
        }
        .padding()
    }
}
