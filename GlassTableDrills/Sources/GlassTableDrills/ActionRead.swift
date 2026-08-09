// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

// MARK: - 액션 리드

/// A seat opens, the flop comes, and the archetype bets or checks. *Of the range that
/// took that action, what share has a pair or better?*
///
/// 히트 프리퀀시 asked that question of a whole range; this asks it of the part an
/// action leaves standing. The lesson is the shape change, not the number — a bet
/// slides the mass right, and how far right depends on who bet.
public struct ActionReadSpot: Equatable {
    public let villainSeat: Position
    public let villain: Archetype
    public let board: [Card]          // 3 — the c-bet spot, cleanest and most common
    public let action: PostflopAction

    public init(villainSeat: Position, villain: Archetype, board: [Card],
                action: PostflopAction) {
        self.villainSeat = villainSeat; self.villain = villain
        self.board = board; self.action = action
    }

    /// What he opened with — the same stated-premise construction as EV 손실.
    public var range: HandRange { villain.raiseRange(from: villainSeat) }
    public var policy: PostflopPolicy { villain.postflop }
    public var texture: BoardTexture { boardTexture(board) }

    /// The "before" bar.
    public var full: RangeOnBoard { rangeOnBoard(range, board: board) }
    /// The "after" bar — what the action leaves standing.
    public var acted: ActionRange { policy.narrowed(range, board: board, after: action) }

    public var pairOrBetterPct: Double { acted.distribution.pairOrBetter * 100 }

    /// "플랍에서 팟의 75%를 벳" / "플랍에서 체크".
    public var actionLine: String {
        switch action {
        case .bet: return "플랍에서 팟의 \(pctText(policy.betFraction * 100))%를 벳"
        case .check: return "플랍에서 체크"
        }
    }

    /// The policy row for this action, in bucket order — what the reveal and the
    /// walkthrough print so the number is checkable against the rule that made it.
    public var actedBucketList: String {
        MadeHand.allCases.filter { policy.buckets(after: action).contains($0) }
            .map(\.korean).joined(separator: " · ")
    }
}

public enum ActionReadSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> ActionReadSpot {
        var attempt = 0
        while true {
            var rng = SplitMix64(seed: baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt))
            var deck = Deck.all
            deck.shuffle(using: &rng)
            let spot = ActionReadSpot(
                villainSeat: RFIChart.seats.randomElement(using: &rng)!,
                villain: Archetype.allCases.randomElement(using: &rng)!,
                board: Array(deck[0..<3]),
                action: PostflopAction.allCases.randomElement(using: &rng)!)
            // Spec §4.1: an estimation drill needs something to estimate. A
            // deterministic table makes some pairs certain — Nit-벳 and Station-벳 are
            // always 100%, LAG-체크 is exactly 약한 페어 — and 매니악-체크 is an empty
            // set. Those tells are taught in the walkthrough and named in every
            // reveal; they are not gradeable questions, so reseed past them.
            // Narrowed once per attempt. Asking the spot for the percentage and then
            // for the combo count walked the whole range twice on every rejection.
            let acted = spot.acted
            let pct = acted.distribution.pairOrBetter * 100
            if acted.combos > 0 && pct <= 99.5 && pct >= 0.5 {
                return spot
            }
            attempt += 1
        }
    }
}

public func gradeActionRead(estimate: Estimate, spot: ActionReadSpot) -> EstimateReveal {
    // `acted` narrows the whole range combo by combo, so it is taken once and read
    // from — `pairOrBetterPct` would have narrowed it a second time for one number.
    let a = spot.acted
    let correct = a.distribution.pairOrBetter * 100
    let fullPct = spot.full.pairOrBetter * 100
    // Which way the action moved the range is the sentence worth remembering; the
    // percentages are its evidence.
    let direction = correct > fullPct + 1 ? "강한 쪽으로 좁혔어요"
                  : (correct < fullPct - 1 ? "약한 쪽으로 좁혔어요" : "거의 그대로예요")
    return EstimateReveal(
        // 히트 프리퀀시's bands: the same kind of distribution read, one step later.
        band: gradeEstimate(user: estimate.point, correct: correct,
                            closeWithin: 12, spotOnWithin: 5),
        estimate: estimate, correct: correct,
        intervalAnswer: estimate.answer(truth: correct),
        whyText: "\(spot.villain.name)의 \(spot.action.rawValue) 레인지는 \(spot.actedBucketList). "
               + "\(a.combos)콤보 중 \(pctText(correct))%가 페어 이상이에요. "
               + "전체 레인지는 \(pctText(fullPct))% — \(KO.subject(spot.action.rawValue)) "
               + "레인지를 \(direction).")
}
