import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class ShapedRangeTests: XCTestCase {
    func testShapedHitsRoughlyTheRequestedWidth() {
        for w in [10.0, 20, 30, 45, 60] {
            let r = HandRange.shaped(width: w)
            XCTAssertEqual(r.percent, w, accuracy: 3.0, "asked \(w)%, got \(r.percent)%")
        }
    }

    /// With no tendencies it must be exactly the plain Chen cut, or the two paths
    /// would disagree about what "top 20%" means.
    func testNoTendenciesMatchesThePlainChenCut() {
        for w in [12.0, 25, 40] {
            XCTAssertEqual(HandRange.shaped(width: w), HandRange.topByChen(percent: w))
        }
    }

    /// A tendency must measurably tilt the shape while keeping the width — but only
    /// where there is something left to prefer. Pairs are 78 combos (5.9% of the deck)
    /// and offsuit broadways 120 (9%), so by 30% width they are already entirely
    /// inside the cut and the preference is correctly a no-op. Asserted across widths
    /// rather than at one, which is what the first version got wrong.
    func testEveryTendencyBitesSomewhereWithoutChangingWidth() {
        for t in RangeTendency.allCases {
            var bitAtLeastOnce = false
            for w in [8.0, 12, 18, 25, 35, 50] {
                let plain = HandRange.shaped(width: w)
                let tilted = HandRange.shaped(width: w, tendencies: [t])
                XCTAssertEqual(tilted.percent, plain.percent, accuracy: 4.0,
                               "\(t.rawValue) changed the width at \(w)%")
                XCTAssertGreaterThanOrEqual(tilted.tendencyShare(t), plain.tendencyShare(t) - 1e-9,
                                            "\(t.rawValue) *lowered* its own share at \(w)%")
                if tilted.tendencyShare(t) > plain.tendencyShare(t) { bitAtLeastOnce = true }
            }
            XCTAssertTrue(bitAtLeastOnce, "\(t.rawValue) never changed anything at any width")
        }
    }

    /// The saturation itself, pinned — a chip that does nothing needs to be a known
    /// property rather than a surprise, because the UI has to be able to say so.
    func testASaturatedCategoryIsANoOp() {
        let plain = HandRange.shaped(width: 40)
        XCTAssertEqual(plain.tendencyShare(.pairs),
                       HandRange.shaped(width: 40, tendencies: [.pairs]).tendencyShare(.pairs),
                       accuracy: 1e-9,
                       "every pair is already inside a 40% range, so preferring them cannot help")
        XCTAssertTrue(RangeTendency.pairs.isSaturated(atWidth: 40))
        XCTAssertFalse(RangeTendency.pairs.isSaturated(atWidth: 8))
    }

    /// The whole reason a tendency re-weights before the cut instead of adding cells
    /// after it: the result stays a coherent top-N%, never a shape with holes.
    func testShapedRangesHaveNoHoles() {
        let r = HandRange.shaped(width: 25, tendencies: [.suited, .pairs])
        // Every included class must outrank every excluded one under the same
        // weighting, which is exactly what "no holes" means here.
        let included = Set(r.classes)
        func weighted(_ h: HandClass) -> Double {
            Chen.score(h)
                + ([RangeTendency.suited, .pairs].filter { $0.matches(h) })
                    .reduce(0) { $0 + $1.bonus }
        }
        let worstIn = r.classes.map(weighted).min() ?? 0
        let bestOut = HandClass.all.filter { !included.contains($0) }.map(weighted).max() ?? 0
        XCTAssertGreaterThanOrEqual(worstIn, bestOut - 0.001,
                                    "an excluded class outranks an included one")
    }
}

final class JaccardTests: XCTestCase {
    private func cls(_ s: String) -> HandClass { HandClass.all.first { $0.description == s }! }

    func testIdenticalRangesScoreOne() {
        let r = HandRange.shaped(width: 22)
        XCTAssertEqual(r.jaccard(r), 1, accuracy: 1e-9)
    }

    func testDisjointRangesScoreZero() {
        XCTAssertEqual(HandRange([cls("AA")]).jaccard(HandRange([cls("72o")])), 0)
    }

    func testTwoEmptyRangesAreIdentical() {
        XCTAssertEqual(HandRange().jaccard(HandRange()), 1)
        XCTAssertEqual(HandRange().jaccard(HandRange([cls("AA")])), 0)
    }

    /// Combo-weighted, not class-weighted. AA is 6 combos and AKo is 12, so an overlap
    /// of one pair against a union including an offsuit class is 6/18, never 1/2.
    func testOverlapIsWeightedByCombosNotByClassCount() {
        let a = HandRange([cls("AA")])
        let b = HandRange([cls("AA"), cls("AKo")])
        XCTAssertEqual(a.jaccard(b), 6.0 / 18.0, accuracy: 1e-9)
    }

    func testOverlapFallsAsRangesDiverge() {
        let truth = HandRange.shaped(width: 20)
        var previous = 1.0
        for w in [20.0, 25, 35, 50, 70] {
            let o = HandRange.shaped(width: w).jaccard(truth)
            XCTAssertLessThanOrEqual(o, previous + 1e-9, "overlap should not rise at \(w)%")
            previous = o
        }
    }
}

final class ArchetypeTests: XCTestCase {
    func testRaisingIsASubsetOfPlaying() {
        for a in Archetype.allCases {
            for seat in RFIChart.seats {
                let raise = Set(a.raiseRange(from: seat).classes)
                let play = Set(a.playRange(from: seat).classes)
                XCTAssertTrue(raise.isSubset(of: play), "\(a.name) at \(seat.rawValue)")
            }
        }
    }

    func testCallRangeIsExactlyWhatIsPlayedButNotRaised() {
        for a in Archetype.allCases {
            let seat = Position.co
            let call = Set(a.callRange(from: seat).classes)
            let raise = Set(a.raiseRange(from: seat).classes)
            XCTAssertTrue(call.isDisjoint(with: raise), "\(a.name) raises and calls the same hand")
            XCTAssertEqual(call.union(raise), Set(a.playRange(from: seat).classes), a.name)
        }
    }

    /// The seat factor is normalised, so averaging the seats must return the published
    /// statistic. Otherwise the number in decisions.md would not describe the player
    /// the app actually deals.
    func testAveragingSeatsReturnsTheDeclaredStatistics() {
        for a in Archetype.allCases {
            let meanVpip = RFIChart.seats
                .map { a.playRange(from: $0).percent }.reduce(0, +) / Double(RFIChart.seats.count)
            XCTAssertEqual(meanVpip, a.vpip, accuracy: 3.0, "\(a.name) VPIP")
            let meanPfr = RFIChart.seats
                .map { a.raiseRange(from: $0).percent }.reduce(0, +) / Double(RFIChart.seats.count)
            XCTAssertEqual(meanPfr, a.pfr, accuracy: 3.0, "\(a.name) PFR")
        }
    }

    /// The Station has to be separable from a TAG by *shape*, not just by width — its
    /// whole character is the VPIP−PFR gap. If its call range were not far wider than
    /// its raise range, the archetype would be modelling nothing.
    func testTheStationIsPassiveNotMerelyLoose() {
        let seat = Position.co
        let station = Archetype.station
        XCTAssertGreaterThan(station.callRange(from: seat).percent,
                             station.raiseRange(from: seat).percent * 2.5)
        XCTAssertGreaterThan(station.passiveGap, Archetype.tag.passiveGap * 3)
        // A maniac is the opposite: it raises nearly everything it plays.
        XCTAssertGreaterThan(Archetype.maniac.raiseRange(from: seat).percent,
                             Archetype.maniac.callRange(from: seat).percent)
    }

    func testWidthOrdersAsTheArchetypesDo() {
        let seat = Position.co
        let widths = [Archetype.nit, .tag, .lag, .station, .maniac]
            .map { $0.playRange(from: seat).percent }
        XCTAssertEqual(widths, widths.sorted(), "VPIP order must survive derivation")
    }

    func testLatePositionOpensWiderThanEarly() {
        for a in Archetype.allCases {
            XCTAssertGreaterThan(a.playRange(from: .btn).percent,
                                 a.playRange(from: .utg).percent, a.name)
        }
    }
}

final class RangeReadDrillTests: XCTestCase {
    func testGeneratorIsDeterministicAndCoherent() {
        XCTAssertEqual(RangeReadSpotGenerator.spot(baseSeed: 5, index: 8),
                       RangeReadSpotGenerator.spot(baseSeed: 5, index: 8))
        for i in 0..<300 {
            let s = RangeReadSpotGenerator.spot(baseSeed: 5, index: i)
            XCTAssertFalse(s.trueRange.isEmpty, "graded against an empty range")
            XCTAssertNotEqual(s.seat, .bb)
            if case let .called(seat, opener) = s.action {
                XCTAssertGreaterThan(opener.playersBehind(preflop: true),
                                     seat.playersBehind(preflop: true),
                                     "the opener must act before the caller")
            }
            XCTAssertFalse(s.actionLines.isEmpty)
        }
    }

    func testTheFirstExposuresNameTheOpponent() {
        for i in 0..<3 {
            XCTAssertTrue(RangeReadSpotGenerator.spot(baseSeed: 5, index: i).archetypeShown)
        }
    }

    func testAPerfectReadScoresSpotOn() {
        let spot = RangeReadSpot(archetype: .tag, action: .opened(.co), archetypeShown: true)
        let truth = spot.trueRange
        let estimate = RangeEstimate(width: truth.percent)
        XCTAssertEqual(gradeRangeRead(estimate: estimate, spot: spot).band, .spotOn)
    }

    func testAWildlyWrongReadMissesAndSaysWhichWay() {
        let spot = RangeReadSpot(archetype: .nit, action: .opened(.utg), archetypeShown: true)
        let tooWide = gradeRangeRead(estimate: RangeEstimate(width: 70), spot: spot)
        XCTAssertEqual(tooWide.band, .off)
        XCTAssertTrue(tooWide.whyText.contains("너무 넓게"), tooWide.whyText)

        let station = RangeReadSpot(archetype: .station, action: .called(seat: .co, opener: .utg),
                                    archetypeShown: true)
        let tooTight = gradeRangeRead(estimate: RangeEstimate(width: 4), spot: station)
        XCTAssertEqual(tooTight.band, .off)
        XCTAssertTrue(tooTight.whyText.contains("너무 좁게"), tooTight.whyText)
    }

    /// Right width, wrong shape must be diagnosed as shape rather than as width.
    func testRightWidthWrongShapeIsNamedAsShape() {
        let spot = RangeReadSpot(archetype: .tag, action: .opened(.co), archetypeShown: true)
        let width = spot.trueRange.percent
        let skewed = RangeEstimate(width: width, tendencies: [.offsuitBroadway, .connectors])
        let why = gradeRangeRead(estimate: skewed, spot: spot).whyText
        XCTAssertFalse(why.contains("너무 넓게"), why)
        XCTAssertFalse(why.contains("너무 좁게"), why)
    }

    func testEveryGeneratedSpotIsGradableWithoutCrashing() {
        for i in 0..<200 {
            let s = RangeReadSpotGenerator.spot(baseSeed: 11, index: i)
            for w in [8.0, 25, 55] {
                let r = gradeRangeRead(estimate: RangeEstimate(width: w, tendencies: [.suited]),
                                       spot: s)
                XCTAssertTrue((0...1).contains(r.overlap))
                XCTAssertFalse(r.whyText.contains("nil"))
            }
        }
    }
}

final class RangeReadCurriculumTests: XCTestCase {
    func testUnitFourTeachesRangeReadAndItsBossReachesBack() {
        // By id, not by position — `units.last` meant u4 until R4-S1 appended u5.
        let u4 = Curriculum.units.first { $0.id == "u4" }!
        XCTAssertEqual(Curriculum.taughtConcept(of: u4.nodes[0]), .rangeRead)
        guard case let .boss(_, mixes) = u4.nodes.last?.kind else {
            return XCTFail("u4 must end in a boss")
        }
        // The point of the boss is that a read is where the earlier units finally get
        // used at once, so it has to draw from more than its own unit.
        XCTAssertTrue(mixes.contains(.rangeRead))
        XCTAssertFalse(Set(mixes).intersection([.rfi, .rangeNotation, .combos, .position])
                        .isEmpty)
    }

    /// Every concept must be reachable, or a drill ships with no way to meet it.
    func testEveryConceptWithANodeIsReachableFromThePath() {
        let onPath = Set(Curriculum.allNodes.flatMap(Curriculum.concepts(of:)))
        XCTAssertTrue(onPath.contains(.rangeRead))
        // mdf is the documented exception (Concept.swift): shipped drill, no R1 node.
        XCTAssertEqual(Set(Concept.allCases).subtracting(onPath), [.mdf])
    }
}

final class RangeReadBeatTests: XCTestCase {
    func testTheScriptDerivesTheAnswerRatherThanAnnouncingIt() {
        let spot = RangeReadSpot(archetype: .station, action: .called(seat: .co, opener: .utg),
                                 archetypeShown: true)
        let beats = BeatScript.rangeRead(spot)
        // VPIP and PFR must both be printed before the grid appears, or the range is
        // a picture handed over rather than a number the user could have derived.
        let statsBeat = beats.first { $0.value?.contains("VPIP") == true }
        XCTAssertNotNil(statsBeat)
        let gridIndex = beats.firstIndex { if case .rangeGrid = $0.focus { return true }
                                           else { return false } }
        XCTAssertNotNil(gridIndex)
        XCTAssertLessThan(beats.firstIndex { $0.value?.contains("VPIP") == true }!, gridIndex!)
    }

    func testEveryGeneratedSpotProducesACompleteScript() {
        for i in 0..<200 {
            let beats = BeatScript.rangeRead(RangeReadSpotGenerator.spot(baseSeed: 3, index: i))
            XCTAssertGreaterThanOrEqual(beats.count, 5)
            for b in beats {
                XCTAssertFalse(b.caption.isEmpty)
                XCTAssertFalse(b.detail?.contains("nil") ?? false, b.detail ?? "")
                XCTAssertFalse(b.value?.isEmpty ?? false)
            }
            // The last beat is the shape, so it must be showing the grid.
            guard case .rangeGrid = beats.last!.focus else {
                return XCTFail("script \(i) ends without showing the range")
            }
        }
    }
}

final class BoardDrillTests: XCTestCase {
    func testHitFrequencyGeneratorIsDeterministicAndCoherent() {
        XCTAssertEqual(HitFrequencySpotGenerator.spot(baseSeed: 7, index: 3),
                       HitFrequencySpotGenerator.spot(baseSeed: 7, index: 3))
        for i in 0..<120 {
            let s = HitFrequencySpotGenerator.spot(baseSeed: 7, index: i)
            XCTAssertEqual(s.board.count, 3)
            XCTAssertEqual(Set(s.board).count, 3, "a board dealt the same card twice")
            XCTAssertNotEqual(s.seat, .bb, "the big blind never opens")
            XCTAssertTrue((0...100).contains(s.pairOrBetterPct))
            XCTAssertGreaterThan(s.distribution.liveCombos, 0)
        }
    }

    /// The graded number must be pair-or-better, never the looser hit rate that counts
    /// draws — those are different questions and the spec picks one (§1).
    func testHitFrequencyGradesPairOrBetterNotHitRate() {
        let s = HitFrequencySpot(seat: .utg, board: Card.parse("Ah9d3c")!)
        XCTAssertEqual(s.pairOrBetterPct, s.distribution.pairOrBetter * 100, accuracy: 1e-9)
        XCTAssertLessThan(s.distribution.pairOrBetter, s.distribution.hitRate,
                          "draws must not be counted as made hands")
    }

    func testRangeAdvantageCallerAlwaysActsAfterTheOpener() {
        for i in 0..<120 {
            let s = RangeAdvantageSpotGenerator.spot(baseSeed: 11, index: i)
            XCTAssertLessThan(s.callerSeat.playersBehind(preflop: true),
                              s.openerSeat.playersBehind(preflop: true),
                              "the caller must act after the opener")
            XCTAssertFalse(s.openerRange.isEmpty)
            XCTAssertFalse(s.callerRange.isEmpty)
        }
    }

    /// A tight opener on an ace-high board is the textbook range-advantage case; if the
    /// number did not show it, it would be decorative.
    func testATightOpenerIsAheadOnAnAceHighBoard() {
        let s = RangeAdvantageSpot(openerSeat: .utg, callerSeat: .btn, caller: .station,
                                   board: Card.parse("AhKd7c")!)
        XCTAssertGreaterThan(s.openerEquityPct, 55, "UTG should own an A-K-high flop")
    }

    /// Four spots, not forty: each `gradeRangeAdvantage` runs a 20,000-sample Monte
    /// Carlo, which is ~6s under a debug build. Breadth here buys nothing the engine's
    /// own property tests do not already cover.
    func testBothGradersProduceAUsableRevealForEverySpot() {
        for i in 0..<4 {
            let h = HitFrequencySpotGenerator.spot(baseSeed: 3, index: i)
            let hr = gradeHitFrequency(estimate: Estimate(point: 40, lo: 30, hi: 50), spot: h)
            XCTAssertFalse(hr.whyText.contains("nil"))
            XCTAssertTrue(hr.whyText.contains("%"))

            let a = RangeAdvantageSpotGenerator.spot(baseSeed: 3, index: i)
            let ar = gradeRangeAdvantage(estimate: Estimate(point: 50, lo: 40, hi: 60), spot: a)
            XCTAssertFalse(ar.whyText.contains("nil"))
            XCTAssertTrue((0...100).contains(ar.correct))
        }
    }

    func testBoardBeatScriptsAreCompleteOnArbitrarySpots() {
        for i in 0..<4 {
            for beats in [BeatScript.hitFrequency(
                              HitFrequencySpotGenerator.spot(baseSeed: 5, index: i)),
                          BeatScript.rangeAdvantage(
                              RangeAdvantageSpotGenerator.spot(baseSeed: 5, index: i))] {
                XCTAssertGreaterThanOrEqual(beats.count, 5)
                for b in beats {
                    XCTAssertFalse(b.caption.isEmpty)
                    XCTAssertFalse(b.value?.isEmpty ?? true)
                    XCTAssertFalse(b.detail?.contains("nil") ?? false)
                }
                // The last beat has to be showing the distribution it is talking about.
                guard case .buckets = beats.last!.focus else {
                    return XCTFail("script \(i) ends without showing the breakdown")
                }
            }
        }
    }
}
