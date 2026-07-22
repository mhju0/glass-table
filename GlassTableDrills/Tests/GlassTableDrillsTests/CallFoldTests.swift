import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class CallFoldTests: XCTestCase {
    func testDeterministic() {
        XCTAssertEqual(CallFoldSpotGenerator.spot(baseSeed: 11, index: 5),
                       CallFoldSpotGenerator.spot(baseSeed: 11, index: 5))
    }

    func testSpotInvariants() {
        for i in 0..<30 {
            let s = CallFoldSpotGenerator.spot(baseSeed: 11, index: i)
            XCTAssertEqual(s.board.count, 4)
            XCTAssertGreaterThanOrEqual(s.bet, 1)
            XCTAssertTrue((5.0...95.0).contains(s.equityPct), "index \(i): \(s.equityPct)")
            // equityPct must match the engine's exact enumeration.
            let exact = exactEquityHeadsUp(hero: s.hero, villain: s.villain, board: s.board).equity
            XCTAssertEqual(s.equityPct, exact * 100, accuracy: 1e-9)
            XCTAssertEqual(s.correctIsCall,
                           callIsProfitable(equity: exact, toCall: Double(s.bet),
                                            pot: Double(s.pot + s.bet)))
        }
    }

    func testGradeBothWays() {
        let s = CallFoldSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
                             board: Card.parse("Qh7h2s3c")!, pot: 10, bet: 5, equityPct: 30)
        XCTAssertTrue(s.correctIsCall)  // 30% > required 25%
        XCTAssertEqual(gradeCallFold(userCalls: true, spot: s).band, .spotOn)
        XCTAssertEqual(gradeCallFold(userCalls: false, spot: s).band, .off)
        XCTAssertEqual(gradeCallFold(userCalls: true, spot: s).whyText,
                       "에퀴티 30% vs 필요 25% → 콜")
    }

    func testFoldSpotWhy() {
        let s = CallFoldSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
                             board: Card.parse("Qh7h2s3c")!, pot: 10, bet: 5, equityPct: 20)
        XCTAssertFalse(s.correctIsCall)
        XCTAssertEqual(gradeCallFold(userCalls: false, spot: s).whyText,
                       "에퀴티 20% vs 필요 25% → 폴드")
    }
}
