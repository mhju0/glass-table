// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class PairLessonFollowUpTests: XCTestCase {
    func testFreshHandFollowsSoloHelpWithoutChangingTheBaseScore() throws {
        let now = try date("2026-11-23T15:00:00Z")
        let calendar = try calendar(in: "Asia/Seoul")
        let today = PairLessonFollowUpProgress.localDay(at: now, calendar: calendar)

        let (guided, _) = try finishedLesson(seed: 17, hinted: 0)
        let guidedFollowUp = PairLessonFollowUpProgress.recordingCompletion(
            of: guided, previous: nil, at: now, calendar: calendar)
        XCTAssertNil(guidedFollowUp.attempt(for: .fresh))
        XCTAssertEqual(guided.firstRight, 8)

        let (missed, _) = try finishedLesson(seed: 17, miss: 2)
        let missedFollowUp = PairLessonFollowUpProgress.recordingCompletion(
            of: missed, previous: nil, at: now, calendar: calendar)
        XCTAssertNil(missedFollowUp.attempt(for: .fresh))
        XCTAssertEqual(missed.firstRight, 7)
        XCTAssertEqual(missed.retryRight, 1)

        let (assisted, _) = try finishedLesson(seed: 17, hinted: 2, miss: 3)
        var followUp = PairLessonFollowUpProgress.recordingCompletion(
            of: assisted, previous: nil, at: now, calendar: calendar)
        let attempt = try XCTUnwrap(followUp.attempt(for: .fresh))
        XCTAssertTrue(followUp.isAvailable(.fresh, on: today))
        XCTAssertNil(attempt.correct)
        XCTAssertFalse(followUp.apply(.hint, to: .fresh, today: today))
        try finish(&followUp, kind: .fresh, today: today)
        XCTAssertTrue(try XCTUnwrap(followUp.attempt(for: .fresh)?.correct))
        XCTAssertFalse(followUp.isAvailable(.fresh, on: today))
        XCTAssertFalse(followUp.apply(.advance, to: .fresh, today: today))
        XCTAssertEqual(assisted.firstRight, 6)
        XCTAssertEqual(assisted.bestFirstRight, 6)
        XCTAssertEqual(assisted.assistedSoloCount, 1)
        XCTAssertEqual(assisted.retryRight, 1)
        XCTAssertTrue(assisted.passed)
    }

    func testReviewOpensAtLocalMidnightEvenAcrossDSTAndWithNonGregorianSettings() throws {
        let (lesson, _) = try finishedLesson(seed: 3)
        var calendar = Calendar(identifier: .hebrew)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        for (finishedAt, beforeMidnight, afterMidnight, due) in [
            ("2026-03-08T00:15:00-05:00", "2026-03-08T23:59:59-04:00",
             "2026-03-09T00:00:00-04:00", "2026-03-09"),
            ("2026-11-01T00:15:00-04:00", "2026-11-01T23:59:59-05:00",
             "2026-11-02T00:00:00-05:00", "2026-11-02"),
            ("2026-12-31T23:59:58-05:00", "2026-12-31T23:59:59-05:00",
             "2027-01-01T00:00:00-05:00", "2027-01-01"),
        ] {
            var followUp = PairLessonFollowUpProgress.recordingCompletion(
                of: lesson, previous: nil, at: try date(finishedAt), calendar: calendar)
            let before = PairLessonFollowUpProgress.localDay(at: try date(beforeMidnight), calendar: calendar)
            let after = PairLessonFollowUpProgress.localDay(at: try date(afterMidnight), calendar: calendar)
            XCTAssertTrue(followUp.isValid)
            XCTAssertEqual(followUp.reviewDueDay.raw, due)
            XCTAssertFalse(followUp.isAvailable(.review, on: before))
            XCTAssertFalse(followUp.apply(.select(.learner), to: .review, today: before))
            XCTAssertTrue(followUp.isAvailable(.review, on: after))
            XCTAssertTrue(followUp.apply(.select(.learner), to: .review, today: after))
        }
    }

    func testReviewResumesExactDraftAndRevealedAnswerWhenTheLocalDayMovesBack() throws {
        let (lesson, _) = try finishedLesson(seed: 99, hinted: 2)
        var followUp = try makeFollowUp(lesson)
        let due = followUp.reviewDueDay
        let earlier = try XCTUnwrap(DayKey(raw: "2026-11-23"))
        let question = try XCTUnwrap(followUp.attempt(for: .review)?.question)
        let wrong: PairLessonSide = question.winner == .learner ? .opponent : .learner
        let fresh = followUp.attempt(for: .fresh)

        XCTAssertFalse(followUp.apply(.advance, to: .review, today: due))
        XCTAssertFalse(followUp.apply(.submit, to: .review, today: due))
        XCTAssertTrue(followUp.apply(.select(wrong), to: .review, today: due))
        followUp = try roundTrip(followUp)
        XCTAssertTrue(followUp.isAvailable(.review, on: earlier))
        XCTAssertEqual(followUp.attempt(for: .review)?.question, question)
        XCTAssertEqual(followUp.attempt(for: .review)?.selection, wrong)
        XCTAssertNil(followUp.attempt(for: .review)?.correct)
        XCTAssertTrue(followUp.apply(.submit, to: .review, today: earlier))
        followUp = try roundTrip(followUp)
        XCTAssertTrue(followUp.isAvailable(.review, on: earlier))
        XCTAssertEqual(followUp.attempt(for: .review)?.question, question)
        XCTAssertEqual(followUp.attempt(for: .review)?.correct, false)
        XCTAssertFalse(followUp.apply(.select(question.winner), to: .review, today: earlier))
        XCTAssertFalse(followUp.apply(.submit, to: .review, today: earlier))
        XCTAssertTrue(followUp.apply(.advance, to: .review, today: earlier))
        followUp = try roundTrip(followUp)
        XCTAssertEqual(followUp.attempt(for: .review)?.finished, true)
        XCTAssertFalse(followUp.isAvailable(.review, on: due))
        XCTAssertEqual(followUp.attempt(for: .fresh), fresh)
    }

    func testReplayKeepsPendingHandsAndSchedulesAnotherOnlyAfterFinishingThePreviousOne() throws {
        var (lesson, _) = try finishedLesson(seed: 27, hinted: 2)
        var followUp = try makeFollowUp(lesson)
        let due = followUp.reviewDueDay
        XCTAssertTrue(followUp.apply(.select(.opponent), to: .fresh, today: due))
        XCTAssertTrue(followUp.apply(.select(.learner), to: .review, today: due))
        let pending = followUp

        XCTAssertTrue(lesson.restart(seed: 28))
        _ = try finishLesson(&lesson, hinted: 2)
        followUp = try makeFollowUp(lesson, previous: followUp, day: "25")
        XCTAssertEqual(followUp, pending)

        try finish(&followUp, kind: .fresh, today: due)
        try finish(&followUp, kind: .review, today: due)
        let finished = followUp
        XCTAssertTrue(lesson.restart(seed: 29))
        _ = try finishLesson(&lesson, hinted: 2)
        followUp = try makeFollowUp(lesson, previous: followUp, day: "26")
        XCTAssertEqual(followUp.reviewDueDay.raw, "2026-11-27")
        for kind in [PairLessonFollowUpKind.fresh, .review] {
            let next = try XCTUnwrap(followUp.attempt(for: kind))
            XCTAssertNil(next.selection)
            XCTAssertFalse(next.finished)
            XCTAssertNotEqual(next.question.id, finished.attempt(for: kind)?.question.id)
        }
    }

    func testAllHeldOutDealsAreDistinctEvenByRankAndMatchTheEngine() throws {
        var baseHands = Set<Set<Int>>()
        var heldOut: [String: PairLessonQuestion] = [:]
        for seed in UInt64(0)..<64 {
            let (lesson, questions) = try finishedLesson(seed: seed, hinted: 2)
            baseHands.formUnion(questions.map { Set($0.board.map(\.rank)) })
            let followUp = try makeFollowUp(lesson)
            XCTAssertEqual(followUp, try makeFollowUp(lesson))
            for kind in [PairLessonFollowUpKind.fresh, .review] {
                let question = try XCTUnwrap(followUp.attempt(for: kind)?.question)
                heldOut[question.id] = question
            }
        }
        XCTAssertEqual(heldOut.count, 8)
        XCTAssertEqual(Set(heldOut.values.map { Set($0.board.map(\.rank)) }).count, 8)
        for question in heldOut.values {
            XCTAssertFalse(baseHands.contains(Set(question.board.map(\.rank))))
            XCTAssertEqual(Set(question.board + question.learner + question.opponent).count, 9)
            let hero = bestHand(question.board + question.learner)
            let villain = bestHand(question.board + question.opponent)
            XCTAssertEqual(hero.category, 1)
            XCTAssertEqual(villain.category, 1)
            XCTAssertNotEqual(hero.topRank, villain.topRank)
            XCTAssertEqual(question.winner, hero.topRank > villain.topRank ? .learner : .opponent)
        }
    }

    func testCorruptScheduleAndMalformedDealOrAnswerRejectWithoutCrashing() throws {
        let (lesson, _) = try finishedLesson(seed: 8, hinted: 2)
        let followUp = try makeFollowUp(lesson)
        let data = try JSONEncoder().encode(followUp)
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for (field, value) in [("contentVersion", 0 as Any), ("reviewDueDay", "2026-11-25" as Any)] {
            var document = original
            document[field] = value
            var decoded = try read(document)
            XCTAssertFalse(decoded.isValid)
            XCTAssertFalse(decoded.apply(.select(.learner), to: .review, today: followUp.reviewDueDay))
        }
        var swapped = original
        swapped["review"] = original["fresh"]
        XCTAssertFalse(try read(swapped).isValid)

        var corrupted = original
        var review = try XCTUnwrap(original["review"] as? [String: Any])
        review["finished"] = true
        corrupted["review"] = review
        XCTAssertThrowsError(try read(corrupted))
        review["revealed"] = true
        corrupted["review"] = review
        XCTAssertThrowsError(try read(corrupted))
        review["finished"] = false
        review["revealed"] = false
        var deal = try XCTUnwrap(review["deal"] as? [String: String])
        deal["board"] = "invalid"
        review["deal"] = deal
        corrupted["review"] = review
        XCTAssertThrowsError(try read(corrupted))
    }

    private func date(_ iso8601: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: iso8601))
    }

    private func calendar(in timezone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: timezone))
        return calendar
    }

    private func makeFollowUp(_ lesson: PairLessonProgress, previous: PairLessonFollowUpProgress? = nil,
                              day: String = "23") throws -> PairLessonFollowUpProgress {
        PairLessonFollowUpProgress.recordingCompletion(of: lesson, previous: previous,
            at: try date("2026-11-\(day)T12:00:00Z"), calendar: try calendar(in: "Asia/Seoul"))
    }

    private func roundTrip(_ followUp: PairLessonFollowUpProgress) throws -> PairLessonFollowUpProgress {
        let decoded = try JSONDecoder().decode(PairLessonFollowUpProgress.self,
                                               from: JSONEncoder().encode(followUp))
        XCTAssertEqual(decoded, followUp)
        XCTAssertTrue(decoded.isValid)
        return decoded
    }

    private func read(_ document: [String: Any]) throws -> PairLessonFollowUpProgress {
        let data = try JSONSerialization.data(withJSONObject: document)
        return try JSONDecoder().decode(PairLessonFollowUpProgress.self, from: data)
    }

    private func finish(_ followUp: inout PairLessonFollowUpProgress,
                        kind: PairLessonFollowUpKind, today: DayKey) throws {
        let attempt = try XCTUnwrap(followUp.attempt(for: kind))
        if attempt.selection != attempt.question.winner {
            XCTAssertTrue(followUp.apply(.select(attempt.question.winner), to: kind, today: today))
        }
        XCTAssertTrue(followUp.apply(.submit, to: kind, today: today))
        XCTAssertTrue(followUp.apply(.advance, to: kind, today: today))
    }

    private func finishedLesson(seed: UInt64, hinted: Int? = nil, miss: Int? = nil) throws
        -> (PairLessonProgress, [PairLessonQuestion]) {
        var lesson = PairLessonProgress(seed: seed)
        let questions = try finishLesson(&lesson, hinted: hinted, miss: miss)
        return (lesson, questions)
    }

    private func finishLesson(_ lesson: inout PairLessonProgress, hinted: Int?, miss: Int? = nil) throws
        -> [PairLessonQuestion] {
        let example = try XCTUnwrap(lesson.currentQuestion)
        var questions = [example]
        XCTAssertTrue(lesson.apply(.advance))
        for index in 0..<10 {
            let question = try XCTUnwrap(lesson.currentQuestion)
            questions.append(question)
            if index == hinted {
                XCTAssertTrue(lesson.apply(.hint))
                XCTAssertTrue(lesson.apply(.hint))
            }
            let wrong: PairLessonSide = question.winner == .learner ? .opponent : .learner
            XCTAssertTrue(lesson.apply(.select(index == miss ? wrong : question.winner)))
            XCTAssertTrue(lesson.apply(.submit))
            XCTAssertTrue(lesson.apply(.advance))
        }
        if let miss {
            XCTAssertEqual(lesson.currentQuestion, questions[miss + 1])
            let question = try XCTUnwrap(lesson.currentQuestion)
            XCTAssertTrue(lesson.apply(.select(question.winner)))
            XCTAssertTrue(lesson.apply(.submit))
            XCTAssertTrue(lesson.apply(.advance))
        }
        XCTAssertEqual(lesson.phase, .finished)
        return questions
    }
}
