// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
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

    private let store: ProgressionStore
    private let scheduler = FSRSScheduler()
    /// Bumped whenever generated content changes, so the daily set reshuffles instead
    /// of replaying a stale puzzle.
    static let contentVersion = 1

    init(store: ProgressionStore = .standard()) {
        self.store = store
        #if DEBUG
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
            try? store.save(state)
        case let .loaded(loaded):
            state = loaded
        case let .unreadable(reason):
            unreadable = reason
        }
    }

    // MARK: - reads

    var nextNode: CurriculumNode? { Curriculum.nextNode(in: state) }

    func status(of node: CurriculumNode) -> NodeStatus {
        Curriculum.status(of: node.id, in: state)
    }

    func dueConcepts(now: Date = Date()) -> [Concept] {
        ReviewQueue.dueConcepts(in: state, at: now, scheduler: scheduler)
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

    /// Spec §4.6: three misses in a row means the explanation didn't land.
    func shouldOfferWalkthrough(_ concept: Concept) -> Bool {
        Mastery.shouldOfferWalkthrough(state.record(for: concept))
    }

    // MARK: - writes

    /// One graded answer: counts, miss streak, FSRS schedule, calibration log.
    func record(concept: Concept, band: GradeBand, interval: IntervalAnswer? = nil,
                evLoss: Double? = nil, now: Date = Date()) {
        ReviewQueue.recordReview(&state, concept: concept, rating: .forBand(band),
                                 interval: interval, now: now, scheduler: scheduler,
                                 evLoss: evLoss)
        save()
    }

    /// Marks a node cleared and promotes every concept it exercised. `cleanRun` is
    /// what separates 익숙 from 능숙; `viaBoss` is the only route to 숙달.
    func completeNode(_ node: CurriculumNode, cleanRun: Bool, now: Date = Date()) {
        var record = state.nodes[node.id] ?? NodeRecord()
        record.attempts += 1
        record.cleared = true
        if record.clearedAt == nil { record.clearedAt = now }
        state.nodes[node.id] = record

        let viaBoss: Bool
        if case .boss = node.kind { viaBoss = true } else { viaBoss = false }
        for concept in Curriculum.concepts(of: node) {
            state.updateRecord(for: concept) {
                Mastery.promote(&$0, cleanRun: cleanRun, viaBoss: viaBoss, now: now)
            }
        }
        save()
    }

    /// Spec §7.1: a streak day needs a session that included a due item, so the
    /// streak can't be farmed on already-mastered material.
    func endSession(answered: [Concept], now: Date = Date()) {
        guard ReviewQueue.sessionQualifiesForStreak(answered: answered, in: state,
                                                    at: now, scheduler: scheduler)
        else { return }
        Streak.recordSession(&state.streak, on: DayKey(now))
        save()
    }

    /// Today's practice set, seeded so it is the same for everyone on a given day.
    func dailySet(size: Int = 5, now: Date = Date()) -> [Concept] {
        ReviewQueue.dailySet(in: state, at: now, scheduler: scheduler, size: size)
    }

    // MARK: - recovery (spec §8.2)

    func exportData() throws -> Data { try store.exportData() }

    func importData(_ data: Data) throws {
        state = try store.importData(data)
        try store.save(state)
        unreadable = nil
    }

    /// Explicit "start over": the unreadable file is moved aside, never deleted.
    func discardUnreadableStore() {
        try? store.quarantineCorruptFile()
        state = ProgressState()
        unreadable = nil
        save()
    }

    private func save() { try? store.save(state) }

    #if DEBUG
    /// Mid-path demo state: unit 1 cleared, unit 2 started, two concepts due for
    /// review, one stuck, and enough interval answers for a calibration readout.
    static func demoState() -> ProgressState {
        var s = ProgressState()
        let now = Date()
        let scheduler = FSRSScheduler()

        func study(_ c: Concept, correct: Int, total: Int, tier: MasteryTier,
                   dueInDays: Double, misses: Int = 0) {
            s.updateRecord(for: c) {
                $0.correct = correct; $0.total = total; $0.tier = tier
                $0.consecutiveMisses = misses
                $0.proficientAt = tier >= .proficient ? now.addingTimeInterval(-86400 * 3) : nil
                $0.masteredAt = tier == .mastered ? now.addingTimeInterval(-86400 * 2) : nil
                $0.review = ReviewState(stability: 6, difficulty: 5,
                                        lastReview: now.addingTimeInterval(-86400 * 2),
                                        due: now.addingTimeInterval(86400 * dueInDays),
                                        reps: 3)
            }
        }
        study(.showdown, correct: 18, total: 20, tier: .mastered, dueInDays: 6)
        study(.potMath, correct: 14, total: 16, tier: .proficient, dueInDays: 1)
        study(.position, correct: 11, total: 15, tier: .familiar, dueInDays: -1)
        study(.combos, correct: 9, total: 14, tier: .familiar, dueInDays: -2)
        study(.potOdds, correct: 4, total: 12, tier: .attempted, dueInDays: -3, misses: 3)
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
        _ = scheduler
        return s
    }
    #endif
}
