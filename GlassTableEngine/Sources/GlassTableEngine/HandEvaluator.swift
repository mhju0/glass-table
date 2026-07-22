// Copyright (c) 2026 Michael Ju (github.com/mhju0)
// ponytail: naive 5-card classifier taken best-of-7 in evaluate7. Allocation-free hot
// path (stack rank-count buffer, no dict/set/sorted/map, and no per-subhand array in
// evaluate7) so the exact-enumeration and Monte-Carlo test gates run in seconds, not
// minutes. Same algorithm and same integer keys as the original dictionary version —
// only the constant factor changed. Swap for a perfect-hash evaluator only when
// Milestone 3 (8-way Table Monte Carlo) profiling shows this is still the bottleneck.

/// Rank a 5-card hand. Higher = stronger. Suit-independent within a category.
func evaluate5(_ cards: [Card]) -> Int {
    precondition(cards.count == 5)
    return eval5(cards[0], cards[1], cards[2], cards[3], cards[4])
}

/// Allocation-free 5-card core. Produces the same comparable key as `evaluate5`:
/// `category` (0=high card … 8=straight flush) in the top base-16 slot, then exactly
/// five tiebreak ranks, so category always dominates.
@inline(__always)
func eval5(_ c0: Card, _ c1: Card, _ c2: Card, _ c3: Card, _ c4: Card) -> Int {
    let s0 = c0.suit
    let isFlush = c1.suit == s0 && c2.suit == s0 && c3.suit == s0 && c4.suit == s0

    return withUnsafeTemporaryAllocation(of: Int.self, capacity: 15) { counts -> Int in
        for i in 0..<15 { counts[i] = 0 }
        counts[c0.rank] += 1; counts[c1.rank] += 1; counts[c2.rank] += 1
        counts[c3.rank] += 1; counts[c4.rank] += 1

        // Single high→low scan: distinct count, pair/trip/quad tallies, high & low rank.
        var n2 = 0, n3 = 0, n4 = 0, nDistinct = 0
        var hi = 0, lo = 0
        var r = 14
        while r >= 2 {
            let cnt = counts[r]
            if cnt > 0 {
                nDistinct += 1
                if hi == 0 { hi = r }  // first present = highest
                lo = r                 // last present so far = lowest
                if cnt == 2 { n2 += 1 } else if cnt == 3 { n3 += 1 } else if cnt == 4 { n4 += 1 }
            }
            r -= 1
        }

        // Straight detection (needs 5 distinct ranks; Ace-low wheel handled explicitly).
        var straightHigh = 0
        if nDistinct == 5 {
            if hi - lo == 4 {
                straightHigh = hi
            } else if counts[14] == 1 && counts[2] == 1 && counts[3] == 1
                        && counts[4] == 1 && counts[5] == 1 {
                straightHigh = 5  // wheel: 5-high
            }
        }
        let isStraight = straightHigh != 0

        let category: Int
        if isStraight && isFlush { category = 8 }
        else if n4 == 1 { category = 7 }
        else if n3 == 1 && n2 == 1 { category = 6 }
        else if isFlush { category = 5 }
        else if isStraight { category = 4 }
        else if n3 == 1 { category = 3 }
        else if n2 == 2 { category = 2 }
        else if n2 == 1 { category = 1 }
        else { category = 0 }

        // Tiebreak (exactly 5 base-16 slots, zero-padded): straights / straight flushes
        // rank by high card; everything else by distinct ranks in (count desc, rank desc).
        var key = category
        if isStraight && (category == 8 || category == 4) {
            key = key * 16 + straightHigh
            for _ in 0..<4 { key = key * 16 }  // pad remaining 4 slots with 0
        } else {
            var slots = 0
            for wanted in stride(from: 4, through: 1, by: -1) {
                var rr = 14
                while rr >= 2 {
                    if counts[rr] == wanted { key = key * 16 + rr; slots += 1 }
                    rr -= 1
                }
            }
            while slots < 5 { key = key * 16; slots += 1 }
        }
        return key
    }
}

// The 21 five-card index combinations of 7 cards.
private let combos7choose5: [[Int]] = {
    var out: [[Int]] = []
    let n = 7
    for a in 0..<n { for b in (a+1)..<n { for c in (b+1)..<n {
        for d in (c+1)..<n { for e in (d+1)..<n {
            out.append([a, b, c, d, e])
        } } }
    } }
    return out  // 21 combinations
}()

/// Best 5-card rank out of 7 cards. Same scale as `evaluate5`.
func evaluate7(_ cards: [Card]) -> Int {
    precondition(cards.count == 7)
    var best = 0
    for combo in combos7choose5 {
        let key = eval5(cards[combo[0]], cards[combo[1]], cards[combo[2]], cards[combo[3]], cards[combo[4]])
        if key > best { best = key }
    }
    return best
}
