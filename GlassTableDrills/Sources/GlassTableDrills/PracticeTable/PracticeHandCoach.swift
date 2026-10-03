// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// A finished free-table hand, retold one learner decision at a time.
///
/// The advice is the app's own beginner chart, a few plain rules a new player can
/// hold in their head. It is not solver output and never claims to be what an expert
/// would do. Every verdict uses only what the learner could see when they chose.
public struct PracticeCoachStep: Equatable, Sendable {
    /// What the learner held at the moment of the decision.
    public enum Strength: String, Sendable, CaseIterable {
        /// Before the flop: top 15%, top 45%, and the rest of all starting hands.
        case premium, playable, weak
        /// After the flop.
        case strong, topPair, weakPair, draw, air
    }

    public enum Verdict: String, Sendable { case good, fine, risky }

    /// An opponent's action on this street that the learner was answering.
    public struct Pressure: Equatable, Sendable {
        public let seat: Int
        public let label: String
        public let chips: Int
    }

    public let eventIndex: Int
    /// Replay steps already shown when the learner chose: `table.frame(after:)` of this
    /// is the table they were looking at.
    public let stepIndex: Int
    public let street: PracticeStreet
    public let action: PracticeAction
    public let chips: Int
    public let facts: PracticeDecisionFacts
    public let strength: Strength
    public let pressure: [Pressure]
    public let verdict: Verdict
}

/// An opponent's bet or raise after the flop, read back once their cards were shown.
public struct PracticeCoachReveal: Equatable, Sendable {
    public let seat: Int
    public let eventIndex: Int
    public let street: PracticeStreet
    public let held: MadeHand
    /// A bet with no pair and no draw: it could only win by making everyone fold.
    public var wasBluff: Bool { held == .air }
}

public enum PracticeHandCoach {
    /// Share of starting hands the beginner chart raises, and the share it plays at all.
    public static let premiumPercent = 15
    public static let playablePercent = 45

    /// One step per learner action in a settled hand, in the order they happened.
    public static func steps(for table: PracticeTableState) -> [PracticeCoachStep] {
        guard let review = table.review, let hole = Card.parse(table.learnerHole.joined()) else { return [] }
        var result: [PracticeCoachStep] = []
        for (stepIndex, step) in table.replaySteps.enumerated() {
            guard case let .action(eventIndex) = step else { continue }
            let event = table.events[eventIndex]
            guard event.seat == 0, let action = event.action else { continue }
            let frame = table.frame(after: stepIndex)
            guard let facts = PracticeDecisionFacts(frame: frame, learnerHole: table.learnerHole,
                                                     visibleBoard: review.board) else { continue }
            let board = Card.parse(review.board.prefix(frame.boardCount).joined()) ?? []
            let strength = strength(hole: hole, board: board, topPercent: facts.startingHandTopPercent)
            let pressure = (1..<table.seatCount).compactMap { seat -> PracticeCoachStep.Pressure? in
                guard let last = frame.lastEvent[seat], last.action != nil else { return nil }
                return .init(seat: seat, label: last.label, chips: last.chips)
            }
            result.append(PracticeCoachStep(
                eventIndex: eventIndex, stepIndex: stepIndex, street: event.street, action: action,
                chips: event.chips, facts: facts, strength: strength, pressure: pressure,
                verdict: verdict(action: action, strength: strength, toCall: facts.toCall,
                                 needed: facts.requiredEquityPercent, boardCount: board.count)))
        }
        return result
    }

    public static func strength(hole: [Card], board: [Card], topPercent: Int?) -> PracticeCoachStep.Strength {
        guard board.count >= 3 else {
            let top = topPercent ?? 100
            return top <= premiumPercent ? .premium : top <= playablePercent ? .playable : .weak
        }
        switch madeHand(hand: hole, board: board) {
        case .strong: return .strong
        case .topPair: return .topPair
        case .weakPair: return .weakPair
        case .draw: return .draw
        case .air: return .air
        }
    }

    /// What the beginner chart would do here, for a learner who asks before choosing at
    /// the free table. The same rules as `verdict`, so a hint and the later review of
    /// the same decision can never disagree. Graded lessons never call this.
    public static func suggestion(strength: PracticeCoachStep.Strength, toCall: Int, needed: Int?,
                                  boardCount: Int, legal: [PracticeAction]) -> PracticeAction? {
        let raise = legal.first { if case .raise = $0 { true } else { false } }
        func rated(_ wanted: PracticeCoachStep.Verdict, _ order: [PracticeAction?]) -> PracticeAction? {
            order.compactMap { $0 }.first {
                legal.contains($0) && verdict(action: $0, strength: strength, toCall: toCall,
                                              needed: needed, boardCount: boardCount) == wanted
            }
        }
        // When nothing is clearly good, lean to the cheaper choice.
        return rated(.good, [raise, .check, .call, .fold]) ?? rated(.fine, [.check, .fold, .call, raise])
    }

    /// The beginner chart, in full. Raise the best starting hands, play the decent ones
    /// cheaply, fold the rest when it costs chips. After the flop, bet top pair or
    /// better, keep small pairs and draws cheap, and let nothing-hands go.
    public static func verdict(action: PracticeAction, strength: PracticeCoachStep.Strength,
                               toCall: Int, needed: Int?, boardCount: Int) -> PracticeCoachStep.Verdict {
        let raised: Bool = if case .raise = action { true } else { false }
        switch strength {
        case .premium, .strong, .topPair:
            if raised { return .good }
            return action == .fold ? .risky : .fine
        case .playable:
            if action == .fold { return toCall > 2 ? .fine : .risky }
            return raised ? .fine : .good
        case .weak:
            if action == .check || action == .fold { return .good }
            // Completing the small blind for one chip is cheap enough to look.
            return action == .call && toCall <= 1 ? .fine : .risky
        case .weakPair:
            if action == .check { return .good }
            if action == .call { return (needed ?? 0) <= 25 ? .good : .risky }
            return .fine
        case .draw:
            if action == .check { return .good }
            // A flush or straight draw arrives about one time in three with two cards
            // to come and one in five with one to come.
            if action == .call { return (needed ?? 0) <= (boardCount == 3 ? 35 : 20) ? .good : .risky }
            return .fine
        case .air:
            if action == .check || action == .fold { return .good }
            return raised ? .fine : .risky
        }
    }

    /// Bets and raises after the flop by opponents whose cards reached the showdown.
    /// A folded opponent's cards were never shown, so they are never read back.
    public static func reveals(for table: PracticeTableState) -> [PracticeCoachReveal] {
        guard let review = table.review else { return [] }
        let shown = Set(review.pots.filter { $0.eligibleSeats.count > 1 }.flatMap(\.eligibleSeats))
        return table.events.enumerated().compactMap { index, event in
            guard event.seat != 0, shown.contains(event.seat), event.street != .preflop,
                  event.label == "bet" || event.label == "raise",
                  let hole = Card.parse(review.holeCards[event.seat].joined()),
                  let board = Card.parse(review.board.prefix(PracticeTableState.boardCount(event.street)).joined()),
                  board.count >= 3 else { return nil }
            return PracticeCoachReveal(seat: event.seat, eventIndex: index, street: event.street,
                                       held: madeHand(hand: hole, board: board))
        }
    }
}
