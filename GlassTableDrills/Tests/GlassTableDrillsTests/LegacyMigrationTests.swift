import XCTest
@testable import GlassTableDrills

final class LegacyMigrationTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gt-legacy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: dir) }

    private func writeLegacy(_ drill: String, streak: Int = 0, correct: Int = 0, total: Int = 0) throws {
        // Encode the shipped JSON format independently of the migration's decoder.
        try JSONSerialization.data(withJSONObject: ["streak": streak, "correct": correct, "total": total])
            .write(to: dir.appendingPathComponent("\(drill)-progress.json"))
    }

    func testFoldsEachLegacyDrillIntoItsConcept() throws {
        try writeLegacy("outs", streak: 4, correct: 9, total: 12)
        try writeLegacy("potodds", streak: 0, correct: 3, total: 5)
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .outs).correct, 9)
        XCTAssertEqual(s.record(for: .outs).total, 12)
        XCTAssertEqual(s.record(for: .potOdds).correct, 3)
        XCTAssertEqual(s.record(for: .potOdds).total, 5)
    }

    /// Spec §3.2 / §8.3: 블로커 was always combinatorics, so its history is 콤보's.
    func testBlockersHistoryBecomesCombos() throws {
        try writeLegacy("blockers", streak: 2, correct: 6, total: 8)
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .combos).correct, 6)
        XCTAssertEqual(s.record(for: .combos).total, 8)
        XCTAssertNil(s.concepts["blockers"])
    }

    /// MDF is parked from the path but its 자유 연습 history is not thrown away.
    func testParkedMdfHistoryIsStillCarried() throws {
        try writeLegacy("mdf", streak: 1, correct: 2, total: 4)
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .mdf).total, 4)
    }

    func testHighestLegacyStreakSeedsTheLongestStreak() throws {
        try writeLegacy("outs", streak: 4, correct: 9, total: 12)
        try writeLegacy("callfold", streak: 11, correct: 20, total: 25)
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.streak.longest, 11)
    }

    func testTierIsDerivedFromLegacyAccuracy() throws {
        try writeLegacy("outs", streak: 0, correct: 9, total: 10)     // 90%
        try writeLegacy("potodds", streak: 0, correct: 2, total: 10)  // 20%
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .outs).tier, .familiar)      // >= 70%
        XCTAssertEqual(s.record(for: .potOdds).tier, .attempted)  // < 70%
        // 능숙/숙달 are earned in-app only; migration never grants them.
        for c in Concept.allCases { XCTAssertLessThan(s.record(for: c).tier, .proficient) }
    }

    func testNoLegacyFilesLeavesStateUntouched() {
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s, ProgressState())
    }

    func testEmptyLegacyProgressIsSkippedRatherThanCreatingBlankRecords() throws {
        try writeLegacy("outs")   // never played
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertTrue(s.concepts.isEmpty)
    }

    /// Migration must not clobber real progress if it is ever run twice.
    func testDoesNotOverwriteAConceptThatAlreadyHasState() throws {
        try writeLegacy("outs", streak: 4, correct: 9, total: 12)
        var existing = ProgressState()
        existing.updateRecord(for: .outs) { $0.total = 99; $0.correct = 90; $0.tier = .mastered }
        let s = LegacyMigration.migrate(from: dir, into: existing)
        XCTAssertEqual(s.record(for: .outs).total, 99)
        XCTAssertEqual(s.record(for: .outs).tier, .mastered)
    }

    func testCorruptLegacyFileIsSkippedNotFatal() throws {
        try Data("{ bad".utf8).write(to: dir.appendingPathComponent("outs-progress.json"))
        try writeLegacy("potodds", streak: 0, correct: 3, total: 5)
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertNil(s.concepts["outs"])
        XCTAssertEqual(s.record(for: .potOdds).total, 5)
    }

}
