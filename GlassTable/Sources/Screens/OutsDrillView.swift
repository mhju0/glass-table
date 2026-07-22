// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct OutsDrillView: View {
    @State private var model = DrillModel<OutsSpot, Int, OutsReveal>(
        slug: DrillKind.outs.rawValue,
        generate: OutsSpotGenerator.spot(baseSeed:index:),
        grade: { gradeOuts(estimate: $0, spot: $1) },
        demoAnswer: 8)
    @State private var estimate = 8

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DecideView(spot: spot, estimate: estimate, streak: model.streak,
                           onAdjust: { estimate = max(0, min(21, estimate + $0)) },
                           onCommit: { model.commit(estimate) })
            case let .revealed(spot, reveal):
                RevealView(spot: spot, reveal: reveal, streak: model.streak,
                           onNext: { estimate = 8; model.next() })
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
