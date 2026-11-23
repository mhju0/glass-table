// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
@testable import GlassTableDrills
import XCTest

final class UnitGContentTests: XCTestCase {
    private let lessons: [TableCourseLesson] = [.g1, .g2, .g3, .g4, .g5, .g6, .g7]

    func testCatalogHasOneExampleThreeQuestionsAndFreshReviewsPerObjective() throws {
        let teaching = lessons.flatMap { TableCourseUnit.winningCards.activities(for: $0) }
        let reviews = lessons.flatMap(WinningCardsUnitContent.reviewActivities(for:))
        let all = teaching + reviews
        XCTAssertEqual(TableCourseUnit.winningCards.lessons, lessons)
        XCTAssertEqual(teaching.count, 28)
        XCTAssertEqual(reviews.count, 18)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)

        for lesson in lessons {
            let activities = TableCourseUnit.winningCards.activities(for: lesson)
            XCTAssertTrue(try XCTUnwrap(activities.first).isExample, lesson.rawValue)
            XCTAssertEqual(activities.filter(\.isExample).count, 1, lesson.rawValue)
            XCTAssertEqual(activities.filter { !$0.isExample }.count, 3, lesson.rawValue)
            let review = WinningCardsUnitContent.reviewActivities(for: lesson)
            XCTAssertEqual(review.count, lesson == .g7 ? 0 : 3, lesson.rawValue)
            XCTAssertTrue(review.allSatisfy { !$0.isExample }, lesson.rawValue)
        }

        let teachingDeals = Set(teaching.map(dealKey))
        XCTAssertEqual(Set(reviews.map(dealKey)).count, reviews.count)
        XCTAssertTrue(reviews.allSatisfy { !teachingDeals.contains(dealKey($0)) })

        for activity in all {
            let evidence = activity.evidence
            let visible = evidence.cards + evidence.opponent + evidence.board
            XCTAssertEqual(evidence.cards.count, 2, activity.id)
            XCTAssertEqual(evidence.opponent.count, activity.id.hasPrefix("G6") ? 0 : 2, activity.id)
            XCTAssertEqual(evidence.board.count, activity.id == "G2-example" ? 5 : 4, activity.id)
            XCTAssertEqual(Set(visible).count, visible.count, activity.id)
            XCTAssertTrue(evidence.seats.allSatisfy { !$0.highlighted }, activity.id)
            XCTAssertNil(evidence.chart, activity.id)
            for language in LearningLanguage.allCases {
                XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                XCTAssertFalse(try XCTUnwrap(activity.prompt(in: language)).isEmpty, activity.id)
                XCTAssertFalse(try XCTUnwrap(activity.explanation(in: language)).isEmpty, activity.id)
                let choices = activity.choices(in: language)
                XCTAssertEqual(Set(choices).count, choices.count, activity.id)
                if let answer = activity.correctChoice {
                    XCTAssertEqual(choices.count, 3, activity.id)
                    XCTAssertTrue(choices.indices.contains(answer), activity.id)
                    XCTAssertNotNil(activity.revealedEvidence, activity.id)
                    XCTAssertFalse(evidence.rows.contains { $0.label.text(in: .english) == "Result" }, activity.id)
                } else {
                    XCTAssertTrue(choices.isEmpty, activity.id)
                    XCTAssertNil(activity.revealedEvidence, activity.id)
                }
            }
        }
    }

    func testEveryFaceUpCountAndRiverChoiceMatchesExactEngineOutcomes() throws {
        let all = lessons.filter { $0 != .g6 }.flatMap { lesson in
            WinningCardsUnitContent.activities(for: lesson) + WinningCardsUnitContent.reviewActivities(for: lesson)
        }
        for activity in all {
            let reveal = activity.revealedEvidence ?? activity.evidence
            let board = Array(reveal.board.prefix(4))
            let visible = Set(reveal.cards + reveal.opponent + board)
            let removed = try row("Cards already out of the deck", in: reveal).map(cards) ?? []
            XCTAssertTrue(visible.isDisjoint(with: removed), activity.id)
            let exact = exactEquityHeadsUp(hero: reveal.cards, villain: reveal.opponent, board: board)
            let blockedResults = removed.map {
                exactEquityHeadsUp(hero: reveal.cards, villain: reveal.opponent, board: board + [$0])
            }
            let wins = exact.wins - blockedResults.reduce(0) { $0 + $1.wins }
            let ties = exact.ties - blockedResults.reduce(0) { $0 + $1.ties }
            let total = exact.total - removed.count

            let choices = activity.choices(in: .english)
            let chosen = activity.correctChoice.map { choices[$0] }
            if let cardsText = row("Winning cards", in: reveal) {
                let winningCards = try cards(cardsText)
                let oracle = countOuts(hero: reveal.cards, villain: reveal.opponent, board: board)
                    .filter { !removed.contains($0) }
                XCTAssertEqual(winningCards, oracle, activity.id)
                XCTAssertEqual(winningCards.count, wins, activity.id)
                XCTAssertEqual(Set(winningCards).count, wins, activity.id)
                if let chance = row("Chance of winning", in: reveal) {
                    XCTAssertEqual(row("Possible rivers", in: reveal), "52 − \(52 - total) = \(total)", activity.id)
                    XCTAssertEqual(chance, "\(wins) / \(total)", activity.id)
                    if let chosen { XCTAssertEqual(chosen, chance, activity.id) }
                } else if let chosen {
                    XCTAssertEqual(chosen, String(wins), activity.id)
                }
            }

            if let share = row("Average pot share (equity)", in: reveal) {
                XCTAssertEqual(row("Winning rivers", in: reveal), "\(wins) / \(total)", activity.id)
                XCTAssertEqual(row("Tying rivers", in: reveal), "\(ties) / \(total)", activity.id)
                let tieCards = try cards(XCTUnwrap(row("Rivers that tie", in: reveal)))
                XCTAssertEqual(Set(tieCards).count, ties, activity.id)
                XCTAssertTrue(visible.union(removed).isDisjoint(with: tieCards), activity.id)
                XCTAssertTrue(tieCards.allSatisfy {
                    exactEquityHeadsUp(hero: reveal.cards, villain: reveal.opponent, board: board + [$0]).ties == 1
                }, activity.id)
                let shareNumerator = wins + ties / 2
                let shareString = ties.isMultiple(of: 2) ? "\(shareNumerator)" : "\(shareNumerator).5"
                let ratio = "\(shareString) / \(total)"
                XCTAssertEqual(share, "(\(wins) + \(ties) ÷ 2) / \(total) = \(ratio)", activity.id)
                if let chosen { XCTAssertEqual(chosen, ratio, activity.id) }
            }

            guard reveal.board.count == 5 else { continue }
            let river = reveal.board[4]
            XCTAssertFalse(visible.union(removed).contains(river), activity.id)
            let result = exactEquityHeadsUp(hero: reveal.cards, villain: reveal.opponent, board: reveal.board)
            if let resultText = row("Result", in: reveal) {
                let expected = result.wins == 1 ? "I win" : (result.ties == 1 ? "It's a tie" : "The opponent wins")
                XCTAssertEqual(resultText, expected, activity.id)
                if let chosen { XCTAssertEqual(chosen, expected, activity.id) }
            } else {
                XCTAssertEqual(try chosen.map(cards), [river], activity.id)
                switch activity.title(in: .english) {
                case "Find the winning river":
                    XCTAssertEqual(result.wins, 1, activity.id)
                    if activity.id == "G7-01" {
                        XCTAssertEqual(bestHand(reveal.cards + reveal.board).category, 7, activity.id)
                        XCTAssertTrue(activity.explanation(in: .english)?.contains("four sevens") == true)
                        XCTAssertTrue(activity.explanation(in: .korean)?.contains("7 네 장") == true)
                    }
                case "A stronger hand can still lose":
                    XCTAssertEqual(result.wins + result.ties, 0, activity.id)
                    XCTAssertGreaterThan(bestHand(reveal.cards + reveal.board).category,
                                         bestHandOfAny(reveal.cards + board).category, activity.id)
                default:
                    let legalOptions = try choices.flatMap(cards).filter { !visible.union(removed).contains($0) }
                    XCTAssertEqual(legalOptions, [river], activity.id)
                }
            }
        }
    }

    func testExactRangeWeightsShowConditionalWinsTiesAndDenominators() throws {
        let range = WinningCardsUnitContent.activities(for: .g6) + WinningCardsUnitContent.reviewActivities(for: .g6)
        for activity in range {
            let evidence = activity.evidence
            let reveal = activity.revealedEvidence ?? evidence
            let cases = try ["A", "B"].map { letter in
                let assumption = try XCTUnwrap(row("Opponent hand \(letter)", in: evidence))
                let parts = assumption.components(separatedBy: " · ")
                XCTAssertEqual(parts.count, 2, activity.id)
                let combo = try cards(parts[0])
                XCTAssertEqual(combo.count, 2, activity.id)
                XCTAssertEqual(Set(combo + evidence.cards + evidence.board).count, 8, activity.id)
                let weights = try parts[1].components(separatedBy: " / ").map { try XCTUnwrap(Int($0)) }
                XCTAssertEqual(weights.count, 2, activity.id)
                let result = exactEquityHeadsUp(hero: evidence.cards, villain: combo, board: evidence.board)
                let breakdown = try XCTUnwrap(row("Against \(letter)", in: reveal))
                XCTAssertTrue(breakdown.hasPrefix("\(result.total) legal rivers · \(result.wins) wins · \(result.ties) ties"), activity.id)
                return (result.equity, weights[0], weights[1])
            }
            XCTAssertEqual(cases[0].2, cases[1].2, activity.id)
            XCTAssertEqual(cases[0].1 + cases[1].1, cases[0].2, activity.id)

            let share = cases.reduce(0.0) { $0 + $1.0 * Double($1.1) / Double($1.2) }
            let formatted = String(format: "%.1f%%", locale: Locale(identifier: "en_US_POSIX"), share * 100)
            let rangeResult = try XCTUnwrap(row("Equity against the range", in: reveal))
            XCTAssertTrue(rangeResult.hasSuffix("≈ \(formatted)"), activity.id)
            if let answer = activity.correctChoice {
                let option = activity.choices(in: .english)[answer]
                if option.hasSuffix("%") {
                    XCTAssertEqual(option, formatted, activity.id)
                } else {
                    XCTAssertEqual(option, cases[0].0 > cases[1].0 ? "Hand A" : "Hand B", activity.id)
                }
                XCTAssertNil(row("Equity against the range", in: evidence), activity.id)
            }
        }
    }

    private func dealKey(_ activity: TableCourseActivity) -> String {
        let evidence = activity.evidence
        return [evidence.cards, evidence.opponent, Array(evidence.board.prefix(4))]
            .map { $0.map(\.description).sorted().joined() }.joined(separator: " ")
    }

    private func row(_ label: String, in evidence: TableCourseEvidence) -> String? {
        evidence.rows.first { $0.label.text(in: .english) == label }?.value.text(in: .english)
    }

    private func cards(_ display: String) throws -> [Card] {
        try display.split(separator: " ").map { name in
            let rankAndSuit = name.replacingOccurrences(of: "\u{FE0E}", with: "")
            XCTAssertEqual(String(name), rankAndSuit + "\u{FE0E}", "Card suits should use text presentation")
            return try XCTUnwrap(Deck.all.first { $0.display == rankAndSuit }, "Unknown card: \(name)")
        }
    }
}
