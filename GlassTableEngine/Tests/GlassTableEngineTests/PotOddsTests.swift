import XCTest
@testable import GlassTableEngine

final class PotOddsTests: XCTestCase {
    func testRequiredEquityHalfPotCall() {
        // Pot is 100 (incl. villain's 50 bet), call 50 -> need 50/150 = 33.3%.
        XCTAssertEqual(requiredEquity(toCall: 50, pot: 100), 1.0/3.0, accuracy: 1e-9)
    }

    func testCallProfitability() {
        XCTAssertTrue(callIsProfitable(equity: 0.40, toCall: 50, pot: 100))
        XCTAssertFalse(callIsProfitable(equity: 0.30, toCall: 50, pot: 100))
    }

    func testCallEV() {
        // equity 0.40, win 100, lose 50: 0.40*100 - 0.60*50 = 40 - 30 = 10.
        XCTAssertEqual(callEV(equity: 0.40, toCall: 50, pot: 100), 10, accuracy: 1e-9)
    }

    func testMDFAgainstHalfPotBet() {
        // Bet 50 into 100 -> defend 100/150 = 66.7%.
        XCTAssertEqual(mdf(bet: 50, pot: 100), 2.0/3.0, accuracy: 1e-9)
    }
}
