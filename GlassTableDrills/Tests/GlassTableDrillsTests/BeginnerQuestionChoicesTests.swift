import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class BeginnerQuestionChoicesTests: XCTestCase {
    func testNumericChoicesRemainLegalDistinctAndContainAnswerAtBoundaries() {
        for answer in [0, 1, 50, 99, 100] {
            for seed in UInt64(0)..<20 {
                let choices = BeginnerQuestionChoices.integers(answer: answer, bounds: 0...100, seed: seed)
                XCTAssertEqual(choices.count, 3)
                XCTAssertEqual(Set(choices).count, 3)
                XCTAssertTrue(choices.contains(answer))
                XCTAssertTrue(choices.allSatisfy { (0...100).contains($0) })
                XCTAssertEqual(choices, BeginnerQuestionChoices.integers(answer: answer, bounds: 0...100, seed: seed))
            }
        }
        XCTAssertEqual(Set(BeginnerQuestionChoices.integers(answer: 0, bounds: 0...1, seed: 9)), [0, 1])
    }

    func testPercentChoicesHaveMeaningfullyDifferentDisplayedValues() {
        for answer in [0.0, 1, 50, 99, 100] {
            for seed in UInt64(0)..<20 {
                let choices = BeginnerQuestionChoices.percentages(answer: answer, seed: seed)
                XCTAssertEqual(choices.count, 3)
                XCTAssertEqual(Set(choices).count, 3)
                XCTAssertTrue(choices.contains(answer))
                XCTAssertTrue(choices.allSatisfy { $0 == answer || abs($0 - answer) >= 15 })
            }
        }
    }

    func testRangeChoicesIncludeAnAttainableOnTargetAnswer() {
        for archetype in Archetype.allCases {
            for seat in RFIChart.seats {
                for action in [RangeReadSpot.Action.opened(seat), .called(seat: seat, opener: .utg)] {
                    let spot = RangeReadSpot(archetype: archetype, action: action, archetypeShown: true)
                    let choices = BeginnerQuestionChoices.rangeEstimates(spot: spot, seed: 9)
                    XCTAssertEqual(choices.count, 3)
                    XCTAssertEqual(Set(choices.map { Int($0.width.rounded()) }).count, 3, "\(archetype) \(seat) \(action)")
                    XCTAssertTrue(choices.allSatisfy {
                        SavedDrillInput.rangeBand(width: $0.width, excludedTop: $0.excludedTop, tendencies: []).isValid(for: .rangeRead)
                    }, "\(archetype) \(seat) \(action)")
                    XCTAssertEqual(choices.filter { gradeRangeRead(estimate: $0, spot: spot).band == .spotOn }.count, 1,
                                   "\(archetype) \(seat) \(action)")
                }
            }
        }
    }

    func testDefendSessionSeedCoversEveryActualGradedAction() {
        for seed in UInt64(0)..<100 {
            let selected = LessonSessionSeed.variedDefend(seed)
            let actions = Set((2...4).map { DefendSpotGenerator.spot(baseSeed: selected, index: $0).correct })
            XCTAssertEqual(actions, Set(DefendAction.allCases))
            XCTAssertEqual(selected, LessonSessionSeed.variedDefend(seed))
        }
    }

    func testOutsGroupingKeepsKickersAndOpponentOutcomeSeparate() {
        let hero = Card.parse("AhKh")!, villain = Card.parse("QsQd")!
        let board = Card.parse("Qh7h2s3c")!
        let candidates = Card.parse("4h5h6h8h9hThJh2h3h")!
        let groups = OutsOutcomeGroups.make(hero: hero, villain: villain, board: board, candidates: candidates)
        XCTAssertEqual(Set(groups.flatMap(\.cards)), Set(candidates))
        // All seven safe hearts are ace-high flushes, but their full kickers differ.
        XCTAssertEqual(groups.filter { $0.winner == 0 }.count, 7)
        XCTAssertEqual(groups.filter { $0.winner == 1 }.count, 2)
        for group in groups {
            for river in group.cards {
                let spot = ShowdownSpot(hero: hero, villain: villain, board: board + [river])
                XCTAssertEqual(group.winner, spot.winner)
                XCTAssertEqual(group.heroRanks, bestFiveCards(hero + spot.board).map(\.rank).sorted(by: >))
                XCTAssertEqual(group.villainRanks, bestFiveCards(villain + spot.board).map(\.rank).sorted(by: >))
            }
        }
    }

    func testEquivalentSuitOutcomesGroupWithoutDroppingSuits() {
        let groups = OutsOutcomeGroups.make(hero: Card.parse("AsAd")!, villain: Card.parse("KsKd")!,
            board: Card.parse("2c4d7h9s")!, candidates: Card.parse("QcQhQs")!)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.cards, Card.parse("QsQhQc")!)
        XCTAssertEqual(groups.first?.winner, 0)
    }

    func testGroupsComeStrongestHandFirstWithCardsAceFirst() {
        // Hero holds 9h8h on Th 7c 2h 2s: a jack or six makes a straight, a heart a flush.
        let hero = Card.parse("9h8h")!, villain = Card.parse("AsKd")!, board = Card.parse("Th7c2h2s")!
        let groups = OutsOutcomeGroups.make(hero: hero, villain: villain, board: board,
            candidates: countOuts(hero: hero, villain: villain, board: board))
        XCTAssertEqual(groups.map(\.heroCategory), groups.map(\.heroCategory).sorted(by: >))
        XCTAssertGreaterThan(Set(groups.map(\.heroCategory)).count, 1)
        for group in groups {
            XCTAssertEqual(group.cards.map(\.rank), group.cards.map(\.rank).sorted(by: >))
        }
    }
}
