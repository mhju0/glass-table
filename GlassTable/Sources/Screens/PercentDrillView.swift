// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct PercentDrillConfig {
    let slug: String
    let title: String
    let question: String
    let questionEn: String
    let grade: (Int, BetSpot) -> PercentReveal
    /// What the GT_DEMO_REVEAL hook commits — spot index 1's correct pct (baseSeed
    /// 20260722), rounded, so the demo reveal grades 정확 for screenshots.
    let demoAnswer: Int

    static let potOdds = PercentDrillConfig(
        slug: DrillKind.potodds.rawValue, title: "팟 오즈",
        question: "콜하려면 에퀴티가 몇 % 필요할까요?",
        questionEn: "Equity needed to call?",
        grade: { gradePotOdds(estimatePct: $0, spot: $1) },
        demoAnswer: 31)

    static let mdf = PercentDrillConfig(
        slug: DrillKind.mdf.rawValue, title: "MDF",
        question: "최소 몇 %는 폴드하지 않아야 할까요?",
        questionEn: "Minimum defense frequency?",
        grade: { gradeMDF(estimatePct: $0, spot: $1) },
        demoAnswer: 55)
}

struct PercentDrillView: View {
    let config: PercentDrillConfig
    @State private var model: DrillModel<BetSpot, Int, PercentReveal>
    @State private var estimate = 50

    init(config: PercentDrillConfig) {
        self.config = config
        _model = State(initialValue: DrillModel(
            slug: config.slug,
            generate: BetSpotGenerator.spot(baseSeed:index:),
            grade: config.grade,
            demoAnswer: config.demoAnswer))
    }

    private func chip(_ label: String, _ bb: Int) -> some View {
        VStack(spacing: 4) {
            Text(label).font(GT.semibold(11)).foregroundStyle(.white.opacity(0.62))
            Text("\(bb) bb").font(GT.title(26)).foregroundStyle(.white)
        }
        .frame(minWidth: 96)
        .padding(.vertical, 14).padding(.horizontal, 18)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private func potBet(_ spot: BetSpot) -> some View {
        HStack(spacing: 14) { chip("팟", spot.pot); chip("벳", spot.bet) }
            .frame(maxWidth: .infinity)
            .padding(.top, 30)
    }

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DrillScaffold(title: config.title, streak: model.streak) {
                    potBet(spot)
                } sheet: {
                    VStack(spacing: 15) {
                        VStack(spacing: 3) {
                            Text(config.question).font(GT.title(15)).foregroundStyle(GT.ink)
                            Text(config.questionEn).font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        }
                        EstimateStepper(value: estimate, step: 5, suffix: "%",
                                        onAdjust: { estimate = max(0, min(100, estimate + $0)) })
                        PrimaryCTAButton(title: "확인하기", action: { model.commit(estimate) })
                    }
                }
            case let .revealed(spot, reveal):
                DrillScaffold(title: config.title, streak: model.streak) {
                    potBet(spot)
                } sheet: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 9) {
                            GradePill(band: reveal.band)
                            Text("내 답 \(reveal.answerPct)% · 정답 \(pctText(reveal.correctPct))%")
                                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                        }
                        Text(reveal.whyText)
                            .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                        PrimaryCTAButton(title: "다음 문제", action: { estimate = 50; model.next() })
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview { PercentDrillView(config: .potOdds) }
