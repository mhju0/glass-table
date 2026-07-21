// Copyright (c) 2026 Michael Ju
// ponytail: naive 5-card classifier taken best-of-7 in evaluate7.
// Correct and oracle-verified; swap for a perfect-hash evaluator only when
// Milestone 3 (8-way Table Monte Carlo) profiling shows this is the bottleneck.

/// Rank a 5-card hand. Higher = stronger. Suit-independent within a category.
func evaluate5(_ cards: [Card]) -> Int {
    precondition(cards.count == 5)
    let ranks = cards.map { $0.rank }
    let isFlush = Set(cards.map { $0.suit }).count == 1

    var counts: [Int: Int] = [:]
    for r in ranks { counts[r, default: 0] += 1 }

    // Distinct ranks ordered by (count desc, rank desc).
    let ordered = counts.keys.sorted { a, b in
        counts[a]! != counts[b]! ? counts[a]! > counts[b]! : a > b
    }
    let pattern = ordered.map { counts[$0]! }  // e.g. [4,1], [3,2], [2,2,1]

    // Straight detection (Ace-low wheel handled explicitly).
    let distinct = Set(ranks)
    var straightHigh = 0
    if distinct.count == 5 {
        let hi = ranks.max()!, lo = ranks.min()!
        if hi - lo == 4 {
            straightHigh = hi
        } else if distinct == [14, 2, 3, 4, 5] {
            straightHigh = 5  // wheel: 5-high
        }
    }
    let isStraight = straightHigh != 0

    let category: Int
    if isStraight && isFlush { category = 8 }
    else if pattern.first == 4 { category = 7 }
    else if pattern == [3, 2] { category = 6 }
    else if isFlush { category = 5 }
    else if isStraight { category = 4 }
    else if pattern.first == 3 { category = 3 }
    else if pattern == [2, 2, 1] { category = 2 }
    else if pattern.first == 2 { category = 1 }
    else { category = 0 }

    // Tiebreak ranks (exactly 5 slots, zero-padded, so category always dominates).
    let tb: [Int] = (isStraight && (category == 8 || category == 4)) ? [straightHigh] : ordered
    var padded = tb
    while padded.count < 5 { padded.append(0) }

    var key = category
    for v in padded { key = key * 16 + v }
    return key
}
