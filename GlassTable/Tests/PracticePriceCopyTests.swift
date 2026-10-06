import XCTest
import GlassTableDrills
@testable import GlassTable

final class PracticePriceCopyTests: XCTestCase {
    func testFractionsStayTruthfulAndDefineTieShares() {
        for language in [LearningLanguage.korean, .english] {
            let twentyFive = PracticePriceCopy.threshold(25, language: language)
            let thirtyThree = PracticePriceCopy.threshold(33, language: language)
            let fifty = PracticePriceCopy.threshold(50, language: language)
            XCTAssertTrue(twentyFive.contains(language.text("네 번 중 한 번", "one in four")))
            XCTAssertTrue(thirtyThree.contains(language.text("약 세 번 중 한 번", "about one in three")))
            XCTAssertFalse(thirtyThree.contains(language.text("열 번 중 4", "4 times in 10")))
            XCTAssertTrue(fifty.contains(language.text("두 번 중 한 번", "one in two")))
            for percent in [0, 24, 25, 26, 32, 33, 34, 49, 50, 51, 100] {
                let text = PracticePriceCopy.threshold(percent, language: language)
                XCTAssertTrue(text.contains("\(percent)%"))
                XCTAssertTrue(text.contains(language.text("무승부 때 받는 지분", "your share of ties")))
                if ![25, 33, 50].contains(percent) {
                    XCTAssertFalse(text.contains(language.text("번 중", "one in")))
                }
            }
        }
    }
}
