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
            XCTAssertTrue((4...5).contains(s.participantCount))
            guard case let .raiseTo(actor, total, alreadyIn) = s.actions[1] else {
                return XCTFail("generated sequence must begin with a non-blind open")
            }
            XCTAssertEqual(actor, .opener)
            XCTAssertGreaterThanOrEqual(total, 4)
            XCTAssertEqual(alreadyIn, 0)
            XCTAssertGreaterThan(s.correctAnswer, 0, "every question has a positive answer")
            XCTAssertEqual(gradePotMath(answer: s.correctAnswer, spot: s).band, .spotOn)
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
