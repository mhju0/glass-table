// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class CapstoneUnitContentTests: XCTestCase {
    func testWholeHandUsesTheIdenticalLegalCoachReplayAndHidesPrivateCardsUntilShowdown() throws {
        let activities = TableCourseUnit.capstone.activities(for: .i6)
        let hand = CapstoneUnitContent.coachHand
        let review = try XCTUnwrap(hand.review)
        try hand.validate()
        let revealed = try XCTUnwrap(Card.parse(review.board.joined()))
        let hero = try XCTUnwrap(Card.parse(review.holeCards[0].joined()))
        let other = try XCTUnwrap(Card.parse(review.holeCards[2].joined()))
        XCTAssertEqual(activities.map { $0.evidence.cards }, Array(repeating: hero, count: 6))
        XCTAssertEqual(activities.map { $0.evidence.board.count }, [0, 0, 3, 4, 5, 5])
        XCTAssertTrue(activities.dropLast().allSatisfy { $0.evidence.opponent.isEmpty })
        for activity in activities { XCTAssertEqual(activity.evidence.board, Array(revealed.prefix(activity.evidence.board.count))) }
        XCTAssertEqual(activities.last?.evidence.opponent, other)
        XCTAssertEqual(activities.last?.correctChoice, compareHands(hero: hero + revealed, villain: other + revealed))
        XCTAssertEqual(review.contributions.reduce(0, +), 21)
        XCTAssertEqual(activities[4].choices(in: .english), ["17 chips", "21 chips", "25 chips"])
        XCTAssertEqual(activities[4].correctChoice, 1)
        XCTAssertEqual(activities[3].correctChoice, 2)
    }

    func testRiverPriceAndShowdownVariantsDistinguishBoundaryAndKickers() throws {
        XCTAssertEqual(TableCourseUnit.capstone.activities(for: .i4).dropFirst().map(\.correctChoice), [2, 1, 0])
        let showdown = TableCourseUnit.capstone.activities(for: .i5)
        XCTAssertEqual(showdown.dropFirst().map(\.correctChoice), [0, 1, 2])
        XCTAssertTrue(showdown[1].explanation(in: .english)?.contains("K kicker") == true)
        XCTAssertTrue(showdown[3].explanation(in: .english)?.hasPrefix("Both players can use the board.") == true)
        XCTAssertEqual(showdown[0].evidence.rows[0].value, showdown[0].evidence.rows[1].value)
        XCTAssertTrue(showdown.dropFirst().allSatisfy { $0.evidence.rows.isEmpty && $0.revealedEvidence?.rows.count == 2 })
    }

    func testCapstoneAndPriceReviewReuseEarlierObjectives() throws {
        var state = ProgressState()
        var price = TableCourseProgress(unit: .priceChance)
        var capstone = TableCourseProgress(unit: .capstone)
        for unit in [TableCourseUnit.priceChance, .capstone] {
            var progress = TableCourseProgress(unit: unit)
            while let activity = progress.activity {
                if let answer = activity.correctChoice {
                    XCTAssertTrue(progress.apply(.select(answer)))
                    XCTAssertTrue(progress.apply(.submit))
                }
                XCTAssertTrue(progress.apply(.advance))
            }
            if unit == .priceChance { price = progress } else { capstone = progress }
        }
        state.tableCourse = [price.unit.rawValue: price, capstone.unit.rawValue: capstone]

        XCTAssertEqual(CourseReviewSession.eligibleSkills(in: state, scope: .tableUnit(.priceChance)), [.d5])
        XCTAssertEqual(CourseReviewSession.eligibleSkills(in: state, scope: .tableUnit(.capstone)), [.e4])
        XCTAssertEqual(CourseReviewSession.eligibleSkills(in: state), [.d5, .e4])
        let review = try XCTUnwrap(CourseReviewSession(scope: .tableUnit(.capstone),
                                                       eligibleSkills: [.e4], seed: 20))
        XCTAssertTrue(review.isValid(in: state))
        var older = state
        older.schemaVersion = 11
        XCTAssertFalse(review.isValid(in: older))
        for unit in [TableCourseUnit.priceChance, .capstone] {
            var complete = try XCTUnwrap(state.progress(in: unit))
            while complete.phase != .finished {
                if let correct = complete.activity?.correctChoice {
                    XCTAssertTrue(complete.apply(.select(correct)))
                    XCTAssertTrue(complete.apply(.submit))
                }
                XCTAssertTrue(complete.apply(.advance))
            }
            state.tableCourse?[unit.rawValue] = complete
        }

        let priceSkills = CourseReviewSession.eligibleSkills(in: state, scope: .tableUnit(.priceChance))
        let capstoneSkills = CourseReviewSession.eligibleSkills(in: state, scope: .tableUnit(.capstone))
        XCTAssertEqual(Set(priceSkills), [.d5, .h2, .h3, .h4, .h5, .h6])
        XCTAssertEqual(Set(capstoneSkills), [.e4, .e6, .f4, .h4, .bestFive])
        let all = CourseReviewSession.eligibleSkills(in: state)
        XCTAssertEqual(all.count, Set(priceSkills + capstoneSkills).count)
        for (unit, skills) in [(TableCourseUnit.priceChance, priceSkills), (.capstone, capstoneSkills)] {
            let session = try XCTUnwrap(CourseReviewSession(scope: .tableUnit(unit), eligibleSkills: skills, seed: 41))
            XCTAssertTrue(session.isValid(in: state))
            XCTAssertEqual(session.itemCount, skills.count)
        }

        state.tableCourse?.removeValue(forKey: TableCourseUnit.capstone.rawValue)
        XCTAssertFalse(review.isValid(in: state))
    }
}
