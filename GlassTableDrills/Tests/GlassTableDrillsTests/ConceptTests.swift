import XCTest
@testable import GlassTableDrills

final class ConceptTests: XCTestCase {
    func testRosterIsTheTenR1Concepts() {
        XCTAssertEqual(Concept.allCases.count, 10)
        XCTAssertEqual(Set(Concept.allCases.map(\.rawValue)),
                       ["showdown", "potMath", "position", "combos", "potOdds",
                        "outs", "equitySense", "evCall", "callFold", "mdf"])
    }

    /// Spec §5.4: interval input only where the answer is genuinely estimated.
    func testOnlyEstimationConceptsTakeAnInterval() {
        XCTAssertEqual(Set(Concept.allCases.filter(\.isEstimation)),
                       [.equitySense, .evCall, .outs])
        for c in [Concept.showdown, .potMath, .position, .combos, .potOdds, .callFold, .mdf] {
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
