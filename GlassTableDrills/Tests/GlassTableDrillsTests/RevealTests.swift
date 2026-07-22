import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class RevealTests: XCTestCase {
    private func spot() -> OutsSpot {
        OutsSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
                 board: Card.parse("Qh7h2s3c")!, outs: Card.parse("4h5h6h8h9hThJh")!,
                 excluded: Card.parse("2h3h")!)
    }

    func testExactIsSpotOn()      { XCTAssertEqual(gradeOuts(estimate: 7, spot: spot()).band, .spotOn) }
    func testWithinTwoIsClose() {
        XCTAssertEqual(gradeOuts(estimate: 9, spot: spot()).band, .close)
        XCTAssertEqual(gradeOuts(estimate: 5, spot: spot()).band, .close)
    }
    func testOffByThreeIsOff()    { XCTAssertEqual(gradeOuts(estimate: 11, spot: spot()).band, .off) }
    func testImprovementPct()     { XCTAssertEqual(gradeOuts(estimate: 7, spot: spot()).improvementPct, 14, accuracy: 1e-9) }

    func testWhyMentionsExcludedAndTrueCount() {
        let why = gradeOuts(estimate: 7, spot: spot()).whyText
        XCTAssertTrue(why.contains("2h"))
        XCTAssertTrue(why.contains("3h"))
        XCTAssertTrue(why.contains("7"))
    }

    func testWhyWithoutExcludedIsSimple() {
        let s = OutsSpot(hero: Card.parse("AhKd")!, villain: Card.parse("QsQc")!,
                         board: Card.parse("2s7h9dTc")!, outs: Card.parse("Jc")!, excluded: [])
        XCTAssertEqual(gradeOuts(estimate: 1, spot: s).whyText, "1 아웃.")
    }
}
