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
}
