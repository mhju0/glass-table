// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// First run (spec §6). Not a separate system — it is Unit 1's first three nodes
/// played **in their normal path order**, plus a diagnostic. That ordering is why it
/// cannot contradict the linear unlock rule in §4.1.
///
/// Deliberately absent: any difficulty selector (the category's most common
/// complaint), the notification prompt, and any explanation of streaks.
struct FirstRunView: View {
    @Environment(ProgressionModel.self) private var model
    let onFinish: () -> Void

    /// −1 is the welcome screen; 0..<steps.count are the scripted nodes;
    /// steps.count is the diagnostic; anything beyond is the handoff.
    @State private var step = -1
    @State private var itemInStep = 0
    @State private var diagnosticCorrect = 0
    @State private var answered: [Concept] = []

    /// 쇼다운 ×3 → 팟 계산 ×1 (carrying the thesis line) → 포지션 (full walkthrough)
    /// → 진단 ×8 mixed.
    private struct Step {
        let concept: Concept
        let items: Int
        let teach: Bool
        let framing: String?
    }
    private let steps: [Step] = [
        Step(concept: .showdown, items: 3, teach: false, framing: nil),
        Step(concept: .potMath, items: 1, teach: false,
             framing: "숫자는 답을 정한 뒤에 보여줘요. 그게 이 앱의 전부예요."),
        Step(concept: .position, items: 1, teach: true, framing: nil),
    ]
    private let diagnosticItems = 8
    private let seed: UInt64 = 0x6C17_5EED

    private var isDiagnostic: Bool { step >= steps.count }

    var body: some View {
        Group {
            if step < 0 { welcome }
            else if isDiagnostic, step > steps.count { handoff }
            else if isDiagnostic { diagnostic }
            else { scripted }
        }
        .background(FeltBackground())
    }

    // MARK: - beats

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("Glass Table")
                .font(.system(size: 34, weight: .heavy, design: .serif).italic())
                .foregroundStyle(GT.onFelt)
            Text("레인지와 EV로 생각하는 홀덤 훈련")
                .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
            Text("먼저 몇 문제만 같이 풀어볼게요. 6분이면 돼요.")
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .padding(.top, 6)
            Spacer()
            Button { step = 0 } label: {
                Text("시작하기").font(GT.title(15)).foregroundStyle(GT.felt)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .gtCard(radius: 14)
            }
            .buttonStyle(GTPress())
            Button("건너뛰기", action: finish)
                .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(22)
    }

    @ViewBuilder
    private var scripted: some View {
        let s = steps[step]
        VStack(spacing: 0) {
            if let framing = s.framing, itemInStep == 0 {
                Text(framing)
                    .font(GT.title(14)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18).padding(.vertical, 12)
            }
            if s.teach {
                let w = Walkthrough.make(concept: s.concept, seed: seed, index: 0)
                WalkthroughView(title: conceptTitle(s.concept), beats: w.beats, rows: w.rows,
                                onFinish: advanceStep, onSkip: advanceStep)
            } else {
                ConceptDrillView(concept: s.concept, seed: seed, index: itemInStep,
                                 progressText: "\(itemInStep + 1)/\(s.items)") { outcome in
                    record(s.concept, outcome)
                    if itemInStep + 1 >= s.items { advanceStep() } else { itemInStep += 1 }
                }
            }
        }
    }

    /// Spec §6: 8 mixed items across what was just covered. Sets the starting band and
    /// may pre-clear nodes the user demonstrably doesn't need.
    private var diagnostic: some View {
        let concept = steps[itemInStep % steps.count].concept
        return VStack(spacing: 0) {
            Text("진단 · 어디서 시작할지 정할게요")
                .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18).padding(.top, 6)
            ConceptDrillView(concept: concept, seed: seed &+ 99, index: itemInStep,
                             progressText: "\(itemInStep + 1)/\(diagnosticItems)") { outcome in
                record(concept, outcome)
                if outcome.band == .spotOn { diagnosticCorrect += 1 }
                if itemInStep + 1 >= diagnosticItems {
                    applyDiagnostic()
                    step += 1
                } else {
                    itemInStep += 1
                }
            }
        }
    }

    private var handoff: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            Text("여기서 시작해요").font(GT.title(26)).foregroundStyle(GT.onFelt)
            Text(handoffLine)
                .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: finish) {
                Text("길 열기").font(GT.title(15)).foregroundStyle(GT.felt)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .gtCard(radius: 14)
            }
            .buttonStyle(GTPress())
        }
        .padding(22)
    }

    private var handoffLine: String {
        let cleared = Curriculum.allNodes.filter { model.status(of: $0) == .cleared }.count
        return cleared > 0
            ? "\(diagnosticCorrect)/\(diagnosticItems) 맞혔어요. 이미 아는 \(cleared)단계는 완료로 표시했어요."
            : "\(diagnosticCorrect)/\(diagnosticItems) 맞혔어요. 처음부터 차근차근 가볼게요."
    }

    // MARK: - plumbing

    private func record(_ concept: Concept, _ outcome: DrillOutcome) {
        model.record(concept: concept, band: outcome.band, interval: outcome.interval)
        answered.append(concept)
    }

    private func advanceStep() {
        itemInStep = 0
        step += 1
    }

    /// Pre-clearing is the *only* way a node is skipped (spec §4.1/§6): a concept the
    /// user answered cleanly here is marked done so the path doesn't open at zero.
    private func applyDiagnostic() {
        for s in steps {
            let r = model.record(for: s.concept)
            guard r.total >= 3, r.accuracy >= 0.8 else { continue }
            guard let node = Curriculum.allNodes.first(where: {
                Curriculum.taughtConcept(of: $0) == s.concept
            }) else { continue }
            model.completeNode(node, cleanRun: r.accuracy == 1.0)
        }
        model.endSession(answered: answered)
    }

    private func finish() {
        model.endSession(answered: answered)
        onFinish()
    }
}
