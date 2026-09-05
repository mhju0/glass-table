// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// One 팟 계산 spot: an action sequence, then "what is the pot now?" or
/// "what is N% of it?".
///
/// The cheapest high-leverage drill in the app. A beginner who cannot state the pot
/// cannot use pot odds at all, so this sits under 팟 오즈 rather than beside it.
public struct PotMathSpot: Equatable {
    public enum Action: Equatable {
        case blinds(sb: Int, bb: Int)
        case bet(Int)
        /// Chips this player *adds* now (for a caller facing a 3-bet, the difference).
        case call(Int)
        /// A raise to `to` total by a player who already had `from` in this street.
        /// `from` is 0 for anyone who has posted nothing — only the blinds raising
        /// over their own post replace rather than add. Conflating the two is the
        /// single most common beginner pot-counting error, which is why it is modelled.
        case raiseTo(Int, from: Int)
    }
    public enum Question: Equatable {
        case potNow
        /// "You face no bet — what is a `fraction` pot-sized bet?"
        case fractionOfPot(Double)
    }

    public let actions: [Action]
    public let question: Question

    public init(actions: [Action], question: Question) {
        self.actions = actions; self.question = question
    }

    /// Chips in the middle after the whole sequence.
    public var pot: Int {
        actions.reduce(0) { total, action in
            switch action {
            case let .blinds(sb, bb): return total + sb + bb
            case let .bet(n): return total + n
            case let .call(n): return total + n
            case let .raiseTo(to, from): return total - from + to
            }
        }
    }

    public var correctAnswer: Int {
        switch question {
        case .potNow: return pot
        case let .fractionOfPot(f): return Int((Double(pot) * f).rounded())
        }
    }
}

public enum PotMathSpotGenerator {
    /// decisions.md §A sizing menu, minus all-in (which needs a stack to mean anything).
    static let fractions = [0.33, 0.5, 0.75, 1.0]

    public static func spot(baseSeed: UInt64, index: Int) -> PotMathSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)

        var actions: [PotMathSpot.Action] = [.blinds(sb: 1, bb: 2)]
        // The opener is a non-blind seat, so nothing of theirs is replaced.
        let open = [3, 4, 5, 6].randomElement(using: &rng)!
        actions.append(.raiseTo(open, from: 0))

        let callers = Int.random(in: 1...2, using: &rng)
        for _ in 0..<callers { actions.append(.call(open)) }

        if Bool.random(using: &rng) {
            // The BB 3-bets, so their existing 2 *is* replaced — the one action shape
            // where the arithmetic is not a plain addition.
            let threeBet = open * [3, 4].randomElement(using: &rng)!
            actions.append(.raiseTo(threeBet, from: 2))
            actions.append(.call(threeBet - open))   // the opener calls the difference
        }

        let question: PotMathSpot.Question = Bool.random(using: &rng)
            ? .potNow
            : .fractionOfPot(fractions.randomElement(using: &rng)!)
        return PotMathSpot(actions: actions, question: question)
    }
}

public struct PotMathReveal: Equatable {
    public let band: GradeBand
    public let answer: Int
    public let correct: Int
    public let pot: Int
    public let whyText: String
}

public func gradePotMath(answer: Int, spot: PotMathSpot) -> PotMathReveal {
    let correct = spot.correctAnswer
    let why: String
    switch spot.question {
    case .potNow:
        why = "\(potBreakdown(spot)) = \(spot.pot)bb"
    case let .fractionOfPot(f):
        why = "팟 \(spot.pot)bb × \(Int((f * 100).rounded()))% = \(correct)bb"
    }
    return PotMathReveal(band: answer == correct ? .spotOn : .off,
                         answer: answer, correct: correct, pot: spot.pot, whyText: why)
}

/// "1 + 2 → 5 (레이즈) + 5 + 5" — the arithmetic shown rather than asserted, which is
/// the same rule the 천천히 beats follow.
func potBreakdown(_ spot: PotMathSpot) -> String {
    var parts: [String] = []
    for action in spot.actions {
        switch action {
        case let .blinds(sb, bb): parts.append("블라인드 \(sb)+\(bb)")
        case let .bet(n): parts.append("벳 \(n)")
        case let .call(n): parts.append("콜 \(n)")
        case let .raiseTo(to, from): parts.append("레이즈 \(to) (−\(from))")
        }
    }
    return parts.joined(separator: " + ")
}
