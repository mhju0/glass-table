// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// "How many combos of X remain?" given removed (visible) cards.
/// Kinds used: .pair, .any, .suited — offsuit deferred (any − suited; more
/// confusing than instructive). Ranks are always T–A (10...14).
public struct BlockerSpot: Equatable {
    public let rankA: Int          // for non-pairs, always the higher rank
    public let rankB: Int
    public let kind: ComboKind
    public let removed: [Card]
    public let count: Int

    /// "QQ", "AK", "AKs" — acronyms Latin per decisions.md §F.
    public var className: String {
        switch kind {
        case .pair: return rankName(rankA) + rankName(rankA)
        case .suited: return rankName(rankA) + rankName(rankB) + "s"
        default: return rankName(rankA) + rankName(rankB)
        }
    }
    /// Unblocked baseline for the class — the stepper's starting value.
    public var baseline: Int {
        switch kind { case .pair: return 6; case .suited: return 4; default: return 16 }
    }
}

/// T–A only; the generator never produces ranks below 10.
func rankName(_ r: Int) -> String { ["T", "J", "Q", "K", "A"][r - 10] }

/// Deterministic blocker questions. Same (baseSeed, index) → same spot.
public enum BlockerSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> BlockerSpot {
        var attempt = 0
        while true {
            let seed = baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt)
            var rng = SplitMix64(seed: seed)
            let roll = rng.next() % 3
            var rankA = Int.random(in: 10...14, using: &rng)
            var rankB = rankA
            let kind: ComboKind
            if roll == 0 {
                kind = .pair
            } else {
                kind = roll == 1 ? .any : .suited
                repeat { rankB = Int.random(in: 10...14, using: &rng) } while rankB == rankA
                if rankB > rankA { swap(&rankA, &rankB) }
            }
            let k = Int.random(in: 2...4, using: &rng)
            let removed = Array(Deck.all.shuffled(using: &rng)[0..<k])
            // The answer must differ from the baseline: ≥1 removed card hits the class.
            guard removed.contains(where: { $0.rank == rankA || $0.rank == rankB }) else {
                attempt += 1
                continue
            }
            return BlockerSpot(rankA: rankA, rankB: rankB, kind: kind, removed: removed,
                               count: comboCount(rankA: rankA, rankB: rankB, kind: kind,
                                                 removed: Set(removed)))
        }
    }
}

public struct BlockerReveal: GradedReveal {
    public let band: GradeBand
    public let estimate: Int
    public let count: Int
    public let whyText: String
}

/// Same bands as the Outs drill: exact = 정확, ±2 = 근접, else = 빗나감.
public func gradeBlocker(estimate: Int, spot: BlockerSpot) -> BlockerReveal {
    BlockerReveal(
        band: gradeEstimate(user: Double(estimate), correct: Double(spot.count),
                            closeWithin: 2, spotOnWithin: 0),
        estimate: estimate, count: spot.count, whyText: whyText(for: spot))
}

func whyText(for spot: BlockerSpot) -> String {
    let removedSet = Set(spot.removed)
    func left(_ rank: Int) -> Int {
        (0...3).filter { !removedSet.contains(Card(rank: rank, suit: $0)) }.count
    }
    let na = left(spot.rankA)
    switch spot.kind {
    case .pair:
        return "\(rankName(spot.rankA)) \(na)장 남음 → \(na)×\(na - 1)÷2 = \(spot.count) 콤보"
    case .suited:
        return "양쪽 다 남은 무늬 \(spot.count)개 = \(spot.count) 콤보"
    default:
        return "\(rankName(spot.rankA)) \(na)장 × \(rankName(spot.rankB)) \(left(spot.rankB))장 = \(spot.count) 콤보"
    }
}
