// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// What each step of the first three skills deals (D53). The first step is frozen by
/// `LearnSpotGoldenTests`; these check the properties the later steps promise.
final class StepLevelSpotTests: XCTestCase {
    private let seeds: [UInt64] = [0, 7, 0x9E37_79B9_7F4A_7C15, 123_456_789]

    private func holeCardsUsed(_ hole: [Card], board: [Card]) -> Int {
        bestFiveCards(hole + board).filter(hole.contains).count
    }

    func testOnlyTheFirstThreeSkillsHaveSteps() {
        for concept in Concept.allCases {
            let expected: DrillLevel = [.showdown, .potMath, .callFold,
                                        .position, .rfi, .defend, .rangeRead, .actionRead]
                .contains(concept) ? .sharp : .learn
            XCTAssertEqual(DrillLevel.highest(for: concept), expected, concept.rawValue)
        }
        XCTAssertEqual(DrillLevel.sharp.capped(for: .outs), .learn)
        XCTAssertEqual(DrillLevel.apply.capped(for: .showdown), .apply)
    }

    func testEveryApplyShowdownSharesACategoryAndIsDecidedByACard() {
        for seed in seeds {
            for index in 0..<40 {
                let spot = ShowdownSpotGenerator.spot(baseSeed: seed, index: index, level: .apply)
                XCTAssertEqual(spot.heroBest.category, spot.villainBest.category, "\(seed)/\(index)")
                XCTAssertNotEqual(spot.winner, 2, "a tie is a third-step spot")
            }
        }
    }

    func testEverySharpShowdownIsATieOrABoardThatPlaysWithinOneCategory() {
        var ties = 0
        for seed in seeds {
            for index in 0..<40 {
                let spot = ShowdownSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                XCTAssertEqual(spot.heroBest.category, spot.villainBest.category, "category never decides")
                let unused = min(holeCardsUsed(spot.hero, board: spot.board),
                                 holeCardsUsed(spot.villain, board: spot.board))
                XCTAssertTrue(spot.winner == 2 || unused == 0, "\(seed)/\(index)")
                if spot.winner == 2 { ties += 1 }
            }
        }
        XCTAssertGreaterThan(ties, 0)
        XCTAssertLessThan(ties, 160, "not every spot is a tie")
    }

    func testStepsDealDifferentSpotsFromTheFirstStep() {
        let learn = ShowdownSpotGenerator.spot(baseSeed: 7, index: 2)
        XCTAssertEqual(learn, ShowdownSpotGenerator.spot(baseSeed: 7, index: 2, level: .learn))
        XCTAssertEqual(ShowdownSpotGenerator.spot(baseSeed: 7, index: 2, level: .apply),
                       ShowdownSpotGenerator.spot(baseSeed: 7, index: 2, level: .apply), "deterministic")
        XCTAssertEqual(PotMathSpotGenerator.spot(baseSeed: 7, index: 2),
                       PotMathSpotGenerator.spot(baseSeed: 7, index: 2, level: .learn))
        XCTAssertEqual(CallFoldSpotGenerator.spot(baseSeed: 7, index: 2),
                       CallFoldSpotGenerator.spot(baseSeed: 7, index: 2, level: .learn))
    }

    func testApplyPotMathVariesOpensThreeBetsAndTheQuestion() {
        var opens = Set<Int>(), multipliers = Set<Int>(), sbCalls = 0, firstFractions = 0, potNow = 0
        for seed in seeds {
            for index in 0..<60 {
                let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: index, level: .apply)
                XCTAssertLessThanOrEqual(spot.actors.count, 4, "the table seats four")
                var open = 0
                for action in spot.actions {
                    switch action {
                    case let .raiseTo(.opener, total, _): open = total; opens.insert(total)
                    case let .raiseTo(.bb, total, _): multipliers.insert(total / open)
                        XCTAssertEqual(total % open, 0)
                    case .call(.sb, _): sbCalls += 1
                    case .bet: XCTFail("no flop bet before the third step")
                    default: break
                    }
                }
                XCTAssertEqual(spot.foldedActors.contains(.sb), !spot.actions.contains {
                    if case .call(.sb, _) = $0 { return true } else { return false }
                })
                if case .potNow = spot.question { potNow += 1 }
                XCTAssertEqual(spot.answerChoices.count, 3)
                XCTAssertTrue(spot.answerChoices.contains(spot.correctAnswer))
            }
        }
        XCTAssertEqual(opens, [4, 5, 6, 7, 8])
        XCTAssertEqual(multipliers, [3, 4])
        XCTAssertGreaterThan(sbCalls, 0)
        XCTAssertGreaterThan(potNow, 0)
        for seed in UInt64(0)..<32 {
            if case .fractionOfPot = PotMathSpotGenerator.spot(baseSeed: seed, index: 2, level: .apply).question {
                firstFractions += 1
            }
        }
        XCTAssertGreaterThan(firstFractions, 0, "question 1 (index 2) is not always the pot")
    }

    func testSharpPotMathAddsAFlopBetAndCallAndIsTyped() {
        for seed in seeds {
            for index in 0..<30 {
                let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                guard let bet = spot.actions.firstIndex(where: {
                    if case .bet(.bb, _) = $0 { return true } else { return false }
                }) else { return XCTFail("no flop bet") }
                guard case let .bet(_, amount) = spot.actions[bet],
                      case let .call(.opener, called)? = spot.actions.dropFirst(bet + 1).first
                else { return XCTFail("the bet is called") }
                XCTAssertEqual(amount, called)
                XCTAssertGreaterThan(amount, 0)
                XCTAssertLessThanOrEqual(spot.actors.count, 4)
            }
        }
        XCTAssertTrue(DrillLevel.sharp.typesExactAnswer(.potMath))
        XCTAssertFalse(DrillLevel.apply.typesExactAnswer(.potMath))
    }

    func testSharpCallFoldSpotsAreClose() {
        for seed in seeds {
            for index in 0..<20 {
                let spot = CallFoldSpotGenerator.spot(baseSeed: seed, index: index, level: .sharp)
                XCTAssertLessThanOrEqual(abs(spot.equityPct - spot.requiredPct), 8, "\(seed)/\(index)")
            }
        }
    }

    func testCallFoldLessonNumbersNarrowWithTheStep() {
        let spot = CallFoldSpotGenerator.spot(baseSeed: 7, index: 2)
        let learn = callFoldLessonNumbers(spot: spot, language: .english)
        XCTAssertEqual(callFoldLessonNumbers(spot: spot, language: .english, level: .learn), learn)
        XCTAssertTrue(learn?.contains("Your share") == true)
        let apply = callFoldLessonNumbers(spot: spot, language: .english, level: .apply)
        XCTAssertEqual(apply, "The call needs \(pctText(spot.requiredPct))%")
        XCTAssertNil(callFoldLessonNumbers(spot: spot, language: .korean, level: .sharp))
    }

    func testSavedAnswersRegradeAtTheirStep() {
        let sharp = ShowdownSpotGenerator.spot(baseSeed: 5, index: 3, level: .sharp)
        let reveal = SavedDrillReveal(band: GradeBand.spotOn.rawValue)
        XCTAssertTrue(SavedDrillScore.matches(concept: .showdown, seed: 5, index: 3, level: .sharp,
                                              input: .integer(sharp.winner), reveal: reveal))
        let pot = PotMathSpotGenerator.spot(baseSeed: 5, index: 3, level: .sharp)
        XCTAssertTrue(SavedDrillScore.matches(concept: .potMath, seed: 5, index: 3, level: .sharp,
                                              input: .integer(pot.correctAnswer), reveal: reveal))
        XCTAssertNotEqual(PotMathSpotGenerator.spot(baseSeed: 5, index: 3).correctAnswer, pot.correctAnswer)
        XCTAssertFalse(SavedDrillScore.matches(concept: .potMath, seed: 5, index: 3, level: .learn,
                                               input: .integer(pot.correctAnswer), reveal: reveal),
                       "an answer is checked against the step it was dealt at")
    }

    func testHeadlineNamesTheStepOnlyAfterTheFirst() {
        XCTAssertNil(DrillLevel.learn.headline(for: .showdown, in: .english))
        XCTAssertEqual(DrillLevel.apply.headline(for: .showdown, in: .english)?.hasPrefix("Step 2 · "), true)
        XCTAssertEqual(DrillLevel.sharp.headline(for: .callFold, in: .korean)?.hasPrefix("3단계 · "), true)
        XCTAssertNil(DrillLevel.apply.headline(for: .outs, in: .english))
    }
}
