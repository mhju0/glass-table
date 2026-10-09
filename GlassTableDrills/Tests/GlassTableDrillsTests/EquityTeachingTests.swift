import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class EquityTeachingTests: XCTestCase {
    func testSharedBoardCountsHalfThePotRatherThanAWin() {
        let spot = EquitySenseSpot(hero: Card.parse("2c3d")!,
                                   villain: Card.parse("4c5d")!,
                                   board: Card.parse("AsKsQsJsTs")!)
        XCTAssertEqual(spot.equityPct, 50)
        for language in [LearningLanguage.english, .korean] {
            let reveal = gradeEquitySense(estimate: Estimate(point: 50, lo: 50, hi: 50),
                                         spot: spot, language: language)
            XCTAssertEqual(reveal.band, .spotOn)
            XCTAssertEqual(reveal.correct, 50)
            XCTAssertTrue(reveal.whyText.contains(language == .english ? "share of ties" : "무승부 몫"))
            let explanation = BeatScript.equitySense(spot, language: language)
                .compactMap(\.detail).joined(separator: " ")
            XCTAssertTrue(explanation.contains(language == .english ? "share of tied pots" : "무승부로 나눠"))
        }
    }
}
