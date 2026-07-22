// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// A priced decision point: pot (before villain's bet) and villain's bet, in bb.
public struct BetSpot: Equatable {
    public let pot: Int
    public let bet: Int
    public init(pot: Int, bet: Int) { self.pot = pot; self.bet = bet }

    /// Equity needed to call, in percent. Engine's `pot` param includes the bet.
    public var requiredPct: Double {
        requiredEquity(toCall: Double(bet), pot: Double(pot + bet)) * 100
    }
    /// Minimum defense frequency, in percent.
    public var mdfPct: Double { mdf(bet: Double(bet), pot: Double(pot)) * 100 }
}

/// Deterministic priced spots. Same (baseSeed, index) → same spot.
public enum BetSpotGenerator {
    static let pots = [6, 8, 10, 12, 15, 20, 24, 30]
    static let fractions = [0.33, 0.5, 0.75, 1.0, 1.5]  // decisions.md §A sizing menu

    public static func spot(baseSeed: UInt64, index: Int) -> BetSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let pot = pots.randomElement(using: &rng)!
        let f = fractions.randomElement(using: &rng)!
        return BetSpot(pot: pot, bet: max(1, Int((f * Double(pot)).rounded())))
    }
}

/// Shared reveal for the two percent-estimate drills (팟 오즈, MDF).
public struct PercentReveal: GradedReveal {
    public let band: GradeBand
    public let answerPct: Int
    public let correctPct: Double
    public let whyText: String
}

/// "25" for whole numbers, "66.7" otherwise (percent formatting for UI copy).
public func pctText(_ x: Double) -> String {
    abs(x - x.rounded()) < 0.05 ? "\(Int(x.rounded()))" : String(format: "%.1f", x)
}

public func gradePotOdds(estimatePct: Int, spot: BetSpot) -> PercentReveal {
    let correct = spot.requiredPct
    return PercentReveal(
        band: gradeEstimate(user: Double(estimatePct), correct: correct,
                            closeWithin: 7.5, spotOnWithin: 2.5),
        answerPct: estimatePct, correctPct: correct,
        whyText: "벳 \(spot.bet) ÷ (팟 \(spot.pot) + 벳 \(spot.bet) + 콜 \(spot.bet)) = \(pctText(correct))%")
}

public func gradeMDF(estimatePct: Int, spot: BetSpot) -> PercentReveal {
    let correct = spot.mdfPct
    return PercentReveal(
        band: gradeEstimate(user: Double(estimatePct), correct: correct,
                            closeWithin: 7.5, spotOnWithin: 2.5),
        answerPct: estimatePct, correctPct: correct,
        whyText: "팟 \(spot.pot) ÷ (팟 \(spot.pot) + 벳 \(spot.bet)) = \(pctText(correct))%")
}
