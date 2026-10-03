// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Testing
@testable import GlassTableDrills

/// Plays the current hand to settlement with the learner always calling or checking.
private func finishHand(_ table: inout PracticeTableState, tag: String) throws {
    var turn = 0
    try table.advanceBots()
    while table.street != .finished {
        try table.apply(table.legalActions.contains(.call) ? .call : .check, actionID: "\(tag)-\(turn)")
        try table.advanceBots()
        turn += 1
    }
}

@Test func quickGameStartsShortAndEndsAfterItsHandLimit() throws {
    var table = PracticeTableState(seed: 3, styles: [.nit, .station, .lag], startingStack: 40, handLimit: 3)
    #expect(table.startingStack == 40)
    #expect(table.seats.map { $0.stack + $0.committed } == [40, 40, 40, 40])
    for hand in 0..<3 {
        #expect(!table.isGameOver)
        try finishHand(&table, tag: "h\(hand)")
        try table.validate()
        let decoded = try JSONDecoder().decode(PracticeTableState.self, from: JSONEncoder().encode(table))
        try decoded.validate()
        #expect(decoded == table)
        if hand < 2 { try table.nextHand(handID: "hand-\(hand + 1)") }
    }
    #expect(table.isGameOver)
    #expect(throws: PracticeTableError.gameOver) { try table.nextHand(handID: "one-too-many") }
    #expect(table.seats.map(\.stack).reduce(0, +) == 160 + table.refills.reduce(0, +))
}

@Test func quickGameRefillsABustedComputerToTheQuickStackAndEndsWhenTheLearnerBusts() throws {
    var botBust: PracticeTableState?
    var learnerBust: PracticeTableState?
    for seed in 0..<400 where botBust == nil || learnerBust == nil {
        var table = PracticeTableState(seed: UInt64(seed), styles: [.maniac], startingStack: 6, handLimit: 50)
        for hand in 0..<50 {
            try finishHand(&table, tag: "s\(seed)-h\(hand)")
            if table.seats[0].stack == 0 { learnerBust = learnerBust ?? table; break }
            if table.seats[1].stack == 0 { botBust = botBust ?? table; break }
            try table.nextHand(handID: "s\(seed)-hand-\(hand + 1)")
        }
    }
    var refilled = try #require(botBust)
    #expect(!refilled.isGameOver)
    try refilled.nextHand(handID: "after-bust")
    #expect(refilled.refills == [0, 6])
    try refilled.validate()

    let over = try #require(learnerBust)
    #expect(over.isGameOver)
    #expect(over.handNumber + 1 < 50)
}

@Test func longTableKeepsHundredChipsNoEndingAndItsSavedShape() throws {
    var table = PracticeTableState(seed: 9, styles: [.nit, .station, .lag])
    #expect(table.startingStack == 100)
    #expect(table.handLimit == nil)
    try finishHand(&table, tag: "long")
    #expect(!table.isGameOver)
    // A table saved before quick games existed has neither key and must still load.
    let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(table)) as? [String: Any])
    #expect(json["quickStack"] == nil)
    #expect(json["handLimit"] == nil)
    let decoded = try JSONDecoder().decode(PracticeTableState.self, from: JSONEncoder().encode(table))
    try decoded.validate()
    #expect(decoded == table)
}
