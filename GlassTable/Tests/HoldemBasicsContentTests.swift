import XCTest
import GlassTableEngine
import GlassTableDrills
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

    /// The ladder names a pair the way every reveal does ("J 원 페어"), with the space.
    func testLadderPairNamesMatchTheRevealNames() {
        for rank in HoldemBasics.ladder where rank.category == 1 || rank.category == 2 {
            XCTAssertTrue(handName(bestHandOfAny(rank.example)).hasSuffix(" " + rank.korean), rank.id)
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

    func testGuideHandIsAPairOfKingsThatLeavesTwoSharedCardsOut() {
        XCTAssertEqual(HoldemBasics.bestBrief.category, 1)
        XCTAssertEqual(HoldemBasics.bestBrief.topRank, 13)
        XCTAssertEqual(HoldemBasics.bestFive.count, 5)
        XCTAssertTrue(HoldemBasics.hole.allSatisfy(HoldemBasics.bestFive.contains))
        XCTAssertEqual(Set(HoldemBasics.seven.filter { !HoldemBasics.bestFive.contains($0) }),
                       Set(Card.parse("7c2h")!))
    }

    /// The first check is dealt from seven cards: my flush and the opponent's straight,
    /// each using both private cards, with no pair and no board-only hand to confuse it.
    func testFirstCheckIsAFlushAgainstAStraightFromSevenCards() {
        let spot = HoldemBasics.firstCheck
        XCTAssertEqual(spot.heroBest.category, 5)
        XCTAssertEqual(spot.villainBest.category, 4)
        XCTAssertEqual(spot.winner, 0)
        XCTAssertEqual(bestHandOfAny(spot.board).category, 0, "The board alone is only a high card")
        for hole in [spot.hero, spot.villain] {
            XCTAssertTrue(hole.allSatisfy(bestFiveCards(hole + spot.board).contains))
            XCTAssertEqual(Set((hole + spot.board).map(\.rank)).count, 7, "No pair anywhere")
        }
    }

    func testFrequencyTextRoundsOneInNToTwoSignificantFigures() {
        let english = HoldemBasics.ladder.map { HoldemBasics.frequencyText($0.share, in: .english) }
        XCTAssertEqual(english, ["1 in 31,000 hands", "1 in 3,600 hands", "1 in 600 hands",
                                 "1 in 39 hands", "1 in 33 hands", "1 in 22 hands", "1 in 21 hands",
                                 "1 in 4.3 hands", "1 in 2.3 hands", "1 in 5.7 hands"])
        XCTAssertEqual(HoldemBasics.frequencyText(HoldemBasics.rank("royal").share, in: .korean),
                       "31,000판에 한 번")
        XCTAssertEqual(HoldemBasics.frequencyText(HoldemBasics.rank("pair").share, in: .korean),
                       "2.3판에 한 번")
    }

    /// The check's answer names the winning hand mid-sentence, so English lowercases it
    /// while the choice buttons keep the capitalized label.
    func testCheckAnswerNamesTheWinnerInLowercase() {
        XCTAssertEqual(HoldemBasics.checkFlush.name(in: .english), "Flush")
        XCTAssertEqual(HoldemBasics.answerText(winner: HoldemBasics.checkFlush, in: .english),
                       "The flush wins. Compare the hand types first; when they match, compare the combination’s ranks. Suits have no ranking.")
        XCTAssertEqual(HoldemBasics.answerText(winner: HoldemBasics.checkFlush, in: .korean),
                       "플러시 쪽이 이겨요. 먼저 족보를 비교하고, 같은 족보라면 조합을 만든 숫자부터 비교해요. 무늬에는 우열이 없어요.")
        XCTAssertEqual(HoldemBasics.ladder.map { $0.sentenceName(in: .english) },
                       ["royal flush", "straight flush", "four of a kind", "full house", "flush", "straight",
                        "three of a kind", "two pair", "one pair", "high card"])
        let five = Card.parse("KcKd6d6sQc")!
        let twoPair = HoldemBasics.checkRank(id: "check-0", hand: bestHandOfAny(five), example: five)
        XCTAssertEqual(twoPair.name(in: .english), "Two pair, K high")
        XCTAssertTrue(HoldemBasics.answerText(winner: twoPair, in: .english).hasPrefix("The two pair, K high, wins. "))
        XCTAssertTrue(HoldemBasics.answerText(winner: twoPair, in: .korean).hasPrefix("K 투 페어 쪽이 이겨요. "))
    }

    /// The third check (owner, 2026-10-17): both play the same pair of Js, and the
    /// engine settles it on A♠ against Q♦, the kicker the duel panel shows.
    func testKickerCheckIsTheSamePairSettledByTheKicker() {
        let spot = HoldemBasics.kickerCheck
        XCTAssertEqual(spot.heroBest, spot.villainBest)
        XCTAssertEqual(spot.heroBest, HandBrief(category: 1, topRank: 11))
        let pair = BestFivePair(spot)
        XCTAssertEqual(pair.winner, 0)
        XCTAssertEqual(pair.first.deciding, Card.parse("As")!)
        XCTAssertEqual(pair.second.deciding, Card.parse("Qd")!)
        XCTAssertEqual(Set(HoldemBasics.pairCards(pair.first)), Set(Card.parse("JhJs")!))
        XCTAssertEqual(Set(HoldemBasics.pairCards(pair.second)), Set(Card.parse("JcJs")!))
        XCTAssertEqual(HoldemBasics.samePairLine(pair.first, in: .korean), "J 페어는 같아요")
        XCTAssertEqual(HoldemBasics.samePairLine(pair.first, in: .english), "The pair of Js is the same")
        XCTAssertEqual(pair.why(in: .korean), "둘 다 J 원 페어예요. 키커가 승부를 갈랐어요. 내 A, 상대 Q라서 내 쪽이 이겨요.")
        XCTAssertEqual(pair.why(in: .english), "Both have a pair of Js. The kicker decides it: your A beats the opponent's Q.")
    }
}
