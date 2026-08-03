import XCTest
@testable import GlassTableEngine

final class HandClassTests: XCTestCase {
    func testThereAreExactlyOneSixtyNineClassesAnd1326Combos() {
        XCTAssertEqual(HandClass.all.count, 169)
        XCTAssertEqual(Set(HandClass.all).count, 169, "no duplicates")
        XCTAssertEqual(HandClass.all.reduce(0) { $0 + $1.comboCount }, 1326)
        XCTAssertEqual(HandClass.totalCombos, 1326)
    }

    func testComboCountsByShape() {
        XCTAssertEqual(HandClass(high: 14, low: 14, suited: false)!.comboCount, 6)
        XCTAssertEqual(HandClass(high: 14, low: 13, suited: true)!.comboCount, 4)
        XCTAssertEqual(HandClass(high: 14, low: 13, suited: false)!.comboCount, 12)
    }

    func testASuitedPairIsNotConstructible() {
        XCTAssertNil(HandClass(high: 14, low: 14, suited: true))
        XCTAssertNil(HandClass(high: 5, low: 9, suited: true), "low must not exceed high")
    }

    func testNamesMatchChartNotation() {
        XCTAssertEqual(HandClass(high: 14, low: 14, suited: false)!.description, "AA")
        XCTAssertEqual(HandClass(high: 14, low: 13, suited: true)!.description, "AKs")
        XCTAssertEqual(HandClass(high: 10, low: 9, suited: false)!.description, "T9o")
    }

    func testClassifiesAConcreteHolding() {
        XCTAssertEqual(HandClass(Card.parse("AhAs")!)?.description, "AA")
        XCTAssertEqual(HandClass(Card.parse("AhKh")!)?.description, "AKs")
        XCTAssertEqual(HandClass(Card.parse("KdAh")!)?.description, "AKo", "order is normalised")
    }

    func testExpandedCombosAreLegalAndCorrectlyCounted() {
        for h in HandClass.all {
            let combos = h.combos()
            XCTAssertEqual(combos.count, h.comboCount, h.description)
            for c in combos {
                XCTAssertEqual(c.count, 2)
                XCTAssertNotEqual(c[0], c[1])
                XCTAssertEqual(HandClass(c), h, "expansion must round-trip")
            }
        }
    }

    func testRemovalReducesCombos() {
        let aa = HandClass(high: 14, low: 14, suited: false)!
        XCTAssertEqual(aa.combos(removing: [Card("As")!]).count, 3)   // 3 aces left → 3 pairs
        let aks = HandClass(high: 14, low: 13, suited: true)!
        XCTAssertEqual(aks.combos(removing: [Card("Ah")!]).count, 3)
        let ako = HandClass(high: 14, low: 13, suited: false)!
        XCTAssertEqual(ako.combos(removing: [Card("Ah")!]).count, 9)  // 3 aces × 3 kings
    }
}

final class ChenTests: XCTestCase {
    private func score(_ s: String) -> Double {
        Chen.score(HandClass.all.first { $0.description == s }!)
    }

    /// Hand-checked against the published formula.
    func testPublishedValues() {
        XCTAssertEqual(score("AA"), 20)      // 10 × 2
        XCTAssertEqual(score("KK"), 16)
        XCTAssertEqual(score("QQ"), 14)
        XCTAssertEqual(score("JJ"), 12)
        XCTAssertEqual(score("TT"), 10)
        XCTAssertEqual(score("AKs"), 12)     // 10 + 2 suited − 0 gap... gap 1 → −1, +1? A,K gap 0
        XCTAssertEqual(score("AKo"), 10)
        XCTAssertEqual(score("72o"), -1.5)   // 3.5 − 5 gap
    }

    /// The pair minimum: 22 scores 1 × 2 = 2, floored to 5.
    func testSmallPairsTakeTheMinimumOfFive() {
        XCTAssertEqual(score("22"), 5)
        XCTAssertEqual(score("33"), 5)
        XCTAssertEqual(score("44"), 5)
        XCTAssertEqual(score("55"), 5)   // 2.5 × 2 = 5, exactly at the floor
        XCTAssertEqual(score("66"), 6)   // 3 × 2 = 6, above it
    }

    /// The straight bonus applies only below Q and only at gap ≤ 1.
    func testStraightBonusBoundary() {
        XCTAssertEqual(score("JTs"), 9)    // 6 + 2 suited − 0 gap + 1 bonus
        XCTAssertEqual(score("QJs"), 9)    // 7 + 2 − 0, no bonus: high card is Q
        XCTAssertEqual(score("T8s"), 7)    // 5 + 2 − 1 gap + 1 bonus
        XCTAssertEqual(score("T7s"), 5)    // 5 + 2 − 2 gap, gap too wide for the bonus
    }

    func testGapLadder() {
        XCTAssertEqual(Chen.gapPenalty(0), 0)
        XCTAssertEqual(Chen.gapPenalty(1), 1)
        XCTAssertEqual(Chen.gapPenalty(2), 2)
        XCTAssertEqual(Chen.gapPenalty(3), 4)
        XCTAssertEqual(Chen.gapPenalty(4), 5)
        XCTAssertEqual(Chen.gapPenalty(11), 5)
    }

    func testRankingCoversEveryClassExactlyOnce() {
        XCTAssertEqual(Chen.ranked.count, 169)
        XCTAssertEqual(Set(Chen.ranked).count, 169)
        XCTAssertEqual(Chen.ranked.first?.description, "AA")
        XCTAssertEqual(Chen.ranked.last?.description, "72o")
    }

    /// **The regression this whole derivation exists for.** An equity-vs-random
    /// ranking put 76s at 129/169, 22 at 87/169 and A9o above AJs — it would have
    /// shipped a chart opening A9o under the gun while folding 76s everywhere.
    /// These are the boundary cases every published chart agrees on.
    func testRankingMatchesConventionWhereEquityVsRandomDidNot() {
        func rank(_ s: String) -> Int {
            Chen.ranked.firstIndex { $0.description == s }! + 1
        }
        XCTAssertLessThan(rank("AJs"), rank("ATo"), "suited broadway beats offsuit one gap wider")
        XCTAssertLessThan(rank("76s"), rank("A9o"), "a suited connector beats offsuit ace-rag")
        XCTAssertLessThan(rank("76s"), 70, "76s must be inside late-position ranges")
        XCTAssertLessThan(rank("22"), 70, "22 must be inside mid-to-late ranges")
        XCTAssertGreaterThan(rank("A9o"), 70, "A9o must fall outside early ranges")
        XCTAssertLessThan(rank("JTs"), rank("KJo"), "suited connector over offsuit broadway")
    }

    /// 22 and A9o score identically, so the tie-break — not the score — decides which
    /// makes a chart at its boundary. It orders by the playability the raw score
    /// under-weights, which is why this is pinned rather than left to sort order.
    func testTiesBreakByPlayabilityNotByIncidentalSortOrder() {
        let twos = HandClass.all.first { $0.description == "22" }!
        let a9o = HandClass.all.first { $0.description == "A9o" }!
        XCTAssertEqual(Chen.score(twos), Chen.score(a9o), "these genuinely tie at 5")

        let order = Chen.ranked
        XCTAssertLessThan(order.firstIndex(of: twos)!, order.firstIndex(of: a9o)!,
                          "the pair must win the tie")

        // Same score, differing only in shape: suited beats offsuit, tighter gap wins.
        func rankOf(_ s: String) -> Int {
            order.firstIndex { $0.description == s }!
        }
        for (a, b) in [("KQs", "KQo"), ("T9s", "T8s")] where
            Chen.score(HandClass.all.first { $0.description == a }!)
            == Chen.score(HandClass.all.first { $0.description == b }!) {
            XCTAssertLessThan(rankOf(a), rankOf(b), "\(a) should outrank \(b) on a tie")
        }
    }

    func testExplanationShowsTheArithmeticNotJustTheScore() {
        let aks = HandClass.all.first { $0.description == "AKs" }!
        let text = Chen.explain(aks)
        XCTAssertTrue(text.contains("수티드 +2"), text)
        XCTAssertTrue(text.contains("= 12"), text)

        let twos = HandClass.all.first { $0.description == "22" }!
        XCTAssertTrue(Chen.explain(twos).contains("최소 5"), Chen.explain(twos))
    }
}

final class HandRangeTests: XCTestCase {
    private func cls(_ s: String) -> HandClass { HandClass.all.first { $0.description == s }! }

    func testComboCountIsWeightedByShapeNotByClass() {
        // One pair (6) + one suited (4) + one offsuit (12) = 22 combos, not 3.
        let r = HandRange([cls("AA"), cls("AKs"), cls("AKo")])
        XCTAssertEqual(r.comboCount, 22)
        XCTAssertEqual(r.percent, 22.0 / 1326 * 100, accuracy: 1e-9)
    }

    func testEveryClassIsAHundredPercent() {
        XCTAssertEqual(HandRange(HandClass.all).comboCount, 1326)
        XCTAssertEqual(HandRange(HandClass.all).percent, 100, accuracy: 1e-9)
    }

    func testPartialWeightsScaleTheCount() {
        XCTAssertEqual(HandRange([cls("AA"): 0.5]).comboCount, 3)
        XCTAssertEqual(HandRange([cls("AA"): 0]).isEmpty, true, "zero weight is not membership")
    }

    func testContainsUsesTheConcreteHolding() {
        let r = HandRange([cls("AKs")])
        XCTAssertTrue(r.contains(Card.parse("AhKh")!))
        XCTAssertFalse(r.contains(Card.parse("AhKs")!), "offsuit is a different class")
    }

    func testRemovalReducesTheComboCount() {
        let r = HandRange([cls("AA"), cls("AKs")])
        XCTAssertEqual(r.comboCount(removing: []), 10)
        XCTAssertEqual(r.comboCount(removing: Card.parse("As")!), 6)  // AA 6→3, AKs 4→3
    }

    func testSetAlgebra() {
        let a = HandRange([cls("AA"), cls("KK")])
        let b = HandRange([cls("KK"), cls("QQ")])
        XCTAssertEqual(Set(a.union(b).classes), Set([cls("AA"), cls("KK"), cls("QQ")]))
        XCTAssertEqual(a.intersection(b).classes, [cls("KK")])
        XCTAssertEqual(a.subtracting(b).classes, [cls("AA")])
    }

    func testIntersectionTakesTheSmallerWeight() {
        let a = HandRange([cls("AA"): 1.0]), b = HandRange([cls("AA"): 0.25])
        XCTAssertEqual(a.intersection(b).weight(cls("AA")), 0.25)
    }

    /// The cut is on combos, so "top 15%" means 15% of hands dealt — not 15% of the
    /// 169 cells, which would be wrong by roughly a factor of two on pair-heavy cuts.
    func testTopByChenCutsOnCombosAndIsMonotonic() {
        var previous = 0.0
        for pct in [5.0, 10, 15, 20, 25, 30, 40, 50] {
            let r = HandRange.topByChen(percent: pct)
            XCTAssertGreaterThan(r.percent, previous)
            // Includes the straddling class whole, so it lands at or just past target.
            XCTAssertEqual(r.percent, pct, accuracy: 3.0, "top \(pct)% landed at \(r.percent)%")
            previous = r.percent
        }
    }

    func testTighterChartsAreSubsetsOfWiderOnes() {
        let cuts = [15.0, 17, 20, 23, 28, 36, 42].map { HandRange.topByChen(percent: $0) }
        for (tight, wide) in zip(cuts, cuts.dropFirst()) {
            XCTAssertTrue(Set(tight.classes).isSubset(of: Set(wide.classes)),
                          "a wider chart must contain everything a tighter one opens")
        }
    }

    func testTopChartsContainTheHandsEveryChartOpens() {
        let utg = HandRange.topByChen(percent: 15)
        for h in ["AA", "KK", "QQ", "AKs", "AKo", "AQs", "JJ"] {
            XCTAssertGreaterThan(utg.weight(cls(h)), 0, "\(h) must be in a 15% opening range")
        }
        for h in ["72o", "J2o", "83o"] {
            XCTAssertEqual(utg.weight(cls(h)), 0, "\(h) must not be")
        }
    }
}

final class RangeNotationTests: XCTestCase {
    private func cls(_ s: String) -> HandClass { HandClass.all.first { $0.description == s }! }

    func testParsesSingleClasses() throws {
        XCTAssertEqual(try RangeNotation.parse("QQ").classes, [cls("QQ")])
        XCTAssertEqual(try RangeNotation.parse("AKs").classes, [cls("AKs")])
        XCTAssertEqual(try RangeNotation.parse("T9o").classes, [cls("T9o")])
    }

    func testPairPlusWalksUp() throws {
        let r = try RangeNotation.parse("QQ+")
        XCTAssertEqual(Set(r.classes.map(\.description)), ["QQ", "KK", "AA"])
    }

    func testSuitedPlusWalksTheLowCardUp() throws {
        let r = try RangeNotation.parse("ATs+")
        XCTAssertEqual(Set(r.classes.map(\.description)), ["ATs", "AJs", "AQs", "AKs"])
    }

    func testRunsStepBothRanksDown() throws {
        let r = try RangeNotation.parse("T9s-76s")
        XCTAssertEqual(Set(r.classes.map(\.description)), ["T9s", "98s", "87s", "76s"])
    }

    func testAWholeChartLine() throws {
        let r = try RangeNotation.parse("22+, ATs+, KQs, 76s")
        XCTAssertEqual(r.classes.count, 13 + 4 + 1 + 1)
        XCTAssertTrue(r.contains(Card.parse("7h6h")!))
        XCTAssertFalse(r.contains(Card.parse("7h6s")!), "76o is not 76s")
    }

    func testRejectsGarbage() {
        XCTAssertThrowsError(try RangeNotation.parse("XX"))
        XCTAssertThrowsError(try RangeNotation.parse("AK"), "unsuffixed non-pair is ambiguous")
        XCTAssertThrowsError(try RangeNotation.parse("T9s-76o"), "a run cannot change shape")
    }

    func testRoundTrips() throws {
        for text in ["22+, ATs+, KQs, 76s", "AA", "T9s-76s", "77+, AJo+"] {
            let once = try RangeNotation.parse(text)
            let twice = try RangeNotation.parse(RangeNotation.print(once))
            XCTAssertEqual(once, twice, text)
        }
    }
}
