// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
import GlassTableDrills
@testable import GlassTable

final class GuidedHandTests: XCTestCase {
    private typealias Move = GuidedHandState.Move

    /// Every line the learner can take without giving up, by choosing each offered move.
    private func lines(_ hand: GuidedHandState = { var h = GuidedHandState(); h.next(); h.next(); return h }(),
                       _ taken: [Move] = []) -> [(GuidedHandState, [Move])] {
        guard hand.isDecision else { return [(hand, taken)] }
        return hand.choices.filter { $0 != .fold }.flatMap { move -> [(GuidedHandState, [Move])] in
            var next = hand
            next.choose(move)
            return lines(next, taken + [move])
        }
    }

    func testDealIsLegalAndTheLearnerHoldsTheBetterHand() {
        let dealt = GuidedHandState.hero + GuidedHandState.opponent + GuidedHandState.board
        XCTAssertEqual(Set(dealt).count, 9)
        XCTAssertTrue(dealt.allSatisfy { Deck.all.contains($0) })
        XCTAssertEqual(GuidedHandState().showdown.winner, 0)
    }

    func testEveryLineReachesShowdownAndConservesChips() {
        let all = lines()
        XCTAssertEqual(all.count, 16, "Two choices on each of four streets once folding is set aside.")
        for (reached, taken) in all {
            var hand = reached
            XCTAssertEqual(hand.stage, .showdown, "\(taken)")
            XCTAssertEqual(hand.paid[0], hand.paid[1], "Both players matched: \(taken)")
            XCTAssertEqual(hand.visibleBoard.count, 5)
            XCTAssertEqual(hand.stacks.reduce(0, +) + hand.pot, 40, "\(taken)")
            XCTAssertTrue(hand.stacks.allSatisfy { $0 > 0 })
            let pot = hand.pot
            hand.next()
            XCTAssertEqual(hand.stage, .summary)
            XCTAssertEqual(hand.stacks, [20 + pot / 2, 20 - pot / 2])
        }
    }

    func testCoachLineCostsAndPot() {
        var hand = GuidedHandState()
        XCTAssertEqual(hand.pot, 3)
        XCTAssertEqual(hand.owed, 0, "Nothing is owed before the learner's first turn is shown.")
        hand.follow(); hand.follow()
        XCTAssertEqual(hand.stage, .preflop)
        XCTAssertEqual(hand.owed, 1)
        XCTAssertEqual(hand.choices, [.fold, .call, .raise])
        hand.follow()
        XCTAssertEqual([hand.stage, .flop], [.flop, .flop])
        XCTAssertEqual(hand.pot, 4); XCTAssertEqual(hand.owed, 0)
        XCTAssertEqual(hand.choices, [.check, .raise], "Nothing to match, so giving up is not offered.")
        XCTAssertEqual(hand.visibleBoard.count, 3)
        hand.follow()
        XCTAssertEqual(hand.stage, .turn)
        XCTAssertEqual(hand.pot, 10, "Bet 2, call 2, then the opponent's turn bet of 2.")
        XCTAssertEqual(hand.owed, 2); XCTAssertEqual(hand.raiseTo, 6)
        hand.follow()
        XCTAssertEqual(hand.stage, .river); XCTAssertEqual(hand.pot, 12)
        hand.follow()
        XCTAssertEqual(hand.stage, .showdown)
        hand.follow()
        XCTAssertEqual(hand.stacks, [26, 14])
    }

    func testGivingUpAsksFirstAndThenEndsTheHand() {
        var hand = GuidedHandState()
        hand.next(); hand.next()
        hand.choose(.fold)
        XCTAssertTrue(hand.confirmingFold)
        XCTAssertEqual(hand.stage, .preflop, "The first tap only asks.")
        hand.choose(.call)
        XCTAssertEqual(hand.stage, .preflop, "Other choices wait while the question is open.")
        hand.cancelFold()
        XCTAssertFalse(hand.confirmingFold)
        hand.choose(.fold); hand.choose(.fold)
        XCTAssertEqual(hand.stage, .summary)
        XCTAssertTrue(hand.folded)
        XCTAssertEqual(hand.stacks, [19, 21])
        XCTAssertTrue(hand.visibleBoard.isEmpty)
    }

    func testRestoredRangeEvidenceEqualsLiveForLegacyAndBandAnswers() throws {
        let inputs: [DrillSubmittedInput] = [.range(width: 30, tendencies: []),
                                            .rangeBand(width: 42, excludedTop: 8, tendencies: [])]
        for input in inputs {
            let bytes = try JSONEncoder().encode(input)
            let resumed = try JSONDecoder().decode(DrillSubmittedInput.self, from: bytes)
            for language in [LearningLanguage.korean, .english] {
                let direct = try XCTUnwrap(RestoredLessonEvidence.rangeReveal(seed: 7, index: 1, input: input, language: language))
                let restored = try XCTUnwrap(RestoredLessonEvidence.rangeReveal(seed: 7, index: 1, input: resumed, language: language))
                XCTAssertEqual(direct, restored)
                let estimate = RangeEstimate(width: input == inputs[0] ? 30 : 42, tendencies: [], excludedTop: input == inputs[0] ? 0 : 8)
                XCTAssertEqual(restored, gradeRangeRead(estimate: estimate, spot: RangeReadSpotGenerator.spot(baseSeed: 7, index: 1), language: language))
            }
        }
    }

    func testRestoredPositionLabelsUseSameNumberedPlainSeats() throws {
        for language in [LearningLanguage.korean, .english] {
            for seed: UInt64 in 0..<40 {
                let spot = PositionSpotGenerator.spot(baseSeed: seed, index: 0)
                guard case let .whichIsLater(a, b) = spot.question else { continue }
                for choice in [0, 1] {
                    let input = DrillSubmittedInput.integer(choice)
                    let resumed = try JSONDecoder().decode(DrillSubmittedInput.self, from: JSONEncoder().encode(input))
                    let description = try XCTUnwrap(ConceptReveal(concept: .position, seed: seed, index: 0, input: resumed, language: language))
                    XCTAssertEqual(description.mine, (choice == 0 ? a : b).seatLabel(in: language))
                    XCTAssertFalse(description.mine.contains((choice == 0 ? a : b).rawValue))
                }
            }
        }
    }
}
