import XCTest
import Foundation
import GlassTableEngine
@testable import GlassTableDrills

final class ProgressTests: XCTestCase {
    func testRecordingStreakAndAccuracy() {
        var p = DrillProgress()
        p = p.recording(.spotOn)   // streak 1, correct 1, total 1
        p = p.recording(.close)    // streak 2, correct 1, total 2 (close keeps the streak)
        p = p.recording(.off)      // streak 0, correct 1, total 3 (off resets)
        XCTAssertEqual(p.streak, 0)
        XCTAssertEqual(p.correct, 1)
        XCTAssertEqual(p.total, 3)
        XCTAssertEqual(p.accuracy, 1.0 / 3.0, accuracy: 1e-9)
    }

    func testStoreRoundTrip() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gt-\(UUID()).json")
        let store = ProgressStore(url: url)
        XCTAssertEqual(store.load(), DrillProgress())        // missing file → default
        let p = DrillProgress(streak: 5, correct: 4, total: 6)
        store.save(p)
        XCTAssertEqual(store.load(), p)
        try? FileManager.default.removeItem(at: url)
    }
}
