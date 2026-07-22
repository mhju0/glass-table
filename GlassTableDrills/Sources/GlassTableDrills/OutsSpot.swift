// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// One Outs-drill spot: hero vs a shown villain on a turn board, with the exact
/// winning river cards precomputed by the engine.
public struct OutsSpot: Equatable {
    public let hero: [Card]      // 2
    public let villain: [Card]   // 2
    public let board: [Card]     // 4 (turn)
    public let outs: [Card]      // winning river cards (engine countOuts)
    public let excluded: [Card]  // "looks like an out but loses" (flush-draw heuristic)

    public var outCount: Int { outs.count }
    /// Rule-of-2 improvement estimate (one card to come), as a percent.
    public var improvementPct: Double { ruleOf2or4(outs: outCount, cardsToCome: 1) }

    public init(hero: [Card], villain: [Card], board: [Card], outs: [Card], excluded: [Card]) {
        self.hero = hero; self.villain = villain; self.board = board
        self.outs = outs; self.excluded = excluded
    }
}
