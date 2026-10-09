// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
import GlassTableDrills
@testable import GlassTable

final class GuidedHandTests: XCTestCase {
    func testLegalDealAndChipLedgerAcrossSeededReplays() {
        for seed: UInt64 in 0..<16 {
            var hand = GuidedHandState(seed: seed)
            for lessGuidance in [false, true] {
                hand.replay(lessGuidance: lessGuidance)
                let dealt = hand.hero + hand.opponent + hand.board
                XCTAssertEqual(Set(dealt).count, 9)
                XCTAssertTrue(dealt.allSatisfy { Deck.all.contains($0) })
                XCTAssertEqual(hand.showdown.winner, lessGuidance ? 1 : 0)
                XCTAssertEqual(hand.pot, 3)
                hand.next()
                XCTAssertEqual(hand.visibleBoard.count, 0)
                XCTAssertEqual(hand.pot, 3)
                hand.choose(hand.correct)
                XCTAssertEqual(hand.pot, 4)
                hand.next()
                XCTAssertEqual(hand.pot, 4)
                XCTAssertEqual(hand.visibleBoard.count, 3)
                hand.choose(hand.correct); hand.next()
                XCTAssertEqual(hand.pot, 6)
                XCTAssertEqual(hand.visibleBoard.count, 4)
                hand.choose(hand.correct)
                XCTAssertEqual(hand.pot, 8)
                hand.next()
                XCTAssertEqual(hand.visibleBoard.count, 5)
            }
        }
    }

    func testCompleteWrongAnswersPreviousAndReplayRemainLocal() {
        var hand = GuidedHandState()
        hand.next()
        for page in 1...5 {
            XCTAssertEqual(hand.page, page)
            hand.next()
            XCTAssertEqual(hand.page, page, "A choice is required before the reveal advances.")
            let wrong = hand.correct == 0 ? 1 : 0
            hand.choose(wrong)
            XCTAssertEqual(hand.answers[page], wrong)
            hand.choose(hand.correct)
            XCTAssertEqual(hand.answers[page], wrong, "Committed choices cannot be overwritten.")
            hand.next()
            hand.previous()
            XCTAssertEqual(hand.answers[page], wrong)
            hand.next()
        }
        XCTAssertEqual(hand.page, 6)
        hand.replay(lessGuidance: true)
        XCTAssertEqual(hand.page, 0)
        XCTAssertTrue(hand.answers.isEmpty)
        XCTAssertTrue(hand.lessGuidance)
        hand.next()
        for _ in 1...5 { hand.choose(hand.correct); hand.next() }
        XCTAssertEqual(hand.page, 6)
        XCTAssertEqual(hand.answers[5], hand.showdown.winner)
        hand.replay(lessGuidance: false)
        XCTAssertFalse(hand.lessGuidance)
        XCTAssertTrue(hand.answers.isEmpty)
    }

    func testRestoredRangeEvidenceEqualsLiveForLegacyAndBandAnswers() throws {
        let inputs: [DrillSubmittedInput] = [.range(width: 30, tendencies: []),
                                            .rangeBand(width: 42, excludedTop: 8, tendencies: [])]
        for input in inputs {
            let bytes = try JSONEncoder().encode(input)
            let resumed = try JSONDecoder().decode(DrillSubmittedInput.self, from: bytes)
            for language in [LearningLanguage.korean, .english] {
                let direct = try XCTUnwrap(RestoredLessonEvidence.rangeReveal(seed: 7, index: 1, input: input, language: language))
                let restored = try XCTUnwrap(RestoredLessonEvidence.rangeReveal(seed: 7, index: 1, input: resumed, language: language))
                XCTAssertEqual(direct, restored)
                let estimate = RangeEstimate(width: input == inputs[0] ? 30 : 42, tendencies: [], excludedTop: input == inputs[0] ? 0 : 8)
                XCTAssertEqual(restored, gradeRangeRead(estimate: estimate, spot: RangeReadSpotGenerator.spot(baseSeed: 7, index: 1), language: language))
            }
        }
    }

    func testRestoredPositionLabelsUseSameNumberedPlainSeats() throws {
        for language in [LearningLanguage.korean, .english] {
            for seed: UInt64 in 0..<40 {
                let spot = PositionSpotGenerator.spot(baseSeed: seed, index: 0)
                guard case let .whichIsLater(a, b) = spot.question else { continue }
                for choice in [0, 1] {
                    let input = DrillSubmittedInput.integer(choice)
                    let resumed = try JSONDecoder().decode(DrillSubmittedInput.self, from: JSONEncoder().encode(input))
                    let description = try XCTUnwrap(RestoredDrillDescription.make(concept: .position, seed: seed, index: 0, input: resumed, stored: nil, language: language))
                    XCTAssertEqual(description.mine, RestoredLessonEvidence.positionLabel(choice == 0 ? a : b, language: language))
                    XCTAssertFalse(description.mine.contains((choice == 0 ? a : b).rawValue))
                }
            }
        }
    }
}
