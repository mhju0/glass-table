// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct RevealView: View {
    let spot: OutsSpot
    let reveal: OutsReveal
    let streak: Int
    let onNext: () -> Void

    private func wrap(_ cards: [Card], dead: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 6), count: 7), spacing: 6) {
            ForEach(Array(cards.enumerated()), id: \.offset) {
                PlayingCardView(card: $0.element, size: 34, dead: dead)
            }
        }
    }

    var body: some View {
        DrillScaffold(title: "아웃 카운팅", streak: streak) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ForEach(Array(spot.hero.enumerated()), id: \.offset) { PlayingCardView(card: $0.element, size: 30) }
                    Text("vs").font(GT.body(12)).foregroundStyle(.white.opacity(0.6))
                    ForEach(Array(spot.villain.enumerated()), id: \.offset) { PlayingCardView(card: $0.element, size: 30) }
                }
                SectionLabel(text: "리버 아웃 · \(reveal.outs.count)장").padding(.top, 6)
                wrap(reveal.outs, dead: false)
                if !reveal.excluded.isEmpty {
                    SectionLabel(text: "제외 · 상대 핸드 개선").padding(.top, 8)
                    wrap(reveal.excluded, dead: true)
                }
            }
        } sheet: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 9) {
                    GradePill(band: reveal.band)
                    Text("내 답 \(reveal.estimate) · 정답 \(spot.outCount)")
                        .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                }
                Text("≈ \(Int(reveal.improvementPct))% 개선  ·  룰 오브 2")
                    .font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
                Text(reveal.whyText)
                    .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                PrimaryCTAButton(title: "다음 문제", action: onNext)
            }
        }
    }
}

#Preview {
    let spot = OutsSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
                        board: Card.parse("Qh7h2s3c")!, outs: Card.parse("4h5h6h8h9hThJh")!,
                        excluded: Card.parse("2h3h")!)
    return RevealView(spot: spot, reveal: gradeOuts(estimate: 9, spot: spot),
                      streak: 8, onNext: {})
}
