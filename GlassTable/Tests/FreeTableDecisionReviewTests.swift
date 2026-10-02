// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Testing
import UIKit
import GlassTableDrills
import GlassTableEngine
@testable import GlassTable

struct FreeTableDecisionReviewTests {
    @Test @MainActor func closeSymbolKeepsOpaqueBoundsAndTemplateRendering() {
        let image = FreeTableCloseSymbol.image
        #expect(image.renderingMode == .alwaysTemplate)
        #expect(FreeTableCloseSymbol.opaquePixelCount > 0)
        #expect(image.cgImage?.width == Int(FreeTableCloseSymbol.sourceBounds.width))
        #expect(image.cgImage?.height == Int(FreeTableCloseSymbol.sourceBounds.height))
        let cg = image.cgImage!
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let context = CGContext(data: &bytes, width: cg.width, height: cg.height,
            bitsPerComponent: 8, bytesPerRow: cg.width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        let visible = stride(from: 3, to: bytes.count, by: 4).filter { bytes[$0] > 0 }.count
        #expect(visible == FreeTableCloseSymbol.opaquePixelCount)
        print("close-symbol alpha bounds=\(FreeTableCloseSymbol.sourceBounds), pixels=\(FreeTableCloseSymbol.opaquePixelCount), cropped-size=\(image.size)")
    }

    @Test func liveHandHasNoReviewChanceRows() throws {
        var table = PracticeTableState(seed: 97, styles: [.station])
        try table.advanceBots()
        #expect(FreeTableDecisionSnapshot.rows(table: table).isEmpty)
    }

    @Test func FoldedOpponentDoesNotQualifyForEquity() throws {
        var table = PracticeTableState(seed: 97, styles: [.station])
        try table.advanceBots()
        try table.apply(.fold, actionID: "hero-fold")
        let rows = FreeTableDecisionSnapshot.rows(table: table)
        #expect(rows.count == 1)
        #expect(rows[0].villain == nil)
        #expect(rows[0].board.isEmpty)
    }

    @Test func automaticHeadsUpShowdownUsesDecisionStreetOnly() throws {
        var candidates: [PracticeTableState] = []
        for seed in 97..<147 {
            var candidate = PracticeTableState(seed: UInt64(seed), styles: [.station])
            try candidate.advanceBots()
            guard candidate.legalActions.contains(where: { if case .raise = $0 { true } else { false } }) else { continue }
            try candidate.apply(.raise(to: 100), actionID: "hero-allin")
            try candidate.advanceBots()
            if candidate.review?.board.count == 5 { candidates.append(candidate); break }
        }
        let table = try #require(candidates.first)
        let rows = FreeTableDecisionSnapshot.rows(table: table)
        #expect(table.review != nil)
        #expect(rows.count == 1)
        #expect(rows[0].villain?.count == 2)
        #expect(rows[0].board.isEmpty)
    }

    @Test func equityCacheReturnsExactTieFraction() async throws {
        let cache = FreeTableEquityCache()
        let row = FreeTableDecisionSnapshot(id: "river", street: .river, needed: 25,
            hero: try #require(Card.parse("AsKd")), villain: try #require(Card.parse("AcKh")),
            board: try #require(Card.parse("2s3d4c5h6s")))
        let first = await cache.equity(for: row)
        #expect(first == 0.5)
        #expect(await cache.equity(for: row) == first)
    }
    @Test func multiwayAndRepeatedStreetDecisionsUseDistinctPublicSnapshots() throws {
        var table = PracticeTableState(seed: 31, styles: [.station, .station])
        try table.apply(.raise(to: 4), actionID: "hero-open")
        try table.apply(.fold, actionID: "sb-fold")
        try table.apply(.raise(to: 6), actionID: "bb-reraise")
        try table.apply(.call, actionID: "hero-call")
        for index in 0..<3 {
            try table.apply(.raise(to: 2), actionID: "bb-bet-\(index)")
            try table.apply(.call, actionID: "hero-call-\(index)")
        }
        let rows = FreeTableDecisionSnapshot.rows(table: table)
        #expect(rows.count == 5)
        #expect(rows[0].villain == nil)
        #expect(rows[1].villain != nil)
        #expect(rows[0].street == rows[1].street)
        #expect(Set(rows.map(\.id)).count == rows.count)
    }

    @Test func equityCacheRemainsBoundedAcrossDistinctRequests() async throws {
        let cache = FreeTableEquityCache()
        let hero = try #require(Card.parse("AsKd"))
        let villain = try #require(Card.parse("AcKh"))
        let prefix = try #require(Card.parse("2s3d4c5h"))
        let available = Deck.all.filter { !(hero + villain + prefix).contains($0) }
        for card in available.prefix(13) {
            let row = FreeTableDecisionSnapshot(id: card.description, street: .river, needed: 25,
                                               hero: hero, villain: villain, board: prefix + [card])
            #expect(await cache.equity(for: row) != nil)
        }
        #expect(await cache.cachedEntryCount == 12)
    }

    @Test func allInOpponentStillCountsAsLiveAtCallDecision() throws {
        var table = PracticeTableState(seed: 31, styles: [.station])
        try table.apply(.call, actionID: "hero-limp")
        try table.apply(.raise(to: 100), actionID: "computer-allin")
        #expect(table.seats[1].stack == 0)
        try table.apply(.call, actionID: "hero-allin-call")
        let rows = FreeTableDecisionSnapshot.rows(table: table)
        #expect(rows.count == 2)
        #expect(rows.last?.needed == 49)
        #expect(rows.allSatisfy { $0.villain != nil })
    }

    @Test func mathDotsChooseNearestProbabilityAndHideBeyondSix() {
        #expect(FreeMathDots.count(neededPercent: nil) == nil)
        #expect(FreeMathDots.count(neededPercent: 0) == nil)
        #expect(FreeMathDots.count(neededPercent: 16) == nil)
        #expect(FreeMathDots.count(neededPercent: 17) == 6)
        #expect(FreeMathDots.count(neededPercent: 25) == 4)
        #expect(FreeMathDots.count(neededPercent: 29) == 4)
        #expect(FreeMathDots.count(neededPercent: 40) == 3)
        #expect(FreeMathDots.count(neededPercent: 50) == 2)
    }

}
