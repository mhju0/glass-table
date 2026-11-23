// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
@testable import GlassTableDrills

final class UnitKContentTests: XCTestCase {
    func testEachLessonHasWorkedEvidenceAndFreshBilingualReview() throws {
        let unit = TableCourseUnit.expectedValue
        XCTAssertEqual(unit.lessons, [.k1, .k2, .k3, .k4, .k5])
        var ids: Set<String> = []

        for lesson in unit.lessons {
            let practice = unit.activities(for: lesson)
            let review = ExpectedValueUnitContent.reviewActivities(for: lesson)
            XCTAssertEqual(practice.count, 4, lesson.id)
            XCTAssertTrue(try XCTUnwrap(practice.first).isExample, lesson.id)
            XCTAssertEqual(review.count, 3, lesson.id)
            let graded = practice.dropFirst() + review
            var evidenceSeen: [TableCourseEvidence] = []

            for activity in practice + review {
                XCTAssertTrue(ids.insert(activity.id).inserted, activity.id)
                XCTAssertFalse(evidenceSeen.contains(activity.evidence), activity.id)
                evidenceSeen.append(activity.evidence)
                for language in LearningLanguage.allCases {
                    XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                    XCTAssertFalse(try XCTUnwrap(activity.prompt(in: language)).isEmpty, activity.id)
                    XCTAssertFalse(try XCTUnwrap(activity.explanation(in: language)).isEmpty, activity.id)
                }
            }

            for activity in graded {
                let answer = try XCTUnwrap(activity.correctChoice, activity.id)
                for language in LearningLanguage.allCases {
                    let choices = activity.choices(in: language)
                    XCTAssertEqual(Set(choices).count, 3, activity.id)
                    XCTAssertTrue(choices.indices.contains(answer), activity.id)
                }
                let shown = try XCTUnwrap(activity.revealedEvidence, activity.id)
                XCTAssertEqual(Array(shown.rows.prefix(activity.evidence.rows.count)), activity.evidence.rows, activity.id)
                XCTAssertGreaterThan(shown.rows.count, activity.evidence.rows.count, activity.id)
            }
        }
        XCTAssertEqual(ids.count, 35)
    }

    func testDecisionPointNetKeepsCommittedChipsOutButWholeHandIncludesThem() throws {
        let expected: [String: (net: Int, wholeHand: Int)] = [
            "K1-example": (28, 22), "K1-01": (7, 2), "K1-02": (0, -8), "K1-03": (52, 40),
            "K1-review-01": (19, 16), "K1-review-02": (0, -11), "K1-review-03": (7, -2),
        ]
        for activity in activities(.k1) {
            let values = try XCTUnwrap(expected[activity.id])
            let shown = try evidence(for: activity, hiding: "Net from this decision")
            XCTAssertEqual(try equationResult("Net from this decision", in: shown), Double(values.net), activity.id)
            XCTAssertEqual(try equationResult("Net over the whole hand", in: shown), Double(values.wholeHand), activity.id)
            if !activity.isExample {
                XCTAssertEqual(try number(try selected(activity)), Double(values.net), activity.id)
            }
        }
    }

    func testWeightedEVIncludesHalfPotTiesAndCanDisagreeWithTheRealizedResult() throws {
        let expected: [String: Double] = [
            "K2-example": 3.2, "K2-01": 0, "K2-02": -2, "K2-03": 2.5,
            "K2-review-01": 1, "K2-review-02": -4.5, "K2-review-03": 0,
        ]
        for activity in activities(.k2) {
            let ev = try XCTUnwrap(expected[activity.id])
            let shown = try evidence(for: activity, hiding: "Call EV")
            XCTAssertEqual(try equationResult("Call EV", in: shown), ev, activity.id)

            let pot = try number(try XCTUnwrap(row("Pot with opponent’s bet", in: shown)))
            let cost = try number(try XCTUnwrap(row("Extra to call", in: shown)))
            let counts = try XCTUnwrap(row("Wins · Ties · Losses", in: shown))
                .components(separatedBy: " · ").compactMap(Int.init)
            XCTAssertEqual(counts.count, 3, activity.id)
            XCTAssertEqual(counts.reduce(0, +), 10, activity.id)
            let halfPotNet = (pot + cost) / 2 - cost
            XCTAssertEqual(try equationResult("Net on a tie", in: shown), halfPotNet, activity.id)
            if !activity.isExample {
                XCTAssertEqual(try number(try selected(activity)), ev, activity.id)
            }
        }

        let winningHand = try XCTUnwrap(activities(.k2).first { $0.id == "K2-02" })
        let losingHand = try XCTUnwrap(activities(.k2).first { $0.id == "K2-03" })
        XCTAssertEqual(row("Result on one hand", in: winningHand.evidence), "Win")
        XCTAssertEqual(try number(try selected(winningHand)), -2)
        XCTAssertEqual(row("Result on one hand", in: losingHand.evidence), "Loss")
        XCTAssertEqual(try number(try selected(losingHand)), 2.5)
    }

    func testCallAndFoldUseTheSameDecisionBaselineAndCanTie() throws {
        let expected: [String: (callEV: Double, choice: String)] = [
            "K3-example": (3, "Call"), "K3-01": (-3, "Fold"), "K3-02": (0, "Same EV"), "K3-03": (7, "Call"),
            "K3-review-01": (3, "Call"), "K3-review-02": (0, "Same EV"), "K3-review-03": (-3, "Fold"),
        ]
        for activity in activities(.k3) {
            let values = try XCTUnwrap(expected[activity.id])
            let shown = try evidence(for: activity, hiding: "Call EV")
            XCTAssertEqual(try equationResult("Call EV", in: shown), values.callEV, activity.id)
            XCTAssertEqual(row("Fold EV", in: shown), "0 chips", activity.id)
            if !activity.isExample {
                XCTAssertEqual(try selected(activity), values.choice, activity.id)
            }
        }
    }

    func testEVGapComparesTwoNonzeroActionsAndCanBeZero() throws {
        let expected: [String: (check: Double, bet: Double, gap: Double)] = [
            "K4-example": (9, 15, 6), "K4-01": (12, 4, 8), "K4-02": (36, 36, 0), "K4-03": (13.5, 22.5, 9),
            "K4-review-01": (15, 16.5, 1.5), "K4-review-02": (14, 10, 4), "K4-review-03": (25, 25, 0),
        ]
        for activity in activities(.k4) {
            let values = try XCTUnwrap(expected[activity.id])
            let shown = try evidence(for: activity, hiding: "EV given up")
            XCTAssertEqual(try number(try XCTUnwrap(row("Check EV", in: shown))), values.check, activity.id)
            XCTAssertEqual(try number(try XCTUnwrap(row("Bet EV", in: shown))), values.bet, activity.id)
            XCTAssertEqual(try equationResult("EV given up", in: shown), values.gap, activity.id)
            if !activity.isExample {
                XCTAssertEqual(try number(try selected(activity)), values.gap, activity.id)
            }
        }
    }

    func testPureBluffThresholdBreaksEvenAcrossTheRangeAndDoesNotPickAHand() throws {
        let worked = try XCTUnwrap(activities(.k5).first)
        XCTAssertEqual(row("Minimum defense frequency (MDF)", in: worked.evidence), "30 ÷ 50 = 60%")
        XCTAssertEqual(try equationResult("Bluff EV at this frequency", in: worked.evidence), 0)

        let choices = ["K5-01": "75%", "K5-02": "+6 chips", "K5-03": "It applies across the range",
                       "K5-review-01": "0 chips", "K5-review-02": "It applies across the range", "K5-review-03": "45%"]
        for activity in activities(.k5) where !activity.isExample {
            XCTAssertEqual(try selected(activity), choices[activity.id], activity.id)
            _ = try evidence(for: activity, hiding: "Minimum defense frequency (MDF)")
            let model = try XCTUnwrap(activity.prompt(in: .english))
            XCTAssertTrue(model.contains("one fixed size"), activity.id)
            XCTAssertTrue(model.contains("always loses when called"), activity.id)
        }
        let exactShare = try XCTUnwrap(activities(.k5).first { $0.id == "K5-03" })
        XCTAssertEqual(row("Minimum defense in this model", in: exactShare.evidence), "40/60")
    }

    private func activities(_ lesson: TableCourseLesson) -> [TableCourseActivity] {
        TableCourseUnit.expectedValue.activities(for: lesson) + ExpectedValueUnitContent.reviewActivities(for: lesson)
    }

    private func selected(_ activity: TableCourseActivity) throws -> String {
        let index = try XCTUnwrap(activity.correctChoice)
        let choices = activity.choices(in: .english)
        return try XCTUnwrap(choices.indices.contains(index) ? choices[index] : nil)
    }

    private func evidence(for activity: TableCourseActivity, hiding label: String) throws -> TableCourseEvidence {
        if activity.isExample { return activity.evidence }
        XCTAssertNil(row(label, in: activity.evidence), activity.id)
        return try XCTUnwrap(activity.revealedEvidence, activity.id)
    }

    private func row(_ label: String, in evidence: TableCourseEvidence) -> String? {
        evidence.rows.first { $0.label.text(in: .english) == label }?.value.text(in: .english)
    }

    private func equationResult(_ label: String, in evidence: TableCourseEvidence) throws -> Double {
        let equation = try XCTUnwrap(row(label, in: evidence))
        return try number(try XCTUnwrap(equation.components(separatedBy: " = ").last))
    }

    private func number(_ text: String) throws -> Double {
        let token = text.split(separator: " ").first?.replacingOccurrences(of: "−", with: "-")
        return try XCTUnwrap(token.flatMap(Double.init), text)
    }
}
