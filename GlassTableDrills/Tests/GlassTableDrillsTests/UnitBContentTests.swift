// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class UnitBContentTests: XCTestCase {
    func testEveryLessonHasAWalkthroughAndThreeOrFourEvaluatorCheckedPrompts() {
        let allActivities = UnitBLesson.allCases.flatMap(UnitBContentV1.activities(for:))
        XCTAssertEqual(Set(allActivities.map(\.id)).count, allActivities.count)

        for lesson in UnitBLesson.allCases {
            let activities = UnitBContentV1.activities(for: lesson)
            if lesson == .pairComparison {
                XCTAssertTrue(activities.isEmpty)
                continue
            }
            XCTAssertEqual(activities.first?.kind, .example, lesson.rawValue)
            XCTAssertTrue((4...5).contains(activities.count), lesson.rawValue)

            for activity in activities {
                let seven = activity.learner + activity.board
                XCTAssertEqual(activity.board.count, 5, activity.id)
                XCTAssertEqual(activity.learner.count, 2, activity.id)
                XCTAssertEqual(Set(seven + activity.opponent).count,
                               seven.count + activity.opponent.count, activity.id)
                XCTAssertEqual(activity.correctFive.count, 5, activity.id)
                XCTAssertTrue(Set(activity.correctFive).isSubset(of: Set(seven)), activity.id)
                XCTAssertEqual(compareHands(hero: activity.correctFive, villain: seven), 2, activity.id)
                if !activity.opponent.isEmpty {
                    let otherSeven = activity.opponent + activity.board
                    XCTAssertEqual(activity.opponent.count, 2, activity.id)
                    XCTAssertEqual(activity.opponentFive.count, 5, activity.id)
                    XCTAssertTrue(Set(activity.opponentFive).isSubset(of: Set(otherSeven)), activity.id)
                    XCTAssertEqual(compareHands(hero: activity.opponentFive, villain: otherSeven), 2, activity.id)
                    if activity.kind == .choice {
                        let outcome = compareHands(hero: seven, villain: otherSeven)
                        XCTAssertEqual(activity.correctChoice, outcome, activity.id)
                        XCTAssertEqual(compareHands(hero: activity.correctFive, villain: activity.opponentFive),
                                       outcome, activity.id)
                    }
                } else {
                    XCTAssertTrue(activity.opponentFive.isEmpty, activity.id)
                }

                for language in LearningLanguage.allCases {
                    let choices = activity.choices(in: language)
                    XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                    XCTAssertFalse(activity.explanation(in: language).isEmpty, activity.id)
                    XCTAssertEqual(Set(choices).count, choices.count, activity.id)
                    if let answer = activity.correctChoice {
                        XCTAssertTrue(choices.indices.contains(answer), activity.id)
                    } else {
                        XCTAssertTrue(choices.isEmpty, activity.id)
                    }
                }
            }
        }
    }

    func testEarlyLessonsShowBestFivesAndBestFiveSelectionsKeepThemHidden() {
        for lesson in UnitBLesson.allCases.prefix(9) {
            for activity in UnitBContentV1.activities(for: lesson) {
                XCTAssertTrue(activity.showsBestFivesBeforeAnswer, activity.id)
                XCTAssertEqual(activity.opponentFive.count, 5, activity.id)
            }
        }
        for lesson in [.bestFive, UnitBLesson.checkpoint] {
            for activity in UnitBContentV1.activities(for: lesson) where activity.kind == .bestFive {
                XCTAssertFalse(activity.showsBestFivesBeforeAnswer, activity.id)
                XCTAssertTrue(activity.opponent.isEmpty, activity.id)
            }
        }
    }

    func testBestFiveLessonsIncludeZeroOneAndTwoPrivateCardsAndEquivalentSuits() throws {
        let activities = UnitBContentV1.activities(for: .bestFive).dropFirst()
        XCTAssertEqual(activities.map { activity in
            activity.correctFive.filter(activity.learner.contains).count
        }, [0, 1, 2, 1])

        let kicker = try activity("B10-03", in: .bestFive)
        let lowerNineRemoved = try XCTUnwrap(Card.parse("8s8hAcJd6h"))
        XCTAssertEqual(bestHandOfAny(lowerNineRemoved), bestHandOfAny(kicker.correctFive))
        XCTAssertEqual(compareHands(hero: kicker.correctFive, villain: lowerNineRemoved), 0)

        let equivalent = try activity("B10-04", in: .bestFive)
        let boardTen = try XCTUnwrap(Card.parse("6h7s8d9cTc"))
        let privateTen = try XCTUnwrap(Card.parse("6h7s8d9cTh"))
        XCTAssertNotEqual(Set(boardTen), Set(privateTen))
        XCTAssertEqual(compareHands(hero: boardTen, villain: equivalent.correctFive), 2)
        XCTAssertEqual(compareHands(hero: privateTen, villain: equivalent.correctFive), 2)
    }

    func testWheelRoyalKickerAndSplitExamplesDemonstrateTheSpecifiedRules() throws {
        let wheel = try activity("B5-example", in: .straight)
        XCTAssertEqual(bestHandOfAny(wheel.correctFive), HandBrief(category: 4, topRank: 5))
        XCTAssertEqual(wheel.correctFive.map(\.rank), [5, 4, 3, 2, 14])
        let wrap = try activity("B5-02", in: .straight)
        XCTAssertEqual(bestHandOfAny(wrap.opponentFive).category, 0)

        let royal = try activity("B9-01", in: .straightFlush)
        XCTAssertEqual(bestHandOfAny(royal.opponentFive), HandBrief(category: 8, topRank: 14))
        XCTAssertEqual(bestHandOfAny(royal.correctFive), HandBrief(category: 8, topRank: 13))
        XCTAssertEqual(royal.correctChoice, 1)

        let kicker = try activity("B11-01", in: .kickers)
        XCTAssertEqual(kicker.correctFive.map(\.rank), [8, 8, 14, 13, 10])
        XCTAssertEqual(kicker.opponentFive.map(\.rank), [8, 8, 14, 13, 9])
        XCTAssertEqual(kicker.correctChoice, 0)
        let sameTypeComparison = UnitBContentV1.activities(for: .kickers).dropFirst()
        XCTAssertEqual(sameTypeComparison.map { bestHandOfAny($0.correctFive).category }, [1, 0, 2, 6])
        XCTAssertEqual(sameTypeComparison.map(\.correctChoice), [0, 1, 0, 1])

        let sharedTie = try activity("B12-01", in: .boardPlays)
        XCTAssertEqual(Set(sharedTie.correctFive), Set(sharedTie.board))
        XCTAssertEqual(Set(sharedTie.opponentFive), Set(sharedTie.board))
        XCTAssertEqual(sharedTie.correctChoice, 2)
        let unsharedTie = try activity("B12-03", in: .boardPlays)
        XCTAssertNotEqual(Set(unsharedTie.correctFive), Set(unsharedTie.opponentFive))
        XCTAssertEqual(unsharedTie.correctChoice, 2)
        let kickerBreaksTie = try activity("B12-02", in: .boardPlays)
        XCTAssertEqual(kickerBreaksTie.correctChoice, 0)
    }

    func testCheckpointUsesFourHeldOutDealsWithTheApprovedMix() {
        let checkpoint = Array(UnitBContentV1.activities(for: .checkpoint).dropFirst())
        XCTAssertEqual(checkpoint.map(\.kind), [.choice, .bestFive, .choice, .choice])
        XCTAssertEqual(checkpoint.map(\.correctChoice), [0, nil, 1, 2])
        let previousBoards = UnitBLesson.allCases.dropLast()
            .flatMap(UnitBContentV1.activities(for:)).map { Set($0.board) }
        XCTAssertEqual(Set(checkpoint.map { Set($0.board) }).count, checkpoint.count)
        XCTAssertTrue(checkpoint.allSatisfy { !previousBoards.contains(Set($0.board)) })

        XCTAssertNotEqual(bestHandOfAny(checkpoint[0].correctFive).category,
                          bestHandOfAny(checkpoint[0].opponentFive).category)
        XCTAssertEqual(bestHandOfAny(checkpoint[2].correctFive), bestHandOfAny(checkpoint[2].opponentFive))
        XCTAssertEqual(compareHands(hero: checkpoint[2].correctFive,
                                    villain: checkpoint[2].opponentFive), 1)
        XCTAssertEqual(Set(checkpoint[3].correctFive), Set(checkpoint[3].board))
        XCTAssertEqual(Set(checkpoint[3].opponentFive), Set(checkpoint[3].board))
    }

    private func activity(_ id: String, in lesson: UnitBLesson,
                          file: StaticString = #filePath, line: UInt = #line) throws -> UnitBActivity {
        try XCTUnwrap(UnitBContentV1.activities(for: lesson).first { $0.id == id },
                      file: file, line: line)
    }
}
