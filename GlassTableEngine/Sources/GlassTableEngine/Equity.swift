// Copyright (c) 2026 Michael Ju

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
