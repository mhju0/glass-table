import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class PairLessonTests: XCTestCase {
    func testZeroOneAndTenMissesQueueExactQuestionsOnceInEncounterOrder() throws {
        for misses in [Set<Int>(), [6], Set(0..<10)] {
            var lesson = PairLessonProgress(seed: 42)
            XCTAssertEqual(lesson.phase, .example)
            XCTAssertEqual(lesson.completedActivities, 0)
            XCTAssertTrue(lesson.apply(.advance))
            var missedQuestions: [PairLessonQuestion] = []

            for activity in 0..<10 {
                let question = try answer(&lesson, correctly: !misses.contains(activity))
                if misses.contains(activity) { missedQuestions.append(question) }
                XCTAssertEqual(lesson.completedActivities, activity + 2)
                XCTAssertTrue(lesson.apply(.advance))
            }
            let originalScore = 8 - misses.filter { $0 >= 2 }.count
            XCTAssertEqual(lesson.firstRight, originalScore)
            XCTAssertEqual(lesson.passed, originalScore >= 6)
            XCTAssertEqual(lesson.retryCount, misses.count)

            for (index, expected) in missedQuestions.enumerated() {
                XCTAssertEqual(lesson.phase, .retry)
                XCTAssertEqual(lesson.retryNumber, index + 1)
                XCTAssertEqual(lesson.currentQuestion, expected)
                XCTAssertEqual(lesson.completedActivities, 11)
                XCTAssertNil(lesson.selection)
                XCTAssertFalse(lesson.hintVisible)
                XCTAssertFalse(lesson.currentHelpUsed)
                XCTAssertFalse(lesson.apply(.hint))
                _ = try answer(&lesson, correctly: index > 0)
                XCTAssertTrue(lesson.apply(.advance))
            }
            XCTAssertEqual(lesson.phase, .finished)
            XCTAssertNil(lesson.currentQuestion)
            XCTAssertEqual(lesson.firstRight, originalScore)
            XCTAssertEqual(lesson.bestFirstRight, originalScore)
            XCTAssertEqual(lesson.retryRight, max(0, misses.count - 1))
            XCTAssertTrue(lesson.isValid)
            XCTAssertFalse(lesson.apply(.advance))
        }
    }

    func testDraftAndRevealRoundTripAndRejectDuplicateActions() throws {
        var lesson = PairLessonProgress(seed: 19, exampleAlreadySeen: true)
        XCTAssertEqual(lesson.phase, .guided)
        XCTAssertEqual(lesson.guidedNumber, 1)
        XCTAssertEqual(lesson.completedActivities, 1)
        XCTAssertFalse(lesson.restart(seed: 20))
        XCTAssertFalse(lesson.apply(.advance))
        XCTAssertFalse(lesson.apply(.submit))
        XCTAssertTrue(lesson.apply(.hint))
        XCTAssertTrue(lesson.apply(.select(.opponent)))
        XCTAssertFalse(lesson.apply(.select(.opponent)))
        lesson = try roundTrip(lesson)
        XCTAssertTrue(lesson.hintVisible)
        XCTAssertTrue(lesson.currentHelpUsed)
        XCTAssertEqual(lesson.selection, .opponent)
        XCTAssertFalse(lesson.revealed)
        XCTAssertTrue(lesson.apply(.select(.learner)))
        XCTAssertTrue(lesson.apply(.submit))
        lesson = try roundTrip(lesson)
        XCTAssertTrue(lesson.revealed)
        XCTAssertEqual(lesson.selection, .learner)
        XCTAssertFalse(lesson.hintVisible)
        XCTAssertFalse(lesson.apply(.submit))
        XCTAssertFalse(lesson.apply(.hint))
        XCTAssertFalse(lesson.apply(.select(.opponent)))
        XCTAssertTrue(lesson.apply(.advance))
        XCTAssertEqual(lesson.guidedNumber, 2)
        XCTAssertFalse(lesson.currentHelpUsed)
        XCTAssertNil(lesson.selection)
    }

    func testSoloHelpStaysUsedWhenHiddenAndOnlyActualMissesRetry() throws {
        var lesson = PairLessonProgress(seed: 17, exampleAlreadySeen: true)
        for _ in 0..<2 {
            _ = try answer(&lesson, correctly: true)
            XCTAssertTrue(lesson.apply(.advance))
        }
        var wrong: PairLessonQuestion?
        for index in 0..<8 {
            XCTAssertEqual(lesson.soloNumber, index + 1)
            if index < 2 {
                XCTAssertTrue(lesson.apply(.hint))
                XCTAssertTrue(lesson.hintVisible)
                XCTAssertTrue(lesson.apply(.hint))
                XCTAssertFalse(lesson.hintVisible)
                lesson = try roundTrip(lesson)
                XCTAssertTrue(lesson.currentHelpUsed)
            }
            let question = try answer(&lesson, correctly: index != 1)
            if index == 1 { wrong = question }
            XCTAssertTrue(lesson.apply(.advance))
        }
        XCTAssertEqual(lesson.firstRight, 6)
        XCTAssertEqual(lesson.assistedSoloCount, 2)
        XCTAssertEqual(lesson.retryCount, 1)
        XCTAssertEqual(lesson.currentQuestion, wrong)
        _ = try answer(&lesson, correctly: true)
        XCTAssertTrue(lesson.apply(.advance))
        XCTAssertTrue(lesson.passed)
        XCTAssertEqual(lesson.bestFirstRight, 6)
        XCTAssertEqual(lesson.retryRight, 1)
    }

    func testPublishedScheduleUsesUniqueEngineVerifiedHandsAndSeededBalance() throws {
        var observedIDs = Set<String>()
        var observedSchedules = Set<[String]>()
        for seed in UInt64(0)..<64 {
            var lesson = PairLessonProgress(seed: seed)
            XCTAssertEqual(lesson, PairLessonProgress(seed: seed))
            let example = try XCTUnwrap(lesson.currentQuestion)
            XCTAssertEqual(example.learner, Card.parse("KhKd"))
            XCTAssertEqual(example.opponent, Card.parse("JcJs"))
            XCTAssertTrue(lesson.apply(.advance))

            var questions = [example]
            for _ in 0..<10 {
                questions.append(try answer(&lesson, correctly: true))
                XCTAssertTrue(lesson.apply(.advance))
            }
            let ids = questions.map(\.id)
            XCTAssertEqual(Set(ids).count, 11)
            XCTAssertEqual(Set(questions.map { Set($0.board + $0.learner + $0.opponent) }).count, 11)
            observedIDs.formUnion(ids)
            observedSchedules.insert(ids)
            for question in questions {
                let hero = question.board + question.learner
                let villain = question.board + question.opponent
                let heroRank = bestHand(hero)
                let villainRank = bestHand(villain)
                XCTAssertEqual(heroRank.category, 1)
                XCTAssertEqual(villainRank.category, 1)
                XCTAssertNotEqual(heroRank.topRank, villainRank.topRank)
                XCTAssertEqual(Set(question.board + question.learner + question.opponent).count, 9)
                XCTAssertEqual(question.winner, heroRank.topRank > villainRank.topRank ? .learner : .opponent)
                XCTAssertEqual(compareHands(hero: hero, villain: villain), question.winner == .learner ? 0 : 1)
            }
            let winners = Array(questions.suffix(8).map(\.winner))
            XCTAssertEqual(winners.filter { $0 == .learner }.count, 4)
            XCTAssertTrue(zip(winners, winners.dropFirst()).contains { first, second in first == second })
            for start in 0...4 { XCTAssertEqual(Set(winners[start..<start + 4]).count, 2) }
        }
        XCTAssertEqual(observedIDs.count, 27)
        XCTAssertGreaterThan(observedSchedules.count, 50)
    }

    func testRestartCarriesBestAndUsesTheNewSeedsSchedule() throws {
        var lesson = PairLessonProgress(seed: 0, exampleAlreadySeen: true)
        var originalSoloHands: [PairLessonQuestion] = []
        for _ in 0..<10 {
            let wasSolo = lesson.phase == .solo
            let question = try answer(&lesson, correctly: true)
            if wasSolo { originalSoloHands.append(question) }
            XCTAssertTrue(lesson.apply(.advance))
        }
        XCTAssertTrue(lesson.restart(seed: 1))
        XCTAssertEqual(lesson.phase, .example)
        XCTAssertEqual(lesson.bestFirstRight, 8)
        XCTAssertEqual(lesson.firstRight, 0)
        XCTAssertFalse(lesson.restart(seed: 2))
        XCTAssertTrue(lesson.apply(.advance))
        var newSoloHands: [PairLessonQuestion] = []
        for _ in 0..<10 {
            let wasSolo = lesson.phase == .solo
            let question = try answer(&lesson, correctly: false)
            if wasSolo { newSoloHands.append(question) }
            XCTAssertTrue(lesson.apply(.advance))
        }
        XCTAssertTrue(Set(originalSoloHands.map(\.id)).isDisjoint(with: newSoloHands.map(\.id)))
        for _ in 0..<10 {
            _ = try answer(&lesson, correctly: true)
            XCTAssertTrue(lesson.apply(.advance))
        }
        XCTAssertFalse(lesson.passed)
        XCTAssertEqual(lesson.firstRight, 0)
        XCTAssertEqual(lesson.bestFirstRight, 8)
    }

    func testRejectsDecodedContentAndImpossibleState() throws {
        var lesson = PairLessonProgress(seed: 32, exampleAlreadySeen: true)
        _ = try answer(&lesson, correctly: false)
        let original = try dictionary(lesson)
        let invalidFields: [(String, Any)] = [
            ("contentVersion", 2), ("activityIndex", Int.min), ("activityIndex", Int.max),
            ("retryIndex", Int.min), ("retryIndex", Int.max), ("retryIndex", 1),
            ("helpUsedAt", [Int.max]), ("helpUsedAt", [0]), ("helpUsedAt", [1, 1]), ("helpUsedAt", [2]),
            ("firstAnswers", ["learner", "opponent"]), ("retryAnswers", ["learner"]),
            ("hintVisible", true), ("previousBestFirstRight", 9), ("excludedSoloIDs", ["solo-01"]),
        ]
        for (key, value) in invalidFields {
            var document = original
            document[key] = value
            try assertInvalid(document)
        }
        var invalidSelection = original
        invalidSelection["selection"] = NSNull()
        try assertInvalid(invalidSelection)

        let tokens = try XCTUnwrap(original["schedule"] as? [[String: String]])
        var invalidSchedule = original
        invalidSchedule["schedule"] = Array(tokens.dropLast())
        try assertInvalid(invalidSchedule)
        var duplicate = tokens
        duplicate[3] = tokens[4]
        invalidSchedule["schedule"] = duplicate
        try assertInvalid(invalidSchedule)
        var altered = tokens
        altered[1]["learner"] = tokens[1]["opponent"]
        invalidSchedule["schedule"] = altered
        try assertInvalid(invalidSchedule)
        var reordered = tokens
        reordered.swapAt(3, 4)
        invalidSchedule["schedule"] = reordered
        try assertInvalid(invalidSchedule)
    }

    private func answer(_ lesson: inout PairLessonProgress, correctly: Bool) throws -> PairLessonQuestion {
        let question = try XCTUnwrap(lesson.currentQuestion)
        let wrongSide: PairLessonSide = question.winner == .learner ? .opponent : .learner
        XCTAssertTrue(lesson.apply(.select(correctly ? question.winner : wrongSide)))
        XCTAssertTrue(lesson.apply(.submit))
        XCTAssertTrue(lesson.revealed)
        XCTAssertTrue(lesson.isValid)
        return question
    }

    private func dictionary(_ lesson: PairLessonProgress) throws -> [String: Any] {
        let encoded = try JSONEncoder().encode(lesson)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    }

    private func roundTrip(_ lesson: PairLessonProgress) throws -> PairLessonProgress {
        let decoded = try JSONDecoder().decode(PairLessonProgress.self, from: JSONEncoder().encode(lesson))
        XCTAssertEqual(decoded, lesson)
        XCTAssertTrue(decoded.isValid)
        return decoded
    }

    private func assertInvalid(_ document: [String: Any], file: StaticString = #filePath, line: UInt = #line) throws {
        let data = try JSONSerialization.data(withJSONObject: document)
        var decoded = try JSONDecoder().decode(PairLessonProgress.self, from: data)
        XCTAssertFalse(decoded.isValid, file: file, line: line)
        XCTAssertFalse(decoded.apply(.advance), file: file, line: line)
    }
}
