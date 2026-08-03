// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// A point estimate plus the 90% interval the user is willing to stand behind
/// (spec §5.4). Only estimation concepts collect one.
public struct Estimate: Equatable {
    public let point: Double
    public let lo: Double
    public let hi: Double

    public init(point: Double, lo: Double, hi: Double) {
        self.point = point; self.lo = min(lo, hi); self.hi = max(lo, hi)
    }

    public func answer(truth: Double) -> IntervalAnswer {
        IntervalAnswer(point: point, lo: lo, hi: hi, truth: truth)
    }
}

// MARK: - 에퀴티 감각

/// Hand vs hand on a partial board: "what is my equity?"
///
/// The villain's hand is shown. That is a deliberate simplification of a real read —
/// equity against a *range* needs the Range primitive and belongs to R2 — but the
/// number here is exact rather than approximated, so nothing taught has to be untaught.
public struct EquitySenseSpot: Equatable {
    public let hero: [Card]
    public let villain: [Card]
    public let board: [Card]      // 3 (flop) or 4 (turn)

    public init(hero: [Card], villain: [Card], board: [Card]) {
        self.hero = hero; self.villain = villain; self.board = board
    }

    /// Exact, by full enumeration of the remaining board — no Monte Carlo, so the
    /// same spot always grades identically.
    public var equityPct: Double {
        exactEquityHeadsUp(hero: hero, villain: villain, board: board).equity * 100
    }
}

public enum EquitySenseSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> EquitySenseSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        var deck = Deck.all
        deck.shuffle(using: &rng)
        let street = Bool.random(using: &rng) ? 3 : 4
        return EquitySenseSpot(hero: Array(deck[0..<2]),
                               villain: Array(deck[2..<4]),
                               board: Array(deck[4..<(4 + street)]))
    }
}

// MARK: - EV 계산

/// "You can call `bet` into `pot` with `equityPct`. What is the EV of calling?"
///
/// The brief's headline is "EV, not equity", and every competitor *reports* EV while
/// none asks the learner to produce it. This drill is that gap.
public struct EVCallSpot: Equatable {
    public let pot: Int
    public let bet: Int
    public let equityPct: Double
    /// Shown after the answer as a distractor: one hand's result says nothing about
    /// whether the call was right. This is the outcome-bias lesson in miniature.
    public let didWin: Bool

    public init(pot: Int, bet: Int, equityPct: Double, didWin: Bool) {
        self.pot = pot; self.bet = bet; self.equityPct = equityPct; self.didWin = didWin
    }

    /// EV of calling in bb. Positive means the call makes money over many repetitions.
    public var evBB: Double {
        callEV(equity: equityPct / 100, toCall: Double(bet), pot: Double(pot + bet))
    }
    public var isProfitable: Bool { evBB > 0 }
}

public enum EVCallSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> EVCallSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let pot = [8, 10, 12, 16, 20, 24, 30].randomElement(using: &rng)!
        let f = [0.33, 0.5, 0.75, 1.0].randomElement(using: &rng)!
        let bet = max(1, Int((f * Double(pot)).rounded()))
        // Equity in whole percent, spread either side of the break-even price so the
        // answer's sign is not guessable from the sizing alone.
        let equity = Double(Int.random(in: 15...70, using: &rng))
        return EVCallSpot(pot: pot, bet: bet, equityPct: equity,
                          didWin: Double(Int.random(in: 0..<100, using: &rng)) < equity)
    }
}

// MARK: - grading

public struct EstimateReveal: GradedReveal {
    public let band: GradeBand
    public let estimate: Estimate
    public let correct: Double
    public let intervalAnswer: IntervalAnswer
    public let whyText: String

    /// Whether the stated 90% interval actually contained the truth — the input to
    /// the calibration readout.
    public var intervalHit: Bool { intervalAnswer.containsTruth }
}

public func gradeEquitySense(estimate: Estimate, spot: EquitySenseSpot) -> EstimateReveal {
    let correct = spot.equityPct
    let unseen = 52 - Set(spot.hero + spot.villain + spot.board).count
    return EstimateReveal(
        band: gradeEstimate(user: estimate.point, correct: correct,
                            closeWithin: 10, spotOnWithin: 4),
        estimate: estimate, correct: correct,
        intervalAnswer: estimate.answer(truth: correct),
        whyText: "남은 \(unseen)장으로 가능한 모든 보드를 세어 계산한 값이에요 — "
               + "\(pctText(correct))%. 근사가 아니라 정확한 수치예요.")
}

public func gradeEVCall(estimate: Estimate, spot: EVCallSpot) -> EstimateReveal {
    let correct = spot.evBB
    let win = pctText(spot.equityPct)
    let sign = correct > 0 ? "이득" : "손해"
    return EstimateReveal(
        // EV is in bb, not percent, so the bands are much tighter than the equity ones.
        band: gradeEstimate(user: estimate.point, correct: correct,
                            closeWithin: 1.5, spotOnWithin: 0.5),
        estimate: estimate, correct: correct,
        intervalAnswer: estimate.answer(truth: correct),
        whyText: "\(win)%로 \(spot.pot + spot.bet)bb를 따고, \(pctText(100 - spot.equityPct))%로 "
               + "\(spot.bet)bb를 잃어요 → \(pctText(correct))bb \(sign). "
               + "이번 판의 결과는 이 계산과 상관없어요.")
}
