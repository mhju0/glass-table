import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class EstimateTests: XCTestCase {
    func testBoundsAreNormalisedSoAnInvertedIntervalStillScores() {
        let e = Estimate(point: 40, lo: 50, hi: 30)
        XCTAssertEqual(e.lo, 30)
        XCTAssertEqual(e.hi, 50)
        XCTAssertTrue(e.answer(truth: 45).containsTruth)
    }
}

final class EquitySenseTests: XCTestCase {
    private func spot(_ h: String, _ v: String, _ b: String) -> EquitySenseSpot {
        EquitySenseSpot(hero: Card.parse(h)!, villain: Card.parse(v)!, board: Card.parse(b)!)
    }

    /// A drawing hand on the turn: A♥K♥ vs Q♠Q♦ on Q♥7♥2♠3♣ — the 첫 핸드 spot, where
    /// 7 of 44 rivers win. Cross-checks the drill against a number the app already
    /// teaches elsewhere.
    func testTurnEquityMatchesTheOutsTheAppAlreadyTeaches() {
        let s = spot("AhKh", "QsQd", "Qh7h2s3c")
        XCTAssertEqual(s.equityPct, 7.0 / 44.0 * 100, accuracy: 0.01)
    }

    func testADominatedHandHasLowEquityAndTheDominatorHigh() {
        let hero = spot("AhKh", "QsQd", "Qh7h2s3c")
        let villain = spot("QsQd", "AhKh", "Qh7h2s3c")
        XCTAssertEqual(hero.equityPct + villain.equityPct, 100, accuracy: 1e-9,
                       "the two sides must sum to 100%")
        XCTAssertLessThan(hero.equityPct, villain.equityPct)
    }

    func testEquityIsAlwaysAPercentage() {
        for i in 0..<40 {
            let s = EquitySenseSpotGenerator.spot(baseSeed: 4, index: i)
            XCTAssertTrue(s.equityPct >= 0 && s.equityPct <= 100)
        }
    }

    func testGeneratorIsDeterministicAndDealsFlopsAndTurns() {
        XCTAssertEqual(EquitySenseSpotGenerator.spot(baseSeed: 4, index: 8),
                       EquitySenseSpotGenerator.spot(baseSeed: 4, index: 8))
        var streets = Set<Int>()
        for i in 0..<60 {
            let s = EquitySenseSpotGenerator.spot(baseSeed: 4, index: i)
            XCTAssertEqual(Set(s.hero + s.villain + s.board).count, 4 + s.board.count,
                           "no duplicate cards")
            streets.insert(s.board.count)
        }
        XCTAssertEqual(streets, [3, 4], "both flop and turn spots must appear")
    }

    func testGradingBandsWidenFromTheExactAnswer() {
        let s = spot("AhKh", "QsQd", "Qh7h2s3c")
        let truth = s.equityPct                                     // ≈ 15.9%
        func band(_ p: Double) -> GradeBand {
            gradeEquitySense(estimate: Estimate(point: p, lo: p - 5, hi: p + 5), spot: s).band
        }
        XCTAssertEqual(band(truth), .spotOn)
        XCTAssertEqual(band(truth + 3), .spotOn)
        XCTAssertEqual(band(truth + 8), .close)
        XCTAssertEqual(band(truth + 20), .off)
    }

    func testIntervalHitIsReportedIndependentlyOfTheBand() {
        let s = spot("AhKh", "QsQd", "Qh7h2s3c")
        let truth = s.equityPct
        // A wide interval contains the truth even though the point estimate is off.
        let wide = gradeEquitySense(estimate: Estimate(point: truth + 20, lo: 0, hi: 100), spot: s)
        XCTAssertEqual(wide.band, .off)
        XCTAssertTrue(wide.intervalHit)
        // ...and Winkler still punishes it relative to an honest tight one.
        let tight = gradeEquitySense(estimate: Estimate(point: truth, lo: truth - 3, hi: truth + 3),
                                     spot: s)
        XCTAssertTrue(tight.intervalHit)
        XCTAssertGreaterThan(Calibration.winklerScore(wide.intervalAnswer),
                             Calibration.winklerScore(tight.intervalAnswer))
    }
}

final class EVCallTests: XCTestCase {
    /// Pot 10, bet 10, so calling 10 wins 20 and loses 10. At 50% equity that is
    /// 0.5*20 − 0.5*10 = +5bb.
    func testEVOfAClearlyProfitableCall() {
        let s = EVCallSpot(pot: 10, bet: 10, equityPct: 50, didWin: true)
        XCTAssertEqual(s.evBB, 5, accuracy: 1e-9)
        XCTAssertTrue(s.isProfitable)
    }

    func testEVOfAClearlyLosingCall() {
        let s = EVCallSpot(pot: 10, bet: 10, equityPct: 20, didWin: false)
        // 0.2*20 − 0.8*10 = 4 − 8 = −4
        XCTAssertEqual(s.evBB, -4, accuracy: 1e-9)
        XCTAssertFalse(s.isProfitable)
    }

    /// EV must cross zero exactly at the pot-odds break-even the app already teaches.
    func testEVIsZeroAtExactlyTheRequiredEquity() {
        let pot = 10.0, bet = 5.0
        let required = requiredEquity(toCall: bet, pot: pot + bet) * 100
        let s = EVCallSpot(pot: 10, bet: 5, equityPct: required, didWin: false)
        XCTAssertEqual(s.evBB, 0, accuracy: 1e-9)
    }

    func testEVRisesMonotonicallyWithEquity() {
        var previous = -Double.infinity
        for e in stride(from: 0.0, through: 100.0, by: 5.0) {
            let ev = EVCallSpot(pot: 12, bet: 6, equityPct: e, didWin: false).evBB
            XCTAssertGreaterThan(ev, previous)
            previous = ev
        }
    }

    func testGeneratorIsDeterministicAndProducesBothSigns() {
        XCTAssertEqual(EVCallSpotGenerator.spot(baseSeed: 13, index: 2),
                       EVCallSpotGenerator.spot(baseSeed: 13, index: 2))
        var profitable = 0, losing = 0
        for i in 0..<200 {
            let s = EVCallSpotGenerator.spot(baseSeed: 13, index: i)
            XCTAssertGreaterThan(s.bet, 0)
            XCTAssertTrue(s.equityPct >= 0 && s.equityPct <= 100)
            if s.isProfitable { profitable += 1 } else { losing += 1 }
        }
        XCTAssertGreaterThan(profitable, 0)
        XCTAssertGreaterThan(losing, 0, "the sign must not be guessable from sizing alone")
    }

    /// The outcome is a distractor and must never enter the grade — that is the whole
    /// outcome-bias lesson.
    func testTheHandsResultDoesNotAffectTheAnswerOrTheGrade() {
        let won = EVCallSpot(pot: 10, bet: 10, equityPct: 20, didWin: true)
        let lost = EVCallSpot(pot: 10, bet: 10, equityPct: 20, didWin: false)
        XCTAssertEqual(won.evBB, lost.evBB)
        let e = Estimate(point: -4, lo: -5, hi: -3)
        XCTAssertEqual(gradeEVCall(estimate: e, spot: won).band,
                       gradeEVCall(estimate: e, spot: lost).band)
        XCTAssertTrue(gradeEVCall(estimate: e, spot: won).whyText.contains("결과는"))
    }

    func testGradingBandsAreTightBecauseEVIsInBigBlinds() {
        let s = EVCallSpot(pot: 10, bet: 10, equityPct: 50, didWin: true)   // EV = +5
        func band(_ p: Double) -> GradeBand {
            gradeEVCall(estimate: Estimate(point: p, lo: p - 1, hi: p + 1), spot: s).band
        }
        XCTAssertEqual(band(5), .spotOn)
        XCTAssertEqual(band(5.4), .spotOn)
        XCTAssertEqual(band(6.2), .close)
        XCTAssertEqual(band(8), .off)
    }
}
