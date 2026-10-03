// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Testing
@testable import GlassTableDrills
import GlassTableEngine

@Test func beginnerChartRaisesTheBestFoldsTheWorstAndKeepsDrawsCheap() {
    typealias Coach = PracticeHandCoach
    #expect(Coach.verdict(action: .raise(to: 6), strength: .premium, toCall: 2, needed: 40, boardCount: 0) == .good)
    #expect(Coach.verdict(action: .fold, strength: .premium, toCall: 2, needed: 40, boardCount: 0) == .risky)
    #expect(Coach.verdict(action: .call, strength: .playable, toCall: 2, needed: 40, boardCount: 0) == .good)
    #expect(Coach.verdict(action: .fold, strength: .playable, toCall: 6, needed: 40, boardCount: 0) == .fine)
    #expect(Coach.verdict(action: .fold, strength: .weak, toCall: 2, needed: 40, boardCount: 0) == .good)
    #expect(Coach.verdict(action: .call, strength: .weak, toCall: 2, needed: 40, boardCount: 0) == .risky)
    #expect(Coach.verdict(action: .call, strength: .weak, toCall: 1, needed: 20, boardCount: 0) == .fine)
    #expect(Coach.verdict(action: .check, strength: .weak, toCall: 0, needed: nil, boardCount: 0) == .good)

    #expect(Coach.verdict(action: .raise(to: 8), strength: .topPair, toCall: 0, needed: nil, boardCount: 3) == .good)
    #expect(Coach.verdict(action: .check, strength: .strong, toCall: 0, needed: nil, boardCount: 3) == .fine)
    #expect(Coach.verdict(action: .fold, strength: .strong, toCall: 4, needed: 20, boardCount: 4) == .risky)
    // The same draw is worth a cheap call and not a dear one, and less with one card to come.
    #expect(Coach.verdict(action: .call, strength: .draw, toCall: 4, needed: 30, boardCount: 3) == .good)
    #expect(Coach.verdict(action: .call, strength: .draw, toCall: 4, needed: 30, boardCount: 4) == .risky)
    #expect(Coach.verdict(action: .call, strength: .weakPair, toCall: 2, needed: 20, boardCount: 3) == .good)
    #expect(Coach.verdict(action: .call, strength: .weakPair, toCall: 9, needed: 33, boardCount: 3) == .risky)
    #expect(Coach.verdict(action: .call, strength: .air, toCall: 2, needed: 20, boardCount: 5) == .risky)
    #expect(Coach.verdict(action: .fold, strength: .air, toCall: 2, needed: 20, boardCount: 5) == .good)
    #expect(Coach.verdict(action: .raise(to: 6), strength: .air, toCall: 0, needed: nil, boardCount: 5) == .fine)
}

@Test func coachRetellsEveryLearnerDecisionFromWhatWasVisibleThen() throws {
    var sawPostflop = false, sawPressure = false
    for seed in 0..<60 as Range<UInt64> {
        var table = PracticeTableState(seed: seed, styles: [.casual, .casual], startingStack: 40, handLimit: 10)
        #expect(PracticeHandCoach.steps(for: table).isEmpty, "Nothing is judged while the hand is live")
        var turn = 0
        try table.advanceBots()
        while table.street != .finished {
            try table.apply(table.legalActions.contains(.call) ? .call : .check, actionID: "a\(turn)")
            try table.advanceBots()
            turn += 1
        }
        let steps = PracticeHandCoach.steps(for: table)
        let learner = table.events.enumerated().filter { $0.element.seat == 0 && $0.element.action != nil }
        #expect(steps.map(\.eventIndex) == learner.map(\.offset))
        for step in steps {
            let frame = table.frame(after: step.stepIndex)
            #expect(frame.street == step.street)
            #expect(step.facts.pot == frame.pot)
            #expect((step.street == .preflop) == [.premium, .playable, .weak].contains(step.strength))
            #expect(step.pressure.allSatisfy { $0.seat != 0 })
            sawPostflop = sawPostflop || step.street != .preflop
            sawPressure = sawPressure || step.pressure.contains { $0.label == "bet" || $0.label == "raise" }
        }
    }
    #expect(sawPostflop && sawPressure)
}

@Test func coachCallsABetWithNothingABluffOnlyWhenTheCardsWereShown() throws {
    var bluffs = 0, honest = 0
    for seed in 0..<300 as Range<UInt64> {
        var table = PracticeTableState(seed: seed, styles: [.casual], startingStack: 40, handLimit: 10)
        var turn = 0
        try table.advanceBots()
        while table.street != .finished {
            try table.apply(table.legalActions.contains(.call) ? .call : .check, actionID: "a\(turn)")
            try table.advanceBots()
            turn += 1
        }
        let review = try #require(table.review)
        for reveal in PracticeHandCoach.reveals(for: table) {
            #expect(review.pots.contains { $0.eligibleSeats.count > 1 && $0.eligibleSeats.contains(reveal.seat) })
            let hole = try #require(Card.parse(review.holeCards[reveal.seat].joined()))
            let board = try #require(Card.parse(review.board.prefix(reveal.street == .flop ? 3 : reveal.street == .turn ? 4 : 5).joined()))
            #expect(reveal.held == madeHand(hand: hole, board: board))
            if reveal.wasBluff { bluffs += 1 } else { honest += 1 }
        }
    }
    #expect(bluffs > 0 && honest > bluffs, "bluffs=\(bluffs) honest=\(honest)")

    // The learner folds preflop: no showdown, so nothing is read back.
    var folded = PracticeTableState(seed: 1, styles: [.maniac, .maniac, .maniac])
    try folded.advanceBots()
    if folded.street != .finished, folded.legalActions.contains(.fold) {
        try folded.apply(.fold, actionID: "fold")
        try folded.advanceBots()
    }
    if let review = folded.review, !review.pots.contains(where: { $0.eligibleSeats.count > 1 }) {
        #expect(PracticeHandCoach.reveals(for: folded).isEmpty)
    }
}

@Test func hintSuggestsWhatTheReviewWouldLaterCallGoodAndLeansCheapOtherwise() {
    typealias Coach = PracticeHandCoach
    let open: [PracticeAction] = [.fold, .call, .raise(to: 6)]
    #expect(Coach.suggestion(strength: .premium, toCall: 2, needed: 40, boardCount: 0, legal: open) == .raise(to: 6))
    #expect(Coach.suggestion(strength: .playable, toCall: 2, needed: 40, boardCount: 0, legal: open) == .call)
    #expect(Coach.suggestion(strength: .weak, toCall: 2, needed: 40, boardCount: 0, legal: open) == .fold)
    #expect(Coach.suggestion(strength: .weak, toCall: 0, needed: nil, boardCount: 0, legal: [.check, .raise(to: 4)]) == .check)
    // The same draw, the same price: call with two cards to come, let it go with one.
    #expect(Coach.suggestion(strength: .draw, toCall: 4, needed: 30, boardCount: 3, legal: open) == .call)
    #expect(Coach.suggestion(strength: .draw, toCall: 4, needed: 30, boardCount: 4, legal: open) == .fold)
    // A dear bet into a small pair: never a raise just because raising is "fine".
    #expect(Coach.suggestion(strength: .weakPair, toCall: 9, needed: 33, boardCount: 3, legal: open) == .fold)
    // A strong hand that cannot raise again still continues.
    #expect(Coach.suggestion(strength: .strong, toCall: 4, needed: 20, boardCount: 4, legal: [.fold, .call]) == .call)
    // Whatever is suggested is never something the review would call risky.
    for strength in PracticeCoachStep.Strength.allCases {
        for (toCall, needed, legal) in [(0, Int?.none, [PracticeAction.check, .raise(to: 4)]), (4, 30, open), (12, 45, [.fold, .call])] {
            let board = [.premium, .playable, .weak].contains(strength) ? 0 : 3
            guard let pick = Coach.suggestion(strength: strength, toCall: toCall, needed: needed,
                                              boardCount: board, legal: legal) else { continue }
            #expect(Coach.verdict(action: pick, strength: strength, toCall: toCall, needed: needed, boardCount: board) != .risky)
        }
    }
}
