import XCTest
import GlassTableEngine
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
        let reads = state(.playRegularly, cleared: ["u4-rangeRead", "u7-actionRead",
                                                    "u4-rangeRead.2", "u7-actionRead.2"])
        XCTAssertEqual(Curriculum.suggestedLesson(in: reads)?.id, "u4-boss", "D53: the track's challenge")
        let read = state(.playRegularly, cleared: ["u4-rangeRead", "u7-actionRead", "u4-boss"])
        XCTAssertEqual(Curriculum.suggestedLesson(in: read)?.id, "u2-outs")
        // The first lap wraps round before any third step is suggested.
        let done = state(.playRegularly, cleared: ["u4-boss", "u2-boss"])
        XCTAssertEqual(Curriculum.suggestedLesson(in: done)?.id, "u1-showdown")
    }

    func testAPassedTrackChallengeSkipsThatTracksLessons() {
        let passed = state(.knowRules, cleared: ["u1-boss", "u3-boss"])
        XCTAssertEqual(Curriculum.suggestedLesson(in: passed)?.id, "u4-rangeRead")
    }

    /// D48: the check's pot and price questions are math, which comes last, so missing
    /// them starts the learner at the game rather than half-way down the path.
    func testTheStartingCheckStartsAtTheGameAndOnlyAWrongShowdownGoesBack() {
        let right = ["showdown": "pair", "pot": "include-blinds", "price": "compare-call-to-pot"]
        XCTAssertEqual(PlacementGuide.recommendation(report: .knowRules, answers: [:]), .showdown)
        XCTAssertEqual(PlacementGuide.recommendation(report: .knowRules, answers: right), .position)
        XCTAssertEqual(PlacementGuide.recommendation(report: .playRegularly, answers: right), .rangeRead)
        for missed in ["pot", "price"] {
            var answers = right
            answers[missed] = "unsure"
            XCTAssertEqual(PlacementGuide.recommendation(report: .playRegularly, answers: answers), .position)
            XCTAssertEqual(PlacementGuide.recommendation(report: .knowRules, answers: answers), .position)
        }
    }

    func testLessonsBeforeTheLevelStartAreNotAskedForFirst() {
        let position = Curriculum.node(id: "u1-position")!
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: position, in: state(.newToPoker)).map(\.id),
                       ["u1-showdown"])
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: position, in: state(.knowRules)), [])
        let rfi = Curriculum.node(id: "u3-rfi")!
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: rfi, in: state(.knowRules)).map(\.id),
                       ["u1-position", "u1-showdown.2", "u1-position.2"])
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
        let rfi = Curriculum.node(id: "u3-rfi")!
        XCTAssertEqual(Curriculum.skipAheadChallenge(after: rfi, in: state(.knowRules))?.id, "u3-boss")
        XCTAssertNil(Curriculum.skipAheadChallenge(after: rfi,
            in: state(.knowRules, cleared: ["u3-rfi", "u8-defend", "u3-rfi.2", "u8-defend.2"])))
        XCTAssertNil(Curriculum.skipAheadChallenge(after: rfi, in: state(.knowRules, cleared: ["u3-boss"])))
        let position = Curriculum.node(id: "u1-position")!
        XCTAssertEqual(Curriculum.skipAheadChallenge(after: position, in: state(.newToPoker))?.id, "u1-boss")
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

}

final class PlainQuestionWordsTests: XCTestCase {
    func testOddsWordsReduceAWholePercentExactly() {
        XCTAssertEqual(oddsWords(25, language: .english), "1 in 4")
        XCTAssertEqual(oddsWords(30, language: .english), "3 in 10")
        XCTAssertEqual(oddsWords(15, language: .english), "3 in 20")
        XCTAssertEqual(oddsWords(100, language: .english), "every time")
        XCTAssertEqual(oddsWords(0, language: .english), "never")
        XCTAssertEqual(oddsWords(25, language: .korean), "4번 중 1번")
    }

    func testFrequencyWordsCoverTheWholeScaleInOrder() {
        let words = stride(from: 0.0, through: 100, by: 10).map { frequencyWord($0, language: .english) }
        XCTAssertEqual(words.first, "Rarely")
        XCTAssertEqual(frequencyWord(50, language: .english), "About half the time")
        XCTAssertEqual(words.last, "Almost always")
        XCTAssertEqual(NSOrderedSet(array: words).count, 5)
    }

    func testOpeningGroupsComeFromThePublishedChart() throws {
        let aces = try XCTUnwrap(Card.parse("AsAh"))
        let trash = try XCTUnwrap(Card.parse("7s2h"))
        XCTAssertEqual(RFIChart.group(of: aces), .always)
        XCTAssertEqual(RFIChart.group(of: trash), .fold)
        var seen = Set<OpeningGroup>()
        for spot in (0..<200).map({ RFISpotGenerator.spot(baseSeed: 9, index: $0) }) {
            let group = RFIChart.group(of: spot.hand)
            seen.insert(group)
            let opens = RFIChart.opens(spot.hand, from: spot.seat)
            switch group {
            case .always: XCTAssertTrue(opens, "An always-play hand opens from every seat")
            case .fold: XCTAssertFalse(opens, "A fold-group hand opens from no seat")
            case .late: XCTAssertFalse(RFIChart.opens(spot.hand, from: .utg))
            }
        }
        XCTAssertEqual(seen, [.always, .late, .fold])
    }

    /// Explanations name a seat in everyday words first and keep its code beside them.
    func testExplanationsLeadWithThePlainSeatName() {
        for language in [LearningLanguage.korean, .english] {
            for index in 0..<12 {
                let range = RangeReadSpotGenerator.spot(baseSeed: 3, index: index)
                let first = range.actionLines(in: language)[0]
                XCTAssertTrue(Position.allCases.contains { first.hasPrefix($0.plainName(in: language)) }, first)

                let defend = DefendSpotGenerator.spot(baseSeed: 3, index: index)
                let why = gradeDefend(chosen: .fold, spot: defend, language: language).whyText
                XCTAssertTrue(why.hasPrefix(defend.opener.plainName(in: language)), why)

                let position = PositionSpotGenerator.spot(baseSeed: 3, index: index)
                let told = gradePosition(answer: 0, spot: position, language: language).whyText
                XCTAssertTrue(Position.allCases.contains { told.contains($0.plainName(in: language)) }, told)
            }
        }
    }
}
