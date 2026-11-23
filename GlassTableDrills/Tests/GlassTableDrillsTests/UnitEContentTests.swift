// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine
@testable import GlassTableDrills
import XCTest

final class UnitEContentTests: XCTestCase {
    private let lessons: [TableCourseLesson] = [.e1, .e2, .e3, .e4, .e5, .e6, .e7]

    func testEachLessonHasAWorkedExampleFourQuestionsAndBilingualCopy() throws {
        let teaching = lessons.flatMap(StartingHandUnitContent.activities(for:))
        let reviews = lessons.flatMap(StartingHandUnitContent.reviewActivities(for:))
        let all = teaching + reviews
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)

        for lesson in lessons {
            let activities = StartingHandUnitContent.activities(for: lesson)
            XCTAssertEqual(activities.filter(\.isExample).count, 1, lesson.rawValue)
            XCTAssertEqual(activities.filter { !$0.isExample }.count, 4, lesson.rawValue)
            XCTAssertTrue(try XCTUnwrap(activities.first).isExample, lesson.rawValue)

            let review = StartingHandUnitContent.reviewActivities(for: lesson)
            XCTAssertEqual(review.count, lesson == .e7 ? 0 : 3, lesson.rawValue)
            XCTAssertTrue(review.allSatisfy { !$0.isExample }, lesson.rawValue)
        }

        let teachingDeals = Set(teaching.map { Set($0.evidence.cards) })
        XCTAssertTrue(reviews.allSatisfy { !teachingDeals.contains(Set($0.evidence.cards)) })

        for activity in all {
            XCTAssertEqual(Set(activity.evidence.cards).count, 2, activity.id)
            for language in LearningLanguage.allCases {
                XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                XCTAssertFalse(try XCTUnwrap(activity.prompt(in: language)).isEmpty, activity.id)
                let choices = activity.choices(in: language)
                XCTAssertEqual(Set(choices).count, choices.count, activity.id)
                if let answer = activity.correctChoice {
                    XCTAssertFalse(try XCTUnwrap(activity.explanation(in: language)).isEmpty, activity.id)
                    XCTAssertTrue(choices.indices.contains(answer), activity.id)
                } else {
                    XCTAssertTrue(choices.isEmpty, activity.id)
                }
            }
        }
    }

    func testRankSuitAndListQuestionsUseActualCards() throws {
        let classifications = StartingHandUnitContent.activities(for: .e1).dropFirst()
        XCTAssertEqual(classifications.map(\.correctChoice), [1, 2, 0, 1])
        for activity in Array(classifications) + StartingHandUnitContent.reviewActivities(for: .e1) {
            let cards = activity.evidence.cards
            let expected = cards[0].rank == cards[1].rank ? 0 : cards[0].suit == cards[1].suit ? 1 : 2
            XCTAssertEqual(activity.correctChoice, expected, activity.id)
        }

        let ranges = StartingHandUnitContent.activities(for: .e2)
        XCTAssertEqual(ranges.dropFirst().map(\.correctChoice), [1, 0, 1, 2])
        let reversed = try XCTUnwrap(ranges.first { $0.id == "E2-03" })
        XCTAssertEqual(reversed.evidence.rows[1].value.text(in: .english), "7♠ 6♠  ·  5♦ 6♦")
        XCTAssertNil(reversed.evidence.chart)
        XCTAssertEqual(StartingHandUnitContent.reviewActivities(for: .e2).map(\.correctChoice), [0, 2, 1])
    }

    func testLocatorShowsLabelsWithoutGivingAwayTheAnswer() throws {
        let drills = StartingHandUnitContent.activities(for: .e3).dropFirst()
        let review = StartingHandUnitContent.reviewActivities(for: .e3)
        for activity in Array(drills) + review {
            let chart = try XCTUnwrap(activity.evidence.chart, activity.id)
            XCTAssertEqual(chart.rows.count, 14, activity.id)
            XCTAssertTrue(chart.rows.allSatisfy { $0.count == 14 }, activity.id)
            XCTAssertEqual(chart.rows[0].prefix(4).map(\.label), ["", "A", "K", "Q"], activity.id)
            XCTAssertEqual(chart.rows[1][2].label, "AKs", activity.id)
            XCTAssertEqual(chart.rows[2][1].label, "AKo", activity.id)
            XCTAssertEqual(chart.rows[1][1].label, "AA", activity.id)
            XCTAssertNil(chart.inactiveLabel, activity.id)
            XCTAssertFalse(chart.rows.joined().contains { $0.highlighted || $0.active || $0.secondary }, activity.id)
            let correct = try XCTUnwrap(activity.correctChoice, activity.id)
            let name = try XCTUnwrap(HandClass(activity.evidence.cards), activity.id).description
            XCTAssertEqual(activity.choices(in: .english)[correct], name, activity.id)
            try assertRevealHighlight(activity, expected: name)
        }
    }

    func testOpeningChartChangesWithSeatWhileCardsStayFixed() throws {
        let questions = StartingHandUnitContent.activities(for: .e5).dropFirst()
        XCTAssertEqual(questions.map(\.correctChoice), [1, 0, 1, 0])
        let first = try XCTUnwrap(questions.first)
        let second = try XCTUnwrap(questions.dropFirst().first)
        XCTAssertEqual(first.evidence.cards, second.evidence.cards)
        XCTAssertNotEqual(first.evidence.chart?.title, second.evidence.chart?.title)

        let activities = [.e4, .e5, .e7].flatMap(StartingHandUnitContent.activities(for:))
            + [.e4, .e5].flatMap(StartingHandUnitContent.reviewActivities(for:))
        for activity in activities {
            guard let chart = activity.evidence.chart,
                  chart.title.text(in: .english).hasSuffix("opening chart") else { continue }
            let seat = try learnerSeat(for: activity)
            let range = RFIChart.range(for: seat)
            XCTAssertNotEqual(seat, .bb, activity.id)
            let cells = chart.rows.dropFirst().flatMap { $0.dropFirst() }
            XCTAssertEqual(Set(cells.filter(\.active).map(\.label)), Set(range.classes.map(\.description)), activity.id)
            XCTAssertFalse(cells.contains(where: \.secondary), activity.id)
            XCTAssertEqual(chart.activeLabel?.text(in: .english), "Open", activity.id)
            XCTAssertEqual(chart.inactiveLabel?.text(in: .english), "Fold", activity.id)

            let name = try XCTUnwrap(HandClass(activity.evidence.cards)).description
            if !activity.isExample {
                XCTAssertEqual(activity.correctChoice, RFIChart.opens(activity.evidence.cards, from: seat) ? 0 : 1)
                try assertRevealHighlight(activity, expected: name)
            }
        }
    }

    func testResponseChartUsesAnInPositionSingleOpenAndAllThreeActions() throws {
        let questions = StartingHandUnitContent.activities(for: .e6).dropFirst()
        XCTAssertEqual(questions.map(\.correctChoice), [1, 2, 0, 1])
        XCTAssertEqual(StartingHandUnitContent.reviewActivities(for: .e6).map(\.correctChoice), [1, 0, 2])
        let first = try XCTUnwrap(questions.first)
        let second = try XCTUnwrap(questions.dropFirst().first)
        XCTAssertEqual(first.evidence.cards, second.evidence.cards)
        XCTAssertEqual(try learnerSeat(for: first), try learnerSeat(for: second))

        let activities = [.e6, .e7].flatMap(StartingHandUnitContent.activities(for:))
            + StartingHandUnitContent.reviewActivities(for: .e6)
        for activity in activities {
            guard let chart = activity.evidence.chart,
                  chart.title.text(in: .english).hasPrefix("Response chart vs. ") else { continue }
            let action = activity.evidence.rows[1].value.text(in: .english)
            let opener = try XCTUnwrap(Position(rawValue: String(action.prefix { $0 != " " })))
            XCTAssertTrue(try learnerSeat(for: activity).actsAfter(opener), activity.id)
            XCTAssertTrue(action.contains("3 bb"), activity.id)
            XCTAssertTrue(action.contains("Everyone else before you folded"), activity.id)
            let practiceModel = activity.evidence.rows[2].value.text(in: .english)
            XCTAssertTrue(practiceModel.contains("8-seat"), activity.id)
            XCTAssertTrue(practiceModel.contains("100 bb"), activity.id)
            XCTAssertTrue(practiceModel.contains("opener’s range"), activity.id)

            let raises = DefendChart.threeBetRange(vsOpenFrom: opener).classes
            let calls = DefendChart.callRange(vsOpenFrom: opener).classes
            let cells = chart.rows.dropFirst().flatMap { $0.dropFirst() }
            XCTAssertEqual(Set(cells.filter(\.active).map(\.label)), Set(raises.map(\.description)), activity.id)
            XCTAssertEqual(Set(cells.filter(\.secondary).map(\.label)), Set(calls.map(\.description)), activity.id)
            XCTAssertFalse(cells.contains { $0.active && $0.secondary }, activity.id)
            XCTAssertEqual(chart.activeLabel?.text(in: .english), "Raise again", activity.id)
            XCTAssertEqual(chart.secondaryLabel?.text(in: .english), "Call", activity.id)
            XCTAssertEqual(chart.inactiveLabel?.text(in: .english), "Fold", activity.id)
            if !activity.isExample {
                let expected = DefendChart.action(for: activity.evidence.cards, vsOpenFrom: opener)
                XCTAssertEqual(activity.correctChoice, [.fold, .call, .threeBet].firstIndex(of: expected), activity.id)
                try assertRevealHighlight(activity, expected: XCTUnwrap(HandClass(activity.evidence.cards)).description)
            }
        }
    }

    func testCheckpointChoosesChartThenAppliesItToTheSameCardsInTwoSpots() throws {
        let questions = Array(StartingHandUnitContent.activities(for: .e7).dropFirst())
        XCTAssertEqual(questions.map(\.correctChoice), [1, 0, 0, 0])
        for activity in questions.prefix(2) {
            XCTAssertNil(activity.evidence.chart, activity.id)
            XCTAssertFalse(activity.evidence.rows[2].value.text(in: .english).contains("chart"), activity.id)
        }
        let opening = questions[2]
        let defending = questions[3]
        XCTAssertEqual(opening.evidence.cards, defending.evidence.cards)
        XCTAssertEqual(try learnerSeat(for: opening), try learnerSeat(for: defending))
        XCTAssertEqual(opening.choices(in: .english).first, "Open")
        XCTAssertEqual(defending.choices(in: .english).first, "Fold")
    }

    private func learnerSeat(for activity: TableCourseActivity) throws -> Position {
        let row = try XCTUnwrap(activity.evidence.rows.first, activity.id)
        let label = row.value.text(in: .english)
        return try XCTUnwrap(Position.allCases.first { label.hasSuffix("(\($0.rawValue))") }, activity.id)
    }

    private func assertRevealHighlight(_ activity: TableCourseActivity, expected: String) throws {
        let before = try XCTUnwrap(activity.evidence.chart, activity.id)
        let after = try XCTUnwrap(activity.revealedEvidence?.chart, activity.id)
        XCTAssertFalse(before.rows.joined().contains(where: \.highlighted), activity.id)
        XCTAssertEqual(after.rows.joined().filter(\.highlighted).map(\.label), [expected], activity.id)
    }
}
