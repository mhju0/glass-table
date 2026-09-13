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
        if !due.isEmpty { return "복습 \(due.count)개가 기다리고 있어요" }
        if model.nextNode == nil { return "기초 완주 · 복습으로 감각을 유지해요" }
        return model.state.nodes.isEmpty ? "첫 단계부터 시작해요" : "다음 단계를 이어가요"
    }

    @ViewBuilder
    private var recommendation: some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            SectionLabel(text: "지금 할 일", onDark: false)
            if !due.isEmpty {
                Text("기억을 꺼내 볼 때예요").font(GT.title(24)).foregroundStyle(GT.ink)
                Text(due.prefix(3).map(conceptTitle).joined(separator: " · "))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let node = model.nextNode {
                Text(node.title).font(GT.title(24)).foregroundStyle(GT.ink)
                Text(nodeBlurb(node)).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("기초 코스를 마쳤어요").font(GT.title(24)).foregroundStyle(GT.ink)
                Text("새 복습이 생기면 오늘의 추천으로 다시 알려드릴게요.")
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
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
            Text("막힌 개념은 기록에서 천천히 다시 볼 수 있어요.")
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

func conceptBlurb(_ c: Concept) -> String {
    switch c {
    case .showdown:    return "누가 이겼는지 읽어요"
    case .potMath:     return "팟이 얼마인지 세요"
    case .position:    return "내 뒤에 몇 명이 남았는지 세요"
    case .combos:      return "내 카드가 지운 상대 콤보를 세요"
    case .potOdds:     return "낼 가격을 필요 에퀴티로 바꿔요"
    case .outs:        return "이기는 카드를 세서 확률로 바꿔요"
    case .equitySense: return "이길 확률을 눈대중으로 맞춰요"
    case .evCall:      return "이 콜이 얼마를 버는지 계산해요"
    case .callFold:    return "이길 확률과 낼 가격을 비교해요"
    case .rangeNotation: return "핸드 묶음이 몇 콤보인지 세요"
    case .rfi:           return "이 자리에서 열 핸드인지 판단해요"
    case .rangeRead:     return "행동만 보고 상대 패의 범위를 읽어요"
    case .hitFrequency:  return "이 보드가 레인지의 몇 %를 맞혔는지 세요"
    case .rangeAdvantage: return "이 보드가 누구에게 유리한지 판단해요"
    case .evLoss:      return "고른 쪽이 몇 bb를 버렸는지 확인해요"
    case .actionRead:  return "벳과 체크가 레인지를 어떻게 좁히는지 읽어요"
    case .defend:      return "오픈에 맞서 폴드·콜·3벳을 판단해요"
    case .mdf:         return "얼마나 자주 지켜야 하는지 계산해요"
    }
}
