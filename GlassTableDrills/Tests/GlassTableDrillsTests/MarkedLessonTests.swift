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
    }
}
