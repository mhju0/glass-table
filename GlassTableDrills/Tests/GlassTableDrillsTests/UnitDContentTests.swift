// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class UnitDContentTests: XCTestCase {
    func testLessonsAndFreshReviewsContainUniqueBilingualQuestionsWithCorrectAmounts() throws {
        let expected: [(TableCourseLesson, [Int], [Int])] = [
            (.d1, [99, 94, 92], [33, 54, 68]),
            (.d2, [3, 25, 29], [18, 28, 48]),
            (.d3, [7, 12, 13], [11, 16, 19]),
            (.d4, [2, 8, 10], [7, 12, 14]),
            (.d5, [4, 7, 5], [4, 8, 6]),
            (.d6, [53, 6, 77, 10, 6], [])
        ]

        var ids: Set<String> = []
        for (lesson, taughtAnswers, reviewAnswers) in expected {
            let taught = TableCourseUnit.chips.activities(for: lesson)
            let fresh = ChipUnitContent.reviewActivities(for: lesson)
            XCTAssertTrue(taught.first?.isExample == true, lesson.rawValue)
            XCTAssertTrue(fresh.allSatisfy { !$0.isExample }, lesson.rawValue)
            let taughtEvidence = taught.map(\.evidence)
            XCTAssertTrue(fresh.allSatisfy { !taughtEvidence.contains($0.evidence) }, lesson.rawValue)
            try assertAmounts(taught.filter { !$0.isExample }, taughtAnswers)
            try assertAmounts(fresh, reviewAnswers)
            for activity in taught + fresh {
                XCTAssertTrue(ids.insert(activity.id).inserted)
                for language in LearningLanguage.allCases {
                    XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                    XCTAssertFalse(activity.prompt(in: language)?.isEmpty ?? true, activity.id)
                    if !activity.isExample {
                        let choices = activity.choices(in: language)
                        XCTAssertEqual(Set(choices).count, 3, activity.id)
                        XCTAssertFalse(activity.explanation(in: language)?.isEmpty ?? true, activity.id)
                    }
                }
            }
        }
    }

    func testReplayPreservesWhatEachSeatPaidThisRoundAndAcrossTheHand() throws {
        let replay = TableCourseUnit.chips.activities(for: .d6).filter { $0.id.hasPrefix("D6-replay-") }
        XCTAssertEqual(replay.map { $0.evidence.board.count }, [0, 3, 4, 5])
        XCTAssertEqual(replay.map { $0.evidence.seats.map(\.chips) }, [
            [94, 99, 94, 94], [90, 99, 94, 90], [77, 99, 94, 77], [77, 99, 94, 77]
        ])
        XCTAssertEqual(replay.map { $0.evidence.seats.map(\.folded) }, [
            [false, true, false, false], [false, true, true, false],
            [false, true, true, false], [false, true, true, false]
        ])
        let ledgers = replay.map { $0.evidence.seats.map { $0.detail?.text(in: .english) } }
        XCTAssertEqual(ledgers, [
            ["Paid 6", "Paid 1", "Paid 6", "Paid 6"],
            ["4 this round · 10 total", "0 this round · 1 total", "0 this round · 6 total", "4 this round · 10 total"],
            ["13 this round · 23 total", "0 this round · 1 total", "0 this round · 6 total", "13 this round · 23 total"],
            ["0 this round · 23 total", "0 this round · 1 total", "0 this round · 6 total", "0 this round · 23 total"]
        ])
        XCTAssertTrue(replay.allSatisfy { $0.evidence.rows.isEmpty && $0.revealedEvidence == nil })
    }

    func testEachRaiseToAnswerMatchesChipsPaidByLegalEngineAction() throws {
        let lesson = TableCourseUnit.chips.activities(for: .d3).filter { !$0.isExample }
        let review = ChipUnitContent.reviewActivities(for: .d3)
        let cases: [(Int, Int, Int)] = [(5, 8, 12), (6, 10, 18), (7, 12, 20),
                                       (5, 10, 16), (8, 15, 24), (9, 18, 28)]
        XCTAssertEqual((lesson + review).count, cases.count)
        for (activity, (open, facing, total)) in zip(lesson + review, cases) {
            var table = PracticeTableState(seed: 29)
            let actions: [PracticeAction] = [.raise(to: open), .raise(to: facing), .fold, .call, .raise(to: total)]
            for (index, action) in actions.enumerated() {
                try table.apply(action, actionID: "raise-\(index)")
            }
            let paid = try XCTUnwrap(table.events.last)
            XCTAssertEqual(paid.seat, 3)
            XCTAssertEqual(table.seats[3].streetCommitted, total)
            try assertAmounts([activity], [paid.chips])
        }
    }

    func testReplayRestoresOnSameStreetAndPotTotalRequiresSubmission() throws {
        var progress = TableCourseProgress(unit: .chips)
        for lesson in TableCourseUnit.chips.lessons.prefix(5) {
            XCTAssertEqual(progress.lesson, lesson)
            for _ in TableCourseUnit.chips.activities(for: lesson) {
                let activity = try XCTUnwrap(progress.activity)
                if let correctChoice = activity.correctChoice {
                    XCTAssertTrue(progress.apply(.select(correctChoice)))
                    XCTAssertTrue(progress.apply(.submit))
                }
                XCTAssertTrue(progress.apply(.advance))
            }
            XCTAssertEqual(progress.phase, .results)
            XCTAssertTrue(progress.apply(.advance))
        }
        XCTAssertEqual(progress.lesson, .d6)
        for _ in 0..<3 { XCTAssertTrue(progress.apply(.advance)) }
        XCTAssertEqual(progress.activity?.id, "D6-replay-turn")
        let save = try JSONEncoder().encode(progress)
        var restored = try JSONDecoder().decode(TableCourseProgress.self, from: save)
        XCTAssertTrue(restored.isValid)
        XCTAssertEqual(restored.activity, progress.activity)
        XCTAssertTrue(restored.apply(.advance))
        XCTAssertTrue(restored.apply(.advance))

        let pot = try XCTUnwrap(restored.activity)
        XCTAssertEqual(pot.id, "D6-01")
        XCTAssertTrue(pot.evidence.rows.isEmpty)
        XCTAssertEqual(pot.revealedEvidence?.rows.last?.value.text(in: .english), "53 chips")
        XCTAssertTrue(restored.apply(.select(try XCTUnwrap(pot.correctChoice))))
        XCTAssertFalse(restored.revealed)
        XCTAssertTrue(restored.apply(.submit))
        XCTAssertTrue(restored.revealed)
    }

    func testMilestoneTurnCallAndShowdownBelongToTheSameValidCoachHand() throws {
        let finished = ChipUnitContent.coachHand
        try finished.validate()
        let review = try XCTUnwrap(finished.review)
        XCTAssertEqual(finished.street, .finished)
        XCTAssertEqual(review.refunds, [0, 0, 0, 0])
        XCTAssertEqual(review.contributions, [20, 1, 8, 20])
        XCTAssertEqual(review.payouts.reduce(0, +), 49)

        let activities = TableCourseUnit.milestone.activities(for: .tableMilestone)
        XCTAssertEqual(activities.count, 3)
        var hand = PracticeTableState(seed: finished.seed)
        let decisions = review.events.filter { $0.action != nil }
        for event in decisions.prefix(5) {
            try hand.apply(try XCTUnwrap(event.action), actionID: event.id)
        }
        XCTAssertEqual(hand.street, .flop)
        XCTAssertEqual(hand.currentSeat, 2)
        XCTAssertEqual(activities[0].choices(in: .english)[try XCTUnwrap(activities[0].correctChoice)], "C")
        XCTAssertEqual(activities[0].evidence.seats[1].folded, true)
        for event in decisions[5..<7] {
            try hand.apply(try XCTUnwrap(event.action), actionID: event.id)
        }
        XCTAssertEqual(hand.currentSeat, 0)
        try assertAmounts([activities[1]], [hand.amountToCall])

        let showdown = activities[2]
        let board = review.board.compactMap(Card.init)
        XCTAssertEqual(showdown.evidence.board, board)
        XCTAssertTrue(showdown.evidence.rows.isEmpty)
        XCTAssertEqual(showdown.revealedEvidence?.rows.count, 3)
        let a = review.holeCards[0].compactMap(Card.init) + board
        let d = review.holeCards[3].compactMap(Card.init) + board
        let result = compareHands(hero: a, villain: d)
        let winners = result == 0 ? [0] : result == 1 ? [3] : [0, 3]
        XCTAssertTrue(review.pots.allSatisfy { $0.winners == winners })
        XCTAssertEqual(showdown.choices(in: .english)[try XCTUnwrap(showdown.correctChoice)],
                       "The remaining players’ best five cards")
    }

    private func assertAmounts(_ activities: [TableCourseActivity], _ counts: [Int]) throws {
        XCTAssertEqual(activities.count, counts.count)
        for (activity, count) in zip(activities, counts) {
            let answer = try XCTUnwrap(activity.correctChoice, activity.id)
            XCTAssertEqual(activity.choices(in: .english)[answer], count == 1 ? "1 chip" : "\(count) chips", activity.id)
            XCTAssertEqual(activity.choices(in: .korean)[answer], "칩 \(count)개", activity.id)
        }
    }
}
