// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine
@testable import GlassTableDrills
import XCTest

final class UnitFContentTests: XCTestCase {
    private let lessons: [TableCourseLesson] = [.f1, .f2, .f3, .f4, .f5, .f6]

    func testEachLessonHasAnExampleFourQuestionsAndFreshBilingualReviews() throws {
        let teaching = lessons.flatMap(PossibleHandsUnitContent.activities(for:))
        let reviews = lessons.flatMap(PossibleHandsUnitContent.reviewActivities(for:))
        let all = teaching + reviews
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertEqual(reviews.count, 15)
        for lesson in lessons {
            let activities = PossibleHandsUnitContent.activities(for: lesson)
            XCTAssertEqual(activities.map(\.isExample), [true, false, false, false, false])
            let heldOut = PossibleHandsUnitContent.reviewActivities(for: lesson)
            XCTAssertEqual(heldOut.count, lesson == .f6 ? 0 : 3)
            XCTAssertTrue(heldOut.allSatisfy { !$0.isExample })
            XCTAssertTrue(heldOut.allSatisfy { review in
                !activities.contains { Set($0.evidence.board) == Set(review.evidence.board) }
            }, lesson.rawValue)
        }

        for activity in all {
            let visible = activity.evidence.cards + activity.evidence.board
            XCTAssertEqual(Set(visible).count, visible.count, activity.id)
            XCTAssertEqual(activity.evidence.board.count, 3, activity.id)
            XCTAssertNil(activity.evidence.chart, activity.id)
            XCTAssertFalse(activity.evidence.seats.contains(where: \.highlighted), activity.id)
            XCTAssertNil(activity.revealedEvidence, activity.id)
            for language in LearningLanguage.allCases {
                XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                XCTAssertFalse(try XCTUnwrap(activity.prompt(in: language)).isEmpty, activity.id)
                let explanation = try XCTUnwrap(activity.explanation(in: language))
                XCTAssertFalse(explanation.isEmpty, activity.id)
                XCTAssertFalse(explanation.contains("(removed)"), activity.id)
                let choices = activity.choices(in: language)
                XCTAssertEqual(Set(choices).count, choices.count, activity.id)
                if let correct = activity.correctChoice {
                    XCTAssertTrue(choices.indices.contains(correct), activity.id)
                } else {
                    XCTAssertTrue(choices.isEmpty, activity.id)
                }
            }
        }
    }

    func testUnseenHandsStayPossibleAndRevealedHandsMatchByExactCards() throws {
        for activity in questions(.f1) {
            let rows = activity.evidence.rows
            let guess = try parseDisplayCards(rows[1].value.text(in: .english))
            let visible = Set(activity.evidence.cards + activity.evidence.board)
            XCTAssertTrue(visible.isDisjoint(with: guess), activity.id)
            let shown = rows[0].value.text(in: .english)
            if shown == "Still face down" {
                XCTAssertEqual(activity.correctChoice, 1, activity.id)
            } else {
                let actual = try parseDisplayCards(shown)
                XCTAssertTrue(visible.isDisjoint(with: actual), activity.id)
                XCTAssertEqual(activity.correctChoice, Set(guess) == Set(actual) ? 0 : 2, activity.id)
            }
        }
    }

    func testRemovalRequiresExactRankAndSuitAgainstBothVisibleZones() throws {
        for activity in questions(.f2) {
            let visible = Set(activity.evidence.cards + activity.evidence.board)
            let candidates = try activity.choices(in: .english).map(parseDisplayCards)
            let available = candidates.indices.filter { visible.isDisjoint(with: candidates[$0]) }
            XCTAssertEqual(available, [try XCTUnwrap(activity.correctChoice)], activity.id)
            XCTAssertTrue(candidates.contains { !Set(activity.evidence.cards).isDisjoint(with: $0) }, activity.id)
            XCTAssertTrue(candidates.contains { !Set(activity.evidence.board).isDisjoint(with: $0) }, activity.id)
        }
    }

    func testActualMadeHandsCanCoexistWithDraws() throws {
        let drills = questions(.f3)
        let expected = [1, 2, 3, 0, 3, 1, 2]
        XCTAssertEqual(drills.map { $0.correctChoice ?? -1 }, expected)
        for (activity, answer) in zip(drills, expected) {
            let all = activity.evidence.cards + activity.evidence.board
            let made = bestHandOfAny(all).category
            let oneCardCanFinish = Deck.all.filter { !all.contains($0) }.contains { next in
                let category = bestHandOfAny(all + [next]).category
                return [4, 5, 8].contains(category)
            }
            switch answer {
            case 0:
                XCTAssertEqual(made, 1)
                XCTAssertFalse(oneCardCanFinish)
            case 1:
                XCTAssertEqual(made, 0)
                XCTAssertTrue(oneCardCanFinish)
            case 2:
                XCTAssertEqual(made, 1)
                XCTAssertTrue(oneCardCanFinish)
            default:
                XCTAssertEqual(made, 4)
            }
        }
    }

    func testFlopAnswersMatchAllPossibleTwoCardHoldings() throws {
        let drills = questions(.f4)
        XCTAssertEqual(drills.map { $0.correctChoice ?? -1 }, [2, 0, 1, 3, 1, 2, 0])
        for activity in drills {
            let board = activity.evidence.board
            let available = Deck.all.filter { !board.contains($0) }
            var straight = false
            var flush = false
            for (index, first) in available.enumerated() {
                for second in available.dropFirst(index + 1) {
                    let category = bestHandOfAny(board + [first, second]).category
                    straight = straight || category == 4 || category == 8
                    flush = flush || category == 5 || category == 8
                }
            }
            XCTAssertEqual(activity.correctChoice, (straight ? 1 : 0) + (flush ? 2 : 0), activity.id)
        }
    }

    func testDisclosedPolicyEliminatesImpossibleHandsAndAllowsMultipleExplanations() throws {
        let drills = questions(.f5) + questions(.f6)
        for activity in drills {
            let rows = activity.evidence.rows
            let rule = rows[0].value.text(in: .english)
            XCTAssertTrue(rule.contains("two pair or better"), activity.id)
            let observedBet = rows[1].value.text(in: .english) == "Bet"
            let visible = Set(activity.evidence.cards + activity.evidence.board)
            let candidates = try rows.dropFirst(2).map { try parseDisplayCards($0.value.text(in: .english)) }
            let matching = candidates.indices.filter { index in
                let hand = candidates[index]
                guard visible.isDisjoint(with: hand) else { return false }
                let bets = bestHandOfAny(hand + activity.evidence.board).category >= 2
                return bets == observedBet
            }
            let names = matching.map { ["A", "B", "C"][$0] }
            let checkpoint = activity.id.hasPrefix("F6")
            XCTAssertEqual(names.count, checkpoint ? 2 : 1, activity.id)
            let choice = try XCTUnwrap(activity.correctChoice)
            let expected = checkpoint ? names.joined(separator: " and ") : "Hand \(names[0])"
            XCTAssertEqual(activity.choices(in: .english)[choice], expected, activity.id)
        }

        let blocked = try XCTUnwrap(drills.first { $0.id == "F6-01" })
        let unavailable = try parseDisplayCards(blocked.evidence.rows[3].value.text(in: .english))
        XCTAssertFalse(Set(blocked.evidence.cards).isDisjoint(with: unavailable))
        XCTAssertEqual(bestHandOfAny(blocked.evidence.board + unavailable).category, 2)
        XCTAssertTrue(try XCTUnwrap(blocked.explanation(in: .english)).contains("already visible"))
        XCTAssertEqual(questions(.f6).map { $0.correctChoice ?? -1 }, [1, 2, 0, 1])
    }

    private func questions(_ lesson: TableCourseLesson) -> [TableCourseActivity] {
        Array(PossibleHandsUnitContent.activities(for: lesson).dropFirst())
            + PossibleHandsUnitContent.reviewActivities(for: lesson)
    }

    private func parseDisplayCards(_ text: String) throws -> [Card] {
        let raw = text.replacingOccurrences(of: "10", with: "T")
            .replacingOccurrences(of: "♣\u{FE0E}", with: "c", options: .literal)
            .replacingOccurrences(of: "♦\u{FE0E}", with: "d", options: .literal)
            .replacingOccurrences(of: "♥\u{FE0E}", with: "h", options: .literal)
            .replacingOccurrences(of: "♠\u{FE0E}", with: "s", options: .literal)
            .replacingOccurrences(of: " ", with: "")
        let cards = try XCTUnwrap(Card.parse(raw))
        XCTAssertEqual(cards.count, 2)
        XCTAssertEqual(Set(cards).count, 2)
        return cards
    }
}
