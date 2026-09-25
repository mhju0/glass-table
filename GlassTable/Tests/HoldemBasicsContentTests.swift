import XCTest
import GlassTableEngine
@testable import GlassTable

final class HoldemBasicsContentTests: XCTestCase {
    /// Each ladder row's example must be the hand the row names, by the engine's rules.
    func testLadderExamplesAreTheHandsTheyName() {
        for rank in HoldemBasics.ladder {
            let brief = bestHandOfAny(rank.example)
            XCTAssertEqual(brief.category, rank.category, rank.id)
            if rank.category == 8 {
                XCTAssertEqual(brief.topRank == 14, rank.isRoyal, rank.id)
            }
        }
    }

    func testLadderRunsStrongestFirstAndCoversEveryCategory() {
        let categories = HoldemBasics.ladder.map(\.category)
        XCTAssertEqual(categories, [8, 8, 7, 6, 5, 4, 3, 2, 1, 0])
        XCTAssertEqual(HoldemBasics.ladder.map(\.share).reduce(0, +), 1, accuracy: 1e-12)
    }

    func testRarerHandsRankHigherExceptHighCard() {
        // The page says rarer means stronger. That holds down to one pair; high card is
        // rarer than one pair and two pair, so the page must not claim it for that row.
        let shares = HoldemBasics.ladder.dropLast().map(\.share)
        XCTAssertEqual(shares, shares.sorted())
    }

    func testWorkedHandIsAFlushThatLeavesTwoCardsOut() {
        XCTAssertEqual(HoldemBasics.bestBrief.category, 5)
        XCTAssertEqual(HoldemBasics.bestFive.count, 5)
        XCTAssertTrue(HoldemBasics.bestFive.allSatisfy { $0.suit == 2 })
        XCTAssertTrue(HoldemBasics.hole.allSatisfy(HoldemBasics.bestFive.contains))
    }

    func testPercentTextMatchesThePublishedRoundings() {
        let texts = HoldemBasics.ladder.map { HoldemBasics.percentText($0.share) }
        XCTAssertEqual(texts, ["0.0032%", "0.028%", "0.17%", "2.6%", "3.0%", "4.6%",
                               "4.8%", "23.5%", "43.8%", "17.4%"])
    }
}
