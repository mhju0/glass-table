// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine
import Testing
@testable import GlassTableDrills

/// The free table used to rebuild these reasons from the public event log. This copy of
/// that view logic is the oracle: the table's own answer must agree with it at every
/// learner decision.
private func eventLogReason(_ table: PracticeTableState) -> String {
    let frame = table.frame(after: table.replaySteps.count)
    let publicBet = max(frame.street == .preflop ? 2 : 0, frame.streetCommitted.max() ?? 0)
    let owed = max(0, publicBet - frame.streetCommitted[0])
    let canRaise = table.legalActions.contains { if case .raise = $0 { true } else { false } }
    if frame.stacks[0] <= owed { return name(.noChipsBeyondCall) }
    let answerable = frame.stacks.indices.contains { $0 != 0 && !frame.folded[$0] && frame.stacks[$0] > 0 }
    if !answerable { return name(.noOpponentCanAnswer) }
    var committed = Array(repeating: 0, count: table.seatCount)
    var currentBet = frame.street == .preflop ? 2 : 0
    var fullRaise = 2
    var heroFacing: Int?
    var shortAfterHero = false
    for event in table.events where event.street == frame.street {
        committed[event.seat] += event.chips
        if event.label == "raise" || event.label == "bet" {
            let increment = committed[event.seat] - currentBet
            if increment >= fullRaise {
                fullRaise = increment
                shortAfterHero = false
            } else if event.seat != 0, heroFacing != nil, frame.stacks[event.seat] == 0 {
                shortAfterHero = true
            }
            currentBet = committed[event.seat]
        }
        if event.seat == 0, event.action != nil { heroFacing = currentBet }
    }
    if shortAfterHero && heroFacing.map({ currentBet - $0 < fullRaise }) == true { return name(.shortAllInDidNotReopen) }
    return canRaise ? name(nil) : "unexplained"
}

private func name(_ block: PracticeRaiseBlock?) -> String { block.map { "\($0)" } ?? "open" }

@Test func raiseBlockMatchesTheEventLogAtEveryLearnerDecision() throws {
    var seen: [String: Int] = [:]
    for seed in 0..<400 {
        var rng = SplitMix64(seed: UInt64(seed))
        let stacks = (0..<4).map { _ in Int.random(in: 3...40, using: &rng) }
        var table = PracticeTableState.fixture(seed: UInt64(seed), stacks: stacks, dealer: seed % 4)
        var step = 0
        while table.street != .finished {
            if table.currentSeat == 0 {
                let expected = eventLogReason(table)
                #expect(expected != "unexplained", "seed \(seed) step \(step)")
                #expect(name(table.raiseBlock) == expected, "seed \(seed) step \(step)")
                seen[expected, default: 0] += 1
            }
            var action = table.legalActions.randomElement(using: &rng)!
            if case let .raise(minimum) = action, let seat = table.currentSeat {
                let most = table.seats[seat].streetCommitted + table.seats[seat].stack
                action = .raise(to: Bool.random(using: &rng) ? most : Int.random(in: minimum...max(minimum, most), using: &rng))
            }
            try table.apply(action, actionID: "s\(step)")
            step += 1
        }
    }
    // Every reason, and the open case, actually occurred.
    for reason in [nil, .noChipsBeyondCall, .noOpponentCanAnswer, .shortAllInDidNotReopen] as [PracticeRaiseBlock?] {
        #expect(seen[name(reason), default: 0] > 0, "\(name(reason)) never occurred")
    }
}

@Test func shortAllInDoesNotReopenRaisingForTheLearner() throws {
    // Seat 2 is the small blind with 7 chips. The learner opens to 6, seat 2 shoves to 7
    // (one chip more, short of a full raise) and seat 3 calls, so the learner may only call.
    var table = PracticeTableState.fixture(seed: 3, stacks: [100, 100, 7, 100], dealer: 1)
    #expect(table.currentSeat == 0)
    try table.apply(.raise(to: 6), actionID: "open")
    try table.apply(.fold, actionID: "fold")
    try table.apply(.raise(to: 7), actionID: "shove")
    try table.apply(.call, actionID: "call")
    #expect(table.currentSeat == 0)
    #expect(table.raiseBlock == .shortAllInDidNotReopen)
    #expect(!table.legalActions.contains { if case .raise = $0 { true } else { false } })
}
