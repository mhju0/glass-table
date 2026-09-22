// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// One 팟 계산 spot: an action sequence, then "what is the pot now?" or
/// "what is N% of it?".
///
/// The cheapest high-leverage drill in the app. A beginner who cannot state the pot
/// cannot use pot odds at all, so this sits under 팟 오즈 rather than beside it.
public struct PotMathSpot: Equatable {
    public enum Actor: String, Equatable, Hashable {
        case sb = "SB"
        case bb = "BB"
        case opener = "플레이어 A"
        case caller1 = "플레이어 B"
        case caller2 = "플레이어 C"
    }

    public enum Action: Equatable {
        case blinds(sb: Int, bb: Int)
        case bet(actor: Actor, amount: Int)
        /// Chips this player *adds* now (for a caller facing a 3-bet, the difference).
        case call(actor: Actor, amount: Int)
        /// A raise to `to` total by a player who already had `from` in this street.
        /// `from` is 0 for anyone who has posted nothing — only the blinds raising
        /// over their own post replace rather than add. Conflating the two is the
        /// single most common beginner pot-counting error, which is why it is modelled.
        case raiseTo(actor: Actor, total: Int, alreadyIn: Int)
    }
    public enum Question: Equatable {
        case potNow
        /// The requested fraction of the pot at this exact point in the action.
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
            case let .bet(_, n): return total + n
            case let .call(_, n): return total + n
            case let .raiseTo(_, to, from): return total - from + to
            }
        }
    }

    public var participantCount: Int {
        var actors: Set<Actor> = []
        for action in actions {
            switch action {
            case .blinds:
                actors.formUnion([.sb, .bb])
            case let .bet(actor, _), let .call(actor, _), let .raiseTo(actor, _, _):
                actors.insert(actor)
            }
        }
        return actors.count
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
        let open = [4, 5, 6].randomElement(using: &rng)!
        actions.append(.raiseTo(actor: .opener, total: open, alreadyIn: 0))

        let callers = Int.random(in: 1...2, using: &rng)
        let callerActors: [PotMathSpot.Actor] = [.caller1, .caller2]
        for actor in callerActors.prefix(callers) {
            actions.append(.call(actor: actor, amount: open))
        }

        if Bool.random(using: &rng) {
            // The BB 3-bets, so their existing 2 *is* replaced — the one action shape
            // where the arithmetic is not a plain addition.
            let threeBet = open * [3, 4].randomElement(using: &rng)!
            actions.append(.raiseTo(actor: .bb, total: threeBet, alreadyIn: 2))
            actions.append(.call(actor: .opener, amount: threeBet - open))
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
        why = potBreakdown(spot) + "\n지금 팟: \(spot.pot)칩"
    case let .fractionOfPot(f):
        let percentage = Int((f * 100).rounded())
        let unrounded = Double(spot.pot) * f
        why = potBreakdown(spot)
            + "\n현재 팟의 \(percentage)%: \(spot.pot) × \(percentage)% = "
            + "\(decimalChipText(unrounded))칩 → \(correct)칩"
    }
    return PotMathReveal(band: answer == correct ? .spotOn : .off,
                         answer: answer, correct: correct, pot: spot.pot, whyText: why)
}

/// One cumulative equation per action. Newlines let the reveal preserve the same
/// sequence the learner just read instead of compressing every player into one sum.
func potBreakdown(_ spot: PotMathSpot) -> String {
    var running = 0
    var parts: [String] = []
    for action in spot.actions {
        switch action {
        case let .blinds(sb, bb):
            running += sb + bb
            parts.append("블라인드: \(sb) + \(bb) = \(running)칩")
        case let .bet(actor, n):
            let before = running
            running += n
            parts.append("\(actor.rawValue) 벳: \(before) + \(n) = \(running)칩")
        case let .call(actor, n):
            let before = running
            running += n
            parts.append("\(actor.rawValue) 콜: \(before) + \(n) = \(running)칩")
        case let .raiseTo(actor, to, from):
            let before = running
            let added = to - from
            running += added
            parts.append("\(actor.rawValue) 레이즈: \(before) + \(added) = \(running)칩 "
                         + "(총 \(to)칩)")
        }
    }
    return parts.joined(separator: "\n")
}

private func decimalChipText(_ value: Double) -> String {
    var result = String(format: "%.2f", value)
    while result.last == "0" { result.removeLast() }
    if result.last == "." { result.removeLast() }
    return result
}
