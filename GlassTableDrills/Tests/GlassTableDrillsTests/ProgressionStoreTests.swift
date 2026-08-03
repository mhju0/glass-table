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

    func testQuarantineMovesTheBadFileAsideSoTheNextLoadIsFresh() throws {
        let s = store()
        let url = dir.appendingPathComponent("progress.json")
        try Data("{ bad".utf8).write(to: url)
        let moved = try s.quarantineCorruptFile()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: moved.path))
        XCTAssertEqual(try Data(contentsOf: moved), Data("{ bad".utf8))
        guard case .fresh = s.load() else { return XCTFail("expected .fresh after quarantine") }
    }

    func testSaveIsAtomicSoAFailedWriteLeavesThePreviousFileIntact() throws {
        let s = store()
        var good = ProgressState()
        good.streak.current = 9
        try s.save(good)
        // Writing to a path whose parent does not exist must throw, not truncate.
        let bad = ProgressionStore(url: dir.appendingPathComponent("nope/progress.json"))
        XCTAssertThrowsError(try bad.save(ProgressState()))
        guard case let .loaded(back) = s.load() else { return XCTFail("expected .loaded") }
        XCTAssertEqual(back.streak.current, 9)
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
}
