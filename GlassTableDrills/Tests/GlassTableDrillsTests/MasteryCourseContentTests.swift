// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class MasteryCourseContentTests: XCTestCase {
    private let units: [TableCourseUnit] = [.allIns, .tableContexts, .independentHands]

    func testOriginalLessonsAndHeldOutReviewsHaveStableBilingualEvidence() throws {
        var ids = Set<String>()
        var counts = (examples: 0, questions: 0, reviews: 0)
        for unit in units {
            for lesson in unit.lessons {
                let activities = unit.activities(for: lesson)
                let skill = try XCTUnwrap(lesson.reviewSkill)
                let reviews = MasteryCourseContent.reviewActivities(for: lesson)
                XCTAssertEqual(reviews.count, 3, lesson.id)
                XCTAssertEqual(CourseReviewContent.variantCount(for: skill), reviews.count)
                let taught = activities.map(\.evidence)
                XCTAssertTrue(reviews.allSatisfy { !taught.contains($0.evidence) || $0.evidence == .init() }, lesson.id)
                let reviewCards = reviews.map(\.evidence).filter { !$0.cards.isEmpty }
                let teachingCards = activities.map(\.evidence).filter { !$0.cards.isEmpty }
                XCTAssertTrue(Set(reviewCards.map { $0.cards + $0.board + $0.opponent })
                    .isDisjoint(with: teachingCards.map { $0.cards + $0.board + $0.opponent }), lesson.id)
                counts.examples += activities.count(where: \.isExample)
                counts.questions += activities.count(where: { !$0.isExample })
                counts.reviews += reviews.count

                for (index, review) in reviews.enumerated() {
                    let mapped = try XCTUnwrap(CourseReviewContent.activity(for: skill, variant: index))
                    XCTAssertEqual(mapped.id, review.id)
                    XCTAssertEqual(mapped.correctChoice, review.correctChoice)
                    XCTAssertEqual(mapped.tableEvidence, review.evidence)
                }
                for activity in activities + reviews {
                    XCTAssertTrue(ids.insert(activity.id).inserted, activity.id)
                    let evidence = activity.evidence
                    let deal = evidence.cards + evidence.board + evidence.opponent
                    XCTAssertEqual(Set(deal).count, deal.count, activity.id)
                    for language in LearningLanguage.allCases {
                        XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                        XCTAssertFalse((activity.prompt(in: language) ?? "").isEmpty, activity.id)
                        XCTAssertFalse((activity.explanation(in: language) ?? "").isEmpty, activity.id)
                        let options = activity.choices(in: language)
                        if let answer = activity.correctChoice {
                            XCTAssertTrue(options.indices.contains(answer), activity.id)
                            XCTAssertEqual(options.count, Set(options).count, activity.id)
                        } else {
                            XCTAssertTrue(options.isEmpty, activity.id)
                        }
                    }
                }
            }
        }
        XCTAssertEqual(counts.examples, 11)
        XCTAssertEqual(counts.questions, 43)
        XCTAssertEqual(counts.reviews, 30)
    }

    func testExpectedAnswersFromIndependentCalculations() throws {
        let answers: [(TableCourseLesson, [Int])] = [
            (.d7, [1, 1, 1, 0]),
            (.d8, [0, 2, 1, 2]),
            (.m1, [2, 0, 1, 1]),
            (.m2, [0, 2, 1, 2]),
            (.m3, [1, 0, 2, 1]),
            (.m4, [2, 2, 0, 1]),
            (.m5, [1, 2, 1, 0]),
            (.n1, [1, 1, 0, 0, 1]),
            (.n2, [0, 2, 1, 1, 2]),
            (.n3, [1, 0, 0, 0, 0]),
        ]
        for (lesson, expected) in answers {
            XCTAssertEqual(lesson.unit.activities(for: lesson).compactMap(\.correctChoice), expected, lesson.id)
        }
        let turn = try XCTUnwrap(TableCourseUnit.independentHands.activities(for: .n1).first)
        XCTAssertEqual(turn.evidence.rows.dropFirst(2).map { $0.value.text(in: .english) },
                       ["12 · 0", "(12 + 0 ÷ 2) ÷ 44", "4 ÷ 21", "Calling has higher EV"])
        let heldOut = try XCTUnwrap(MasteryCourseContent.reviewActivities(for: .n1).first)
        XCTAssertEqual(heldOut.correctChoice, 1)
        XCTAssertEqual(heldOut.revealedEvidence?.rows.dropFirst(2).map { $0.value.text(in: .english) },
                       ["9 · 0", "(9 + 0 ÷ 2) ÷ 44", "6 ÷ 25", "Folding has higher EV"])
        let pot = try XCTUnwrap(TableCourseUnit.allIns.activities(for: .d8).first)
        XCTAssertEqual(pot.evidence.rows.map { $0.value.text(in: .english) }, ["3 × 40 = 120", "2 × (70 − 40) = 60", "100 − 70 = 30"])
    }

    func testExactEndRetryAndMixedReviewResumeWithDifferentEvidence() throws {
        let unit = TableCourseUnit.allIns
        var progress = TableCourseProgress(unit: unit)
        XCTAssertTrue(progress.apply(.advance))
        let missed = try XCTUnwrap(progress.activity)
        XCTAssertTrue(progress.apply(.select(0)))
        progress = try roundTrip(progress)
        XCTAssertEqual(progress.selection, 0)
        XCTAssertTrue(progress.apply(.submit))
        progress = try roundTrip(progress)
        XCTAssertEqual(progress.answeredCorrectly, false)
        XCTAssertTrue(progress.apply(.advance))
        while progress.phase == .lesson {
            try answerLesson(&progress)
        }
        XCTAssertEqual(progress.phase, .retry)
        XCTAssertEqual(progress.activity, missed)
        XCTAssertNil(progress.selection)
        progress = try roundTrip(progress)
        try answerLesson(&progress)
        XCTAssertEqual(progress.firstRight, 3)
        XCTAssertEqual(progress.retryRight, 1)
        XCTAssertTrue(progress.apply(.advance))
        while progress.phase != .finished {
            if progress.phase == .results { XCTAssertTrue(progress.apply(.advance)) }
            else { try answerLesson(&progress) }
        }
        var state = ProgressState(tableCourse: [unit.rawValue: progress])
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        state.scheduleMasteryReview(for: progress, now: now)
        let today = DayKey(now)
        let tomorrow = try XCTUnwrap(state.masteryReview?["d7"]?.dueDay)
        XCTAssertTrue(state.masteryReviewDue(on: today).isEmpty)
        XCTAssertEqual(state.masteryReviewDue(on: tomorrow), [.d7, .d8])
        XCTAssertTrue(CourseReviewSession.eligibleSkills(in: state, scope: .tableUnit(unit)).isEmpty)
        let eligible = CourseReviewSession.eligibleSkills(in: state, scope: .spacedMastery, today: tomorrow)
        var review = try XCTUnwrap(CourseReviewSession(scope: .spacedMastery, eligibleSkills: eligible, seed: 91))
        let first = try XCTUnwrap(review.activity)
        XCTAssertNotEqual(first.tableEvidence, missed.evidence)
        let right = try XCTUnwrap(first.correctChoice)
        XCTAssertTrue(review.apply(.select((right + 1) % first.choices(in: .english).count)))
        XCTAssertTrue(review.apply(.submit))
        XCTAssertTrue(review.apply(.advance))
        let second = try XCTUnwrap(review.activity)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertTrue(review.apply(.select(try XCTUnwrap(second.correctChoice))))
        XCTAssertTrue(review.apply(.submit))
        XCTAssertTrue(review.apply(.advance))
        XCTAssertEqual(review.phase, .retry)
        XCTAssertEqual(review.activity, first)
        state.courseReview = review
        state = try roundTrip(state)
        XCTAssertEqual(state.courseReview, review)
        XCTAssertTrue(state.courseReview?.isValid(in: state) == true)
        XCTAssertTrue(review.apply(.select(right)))
        XCTAssertTrue(review.apply(.submit))
        XCTAssertTrue(review.apply(.advance))
        XCTAssertEqual(review.phase, .setResults)
        XCTAssertEqual(review.firstRight, 1)
        XCTAssertEqual(review.retryRight, 1)
        XCTAssertTrue(review.apply(.advance))
        state.finishMasteryReview(review)
        state.courseReview = nil
        XCTAssertTrue(state.masteryReviewDue(on: tomorrow).isEmpty)
        XCTAssertFalse(state.hasUpcomingMasteryReview)
    }

    private func answerLesson(_ progress: inout TableCourseProgress) throws {
        if let choice = progress.activity?.correctChoice {
            XCTAssertTrue(progress.apply(.select(choice)))
            XCTAssertTrue(progress.apply(.submit))
        }
        XCTAssertTrue(progress.apply(.advance))
    }

    private func roundTrip<Value: Codable>(_ value: Value) throws -> Value {
        try JSONDecoder().decode(Value.self, from: JSONEncoder().encode(value))
    }
}
