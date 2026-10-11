import XCTest
@testable import GlassTableEngine

final class HandComparisonTests: XCTestCase {
    func testTurnComparisonUsesFullKickerStrength() {
        let board = Card.parse("8d2sJcAc")!
        XCTAssertEqual(compareHands(hero: Card.parse("Js4h")! + board, villain: Card.parse("3hJh")! + board), 0)
        XCTAssertEqual(compareHands(hero: Card.parse("3hJh")! + board, villain: Card.parse("Js4h")! + board), 1)
        XCTAssertEqual(compareHands(hero: Card.parse("Js3h")! + board, villain: Card.parse("Jd3c")! + board), 2)
    }

    func testBoardFlushTieAndHigherFlushLoss() {
        let board = Card.parse("4s9sJsKs")!
        let h = Card.parse("Qc9c")!, v = Card.parse("2hJd")!
        XCTAssertEqual(compareHands(hero: h + board + Card.parse("2s")!, villain: v + board + Card.parse("2s")!), 2)
        XCTAssertEqual(compareHands(hero: h + board + Card.parse("Ts")!, villain: v + board + Card.parse("Ts")!), 2)
    }
}
