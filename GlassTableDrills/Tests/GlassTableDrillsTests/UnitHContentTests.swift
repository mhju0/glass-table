// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class UnitHContentTests: XCTestCase {
    func testTeachingAndReviewAreFreshBilingualAndComplete() throws {
        XCTAssertEqual(TableCourseUnit.priceChance.lessons, [.h1, .h2, .h3, .h4, .h5, .h6, .h7])
        var ids: Set<String> = []
        for lesson in TableCourseUnit.priceChance.lessons {
            let teaching = lesson.unit.activities(for: lesson)
            let review = PriceChanceUnitContent.reviewActivities(for: lesson)
            XCTAssertEqual(teaching.count, lesson == .h7 ? 5 : 4)
            XCTAssertTrue(teaching.first?.isExample == true)
            XCTAssertTrue(teaching.dropFirst().allSatisfy { !$0.isExample })
            XCTAssertEqual(review.count, [.h1, .h7].contains(lesson) ? 0 : 3)
            XCTAssertTrue(review.allSatisfy { !$0.isExample })
            let teachingEvidence = teaching.map(\.evidence)
            for activity in review {
                XCTAssertFalse(teachingEvidence.contains(activity.evidence), activity.id)
            }
            for activity in teaching + review {
                XCTAssertTrue(ids.insert(activity.id).inserted, activity.id)
                for language in LearningLanguage.allCases {
                    XCTAssertFalse(activity.title(in: language).isEmpty, activity.id)
                    XCTAssertFalse(activity.prompt(in: language)?.isEmpty ?? true, activity.id)
                    XCTAssertFalse(activity.explanation(in: language)?.isEmpty ?? true, activity.id)
                    let choices = activity.choices(in: language)
                    XCTAssertEqual(Set(choices).count, choices.count, activity.id)
                    if activity.isExample {
                        XCTAssertTrue(choices.isEmpty, activity.id)
                    } else {
                        XCTAssertTrue(choices.indices.contains(try XCTUnwrap(activity.correctChoice)), activity.id)
                    }
                }
            }
        }
    }

    func testCallCostAndFinalPotAreCalculatedFromShownPayments() throws {
        for lesson in [TableCourseLesson.h1, .h2] {
            for activity in gradedActivities(for: lesson) {
                let inPot = try chips("Pot now", in: activity)
                let paid = try chips("You paid this round", in: activity)
                let facing = try chips("Opponent paid this round", in: activity)
                let call = facing - paid
                let answer = lesson == .h1 ? call : inPot + call
                XCTAssertGreaterThan(inPot, paid + facing, activity.id)
                XCTAssertEqual(try correct(activity), "\(answer) chips", activity.id)
                XCTAssertEqual(try correct(activity, in: .korean), "칩 \(answer)개", activity.id)
            }
        }
    }

    func testBreakEvenShareMatchesCostOverFinalPot() throws {
        for activity in gradedActivities(for: .h3) {
            let pot = try chips("Pot now", in: activity)
            let cost = try chips("Extra to call", in: activity)
            let answer = try tenths(correct(activity))
            XCTAssertEqual(answer * (pot + cost), 1000 * cost, activity.id)
        }
    }

    func testFinalDecisionModelGradesGainsLossesAndExactBreakEven() throws {
        for lesson in [TableCourseLesson.h4, .h7] {
            var outcomes: Set<String> = []
            for activity in gradedActivities(for: lesson) {
                let cost = lesson == .h4
                    ? try chips("Extra to call", in: activity)
                    : try chips("Opponent paid this round", in: activity) - chips("You paid this round", in: activity)
                let pot = try chips("Pot now", in: activity)
                let equity = try tenths(value("Your average pot share", in: activity))
                let net = equity * (pot + cost) - 1000 * cost
                let answer = net == 0 ? "Break even" : net > 0 ? "Call" : "Fold"
                XCTAssertEqual(try correct(activity), answer, activity.id)
                outcomes.insert(answer)
                let prompt = try XCTUnwrap(activity.prompt(in: .english))
                for assumption in ["Calling ends the betting", "no fee or side pot", "Choose Break even"] {
                    XCTAssertTrue(prompt.contains(assumption), activity.id)
                }
            }
            XCTAssertEqual(outcomes, ["Call", "Fold", "Break even"])
        }
        let close = gradedActivities(for: .h7).prefix(3)
        XCTAssertEqual(try close.map { try tenths(value("Your average pot share", in: $0)) }, [370, 375, 380])
        XCTAssertEqual(try close.map { try correct($0) }, ["Fold", "Break even", "Call"])
        for activity in close {
            let cost = try chips("Opponent paid this round", in: activity) - chips("You paid this round", in: activity)
            let pot = try chips("Pot now", in: activity)
            XCTAssertEqual(1000 * cost, 375 * (pot + cost), activity.id)
        }
    }

    func testSameCardsOnlyChangingThePriceFlipsTheDecision() throws {
        let teaching = TableCourseUnit.priceChance.activities(for: .h5)
        let review = PriceChanceUnitContent.reviewActivities(for: .h5)
        for activity in teaching + review {
            let equity = try tenths(value("Your average pot share", in: activity))
            assertShare(equity, hero: activity.evidence.cards, activity: activity)
            let baseline = try chips("Pot before the bet", in: activity)
            let small = try chips("Small bet", in: activity)
            let large = try chips("Large bet", in: activity)
            XCTAssertLessThan(small, large, activity.id)
            if !activity.isExample {
                let smallProfit = gains(equity, cost: small, pot: baseline + small)
                let largeProfit = gains(equity, cost: large, pot: baseline + large)
                XCTAssertFalse(!smallProfit && largeProfit, activity.id)
                let answer = largeProfit ? "Both" : smallProfit ? "Small bet only" : "Neither"
                XCTAssertEqual(try correct(activity), answer, activity.id)
            }
        }
        XCTAssertEqual(try teaching.dropFirst().map { try correct($0) }, ["Small bet only", "Both", "Neither"])
    }

    func testSamePriceUsesSeparateHeroHandsAgainstTheDisclosedOpponent() throws {
        let teaching = TableCourseUnit.priceChance.activities(for: .h6)
        let review = PriceChanceUnitContent.reviewActivities(for: .h6)
        for activity in teaching + review {
            let pot = try chips("Pot now", in: activity)
            let cost = try chips("Extra to call", in: activity)
            var profitable: [String] = []
            for letter in ["A", "B"] {
                let row = try value("Hand \(letter) · Average pot share", in: activity)
                let fields = row.components(separatedBy: " · ")
                XCTAssertEqual(fields.count, 2, activity.id)
                let hand = try cards(XCTUnwrap(fields.first))
                let equity = try tenths(XCTUnwrap(fields.last))
                assertShare(equity, hero: hand, activity: activity)
                if gains(equity, cost: cost, pot: pot) { profitable.append(letter) }
            }
            let prompt = try XCTUnwrap(activity.prompt(in: .english))
            XCTAssertTrue(prompt.contains("Assume the opponent has the hand shown"))
            XCTAssertTrue(prompt.contains("no more betting"))
            if !activity.isExample {
                let answer = profitable.count == 2 ? "Both" : "Hand \(try XCTUnwrap(profitable.first)) only"
                XCTAssertEqual(try correct(activity), answer, activity.id)
            }
        }
        XCTAssertEqual(try teaching.dropFirst().map { try correct($0) }, ["Hand A only", "Hand B only", "Both"])
    }

    func testExactBreakEvenRequiresItsDeclaredChoiceInLessonAndCorrection() throws {
        var progress = TableCourseProgress(unit: .priceChance)
        while progress.activity?.id != "H7-02" {
            let activity = try XCTUnwrap(progress.activity, progress.lesson.rawValue)
            if let answer = activity.correctChoice {
                XCTAssertTrue(progress.apply(.select(answer)))
                XCTAssertFalse(progress.revealed)
                XCTAssertTrue(progress.apply(.submit))
            }
            XCTAssertTrue(progress.apply(.advance))
            if progress.phase == .results { XCTAssertTrue(progress.apply(.advance)) }
        }

        let activity = try XCTUnwrap(progress.activity)
        let call = try XCTUnwrap(activity.choices(in: .english).firstIndex(of: "Call"))
        XCTAssertTrue(progress.apply(.select(call)))
        XCTAssertNil(progress.answeredCorrectly)
        XCTAssertTrue(progress.apply(.submit))
        XCTAssertEqual(progress.answeredCorrectly, false)
        XCTAssertTrue(progress.apply(.advance))
        for _ in 0..<2 {
            XCTAssertTrue(progress.apply(.select(try XCTUnwrap(progress.activity?.correctChoice))))
            XCTAssertTrue(progress.apply(.submit))
            XCTAssertTrue(progress.apply(.advance))
        }
        XCTAssertEqual(progress.phase, .retry)
        XCTAssertEqual(progress.activity?.id, activity.id)
        XCTAssertTrue(progress.apply(.select(try XCTUnwrap(activity.correctChoice))))
        XCTAssertTrue(progress.apply(.submit))
        XCTAssertEqual(progress.answeredCorrectly, true)
    }

    private func gradedActivities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        lesson.unit.activities(for: lesson).filter { !$0.isExample } + PriceChanceUnitContent.reviewActivities(for: lesson)
    }

    private func correct(_ activity: TableCourseActivity, in language: LearningLanguage = .english) throws -> String {
        activity.choices(in: language)[try XCTUnwrap(activity.correctChoice)]
    }

    private func value(_ label: String, in activity: TableCourseActivity) throws -> String {
        let row = try XCTUnwrap(activity.evidence.rows.first { $0.label.text(in: .english) == label }, activity.id)
        return row.value.text(in: .english)
    }

    private func chips(_ label: String, in activity: TableCourseActivity) throws -> Int {
        let text = try value(label, in: activity)
        return try XCTUnwrap(text.split(separator: " ").first.flatMap { Int($0) })
    }

    private func tenths(_ percentage: String) throws -> Int {
        XCTAssertTrue(percentage.hasSuffix("%"))
        let fields = percentage.dropLast().split(separator: ".")
        let whole = try XCTUnwrap(fields.first.flatMap { Int($0) })
        let decimal = fields.count == 2 ? try XCTUnwrap(Int(fields[1])) : 0
        return 10 * whole + decimal
    }

    private func cards(_ labels: String) throws -> [Card] {
        let suits: [Character: String] = ["♣": "c", "♦": "d", "♥": "h", "♠": "s"]
        return try labels.split(separator: " ").map { label in
            let symbol = try XCTUnwrap(label.last.flatMap { suits[$0] })
            let rank = label.dropLast()
            return try XCTUnwrap(Card((rank == "10" ? "T" : String(rank)) + symbol))
        }
    }

    private func assertShare(_ equity: Int, hero: [Card], activity: TableCourseActivity) {
        let board = activity.evidence.board
        let opponent = activity.evidence.opponent
        let removed = Set(hero + opponent + board)
        XCTAssertEqual(hero.count, 2, activity.id)
        XCTAssertEqual(opponent.count, 2, activity.id)
        XCTAssertEqual(board.count, 4, activity.id)
        XCTAssertEqual(removed.count, 8, activity.id)
        let rivers = Deck.all.filter { !removed.contains($0) }
        let counts = rivers.map { compareHands(hero: hero + board + [$0], villain: opponent + board + [$0]) }
        let twiceShare = counts.filter { $0 == 0 }.count * 2 + counts.filter { $0 == 2 }.count
        XCTAssertEqual(twiceShare * 1000, equity * 2 * rivers.count, activity.id)
    }

    private func gains(_ equity: Int, cost: Int, pot: Int) -> Bool {
        callEV(equity: Double(equity) / 1000, toCall: Double(cost), pot: Double(pot)) > 0
    }
}
