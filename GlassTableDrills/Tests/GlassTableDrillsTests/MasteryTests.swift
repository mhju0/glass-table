import XCTest
@testable import GlassTableDrills

final class MasteryTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_785_000_000)
    private func hours(_ n: Double) -> TimeInterval { n * 3600 }

    // MARK: - tier promotion

    func testUnderSeventyPercentStaysAttempted() {
        var r = ConceptRecord(correct: 6, total: 10)
        Mastery.promote(&r, cleanRun: false, viaBoss: false, now: t0)
        XCTAssertEqual(r.tier, .attempted)
    }

    func testSeventyPercentReachesFamiliar() {
        var r = ConceptRecord(correct: 7, total: 10)
        Mastery.promote(&r, cleanRun: false, viaBoss: false, now: t0)
        XCTAssertEqual(r.tier, .familiar)
    }

    func testACleanRunReachesProficientAndStampsTheTime() {
        var r = ConceptRecord(correct: 9, total: 10)
        Mastery.promote(&r, cleanRun: true, viaBoss: false, now: t0)
        XCTAssertEqual(r.tier, .proficient)
        XCTAssertEqual(r.proficientAt, t0)
    }

    /// Spec §4.3 — the whole point of the top tier: blocked practice can never reach it.
    func testBlockedPracticeCanNeverReachMasteredNoMatterHowPerfect() {
        var r = ConceptRecord(correct: 500, total: 500, proficientAt: t0)
        for i in 0..<50 {
            Mastery.promote(&r, cleanRun: true, viaBoss: false,
                            now: t0.addingTimeInterval(hours(Double(i * 24))))
        }
        XCTAssertEqual(r.tier, .proficient)
        XCTAssertNil(r.masteredAt)
    }

    func testBossAfterTheTwelveHourCooldownAwardsMastered() {
        var r = ConceptRecord(tier: .proficient, correct: 20, total: 20, proficientAt: t0)
        Mastery.promote(&r, cleanRun: true, viaBoss: true, now: t0.addingTimeInterval(hours(12)))
        XCTAssertEqual(r.tier, .mastered)
        XCTAssertEqual(r.masteredAt, t0.addingTimeInterval(hours(12)))
    }

    func testBossBeforeTheCooldownDoesNotAwardMastered() {
        var r = ConceptRecord(tier: .proficient, correct: 20, total: 20, proficientAt: t0)
        Mastery.promote(&r, cleanRun: true, viaBoss: true,
                        now: t0.addingTimeInterval(hours(11.9)))
        XCTAssertEqual(r.tier, .proficient)
        XCTAssertNil(r.masteredAt)
    }

    func testBossCannotSkipStraightToMasteredFromFamiliar() {
        var r = ConceptRecord(tier: .familiar, correct: 8, total: 10)
        Mastery.promote(&r, cleanRun: false, viaBoss: true,
                        now: t0.addingTimeInterval(hours(48)))
        XCTAssertLessThan(r.tier, .mastered)
    }

    func testTierNeverRegresses() {
        var r = ConceptRecord(tier: .mastered, correct: 1, total: 10,
                              proficientAt: t0, masteredAt: t0)
        Mastery.promote(&r, cleanRun: false, viaBoss: false, now: t0.addingTimeInterval(hours(99)))
        XCTAssertEqual(r.tier, .mastered, "a bad session must not demote earned mastery")
    }

    // MARK: - answer recording and the miss counters (spec §4.6)

    func testRecordingACorrectAnswerClearsTheMissStreak() {
        var s = ProgressState()
        s.updateRecord(for: .outs) { $0.consecutiveMisses = 2 }
        Mastery.record(&s, concept: .outs, correct: true, interval: nil, now: t0)
        XCTAssertEqual(s.record(for: .outs).consecutiveMisses, 0)
        XCTAssertEqual(s.record(for: .outs).correct, 1)
        XCTAssertEqual(s.record(for: .outs).total, 1)
        XCTAssertEqual(s.answers.count, 1)
    }

    func testThreeConsecutiveMissesTriggersTheSlowWalkthroughOffer() {
        var s = ProgressState()
        for _ in 0..<2 { Mastery.record(&s, concept: .outs, correct: false, interval: nil, now: t0) }
        XCTAssertFalse(Mastery.shouldOfferWalkthrough(s.record(for: .outs)))
        Mastery.record(&s, concept: .outs, correct: false, interval: nil, now: t0)
        XCTAssertTrue(Mastery.shouldOfferWalkthrough(s.record(for: .outs)))
    }

    func testEightMissesStopsDrillingTheConcept() {
        var s = ProgressState()
        for _ in 0..<7 { Mastery.record(&s, concept: .outs, correct: false, interval: nil, now: t0) }
        XCTAssertFalse(Mastery.shouldStopDrilling(s.record(for: .outs)))
        Mastery.record(&s, concept: .outs, correct: false, interval: nil, now: t0)
        XCTAssertTrue(Mastery.shouldStopDrilling(s.record(for: .outs)))
    }

    func testIntervalAnswersAreLoggedForCalibration() {
        var s = ProgressState()
        let iv = IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 52)
        Mastery.record(&s, concept: .equitySense, correct: false, interval: iv, now: t0)
        XCTAssertEqual(s.answers.first?.interval, iv)
    }
}
