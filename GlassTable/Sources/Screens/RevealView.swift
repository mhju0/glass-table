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
                                    .stroke(GT.cta, lineWidth: 3)
                            }
                        }
                }
                .buttonStyle(GTPress())
                .accessibilityHint("리버 완성 핸드 보기")
            }
        }
    }

    /// Board + tapped river runout, then both players' made hands and the verdict.
    private func explainPanel(_ river: Card) -> some View {
        let ex = explainRiver(spot: spot, river: river)
        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                ForEach(Array(spot.board.enumerated()), id: \.offset) {
                    PlayingCardView(card: $0.element, size: 40)
                }
                Text("+").font(GT.title(16)).foregroundStyle(.white.opacity(0.7))
                PlayingCardView(card: river, size: 40)
                    .overlay(RoundedRectangle(cornerRadius: 40 * 0.17).stroke(GT.cta, lineWidth: 2.5))
            }
            Text("내 핸드 · \(handName(ex.hero))").font(GT.title(14)).foregroundStyle(.white)
            Text("상대 · \(handName(ex.villain))").font(GT.semibold(13)).foregroundStyle(.white.opacity(0.85))
            Text(ex.heroWins ? "→ 내가 이겨요" : "→ 완성해도 상대가 더 강해요")
                .font(GT.title(13))
                .foregroundStyle(Color(hex: ex.heroWins ? 0xA5F3CB : 0xFFB9B9))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    var body: some View {
        DrillScaffold(title: "아웃 카운팅", streak: streak) {
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
                            explainPanel(selected).padding(.top, 10).id("explain")
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
