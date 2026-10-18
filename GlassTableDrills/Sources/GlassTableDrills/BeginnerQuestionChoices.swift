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

    // MARK: Later steps (D53)

    /// A count's choices at a step. Later steps offer four neighbouring counts, so the
    /// answer cannot be told from the others by size.
    public static func integers(answer: Int, bounds: ClosedRange<Int>, seed: UInt64, level: DrillLevel) -> [Int] {
        guard level > .learn else { return integers(answer: answer, bounds: bounds, seed: seed) }
        var rng = SplitMix64(seed: seed)
        return spread(answer: Double(answer), gap: 1, count: 4,
                      bounds: Double(bounds.lowerBound)...Double(bounds.upperBound), rng: &rng).map { Int($0) }
    }

    /// An equity's choices at a step: four 10 points apart, then four 5 or 6 apart.
    public static func percentages(answer: Double, seed: UInt64, level: DrillLevel) -> [Double] {
        guard level > .learn else { return percentages(answer: answer, seed: seed) }
        var rng = SplitMix64(seed: seed)
        let gap: Double = level == .sharp ? (Bool.random(using: &rng) ? 5 : 6) : 10
        return spread(answer: Double(min(100, max(0, Int(answer.rounded())))), gap: gap, count: 4,
                      bounds: 0...100, rng: &rng)
    }

    /// A price's choices at a step: three 10 points apart, then four 5 apart.
    public static func shares(answer: Double, seed: UInt64, level: DrillLevel) -> [Int] {
        guard level > .learn else { return shares(answer: answer, seed: seed) }
        var rng = SplitMix64(seed: seed)
        return spread(answer: Double(min(100, max(0, Int(answer.rounded())))), gap: level == .sharp ? 5 : 10,
                      count: level == .sharp ? 4 : 3, bounds: 0...100, rng: &rng).map { Int($0) }
    }

    /// The second EV step's choices: four, 1bb apart, with the answer (to the nearest
    /// half bb) anywhere among them. None loses more than the bet, which no call can.
    /// The first step's three choices are the app's `LessonEstimateChoices.evValues`.
    public static func evValues(answer: Double, bet: Int, seed: UInt64) -> [Double] {
        let rounded = (answer * 2).rounded() / 2
        var rng = SplitMix64(seed: seed)
        return spread(answer: rounded, gap: 1, count: 4,
                      bounds: min(rounded, -Double(bet))...Double.greatestFiniteMagnitude, rng: &rng)
    }

    /// `count` values `gap` apart with the answer at a seeded place among them, all in
    /// `bounds`. Evenly spaced, so neither the middle nor an end gives the answer away.
    static func spread(answer: Double, gap: Double, count: Int, bounds: ClosedRange<Double>,
                       rng: inout SplitMix64) -> [Double] {
        let below = Int(min(Double(count - 1), ((answer - bounds.lowerBound) / gap + 1e-9).rounded(.down)))
        let above = Int(min(Double(count - 1), ((bounds.upperBound - answer) / gap + 1e-9).rounded(.down)))
        let place = Int.random(in: max(0, count - 1 - above)...max(0, below), using: &rng)
        return (0..<count).map { answer + Double($0 - place) * gap }.shuffled(using: &rng)
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
    /// `HandBrief.category` of my best five once the river is dealt.
    public let category: Int
    /// A royal flush is listed apart from other straight flushes, as on the hand-rank page.
    public let isRoyal: Bool
}

public enum OutsOutcomeGroups {
    /// River cards grouped by the kind of hand they give me. The exact names, kickers and
    /// the opponent's hand can differ inside a group, so the reveal reads them per card.
    /// Groups come strongest hand first; cards within a group ace first.
    public static func make(hero: [Card], villain: [Card], board: [Card], candidates: [Card]) -> [OutsOutcomeGroup] {
        let known = hero + villain + board
        guard hero.count == 2, villain.count == 2, board.count == 4,
              Set(known).count == 8,
              (known + candidates).allSatisfy({ (2...14).contains($0.rank) && (0...3).contains($0.suit) })
        else { return [] }
        var groups: [OutsOutcomeGroup] = []
        for card in candidates where !known.contains(card) {
            let brief = bestHand(hero + board + [card])
            let royal = brief.category == 8 && brief.topRank == 14
            if let index = groups.firstIndex(where: { $0.category == brief.category && $0.isRoyal == royal }) {
                let old = groups[index]
                if !old.cards.contains(card) {
                    groups[index] = OutsOutcomeGroup(cards: old.cards + [card], category: old.category, isRoyal: royal)
                }
            } else {
                groups.append(OutsOutcomeGroup(cards: [card], category: brief.category, isRoyal: royal))
            }
        }
        return groups
            .map { OutsOutcomeGroup(cards: $0.cards.sorted(by: BeatScript.byRank), category: $0.category, isRoyal: $0.isRoyal) }
            .sorted { a, b in a.category != b.category ? a.category > b.category : a.isRoyal && !b.isRoyal }
    }
}
