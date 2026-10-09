import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class FirstLessonTests: XCTestCase {
    func testBothFirstLessonHandsAreLegalAndHeroWinsWithTheNamedPair() {
        for (spot, expectedWinner, expectedName) in [(FirstLesson.example, 0, "A 원 페어"),
                                                     (FirstLesson.transfer, 1, "10 원 페어")] {
            let cards = spot.hero + spot.villain + spot.board
            XCTAssertEqual(cards.count, 9)
            XCTAssertEqual(Set(cards).count, cards.count)
            XCTAssertEqual(spot.winner, expectedWinner)
            let winningHand = expectedWinner == 0 ? spot.heroBest : spot.villainBest
            XCTAssertEqual(handName(winningHand), expectedName)
            XCTAssertNotEqual(handName(spot.heroBest), handName(spot.villainBest))
        }
    }

    func testFirstLessonFeedbackComesFromTheShowdownGrader() {
        let correct = gradeShowdown(answer: 0, spot: FirstLesson.example)
        let incorrect = gradeShowdown(answer: 0, spot: FirstLesson.transfer)

        XCTAssertEqual(correct.band, .spotOn)
        XCTAssertEqual(incorrect.band, .off)
        XCTAssertTrue(correct.whyText.contains("A 원 페어"))
        XCTAssertTrue(incorrect.whyText.contains("10 원 페어"))
    }
    func testOptionalComparisonsAreLegalAndTeachIncreasingCategories() {
        for (spot, categories) in zip(FirstLesson.comparisons, [(3, 1), (4, 3), (5, 4)]) {
            XCTAssertEqual(Set(spot.hero + spot.villain + spot.board).count, 9)
            XCTAssertEqual(spot.heroBest.category, categories.0)
            XCTAssertEqual(spot.villainBest.category, categories.1)
            XCTAssertEqual(spot.winner, 0)
            XCTAssertEqual(bestFiveCards(spot.hero + spot.board).count, 5)
        }
    }

    func testRepeatedGuideVariationStaysStableAndPreservesPairRule() {
        for seed in UInt64(0)..<16 {
            XCTAssertEqual(FirstLesson.comparisonOrder(seed: seed), FirstLesson.comparisonOrder(seed: seed))
            for transfer in [false, true] {
                let spot = FirstLesson.pairExample(seed: seed, transfer: transfer)
                XCTAssertEqual(Set(spot.hero + spot.villain + spot.board).count, 9)
                XCTAssertEqual(spot.heroBest.category, 1)
                XCTAssertEqual(spot.villainBest.category, 1)
                XCTAssertNotEqual(spot.winner, 2)
            }
        }
        XCTAssertNotEqual(FirstLesson.pairExample(seed: 0, transfer: false),
                          FirstLesson.pairExample(seed: 1, transfer: false))
    }
    func testRequiredPathContainsAllFiveRulesWithoutOptionalPractice() {
        for seed in UInt64(0)..<18 {
            let path = FirstLesson.requiredComparisons(seed: seed)
            XCTAssertEqual(path.map(\.rule), [.pairOverHighCard, .higherPair, .trips, .straight, .flush])
            XCTAssertEqual(path, FirstLesson.requiredComparisons(seed: seed))
            for comparison in path {
                let cards = comparison.spot.hero + comparison.spot.villain + comparison.spot.board
                XCTAssertEqual(cards.count, 9)
                XCTAssertEqual(Set(cards).count, 9)
                XCTAssertNotEqual(comparison.spot.winner, 2)
            }
        }
    }

    func testCuratedBanksHaveSemanticVarietyAndEvaluatorConfirmedRules() {
        for rule in FirstLesson.Rule.allCases {
            let variants = FirstLesson.bank(for: rule)
            XCTAssertEqual(variants.count, 3)
            let rankStructures = variants.map { ($0.hero + $0.villain + $0.board).map(\.rank) }
            XCTAssertEqual(Set(rankStructures).count, 3, "Repeat variety must change ranks, not only suits.")
            for spot in variants {
                XCTAssertEqual(Set(spot.hero + spot.villain + spot.board).count, 9)
                let categories = [spot.heroBest.category, spot.villainBest.category].sorted()
                switch rule {
                case .pairOverHighCard: XCTAssertEqual(categories, [0, 1])
                case .higherPair: XCTAssertEqual(categories, [1, 1])
                case .trips:
                    XCTAssertEqual(spot.heroBest.category, 3)
                    XCTAssertTrue([1, 2].contains(spot.villainBest.category))
                case .straight: XCTAssertEqual(categories, [3, 4])
                case .flush: XCTAssertEqual(categories, [4, 5])
                }
                if rule != .higherPair { XCTAssertEqual(spot.winner, 0) }
                else {
                    let winner = spot.winner == 0 ? spot.heroBest : spot.villainBest
                    let loser = spot.winner == 0 ? spot.villainBest : spot.heroBest
                    XCTAssertGreaterThan(winner.topRank, loser.topRank)
                }
                XCTAssertEqual(gradeShowdown(answer: spot.winner, spot: spot).band, .spotOn)
            }
        }
        XCTAssertNotEqual(FirstLesson.requiredComparisons(seed: 0), FirstLesson.requiredComparisons(seed: 1))
    }

}
