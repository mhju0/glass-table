import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class BlockerTests: XCTestCase {
    func testDeterministic() {
        XCTAssertEqual(BlockerSpotGenerator.spot(baseSeed: 3, index: 9),
                       BlockerSpotGenerator.spot(baseSeed: 3, index: 9))
    }

    func testSpotInvariants() {
        for i in 0..<30 {
            let s = BlockerSpotGenerator.spot(baseSeed: 3, index: i)
            XCTAssertTrue((10...14).contains(s.rankA))
            XCTAssertTrue((10...14).contains(s.rankB))
            XCTAssertNotEqual(s.kind, .offsuit)
            if s.kind != .pair { XCTAssertGreaterThan(s.rankA, s.rankB) }
            XCTAssertTrue((2...4).contains(s.removed.count))
            XCTAssertTrue(s.removed.contains { $0.rank == s.rankA || $0.rank == s.rankB },
                          "index \(i): no relevant removed card")
            XCTAssertEqual(s.count, comboCount(rankA: s.rankA, rankB: s.rankB,
                                               kind: s.kind, removed: Set(s.removed)))
        }
    }

    func testClassNamesAndBaselines() {
        let qq = BlockerSpot(rankA: 12, rankB: 12, kind: .pair, removed: [Card("Qh")!], count: 3)
        XCTAssertEqual(qq.className, "QQ"); XCTAssertEqual(qq.baseline, 6)
        let ak = BlockerSpot(rankA: 14, rankB: 13, kind: .any, removed: [Card("As")!], count: 12)
        XCTAssertEqual(ak.className, "AK"); XCTAssertEqual(ak.baseline, 16)
        let aks = BlockerSpot(rankA: 14, rankB: 13, kind: .suited, removed: [Card("As")!], count: 3)
        XCTAssertEqual(aks.className, "AKs"); XCTAssertEqual(aks.baseline, 4)
    }

    func testGradeAndWhy() {
        let qq = BlockerSpot(rankA: 12, rankB: 12, kind: .pair, removed: [Card("Qh")!], count: 3)
        XCTAssertEqual(gradeBlocker(estimate: 3, spot: qq).band, .spotOn)
        XCTAssertEqual(gradeBlocker(estimate: 5, spot: qq).band, .close)
        XCTAssertEqual(gradeBlocker(estimate: 6, spot: qq).band, .off)
        XCTAssertEqual(gradeBlocker(estimate: 3, spot: qq).whyText,
                       "Q 3장 남음 → 3×2÷2 = 3 콤보")
        let ak = BlockerSpot(rankA: 14, rankB: 13, kind: .any, removed: [Card("As")!], count: 12)
        XCTAssertEqual(gradeBlocker(estimate: 12, spot: ak).whyText,
                       "A 3장 × K 4장 = 12 콤보")
        let aks = BlockerSpot(rankA: 14, rankB: 13, kind: .suited, removed: [Card("As")!], count: 3)
        XCTAssertEqual(gradeBlocker(estimate: 3, spot: aks).whyText,
                       "양쪽 다 남은 무늬 3개 = 3 콤보")
    }
}
