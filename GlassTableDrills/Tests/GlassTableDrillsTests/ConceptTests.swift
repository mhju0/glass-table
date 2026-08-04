import XCTest
@testable import GlassTableDrills

final class ConceptTests: XCTestCase {
    func testRosterCoversBlockA() {
        XCTAssertEqual(Concept.allCases.count, 16)
        XCTAssertEqual(Set(Concept.allCases.map(\.rawValue)),
                       ["showdown", "potMath", "position", "combos", "potOdds",
                        "outs", "equitySense", "evCall", "callFold",
                        "rangeNotation", "rfi", "rangeRead",
                        "hitFrequency", "rangeAdvantage", "evLoss", "mdf"])
    }

    /// Spec §5.4: interval input only where the answer is genuinely estimated.
    func testOnlyEstimationConceptsTakeAnInterval() {
        XCTAssertEqual(Set(Concept.allCases.filter(\.isEstimation)),
                       [.equitySense, .evCall, .outs, .hitFrequency, .rangeAdvantage])
        for c in [Concept.showdown, .potMath, .position, .combos, .potOdds, .callFold,
                  .rangeNotation, .rfi, .rangeRead, .evLoss, .mdf] {
            XCTAssertFalse(c.isEstimation, "\(c.rawValue) has an exact answer")
        }
    }

    func testMasteryTiersOrderLowToHigh() {
        XCTAssertEqual(MasteryTier.allCases, [.attempted, .familiar, .proficient, .mastered])
        XCTAssertLessThan(MasteryTier.attempted, MasteryTier.familiar)
        XCTAssertLessThan(MasteryTier.familiar, MasteryTier.proficient)
        XCTAssertLessThan(MasteryTier.proficient, MasteryTier.mastered)
        XCTAssertEqual(max(MasteryTier.familiar, .proficient), .proficient)
    }
}
