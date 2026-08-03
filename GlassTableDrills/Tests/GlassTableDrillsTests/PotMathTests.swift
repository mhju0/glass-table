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
        let bbRaises = PotMathSpot(actions: [.blinds(sb: 1, bb: 2), .raiseTo(6, from: 2)],
                                   question: .potNow)
        XCTAssertEqual(bbRaises.pot, 7, "1 + 2, then the BB's 2 becomes 6 → 1 + 6")

        let openerRaises = PotMathSpot(actions: [.blinds(sb: 1, bb: 2), .raiseTo(6, from: 0)],
                                       question: .potNow)
        XCTAssertEqual(openerRaises.pot, 9, "1 + 2 + 6 — nothing of theirs is replaced")
    }

    func testOpenAndTwoCallers() {
        let s = PotMathSpot(actions: [.blinds(sb: 1, bb: 2), .raiseTo(5, from: 0),
                                      .call(5), .call(5)],
                            question: .potNow)
        XCTAssertEqual(s.pot, 18)   // 1 + 2 + 5 + 5 + 5
    }

    /// A realistic 3-bet: CO opens to 5, BTN calls, BB 3-bets to 15 (replacing its
    /// own 2), CO calls the 10 difference.
    func testThreeBetSequence() {
        let s = PotMathSpot(actions: [.blinds(sb: 1, bb: 2), .raiseTo(5, from: 0),
                                      .call(5), .raiseTo(15, from: 2), .call(10)],
                            question: .potNow)
        // SB 1 + BB 15 + CO 15 + BTN 5 = 36
        XCTAssertEqual(s.pot, 36)
    }

    func testFractionOfPotRoundsToWholeChips() {
        let actions: [PotMathSpot.Action] = [.blinds(sb: 1, bb: 2), .raiseTo(5, from: 0), .call(5)]
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
            XCTAssertGreaterThan(s.correctAnswer, 0, "every question has a positive answer")
            XCTAssertEqual(gradePotMath(answer: s.correctAnswer, spot: s).band, .spotOn)
        }
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
                case let .bet(n): recomputed += n
                case let .call(n): recomputed += n
                case let .raiseTo(to, from): recomputed += to - from
                }
            }
            XCTAssertEqual(recomputed, s.pot)
        }
    }

    func testGradingIsBinaryAndShowsTheArithmetic() {
        let s = PotMathSpot(actions: [.blinds(sb: 1, bb: 2), .raiseTo(5, from: 0), .call(5)],
                            question: .potNow)
        XCTAssertEqual(gradePotMath(answer: 13, spot: s).band, .spotOn)
        XCTAssertEqual(gradePotMath(answer: 12, spot: s).band, .off)
        let why = gradePotMath(answer: 13, spot: s).whyText
        XCTAssertTrue(why.contains("블라인드 1+2"))
        XCTAssertTrue(why.contains("13bb"))
    }
}
