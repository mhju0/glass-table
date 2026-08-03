// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// One of the 169 starting-hand classes — the cells of a 13×13 grid.
///
/// A class is not a holding: `AKs` is four concrete combos, `QQ` is six, `AKo` is
/// twelve. That asymmetry is why anything counting a range has to weight by
/// `comboCount` rather than by class, and it is the single most common place to be
/// wrong by roughly a factor of two.
public struct HandClass: Hashable, Sendable, CustomStringConvertible, Comparable {
    /// 2...14. For a pair, `high == low`.
    public let high: Int
    public let low: Int
    /// Always `false` for a pair — two cards of the same rank cannot share a suit.
    public let suited: Bool

    public init?(high: Int, low: Int, suited: Bool) {
        guard (2...14).contains(high), (2...14).contains(low), low <= high else { return nil }
        guard !(high == low && suited) else { return nil }
        self.high = high; self.low = low; self.suited = suited
    }

    /// The class a concrete two-card holding belongs to.
    public init?(_ cards: [Card]) {
        guard cards.count == 2 else { return nil }
        let hi = max(cards[0].rank, cards[1].rank)
        let lo = min(cards[0].rank, cards[1].rank)
        let s = hi != lo && cards[0].suit == cards[1].suit
        self.init(high: hi, low: lo, suited: s)
    }

    public var isPair: Bool { high == low }

    /// 6 for a pair, 4 suited, 12 offsuit — 169 classes, 1326 combos.
    public var comboCount: Int { isPair ? 6 : (suited ? 4 : 12) }

    /// "AA", "AKs", "T9o" — the notation every chart and solver already uses.
    public var description: String {
        let r = HandClass.rankChars
        if isPair { return "\(r[high - 2])\(r[low - 2])" }
        return "\(r[high - 2])\(r[low - 2])\(suited ? "s" : "o")"
    }

    /// Rank letters in chart notation. Public because the drill generators build
    /// notation strings from them, and two copies would be one too many.
    public static let rankChars = Array("23456789TJQKA").map(String.init)

    /// All 169, in no particular order.
    public static let all: [HandClass] = {
        var out: [HandClass] = []
        for hi in 2...14 {
            for lo in 2...hi {
                if hi == lo { out.append(HandClass(high: hi, low: lo, suited: false)!) }
                else {
                    out.append(HandClass(high: hi, low: lo, suited: true)!)
                    out.append(HandClass(high: hi, low: lo, suited: false)!)
                }
            }
        }
        return out
    }()

    /// Total combos across all classes — the denominator for any range percentage.
    public static let totalCombos = 1326

    /// Arbitrary but stable, so ranges print deterministically.
    public static func < (a: HandClass, b: HandClass) -> Bool {
        if a.high != b.high { return a.high > b.high }
        if a.low != b.low { return a.low > b.low }
        return a.suited && !b.suited
    }

    /// Every concrete two-card combo in this class, minus any dead cards.
    public func combos(removing dead: Set<Card> = []) -> [[Card]] {
        var out: [[Card]] = []
        if isPair {
            let cards = (0..<4).map { Card(rank: high, suit: $0) }.filter { !dead.contains($0) }
            for i in 0..<cards.count {
                for j in (i + 1)..<cards.count { out.append([cards[i], cards[j]]) }
            }
        } else if suited {
            for s in 0..<4 {
                let a = Card(rank: high, suit: s), b = Card(rank: low, suit: s)
                if !dead.contains(a) && !dead.contains(b) { out.append([a, b]) }
            }
        } else {
            for sa in 0..<4 {
                for sb in 0..<4 where sa != sb {
                    let a = Card(rank: high, suit: sa), b = Card(rank: low, suit: sb)
                    if !dead.contains(a) && !dead.contains(b) { out.append([a, b]) }
                }
            }
        }
        return out
    }
}
