import XCTest
import GlassTableDrills
@testable import GlassTable

final class LessonLearningUITests: XCTestCase {
    func testPositionAndPotOrientationPreserveSavedBeatIndices() {
        for language in [LearningLanguage.korean, .english] {
            for seed: UInt64 in [0, 1, 0x7EAC, 0xBEEF] {
                let position = PositionSpotGenerator.spot(baseSeed: seed, index: 0)
                XCTAssertEqual(Walkthrough.make(concept: .position, seed: seed, index: 0, language: language).beats,
                               BeatScript.position(position, language: language))
                let pot = PotMathSpotGenerator.spot(baseSeed: seed, index: 0)
                XCTAssertEqual(Walkthrough.make(concept: .potMath, seed: seed, index: 0, language: language).beats,
                               BeatScript.potMath(pot, language: language))
            }
        }
    }

    func testSeatIdentityAndNormalLabelLinesAreLanguageIndependent() {
        XCTAssertEqual(Position.allCases.map(LessonSeatLoop.number), Array(1...8))
        XCTAssertEqual(LessonSeatLoop.number(.btn), 6)
        XCTAssertEqual(LessonSeatLoop.number(.sb), 7)
        XCTAssertEqual(LessonSeatLoop.number(.bb), 8)
        for seat in Position.allCases {
            let korean = LessonSeatLoop.name(seat, language: .korean).components(separatedBy: "\n")
            let english = LessonSeatLoop.name(seat, language: .english).components(separatedBy: "\n")
            XCTAssertEqual(korean.count, english.count)
            XCTAssertTrue(korean.allSatisfy { !$0.isEmpty })
            XCTAssertTrue(english.allSatisfy { !$0.isEmpty })
        }
    }

    func testEVChoicesRetainAnOnTargetPointWithoutOrderingTheAnswer() {
        for answer in [-6.23, -0.12, 0, 3.31, 12.75] {
            let choices = LessonEstimateChoices.evValues(answer: answer, seed: 42)
            XCTAssertEqual(choices, LessonEstimateChoices.evValues(answer: answer, seed: 42))
            XCTAssertEqual(Set(choices).count, 3)
            XCTAssertTrue(choices.contains { abs($0 - answer) <= 0.25 })
        }
        let orders = Set((0..<16).map { seed in
            LessonEstimateChoices.evValues(answer: 3, seed: UInt64(seed)).map { String($0) }.joined(separator: ",")
        })
        XCTAssertGreaterThan(orders.count, 1)
    }
}
