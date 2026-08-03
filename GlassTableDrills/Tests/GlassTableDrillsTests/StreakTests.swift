import XCTest
@testable import GlassTableDrills

final class StreakTests: XCTestCase {
    private func day(_ s: String) -> DayKey { DayKey(raw: s)! }

    func testFirstSessionStartsAStreakOfOne() {
        var r = StreakRecord()
        Streak.recordSession(&r, on: day("2026-08-03"))
        XCTAssertEqual(r.current, 1)
        XCTAssertEqual(r.longest, 1)
        XCTAssertEqual(r.lastSessionDay, day("2026-08-03"))
    }

    func testASecondSessionTheSameDayDoesNotDoubleCount() {
        var r = StreakRecord()
        Streak.recordSession(&r, on: day("2026-08-03"))
        Streak.recordSession(&r, on: day("2026-08-03"))
        XCTAssertEqual(r.current, 1)
    }

    func testConsecutiveDaysExtendTheStreak() {
        var r = StreakRecord()
        for d in ["2026-08-01", "2026-08-02", "2026-08-03"] {
            Streak.recordSession(&r, on: day(d))
        }
        XCTAssertEqual(r.current, 3)
        XCTAssertEqual(r.longest, 3)
    }

    /// Spec §7.1: forgiveness is silent and automatic — no dialog, no confirmation.
    func testOneMissedDayIsCoveredByAFreezeWithoutBreakingTheStreak() {
        var r = StreakRecord()
        Streak.recordSession(&r, on: day("2026-08-01"))
        Streak.recordSession(&r, on: day("2026-08-02"))
        XCTAssertEqual(r.freezesRemaining, 2)

        Streak.recordSession(&r, on: day("2026-08-04"))   // skipped the 3rd
        XCTAssertEqual(r.current, 3, "the freeze covers the gap and the streak grows")
        XCTAssertEqual(r.freezesRemaining, 1)
    }

    func testFreezesAreConsumedOnePerMissedDay() {
        var r = StreakRecord()
        Streak.recordSession(&r, on: day("2026-08-01"))
        Streak.recordSession(&r, on: day("2026-08-04"))   // 2 missed days, 2 freezes
        XCTAssertEqual(r.freezesRemaining, 0)
        XCTAssertEqual(r.current, 2)
    }

    func testAGapWiderThanTheFreezesResetsTheStreakButKeepsTheRecord() {
        var r = StreakRecord()
        for d in ["2026-08-01", "2026-08-02", "2026-08-03", "2026-08-04"] {
            Streak.recordSession(&r, on: day(d))
        }
        XCTAssertEqual(r.current, 4)
        Streak.recordSession(&r, on: day("2026-08-12"))   // 7 missed days, only 2 freezes
        XCTAssertEqual(r.current, 1)
        XCTAssertEqual(r.longest, 4, "the personal best survives a broken streak")
    }

    /// Spec §7.1: a 48h earn-back window, capped at two.
    ///
    /// Sessions are on *consecutive* days on purpose — a gap would consume the very
    /// freeze being earned and this would stop measuring earn-back at all.
    func testFreezesEarnBackEveryFortyEightHoursAndCapAtTwo() {
        var r = StreakRecord(current: 1, longest: 1,
                             lastSessionDay: day("2026-08-01"), freezesRemaining: 0,
                             lastFreezeEarnedDay: day("2026-08-01"))
        Streak.recordSession(&r, on: day("2026-08-02"))
        XCTAssertEqual(r.freezesRemaining, 0, "only 24h since the last earn")

        Streak.recordSession(&r, on: day("2026-08-03"))
        XCTAssertEqual(r.freezesRemaining, 1, "48h → one freeze back")

        Streak.recordSession(&r, on: day("2026-08-04"))
        XCTAssertEqual(r.freezesRemaining, 1, "clock reset on the grant")

        Streak.recordSession(&r, on: day("2026-08-05"))
        XCTAssertEqual(r.freezesRemaining, 2)

        Streak.recordSession(&r, on: day("2026-08-06"))
        XCTAssertEqual(r.freezesRemaining, 2, "capped at two")
    }

    /// A record with no earn clock (built directly, or restored from an older store)
    /// must still accrue rather than being frozen at zero forever.
    func testAnUnsetEarnClockSeedsFromTheLastSessionInsteadOfStalling() {
        var r = StreakRecord(current: 1, longest: 1,
                             lastSessionDay: day("2026-08-01"), freezesRemaining: 0)
        XCTAssertNil(r.lastFreezeEarnedDay)
        Streak.recordSession(&r, on: day("2026-08-02"))
        XCTAssertEqual(r.lastFreezeEarnedDay, day("2026-08-01"), "clock seeded, not lost")
        Streak.recordSession(&r, on: day("2026-08-03"))
        XCTAssertEqual(r.freezesRemaining, 1)
    }

    /// A consumed freeze must be re-earnable, or forgiveness is one-shot.
    func testAConsumedFreezeCanBeEarnedBack() {
        var r = StreakRecord()
        Streak.recordSession(&r, on: day("2026-08-01"))
        Streak.recordSession(&r, on: day("2026-08-03"))   // skips a day, spends one
        XCTAssertEqual(r.freezesRemaining, 1)
        Streak.recordSession(&r, on: day("2026-08-04"))
        Streak.recordSession(&r, on: day("2026-08-05"))   // 48h since the grant clock
        XCTAssertEqual(r.freezesRemaining, 2)
    }

    /// A clock that goes backwards (timezone travel, manual clock change) must not
    /// corrupt the streak.
    func testAnOlderDayThanTheLastSessionIsIgnored() {
        var r = StreakRecord()
        Streak.recordSession(&r, on: day("2026-08-05"))
        Streak.recordSession(&r, on: day("2026-08-02"))
        XCTAssertEqual(r.current, 1)
        XCTAssertEqual(r.lastSessionDay, day("2026-08-05"))
    }
}

final class CalibrationTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_785_000_000)

    private func log(_ intervals: [IntervalAnswer]) -> ProgressState {
        var s = ProgressState()
        for (i, iv) in intervals.enumerated() {
            s.append(AnswerRecord(concept: .equitySense,
                                  at: t0.addingTimeInterval(Double(i)),
                                  correct: iv.containsTruth, interval: iv))
        }
        return s
    }

    func testHitRateIsTheShareOfIntervalsContainingTheTruth() {
        let s = log([
            IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 41),   // hit
            IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 44),   // hit
            IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 60),   // miss
            IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 10),   // miss
        ])
        XCTAssertEqual(Calibration.hitRate(in: s), 0.5)
    }

    func testHitRateIsNilWithoutIntervalAnswers() {
        XCTAssertNil(Calibration.hitRate(in: ProgressState()))
    }

    func testExactAnswersAreExcludedFromCalibration() {
        var s = ProgressState()
        s.append(AnswerRecord(concept: .potOdds, at: t0, correct: true))
        XCTAssertNil(Calibration.hitRate(in: s))
    }

    /// Winkler: width alone when the truth is inside, plus a miss penalty scaled by
    /// 2/alpha when it falls outside. Lower is better.
    func testWinklerScoresWidthWhenTheTruthIsContained() {
        let iv = IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 41)
        XCTAssertEqual(Calibration.winklerScore(iv, confidence: 0.9), 10, accuracy: 1e-9)
    }

    func testWinklerPenalisesMissesInProportionToTheShortfall() {
        let over = IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 50)   // 5 above hi
        // width 10 + (2/0.1) * 5 = 110
        XCTAssertEqual(Calibration.winklerScore(over, confidence: 0.9), 110, accuracy: 1e-9)
        let under = IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 30)  // 5 below lo
        XCTAssertEqual(Calibration.winklerScore(under, confidence: 0.9), 110, accuracy: 1e-9)
    }

    /// The property that makes this ungameable: a huge interval always contains the
    /// truth but scores worse than a tight one that also contains it.
    func testAWideAlwaysCorrectIntervalScoresWorseThanATightCorrectOne() {
        let lazyWide = IntervalAnswer(point: 50, lo: 0, hi: 100, truth: 41)
        let tight = IntervalAnswer(point: 40, lo: 38, hi: 44, truth: 41)
        XCTAssertTrue(lazyWide.containsTruth && tight.containsTruth)
        XCTAssertGreaterThan(Calibration.winklerScore(lazyWide, confidence: 0.9),
                             Calibration.winklerScore(tight, confidence: 0.9))
    }

    func testVerdictNamesOverconfidenceAndUnderconfidence() {
        XCTAssertEqual(Calibration.verdict(hitRate: 0.58, nominal: 0.9), .overconfident)
        XCTAssertEqual(Calibration.verdict(hitRate: 0.99, nominal: 0.9), .underconfident)
        XCTAssertEqual(Calibration.verdict(hitRate: 0.89, nominal: 0.9), .calibrated)
    }
}
