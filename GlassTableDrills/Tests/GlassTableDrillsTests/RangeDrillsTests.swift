import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class RFIChartTests: XCTestCase {
    func testSevenSeatsOpen_BigBlindNeverDoes() {
        XCTAssertEqual(Set(RFIChart.seats), Set(Position.allCases).subtracting([.bb]))
        XCTAssertTrue(RFIChart.range(for: .bb).isEmpty,
                      "folded to the BB ends the hand — there is no RFI decision")
    }

    /// The whole point of position: the fewer players behind, the wider you open.
    func testChartsWidenAsPlayersBehindDecrease() {
        let ordered = [Position.utg, .utg1, .lj, .hj, .co, .btn]
        for (tight, wide) in zip(ordered, ordered.dropFirst()) {
            XCTAssertLessThan(RFIChart.range(for: tight).percent,
                              RFIChart.range(for: wide).percent,
                              "\(wide.rawValue) must open wider than \(tight.rawValue)")
        }
    }

    /// A wider chart must contain everything a tighter one opens. Without this a hand
    /// could be "open from UTG, fold from BTN", which no chart in the world says.
    func testTighterChartsNestInsideWiderOnes() {
        let ordered = [Position.utg, .utg1, .lj, .hj, .co, .btn]
        for (tight, wide) in zip(ordered, ordered.dropFirst()) {
            let t = Set(RFIChart.range(for: tight).classes)
            let w = Set(RFIChart.range(for: wide).classes)
            XCTAssertTrue(t.isSubset(of: w), "\(tight.rawValue) ⊄ \(wide.rawValue)")
        }
    }

    func testPremiumsOpenEverywhereAndTrashOpensNowhere() {
        for seat in RFIChart.seats {
            XCTAssertTrue(RFIChart.opens(Card.parse("AhAs")!, from: seat), seat.rawValue)
            XCTAssertTrue(RFIChart.opens(Card.parse("AhKh")!, from: seat), seat.rawValue)
            XCTAssertFalse(RFIChart.opens(Card.parse("7h2s")!, from: seat), seat.rawValue)
        }
    }

    /// The boundary cases that killed the equity-vs-random derivation.
    func testBoundaryHandsLandWhereChartsPutThem() {
        // 76s is a late-position open, not an early one.
        XCTAssertFalse(RFIChart.opens(Card.parse("7h6h")!, from: .utg))
        XCTAssertTrue(RFIChart.opens(Card.parse("7h6h")!, from: .btn))
        // A9o is later still than 22.
        XCTAssertFalse(RFIChart.opens(Card.parse("Ah9s")!, from: .utg))
        // Suited beats its offsuit twin at every seat.
        for seat in RFIChart.seats where RFIChart.opens(Card.parse("Kh9h")!, from: seat) == false {
            XCTAssertFalse(RFIChart.opens(Card.parse("Kh9s")!, from: seat),
                           "offsuit cannot open where suited does not")
        }
    }

    func testEarliestSeatOpeningIsTheTightestOneThatDoes() {
        XCTAssertEqual(RFIChart.earliestSeatOpening(Card.parse("AhAs")!), .utg)
        XCTAssertNil(RFIChart.earliestSeatOpening(Card.parse("7h2s")!))
        let seat = RFIChart.earliestSeatOpening(Card.parse("7h6h")!)
        XCTAssertNotNil(seat)
        XCTAssertTrue(RFIChart.opens(Card.parse("7h6h")!, from: seat!))
    }
}

final class RangeNotationDrillTests: XCTestCase {
    func testGeneratorIsDeterministicAndAlwaysParses() {
        XCTAssertEqual(RangeNotationSpotGenerator.spot(baseSeed: 9, index: 4).notation,
                       RangeNotationSpotGenerator.spot(baseSeed: 9, index: 4).notation)
        for i in 0..<300 {
            let s = RangeNotationSpotGenerator.spot(baseSeed: 9, index: i)
            XCTAssertFalse(s.range.isEmpty, "generated \(s.notation) which parsed to nothing")
            XCTAssertGreaterThan(s.comboCount, 0)
            // Whatever it printed must parse back to exactly the same range.
            XCTAssertEqual(try? RangeNotation.parse(s.notation), s.range, s.notation)
        }
    }

    func testComboCountMatchesTheShapeArithmetic() {
        let spot = RangeNotationSpot(notation: "QQ+, AKs",
                                     range: try! RangeNotation.parse("QQ+, AKs"))
        // QQ, KK, AA = 3 pairs × 6 = 18, plus AKs 4 → 22
        XCTAssertEqual(spot.comboCount, 22)
        XCTAssertEqual(gradeRangeNotation(estimate: 22, spot: spot).band, .spotOn)
        XCTAssertEqual(gradeRangeNotation(estimate: 21, spot: spot).band, .off,
                       "an exact question has no near-miss band")
    }

    func testWhyTextShowsThePerClassArithmetic() {
        let spot = RangeNotationSpot(notation: "AA, AKo",
                                     range: try! RangeNotation.parse("AA, AKo"))
        let why = gradeRangeNotation(estimate: 18, spot: spot).whyText
        XCTAssertTrue(why.contains("AA 6"), why)
        XCTAssertTrue(why.contains("AKo 12"), why)
        XCTAssertTrue(why.contains("= 18"), why)
    }
}

final class RFIDrillTests: XCTestCase {
    func testGeneratorIsDeterministicAndLegal() {
        XCTAssertEqual(RFISpotGenerator.spot(baseSeed: 3, index: 7),
                       RFISpotGenerator.spot(baseSeed: 3, index: 7))
        for i in 0..<300 {
            let s = RFISpotGenerator.spot(baseSeed: 3, index: i)
            XCTAssertEqual(s.hand.count, 2)
            XCTAssertNotEqual(s.hand[0], s.hand[1])
            XCTAssertNotEqual(s.seat, .bb, "BB has no RFI decision")
        }
    }

    /// Both answers must actually occur, or the drill is guessable from the shape.
    func testBothVerdictsAppear() {
        var opens = 0, folds = 0
        for i in 0..<300 {
            RFISpotGenerator.spot(baseSeed: 3, index: i).opens ? (opens += 1) : (folds += 1)
        }
        XCTAssertGreaterThan(opens, 30)
        XCTAssertGreaterThan(folds, 30)
    }

    func testGradingIsBinaryAndExplainsWithTheChenArithmetic() {
        let spot = RFISpot(hand: Card.parse("AhAs")!, seat: .utg)
        XCTAssertEqual(gradeRFI(userOpens: true, spot: spot).band, .spotOn)
        XCTAssertEqual(gradeRFI(userOpens: false, spot: spot).band, .off)
        let why = gradeRFI(userOpens: true, spot: spot).whyText
        XCTAssertTrue(why.contains("AA"), why)
        XCTAssertTrue(why.contains("상위 15%"), why)
        XCTAssertTrue(why.contains("= 20"), "the Chen arithmetic is shown, not just the verdict: \(why)")
    }

    /// A fold is never just "no" — it names the seat the hand does open from.
    func testAFoldNamesTheSeatThatWouldOpenIt() {
        let spot = RFISpot(hand: Card.parse("7h6h")!, seat: .utg)
        guard !spot.opens else { return XCTFail("76s should not open from UTG") }
        let why = gradeRFI(userOpens: false, spot: spot).whyText
        XCTAssertTrue(why.contains("부터 열어요"), why)
    }

    func testBeatScriptsRunOnAnyGeneratedSpot() {
        for i in 0..<120 {
            let rfi = BeatScript.rfi(RFISpotGenerator.spot(baseSeed: 12, index: i))
            XCTAssertFalse(rfi.isEmpty)
            for b in rfi {
                let all = b.caption + (b.value ?? "") + (b.detail ?? "")
                XCTAssertFalse(all.contains("nil") || all.contains("Optional"), all)
            }
            let notation = BeatScript.rangeNotation(
                RangeNotationSpotGenerator.spot(baseSeed: 12, index: i))
            XCTAssertFalse(notation.isEmpty)
            XCTAssertTrue(notation.last!.value?.contains("콤보") == true)
        }
    }
}

final class RangeGridLayoutTests: XCTestCase {
    /// The universal convention (`decisions.md` §B). The first implementation had the
    /// triangles swapped, which is invisible until you hold the app next to any other
    /// tool — so it is pinned here rather than left to the view.
    func testSuitedIsAboveTheDiagonalAndOffsuitBelow() {
        // Row A, column K — upper right of the diagonal.
        XCTAssertEqual(RangeGrid.classAt(row: 14, col: 13).description, "AKs")
        // Row K, column A — lower left.
        XCTAssertEqual(RangeGrid.classAt(row: 13, col: 14).description, "AKo")
        XCTAssertEqual(RangeGrid.classAt(row: 10, col: 9).description, "T9s")
        XCTAssertEqual(RangeGrid.classAt(row: 9, col: 10).description, "T9o")
    }

    func testTheDiagonalIsThePairs() {
        for r in 2...14 {
            let h = RangeGrid.classAt(row: r, col: r)
            XCTAssertTrue(h.isPair, "\(h.description) should be a pair")
        }
    }

    func testRanksRunAceFirst() {
        XCTAssertEqual(RangeGrid.ranks.first, 14)
        XCTAssertEqual(RangeGrid.ranks.last, 2)
        XCTAssertEqual(RangeGrid.ranks.count, 13)
    }

    /// Every cell of the 13×13 must be a distinct class, and together exactly the 169.
    func testTheGridCoversAllOneSixtyNineExactlyOnce() {
        var seen: [HandClass] = []
        for row in RangeGrid.ranks {
            for col in RangeGrid.ranks { seen.append(RangeGrid.classAt(row: row, col: col)) }
        }
        XCTAssertEqual(seen.count, 169)
        XCTAssertEqual(Set(seen).count, 169)
        XCTAssertEqual(Set(seen), Set(HandClass.all))
    }
}
