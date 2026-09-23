import Foundation
import Testing
@testable import GlassTableDrills

@Test func importedTableRejectsOverflowAndFabricatedReview() throws {
    var table = PracticeTableState(seed: 9)
    try table.advanceBots()
    while table.street != .finished {
        try table.apply(table.legalActions.contains(.call) ? .call : .check,
                        actionID: "a-\(table.events.count)")
        try table.advanceBots()
    }
    try table.validate()
    let data = try JSONEncoder().encode(table)
    var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    var seats = try #require(object["seats"] as? [[String: Any]])
    seats[0]["stack"] = Int.max
    object["seats"] = seats
    let overflow = try JSONDecoder().decode(PracticeTableState.self,
                                            from: JSONSerialization.data(withJSONObject: object))
    #expect(throws: PracticeTableError.invalidState) { try overflow.validate() }

    object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    var review = try #require(object["review"] as? [String: Any])
    review["payouts"] = [400]
    object["review"] = review
    let fabricated = try JSONDecoder().decode(PracticeTableState.self,
                                              from: JSONSerialization.data(withJSONObject: object))
    #expect(throws: PracticeTableError.invalidState) { try fabricated.validate() }
}

@Test func importedTableRejectsUnsupportedPolicyAndTurnTampering() throws {
    let original = PracticeTableState(seed: 10)
    let data = try JSONEncoder().encode(original)
    for edit in ["storedPolicyVersion", "currentSeat"] {
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object[edit] = edit == "storedPolicyVersion" ? 99 : 1
        let changed = try JSONDecoder().decode(PracticeTableState.self,
                                               from: JSONSerialization.data(withJSONObject: object))
        #expect(throws: PracticeTableError.invalidState) { try changed.validate() }
    }
}

@Test func randomLegalActionsResumeAndConserveAcrossHands() throws {
    for seed in 0..<60 {
        var table = PracticeTableState(seed: UInt64(seed))
        for hand in 0..<6 {
            var step = 0
            while table.street != .finished {
                let actions = table.legalActions
                let selected = actions[(seed + hand + step) % actions.count]
                try table.apply(selected, actionID: "h\(hand)-a\(step)")
                try table.validate()
                table = try JSONDecoder().decode(PracticeTableState.self,
                                                 from: JSONEncoder().encode(table))
                step += 1
                #expect(step < 2000)
            }
            let settled = table
            try table.nextHand(handID: "h\(hand + 1)")
            let next = table
            try table.nextHand(handID: "h\(hand + 1)")
            #expect(next == table)
            #expect(table.dealer == (settled.dealer + 1) % 4)
            let chips = table.seats.map { $0.stack + $0.committed }.reduce(0, +)
            let introduced = 400 + table.refills.reduce(0, +)
            #expect(chips == introduced)
        }
    }
}

@Test func learnerFoldStillAllowsOtherPlayersToSettle() throws {
    var found = false
    for seed in 0..<80 {
        var table = PracticeTableState(seed: UInt64(seed), styles: [.maniac, .station, .maniac])
        try table.advanceBots()
        guard table.currentSeat == 0, table.legalActions.contains(.fold) else { continue }
        try table.apply(.fold, actionID: "learner-fold")
        try table.advanceBots()
        #expect(table.street == .finished)
        #expect(table.review != nil)
        #expect(table.review?.payouts[0] == 0)
        try table.validate()
        found = true
    }
    #expect(found)
}

@Test func blindAllInsAndBigBlindOptionRemainLegal() throws {
    var table = PracticeTableState.fixture(seed: 12, stacks: [100, 1, 1, 100])
    #expect(table.legalActions.contains(.call))
    try table.apply(.call, actionID: "utg-call")
    try table.apply(.call, actionID: "button-call")
    #expect(table.street == .flop)
    try table.validate()

    table = PracticeTableState(seed: 12)
    try table.apply(.call, actionID: "utg-call")
    try table.apply(.call, actionID: "button-call")
    try table.apply(.call, actionID: "small-call")
    #expect(table.currentSeat == 2)
    #expect(table.legalActions.contains(.check))
    #expect(table.legalActions.contains(.raise(to: 4)))
}

@Test func largeStackBotsSettleWithoutUnboundedReraising() throws {
    for seed in 0..<100 {
        var table = PracticeTableState.fixture(seed: UInt64(seed),
                                               stacks: [100_000, 100_000, 100_000, 100_000])
        try table.advanceBots()
        guard table.currentSeat == 0 else { continue }
        try table.apply(.fold, actionID: "learner-fold")
        let before = table.events.count
        try table.advanceBots()
        #expect(table.street == .finished)
        #expect(table.events.count - before <= 48)
        #expect(table.seats.map(\.stack).reduce(0, +) == 400_000)
        try table.validate()
    }
}

@Test func botObservationContainsOnlyOwnCardsAndPublicFacts() {
    let view = PracticeBotView(seat: 1, style: .tag, hole: ["As", "Ah"],
                               board: [], street: .preflop, pot: 3, toCall: 2,
                               stack: 100, minimumRaiseTo: 4, hasRaisedThisStreet: false)
    let exposedFields = Set(Mirror(reflecting: view).children.compactMap(\.label))
    #expect(exposedFields == ["seat", "style", "hole", "board", "street", "pot",
                              "toCall", "stack", "minimumRaiseTo", "hasRaisedThisStreet"])
    #expect(PracticeBotPolicy.action(for: view) == .raise(to: 4))
    let alreadyRaised = PracticeBotView(seat: 1, style: .tag, hole: ["As", "Ah"],
                                        board: [], street: .preflop, pot: 50, toCall: 2,
                                        stack: 100_000, minimumRaiseTo: 20,
                                        hasRaisedThisStreet: true)
    #expect(PracticeBotPolicy.action(for: alreadyRaised) == .call)
}
