// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Two intentionally simple, complete Hold'em hands for the first experience.
/// The board cannot make a straight, flush, pair, or stronger shared hand, so the
/// pocket-pair comparison is the only rule the learner needs.
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
}
