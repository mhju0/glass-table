// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// 오늘 — home. One screen answering exactly one question: what do I do right now?
///
struct TodayView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenReview: () -> Void
    private var due: [Concept] { model.dueConcepts() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.screen) {
                header
                recommendation
                context
            }
            .padding(.horizontal, 18)
        }
        .safeAreaInset(edge: .bottom) {
            primaryAction
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(GT.felt)
        }
        .gtTabBarClearance(20)
        .background(FeltBackground())
    }

    private func streakChip(symbol: String, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 11.5, weight: .semibold))
            Text(text).font(GT.semibold(12).monospacedDigit())
        }
        .foregroundStyle(tint)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if dynamicTypeSize.isAccessibilitySize {
                Text("오늘").font(GT.title(30)).foregroundStyle(GT.onFelt)
                if model.state.streak.current > 0 {
                    streakSummary(includeFreezeVisual: false)
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("오늘").font(GT.title(30)).foregroundStyle(GT.onFelt)
                    Spacer()
                    if model.state.streak.current > 0 {
                        streakSummary(includeFreezeVisual: true)
                    }
                }
            }
            Text(subtitleLine).font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
        }
        .padding(.top, 14)
    }

    private func streakSummary(includeFreezeVisual: Bool) -> some View {
        HStack(spacing: 9) {
            streakChip(symbol: "flame.fill",
                       text: "\(model.state.streak.current)일째",
                       tint: GT.mint)
            if includeFreezeVisual, model.state.streak.freezesRemaining > 0 {
                streakChip(symbol: "shield.fill",
                           text: "\(model.state.streak.freezesRemaining)",
                           tint: GT.onFeltSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("연속 \(model.state.streak.current)일째"
            + (model.state.streak.freezesRemaining > 0
               ? ", 하루 놓쳐도 지켜주는 보호 \(model.state.streak.freezesRemaining)개" : ""))
    }

    /// Only claims the screen can keep: the old "N문제 · 약 X분" promised a daily set
    /// no button ever played.
    private var subtitleLine: String {
        if !due.isEmpty { return "다시 풀어볼 문제 \(due.count)개가 있어요" }
        if model.nextNode == nil { return "모든 레슨 완료 · 복습으로 감각을 유지해요" }
        return model.state.nodes.isEmpty ? "첫 단계부터 시작해요" : "다음 단계를 이어가요"
    }

    @ViewBuilder
    private var recommendation: some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            SectionLabel(text: "지금 할 일", onDark: false)
            if !due.isEmpty {
                Text("배운 내용을 다시 풀어봐요").font(GT.title(24)).foregroundStyle(GT.ink)
                Text(due.prefix(3).map(conceptTitle).joined(separator: " · "))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let node = model.nextNode {
                Text(node.title).font(GT.title(24)).foregroundStyle(GT.ink)
                Text(nodeBlurb(node)).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("모든 레슨을 마쳤어요").font(GT.title(24)).foregroundStyle(GT.ink)
                Text("새 복습이 생기면 오늘의 추천으로 다시 알려드릴게요.")
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.Radius.panel)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if !due.isEmpty {
            FeltCTAButton(title: "복습 \(min(5, due.count))개 시작") { onOpenReview() }
        } else if let node = model.nextNode {
            FeltCTAButton(title: model.state.nodes.isEmpty ? "첫 레슨 시작" : "이어서 배우기") {
                onOpenNode(node)
            }
        }
    }

    @ViewBuilder
    private var context: some View {
        if !due.isEmpty, let node = model.nextNode {
            VStack(alignment: .leading, spacing: 5) {
                SectionLabel(text: "그다음")
                Text(node.title).font(GT.title(18)).foregroundStyle(GT.onFelt)
                Text(nodeBlurb(node)).font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
            }
            .accessibilityElement(children: .combine)
        } else if !model.needingExplainer().isEmpty {
            Text("막힌 개념은 기록에서 따라 배우기로 다시 볼 수 있어요.")
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
        }
    }
}

/// `sheet(item:)` currency for the replay sheets here and in 기록.
extension Concept: @retroactive Identifiable {
    public var id: String { rawValue }
}

/// Korean title for a concept, taken from the node that teaches it so the path and
/// every other surface can never drift apart.
func conceptTitle(_ c: Concept) -> String {
    Curriculum.allNodes.first { Curriculum.taughtConcept(of: $0) == c }?.title
        ?? c.rawValue
}

/// One verb line per node — the same rule the drill headers already follow.
func nodeBlurb(_ node: CurriculumNode) -> String {
    switch node.kind {
    case let .drill(c): return conceptBlurb(c)
    case .boss: return "배운 것을 섞어서 확인해요"
    }
}

func conceptBlurb(_ c: Concept, language: LearningLanguage = .korean) -> String {
    switch c {
    case .showdown:    return language.text("누가 이겼는지 읽어요", "Read who won the hand")
    case .potMath:     return language.text("팟이 얼마인지 세요", "Count the chips in the pot")
    case .position:    return language.text("내 뒤에 몇 명이 남았는지 세요", "Count the players still to act")
    case .combos:      return language.text("내 카드가 지운 상대 콤보를 세요", "Count the combos your cards remove")
    case .potOdds:     return language.text("낼 가격을 필요 에퀴티로 바꿔요", "Turn the price into needed equity")
    case .outs:        return language.text("이기는 카드를 세서 확률로 바꿔요", "Count winning cards, then the chance")
    case .equitySense: return language.text("이길 확률을 눈대중으로 맞춰요", "Estimate your chance to win")
    case .evCall:      return language.text("콜했을 때의 기대값을 계산해요", "Work out what a call is worth")
    case .callFold:    return language.text("이길 확률과 낼 가격을 비교해요", "Compare your chance to win with the price")
    case .rangeNotation: return language.text("핸드 묶음이 몇 콤보인지 세요", "Count the combos in hand shorthand")
    case .rfi:           return language.text("이 자리에서 열 핸드인지 판단해요", "Decide whether to open from this seat")
    case .rangeRead:     return language.text("상대의 행동을 보고 가능한 패를 좁혀요", "Narrow their hands from their actions")
    case .hitFrequency:  return language.text("이 보드가 레인지의 몇 %를 맞혔는지 세요", "Count how much of a range this board hits")
    case .rangeAdvantage: return language.text("이 보드가 누구에게 유리한지 판단해요", "Decide who this board favors")
    case .evLoss:      return language.text("고른 쪽이 몇 bb를 버렸는지 확인해요", "See how many bb a choice gave up")
    case .actionRead:  return language.text("벳과 체크 뒤에 남는 패의 범위를 읽어요", "Read the hands behind a bet or check")
    case .defend:      return language.text("오픈에 맞서 폴드·콜·3벳을 판단해요", "Fold, call or 3-bet against a raise")
    case .mdf:         return language.text("얼마나 자주 지켜야 하는지 계산해요", "Work out how often to continue")
    }
}
