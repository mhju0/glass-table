// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// Runs one node: a fixed number of spots, then a summary that reports the result
/// back to the progression model.
///
/// Spec §4.2 — first exposure is *blocked*: the same concept several times in a row,
/// which acquires faster. A boss interleaves its whole mix instead, which is what
/// makes it evidence of transfer rather than fluency.
struct NodeSessionView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let node: CurriculumNode

    @State private var index = 0
    @State private var missed = 0
    @State private var answered: [Concept] = []
    @State private var finished = false
    @State private var stage: Stage = .solo
    @State private var showHint = false

    /// Spec §5.1 — every new concept opens the same way: watch it worked, do it with
    /// the scaffolding, then do it alone. Grading starts at `.solo` and only there.
    enum Stage { case show, together, solo }

    /// Blocked first exposure is 5; a boss is 6 mixed items (spec §4.1).
    private var itemCount: Int { if case .boss = node.kind { return 6 } else { return 5 } }

    /// Seeded from the node id so a node's items are stable within a session but a
    /// *re-run* draws fresh spots — the generators make that free.
    private var baseSeed: UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in node.id.utf8 { hash ^= UInt64(byte); hash &*= 0x0000_0100_0000_01b3 }
        return hash &+ UInt64(model.record(for: conceptFor(0)).total)
    }

    /// A drill node repeats its own concept; a boss cycles its mix so consecutive
    /// items are deliberately different (interleaving is the point of the node).
    private func conceptFor(_ i: Int) -> Concept {
        switch node.kind {
        case let .drill(c): return c
        case let .boss(own, mixes):
            let pool = (own.map { [$0] } ?? []) + mixes
            return pool[i % pool.count]
        }
    }

    var body: some View {
        Group {
            if finished { summary }
            else if stage != .solo { teaching }
            else { current }
        }
        .background(FeltBackground())
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
        .onAppear {
            // First exposure to the concept this node teaches opens with the
            // walkthrough. A node the user has already met goes straight to drilling,
            // and 천천히 stays available from 기록 either way (spec §5.1).
            guard let taught = Curriculum.taughtConcept(of: node) else { return }
            var seen = model.record(for: taught).total > 0
            #if DEBUG
            // A GT_DEMO_NODE capture wants the *drill*; the sweep reaches the teaching
            // stages through GT_DEMO_BEAT instead. Without this every `drill-…` entry
            // for a concept the demo state has not studied silently screenshotted the
            // walkthrough under a drill's name — which is how drill-rfi, drill-notation
            // and drill-callfold went unlooked-at.
            let env = ProcessInfo.processInfo.environment
            if env["GT_DEMO_NODE"] != nil, env["GT_DEMO_BEAT"] == nil { seen = true }
            #endif
            stage = seen ? .solo : .show
        }
    }

    /// The concept this node introduces — what the teaching stages are about.
    private var taughtConcept: Concept { Curriculum.taughtConcept(of: node) ?? conceptFor(0) }

    @ViewBuilder
    private var teaching: some View {
        switch stage {
        case .show:
            // 보여주기: the app solves one out loud. The user answers nothing.
            let w = Walkthrough.make(concept: taughtConcept, seed: baseSeed, index: 0)
            WalkthroughView(title: conceptTitle(taughtConcept), beats: w.beats, rows: w.rows,
                            onFinish: { stage = .together }, onSkip: { stage = .solo })
        case .together:
            // 함께 풀기: a *different* spot, the user answers, and the full reasoning
            // is one tap away via 힌트 — which is never penalised because nothing here
            // is graded. Only .solo records anything (spec §5.1).
            ZStack(alignment: .bottomTrailing) {
                ConceptDrillView(concept: taughtConcept, seed: baseSeed, index: 1,
                                 progressText: "함께 풀기") { _ in
                    stage = .solo
                }
                hintButton
            }
        case .solo:
            EmptyView()
        }
    }

    private var hintButton: some View {
        Button { showHint = true } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill").font(.system(size: 11))
                Text("힌트").font(GT.semibold(12))
            }
            .foregroundStyle(GT.felt)
            .padding(.horizontal, 13).padding(.vertical, 9)
            .background(GT.mint, in: Capsule())
        }
        .buttonStyle(GTPress())
        // Sits clear of the answer sheet so it never covers a control.
        .padding(.trailing, 18).padding(.bottom, 250)
        .sheet(isPresented: $showHint) {
            let w = Walkthrough.make(concept: taughtConcept, seed: baseSeed, index: 1)
            NavigationStack {
                // Drops the concluding beat: the hint shows the reasoning, not the
                // answer the user is being asked for.
                WalkthroughView(title: conceptTitle(taughtConcept),
                                beats: Array(w.beats.dropLast()), rows: w.rows,
                                onFinish: { showHint = false }, onSkip: { showHint = false })
            }
        }
    }

    private var current: some View {
        // Indices 0 and 1 are reserved for 보여주기 and 함께 풀기, so the graded items
        // are never a spot the user has already been walked through.
        ConceptDrillView(concept: conceptFor(index),
                         seed: baseSeed, index: index + 2,
                         progressText: "\(index + 1)/\(itemCount)") { band in
            model.record(concept: conceptFor(index), band: band.band,
                         interval: band.interval, evLoss: band.evLoss)
            answered.append(conceptFor(index))
            if band.band != .spotOn { missed += 1 }
            if index + 1 >= itemCount {
                finished = true
                model.completeNode(node, cleanRun: missed == 0)
                model.endSession(answered: answered)
            } else {
                index += 1
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer(minLength: 20)
            Text(missed == 0 ? "완벽했어요" : "\(itemCount - missed)/\(itemCount) 맞았어요")
                .font(GT.title(24)).foregroundStyle(GT.onFelt)
            Text(missed == 0
                 ? "이 개념은 이제 능숙이에요."
                 : "틀린 개념은 복습 목록에 올라가요. 며칠 뒤에 다시 물어볼게요.")
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            FeltCTAButton(title: "길로 돌아가기") { dismiss() }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Unlimited practice on any single concept, no node and no grading pressure
/// (spec §7.1: no caps, ever).
///
/// Doubles as 오늘's 복습 flow: same player, the picker just narrowed to the due
/// concepts. Answers record through the same path either way, which is what clears
/// an item off the review queue.
struct FreePlayView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var title = "자유 연습"
    var blurb = "횟수 제한은 없어요. 아무거나 골라서 원하는 만큼 푸세요."
    var concepts = Concept.allCases
    @State private var concept: Concept?
    @State private var index = 0

    var body: some View {
        Group {
            if let concept {
                ConceptDrillView(concept: concept, seed: 0x5EED, index: index,
                                 progressText: title) { result in
                    model.record(concept: concept, band: result.band,
                                 interval: result.interval, evLoss: result.evLoss)
                    index += 1
                }
            } else {
                picker
            }
        }
        .background(FeltBackground())
        // Two different jobs, so two different arrows: at the picker the button leaves
        // free play altogether, inside a drill it only steps back to the picker.
        .gtChrome(.topBarLeading) {
            if concept == nil { ChromeButton.close { dismiss() } }
            else { ChromeButton.back("드릴 바꾸기") { concept = nil } }
        }
    }

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(GT.title(22)).foregroundStyle(GT.onFelt)
                    .padding(.bottom, 4)
                Text(blurb)
                    .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                    .padding(.bottom, 8)
                ForEach(concepts, id: \.self) { c in
                    Button { index = 0; concept = c } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conceptTitle(c)).font(GT.title(13.5))
                                    .foregroundStyle(GT.ink)
                                Text(conceptBlurb(c)).font(GT.body(11))
                                    .foregroundStyle(GT.inkMuted).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GT.inkMuted)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .gtCard(radius: 14)
                    }
                    .buttonStyle(GTPress())
                }
            }
            .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 28)
        }
    }
}
