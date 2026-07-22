// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Deterministic, procedural Outs-drill spots. Same (baseSeed, index) → same spot.
public enum OutsSpotGenerator {
    /// Draw hero/villain/turn-board from a seeded shuffle; keep only spots where hero
    /// is behind and drawing — operationalized as 2...15 winning river outs.
    public static func spot(baseSeed: UInt64, index: Int) -> OutsSpot {
        var attempt = 0
        var lo = 2, hi = 15
        while true {
            let seed = baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt)
            var rng = SplitMix64(seed: seed)
            let deck = Deck.all.shuffled(using: &rng)
            let hero = Array(deck[0..<2])
            let villain = Array(deck[2..<4])
            let board = Array(deck[4..<8])
            let outs = countOuts(hero: hero, villain: villain, board: board)
            if outs.count >= lo && outs.count <= hi {
                let excluded = excludedCards(hero: hero, villain: villain, board: board, outs: outs)
                return OutsSpot(hero: hero, villain: villain, board: board,
                                outs: outs, excluded: excluded)
            }
            attempt += 1
            // ponytail: 2..15 selects ~a third of random spots, so this never widens in
            // practice — it's a hang-proof safety valve, one step wider per 200 misses.
            if attempt % 200 == 0 { lo = max(1, lo - 1); hi = min(46, hi + 1) }
        }
    }

    /// Flush-draw heuristic: when hero holds four to a flush, the remaining cards of that
    /// suit that are NOT winning outs (they complete the flush but lose). Empty otherwise.
    static func excludedCards(hero: [Card], villain: [Card], board: [Card], outs: [Card]) -> [Card] {
        var bySuit = [Int: Int]()
        for c in hero + board { bySuit[c.suit, default: 0] += 1 }
        guard let suit = bySuit.first(where: { $0.value >= 4 })?.key else { return [] }
        let known = Set(hero + villain + board)
        let outsSet = Set(outs)
        return Deck.all.filter { $0.suit == suit && !known.contains($0) && !outsSet.contains($0) }
    }
}
