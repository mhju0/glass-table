// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Testing
@testable import GlassTableDrills

@Test func practiceTableResumeAndConservation() throws {
    for seed in 0..<40 {
        var table = PracticeTableState(seed: UInt64(seed))
        let initial = table
        try table.validate()
        let encoded = try JSONEncoder().encode(table)
        #expect(try JSONDecoder().decode(PracticeTableState.self, from: encoded) == initial)
        var turns = 0
        while table.street != .finished && turns < 100 {
            try table.advanceBots()
            try table.validate()
            if table.street == .finished { break }
            let choice = table.legalActions.contains(.call) ? PracticeAction.call : .check
            let id = "learner-\(turns)"
            try table.apply(choice, actionID: id)
            try table.validate()
            let once = table
            try table.apply(choice, actionID: id)
            #expect(table == once)
            turns += 1
        }
        #expect(table.street == .finished)
        #expect(turns < 100)
        let review = try #require(table.review)
        try table.validate()
        let paidOut: Int = review.payouts.reduce(0, +)
        let refunded: Int = review.refunds.reduce(0, +)
        let contributed: Int = review.contributions.reduce(0, +)
        #expect(paidOut + refunded == contributed)
        #expect(table.seats.map(\.stack).reduce(0, +) == 400)
        let awarded = review.pots.map(\.amount).reduce(0, +)
        let returned = review.refunds.reduce(0, +)
        let invested = review.contributions.reduce(0, +)
        #expect(awarded + returned == invested)
        let settled = try JSONDecoder().decode(PracticeTableState.self,
                                               from: JSONEncoder().encode(table))
        #expect(settled == table)
        try table.nextHand(handID: "next-\(seed)")
        try table.validate()
        #expect(table.dealer == 1)
        #expect(table.handNumber == 1)
        #expect(table.street == .preflop)
    }
}

@Test func practiceTableRejectsIllegalRaiseWithoutChangingState() throws {
    var table = PracticeTableState(seed: 21)
    let original = table
    #expect(throws: PracticeTableError.illegalAction) {
        try table.apply(.raise(to: 3), actionID: "bad")
    }
    #expect(table == original)
    #expect(throws: PracticeTableError.illegalAction) {
        try table.apply(.check, actionID: "also-bad")
    }
    #expect(table == original)
}

@Test func observedStyleRequiresEvidenceAndSeparatesPolicyVersions() {
    let few = (0..<99).map { i in
        PracticeHandObservation(handID: "h\(i)", day: "2026-09-2\(i % 5)",
                                voluntarilyEntered: true, raisedPreflop: true)
    }
    let report = PracticeStyleAnalysis.report(few, asOf: "2026-09-25")
    #expect(report.style == nil)
    #expect(report.hands == 99)
    let old = PracticeHandObservation(handID: "old", day: "2026-09-22", policyVersion: 0,
                                      voluntarilyEntered: true, raisedPreflop: true)
    let mixed = PracticeStyleAnalysis.report(few + [old], asOf: "2026-09-25")
    #expect(mixed.hands == 99)
}

@Test func cumulativeShortAllInsReopenOnlyAfterFullIncrement() throws {
    var table = PracticeTableState.fixture(seed: 7, stacks: [50, 5, 6, 30])
    #expect(table.currentSeat == 3)
    try table.apply(.raise(to: 4), actionID: "open")
    try table.apply(.call, actionID: "first-call")
    #expect(table.currentSeat == 1)
    try table.apply(.raise(to: 5), actionID: "short-one")
    #expect(table.currentSeat == 2)
    try table.apply(.raise(to: 6), actionID: "short-two")
    #expect(table.currentSeat == 3)
    #expect(table.legalActions.contains(.raise(to: 8)))
    try table.apply(.call, actionID: "opener-calls")
    #expect(table.currentSeat == 0)
    #expect(table.legalActions.contains(.raise(to: 8)))
}

@Test func oneShortAllInDoesNotReopenForPriorRaiser() throws {
    var table = PracticeTableState.fixture(seed: 7, stacks: [50, 5, 50, 30])
    try table.apply(.raise(to: 4), actionID: "open")
    try table.apply(.call, actionID: "first-call")
    try table.apply(.raise(to: 5), actionID: "short")
    try table.apply(.call, actionID: "big-blind-calls")
    #expect(table.currentSeat == 3)
    #expect(!table.legalActions.contains(where: { if case .raise = $0 { return true }; return false }))
}

@Test func sidePotsWithUnequalStacksConserveChips() throws {
    var table = PracticeTableState.fixture(seed: 31, stacks: [9, 3, 6, 15])
    try table.apply(.raise(to: 15), actionID: "utg-all-in")
    try table.apply(.call, actionID: "learner-all-in")
    try table.apply(.call, actionID: "small-all-in")
    try table.apply(.call, actionID: "big-all-in")
    #expect(table.street == .finished)
    let review = try #require(table.review)
    #expect(review.contributions == [9, 3, 6, 15])
    #expect(review.pots.map(\.amount) == [12, 9, 6])
    #expect(review.refunds == [0, 0, 0, 6])
    #expect(review.payouts.reduce(0, +) == 27)
    #expect(table.seats.map(\.stack).reduce(0, +) == 33)
}

@Test func oddChipGoesClockwiseFromDealerAmongTiedEligibleSeats() throws {
    let table = PracticeTableState.settlementFixture(
        contributions: [2, 2, 1, 2], folded: [false, false, true, false],
        holes: [["2d", "3d"], ["4d", "5d"], ["6d", "7d"], ["8d", "9d"]],
        board: ["Ac", "Kc", "Qc", "Jc", "Tc"], dealer: 0)
    let review = try #require(table.review)
    #expect(review.payouts == [2, 3, 0, 2])
    #expect(review.pots.count == 2)
    #expect(review.pots[0].winners == [0, 1, 3])
}

@Test func foldBeforeBoardDoesNotRevealUndealtFutureCards() throws {
    var table = PracticeTableState(seed: 8)
    try table.apply(.fold, actionID: "u-fold")
    // Deal completion is stored for resume, but no future board is public.
    #expect(table.visibleBoard.isEmpty)
    #expect(table.review == nil)
}

@Test func observedStyleClassifiesOnlyWhollySupportedBands() {
    let evidence = (0..<200).map { index in
        PracticeHandObservation(handID: "sample-\(index)", day: "2026-09-2\(index % 5 + 1)",
                                voluntarilyEntered: index < 40,
                                raisedPreflop: index < 36)
    }
    let report = PracticeStyleAnalysis.report(evidence, asOf: "2026-09-25")
    #expect(report.hands == 200)
    #expect(report.days == 5)
    #expect(report.voluntaryEntries == 40)
    #expect(report.preflopRaises == 36)
    #expect(report.style == .selectiveRaiser)
    let expired = PracticeStyleAnalysis.report(evidence, asOf: "2026-11-01")
    #expect(expired.hands == 0)
    #expect(expired.style == nil)
}
