// Copyright (c) 2026 Michael Ju (github.com/mhju0)

public struct EquityResult {
    public let wins: Int
    public let ties: Int
    public let total: Int
    public var equity: Double {
        total == 0 ? 0 : (Double(wins) + Double(ties) / 2.0) / Double(total)
    }
}

/// Exact heads-up equity by enumerating every completion of the board to 5 cards.
/// `board` may hold 0–5 known community cards.
public func exactEquityHeadsUp(hero: [Card], villain: [Card], board: [Card]) -> EquityResult {
    precondition(hero.count == 2 && villain.count == 2)
    let known = Set(hero + villain + board)
    let remaining = Deck.all.filter { !known.contains($0) }
    let need = 5 - board.count
    precondition(need >= 0)

    var wins = 0, ties = 0, total = 0
    forEachCombination(of: remaining, choose: need) { completion in
        let full = board + completion
        let h = evaluate7(hero + full)
        let v = evaluate7(villain + full)
        if h > v { wins += 1 } else if h == v { ties += 1 }
        total += 1
    }
    return EquityResult(wins: wins, ties: ties, total: total)
}

/// Fixed-seed Monte Carlo equity: sample `iterations` random board completions.
/// Deterministic for a given `seed` (partial Fisher–Yates over the remaining deck).
public func monteCarloEquityHeadsUp(hero: [Card], villain: [Card], board: [Card],
                                    iterations: Int, seed: UInt64) -> EquityResult {
    precondition(hero.count == 2 && villain.count == 2)
    let known = Set(hero + villain + board)
    var deck = Deck.all.filter { !known.contains($0) }
    let need = 5 - board.count
    var rng = SplitMix64(seed: seed)

    var wins = 0, ties = 0
    for _ in 0..<iterations {
        // Partial shuffle: draw `need` cards to the front.
        for i in 0..<need {
            let j = Int(rng.next() % UInt64(deck.count - i)) + i
            deck.swapAt(i, j)
        }
        let full = board + Array(deck[0..<need])
        let h = evaluate7(hero + full)
        let v = evaluate7(villain + full)
        if h > v { wins += 1 } else if h == v { ties += 1 }
    }
    return EquityResult(wins: wins, ties: ties, total: iterations)
}

/// Hero's equity averaged over a villain range (a list of 2-card combos).
/// Combos colliding with hero's cards or the board are skipped.
public func equityVsRange(hero: [Card], villainCombos: [[Card]], board: [Card]) -> Double {
    let blocked = Set(hero + board)
    var sum = 0.0, n = 0
    for combo in villainCombos {
        if combo.contains(where: { blocked.contains($0) }) { continue }
        sum += exactEquityHeadsUp(hero: hero, villain: combo, board: board).equity
        n += 1
    }
    return n == 0 ? 0 : sum / Double(n)
}

/// Invoke `body` once per k-combination of `items` (no allocation of the full list).
func forEachCombination(of items: [Card], choose k: Int, _ body: ([Card]) -> Void) {
    if k == 0 { body([]); return }
    let n = items.count
    if k > n { return }
    var idx = Array(0..<k)
    var buf = [Card](repeating: items[0], count: k)
    while true {
        for i in 0..<k { buf[i] = items[idx[i]] }
        body(buf)
        // advance indices (lexicographic)
        var i = k - 1
        while i >= 0 && idx[i] == n - k + i { i -= 1 }
        if i < 0 { break }
        idx[i] += 1
        for j in (i+1)..<k { idx[j] = idx[j-1] + 1 }
    }
}
