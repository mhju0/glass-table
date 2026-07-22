import XCTest
@testable import GlassTableEngine

final class OutsTests: XCTestCase {
    func testFlushDrawOutsExcludeBoardPairingHearts() {
        // Hero AhKh has the nut flush draw; villain holds pocket QsQd = trip queens on
        // board Qh7h2s3c. Hero is behind (ace-high vs trips) and needs a heart on the river.
        //
        // The textbook "flush draw = 9 outs" is WRONG here: the board pairs on 2h and 3h,
        // and those rivers give villain QQQ + a pair = a FULL HOUSE, which beats hero's
        // flush. So of the 9 remaining hearts, only 7 are genuine outs — 2h and 3h are not.
        // A correct evaluate7-based countOuts must exclude them.
        let hero = Card.parse("AhKh")!
        let vill = Card.parse("QsQd")!  // pocket queens
        let board = Card.parse("Qh7h2s3c")!
        let outs = countOuts(hero: hero, villain: vill, board: board)

        XCTAssertEqual(outs.count, 7)
        XCTAssertTrue(outs.allSatisfy { $0.suit == 2 })  // all hearts
        // The two board-pairing hearts fill villain's full house and must NOT be outs.
        XCTAssertFalse(outs.contains(Card("2h")!))
        XCTAssertFalse(outs.contains(Card("3h")!))
        // The seven clean flush cards are all outs.
        XCTAssertEqual(Set(outs), Set(Card.parse("4h5h6h8h9hThJh")!))
    }

    func testRuleOfTwoAndFour() {
        XCTAssertEqual(ruleOf2or4(outs: 9, cardsToCome: 1), 18, accuracy: 1e-9)  // rule of 2
        XCTAssertEqual(ruleOf2or4(outs: 9, cardsToCome: 2), 36, accuracy: 1e-9)  // rule of 4
    }
}
