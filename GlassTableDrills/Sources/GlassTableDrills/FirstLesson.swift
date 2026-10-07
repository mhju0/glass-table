// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Two minimal pair comparisons followed by optional best-five comparisons.
public enum FirstLesson {
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

    public static let comparisons: [ShowdownSpot] = [
        ShowdownSpot(hero: Card.parse("7h7c")!, villain: Card.parse("KdKc")!,
                     board: Card.parse("7s2d4c9hQs")!),
        ShowdownSpot(hero: Card.parse("9h8d")!, villain: Card.parse("QcQd")!,
                     board: Card.parse("7s6h5c2dQh")!),
        ShowdownSpot(hero: Card.parse("Ad3d")!, villain: Card.parse("6cQc")!,
                     board: Card.parse("7d8d9dTd2c")!),
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
