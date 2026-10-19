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
    /// Players who left the hand without adding chips. Their earlier contribution
    /// stays in the pot and is therefore still visible in the table replay.
    public let foldedActors: Set<Actor>

    public init(actions: [Action], question: Question, foldedActors: Set<Actor> = []) {
        self.actions = actions
        self.question = question
        self.foldedActors = foldedActors
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

    /// Seats in clockwise table order. Generated spots deliberately stop at four
    /// players so names and chip totals stay legible on a compact phone.
    public var actors: [Actor] {
        let present = Set(actions.flatMap { action -> [Actor] in
            switch action {
            case .blinds: return [.sb, .bb]
            case let .bet(actor, _), let .call(actor, _), let .raiseTo(actor, _, _):
                return [actor]
            }
        })
        return [Actor.sb, .bb, .opener, .caller1, .caller2].filter(present.contains)
    }

    public var correctAnswer: Int {
        switch question {
        case .potNow: return pot
        case let .fractionOfPot(f): return Int((Double(pot) * f).rounded())
        }
    }

    /// The first bet after preflop raises begins the flop. Earlier callers who did
    /// not match the final raise fold before it; their chips stay in the pot. This
    /// transition is attached to that bet, preserving saved replay-step indexes.
    public var flopTransition: PotMathFlopTransition? {
        guard let index = actions.firstIndex(where: {
            if case .bet = $0 { return true }
            return false
        }), actions[..<index].contains(where: {
            if case .raiseTo = $0 { return true }
            return false
        }) else { return nil }
        var paid: [Actor: Int] = [:]
        for action in actions[..<index] {
            switch action {
            case let .blinds(sb, bb):
                paid[.sb, default: 0] += sb
                paid[.bb, default: 0] += bb
            case let .bet(actor, amount), let .call(actor, amount): paid[actor, default: 0] += amount
            case let .raiseTo(actor, total, alreadyIn): paid[actor, default: 0] += total - alreadyIn
            }
        }
        let price = paid.values.max() ?? 0
        let order: [Actor] = [.opener, .caller1, .caller2, .sb, .bb]
        let folds = order.filter { actor in
            guard let chips = paid[actor] else { return false }
            return !foldedActors.contains(actor) && chips < price
        }
        return PotMathFlopTransition(actionIndex: index, foldedActors: folds)
    }


    /// The question's three equal-weight choices. Wrong values represent useful
    /// arithmetic checks, but feedback never claims which mistake the learner made.
    public var answerChoices: [Int] {
        let correct = correctAnswer
        var lower: [Int] = []
        var higher: [Int] = []

        func appendCandidate(_ value: Int) {
            guard value >= 0, value != correct else { return }
            if value < correct, !lower.contains(value) { lower.append(value) }
            if value > correct, !higher.contains(value) { higher.append(value) }
        }

        switch question {
        case .potNow:
            let finalAddition = replaySteps.last(where: { $0.addedChips > 0 })?.addedChips ?? 1
            // Missing the folded blind or the final call produces lower checks.
            appendCandidate(pot - 1)
            appendCandidate(pot - finalAddition)
            // Counting the BB post twice or using the full raise target for the
            // opener's final call produces higher checks.
            appendCandidate(pot + 2)
            let openingTotal = actions.compactMap { action -> Int? in
                guard case let .raiseTo(actor, total, _) = action, actor == .opener else { return nil }
                return total
            }.first ?? 1
            appendCandidate(pot + openingTotal)
        case let .fractionOfPot(fraction):
            let raw = Double(pot) * fraction
            appendCandidate(Int(raw.rounded(.down)))
            appendCandidate(Int((Double(max(0, pot - 3)) * fraction).rounded()))
            appendCandidate(pot)
            appendCandidate(correct + max(1, Int((Double(pot) * 0.25).rounded())))
        }

        let lowerTarget = min(2, correct)
        var distance = 1
        while lower.count < lowerTarget || higher.count < 2 {
            appendCandidate(correct + distance)
            appendCandidate(correct - distance)
            distance += 1
        }

        let pattern = (pot + questionSalt) % 3
        let distractors: [Int]
        if pattern == 0, lower.count >= 2 {
            distractors = Array(lower.prefix(2))
        } else if pattern == 1 || lower.isEmpty {
            distractors = Array(higher.prefix(2))
        } else {
            distractors = [lower[0], higher[0]]
        }
        var rng = SplitMix64(seed: choiceSeed)
        return ([correct] + distractors).shuffled(using: &rng)
    }

    /// One replay step per visible action. Blind posts are separate so a beginner
    /// can associate each compulsory chip with the seat that paid it.
    public var replaySteps: [PotMathReplayStep] {
        var result: [PotMathReplayStep] = []
        var contributions: [Actor: Int] = [:]
        var insertedFolds: Set<Actor> = []

        func add(_ actor: Actor, _ amount: Int, _ kind: PotMathReplayStep.Kind,
                 transition: PotMathFlopTransition? = nil) {
            contributions[actor, default: 0] += amount
            result.append(PotMathReplayStep(actor: actor, kind: kind,
                                            addedChips: amount,
                                            totalContribution: contributions[actor, default: 0],
                                            flopTransition: transition))
        }

        func insertFolds() {
            for actor in actors where foldedActors.contains(actor) && !insertedFolds.contains(actor) {
                result.append(PotMathReplayStep(actor: actor, kind: .fold,
                                                addedChips: 0,
                                                totalContribution: contributions[actor, default: 0]))
                insertedFolds.insert(actor)
            }
        }

        let transition = flopTransition
        for (index, action) in actions.enumerated() {
            switch action {
            case let .blinds(sb, bb):
                add(.sb, sb, .post)
                add(.bb, bb, .post)
            case let .bet(actor, amount):
                add(actor, amount, .bet, transition: transition?.actionIndex == index ? transition : nil)
            case let .call(actor, amount):
                add(actor, amount, .call)
            case let .raiseTo(actor, total, alreadyIn):
                if actor == .bb { insertFolds() }
                add(actor, total - alreadyIn, .raiseTo(total))
            }
        }
        insertFolds()
        return result
    }

    public func contribution(of actor: Actor, throughReplayStep stepIndex: Int) -> Int {
        guard stepIndex >= 0 else { return 0 }
        return replaySteps.prefix(stepIndex + 1)
            .filter { $0.actor == actor }
            .last?.totalContribution ?? 0
    }

    private var questionSalt: Int {
        switch question {
        case .potNow: return 0
        case let .fractionOfPot(f): return Int((f * 100).rounded())
        }
    }

    private var choiceSeed: UInt64 {
        var fingerprint = UInt64(pot) &* 0x9E37_79B9_7F4A_7C15
        fingerprint ^= UInt64(questionSalt) &* 0xBF58_476D_1CE4_E5B9
        for step in replaySteps {
            fingerprint = (fingerprint ^ UInt64(step.addedChips + 1))
                &* 0x94D0_49BB_1331_11EB
            fingerprint ^= UInt64(step.totalContribution + 1)
        }
        return fingerprint
    }
}

public struct PotMathFlopTransition: Equatable {
    public let actionIndex: Int
    public let foldedActors: [PotMathSpot.Actor]

    public func foldExplanation(in language: LearningLanguage) -> String? {
        guard !foldedActors.isEmpty else { return nil }
        let folds = foldedActors.map { actor in
            language.text("\(DrillTerms.actor(actor, in: language)) 폴드",
                          "\(DrillTerms.actor(actor, in: language)) folds")
        }.joined(separator: " · ")
        return language.text("플랍 전: ", "Before the flop: ") + folds
            + language.text(" · 이미 낸 칩은 팟에 남아요", " · paid chips stay in the pot")
    }
}

public struct PotMathReplayStep: Equatable {
    public enum Kind: Equatable {
        case post
        case bet
        case call
        case raiseTo(Int)
        case fold
    }

    public let actor: PotMathSpot.Actor
    public let kind: Kind
    public let addedChips: Int
    public let totalContribution: Int
    public let flopTransition: PotMathFlopTransition?

    public init(actor: PotMathSpot.Actor, kind: Kind, addedChips: Int, totalContribution: Int,
                flopTransition: PotMathFlopTransition? = nil) {
        self.actor = actor
        self.kind = kind
        self.addedChips = addedChips
        self.totalContribution = totalContribution
        self.flopTransition = flopTransition
    }
}

public enum PotMathSpotGenerator {
    /// decisions.md §A sizing menu, minus all-in and pot-sized, which would make a
    /// fraction question indistinguishable from the already practised pot total.
    static let fractions = [0.33, 0.5, 0.75]

    public static func spot(baseSeed: UInt64, index: Int, level: DrillLevel = .learn) -> PotMathSpot {
        guard level > .learn else { return learnSpot(baseSeed: baseSeed, index: index) }
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(level.rawValue) &* 0xD1B5_4A32_D192_ED03
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)

        // Later steps (D53) vary every size the first step fixes: any open from 4 to 8,
        // a 3-bet to three or four times it, the SB sometimes calling instead of
        // folding, and the question picked at random from the first question on. The
        // table still seats four, so a second caller never appears.
        var actions: [PotMathSpot.Action] = [.blinds(sb: 1, bb: 2)]
        let open = Int.random(in: 4...8, using: &rng)
        actions.append(.raiseTo(actor: .opener, total: open, alreadyIn: 0))
        if Bool.random(using: &rng) {
            actions.append(.call(actor: .caller1, amount: open))
        }
        let sbCalls = Bool.random(using: &rng)
        if sbCalls {
            actions.append(.call(actor: .sb, amount: open - 1))
        }
        let threeBet = open * Int.random(in: 3...4, using: &rng)
        actions.append(.raiseTo(actor: .bb, total: threeBet, alreadyIn: 2))
        actions.append(.call(actor: .opener, amount: threeBet - open))

        // The third step plays on: unmatched callers fold at `flopTransition`,
        // then the BB leads the flop and the opener calls. No RNG or chips are added
        // for those folds, so saved Sharp questions retain their original answers.
        if level == .sharp {
            let preflop = PotMathSpot(actions: actions, question: .potNow).pot
            let bet = max(1, Int((Double(preflop) * fractions.randomElement(using: &rng)!).rounded()))
            actions.append(.bet(actor: .bb, amount: bet))
            actions.append(.call(actor: .opener, amount: bet))
        }

        let question: PotMathSpot.Question = Bool.random(using: &rng)
            ? .potNow
            : .fractionOfPot(fractions.randomElement(using: &rng)!)
        return PotMathSpot(actions: actions, question: question, foldedActors: sbCalls ? [] : [.sb])
    }

    /// The first step, frozen by `LearnSpotGoldenTests`.
    private static func learnSpot(baseSeed: UInt64, index: Int) -> PotMathSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)

        var actions: [PotMathSpot.Action] = [.blinds(sb: 1, bb: 2)]
        let open = [4, 5, 6].randomElement(using: &rng)!
        actions.append(.raiseTo(actor: .opener, total: open, alreadyIn: 0))

        // Three seats keep the compact table readable; a fourth caller appears on
        // half the seeds. The BB raise exercises the important total-versus-added
        // distinction on every generated spot.
        if Bool.random(using: &rng) {
            actions.append(.call(actor: .caller1, amount: open))
        }
        let threeBet = open * 3
        actions.append(.raiseTo(actor: .bb, total: threeBet, alreadyIn: 2))
        actions.append(.call(actor: .opener, amount: threeBet - open))

        let question: PotMathSpot.Question = index <= 2 || Bool.random(using: &rng)
            ? .potNow
            : .fractionOfPot(fractions.randomElement(using: &rng)!)
        return PotMathSpot(actions: actions, question: question, foldedActors: [.sb])
    }
}

public struct PotMathReveal: Equatable {
    public let band: GradeBand
    public let answer: Int
    public let correct: Int
    public let pot: Int
    public let whyText: String
}

public func gradePotMath(answer: Int, spot: PotMathSpot,
                         language: LearningLanguage = .korean) -> PotMathReveal {
    let correct = spot.correctAnswer
    let why: String
    switch spot.question {
    case .potNow:
        why = potBreakdown(spot, language: language)
            + language.text("\n지금 팟: \(spot.pot)칩", "\nPot now: \(spot.pot) chips")
    case let .fractionOfPot(f):
        let percentage = Int((f * 100).rounded())
        let unrounded = Double(spot.pot) * f
        why = potBreakdown(spot, language: language)
            + language.text(
                "\n현재 팟의 \(percentage)%: \(spot.pot) × \(percentage)% = \(decimalChipText(unrounded))칩 → \(correct)칩",
                "\n\(percentage)% of the current pot: \(spot.pot) × \(percentage)% = \(decimalChipText(unrounded)) chips → \(correct) chips")
    }
    return PotMathReveal(band: answer == correct ? .spotOn : .off,
                         answer: answer, correct: correct, pot: spot.pot, whyText: why)
}

/// One cumulative equation per action. Newlines let the reveal preserve the same
/// sequence the learner just read instead of compressing every player into one sum.
func potBreakdown(_ spot: PotMathSpot, language: LearningLanguage = .korean) -> String {
    var running = 0
    var parts: [String] = []
    let transition = spot.flopTransition
    for (index, action) in spot.actions.enumerated() {
        if transition?.actionIndex == index {
            if let folds = transition?.foldExplanation(in: language) { parts.append(folds) }
            parts.append(language.text("플랍", "Flop"))
        }
        switch action {
        case let .blinds(sb, bb):
            running += sb + bb
            parts.append(language.text("블라인드: \(sb) + \(bb) = \(running)칩",
                                       "Blinds: \(sb) + \(bb) = \(running) chips"))
        case let .bet(actor, n):
            let before = running
            running += n
            parts.append(language.text("\(actor.rawValue) 벳: \(before) + \(n) = \(running)칩",
                                       "\(DrillTerms.actor(actor, in: language)) bets: \(before) + \(n) = \(running) chips"))
        case let .call(actor, n):
            let before = running
            running += n
            parts.append(language.text("\(actor.rawValue) 콜: \(before) + \(n) = \(running)칩",
                                       "\(DrillTerms.actor(actor, in: language)) calls: \(before) + \(n) = \(running) chips"))
        case let .raiseTo(actor, to, from):
            if actor == .bb, spot.foldedActors.contains(.sb) {
                parts.append(language.text("SB 폴드: 이미 낸 칩은 팟에 남아요",
                                           "SB folds: the chips already posted stay in the pot"))
            }
            let before = running
            let added = to - from
            running += added
            parts.append(language.text(
                "\(actor.rawValue) 레이즈: \(before) + \(added) = \(running)칩 (총 \(to)칩)",
                "\(DrillTerms.actor(actor, in: language)) raises: \(before) + \(added) = \(running) chips (\(to) total)"))
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
