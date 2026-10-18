// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// The step path (D53): each track at Learn, then at Apply, then its challenge; after
/// the four tracks, a lap of every Sharp lesson, then each challenge again.
final class StepCurriculumTests: XCTestCase {
    private func node(_ id: String) throws -> CurriculumNode { try XCTUnwrap(Curriculum.node(id: id), id) }

    private func state(cleared: [String] = []) -> ProgressState {
        var state = ProgressState()
        state.basicsLessonCompleted = true
        for id in cleared { state.nodes[id] = NodeRecord(cleared: true, attempts: 1) }
        return state
    }

    static let stepOrder = [
        "u1-showdown", "u1-position", "u1-showdown.2", "u1-boss",
        "u3-rfi", "u8-defend", "u3-boss",
        "u4-rangeRead", "u7-actionRead", "u4-boss",
        "u2-outs", "u1-potMath", "u2-equitySense", "u2-potOdds", "u2-callFold",
        "u1-potMath.2", "u2-callFold.2", "u2-boss",
        "u1-showdown.3", "u1-potMath.3", "u2-callFold.3", "u1-boss.3", "u2-boss.3",
    ]

    func testStepsRunEachTrackAtLearnThenApplyThenItsChallengeThenASharpLap() {
        XCTAssertEqual(Curriculum.steps.map(\.id), Self.stepOrder)
    }

    func testStepNodesAreTheirLessonAtALevel() throws {
        let apply = try node("u1-showdown.2")
        XCTAssertEqual(apply.kind, .drill(.showdown))
        XCTAssertEqual(apply.level, .apply)
        XCTAssertEqual(apply.baseID, "u1-showdown")
        XCTAssertEqual(try node("u1-showdown").level, .learn)
        XCTAssertEqual(try node("u2-boss.3").level, .sharp)
        XCTAssertEqual(try node("u2-boss.3").kind, try node("u2-boss").kind)
        for missing in ["u1-position.2", "u1-showdown.4", "u3-boss.3", "u1-boss.2", "u1-showdown.1"] {
            XCTAssertNil(Curriculum.node(id: missing), missing)
        }
        XCTAssertEqual(Curriculum.track(containing: apply)?.id, .basics)
        XCTAssertEqual(Curriculum.lessonSteps(for: try node("u1-potMath")).map(\.id),
                       ["u1-potMath", "u1-potMath.2", "u1-potMath.3"])
        XCTAssertEqual(Curriculum.lessonSteps(for: try node("u3-rfi")).map(\.id), ["u3-rfi"])
    }

    func testGoDeeperHasAChallengeOfItsOwnSkills() throws {
        let deeper = try XCTUnwrap(Curriculum.tracks.first(where: \.isOptional))
        let challenge = try XCTUnwrap(deeper.challenge)
        XCTAssertEqual(challenge.id, "deeper-boss")
        XCTAssertEqual(Curriculum.node(id: "deeper-boss"), challenge)
        XCTAssertEqual(Set(Curriculum.sessionConcepts(for: challenge, seed: 3)), [.combos, .rangeNotation, .evCall])
        XCTAssertFalse(Curriculum.steps.contains(challenge), "Go deeper is never suggested")
    }

    func testFollowingTheSuggestionWalksEveryStepInOrder() {
        var state = state()
        var suggested: [String] = []
        while let next = Curriculum.suggestedLesson(in: state) {
            suggested.append(next.id)
            state.nodes[next.id] = NodeRecord(cleared: true)
            if suggested.count > 40 { break }
        }
        // Passing a challenge skips what is left of its lap, so only challenges stay
        // owed when every step is taken in order: the suggestion visits each one.
        XCTAssertEqual(suggested, Self.stepOrder)
    }

    func testAPassedChallengeSkipsItsLapButNotTheSharpLap() throws {
        let state = state(cleared: ["u1-showdown", "u1-boss"])
        XCTAssertFalse(Curriculum.isOwed(try node("u1-position"), in: state))
        XCTAssertFalse(Curriculum.isOwed(try node("u1-showdown.2"), in: state))
        XCTAssertTrue(Curriculum.isOwed(try node("u1-showdown.3"), in: state))
        XCTAssertTrue(Curriculum.isOwed(try node("u1-boss.3"), in: state))
        let sharp = self.state(cleared: ["u1-boss.3"])
        XCTAssertFalse(Curriculum.isOwed(try node("u1-showdown.3"), in: sharp))
        XCTAssertTrue(Curriculum.isOwed(try node("u1-showdown"), in: sharp), "the first lap is its own")
    }

    func testTheMarkMovesFromAPassedStepToTheNextOwedStep() throws {
        var state = state(cleared: ["u1-showdown", "u1-position"])
        state.lastNodeID = "u1-position"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-showdown.2")))
        state.lastNodeID = "u1-showdown.2"
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-showdown.2")), "not passed yet")
        state.nodes["u1-showdown.2"] = NodeRecord(cleared: true)
        XCTAssertEqual(Curriculum.markedLesson(in: state), .next(try node("u1-boss")))
    }

    func testEasierLessonOfAStepIsTheStepBelowIt() throws {
        XCTAssertEqual(Curriculum.easierLesson(than: try node("u1-potMath.2"))?.id, "u1-potMath")
        XCTAssertEqual(Curriculum.easierLesson(than: try node("u1-potMath.3"))?.id, "u1-potMath.2")
        XCTAssertEqual(Curriculum.easierLesson(than: try node("u2-boss.3"))?.id, "u2-callFold.3")
    }

    func testSkipAheadFromASharpLessonIsTheSharpChallenge() throws {
        let state = state()
        XCTAssertEqual(Curriculum.skipAheadChallenge(after: try node("u1-potMath.3"), in: state)?.id, "u2-boss.3")
        XCTAssertEqual(Curriculum.skipAheadChallenge(after: try node("u1-potMath.2"), in: state)?.id, "u2-boss")
        XCTAssertNil(Curriculum.skipAheadChallenge(after: try node("u1-showdown.3"), in: state),
                     "nothing else in the basics Sharp lap")
    }

    func testGroundworkForAStepIsTheLessonStepsBeforeIt() throws {
        let state = state(cleared: ["u1-showdown", "u1-position"])
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: try node("u3-rfi"), in: state).map(\.id),
                       ["u1-showdown.2"], "challenges are never groundwork")
        XCTAssertEqual(Curriculum.unfinishedGroundwork(for: try node("u1-boss.3"), in: state).map(\.id),
                       ["u1-showdown.3"])
    }

    // MARK: Which step a skill is dealt at

    func testASkillIsPractisedAtTheHighestStepPassed() {
        XCTAssertEqual(Curriculum.passedLevel(of: .showdown, in: state()), .learn)
        XCTAssertEqual(Curriculum.passedLevel(of: .showdown, in: state(cleared: ["u1-showdown.2"])), .apply)
        XCTAssertEqual(Curriculum.passedLevel(of: .showdown, in: state(cleared: ["u1-showdown.3"])), .sharp)
        XCTAssertEqual(Curriculum.passedLevel(of: .outs, in: state(cleared: ["u2-outs"])), .learn)
    }

    func testAChallengeDealsEachSkillAtTheLearnersStepCappedByItsLap() throws {
        let state = state(cleared: ["u1-showdown.2", "u1-showdown.3"])
        XCTAssertEqual(Curriculum.challengeLevel(of: .showdown, in: try node("u1-boss"), state: state), .apply)
        XCTAssertEqual(Curriculum.challengeLevel(of: .showdown, in: try node("u1-boss.3"), state: state), .sharp)
        XCTAssertEqual(Curriculum.challengeLevel(of: .position, in: try node("u1-boss.3"), state: state), .learn)
        XCTAssertEqual(Curriculum.challengeLevel(of: .potMath, in: try node("u2-boss.3"), state: state), .learn)
    }

    // MARK: Promotion follows the step

    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    private func record(tier: MasteryTier = .familiar, proficientAt: Date? = nil) -> ConceptRecord {
        var r = ConceptRecord()
        r.total = 10; r.correct = 9; r.tier = tier; r.proficientAt = proficientAt
        return r
    }

    func testAPerfectFirstStepStopsAtFamiliarForASkillWithSteps() {
        var r = record()
        Mastery.promote(&r, evidence: SessionEvidence(attempted: 3, spotOn: 3), viaBoss: false,
                        level: .learn, of: .showdown, now: t0)
        XCTAssertEqual(r.tier, .familiar)
        Mastery.promote(&r, evidence: SessionEvidence(attempted: 3, spotOn: 3), viaBoss: false,
                        level: .apply, of: .showdown, now: t0)
        XCTAssertEqual(r.tier, .proficient)
    }

    func testASkillWithoutStepsKeepsTodaysRule() {
        var r = record()
        Mastery.promote(&r, evidence: SessionEvidence(attempted: 3, spotOn: 3), viaBoss: false,
                        level: .learn, of: .outs, now: t0)
        XCTAssertEqual(r.tier, .proficient)
        Mastery.promote(&r, evidence: SessionEvidence(attempted: 2, spotOn: 2), viaBoss: true,
                        level: .learn, of: .outs, now: t0.addingTimeInterval(Mastery.masteryCooldown))
        XCTAssertEqual(r.tier, .mastered)
    }

    func testMasteredNeedsThePerfectChallengeAtTheSharpStep() {
        let later = t0.addingTimeInterval(Mastery.masteryCooldown)
        var r = record(tier: .proficient, proficientAt: t0)
        Mastery.promote(&r, evidence: SessionEvidence(attempted: 2, spotOn: 2), viaBoss: true,
                        level: .apply, of: .potMath, now: later)
        XCTAssertEqual(r.tier, .proficient)
        Mastery.promote(&r, evidence: SessionEvidence(attempted: 2, spotOn: 2), viaBoss: true,
                        level: .sharp, of: .potMath, now: later)
        XCTAssertEqual(r.tier, .mastered)
    }
}
