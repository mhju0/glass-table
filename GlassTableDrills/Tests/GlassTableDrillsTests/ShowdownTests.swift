import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class ShowdownTests: XCTestCase {
    private func spot(_ hero: String, _ villain: String, _ board: String) -> ShowdownSpot {
        ShowdownSpot(hero: Card.parse(hero)!, villain: Card.parse(villain)!,
                     board: Card.parse(board)!)
    }

    func testHigherPairWins() {
        // Hero KK vs villain QQ on a blank board.
        XCTAssertEqual(spot("KhKs", "QhQs", "2c7d9hJc4s").winner, 0)
        XCTAssertEqual(spot("QhQs", "KhKs", "2c7d9hJc4s").winner, 1)
    }

    func testFlushBeatsStraight() {
        XCTAssertEqual(spot("AhKh", "9s8s", "QhJh2h7c6d").winner, 0)
    }

    /// The case a lossy category+topRank comparison gets wrong: both players hold
    /// two pair with the same top pair, decided by the second pair.
    func testTwoPairIsDecidedBySecondPairNotJustTheTopPair() {
        // Board A-9-4. Hero A9 (aces and nines), villain A4 (aces and fours).
        let s = spot("Ac9c", "Ad4d", "As9h4h2s7d")
        XCTAssertEqual(s.heroBest.category, s.villainBest.category, "same category")
        XCTAssertEqual(s.heroBest.topRank, s.villainBest.topRank, "same top rank")
        XCTAssertEqual(s.winner, 0, "hero's nines must beat villain's fours")
    }

    /// The other lossy case: same made hand, decided by the kicker.
    func testKickerDecidesOtherwiseIdenticalPairs() {
        // Board K-7-2-5-9. Hero AK vs villain QK — both a pair of kings.
        let s = spot("AcKc", "QdKd", "Kh7s2d5c9h")
        XCTAssertEqual(s.heroBest, s.villainBest, "HandBrief cannot tell these apart")
        XCTAssertEqual(s.winner, 0, "ace kicker wins")
    }

    func testBoardThatPlaysIsAChop() {
        // Broadway on the board; both players' hole cards are irrelevant.
        let s = spot("2c3c", "4d5d", "AsKsQhJhTc")
        XCTAssertEqual(s.winner, 2)
        XCTAssertTrue(gradeShowdown(answer: 2, spot: s).whyText.contains("찹"))
    }

    func testCounterfeitedTwoPairLosesToTheBoard() {
        // Hero 3-2 made two pair on the flop, then the board counterfeited it:
        // board's own two pair (K-K, J-J) with an ace kicker plays bigger.
        let s = spot("3c2c", "Ad4d", "KhKsJdJc9h")
        XCTAssertEqual(s.winner, 1)
    }

    func testGeneratorIsDeterministicAndDealsLegalSpots() {
        XCTAssertEqual(ShowdownSpotGenerator.spot(baseSeed: 5, index: 9),
                       ShowdownSpotGenerator.spot(baseSeed: 5, index: 9))
        for i in 0..<300 {
            let s = ShowdownSpotGenerator.spot(baseSeed: 5, index: i)
            XCTAssertEqual(s.hero.count, 2)
            XCTAssertEqual(s.villain.count, 2)
            XCTAssertEqual(s.board.count, 5)
            XCTAssertEqual(Set(s.hero + s.villain + s.board).count, 9, "no duplicate cards")
            XCTAssertTrue((0...2).contains(s.winner))
        }
    }

    func testGeneratorProducesAllThreeOutcomesOverEnoughSpots() {
        var seen = Set<Int>()
        for i in 0..<600 { seen.insert(ShowdownSpotGenerator.spot(baseSeed: 5, index: i).winner) }
        XCTAssertEqual(seen, [0, 1, 2], "hero wins, villain wins, and chops must all occur")
    }

    func testGradingIsBinaryAndNamesBothHands() {
        let s = spot("KhKs", "QhQs", "2c7d9hJc4s")
        XCTAssertEqual(gradeShowdown(answer: 0, spot: s).band, .spotOn)
        XCTAssertEqual(gradeShowdown(answer: 1, spot: s).band, .off)
        XCTAssertEqual(gradeShowdown(answer: 2, spot: s).band, .off)
        let r = gradeShowdown(answer: 0, spot: s)
        XCTAssertEqual(r.heroName, "K 원 페어")
        XCTAssertEqual(r.villainName, "Q 원 페어")
    }

    /// The showdown reveal must name hands with the same function the outs reveal
    /// uses, or the app would describe one hand two different ways.
    func testHandNamingReusesTheShippedRevealNaming() {
        let s = spot("KhKs", "QhQs", "2c7d9hJc4s")
        XCTAssertEqual(gradeShowdown(answer: 0, spot: s).heroName, handName(s.heroBest))
    }
}
