// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import XCTest
@testable import GlassTableDrills

final class CourseReviewTests: XCTestCase {
    func testEligibilityRequiresTheMainSetAndExpandsOnlyItsObjectives() throws {
        var state = ProgressState()
        state.firstLessonCompleted = true
        state.unitA = UnitAProgress()
        state.unitB = UnitBProgress()
        state.pairLesson = PairLessonProgress(seed: 1)
        XCTAssertEqual(CourseReviewSession.eligibleSkills(in: state), [])
        XCTAssertNil(CourseReviewSession(scope: .all, eligibleSkills: [], seed: 1))

        var unitA = UnitAProgress()
        while unitA.stepNumber < unitA.stepCount {
            try advanceTeaching(&unitA)
        }
        state.unitA = unitA
        XCTAssertFalse(unitA.revealed)
        XCTAssertTrue(CourseReviewSession.eligibleSkills(in: state).isEmpty)
        try answerTeaching(&unitA, correct: false)
        state.unitA = unitA
        XCTAssertEqual(unitA.phase, .lesson)
        XCTAssertEqual(CourseReviewSession.eligibleSkills(in: state),
                       [.privateCards, .fiveCardHand, .sharedBestFive])

        XCTAssertTrue(unitA.apply(.advance))
        XCTAssertEqual(unitA.phase, .retry)
        state.unitA = unitA
        XCTAssertEqual(CourseReviewSession.studiedLessons(in: state, scope: .unitA), [.privateCards])
        XCTAssertTrue(CourseReviewSession.eligibleSkills(in: state, scope: .unitB).isEmpty)
        XCTAssertNil(CourseReviewSession(scope: .lesson(.privateCards),
                                         eligibleSkills: [.privateCards], seed: 1))

        var pair = PairLessonProgress(seed: 1)
        while pair.phase != .solo || pair.soloNumber != 8 {
            try advancePair(&pair, correct: false)
        }
        state.pairLesson = pair
        XCTAssertEqual(CourseReviewSession.studiedLessons(in: state), [.privateCards])
        XCTAssertTrue(pair.apply(.select(other(try XCTUnwrap(pair.currentQuestion?.winner)))))
        XCTAssertTrue(pair.apply(.submit))
        XCTAssertFalse(pair.passed)
        XCTAssertNil(pair.bestFirstRight)
        state.pairLesson = pair
        XCTAssertEqual(CourseReviewSession.studiedLessons(in: state), [.privateCards, .pairComparison])
        while pair.phase != .finished { try advancePair(&pair, correct: true) }
        XCTAssertEqual(pair.bestFirstRight, 0)
        XCTAssertTrue(pair.restart(seed: 2))
        state.pairLesson = pair
        XCTAssertEqual(CourseReviewSession.studiedLessons(in: state), [.privateCards, .pairComparison])
    }

    func testLessonReviewsUseThreeVariantsOrOneItemPerMappedObjective() throws {
        let single = try XCTUnwrap(CourseReviewSession(scope: .lesson(.findPair),
                                                  eligibleSkills: [.findPair, .findPair], seed: 12))
        XCTAssertEqual(single.skills, [.findPair])
        XCTAssertEqual(single.itemCount, 3)
        var replay = single
        var activityIDs: [String] = []
        while replay.phase == .question {
            XCTAssertEqual(replay.currentSkill, .findPair)
            activityIDs.append(try XCTUnwrap(replay.activity?.id))
            try answer(&replay, correct: true)
            XCTAssertTrue(replay.apply(.advance))
        }
        XCTAssertEqual(replay.phase, .setResults)
        XCTAssertEqual(replay.firstRight, 3)
        XCTAssertEqual(Set(activityIDs).count, 3)
        XCTAssertEqual(replay.setCount, 1)

        let compound = try XCTUnwrap(CourseReviewSession(scope: .lesson(.kickers),
            eligibleSkills: CourseReviewSkill.allCases.reversed(), seed: .max))
        XCTAssertEqual(compound.skills, [.kickers, .highCardRanks, .twoPairRanks, .fullHouseRanks])
        XCTAssertEqual(compound.itemCount, 4)
        XCTAssertEqual(compound.setCount, 1)
        XCTAssertNil(CourseReviewSession(scope: .lesson(.highCardRanks),
                                        eligibleSkills: CourseReviewSkill.allCases, seed: 1))
    }

    func testCumulativeReviewFreezesBothUnitsAndRestoresDraftAndExactRetry() throws {
        var state = try cumulativeFixture()
        let eligible = CourseReviewSession.eligibleSkills(in: state)
        XCTAssertEqual(eligible, [.privateCards, .fiveCardHand, .sharedBestFive, .rankAndSuit,
                                  .cardSuit, .suitStrength, .findPair, .pairBeatsHighCard, .pairComparison])
        var session = try XCTUnwrap(CourseReviewSession(scope: .all, eligibleSkills: eligible, seed: 4))
        XCTAssertTrue(session.isValid(in: state))
        XCTAssertEqual(session.setCount, 2)
        XCTAssertEqual(session.questionCount, 5)
        XCTAssertEqual(session.coveredCount, 0)
        XCTAssertEqual(session, CourseReviewSession(scope: .all, eligibleSkills: eligible.reversed(), seed: 4))

        var unitA = try XCTUnwrap(state.unitA)
        while !unitA.completedResults.contains(where: { $0.lesson == .streets }) {
            try advanceTeaching(&unitA)
        }
        state.unitA = unitA
        XCTAssertTrue(session.isValid(in: state))
        XCTAssertFalse(session.skills.contains(.streets))
        XCTAssertTrue(CourseReviewSession.eligibleSkills(in: state).contains(.streets))
        var cleared = state
        cleared.unitA = nil
        XCTAssertFalse(session.isValid(in: cleared))

        XCTAssertFalse(session.apply(.advance))
        let original = try XCTUnwrap(session.activity)
        var visited = [try XCTUnwrap(session.currentSkill)]
        let wrong = try wrongChoice(for: original)
        XCTAssertTrue(session.apply(.select(wrong)))
        XCTAssertEqual(session.coveredCount, 0)
        session = try restore(session)
        XCTAssertEqual(session.activity, original)
        XCTAssertEqual(session.selection, wrong)
        XCTAssertTrue(session.apply(.submit))
        XCTAssertEqual(session.coveredCount, 1)
        XCTAssertFalse(session.apply(.submit))
        XCTAssertFalse(session.apply(.select(try XCTUnwrap(original.correctChoice))))
        session = try restore(session)
        XCTAssertEqual(session.answeredCorrectly, false)
        XCTAssertTrue(session.apply(.advance))
        for _ in 0..<4 {
            visited.append(try XCTUnwrap(session.currentSkill))
            try answer(&session, correct: true)
            XCTAssertTrue(session.apply(.advance))
        }
        XCTAssertEqual(session.phase, .retry)
        XCTAssertEqual(session.activity, original)
        XCTAssertEqual(session.coveredCount, 5)
        try answer(&session, correct: false)
        session = try restore(session)
        XCTAssertEqual(session.activity, original)
        XCTAssertEqual(session.answeredCorrectly, false)
        XCTAssertEqual(session.coveredCount, 5)
        XCTAssertTrue(session.apply(.advance))
        XCTAssertEqual(session.phase, .setResults)
        XCTAssertEqual(session.completedResults.map(\.firstRight), [4])
        XCTAssertEqual(session.completedResults.map(\.retryRight), [0])

        XCTAssertTrue(session.apply(.advance))
        XCTAssertEqual(session.setNumber, 2)
        XCTAssertEqual(session.questionCount, 4)
        while session.phase == .question {
            visited.append(try XCTUnwrap(session.currentSkill))
            try answer(&session, correct: true)
            XCTAssertTrue(session.apply(.advance))
        }
        XCTAssertEqual(visited.count, eligible.count)
        XCTAssertEqual(Set(visited), Set(eligible))
        XCTAssertEqual(Set(visited.prefix(5).map(\.isUnitA)), [true, false])
        XCTAssertTrue(zip(visited.prefix(4), visited.dropFirst().prefix(3))
            .allSatisfy { earlier, later in earlier.isUnitA != later.isUnitA })
        XCTAssertEqual(session.phase, .setResults)
        XCTAssertEqual(session.coveredCount, 9)
        XCTAssertEqual(session.completedResults.map(\.questionCount), [5, 4])
        XCTAssertEqual(session.completedResults.map(\.firstRight), [4, 4])
        XCTAssertEqual(session.completedResults.map(\.retryCount), [1, 0])
        XCTAssertTrue(session.apply(.advance))
        XCTAssertEqual(session.phase, .finished)
        XCTAssertFalse(session.apply(.advance))
        XCTAssertEqual(session, try restore(session))
        XCTAssertTrue(session.isValid(in: state))
    }

    func testAllMissesRetryInOriginalOrderWithoutChangingCoverage() throws {
        var session = try XCTUnwrap(CourseReviewSession(scope: .unitA, eligibleSkills: [
            .privateCards, .fiveCardHand, .sharedBestFive, .rankAndSuit, .cardSuit
        ], seed: 1))
        var order: [String] = []
        var visited: [CourseReviewSkill] = []
        while session.phase == .question {
            visited.append(try XCTUnwrap(session.currentSkill))
            order.append(try XCTUnwrap(session.activity?.id))
            try answer(&session, correct: false)
            XCTAssertTrue(session.apply(.advance))
        }
        XCTAssertEqual(order.count, 5)
        XCTAssertEqual(Set(visited), Set(session.skills))
        XCTAssertNotEqual(visited, session.skills)
        XCTAssertEqual(session.retryCount, 5)
        XCTAssertEqual(session.coveredCount, 5)
        for id in order {
            XCTAssertEqual(session.phase, .retry)
            XCTAssertEqual(session.activity?.id, id)
            try answer(&session, correct: true)
            XCTAssertTrue(session.apply(.advance))
        }
        XCTAssertEqual(session.phase, .setResults)
        XCTAssertEqual(session.firstRight, 0)
        XCTAssertEqual(session.retryRight, 5)
        XCTAssertEqual(session.coveredCount, 5)
    }

    func testBestFiveRestoresDraftAndGradesFullRank() throws {
        var session = try XCTUnwrap(CourseReviewSession(scope: .lesson(.bestFive),
                                                     eligibleSkills: [.bestFive], seed: 0))
        let activity = try XCTUnwrap(session.activity)
        let available = activity.learner + activity.board
        let best = available.indices.filter { activity.correctFive.contains(available[$0]) }
        guard let inferior = fiveCardChoices(available.indices).first(where: { indices in
            compareHands(hero: indices.map { available[$0] }, villain: available) == 1
        }) else { return XCTFail("Expected a review deal with an inferior five") }
        XCTAssertFalse(session.apply(.select(0)))
        XCTAssertFalse(session.apply(.toggleCard(-1)))
        for i in inferior.prefix(3) { XCTAssertTrue(session.apply(.toggleCard(i))) }
        XCTAssertFalse(session.canSubmit)
        XCTAssertFalse(session.apply(.submit))

        session = try restore(session)
        XCTAssertEqual(session.activity, activity)
        XCTAssertEqual(session.selectedCardIndices, Set(inferior.prefix(3)))
        for i in inferior.dropFirst(3) { XCTAssertTrue(session.apply(.toggleCard(i))) }
        let sixth = try XCTUnwrap(available.indices.first(where: { !inferior.contains($0) }))
        XCTAssertFalse(session.apply(.toggleCard(sixth)))
        XCTAssertTrue(session.apply(.submit))
        XCTAssertEqual(session.answeredCorrectly, false)
        XCTAssertTrue(session.apply(.advance))
        while session.phase == .question {
            try answer(&session, correct: true)
            XCTAssertTrue(session.apply(.advance))
        }
        XCTAssertEqual(session.activity, activity)
        XCTAssertEqual(session.phase, .retry)

        let tiedAlternative = fiveCardChoices(available.indices).first(where: { indices in
            indices != best && compareHands(hero: indices.map { available[$0] }, villain: available) == 2
        })
        for i in tiedAlternative ?? best { XCTAssertTrue(session.apply(.toggleCard(i))) }
        XCTAssertTrue(session.apply(.submit))
        XCTAssertEqual(session.answeredCorrectly, true)
        XCTAssertEqual(session.coveredCount, 3)
    }

    func testInvalidImportedScheduleOrCursorCannotApply() throws {
        let valid = try XCTUnwrap(CourseReviewSession(scope: .lesson(.findPair),
                                                   eligibleSkills: [.findPair], seed: 2))
        let data = try JSONEncoder().encode(valid)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let items = try XCTUnwrap(fields["items"] as? [[String: Any]])
        for changes: [String: Any] in [
            ["contentVersion": 2],
            ["setIndex": Int.max],
            ["itemIndex": -1],
            ["retryIndex": Int.max],
            ["finished": true],
            ["items": [items[0], items[0], items[2]]],
            ["firstAnswers": [["choice": ["_0": 999]]]],
            ["draft": ["cards": ["_0": [Int.max]]]]
        ] {
            let tampered = fields.merging(changes, uniquingKeysWith: { _, replacement in replacement })
            var decoded = try JSONDecoder().decode(CourseReviewSession.self,
                from: JSONSerialization.data(withJSONObject: tampered))
            XCTAssertFalse(decoded.isValid)
            XCTAssertFalse(decoded.apply(.advance))
        }
    }

    private func cumulativeFixture() throws -> ProgressState {
        var unitA = UnitAProgress()
        while !unitA.completedResults.contains(where: { $0.lesson == .findPair }) {
            try advanceTeaching(&unitA)
        }
        var unitB = UnitBProgress()
        while unitB.phase != .pairLesson {
            if unitB.phase == .lesson, let activity = unitB.activity, activity.kind == .choice {
                XCTAssertTrue(unitB.apply(.select(try XCTUnwrap(activity.correctChoice))))
                XCTAssertTrue(unitB.apply(.submit))
            }
            XCTAssertTrue(unitB.apply(.advance))
        }
        var pair = PairLessonProgress(seed: 2)
        while pair.phase != .finished { try advancePair(&pair, correct: true) }
        XCTAssertTrue(unitB.apply(.completePairLesson(bestFirstRight: try XCTUnwrap(pair.bestFirstRight))))

        var state = ProgressState()
        state.unitA = unitA
        state.unitB = unitB
        state.pairLesson = pair
        return state
    }

    private func advanceTeaching(_ unit: inout UnitAProgress) throws {
        if let activity = unit.activity, activity.kind != .example, !unit.revealed {
            try answerTeaching(&unit, correct: true)
        }
        XCTAssertTrue(unit.apply(.advance))
    }

    private func answerTeaching(_ unit: inout UnitAProgress, correct: Bool) throws {
        let activity = try XCTUnwrap(unit.activity)
        let answer = activity.rightIndex ?? 0
        let wrong = activity.choices.indices.first(where: { $0 != answer })
        XCTAssertTrue(unit.apply(.select(correct ? answer : try XCTUnwrap(wrong))))
        XCTAssertTrue(unit.apply(.submit))
    }

    private func advancePair(_ pair: inout PairLessonProgress, correct: Bool) throws {
        if pair.phase != .example && !pair.revealed {
            let winner = try XCTUnwrap(pair.currentQuestion?.winner)
            XCTAssertTrue(pair.apply(.select(correct ? winner : other(winner))))
            XCTAssertTrue(pair.apply(.submit))
        }
        XCTAssertTrue(pair.apply(.advance))
    }

    private func other(_ side: PairLessonSide) -> PairLessonSide {
        side == .learner ? .opponent : .learner
    }

    private func answer(_ session: inout CourseReviewSession, correct: Bool) throws {
        let activity = try XCTUnwrap(session.activity)
        switch activity.kind {
        case .choice:
            let index = correct ? try XCTUnwrap(activity.correctChoice) : try wrongChoice(for: activity)
            XCTAssertTrue(session.apply(.select(index)))
        case .bestFive:
            precondition(correct, "The wrong-five test selects its cards explicitly")
            for (index, card) in (activity.learner + activity.board).enumerated()
                where activity.correctFive.contains(card) {
                XCTAssertTrue(session.apply(.toggleCard(index)))
            }
        }
        XCTAssertTrue(session.apply(.submit))
        XCTAssertEqual(session.answeredCorrectly, correct)
    }

    private func wrongChoice(for activity: CourseReviewActivity) throws -> Int {
        try XCTUnwrap(activity.choices(in: .english).indices.first(where: { $0 != activity.correctChoice }))
    }

    private func fiveCardChoices(_ indices: Range<Int>) -> [[Int]] {
        (0..<(1 << indices.count)).compactMap { mask in
            let selected = indices.filter { (mask & (1 << $0)) != 0 }
            return selected.count == 5 ? selected : nil
        }
    }

    private func restore(_ session: CourseReviewSession) throws -> CourseReviewSession {
        let restored = try JSONDecoder().decode(CourseReviewSession.self,
                                                from: JSONEncoder().encode(session))
        XCTAssertTrue(restored.isValid)
        return restored
    }
}
