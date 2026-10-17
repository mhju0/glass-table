import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class BestFivePairTests: XCTestCase {
    private func cards(_ text: String) -> [Card] { Card.parse(text)! }

    private func spot(_ hero: String, _ villain: String, _ board: String) -> ShowdownSpot {
        ShowdownSpot(hero: cards(hero), villain: cards(villain), board: cards(board))
    }

    // MARK: The owner's example: K two pair against a pair of threes

    func testExampleUsesBothHoleCardsAgainstOne() {
        let pair = BestFivePair(spot("Kc6d", "5d3h", "Qc6sKdJh3d"))
        XCTAssertEqual(pair.winner, 0)
        XCTAssertFalse(pair.boardPlays)
        XCTAssertEqual(Set(pair.first.used), Set(cards("KcKd6d6sQc")))
        XCTAssertEqual(pair.first.holeCardsUsed, 2)
        XCTAssertEqual(pair.first.boardCardsUsed, 3)
        XCTAssertEqual(Set(pair.second.used), Set(cards("3h3dKdQcJh")))
        XCTAssertEqual(pair.second.holeCardsUsed, 1)
        XCTAssertEqual(pair.second.boardCardsUsed, 4)
        XCTAssertEqual(pair.first.unused.count, 2)
        XCTAssertEqual(Set(pair.second.unused), Set(cards("5d6s")))
    }

    func testExampleNamesHandsAndCounts() {
        let pair = BestFivePair(spot("Kc6d", "5d3h", "Qc6sKdJh3d"))
        XCTAssertEqual(pair.first.name(in: .korean), "K 투 페어")
        XCTAssertEqual(pair.second.name(in: .korean), "3 원 페어")
        XCTAssertEqual(pair.first.countLine(in: .korean), "내 카드 2장 · 공용 카드 3장")
        XCTAssertEqual(pair.second.countLine(in: .korean), "상대 카드 1장 · 공용 카드 4장")
        XCTAssertEqual(pair.first.countLine(in: .english), "2 of your cards · 3 board cards")
        XCTAssertEqual(pair.second.countLine(in: .english), "1 of the opponent's cards · 4 board cards")
    }

    func testDifferentHandNamesRingNothing() {
        let pair = BestFivePair(spot("Kc6d", "5d3h", "Qc6sKdJh3d"))
        XCTAssertTrue(pair.first.deciding.isEmpty)
        XCTAssertTrue(pair.second.deciding.isEmpty)
    }

    /// The line under the rows is the reveal's own sentence, word for word.
    func testWhyIsTheRevealSentenceWhenAPlayerWins() {
        let s = spot("Kc6d", "5d3h", "Qc6sKdJh3d")
        for language in [LearningLanguage.korean, .english] {
            XCTAssertEqual(BestFivePair(s).why(in: language),
                           gradeShowdown(answer: 0, spot: s, language: language).whyText)
        }
        XCTAssertEqual(BestFivePair(s).why(in: .korean), "내 K 투 페어가 상대 3 원 페어를 이겨요.")
        XCTAssertEqual(BestFivePair(s).why(in: .english), "Your two pair, K high, beats the opponent's pair of 3s.")
    }

    // MARK: A kicker decides

    func testKickerIsRingedOnBothRows() {
        // Both a pair of kings; the ace beats the queen.
        let pair = BestFivePair(spot("AcKc", "QdKd", "Kh7s2d5c9h"))
        XCTAssertEqual(pair.winner, 0)
        XCTAssertEqual(pair.first.deciding, cards("Ac"))
        XCTAssertEqual(pair.second.deciding, cards("Qd"))
        XCTAssertTrue(pair.why(in: .korean).contains("키커"))
        XCTAssertTrue(pair.why(in: .english).contains("kicker"))
    }

    func testOpponentKickerIsRingedWhenTheOpponentWins() {
        let pair = BestFivePair(spot("QdKd", "AcKc", "Kh7s2d5c9h"))
        XCTAssertEqual(pair.winner, 1)
        XCTAssertEqual(pair.first.deciding, cards("Qd"))
        XCTAssertEqual(pair.second.deciding, cards("Ac"))
    }

    /// Same top pair; the second pair decides, so both its cards are ringed.
    func testSecondPairIsRingedWhenItDecides() {
        let pair = BestFivePair(spot("Ac9c", "Ad4d", "As9h4h2s7d"))
        XCTAssertEqual(Set(pair.first.deciding), Set(cards("9c9h")))
        XCTAssertEqual(Set(pair.second.deciding), Set(cards("4d4h")))
    }

    /// Ranks must be compared in the order the hands are compared (pairs before
    /// kickers), not sorted high to low: K-K-6-6-5 beats K-K-5-5-Q on the sixes,
    /// not on a six against a queen.
    func testDecidingRankFollowsComparisonOrderNotHighCardOrder() {
        let s = spot("6h6c", "Qd5d", "KsKh5c2d3h")
        let pair = BestFivePair(s)
        XCTAssertEqual(pair.winner, 0)
        XCTAssertEqual(Set(pair.first.deciding), Set(cards("6h6c")))
        XCTAssertEqual(Set(pair.second.deciding), Set(cards("5d5c")))
        let ko = gradeShowdown(answer: 0, spot: s, language: .korean).whyText
        XCTAssertTrue(ko.contains("내 6 페어, 상대 5 페어라서"), ko)
        let en = gradeShowdown(answer: 0, spot: s, language: .english).whyText
        XCTAssertTrue(en.contains("your 6s beat the opponent's 5s"), en)
    }

    /// The word kicker names a leftover card. When the second pair of two pair decides,
    /// the sentence names that pair instead (J-J-9-9 against J-J-6-6).
    func testSecondPairDecidingIsNotCalledAKicker() {
        let s = spot("9hQc", "6d6s", "JhJs2h3d9s")
        let pair = BestFivePair(s)
        XCTAssertEqual(pair.winner, 0)
        XCTAssertEqual(pair.why(in: .korean),
                       "둘 다 J 투 페어예요. 두 번째 페어가 승부를 갈랐어요. 내 9 페어, 상대 6 페어라서 내 쪽이 이겨요.")
        XCTAssertEqual(pair.why(in: .english),
                       "Both have two pair, Js up. The second pair decides it: your 9s beat the opponent's 6s.")
    }

    /// Two full houses on the same three: the pair decides, not a kicker.
    func testFullHousePairDecidingIsNotCalledAKicker() {
        let s = spot("9c9d", "7c7d", "5s5h5d2c3h")
        let pair = BestFivePair(s)
        XCTAssertEqual(pair.winner, 0)
        XCTAssertEqual(pair.why(in: .korean),
                       "둘 다 5 풀하우스예요. 함께 쓰는 페어가 승부를 갈랐어요. 내 9, 상대 7이라서 내 쪽이 이겨요.")
        XCTAssertEqual(pair.why(in: .english),
                       "Both have a full house of 5s. The pair decides it: your 9s beat the opponent's 7s.")
    }

    /// Same two pair, the fifth card decides: the hand reads "Qs up" like the second-pair case.
    func testTwoPairKickerSentenceNamesTheTopPairUp() {
        let pair = BestFivePair(spot("AcQd", "KcQh", "QsJhJd5c3s"))
        XCTAssertEqual(pair.winner, 0)
        XCTAssertEqual(pair.why(in: .english),
                       "Both have two pair, Qs up. The kicker decides it: your A beats the opponent's K.")
    }

    /// The ten reads "10" as on the card face, pluralised like the other ranks.
    func testSameHandSentenceNamesTheTenAsOnTheCardFace() {
        XCTAssertEqual(BestFivePair(spot("9hQc", "6d6s", "ThTs2h3d9s")).why(in: .english),
                       "Both have two pair, 10s up. The second pair decides it: your 9s beat the opponent's 6s.")
        XCTAssertEqual(BestFivePair(spot("9c9d", "7c7d", "TsThTd2c3h")).why(in: .english),
                       "Both have a full house of 10s. The pair decides it: your 9s beat the opponent's 7s.")
    }

    /// The spot the Hold'em basics teaches the kicker with: the same pair of jacks,
    /// the ace beats the queen.
    func testBasicsKickerSpotNamesTheKicker() {
        let pair = BestFivePair(spot("AsJh", "QdJc", "Js8d5c3h2s"))
        XCTAssertEqual(pair.winner, 0)
        XCTAssertEqual(pair.first.deciding, cards("As"))
        XCTAssertEqual(pair.second.deciding, cards("Qd"))
        XCTAssertEqual(pair.why(in: .korean), "둘 다 J 원 페어예요. 키커가 승부를 갈랐어요. 내 A, 상대 Q라서 내 쪽이 이겨요.")
    }

    /// "6라서" reads 육라서; a rank read with a final consonant takes 이라서.
    func testKickerSentenceParticleFollowsTheRankReading() {
        let s = spot("Ac7c", "Ad6d", "AsKh9c4d2h")
        let ko = gradeShowdown(answer: 0, spot: s, language: .korean).whyText
        XCTAssertTrue(ko.contains("상대 6이라서"), ko)
    }

    // MARK: Board plays

    func testBoardPlaysLightsTheSameFiveBoardCardsOnBothRows() {
        let s = spot("2c3c", "4d5d", "AsKsQhJhTc")
        let pair = BestFivePair(s)
        XCTAssertEqual(pair.winner, 2)
        XCTAssertTrue(pair.boardPlays)
        XCTAssertEqual(Set(pair.first.used), Set(s.board))
        XCTAssertEqual(Set(pair.second.used), Set(s.board))
        XCTAssertEqual(pair.first.countLine(in: .korean), "내 카드 0장 · 공용 카드 5장")
        XCTAssertEqual(pair.why(in: .korean), "둘 다 공용 카드 다섯 장을 써서 팟을 나눠요.")
        XCTAssertEqual(pair.why(in: .english), "You both play the board, so the pot is split.")
        XCTAssertTrue(pair.first.deciding.isEmpty && pair.second.deciding.isEmpty)
    }

    /// A hole card that only duplicates a board card's rank does not count as used:
    /// the board's own five play.
    func testBoardPlaysEvenWhenAHoleCardMatchesABoardRank() {
        let s = spot("Qd2c", "Qs3c", "AhAdKcKsQc")
        let pair = BestFivePair(s)
        XCTAssertTrue(pair.boardPlays)
        XCTAssertEqual(pair.first.holeCardsUsed, 0)
        XCTAssertEqual(pair.second.holeCardsUsed, 0)
    }

    func testTieWithHoleCardsKeepsEachPlayersOwnFive() {
        let s = spot("AsKd", "AhKc", "QsJdTc3h2c")
        let pair = BestFivePair(s)
        XCTAssertEqual(pair.winner, 2)
        XCTAssertFalse(pair.boardPlays)
        XCTAssertEqual(pair.first.holeCardsUsed, 2)
        XCTAssertEqual(pair.why(in: .korean), gradeShowdown(answer: 2, spot: s, language: .korean).whyText)
    }

    // MARK: Named seats (free table)

    func testNamedSeatsWordTheCountAndWhyLines() {
        let tom = BestFiveOwner.seat(korean: "토마스", english: "Tom")
        let mike = BestFiveOwner.seat(korean: "마이클", english: "Mike")
        let pair = BestFivePair(first: cards("AcKc"), firstOwner: tom,
                                second: cards("QdKd"), secondOwner: mike, board: cards("Kh7s2d5c9h"))
        XCTAssertEqual(pair.first.countLine(in: .korean), "토마스의 카드 2장 · 공용 카드 3장")
        XCTAssertEqual(pair.first.countLine(in: .english), "2 of Tom's cards · 3 board cards")
        XCTAssertEqual(pair.why(in: .korean),
                       "둘 다 K 원 페어예요. 키커가 승부를 갈랐어요. 토마스의 A, 마이클의 Q라서 토마스 쪽이 이겨요.")
        XCTAssertEqual(pair.why(in: .english),
                       "Both have a pair of Ks. The kicker decides it: Tom's A beats Mike's Q.")
    }

    func testTwoSeatsPlayingTheBoardAreNotAddressedAsYou() {
        let pair = BestFivePair(first: cards("2c3c"), firstOwner: .seat(korean: "토마스", english: "Tom"),
                                second: cards("4d5d"), secondOwner: .seat(korean: "마이클", english: "Mike"),
                                board: cards("AsKsQhJhTc"))
        XCTAssertEqual(pair.why(in: .english), "Both players play the board, so the pot is split.")
    }

    // MARK: Free table: the winner and whoever came closest

    private func review(holes: [String], board: String, pots: [PracticePot]) -> PracticeTableReview {
        PracticeTableReview(settlementID: "s", handID: "h",
                            board: cards(board).map(\.description),
                            holeCards: holes.map { cards($0).map(\.description) },
                            contributions: holes.map { _ in 0 }, refunds: holes.map { _ in 0 },
                            payouts: holes.map { _ in 0 }, pots: pots, events: [],
                            startingStacks: holes.map { _ in 0 }, endingStacks: holes.map { _ in 0 },
                            learnerEnteredVoluntarily: true, learnerRaisedPreflop: false)
    }

    func testShowdownPairIsTheWinnerAndTheClosestRival() {
        // Seat 2 wins with trips; seat 0's two pair is closer than seat 3's pair.
        let r = review(holes: ["Kc6d", "2h4s", "QdQh", "5d3h"], board: "Qc6sKdJh3d",
                       pots: [PracticePot(amount: 100, eligibleSeats: [0, 2, 3], winners: [2])])
        let pair = r.bestFiveShowdownPair
        XCTAssertEqual(pair?.winner, 2)
        XCTAssertEqual(pair?.rival, 0)
    }

    func testShowdownPairPutsTheLearnerFirstInASplit() {
        let r = review(holes: ["2c3c", "4d5d"], board: "AsKsQhJhTc",
                       pots: [PracticePot(amount: 100, eligibleSeats: [0, 1], winners: [1, 0])])
        XCTAssertEqual(r.bestFiveShowdownPair?.winner, 0)
        XCTAssertEqual(r.bestFiveShowdownPair?.rival, 1)
    }

    func testNoShowdownPairWithoutAShowdown() {
        let r = review(holes: ["Kc6d", "5d3h"], board: "Qc6sKdJh3d",
                       pots: [PracticePot(amount: 100, eligibleSeats: [1], winners: [1])])
        XCTAssertNil(r.bestFiveShowdownPair)
        let early = review(holes: ["Kc6d", "5d3h"], board: "Qc6sKd",
                           pots: [PracticePot(amount: 100, eligibleSeats: [0, 1], winners: [0])])
        XCTAssertNil(early.bestFiveShowdownPair)
    }
}
