import Foundation
import Testing
import GlassTableDrills
@testable import GlassTable

@MainActor
struct QuickPlayModelTests {
    private func withStore(_ body: (ProgressionStore) throws -> Void) throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("quick-model-\(UUID())")
        defer { try? FileManager.default.removeItem(at: dir) }
        try body(ProgressionStore(url: dir.appendingPathComponent("progression.json")))
    }

    private func settle(_ model: ProgressionModel) throws {
        while let table = model.state.tableState, table.review == nil {
            #expect(try model.applyTableAction(table.legalActions.contains(.check) ? .check : .call,
                actionID: UUID().uuidString, handID: table.handID, expectedEpoch: model.epoch))
        }
    }

    @Test func tenHandsPersistThroughResumeThenEndAndNewSameSeedGame() throws {
        try withStore { store in
            var model = ProgressionModel(store: store)
            #expect(try model.startTable(seed: 97, styles: [.tag, .station, .lag],
                startingStack: 40, handLimit: 10, expectedEpoch: model.epoch))
            while true {
                try settle(model)
                let hand = try #require(model.state.tableState)
                #expect(model.state.quickPlaySessions.first?.hands.last == hand)
                let saved = model.state
                model = ProgressionModel(store: store)
                #expect(model.state == saved)
                if hand.isGameOver { break }
                let nextID = UUID().uuidString
                #expect(try model.nextTableHand(handID: nextID, after: hand.handID, expectedEpoch: model.epoch))
                #expect(try model.nextTableHand(handID: nextID, after: hand.handID, expectedEpoch: model.epoch))
            }
            let hand = try #require(model.state.tableState)
            #expect(model.state.quickPlaySessions.first?.hands.count == 10)
            let id = model.state.activeQuickPlaySessionID
            #expect(model.endTable(handID: hand.handID, expectedEpoch: model.epoch))
            #expect(model.state.tableState == nil)
            #expect(model.state.quickPlaySessions.first?.endReason == .completed)
            #expect(try model.startTable(seed: 97, styles: [.tag, .station, .lag],
                startingStack: 40, handLimit: 10, expectedEpoch: model.epoch))
            #expect(model.state.activeQuickPlaySessionID != id)
        }
    }

    @Test func legacySettledNextCapturesBeforeAdvancingAndLiveEndRetainsIt() throws {
        try withStore { store in
            var table = PracticeTableState(seed: 97, handID: "legacy", startingStack: 40, handLimit: 10)
            try table.advanceBots()
            while table.review == nil {
                try table.apply(table.legalActions.contains(.check) ? .check : .call, actionID: UUID().uuidString)
                try table.advanceBots()
            }
            try store.save(ProgressState(tableState: table))
            let model = ProgressionModel(store: store)
            #expect(try model.nextTableHand(handID: "next", after: table.handID, expectedEpoch: model.epoch))
            #expect(model.state.quickPlaySessions.first?.hands.first == table)
            #expect(model.endTable(handID: "next", expectedEpoch: model.epoch))
            #expect(model.state.quickPlaySessions.first?.hands.count == 1)
            #expect(model.state.quickPlaySessions.first?.endReason == .endedEarly)
            #expect(ProgressionModel(store: store).state == model.state)
        }
    }

    @Test func settlementSaveFailureLeavesDisplayedStateAndRetrySavesOneSnapshot() throws {
        try withStore { store in
            let model = ProgressionModel(store: store)
            #expect(try model.startTable(seed: 97, styles: [.tag], startingStack: 40,
                handLimit: 10, expectedEpoch: model.epoch))
            // Fold settles a heads-up hand; blocking the store directory forces the atomic save to fail.
            let table = try #require(model.state.tableState)
            #expect(table.legalActions.contains(.fold))
            let before = model.state
            let parent = store.url.deletingLastPathComponent()
            let original = try Data(contentsOf: store.url)
            try FileManager.default.removeItem(at: parent)
            try Data("blocked".utf8).write(to: parent)
            #expect(try !model.applyTableAction(.fold, actionID: "fold-once", handID: table.handID,
                expectedEpoch: model.epoch))
            #expect(model.state == before)
            #expect(model.saveError != nil)
            let pending = try JSONDecoder().decode(ProgressState.self, from: model.exportData())
            #expect(pending.quickPlaySessions.first?.hands.count == 1)
            try FileManager.default.removeItem(at: parent)
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try original.write(to: store.url)
            model.retrySave()
            #expect(model.saveError == nil)
            #expect(model.state.quickPlaySessions.first?.hands.count == 1)
            #expect(try model.applyTableAction(.fold, actionID: "fold-once", handID: table.handID,
                expectedEpoch: model.epoch))
            #expect(model.state.quickPlaySessions.first?.hands.count == 1)
            #expect(ProgressionModel(store: store).state == model.state)
        }
    }

    @Test func importAndResetArchivePreserveReplacementRecoveryAndRejectStaleEnd() throws {
        try withStore { store in
            let model = ProgressionModel(store: store)
            #expect(try model.startTable(seed: 97, styles: [.tag], startingStack: 40,
                handLimit: 10, expectedEpoch: model.epoch))
            try settle(model)
            let original = try model.exportData()
            let before = model.state
            let epoch = model.epoch
            let handID = try #require(model.state.tableState?.handID)
            try model.resetProgress()
            #expect(model.state.quickPlaySessions.isEmpty)
            #expect(!model.endTable(handID: handID, expectedEpoch: epoch))
            #expect(try FileManager.default.contentsOfDirectory(at: store.url.deletingLastPathComponent(),
                includingPropertiesForKeys: nil).contains { url in
                    url != store.url && (try? Data(contentsOf: url)) == original
                })
            try model.importData(original)
            #expect(model.state == before)
            #expect(ProgressionModel(store: store).state == before)
        }
    }
    @Test func legacySettledLeaveAndFailedEndRetryRetainArchive() throws {
        try withStore { store in
            var table = PracticeTableState(seed: 97, handID: "legacy-leave", startingStack: 40, handLimit: 10)
            try table.advanceBots()
            while table.review == nil {
                try table.apply(table.legalActions.contains(.check) ? .check : .call, actionID: UUID().uuidString)
                try table.advanceBots()
            }
            try store.save(ProgressState(tableState: table))
            let model = ProgressionModel(store: store)
            let before = model.state
            #expect(!model.endTable(handID: "stale-hand", expectedEpoch: model.epoch))
            #expect(model.state == before)
            let parent = store.url.deletingLastPathComponent()
            let original = try Data(contentsOf: store.url)
            try FileManager.default.removeItem(at: parent)
            try Data("blocked".utf8).write(to: parent)
            #expect(!model.leaveFinishedTable(handID: table.handID, expectedEpoch: model.epoch))
            #expect(model.state == before)
            let pending = try JSONDecoder().decode(ProgressState.self, from: model.exportData())
            #expect(pending.tableState == nil)
            #expect(pending.quickPlaySessions.first?.hands == [table])
            #expect(pending.quickPlaySessions.first?.endReason == .endedEarly)
            try FileManager.default.removeItem(at: parent)
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try original.write(to: store.url)
            model.retrySave()
            #expect(model.saveError == nil)
            #expect(model.state.tableState == nil)
            #expect(model.state.quickPlaySessions.first?.hands == [table])
            #expect(ProgressionModel(store: store).state == model.state)
        }
    }

}
