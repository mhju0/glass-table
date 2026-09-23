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

enum NodeSessionSeed {
    static func make(nodeID: String, conceptTotals: [Int]) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in nodeID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01b3
        }
        let aggregate = conceptTotals.reduce(into: UInt64.zero) {
            $0 &+= UInt64($1)
        }
        return hash &+ aggregate
    }
}

private struct PendingDraftWrite: Equatable {
    let sessionID: String
    let ordinal: Int
    let input: SavedDrillDraftInput
    let epoch: UUID
    let guided: Bool
    init(sessionID: String, ordinal: Int, input: SavedDrillDraftInput,
         epoch: UUID, guided: Bool = false) {
        self.sessionID = sessionID; self.ordinal = ordinal
        self.input = input; self.epoch = epoch; self.guided = guided
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
    @Environment(\.learningLanguage) private var language
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var sessionEpoch: UUID?
    @State private var timing = QuestionTiming()
    @State private var createdSessionID: String?
    @State private var pendingDraftTask: Task<Void, Never>?
    @State private var pendingDraft: PendingDraftWrite?

    private var questionReadyAt: TimeInterval? {
        get { timing.startedAt }
        nonmutating set {
            if let value = newValue, let key = timing.eligibleKey {
                timing.ready(key, uptime: value)
            } else { timing.clearClock() }
        }
    }
    private var eligibleQuestionKey: String? {
        get { timing.eligibleKey }
        nonmutating set {
            if let key = newValue { timing.beginNewQuestion(key) }
            else { timing.interrupt() }
        }
    }

    /// Spec §5.1 — every new concept opens the same way: watch it worked, do it with
    /// the scaffolding, then do it alone. Grading starts at `.solo` and only there.
    enum Stage { case show, together, solo }

    private var itemCount: Int { sessionConcepts.count }

    /// Seeded from the node id so a node's items are stable within a session but a
    /// *re-run* draws fresh spots — the generators make that free.
    private var baseSeed: UInt64 { sessionSeed ?? 0 }
    private var savedSession: NodeSessionSnapshot? {
        guard let session = model.state.activeNodeSession,
              session.nodeID == node.id else { return nil }
        return session
    }

    var body: some View {
        Group {
            if sessionConcepts.isEmpty {
                if model.state.activeNodeSession != nil { occupiedSession }
                else { ProgressView().tint(GT.onFelt) }
            }
            else if finished { summary }
            else if stage != .solo { teaching }
            else { current }
        }
        .background(FeltBackground())
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
        .gtChrome(.topBarTrailing) {
            if stage == .together { hintButton }
        }
        .onAppear {
            if sessionEpoch == nil { sessionEpoch = model.epoch }
            guard sessionSeed == nil else { return }
            if let savedSession {
                restore(savedSession)
                return
            }
            let totals = Curriculum.concepts(of: node).map { model.record(for: $0).total }
            let seed = NodeSessionSeed.make(nodeID: node.id, conceptTotals: totals)
            guard model.beginNodeSession(node, seed: seed,
                                         expectedEpoch: sessionEpoch ?? model.epoch),
                  let savedSession else { return }
            createdSessionID = savedSession.id
            if savedSession.phase == .question {
                eligibleQuestionKey = "\(savedSession.id):\(savedSession.ordinal)"
            }
            restore(savedSession)
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
            if seen && savedSession.phase == .show {
                _ = model.advanceNodeTeaching(sessionID: savedSession.id,
                    skip: true, expectedEpoch: sessionEpoch ?? model.epoch)
                if let savedSession = self.savedSession { restore(savedSession) }
            }
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
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                questionReadyAt = nil
                eligibleQuestionKey = nil
                pendingDraftTask?.cancel()
                if let write = pendingDraft {
                    if write.guided {
                        _ = model.saveNodeGuidedDraft(sessionID: write.sessionID,
                            input: write.input, expectedEpoch: write.epoch)
                    } else {
                        _ = model.saveNodeDraft(sessionID: write.sessionID,
                            ordinal: write.ordinal, input: write.input,
                            expectedEpoch: write.epoch)
                    }
                    pendingDraft = nil
                }
            }
        }
        .onChange(of: language) { _, _ in
            questionReadyAt = nil
            eligibleQuestionKey = nil
        }
        .onDisappear {
            questionReadyAt = nil
            eligibleQuestionKey = nil
            pendingDraftTask?.cancel()
            if let write = pendingDraft {
                if write.guided {
                    _ = model.saveNodeGuidedDraft(sessionID: write.sessionID,
                        input: write.input, expectedEpoch: write.epoch)
                } else {
                    _ = model.saveNodeDraft(sessionID: write.sessionID,
                        ordinal: write.ordinal, input: write.input, expectedEpoch: write.epoch)
                }
            }
            pendingDraft = nil
        }
    }

    private var occupiedSession: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(language.text("진행 중인 레슨이 있어요", "You have a lesson in progress"))
                .font(GT.title(22)).foregroundStyle(GT.onFelt)
            Text(language.text("지금까지 푼 답은 저장돼요. 이 레슨을 시작하면 이전 레슨의 남은 문제는 다시 시작해요.",
                               "Your answers are saved. Starting this lesson restarts the unfinished part of the other lesson."))
                .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
            FeltCTAButton(title: language.text("이 레슨 시작", "Start this lesson")) {
                guard model.abandonNodeSession(expectedEpoch: sessionEpoch ?? model.epoch) else { return }
                let totals = Curriculum.concepts(of: node).map { model.record(for: $0).total }
                let seed = NodeSessionSeed.make(nodeID: node.id, conceptTotals: totals)
                guard model.beginNodeSession(node, seed: seed,
                                             expectedEpoch: sessionEpoch ?? model.epoch),
                      let savedSession else { return }
                createdSessionID = savedSession.id
                if savedSession.phase == .question {
                    eligibleQuestionKey = "\(savedSession.id):\(savedSession.ordinal)"
                }
                restore(savedSession)
            }
        }
        .padding(20)
    }

    private func restore(_ session: NodeSessionSnapshot) {
        sessionSeed = session.seed
        sessionConcepts = session.scheduledConcepts.compactMap(Concept.init(rawValue:))
        index = session.ordinal
        evidence = [:]
        for item in session.answers {
            guard let concept = Concept(rawValue: item.concept) else { continue }
            evidence[concept, default: SessionEvidence()].record(
                spotOn: item.answer.band == GradeBand.spotOn.rawValue)
        }
        missed = session.answers.filter { $0.answer.band != GradeBand.spotOn.rawValue }.count
        finished = session.phase == .finished
        switch session.phase {
        case .show: stage = .show
        case .together: stage = .together
        case .question, .reveal, .finished: stage = .solo
        }
        questionReadyAt = nil
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
            let w = Walkthrough.make(concept: taughtConcept, seed: baseSeed, index: 0,
                                     language: language)
            WalkthroughView(title: ConceptIntroduction.make(taughtConcept,
                                language: language).title,
                            beats: w.beats, rows: w.rows,
                            initialIndex: savedSession?.showBeatIndex ?? 0,
                            onStep: { next in
                                guard let savedSession else { return false }
                                return model.setNodeShowBeat(sessionID: savedSession.id,
                                    index: next, expectedEpoch: sessionEpoch ?? model.epoch)
                            },
                            onFinish: { advanceTeaching(skip: false) },
                            onSkip: { advanceTeaching(skip: true) })
        case .together:
            // 함께 풀기: a *different* spot, the user answers, and the full reasoning
            // is one tap away via 힌트 — which is never penalised because nothing here
            // is graded. Only .solo records anything (spec §5.1).
            ConceptDrillView(concept: taughtConcept, seed: baseSeed, index: 1,
                             progressText: language.text("함께 풀기", "Try together"),
                             restoredAnswer: savedSession?.guidedAnswer,
                             initialDraft: savedSession?.guidedDraft?.input,
                             onDraft: { input in
                guard let savedSession else { return }
                pendingDraftTask?.cancel()
                let write = PendingDraftWrite(sessionID: savedSession.id, ordinal: 0,
                    input: input, epoch: sessionEpoch ?? model.epoch, guided: true)
                pendingDraft = write
                pendingDraftTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    guard !Task.isCancelled, pendingDraft == write else { return }
                    _ = model.saveNodeGuidedDraft(sessionID: write.sessionID,
                        input: write.input, expectedEpoch: write.epoch)
                    pendingDraft = nil
                }
            }, onCommit: { outcome in
                guard let savedSession, let input = outcome.submittedInput,
                      let inputData = try? JSONEncoder().encode(input),
                      let revealData = try? JSONEncoder().encode(DrillStoredReveal(outcome))
                else { return false }
                let committed = model.commitNodeGuidedAnswer(sessionID: savedSession.id,
                    band: outcome.band, input: inputData, reveal: revealData,
                    expectedEpoch: sessionEpoch ?? model.epoch)
                if committed { pendingDraftTask?.cancel(); pendingDraft = nil }
                return committed
            }) { _ in
                advanceTeaching(skip: false)
            }
        case .solo:
            EmptyView()
        }
    }

    private func advanceTeaching(skip: Bool) {
        guard let savedSession,
              model.advanceNodeTeaching(sessionID: savedSession.id, skip: skip,
                  expectedEpoch: sessionEpoch ?? model.epoch),
              let updated = self.savedSession else { return }
        if updated.phase == .question, createdSessionID == updated.id {
            eligibleQuestionKey = "\(updated.id):\(updated.ordinal)"
        }
        restore(updated)
    }

    private var hintButton: some View {
        Button { showHint = true } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill").font(.system(size: 11))
                Text(language.text("힌트", "Hint")).font(GT.semibold(12))
            }
            .foregroundStyle(GT.onCTA)
            .padding(.horizontal, 13).padding(.vertical, 9)
            .frame(minHeight: 44)
            .background(GT.cta, in: Capsule())
        }
        .buttonStyle(GTPress())
        .popover(isPresented: $showHint, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            GuidedHintView(concept: taughtConcept) { showHint = false }
                .presentationCompactAdaptation(.popover)
        }
    }

    private var current: some View {
        // Indices 0 and 1 are reserved for 보여주기 and 함께 풀기, so the graded items
        // are never a spot the user has already been walked through.
        let concept = sessionConcepts[index]
        let spotIndex = index + 2
        let restoredAnswer = savedSession?.phase == .reveal
            ? savedSession?.answers.last?.answer : nil
        return ConceptDrillView(concept: concept, seed: baseSeed, index: spotIndex,
                         progressText: "\(index + 1)/\(itemCount)",
                         restoredAnswer: restoredAnswer,
                         initialDraft: savedSession?.draft?.input,
                         onDraft: { input in
            guard let savedSession else { return }
            pendingDraftTask?.cancel()
            let write = PendingDraftWrite(sessionID: savedSession.id, ordinal: index,
                input: input, epoch: sessionEpoch ?? model.epoch)
            pendingDraft = write
            pendingDraftTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled, pendingDraft == write else { return }
                _ = model.saveNodeDraft(sessionID: write.sessionID, ordinal: write.ordinal,
                    input: write.input, expectedEpoch: write.epoch)
                pendingDraft = nil
            }
        }, onQuestionReady: {
            if questionReadyAt == nil,
               eligibleQuestionKey == "\(savedSession?.id ?? ""):\(index)",
               savedSession?.phase == .question, savedSession?.ordinal == index,
               scenePhase == .active {
                questionReadyAt = ProcessInfo.processInfo.systemUptime
            }
        }, onCommit: { outcome in
            guard let savedSession, let input = outcome.submittedInput,
                  let inputData = try? JSONEncoder().encode(input),
                  let revealData = try? JSONEncoder().encode(DrillStoredReveal(outcome))
            else { return false }
            let committed = model.commitNodeAnswer(sessionID: savedSession.id,
                attemptID: "node:\(savedSession.id):\(index)", ordinal: index,
                band: outcome.band, input: inputData, reveal: revealData,
                language: language,
                eligibleSeconds: timing.elapsed(for: "\(savedSession.id):\(index)",
                    at: ProcessInfo.processInfo.systemUptime),
                interval: outcome.interval, evLoss: outcome.evLoss,
                expectedEpoch: sessionEpoch ?? model.epoch)
            if committed {
                pendingDraftTask?.cancel()
                pendingDraft = nil
                if let updated = self.savedSession { restore(updated) }
            }
            return committed
        }, onAnswer: { _ in
            guard let savedSession,
                  model.nextNodeQuestion(sessionID: savedSession.id, afterOrdinal: index,
                      expectedEpoch: sessionEpoch ?? model.epoch),
                  let updated = self.savedSession else { return }
            if updated.phase == .question {
                eligibleQuestionKey = "\(updated.id):\(updated.ordinal)"
            }
            restore(updated)
        })
        .task(id: "\(savedSession?.id ?? ""):\(index):\(savedSession?.phase.rawValue ?? "")") {
            guard questionReadyAt == nil else { return }
            await Task.yield()
            if concept != .rangeAdvantage,
               eligibleQuestionKey == "\(savedSession?.id ?? ""):\(index)",
               savedSession?.phase == .question, savedSession?.ordinal == index,
               scenePhase == .active { questionReadyAt = ProcessInfo.processInfo.systemUptime }
        }
    }

    private var summary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(missed == 0
                     ? language.text("모두 목표 안에 들었어요", "All answers were on target")
                     : language.text("\(itemCount - missed)/\(itemCount) 목표 안에 들었어요",
                                     "\(itemCount - missed)/\(itemCount) on target"))
                    .font(GT.title(24)).foregroundStyle(GT.onFelt)
                Text(summaryDetail)
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                FeltCTAButton(title: language.text("길로 돌아가기", "Back to path")) {
                    if let savedSession {
                        _ = model.dismissFinishedNodeSession(sessionID: savedSession.id,
                            expectedEpoch: sessionEpoch ?? model.epoch)
                    }
                    dismiss()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var summaryDetail: String {
        let missedConcepts = evidence.compactMap { concept, result in
            result.isPerfect ? nil : ConceptIntroduction.make(concept, language: language).title
        }.sorted()
        if missedConcepts.isEmpty {
            return language.text(
                "모든 답이 목표 안에 들었어요. 기록에서 개념별 단계와 다음 복습 시점을 볼 수 있어요.",
                "Every answer was on target. See your skill levels and next reviews in Progress.")
        }
        return language.text(
            "다시 볼 개념: \(missedConcepts.joined(separator: " · ")). 복습에서 한 문제씩 다시 만나요.",
            "Review these skills: \(missedConcepts.joined(separator: " · ")). You will see them again in review.")
    }
}

private struct GuidedHintView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    let concept: Concept
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    Text(language.text("풀이 순서", "How to work it out"))
                        .font(GT.title(GT.Typography.resultSize))
                        .foregroundStyle(GT.onFelt)
                    Spacer(minLength: 12)
                    Button {
                        onClose()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GT.onFelt)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(GTPress())
                    .accessibilityLabel(language.text("힌트 닫기", "Close hint"))
                }
                Text(cue)
                    .font(GT.body(GT.Typography.explanationSize))
                    .foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                FeltCTAButton(title: language.text("문제로 돌아가기", "Back to question")) {
                    onClose()
                    dismiss()
                }
            }
            .padding(20)
        }
        .frame(idealWidth: 330, idealHeight: 280)
        .background(FeltBackground())
    }

    private var cue: String {
        switch concept {
        case .showdown: return language.text(
            "가장 높은 5장 조합을 만들고, 같으면 높은 카드부터 비교해 보세요.",
            "Make each player's best five-card hand. If tied, compare the highest cards first.")
        case .potMath: return language.text(
            "시작 팟과 각 행동에서 들어온 칩을 한 번씩 더해 보세요.",
            "Start with the pot, then add each contribution once.")
        case .position: return language.text(
            "버튼에서 시계 방향으로 좌석을 세고, 누가 먼저 행동하는지 확인하세요.",
            "Count seats clockwise from the dealer button, then check who acts first.")
        case .combos: return language.text(
            "두 장 조합에서 이미 보인 카드가 들어간 조합을 빼세요.",
            "Count two-card pairs, then remove pairs containing a visible card.")
        case .potOdds: return language.text(
            "콜 금액을 콜 뒤 전체 팟으로 나눠 보세요.",
            "Divide the call amount by the full pot after your call.")
        case .outs: return language.text(
            "상대 패를 이기게 하는 카드만 세고, 이미 보인 카드는 빼세요.",
            "Count cards that beat the shown opponent hand, excluding visible cards.")
        case .equitySense: return language.text(
            "남은 카드에서 이기거나 비기는 경우가 얼마나 될지 가늠하세요.",
            "Estimate how often the remaining cards let you win or tie.")
        case .evCall: return language.text(
            "이길 때 얻는 돈과 질 때 내는 돈을 각각 확률만큼 반영하세요.",
            "Weight the money won and the call lost by their chances.")
        case .callFold: return language.text(
            "콜에 필요한 승률을 내 승률과 비교하세요.",
            "Compare the win chance your call needs with your own win chance.")
        case .rangeNotation: return language.text(
            "같은 숫자, 같은 무늬, 다른 무늬를 먼저 구분해 보세요.",
            "First separate pairs, same-suit hands, and different-suit hands.")
        case .rfi: return language.text(
            "내 자리의 표에서 손패 칸이 열기 범위에 있는지 보세요.",
            "Find your hand on the chart for your seat and see whether it is in range.")
        case .rangeRead: return language.text(
            "시작 손패에서 지금까지의 행동과 보드에 맞지 않는 조합을 빼세요.",
            "Start with possible hands, then remove ones that do not fit the action or board.")
        case .hitFrequency: return language.text(
            "맞은 손패, 드로, 놓친 손패로 나눠 비중을 보세요.",
            "Separate made hands, draws, and misses, then compare their shares.")
        case .rangeAdvantage: return language.text(
            "두 사람의 시작 손패가 이 보드에서 얼마나 강해지는지 비교하세요.",
            "Compare how often each player's starting hands become strong on this board.")
        case .evLoss: return language.text(
            "두 선택의 예상 가치를 비교하고, 더 좋은 선택과의 차이를 보세요.",
            "Compare the two choices' expected value, then find the gap from the better one.")
        case .actionRead: return language.text(
            "이 크기로 베팅할 법한 손패가 무엇인지 좁혀 보세요.",
            "Narrow down which hands would likely choose this bet size.")
        case .defend: return language.text(
            "내 자리와 상대가 처음 올린 자리를 확인하고 표에서 손패를 찾으세요.",
            "Check both seats, then find your hand on the defend chart.")
        case .mdf: return language.text(
            "1 − 베팅/(기존 팟 + 베팅)으로 전체 방어 비율을 구하세요. 한 손패의 콜 여부는 따로 판단해요.",
            "Use 1 − bet/(pot + bet) for the overall defend share. One hand's call is a separate decision.")
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
    @Environment(\.learningLanguage) private var language
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var sessionEpoch: UUID?
    @State private var introStage: NodeSessionView.Stage?
    @State private var timing = QuestionTiming()
    @State private var createdRoundID: String?
    @State private var pendingDraftTask: Task<Void, Never>?
    @State private var pendingDraft: PendingDraftWrite?

    private var questionReadyAt: TimeInterval? {
        get { timing.startedAt }
        nonmutating set {
            if let value = newValue, let key = timing.eligibleKey {
                timing.ready(key, uptime: value)
            } else { timing.clearClock() }
        }
    }
    private var eligibleQuestionKey: String? {
        get { timing.eligibleKey }
        nonmutating set {
            if let key = newValue { timing.beginNewQuestion(key) }
            else { timing.interrupt() }
        }
    }

    private var activeRound: PracticeRound? { model.state.activeRound }

    var body: some View {
        Group {
            if let concept, let introStage {
                intro(for: concept, stage: introStage)
            } else if let concept, let round = activeRound,
               round.concept == concept.rawValue {
                if round.phase == .finished {
                    roundSummary(round)
                } else {
                    let restored = round.phase == .reveal ? round.answers.last : nil
                    ConceptDrillView(concept: concept, seed: round.seed,
                                     index: round.ordinal + 2,
                                     progressText: "\(round.ordinal + 1)/\(round.questionCount)",
                                     restoredAnswer: restored,
                                     initialDraft: round.draft?.input,
                                     onDraft: { input in
                        pendingDraftTask?.cancel()
                        let write = PendingDraftWrite(sessionID: round.id,
                            ordinal: round.ordinal, input: input,
                            epoch: sessionEpoch ?? model.epoch)
                        pendingDraft = write
                        pendingDraftTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(200))
                            guard !Task.isCancelled, pendingDraft == write else { return }
                            _ = model.saveRoundDraft(roundID: write.sessionID,
                                ordinal: write.ordinal, input: write.input,
                                expectedEpoch: write.epoch)
                            pendingDraft = nil
                        }
                    }, onQuestionReady: {
                        if questionReadyAt == nil,
                           eligibleQuestionKey == "\(round.id):\(round.ordinal)",
                           activeRound?.id == round.id,
                           activeRound?.ordinal == round.ordinal,
                           activeRound?.phase == .question, introStage == nil,
                           scenePhase == .active {
                            questionReadyAt = ProcessInfo.processInfo.systemUptime
                        }
                    }, onCommit: { result in
                        guard let input = result.submittedInput,
                              let inputData = try? JSONEncoder().encode(input),
                              let revealData = try? JSONEncoder().encode(DrillStoredReveal(result))
                        else { return false }
                        let committed = model.commitRoundAnswer(roundID: round.id,
                            attemptID: "round:\(round.id):\(round.ordinal)",
                            ordinal: round.ordinal, band: result.band,
                            language: language.rawValue, assisted: false,
                            input: inputData, reveal: revealData,
                            eligibleSeconds: timing.elapsed(
                                for: "\(round.id):\(round.ordinal)",
                                at: ProcessInfo.processInfo.systemUptime),
                            interval: result.interval, evLoss: result.evLoss,
                            expectedEpoch: sessionEpoch ?? model.epoch)
                        if committed {
                            pendingDraftTask?.cancel()
                            pendingDraft = nil
                        }
                        return committed
                    }, onAnswer: { _ in
                        guard model.nextRoundQuestion(roundID: round.id,
                            afterOrdinal: round.ordinal,
                            expectedEpoch: sessionEpoch ?? model.epoch) else { return }
                        if let updated = activeRound, updated.phase == .question {
                            eligibleQuestionKey = "\(updated.id):\(updated.ordinal)"
                        }
                    })
                    .task(id: "\(round.id):\(round.ordinal):\(round.phase.rawValue):\(introStage == nil)") {
                        guard questionReadyAt == nil else { return }
                        await Task.yield()
                        if concept != .rangeAdvantage,
                           eligibleQuestionKey == "\(round.id):\(round.ordinal)",
                           activeRound?.id == round.id, activeRound?.ordinal == round.ordinal,
                           activeRound?.phase == .question, introStage == nil,
                           scenePhase == .active {
                            questionReadyAt = ProcessInfo.processInfo.systemUptime
                        }
                    }
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
            else { ChromeButton.back(language.text("드릴 바꾸기", "Change skill")) {
                concept = nil
            } }
        }
        .onAppear {
            if sessionEpoch == nil { sessionEpoch = model.epoch }
            if let round = activeRound,
               let activeConcept = Concept(rawValue: round.concept) {
                concept = activeConcept
                seed = round.seed
                prepareIntro(for: activeConcept)
            }
        }
        .onChange(of: activeRound?.ordinal) { _, _ in
            questionReadyAt = nil
        }
        .onChange(of: activeRound?.phase) { _, _ in
            questionReadyAt = nil
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                questionReadyAt = nil
                eligibleQuestionKey = nil
                pendingDraftTask?.cancel()
                if let write = pendingDraft {
                    if write.guided {
                        _ = model.saveRoundGuidedDraft(roundID: write.sessionID,
                            input: write.input, expectedEpoch: write.epoch)
                    } else {
                        _ = model.saveRoundDraft(roundID: write.sessionID,
                            ordinal: write.ordinal, input: write.input,
                            expectedEpoch: write.epoch)
                    }
                    pendingDraft = nil
                }
            }
        }
        .onChange(of: language) { _, _ in
            questionReadyAt = nil
            eligibleQuestionKey = nil
        }
        .onDisappear {
            questionReadyAt = nil
            eligibleQuestionKey = nil
            pendingDraftTask?.cancel()
            if let write = pendingDraft {
                if write.guided {
                    _ = model.saveRoundGuidedDraft(roundID: write.sessionID,
                        input: write.input, expectedEpoch: write.epoch)
                } else {
                    _ = model.saveRoundDraft(roundID: write.sessionID,
                        ordinal: write.ordinal, input: write.input,
                        expectedEpoch: write.epoch)
                }
            }
            pendingDraft = nil
        }
    }

    @ViewBuilder
    private func intro(for concept: Concept, stage: NodeSessionView.Stage) -> some View {
        let introduction = ConceptIntroduction.make(concept, language: language)
        switch stage {
        case .show:
            let worked = Walkthrough.make(concept: concept, seed: seed, index: 0,
                                          language: language)
            VStack(alignment: .leading, spacing: 10) {
                Text(introduction.title).font(GT.title(22)).foregroundStyle(GT.onFelt)
                Text(introduction.why).font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                Text(introduction.how).font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                WalkthroughView(title: introduction.title, beats: worked.beats,
                                rows: worked.rows,
                                initialIndex: activeRound?.showBeatIndex ?? 0,
                                onStep: { next in
                                    guard let round = activeRound else { return false }
                                    return model.setRoundShowBeat(roundID: round.id,
                                        index: next, expectedEpoch: sessionEpoch ?? model.epoch)
                                },
                                onFinish: {
                                    guard let round = activeRound,
                                          model.advanceRoundIntroduction(roundID: round.id,
                                              skip: false,
                                              expectedEpoch: sessionEpoch ?? model.epoch)
                                    else { return }
                                    introStage = .together
                                },
                                onSkip: { finishIntro(concept) })
            }
            .padding(16)
        case .together:
            ConceptDrillView(concept: concept, seed: seed, index: 1,
                progressText: language.text("함께 연습", "Try together"),
                restoredAnswer: activeRound?.guidedAnswer,
                initialDraft: activeRound?.guidedDraft?.input,
                onDraft: { input in
                    guard let round = activeRound else { return }
                    pendingDraftTask?.cancel()
                    let write = PendingDraftWrite(sessionID: round.id, ordinal: 0,
                        input: input, epoch: sessionEpoch ?? model.epoch, guided: true)
                    pendingDraft = write
                    pendingDraftTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        guard !Task.isCancelled, pendingDraft == write else { return }
                        _ = model.saveRoundGuidedDraft(roundID: write.sessionID,
                            input: write.input, expectedEpoch: write.epoch)
                        pendingDraft = nil
                    }
                }, onCommit: { outcome in
                    guard let round = activeRound, let input = outcome.submittedInput,
                          let inputData = try? JSONEncoder().encode(input),
                          let revealData = try? JSONEncoder().encode(DrillStoredReveal(outcome))
                    else { return false }
                    let committed = model.commitRoundGuidedAnswer(roundID: round.id,
                        band: outcome.band, input: inputData, reveal: revealData,
                        expectedEpoch: sessionEpoch ?? model.epoch)
                    if committed { pendingDraftTask?.cancel(); pendingDraft = nil }
                    return committed
                }) { _ in
                finishIntro(concept)
            }
        case .solo:
            EmptyView()
        }
    }

    private func prepareIntro(for concept: Concept) {
        guard activeRound?.concept == concept.rawValue else { introStage = nil; return }
        switch activeRound?.introPhase {
        case .show: introStage = .show
        case .together: introStage = .together
        case nil: introStage = nil
        }
    }

    private func finishIntro(_ concept: Concept) {
        guard let round = activeRound, round.concept == concept.rawValue,
              model.advanceRoundIntroduction(roundID: round.id, skip: true,
                  expectedEpoch: sessionEpoch ?? model.epoch) else { return }
        introStage = nil
        questionReadyAt = nil
        if createdRoundID == round.id {
            eligibleQuestionKey = "\(round.id):\(round.ordinal)"
        }
    }

    private func roundSummary(_ round: PracticeRound) -> some View {
        let exact = round.answers.filter { $0.band == GradeBand.spotOn.rawValue }.count
        let near = round.answers.filter { $0.band == GradeBand.close.rawValue }.count
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(language.text("5문제를 마쳤어요", "Five questions complete"))
                    .font(GT.title(24)).foregroundStyle(GT.onFelt)
                Text(language.text("목표 안 \(exact) · 근접 \(near) · 다시 보기 \(round.answers.count - exact - near)",
                                   "On target \(exact) · Close \(near) · Revisit \(round.answers.count - exact - near)"))
                    .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                FeltCTAButton(title: language.text("다섯 문제 더", "Another five")) {
                    guard model.dismissFinishedRound(roundID: round.id,
                          expectedEpoch: sessionEpoch ?? model.epoch),
                          let concept = Concept(rawValue: round.concept) else { return }
                    _ = model.beginRound(concept: concept,
                        seed: 0x5EED &+ UInt64(model.record(for: concept).total),
                        expectedEpoch: sessionEpoch ?? model.epoch)
                    if let newRound = activeRound {
                        createdRoundID = newRound.id
                        if newRound.introPhase == nil {
                            eligibleQuestionKey = "\(newRound.id):\(newRound.ordinal)"
                        }
                    }
                    seed = model.state.activeRound?.seed ?? seed
                }
                Button(language.text("다른 개념 고르기", "Choose another skill")) {
                    guard model.dismissFinishedRound(roundID: round.id,
                        expectedEpoch: sessionEpoch ?? model.epoch) else { return }
                    concept = nil
                }
                .frame(minHeight: 44)
                .foregroundStyle(GT.onFelt)
            }
            .padding(20)
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
                if let activeRound,
                   let activeConcept = Concept(rawValue: activeRound.concept) {
                    Button {
                        concept = activeConcept
                    } label: {
                        Text(language.text("이어 풀기 · \(conceptTitle(activeConcept))",
                                           "Resume · \(ConceptIntroduction.make(activeConcept, language: language).title)"))
                            .font(GT.semibold(16))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(GTPress())
                    .gtCard(radius: 14)
                }
                ForEach(concepts, id: \.self) { c in
                    Button {
                        if let activeRound, activeRound.concept != c.rawValue {
                            guard model.abandonRound(roundID: activeRound.id,
                                expectedEpoch: sessionEpoch ?? model.epoch) else { return }
                        }
                        if model.state.activeRound == nil {
                            guard model.beginRound(concept: c,
                                seed: 0x5EED &+ UInt64(model.record(for: c).total),
                                expectedEpoch: sessionEpoch ?? model.epoch) else { return }
                            if let newRound = activeRound {
                                createdRoundID = newRound.id
                                if newRound.introPhase == nil {
                                    eligibleQuestionKey = "\(newRound.id):\(newRound.ordinal)"
                                }
                            }
                        }
                        concept = c
                        seed = model.state.activeRound?.seed ?? seed
                        prepareIntro(for: c)
                        questionReadyAt = nil
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
    @Environment(\.learningLanguage) private var language
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var queue: [Concept] = []
    @State private var index = 0
    @State private var outcomes: [Concept: GradeBand] = [:]
    @State private var seed: UInt64 = 0
    @State private var initialized = false
    @State private var finished = false
    @State private var attemptLedger = SessionAttemptLedger()
    @State private var sessionEpoch: UUID?
    @State private var timing = QuestionTiming()
    @State private var pendingDraftTask: Task<Void, Never>?
    @State private var pendingDraft: PendingDraftWrite?

    private var questionReadyAt: TimeInterval? {
        get { timing.startedAt }
        nonmutating set {
            if let value = newValue, let key = timing.eligibleKey {
                timing.ready(key, uptime: value)
            } else { timing.clearClock() }
        }
    }
    private var eligibleQuestionKey: String? {
        get { timing.eligibleKey }
        nonmutating set {
            if let key = newValue { timing.beginNewQuestion(key) }
            else { timing.interrupt() }
        }
    }

    private var savedSession: ReviewSessionSnapshot? { model.state.activeReviewSession }

    var body: some View {
        Group {
            if !initialized {
                ProgressView().tint(GT.onFelt)
            } else if finished || queue.isEmpty {
                summary
            } else if let session = savedSession {
                let concept = queue[index]
                let spotIndex = index + 2
                let restored = session.phase == .reveal ? session.answers.last?.answer : nil
                ConceptDrillView(concept: concept, seed: session.seed, index: spotIndex,
                                 progressText: language.text("복습 \(index + 1)/\(queue.count)",
                                                             "Review \(index + 1)/\(queue.count)"),
                                 restoredAnswer: restored,
                                 initialDraft: session.draft?.input,
                                 onDraft: { input in
                    pendingDraftTask?.cancel()
                    let write = PendingDraftWrite(sessionID: session.id, ordinal: index,
                        input: input, epoch: sessionEpoch ?? model.epoch)
                    pendingDraft = write
                    pendingDraftTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        guard !Task.isCancelled, pendingDraft == write else { return }
                        _ = model.saveReviewDraft(sessionID: write.sessionID,
                            ordinal: write.ordinal, input: write.input,
                            expectedEpoch: write.epoch)
                        pendingDraft = nil
                    }
                }, onQuestionReady: {
                    if questionReadyAt == nil,
                       eligibleQuestionKey == "\(session.id):\(session.ordinal)",
                       savedSession?.id == session.id,
                       savedSession?.ordinal == session.ordinal,
                       savedSession?.phase == .question, scenePhase == .active {
                        questionReadyAt = ProcessInfo.processInfo.systemUptime
                    }
                },
                                 onCommit: { outcome in
                    guard let input = outcome.submittedInput,
                          let inputData = try? JSONEncoder().encode(input),
                          let revealData = try? JSONEncoder().encode(DrillStoredReveal(outcome))
                    else { return false }
                    let committed = model.commitReviewAnswer(sessionID: session.id,
                        attemptID: "review:\(session.id):\(index)", ordinal: index,
                        band: outcome.band, input: inputData, reveal: revealData,
                        language: language, interval: outcome.interval, evLoss: outcome.evLoss,
                        eligibleSeconds: timing.elapsed(
                            for: "\(session.id):\(session.ordinal)",
                            at: ProcessInfo.processInfo.systemUptime),
                        expectedEpoch: sessionEpoch ?? model.epoch)
                    if committed {
                        pendingDraftTask?.cancel()
                        pendingDraft = nil
                        if let updated = savedSession { restore(updated) }
                    }
                    return committed
                }, onAnswer: { _ in
                    guard model.nextReviewQuestion(sessionID: session.id,
                        afterOrdinal: index, expectedEpoch: sessionEpoch ?? model.epoch),
                        let updated = savedSession else { return }
                    if updated.phase == .question {
                        eligibleQuestionKey = "\(updated.id):\(updated.ordinal)"
                    }
                    restore(updated)
                })
                .task(id: "\(session.id):\(session.ordinal):\(session.phase.rawValue)") {
                    guard questionReadyAt == nil else { return }
                    await Task.yield()
                    if concept != .rangeAdvantage,
                       eligibleQuestionKey == "\(session.id):\(session.ordinal)",
                       savedSession?.id == session.id,
                       savedSession?.ordinal == session.ordinal,
                       savedSession?.phase == .question,
                       scenePhase == .active {
                        questionReadyAt = ProcessInfo.processInfo.systemUptime
                    }
                }
            } else {
                ProgressView().tint(GT.onFelt)
            }
        }
        .background(FeltBackground())
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
        .onAppear {
            if sessionEpoch == nil { sessionEpoch = model.epoch }
            guard !initialized else { return }
            if let savedSession { restore(savedSession) }
            else {
                queue = model.reviewSessionConcepts()
                if !queue.isEmpty {
                    seed = reviewSeed(queue)
                    if model.beginReviewSession(seed: seed,
                        expectedEpoch: sessionEpoch ?? model.epoch), let savedSession {
                        eligibleQuestionKey = "\(savedSession.id):\(savedSession.ordinal)"
                        restore(savedSession)
                    }
                }
            }
            initialized = true
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_REVIEW_COMPLETE"] != nil {
                for concept in queue { outcomes[concept] = .spotOn }
                finished = true
            }
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                questionReadyAt = nil
                eligibleQuestionKey = nil
                pendingDraftTask?.cancel()
                if let write = pendingDraft {
                    _ = model.saveReviewDraft(sessionID: write.sessionID, ordinal: write.ordinal,
                        input: write.input, expectedEpoch: write.epoch)
                    pendingDraft = nil
                }
            }
        }
        .onChange(of: language) { _, _ in
            questionReadyAt = nil
            eligibleQuestionKey = nil
        }
        .onDisappear {
            questionReadyAt = nil
            eligibleQuestionKey = nil
            pendingDraftTask?.cancel()
            if let write = pendingDraft {
                _ = model.saveReviewDraft(sessionID: write.sessionID, ordinal: write.ordinal,
                    input: write.input, expectedEpoch: write.epoch)
            }
            pendingDraft = nil
        }
    }

    private func restore(_ session: ReviewSessionSnapshot) {
        queue = session.scheduledConcepts.compactMap(Concept.init(rawValue:))
        seed = session.seed
        index = session.ordinal
        outcomes = Dictionary(uniqueKeysWithValues: session.answers.compactMap { graded in
            guard let concept = Concept(rawValue: graded.concept),
                  let band = GradeBand(rawValue: graded.answer.band) else { return nil }
            return (concept, band)
        })
        finished = session.phase == .finished
        questionReadyAt = nil
    }

    private var summary: some View {
        let exact = outcomes.values.filter { $0 == .spotOn }.count
        let missed = queue.filter { outcomes[$0] != .spotOn }
            .map { ConceptIntroduction.make($0, language: language).title }
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(queue.isEmpty
                     ? language.text("지금 복습할 문제가 없어요", "No reviews due now")
                     : language.text("\(exact)/\(queue.count) 목표 안에 들었어요",
                                     "\(exact)/\(queue.count) on target"))
                    .font(GT.title(24)).foregroundStyle(GT.onFelt)
                Text(queue.isEmpty
                     ? language.text("지금 복습할 개념이 없어요.", "No skills are due right now.")
                     : missed.isEmpty
                        ? language.text(
                            "각 개념을 한 번씩 목표 안에 답했어요. 다음 복습은 기록에서 볼 수 있어요.",
                            "You answered each skill on target. Check Progress for the next review.")
                        : language.text(
                            "다시 볼 개념: \(missed.joined(separator: " · ")). 오늘 답은 저장됐어요.",
                            "Review these skills: \(missed.joined(separator: " · ")). Today's answers are saved."))
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                FeltCTAButton(title: language.text("학습으로 돌아가기", "Back to Learn")) {
                    if let savedSession, savedSession.phase == .finished {
                        guard model.dismissFinishedReviewSession(sessionID: savedSession.id,
                            expectedEpoch: sessionEpoch ?? model.epoch) else { return }
                    }
                    dismiss()
                }
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
