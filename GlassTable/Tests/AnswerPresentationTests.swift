import XCTest
import GlassTableEngine
import GlassTableDrills
@testable import GlassTable

final class AnswerPresentationTests: XCTestCase {
    /// A choice that gave up value never shows as right, however small the loss; the
    /// stored band, which drives progress, is untouched.
    func testEVLossChoiceThatLostValueNeverShowsAsRight() {
        var nearBest = 0
        for index in 0..<200 {
            for calls in [true, false] {
                let reveal = gradeEVLoss(userCalls: calls, spot: EVLossSpotGenerator.spot(baseSeed: 1, index: index))
                if reveal.grade.loss <= 0 {
                    XCTAssertEqual(reveal.shownBand, .spotOn)
                } else if reveal.band == .spotOn {
                    nearBest += 1
                    XCTAssertEqual(reveal.shownBand, .close)
                } else {
                    XCTAssertEqual(reveal.shownBand, reveal.band)
                }
            }
        }
        XCTAssertGreaterThan(nearBest, 0, "no near-best spot in the sample, so the rule went untested")
    }

    func testPlayTableHoleCardsReadHighCardFirst() {
        XCTAssertEqual(["7s", "Ah"].highCardFirst, ["Ah", "7s"])
        XCTAssertEqual(["Kc", "4d"].highCardFirst, ["Kc", "4d"])
        XCTAssertEqual(["9h", "9s"].highCardFirst, ["9s", "9h"])
        XCTAssertEqual(["Td"].highCardFirst, ["Td"])
    }
}
