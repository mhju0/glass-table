// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import XCTest
@testable import GlassTableDrills

final class MasteryReviewAcceptanceTests: XCTestCase {
    func testFullReopeningAndUnactedRaiseStateTheChipsNeededByBothPlayers() throws {
        let d7 = TableCourseUnit.allIns.activities(for: .d7)
        let full = try XCTUnwrap(d7.first { $0.id == "D7-04" })
        let pending = try XCTUnwrap(d7.first { $0.id == "D7-02" })
        for language in LearningLanguage.allCases {
            XCTAssertTrue(full.prompt(in: language)?.contains("33") == true, "A and C must be able to reach 33")
            XCTAssertTrue(pending.prompt(in: language)?.contains("30") == true, "C and A have at least 21 available")
        }
    }

    func testEtiquetteQuizUsesADifferentSituationAndTheFinalHandEndsWithUnaidedTransfer() throws {
        let conduct = TableCourseUnit.tableContexts.activities(for: .m5)
        XCTAssertNotEqual(conduct[0].prompt(in: .english), conduct[3].prompt(in: .english))
        let end = TableCourseUnit.independentHands.activities(for: .n3)
        let last = try XCTUnwrap(end.last)
        XCTAssertFalse(last.isExample)
        XCTAssertFalse(end.dropLast().contains {
            !$0.evidence.cards.isEmpty && $0.evidence.cards == last.evidence.cards
        }, "The final scored decision must use an unseen hand")
    }

    func testFirstAnswersDoNotOpenReviewBeforeTheExactCorrection() throws {
        let unit = TableCourseUnit.allIns
        var p = TableCourseProgress(unit: unit)
        XCTAssertTrue(p.apply(.advance))
        let first = try XCTUnwrap(p.activity)
        for index in 0..<p.questionCount {
            let correct = try XCTUnwrap(p.activity?.correctChoice)
            XCTAssertTrue(p.apply(.select(index == 0 ? (correct + 1) % first.optionCount : correct)))
            XCTAssertTrue(p.apply(.submit))
            XCTAssertTrue(p.apply(.advance))
        }
        XCTAssertEqual(p.phase, .retry)
        XCTAssertEqual(p.activity, first)
        var state = ProgressState(tableCourse: [unit.id: p])
        state.scheduleMasteryReview(for: p, now: Date(timeIntervalSince1970: 1_800_000_000))
        XCTAssertNil(state.masteryReview)
        XCTAssertEqual(CourseReviewSession.eligibleSkills(in: state, scope: .tableUnit(unit)), [])
    }
    func testReservedSpacedDealsAreUnseenAcrossBothCatalogs() throws {
        let skills = CourseReviewSkill.allCases.filter { $0.tableLesson?.unit.usesSpacedReview == true }
        let fresh = try skills.map { try XCTUnwrap(CourseReviewContent.spacedActivity(for: $0)) }
        XCTAssertEqual(fresh.count, 10)
        XCTAssertEqual(Set(fresh.map(\.id)).count, 10)
        func deal(_ evidence: TableCourseEvidence?) -> String? {
            guard let evidence, !evidence.cards.isEmpty else { return nil }
            return (evidence.cards + evidence.opponent + evidence.board.prefix(4)).map(\.description).joined()
        }
        let oldQuestions = CourseReviewSkill.allCases.flatMap { skill in
            (0..<CourseReviewContent.variantCount(for: skill)).compactMap {
                CourseReviewContent.activity(for: skill, variant: $0)
            }
        }
        let lessons = TableCourseUnit.allCases.flatMap { unit in
            unit.lessons.flatMap(unit.activities(for:))
        }
        let old = Set(oldQuestions.compactMap { deal($0.tableEvidence) } + lessons.compactMap { deal($0.evidence) })
        let new = fresh.compactMap { deal($0.tableEvidence) }
        XCTAssertEqual(Set(new).count, new.count)
        XCTAssertTrue(Set(new).isDisjoint(with: old))
        for activity in fresh {
            let right = try XCTUnwrap(activity.correctChoice)
            for language in LearningLanguage.allCases {
                let options = activity.choices(in: language)
                XCTAssertTrue(options.indices.contains(right), activity.id)
                XCTAssertEqual(options.count, Set(options).count, activity.id)
                XCTAssertFalse(activity.detail(in: language).isEmpty, activity.id)
                XCTAssertFalse(activity.explanation(in: language).isEmpty, activity.id)
            }
        }
    }

}
