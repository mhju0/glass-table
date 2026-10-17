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

    func testShareChoicesOfferExactlyOneAnswerThatGradesRight() {
        // Pot odds and MDF accept 2.5 points either side, so a choice 1 or 2 away
        // would be a second right answer.
        for seed in UInt64(0)..<200 {
            for index in 0..<10 {
                let spot = BetSpotGenerator.spot(baseSeed: seed, index: index)
                let odds = BeginnerQuestionChoices.shares(answer: spot.requiredPct, seed: seed &+ UInt64(index))
                XCTAssertEqual(odds.count, 3)
                XCTAssertEqual(odds.filter { gradePotOdds(estimatePct: $0, spot: spot).band == .spotOn }.count, 1,
                               "pot odds \(spot) \(odds)")
                let mdf = BeginnerQuestionChoices.shares(answer: spot.mdfPct, seed: seed &+ UInt64(index))
                XCTAssertEqual(mdf.filter { gradeMDF(estimatePct: $0, spot: spot).band == .spotOn }.count, 1,
                               "MDF \(spot) \(mdf)")
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

    /// The reveal groups winning rivers by the hand they make for me, not by exact
    /// ranks: A♥ J♥ against 6♦ K♦ on 5♠ 9♣ Q♥ K♥ has fifteen outs in four kinds of
    /// hand, though the flushes alone differ in kickers and in what the opponent makes.
    func testOutsGroupByMyHandCategory() {
        let spot = OutsSpotGenerator.spot(baseSeed: 24500, index: 4)
        XCTAssertEqual(Set(spot.hero), Set(Card.parse("AhJh")!))
        let groups = OutsOutcomeGroups.make(hero: spot.hero, villain: spot.villain, board: spot.board,
                                            candidates: spot.outs)
        XCTAssertEqual(groups.map(\.cards.count), [1, 8, 3, 3])
        XCTAssertEqual(groups.map(\.category), [8, 5, 4, 1])
        XCTAssertEqual(groups.map(\.isRoyal), [true, false, false, false])
        XCTAssertEqual(groups.first?.cards, Card.parse("Th")!)
        XCTAssertEqual(Set(groups.flatMap(\.cards)), Set(spot.outs))
    }

    func testEquivalentSuitOutcomesGroupWithoutDroppingSuits() {
        let groups = OutsOutcomeGroups.make(hero: Card.parse("AsAd")!, villain: Card.parse("KsKd")!,
            board: Card.parse("2c4d7h9s")!, candidates: Card.parse("QcQhQs")!)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.cards, Card.parse("QsQhQc")!)
        XCTAssertEqual(groups.first?.category, 1)
    }

    func testGroupsComeStrongestHandFirstWithCardsAceFirst() {
        // Hero holds 9h8h on Th 7c 2h 2s: a jack or six makes a straight, a heart a flush.
        let hero = Card.parse("9h8h")!, villain = Card.parse("AsKd")!, board = Card.parse("Th7c2h2s")!
        let groups = OutsOutcomeGroups.make(hero: hero, villain: villain, board: board,
            candidates: countOuts(hero: hero, villain: villain, board: board))
        XCTAssertEqual(groups.map(\.category), groups.map(\.category).sorted(by: >))
        XCTAssertEqual(Set(groups.map(\.category)).count, groups.count, "One group per kind of hand")
        for group in groups {
            XCTAssertEqual(group.cards.map(\.rank), group.cards.map(\.rank).sorted(by: >))
        }
    }
}
