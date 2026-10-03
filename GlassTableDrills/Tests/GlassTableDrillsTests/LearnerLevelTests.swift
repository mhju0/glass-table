import XCTest
@testable import GlassTableDrills

final class LearnerLevelTests: XCTestCase {
    private func state(_ report: PlacementSelfReport?, recommended: Concept? = nil,
                       cleared: [String] = []) -> ProgressState {
        var state = ProgressState()
        if report != nil || recommended != nil {
            state.placement = PlacementState(selfReport: report,
                                             recommendedConcept: recommended?.rawValue,
                                             skipped: recommended == nil)
        }
        for id in cleared { state.nodes[id] = NodeRecord(cleared: true, attempts: 1) }
        return state
    }

    func testLevelIsTheSavedSelfReportAndDefaultsToNewPlayer() {
        XCTAssertEqual(ProgressState().level, .newToPoker)
        XCTAssertEqual(state(.knowRules).level, .knowRules)
        XCTAssertEqual(state(nil, recommended: .potOdds).level, .newToPoker)
    }

    func testUpNextStartsWhereTheLevelStarts() {
        XCTAssertEqual(Curriculum.suggestedLesson(in: state(.newToPoker))?.id, "u1-showdown")
        XCTAssertEqual(Curriculum.suggestedLesson(in: state(.knowRules))?.id, "u1-position")
        XCTAssertEqual(Curriculum.suggestedLesson(in: state(.playRegularly))?.id, "u4-rangeRead")
    }

    func testTheStartingCheckResultWinsOverTheLevelDefault() {
        XCTAssertEqual(Curriculum.suggestedLesson(in: state(.playRegularly, recommended: .potOdds))?.id,
                       "u2-potOdds")
    }

    func testUpNextReturnsToEarlierLessonsOnceTheLaterOnesAreDone() {
        let done = state(.playRegularly, cleared: ["u4-rangeRead", "u7-actionRead"])
        XCTAssertEqual(Curriculum.suggestedLesson(in: done)?.id, "u1-showdown")
    }

    func testAPassedTrackChallengeSkipsThatTracksLessons() {
        let passed = state(.knowRules, cleared: ["u1-position", "u3-boss"])
        XCTAssertEqual(Curriculum.suggestedLesson(in: passed)?.id, "u2-outs")
    }

    func testLessonsBeforeTheLevelStartAreNotAskedForFirst() {
        let position = Curriculum.node(id: "u1-position")!
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: position, in: state(.newToPoker)).map(\.id),
                       ["u1-showdown", "u1-potMath"])
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: position, in: state(.knowRules)), [])
        let rfi = Curriculum.node(id: "u3-rfi")!
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: rfi, in: state(.knowRules)).map(\.id),
                       ["u1-position"])
    }

    func testTwoRoughLessonsInARowTurnGuidanceUpAndOneBetterLessonTurnsItBack() {
        var state = state(.playRegularly)
        XCTAssertFalse(state.helpsFirstQuestion)
        state.recordLessonResult(questions: 3, missed: 2, helped: 0)
        XCTAssertFalse(state.guidanceIsUp)
        state.recordLessonResult(questions: 3, missed: 2, helped: 1)
        XCTAssertTrue(state.guidanceIsUp)
        XCTAssertTrue(state.helpsFirstQuestion)
        state.recordLessonResult(questions: 3, missed: 1, helped: 0)
        XCTAssertFalse(state.guidanceIsUp)
        XCTAssertEqual(state.lessonTrend, 0)
    }

    func testThreeCleanLessonsInARowOfferSkippingAhead() {
        var state = state(.newToPoker)
        XCTAssertTrue(state.helpsFirstQuestion)
        for _ in 0..<2 { state.recordLessonResult(questions: 3, missed: 0, helped: 1) }
        XCTAssertFalse(state.offersSkipAhead)
        state.recordLessonResult(questions: 3, missed: 0, helped: 1)
        XCTAssertTrue(state.offersSkipAhead)
        state.recordLessonResult(questions: 3, missed: 2, helped: 1)
        XCTAssertFalse(state.offersSkipAhead)
        XCTAssertEqual(state.lessonTrend, -1)
    }

    func testALessonSolvedOnlyWithHelpIsNeitherCleanNorRough() {
        var state = ProgressState()
        state.recordLessonResult(questions: 3, missed: 0, helped: 3)
        XCTAssertEqual(state.lessonTrend, 0)
    }

    func testSkipAheadChallengeIsTheTracksOwnWhileLessonsRemain() {
        let position = Curriculum.node(id: "u1-position")!
        XCTAssertEqual(Curriculum.skipAheadChallenge(after: position, in: state(.knowRules))?.id, "u3-boss")
        XCTAssertNil(Curriculum.skipAheadChallenge(after: position,
            in: state(.knowRules, cleared: ["u1-position", "u3-rfi", "u8-defend"])))
        XCTAssertNil(Curriculum.skipAheadChallenge(after: position, in: state(.knowRules, cleared: ["u3-boss"])))
        XCTAssertNil(Curriculum.skipAheadChallenge(after: Curriculum.node(id: "u3-boss")!, in: state(.knowRules)))
    }

    func testLessonTrendSurvivesSavingAndOldFilesReadAsNone() throws {
        var state = ProgressState()
        state.recordLessonResult(questions: 3, missed: 3, helped: 0)
        let data = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(ProgressState.self, from: data).lessonTrend, -1)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["lessonTrend"] = nil
        let old = try JSONSerialization.data(withJSONObject: object)
        XCTAssertNil(try JSONDecoder().decode(ProgressState.self, from: old).lessonTrend)
    }

    func testPlainWordsLeadUnlessTheLearnerPlaysSometimes() {
        XCTAssertFalse(PlacementSelfReport.newToPoker.leadsWithTerms)
        XCTAssertFalse(PlacementSelfReport.knowRules.leadsWithTerms)
        XCTAssertTrue(PlacementSelfReport.playRegularly.leadsWithTerms)
    }
}
