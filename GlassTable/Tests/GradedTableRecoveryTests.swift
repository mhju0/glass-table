import XCTest
import GlassTableDrills
@testable import GlassTable

@MainActor
final class GradedTableRecoveryTests: XCTestCase {
    func testFailedDecisionRetryAndNextDecisionPersistExactlyOnceWithoutSkillCredit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gt-table-recovery-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }
        let store = ProgressionStore(url: directory.appendingPathComponent("progression.json"))
        let model = ProgressionModel(store: store)
        let original = model.state
        let originalBytes = try store.exportData()
        let now = Date(timeIntervalSince1970: 1_792_368_000)

        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        XCTAssertFalse(model.recordTableDecision(attemptID: "table:seed:1:1", band: .spotOn,
                                                language: .english, now: now))
        XCTAssertNotNil(model.saveError)
        XCTAssertEqual(model.state, original)
        XCTAssertEqual(try store.exportData(), originalBytes)
        let pending = try store.importData(model.exportData())
        XCTAssertEqual(pending.recentEvidence.map(\.attemptID), ["table:seed:1:1"])
        XCTAssertEqual(pending.dailySummaries.reduce(0) { $0 + $1.total }, 1)

        // Neither another choice nor the same callback may replace the pending write.
        XCTAssertFalse(model.recordTableDecision(attemptID: "table:seed:1:2", band: .off,
                                                language: .english, now: now))
        XCTAssertFalse(model.recordTableDecision(attemptID: "table:seed:1:1", band: .spotOn,
                                                language: .english, now: now))
        XCTAssertEqual(try store.importData(model.exportData()), pending)
        model.retrySave()
        XCTAssertNotNil(model.saveError)
        XCTAssertEqual(try store.exportData(), originalBytes)

        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
        model.retrySave()
        XCTAssertNil(model.saveError)
        XCTAssertEqual(model.state, pending)
        XCTAssertEqual(ProgressionModel(store: store).state, pending)
        XCTAssertTrue(model.recordTableDecision(attemptID: "table:seed:1:1", band: .spotOn,
                                               language: .english, now: now))
        XCTAssertEqual(model.state, pending)

        XCTAssertTrue(model.recordTableDecision(attemptID: "table:seed:1:2", band: .off,
                                               language: .english, now: now))
        let reloaded = ProgressionModel(store: store).state
        XCTAssertEqual(reloaded.recentEvidence.map(\.attemptID), ["table:seed:1:1", "table:seed:1:2"])
        XCTAssertEqual(reloaded.dailySummaries.reduce(0) { $0 + $1.total }, 2)
        XCTAssertEqual(reloaded.concepts, original.concepts)
        XCTAssertEqual(reloaded.answers, original.answers)
        XCTAssertEqual(reloaded.nodes, original.nodes)
        XCTAssertEqual(reloaded.streak, original.streak)
    }
}
