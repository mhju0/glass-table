// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Testing
@testable import GlassTableDrills

/// Plays hands to the end, stopping at every learner decision, and checks the replay
/// against the real table at each stop.
@Test(arguments: [1, 2, 3])
func replayEndsExactlyWhereTheTableIs(computers: Int) throws {
    let styles = Array([Archetype.nit, .station, .lag].prefix(computers))
    for seed in 0..<25 {
        var table = PracticeTableState(seed: UInt64(seed), styles: styles)
        var turns = 0
        for hand in 0..<3 {
            while turns < 300 {
                try table.advanceBots()
                let steps = table.replaySteps
                let frame = table.frame(after: steps.count)
                #expect(frame.boardCount == (table.review?.board.count ?? table.visibleBoard.count))
                if let review = table.review {
                    #expect(frame.settled)
                    #expect(frame.stacks == review.endingStacks)
                    #expect(frame.committed == review.contributions)
                    break
                }
                #expect(frame.stacks == table.seats.map(\.stack))
                #expect(frame.committed == table.seats.map(\.committed))
                #expect(frame.streetCommitted == table.seats.map(\.streetCommitted))
                #expect(frame.folded == table.seats.map(\.folded))
                #expect(frame.pot == table.pot)
                let choice = table.legalActions.contains(.call) ? PracticeAction.call : .check
                try table.apply(choice, actionID: "learner-\(turns)")
                turns += 1
            }
            try table.nextHand(handID: "hand-\(seed)-\(hand + 1)")
        }
    }
}

/// Shared cards arrive before the first action on their street, never with the last
/// action of the one before.
@Test func dealStepsSitBetweenStreets() throws {
    for seed in 0..<40 {
        var table = PracticeTableState(seed: UInt64(seed), styles: [.station, .station])
        var turns = 0
        while table.street != .finished, turns < 60 {
            try table.advanceBots()
            if table.street == .finished { break }
            try table.apply(table.legalActions.contains(.call) ? .call : .check, actionID: "l-\(turns)")
            turns += 1
        }
        var street = PracticeStreet.preflop
        for step in table.replaySteps {
            switch step {
            case let .action(index):
                #expect(table.events[index].street == street)
            case let .deal(next):
                street = next
            case .settle:
                break
            }
        }
    }
}

/// The frame halfway through shows the earlier seats' chips and nothing after.
@Test func aPartialFrameOnlyCountsTheShownSteps() {
    let table = PracticeTableState(seed: 7, styles: [.tag, .station, .lag])
    let blindsOnly = table.frame(after: 2)
    #expect(blindsOnly.pot == 3)
    #expect(blindsOnly.boardCount == 0)
    #expect(table.frame(after: 0).pot == 0)
}

/// The free table names one style per computer. The old loop read three styles and
/// crashed on two- and three-player tables.
@Test(arguments: [1, 2, 3])
func computerSeatsMatchTheTableSize(computers: Int) {
    let styles = Array([Archetype.nit, .station, .lag].prefix(computers))
    let table = PracticeTableState(seed: 1, styles: styles)
    #expect(table.computerSeats.map(\.seat) == Array(1..<table.seatCount))
    #expect(table.computerSeats.map(\.style) == styles)
}

/// A hint states facts about the spot and never exists when it isn't the learner's turn.
@Test func decisionFactsDescribeTheSpotOnly() throws {
    var found = false
    for seed in 0..<40 {
        var table = PracticeTableState(seed: UInt64(seed), styles: [.tag])
        try table.advanceBots()
        guard table.currentSeat == 0, let facts = PracticeDecisionFacts(table: table) else { continue }
        found = true
        #expect(facts.startingHand != nil)
        #expect((1...100).contains(facts.startingHandTopPercent ?? 0))
        #expect(facts.madeHand == nil)
        if facts.toCall > 0 {
            let expected = Int((Double(facts.toCall) / Double(facts.pot + facts.toCall) * 100).rounded())
            #expect(facts.requiredEquityPercent == expected)
        } else {
            #expect(facts.requiredEquityPercent == nil)
        }
    }
    #expect(found)
}

@Test func decisionFactsExcludeUnmatchedOpponentChips() throws {
    var table = PracticeTableState.fixture(seed: 31, stacks: [9, 3, 6, 15])
    try table.apply(.raise(to: 4), actionID: "raise4")
    try table.apply(.call, actionID: "hero4")
    try table.apply(.fold, actionID: "sb-fold")
    try table.apply(.fold, actionID: "bb-fold")
    try table.apply(.raise(to: 11), actionID: "bet11")
    let facts = try #require(PracticeDecisionFacts(table: table))
    #expect(facts.pot == 22)
    #expect(facts.toCall == 5)
    #expect(facts.requiredEquityPercent == 24)
    #expect(facts.madeHand != nil)
    try table.apply(.call, actionID: "hero-allin")
    #expect(table.review?.refunds[3] == 6)
    #expect(table.review?.pots.reduce(0) { $0 + $1.amount } == 21)
}

@Test func decisionFactsSubtractNewShortBlindRefund() throws {
    var table = PracticeTableState.fixture(seed: 23, stacks: [100, 1, 1, 1], dealer: 0)
    try table.apply(.call, actionID: "last-opponent-call")
    let facts = try #require(PracticeDecisionFacts(table: table))
    #expect(facts.pot == 3)
    #expect(facts.toCall == 2)
    #expect(facts.requiredEquityPercent == 25)
    try table.apply(.call, actionID: "hero-call")
    #expect(table.review?.refunds[0] == 1)
    #expect(table.review?.pots.reduce(0) { $0 + $1.amount } == 4)
}

@Test func publicFactsStayAtTheirRenderedPrefix() throws {
    var table = PracticeTableState(seed: 97, styles: [.station])
    try table.advanceBots()
    let count = table.replaySteps.count
    let board = table.visibleBoard
    let before = PracticeDecisionFacts(frame: table.frame(after: count),
                                       learnerHole: table.learnerHole, visibleBoard: board)
    for index in 0..<30 where table.review == nil {
        try table.apply(table.legalActions.contains(.call) ? .call : .check, actionID: "hero-\(index)")
        try table.advanceBots()
    }
    let after = PracticeDecisionFacts(frame: table.frame(after: count),
                                      learnerHole: table.learnerHole,
                                      visibleBoard: table.review?.board ?? table.visibleBoard)
    #expect(before == after)
}

@Test func publicFactsSafelyEvaluateFlopAndTurn() {
    let table = PracticeTableState(seed: 1, styles: [.station])
    let hole = table.learnerHole
    var frame = table.frame(after: 2)
    for board in [["2c", "7d", "Jh"], ["2c", "7d", "Jh", "9s"]] {
        frame.boardCount = board.count
        frame.street = board.count == 3 ? .flop : .turn
        #expect(PracticeDecisionFacts(frame: frame, learnerHole: ["As", "Kd"], visibleBoard: board)?.madeHand != nil)
    }
    frame.folded[0] = true
    #expect(PracticeDecisionFacts(frame: frame, learnerHole: hole, visibleBoard: [])?.toCall == 0)
    #expect(PracticeDecisionFacts(frame: frame, learnerHole: hole, visibleBoard: [])?.requiredEquityPercent == nil)
}
