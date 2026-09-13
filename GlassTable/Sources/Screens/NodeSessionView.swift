// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct SessionAttemptID: Hashable {
    let concept: Concept
    let seed: UInt64
    let index: Int
}

struct SessionAttemptLedger {
    private(set) var committed: Set<SessionAttemptID> = []
    private(set) var advanced: Set<SessionAttemptID> = []

    mutating func commit(_ id: SessionAttemptID) -> Bool {
        committed.insert(id).inserted
    }

    mutating func advance(_ id: SessionAttemptID) -> Bool {
        guard committed.contains(id) else { return false }
        return advanced.insert(id).inserted
    }
}

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
    @State private var evidence: [Concept: SessionEvidence] = [:]
    @State private var finished = false
    @State private var stage: Stage = .solo
    @State private var showHint = false
    @State private var sessionSeed: UInt64?
    @State private var sessionConcepts: [Concept] = []
    @State private var attemptLedger = SessionAttemptLedger()

    /// Spec §5.1 — every new concept opens the same way: watch it worked, do it with
    /// the scaffolding, then do it alone. Grading starts at `.solo` and only there.
    enum Stage { case show, together, solo }

    private var itemCount: Int { sessionConcepts.count }

    /// Seeded from the node id so a node's items are stable within a session but a
    /// *re-run* draws fresh spots — the generators make that free.
    private static func baseSeed(nodeID: String, progress: Int) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in nodeID.utf8 { hash ^= UInt64(byte); hash &*= 0x0000_0100_0000_01b3 }
        return hash &+ UInt64(progress)
    }

    private var baseSeed: UInt64 { sessionSeed ?? 0 }

    var body: some View {
        Group {
            if sessionConcepts.isEmpty { ProgressView().tint(GT.onFelt) }
            else if finished { summary }
            else if stage != .solo { teaching }
            else { current }
        }
        .background(FeltBackground())
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
        .onAppear {
            guard sessionSeed == nil else { return }
            let first = Curriculum.concepts(of: node)[0]
            let seed = Self.baseSeed(nodeID: node.id, progress: model.record(for: first).total)
            sessionSeed = seed
            sessionConcepts = Curriculum.sessionConcepts(for: node, seed: seed)
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
            #if DEBUG
            if env["GT_DEMO_STAGE"] == "together" { stage = .together }
            if env["GT_DEMO_SESSION_COMPLETE"] != nil {
                for (concept, items) in Dictionary(grouping: sessionConcepts, by: { $0 }) {
                    evidence[concept] = SessionEvidence(attempted: items.count, spotOn: items.count)
                }
                finished = true
            }
            #endif
        }
    }

    /// The concept this node introduces — what the teaching stages are about.
    private var taughtConcept: Concept {
        Curriculum.taughtConcept(of: node) ?? Curriculum.concepts(of: node)[0]
    }

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
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    hintButton
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                ConceptDrillView(concept: taughtConcept, seed: baseSeed, index: 1,
                                 progressText: "함께 풀기") { _ in
                    stage = .solo
                }
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
        .sheet(isPresented: $showHint) {
            NavigationStack {
                GuidedHintView(concept: taughtConcept) { showHint = false }
            }
        }
    }

    private var current: some View {
        // Indices 0 and 1 are reserved for 보여주기 and 함께 풀기, so the graded items
        // are never a spot the user has already been walked through.
        let concept = sessionConcepts[index]
        let spotIndex = index + 2
        let attemptID = SessionAttemptID(concept: concept, seed: baseSeed, index: spotIndex)
        return ConceptDrillView(concept: concept, seed: baseSeed, index: spotIndex,
                         progressText: "\(index + 1)/\(itemCount)", onCommit: { outcome in
            guard attemptLedger.commit(attemptID) else { return }
            model.record(concept: concept, band: outcome.band,
                         interval: outcome.interval, evLoss: outcome.evLoss)
            evidence[concept, default: SessionEvidence()]
                .record(spotOn: outcome.band == .spotOn)
            if outcome.band != .spotOn { missed += 1 }
        }, onAnswer: { _ in
            guard attemptLedger.advance(attemptID) else { return }
            if index + 1 >= itemCount {
                finished = true
                model.completeNode(node, scheduled: sessionConcepts, evidence: evidence)
            } else {
                index += 1
            }
        })
    }

    private var summary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(missed == 0 ? "모두 정확했어요" : "\(itemCount - missed)/\(itemCount) 정확했어요")
                    .font(GT.title(24)).foregroundStyle(GT.onFelt)
                Text(summaryDetail)
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                FeltCTAButton(title: "길로 돌아가기") { dismiss() }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var summaryDetail: String {
        let missedConcepts = evidence.compactMap { concept, result in
            result.isPerfect ? nil : conceptTitle(concept)
        }.sorted()
        if missedConcepts.isEmpty {
            return "모든 문제를 정확히 풀었어요. 기록에서 개념별 단계와 다음 복습 시점을 확인할 수 있어요."
        }
        return "다시 볼 개념: \(missedConcepts.joined(separator: " · ")). 복습에서 한 문제씩 다시 만나요."
    }
}

private struct GuidedHintView: View {
    @Environment(\.dismiss) private var dismiss
    let concept: Concept
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("풀이 순서").font(GT.title(22)).foregroundStyle(GT.onFelt)
            Text(cue).font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            FeltCTAButton(title: "문제로 돌아가기") {
                onClose()
                dismiss()
            }
        }
        .padding(20)
        .background(FeltBackground())
    }

    private var cue: String {
        switch concept {
        case .showdown: return "먼저 각 플레이어의 가장 높은 5장 조합을 만든 뒤, 족보가 같으면 높은 카드부터 비교해 보세요."
        case .potMath: return "행동마다 들어온 칩과 시작 팟을 따로 적은 뒤, 마지막에 모두 더해 보세요."
        case .position: return "버튼을 기준으로 시계 방향 좌석을 짚고, 이번 스트리트에서 먼저 행동하는 쪽을 확인하세요."
        case .combos: return "두 장 조합의 전체 개수에서 보이는 카드와 겹치는 조합을 하나씩 빼세요."
        case .potOdds: return "콜 금액을 콜 뒤의 전체 팟으로 나누고 백분율로 바꿔 보세요."
        case .outs: return "알려진 상대 핸드를 이기는 카드만 후보로 잡고, 이미 보인 카드와 중복 후보를 제외하세요."
        case .equitySense: return "공개된 상대 핸드와 내 핸드를 비교하고, 남은 카드에서 이기거나 비기는 경우를 가늠하세요."
        case .evCall: return "이길 때 얻는 금액과 질 때 잃는 콜 금액을 확률로 가중해 더하세요."
        case .callFold: return "필요 에퀴티를 먼저 구한 뒤 내 에퀴티와 같은 단위로 비교하세요."
        case .rangeNotation: return "페어, 수딧, 오프수딧을 먼저 구분하고 플러스와 구간 표기가 넓히는 방향을 확인하세요."
        case .rfi: return "현재 포지션의 차트에서 핸드 칸을 찾고, 경계 안팎만 확인하세요."
        case .rangeRead: return "가능한 시작 레인지에서 지금까지의 행동과 보드 카드가 배제하는 조합을 순서대로 빼세요."
        case .hitFrequency: return "보드와 직접 연결된 메이드 핸드, 드로, 미스를 나눠 각 버킷의 비중을 비교하세요."
        case .rangeAdvantage: return "양쪽 시작 레인지가 이 보드에서 만드는 강한 조합의 밀도와 넛 조합을 비교하세요."
        case .evLoss: return "각 선택의 EV를 같은 기준으로 놓고, 가장 높은 EV와 선택한 EV의 차이를 구하세요."
        case .actionRead: return "행동 전 레인지에서 이 사이즈를 택할 법한 조합이 무엇인지 먼저 좁혀 보세요."
        case .defend: return "포지션과 오픈 위치를 확인한 뒤 디펜드 차트에서 해당 핸드의 칸을 찾으세요."
        case .mdf: return "단일 베팅 가정에서 1 - 베팅/(기존 팟 + 베팅)으로 전체 방어 빈도를 구하세요. 이 값만으로 개별 핸드의 콜이나 레이즈를 정하지는 않아요."
        }
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
    /// Shown in place of the roster when `concepts` runs dry — the 복습 flow ends by
    /// emptying its own list, which must read as finishing, not as a broken screen.
    var emptyText: String?
    @State private var concept: Concept?
    @State private var index = 0
    /// Progress-salted at pick time, the same fresh-spots rule as a node re-run
    /// (§4.2): a fixed seed replayed the identical question sequence every visit.
    @State private var seed: UInt64 = 0x5EED
    @State private var attemptLedger = SessionAttemptLedger()

    var body: some View {
        Group {
            if let concept {
                let attemptID = SessionAttemptID(concept: concept, seed: seed, index: index)
                ConceptDrillView(concept: concept, seed: seed, index: index,
                                 progressText: title, onCommit: { result in
                    guard attemptLedger.commit(attemptID) else { return }
                    model.record(concept: concept, band: result.band,
                                 interval: result.interval, evLoss: result.evLoss)
                }, onAnswer: { _ in
                    guard attemptLedger.advance(attemptID) else { return }
                    index += 1
                })
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
                Text(concepts.isEmpty ? (emptyText ?? blurb) : blurb)
                    .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)
                ForEach(concepts, id: \.self) { c in
                    Button {
                        index = 0
                        seed = 0x5EED &+ UInt64(model.record(for: c).total)
                        concept = c
                    } label: {
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

/// A fixed due-review snapshot. Each concept appears once, every committed answer is
/// persisted immediately, and the session ends after at most five questions.
struct ReviewSessionView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var queue: [Concept] = []
    @State private var index = 0
    @State private var outcomes: [Concept: GradeBand] = [:]
    @State private var seed: UInt64 = 0
    @State private var initialized = false
    @State private var finished = false
    @State private var attemptLedger = SessionAttemptLedger()

    var body: some View {
        Group {
            if !initialized {
                ProgressView().tint(GT.onFelt)
            } else if finished || queue.isEmpty {
                summary
            } else {
                let concept = queue[index]
                let spotIndex = index
                let attemptID = SessionAttemptID(concept: concept, seed: seed, index: spotIndex)
                ConceptDrillView(concept: concept, seed: seed, index: spotIndex,
                                 progressText: "복습 \(index + 1)/\(queue.count)",
                                 onCommit: { outcome in
                    guard attemptLedger.commit(attemptID) else { return }
                    model.record(concept: concept, band: outcome.band,
                                 interval: outcome.interval, evLoss: outcome.evLoss)
                    outcomes[concept] = outcome.band
                }, onAnswer: { _ in
                    guard attemptLedger.advance(attemptID) else { return }
                    if index + 1 == queue.count { finished = true }
                    else { index += 1 }
                })
            }
        }
        .background(FeltBackground())
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
        .onAppear {
            guard !initialized else { return }
            queue = model.reviewSessionConcepts()
            seed = reviewSeed(queue)
            initialized = true
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_REVIEW_COMPLETE"] != nil {
                for concept in queue { outcomes[concept] = .spotOn }
                finished = true
            }
            #endif
        }
    }

    private var summary: some View {
        let exact = outcomes.values.filter { $0 == .spotOn }.count
        let missed = queue.filter { outcomes[$0] != .spotOn }.map(conceptTitle)
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(queue.isEmpty ? "오늘 복습은 끝났어요" : "\(exact)/\(queue.count) 정확했어요")
                    .font(GT.title(24)).foregroundStyle(GT.onFelt)
                Text(queue.isEmpty
                     ? "지금 복습할 개념이 없어요."
                     : missed.isEmpty
                        ? "각 개념을 한 번씩 정확히 떠올렸어요. 다음 복습 시점은 기록에서 확인할 수 있어요."
                        : "다시 볼 개념: \(missed.joined(separator: " · ")). 오늘 답은 저장됐고, 일정에 따라 다시 만나요.")
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                FeltCTAButton(title: "오늘로 돌아가기") { dismiss() }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func reviewSeed(_ concepts: [Concept]) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for concept in concepts {
            for byte in concept.rawValue.utf8 {
                hash ^= UInt64(byte)
                hash &*= 0x0000_0100_0000_01b3
            }
            hash &+= UInt64(model.record(for: concept).total)
        }
        return hash
    }
}
