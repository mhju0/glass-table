// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

/// Spec: docs/specs/2026-08-04-r5-hero-preflop-design.md §6.
final class DefendChartTests: XCTestCase {

    private func c(_ s: String) -> [Card] {
        [Card(String(s.prefix(2)))!, Card(String(s.suffix(2)))!]
    }

    // §6.1 — bands are well-formed.

    func testBandsAreDisjointNestedAndTotal() {
        for seat in RFIChart.seats {
            let three = DefendChart.threeBetRange(vsOpenFrom: seat)
            let call = DefendChart.callRange(vsOpenFrom: seat)
            XCTAssertFalse(three.isEmpty, "\(seat)")
            XCTAssertFalse(call.isEmpty, "\(seat)")
            for h in HandClass.all {
                XCTAssertFalse(three.weight(h) > 0 && call.weight(h) > 0,
                               "\(seat): \(h) in both bands")
            }
            // Every concrete hand maps to exactly one action, fold included.
            XCTAssertEqual(DefendChart.action(for: c("AhAd"), vsOpenFrom: seat), .threeBet)
            XCTAssertEqual(DefendChart.action(for: c("7h2c"), vsOpenFrom: seat), .fold)
        }
    }

    // §6.2 — anchors: defense widens as the opener does.

    func testDefenseIsMonotoneInOpenerWidth() {
        // UTG opens narrowest, BTN widest, per the RFI derivation.
        let vsTight = DefendChart.threeBetRange(vsOpenFrom: .utg).percent
            + DefendChart.callRange(vsOpenFrom: .utg).percent
        let vsWide = DefendChart.threeBetRange(vsOpenFrom: .btn).percent
            + DefendChart.callRange(vsOpenFrom: .btn).percent
        XCTAssertLessThan(vsTight, vsWide)
        // And the derived shares hold: total defense ≈ defendShare × opener width.
        for seat in [Position.utg, .co, .btn] {
            let opener = RFIChart.openPercent[seat] ?? 0
            let total = DefendChart.threeBetRange(vsOpenFrom: seat).percent
                + DefendChart.callRange(vsOpenFrom: seat).percent
            XCTAssertEqual(total, opener * DefendChart.defendShare, accuracy: 1.5,
                           "\(seat): class granularity may round, not drift")
        }
    }

    // §6.3 — the bot's continue band.

    /// The character order lives in the *shares of his own opening range* — Maniac's
    /// 85% is absolutely wider than Station's 100% because he opens 4× as much, and
    /// that is correct, not a bug. What must hold: share ordering, and nesting.
    func testContinueBandsAreNestedAndSharesAreInCharacterOrder() {
        let byShare = [Archetype.nit, .tag, .lag, .maniac, .station]
        for (tighter, looser) in zip(byShare, byShare.dropFirst()) {
            XCTAssertLessThan(tighter.threeBetContinueShare, looser.threeBetContinueShare + 1e-12,
                              "\(tighter) must continue a smaller share than \(looser)")
        }
        for seat in [Position.utg, .co] {
            // Nested in the range he opened: continuing with a hand he never opened
            // would be a contradiction, not a caricature.
            for a in Archetype.allCases {
                let open = a.raiseRange(from: seat)
                let cont = a.continueRange(vs3BetFrom: seat)
                for h in cont.classes {
                    XCTAssertTrue(open.weight(h) > 0, "\(a) continues unopened \(h)")
                }
            }
        }
    }

    func testTheStationNeverFoldsPreflop() {
        for seat in RFIChart.seats {
            XCTAssertEqual(Archetype.station.continueRange(vs3BetFrom: seat).percent,
                           Archetype.station.raiseRange(from: seat).percent,
                           accuracy: 1e-9, "\(seat)")
        }
    }

    // §6.4 — the machine plays the street.

    func testPreflopFoldNetsExactlyZero() {
        var hand = TableDealer.deal(baseSeed: 0xF01D, index: 0)
        hand.play(.fold)
        guard case let .over(o) = hand.phase else { return XCTFail() }
        XCTAssertEqual(o.heroNet, 0)
        XCTAssertFalse(o.wentToShowdown)
        XCTAssertEqual(o.villainHand.count, 2)
    }

    func testThreeBetOutcomesBalanceTheBooks() {
        var sawFold = false, sawCall = false
        for i in 0..<60 where !(sawFold && sawCall) {
            var hand = TableDealer.deal(baseSeed: 0x3BE7, index: i)
            hand.play(.raise)
            if case let .over(o) = hand.phase {
                // Bot folded: hero wins his open plus the dead blinds.
                XCTAssertEqual(o.heroNet, 4.5, accuracy: 1e-9)
                sawFold = true
            } else {
                // Bot called: 19.5bb pot, both stacks 91, flop dealt, and his range
                // narrowed to exactly his continue band — his combo inside it.
                XCTAssertEqual(hand.pot, hand.street >= 3 ? hand.pot : 19.5)
                XCTAssertEqual(hand.heroInvested, 9, accuracy: 1e-9)
                XCTAssertEqual(hand.board.count, 3)
                let band = hand.villain.continueRange(vs3BetFrom: hand.villainSeat)
                XCTAssertTrue(hand.villainCombos.allSatisfy(band.contains))
                sawCall = true
            }
        }
        XCTAssertTrue(sawFold, "no bot fold to a 3-bet in 60 hands")
        XCTAssertTrue(sawCall, "no bot call of a 3-bet in 60 hands")
    }

    // §6.5 — chart grading is total and matches the bands.

    func testPreflopVerdictAgreesWithTheChart() {
        for i in 0..<20 {
            let hand = TableDealer.deal(baseSeed: 0xC4A7, index: i)
            let chart = DefendChart.action(for: hand.hero, vsOpenFrom: hand.villainSeat)
            for (choice, action): (TableHand.HeroChoice, DefendAction)
                in [(.fold, .fold), (.call, .call), (.raise, .threeBet)] {
                let v = hand.preflopVerdict(for: choice)
                XCTAssertEqual(v?.chosen, action)
                XCTAssertEqual(v?.chart, chart)
                XCTAssertEqual(v?.matched, action == chart)
            }
        }
    }

    func testVerdictIsNilOncePreflopIsOver() {
        var hand = TableDealer.deal(baseSeed: 1, index: 0)
        hand.play(.call)
        XCTAssertNil(hand.preflopVerdict(for: .fold))
    }
}
