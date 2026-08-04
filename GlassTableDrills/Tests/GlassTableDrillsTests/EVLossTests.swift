// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// Spec: docs/specs/2026-08-04-r4-s2-ev-loss-design.md §8.
final class EVLossTests: XCTestCase {

    private func opts(_ evs: [Double]) -> [DecisionOption] {
        evs.enumerated().map { DecisionOption(label: "opt\($0.offset)", ev: $0.element) }
    }

    // §8.1 — the model is total.

    func testTheBestOptionAlwaysScoresZero() {
        let options = opts([-3, 0, 1.75, -0.2])
        let best = options.enumerated().max { $0.element.ev < $1.element.ev }!.offset
        let g = gradeByEVLoss(chosen: best, options: options)
        XCTAssertEqual(g.loss, 0, accuracy: 1e-12)
        XCTAssertEqual(g.band, .spotOn)
    }

    func testLossIsNeverNegative() {
        let options = opts([-3, 0, 1.75, -0.2])
        for i in options.indices {
            XCTAssertGreaterThanOrEqual(gradeByEVLoss(chosen: i, options: options).loss, 0)
        }
    }

    func testLossIsTheGapToTheBest() {
        let options = opts([0, -1.25])
        XCTAssertEqual(gradeByEVLoss(chosen: 1, options: options).loss, 1.25, accuracy: 1e-12)
    }

    func testTiedOptionsBothLoseNothing() {
        let options = opts([0, 0])
        XCTAssertEqual(gradeByEVLoss(chosen: 0, options: options).loss, 0)
        XCTAssertEqual(gradeByEVLoss(chosen: 1, options: options).loss, 0)
    }

    // §8.2 — band boundaries land in the better band.

    func testBandBoundariesAreInclusiveDownward() {
        XCTAssertEqual(evLossBand(bb: 0), .spotOn)
        XCTAssertEqual(evLossBand(bb: 0.5), .spotOn)
        XCTAssertEqual(evLossBand(bb: 0.5001), .close)
        XCTAssertEqual(evLossBand(bb: 2.0), .close)
        XCTAssertEqual(evLossBand(bb: 2.0001), .off)
    }

    // §8.3 / §8.4 — the spot's EV is the engine's formula, and folding is worth nothing.

    func testCallEVMatchesTheEngineFormula() {
        for i in 0..<20 {
            let s = EVLossSpotGenerator.spot(baseSeed: 0xE7, index: i)
            let expected = callEV(equity: s.equityPct / 100,
                                  toCall: Double(s.bet), pot: Double(s.pot + s.bet))
            XCTAssertEqual(s.callEVbb, expected, accuracy: 1e-12)
        }
    }

    func testFoldIsAlwaysWorthNothing() {
        for i in 0..<20 {
            let s = EVLossSpotGenerator.spot(baseSeed: 0xF01D, index: i)
            XCTAssertEqual(s.options[EVLossSpot.foldIndex].ev, 0)
            XCTAssertEqual(s.options[EVLossSpot.foldIndex].label, "폴드")
        }
    }

    /// The two ways to be told the answer must agree: a call is right exactly when its
    /// EV beats folding, which is exactly when equity clears the required equity.
    func testCallIsBestExactlyWhenEquityClearsThePrice() {
        for i in 0..<40 {
            let s = EVLossSpotGenerator.spot(baseSeed: 0xC0FFEE, index: i)
            let callIsBest = gradeByEVLoss(chosen: EVLossSpot.callIndex,
                                           options: s.options).loss == 0
            XCTAssertEqual(callIsBest, s.equityPct >= s.requiredPct,
                           "spot \(i): equity \(s.equityPct) vs required \(s.requiredPct)")
        }
    }

    // §8.5 — generation is deterministic and non-degenerate.

    func testGenerationIsDeterministic() {
        for i in 0..<10 {
            XCTAssertEqual(EVLossSpotGenerator.spot(baseSeed: 7, index: i),
                           EVLossSpotGenerator.spot(baseSeed: 7, index: i))
        }
    }

    func testSpotsAreDecisionsNotForegoneConclusions() {
        for i in 0..<40 {
            let s = EVLossSpotGenerator.spot(baseSeed: 0xDEC1, index: i)
            XCTAssertEqual(s.board.count, 5, "the drill is a river spot")
            XCTAssertGreaterThanOrEqual(s.equityPct, 5)
            XCTAssertLessThanOrEqual(s.equityPct, 95)
            XCTAssertTrue(Set(s.hero).isDisjoint(with: Set(s.board)))
        }
    }

    // §8.6 — a drill that can only ever award one band is not grading.

    func testAlwaysCallingProducesEveryBand() {
        var seen = Set<GradeBand>()
        for i in 0..<120 {
            let s = EVLossSpotGenerator.spot(baseSeed: 0xBA_11, index: i)
            seen.insert(gradeEVLoss(userCalls: true, spot: s).band)
        }
        XCTAssertEqual(seen, [.spotOn, .close, .off],
                       "always-call saw only \(seen.map(\.rawValue).sorted())")
    }

    func testAlwaysFoldingProducesEveryBand() {
        var seen = Set<GradeBand>()
        for i in 0..<120 {
            let s = EVLossSpotGenerator.spot(baseSeed: 0xF0_1D, index: i)
            seen.insert(gradeEVLoss(userCalls: false, spot: s).band)
        }
        XCTAssertEqual(seen, [.spotOn, .close, .off],
                       "always-fold saw only \(seen.map(\.rawValue).sorted())")
    }

    // The reveal never claims something the numbers do not support.

    func testRevealNamesTheChosenOptionWhenNothingWasLost() {
        for i in 0..<30 {
            let s = EVLossSpotGenerator.spot(baseSeed: 0x5A1E, index: i)
            let callWasBest = s.callEVbb > 0
            let r = gradeEVLoss(userCalls: callWasBest, spot: s)
            XCTAssertEqual(r.grade.loss, 0)
            XCTAssertTrue(r.whyText.contains("최선이었어요"), r.whyText)
        }
    }

    func testRevealPrintsBothPricesAlways() {
        for i in 0..<20 {
            for calls in [true, false] {
                let s = EVLossSpotGenerator.spot(baseSeed: 0xB0_7E, index: i)
                let r = gradeEVLoss(userCalls: calls, spot: s)
                XCTAssertTrue(r.whyText.contains("콜의 EV는"), r.whyText)
                XCTAssertTrue(r.whyText.contains("폴드는 0bb"), r.whyText)
            }
        }
    }

    // Korean particles are computed, never baked — 콜 takes 이, 폴드 takes 가.

    func testVerdictParticlesAgreeWithTheWord() {
        XCTAssertEqual(KO.subject("콜"), "콜이")
        XCTAssertEqual(KO.subject("폴드"), "폴드가")
    }

    /// A 0.2bb leak bands as .spotOn. Labelling that 정확 next to "the other option was
    /// better" is the contradiction `evLossLabel` exists to avoid.
    func testDecisionSeverityWordsAreNotTheAnswerWords() {
        XCTAssertEqual(evLossBand(bb: 0.2).evLossLabel, "최선")
        XCTAssertEqual(evLossBand(bb: 1.0).evLossLabel, "부정확")
        XCTAssertEqual(evLossBand(bb: 5.0).evLossLabel, "실수")
        for b in [GradeBand.spotOn, .close, .off] {
            XCTAssertNotEqual(b.evLossLabel, b.rawValue)
        }
    }

    func testBBTextDoesNotPrintASignedZero() {
        XCTAssertEqual(bbText(0), "0")
        XCTAssertEqual(bbText(-0.02), "0")
        // Not a .x5 tie: %.1f resolves those to even, which is a printf rule rather
        // than anything this app decided, and asserting on it would test the platform.
        XCTAssertEqual(bbText(-1.24), "-1.2")
        XCTAssertEqual(bbText(-1.26), "-1.3")
        XCTAssertEqual(bbText(2), "2")
    }

    // §8.7 — a store written before evLoss existed still decodes.

    func testOldAnswerRecordsWithoutEVLossStillDecode() throws {
        let json = """
        {"concept":"potOdds","at":0,"correct":true}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let r = try decoder.decode(AnswerRecord.self, from: json)
        XCTAssertEqual(r.concept, "potOdds")
        XCTAssertNil(r.evLoss)
        XCTAssertNil(r.interval)
    }

    func testMeanEVLossIgnoresAnswersThatAreNotGradedThatWay() {
        var state = ProgressState()
        XCTAssertNil(meanEVLoss(in: state), "no EV-graded answers yet")
        state.append(AnswerRecord(concept: .potOdds, at: Date(), correct: true))
        XCTAssertNil(meanEVLoss(in: state), "a non-EV concept must not count as 0bb")
        state.append(AnswerRecord(concept: .evLoss, at: Date(), correct: false, evLoss: 3))
        state.append(AnswerRecord(concept: .evLoss, at: Date(), correct: true, evLoss: 0))
        XCTAssertEqual(meanEVLoss(in: state)!, 1.5, accuracy: 1e-12)
    }

    // The concept is wired into the path exactly once, and is not an estimation concept.

    func testEVLossIsTaughtByExactlyOneNode() {
        let taught = Curriculum.allNodes.filter { Curriculum.taughtConcept(of: $0) == .evLoss }
        XCTAssertEqual(taught.map(\.id), ["u6-evLoss"])
    }

    func testEVLossCollectsNoInterval() {
        XCTAssertFalse(Concept.evLoss.isEstimation)
    }

    func testTheWalkthroughEndsOnTheCostNotTheChoice() {
        let s = EVLossSpotGenerator.spot(baseSeed: 1, index: 0)
        let beats = BeatScript.evLoss(s)
        XCTAssertEqual(beats.count, 6)
        XCTAssertEqual(beats.last?.caption, "폴드는 언제나 0bb")
        // Every beat renders something; an empty felt is the bug R3 shipped once.
        XCTAssertTrue(beats.allSatisfy { $0.focus != .none })
    }
}
