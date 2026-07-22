import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class BetSpotTests: XCTestCase {
    func testDeterministicAndVaried() {
        XCTAssertEqual(BetSpotGenerator.spot(baseSeed: 7, index: 3),
                       BetSpotGenerator.spot(baseSeed: 7, index: 3))
        let distinct = Set((0..<20).map { BetSpotGenerator.spot(baseSeed: 7, index: $0) }
            .map { "\($0.pot)-\($0.bet)" })
        XCTAssertGreaterThan(distinct.count, 1)
    }

    func testSpotInvariants() {
        for i in 0..<200 {
            let s = BetSpotGenerator.spot(baseSeed: 7, index: i)
            XCTAssertTrue(BetSpotGenerator.pots.contains(s.pot))
            XCTAssertGreaterThanOrEqual(s.bet, 1)
            // Both answers must be reachable on the 5%-step grid within the 정확 band.
            let nearestReq = (s.requiredPct / 5).rounded() * 5
            XCTAssertLessThanOrEqual(abs(nearestReq - s.requiredPct), 2.5)
            let nearestMdf = (s.mdfPct / 5).rounded() * 5
            XCTAssertLessThanOrEqual(abs(nearestMdf - s.mdfPct), 2.5)
        }
    }

    func testPotOddsGradeAndWhy() {
        let s = BetSpot(pot: 10, bet: 5)  // required = 5/20 = 25%
        XCTAssertEqual(gradePotOdds(estimatePct: 25, spot: s).band, .spotOn)
        XCTAssertEqual(gradePotOdds(estimatePct: 30, spot: s).band, .close)
        XCTAssertEqual(gradePotOdds(estimatePct: 35, spot: s).band, .off)
        XCTAssertEqual(gradePotOdds(estimatePct: 25, spot: s).whyText,
                       "벳 5 ÷ (팟 10 + 벳 5 + 콜 5) = 25%")
    }

    func testMDFGradeAndWhy() {
        let s = BetSpot(pot: 10, bet: 5)  // mdf = 10/15 = 66.7%
        XCTAssertEqual(gradeMDF(estimatePct: 65, spot: s).band, .spotOn)  // nearest grid step
        XCTAssertEqual(gradeMDF(estimatePct: 60, spot: s).band, .close)
        XCTAssertEqual(gradeMDF(estimatePct: 55, spot: s).band, .off)
        XCTAssertEqual(gradeMDF(estimatePct: 65, spot: s).whyText,
                       "팟 10 ÷ (팟 10 + 벳 5) = 66.7%")
    }

    func testPctText() {
        XCTAssertEqual(pctText(25.0), "25")
        XCTAssertEqual(pctText(100.0 * 2 / 3), "66.7")
        XCTAssertEqual(pctText(37.5), "37.5")
    }
}
