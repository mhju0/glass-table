// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// What to do in position facing a 3bb open (R5 spec §1).
public enum DefendAction: String, CaseIterable, Sendable {
    case threeBet = "3벳", call = "콜", fold = "폴드"
}

/// The defending baseline, derived the way R2 derived RFI: Chen-ranked slices whose
/// widths scale with **the opener's range width** — the variable that dominates
/// in-position defense. Constants in one place, chart printable, never copied from a
/// published chart (decisions.md §E).
///
/// Stated simplification: the bands ignore hero's own seat. Real defense widens a
/// little as position improves; that refinement — and blind defense, where hero is
/// out of position — is future work, disclosed rather than faked.
public enum DefendChart {
    /// Share of the opener's width that 3-bets.
    public static let threeBetShare = 0.30
    /// Share of the opener's width that continues at all; the band between the two
    /// calls. Anchors: vs ~10% UTG → 3벳 ~3%, 콜 ~4.5% wide; vs ~26% CO → ~8% and
    /// ~11%, ≈19% total defense — both in the published neighborhoods.
    public static let defendShare = 0.75

    static func openPercent(of seat: Position) -> Double {
        RFIChart.openPercent[seat] ?? 0
    }

    public static func threeBetRange(vsOpenFrom seat: Position) -> HandRange {
        HandRange.topByChen(percent: openPercent(of: seat) * threeBetShare)
    }

    public static func callRange(vsOpenFrom seat: Position) -> HandRange {
        HandRange.topByChen(percent: openPercent(of: seat) * defendShare)
            .subtracting(threeBetRange(vsOpenFrom: seat))
    }

    /// The share of all combos ranked at or above `hand` by Chen — the order the bands
    /// are cut from, so it places the hand against each band's edge.
    public static func strengthPercent(of hand: HandClass) -> Double {
        var running = 0
        for h in Chen.ranked {
            running += h.comboCount
            if h == hand { break }
        }
        return Double(running) / Double(HandClass.totalCombos) * 100
    }

    /// The opener's rule in the chart's own numbers, then where this hand sits in it.
    public static func reason(for hand: HandClass, vsOpenFrom seat: Position,
                              language: LearningLanguage) -> String {
        let open = openPercent(of: seat)
        let rank = Int(strengthPercent(of: hand).rounded())
        let action = action(for: hand, vsOpenFrom: seat)
        let koAction = switch action {
        case .fold: "폴드"
        case .call: "콜"
        case .threeBet: "다시 올리기"
        }
        let enAction = switch action {
        case .fold: "a fold"
        case .call: "a call"
        case .threeBet: "a raise again"
        }
        // The opener's width is a target; the band edges are the shares the bands hold.
        let threeBet = threeBetRange(vsOpenFrom: seat)
        let raiseAgain = exactPctText(threeBet.percent)
        let callTo = exactPctText(threeBet.percent + callRange(vsOpenFrom: seat).percent)
        return language.text(
            "\(seat.plainName(in: language)): 상위 약 \(pctText(open))%로 먼저 올려요. "
            + "상위 \(raiseAgain)%는 다시 올리고, "
            + "\(callTo)%까지는 콜이에요. "
            + "\(KO.topic(hand.description)) 강한 순서로 상위 \(rank)%쯤이라 \(KO.copula(koAction))",
            "\(seat.plainName(in: language)) raises first with about \(pctText(open))% of hands, strongest first. "
            + "Raise again with the top \(raiseAgain)%; call up to \(callTo)%. "
            + "\(hand.description) ranks near the top \(rank)% by strength, so it is \(enAction).")
    }

    static func action(for hand: HandClass, vsOpenFrom seat: Position) -> DefendAction {
        if threeBetRange(vsOpenFrom: seat).weight(hand) > 0 { return .threeBet }
        if callRange(vsOpenFrom: seat).weight(hand) > 0 { return .call }
        return .fold
    }

    /// Total by construction: 3벳 band, else 콜 band, else fold.
    public static func action(for hand: [Card], vsOpenFrom seat: Position) -> DefendAction {
        if threeBetRange(vsOpenFrom: seat).contains(hand) { return .threeBet }
        if callRange(vsOpenFrom: seat).contains(hand) { return .call }
        return .fold
    }
}

public extension Archetype {
    /// Share of his *own opening range* (top slice, by Chen) that continues against
    /// a 3-bet — one number per character, no 4-bets (R5 spec §2). The Station's 1.0
    /// is the caricature: he never folds preflop.
    var threeBetContinueShare: Double {
        switch self {
        case .nit: return 0.35
        case .tag: return 0.50
        case .lag: return 0.60
        case .station: return 1.00
        case .maniac: return 0.85
        case .casual: return 0.70
        }
    }

    /// Nested in `raiseRange(from:)` automatically: a top slice of a top slice.
    func continueRange(vs3BetFrom seat: Position) -> HandRange {
        HandRange.topByChen(percent: pfr * Archetype.seatFactor(seat) * threeBetContinueShare)
    }
}
