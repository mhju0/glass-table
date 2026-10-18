// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableDrills
@testable import GlassTable

/// The model deals and saves each question at the learner's step (D53).
@MainActor
final class StepModelTests: XCTestCase {
    private var dir: URL!
    private var store: ProgressionStore!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gt-steps-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        store = ProgressionStore(url: dir.appendingPathComponent("progression.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func passed(_ ids: String...) -> ProgressState {
        var state = ProgressState()
        for id in ids { state.nodes[id] = NodeRecord(cleared: true, clearedAt: Date(), attempts: 1) }
        state.introducedConcepts = [Concept.showdown.rawValue]
        return state
    }

    /// The correct showdown answer at a step, saved the way the drill saves it.
    private func showdownAnswer(seed: UInt64, index: Int, level: DrillLevel) throws -> (Data, Data) {
        let winner = gradeShowdown(answer: 0,
            spot: ShowdownSpotGenerator.spot(baseSeed: seed, index: index, level: level)).winner
        return (try JSONEncoder().encode(SavedDrillInput.integer(winner)),
                try JSONEncoder().encode(SavedDrillReveal(band: "spotOn")))
    }

    func testPracticeRoundDealsThePassedStepAndKeepsItAcrossRelaunch() throws {
        try store.save(passed("u1-showdown", "u1-showdown.2"))
        let model = ProgressionModel(store: store)
        XCTAssertTrue(model.beginRound(concept: .showdown, seed: 77, roundID: "r", expectedEpoch: model.epoch))
        let round = try XCTUnwrap(model.state.activeRound)
        XCTAssertEqual(round.level, 2)
        XCTAssertEqual(round.formatVersion, 2)
        let (input, reveal) = try showdownAnswer(seed: 77, index: 2, level: .apply)
        XCTAssertTrue(model.commitRoundAnswer(roundID: "r", attemptID: "a", ordinal: 0, band: .spotOn,
            language: "en", assisted: false, input: input, reveal: reveal, expectedEpoch: model.epoch))
        XCTAssertEqual(model.state.recentEvidence.last?.key.level, 2)
        // The reload regrades the saved answer against the Apply spot it was dealt.
        let relaunched = ProgressionModel(store: store)
        XCTAssertNil(relaunched.unreadable)
        XCTAssertEqual(relaunched.state.activeRound?.answers.count, 1)
    }

    func testFirstStepPracticeKeepsTheOldRoundShape() throws {
        try store.save(passed("u1-showdown"))
        let model = ProgressionModel(store: store)
        XCTAssertTrue(model.beginRound(concept: .showdown, seed: 77, roundID: "r", expectedEpoch: model.epoch))
        XCTAssertNil(model.state.activeRound?.level)
        XCTAssertEqual(model.state.activeRound?.formatVersion, 1)
    }

    func testALaterStepGoesStraightToItsQuestions() throws {
        let model = ProgressionModel(store: store)
        let step = try XCTUnwrap(Curriculum.node(id: "u1-potMath.2"))
        XCTAssertTrue(model.beginNodeSession(step, seed: 5, expectedEpoch: model.epoch))
        XCTAssertEqual(model.state.activeNodeSession?.phase, .question)
        XCTAssertEqual(model.state.activeNodeSession?.level(at: 0), .apply)
        XCTAssertEqual(model.state.lastNodeID, "u1-potMath.2")
    }

    func testAChallengeDealsEachSkillAtItsStep() throws {
        try store.save(passed("u1-showdown", "u1-showdown.2", "u1-showdown.3"))
        let model = ProgressionModel(store: store)
        let challenge = try XCTUnwrap(Curriculum.node(id: "u1-boss"))
        XCTAssertTrue(model.beginNodeSession(challenge, seed: 9, expectedEpoch: model.epoch))
        let session = try XCTUnwrap(model.state.activeNodeSession)
        for (ordinal, name) in session.scheduledConcepts.enumerated() {
            // The first lap's challenge stops at Apply, even after Sharp is passed.
            XCTAssertEqual(session.level(at: ordinal), name == Concept.showdown.rawValue ? .apply : .learn)
        }
        XCTAssertEqual(ProgressionModel(store: store).state.activeNodeSession?.levels, session.levels)
    }

    func testOnlyAPerfectStepTwoLessonEarnsStrong() throws {
        for (id, tier) in [("u1-showdown", MasteryTier.familiar), ("u1-showdown.2", .proficient)] {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent("progression.json"))
            store = ProgressionStore(url: dir.appendingPathComponent("progression.json"))
            try store.save(passed())
            let model = ProgressionModel(store: store)
            let node = try XCTUnwrap(Curriculum.node(id: id))
            XCTAssertTrue(model.beginNodeSession(node, seed: 3, expectedEpoch: model.epoch))
            let session = try XCTUnwrap(model.state.activeNodeSession)
            XCTAssertEqual(session.phase, .question, id)
            for ordinal in session.scheduledConcepts.indices {
                let (input, reveal) = try showdownAnswer(seed: session.seed, index: ordinal + 2,
                                                         level: session.level(at: ordinal))
                XCTAssertTrue(model.commitNodeAnswer(sessionID: session.id, attemptID: "\(id)-\(ordinal)",
                    ordinal: ordinal, band: .spotOn, input: input, reveal: reveal, language: .english,
                    expectedEpoch: model.epoch), id)
                if ordinal + 1 < session.scheduledConcepts.count {
                    XCTAssertTrue(model.nextNodeQuestion(sessionID: session.id, afterOrdinal: ordinal,
                                                         expectedEpoch: model.epoch))
                }
            }
            XCTAssertEqual(model.record(for: .showdown).tier, tier, id)
            XCTAssertEqual(model.state.nodes[id]?.cleared, true, id)
        }
    }

    func testATableDecisionCountsOnceAndMovesNoSkill() {
        let model = ProgressionModel(store: store)
        XCTAssertTrue(model.recordTableDecision(attemptID: "table:1:1:1", band: .spotOn, language: .korean))
        XCTAssertTrue(model.recordTableDecision(attemptID: "table:1:1:1", band: .spotOn, language: .korean))
        let rows = model.state.dailySummaries.filter { $0.key.mode == "table" }
        XCTAssertEqual(rows.map(\.exact), [1])
        XCTAssertTrue(model.state.concepts.isEmpty)
    }
}
