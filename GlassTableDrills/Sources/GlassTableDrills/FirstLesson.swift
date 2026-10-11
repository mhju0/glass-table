// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Curated, ungraded comparisons for the required beginner path.
public enum FirstLesson {
    public static let currentComparisonVersion = 2

    public enum Rule: String, CaseIterable, Sendable {
        case pairOverHighCard, higherPair, trips, straight, flush
    }

    public struct Comparison: Equatable {
        public let rule: Rule
        public let spot: ShowdownSpot
    }

    /// Rank and card-use changes provide transfer practice, rather than suit-only changes.
    public static func bank(for rule: Rule, version: Int = currentComparisonVersion) -> [ShowdownSpot] {
        precondition((1...currentComparisonVersion).contains(version))
        var variants = legacyBank(for: rule)
        if version == 2, rule == .flush {
            variants[0] = ShowdownSpot(hero: Card.parse("Ad3c")!, villain: Card.parse("6cQc")!,
                                       board: Card.parse("7d8d9dTd2c")!)
        }
        return variants
    }

    private static func legacyBank(for rule: Rule) -> [ShowdownSpot] {
        func spot(_ hero: String, _ villain: String, _ board: String) -> ShowdownSpot {
            ShowdownSpot(hero: Card.parse(hero)!, villain: Card.parse(villain)!, board: Card.parse(board)!)
        }
        switch rule {
        case .pairOverHighCard:
            return [spot("8h8c", "AdKc", "2s5d7cJhQs"),
                    spot("Qh3c", "AdTc", "Qs2d6c9hJs"),
                    spot("6h6d", "AsQc", "2c4s8dJhKs")]
        case .higherPair:
            return [example, transfer,
                    spot("Jh4c", "8d3c", "Js8h2d6cKs")]
        case .trips:
            return [legacyComparisons[0],
                    spot("ThTd", "AhAc", "Ts3d6c9hKs"),
                    spot("Qh3c", "AhAc", "QsQd2c8hKs")]
        case .straight:
            return [legacyComparisons[1],
                    spot("Ah4d", "KcKd", "2s3h5c9dKh"),
                    spot("JhTd", "AcAd", "9s8h7c2dAh")]
        case .flush:
            return [legacyComparisons[2],
                    spot("Kh4h", "QcJc", "2h7h9hTd8s"),
                    spot("Ac3d", "7c5c", "8d6d4d9dTs")]
        }
    }

    /// Teaching order stays fixed; a saved version keeps each response attached to its cards.
    public static func requiredComparisons(seed: UInt64,
                                           version: Int = currentComparisonVersion) -> [Comparison] {
        precondition((1...currentComparisonVersion).contains(version))
        if version == 1 {
            return Rule.allCases.map { rule in
                let variants = legacyBank(for: rule)
                let spot = variants[Int(seed % UInt64(variants.count))]
                let swap = (seed / UInt64(variants.count)) % 2 == 1
                return Comparison(rule: rule, spot: swap ? swapped(spot) : spot)
            }
        }
        var rng = SplitMix64(seed: seed)
        let heroWinCount = Bool.random(using: &rng) ? 2 : 3
        let heroWins = (Array(repeating: true, count: heroWinCount)
            + Array(repeating: false, count: 5 - heroWinCount)).shuffled(using: &rng)
        return zip(Rule.allCases, heroWins).map { rule, heroWins in
            let variants = bank(for: rule, version: version)
            let spot = variants[Int.random(in: variants.indices, using: &rng)]
            return Comparison(rule: rule, spot: (spot.winner == 0) == heroWins ? spot : swapped(spot))
        }
    }

    private static func swapped(_ spot: ShowdownSpot) -> ShowdownSpot {
        ShowdownSpot(hero: spot.villain, villain: spot.hero, board: spot.board)
    }

    public static let example = ShowdownSpot(
        hero: [Card(rank: 14, suit: 3), Card(rank: 14, suit: 1)],
        villain: [Card(rank: 13, suit: 3), Card(rank: 13, suit: 1)],
        board: [Card(rank: 2, suit: 0), Card(rank: 5, suit: 1),
                Card(rank: 8, suit: 2), Card(rank: 11, suit: 0),
                Card(rank: 12, suit: 3)]
    )

    public static let transfer = ShowdownSpot(
        hero: [Card(rank: 8, suit: 3), Card(rank: 8, suit: 2)],
        villain: [Card(rank: 10, suit: 0), Card(rank: 10, suit: 1)],
        board: [Card(rank: 2, suit: 1), Card(rank: 4, suit: 0),
                Card(rank: 7, suit: 3), Card(rank: 11, suit: 2),
                Card(rank: 12, suit: 1)]
    )

    public static func pairExample(seed: UInt64, transfer: Bool) -> ShowdownSpot {
        let spot = transfer ? self.transfer : example
        let rotation = Int(seed % 4)
        func rotated(_ cards: [Card]) -> [Card] {
            cards.map { Card(rank: $0.rank, suit: ($0.suit + rotation) % 4) }
        }
        let swap = (seed / 4) % 2 == 1
        return ShowdownSpot(hero: rotated(swap ? spot.villain : spot.hero),
                            villain: rotated(swap ? spot.hero : spot.villain), board: rotated(spot.board))
    }

    private static let legacyComparisons: [ShowdownSpot] = [
        ShowdownSpot(hero: Card.parse("7h7c")!, villain: Card.parse("KdKc")!,
                     board: Card.parse("7s2d4c9hQs")!),
        ShowdownSpot(hero: Card.parse("9h8d")!, villain: Card.parse("QcQd")!,
                     board: Card.parse("7s6h5c2dQh")!),
        ShowdownSpot(hero: Card.parse("Ad3d")!, villain: Card.parse("6cQc")!,
                     board: Card.parse("7d8d9dTd2c")!),
    ]

    public static let comparisons: [ShowdownSpot] = [
        legacyComparisons[0], legacyComparisons[1], bank(for: .flush)[0]
    ]

    /// Stable within one visit; rotate the optional practice order on later visits.
    public static func comparisonOrder(seed: UInt64) -> [ShowdownSpot] {
        var rng = SplitMix64(seed: seed)
        return comparisons.shuffled(using: &rng).map { spot in
            Bool.random(using: &rng)
                ? ShowdownSpot(hero: spot.villain, villain: spot.hero, board: spot.board) : spot
        }
    }
}
