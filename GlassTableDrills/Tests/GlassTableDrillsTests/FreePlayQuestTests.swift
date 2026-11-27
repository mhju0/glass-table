// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
@testable import GlassTableDrills

final class FreePlayQuestTests: XCTestCase {
    func testRecognitionCountsOnALossAndCanOnlyBeRecordedOnce() throws {
        let table = try XCTUnwrap((0..<20).lazy.compactMap { seed -> PracticeTableState? in
            let hand = try? self.settled(seed: UInt64(seed), styles: [.station])
            guard let hand, let review = hand.review, review.endingStacks[0] < review.startingStacks[0],
                  FreePlayQuestQuestion(hand) != nil else { return nil }
            return hand
        }.first)
        let question = try XCTUnwrap(FreePlayQuestQuestion(table))
        XCTAssertEqual(question.choices.count, 3)
        XCTAssertEqual(Set(question.choices).count, 3)
        let answer = question.hand.category
        var quest = FreePlayQuest()
        XCTAssertFalse(quest.resolve(9, table: table))
        XCTAssertTrue(quest.resolve(answer, table: table))
        XCTAssertEqual(quest.correct, 1)
        XCTAssertFalse(quest.resolve(answer, table: table))
        XCTAssertTrue(quest.isValid(for: table))

        var next = table
        try next.nextHand(handID: "second")
        quest.beginNextHand()
        XCTAssertFalse(quest.resolve(answer, table: next))
        XCTAssertTrue(quest.isValid(for: next))
        XCTAssertEqual(quest.correct, 1)
        XCTAssertNil(quest.response)
    }

    func testWrongAndSkippedAnswersLeaveCreditUnchanged() throws {
        let table = try settled(seed: 97, styles: [.station])
        let question = try XCTUnwrap(FreePlayQuestQuestion(table))
        let wrong = try XCTUnwrap(question.choices.first { $0 != question.hand.category })
        for answer in [Optional(wrong), nil] {
            var quest = FreePlayQuest()
            XCTAssertTrue(quest.resolve(answer, table: table))
            XCTAssertEqual(quest.correct, 0)
            XCTAssertEqual(quest.response?.category, answer)
            XCTAssertTrue(quest.isValid(for: table))
            XCTAssertFalse(quest.resolve(question.hand.category, table: table))
        }
    }

    func testQuestionExcludesFoldBeforeTwoOtherPlayersShowDown() throws {
        let table = try XCTUnwrap((0..<20).lazy.compactMap { seed -> PracticeTableState? in
            let hand = try? self.settled(seed: UInt64(seed), styles: [.station, .station], fold: true)
            guard let hand, let review = hand.review, review.pots.contains(where: { $0.eligibleSeats.count > 1 }) else {
                return nil
            }
            return hand
        }.first)
        XCTAssertTrue(table.seats[0].folded)
        XCTAssertNil(FreePlayQuestQuestion(table))
        var quest = FreePlayQuest()
        XCTAssertFalse(quest.resolve(nil, table: table))
        XCTAssertTrue(quest.isValid(for: table))
    }

    private func settled(seed: UInt64, styles: [Archetype], fold: Bool = false) throws -> PracticeTableState {
        var table = PracticeTableState(seed: seed, styles: styles, handID: "quest-test")
        if fold { try table.apply(.fold, actionID: "hero-fold") }
        try table.advanceBots()
        for index in 0..<20 where table.review == nil {
            let action: PracticeAction = table.legalActions.contains(.check) ? .check : .call
            try table.apply(action, actionID: "learner-\(index)")
            try table.advanceBots()
        }
        return table
    }
}
