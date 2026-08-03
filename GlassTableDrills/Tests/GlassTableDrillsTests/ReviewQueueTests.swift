import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class ReviewQueueTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_785_000_000)
    private let sched = FSRSScheduler()
    private func days(_ n: Double) -> Date { t0.addingTimeInterval(n * 86400) }

    /// A state where `concepts` have been studied and are due at the given offsets.
    private func state(due: [(Concept, Double)]) -> ProgressState {
        var s = ProgressState()
        for (c, offset) in due {
            s.updateRecord(for: c) {
                $0.tier = .familiar
                $0.total = 5; $0.correct = 4
                $0.review = ReviewState(stability: 5, difficulty: 5,
                                        lastReview: self.t0, due: self.days(offset), reps: 2)
            }
        }
        return s
    }

    func testOnlyStudiedConceptsPastTheirDueDateAreReturned() {
        let s = state(due: [(.outs, -1), (.potOdds, 3), (.combos, -5)])
        let due = ReviewQueue.dueConcepts(in: s, at: t0, scheduler: sched)
        XCTAssertEqual(Set(due), [.outs, .combos])
    }

    /// An untouched concept is not "due" — it has never been taught, so surfacing it
    /// in review would be teaching by ambush.
    func testUntouchedConceptsAreNotDue() {
        let due = ReviewQueue.dueConcepts(in: ProgressState(), at: t0, scheduler: sched)
        XCTAssertTrue(due.isEmpty)
    }

    func testMostOverdueComesFirst() {
        let s = state(due: [(.outs, -1), (.combos, -10), (.potOdds, -4)])
        XCTAssertEqual(ReviewQueue.dueConcepts(in: s, at: t0, scheduler: sched),
                       [.combos, .potOdds, .outs])
    }

    /// Spec §4.6: a concept past the stop-drilling threshold must leave the queue —
    /// it needs an explainer, not another rep.
    func testConceptsPastTheStopDrillingThresholdAreWithheld() {
        var s = state(due: [(.outs, -1), (.combos, -2)])
        s.updateRecord(for: .outs) { $0.consecutiveMisses = 8 }
        XCTAssertEqual(ReviewQueue.dueConcepts(in: s, at: t0, scheduler: sched), [.combos])
        XCTAssertEqual(ReviewQueue.needingExplainer(in: s), [.outs])
    }

    func testRecordingAReviewAdvancesTheScheduleAndClearsTheDueState() {
        var s = state(due: [(.outs, -1)])
        XCTAssertFalse(ReviewQueue.dueConcepts(in: s, at: t0, scheduler: sched).isEmpty)
        ReviewQueue.recordReview(&s, concept: .outs, rating: .good,
                                 interval: nil, now: t0, scheduler: sched)
        XCTAssertTrue(ReviewQueue.dueConcepts(in: s, at: t0, scheduler: sched).isEmpty)
        XCTAssertEqual(s.record(for: .outs).total, 6)
        XCTAssertEqual(s.record(for: .outs).review.reps, 3)
        XCTAssertEqual(s.answers.count, 1)
    }

    func testAFailedReviewCountsAMissAndComesBackSooner() {
        var passed = state(due: [(.outs, -1)])
        var failed = passed
        ReviewQueue.recordReview(&passed, concept: .outs, rating: .good,
                                 interval: nil, now: t0, scheduler: sched)
        ReviewQueue.recordReview(&failed, concept: .outs, rating: .again,
                                 interval: nil, now: t0, scheduler: sched)
        XCTAssertEqual(failed.record(for: .outs).consecutiveMisses, 1)
        XCTAssertEqual(passed.record(for: .outs).consecutiveMisses, 0)
        XCTAssertLessThan(failed.record(for: .outs).review.due!,
                          passed.record(for: .outs).review.due!)
    }

    // MARK: - the daily set (spec §7.1)

    func testDailySeedIsStableForADayAndDiffersAcrossDays() {
        let a = ReviewQueue.dailySeed(day: DayKey(raw: "2026-08-03")!, contentVersion: 1)
        let b = ReviewQueue.dailySeed(day: DayKey(raw: "2026-08-03")!, contentVersion: 1)
        let c = ReviewQueue.dailySeed(day: DayKey(raw: "2026-08-04")!, contentVersion: 1)
        XCTAssertEqual(a, b, "everyone gets the same set on the same day")
        XCTAssertNotEqual(a, c)
    }

    /// Bumping content must reshuffle the day, or a rebuilt spot set would silently
    /// keep serving yesterday's puzzle.
    func testDailySeedChangesWithContentVersion() {
        let day = DayKey(raw: "2026-08-03")!
        XCTAssertNotEqual(ReviewQueue.dailySeed(day: day, contentVersion: 1),
                          ReviewQueue.dailySeed(day: day, contentVersion: 2))
    }

    func testDailySetPrefersDueConceptsThenFallsBackToStudiedOnes() {
        var s = state(due: [(.outs, -1), (.combos, -2)])
        s.updateRecord(for: .potOdds) {
            $0.tier = .familiar; $0.total = 3; $0.correct = 3
            $0.review = ReviewState(stability: 5, difficulty: 5,
                                    lastReview: self.t0, due: self.days(30), reps: 2)
        }
        let set = ReviewQueue.dailySet(in: s, at: t0, scheduler: sched, size: 5)
        XCTAssertEqual(set.prefix(2).map { $0 }, [.combos, .outs], "due first, most overdue leading")
        XCTAssertTrue(set.contains(.potOdds), "then studied-but-not-due material")
        XCTAssertLessThanOrEqual(set.count, 5)
        XCTAssertEqual(Set(set).count, set.count, "no concept twice in one day")
    }

    func testDailySetIsEmptyForAUserWhoHasStudiedNothing() {
        XCTAssertTrue(ReviewQueue.dailySet(in: ProgressState(), at: t0,
                                           scheduler: sched, size: 5).isEmpty)
    }

    /// Spec §7.1: a streak day requires a session that included a due item, so this
    /// question has to be answerable from state alone.
    func testSessionQualifiesForTheStreakOnlyWhenItIncludedADueItem() {
        let s = state(due: [(.outs, -1)])
        XCTAssertTrue(ReviewQueue.sessionQualifiesForStreak(answered: [.outs], in: s,
                                                            at: t0, scheduler: sched))
        XCTAssertFalse(ReviewQueue.sessionQualifiesForStreak(answered: [.potOdds], in: s,
                                                             at: t0, scheduler: sched))
        XCTAssertFalse(ReviewQueue.sessionQualifiesForStreak(answered: [], in: s,
                                                             at: t0, scheduler: sched))
    }

    /// A brand-new user has nothing due; their first lesson must still count.
    func testAFirstSessionWithNothingDueStillQualifies() {
        XCTAssertTrue(ReviewQueue.sessionQualifiesForStreak(answered: [.showdown],
                                                            in: ProgressState(),
                                                            at: t0, scheduler: sched))
    }
}
