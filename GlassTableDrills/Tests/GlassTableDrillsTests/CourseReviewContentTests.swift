// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class CourseReviewContentTests: XCTestCase {
    func testEveryReviewObjectiveHasDistinctLocalizedQuestions() throws {
        var ids: Set<String> = []
        var deals: Set<String> = []
        for skill in CourseReviewSkill.allCases {
            let count = CourseReviewContent.variantCount(for: skill)
            XCTAssertGreaterThanOrEqual(count, 2, skill.rawValue)
            XCTAssertNil(CourseReviewContent.activity(for: skill, variant: -1))
            XCTAssertNil(CourseReviewContent.activity(for: skill, variant: count))
            for item in try items(skill) {
                XCTAssertTrue(ids.insert(item.id).inserted, item.id)
                if skill.tableLesson == nil {
                    XCTAssertTrue(deals.insert(signature([item.learner, item.board, item.opponent])).inserted, item.id)
                } else {
                    XCTAssertEqual(count, 3, skill.rawValue)
                    XCTAssertNotNil(item.tableEvidence)
                }
                let cards = item.learner + item.board + item.opponent
                XCTAssertEqual(Set(cards).count, cards.count, item.id)
                for language in LearningLanguage.allCases {
                    XCTAssertFalse(item.title(in: language).isEmpty, item.id)
                    XCTAssertFalse(item.explanation(in: language).isEmpty, item.id)
                    let labels = item.choices(in: language)
                    XCTAssertEqual(labels.count, Set(labels).count, item.id)
                    if let answer = item.correctChoice {
                        XCTAssertTrue(labels.indices.contains(answer), item.id)
                    } else {
                        XCTAssertTrue(labels.isEmpty, item.id)
                        XCTAssertEqual(item.kind, .bestFive)
                    }
                }
            }
        }
    }

    func testUnitAVariantsUseBothAnswerPositions() throws {
        for skill in CourseReviewSkill.allCases where skill.isUnitA {
            XCTAssertEqual(Set(try items(skill).compactMap(\.correctChoice)), [0, 1], skill.rawValue)
        }
    }

    func testReviewDoesNotRepeatATaughtDealOrExistingPairFollowUp() throws {
        var taught = Set(UnitALesson.allCases.flatMap(UnitAContentV1.activities(for:)).flatMap { item in
            [item.cards] + item.revealGroups
        }.map { signature($0.map(\.cards)) })
        taught.formUnion(UnitBLesson.allCases.flatMap(UnitBContentV1.activities(for:)).map {
            signature([$0.learner, $0.board, $0.opponent])
        })

        var pairDeals: Set<String> = []
        for seed in UInt64(0)..<32 {
            var progress = PairLessonProgress(seed: seed)
            while let question = progress.currentQuestion {
                pairDeals.insert(signature([question.learner, question.board, question.opponent]))
                if progress.phase != .example {
                    if progress.phase == .solo && progress.soloNumber == 1 {
                        XCTAssertTrue(progress.apply(.hint))
                    }
                    XCTAssertTrue(progress.apply(.select(question.winner)))
                    XCTAssertTrue(progress.apply(.submit))
                }
                guard progress.apply(.advance) else { return XCTFail("Pair lesson stalled") }
            }
            let followUp = PairLessonFollowUpProgress.recordingCompletion(
                of: progress, previous: nil, at: Date(timeIntervalSince1970: 1_800_000_000))
            for kind in [PairLessonFollowUpKind.fresh, .review] {
                let question = try XCTUnwrap(followUp.attempt(for: kind)?.question)
                pairDeals.insert(signature([question.learner, question.board, question.opponent]))
            }
        }
        XCTAssertEqual(pairDeals.count, 35)
        taught.formUnion(pairDeals)

        for item in try CourseReviewSkill.allCases.filter({ $0.tableLesson == nil }).flatMap(items) {
            XCTAssertFalse(taught.contains(signature([item.learner, item.board, item.opponent])), item.id)
        }
    }

    func testReviewShowdownsAndAvailableEvidenceAgreeWithTheEngine() throws {
        for item in try CourseReviewSkill.allCases.flatMap(items) where !item.opponent.isEmpty {
            XCTAssertEqual(item.learner.count, 2, item.id)
            XCTAssertEqual(item.board.count, 5, item.id)
            XCTAssertEqual(item.opponent.count, 2, item.id)
            let learner = item.learner + item.board
            let opponent = item.opponent + item.board
            XCTAssertEqual(item.correctChoice, compareHands(hero: learner, villain: opponent), item.id)
            XCTAssertEqual(item.correctFive.count, 5, item.id)
            XCTAssertEqual(item.opponentFive.count, 5, item.id)
            XCTAssertTrue(Set(item.correctFive).isSubset(of: Set(learner)), item.id)
            XCTAssertTrue(Set(item.opponentFive).isSubset(of: Set(opponent)), item.id)
            XCTAssertEqual(compareHands(hero: learner, villain: item.correctFive), 2, item.id)
            XCTAssertEqual(compareHands(hero: opponent, villain: item.opponentFive), 2, item.id)
        }
        XCTAssertEqual(try items(.boardPlays).map(\.correctChoice), [2, 2, 0])
    }

    func testShowdownDealsExerciseTheirNamedRules() throws {
        let categories: [CourseReviewSkill: [Int]] = [
            .pairBeatsHighCard: [0, 1], .pairComparison: [1, 1], .twoPair: [1, 2],
            .threeOfAKind: [2, 3], .straight: [3, 4], .flush: [4, 5],
            .fullHouse: [5, 6], .fourOfAKind: [6, 7], .straightFlush: [5, 8],
            .kickers: [1, 1], .highCardRanks: [0, 0], .twoPairRanks: [2, 2],
            .fullHouseRanks: [6, 6], .boardPlays: [4, 4],
        ]
        for (skill, expected) in categories {
            for item in try items(skill) {
                let learner = bestHand(item.learner + item.board)
                let opponent = bestHand(item.opponent + item.board)
                XCTAssertEqual([learner.category, opponent.category].sorted(), expected, item.id)
                switch skill {
                case .kickers, .highCardRanks:
                    XCTAssertEqual(learner.topRank, opponent.topRank, item.id)
                case .pairComparison, .twoPairRanks, .fullHouseRanks:
                    XCTAssertNotEqual(learner.topRank, opponent.topRank, item.id)
                default: break
                }
            }
        }
    }

    func testBestFiveDealsIncludeZeroOneAndTwoPrivateCardsAndAcceptAnEquivalentFive() throws {
        let questions = try items(.bestFive)
        XCTAssertEqual(questions.map { item in item.correctFive.filter(item.learner.contains).count }, [0, 2, 1])
        for item in questions {
            XCTAssertEqual(item.correctFive.count, 5, item.id)
            XCTAssertEqual(compareHands(hero: item.learner + item.board, villain: item.correctFive), 2, item.id)
        }
        let interchangeable = try XCTUnwrap(questions.last)
        let sixOfSpades = try XCTUnwrap(Card.parse("5d6s7s8h9c"))
        let sixOfDiamonds = try XCTUnwrap(Card.parse("5d6d7s8h9c"))
        XCTAssertEqual(compareHands(hero: sixOfSpades, villain: interchangeable.correctFive), 2)
        XCTAssertEqual(compareHands(hero: sixOfDiamonds, villain: interchangeable.correctFive), 2)
    }

    private func items(_ skill: CourseReviewSkill) throws -> [CourseReviewActivity] {
        try (0..<CourseReviewContent.variantCount(for: skill)).map {
            try XCTUnwrap(CourseReviewContent.activity(for: skill, variant: $0))
        }
    }

    private func signature(_ groups: [[Card]]) -> String {
        groups.filter { !$0.isEmpty }.map { $0.map(\.description).sorted().joined() }
            .sorted().joined(separator: "/")
    }
}
