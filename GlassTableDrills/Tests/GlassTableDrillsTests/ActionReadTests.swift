// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// Spec: docs/specs/2026-08-04-r4-s3-postflop-policy-design.md §4, §7.6.
final class ActionReadTests: XCTestCase {

    func testGenerationIsDeterministic() {
        for i in 0..<10 {
            XCTAssertEqual(ActionReadSpotGenerator.spot(baseSeed: 11, index: i),
                           ActionReadSpotGenerator.spot(baseSeed: 11, index: i))
        }
    }

    func testSpotsAreAlwaysGradeable() {
        for i in 0..<60 {
            let s = ActionReadSpotGenerator.spot(baseSeed: 0xACE, index: i)
            XCTAssertEqual(s.board.count, 3)
            XCTAssertGreaterThan(s.acted.combos, 0, "an empty action set is not a spot")
            // Spec §4.1: the certain tells are walkthrough material, not questions.
            XCTAssertLessThanOrEqual(s.pairOrBetterPct, 99.5, "spot \(i)")
            XCTAssertGreaterThanOrEqual(s.pairOrBetterPct, 0.5, "spot \(i)")
        }
    }

    func testBothActionsActuallyOccur() {
        var seen = Set<PostflopAction>()
        for i in 0..<40 {
            seen.insert(ActionReadSpotGenerator.spot(baseSeed: 0xBEEF, index: i).action)
        }
        XCTAssertEqual(seen, Set(PostflopAction.allCases))
    }

    func testGradeBandsMatchHitFrequencys() {
        let s = ActionReadSpotGenerator.spot(baseSeed: 1, index: 0)
        let correct = s.pairOrBetterPct
        func band(_ off: Double) -> GradeBand {
            gradeActionRead(estimate: Estimate(point: correct + off,
                                               lo: correct - 20, hi: correct + 20),
                            spot: s).band
        }
        XCTAssertEqual(band(0), .spotOn)
        XCTAssertEqual(band(5), .spotOn)
        XCTAssertEqual(band(12), .close)
        XCTAssertEqual(band(13), .off)
    }

    /// The reveal must print the rule the number came from, and both percentages —
    /// the acted range's and the full range's — or the "checkable" claim is empty.
    func testTheRevealShowsItsWork() {
        for i in 0..<20 {
            let s = ActionReadSpotGenerator.spot(baseSeed: 0xFACE, index: i)
            let r = gradeActionRead(estimate: Estimate(point: 50, lo: 40, hi: 60), spot: s)
            XCTAssertTrue(r.whyText.contains(s.actedBucketList), r.whyText)
            XCTAssertTrue(r.whyText.contains(pctText(s.pairOrBetterPct)), r.whyText)
            XCTAssertTrue(r.whyText.contains(pctText(s.full.pairOrBetter * 100)), r.whyText)
        }
    }

    /// The narrowing direction claim must agree with the numbers it prints.
    func testTheDirectionSentenceIsTrue() {
        for i in 0..<30 {
            let s = ActionReadSpotGenerator.spot(baseSeed: 0xD1, index: i)
            let r = gradeActionRead(estimate: Estimate(point: 50, lo: 40, hi: 60), spot: s)
            let fullPct = s.full.pairOrBetter * 100
            if s.pairOrBetterPct > fullPct + 1 {
                XCTAssertTrue(r.whyText.contains("강한 쪽으로"), r.whyText)
            } else if s.pairOrBetterPct < fullPct - 1 {
                XCTAssertTrue(r.whyText.contains("약한 쪽으로"), r.whyText)
            }
        }
    }

    // Wiring.

    func testActionReadIsAnEstimationConceptTaughtOnce() {
        XCTAssertTrue(Concept.actionRead.isEstimation)
        let taught = Curriculum.allNodes.filter {
            Curriculum.taughtConcept(of: $0) == .actionRead
        }
        XCTAssertEqual(taught.map(\.id), ["u7-actionRead"])
    }

    func testTheWalkthroughShowsRuleThenBars() {
        let s = ActionReadSpotGenerator.spot(baseSeed: 1, index: 0)
        let beats = BeatScript.actionRead(s)
        XCTAssertEqual(beats.count, 5)
        // The rule beat renders the policy as an action list, one line per bucket.
        guard case let .actionList(lines, _) = beats[2].focus else {
            return XCTFail("beat 3 must show the policy table")
        }
        XCTAssertEqual(lines.count, MadeHand.allCases.count)
        // Both bar beats carry before AND after — the shape change is the lesson.
        for i in [3, 4] {
            guard case let .buckets(bars) = beats[i].focus else {
                return XCTFail("beat \(i + 1) must show the bars")
            }
            XCTAssertEqual(bars.count, 2)
        }
        XCTAssertTrue(beats.allSatisfy { $0.focus != .none })
    }
}
