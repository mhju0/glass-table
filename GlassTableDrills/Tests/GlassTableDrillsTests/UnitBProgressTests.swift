// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class UnitBProgressTests: XCTestCase {
    func testChoiceDraftAndRevealRestoreThenRetryTheSameDeal() throws {
        var unit = UnitBProgress()
        try reachQuestion(in: &unit)
        let activity = try XCTUnwrap(unit.activity)
        let correct = try XCTUnwrap(activity.correctChoice)
        let wrong = try XCTUnwrap(activity.choices(in: .english).indices.first { $0 != correct })

        XCTAssertFalse(unit.canSubmit)
        XCTAssertFalse(unit.apply(.advance))
        XCTAssertFalse(unit.apply(.submit))
        XCTAssertFalse(unit.apply(.select(-1)))
        XCTAssertFalse(unit.apply(.toggleCard(0)))
        XCTAssertTrue(unit.apply(.select(wrong)))
        unit = try reload(unit)
        XCTAssertEqual(unit.selection, wrong)
        XCTAssertFalse(unit.revealed)
        XCTAssertTrue(unit.canSubmit)
        XCTAssertTrue(unit.apply(.submit))
        unit = try reload(unit)
        XCTAssertTrue(unit.revealed)
        XCTAssertEqual(unit.answeredCorrectly, false)
        XCTAssertFalse(unit.apply(.select(correct)))
        XCTAssertFalse(unit.apply(.submit))
        XCTAssertTrue(unit.apply(.advance))

        while unit.phase == .lesson {
            try answerAndAdvance(&unit)
        }

        XCTAssertEqual(unit.phase, .retry)
        XCTAssertEqual(unit.activity?.id, activity.id)
        XCTAssertEqual(unit.activity?.board, activity.board)
        XCTAssertEqual(unit.activity?.learner, activity.learner)
        XCTAssertEqual(unit.activity?.opponent, activity.opponent)
        XCTAssertEqual(unit.activity?.choices(in: .korean), activity.choices(in: .korean))
        XCTAssertNil(unit.selection)
        XCTAssertFalse(unit.revealed)
        XCTAssertTrue(unit.apply(.select(correct)))
        XCTAssertTrue(unit.apply(.submit))
        unit = try reload(unit)
        XCTAssertEqual(unit.answeredCorrectly, true)
        XCTAssertTrue(unit.apply(.advance))
        XCTAssertEqual(unit.phase, .results)
        XCTAssertEqual(unit.firstRight, unit.questionCount - 1)
        XCTAssertEqual(unit.retryCount, 1)
        XCTAssertEqual(unit.retryRight, 1)
    }

    func testExistingOnePairLessonRequiresKnownPassAndRecordsOnlyOnce() throws {
        var unit = UnitBProgress()
        XCTAssertFalse(unit.apply(.completePairLesson(bestFirstRight: 8)))
        try reach(.pairComparison, in: &unit)
        XCTAssertEqual(unit.phase, .pairLesson)
        XCTAssertEqual(unit.completedLessons, 1)
        XCTAssertNil(unit.pairBestFirstRight)
        XCTAssertNil(unit.activity)
        let waiting = try reload(unit)
        for action: UnitBAction in [.advance, .select(0), .submit, .completePairLesson(bestFirstRight: 5),
                                    .completePairLesson(bestFirstRight: 9)] {
            XCTAssertFalse(unit.apply(action))
            XCTAssertEqual(unit, waiting)
        }
        XCTAssertTrue(unit.apply(.completePairLesson(bestFirstRight: 6)))
        XCTAssertFalse(unit.apply(.completePairLesson(bestFirstRight: 8)))
        unit = try reload(unit)
        XCTAssertEqual(unit.lesson, .twoPair)
        XCTAssertEqual(unit.phase, .lesson)
        XCTAssertEqual(unit.completedLessons, 2)
        let result = try XCTUnwrap(unit.completedResults.last)
        XCTAssertEqual(result.lesson, .pairComparison)
        XCTAssertEqual(result.firstRight, 6)
        XCTAssertEqual(result.questionCount, 8)
        XCTAssertEqual(unit.pairBestFirstRight, 6)
    }

    func testBestFiveDraftRejectsASixthCardAndRestoresExactRevealedPick() throws {
        var unit = UnitBProgress()
        try reach(.bestFive, in: &unit)
        while unit.activity?.kind != .bestFive {
            guard unit.phase == .lesson else { return XCTFail("B10 needs a best-five task") }
            try answerAndAdvance(&unit)
        }
        let activity = try XCTUnwrap(unit.activity)
        let indices = canonicalIndices(for: activity)
        let excluded = try XCTUnwrap((0..<7).first { !indices.contains($0) })
        XCTAssertEqual(indices.count, 5)
        XCTAssertFalse(unit.apply(.toggleCard(-1)))
        XCTAssertFalse(unit.apply(.toggleCard(7)))
        XCTAssertFalse(unit.apply(.select(0)))
        for index in indices.prefix(4) {
            XCTAssertTrue(unit.apply(.toggleCard(index)))
        }
        unit = try reload(unit)
        XCTAssertEqual(unit.selectedCardIndices, Set(indices.prefix(4)))
        XCTAssertFalse(unit.canSubmit)
        XCTAssertFalse(unit.apply(.submit))
        let fifth = try XCTUnwrap(indices.last)
        XCTAssertTrue(unit.apply(.toggleCard(fifth)))
        XCTAssertFalse(unit.apply(.toggleCard(excluded)))
        XCTAssertTrue(unit.apply(.toggleCard(fifth)))
        XCTAssertFalse(unit.canSubmit)
        XCTAssertTrue(unit.apply(.toggleCard(fifth)))
        XCTAssertTrue(unit.canSubmit)
        XCTAssertTrue(unit.apply(.submit))
        unit = try reload(unit)
        XCTAssertEqual(unit.selectedCardIndices, Set(indices))
        XCTAssertEqual(unit.activity?.id, activity.id)
        XCTAssertEqual(unit.answeredCorrectly, true)
        XCTAssertFalse(unit.apply(.toggleCard(fifth)))
        XCTAssertTrue(unit.apply(.advance))
        XCTAssertTrue(unit.selectedCardIndices.isEmpty)
    }

    func testEquivalentCardsCountButAWorseKickerDoesNot() throws {
        var unit = UnitBProgress()
        try reach(.bestFive, in: &unit)
        var verifiedEquivalent = false
        var verifiedWorseKicker = false

        while unit.phase == .lesson {
            if let activity = unit.activity, activity.kind == .bestFive {
                let cards = activity.learner + activity.board
                let canonical = canonicalIndices(for: activity)
                let possibleIndices = (0..<(1 << cards.count))
                    .filter { $0.nonzeroBitCount == 5 }
                    .map { mask in cards.indices.filter { mask & (1 << $0) != 0 } }
                let fullStrength = bestHandOfAny(cards)

                if !verifiedEquivalent, let equal = possibleIndices.first(where: {
                    $0 != canonical && compareHands(hero: $0.map { cards[$0] }, villain: cards) == 2
                }) {
                    var equivalent = unit
                    for index in equal { XCTAssertTrue(equivalent.apply(.toggleCard(index))) }
                    XCTAssertTrue(equivalent.apply(.submit))
                    XCTAssertEqual(equivalent.answeredCorrectly, true)
                    verifiedEquivalent = true
                }

                if !verifiedWorseKicker, let wrong = possibleIndices.first(where: {
                    let selection = $0.map { cards[$0] }
                    return bestHandOfAny(selection) == fullStrength
                        && compareHands(hero: selection, villain: cards) != 2
                }) {
                    var weaker = unit
                    for index in wrong { XCTAssertTrue(weaker.apply(.toggleCard(index))) }
                    XCTAssertTrue(weaker.apply(.submit))
                    XCTAssertEqual(weaker.answeredCorrectly, false)
                    verifiedWorseKicker = true
                }
            }
            try answerAndAdvance(&unit)
        }

        XCTAssertTrue(verifiedEquivalent, "The unit should exercise interchangeable physical cards.")
        XCTAssertTrue(verifiedWorseKicker, "The unit should exercise a misleadingly similar hand.")
    }

    func testAllThirteenSummariesSurviveCompletionAndRelaunch() throws {
        var unit = UnitBProgress()
        for lesson in UnitBLesson.allCases {
            XCTAssertEqual(unit.lesson, lesson)
            if lesson == .pairComparison {
                XCTAssertTrue(unit.apply(.completePairLesson(bestFirstRight: 7)))
            } else {
                while unit.phase == .lesson { try answerAndAdvance(&unit) }
                XCTAssertEqual(unit.phase, .results)
                XCTAssertEqual(unit.firstRight, unit.questionCount)
                XCTAssertGreaterThan(unit.firstRight, 0)
                XCTAssertTrue(unit.apply(.advance))
            }
            unit = try reload(unit)
        }
        XCTAssertEqual(unit.phase, .finished)
        XCTAssertEqual(unit.completedLessons, 13)
        XCTAssertEqual(unit.completedResults.map(\.lesson), UnitBLesson.allCases)
        XCTAssertEqual(unit.pairBestFirstRight, 7)
        XCTAssertTrue(unit.completedResults.allSatisfy { $0.retryCount == 0 })
        XCTAssertFalse(unit.apply(.advance))
        XCTAssertFalse(unit.apply(.submit))
    }

    func testInvalidPersistedCursorCardDraftAndSummaryAreRejected() throws {
        let start = UnitBProgress()
        XCTAssertFalse(try changed(start) { $0["activityIndex"] = -1 }.isValid)
        XCTAssertFalse(try changed(start) { $0["contentVersion"] = 999 }.isValid)
        XCTAssertFalse(try changed(start) { $0["finished"] = true }.isValid)

        var pair = start
        try reach(.twoPair, in: &pair)
        XCTAssertFalse(try changed(pair) { $0["priorResults"] = [] }.isValid)
        XCTAssertFalse(try changed(pair) {
            var prior = try XCTUnwrap($0["priorResults"] as? [[String: Any]])
            prior[1]["firstRight"] = 5
            $0["priorResults"] = prior
        }.isValid)
        XCTAssertFalse(try changed(pair) {
            let prior = try XCTUnwrap($0["priorResults"] as? [[String: Any]])
            $0["priorResults"] = Array(prior.reversed())
        }.isValid)

        var bestFive = start
        try reach(.bestFive, in: &bestFive)
        while bestFive.activity?.kind != .bestFive {
            guard bestFive.phase == .lesson else { return XCTFail("B10 needs a best-five task") }
            try answerAndAdvance(&bestFive)
        }
        XCTAssertFalse(try changed(bestFive) {
            $0["draft"] = ["cards": ["_0": [0, 0, 1, 2, 3]]]
        }.isValid)
        XCTAssertFalse(try changed(bestFive) {
            $0["draft"] = ["cards": ["_0": [7]]]
        }.isValid)
        XCTAssertFalse(try changed(bestFive) {
            $0["draft"] = ["choice": ["_0": 0]]
        }.isValid)
    }

    private func reach(_ lesson: UnitBLesson, in unit: inout UnitBProgress) throws {
        while unit.lesson != lesson {
            switch unit.phase {
            case .lesson:
                try answerAndAdvance(&unit)
            case .pairLesson:
                _ = try XCTUnwrap(unit.apply(.completePairLesson(bestFirstRight: 8)) ? true : nil)
            case .results:
                _ = try XCTUnwrap(unit.apply(.advance) ? true : nil)
            case .retry, .finished:
                XCTFail("Could not reach \(lesson)")
                return
            }
        }
    }

    private func reachQuestion(in unit: inout UnitBProgress) throws {
        while unit.activity?.kind == .example {
            _ = try XCTUnwrap(unit.apply(.advance) ? true : nil)
        }
        XCTAssertEqual(unit.activity?.kind, .choice)
    }

    private func answerAndAdvance(_ unit: inout UnitBProgress) throws {
        let activity = try XCTUnwrap(unit.activity)
        switch activity.kind {
        case .example: break
        case .choice:
            let answer = try XCTUnwrap(activity.correctChoice)
            _ = try XCTUnwrap(unit.apply(.select(answer)) ? true : nil)
            _ = try XCTUnwrap(unit.apply(.submit) ? true : nil)
        case .bestFive:
            for index in canonicalIndices(for: activity) {
                _ = try XCTUnwrap(unit.apply(.toggleCard(index)) ? true : nil)
            }
            _ = try XCTUnwrap(unit.apply(.submit) ? true : nil)
        }
        _ = try XCTUnwrap(unit.apply(.advance) ? true : nil)
        XCTAssertTrue(unit.isValid)
    }

    private func canonicalIndices(for activity: UnitBActivity) -> [Int] {
        (activity.learner + activity.board).enumerated().compactMap { index, card in
            activity.correctFive.contains(card) ? index : nil
        }
    }

    private func reload(_ unit: UnitBProgress) throws -> UnitBProgress {
        let decoded = try JSONDecoder().decode(UnitBProgress.self, from: JSONEncoder().encode(unit))
        XCTAssertEqual(decoded, unit)
        XCTAssertTrue(decoded.isValid)
        return decoded
    }

    private func changed(_ unit: UnitBProgress, edit: (inout [String: Any]) throws -> Void) throws -> UnitBProgress {
        let data = try JSONEncoder().encode(unit)
        var document = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        try edit(&document)
        let modified = try JSONSerialization.data(withJSONObject: document)
        return try JSONDecoder().decode(UnitBProgress.self, from: modified)
    }
}
