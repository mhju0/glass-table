import Testing
import GlassTableDrills
@testable import GlassTable

struct FreeRaisePresentationTests {
    @Test func unraisedPreflopKeepsEveryBigBlindPreset() {
        let sizing = FreeRaisePresentation(street: .preflop, minimum: 4, maximum: 100,
                                           committed: 0, currentBet: 2, pot: 3, toCall: 2)
        #expect(sizing.presets.map(\.amount) == [4, 5, 6, 8, 100])
        #expect(sizing.context(amount: 7, language: .english) == "7 from your stack · 3.5 BB")
    }

    @Test func facingRaiseRetainsDuplicateTargetsAndOddAmounts() throws {
        let sizing = FreeRaisePresentation(street: .preflop, minimum: 6, maximum: 100,
                                           committed: 2, currentBet: 4, pot: 6, toCall: 2)
        #expect(sizing.presets.map(\.amount) == [10, 12, 16, 12, 100])
        #expect(sizing.presets[1].english == "3×")
        #expect(sizing.presets[3].english == "Pot")
        #expect(sizing.context(amount: 7, language: .english) == "5 from your stack · 3.5 BB")
        var table = PracticeTableState(seed: 31, styles: [.station])
        try table.apply(.call, actionID: "hero-call")
        try table.apply(.raise(to: 4), actionID: "computer-raise")
        #expect(FreeRaisePresentation(table: table).presets == sizing.presets)
        #expect(throws: Never.self) { try table.apply(.raise(to: 7), actionID: "odd-raise") }
    }

    @Test func postflopUsesRoundedPotFractionsAndIncrementalStackCost() {
        let bet = FreeRaisePresentation(street: .flop, minimum: 2, maximum: 100,
                                        committed: 0, currentBet: 0, pot: 18, toCall: 0)
        #expect(bet.presets.map(\.amount) == [6, 9, 14, 18, 100])
        #expect(bet.title(amount: 9, language: .korean) == "9칩 벳")
        #expect(bet.context(amount: 14, language: .english) == "14 from your stack · 78% of pot")
        let raise = FreeRaisePresentation(street: .turn, minimum: 24, maximum: 100,
                                          committed: 6, currentBet: 12, pot: 30, toCall: 6)
        #expect(raise.presets.map(\.amount) == [24, 30, 39, 48, 100])
        #expect(raise.context(amount: 30, language: .english) == "24 from your stack · 50% of pot")
    }

    @Test func IllegalPresetsStayUnclamped() {
        let sizing = FreeRaisePresentation(street: .flop, minimum: 8, maximum: 10,
                                           committed: 0, currentBet: 0, pot: 5, toCall: 0)
        #expect(sizing.presets.map(\.amount) == [2, 3, 4, 5, 10])
        #expect(sizing.presets.count == 5)
    }
}
