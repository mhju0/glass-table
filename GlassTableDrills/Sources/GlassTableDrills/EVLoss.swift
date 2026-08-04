// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

// MARK: - the grading model

/// One option at a decision point, and what it is worth in big blinds.
public struct DecisionOption: Equatable, Sendable {
    public let label: String
    public let ev: Double

    public init(label: String, ev: Double) { self.label = label; self.ev = ev }
}

/// What a choice cost, rather than whether it was the choice.
///
/// Not `Sendable`: `GradeBand` is not, and nothing crosses an isolation boundary with
/// a grade. Claiming it would only add to the warning pile `Beat` already carries.
public struct EVLossGrade: Equatable {
    public let chosen: DecisionOption
    public let best: DecisionOption
    /// `best.ev − chosen.ev`, so it is never negative and the best option scores 0.
    public let loss: Double
    public let band: GradeBand
}

/// `decisions.md` §D: absolute big blinds, PokerSnowie's scale, so a learner reading
/// that tool or GTO Wizard sees the same numbers mean the same thing.
///
/// It is also the model's weakest joint. 0.5bb given up in a 6bb pot is a far worse
/// decision than 0.5bb given up in a 30bb pot, and an absolute threshold cannot tell
/// them apart. Kept as decided; the spec (§2, §7) records it as the thing to retune
/// from real answers rather than from taste.
public func evLossBand(bb loss: Double) -> GradeBand {
    if loss <= 0.5 { return .spotOn }
    if loss <= 2.0 { return .close }
    return .off
}

public extension GradeBand {
    /// The severity names `decisions.md` §D uses for a *decision*, as opposed to
    /// 정확/근접/빗나감, which describe an *answer*.
    ///
    /// They cannot be shared. A 0.2bb leak bands as `.spotOn`, and printing 정확 beside
    /// a sentence saying the other option was better asks the user to hold two
    /// contradictory claims at once. 최선 covers §D's "optimal/near-optimal" band, with
    /// the exact cost printed next to it.
    var evLossLabel: String {
        switch self {
        case .spotOn: return "최선"
        case .close:  return "부정확"
        case .off:    return "실수"
        }
    }
}

/// Grades a choice among priced options. `chosen` is an index into `options`.
public func gradeByEVLoss(chosen: Int, options: [DecisionOption]) -> EVLossGrade {
    precondition(options.indices.contains(chosen), "chosen must index options")
    let best = options.max { $0.ev < $1.ev }!
    let mine = options[chosen]
    // Clamped at zero: floating-point subtraction of two equal EVs can land at -1e-17,
    // and a negative "loss" would read as the user beating the best line.
    let loss = max(0, best.ev - mine.ev)
    return EVLossGrade(chosen: mine, best: best, loss: loss, band: evLossBand(bb: loss))
}

/// Mean big blinds given up per EV-graded answer in the log. `nil` until there is one —
/// an empty readout is honest, a 0.0bb one would claim perfection (decisions.md §D asks
/// for a rolling progress signal; a per-hand mean is the only one that stays comparable
/// as the bounded log rolls).
public func meanEVLoss(in state: ProgressState) -> Double? {
    let losses = state.answers.compactMap(\.evLoss)
    guard !losses.isEmpty else { return nil }
    return losses.reduce(0, +) / Double(losses.count)
}

/// "1.4" / "0" / "-2.25" → the same shape `pctText` gives, so bb and % read alike.
public func bbText(_ x: Double) -> String {
    // −0.04 would print as "-0" otherwise, which reads as a signed zero.
    abs(x) < 0.05 ? "0" : pctText(x)
}

// MARK: - 「EV 손실」

/// A river call, priced, against a **stated** range.
///
/// The screen names the opponent's range and the number is computed against exactly
/// that. The app does not claim to know what he bets — narrowing a preflop range by a
/// postflop action is the bot's job (S3), and faking it here would bias every spot
/// toward calling. The question is not "what does he have" but "given this range, what
/// is this call worth".
///
/// River, because an exact hand-versus-range equity costs 571ms on a flop, 24ms on a
/// turn and **1ms** on a river (measured, release). It is also where the lesson is
/// cleanest: no draws left, so the decision is only "am I ahead often enough".
public struct EVLossSpot: Equatable {
    public let hero: [Card]
    public let board: [Card]          // 5 — the river
    public let villainSeat: Position
    public let villain: Archetype
    public let pot: Int               // before villain's bet, bb
    public let bet: Int
    /// Exact, against `villainRange`. Stored rather than recomputed so grading and the
    /// reveal cannot drift apart, the same shape `CallFoldSpot` uses.
    public let equityPct: Double

    public init(hero: [Card], board: [Card], villainSeat: Position, villain: Archetype,
                pot: Int, bet: Int, equityPct: Double) {
        self.hero = hero; self.board = board
        self.villainSeat = villainSeat; self.villain = villain
        self.pot = pot; self.bet = bet; self.equityPct = equityPct
    }

    /// What he opened with. Printable, which is the point.
    public var villainRange: HandRange { villain.raiseRange(from: villainSeat) }
    public var rangeLabel: String { "\(villainSeat.rawValue) 오픈 · \(villain.name)" }

    public var requiredPct: Double {
        requiredEquity(toCall: Double(bet), pot: Double(pot + bet)) * 100
    }

    /// Calling wins `pot + bet` and loses `bet` — the engine's formula, not a second
    /// copy of it.
    public var callEVbb: Double {
        callEV(equity: equityPct / 100, toCall: Double(bet), pot: Double(pot + bet))
    }

    /// Folding is worth exactly nothing, always. Money already in the pot is not
    /// hero's any more, which is the whole reason EV is measured from here forward.
    public var options: [DecisionOption] {
        [DecisionOption(label: "폴드", ev: 0),
         DecisionOption(label: "콜", ev: callEVbb)]
    }
    public static let foldIndex = 0
    public static let callIndex = 1
}

public enum EVLossSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> EVLossSpot {
        var attempt = 0
        while true {
            var rng = SplitMix64(seed: baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt))
            var deck = Deck.all
            deck.shuffle(using: &rng)
            let hero = Array(deck[0..<2])
            let board = Array(deck[2..<7])
            let seat = RFIChart.seats.randomElement(using: &rng)!
            let villain = Archetype.allCases.randomElement(using: &rng)!
            let range = villain.raiseRange(from: seat)
            let equity = equityVsRange(hero: hero,
                                       villainCombos: range.combos(removing: board),
                                       board: board) * 100
            // Same valve as CallFoldSpotGenerator: a stone-cold nut or total air is not
            // a decision. Marginal spots are deliberately *not* preferred — if every
            // spot were close, every answer would score 최선 and the bands would never
            // move (spec §3.3).
            if equity >= 5 && equity <= 95 {
                let pot = BetSpotGenerator.pots.randomElement(using: &rng)!
                let f = BetSpotGenerator.fractions.randomElement(using: &rng)!
                return EVLossSpot(hero: hero, board: board, villainSeat: seat,
                                  villain: villain, pot: pot,
                                  bet: max(1, Int((f * Double(pot)).rounded())),
                                  equityPct: equity)
            }
            attempt += 1
        }
    }
}

public struct EVLossReveal: GradedReveal {
    public let band: GradeBand
    public let grade: EVLossGrade
    public let equityPct: Double
    public let requiredPct: Double
    public let callEVbb: Double
    public let whyText: String
}

public func gradeEVLoss(userCalls: Bool, spot: EVLossSpot) -> EVLossReveal {
    let grade = gradeByEVLoss(chosen: userCalls ? EVLossSpot.callIndex : EVLossSpot.foldIndex,
                              options: spot.options)
    // Phrased off `chosen` when nothing was lost and off `best` otherwise, so the
    // sentence is true even in the measure-zero case where both options price the same.
    let verdict = grade.loss <= 0
        ? "\(KO.subject(grade.chosen.label)) 최선이었어요."
        : "\(KO.subject(grade.best.label)) 더 좋았어요."
    // Both EVs, always — including the one the user picked. A grade that prints only the
    // better option is asking to be taken on faith.
    return EVLossReveal(
        band: grade.band, grade: grade,
        equityPct: spot.equityPct, requiredPct: spot.requiredPct,
        callEVbb: spot.callEVbb,
        whyText: "콜의 EV는 \(bbText(spot.callEVbb))bb, 폴드는 0bb. "
               + "\(spot.rangeLabel) 상대로 에퀴티 \(pctText(spot.equityPct))%, "
               + "필요 에퀴티 \(pctText(spot.requiredPct))%. " + verdict)
}
