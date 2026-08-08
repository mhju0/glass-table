// Copyright (c) 2026 Michael Ju (github.com/mhju0)
// ponytail: naive 5-card classifier taken best-of-7 in evaluate7. Allocation-free hot
// path (rank multiplicities packed 4 bits per rank in one UInt64, no dict/set/sorted/map,
// and no per-subhand array in evaluate7) so the exact-enumeration and Monte-Carlo test
// gates run in seconds, not minutes. Same algorithm and same integer keys as the original
// dictionary version — only the constant factor changed. Swap for a perfect-hash
// evaluator only when Milestone 3 (8-way Table Monte Carlo) profiling shows this is
// still the bottleneck.

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

    // Rank multiplicities packed 4 bits per rank (rank r lives in nibble r), so the
    // scratch buffer, its zeroing, and the 52-iteration tiebreak sweep all go away.
    var packed: UInt64 = 0
    packed &+= 1 << UInt64(c0.rank << 2)
    packed &+= 1 << UInt64(c1.rank << 2)
    packed &+= 1 << UInt64(c2.rank << 2)
    packed &+= 1 << UInt64(c3.rank << 2)
    packed &+= 1 << UInt64(c4.rank << 2)

    // One high→low pass: a rank mask per multiplicity, plus the extremes.
    var m1 = 0, m2 = 0, m3 = 0, m4 = 0
    var n2 = 0, n3 = 0, n4 = 0, nDistinct = 0
    var hi = 0, lo = 0
    var r = 14
    while r >= 2 {
        let cnt = Int((packed >> UInt64(r << 2)) & 0xF)
        if cnt > 0 {
            nDistinct += 1
            if hi == 0 { hi = r }  // first present = highest
            lo = r                 // last present so far = lowest
            switch cnt {
            case 1: m1 |= 1 << r
            case 2: m2 |= 1 << r; n2 += 1
            case 3: m3 |= 1 << r; n3 += 1
            default: m4 |= 1 << r; n4 += 1
            }
        }
        r -= 1
    }

    // Straight detection (needs 5 distinct ranks; Ace-low wheel handled explicitly).
    var straightHigh = 0
    if nDistinct == 5 {
        if hi - lo == 4 {
            straightHigh = hi
        } else if m1 == (1 << 14) | (1 << 5) | (1 << 4) | (1 << 3) | (1 << 2) {
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
        emitRanks(m4, &key, &slots)
        emitRanks(m3, &key, &slots)
        emitRanks(m2, &key, &slots)
        emitRanks(m1, &key, &slots)
        while slots < 5 { key = key * 16; slots += 1 }
    }
    return key
}

/// Append every rank in `mask`, highest first, to the base-16 tiebreak key.
@inline(__always)
private func emitRanks(_ mask: Int, _ key: inout Int, _ slots: inout Int) {
    var m = mask
    while m != 0 {
        let r = 63 - m.leadingZeroBitCount
        key = key * 16 + r
        slots += 1
        m &= ~(1 << r)
    }
}

/// Beginner-facing summary of a hand: category plus the rank that defines it
/// (pair rank, trip rank, straight/flush high card, …).
public struct HandBrief: Equatable {
    public let category: Int  // 0=high card, 1=pair, 2=two pair, 3=trips, 4=straight,
                              // 5=flush, 6=full house, 7=quads, 8=straight flush
    public let topRank: Int   // 2...14
    public init(category: Int, topRank: Int) {
        self.category = category; self.topRank = topRank
    }
}

/// Summarize the best 5-card hand out of 7. The evaluate key packs category in the
/// top base-16 slot and the defining rank in the next, so this is pure arithmetic.
public func bestHand(_ seven: [Card]) -> HandBrief {
    let key = evaluate7(seven)
    return HandBrief(category: key >> 20, topRank: (key >> 16) & 0xF)
}

// The 21 five-card index combinations of 7 cards, flattened: combination `i` occupies
// slots `5*i ..< 5*i+5`. Flat rather than `[[Int]]` so the hot loop reads contiguous
// memory instead of chasing 21 separate array buffers.
private let combos7choose5: [Int] = {
    var out: [Int] = []
    out.reserveCapacity(105)
    let n = 7
    for a in 0..<n { for b in (a+1)..<n { for c in (b+1)..<n {
        for d in (c+1)..<n { for e in (d+1)..<n {
            out.append(contentsOf: [a, b, c, d, e])
        } } }
    } }
    return out  // 21 combinations × 5
}()

/// Best 5-card rank out of 7 cards. Same scale as `evaluate5`.
func evaluate7(_ cards: [Card]) -> Int {
    precondition(cards.count == 7)
    var best = 0
    cards.withUnsafeBufferPointer { c in
        combos7choose5.withUnsafeBufferPointer { t in
            var i = 0
            while i < 105 {
                let key = eval5(c[t[i]], c[t[i+1]], c[t[i+2]], c[t[i+3]], c[t[i+4]])
                if key > best { best = key }
                i += 5
            }
        }
    }
    return best
}

/// Best 5-card key from 5, 6 or 7 cards, without materialising index combinations.
/// `bestFiveCards` needs the winning subset; the classifiers only need the key.
func bestKeyOfAny(_ cards: [Card]) -> Int {
    switch cards.count {
    case 5: return eval5(cards[0], cards[1], cards[2], cards[3], cards[4])
    case 7: return evaluate7(cards)
    default: break
    }
    // Six cards: the six ways to drop one.
    precondition(cards.count == 6)
    var best = 0
    for drop in 0..<6 {
        var f = [Card]()
        f.reserveCapacity(5)
        for i in 0..<6 where i != drop { f.append(cards[i]) }
        let key = eval5(f[0], f[1], f[2], f[3], f[4])
        if key > best { best = key }
    }
    return best
}

/// Which five of seven cards actually play — the subset `evaluate7` scored highest.
///
/// `evaluate7` returns only the score, so the winning combination is otherwise
/// unrecoverable. Teaching surfaces need the cards themselves: "your hand is two pair"
/// means nothing next to a highlight covering all seven.
///
/// Ties are impossible to observe here: two subsets scoring equal are the same hand by
/// definition (e.g. two identical kickers cannot both be in one seven-card set), so
/// returning the first maximum is deterministic and correct.
/// Accepts 5–7 cards, so a hand can be named at the turn (2 + 4 = six cards) as well
/// as at showdown. Teaching the street-by-street progression needs both.
public func bestFiveCards(_ cards: [Card]) -> [Card] {
    precondition((5...7).contains(cards.count))
    var best = 0
    var bestIdx: [Int] = []
    for combo in combinations(of: cards.count, choose: 5) {
        let key = eval5(cards[combo[0]], cards[combo[1]], cards[combo[2]],
                        cards[combo[3]], cards[combo[4]])
        if key > best { best = key; bestIdx = combo }
    }
    return bestIdx.map { cards[$0] }
}

/// Summarize the best hand from 5–7 cards. `bestHand` requires exactly seven, which
/// makes it unusable on a turn board — this is the street-agnostic form.
public func bestHandOfAny(_ cards: [Card]) -> HandBrief {
    let key = bestKeyOfAny(cards)
    return HandBrief(category: key >> 20, topRank: (key >> 16) & 0xF)
}

/// Index combinations. At most 21 of them (7 choose 5), so this is computed per call
/// rather than cached — a global cache here would buy nothing and cost thread safety.
private func combinations(of n: Int, choose k: Int) -> [[Int]] {
    var out: [[Int]] = []
    var idx = Array(0..<k)
    while true {
        out.append(idx)
        var i = k - 1
        while i >= 0 && idx[i] == n - k + i { i -= 1 }
        if i < 0 { break }
        idx[i] += 1
        for j in (i + 1)..<k { idx[j] = idx[j - 1] + 1 }
    }
    return out
}
