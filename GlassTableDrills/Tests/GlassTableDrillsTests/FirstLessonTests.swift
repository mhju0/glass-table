import XCTest
@testable import GlassTableDrills

final class FirstLessonTests: XCTestCase {
    func testBothFirstLessonHandsAreLegalAndHeroWinsWithTheNamedPair() {
        for (spot, expectedWinner, expectedName) in [(FirstLesson.example, 0, "A 원 페어"),
                                                     (FirstLesson.transfer, 1, "10 원 페어")] {
            let cards = spot.hero + spot.villain + spot.board
            XCTAssertEqual(cards.count, 9)
            XCTAssertEqual(Set(cards).count, cards.count)
            XCTAssertEqual(spot.winner, expectedWinner)
            let winningHand = expectedWinner == 0 ? spot.heroBest : spot.villainBest
            XCTAssertEqual(handName(winningHand), expectedName)
            XCTAssertNotEqual(handName(spot.heroBest), handName(spot.villainBest))
        }
    }

    func testFirstLessonFeedbackComesFromTheShowdownGrader() {
        let correct = gradeShowdown(answer: 0, spot: FirstLesson.example)
        let incorrect = gradeShowdown(answer: 0, spot: FirstLesson.transfer)

        XCTAssertEqual(correct.band, .spotOn)
        XCTAssertEqual(incorrect.band, .off)
        XCTAssertTrue(correct.whyText.contains("A 원 페어"))
        XCTAssertTrue(incorrect.whyText.contains("10 원 페어"))
    }
}
