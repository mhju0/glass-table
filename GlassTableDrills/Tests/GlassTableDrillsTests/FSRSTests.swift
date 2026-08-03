import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class FSRSTests: XCTestCase {
    private let s = FSRSScheduler()
    private let t0 = Date(timeIntervalSince1970: 1_785_000_000)
    private func days(_ n: Double) -> Date { t0.addingTimeInterval(n * 86400) }

    // MARK: - the published constants

    func testShipsTheTwentyOnePublishedFSRS6Parameters() {
        XCTAssertEqual(FSRS.defaultParameters.count, 21)
        XCTAssertEqual(FSRS.defaultParameters[0], 0.212)
        XCTAssertEqual(FSRS.defaultParameters[4], 6.4133)
        XCTAssertEqual(FSRS.defaultParameters[7], 0.001)
        XCTAssertEqual(FSRS.defaultParameters[20], 0.1542, "the decay term")
    }

    // MARK: - retrievability

    func testRetrievabilityIsOneAtZeroElapsedAndDecaysMonotonically() {
        XCTAssertEqual(s.retrievability(stability: 10, elapsedDays: 0), 1, accuracy: 1e-12)
        var previous = 1.0
        for d in stride(from: 1.0, through: 60.0, by: 1.0) {
            let r = s.retrievability(stability: 10, elapsedDays: d)
            XCTAssertLessThan(r, previous)
            XCTAssertTrue(r > 0 && r <= 1)
            previous = r
        }
    }

    /// The defining property: at the interval FSRS picks, retrievability should have
    /// decayed to (about) the retention the user asked for.
    func testTheChosenIntervalLandsOnDesiredRetention() {
        for retention in [0.8, 0.9, 0.95] {
            let sched = FSRSScheduler(desiredRetention: retention)
            for stability in [1.0, 10.0, 100.0, 365.0] {
                let interval = Double(sched.nextInterval(stability: stability))
                let r = sched.retrievability(stability: stability, elapsedDays: interval)
                XCTAssertEqual(r, retention, accuracy: 0.05,
                               "S=\(stability) retention=\(retention)")
            }
        }
    }

    func testHigherDesiredRetentionMeansShorterIntervals() {
        let relaxed = FSRSScheduler(desiredRetention: 0.8)
        let strict = FSRSScheduler(desiredRetention: 0.95)
        XCTAssertGreaterThan(relaxed.nextInterval(stability: 50),
                             strict.nextInterval(stability: 50))
    }

    func testIntervalIsAtLeastOneDayAndRespectsTheMaximum() {
        XCTAssertGreaterThanOrEqual(s.nextInterval(stability: 0.001), 1)
        let capped = FSRSScheduler(maximumInterval: 30)
        XCTAssertEqual(capped.nextInterval(stability: 100_000), 30)
    }

    // MARK: - first review

    func testFirstReviewSeedsStabilityFromTheRatingsOwnParameter() {
        for (rating, index) in [(FSRS.Rating.again, 0), (.hard, 1), (.good, 2), (.easy, 3)] {
            var st = ReviewState()
            s.review(&st, rating: rating, now: t0)
            XCTAssertEqual(st.stability, FSRS.defaultParameters[index], accuracy: 1e-12)
            XCTAssertEqual(st.reps, 1)
            XCTAssertEqual(st.lastReview, t0)
            XCTAssertNotNil(st.due)
        }
    }

    func testABetterFirstRatingGivesMoreStabilityAndLessDifficulty() {
        var again = ReviewState(); s.review(&again, rating: .again, now: t0)
        var good = ReviewState(); s.review(&good, rating: .good, now: t0)
        var easy = ReviewState(); s.review(&easy, rating: .easy, now: t0)
        XCTAssertLessThan(again.stability, good.stability)
        XCTAssertLessThan(good.stability, easy.stability)
        XCTAssertGreaterThan(again.difficulty, good.difficulty)
        XCTAssertGreaterThan(good.difficulty, easy.difficulty)
    }

    func testDifficultyStaysInsideOneToTen() {
        var st = ReviewState()
        var now = t0
        for i in 0..<200 {
            s.review(&st, rating: i % 3 == 0 ? .again : .good, now: now)
            XCTAssertTrue((FSRS.minDifficulty...FSRS.maxDifficulty).contains(st.difficulty),
                          "difficulty escaped: \(st.difficulty)")
            XCTAssertGreaterThanOrEqual(st.stability, FSRS.minStability)
            now = now.addingTimeInterval(Double(st.due!.timeIntervalSince(now)))
        }
    }

    // MARK: - spaced reviews

    func testSuccessfulSpacedReviewsGrowStabilityAndStretchIntervals() {
        var st = ReviewState()
        var now = t0
        s.review(&st, rating: .good, now: now)
        var lastInterval = 0
        for _ in 0..<6 {
            let interval = s.nextInterval(stability: st.stability)
            XCTAssertGreaterThanOrEqual(interval, lastInterval)
            lastInterval = interval
            now = now.addingTimeInterval(Double(interval) * 86400)
            let before = st.stability
            s.review(&st, rating: .good, now: now)
            XCTAssertGreaterThan(st.stability, before, "stability must grow on recall")
        }
    }

    func testForgettingCollapsesStabilityAndCountsALapse() {
        var st = ReviewState()
        var now = t0
        s.review(&st, rating: .good, now: now)
        for _ in 0..<4 {
            now = now.addingTimeInterval(Double(s.nextInterval(stability: st.stability)) * 86400)
            s.review(&st, rating: .good, now: now)
        }
        let grown = st.stability
        XCTAssertEqual(st.lapses, 0)

        now = now.addingTimeInterval(Double(s.nextInterval(stability: st.stability)) * 86400)
        s.review(&st, rating: .again, now: now)
        XCTAssertLessThan(st.stability, grown, "a lapse must shrink stability")
        XCTAssertEqual(st.lapses, 1)
    }

    /// Spec §4.2: blocked practice is several reps in one sitting. Those must not
    /// inflate stability the way genuinely spaced reviews do.
    func testSameDayRepsGrowStabilityFarLessThanSpacedOnes() {
        var sameDay = ReviewState()
        s.review(&sameDay, rating: .good, now: t0)
        for i in 1...4 {
            s.review(&sameDay, rating: .good, now: t0.addingTimeInterval(Double(i) * 300))
        }

        var spaced = ReviewState()
        var now = t0
        s.review(&spaced, rating: .good, now: now)
        for _ in 0..<4 {
            now = now.addingTimeInterval(Double(s.nextInterval(stability: spaced.stability)) * 86400)
            s.review(&spaced, rating: .good, now: now)
        }
        XCTAssertLessThan(sameDay.stability, spaced.stability)
    }

    func testHardScoresBetweenAgainAndGood() {
        func stability(after rating: FSRS.Rating) -> Double {
            var st = ReviewState()
            s.review(&st, rating: .good, now: t0)
            s.review(&st, rating: rating, now: days(10))
            return st.stability
        }
        XCTAssertLessThan(stability(after: .again), stability(after: .hard))
        XCTAssertLessThan(stability(after: .hard), stability(after: .good))
    }

    // MARK: - due dates

    func testANewConceptIsDueAndAJustReviewedOneIsNot() {
        XCTAssertTrue(s.isDue(ReviewState(), at: t0))
        var st = ReviewState()
        s.review(&st, rating: .good, now: t0)
        XCTAssertFalse(s.isDue(st, at: t0))
        XCTAssertTrue(s.isDue(st, at: days(3650)))
    }

    // MARK: - grade mapping

    func testGlassTableGradesMapOntoRatings() {
        XCTAssertEqual(FSRS.Rating.forExact(correct: true), .good)
        XCTAssertEqual(FSRS.Rating.forExact(correct: false), .again)
        XCTAssertEqual(FSRS.Rating.forBand(.spotOn), .good)
        XCTAssertEqual(FSRS.Rating.forBand(.close), .hard)
        XCTAssertEqual(FSRS.Rating.forBand(.off), .again)
    }

    func testSchedulingIsDeterministic() {
        var a = ReviewState(), b = ReviewState()
        for i in 0..<10 {
            s.review(&a, rating: .good, now: days(Double(i * 3)))
            s.review(&b, rating: .good, now: days(Double(i * 3)))
        }
        XCTAssertEqual(a, b)
    }
}
