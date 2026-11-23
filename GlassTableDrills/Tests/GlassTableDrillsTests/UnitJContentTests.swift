// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class UnitJContentTests: XCTestCase {
    private let lessons: [TableCourseLesson] = [.j1, .j2, .j3, .j4, .j5]

    func testCombinationLessonsHaveBilingualWorkedExamplesAndFreshReviewEvidence() throws {
        XCTAssertEqual(TableCourseUnit.combinations.lessons, lessons)
        var ids: Set<String> = []

        for lesson in lessons {
            let main = TableCourseUnit.combinations.activities(for: lesson)
            let review = CombinationUnitContent.reviewActivities(for: lesson)
            XCTAssertEqual(main.filter(\.isExample).count, 1)
            XCTAssertEqual(main.filter { !$0.isExample }.count, 3)
            XCTAssertTrue(try XCTUnwrap(main.first).isExample)
            XCTAssertEqual(review.count, 3)
            XCTAssertTrue(review.allSatisfy { !$0.isExample })
            var evidenceSeen: [TableCourseEvidence] = []

            for activity in main + review {
                XCTAssertTrue(ids.insert(activity.id).inserted, activity.id)
                XCTAssertFalse(evidenceSeen.contains(activity.evidence), activity.id)
                evidenceSeen.append(activity.evidence)

                let cards = activity.evidence.cards + activity.evidence.board
                XCTAssertEqual(Set(cards).count, cards.count, activity.id)
                for language in LearningLanguage.allCases {
                    XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                    XCTAssertFalse(try XCTUnwrap(activity.prompt(in: language)).isEmpty, activity.id)
                    XCTAssertFalse(try XCTUnwrap(activity.explanation(in: language)).isEmpty, activity.id)
                    if let correct = activity.correctChoice {
                        let choices = activity.choices(in: language)
                        XCTAssertTrue(choices.indices.contains(correct), activity.id)
                        XCTAssertEqual(Set(choices).count, 3, activity.id)
                        XCTAssertNotEqual(activity.evidence, try XCTUnwrap(activity.revealedEvidence), activity.id)
                    }
                }
            }
        }
        XCTAssertEqual(ids.count, 35)
    }

    func testClassCountsAndExpandedRangeTotals() throws {
        let classCounts = ["J1-01": 12, "J1-02": 6, "J1-03": 4,
                           "J1-review-01": 6, "J1-review-02": 4, "J1-review-03": 12]
        for activity in questions(.j1) {
            let expected = try XCTUnwrap(classCounts[activity.id])
            XCTAssertEqual(try selected(activity), comboCount(expected), activity.id)
        }

        let rangeCounts = ["J3-01": 22, "J3-02": 12, "J3-03": 18,
                           "J3-review-01": 36, "J3-review-02": 24, "J3-review-03": 18]
        for activity in questions(.j3) {
            let expected = try XCTUnwrap(rangeCounts[activity.id])
            XCTAssertEqual(try selected(activity), comboCount(expected), activity.id)
            let shown = try XCTUnwrap(activity.revealedEvidence)
            XCTAssertEqual(row("Total", in: shown), comboCount(expected), activity.id)
        }
        let repeated = try XCTUnwrap(questions(.j3).first(where: { $0.id == "J3-02" })?.revealedEvidence)
        XCTAssertEqual(row("Combos by class", in: repeated), "AKs · 4, AQs · 4, AJs · 4")
    }

    func testBoardRemovalCountsEachIllegalHoldingOnce() throws {
        let expectedCounts = ["J2-01": 3, "J2-02": 2, "J2-03": 7,
                              "J2-review-01": 1, "J2-review-02": 3, "J2-review-03": 6]
        for activity in questions(.j2) {
            let board = activity.evidence.board
            let label = try XCTUnwrap(row("Hand class", in: activity.evidence))
            let remaining = Deck.all.filter { !board.contains($0) }
            var combinations = 0
            for (i, first) in remaining.enumerated() {
                for second in remaining.dropFirst(i + 1) {
                    if HandClass([first, second])?.description == label {
                        combinations += 1
                    }
                }
            }
            XCTAssertEqual(combinations, expectedCounts[activity.id], activity.id)
            XCTAssertEqual(try selected(activity), comboCount(combinations), activity.id)
            let revealed = try XCTUnwrap(activity.revealedEvidence)
            XCTAssertEqual(revealed.board, board, activity.id)
            XCTAssertEqual(row("Combos left", in: revealed), comboCount(combinations), activity.id)
        }
        let worked = try XCTUnwrap(CombinationUnitContent.activities(for: .j2).first)
        XCTAssertEqual(row("Blocked combos", in: worked.evidence), "1 combo")
        XCTAssertEqual(row("One blocked combo", in: worked.evidence), "A♥ K♥")
        XCTAssertEqual(row("Combos left", in: worked.evidence), "3 combos")
    }

    func testWeightedTotalAndPhysicalCountStayDistinct() throws {
        let expected: [String: (weightedA: Int, physicalA: Int, weightedB: Int, physicalB: Int, choice: String)] = [
            "J4-01": (12, 18, 8, 8, "Range A"),
            "J4-02": (3, 12, 4, 4, "Range B"),
            "J4-03": (6, 12, 6, 6, "Equal"),
            "J4-review-01": (3, 4, 3, 6, "Equal"),
            "J4-review-02": (7, 16, 6, 6, "Range A"),
            "J4-review-03": (3, 12, 5, 10, "Range B"),
        ]
        for activity in questions(.j4) {
            let totals = try XCTUnwrap(expected[activity.id])
            XCTAssertEqual(try selected(activity), totals.choice, activity.id)
            let shown = try XCTUnwrap(activity.revealedEvidence)
            let a = try XCTUnwrap(row("Range A calculation", in: shown))
            let b = try XCTUnwrap(row("Range B calculation", in: shown))
            XCTAssertTrue(a.hasSuffix("= \(totals.weightedA) weighted combos · \(totals.physicalA) physical combos"),
                          activity.id)
            XCTAssertTrue(b.hasSuffix("= \(totals.weightedB) weighted combos · \(totals.physicalB) physical combos"),
                          activity.id)
            XCTAssertNil(row("Range A calculation", in: activity.evidence), activity.id)
        }
        let worked = try XCTUnwrap(CombinationUnitContent.activities(for: .j4).first)
        let a = try XCTUnwrap(row("Range A calculation", in: worked.evidence))
        XCTAssertTrue(a.hasSuffix("= 5.5 weighted combos · 10 physical combos"))
    }

    func testModelComparisonNamesMissingAndExtraClassesAfterTheAnswer() throws {
        let expected = [
            "J5-01": ("Add QJs", "QJs · 4 combos", "None"),
            "J5-02": ("Remove ATo", "None", "ATo · 12 combos"),
            "J5-03": ("Remove JTs and add J9s", "J9s · 4 combos", "JTs · 4 combos"),
            "J5-review-01": ("Remove KJs", "None", "KJs · 4 combos"),
            "J5-review-02": ("Remove 98o and add 98s", "98s · 4 combos", "98o · 12 combos"),
            "J5-review-03": ("Add A4s", "A4s · 4 combos", "None"),
        ]
        for activity in questions(.j5) {
            let (choice, missing, extra) = try XCTUnwrap(expected[activity.id])
            XCTAssertEqual(try selected(activity), choice, activity.id)
            XCTAssertNotNil(row("Revealed practice model", in: activity.evidence), activity.id)
            XCTAssertNil(row("Add to the estimate", in: activity.evidence), activity.id)
            XCTAssertNil(row("Remove from the estimate", in: activity.evidence), activity.id)
            let shown = try XCTUnwrap(activity.revealedEvidence)
            XCTAssertEqual(row("Add to the estimate", in: shown), missing, activity.id)
            XCTAssertEqual(row("Remove from the estimate", in: shown), extra, activity.id)
        }
    }

    private func questions(_ lesson: TableCourseLesson) -> [TableCourseActivity] {
        CombinationUnitContent.activities(for: lesson).filter { !$0.isExample }
            + CombinationUnitContent.reviewActivities(for: lesson)
    }

    private func selected(_ activity: TableCourseActivity) throws -> String {
        let index = try XCTUnwrap(activity.correctChoice)
        let choices = activity.choices(in: .english)
        return try XCTUnwrap(choices.indices.contains(index) ? choices[index] : nil)
    }

    private func row(_ label: String, in evidence: TableCourseEvidence) -> String? {
        evidence.rows.first { $0.label.text(in: .english) == label }?.value.text(in: .english)
    }

    private func comboCount(_ count: Int) -> String {
        count == 1 ? "1 combo" : "\(count) combos"
    }
}
