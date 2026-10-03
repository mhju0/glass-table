// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Testing
@testable import GlassTableDrills

private func view(hole: [String], board: [String], street: PracticeStreet, pot: Int, toCall: Int,
                  minimumRaiseTo: Int?, roll: UInt64) -> PracticeBotView {
    PracticeBotView(seat: 1, style: .casual, hole: hole, board: board, street: street, pot: pot,
                    toCall: toCall, stack: 40, minimumRaiseTo: minimumRaiseTo,
                    hasRaisedThisStreet: false, streetCommitted: 0, roll: roll)
}

/// Seeded drills pick a random published style; a sixth case there would reshuffle them.
@Test func casualStyleStaysOutOfThePublishedStyles() {
    #expect(Archetype.allCases == [.nit, .tag, .lag, .station, .maniac])
    #expect(Archetype(rawValue: "casual") == .casual)
}

@Test func casualBotSometimesBluffsWhenCheckedToButMostlyChecks() {
    // 7-2 on an A-K-9 board: nothing, and no draw.
    let actions = (0..<1000).map {
        PracticeBotPolicy.action(for: view(hole: ["7c", "2d"], board: ["As", "Kh", "9s"], street: .flop,
                                           pot: 12, toCall: 0, minimumRaiseTo: 2, roll: UInt64($0)))
    }
    let bluffs = actions.filter { $0 != .check }
    #expect(bluffs.count == 150)
    #expect(bluffs.allSatisfy { $0 == .raise(to: 6) }, "A bluff is half the pot, not the minimum")
}

@Test func casualBotBetsHalfThePotWithTopPairAndNeverMoreThanItsStack() {
    let top = view(hole: ["Ac", "Qd"], board: ["As", "Kh", "9s"], street: .flop,
                   pot: 20, toCall: 0, minimumRaiseTo: 2, roll: 999)
    #expect(PracticeBotPolicy.action(for: top) == .raise(to: 10))
    let deep = view(hole: ["Ac", "Qd"], board: ["As", "Kh", "9s"], street: .flop,
                    pot: 200, toCall: 0, minimumRaiseTo: 2, roll: 999)
    #expect(PracticeBotPolicy.action(for: deep) == .raise(to: 40))
}

@Test func casualBotFoldsNothingHandsToARealBetAndCallsWithAPair() {
    let air = view(hole: ["7c", "2d"], board: ["As", "Kh", "9s"], street: .flop,
                   pot: 12, toCall: 6, minimumRaiseTo: 12, roll: 5)
    #expect(PracticeBotPolicy.action(for: air) == .fold, "A half-pot bet is too dear for a curious call")
    let pair = view(hole: ["9c", "2d"], board: ["As", "Kh", "9s"], street: .flop,
                    pot: 12, toCall: 6, minimumRaiseTo: 12, roll: 5)
    #expect(PracticeBotPolicy.action(for: pair) == .call)
}

@Test func casualTableReplaysIdenticallyAndStaysValid() throws {
    func play(seed: UInt64) throws -> PracticeTableState {
        var table = PracticeTableState(seed: seed, styles: [.casual, .casual, .casual],
                                       startingStack: 40, handLimit: 10)
        var turn = 0
        for hand in 0..<10 {
            try table.advanceBots()
            while table.street != .finished {
                try table.apply(table.legalActions.contains(.call) ? .call : .check, actionID: "a\(turn)")
                try table.advanceBots()
                turn += 1
            }
            try table.validate()
            if table.isGameOver { break }
            try table.nextHand(handID: "hand-\(hand + 1)")
        }
        return table
    }
    var sized = false
    for seed in 0..<40 as Range<UInt64> {
        let first = try play(seed: seed)
        #expect(try play(seed: seed) == first)
        let decoded = try JSONDecoder().decode(PracticeTableState.self, from: JSONEncoder().encode(first))
        try decoded.validate()
        sized = sized || first.events.contains { $0.seat != 0 && $0.label == "bet" && $0.chips > 2 }
    }
    #expect(sized, "Across forty games the casual players bet more than the minimum at least once")
}
