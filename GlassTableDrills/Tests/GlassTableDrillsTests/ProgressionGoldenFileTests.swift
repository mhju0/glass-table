import XCTest
@testable import GlassTableDrills

/// Every shipped `progression.json` shape must load, validate, re-grade and survive a
/// save without losing a key. Fixtures were written by the old builds themselves; see
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
                                   "schema2-build30", "schema3-build34", "schema4-build35"]

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

    func testCurrentSchemaVersionIsFive() {
        XCTAssertEqual(ProgressState.currentSchemaVersion, 5)
    }

    func testEveryShippedShapeLoadsValidatesRoundTripsAndRegrades() throws {
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
            func regrade(_ answer: RoundAnswer, concept: String, seed: UInt64, index: Int) throws {
                let input = try JSONDecoder().decode(SavedDrillInput.self, from: answer.input)
                let reveal = try JSONDecoder().decode(SavedDrillReveal.self, from: answer.reveal)
                XCTAssertTrue(SavedDrillScore.matches(concept: try XCTUnwrap(Concept(rawValue: concept)),
                    seed: seed, index: index, input: input, reveal: reveal), "\(name) \(answer.attemptID)")
                regraded += 1
            }
            if let round = state.activeRound {
                for (i, a) in round.answers.enumerated() {
                    try regrade(a, concept: round.concept, seed: round.seed, index: i + 2)
                }
            }
            if let session = state.activeNodeSession {
                for (i, g) in session.answers.enumerated() {
                    try regrade(g.answer, concept: g.concept, seed: session.seed, index: i + 2)
                }
            }
            XCTAssertEqual(regraded, name.hasPrefix("schema1") ? 0 : 3, name)

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
        XCTAssertEqual(state.schemaVersion, 5)

        let backups = try files(containing: "schema-2-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)
        XCTAssertTrue(try XCTUnwrap(backups.first).lastPathComponent.hasPrefix("progress.schema-2-"))

        let header = try JSONSerialization.jsonObject(with: Data(contentsOf: s.url)) as? [String: Any]
        XCTAssertEqual(header?["schemaVersion"] as? Int, 5)
        guard case let .loaded(reloaded) = s.load() else { return XCTFail("upgraded file must load") }
        XCTAssertEqual(reloaded, state)
        XCTAssertEqual(try files(containing: "schema-").count, 1, "a current file is not copied again")
    }

    /// Schema 4 adds `lastNodeID`; a schema-3 file is copied as written, then upgraded
    /// with the key still absent.
    func testSchemaThreeIsCopiedByteForByteBeforeUpgrade() throws {
        let original = try fixture("schema3-build34")
        let s = try store(with: original)
        guard case let .loaded(state) = s.load() else { return XCTFail("schema 3 must upgrade") }
        XCTAssertEqual(state.schemaVersion, 5)
        XCTAssertNil(state.lastNodeID)

        let backups = try files(containing: "schema-3-")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), original)

        let header = try JSONSerialization.jsonObject(with: Data(contentsOf: s.url)) as? [String: Any]
        XCTAssertEqual(header?["schemaVersion"] as? Int, 5)
        XCTAssertNil(header?["lastNodeID"])
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

    func testSchemaSixIsRefusedAsUnsupported() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: fixture("schema2-build30")) as? [String: Any])
        json["schemaVersion"] = 6
        let future = try JSONSerialization.data(withJSONObject: json)
        let s = try store(with: future)

        guard case .unreadable = s.load() else { return XCTFail("schema 6 is newer than this build") }
        XCTAssertEqual(try Data(contentsOf: s.url), future)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: dir.path), ["progress.json"])
        XCTAssertThrowsError(try s.importData(future)) { error in
            XCTAssertEqual(error as? StoreError, .unsupportedSchemaVersion(found: 6, supported: 5))
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
