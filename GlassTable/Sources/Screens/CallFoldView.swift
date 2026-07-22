// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct CallFoldView: View {
    @State private var model = DrillModel<CallFoldSpot, Bool, CallFoldReveal>(
        slug: DrillKind.callfold.rawValue,
        generate: CallFoldSpotGenerator.spot(baseSeed:index:),
        grade: { gradeCallFold(userCalls: $0, spot: $1) },
        demoAnswer: true)

    private func row(_ cards: [Card]) -> some View {
        HStack(spacing: 7) {
            ForEach(Array(cards.enumerated()), id: \.offset) { PlayingCardView(card: $0.element) }
        }
    }

    private func cardZone(_ spot: CallFoldSpot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "상대 · VILLAIN"); row(spot.villain)
            SectionLabel(text: "보드 · 턴").padding(.top, 10); row(spot.board)
            SectionLabel(text: "내 핸드 · HERO").padding(.top, 10); row(spot.hero)
            Text("팟 \(spot.pot) bb · 벳 \(spot.bet) bb")
                .font(GT.title(15)).foregroundStyle(.white).padding(.top, 12)
        }
    }

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DrillScaffold(title: "콜/폴드", streak: model.streak) {
                    cardZone(spot)
                } sheet: {
                    VStack(spacing: 15) {
                        VStack(spacing: 3) {
                            Text("콜해야 할까요?").font(GT.title(15)).foregroundStyle(GT.ink)
                            Text("Call or fold?").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        }
                        HStack(spacing: 10) {
                            SecondaryCTAButton(title: "폴드", action: { model.commit(false) })
                            PrimaryCTAButton(title: "콜", action: { model.commit(true) })
                        }
                    }
                }
            case let .revealed(spot, reveal):
                DrillScaffold(title: "콜/폴드", streak: model.streak) {
                    cardZone(spot)
                } sheet: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 9) {
                            GradePill(band: reveal.band)
                            Text("내 답 \(reveal.userCalls ? "콜" : "폴드") · 정답 \(reveal.correctIsCall ? "콜" : "폴드")")
                                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                        }
                        Text(reveal.whyText)
                            .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                        PrimaryCTAButton(title: "다음 문제", action: model.next)
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview { CallFoldView() }
