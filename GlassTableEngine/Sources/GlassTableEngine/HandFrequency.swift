// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// How often each hand category is the best five of seven random cards.
///
/// These are exact counts over all C(52, 7) = 133,784,560 seven-card sets. They are
/// stored rather than computed at launch because the full enumeration takes seconds;
/// `HandFrequencyTests` recounts every set with this module's own evaluator, so the
/// table cannot drift from the rules the rest of the app grades with.
public enum HandFrequency {
    public static let sevenCardTotal = 133_784_560

    /// Indexed by `HandBrief.category` (0 = high card … 8 = straight flush). The
    /// straight-flush entry includes royal flushes.
    public static let sevenCardCounts: [Int] = [
        23_294_460,  // high card
        58_627_800,  // one pair
        31_433_400,  // two pair
        6_461_620,   // three of a kind
        6_180_020,   // straight
        4_047_644,   // flush
        3_473_184,   // full house
        224_848,     // four of a kind
        41_584,      // straight flush, royal included
    ]

    /// Seven-card sets whose best hand is the ace-high straight flush.
    public static let royalFlushCount = 4_324

    /// Share of all seven-card sets, 0…1, for one category. For category 8 this
    /// includes royal flushes; the two properties below split them apart.
    public static func share(ofCategory category: Int) -> Double {
        Double(sevenCardCounts[category]) / Double(sevenCardTotal)
    }

    public static var royalFlushShare: Double {
        Double(royalFlushCount) / Double(sevenCardTotal)
    }

    public static var straightFlushWithoutRoyalShare: Double {
        Double(sevenCardCounts[8] - royalFlushCount) / Double(sevenCardTotal)
    }
}
