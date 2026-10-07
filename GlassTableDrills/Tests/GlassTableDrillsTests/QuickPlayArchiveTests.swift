import Foundation
import Testing
@testable import GlassTableDrills

struct QuickPlayArchiveTests {
    private func settle(_ initial: PracticeTableState) throws -> PracticeTableState {
        var table = initial
        try table.advanceBots()
        while table.review == nil {
            try table.apply(table.legalActions.contains(.check) ? .check : .call,
                            actionID: UUID().uuidString)
            try table.advanceBots()
        }
        return table
    }

    private func archivedGame(seed: UInt64 = 97, limit: Int = 10) throws -> ProgressState {
        var state = ProgressState()
        var table = PracticeTableState(seed: seed, handID: UUID().uuidString,
                                       startingStack: 40, handLimit: limit)
        state.captureQuickPlay(table)
        repeat {
            table = try settle(table)
            state.tableState = table; state.captureQuickPlay(table)
            if table.isGameOver { break }
            try table.nextHand(handID: UUID().uuidString)
        } while true
        return state
    }

    @Test func everySettledHandRoundTripsAndReviews() throws {
        let state = try archivedGame()
        try state.validateQuickPlayArchive()
        let session = try #require(state.quickPlaySessions.first)
        #expect(session.hands.count == 10)
        #expect(session.hands.map(\.handNumber) == Array(0..<10))
        #expect(session.metrics.decisions == session.metrics.reviewedDecisions)
        #expect(session.metrics.folds + session.metrics.checks + session.metrics.calls
                + session.metrics.bets + session.metrics.raises == session.metrics.decisions)
        let back = try JSONDecoder().decode(ProgressState.self, from: JSONEncoder().encode(state))
        #expect(back == state)
        try back.validateQuickPlayArchive()
    }

    @Test func duplicateCaptureAndSameSeedGamesHaveDifferentIdentity() throws {
        var state = try archivedGame(limit: 1)
        let table = try #require(state.tableState)
        state.captureQuickPlay(table); state.captureQuickPlay(table)
        #expect(state.quickPlaySessions[0].hands.count == 1)
        state.finishQuickPlay(table); state.tableState = nil
        let second = PracticeTableState(seed: table.seed, handID: UUID().uuidString,
                                        startingStack: 40, handLimit: 1)
        state.tableState = second; state.captureQuickPlay(second)
        #expect(state.quickPlaySessions[0].id != state.quickPlaySessions[1].id)
        try state.validateQuickPlayArchive()
    }

    @Test func legacyPartialCoverageAndEarlyEndKeepSettledHands() throws {
        var table = try settle(PracticeTableState(seed: 97, handID: "old-0", startingStack: 40, handLimit: 10))
        try table.nextHand(handID: "old-1")
        table = try settle(table)
        var state = ProgressState(tableState: table)
        state.captureQuickPlay(table)
        #expect(state.quickPlaySessions[0].coverageStartHandNumber == 1)
        #expect(state.quickPlaySessions[0].metrics.netChips
                == table.review!.endingStacks[0] - table.review!.startingStacks[0])
        try table.nextHand(handID: "unfinished")
        state.tableState = table
        try state.validateQuickPlayArchive()
        state.finishQuickPlay(table); state.tableState = nil
        #expect(state.quickPlaySessions[0].hands.count == 1)
        #expect(state.quickPlaySessions[0].endReason == .endedEarly)
        try state.validateQuickPlayArchive()
    }

    @Test func emptyEndAndWholeSessionRetention() throws {
        var state = ProgressState()
        let empty = PracticeTableState(seed: 4, startingStack: 40, handLimit: 10)
        state.finishQuickPlay(empty)
        #expect(state.quickPlaySessions.isEmpty)
        for index in 0..<25 {
            let table = try settle(PracticeTableState(seed: UInt64(index), handID: "game-\(index)",
                                                      startingStack: 40, handLimit: 1))
            state.captureQuickPlay(table); state.finishQuickPlay(table)
        }
        #expect(state.quickPlaySessions.count == 20)
        #expect(state.quickPlaySessions.first?.hands.first?.handID == "game-5")
        let active = try archivedGame()
        state.quickPlaySessions += active.quickPlaySessions
        state.activeQuickPlaySessionID = active.activeQuickPlaySessionID
        state.tableState = active.tableState
        #expect(state.quickPlaySessions.last?.hands.count == 10)
        try state.validateQuickPlayArchive()
    }

    @Test func missingFieldCompatibleButMalformedArchiveRejected() throws {
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(ProgressState())) as? [String: Any])
        json.removeValue(forKey: "quickPlaySessions")
        let old = try JSONDecoder().decode(ProgressState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(old.quickPlaySessions.isEmpty)
        json["quickPlaySessions"] = "invalid"
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(ProgressState.self, from: JSONSerialization.data(withJSONObject: json))
        }
    }

    @Test func tamperedSnapshotAndCrossHandTransitionRejected() throws {
        let state = try archivedGame()
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        var sessions = try #require(json["quickPlaySessions"] as? [[String: Any]])
        var hands = try #require(sessions[0]["hands"] as? [[String: Any]])
        hands[1]["dealer"] = 0
        sessions[0]["hands"] = hands; json["quickPlaySessions"] = sessions
        let tampered = try JSONDecoder().decode(ProgressState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(throws: (any Error).self) { try tampered.validateQuickPlayArchive() }
        var separate = try archivedGame(seed: 97)
        separate.quickPlaySessions = state.quickPlaySessions
        // Same rules and seed with different decisions/hand IDs still cannot replace the active chain.
        #expect(throws: (any Error).self) { try separate.validateQuickPlayArchive() }
    }

    @Test func storeRestartImportResetAndRecoveryPreserveArchive() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProgressionStore(url: dir.appendingPathComponent("progression.json"))
        let state = try archivedGame()
        try store.save(state)
        guard case let .loaded(back) = store.load() else { Issue.record("Expected saved archive"); return }
        #expect(back == state)
        let exported = try store.exportData()
        #expect(try store.importData(exported) == state)
        try store.save(ProgressState())
        #expect(try store.importData(exported) == state)
        var bad = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        bad["quickPlaySessions"] = "broken"
        let malformed = try JSONSerialization.data(withJSONObject: bad)
        let before = try Data(contentsOf: store.url)
        #expect(throws: (any Error).self) { try store.importData(malformed) }
        #expect(try Data(contentsOf: store.url) == before)
        try malformed.write(to: store.url)
        guard case .unreadable = store.load() else { Issue.record("Malformed archive must be unreadable"); return }
        #expect(try store.exportData() == malformed)
    }
    @Test func maximumRetentionReadSavePerformance() throws {
        var state = ProgressState()
        for _ in 0..<ProgressState.quickPlayCompletedSessionCap {
            let game = try archivedGame()
            var session = game.quickPlaySessions[0]
            session.finish(table: try #require(game.tableState))
            state.quickPlaySessions.append(session)
        }
        let active = try archivedGame()
        state.quickPlaySessions += active.quickPlaySessions
        state.activeQuickPlaySessionID = active.activeQuickPlaySessionID
        state.tableState = active.tableState
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProgressionStore(url: dir.appendingPathComponent("progression.json"))
        let saveStart = Date()
        try store.save(state)
        let saveSeconds = Date().timeIntervalSince(saveStart)
        let loadStart = Date()
        guard case let .loaded(back) = store.load() else { Issue.record("Expected maximum archive"); return }
        let loadSeconds = Date().timeIntervalSince(loadStart)
        #expect(back == state)
        let bytes = try Data(contentsOf: store.url).count
        print("QUICK_ARCHIVE_PERFORMANCE hands=210 bytes=\(bytes) save=\(saveSeconds)s load=\(loadSeconds)s")
    }

    @Test func limitedGameWithDefaultStackRemainsCompatible() throws {
        let table = try settle(PracticeTableState(seed: 97, handID: "default-stack", handLimit: 10))
        var state = ProgressState(tableState: table)
        state.captureQuickPlay(table)
        try state.validateQuickPlayArchive()
        #expect(state.quickPlaySessions.first?.startingStack == 100)
    }

    @Test func individuallyValidDifferentGameHandCannotBreakSessionContinuity() throws {
        let state = try archivedGame()
        let original = state.quickPlaySessions[0].hands
        var other = PracticeTableState(seed: 97, handID: "alternate", startingStack: 40, handLimit: 10)
        try other.advanceBots()
        try other.apply(.fold, actionID: "alternate-fold")
        try other.advanceBots()
        other = try settle(other)
        #expect(other.review?.endingStacks != original[0].review?.endingStacks)
        try other.nextHand(handID: original[1].handID)
        other = try settle(other)
        try other.validate()
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        var sessions = try #require(json["quickPlaySessions"] as? [[String: Any]])
        var hands = try #require(sessions[0]["hands"] as? [[String: Any]])
        hands[1] = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(other)) as? [String: Any])
        sessions[0]["hands"] = hands; json["quickPlaySessions"] = sessions
        let tampered = try JSONDecoder().decode(ProgressState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(throws: (any Error).self) { try tampered.validateQuickPlayArchive() }
    }

    @Test func learnerBustedReasonIsDerivedFromActualSettlement() throws {
        var busted: PracticeTableState?
        for seed in 0..<50 {
            var table = PracticeTableState(seed: UInt64(seed), styles: [.station],
                handID: "bust-\(seed)", startingStack: 40, handLimit: 10)
            try table.advanceBots()
            try table.apply(.raise(to: 40), actionID: "all-in")
            try table.advanceBots()
            if table.review != nil, table.seats[0].stack == 0 { busted = table; break }
        }
        let table = try #require(busted)
        var state = ProgressState(tableState: table)
        state.captureQuickPlay(table); state.finishQuickPlay(table); state.tableState = nil
        #expect(state.quickPlaySessions[0].endReason == .learnerBusted)
        #expect(state.quickPlaySessions[0].hands.count == 1)
        try state.validateQuickPlayArchive()
    }

}
