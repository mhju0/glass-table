// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// What a whole range is doing on one board: the combo-weighted share of each bucket.
///
/// Combo-weighted, not class-weighted, and with the board's own cards removed — AA is
/// six combos but only three of them survive an ace on the flop, and a distribution
/// that ignored that would overstate every big pair.
public struct RangeOnBoard: Equatable, Sendable {
    /// Shares by bucket, summing to 1 (or all zero for an empty range).
    public let shares: [MadeHand: Double]
    /// Combos of the range that the board did not block.
    public let liveCombos: Int

    public func share(_ bucket: MadeHand) -> Double { shares[bucket] ?? 0 }

    /// Anything but `air`. One subtraction rather than a special rule (spec §1) —
    /// guarded, because an empty range has no air either and 1 − 0 would claim it hit
    /// everything.
    public var hitRate: Double { liveCombos == 0 ? 0 : 1 - share(.air) }

    /// A made pair or better — the number that actually drives a bet, and the one the
    /// 히트 프리퀀시 drill grades on. `hitRate` counts draws too, which is a different
    /// and also useful question; keeping both named stops either from being fudged.
    public var pairOrBetter: Double { share(.weakPair) + share(.topPair) + share(.strong) }
}

public func rangeOnBoard(_ range: HandRange, board: [Card]) -> RangeOnBoard {
    rangeOnBoard(combos: range.combos(removing: board), board: board)
}

/// The same distribution over an explicit combo list.
///
/// This is how a *subset* of a range gets a `RangeOnBoard` — an action-narrowed range
/// (R4-S3) is combo-level, since A♠K♠ and A♥K♥ land in different buckets on a spade
/// board, so no `HandRange` can describe it. The factory keeps the type's invariant
/// (shares sum to 1 over live combos) where a public memberwise init could not.
///
/// Combos that intersect the board are skipped rather than trusted away, so a caller
/// holding a stale list cannot corrupt the shares.
public func rangeOnBoard(combos: [[Card]], board: [Card]) -> RangeOnBoard {
    precondition((3...5).contains(board.count))
    var counts = [MadeHand: Int]()
    var live = 0
    for combo in combos where !combo.contains(where: board.contains) {
        counts[madeHand(hand: combo, board: board), default: 0] += 1
        live += 1
    }
    guard live > 0 else { return RangeOnBoard(shares: [:], liveCombos: 0) }
    var shares = [MadeHand: Double]()
    for b in MadeHand.allCases { shares[b] = Double(counts[b] ?? 0) / Double(live) }
    return RangeOnBoard(shares: shares, liveCombos: live)
}

// MARK: - range versus range

/// Hero's share of the pot when this range runs out against that one on this board.
///
/// **Fixed-seed Monte Carlo over (hero combo, villain combo, runout) triples.** Exact
/// enumeration on a flop is ~990 runouts × 200 × 200 combo pairs once card collisions
/// are rejected per pair — and they must be, since two players cannot hold the same
/// card. Sampling makes the rejection trivial and costs two evaluations per sample.
///
/// At the default 8,000 samples the standard error is ≈0.56 percentage points — seven
/// times inside the drill's 4-point spot-on band — and the fixed seed makes it
/// reproducible. Measured cost per call: **34ms release, 1.2s debug**. That debug
/// figure is why callers must not run this on the main thread; 20,000 samples was the
/// original default and froze the drill screen for three seconds under a debug build.
///
/// Callers that need the exact number on a complete board can enumerate; this is the
/// one used for teaching, and the reveal says it is sampled.
public func rangeEquity(hero: HandRange, villain: HandRange, board: [Card],
                        samples: Int = 8_000, seed: UInt64 = 0x5EED) -> Double {
    let heroCombos = hero.combos(removing: board)
    let villainCombos = villain.combos(removing: board)
    guard !heroCombos.isEmpty, !villainCombos.isEmpty else { return 0.5 }

    var known = 0 as UInt64
    for c in board { known |= 1 << UInt64(c.rank * 4 + c.suit) }
    let deck = Deck.all.filter { known & (1 << UInt64($0.rank * 4 + $0.suit)) == 0 }
    let need = 5 - board.count
    var rng = SplitMix64(seed: seed)

    // Scratch reused across samples. The old loop allocated a fresh 48-card `pool`,
    // a `runout`, a `board + runout` and two 7-card concatenations *per sample* —
    // four array allocations times 8,000.
    var pool = deck
    var heroSeven = [Card](repeating: deck[0], count: 7)
    var villainSeven = [Card](repeating: deck[0], count: 7)
    for i in 0..<board.count { heroSeven[2 + i] = board[i]; villainSeven[2 + i] = board[i] }
    let tail = 2 + board.count

    var score = 0.0
    var taken = 0
    // Bounded so a pathological pair of ranges (one combo each, fully colliding) cannot
    // spin forever; it returns the samples it managed instead.
    var attempts = 0
    let attemptCap = samples * 20

    while taken < samples && attempts < attemptCap {
        attempts += 1
        let h = heroCombos[Int(rng.next() % UInt64(heroCombos.count))]
        let v = villainCombos[Int(rng.next() % UInt64(villainCombos.count))]
        if h[0] == v[0] || h[0] == v[1] || h[1] == v[0] || h[1] == v[1] { continue }

        heroSeven[0] = h[0]; heroSeven[1] = h[1]
        villainSeven[0] = v[0]; villainSeven[1] = v[1]
        if need > 0 {
            // Compact the four dead cards out of the reused pool in place, then partial
            // Fisher-Yates over what is left.
            var live = 0
            for c in deck where c != h[0] && c != h[1] && c != v[0] && c != v[1] {
                pool[live] = c; live += 1
            }
            for i in 0..<need {
                let j = Int(rng.next() % UInt64(live - i)) + i
                pool.swapAt(i, j)
                heroSeven[tail + i] = pool[i]
                villainSeven[tail + i] = pool[i]
            }
        }
        let hv = evaluate7(heroSeven), vv = evaluate7(villainSeven)
        score += hv > vv ? 1 : (hv == vv ? 0.5 : 0)
        taken += 1
    }
    return taken == 0 ? 0.5 : score / Double(taken)
}
