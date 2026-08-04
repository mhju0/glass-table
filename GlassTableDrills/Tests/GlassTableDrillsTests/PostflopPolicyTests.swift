// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// Spec: docs/specs/2026-08-04-r4-s3-postflop-policy-design.md §7.
final class PostflopPolicyTests: XCTestCase {

    // §7.1 — the table is total and disjoint.

    func testFacingABetEveryBucketGetsExactlyOneResponse() {
        for a in Archetype.allCases {
            let p = a.postflop
            XCTAssertTrue(p.calls.isDisjoint(with: p.raises),
                          "\(a): a bucket cannot both call and raise")
            for b in MadeHand.allCases {
                // response() is total by construction; this pins that the three cases
                // partition, i.e. nothing double-counts.
                let r = p.response(toBetWith: b)
                switch r {
                case .raise: XCTAssertTrue(p.raises.contains(b))
                case .call: XCTAssertTrue(p.calls.contains(b))
                case .fold:
                    XCTAssertFalse(p.calls.contains(b))
                    XCTAssertFalse(p.raises.contains(b))
                }
            }
        }
    }

    func testActionBucketsPartitionTheFiveBuckets() {
        for a in Archetype.allCases {
            let p = a.postflop
            let bet = p.buckets(after: .bet), check = p.buckets(after: .check)
            XCTAssertTrue(bet.isDisjoint(with: check), "\(a)")
            XCTAssertEqual(bet.union(check), Set(MadeHand.allCases), "\(a)")
        }
    }

    // §7.2 — the caricatures are pinned, so a future edit is deliberate.

    func testTheCaricatureInvariants() {
        // Station never raises; the VPIP–PFR gap carried postflop.
        XCTAssertTrue(Archetype.station.postflop.raises.isEmpty)
        // Maniac never folds: everything calls or raises.
        let m = Archetype.maniac.postflop
        XCTAssertEqual(m.calls.union(m.raises), Set(MadeHand.allCases))
        // Nit's raise is 투페어 이상, and only that.
        XCTAssertEqual(Archetype.nit.postflop.raises, [.strong])
        // LAG bets air but checks weak pairs — the counterintuitive row.
        let lag = Archetype.lag.postflop
        XCTAssertTrue(lag.bets.contains(.air))
        XCTAssertFalse(lag.bets.contains(.weakPair))
    }

    func testAggressiveBetRowsWidenMonotonically() {
        let nit = Archetype.nit.postflop.bets
        let tag = Archetype.tag.postflop.bets
        let lag = Archetype.lag.postflop.bets
        let maniac = Archetype.maniac.postflop.bets
        XCTAssertTrue(nit.isSubset(of: tag))
        XCTAssertTrue(tag.isSubset(of: lag))
        XCTAssertTrue(lag.isSubset(of: maniac))
    }

    func testBetSizesComeFromTheSizingMenu() {
        // decisions.md §A: 33/50/75/100/150% pot.
        let menu: Set<Double> = [0.33, 0.5, 0.75, 1.0, 1.5]
        for a in Archetype.allCases {
            XCTAssertTrue(menu.contains(a.postflop.betFraction), "\(a)")
        }
    }

    // §7.3 — narrowing partitions the live range.

    func testNarrowingPartitionsTheLiveRange() {
        let board = [Card(rank: 12, suit: 0), Card(rank: 8, suit: 1), Card(rank: 3, suit: 2)]
        for a in Archetype.allCases {
            let range = a.raiseRange(from: .co)
            let live = range.combos(removing: board).count
            let bet = a.postflop.narrowed(range, board: board, after: .bet)
            let check = a.postflop.narrowed(range, board: board, after: .check)
            XCTAssertEqual(bet.combos + check.combos, live, "\(a)")
            XCTAssertEqual(bet.shareOfRange + check.shareOfRange, 1, accuracy: 1e-12, "\(a)")
            for r in [bet, check] where r.combos > 0 {
                XCTAssertEqual(r.distribution.shares.values.reduce(0, +), 1,
                               accuracy: 1e-9, "\(a)")
                XCTAssertEqual(r.distribution.liveCombos, r.combos, "\(a)")
            }
        }
    }

    // §7.4 — known answers.

    func testTheCertainTellsAreCertain() {
        let board = [Card(rank: 12, suit: 0), Card(rank: 8, suit: 1), Card(rank: 3, suit: 2)]
        // Nit-벳: every betting combo is 투페어 이상 → pair-or-better is exactly 1.
        let nitBet = Archetype.nit.postflop.narrowed(
            Archetype.nit.raiseRange(from: .co), board: board, after: .bet)
        if nitBet.combos > 0 {
            XCTAssertEqual(nitBet.distribution.pairOrBetter, 1, accuracy: 1e-12)
        }
        // Maniac-벳 is the whole range: the narrowed distribution IS the full one.
        let range = Archetype.maniac.raiseRange(from: .co)
        let maniacBet = Archetype.maniac.postflop.narrowed(range, board: board, after: .bet)
        XCTAssertEqual(maniacBet.distribution, rangeOnBoard(range, board: board))
        XCTAssertEqual(maniacBet.shareOfRange, 1)
        // LAG-체크 is exactly 약한 페어.
        let lagCheck = Archetype.lag.postflop.narrowed(
            Archetype.lag.raiseRange(from: .co), board: board, after: .check)
        if lagCheck.combos > 0 {
            XCTAssertEqual(lagCheck.distribution.share(.weakPair), 1, accuracy: 1e-12)
        }
    }
}
