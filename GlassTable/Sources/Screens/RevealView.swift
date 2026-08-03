// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct RevealView: View {
    let spot: OutsSpot
    let reveal: OutsReveal
    let streak: Int
    let onNext: () -> Void
    @State private var selected: Card?

    private func grid(_ cards: [Card], dead: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 38), spacing: 8)],
                  alignment: .leading, spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selected = selected == card ? nil : card
                    }
                } label: {
                    PlayingCardView(card: card, size: 52, dead: dead)
                        .overlay {
                            if selected == card {
                                RoundedRectangle(cornerRadius: 52 * 0.17)
                                    .stroke(GT.mint, lineWidth: 3)
                            }
                        }
                }
                .buttonStyle(GTPress())
                .accessibilityHint("리버 완성 핸드 보기")
            }
        }
    }

    /// Cards neither player nor the board has shown — the honest denominator (52 − 8 = 44
    /// on a turn board with villain face-up). Computed, never typed: 47 is the flop number.
    private var unseen: Int { 52 - Set(spot.hero + spot.villain + spot.board).count }

    var body: some View {
        DrillScaffold(title: "아웃 카운팅", subtitle: DrillKind.outs.explain, streak: streak) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "상대 · VILLAIN"); CardRow(cards: spot.villain)
                        SectionLabel(text: "보드 · 턴").padding(.top, 10); CardRow(cards: spot.board)
                        SectionLabel(text: "내 핸드 · HERO").padding(.top, 10); CardRow(cards: spot.hero)
                        SectionLabel(text: "리버 아웃 · \(reveal.outs.count)장 · 눌러서 확인").padding(.top, 12)
                        grid(reveal.outs, dead: false)
                        if !reveal.excluded.isEmpty {
                            SectionLabel(text: "제외 · 상대 핸드 개선").padding(.top, 10)
                            grid(reveal.excluded, dead: true)
                        }
                        if let selected {
                            RiverExplainPanel(spot: spot, river: selected)
                                .padding(.top, 10).id("explain")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: selected) { _, new in
                    if new != nil {
                        withAnimation { proxy.scrollTo("explain", anchor: .bottom) }
                    }
                }
                .onAppear {
                    #if DEBUG
                    // GT_DEMO_TAP=<i>: preselect out i for screenshots (see GT_DEMO_REVEAL).
                    if let i = ProcessInfo.processInfo.environment["GT_DEMO_TAP"].flatMap(Int.init),
                       reveal.outs.indices.contains(i) {
                        selected = reveal.outs[i]
                    }
                    #endif
                }
            }
        } sheet: {
            VStack(alignment: .leading, spacing: 12) {
                VerdictRow(band: reveal.band, mine: reveal.estimate,
                           correct: spot.outCount, unit: "장")
                // Natural frequency first, percent subordinate and labelled as an
                // approximation: "44장 중 7장" is verifiable by counting, "14%" is not.
                Text("남은 \(unseen)장 중 \(spot.outCount)장")
                    .font(GT.title(15)).foregroundStyle(GT.ink)
                Text("룰 오브 2로 약 \(Int(reveal.improvementPct))% · 근사예요")
                    .font(GT.semibold(12)).foregroundStyle(GT.inkMuted)
                Text(reveal.whyText)
                    .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                GlossaryChip(term: DrillKind.outs.term)
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
