// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Testing
@testable import GlassTableDrills

struct UnitLContentTests {
    private let lessons: [TableCourseLesson] = [.l1, .l2, .l3, .l4, .l5]

    @Test func electiveHasOneWorkedExampleThreeGradedQuestionsAndThreeFreshReviewsPerLesson() throws {
        #expect(TableCourseUnit.boardPatterns.lessons == lessons)
        #expect(TableCourseUnit.electives.contains(.boardPatterns))
        #expect(!TableCourseUnit.corePath.contains(.boardPatterns))

        var ids: Set<String> = []
        for lesson in lessons {
            let main = TableCourseUnit.boardPatterns.activities(for: lesson)
            let review = BoardPatternsUnitContent.reviewActivities(for: lesson)
            #expect(main.count == 4)
            #expect(try #require(main.first).isExample)
            #expect(main.dropFirst().allSatisfy { !$0.isExample })
            #expect(review.count == 3)
            #expect(review.allSatisfy { !$0.isExample })

            var setups: Set<String> = []
            for activity in main + review {
                #expect(ids.insert(activity.id).inserted, "\(activity.id)")
                let initial = activity.evidence
                let shown = try result(activity)
                let setup = initial.board.map(\.description).joined()
                    + "/" + initial.comparisonBoard.map(\.description).joined()
                #expect(setups.insert(setup).inserted, "\(activity.id)")
                #expect(Set(initial.board).count == initial.board.count)
                #expect(Set(initial.comparisonBoard).count == initial.comparisonBoard.count)
                #expect(shown.board == initial.board)
                #expect(shown.comparisonBoard == initial.comparisonBoard)
                #expect(shown.distributions.count == ([.l2, .l3, .l5].contains(lesson) ? 2 : 1))

                for language in LearningLanguage.allCases {
                    #expect(!activity.title(in: language).isEmpty)
                    #expect(!(try #require(activity.prompt(in: language))).isEmpty)
                    #expect(!(try #require(activity.explanation(in: language))).isEmpty)
                    if let correct = activity.correctChoice {
                        let choices = activity.choices(in: language)
                        #expect(Set(choices).count == 3, "\(activity.id)")
                        #expect(choices.indices.contains(correct))
                        #expect(initial != shown)
                        #expect(initial.distributions.count == (lesson == .l3 ? 2 : 0))
                    }
                    for distribution in shown.distributions {
                        #expect(!distribution.title.text(in: language).isEmpty)
                        #expect(distribution.bands.allSatisfy { !$0.label.text(in: language).isEmpty })
                    }
                }
            }
        }
        #expect(ids.count == 35)
    }

    @Test func madeHandSharesUseWeightedLegalCombosAndCountOnePairWithADraw() throws {
        let expected: [String: (weights: [Int], choice: String?)] = [
            "L1-example": ([15, 0, 8], nil),
            "L1-01": ([24, 4, 0], "86%"),
            "L1-02": ([15, 0, 24], "38%"),
            "L1-03": ([10, 0, 24], "29%"),
            "L1-review-01": ([24, 0, 8], "75%"),
            "L1-review-02": ([11, 0, 12], "48%"),
            "L1-review-03": ([13, 8, 0], "62%"),
        ]
        for activity in all(.l1) {
            let value = try #require(expected[activity.id])
            let shown = try result(activity)
            let distribution = try #require(shown.distributions.first)
            expectBands(distribution, value.weights, activity.id)
            #expect(try selected(activity) == value.choice, "\(activity.id)")
            #expect(row("Pair or better ÷ total", in: activity.evidence) == nil || activity.isExample)
        }
        let worked = try #require(all(.l1).first)
        #expect(row("Pair or better ÷ total", in: worked.evidence) == "7.5 ÷ 11.5 ≈ 65%")
    }

    @Test func drawAndMissComparisonsUseEachRangeAsItsOwnDenominator() throws {
        let expected: [String: (a: [Int], b: [Int], choice: String?)] = [
            "L2-example": ([0, 9, 3], [0, 4, 24], nil),
            "L2-01": ([12, 24, 0], [3, 8, 0], "Range B"),
            "L2-02": ([0, 6, 6], [12, 0, 12], "Equal"),
            "L2-03": ([0, 0, 12], [6, 0, 4], "Range A"),
            "L2-review-01": ([0, 25, 3], [3, 8, 0], "Range A"),
            "L2-review-02": ([0, 9, 3], [0, 1, 27], "Range B"),
            "L2-review-03": ([6, 4, 0], [0, 12, 0], "Range B"),
        ]
        for activity in all(.l2) {
            let value = try #require(expected[activity.id])
            let distributions = try result(activity).distributions
            try expectBoth(distributions, a: value.a, b: value.b, activity.id)
            #expect(try selected(activity) == value.choice, "\(activity.id)")
        }
    }

    @Test func boardComparisonsUseTwoCompleteBoardsCompatibleHoldingsAndHalfOfTies() throws {
        let expected: [String: (a: [Int], b: [Int], choice: String?)] = [
            "L3-example": ([174, 6, 0], [72, 24, 160], nil),
            "L3-01": ([42, 0, 108], [0, 174, 0], "Board B"),
            "L3-02": ([108, 0, 36], [0, 0, 117], "Board A"),
            "L3-03": ([0, 588, 0], [0, 588, 0], "Equal"),
            "L3-review-01": ([0, 0, 240], [225, 0, 0], "Board B"),
            "L3-review-02": ([153, 0, 0], [90, 111, 15], "Board A"),
            "L3-review-03": ([0, 108, 240], [0, 348, 0], "Board B"),
        ]
        for activity in all(.l3) {
            let value = try #require(expected[activity.id])
            let shown = try result(activity)
            #expect(shown.board.count == 5)
            #expect(shown.comparisonBoard.count == 5)
            #expect(shown.board != shown.comparisonBoard)
            try expectBoth(activity.evidence.distributions, a: value.a, b: value.b, activity.id)
            #expect(shown.distributions == activity.evidence.distributions)
            #expect(try selected(activity) == value.choice, "\(activity.id)")
            if !activity.isExample {
                #expect(row("Pot share on Board A", in: activity.evidence) == nil)
                #expect(row("Pot share on Board B", in: activity.evidence) == nil)
            }
        }
        let mixed = try #require(all(.l3).first { $0.id == "L3-review-02" })
        let shown = try result(mixed)
        #expect(row("Pot share on Board B", in: shown) == "(22.5 + 27.75 ÷ 2) ÷ 54 ≈ 67%")
    }

    @Test func practiceSizeRuleCountsSinglePairsWithDrawsOnlyOnce() throws {
        let expected: [String: (weights: [Int], choice: String?)] = [
            "L4-example": ([0, 20, 12], nil),
            "L4-01": ([12, 11, 6], "38%"),
            "L4-02": ([12, 8, 6], "23%"),
            "L4-03": ([8, 14, 14], "22%"),
            "L4-review-01": ([6, 5, 6], "29%"),
            "L4-review-02": ([0, 22, 6], "21%"),
            "L4-review-03": ([24, 3, 6], "73%"),
        ]
        for activity in all(.l4) {
            let value = try #require(expected[activity.id])
            let shown = try result(activity)
            let distribution = try #require(shown.distributions.first)
            expectBands(distribution, value.weights, activity.id)
            #expect(try selected(activity) == value.choice, "\(activity.id)")
            #expect(row("Practice rule", in: activity.evidence) != nil)
        }
    }

    @Test func observedHalfPotBetConditionsBothRulesAndPreservesExactMajorityBoundary() throws {
        let expected: [String: (a: [Int], b: [Int], choice: String?)] = [
            "L5-example": ([24, 48], [24, 12], nil),
            "L5-01": ([36, 96], [36, 24], "Only under Rule A"),
            "L5-02": ([12, 96], [12, 24], "Under both rules"),
            "L5-03": ([72, 16], [72, 4], "Under neither rule"),
            "L5-review-01": ([24, 96], [24, 24], "Only under Rule A"),
            "L5-review-02": ([12, 96], [12, 24], "Under both rules"),
            "L5-review-03": ([72, 4], [72, 1], "Under neither rule"),
        ]
        for activity in all(.l5) {
            let value = try #require(expected[activity.id])
            let distributions = try result(activity).distributions
            try expectBoth(distributions, a: value.a, b: value.b, activity.id)
            #expect(try selected(activity) == value.choice, "\(activity.id)")
            #expect(row("Observed action", in: activity.evidence) == "Half-pot bet")
            #expect(row("Rule B", in: activity.evidence)?.contains("25%") == true)
        }
        let boundary = try #require(all(.l5).first { $0.id == "L5-review-01" })
        #expect(row("Draw share after the bet", in: try result(boundary)) == "Rule A 12 ÷ 15 ≈ 80% · Rule B 3 ÷ 6 ≈ 50%")
    }

    private func all(_ lesson: TableCourseLesson) -> [TableCourseActivity] {
        TableCourseUnit.boardPatterns.activities(for: lesson) + BoardPatternsUnitContent.reviewActivities(for: lesson)
    }

    private func result(_ activity: TableCourseActivity) throws -> TableCourseEvidence {
        if activity.isExample { return activity.evidence }
        return try #require(activity.revealedEvidence)
    }

    private func selected(_ activity: TableCourseActivity) throws -> String? {
        guard let index = activity.correctChoice else { return nil }
        let choices = activity.choices(in: .english)
        try #require(choices.indices.contains(index))
        return choices[index]
    }

    private func row(_ label: String, in evidence: TableCourseEvidence) -> String? {
        evidence.rows.first { $0.label.text(in: .english) == label }?.value.text(in: .english)
    }

    private func expectBoth(
        _ distributions: [TableCourseDistribution], a: [Int], b: [Int], _ id: String
    ) throws {
        try #require(distributions.count == 2)
        expectBands(distributions[0], a, id)
        expectBands(distributions[1], b, id)
    }

    private func expectBands(_ distribution: TableCourseDistribution, _ weights: [Int], _ id: String) {
        #expect(distribution.bands.count == weights.count, "\(id)")
        let total = Double(weights.reduce(0, +))
        for (band, weight) in zip(distribution.bands, weights) {
            #expect(abs(band.share - Double(weight) / total) < 0.000_000_000_001, "\(id)")
        }
    }
}
