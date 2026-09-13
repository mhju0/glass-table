import XCTest
@testable import GlassTableDrills

final class ProgressionStoreTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gt-store-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }
    private func store() -> ProgressionStore {
        ProgressionStore(url: dir.appendingPathComponent("progress.json"))
    }

    func testMissingFileLoadsAsFreshNotAsEmptyLoaded() {
        guard case .fresh = store().load() else {
            return XCTFail("a first launch must report .fresh")
        }
    }

    func testSaveThenLoadRoundTrips() throws {
        let s = store()
        var state = ProgressState()
        state.updateRecord(for: .outs) { $0.total = 7; $0.correct = 5; $0.tier = .familiar }
        state.streak.current = 3
        try s.save(state)
        guard case let .loaded(back) = s.load() else { return XCTFail("expected .loaded") }
        XCTAssertEqual(back, state)
    }

    /// Spec §8.2 — the bug being fixed. Garbage must never read as empty progress.
    func testCorruptFileReportsUnreadableAndNeverSilentlyResets() throws {
        let s = store()
        try s.save(ProgressState())
        try Data("{ this is not json".utf8)
            .write(to: dir.appendingPathComponent("progress.json"))
        guard case .unreadable = s.load() else {
            return XCTFail("a corrupt file must report .unreadable, not .fresh/.loaded")
        }
    }

    func testTruncatedFileAlsoReportsUnreadable() throws {
        let s = store()
        var state = ProgressState()
        state.updateRecord(for: .outs) { $0.total = 3 }
        try s.save(state)
        let url = dir.appendingPathComponent("progress.json")
        let full = try Data(contentsOf: url)
        try full.prefix(full.count / 2).write(to: url)   // simulate a kill mid-write
        guard case .unreadable = s.load() else { return XCTFail("expected .unreadable") }
    }

    func testReplacementPreservesUnreadableBytesAndSavesFreshProgress() throws {
        let s = store()
        let url = dir.appendingPathComponent("progress.json")
        try Data("{ bad".utf8).write(to: url)
        let recovery = try XCTUnwrap(s.replace(with: ProgressState()))
        XCTAssertEqual(try Data(contentsOf: recovery), Data("{ bad".utf8))
        guard case let .loaded(state) = s.load() else { return XCTFail("expected .loaded") }
        XCTAssertEqual(state, ProgressState())
    }

    func testSaveIsAtomicSoAFailedWriteLeavesThePreviousFileIntact() throws {
        let s = store()
        var good = ProgressState()
        good.streak.current = 9
        try s.save(good)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
        }
        XCTAssertThrowsError(try s.save(ProgressState()))
        guard case let .loaded(back) = s.load() else { return XCTFail("expected .loaded") }
        XCTAssertEqual(back.streak.current, 9)
    }

    func testReplacementAbortsWhenRecoveryCopyCannotBeWritten() throws {
        let s = store()
        let original = Data("{ damaged but recoverable".utf8)
        try original.write(to: s.url)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
        }

        XCTAssertThrowsError(try s.replace(with: ProgressState()))
        XCTAssertEqual(try Data(contentsOf: s.url), original)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: dir.path), ["progress.json"])
    }

    func testRepeatedReplacementsKeepDistinctRecoveryCopies() throws {
        let s = store()
        var first = ProgressState()
        first.streak.current = 3
        try s.save(first)
        let firstBytes = try s.exportData()
        let firstCopy = try XCTUnwrap(s.replace(with: ProgressState()))
        let secondBytes = try s.exportData()
        let secondCopy = try XCTUnwrap(s.replace(with: first))

        XCTAssertNotEqual(firstCopy, secondCopy)
        XCTAssertEqual(try Data(contentsOf: firstCopy), firstBytes)
        XCTAssertEqual(try Data(contentsOf: secondCopy), secondBytes)
    }

    func testFailedReplacementWriteKeepsTheLiveFileAndRecoveryCopy() throws {
        let s = store()
        let bytes = Data("{ damaged but recoverable".utf8)
        try bytes.write(to: s.url)
        // A locked live file can be copied, but atomic replacement must fail.
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: s.url.path)
        defer {
            for file in (try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil)) ?? [] {
                try? FileManager.default.setAttributes([.immutable: false], ofItemAtPath: file.path)
            }
        }

        XCTAssertThrowsError(try s.replace(with: ProgressState()))

        XCTAssertEqual(try Data(contentsOf: s.url), bytes)
        let recovery = try XCTUnwrap(FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil).first { $0 != s.url })
        XCTAssertEqual(try Data(contentsOf: recovery), bytes)
    }

    func testReplacementWorksWhenThereIsNoPreviousFile() throws {
        let s = store()
        XCTAssertNil(try s.replace(with: ProgressState()))
        guard case .loaded = s.load() else { return XCTFail("expected saved progress") }
    }

    func testExportProducesTheStoreBytesAndImportValidates() throws {
        let s = store()
        var state = ProgressState()
        state.updateRecord(for: .potOdds) { $0.total = 5 }
        try s.save(state)

        let exported = try s.exportData()
        XCTAssertEqual(try JSONDecoder().decode(ProgressState.self, from: exported), state)

        let imported = try s.importData(exported)
        XCTAssertEqual(imported, state)
        XCTAssertThrowsError(try s.importData(Data("nonsense".utf8)))
    }

    func testImportRejectsAFutureSchemaVersion() throws {
        let s = store()
        var future = ProgressState()
        future.schemaVersion = ProgressState.currentSchemaVersion + 1
        let data = try JSONEncoder().encode(future)
        XCTAssertThrowsError(try s.importData(data)) { error in
            XCTAssertEqual(error as? StoreError, .unsupportedSchemaVersion(
                found: ProgressState.currentSchemaVersion + 1,
                supported: ProgressState.currentSchemaVersion))
        }
    }

    func testLoadRejectsAFutureSchemaVersionWithoutChangingTheFile() throws {
        let s = store()
        var future = ProgressState()
        future.schemaVersion = ProgressState.currentSchemaVersion + 1
        let data = try JSONEncoder().encode(future)
        try data.write(to: s.url)

        guard case .unreadable = s.load() else {
            return XCTFail("disk loads must validate the same schema as imports")
        }
        XCTAssertEqual(try Data(contentsOf: s.url), data)
    }

    func testImportRejectsSemanticallyUnsafeProgress() throws {
        let s = store()
        var cases: [ProgressState] = []

        var badSchema = ProgressState()
        badSchema.schemaVersion = -1
        cases.append(badSchema)

        var badCount = ProgressState()
        badCount.concepts["retired-concept"] = ConceptRecord(correct: -1, total: Int.max)
        cases.append(badCount)

        var badReview = ProgressState()
        badReview.concepts[Concept.outs.rawValue] = ConceptRecord(
            review: ReviewState(stability: 1e100, difficulty: 5,
                                lastReview: Date(), due: Date(), reps: 1),
            correct: 1, total: 1)
        cases.append(badReview)

        var badInterval = ProgressState()
        badInterval.answers = [AnswerRecord(concept: .equitySense, at: Date(), correct: true,
            interval: IntervalAnswer(point: 50, lo: 70, hi: 30, truth: 50))]
        cases.append(badInterval)

        for state in cases {
            XCTAssertThrowsError(try s.importData(JSONEncoder().encode(state))) { error in
                XCTAssertEqual(error as? StoreError, .invalidProgress)
            }
        }
    }

    func testImportAcceptsConservativeLifetimeBoundsAndUnknownKeys() throws {
        let s = store()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var state = ProgressState()
        state.concepts["retired-concept"] = ConceptRecord(
            tier: .mastered,
            review: ReviewState(stability: 36_500, difficulty: 10,
                                lastReview: now, due: now.addingTimeInterval(86_400),
                                reps: 1_000_000, lapses: 500_000),
            correct: 900_000, total: 1_000_000, consecutiveMisses: 0,
            proficientAt: now, masteredAt: now)
        state.nodes["retired-node"] = NodeRecord(cleared: true, clearedAt: now,
                                                   attempts: 1_000_000)

        let imported = try s.importData(JSONEncoder().encode(state))

        XCTAssertEqual(imported, state)
        XCTAssertNotNil(imported.concepts["retired-concept"])
        XCTAssertNotNil(imported.nodes["retired-node"])
    }

    func testNegativeEVCallIntervalRoundTrips() throws {
        let s = store()
        let reveal = gradeEVCall(
            estimate: Estimate(point: -4, lo: -5, hi: -3),
            spot: EVCallSpot(pot: 10, bet: 10, equityPct: 20, didWin: false))
        var state = ProgressState()
        state.answers = [AnswerRecord(concept: .evCall, at: Date(), correct: true,
                                      interval: reveal.intervalAnswer)]

        XCTAssertEqual(try s.importData(s.exportData(state)), state)
    }

    func testImportAndDiskLoadRejectOversizedFilesWithoutChangingBytes() throws {
        let s = store()
        let bytes = Data(repeating: 0x20, count: ProgressionStore.maximumFileBytes + 1)

        XCTAssertThrowsError(try s.importData(bytes)) { error in
            XCTAssertEqual(error as? StoreError,
                           .fileTooLarge(maximumBytes: ProgressionStore.maximumFileBytes))
        }

        try bytes.write(to: s.url)
        guard case .unreadable = s.load() else {
            return XCTFail("an oversized disk store must remain recoverable")
        }
        XCTAssertEqual(try FileManager.default.attributesOfItem(atPath: s.url.path)[.size] as? Int,
                       bytes.count)
    }

    func testCanonicalExportDoesNotInflateSlashHeavyImportedKeys() throws {
        let s = store()
        var state = ProgressState()
        state.nodes[String(repeating: "/", count: 3_000_000)] = NodeRecord()
        let encoder = JSONEncoder()
        if #available(macOS 10.15, *) {
            encoder.outputFormatting = [.withoutEscapingSlashes]
        }
        let incoming = try encoder.encode(state)
        XCTAssertLessThan(incoming.count, ProgressionStore.maximumFileBytes)

        let imported = try s.importData(incoming)
        let exported = try s.exportData(imported)

        XCTAssertLessThanOrEqual(exported.count, ProgressionStore.maximumFileBytes)
        XCTAssertEqual(try s.importData(exported), imported)
    }

    func testOversizedEncodedReplacementKeepsOriginalAndCreatesNoRecoveryCopy() throws {
        let s = store()
        var original = ProgressState()
        original.streak.current = 3
        original.streak.longest = 3
        try s.save(original)
        let originalBytes = try s.exportData()
        var oversized = ProgressState()
        oversized.nodes[String(repeating: "x", count: ProgressionStore.maximumFileBytes)] =
            NodeRecord()

        XCTAssertThrowsError(try s.replace(with: oversized)) { error in
            XCTAssertEqual(error as? StoreError,
                           .fileTooLarge(maximumBytes: ProgressionStore.maximumFileBytes))
        }
        XCTAssertEqual(try s.exportData(), originalBytes)
        let files = try FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.map(\.lastPathComponent), [s.url.lastPathComponent])
    }
}
