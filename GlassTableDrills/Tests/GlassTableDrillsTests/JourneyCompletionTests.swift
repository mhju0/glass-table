// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class JourneyCompletionTests: XCTestCase {
    func testCompletionRouteCountsUniqueCasesAndWithholdsTheCapstoneAnswer() throws {
        let units = TableCourseUnit.completionPractice
        XCTAssertEqual(units, [.readHands, .decideHands])
        XCTAssertTrue(Set(units).isDisjoint(with: TableCourseUnit.corePath))
        XCTAssertTrue(Set(units).isDisjoint(with: TableCourseUnit.electives))
        let lessons = units.flatMap(\.lessons)
        XCTAssertEqual(lessons.count, 21)
        let activities = lessons.flatMap { $0.unit.activities(for: $0) }
        XCTAssertEqual(activities.count(where: \.isExample), 20)
        XCTAssertEqual(activities.count(where: { !$0.isExample }), 126)
        XCTAssertEqual(Set(activities.map(\.id)).count, 146)
        XCTAssertTrue(TableCourseUnit.decideHands.activities(for: .s11).allSatisfy { !$0.isExample })

        let deals = JourneyCaseContent.deals.values
        XCTAssertEqual(Set(deals.map { $0.hero + $0.opponent + $0.turn }).count, 21)
        let otherUnits = TableCourseUnit.allCases.filter { !TableCourseUnit.completionPractice.contains($0) }
        let previous = Set(otherUnits.flatMap { unit in unit.lessons.flatMap(unit.activities(for:)) }.compactMap { item in
            item.evidence.board.count >= 4 ? item.evidence.cards + item.evidence.opponent
                + item.evidence.board.prefix(4) : nil
        })
        XCTAssertTrue(previous.isDisjoint(with: deals.map { $0.hero + $0.opponent + $0.turn }))

        for lesson in lessons {
            let deal = try XCTUnwrap(JourneyCaseContent.deals[lesson])
            let quiz = lesson.unit.activities(for: lesson).filter { !$0.isExample }
            XCTAssertEqual(quiz.map { $0.evidence.board.count }, [0, 3, 4, 4, 4, 5])
            XCTAssertTrue(quiz.prefix(4).allSatisfy { $0.evidence.opponent.isEmpty })
            XCTAssertEqual(quiz[4].evidence.opponent, deal.opponent)
            XCTAssertEqual(quiz[5].evidence.board, deal.board)
            for language in LearningLanguage.allCases {
                XCTAssertFalse(lesson.title(in: language).isEmpty)
                for q in quiz {
                    let options = q.choices(in: language)
                    XCTAssertEqual(options.count, Set(options).count, q.id)
                    XCTAssertTrue(options.indices.contains(try XCTUnwrap(q.correctChoice)), q.id)
                    XCTAssertFalse((q.prompt(in: language) ?? "").isEmpty, q.id)
                    XCTAssertFalse((q.explanation(in: language) ?? "").isEmpty, q.id)
                }
            }
        }
    }

    func testExactCorrectionAndTwoFreshQuestionsForOnlyTheMissedTopic() throws {
        let unit = TableCourseUnit.readHands
        var course = TableCourseProgress(unit: unit)
        let missed = try XCTUnwrap(unit.activities(for: .r1).first { $0.id == "R1-02" })
        while course.phase == .lesson {
            let item = try XCTUnwrap(course.activity)
            if let correct = item.correctChoice {
                let answer = item.id == missed.id ? (correct + 1) % item.optionCount : correct
                XCTAssertTrue(course.apply(.select(answer)))
                XCTAssertTrue(course.apply(.submit))
            }
            XCTAssertTrue(course.apply(.advance))
        }
        XCTAssertEqual(course.phase, .retry)
        XCTAssertEqual(course.activity, missed)
        XCTAssertNil(course.selection)
        let data = try JSONEncoder().encode(course)
        course = try JSONDecoder().decode(TableCourseProgress.self, from: data)
        XCTAssertEqual(course.activity, missed)
        var state = ProgressState(tableCourse: [unit.id: course])
        XCTAssertTrue(CourseReviewSession.eligibleSkills(in: state, scope: .journeyPractice).isEmpty)
        XCTAssertTrue(course.apply(.select(try XCTUnwrap(missed.correctChoice))))
        XCTAssertTrue(course.apply(.submit))
        XCTAssertTrue(course.apply(.advance))
        XCTAssertEqual(course.firstRight, 5)
        XCTAssertEqual(course.retryRight, 1)
        XCTAssertEqual(course.completedResults.last?.missedJourneySkills, [.journeyRange])
        XCTAssertTrue(course.apply(.advance))
        state.tableCourse?[unit.id] = course
        let eligible = CourseReviewSession.eligibleSkills(in: state, scope: .journeyPractice)
        XCTAssertEqual(eligible, [.journeyRange])
        XCTAssertTrue(CourseReviewSession.eligibleSkills(in: state).isEmpty)
        var review = try XCTUnwrap(CourseReviewSession(scope: .journeyPractice, eligibleSkills: eligible, seed: 1))
        let first = try XCTUnwrap(review.activity)
        XCTAssertTrue(review.apply(.select(try XCTUnwrap(first.correctChoice))))
        XCTAssertTrue(review.apply(.submit))
        XCTAssertTrue(review.apply(.advance))
        let next = try XCTUnwrap(review.activity)
        XCTAssertNotEqual(next.tableEvidence?.cards, first.tableEvidence?.cards)
        XCTAssertNotEqual(first.tableEvidence?.cards, missed.evidence.cards)
        XCTAssertNotEqual(next.tableEvidence?.cards, missed.evidence.cards)
        XCTAssertTrue(review.isValid(in: state))
    }
}
