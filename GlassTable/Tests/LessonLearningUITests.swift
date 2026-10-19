import XCTest
import GlassTableDrills
@testable import GlassTable

final class LessonLearningUITests: XCTestCase {
    func testSkillNamesKeepTheTaskPlainAndIntroduceItsPokerTerm() {
        let english = skillNames(.showdown, language: .english)
        XCTAssertEqual(english.lead, "Who wins?")
        XCTAssertEqual(english.tag, "Showdown")
        let korean = skillNames(.showdown, language: .korean)
        XCTAssertEqual(korean.tag, "쇼다운")
        XCTAssertNotEqual(korean.lead, korean.tag)
    }

    func testPositionLabelsKeepABAttachedToOriginalAnswerIndexes() throws {
        for language in [LearningLanguage.korean, .english] {
            for a in Position.allCases {
                for b in Position.allCases where a != b {
                    let spot = PositionSpot(question: .whichIsLater(a, b))
                    let zero = try XCTUnwrap(LessonSeatIdentity.answerLabels(spot: spot, input: .integer(0), language: language))
                    let one = try XCTUnwrap(LessonSeatIdentity.answerLabels(spot: spot, input: .integer(1), language: language))
                    XCTAssertEqual(zero.mine, LessonSeatIdentity.label(a, marker: "A", language: language))
                    XCTAssertEqual(one.mine, LessonSeatIdentity.label(b, marker: "B", language: language))
                    XCTAssertEqual(zero.correct, spot.correctAnswer == 0 ? zero.mine : one.mine)
                    XCTAssertEqual(one.correct, zero.correct)
                    XCTAssertTrue(zero.mine.contains(a.rawValue))
                    XCTAssertTrue(one.mine.contains(b.rawValue))
                }
            }
        }
    }

    func testEachSkillLinksToItsOwnGlossaryDefinition() {
        let expected: [Concept: String] = [.showdown: "showdown", .position: "position", .evCall: "ev",
            .evLoss: "ev-loss", .rangeNotation: "range-notation", .rfi: "rfi", .actionRead: "action-read",
            .rangeAdvantage: "range-advantage", .defend: "defend-chart", .hitFrequency: "hit-frequency"]
        for (concept, id) in expected { XCTAssertEqual(ConceptDrillView.glossaryTerm(for: concept), id) }
        for concept in Concept.allCases { XCTAssertNotNil(ConceptDrillView.glossaryTerm(for: concept)) }
    }

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
        XCTAssertEqual(Position.allCases.map(\.seatNumber), Array(1...8))
        XCTAssertEqual(Position.btn.seatNumber, 6)
        XCTAssertEqual(Position.sb.seatNumber, 7)
        XCTAssertEqual(Position.bb.seatNumber, 8)
        for seat in Position.allCases {
            let korean = seat.seatName(in: .korean).components(separatedBy: "\n")
            let english = seat.seatName(in: .english).components(separatedBy: "\n")
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

    /// The on-target choice must not always be the middle value, or a learner can skip the math.
    func testEVChoicesSpreadTheAnswerAcrossLowMiddleAndHigh() {
        var ranks = [0, 0, 0]
        let total = 300
        for seed in 0..<total {
            let spot = EVCallSpotGenerator.spot(baseSeed: UInt64(seed), index: 0)
            let choices = LessonEstimateChoices.evValues(answer: spot.evBB, seed: UInt64(seed))
            XCTAssertEqual(Set(choices).count, 3)
            XCTAssertTrue(choices.allSatisfy { $0 >= -Double(spot.bet) }, "a call cannot lose more than the bet")
            let onTarget = choices.filter { abs($0 - spot.evBB) <= 0.25 }
            XCTAssertEqual(onTarget.count, 1)
            ranks[choices.sorted().firstIndex(of: onTarget[0])!] += 1
        }
        for count in ranks {
            XCTAssertGreaterThan(count, total / 5, "value ranks \(ranks)")
        }
    }
}
