import XCTest
@testable import GlassTableEngine

final class BestFiveTests: XCTestCase {
    private func five(_ s: String) -> [Card] { bestFiveCards(Card.parse(s)!) }

    func testReturnsExactlyFiveOfTheSevenGivenCards() {
        let seven = Card.parse("AhKhQhJhTh2c3d")!
        let best = bestFiveCards(seven)
        XCTAssertEqual(best.count, 5)
        XCTAssertTrue(Set(best).isSubset(of: Set(seven)))
    }

    func testPicksTheStraightFlushOverTheOffsuitJunk() {
        XCTAssertEqual(Set(five("AhKhQhJhTh2c3d")), Set(Card.parse("AhKhQhJhTh")!))
    }

    func testPicksTheFlushAndDropsTheOffsuitCards() {
        // Six hearts available; the five highest must play.
        XCTAssertEqual(Set(five("Ah9h7h5h3h2s4c")), Set(Card.parse("Ah9h7h5h3h")!))
    }

    func testTwoPairKeepsTheBestKicker() {
        // Pairs of aces and nines, kickers K / 4 / 2 — the king plays.
        XCTAssertEqual(Set(five("AsAd9s9dKh4c2h")), Set(Card.parse("AsAd9s9dKh")!))
    }

    /// The board plays: hero's hole cards contribute nothing.
    func testBoardPlayingReturnsOnlyBoardCards() {
        XCTAssertEqual(Set(five("2c3dAsKsQsJsTs")), Set(Card.parse("AsKsQsJsTs")!))
    }

    /// The chosen five must always score the same as the seven-card evaluation.
    func testChosenFiveAlwaysScoresEqualToTheSevenCardEvaluation() {
        var rng = SplitMix64(seed: 424242)
        for _ in 0..<400 {
            let seven = Array(Deck.all.shuffled(using: &rng).prefix(7))
            let best = bestFiveCards(seven)
            XCTAssertEqual(eval5(best[0], best[1], best[2], best[3], best[4]),
                           evaluate7(seven))
        }
    }

    /// The row reads in the order a player compares hands: the made part first, then
    /// kickers high to low; straights from the top card down, the wheel's ace last.
    func testBestFiveReadsMostImportantCardFirst() {
        func ranks(_ text: String) -> [Int] { bestFiveCards(Card.parse(text)!).map(\.rank) }
        XCTAssertEqual(ranks("Tc3hKd3sQh7c2d"), [3, 3, 13, 12, 10])      // pair, kickers
        XCTAssertEqual(ranks("4c9hKd4s9sAc2d"), [9, 9, 4, 4, 14])        // two pair, higher first
        XCTAssertEqual(ranks("7c2h7dKs7sAc3d"), [7, 7, 7, 14, 13])       // trips
        XCTAssertEqual(ranks("Kc8h8d2sKs8cAd"), [8, 8, 8, 13, 13])       // full house
        XCTAssertEqual(ranks("5cQhQdQsQc9cAd"), [12, 12, 12, 12, 14])    // quads
        XCTAssertEqual(ranks("3dAd8dJd6d2cKs"), [14, 11, 8, 6, 3])       // flush
        XCTAssertEqual(ranks("6c9hTd7s8cAc2d"), [10, 9, 8, 7, 6])        // straight
        XCTAssertEqual(ranks("3cAh5d2s4cKcQd"), [5, 4, 3, 2, 14])        // wheel
        XCTAssertEqual(ranks("2c9hJd5sAc7c3d"), [14, 11, 9, 7, 5])       // high card
        XCTAssertEqual(ranks("5h9h6h8h7hAcAd"), [9, 8, 7, 6, 5])         // straight flush
    }
}
