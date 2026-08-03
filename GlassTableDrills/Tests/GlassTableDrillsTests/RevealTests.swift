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
        // Copy names cards with suit symbols; "2h" is the parse format, not prose.
        XCTAssertTrue(why.contains("2♥"))
        XCTAssertTrue(why.contains("3♥"))
        XCTAssertTrue(why.contains("7"))
    }

    func testExplainRiverOut() {
        // 4h river: hero completes the ace-high flush, villain stays on trip queens.
        let ex = explainRiver(spot: spot(), river: Card("4h")!)
        XCTAssertEqual(ex.hero, HandBrief(category: 5, topRank: 14))
        XCTAssertEqual(ex.villain, HandBrief(category: 3, topRank: 12))
        XCTAssertTrue(ex.heroWins)
    }

    func testExplainRiverExcluded() {
        // 2h river: hero's flush completes but the board pairs villain into a full house.
        let ex = explainRiver(spot: spot(), river: Card("2h")!)
        XCTAssertEqual(ex.hero, HandBrief(category: 5, topRank: 14))
        XCTAssertEqual(ex.villain, HandBrief(category: 6, topRank: 12))
        XCTAssertFalse(ex.heroWins)
    }

    func testHandNames() {
        XCTAssertEqual(handName(HandBrief(category: 1, topRank: 14)), "A 원 페어")
        XCTAssertEqual(handName(HandBrief(category: 4, topRank: 5)), "5 하이 스트레이트")
        XCTAssertEqual(handName(HandBrief(category: 5, topRank: 13)), "K 하이 플러시")
        XCTAssertEqual(handName(HandBrief(category: 6, topRank: 10)), "10 풀하우스")
        XCTAssertEqual(handName(HandBrief(category: 8, topRank: 14)), "로열 플러시")
    }

    func testWhyWithoutExcludedIsSimple() {
        let s = OutsSpot(hero: Card.parse("AhKd")!, villain: Card.parse("QsQc")!,
                         board: Card.parse("2s7h9dTc")!, outs: Card.parse("Jc")!, excluded: [])
        XCTAssertEqual(gradeOuts(estimate: 1, spot: s).whyText, "1 아웃.")
    }
}
