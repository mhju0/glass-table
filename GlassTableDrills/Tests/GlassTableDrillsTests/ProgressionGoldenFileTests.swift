import XCTest
@testable import GlassTableDrills

/// Each `progression.json` shape must load, validate, re-grade and survive a
/// save without losing a key. Fixtures were written by their corresponding builds. See
/// `Fixtures/Progression/README.md`.
final class ProgressionGoldenFileTests: XCTestCase {
    private var root: URL!
    private var dir: URL!

    override func setUpWithError() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gt-golden-\(UUID().uuidString)")
        try freshDirectory()
    }
    override func tearDownWithError() throws {
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
        try? FileManager.default.removeItem(at: root)
    }

    /// One empty directory per loaded fixture, so backup counts never mix.
    private func freshDirectory() throws {
        dir = root.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private static let fixtures = ["schema1-build3", "schema2-build16", "schema2-build22",
                                   "schema2-build30", "schema3-build34", "schema4-build35",
                                   "schema5-build37", "schema6-pair-retry",
                                   "schema7-pair-follow-up", "schema8-unit-a-reveal", "schema9-unit-b-draft",
                                   "schema10-course-review-correction", "schema11-table-course-drafts",
                                   "schema12-expanded-course", "schema13-elective-drafts"]

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json",
                                                  subdirectory: "Fixtures/Progression"))
        return try Data(contentsOf: url)
    }

    private func store(with bytes: Data) throws -> ProgressionStore {
        let s = ProgressionStore(url: dir.appendingPathComponent("progress.json"))
        try bytes.write(to: s.url)
        return s
    }

    private func files(containing marker: String) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains(marker) }
    }

    func testCurrentSchemaVersionIsThirteen() {
        XCTAssertEqual(ProgressState.currentSchemaVersion, 13)
    }

    func testEveryFixtureLoadsValidatesRoundTripsAndRegrades() throws {
        for name in Self.fixtures {
            try freshDirectory()
            let original = try fixture(name)
            let s = try store(with: original)
            guard case let .loaded(state) = s.load() else {
                XCTFail("\(name) must load"); continue
            }
            XCTAssertEqual(state.schemaVersion, ProgressState.currentSchemaVersion, name)

            // The import path validates with re-grading on, exactly like a disk load.
            XCTAssertNoThrow(try s.importData(original), name)
            XCTAssertEqual(try s.importData(original).schemaVersion,
                           ProgressState.currentSchemaVersion, name)

            // Save → load → equal, twice, so the upgraded file is itself stable.
            try s.save(state)
            guard case let .loaded(back) = s.load() else { XCTFail(name); continue }
            XCTAssertEqual(back, state, name)
            try s.save(back)
            guard case let .loaded(again) = s.load() else { XCTFail(name); continue }
            XCTAssertEqual(again, state, name)

            // Every saved answer still matches the spot its seed generates today.
            var regraded = 0
            func regrade(_ answer: RoundAnswer, concept: String, seed: UInt64, index: Int,
                         level: DrillLevel) throws {
                let input = try JSONDecoder().decode(SavedDrillInput.self, from: answer.input)
                let reveal = try JSONDecoder().decode(SavedDrillReveal.self, from: answer.reveal)
                XCTAssertTrue(SavedDrillScore.matches(concept: try XCTUnwrap(Concept(rawValue: concept)),
                    seed: seed, index: index, level: level, input: input, reveal: reveal), "\(name) \(answer.attemptID)")
                regraded += 1
            }
            if let round = state.activeRound {
                for (i, a) in round.answers.enumerated() {
                    try regrade(a, concept: round.concept, seed: round.seed, index: i + 2,
                                level: round.level(at: i))
                }
            }
            if let session = state.activeNodeSession {
                for (i, g) in session.answers.enumerated() {
                    try regrade(g.answer, concept: g.concept, seed: session.seed, index: i + 2,
                                level: session.level(at: i))
                }
            }
            let expectedRegrades = ["schema1-build3", "schema6-pair-retry",
                                    "schema7-pair-follow-up", "schema8-unit-a-reveal", "schema9-unit-b-draft",
                                   "schema10-course-review-correction", "schema11-table-course-drafts",
                                   "schema12-expanded-course", "schema13-elective-drafts"].contains(name) ? 0 : 3
            XCTAssertEqual(regraded, expectedRegrades, name)

            // No key the old build wrote is lost when the current build saves it.
            let saved = try JSONSerialization.jsonObject(with: Data(contentsOf: s.url))
            var old = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
            old["schemaVersion"] = nil
            let missing = Self.missingPaths(old, in: saved, path: "")
            XCTAssertEqual(missing, [], "\(name) lost data on save")
        }
    }

    func testFixtureSpecificContentSurvives() throws {
        func loaded(_ name: String) throws -> ProgressState {
            try freshDirectory()
            guard case let .loaded(state) = try store(with: fixture(name)).load() else {
                throw StoreError.notDecodable
            }
            return state
        }
        let schema1 = try loaded("schema1-build3")
        XCTAssertEqual(schema1.record(for: .showdown).total, 2)
        XCTAssertEqual(schema1.answers.count, 5)
        XCTAssertEqual(schema1.nodes["u1-showdown"]?.cleared, true)
        XCTAssertNotNil(schema1.detailedTrackingStartedAt, "tracking starts at the upgrade")

        let b16 = try loaded("schema2-build16")
        XCTAssertNotNil(b16.tableState)
        XCTAssertEqual(b16.recentHands.count, 2)
        XCTAssertTrue(b16.quickPlaySessions.isEmpty)
        XCTAssertNil(b16.nodes["u1-showdown"]?.best)
        XCTAssertEqual(b16.activeNodeSession?.formatVersion, 2)
        XCTAssertEqual(b16.activeReviewSession?.draft?.ordinal, 0)

        let b22 = try loaded("schema2-build22")
        XCTAssertEqual(b22.quickPlaySessions.count, 2)
        XCTAssertEqual(b22.activeQuickPlaySessionID, b22.quickPlaySessions.last?.id)
        XCTAssertEqual(b22.pendingFirstLesson?.step, .comparison1)
        XCTAssertNil(b22.nodes["u1-showdown"]?.best)

        let b30 = try loaded("schema2-build30")
        XCTAssertEqual(b30.nodes["u1-showdown"]?.best, LessonScore(right: 3, questions: 3))
        XCTAssertEqual(b30.nodes["u1-potMath"]?.best, LessonScore(right: 1, questions: 3))
        XCTAssertEqual(b30.quickPlaySessions.count, 2)

        let b37 = try loaded("schema5-build37")
        XCTAssertEqual(b37.activeRound?.formatVersion, 2)
        XCTAssertEqual(b37.activeRound?.level, 3)
        XCTAssertEqual(b37.dailySummaries.filter { $0.key.level == 2 }.count, 1)
        XCTAssertEqual(b37.lastNodeID, "u1-potMath")
        XCTAssertEqual(b37.nodes["u1-showdown.2"]?.cleared, true)

        let b34 = try loaded("schema3-build34")
        XCTAssertEqual(b34.nodes["u1-showdown"]?.best, LessonScore(right: 3, questions: 3))
        XCTAssertEqual(b34.quickPlaySessions.count, 2)
        for state in [schema1, b16, b22, b30, b34] {
            // No file before schema 4 knows the last lesson, so Learn keeps the old mark.
            XCTAssertNil(state.lastNodeID)
            var closed = state
            closed.activeNodeSession = nil
            let old: MarkedLesson? = Curriculum.suggestsBasicsLesson(in: closed) ? .basics
                : Curriculum.suggestedLesson(in: closed).map { .next($0) }
            XCTAssertEqual(Curriculum.markedLesson(in: closed), old)
        }
        for state in [b16, b22, b30, b34] {
            XCTAssertEqual(state.revision, 14)
            XCTAssertEqual(state.lessonTrend, 1)
            XCTAssertEqual(state.basicsLessonCompleted, true)
            XCTAssertFalse(state.dailySummaries.isEmpty)
            XCTAssertEqual(state.recentEvidence.count, 7)
        }
    }

    func testOlderSchemaIsCopiedByteForByteBeforeUpgrade() throws {
        let original = try fixture("schema2-build30")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 2 must upgrade") }
        XCTAssertEqual(state.schemaVersion, ProgressState.currentSchemaVersion)

        let backups = try files(containing: "schema-2-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)
        XCTAssertTrue(try XCTUnwrap(backups.first).lastPathComponent.hasPrefix("progress.schema-2-"))

        let header = try JSONSerialization.jsonObject(with: Data(contentsOf: s.url)) as? [String: Any]
        XCTAssertEqual(header?["schemaVersion"] as? Int, ProgressState.currentSchemaVersion)
        guard case let .loaded(reloaded) = s.load() else { return XCTFail("upgraded file must load") }
        XCTAssertEqual(reloaded, state)
        XCTAssertEqual(try files(containing: "schema-").count, 1, "a current file is not copied again")
    }

    /// The upgrade copies the schema-3 file and leaves `lastNodeID` absent.
    func testSchemaThreeIsCopiedByteForByteBeforeUpgrade() throws {
        let original = try fixture("schema3-build34")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 3 must upgrade") }
        XCTAssertEqual(state.schemaVersion, ProgressState.currentSchemaVersion)
        XCTAssertNil(state.lastNodeID)

        let backups = try files(containing: "schema-3-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)

        let header = try JSONSerialization.jsonObject(with: Data(contentsOf: s.url)) as? [String: Any]
        XCTAssertEqual(header?["schemaVersion"] as? Int, ProgressState.currentSchemaVersion)
        XCTAssertNil(header?["lastNodeID"])
    }

    func testSchemaFiveUpgradePreservesSnapshotsAndCopiesTheOriginalBytes() throws {
        let original = try fixture("schema5-build37")
        var expected = try JSONDecoder().decode(ProgressState.self, from: original)
        expected.schemaVersion = ProgressState.currentSchemaVersion
        let s = try store(with: original)

        guard case let .loaded(state) = s.load() else { return XCTFail("schema 5 must upgrade") }
        XCTAssertEqual(state, expected)
        XCTAssertNil(state.pairLesson)
        XCTAssertEqual(try s.importData(original), expected)

        let backups = try files(containing: "schema-5-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)
        let header = try JSONSerialization.jsonObject(with: Data(contentsOf: s.url)) as? [String: Any]
        XCTAssertEqual(header?["schemaVersion"] as? Int, ProgressState.currentSchemaVersion)
        XCTAssertNil(header?["pairLesson"])
        guard case let .loaded(reloaded) = s.load() else { return XCTFail("upgraded file must load") }
        XCTAssertEqual(reloaded, state)
        XCTAssertEqual(try files(containing: "schema-5-"), backups)
    }

    func testSchemaFiveFileWithPairLessonRequiresRecovery() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema6-pair-retry")) as? [String: Any])
        let pair = try XCTUnwrap(json["pairLesson"])
        json["schemaVersion"] = 5
        for value in [pair, NSNull()] {
            try freshDirectory()
            json["pairLesson"] = value
            let original = try JSONSerialization.data(withJSONObject: json)
            let s = try store(with: original)

            guard case .unreadable = s.load() else { return XCTFail("schema 5 cannot carry pair progress") }
            XCTAssertThrowsError(try s.importData(original)) { error in
                XCTAssertEqual(error as? StoreError, .notDecodable)
            }
            XCTAssertEqual(try Data(contentsOf: s.url), original)
            XCTAssertTrue(try files(containing: "schema-").isEmpty)
        }
    }

    func testInvalidSavedRetryCursorRequiresRecovery() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema6-pair-retry")) as? [String: Any])
        var pair = try XCTUnwrap(json["pairLesson"] as? [String: Any])
        pair["retryIndex"] = Int.max
        json["pairLesson"] = pair
        let original = try JSONSerialization.data(withJSONObject: json)
        let s = try store(with: original)

        guard case .unreadable = s.load() else { return XCTFail("invalid retry cursor must require recovery") }
        XCTAssertThrowsError(try s.importData(original)) { error in
            XCTAssertEqual(error as? StoreError, .invalidProgress)
        }
        XCTAssertEqual(try Data(contentsOf: s.url), original)
        XCTAssertTrue(try files(containing: "schema-").isEmpty)
    }

    func testStoreRefusesSavingPairLessonUnderSchemaFive() throws {
        let original = try fixture("schema6-pair-retry")
        let s = try store(with: original)
        var state = try s.importData(original)
        state.schemaVersion = 5

        XCTAssertThrowsError(try s.save(state)) { error in
            XCTAssertEqual(error as? StoreError, .invalidProgress)
        }
        XCTAssertEqual(try Data(contentsOf: s.url), original)
    }

    func testSavedSecondRetryResumesItsDraftAndReveal() throws {
        let original = try fixture("schema6-pair-retry")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else { return XCTFail("retry draft must load") }
        var migrated = try JSONDecoder().decode(ProgressState.self, from: original)
        migrated.schemaVersion = ProgressState.currentSchemaVersion
        XCTAssertEqual(state, migrated)
        XCTAssertEqual(try s.importData(original), migrated)
        XCTAssertNil(state.pairLessonFollowUp)
        let backups = try files(containing: "schema-6-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)
        var pair = try XCTUnwrap(state.pairLesson)
        let question = try XCTUnwrap(pair.currentQuestion)
        XCTAssertEqual(question.id, "solo-01")
        XCTAssertEqual(pair.phase, .retry)
        XCTAssertEqual(pair.retryNumber, 2)
        XCTAssertEqual(pair.retryCount, 2)
        XCTAssertEqual(pair.firstRight, 7)
        XCTAssertEqual(pair.retryRight, 0)
        XCTAssertEqual(pair.selection, .opponent)
        XCTAssertFalse(pair.hintVisible)
        XCTAssertFalse(pair.revealed)
        XCTAssertTrue(pair.apply(.submit))

        var expected = state
        expected.pairLesson = pair
        try s.save(expected)
        guard case let .loaded(reloaded) = s.load() else { return XCTFail("retry reveal must load") }
        let reveal = try XCTUnwrap(reloaded.pairLesson)
        XCTAssertEqual(reloaded, expected)
        XCTAssertEqual(reveal.currentQuestion, question)
        XCTAssertEqual(reveal.retryNumber, 2)
        XCTAssertEqual(reveal.firstRight, 7)
        XCTAssertEqual(reveal.retryRight, 1)
        XCTAssertTrue(reveal.revealed)
        XCTAssertEqual(try files(containing: "schema-"), backups)
    }

    func testFinishedSchemaSixLessonUpgradesWithoutSchedulingAFollowUp() throws {
        let original = try fixture("schema6-pair-retry")
        var legacy = try JSONDecoder().decode(ProgressState.self, from: original)
        var lesson = try XCTUnwrap(legacy.pairLesson)
        XCTAssertTrue(lesson.apply(.submit))
        XCTAssertTrue(lesson.apply(.advance))
        XCTAssertEqual(lesson.phase, .finished)
        legacy.pairLesson = lesson

        let s = try store(with: original)
        try s.save(legacy)
        let legacyBytes = try s.exportData()
        guard case let .loaded(migrated) = s.load() else {
            return XCTFail("completed schema 6 pilot must upgrade")
        }
        legacy.schemaVersion = ProgressState.currentSchemaVersion
        XCTAssertEqual(migrated, legacy)
        XCTAssertNil(migrated.pairLessonFollowUp)
        let backups = try files(containing: "schema-6-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), legacyBytes)
    }

    func testSchemaSevenMigrationPreservesBothExactFollowUpHands() throws {
        let original = try fixture("schema7-pair-follow-up")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else {
            return XCTFail("schema 7 follow-up file must load")
        }
        var expected = try JSONDecoder().decode(ProgressState.self, from: original)
        expected.schemaVersion = ProgressState.currentSchemaVersion
        let backups = try files(containing: "schema-7-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)
        XCTAssertNil(state.unitA)
        XCTAssertEqual(state, expected)
        XCTAssertEqual(try s.exportData(), try s.exportData(expected))
        XCTAssertEqual(try s.importData(original), state)
        XCTAssertEqual(state.pairLesson?.phase, .finished)
        XCTAssertEqual(state.pairLesson?.firstRight, 7)
        XCTAssertEqual(state.pairLesson?.assistedSoloCount, 1)

        var followUp = try XCTUnwrap(state.pairLessonFollowUp)
        let fresh = try XCTUnwrap(followUp.attempt(for: .fresh))
        let review = try XCTUnwrap(followUp.attempt(for: .review))
        XCTAssertTrue(fresh.revealed)
        XCTAssertFalse(fresh.finished)
        XCTAssertNotEqual(fresh.selection, fresh.question.winner)
        XCTAssertFalse(review.revealed)
        XCTAssertFalse(review.finished)
        XCTAssertEqual(review.selection, review.question.winner)
        XCTAssertNotEqual(review.question, fresh.question)
        XCTAssertEqual(followUp.reviewDueDay.raw, "2026-11-24")

        XCTAssertTrue(followUp.apply(.submit, to: .review, today: followUp.reviewDueDay))
        var updated = state
        updated.pairLessonFollowUp = followUp
        try s.save(updated)
        guard case let .loaded(restored) = s.load() else {
            return XCTFail("review reveal must survive a save and reload")
        }
        XCTAssertEqual(restored, updated)
        let restoredFollowUp = try XCTUnwrap(restored.pairLessonFollowUp)
        XCTAssertEqual(restoredFollowUp.attempt(for: .fresh), fresh)
        XCTAssertEqual(restoredFollowUp.attempt(for: .review)?.question, review.question)
        XCTAssertEqual(restoredFollowUp.attempt(for: .review)?.selection, review.selection)
        XCTAssertEqual(restoredFollowUp.attempt(for: .review)?.revealed, true)
        XCTAssertEqual(try files(containing: "schema-"), backups)
    }

    func testSchemaSixFileWithFollowUpRequiresRecovery() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema7-pair-follow-up")) as? [String: Any])
        let followUp = try XCTUnwrap(json["pairLessonFollowUp"])
        json["schemaVersion"] = 6
        for value in [followUp, NSNull()] {
            try freshDirectory()
            json["pairLessonFollowUp"] = value
            try assertRecovery(for: json, error: .notDecodable)
        }
    }

    func testInvalidOrOrphanedFollowUpRequiresRecovery() throws {
        let json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema7-pair-follow-up")) as? [String: Any])
        var orphan = json
        orphan.removeValue(forKey: "pairLesson")
        try assertRecovery(for: orphan, error: .invalidProgress)

        try freshDirectory()
        var corrupted = json
        var followUp = try XCTUnwrap(json["pairLessonFollowUp"] as? [String: Any])
        followUp["contentVersion"] = 2
        corrupted["pairLessonFollowUp"] = followUp
        try assertRecovery(for: corrupted, error: .invalidProgress)
    }

    func testStoreRefusesSavingFollowUpWithoutItsLessonOrUnderSchemaSix() throws {
        let original = try fixture("schema7-pair-follow-up")
        let s = try store(with: original)
        let state = try s.importData(original)

        var invalid = state
        invalid.schemaVersion = 6
        XCTAssertThrowsError(try s.save(invalid)) { error in
            XCTAssertEqual(error as? StoreError, .invalidProgress)
        }
        for lesson in [nil, PairLessonProgress(seed: 1)] {
            invalid = state
            invalid.pairLesson = lesson
            XCTAssertThrowsError(try s.save(invalid)) { error in
                XCTAssertEqual(error as? StoreError, .invalidProgress)
            }
        }
        XCTAssertEqual(try s.exportData(), original)
    }

    func testFollowUpRemainsValidDuringReplay() throws {
        let original = try fixture("schema7-pair-follow-up")
        let s = try store(with: original)
        var state = try s.importData(original)
        let existingFollowUp = state.pairLessonFollowUp
        var lesson = try XCTUnwrap(state.pairLesson)
        XCTAssertTrue(lesson.restart(seed: 1))
        XCTAssertEqual(lesson.phase, .example)
        state.pairLesson = lesson
        try s.save(state)

        guard case .loaded(let restored) = s.load() else {
            return XCTFail("unfinished replay must keep its earlier follow-up")
        }
        XCTAssertEqual(restored, state)
        XCTAssertEqual(restored.pairLessonFollowUp, existingFollowUp)
    }

    func testSchemaEightResumesAUnitARevealAlongsidePairFollowUps() throws {
        let original = try fixture("schema8-unit-a-reveal")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else {
            return XCTFail("schema 8 Unit A reveal must load")
        }
        let backup = try XCTUnwrap(files(containing: "schema-8-").first)
        XCTAssertEqual(try Data(contentsOf: backup), original)
        XCTAssertEqual(try s.importData(original), state)
        XCTAssertNil(state.unitB)
        let legacy = try s.importData(fixture("schema7-pair-follow-up"))
        var unit = try XCTUnwrap(state.unitA)
        var expected = legacy
        expected.unitA = unit
        XCTAssertEqual(state, expected)
        XCTAssertTrue(unit.isValid)
        XCTAssertEqual(unit.lesson, .privateCards)
        XCTAssertEqual(unit.activity?.id, "A1-01")
        XCTAssertEqual(unit.selection, 1)
        XCTAssertTrue(unit.revealed)
        XCTAssertEqual(unit.answeredCorrectly, false)
        XCTAssertFalse(unit.apply(.submit), "A revealed answer cannot be submitted twice.")
        XCTAssertTrue(unit.apply(.advance))

        expected.unitA = unit
        try s.save(expected)
        guard case let .loaded(restored) = s.load() else {
            return XCTFail("Unit A must resume at the next activity")
        }
        XCTAssertEqual(restored, expected)
        XCTAssertNotEqual(restored.unitA?.activity?.id, state.unitA?.activity?.id)
        XCTAssertEqual(try files(containing: "schema-"), [backup])
    }

    func testSchemaNineKeepsTheUnitBBestFiveDraftAndEarlierProgress() throws {
        let original = try fixture("schema9-unit-b-draft")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 9 must load") }
        let backup = try XCTUnwrap(files(containing: "schema-9-").first)
        XCTAssertEqual(try Data(contentsOf: backup), original)
        var expected = try s.importData(fixture("schema8-unit-a-reveal"))
        let unit = try XCTUnwrap(state.unitB)
        expected.unitB = unit
        XCTAssertEqual(state, expected)
        XCTAssertEqual(unit.lesson, .bestFive)
        XCTAssertEqual(unit.selectedCardIndices, [0, 2])
        XCTAssertFalse(unit.canSubmit)
        XCTAssertFalse(unit.revealed)
        XCTAssertEqual(unit.pairBestFirstRight, expected.pairLesson?.bestFirstRight)
    }

    func testSchemaTenRestoresAReviewCorrectionWithoutReplacingCourseDrafts() throws {
        let original = try fixture("schema10-course-review-correction")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 10 must load") }
        let backup = try XCTUnwrap(files(containing: "schema-10-").first)
        XCTAssertEqual(try Data(contentsOf: backup), original)
        XCTAssertNil(state.tableCourse)
        var expected = try s.importData(fixture("schema9-unit-b-draft"))
        let review = try XCTUnwrap(state.courseReview)
        XCTAssertEqual(review.scope, .all)
        XCTAssertEqual(review.phase, .retry)
        XCTAssertTrue(review.revealed)
        XCTAssertEqual(review.coveredCount, 5)
        XCTAssertEqual(review.retryCount, 1)
        XCTAssertEqual(review.setCount, 2)
        expected.courseReview = review
        XCTAssertEqual(state, expected)
    }

    func testSchemaElevenRestoresSeparateTableDraftsAndEarlierReview() throws {
        let original = try fixture("schema11-table-course-drafts")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 11 must load") }
        let backup = try XCTUnwrap(files(containing: "schema-11-").first)
        XCTAssertEqual(try Data(contentsOf: backup), original)
        let earlier = try s.importData(fixture("schema10-course-review-correction"))
        XCTAssertEqual(state.courseReview, earlier.courseReview)
        for (unit, lesson) in [(TableCourseUnit.turns, TableCourseLesson.c1), (.chips, .d1), (.startingHands, .e1)] {
            let progress = try XCTUnwrap(state.progress(in: unit))
            XCTAssertEqual(progress.lesson, lesson)
            XCTAssertEqual(progress.selection, 0)
            XCTAssertTrue(progress.canSubmit)
            XCTAssertFalse(progress.revealed)
        }
    }

    func testSchemaTwelveRoundTripsNewCourseAndRetainsEarlierDrafts() throws {
        let bytes = try fixture("schema12-expanded-course")
        let s = try store(with: bytes)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 12 must load") }
        let backup = try XCTUnwrap(files(containing: "schema-12-").first)
        XCTAssertEqual(try Data(contentsOf: backup), bytes)
        XCTAssertNil(state.progress(in: .expectedValue))
        XCTAssertNil(state.progress(in: .boardPatterns))
        let earlier = try s.importData(fixture("schema11-table-course-drafts"))
        XCTAssertEqual(state.courseReview, earlier.courseReview)
        for unit in [TableCourseUnit.turns, .chips, .startingHands] {
            XCTAssertEqual(state.progress(in: unit), earlier.progress(in: unit))
        }
        XCTAssertEqual(state.progress(in: .capstone)?.lesson, .i1)
        XCTAssertEqual(state.progress(in: .capstone)?.selection, 0)
        XCTAssertEqual(state.progress(in: .capstone)?.canSubmit, true)
        XCTAssertEqual(state.progress(in: .combinations)?.lesson, .j1)
        XCTAssertEqual(state.progress(in: .combinations)?.selection, 1)
        XCTAssertEqual(state.progress(in: .combinations)?.revealed, true)
    }

    func testSchemaThirteenRetainsPriorDraftsAndEachElectiveState() throws {
        let bytes = try fixture("schema13-elective-drafts")
        let s = try store(with: bytes)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 13 must load") }
        XCTAssertEqual(try s.exportData(state), bytes)
        let older = try s.importData(fixture("schema12-expanded-course"))
        var withoutNewElectives = state
        withoutNewElectives.tableCourse?.removeValue(forKey: TableCourseUnit.expectedValue.rawValue)
        withoutNewElectives.tableCourse?.removeValue(forKey: TableCourseUnit.boardPatterns.rawValue)
        XCTAssertEqual(withoutNewElectives, older)
        let ev = try XCTUnwrap(state.progress(in: .expectedValue))
        XCTAssertEqual(ev.lesson, .k1)
        XCTAssertEqual(ev.selection, 0)
        XCTAssertTrue(ev.canSubmit)
        XCTAssertFalse(ev.revealed)
        let boards = try XCTUnwrap(state.progress(in: .boardPatterns))
        XCTAssertEqual(boards.lesson, .l1)
        XCTAssertEqual(boards.selection, 1)
        XCTAssertTrue(boards.revealed)
    }

    func testNewElectivesCannotAppearInAnOlderStoreVersion() throws {
        let bytes = try fixture("schema13-elective-drafts")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        json["schemaVersion"] = 12
        try assertRecovery(for: json, error: .invalidProgress)
    }

    func testExpandedUnitsRequireSchemaTwelve() throws {
        let bytes = try fixture("schema12-expanded-course")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        json["schemaVersion"] = 11
        try assertRecovery(for: json, error: .invalidProgress)
    }

    func testTableCourseRejectsOlderSchemaAndMismatchedUnitOrOrphanedMilestone() throws {
        let original = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema11-table-course-drafts")) as? [String: Any])
        var downgraded = original
        downgraded["schemaVersion"] = 10
        try assertRecovery(for: downgraded, error: .notDecodable)

        try freshDirectory()
        downgraded["tableCourse"] = NSNull()
        try assertRecovery(for: downgraded, error: .notDecodable)

        try freshDirectory()
        var invalid = original
        let drafts = try XCTUnwrap(original["tableCourse"] as? [String: Any])
        invalid["tableCourse"] = ["chips": try XCTUnwrap(drafts["turns"])]
        try assertRecovery(for: invalid, error: .invalidProgress)

        try freshDirectory()
        let milestone = TableCourseProgress(unit: .milestone)
        invalid["tableCourse"] = ["milestone": try JSONSerialization.jsonObject(with: JSONEncoder().encode(milestone))]
        try assertRecovery(for: invalid, error: .invalidProgress)
    }

    func testCourseReviewRequiresSchemaTenAndStudiedSkills() throws {
        let original = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema10-course-review-correction")) as? [String: Any])
        var downgraded = original
        downgraded["schemaVersion"] = 9
        try assertRecovery(for: downgraded, error: .notDecodable)

        try freshDirectory()
        downgraded["courseReview"] = NSNull()
        try assertRecovery(for: downgraded, error: .notDecodable)

        try freshDirectory()
        var unsupported = original
        unsupported.removeValue(forKey: "unitB")
        try assertRecovery(for: unsupported, error: .invalidProgress)
    }

    func testUnitBRequiresSchemaNineAndVerifiedPairResult() throws {
        let original = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema9-unit-b-draft")) as? [String: Any])
        var mismatched = original
        mismatched["schemaVersion"] = 8
        try assertRecovery(for: mismatched, error: .notDecodable)

        try freshDirectory()
        mismatched["unitB"] = NSNull()
        try assertRecovery(for: mismatched, error: .notDecodable)

        try freshDirectory()
        var orphan = original
        orphan.removeValue(forKey: "pairLesson")
        orphan.removeValue(forKey: "pairLessonFollowUp")
        try assertRecovery(for: orphan, error: .invalidProgress)

        try freshDirectory()
        var unsupportedScore = original
        var unit = try XCTUnwrap(original["unitB"] as? [String: Any])
        var results = try XCTUnwrap(unit["priorResults"] as? [[String: Any]])
        let pairResult = try XCTUnwrap(results.firstIndex { $0["lesson"] as? String == "b2" })
        XCTAssertEqual(results[pairResult]["firstRight"] as? Int, 7)
        results[pairResult]["firstRight"] = 8
        unit["priorResults"] = results
        unsupportedScore["unitB"] = unit
        try assertRecovery(for: unsupportedScore, error: .invalidProgress)
    }

    func testOlderFileWithUnitARequiresRecovery() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema8-unit-a-reveal")) as? [String: Any])
        let unit = try XCTUnwrap(json["unitA"])
        json["schemaVersion"] = 7
        for value in [unit, NSNull()] {
            try freshDirectory()
            json["unitA"] = value
            try assertRecovery(for: json, error: .notDecodable)
        }
    }

    func testMalformedUnitARequiresRecovery() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema8-unit-a-reveal")) as? [String: Any])
        json["unitA"] = true
        try assertRecovery(for: json, error: .notDecodable)
    }

    func testInvalidUnitAContentVersionRequiresRecovery() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema8-unit-a-reveal")) as? [String: Any])
        var unit = try XCTUnwrap(json["unitA"] as? [String: Any])
        unit["contentVersion"] = 2
        json["unitA"] = unit
        try assertRecovery(for: json, error: .invalidProgress)
    }

    func testStoreRefusesSavingUnitAUnderSchemaSeven() throws {
        let original = try fixture("schema7-pair-follow-up")
        let s = try store(with: original)
        var invalid = try s.importData(fixture("schema8-unit-a-reveal"))
        invalid.schemaVersion = 7
        XCTAssertThrowsError(try s.save(invalid)) { error in
            XCTAssertEqual(error as? StoreError, .invalidProgress)
        }
        XCTAssertEqual(try s.exportData(), original)
    }

    private func assertRecovery(for json: [String: Any], error expected: StoreError) throws {
        let original = try JSONSerialization.data(withJSONObject: json)
        let s = try store(with: original)

        guard case .unreadable = s.load() else { return XCTFail("invalid save must require recovery") }
        XCTAssertThrowsError(try s.importData(original)) { error in
            XCTAssertEqual(error as? StoreError, expected)
        }
        XCTAssertEqual(try s.exportData(), original)
        XCTAssertTrue(try files(containing: "schema-").isEmpty)
    }

    func testSchemaOneBackupKeepsItsVersionInTheName() throws {
        let original = try fixture("schema1-build3")
        let s = try store(with: original)
        guard case .loaded = s.load() else { return XCTFail("schema 1 must upgrade") }
        let backups = try files(containing: "schema-1-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)
    }

    func testFailedBackupCopyAbortsUpgradeAndLeavesOriginalUntouched() throws {
        let original = try fixture("schema2-build22")
        let s = try store(with: original)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path) }

        guard case .unreadable = s.load() else { return XCTFail("a failed copy must surface") }
        XCTAssertEqual(try Data(contentsOf: s.url), original)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: dir.path), ["progress.json"])
    }

    func testNewerSchemaIsRefusedAsUnsupported() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema2-build30")) as? [String: Any])
        let current = ProgressState.currentSchemaVersion
        json["schemaVersion"] = current + 1
        let future = try JSONSerialization.data(withJSONObject: json)
        let s = try store(with: future)

        guard case .unreadable = s.load() else { return XCTFail("future schema must require recovery") }
        XCTAssertEqual(try Data(contentsOf: s.url), future)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: dir.path), ["progress.json"])
        XCTAssertThrowsError(try s.importData(future)) { error in
            XCTAssertEqual(error as? StoreError, .unsupportedSchemaVersion(found: current + 1, supported: current))
        }
    }

    /// Why every new key must bump the schema: a build reads an unknown key at its own
    /// schema version without complaint, then drops it on the next save. Bumping the
    /// version turns that silent loss into a refused file and the recovery screen.
    func testUnknownKeyAtTheCurrentSchemaIsDroppedOnSave() throws {
        let s = ProgressionStore(url: dir.appendingPathComponent("progress.json"))
        var state = ProgressState()
        state.updateRecord(for: .outs) { $0.total = 3; $0.correct = 2 }
        try s.save(state)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(contentsOf: s.url)) as? [String: Any])
        json["futureField"] = ["kept": true]
        try JSONSerialization.data(withJSONObject: json).write(to: s.url)

        guard case let .loaded(read) = s.load() else { return XCTFail("unknown keys are tolerated") }
        try s.save(read)
        let saved = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(contentsOf: s.url)) as? [String: Any])
        XCTAssertNil(saved["futureField"], "the downgrade gap: the key is gone after one save")
        XCTAssertEqual(Self.missingPaths(json, in: saved, path: ""), ["/futureField"])
        XCTAssertEqual(try files(containing: "schema-").count, 0)
    }

    /// Paths present in `old` whose value is absent or different in `new`. Arrays of
    /// strings compare as sets, because `Set<String>` encodes in no fixed order.
    static func missingPaths(_ old: Any, in new: Any, path: String) -> [String] {
        switch old {
        case let dict as [String: Any]:
            guard let other = new as? [String: Any] else { return [path] }
            return dict.keys.sorted().flatMap { key -> [String] in
                guard let value = other[key] else { return ["\(path)/\(key)"] }
                return missingPaths(dict[key]!, in: value, path: "\(path)/\(key)")
            }
        case let strings as [String]:
            guard let other = new as? [String], Set(strings) == Set(other),
                  strings.count == other.count else { return [path] }
            return []
        case let array as [Any]:
            guard let other = new as? [Any], other.count == array.count else { return [path] }
            return array.indices.flatMap { missingPaths(array[$0], in: other[$0], path: "\(path)[\($0)]") }
        default:
            return (old as? NSObject)?.isEqual(new) == true ? [] : [path]
        }
    }
}
