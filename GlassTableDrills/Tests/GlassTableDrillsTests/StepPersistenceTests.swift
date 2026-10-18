// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// Schema 5 (D53): what a step adds to `progression.json`, how an older file is
/// upgraded to it, and the table's decisions in the daily summaries.
final class StepPersistenceTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("gt-steps-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: dir) }

    private func store() -> ProgressionStore { ProgressionStore(url: dir.appendingPathComponent("progress.json")) }

    private let seed: UInt64 = 5
    private let t0 = Date(timeIntervalSince1970: 1_790_380_800)

    /// A pot answer at question 1 (spot index 2), right at `answeredAt` and saved as such.
    private func potAnswer(answeredAt level: DrillLevel, ordinal: Int = 0) throws -> RoundAnswer {
        let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: ordinal + 2, level: level)
        return RoundAnswer(attemptID: "a\(ordinal)", ordinal: ordinal, band: .spotOn, submittedAt: t0,
                           input: try JSONEncoder().encode(SavedDrillInput.integer(spot.correctAnswer)),
                           reveal: try JSONEncoder().encode(SavedDrillReveal(band: GradeBand.spotOn.rawValue)))
    }

    private func imports(_ state: ProgressState) -> Bool {
        (try? store().importData(JSONEncoder().encode(state))) != nil
    }

    func testTheSchemaIsFive() {
        XCTAssertEqual(ProgressState.currentSchemaVersion, 5)
    }

    // MARK: Saved answers regrade at their step

    func testAPracticeRoundAtAStepSavesItsLevelInFormatTwo() throws {
        func state(format: Int, level: Int?, answeredAt: DrillLevel) throws -> ProgressState {
            var round = PracticeRound(id: "r", concept: Concept.potMath.rawValue, seed: seed, formatVersion: format)
            round.level = level
            round.answers = [try potAnswer(answeredAt: answeredAt)]
            round.phase = .reveal
            var state = ProgressState()
            state.activeRound = round
            return state
        }
        XCTAssertTrue(imports(try state(format: 2, level: 3, answeredAt: .sharp)))
        XCTAssertTrue(imports(try state(format: 2, level: nil, answeredAt: .learn)))
        XCTAssertTrue(imports(try state(format: 1, level: nil, answeredAt: .learn)), "rounds saved before steps")
        XCTAssertFalse(imports(try state(format: 2, level: nil, answeredAt: .sharp)), "checked at its own step")
        XCTAssertFalse(imports(try state(format: 1, level: 3, answeredAt: .sharp)), "format 1 has no step")
        XCTAssertFalse(imports(try state(format: 2, level: 1, answeredAt: .learn)), "the first step is written as none")
        var noSteps = try state(format: 2, level: 2, answeredAt: .apply)
        noSteps.activeRound?.concept = Concept.mdf.rawValue
        noSteps.activeRound?.answers = []
        noSteps.activeRound?.phase = .question
        XCTAssertFalse(imports(noSteps), "a skill without a second step")
    }

    func testAReviewSavesEachQuestionsStep() throws {
        func state(levels: [Int]?, answeredAt: DrillLevel) throws -> ProgressState {
            var review = ReviewSessionSnapshot(id: "v", seed: seed, scheduledConcepts: ["potMath", "mdf"])
            review.levels = levels
            review.answers = [NodeGradedAnswer(concept: "potMath", answer: try potAnswer(answeredAt: answeredAt))]
            review.phase = .reveal
            var state = ProgressState()
            state.activeReviewSession = review
            return state
        }
        XCTAssertTrue(imports(try state(levels: [3, 1], answeredAt: .sharp)))
        XCTAssertTrue(imports(try state(levels: nil, answeredAt: .learn)))
        XCTAssertFalse(imports(try state(levels: [3], answeredAt: .sharp)), "one step per question")
        XCTAssertFalse(imports(try state(levels: [1, 2], answeredAt: .learn)), "MDF has no second step")
        XCTAssertFalse(imports(try state(levels: nil, answeredAt: .sharp)))
    }

    func testAStepLessonRegradesAtTheStepInItsID() throws {
        func state(node: String, answeredAt: DrillLevel) throws -> ProgressState {
            var session = NodeSessionSnapshot(id: "n", nodeID: node, seed: seed,
                                              scheduledConcepts: ["potMath", "potMath", "potMath"],
                                              phase: .reveal, formatVersion: 2)
            session.answers = [NodeGradedAnswer(concept: "potMath", answer: try potAnswer(answeredAt: answeredAt))]
            var state = ProgressState()
            state.activeNodeSession = session
            return state
        }
        XCTAssertTrue(imports(try state(node: "u1-potMath.3", answeredAt: .sharp)))
        XCTAssertFalse(imports(try state(node: "u1-potMath.3", answeredAt: .learn)))
        XCTAssertTrue(imports(try state(node: "u1-potMath", answeredAt: .learn)))
        XCTAssertEqual(try state(node: "u1-potMath.2", answeredAt: .apply).activeNodeSession?.level(at: 0), .apply)
    }

    func testAChallengeSavesTheStepItDealtEachSkillAt() throws {
        let node = try XCTUnwrap(Curriculum.node(id: "u2-boss.3"))
        let scheduled = Curriculum.sessionConcepts(for: node, seed: seed)
        let first = try XCTUnwrap(scheduled.first)
        func state(levels: [Int]?) -> ProgressState {
            var session = NodeSessionSnapshot(id: "c", nodeID: node.id, seed: seed,
                                              scheduledConcepts: scheduled.map(\.rawValue),
                                              phase: .question, formatVersion: 2)
            session.levels = levels
            var state = ProgressState()
            state.activeNodeSession = session
            return state
        }
        let levels = scheduled.map { DrillLevel.highest(for: $0).rawValue }
        XCTAssertTrue(imports(state(levels: levels)))
        XCTAssertEqual(state(levels: levels).activeNodeSession?.level(at: 0), DrillLevel.highest(for: first))
        XCTAssertTrue(imports(state(levels: nil)))
        XCTAssertFalse(imports(state(levels: Array(levels.dropLast()))))
        let lessonWithLevels = { () -> ProgressState in
            var s = state(levels: nil)
            s.activeNodeSession = NodeSessionSnapshot(id: "l", nodeID: "u1-potMath.2", seed: self.seed,
                                                      scheduledConcepts: ["potMath", "potMath", "potMath"],
                                                      phase: .question, formatVersion: 2)
            s.activeNodeSession?.levels = [2, 2, 2]
            return s
        }()
        XCTAssertFalse(imports(lessonWithLevels), "a lesson's step is its id")
    }

    // MARK: Daily summaries

    func testTheFirstStepWritesNoLevelSoOldSummariesStayTheSameKey() throws {
        let day = DayKey(t0)
        let learn = DailyPracticeKey(day: day, concept: "outs", mode: "path", formatVersion: 2,
                                     language: "en", assisted: false)
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(learn), encoding: .utf8))
        XCTAssertFalse(json.contains("level"))
        var apply = learn
        apply.level = 2
        XCTAssertNotEqual(apply, learn)
        XCTAssertEqual(try JSONDecoder().decode(DailyPracticeKey.self, from: JSONEncoder().encode(apply)).level, 2)
    }

    func testATableDecisionCountsAsPracticeButTouchesNoSchedule() {
        var state = ProgressState()
        state.recordTableDecision(attemptID: "table:1:0:0", band: .spotOn, language: "ko", now: t0)
        state.recordTableDecision(attemptID: "table:1:0:0", band: .spotOn, language: "ko", now: t0)
        state.recordTableDecision(attemptID: "table:1:0:1", band: .off, language: "ko", now: t0)
        XCTAssertEqual(state.dailySummaries.count, 1)
        XCTAssertEqual(state.dailySummaries.first?.key.mode, "table")
        XCTAssertEqual(state.dailySummaries.first?.key.concept, "table")
        XCTAssertEqual(state.dailySummaries.first?.total, 2, "the same decision counts once")
        XCTAssertTrue(state.concepts.isEmpty, "no schedule, accuracy or tier")
        XCTAssertTrue(state.answers.isEmpty)
        XCTAssertEqual(state.streak, ProgressState().streak)
        let overview = PracticeActivityOverview(state: state, now: t0, calendar: .current)
        XCTAssertEqual(overview.todayAnswerCount, 2)
        XCTAssertTrue(overview.recentTopics.isEmpty)
        XCTAssertTrue(imports(state))
    }

    // MARK: Upgrading to schema 5

    /// A schema-4 file built here: a skill at each tier, written with the version it had.
    private func schemaFourFile(_ build: (inout ProgressState) -> Void) throws -> Data {
        var state = ProgressState(schemaVersion: 4)
        build(&state)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        json["schemaVersion"] = 4
        return try JSONSerialization.data(withJSONObject: json)
    }

    func testUpgradingMarksTheStepsATierAlreadyShows() throws {
        let proficientAt = t0, masteredAt = t0.addingTimeInterval(13 * 3600)
        let bytes = try schemaFourFile { state in
            state.nodes["u1-showdown"] = NodeRecord(cleared: true, clearedAt: t0, attempts: 2)
            state.updateRecord(for: .showdown) { $0.tier = .familiar; $0.total = 3; $0.correct = 3 }
            state.updateRecord(for: .potMath) {
                $0.tier = .proficient; $0.proficientAt = proficientAt; $0.total = 3; $0.correct = 3
            }
            state.updateRecord(for: .callFold) {
                $0.tier = .mastered; $0.proficientAt = proficientAt; $0.masteredAt = masteredAt
                $0.total = 5; $0.correct = 5
            }
            state.updateRecord(for: .outs) { $0.tier = .proficient; $0.proficientAt = proficientAt; $0.total = 1; $0.correct = 1 }
        }
        let s = store()
        try bytes.write(to: s.url)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 4 must upgrade") }
        XCTAssertEqual(state.schemaVersion, 5)

        // Cleared: the first step only.
        XCTAssertEqual(state.nodes["u1-showdown"]?.attempts, 2, "an existing record is kept as it was")
        XCTAssertNil(state.nodes["u1-showdown.2"])
        // Strong: the first two steps.
        XCTAssertEqual(state.nodes["u1-potMath"], NodeRecord(cleared: true, clearedAt: proficientAt, attempts: 0))
        XCTAssertEqual(state.nodes["u1-potMath.2"], NodeRecord(cleared: true, clearedAt: proficientAt, attempts: 0))
        XCTAssertNil(state.nodes["u1-potMath.3"])
        // Mastered: all three.
        XCTAssertEqual(state.nodes["u2-callFold.2"]?.clearedAt, proficientAt)
        XCTAssertEqual(state.nodes["u2-callFold.3"], NodeRecord(cleared: true, clearedAt: masteredAt, attempts: 0))
        // A skill given steps in the same schema (outs): Strong, so its first two.
        XCTAssertEqual(state.nodes["u2-outs"]?.cleared, true)
        XCTAssertEqual(state.nodes["u2-outs.2"]?.cleared, true)
        XCTAssertNil(state.nodes["u2-outs.3"])
        // Tiers never drop.
        XCTAssertEqual(state.record(for: .potMath).tier, .proficient)
        XCTAssertEqual(state.record(for: .callFold).tier, .mastered)
        XCTAssertEqual(Curriculum.passedLevel(of: .callFold, in: state), .sharp)
        XCTAssertEqual(Curriculum.passedLevel(of: .potMath, in: state), .apply)

        let backups = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains("schema-4-") }
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), bytes)
    }

    func testTheBuild35FixtureUpgrades() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "schema4-build35", withExtension: "json",
                                                  subdirectory: "Fixtures/Progression"))
        let s = store()
        try Data(contentsOf: url).write(to: s.url)
        guard case let .loaded(state) = s.load() else { return XCTFail("build 35 must load") }
        XCTAssertEqual(state.lastNodeID, "u1-potMath")
        XCTAssertEqual(state.record(for: .showdown).tier, .proficient)
        XCTAssertEqual(state.record(for: .potOdds).tier, .mastered)
        XCTAssertEqual(state.nodes["u1-showdown.2"]?.cleared, true)
        XCTAssertNil(state.nodes["u1-showdown.3"])
        XCTAssertEqual(state.nodes["u2-potOdds"]?.cleared, true)
        // Pot odds has steps and was 숙달, so all three are passed.
        XCTAssertEqual(state.nodes["u2-potOdds.2"]?.cleared, true)
        XCTAssertEqual(state.nodes["u2-potOdds.3"]?.cleared, true)
        XCTAssertEqual(Curriculum.passedLevel(of: .potOdds, in: state), .sharp)
    }
}
