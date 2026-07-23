// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct BlockerView: View {
    @State private var model = DrillModel<BlockerSpot, Int, BlockerReveal>(
        slug: DrillKind.blockers.rawValue,
        generate: BlockerSpotGenerator.spot(baseSeed:index:),
        grade: { gradeBlocker(estimate: $0, spot: $1) },
        // demoAnswer 3 = exact combo count at spot index 1 (baseSeed 20260722) → grades 정확 for screenshots.
        demoAnswer: 3)
    // nil = "not touched yet" → falls back to the current spot's class baseline.
    @State private var estimate: Int?

    private func zone(_ spot: BlockerSpot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "제거된 카드 · REMOVED")
            HStack(spacing: 7) {
                ForEach(Array(spot.removed.enumerated()), id: \.offset) {
                    PlayingCardView(card: $0.element)
                }
            }
            Text("남은 \(spot.className) 콤보는?")
                .font(GT.title(20)).foregroundStyle(.white).padding(.top, 16)
        }
    }

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DrillScaffold(title: "블로커", streak: model.streak) {
                    zone(spot)
                } sheet: {
                    VStack(spacing: 15) {
                        VStack(spacing: 3) {
                            Text("남은 \(spot.className) 콤보는 몇 개?")
                                .font(GT.title(15)).foregroundStyle(GT.ink)
                            Text("Combos remaining?").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        }
                        EstimateStepper(value: estimate ?? spot.baseline, onAdjust: { d in
                            estimate = max(0, min(16, (estimate ?? spot.baseline) + d))
                        })
                        PrimaryCTAButton(title: "확인하기",
                                         action: { model.commit(estimate ?? spot.baseline) })
                    }
                }
            case let .revealed(spot, reveal):
                DrillScaffold(title: "블로커", streak: model.streak) {
                    zone(spot)
                } sheet: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 9) {
                            GradePill(band: reveal.band)
                            Text("내 답 \(reveal.estimate) · 정답 \(reveal.count)")
                                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                        }
                        Text(reveal.whyText)
                            .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                        PrimaryCTAButton(title: "다음 문제",
                                         action: { estimate = nil; model.next() })
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview { BlockerView() }
