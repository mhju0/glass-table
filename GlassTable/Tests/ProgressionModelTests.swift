import XCTest
import GlassTableDrills
@testable import GlassTable

final class ProgressionModelTests: XCTestCase {
    private var dir: URL!
    private var store: ProgressionStore!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gt-model-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        store = ProgressionStore(url: dir.appendingPathComponent("progression.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testFailedImportLeavesDisplayedProgressUnchanged() throws {
        var original = ProgressState()
        original.streak.current = 7
        try store.save(original)
        let model = ProgressionModel(store: store)
        // An unavailable destination reproduces a write failure after valid decoding.
        let moved = dir.appendingPathExtension("unavailable")
        try FileManager.default.moveItem(at: dir, to: moved)
        defer { try? FileManager.default.removeItem(at: moved) }
        try Data("blocked directory".utf8).write(to: dir)
        var replacement = ProgressState()
        replacement.streak.current = 99

        XCTAssertThrowsError(try model.importData(JSONEncoder().encode(replacement)))
        XCTAssertEqual(model.state, original)
        XCTAssertEqual(try JSONDecoder().decode(ProgressState.self,
            from: Data(contentsOf: moved.appendingPathComponent("progression.json"))), original)
    }

    func testFutureStoreRequiresRecoveryAndRetainsItsBytes() throws {
        var future = ProgressState()
        future.schemaVersion = ProgressState.currentSchemaVersion + 1
        let bytes = try JSONEncoder().encode(future)
        try bytes.write(to: store.url)

        let model = ProgressionModel(store: store)

        XCTAssertNotNil(model.unreadable)
        XCTAssertEqual(try Data(contentsOf: store.url), bytes)
    }

    func testFailedInitialSaveIsVisibleAndCanBeRetried() throws {
        try FileManager.default.removeItem(at: dir)
        try Data("blocked directory".utf8).write(to: dir)
        let model = ProgressionModel(store: store)
        XCTAssertNotNil(model.saveError)

        try FileManager.default.removeItem(at: dir)
        model.retrySave()

        XCTAssertNil(model.saveError)
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
    }

    func testFailedAnswerSaveCanBeExportedAndRetriedWithoutLosingAnswers() throws {
        let model = ProgressionModel(store: store)
        let previousBytes = try store.exportData()
        try withReadOnlyDirectory {
            model.record(concept: .outs, band: .spotOn)
            model.record(concept: .potOdds, band: .close)

            XCTAssertNotNil(model.saveError)
            XCTAssertEqual(try store.exportData(), previousBytes)
            let exported = try store.importData(model.exportData())
            XCTAssertEqual(exported.record(for: .outs).total, 1)
            XCTAssertEqual(exported.record(for: .potOdds).total, 1)
        }

        model.retrySave()

        XCTAssertNil(model.saveError)
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
        XCTAssertEqual(model.record(for: .outs).total, 1)
        XCTAssertEqual(model.record(for: .potOdds).total, 1)
    }

    func testFailedResetKeepsDisplayedAndSavedProgress() throws {
        let model = ProgressionModel(store: store)
        model.record(concept: .outs, band: .spotOn)
        let original = model.state
        let bytes = try store.exportData()

        try withReadOnlyDirectory {
            XCTAssertThrowsError(try model.resetProgress())
            XCTAssertEqual(model.state, original)
            XCTAssertEqual(try store.exportData(), bytes)
        }
    }

    func testFailedRecoveryKeepsRecoveryScreenAndOriginalBytes() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        try withReadOnlyDirectory {
            XCTAssertThrowsError(try model.resetProgress())
            XCTAssertThrowsError(try model.importData(JSONEncoder().encode(ProgressState())))
            XCTAssertNotNil(model.unreadable)
            XCTAssertEqual(try store.exportData(), bytes)
        }
    }

    func testSuccessfulRecoveryPreservesOriginalAndSurvivesRelaunch() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        try model.resetProgress()

        XCTAssertNil(model.unreadable)
        XCTAssertNil(model.saveError)
        XCTAssertEqual(model.state, ProgressState())
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
        let recovery = try XCTUnwrap(FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil).first {
                $0.lastPathComponent != store.url.lastPathComponent
            })
        XCTAssertEqual(try Data(contentsOf: recovery), bytes)
    }

    func testSuccessfulImportUpdatesBothMemoryAndDisk() throws {
        let model = ProgressionModel(store: store)
        var replacement = ProgressState()
        replacement.streak.current = 9

        try model.importData(JSONEncoder().encode(replacement))

        XCTAssertEqual(model.state, replacement)
        XCTAssertEqual(ProgressionModel(store: store).state, replacement)
        XCTAssertNil(model.unreadable)
        XCTAssertNil(model.saveError)
    }

    func testInvalidImportDoesNotChangeRecoveryStateOrBytes() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        XCTAssertThrowsError(try model.importData(Data("not a backup".utf8)))

        XCTAssertNotNil(model.unreadable)
        XCTAssertEqual(try model.exportData(), bytes)
    }

    func testOrdinaryWritesCannotOverwriteAnUnreadableStore() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        model.record(concept: .outs, band: .spotOn)
        model.completeNode(try XCTUnwrap(Curriculum.node(id: "u1-showdown")), cleanRun: true)
        model.retrySave()

        XCTAssertNotNil(model.unreadable)
        XCTAssertNil(model.saveError)
        XCTAssertEqual(model.state, ProgressState())
        XCTAssertEqual(try store.exportData(), bytes)
    }

    func testDueAnswerPersistsStreakCreditWithTheAnswer() throws {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        var original = ProgressState()
        for concept in [Concept.outs, .combos] {
            original.updateRecord(for: concept) {
                $0.total = 5
                $0.review = ReviewState(stability: 5, difficulty: 5,
                    lastReview: now.addingTimeInterval(-172800),
                    due: now.addingTimeInterval(-86400), reps: 2)
            }
        }
        try store.save(original)
        let model = ProgressionModel(store: store)

        model.record(concept: .outs, band: .spotOn, now: now)

        XCTAssertEqual(model.state.streak.current, 1)
        XCTAssertEqual(model.dueConcepts(now: now), [.combos])
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
    }

    func testUnitTwoBossPracticesPositionBeforeAwardingMastery() throws {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        var original = ProgressState()
        original.updateRecord(for: .position) {
            $0.total = 5; $0.correct = 5; $0.tier = .proficient
            $0.proficientAt = now.addingTimeInterval(-86400)
        }
        try store.save(original)
        let model = ProgressionModel(store: store)
        let boss = try XCTUnwrap(Curriculum.node(id: "u2-boss"))
        let concepts = Curriculum.sessionConcepts(for: boss)
        XCTAssertEqual(concepts.count, 7)
        XCTAssertEqual(concepts.first, .callFold)
        for concept in concepts { model.record(concept: concept, band: .spotOn, now: now) }
        model.completeNode(boss, cleanRun: true, now: now)

        XCTAssertEqual(model.record(for: .position).total, 6)
        XCTAssertEqual(model.record(for: .position).tier, .mastered)
    }

    private func withReadOnlyDirectory(_ body: () throws -> Void) throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
        }
        try body()
    }
}
