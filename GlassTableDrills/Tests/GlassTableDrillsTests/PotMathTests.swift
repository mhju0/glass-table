import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class PotMathTests: XCTestCase {
    func testBlindsAloneMakeTheOpeningPot() {
        let s = PotMathSpot(actions: [.blinds(sb: 1, bb: 2)], question: .potNow)
        XCTAssertEqual(s.pot, 3)
    }

    /// A blind raising over its own post *replaces* that post. An opener who has
    /// posted nothing simply adds. Conflating the two is the classic beginner error.
    func testABlindRaisingReplacesItsOwnPostButAnOpenerAdds() {
        let bbRaises = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                    .raiseTo(actor: .bb, total: 6, alreadyIn: 2)],
                                   question: .potNow)
        XCTAssertEqual(bbRaises.pot, 7, "1 + 2, then the BB's 2 becomes 6 → 1 + 6")

        let openerRaises = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                        .raiseTo(actor: .opener, total: 6, alreadyIn: 0)],
                                       question: .potNow)
        XCTAssertEqual(openerRaises.pot, 9, "1 + 2 + 6 — nothing of theirs is replaced")
    }

    func testOpenAndTwoCallers() {
        let s = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                      .raiseTo(actor: .opener, total: 5, alreadyIn: 0),
                                      .call(actor: .caller1, amount: 5),
                                      .call(actor: .caller2, amount: 5)],
                            question: .potNow)
        XCTAssertEqual(s.pot, 18)   // 1 + 2 + 5 + 5 + 5
    }

    /// A realistic 3-bet: CO opens to 5, BTN calls, BB 3-bets to 15 (replacing its
    /// own 2), CO calls the 10 difference.
    func testThreeBetSequence() {
        let s = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                      .raiseTo(actor: .opener, total: 5, alreadyIn: 0),
                                      .call(actor: .caller1, amount: 5),
                                      .raiseTo(actor: .bb, total: 15, alreadyIn: 2),
                                      .call(actor: .opener, amount: 10)],
                            question: .potNow)
        // SB 1 + BB 15 + CO 15 + BTN 5 = 36
        XCTAssertEqual(s.pot, 36)
    }

    func testFractionOfPotRoundsToWholeChips() {
        let actions: [PotMathSpot.Action] = [.blinds(sb: 1, bb: 2),
            .raiseTo(actor: .opener, total: 5, alreadyIn: 0),
            .call(actor: .caller1, amount: 5)]
        XCTAssertEqual(PotMathSpot(actions: actions, question: .potNow).pot, 13)
        XCTAssertEqual(PotMathSpot(actions: actions,
                                   question: .fractionOfPot(0.5)).correctAnswer, 7)   // 6.5 → 7
        XCTAssertEqual(PotMathSpot(actions: actions,
                                   question: .fractionOfPot(1.0)).correctAnswer, 13)
        XCTAssertEqual(PotMathSpot(actions: actions,
                                   question: .fractionOfPot(0.33)).correctAnswer, 4)  // 4.29 → 4
    }

    func testGeneratorIsDeterministicAndAlwaysProducesALegalPot() {
        XCTAssertEqual(PotMathSpotGenerator.spot(baseSeed: 21, index: 4),
                       PotMathSpotGenerator.spot(baseSeed: 21, index: 4))
        for i in 0..<400 {
            let s = PotMathSpotGenerator.spot(baseSeed: 21, index: i)
            XCTAssertGreaterThan(s.pot, 0)
            XCTAssertTrue((3...4).contains(s.participantCount))
            guard case let .raiseTo(actor, total, alreadyIn) = s.actions[1] else {
                return XCTFail("generated sequence must begin with a non-blind open")
            }
            XCTAssertEqual(actor, .opener)
            XCTAssertGreaterThanOrEqual(total, 4)
            XCTAssertEqual(alreadyIn, 0)
            XCTAssertEqual(s.foldedActors, [.sb])
            XCTAssertTrue(s.actions.contains { action in
                guard case let .raiseTo(actor, _, alreadyIn) = action else { return false }
                return actor == .bb && alreadyIn == 2
            })
            XCTAssertGreaterThan(s.correctAnswer, 0, "every question has a positive answer")
            XCTAssertEqual(gradePotMath(answer: s.correctAnswer, spot: s).band, .spotOn)
            XCTAssertEqual(Set(s.answerChoices).count, 3)
            XCTAssertTrue(s.answerChoices.contains(s.correctAnswer))
        }
    }

    func testParticipantCountIncludesEveryContributorExactlyOnce() {
        let spot = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                         .raiseTo(actor: .opener, total: 4, alreadyIn: 0),
                                         .call(actor: .caller1, amount: 4),
                                         .raiseTo(actor: .bb, total: 12, alreadyIn: 2),
                                         .call(actor: .opener, amount: 8)],
                               question: .potNow)
        XCTAssertEqual(spot.participantCount, 4,
                       "SB, BB, player A, and player B each count once")

        let noBlinds = PotMathSpot(actions: [.bet(actor: .opener, amount: 5)],
                                   question: .potNow)
        XCTAssertEqual(noBlinds.participantCount, 1,
                       "Participant count follows the actual action list")
    }

    func testGeneratorAsksBothQuestionShapes() {
        var potNow = 0, fraction = 0
        for i in 0..<200 {
            switch PotMathSpotGenerator.spot(baseSeed: 21, index: i).question {
            case .potNow: potNow += 1
            case .fractionOfPot: fraction += 1
            }
        }
        XCTAssertGreaterThan(potNow, 0)
        XCTAssertGreaterThan(fraction, 0)
    }

    func testGeneratorProducesThreeAndFourSeatTables() {
        var counts: Set<Int> = []
        for i in 0..<200 {
            counts.insert(PotMathSpotGenerator.spot(baseSeed: 21, index: i).participantCount)
        }
        XCTAssertEqual(counts, [3, 4])
    }

    func testReplaySplitsBlindPostsAndKeepsFoldedChipsInThePot() {
        let spot = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                         .raiseTo(actor: .opener, total: 6, alreadyIn: 0),
                                         .raiseTo(actor: .bb, total: 18, alreadyIn: 2),
                                         .call(actor: .opener, amount: 12)],
                               question: .potNow,
                               foldedActors: [.sb])
        let steps = spot.replaySteps

        XCTAssertEqual(steps.count, 6)
        XCTAssertEqual(steps[0], PotMathReplayStep(actor: .sb, kind: .post,
                                                   addedChips: 1, totalContribution: 1))
        XCTAssertEqual(steps[1], PotMathReplayStep(actor: .bb, kind: .post,
                                                   addedChips: 2, totalContribution: 2))
        XCTAssertEqual(steps[3], PotMathReplayStep(actor: .sb, kind: .fold,
                                                   addedChips: 0, totalContribution: 1))
        XCTAssertEqual(steps[4], PotMathReplayStep(actor: .bb, kind: .raiseTo(18),
                                                   addedChips: 16, totalContribution: 18))
        XCTAssertEqual(spot.contribution(of: .sb, throughReplayStep: 5), 1)
        XCTAssertEqual(spot.contribution(of: .bb, throughReplayStep: 5), 18)
        XCTAssertEqual(spot.contribution(of: .opener, throughReplayStep: 5), 18)
        XCTAssertEqual(spot.pot, 37)
    }

    func testFourSeatFixtureStopsBeforeTheEarlierCallerRespondsAgain() {
        let spot = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                         .raiseTo(actor: .opener, total: 6, alreadyIn: 0),
                                         .call(actor: .caller1, amount: 6),
                                         .raiseTo(actor: .bb, total: 18, alreadyIn: 2),
                                         .call(actor: .opener, amount: 12)],
                               question: .potNow,
                               foldedActors: [.sb])
        XCTAssertEqual(spot.pot, 43)
        XCTAssertEqual(spot.contribution(of: .caller1,
                                         throughReplayStep: spot.replaySteps.count - 1), 6)
        XCTAssertEqual(spot.replaySteps.last?.actor, .opener)
    }

    func testAnswerChoicesAreUniqueIncludeTheAnswerAndVaryItsPosition() {
        var correctPositions: Set<Int> = []
        var correctRanks: Set<Int> = []
        for i in 0..<200 {
            let spot = PotMathSpotGenerator.spot(baseSeed: 5, index: i)
            XCTAssertEqual(spot.answerChoices.count, 3)
            XCTAssertEqual(Set(spot.answerChoices).count, 3)
            XCTAssertTrue(spot.answerChoices.allSatisfy { $0 >= 0 })
            correctPositions.insert(spot.answerChoices.firstIndex(of: spot.correctAnswer)!)
            correctRanks.insert(spot.answerChoices.sorted().firstIndex(of: spot.correctAnswer)!)
        }
        XCTAssertEqual(correctPositions, [0, 1, 2],
                       "Seeded ordering must use every answer position")
        XCTAssertEqual(correctRanks, [0, 1, 2],
                       "The correct value must not always be the smallest, middle, or largest choice")
    }

    func testFirstPracticeIndicesAskForThePotBeforeIntroducingFractions() {
        for index in 0...2 {
            XCTAssertEqual(PotMathSpotGenerator.spot(baseSeed: 91, index: index).question,
                           .potNow)
        }
    }

    func testAnswerChoicesTerminateForZeroAndOneChipLegacySpots() {
        let zero = PotMathSpot(actions: [], question: .potNow)
        let one = PotMathSpot(actions: [.bet(actor: .opener, amount: 1)], question: .potNow)
        XCTAssertEqual(zero.answerChoices.count, 3)
        XCTAssertEqual(one.answerChoices.count, 3)
        XCTAssertEqual(Set(zero.answerChoices).count, 3)
        XCTAssertEqual(Set(one.answerChoices).count, 3)
        XCTAssertTrue(zero.answerChoices.contains(0))
        XCTAssertTrue(one.answerChoices.contains(1))
    }

    /// The pot must always equal the sum of what players actually put in, so the
    /// breakdown shown to the user can never disagree with the number.
    func testGeneratedPotsAreConsistentWithTheirOwnBreakdown() {
        for i in 0..<200 {
            let s = PotMathSpotGenerator.spot(baseSeed: 9, index: i)
            var recomputed = 0
            for a in s.actions {
                switch a {
                case let .blinds(sb, bb): recomputed += sb + bb
                case let .bet(_, n): recomputed += n
                case let .call(_, n): recomputed += n
                case let .raiseTo(_, to, from): recomputed += to - from
                }
            }
            XCTAssertEqual(recomputed, s.pot)
        }
    }

    func testGradingIsBinaryAndShowsTheArithmetic() {
        let s = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                            .raiseTo(actor: .opener, total: 5, alreadyIn: 0),
                            .call(actor: .caller1, amount: 5)],
                            question: .potNow)
        XCTAssertEqual(gradePotMath(answer: 13, spot: s).band, .spotOn)
        XCTAssertEqual(gradePotMath(answer: 12, spot: s).band, .off)
        let why = gradePotMath(answer: 13, spot: s).whyText
        XCTAssertTrue(why.contains("블라인드: 1 + 2 = 3칩"))
        XCTAssertTrue(why.contains("플레이어 A 레이즈: 3 + 5 = 8칩 (총 5칩)"))
        XCTAssertTrue(why.contains("플레이어 B 콜: 8 + 5 = 13칩"))
        XCTAssertTrue(why.contains("지금 팟: 13칩"))
        XCTAssertEqual(why.split(separator: "\n").count, 4)
    }

    func testFractionRevealShowsTheUnroundedValueBeforeTheWholeChipAnswer() {
        let spot = PotMathSpot(actions: [.blinds(sb: 1, bb: 2),
                                         .raiseTo(actor: .opener, total: 5, alreadyIn: 0),
                                         .call(actor: .caller1, amount: 5)],
                               question: .fractionOfPot(0.5))
        let why = gradePotMath(answer: 7, spot: spot).whyText
        XCTAssertTrue(why.contains("13 × 50% = 6.5칩 → 7칩"), why)
        XCTAssertFalse(why.contains("13 × 50% = 7칩"), why)
    }

    func testFractionRevealPreservesWholeChipMagnitudes() {
        let cases: [(pot: Int, expected: String)] = [
            (20, "20 × 100% = 20칩 → 20칩"),
            (100, "100 × 100% = 100칩 → 100칩"),
            (0, "0 × 100% = 0칩 → 0칩"),
        ]
        for item in cases {
            let actions: [PotMathSpot.Action] = item.pot == 0
                ? []
                : [.bet(actor: .opener, amount: item.pot)]
            let spot = PotMathSpot(actions: actions, question: .fractionOfPot(1))
            let why = gradePotMath(answer: item.pot, spot: spot).whyText
            XCTAssertTrue(why.contains(item.expected), why)
        }
    }
}
