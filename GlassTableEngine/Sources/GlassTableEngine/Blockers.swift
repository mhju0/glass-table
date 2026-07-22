// Copyright (c) 2026 Michael Ju (github.com/mhju0)

public enum ComboKind { case pair, suited, offsuit, any }

/// Number of unblocked 2-card combos of a hand class. For pairs, `rankB` is ignored.
/// Baselines with nothing removed: pair 6, suited 4, offsuit 12, any 16.
public func comboCount(rankA: Int, rankB: Int, kind: ComboKind, removed: Set<Card>) -> Int {
    if kind == .pair || rankA == rankB {
        // Choose 2 of the (up to) 4 unblocked suits of rankA.
        let suits = (0...3).filter { !removed.contains(Card(rank: rankA, suit: $0)) }
        return suits.count * (suits.count - 1) / 2
    }
    // rankA != rankB, so every (sa, sb) names a distinct unordered combo — no double counting.
    var count = 0
    for sa in 0...3 {
        for sb in 0...3 {
            let suited = (sa == sb)
            if kind == .suited && !suited { continue }
            if kind == .offsuit && suited { continue }
            let a = Card(rank: rankA, suit: sa)
            let b = Card(rank: rankB, suit: sb)
            if removed.contains(a) || removed.contains(b) { continue }
            count += 1
        }
    }
    return count
}
