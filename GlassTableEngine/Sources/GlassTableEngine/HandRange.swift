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

// MARK: - shaped ranges, and comparing two of them

/// A leaning a player can have on top of raw hand strength — the vocabulary a read is
/// actually spoken in ("wide, but only suited stuff").
public enum RangeTendency: String, CaseIterable, Sendable {
    case pairs, suited, offsuitBroadway, connectors

    /// Chen-equivalent points added before the cut. Deliberately small: a tendency
    /// tilts a range, it does not replace hand strength with a category.
    public var bonus: Double {
        switch self {
        case .pairs: return 3
        case .suited: return 2
        case .offsuitBroadway: return 2.5
        case .connectors: return 2.5
        }
    }

    public func matches(_ h: HandClass) -> Bool {
        switch self {
        case .pairs: return h.isPair
        case .suited: return h.suited
        case .offsuitBroadway: return !h.isPair && !h.suited && h.low >= 10
        case .connectors: return !h.isPair && h.gap <= 1
        }
    }
}

public extension HandRange {
    /// The top `width` percent under a set of leanings.
    ///
    /// A tendency re-weights the ranking *before* the cut rather than adding cells
    /// after it, so the result is always a coherent "top N% under this preference"
    /// instead of a shape with holes punched in it. That matters because the grid is
    /// shown while the slider moves — an incoherent range would be visibly wrong.
    static func shaped(width: Double, tendencies: Set<RangeTendency> = []) -> HandRange {
        let ranked = HandClass.all.sorted { a, b in
            let sa = Chen.score(a) + tendencies.reduce(0) { $0 + ($1.matches(a) ? $1.bonus : 0) }
            let sb = Chen.score(b) + tendencies.reduce(0) { $0 + ($1.matches(b) ? $1.bonus : 0) }
            if sa != sb { return sa > sb }
            if a.isPair != b.isPair { return a.isPair }
            if a.suited != b.suited { return a.suited }
            if a.gap != b.gap { return a.gap < b.gap }
            return a.high > b.high
        }
        let target = Double(HandClass.totalCombos) * width / 100
        var taken: [HandClass] = []
        var running = 0.0
        for h in ranked {
            if running >= target { break }
            taken.append(h)
            running += Double(h.comboCount)
        }
        return HandRange(taken)
    }

    /// Combo-weighted overlap: |A ∩ B| ÷ |A ∪ B|, 1 for identical ranges, 0 for
    /// disjoint ones. Weighted by combos rather than classes because a pair is 6 and
    /// an offsuit class is 12 — counting cells would score a pair-heavy miss as
    /// generously as an offsuit-heavy one.
    func jaccard(_ other: HandRange) -> Double {
        let inter = intersection(other).comboCount
        let uni = union(other).comboCount
        return uni == 0 ? (comboCount == 0 && other.comboCount == 0 ? 1 : 0) : inter / uni
    }

    /// Which categories this range leans toward, relative to how common they are in a
    /// deck. Used to say *how* a read differed rather than only by how much.
    func tendencyShare(_ t: RangeTendency) -> Double {
        guard comboCount > 0 else { return 0 }
        let mine = classes.filter(t.matches).reduce(0.0) { $0 + Double($1.comboCount) * weight($1) }
        return mine / comboCount
    }
}

public extension RangeTendency {
    /// True when every class in this category already fits inside a range of that
    /// width, so preferring the category cannot change anything.
    ///
    /// Pairs are 78 of 1326 combos and offsuit broadways 120, so both saturate well
    /// before a loose range. The UI needs this to explain why a chip has no visible
    /// effect rather than letting it look broken.
    func isSaturated(atWidth width: Double) -> Bool {
        isSaturated(in: HandRange.shaped(width: width))
    }

    /// The same question against a cut that has already been built. The chip row asks
    /// it once per tendency while the width slider moves, and building a fresh
    /// `shaped(width:)` inside each answer — four sorts of 169 classes per frame —
    /// cost more than everything else the drag touched.
    func isSaturated(in plain: HandRange) -> Bool {
        HandClass.all.filter(matches).allSatisfy { plain.weight($0) > 0 }
    }
}
