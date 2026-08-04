// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// Spec: docs/specs/2026-08-04-r5b-defend-drill-design.md §4.
final class DefendDrillTests: XCTestCase {

    private func c(_ s: String) -> [Card] {
        [Card(String(s.prefix(2)))!, Card(String(s.suffix(2)))!]
    }

    // §4.1 — ordinal bands.

    func testGradeFollowsTheOrdinalDistance() {
        // AA 3-bets against any opener; a call is one band off, a fold is two.
        let aa = DefendSpot(hand: c("AhAd"), opener: .utg)
        XCTAssertEqual(gradeDefend(chosen: .threeBet, spot: aa).band, .spotOn)
        XCTAssertEqual(gradeDefend(chosen: .call, spot: aa).band, .close)
        XCTAssertEqual(gradeDefend(chosen: .fold, spot: aa).band, .off)
        // 72o folds everywhere; a call is one off, a 3-bet two.
        let junk = DefendSpot(hand: c("7h2c"), opener: .btn)
        XCTAssertEqual(gradeDefend(chosen: .fold, spot: junk).band, .spotOn)
        XCTAssertEqual(gradeDefend(chosen: .call, spot: junk).band, .close)
        XCTAssertEqual(gradeDefend(chosen: .threeBet, spot: junk).band, .off)
    }

    func testTheDrillGradesWithTheTablesFunction() {
        for i in 0..<30 {
            let s = DefendSpotGenerator.spot(baseSeed: 0xDEF, index: i)
            XCTAssertEqual(s.correct, DefendChart.action(for: s.hand, vsOpenFrom: s.opener))
        }
    }

    // §4.2 — generation.

    func testGenerationIsDeterministicAndBoundaryBiased() {
        var boundary = 0
        for i in 0..<40 {
            let a = DefendSpotGenerator.spot(baseSeed: 3, index: i)
            XCTAssertEqual(a, DefendSpotGenerator.spot(baseSeed: 3, index: i))
            XCTAssertTrue(RFIChart.seats.contains(a.opener))
            if (2.0...12.0).contains(Chen.score(a.handClass)) { boundary += 1 }
        }
        XCTAssertGreaterThan(boundary, 30, "most spots must sit near the chart's edges")
    }

    /// The drill must actually pose all three answers as correct sometimes — a
    /// three-way question whose answer is always 폴드 is a two-way question.
    func testAllThreeBandsOccurAsCorrectAnswers() {
        var seen = Set<DefendAction>()
        for i in 0..<80 {
            seen.insert(DefendSpotGenerator.spot(baseSeed: 0xABC, index: i).correct)
        }
        XCTAssertEqual(seen, Set(DefendAction.allCases))
    }

    // §4.3 — the reveal shows the rule.

    func testTheRevealDerivesItsNumbersFromTheChartConstants() {
        let s = DefendSpotGenerator.spot(baseSeed: 1, index: 0)
        let r = gradeDefend(chosen: .call, spot: s)
        let openPct = RFIChart.openPercent[s.opener] ?? 0
        XCTAssertTrue(r.whyText.contains(pctText(openPct)), r.whyText)
        XCTAssertTrue(r.whyText.contains(pctText(openPct * DefendChart.threeBetShare)), r.whyText)
        XCTAssertTrue(r.whyText.contains(pctText(openPct * DefendChart.defendShare)), r.whyText)
        XCTAssertTrue(r.whyText.contains(s.correct.rawValue), r.whyText)
    }

    // §4.4 — wiring.

    func testDefendIsWiredIntoThePathOnce() {
        XCTAssertFalse(Concept.defend.isEstimation)
        let taught = Curriculum.allNodes.filter { Curriculum.taughtConcept(of: $0) == .defend }
        XCTAssertEqual(taught.map(\.id), ["u8-defend"])
    }

    func testTheWalkthroughDerivesThenShowsTheChart() {
        let s = DefendSpotGenerator.spot(baseSeed: 1, index: 0)
        let beats = BeatScript.defend(s)
        XCTAssertEqual(beats.count, 5)
        guard case .actionList = beats[2].focus else {
            return XCTFail("beat 3 must derive the bands from the opener's width")
        }
        for i in [3, 4] {
            guard case let .defendChart(opener, highlight) = beats[i].focus else {
                return XCTFail("beat \(i + 1) must show the chart")
            }
            XCTAssertEqual(opener, s.opener)
            XCTAssertEqual(highlight, s.handClass)
        }
        XCTAssertTrue(beats.allSatisfy { $0.focus != .none })
    }
}
