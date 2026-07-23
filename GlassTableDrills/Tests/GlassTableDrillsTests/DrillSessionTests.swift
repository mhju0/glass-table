import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class DrillSessionTests: XCTestCase {
    private func session() -> DrillSession<OutsSpot, Int, OutsReveal> {
        DrillSession(baseSeed: 42,
                     generate: OutsSpotGenerator.spot(baseSeed:index:),
                     grade: { gradeOuts(estimate: $0, spot: $1) })
    }

    func testStartsDeciding() {
        guard case let .deciding(spot) = session().phase else { return XCTFail("not deciding") }
        XCTAssertEqual(spot, OutsSpotGenerator.spot(baseSeed: 42, index: 0))
    }

    func testCommitGradesAndRecords() {
        var s = session()
        s.commit(8)
        guard case let .revealed(_, reveal) = s.phase else { return XCTFail("not revealed") }
        XCTAssertEqual(reveal.estimate, 8)
        XCTAssertEqual(s.progress.total, 1)
    }

    func testCommitWhileRevealedIsNoOp() {
        var s = session()
        s.commit(8)
        s.commit(9)
        XCTAssertEqual(s.progress.total, 1)
    }

    func testNextAdvancesToNewSpot() {
        var s = session()
        s.commit(8)
        s.next()
        XCTAssertEqual(s.index, 1)
        guard case let .deciding(spot) = s.phase else { return XCTFail("not deciding") }
        XCTAssertEqual(spot, OutsSpotGenerator.spot(baseSeed: 42, index: 1))
    }

    // Regression: a session must resume at the caller-provided index, not spot 0 —
    // the app passes progress.total so re-entering a drill never repeats answered spots.
    func testStartIndexResumesSequence() {
        var s = DrillSession(baseSeed: 42,
                             progress: DrillProgress(),
                             startIndex: 3,
                             generate: OutsSpotGenerator.spot(baseSeed:index:),
                             grade: { gradeOuts(estimate: $0, spot: $1) })
        XCTAssertEqual(s.index, 3)
        guard case let .deciding(spot) = s.phase else { return XCTFail("not deciding") }
        XCTAssertEqual(spot, OutsSpotGenerator.spot(baseSeed: 42, index: 3))
        s.commit(8)
        s.next()
        XCTAssertEqual(s.index, 4)
    }
}
