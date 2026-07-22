import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class OutsSpotGeneratorTests: XCTestCase {
    func testDeterministic() {
        XCTAssertEqual(OutsSpotGenerator.spot(baseSeed: 12345, index: 0),
                       OutsSpotGenerator.spot(baseSeed: 12345, index: 0))
    }

    func testDifferentIndicesDiffer() {
        XCTAssertNotEqual(OutsSpotGenerator.spot(baseSeed: 12345, index: 0),
                          OutsSpotGenerator.spot(baseSeed: 12345, index: 1))
    }

    func testQualityFilterWindowAndShape() {
        for i in 0..<50 {
            let s = OutsSpotGenerator.spot(baseSeed: 999, index: i)
            XCTAssertTrue((2...15).contains(s.outCount), "index \(i) had \(s.outCount) outs")
            XCTAssertEqual(s.hero.count, 2)
            XCTAssertEqual(s.villain.count, 2)
            XCTAssertEqual(s.board.count, 4)
            XCTAssertEqual(Set(s.hero + s.villain + s.board).count, 8) // all distinct
        }
    }

    func testOutsMatchEngine() {
        let s = OutsSpotGenerator.spot(baseSeed: 777, index: 3)
        XCTAssertEqual(Set(s.outs),
                       Set(countOuts(hero: s.hero, villain: s.villain, board: s.board)))
    }
}
