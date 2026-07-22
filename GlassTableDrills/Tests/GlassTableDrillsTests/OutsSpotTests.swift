import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class OutsSpotTests: XCTestCase {
    func testDerivedValues() {
        let spot = OutsSpot(
            hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
            board: Card.parse("Qh7h2s3c")!,
            outs: Card.parse("4h5h6h8h9hThJh")!,
            excluded: Card.parse("2h3h")!)
        XCTAssertEqual(spot.outCount, 7)
        XCTAssertEqual(spot.improvementPct, 14, accuracy: 1e-9)  // 7 outs × 2 (rule of 2)
    }
}
