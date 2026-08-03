// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// 오늘 — home. One screen answering exactly one question: what do I do right now?
///
/// Free play is deliberately *not* here (spec §9). A grid of every exercise is the
/// choice paralysis the path exists to remove; 자유 연습 lives one tap down under 길.
struct TodayView: View {
    @Environment(ProgressionModel.self) private var model
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenReview: () -> Void

    private var due: [Concept] { model.dueConcepts() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                nextCard
                if !due.isEmpty { reviewCard }
                calibrationPanel
                if !model.needingExplainer().isEmpty { stuckPanel }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 96)   // clears the floating tab bar
        }
        .background(FeltBackground())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("오늘").font(GT.title(24)).foregroundStyle(GT.onFelt)
                Spacer()
                // Same rule as everywhere else: 🔥 only with a live streak.
                if model.state.streak.current > 0 {
                    Text("🔥 \(model.state.streak.current)일째")
                        .font(GT.semibold(12).monospacedDigit())
                        .foregroundStyle(GT.onFeltSecondary)
                }
            }
            Text(subtitleLine)
                .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
        }
        .padding(.top, 14)
    }

    private var subtitleLine: String {
        let n = model.dailySet().count
        return n == 0 ? "첫 단계부터 시작해요" : "\(n)문제 · 약 \(max(3, n * 90 / 60))분"
    }

    @ViewBuilder
    private var nextCard: some View {
        if let node = model.nextNode {
            Button { onOpenNode(node) } label: {
                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel(text: "다음 단계", onDark: false)
                    Text(node.title).font(GT.title(20)).foregroundStyle(GT.ink)
                        .padding(.top, 6)
                    Text(nodeBlurb(node)).font(GT.body(12))
                        .foregroundStyle(GT.inkSecondary)
                        .padding(.top, 3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("이어서 하기").font(GT.title(14)).foregroundStyle(GT.onCTA)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(GT.cta, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 14)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(GT.card, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(GTPress())
            .accessibilityLabel("다음 단계 \(node.title). \(nodeBlurb(node))")
        } else {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "길", onDark: false)
                Text("기초를 모두 끝냈어요").font(GT.title(17)).foregroundStyle(GT.ink)
                Text("복습으로 감각을 유지해요. 다음 단원은 준비 중이에요.")
                    .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(GT.card, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var reviewCard: some View {
        Button(action: onOpenReview) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("복습 \(due.count)개").font(GT.title(14)).foregroundStyle(GT.ink)
                    Text(due.prefix(3).map(conceptTitle).joined(separator: " · "))
                        .font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GT.green)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(GT.card, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(GTPress())
    }

    /// The hero stat, on the felt rather than in a card — it is a standing fact about
    /// the user, not an action (spec §7.1).
    @ViewBuilder
    private var calibrationPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            SectionLabel(text: "캘리브레이션")
            if let rate = model.calibrationHitRate, let verdict = model.calibrationVerdict {
                Text("90% 구간 적중률 \(Int((rate * 100).rounded()))%")
                    .font(GT.title(14)).foregroundStyle(GT.onFelt)
                Text(verdictLine(verdict))
                    .font(GT.body(11.5)).foregroundStyle(GT.onFeltSecondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GT.hairlineFelt).frame(height: 4)
                        Capsule().fill(GT.mint)
                            .frame(width: geo.size.width * rate, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.top, 2)
            } else {
                Text("추정 문제를 풀면 여기에 나와요")
                    .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
            }
        }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    private func verdictLine(_ v: Calibration.Verdict) -> String {
        switch v {
        case .overconfident:  return "구간을 좁게 잡고 있어요 — 아직 과신하고 있어요"
        case .underconfident: return "구간이 넓어요 — 조금 더 좁혀도 돼요"
        case .calibrated:     return "잘 맞고 있어요"
        }
    }

    /// Spec §4.6: past the stop-drilling threshold the app owes an explanation, not
    /// another rep.
    private var stuckPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "막힌 개념")
            ForEach(model.needingExplainer(), id: \.self) { c in
                Text("\(conceptTitle(c)) · 천천히 다시 보기")
                    .font(GT.semibold(12)).foregroundStyle(GT.onFelt)
            }
        }
        .padding(.top, 6)
    }
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
    case .mdf:         return "얼마나 자주 지켜야 하는지 계산해요"
    }
}
