import XCTest
@testable import GlassTableEngine

final class CardTests: XCTestCase {
    func testParseSingleCard() {
        let c = Card("As")
        XCTAssertEqual(c, Card(rank: 14, suit: 3))
    }

    func testParseSequence() {
        let cards = Card.parse("AsKhTd2c")
        XCTAssertEqual(cards, [
            Card(rank: 14, suit: 3), Card(rank: 13, suit: 2),
            Card(rank: 10, suit: 1), Card(rank: 2, suit: 0),
        ])
    }

    func testInvalidReturnsNil() {
        XCTAssertNil(Card("Zz"))
        XCTAssertNil(Card.parse("AsK"))
    }

    func testDeckHas52UniqueCards() {
        XCTAssertEqual(Deck.all.count, 52)
        XCTAssertEqual(Set(Deck.all).count, 52)
    }

    func testDescriptionRoundTrips() {
        XCTAssertEqual(Card("Th")?.description, "Th")
    }
}
