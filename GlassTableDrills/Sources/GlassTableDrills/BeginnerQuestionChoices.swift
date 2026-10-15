// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum BeginnerQuestionChoices {
    public static func integers(answer: Int, bounds: ClosedRange<Int>, seed: UInt64,
                                count: Int = 3) -> [Int] {
        precondition(bounds.contains(answer))
        let target = min(max(2, count), bounds.count)
        var values = [answer]
        var rng = SplitMix64(seed: seed)
        let distances = [1, 2, 3, 5, 10].shuffled(using: &rng)
        for distance in distances {
            for value in [answer - distance, answer + distance].shuffled(using: &rng) {
                if bounds.contains(value), !values.contains(value) { values.append(value) }
                if values.count == target { return values.shuffled(using: &rng) }
            }
        }
        for value in bounds where !values.contains(value) {
            values.append(value)
            if values.count == target { break }
        }
        return values.shuffled(using: &rng)
    }

    /// Choices for a price share (pot odds, MDF): the rounded answer and two that are
    /// at least 15 points off, beyond the 2.5-point spot-on band, so only one is right.
    public static func shares(answer: Double, seed: UInt64) -> [Int] {
        percentages(answer: answer, seed: seed).map { Int($0) }
    }

    public static func percentages(answer: Double, seed: UInt64, count: Int = 3) -> [Double] {
        let truth = min(100, max(0, Int(answer.rounded())))
        var rng = SplitMix64(seed: seed)
        var values = [truth]
        for offset in [-35, -25, -15, 15, 25, 35].shuffled(using: &rng) {
            let value = truth + offset
            if (0...100).contains(value), !values.contains(value) { values.append(value) }
            if values.count == min(3, max(2, count)) { break }
        }
        return values.shuffled(using: &rng).map(Double.init)
    }
    public static func rangeEstimates(spot: RangeReadSpot, seed: UInt64) -> [RangeEstimate] {
        let factor = Archetype.seatFactor(spot.seat)
        let raising = spot.archetype.pfr * factor
        let calling: Bool
        if case .called = spot.action { calling = true } else { calling = false }
        let truth = RangeEstimate(width: min(80, max(3, calling ? spot.archetype.passiveGap * factor : raising)),
                                  excludedTop: calling ? raising : 0)
        let smaller = truth.width < 9 ? truth.width + 12 : max(3, truth.width * 0.25)
        let narrow = RangeEstimate(width: smaller,
                                   excludedTop: truth.excludedTop)
        let wide = RangeEstimate(width: truth.width > 50 ? truth.width * 0.5 : min(80, max(truth.width + 20, truth.width * 2.5)),
                                 excludedTop: truth.excludedTop)
        var rng = SplitMix64(seed: seed)
        return [truth, narrow, wide].shuffled(using: &rng)
    }

}

/// Select only at session creation; saved seeds and generator indexes never change.
public enum LessonSessionSeed {
    public static func variedDefend(_ seed: UInt64, indexes: [Int] = [2, 3, 4]) -> UInt64 {
        guard indexes.count >= 3 else { return seed }
        for offset in 0..<512 {
            let candidate = seed &+ UInt64(offset) &* 0x9E37_79B9_7F4A_7C15
            let actions = Set(indexes.map { DefendSpotGenerator.spot(baseSeed: candidate, index: $0).correct })
            if actions.count == DefendAction.allCases.count { return candidate }
        }
        return seed
    }
}

public struct OutsOutcomeGroup: Equatable {
    public let cards: [Card]
    public let heroCategory: Int
    public let heroRanks: [Int]
    public let villainCategory: Int
    public let villainRanks: [Int]
    public let winner: Int
}

public enum OutsOutcomeGroups {
    /// Rank multisets of the engine-selected best five retain every kicker and
    /// lower pair. Suits remain on candidate cards but do not break poker ties.
    /// Groups come strongest hero hand first; cards within a group ace first.
    public static func make(hero: [Card], villain: [Card], board: [Card], candidates: [Card]) -> [OutsOutcomeGroup] {
        let known = hero + villain + board
        guard hero.count == 2, villain.count == 2, board.count == 4,
              Set(known).count == 8,
              (known + candidates).allSatisfy({ (2...14).contains($0.rank) && (0...3).contains($0.suit) })
        else { return [] }
        var groups: [OutsOutcomeGroup] = []
        for card in candidates where !(hero + villain + board).contains(card) {
            let spot = ShowdownSpot(hero: hero, villain: villain, board: board + [card])
            let h = bestFiveCards(hero + spot.board).map(\.rank).sorted(by: >)
            let v = bestFiveCards(villain + spot.board).map(\.rank).sorted(by: >)
            let hc = spot.heroBest.category, vc = spot.villainBest.category, winner = spot.winner
            if let index = groups.firstIndex(where: {
                $0.heroCategory == hc && $0.heroRanks == h && $0.villainCategory == vc
                    && $0.villainRanks == v && $0.winner == winner
            }) {
                let old = groups[index]
                if !old.cards.contains(card) {
                    groups[index] = OutsOutcomeGroup(cards: old.cards + [card], heroCategory: hc,
                        heroRanks: h, villainCategory: vc, villainRanks: v, winner: winner)
                }
            } else {
                groups.append(OutsOutcomeGroup(cards: [card], heroCategory: hc, heroRanks: h,
                    villainCategory: vc, villainRanks: v, winner: winner))
            }
        }
        return groups
            .map { group in
                OutsOutcomeGroup(cards: group.cards.sorted(by: BeatScript.byRank),
                                 heroCategory: group.heroCategory, heroRanks: group.heroRanks,
                                 villainCategory: group.villainCategory, villainRanks: group.villainRanks,
                                 winner: group.winner)
            }
            .sorted { a, b in
                a.heroCategory != b.heroCategory ? a.heroCategory > b.heroCategory
                    : a.heroRanks.lexicographicallyPrecedes(b.heroRanks, by: >)
            }
    }
}
