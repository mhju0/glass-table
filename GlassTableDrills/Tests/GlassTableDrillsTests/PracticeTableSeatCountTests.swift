// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Testing
@testable import GlassTableDrills

/// Two- and three-player free tables: the style list sets the table size.
@Test(arguments: [1, 2, 3])
func practiceTableSeatsOneMoreThanItsStyles(computers: Int) throws {
    let styles = Array([Archetype.nit, .station, .lag].prefix(computers))
    for seed in 0..<30 {
        var table = PracticeTableState(seed: UInt64(seed), styles: styles)
        #expect(table.seats.count == computers + 1)
        try table.validate()
        var turns = 0
        for hand in 0..<3 {
            while table.street != .finished && turns < 300 {
                try table.advanceBots()
                try table.validate()
                if table.street == .finished { break }
                let choice = table.legalActions.contains(.call) ? PracticeAction.call : .check
                try table.apply(choice, actionID: "learner-\(turns)")
                try table.validate()
                turns += 1
            }
            #expect(table.street == .finished)
            #expect(table.seats.map(\.stack).reduce(0, +)
                    == 100 * (computers + 1) + table.refills.reduce(0, +))
            let decoded = try JSONDecoder().decode(PracticeTableState.self,
                                                   from: JSONEncoder().encode(table))
            try decoded.validate()
            #expect(decoded == table)
            try table.nextHand(handID: "hand-\(seed)-\(hand + 1)")
            #expect(table.dealer == (hand + 1) % (computers + 1))
        }
    }
}

/// Heads-up: the button posts the small blind and acts first before the flop; the big
/// blind acts first after it.
@Test func headsUpButtonPostsSmallBlindAndActsFirstPreflopOnly() throws {
    var table = PracticeTableState(seed: 5, styles: [.station])
    #expect(table.dealer == 0)
    let blinds = table.events.prefix(2).map { ($0.seat, $0.label) }
    #expect(blinds.map(\.0) == [0, 1])
    #expect(blinds.map(\.1) == ["small blind", "big blind"])
    #expect(table.currentSeat == 0)
    try table.apply(.call, actionID: "limp")
    try table.advanceBots()
    if table.street == .flop {
        let flopActors = table.events.filter { $0.street == .flop }.map(\.seat)
        #expect(flopActors.first == 1 || table.currentSeat == 1)
    }

    var next = PracticeTableState(seed: 5, styles: [.station])
    try next.apply(.fold, actionID: "fold")
    try next.advanceBots()
    #expect(next.street == .finished)
    try next.nextHand(handID: "second")
    #expect(next.dealer == 1)
    #expect(next.events.prefix(2).map(\.seat) == [1, 0])
    #expect(next.currentSeat == 1)
}

/// Three players: small blind left of the button, big blind next, button acts first.
@Test func threeHandedBlindsAndFirstActor() {
    let table = PracticeTableState(seed: 9, styles: [.nit, .lag])
    #expect(table.events.prefix(2).map(\.seat) == [1, 2])
    #expect(table.currentSeat == 0)
}

/// Four-seat tables must deal exactly as before, so saved tables keep replaying.
@Test func fourSeatDealIsUnchanged() throws {
    let table = PracticeTableState(seed: 42)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let fingerprint = try encoder.encode(table)
        .reduce(UInt64(0xcbf2_9ce4_8422_2325)) { ($0 ^ UInt64($1)) &* 0x100_0000_01b3 }
    // Recorded from the four-seat-only engine before seat counts became variable.
    #expect(fingerprint == 8_885_980_407_610_072_459)
    #expect(table.seats.count == 4)
    #expect(table.events.prefix(2).map(\.seat) == [1, 2])
    #expect(table.currentSeat == 3)
}
