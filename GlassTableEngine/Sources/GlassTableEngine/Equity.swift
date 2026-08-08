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
    let need = 5 - board.count
    precondition(need >= 0)

    // A complete board needs no deck at all. Building one — a 9-card Set plus a
    // 52-card filter — cost more than the two evaluations it was setting up for, and
    // this is the path `equityVsRange` walks once per villain combo.
    if need == 0 {
        var seven = hero + board
        let h = evaluate7(seven)
        seven[0] = villain[0]; seven[1] = villain[1]
        let v = evaluate7(seven)
        return EquityResult(wins: h > v ? 1 : 0, ties: h == v ? 1 : 0, total: 1)
    }

    var known = 0 as UInt64
    for c in hero + villain + board { known |= 1 << UInt64(c.rank * 4 + c.suit) }
    let remaining = Deck.all.filter { known & (1 << UInt64($0.rank * 4 + $0.suit)) == 0 }

    // One buffer each, refilled per completion, rather than three fresh arrays.
    var heroSeven = hero + board + [Card](repeating: hero[0], count: need)
    var villainSeven = villain + board + [Card](repeating: hero[0], count: need)
    let tail = 2 + board.count

    var wins = 0, ties = 0, total = 0
    forEachCombination(of: remaining, choose: need) { completion in
        for i in 0..<need {
            heroSeven[tail + i] = completion[i]
            villainSeven[tail + i] = completion[i]
        }
        let h = evaluate7(heroSeven)
        let v = evaluate7(villainSeven)
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
    var known = 0 as UInt64
    for c in hero + villain + board { known |= 1 << UInt64(c.rank * 4 + c.suit) }
    var deck = Deck.all.filter { known & (1 << UInt64($0.rank * 4 + $0.suit)) == 0 }
    let need = 5 - board.count
    var rng = SplitMix64(seed: seed)

    var heroSeven = hero + board + [Card](repeating: hero[0], count: need)
    var villainSeven = villain + board + [Card](repeating: hero[0], count: need)
    let tail = 2 + board.count

    var wins = 0, ties = 0
    for _ in 0..<iterations {
        // Partial shuffle: draw `need` cards to the front.
        for i in 0..<need {
            let j = Int(rng.next() % UInt64(deck.count - i)) + i
            deck.swapAt(i, j)
            heroSeven[tail + i] = deck[i]
            villainSeven[tail + i] = deck[i]
        }
        let h = evaluate7(heroSeven)
        let v = evaluate7(villainSeven)
        if h > v { wins += 1 } else if h == v { ties += 1 }
    }
    return EquityResult(wins: wins, ties: ties, total: iterations)
}

/// Hero's equity averaged over a villain range (a list of 2-card combos).
/// Combos colliding with hero's cards or the board are skipped.
public func equityVsRange(hero: [Card], villainCombos: [[Card]], board: [Card]) -> Double {
    var blocked = 0 as UInt64
    for c in hero + board { blocked |= 1 << UInt64(c.rank * 4 + c.suit) }
    @inline(__always) func isBlocked(_ c: Card) -> Bool {
        blocked & (1 << UInt64(c.rank * 4 + c.suit)) != 0
    }

    // Complete board: hero's key is fixed across every villain combo, so hoist it and
    // compare against one villain evaluation per combo instead of two.
    if board.count == 5 {
        let heroKey = evaluate7(hero + board)
        var seven = hero + board
        var sum = 0.0, n = 0
        for combo in villainCombos {
            if isBlocked(combo[0]) || isBlocked(combo[1]) { continue }
            seven[0] = combo[0]; seven[1] = combo[1]
            let v = evaluate7(seven)
            sum += heroKey > v ? 1 : (heroKey == v ? 0.5 : 0)
            n += 1
        }
        return n == 0 ? 0 : sum / Double(n)
    }

    var sum = 0.0, n = 0
    for combo in villainCombos {
        if isBlocked(combo[0]) || isBlocked(combo[1]) { continue }
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
