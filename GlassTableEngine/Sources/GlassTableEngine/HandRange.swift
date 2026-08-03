// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// A weighted set of starting-hand classes — the object the whole product thesis
/// rests on. "Ranges, not hand ladders" is unimplementable without it.
///
/// Weights are frequencies in 0…1: 1 means always played, 0.5 a mixed strategy. The
/// 13×13 grid renders a partial weight as a proportional split fill rather than
/// collapsing it to one colour, so a mixed range is never misread as a pure one.
public struct HandRange: Equatable, Sendable {
    /// Classes with a weight of zero are dropped, so `==` compares what is actually
    /// in the range rather than how it was written.
    public private(set) var weights: [HandClass: Double]

    public init(_ weights: [HandClass: Double] = [:]) {
        self.weights = weights.filter { $0.value > 0 }.mapValues { min(1, $0) }
    }

    /// Every listed class at full weight.
    public init(_ classes: [HandClass]) {
        self.init(Dictionary(classes.map { ($0, 1.0) }, uniquingKeysWith: { a, _ in a }))
    }

    public func weight(_ h: HandClass) -> Double { weights[h] ?? 0 }
    public var classes: [HandClass] { weights.keys.sorted() }
    public var isEmpty: Bool { weights.isEmpty }

    /// Does the range contain this concrete holding?
    public func contains(_ cards: [Card]) -> Bool {
        guard let h = HandClass(cards) else { return false }
        return weight(h) > 0
    }

    /// **Combo-weighted**, not class-weighted. A pair is 6 combos and an offsuit class
    /// is 12, so counting classes would misreport a pair-heavy range by roughly half.
    public var comboCount: Double {
        weights.reduce(0) { $0 + Double($1.key.comboCount) * $1.value }
    }

    /// Share of all 1326 combos, as a percent — how a chart's width is quoted.
    public var percent: Double {
        comboCount / Double(HandClass.totalCombos) * 100
    }

    /// Concrete combos, minus dead cards. Classes at partial weight are included
    /// whole: sampling by frequency belongs to the bot, not to a range's expansion.
    public func combos(removing dead: [Card] = []) -> [[Card]] {
        let deadSet = Set(dead)
        return classes.flatMap { $0.combos(removing: deadSet) }
    }

    public func comboCount(removing dead: [Card]) -> Int {
        combos(removing: dead).count
    }

    // MARK: set algebra

    /// Weight-aware: a class in both keeps the larger weight.
    public func union(_ other: HandRange) -> HandRange {
        HandRange(weights.merging(other.weights, uniquingKeysWith: max))
    }

    /// Keeps only classes in both, at the smaller weight.
    public func intersection(_ other: HandRange) -> HandRange {
        var out: [HandClass: Double] = [:]
        for (h, w) in weights where other.weight(h) > 0 {
            out[h] = min(w, other.weight(h))
        }
        return HandRange(out)
    }

    public func subtracting(_ other: HandRange) -> HandRange {
        HandRange(weights.filter { other.weight($0.key) == 0 })
    }

    /// The top `percent` of hands by Chen score, cut on **combos** rather than on
    /// classes — the cut point is a share of the hands you are actually dealt.
    ///
    /// The class straddling the boundary is included whole rather than split. A chart
    /// that opens three of the four combos of a suited class is a solver output, not
    /// something a person can hold in their head, and this app's charts are meant to
    /// be memorable.
    public static func topByChen(percent: Double) -> HandRange {
        let target = Double(HandClass.totalCombos) * percent / 100
        var taken: [HandClass] = []
        var running = 0.0
        for h in Chen.ranked {
            if running >= target { break }
            taken.append(h)
            running += Double(h.comboCount)
        }
        return HandRange(taken)
    }
}
