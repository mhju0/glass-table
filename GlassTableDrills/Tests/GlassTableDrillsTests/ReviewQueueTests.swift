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
        let due = ReviewQueue.dueConcepts(in: s, at: t0)
        XCTAssertEqual(Set(due), [.outs, .combos])
    }

    /// An untouched concept is not "due" — it has never been taught, so surfacing it
    /// in review would be teaching by ambush.
    func testUntouchedConceptsAreNotDue() {
        let due = ReviewQueue.dueConcepts(in: ProgressState(), at: t0)
        XCTAssertTrue(due.isEmpty)
    }

    func testMostOverdueComesFirst() {
        let s = state(due: [(.outs, -1), (.combos, -10), (.potOdds, -4)])
        XCTAssertEqual(ReviewQueue.dueConcepts(in: s, at: t0),
                       [.combos, .potOdds, .outs])
    }

    /// Spec §4.6: a concept past the stop-drilling threshold must leave the queue —
    /// it needs an explainer, not another rep.
    func testConceptsPastTheStopDrillingThresholdAreWithheld() {
        var s = state(due: [(.outs, -1), (.combos, -2)])
        s.updateRecord(for: .outs) { $0.consecutiveMisses = 8 }
        XCTAssertEqual(ReviewQueue.dueConcepts(in: s, at: t0), [.combos])
        XCTAssertEqual(ReviewQueue.needingExplainer(in: s), [.outs])
    }

    func testRecordingAReviewAdvancesTheScheduleAndClearsTheDueState() {
        var s = state(due: [(.outs, -1)])
        XCTAssertFalse(ReviewQueue.dueConcepts(in: s, at: t0).isEmpty)
        ReviewQueue.recordReview(&s, concept: .outs, rating: .good,
                                 interval: nil, now: t0, scheduler: sched)
        XCTAssertTrue(ReviewQueue.dueConcepts(in: s, at: t0).isEmpty)
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

    func testAnsweringOneDueConceptEarnsAStreakWhileAnotherRemainsDue() {
        for rating in [FSRS.Rating.good, .again] {
            var s = state(due: [(.outs, -1), (.combos, -2)])
            ReviewQueue.recordReview(&s, concept: .outs, rating: rating,
                                     interval: nil, now: t0, scheduler: sched)
            XCTAssertEqual(s.streak.current, 1)
            XCTAssertEqual(s.streak.lastSessionDay, DayKey(t0))
            XCTAssertTrue(ReviewQueue.dueConcepts(in: s, at: t0).contains(.combos))
        }
    }

    func testAnsweringFreshMaterialDoesNotFarmAStreakWhenReviewIsDue() {
        var s = state(due: [(.outs, -1)])
        ReviewQueue.recordReview(&s, concept: .showdown, rating: .good,
                                 interval: nil, now: t0, scheduler: sched)
        XCTAssertEqual(s.streak.current, 0)
    }

    func testFirstAnswerWithNothingDueEarnsAStreak() {
        var s = ProgressState()
        ReviewQueue.recordReview(&s, concept: .showdown, rating: .good,
                                 interval: nil, now: t0, scheduler: sched)
        XCTAssertEqual(s.streak.current, 1)
        ReviewQueue.recordReview(&s, concept: .showdown, rating: .good,
                                 interval: nil, now: t0, scheduler: sched)
        XCTAssertEqual(s.streak.current, 1, "more answers on the same day do not inflate the streak")
    }
}
