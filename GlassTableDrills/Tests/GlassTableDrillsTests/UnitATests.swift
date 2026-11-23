// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class UnitATests: XCTestCase {
    func testCatalogueUsesDistinctCardsAndMatchesItsDisplayedEvidence() throws {
        let lessons = UnitALesson.allCases.map { UnitAContentV1.activities(for: $0) }
        let activities = lessons.flatMap { $0 }
        XCTAssertEqual(Set(activities.map(\.id)).count, activities.count)
        for activity in activities {
            for language in LearningLanguage.allCases {
                XCTAssertFalse(activity.title(in: language).isEmpty)
                XCTAssertFalse(activity.options(in: language).contains(""))
                for choice in activity.choices.indices {
                    XCTAssertFalse(activity.feedback(in: language, for: choice).isEmpty)
                }
            }
            assertValidCards(activity.cards, id: activity.id)
            for choice in activity.choices.indices {
                assertValidCards(activity.feedbackCards(for: choice), id: activity.id)
            }
            if activity.kind == .question {
                let right = try XCTUnwrap(activity.rightIndex, activity.id)
                XCTAssertTrue(activity.choices.indices.contains(right))
                XCTAssertEqual(activity.choices.count, 2)
                XCTAssertEqual(activity.cards.flatMap(\.highlighted), [], activity.id)
            } else {
                XCTAssertNil(activity.rightIndex)
            }
        }

        let cardsLesson = try XCTUnwrap(lessons.first)
        for (activity, reveal) in [(cardsLesson[0], false), (cardsLesson[2], true)] {
            let groups = reveal ? activity.feedbackCards(for: 1) : activity.cards
            let shared = try XCTUnwrap(groups.first(where: { $0.role == .shared }))
            let own = try XCTUnwrap(groups.first(where: { $0.role == .mine }))
            XCTAssertEqual(own.cards.count, 2)
            XCTAssertEqual(own.highlighted.count, 0)
            XCTAssertEqual(Set(bestFiveCards(own.cards + shared.cards)), Set(shared.cards))
            XCTAssertEqual(Set(shared.highlighted), Set(shared.cards))
        }
        let ranks = try XCTUnwrap(lessons[1].first?.cards.first)
        XCTAssertEqual(ranks.cards.map(\.rank), Array(2...14))
        XCTAssertEqual(Set(ranks.cards.map(\.suit)), [0, 1, 2, 3])

        for activity in lessons[2].prefix(4) + [lessons[4][4]] {
            let groups = activity.kind == .example
                ? activity.cards : activity.feedbackCards(for: try XCTUnwrap(activity.rightIndex))
            let highlighted = groups.flatMap(\.highlighted)
            XCTAssertEqual(highlighted.count, 2, activity.id)
            XCTAssertEqual(Set(highlighted.map(\.rank)).count, 1, activity.id)
            XCTAssertEqual(Set(highlighted.map(\.suit)).count, 2, activity.id)
        }

        let older = Set(lessons.prefix(4).flatMap { $0 }.map { $0.cards.flatMap(\.cards) })
        let mixed = lessons[4].filter { $0.kind == .question }
        XCTAssertEqual(mixed.map(\.id), ["A5-01", "A5-02", "A5-03", "A5-04"])
        for activity in mixed {
            XCTAssertFalse(older.contains(activity.cards.flatMap(\.cards)),
                           "\(activity.id) should use a new deal for the checkpoint")
        }
    }

    func testRetryRestoresExactCardChoicesAndDoesNotOverwriteFirstScore() throws {
        var progress = UnitAProgress()
        XCTAssertFalse(progress.apply(.select(0)))
        XCTAssertTrue(progress.apply(.advance))
        let first = try XCTUnwrap(progress.activity)
        XCTAssertEqual(first.id, "A1-01")
        XCTAssertFalse(progress.apply(.advance))
        XCTAssertFalse(progress.apply(.select(-1)))
        XCTAssertFalse(progress.apply(.select(2)))
        XCTAssertTrue(progress.apply(.select(1)))
        progress = try roundTrip(progress)
        XCTAssertEqual(progress.activity, first)
        XCTAssertEqual(progress.selection, 1)
        XCTAssertFalse(progress.revealed)
        XCTAssertTrue(progress.apply(.submit))
        progress = try roundTrip(progress)
        XCTAssertTrue(progress.revealed)
        XCTAssertEqual(progress.answeredCorrectly, false)
        XCTAssertFalse(progress.apply(.submit))
        XCTAssertFalse(progress.apply(.select(0)))

        XCTAssertTrue(progress.apply(.advance))
        try walk(&progress, until: { $0.phase == .retry })
        XCTAssertEqual(progress.firstRight, 3)
        XCTAssertEqual(progress.questionCount, 4)
        XCTAssertEqual(progress.retryCount, 1)
        XCTAssertEqual(progress.stepNumber, 1)
        XCTAssertEqual(progress.stepCount, 1)
        XCTAssertEqual(progress.completedLessons, 0)
        XCTAssertEqual(progress.activity, first)
        XCTAssertNil(progress.selection)
        XCTAssertFalse(progress.revealed)
        XCTAssertTrue(progress.apply(.select(0)))
        XCTAssertTrue(progress.apply(.submit))
        progress = try roundTrip(progress)
        XCTAssertEqual(progress.activity, first)
        XCTAssertEqual(progress.answeredCorrectly, true)
        XCTAssertEqual(progress.retryRight, 1)
        XCTAssertTrue(progress.apply(.advance))
        XCTAssertEqual(progress.phase, .results)
        XCTAssertEqual(progress.firstRight, 3)
        XCTAssertEqual(progress.completedLessons, 1)
        let saved = UnitALessonResult(lesson: .privateCards, firstRight: 3, questionCount: 4,
                                      retryRight: 1, retryCount: 1)
        XCTAssertEqual(progress.completedResults, [saved])
        XCTAssertTrue(progress.apply(.advance))
        progress = try roundTrip(progress)
        XCTAssertEqual(progress.lesson, .rankAndSuit)
        XCTAssertEqual(progress.completedLessons, 1)
        XCTAssertEqual(progress.firstRight, 0)
        XCTAssertEqual(progress.completedResults, [saved])
    }

    func testStreetExamplesKeepOneDealAndRevealInOrder() throws {
        var progress = UnitAProgress()
        try walk(&progress, until: { $0.lesson == .streets })
        var previous: [Card] = []
        var original: [Card] = []
        for count in [0, 3, 4, 5] {
            let activity = try XCTUnwrap(progress.activity)
            let shared = try XCTUnwrap(activity.cards.first(where: { $0.role == .shared }))
            let own = try XCTUnwrap(activity.cards.first(where: { $0.role == .mine }))
            if count == 0 { original = own.cards }
            XCTAssertEqual(own.cards, original)
            XCTAssertEqual(shared.cards.count, count)
            XCTAssertEqual(shared.cards.prefix(previous.count), previous[...])
            XCTAssertEqual(shared.highlighted, Array(shared.cards.dropFirst(previous.count)))
            previous = shared.cards
            progress = try roundTrip(progress)
            XCTAssertEqual(progress.activity, activity)
            XCTAssertTrue(progress.apply(.advance))
        }
        XCTAssertEqual(progress.activity?.id, "A4-01")
    }

    func testBothEndingsAreUngradedAndOnlyShowdownShowsOpponentCards() throws {
        var progress = UnitAProgress()
        try walk(&progress, until: { $0.activity?.id == "A5-branch" })
        let fork = try XCTUnwrap(progress.activity)
        XCTAssertEqual(fork.cards.first(where: { $0.role == .shared })?.cards.count, 3)
        XCTAssertFalse(fork.cards.contains { $0.role == .opponent })
        for choice in fork.choices.indices {
            var branch = progress
            XCTAssertTrue(branch.apply(.select(choice)))
            branch = try roundTrip(branch)
            XCTAssertEqual(branch.selection, choice)
            XCTAssertFalse(branch.revealed)
            XCTAssertTrue(branch.apply(.submit))
            branch = try roundTrip(branch)
            XCTAssertEqual(branch.activity, fork)
            XCTAssertTrue(branch.revealed)
            XCTAssertNil(branch.answeredCorrectly)
            XCTAssertEqual(branch.firstRight, 0)
            XCTAssertEqual(branch.retryCount, 0)
            let groups = fork.feedbackCards(for: choice)
            let board = try XCTUnwrap(groups.first(where: { $0.role == .shared }))
            let own = try XCTUnwrap(groups.first(where: { $0.role == .mine }))
            if choice == 0 {
                XCTAssertEqual(board.cards.count, 3)
                XCTAssertFalse(groups.contains { $0.role == .opponent })
            } else {
                let opponent = try XCTUnwrap(groups.first(where: { $0.role == .opponent }))
                XCTAssertEqual(board.cards.count, 5)
                XCTAssertEqual(opponent.cards.count, 2)
                XCTAssertEqual(compareHands(hero: own.cards + board.cards,
                                            villain: opponent.cards + board.cards), 0)
                XCTAssertEqual(bestHand(own.cards + board.cards).category, 1)
                XCTAssertEqual(bestHand(own.cards + board.cards).topRank, 14)
            }
            XCTAssertTrue(branch.apply(.advance))
            XCTAssertEqual(branch.activity?.id, "A5-01")
            try walk(&branch, until: { $0.phase == .results })
            XCTAssertEqual(branch.questionCount, 4)
            XCTAssertEqual(branch.firstRight, 4)
            XCTAssertEqual(branch.retryCount, 0)
            XCTAssertEqual(branch.completedLessons, 5)
            let results = UnitALesson.allCases.map {
                UnitALessonResult(lesson: $0, firstRight: 4, questionCount: 4, retryRight: 0, retryCount: 0)
            }
            XCTAssertEqual(branch.completedResults, results)
            XCTAssertTrue(branch.apply(.advance))
            branch = try roundTrip(branch)
            XCTAssertEqual(branch.phase, .finished)
            XCTAssertEqual(branch.completedResults, results)
            XCTAssertFalse(branch.apply(.advance))
        }
    }

    func testInvalidAnswerAndPositionAreRejectedWithoutAdvancing() throws {
        var progress = UnitAProgress()
        XCTAssertTrue(progress.apply(.advance))
        XCTAssertTrue(progress.apply(.select(0)))
        XCTAssertTrue(progress.apply(.submit))
        let encoded = try JSONEncoder().encode(progress)
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        for (key, value) in [("contentVersion", 999 as Any), ("activityIndex", -1 as Any),
                             ("firstAnswers", [1] as Any), ("retryIndex", 4 as Any),
                             ("finished", true as Any)] {
            var invalid = original
            invalid[key] = value
            let data = try JSONSerialization.data(withJSONObject: invalid)
            var decoded = try JSONDecoder().decode(UnitAProgress.self, from: data)
            XCTAssertFalse(decoded.isValid, key)
            XCTAssertFalse(decoded.apply(.advance), key)
        }
    }

    func testEarlierResultsRequireOrderedCoverageAndPossibleCounts() throws {
        var progress = UnitAProgress()
        try walk(&progress, until: { $0.lesson == .findPair })
        XCTAssertEqual(progress.completedResults.map(\.lesson), [.privateCards, .rankAndSuit])
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(progress))
                                     as? [String: Any])
        let results = try XCTUnwrap(original["priorResults"] as? [[String: Any]])

        func assertInvalid(_ prior: [[String: Any]], _ description: String) throws {
            var payload = original
            payload["priorResults"] = prior
            let data = try JSONSerialization.data(withJSONObject: payload)
            var decoded = try JSONDecoder().decode(UnitAProgress.self, from: data)
            XCTAssertFalse(decoded.isValid, description)
            XCTAssertFalse(decoded.apply(.advance), description)
        }

        try assertInvalid([results[0]], "Missing earlier lesson")
        try assertInvalid([results[0], results[0]], "Duplicate earlier lesson")
        try assertInvalid(Array(results.reversed()), "Lessons out of order")
        for (key, value) in [("firstRight", Int.max), ("questionCount", 5),
                             ("retryRight", 1), ("retryCount", 1)] {
            var corrupt = results
            corrupt[0][key] = value
            try assertInvalid(corrupt, key)
        }
    }

    private func assertValidCards(_ groups: [UnitACardGroup], id: String) {
        let cards = groups.flatMap(\.cards)
        XCTAssertEqual(Set(cards).count, cards.count, id)
        XCTAssertEqual(Set(groups.map(\.role)).count, groups.count, id)
        for group in groups {
            XCTAssertTrue(Set(group.highlighted).isSubset(of: Set(group.cards)), id)
        }
    }

    private func roundTrip(_ value: UnitAProgress) throws -> UnitAProgress {
        let decoded = try JSONDecoder().decode(UnitAProgress.self, from: JSONEncoder().encode(value))
        XCTAssertTrue(decoded.isValid)
        XCTAssertEqual(decoded, value)
        return decoded
    }

    private func walk(_ progress: inout UnitAProgress, until stop: (UnitAProgress) -> Bool) throws {
        for _ in 0..<40 {
            if stop(progress) { return }
            if let activity = progress.activity, activity.kind != .example, !progress.revealed {
                XCTAssertTrue(progress.apply(.select(activity.rightIndex ?? 0)), activity.id)
                XCTAssertTrue(progress.apply(.submit), activity.id)
            }
            XCTAssertTrue(progress.apply(.advance))
            XCTAssertTrue(progress.isValid)
        }
        XCTFail("The path did not reach its target")
    }
}
