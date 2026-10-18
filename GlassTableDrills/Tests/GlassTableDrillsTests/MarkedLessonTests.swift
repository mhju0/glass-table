import XCTest
@testable import GlassTableDrills

/// Learn marks exactly one row (owner, 2026-10-17): the lesson left open, else Hold'em
/// basics for a new learner, else the suggested next lesson.
final class MarkedLessonTests: XCTestCase {
    private func session(_ nodeID: String, phase: NodeSessionSnapshot.Phase) -> NodeSessionSnapshot {
        NodeSessionSnapshot(id: "s1", nodeID: nodeID, seed: 1, scheduledConcepts: ["rfi", "rfi", "rfi"],
                            phase: phase, formatVersion: 2)
    }

    func testAnOpenUnfinishedLessonIsMarkedInProgress() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        for phase: NodeSessionSnapshot.Phase in [.show, .together, .question, .reveal] {
            state.activeNodeSession = session("u3-rfi", phase: phase)
            XCTAssertEqual(Curriculum.markedLesson(in: state), .inProgress(try XCTUnwrap(Curriculum.node(id: "u3-rfi"))),
                           "\(phase)")
        }
    }

    /// The open lesson wins even over a brand-new learner's basics suggestion.
    func testAnOpenLessonOutranksTheBasicsSuggestion() throws {
        var state = ProgressState()
        state.activeNodeSession = session("u1-position", phase: .question)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .inProgress(try XCTUnwrap(Curriculum.node(id: "u1-position"))))
    }

    /// A summary closed with ✕ leaves the session saved at `.finished`; nothing is left
    /// to continue, so the row is not "in progress".
    func testAFinishedSessionCountsAsClosed() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        state.activeNodeSession = session("u1-showdown", phase: .finished)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try XCTUnwrap(Curriculum.node(id: "u1-position"))))
    }

    func testANewLearnerIsPointedAtHoldemBasics() {
        XCTAssertEqual(Curriculum.markedLesson(in: ProgressState()), .basics)
        XCTAssertTrue(Curriculum.suggestsBasicsLesson(in: ProgressState()))
    }

    func testAfterBasicsTheMarkFollowsTheSuggestedLesson() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try XCTUnwrap(Curriculum.node(id: "u1-showdown"))))
        XCTAssertEqual(Curriculum.markedLesson(in: state), Curriculum.suggestedLesson(in: state).map { .next($0) })
    }

    /// A passed lesson also ends the basics suggestion, even with basics unfinished.
    func testAPassedLessonMovesTheMarkToTheNextOne() throws {
        var state = ProgressState()
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        XCTAssertFalse(Curriculum.suggestsBasicsLesson(in: state))
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try XCTUnwrap(Curriculum.node(id: "u1-position"))))
        state.nodes["u1-position"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try XCTUnwrap(Curriculum.node(id: "u3-rfi"))))
    }

    /// Only a new player who took no starting check is sent to the basics.
    func testAStartingPointOrALevelSkipsTheBasicsSuggestion() {
        var state = ProgressState()
        state.placement = PlacementState(selfReport: .knowRules)
        XCTAssertFalse(Curriculum.suggestsBasicsLesson(in: state))
        if case .basics? = Curriculum.markedLesson(in: state) { XCTFail("No basics mark for a player who knows the rules") }
    }

    func testEveryLessonPassedLeavesNothingMarked() {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        for node in Curriculum.trackLessons { state.nodes[node.id] = NodeRecord(cleared: true) }
        XCTAssertNil(Curriculum.markedLesson(in: state))
        state.lastNodeID = "u2-callFold"
        XCTAssertNil(Curriculum.markedLesson(in: state), "A passed last lesson with nothing owed marks nothing")
    }

    // MARK: Following the learner (owner, 2026-10-18)

    private func node(_ id: String) throws -> CurriculumNode { try XCTUnwrap(Curriculum.node(id: id)) }

    /// A lesson played out of order and closed under the pass mark keeps the mark,
    /// where the suggestion would go back to the start of the path.
    func testALessonPlayedOutOfOrderAndNotPassedKeepsTheMark() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        state.nodes["u2-outs"] = NodeRecord(attempts: 1, best: LessonScore(right: 1, questions: 3))
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-showdown")), "Without a record")
        state.lastNodeID = "u2-outs"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u2-outs")))
    }

    /// A brand-new learner who went straight to a lesson is followed there, not sent
    /// back to Hold'em basics.
    func testTheLastLessonOutranksTheBasicsSuggestion() throws {
        var state = ProgressState()
        state.lastNodeID = "u1-position"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-position")))
    }

    /// Passed: the mark moves to the next owed lesson after it, not to the start.
    func testAPassedLastLessonMovesTheMarkToTheNextOwedLessonAfterIt() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        state.nodes["u2-outs"] = NodeRecord(cleared: true)
        state.lastNodeID = "u2-outs"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-potMath")))
        state.nodes["u1-potMath"] = NodeRecord(cleared: true)
        state.nodes["u2-equitySense"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u2-potOdds")), "Passed ones are skipped")
    }

    /// Nothing owed after it: wrap round to an earlier owed lesson, the way the
    /// suggestion does, from the learner's starting point.
    func testAPassedLastLessonWrapsToAnEarlierOwedLesson() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        state.nodes["u2-callFold"] = NodeRecord(cleared: true)
        state.lastNodeID = "u2-callFold"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-position")))
        state.placement = PlacementState(selfReport: .playRegularly)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u4-rangeRead")))
    }

    /// The open session still wins over the last lesson played.
    func testAnOpenSessionOutranksTheLastLesson() throws {
        var state = ProgressState()
        state.lastNodeID = "u2-outs"
        state.activeNodeSession = session("u3-rfi", phase: .question)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .inProgress(try node("u3-rfi")))
    }

    /// A challenge is a lesson the learner chose: marked while not passed; once passed,
    /// its track is skipped and the mark moves to the next track.
    func testAChallengeIsFollowedLikeALesson() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        state.lastNodeID = "u3-boss"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u3-boss")))
        state.nodes["u3-boss"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u4-rangeRead")))
    }

    /// An optional deeper lesson the learner chose is marked until passed; then the
    /// mark returns to the suggested lesson, since deeper lessons are never suggested.
    func testADeeperLessonIsFollowedUntilPassed() throws {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        state.nodes["u1-showdown"] = NodeRecord(cleared: true)
        state.lastNodeID = "u1-combos"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-combos")))
        state.nodes["u1-combos"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-position")))
        XCTAssertEqual(Curriculum.markedLesson(in: state), Curriculum.suggestedLesson(in: state).map { .next($0) })
    }

    /// A lesson outside the tracks (kept from an older path) has no row to mark once
    /// closed, so the old rule applies, as it does to an id this build does not know.
    func testALastLessonWithoutARowFallsBackToTheSuggestion() throws {
        let offPath = try XCTUnwrap(Curriculum.allNodes.first { Curriculum.track(containing: $0) == nil })
        for id in [offPath.id, "retired-node"] {
            var state = ProgressState()
            state.lastNodeID = id
            XCTAssertEqual(Curriculum.markedLesson(in: state), .basics, id)
        }
    }
}
