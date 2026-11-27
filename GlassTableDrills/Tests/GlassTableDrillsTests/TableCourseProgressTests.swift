// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import XCTest
@testable import GlassTableDrills

final class TableCourseProgressTests: XCTestCase {
    func testEachUnitKeepsTheApprovedLessonOrderAndFinishesWithSavedResults() throws {
        let expected: [(TableCourseUnit, [String])] = [
            (.turns, ["c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9"]),
            (.chips, ["d1", "d2", "d3", "d4", "d5", "d6"]),
            (.allIns, ["d7", "d8"]),
            (.tableContexts, ["m1", "m2", "m3", "m4", "m5"]),
            (.independentHands, ["n1", "n2", "n3"]),
            (.milestone, ["d-table"]),
            (.startingHands, ["e1", "e2", "e3", "e4", "e5", "e6", "e7"]),
            (.possibleHands, ["f1", "f2", "f3", "f4", "f5", "f6"]),
            (.winningCards, ["g1", "g2", "g3", "g4", "g5", "g6", "g7"]),
            (.priceChance, ["h1", "h2", "h3", "h4", "h5", "h6", "h7"]),
            (.capstone, ["i1", "i2", "i3", "i4", "i5", "i6"]),
            (.combinations, ["j1", "j2", "j3", "j4", "j5"]),
            (.expectedValue, ["k1", "k2", "k3", "k4", "k5"]),
            (.boardPatterns, ["l1", "l2", "l3", "l4", "l5"]),
        ]
        XCTAssertEqual(TableCourseUnit.corePath.flatMap(\.lessons).count
                       + UnitALesson.allCases.count + UnitBLesson.allCases.count, 76)
        XCTAssertEqual(TableCourseUnit.electives.flatMap(\.lessons).count, 15)
        XCTAssertTrue(Set(TableCourseUnit.corePath).isDisjoint(with: TableCourseUnit.electives))
        XCTAssertEqual(Set(expected.map { $0.0 }), Set(TableCourseUnit.allCases))
        var activityIDs: Set<String> = []
        for (unit, lessonIDs) in expected {
            XCTAssertEqual(unit.lessons.map(\.id), lessonIDs)
            var progress = TableCourseProgress(unit: unit)

            for lesson in unit.lessons {
                XCTAssertEqual(progress.lesson, lesson)
                let exercises = unit.activities(for: lesson)
                let questionCount = exercises.filter { !$0.isExample }.count
                XCTAssertGreaterThanOrEqual(questionCount, 3, lesson.id)
                XCTAssertEqual(progress.questionCount, questionCount)
                XCTAssertEqual(progress.stepCount, exercises.count)
                for (index, activity) in exercises.enumerated() {
                    XCTAssertTrue(activityIDs.insert(activity.id).inserted, activity.id)
                    XCTAssertEqual(progress.phase, .lesson)
                    XCTAssertEqual(progress.stepNumber, index + 1)
                    XCTAssertEqual(progress.activity, activity)
                    for language in LearningLanguage.allCases {
                        XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                        if activity.isExample {
                            XCTAssertEqual(activity.optionCount, 0, activity.id)
                        } else {
                            XCTAssertGreaterThanOrEqual(activity.optionCount, 2, activity.id)
                            XCTAssertFalse(activity.prompt(in: language)?.isEmpty ?? true, activity.id)
                            XCTAssertFalse(activity.explanation(in: language)?.isEmpty ?? true, activity.id)
                        }
                    }
                    try answerAndAdvance(&progress)
                }
                XCTAssertEqual(progress.phase, .results)
                let latest = try XCTUnwrap(progress.completedResults.last)
                XCTAssertEqual(latest.lesson, lesson)
                XCTAssertEqual(latest.firstRight, questionCount)
                XCTAssertEqual(latest.retryCount, 0)
                XCTAssertTrue(progress.apply(.advance))
                progress = try reload(progress)
            }

            XCTAssertEqual(progress.phase, .finished)
            XCTAssertEqual(progress.completedResults.map(\.lesson.id), lessonIDs)
            XCTAssertEqual(progress.completedLessons, lessonIDs.count)
            let finished = progress
            for action: TableCourseAction in [.advance, .select(0), .submit] {
                XCTAssertFalse(progress.apply(action))
                XCTAssertEqual(progress, finished)
            }
        }
    }

    func testDraftRevealAndExactMissedExercisesSurviveRelaunchInOrder() throws {
        var progress = TableCourseProgress(unit: .turns)
        let activities = progress.unit.activities(for: progress.lesson)
        let questions = activities.filter { !$0.isExample }
        let missed = [try XCTUnwrap(questions.first), try XCTUnwrap(questions.last)]
        for activity in activities {
            XCTAssertEqual(progress.activity, activity)
            guard missed.contains(activity) else {
                try answerAndAdvance(&progress)
                continue
            }
            let correct = try XCTUnwrap(activity.correctChoice)
            let wrong = try XCTUnwrap(activity.choices(in: .english).indices.first { $0 != correct })

            XCTAssertFalse(progress.apply(.advance))
            XCTAssertFalse(progress.apply(.submit))
            XCTAssertFalse(progress.apply(.select(-1)))
            XCTAssertTrue(progress.apply(.select(wrong)))
            progress = try reload(progress)
            XCTAssertEqual(progress.selection, wrong)
            XCTAssertTrue(progress.canSubmit)
            XCTAssertFalse(progress.revealed)
            XCTAssertTrue(progress.apply(.submit))
            progress = try reload(progress)
            XCTAssertEqual(progress.answeredCorrectly, false)
            XCTAssertFalse(progress.apply(.select(correct)))
            XCTAssertFalse(progress.apply(.submit))
            XCTAssertTrue(progress.apply(.advance))
        }

        XCTAssertTrue(progress.hasAnsweredLessonQuestions)
        XCTAssertEqual(progress.completedLessons, 0)
        XCTAssertEqual(progress.retryCount, 2)
        XCTAssertEqual(progress.firstRight, questions.count - 2)
        for (index, activity) in missed.enumerated() {
            XCTAssertEqual(progress.phase, .retry)
            XCTAssertEqual(progress.stepNumber, index + 1)
            XCTAssertEqual(progress.stepCount, 2)
            XCTAssertEqual(progress.activity, activity)
            XCTAssertNil(progress.selection)
            XCTAssertFalse(progress.revealed)
            let correct = try XCTUnwrap(activity.correctChoice)
            let wrong = try XCTUnwrap(activity.choices(in: .english).indices.first { $0 != correct })
            XCTAssertTrue(progress.apply(.select(index == 0 ? correct : wrong)))
            XCTAssertTrue(progress.apply(.submit))
            progress = try reload(progress)
            XCTAssertEqual(progress.answeredCorrectly, index == 0)
            XCTAssertTrue(progress.apply(.advance))
        }
        XCTAssertEqual(progress.phase, .results)
        XCTAssertEqual(progress.completedLessons, 1)
        let result = try XCTUnwrap(progress.completedResults.first)
        XCTAssertEqual(result.firstRight, questions.count - 2)
        XCTAssertEqual(result.retryRight, 1)
        XCTAssertEqual(result.retryCount, 2)
    }

    func testChipReplayResumesAtEachStreetWithoutConsumingAQuestion() throws {
        var progress = TableCourseProgress(unit: .chips)
        for lesson in [TableCourseLesson.d1, .d2, .d3, .d4, .d5] {
            XCTAssertEqual(progress.lesson, lesson)
            for _ in progress.unit.activities(for: lesson) {
                try answerAndAdvance(&progress)
            }
            XCTAssertEqual(progress.phase, .results)
            XCTAssertTrue(progress.apply(.advance))
        }
        XCTAssertEqual(progress.lesson, .d6)
        XCTAssertEqual(progress.completedLessons, 5)
        try answerAndAdvance(&progress)

        for (street, cardCount) in [("Preflop", 0), ("Flop", 3), ("Turn", 4), ("River", 5)] {
            let activity = try XCTUnwrap(progress.activity)
            XCTAssertEqual(activity.title(in: .english), street)
            XCTAssertEqual(activity.evidence.board.count, cardCount)
            XCTAssertTrue(activity.isExample)
            XCTAssertFalse(progress.apply(.select(0)))
            XCTAssertFalse(progress.apply(.submit))
            progress = try reload(progress)
            XCTAssertEqual(progress.activity, activity)
            XCTAssertEqual(progress.firstRight, 0)
            XCTAssertTrue(progress.apply(.advance))
        }
        XCTAssertFalse(try XCTUnwrap(progress.activity).isExample)
        XCTAssertEqual(progress.questionCount, 5)
    }

    func testMalformedSavedCursorAndOutOfOrderLessonsAreRejected() throws {
        var valid = TableCourseProgress(unit: .turns)
        let bytes = try JSONEncoder().encode(valid)
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        for (key, value) in [
            ("contentVersion", 2 as Any), ("lesson", "d1"), ("lesson", "c2"),
            ("activityIndex", -1), ("retryIndex", 1), ("selection", 0), ("finished", true)
        ] {
            var object = original
            object[key] = value
            let invalidBytes = try JSONSerialization.data(withJSONObject: object)
            let invalid = try JSONDecoder().decode(TableCourseProgress.self, from: invalidBytes)
            XCTAssertFalse(invalid.isValid, key)
            var copy = invalid
            XCTAssertFalse(copy.apply(.advance), key)
            XCTAssertEqual(copy, invalid)
        }
        XCTAssertTrue(valid.isValid)
        XCTAssertTrue(valid.apply(.advance))
    }

    private func answerAndAdvance(_ progress: inout TableCourseProgress) throws {
        let activity = try XCTUnwrap(progress.activity)
        if let correct = activity.correctChoice {
            XCTAssertTrue(progress.apply(.select(correct)), activity.id)
            XCTAssertTrue(progress.apply(.submit), activity.id)
            XCTAssertEqual(progress.answeredCorrectly, true, activity.id)
        }
        XCTAssertTrue(progress.apply(.advance), activity.id)
    }

    private func reload(_ progress: TableCourseProgress) throws -> TableCourseProgress {
        let data = try JSONEncoder().encode(progress)
        let restored = try JSONDecoder().decode(TableCourseProgress.self, from: data)
        XCTAssertEqual(restored, progress)
        XCTAssertTrue(restored.isValid)
        return restored
    }
}
