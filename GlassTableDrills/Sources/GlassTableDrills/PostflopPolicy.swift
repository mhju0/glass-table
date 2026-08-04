// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// What an archetype does after the flop, as a row per action over the five S1
/// buckets. A bucket in no row means check, or fold facing a bet.
///
/// **Deterministic, no mixing.** Real players mix frequencies; the table sharpens a
/// tendency into a rule, which is what an archetype *is* — a caricature. Determinism
/// is also what makes an action invertible: 벳 keeps exactly the combos in `bets`,
/// 체크 keeps the complement, so the app can print and grade the narrowed range
/// instead of waving at it (spec §1).
public struct PostflopPolicy: Equatable, Sendable {
    /// Checked to, these buckets bet; the rest check.
    public let bets: Set<MadeHand>
    /// Facing a bet, these call…
    public let calls: Set<MadeHand>
    /// …these raise, and anything in neither folds. Disjoint from `calls` by test.
    public let raises: Set<MadeHand>
    /// Preferred size as a fraction of pot, from the decisions.md §A menu.
    public let betFraction: Double

    /// Checked to: bet or check. Total by construction.
    public func opens(with bucket: MadeHand) -> Bool { bets.contains(bucket) }

    public enum FacingBetResponse: Equatable, Sendable { case fold, call, raise }

    /// Facing a bet: raise beats call beats fold. Total — any bucket in neither
    /// row folds, which is the only sound default for money already threatened.
    public func response(toBetWith bucket: MadeHand) -> FacingBetResponse {
        if raises.contains(bucket) { return .raise }
        if calls.contains(bucket) { return .call }
        return .fold
    }

    /// The buckets that survive an observed action — the inversion the drill grades.
    public func buckets(after action: PostflopAction) -> Set<MadeHand> {
        switch action {
        case .bet: return bets
        case .check: return Set(MadeHand.allCases).subtracting(bets)
        }
    }
}

public enum PostflopAction: String, CaseIterable, Sendable {
    case bet = "벳", check = "체크"
}

public extension Archetype {
    /// The published postflop row (spec §1). Rationale per row lives with the values,
    /// because the values *are* the design:
    ///
    /// - **Nit**, tight-passive: bets and raises only what beats top pair, calls down
    ///   with top pair, folds draws to pressure. His bet is his hand.
    /// - **TAG**: value bets and semi-bluffs draws — the textbook c-bet mix — and
    ///   makes disciplined folds with air and weak pairs.
    /// - **LAG**: c-bets air but **checks weak pairs**: no showdown value → bluff,
    ///   a little showdown value → free showdown. The one deliberately sophisticated
    ///   row, kept because it produces the counterintuitive tell (his check is a pair).
    /// - **Station**, the VPIP–PFR gap postflop: almost never bets, never raises,
    ///   calls with any piece, folds only 노페어.
    /// - **Maniac**: bets everything, raises most things, folds nothing — his actions
    ///   carry almost no information, which is itself the read.
    var postflop: PostflopPolicy {
        switch self {
        case .nit:
            return PostflopPolicy(bets: [.strong],
                                  calls: [.topPair],
                                  raises: [.strong],
                                  betFraction: 0.5)
        case .tag:
            return PostflopPolicy(bets: [.draw, .topPair, .strong],
                                  calls: [.draw, .topPair],
                                  raises: [.strong],
                                  betFraction: 0.75)
        case .lag:
            return PostflopPolicy(bets: [.air, .draw, .topPair, .strong],
                                  calls: [.draw, .weakPair, .topPair],
                                  raises: [.strong],
                                  betFraction: 0.75)
        case .station:
            return PostflopPolicy(bets: [.strong],
                                  calls: [.draw, .weakPair, .topPair, .strong],
                                  raises: [],
                                  betFraction: 0.33)
        case .maniac:
            return PostflopPolicy(bets: Set(MadeHand.allCases),
                                  calls: [.air, .weakPair],
                                  raises: [.draw, .topPair, .strong],
                                  betFraction: 1.5)
        }
    }
}

// MARK: - narrowing

/// A range after an observed action: what survives, and how often the action happens.
public struct ActionRange: Equatable {
    public let action: PostflopAction
    /// Combos that take this action here.
    public let combos: Int
    /// Distribution of the survivors — the "after" bar.
    public let distribution: RangeOnBoard
    /// How much of the live range takes this action (0…1).
    public let shareOfRange: Double
}

public extension PostflopPolicy {
    /// Inverts an observed action into the range that remains (spec §2). Combo-level,
    /// not class-level: A♠K♠ and A♥K♥ land in different buckets on a spade board.
    func narrowed(_ range: HandRange, board: [Card],
                  after action: PostflopAction) -> ActionRange {
        let kept = buckets(after: action)
        var acted: [[Card]] = []
        var live = 0
        for combo in range.combos(removing: board) {
            live += 1
            if kept.contains(madeHand(hand: combo, board: board)) { acted.append(combo) }
        }
        return ActionRange(action: action, combos: acted.count,
                           distribution: rangeOnBoard(combos: acted, board: board),
                           shareOfRange: live == 0 ? 0 : Double(acted.count) / Double(live))
    }
}
