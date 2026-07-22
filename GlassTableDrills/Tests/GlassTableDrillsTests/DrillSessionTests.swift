import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class DrillSessionTests: XCTestCase {
    func testStartsDecidingAtInitialEstimate() {
        let s = DrillSession(baseSeed: 42)
        guard case let .deciding(spot, estimate) = s.phase else { return XCTFail("not deciding") }
        XCTAssertEqual(estimate, 8)
        XCTAssertEqual(spot, OutsSpotGenerator.spot(baseSeed: 42, index: 0))
    }

    func testAdjustEstimateClamps() {
        var s = DrillSession(baseSeed: 42)
        s.adjustEstimate(-100)
        guard case let .deciding(_, e) = s.phase else { return XCTFail() }
        XCTAssertEqual(e, 0)
    }

    func testCommitGradesAndRecords() {
        var s = DrillSession(baseSeed: 42)
        s.commit()
        guard case .revealed = s.phase else { return XCTFail("not revealed") }
        XCTAssertEqual(s.progress.total, 1)
    }

    func testNextAdvancesToNewSpot() {
        var s = DrillSession(baseSeed: 42)
        s.commit()
        s.next()
        XCTAssertEqual(s.index, 1)
        guard case let .deciding(spot, e) = s.phase else { return XCTFail() }
        XCTAssertEqual(e, 8)
        XCTAssertEqual(spot, OutsSpotGenerator.spot(baseSeed: 42, index: 1))
    }
}
