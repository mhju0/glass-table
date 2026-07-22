// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct RootView: View {
    @State private var model = OutsDrillModel()

    var body: some View {
        switch model.phase {
        case let .deciding(spot, estimate):
            DecideView(spot: spot, estimate: estimate, streak: model.streak,
                       onAdjust: model.adjust, onCommit: model.commit)
        case let .revealed(spot, estimate, reveal):
            RevealView(spot: spot, estimate: estimate, reveal: reveal,
                       streak: model.streak, onNext: model.next)
        }
    }
}
