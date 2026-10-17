// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills
import GlassTableEngine

@main
struct GlassTableApp: App {
    init() {
        #if DEBUG
        // GT_DEMO_SHOWDOWN_SPOT=Kc6d,5d3h,Qc6sKdJh3d deals every showdown question
        // from these cards: yours, the opponent's, the board.
        let parts = ProcessInfo.processInfo.environment["GT_DEMO_SHOWDOWN_SPOT"]?
            .split(separator: ",").compactMap { Card.parse(String($0)) } ?? []
        if parts.count == 3, parts[0].count == 2, parts[1].count == 2, parts[2].count == 5 {
            ShowdownSpotGenerator.demoSpot = ShowdownSpot(hero: parts[0], villain: parts[1], board: parts[2])
        }
        // GT_DEMO_OUTS_SPOT=24500:4 deals every outs question as the generated spot
        // with that base seed and index.
        let outs = ProcessInfo.processInfo.environment["GT_DEMO_OUTS_SPOT"]?
            .split(separator: ":").compactMap { Int(String($0)) } ?? []
        if outs.count == 2 {
            OutsSpotGenerator.demoSpot = OutsSpotGenerator.spot(baseSeed: UInt64(outs[0]), index: outs[1])
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .disclosureGroupStyle(GTDisclosureStyle())
        }
    }
}
