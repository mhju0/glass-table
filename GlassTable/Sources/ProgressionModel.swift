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
                now: Date = Date()) {
        ReviewQueue.recordReview(&state, concept: concept, rating: .forBand(band),
                                 interval: interval, now: now, scheduler: scheduler)
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
}
