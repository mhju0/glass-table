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
        XCTAssertTrue(showdownBoardPlays(s))
        let explanation = gradeShowdown(answer: 2, spot: s).whyText
        XCTAssertTrue(explanation.contains("공용 카드 다섯 장이"), explanation)
        XCTAssertTrue(explanation.contains("비겨요"), explanation)
    }

    func testChopCanRequireBothPlayersHoleCards() {
        // Both players use A-K with Q-J-10 to make the same ace-high straight.
        // The board alone is only queen-high, so calling this a board-play tie is false.
        let s = spot("AsKd", "AhKc", "QsJdTc3h2c")
        XCTAssertEqual(s.winner, 2)
        XCTAssertFalse(showdownBoardPlays(s))
        let explanation = gradeShowdown(answer: 2, spot: s).whyText
        XCTAssertTrue(explanation.contains("패의 세기가 같아서"), explanation)
        XCTAssertFalse(explanation.contains("공용 카드 다섯 장이"), explanation)
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

    // MARK: English hand names: capitalized as labels, lowercase inside a sentence

    private func brief(_ text: String) -> HandBrief { bestHandOfAny(Card.parse(text)!) }

    private let shapes = ["AhJc8s5d2c", "KhKs9d5c2h", "KhKs6d6c2h", "7c7d7hKs2d", "Tc9d8h7s6c",
                          "AdJd8d6d3d", "KsKhKd8c8s", "QsQhQdQc7s", "9h8h7h6h5h", "AsKsQsJsTs"]

    func testHandLabelsStayCapitalized() {
        XCTAssertEqual(shapes.map { DrillTerms.hand(brief($0), in: .english) },
                       ["A high", "Pair of Ks", "Two pair, K high", "Three 7s", "10-high straight",
                        "A-high flush", "Full house, Ks", "Four Qs", "9-high straight flush", "Royal flush"])
    }

    func testHandNamesAreLowercaseInsideASentence() {
        XCTAssertEqual(shapes.map { DrillTerms.handInSentence(brief($0), in: .english) },
                       ["A high", "pair of Ks", "two pair, K high", "three 7s", "10-high straight",
                        "A-high flush", "full house, Ks", "four Qs", "9-high straight flush", "royal flush"])
        for shape in shapes {
            XCTAssertEqual(DrillTerms.handInSentence(brief(shape), in: .korean), handName(brief(shape)))
        }
    }

    /// "two pair, K high" and "full house, Ks" carry an aside that a sentence going on
    /// past the name has to close.
    func testWinnerAsideIsClosedBeforeTheVerb() {
        XCTAssertEqual(gradeShowdown(answer: 0, spot: spot("Kc6d", "5d3h", "Qc6sKdJh3d"), language: .english).whyText,
                       "Your two pair, K high, beats the opponent's pair of 3s.")
        XCTAssertEqual(gradeShowdown(answer: 0, spot: spot("KsKh", "AhTh", "Kd8c8s4h2h"), language: .english).whyText,
                       "Your full house, Ks, beats the opponent's pair of 8s.")
        XCTAssertEqual(gradeShowdown(answer: 0, spot: spot("AhKh", "9s8s", "QhJh2h7cTd"), language: .english).whyText,
                       "Your A-high flush beats the opponent's Q-high straight.")
        XCTAssertEqual(gradeShowdown(answer: 0, spot: spot("KhKs", "QhQs", "2c7d9hJc4s"), language: .english).whyText,
                       "Your pair of Ks beats the opponent's pair of Qs.")
    }

    func testTieNamesTheHandInLowercase() {
        XCTAssertEqual(gradeShowdown(answer: 2, spot: spot("2c3d", "4h5c", "AsKsQsJsTs"), language: .english).whyText,
                       "The five shared cards make the best hand for both players: royal flush. It is a tie.")
        XCTAssertEqual(gradeShowdown(answer: 2, spot: spot("Kc6d", "Kd6h", "KhQc6s9d3c"), language: .english).whyText,
                       "Both players make equally strong five-card hands: two pair, K high. It is a tie.")
    }

    func testKoreanWhyIsUnchanged() {
        XCTAssertEqual(gradeShowdown(answer: 0, spot: spot("Kc6d", "5d3h", "Qc6sKdJh3d")).whyText,
                       "내 K 투 페어가 상대 3 원 페어를 이겨요.")
    }
}
