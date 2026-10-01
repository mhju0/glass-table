import Testing
import GlassTableDrills
@testable import GlassTable

struct FreeDockPresentationTests {
    @Test func replayChoicesIgnoreUnshownActions() throws {
        var table = PracticeTableState(seed: 97, styles: [.tag, .station, .lag])
        try table.advanceBots()
        let shown = table.replaySteps.count
        let before = FreeDockChoices(frame: table.frame(after: shown))
        try table.apply(.call, actionID: "call")
        try table.advanceBots()
        let after = FreeDockChoices(frame: table.frame(after: shown))
        #expect(after == before)
    }

    @Test func preflopPriceRetainsPublicBigBlindFloor() {
        let table = PracticeTableState(seed: 97, styles: [.tag])
        let choices = FreeDockChoices(frame: table.frame(after: 0))
        #expect(choices.owed == 2)
        #expect(choices.price == 2)
        #expect(!choices.bet)
        #expect(!choices.allIn)
    }
}
