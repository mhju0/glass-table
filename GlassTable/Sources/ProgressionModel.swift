// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Observation
import GlassTableEngine
import GlassTableDrills

/// The app's single window onto the progression core.
///
/// Everything with a rule in it — unlocking, mastery, scheduling, streaks,
/// calibration — lives in `GlassTableDrills` and is tested without a simulator. This
/// type only loads, forwards, and saves, so there is no second place where a rule
/// could quietly disagree with the tested one.
@Observable
final class ProgressionModel {
    private(set) var state = ProgressState()
    /// Set when the store exists but will not parse. The UI must offer recovery rather
    /// than silently starting the user over (spec §8.2).
    private(set) var unreadable: String?
    /// Failed ordinary saves keep the latest answers in memory for retry or export.
    private(set) var saveError: String?

    private let store: ProgressionStore
    private let scheduler = FSRSScheduler()

    var recoveryFileURL: URL? {
        guard unreadable != nil, FileManager.default.fileExists(atPath: store.url.path) else {
            return nil
        }
        return store.url
    }

    init(store: ProgressionStore? = nil) {
        let hasInjectedStore = store != nil
        let store = store ?? Self.launchStore()
        self.store = store
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if !hasInjectedStore,
           environment["GT_TEST_STORE_ID"].flatMap(UUID.init(uuidString:)) != nil,
           let nodeID = environment["GT_TEST_PATH_CURRENT_NODE"],
           let index = Curriculum.allNodes.firstIndex(where: { $0.id == nodeID }) {
            var fixture = ProgressState()
            fixture.firstLessonCompleted = true
            for node in Curriculum.allNodes[..<index] {
                fixture.nodes[node.id] = NodeRecord(cleared: true, clearedAt: Date(), attempts: 1)
            }
            state = fixture
            return
        }
        // GT_DEMO_SEED=1 — a representative mid-path state for screenshot runs.
        // Built through the real types rather than a hand-written JSON fixture, so it
        // can never encode a shape the store would reject.
        if ProcessInfo.processInfo.environment["GT_DEMO_SEED"] != nil {
            state = Self.demoState()
            return
        }
        #endif
        switch store.load() {
        case .fresh:
            // First launch on this build. Fold in any M1 per-drill progress, then
            // persist once so the next launch takes the .loaded path.
            state = LegacyMigration.migrate(from: store.url.deletingLastPathComponent(),
                                            into: ProgressState())
            save()
        case let .loaded(loaded):
            state = loaded
        case let .unreadable(reason):
            unreadable = reason
        }
    }

    private static func launchStore() -> ProgressionStore {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["GT_TEST_STORE_ID"],
           let id = UUID(uuidString: raw) {
            let standard = ProgressionStore.standard().url
            return ProgressionStore(url: standard.deletingLastPathComponent()
                .appendingPathComponent("progression-test-\(id.uuidString).json"))
        }
        #endif
        return .standard()
    }

    // MARK: - reads

    var nextNode: CurriculumNode? { Curriculum.nextNode(in: state) }

    func status(of node: CurriculumNode) -> NodeStatus {
        Curriculum.status(of: node.id, in: state)
    }

    func dueConcepts(now: Date = Date()) -> [Concept] {
        ReviewQueue.dueConcepts(in: state, at: now)
    }

    func reviewSessionConcepts(now: Date = Date()) -> [Concept] {
        ReviewQueue.sessionConcepts(in: state, at: now)
    }

    func needingExplainer() -> [Concept] { ReviewQueue.needingExplainer(in: state) }

    func record(for concept: Concept) -> ConceptRecord { state.record(for: concept) }

    /// Spec §4.3: the number the home screen leads with, never XP and never streak.
    var masteredCount: Int {
        Concept.allCases.filter { state.record(for: $0).tier >= .proficient }.count
    }

    var calibrationHitRate: Double? { Calibration.hitRate(in: state) }

    var calibrationVerdict: Calibration.Verdict? {
        calibrationHitRate.map { Calibration.verdict(hitRate: $0) }
    }

    /// A legacy or imported learner should land where they left off. Unknown concept
    /// and node keys count too because they can be valid history from another build.
    var shouldPresentFirstLesson: Bool {
        guard unreadable == nil else { return false }
        guard state.firstLessonCompleted != true else { return false }
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["GT_TEST_FIRST_LESSON"] == "1"
            || environment["GT_DEMO_FIRST_LESSON"] != nil { return true }
        if environment["GT_TEST_FIRST_LESSON"] == "0"
            || environment.keys.contains(where: { $0.hasPrefix("GT_DEMO_") }) {
            return false
        }
        #endif
        return !hasHistoricalActivity
    }

    private var hasHistoricalActivity: Bool {
        !state.concepts.isEmpty || !state.nodes.isEmpty || !state.answers.isEmpty
            || state.streak.current > 0 || state.streak.longest > 0
            || state.streak.lastSessionDay != nil
            || state.streak.lastFreezeEarnedDay != nil
    }

    /// Spec §4.6: three misses in a row means the explanation didn't land.
    func shouldOfferWalkthrough(_ concept: Concept) -> Bool {
        Mastery.shouldOfferWalkthrough(state.record(for: concept))
    }

    // MARK: - writes

    /// One graded answer: counts, miss streak, FSRS schedule, calibration log.
    func record(concept: Concept, band: GradeBand, interval: IntervalAnswer? = nil,
                evLoss: Double? = nil, now: Date = Date()) {
        guard unreadable == nil else { return }
        ReviewQueue.recordReview(&state, concept: concept, rating: .forBand(band),
                                 interval: interval, now: now, scheduler: scheduler,
                                 evLoss: evLoss)
        save()
    }

    /// Marks a fully answered node cleared, then evaluates each concept against only
    /// its own current-session evidence. Missing or extra evidence changes nothing.
    @discardableResult
    func completeNode(_ node: CurriculumNode, scheduled: [Concept],
                      evidence: [Concept: SessionEvidence], now: Date = Date()) -> Bool {
        guard unreadable == nil, Curriculum.isValidSession(scheduled, for: node),
              SessionEvidence.validates(evidence, scheduled: scheduled)
        else { return false }
        var record = state.nodes[node.id] ?? NodeRecord()
        record.attempts += 1
        record.cleared = true
        if record.clearedAt == nil { record.clearedAt = now }
        state.nodes[node.id] = record

        let viaBoss: Bool
        if case .boss = node.kind { viaBoss = true } else { viaBoss = false }
        for concept in Set(scheduled) {
            guard let conceptEvidence = evidence[concept] else { continue }
            state.updateRecord(for: concept) {
                Mastery.promote(&$0, evidence: conceptEvidence, viaBoss: viaBoss, now: now)
            }
        }
        save()
        return true
    }

    /// A finished walkthrough releases the stuck-state guard without fabricating a
    /// graded attempt, review schedule, streak credit, or mastery evidence.
    func completeWalkthrough(concept: Concept) {
        guard unreadable == nil else { return }
        Mastery.completeWalkthrough(&state, concept: concept)
        save()
    }

    /// The introduction is practice, not assessment. Completing or skipping it writes
    /// only this marker: no answer, streak, review date, node, or mastery changes.
    func completeFirstLesson() {
        guard unreadable == nil else { return }
        state.firstLessonCompleted = true
        save()
    }

    // MARK: - recovery (spec §8.2)

    func exportData() throws -> Data {
        if unreadable != nil { return try store.exportData() }
        return try store.exportData(state)
    }

    func importData(_ data: Data) throws {
        try replace(with: store.importData(data))
    }

    func importPrepared(_ prepared: PreparedProgressImport) throws {
        try replace(with: prepared.state)
    }

    /// Explicit "start over": replacement must preserve the old bytes and save
    /// successfully before either the displayed state or recovery screen changes.
    func resetProgress() throws { try replace(with: ProgressState()) }

    private func replace(with replacement: ProgressState) throws {
        try store.replace(with: replacement)
        state = replacement
        unreadable = nil
        saveError = nil
    }

    func retrySave() { save() }

    private func save() {
        guard unreadable == nil else { return }
        do {
            try store.save(state)
            saveError = nil
        } catch {
            saveError = String(describing: error)
        }
    }

    #if DEBUG
    /// Mid-path demo state: unit 1 cleared, unit 2 started, two concepts due for
    /// review, one stuck, and enough interval answers for a calibration readout.
    static func demoState() -> ProgressState {
        var s = ProgressState()
        let now = Date()

        func study(_ c: Concept, correct: Int, total: Int, tier: MasteryTier,
                   dueInDays: Double, misses: Int = 0) {
            let due = now.addingTimeInterval(86400 * dueInDays)
            // Due concepts still need a legal review chronology. The old fixed
            // `now - 2 days` value landed after the demo's three-days-overdue date,
            // so every answer save from a seeded screenshot state was rejected.
            let lastReview = min(now.addingTimeInterval(-86400 * 2),
                                 due.addingTimeInterval(-86400))
            s.updateRecord(for: c) {
                $0.correct = correct; $0.total = total; $0.tier = tier
                $0.consecutiveMisses = misses
                $0.proficientAt = tier >= .proficient ? now.addingTimeInterval(-86400 * 3) : nil
                $0.masteredAt = tier == .mastered ? now.addingTimeInterval(-86400 * 2) : nil
                $0.review = ReviewState(stability: 6, difficulty: 5,
                                        lastReview: lastReview, due: due,
                                        reps: 3)
            }
        }
        study(.showdown, correct: 18, total: 20, tier: .mastered, dueInDays: 6)
        study(.potMath, correct: 14, total: 16, tier: .proficient, dueInDays: 1)
        study(.position, correct: 11, total: 15, tier: .familiar, dueInDays: -1)
        study(.combos, correct: 9, total: 14, tier: .familiar, dueInDays: -2)
        // 8 misses, not 3: past shouldStopDrilling, so the sweep photographs 오늘's
        // 막힌 개념 panel too — at 3 the "stuck" state only ever reached 기록's row.
        study(.potOdds, correct: 4, total: 12, tier: .attempted, dueInDays: -3, misses: 8)
        study(.equitySense, correct: 6, total: 9, tier: .familiar, dueInDays: 2)

        for id in ["u1-showdown", "u1-potMath", "u1-position", "u1-combos", "u1-boss",
                   "u2-potOdds"] {
            s.nodes[id] = NodeRecord(cleared: true, clearedAt: now, attempts: 1)
        }

        // Deliberately overconfident: tight intervals that mostly miss, which is the
        // state the calibration copy is written for.
        let truths: [(Double, Double, Double)] = [
            (40, 5, 52), (30, 4, 31), (55, 6, 70), (25, 5, 26),
            (60, 5, 44), (35, 4, 36), (20, 3, 38), (48, 5, 62),
            (33, 4, 33), (44, 5, 58), (28, 4, 29), (52, 5, 66),
        ]
        for (i, t) in truths.enumerated() {
            let iv = IntervalAnswer(point: t.0, lo: t.0 - t.1, hi: t.0 + t.1, truth: t.2)
            s.append(AnswerRecord(concept: .equitySense,
                                  at: now.addingTimeInterval(-Double(i) * 3600),
                                  correct: iv.containsTruth, interval: iv))
        }

        // A spread of EV-graded answers, so 기록's 결정 card has something to average.
        // Mixed on purpose: two clean choices, a leak, and one real blunder.
        for (i, loss) in [0.0, 0.0, 0.3, 1.4, 0.0, 2.9].enumerated() {
            s.append(AnswerRecord(concept: .evLoss,
                                  at: now.addingTimeInterval(-Double(i) * 1800),
                                  correct: loss <= 0.5, evLoss: loss))
        }

        s.streak = StreakRecord(current: 12, longest: 12, lastSessionDay: DayKey(now),
                                freezesRemaining: 2, lastFreezeEarnedDay: DayKey(now))
        return s
    }
    #endif
}
