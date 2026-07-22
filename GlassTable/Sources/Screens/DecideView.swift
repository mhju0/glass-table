// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct DecideView: View {
    let spot: OutsSpot
    let estimate: Int
    let streak: Int
    let onAdjust: (Int) -> Void
    let onCommit: () -> Void

    private func row(_ cards: [Card]) -> some View {
        HStack(spacing: 7) {
            ForEach(Array(cards.enumerated()), id: \.offset) { PlayingCardView(card: $0.element) }
        }
    }

    var body: some View {
        DrillScaffold(title: "아웃 카운팅", streak: streak) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "상대 · VILLAIN"); row(spot.villain)
                SectionLabel(text: "보드 · 턴").padding(.top, 10); row(spot.board)
                SectionLabel(text: "내 핸드 · HERO").padding(.top, 10); row(spot.hero)
            }
        } sheet: {
            VStack(spacing: 15) {
                VStack(spacing: 3) {
                    Text("리버에서 몇 장이면 이기나?").font(GT.title(15)).foregroundStyle(GT.ink)
                    Text("How many river cards win?").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                }
                EstimateStepper(value: estimate, onAdjust: onAdjust)
                PrimaryCTAButton(title: "확인하기", action: onCommit)
            }
        }
    }
}

#Preview {
    DecideView(spot: OutsSpotGenerator.spot(baseSeed: 1, index: 0),
               estimate: 8, streak: 3, onAdjust: { _ in }, onCommit: {})
}
