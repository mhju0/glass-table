import XCTest
@testable import GlassTableEngine

final class BlockersTests: XCTestCase {
    func testBaselineCounts() {
        XCTAssertEqual(comboCount(rankA: 14, rankB: 14, kind: .pair, removed: []), 6)
        XCTAssertEqual(comboCount(rankA: 14, rankB: 13, kind: .suited, removed: []), 4)
        XCTAssertEqual(comboCount(rankA: 14, rankB: 13, kind: .offsuit, removed: []), 12)
        XCTAssertEqual(comboCount(rankA: 14, rankB: 13, kind: .any, removed: []), 16)
    }

    func testBlockerRemovesCombos() {
        // Holding the As removes AK combos that use it: 4 (As with each K).
        let removed: Set<Card> = [Card("As")!]
        XCTAssertEqual(comboCount(rankA: 14, rankB: 13, kind: .any, removed: removed), 12)
        // For pocket AA, one blocked ace leaves C(3,2) = 3 combos.
        XCTAssertEqual(comboCount(rankA: 14, rankB: 14, kind: .pair, removed: removed), 3)
    }
}
