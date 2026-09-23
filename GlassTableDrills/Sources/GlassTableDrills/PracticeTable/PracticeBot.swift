// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// The only information passed to a bot policy. Its decision cannot inspect another hole hand.
public struct PracticeBotView: Sendable {
    public let seat: Int
    public let style: Archetype
    public let hole: [String]
    public let board: [String]
    public let street: PracticeStreet
    public let pot: Int
    public let toCall: Int
    public let stack: Int
    public let minimumRaiseTo: Int?
    public let hasRaisedThisStreet: Bool
}

public enum PracticeBotPolicy {
    public static let version = PracticeTableState.policyVersion

    /// Authored, deterministic training opponent. Percentages are selection rules,
    /// not a claim that observed four-seat action rates equal the headline VPIP/PFR.
    public static func action(for view: PracticeBotView) -> PracticeAction {
        guard let cards = Card.parse(view.hole.joined()) else {
            return view.toCall == 0 ? .check : .fold
        }
        if view.street == .preflop {
            let raiseRange = HandRange.topByChen(percent: view.style.pfr)
            let playRange = HandRange.topByChen(percent: view.style.vpip)
            if raiseRange.contains(cards), !view.hasRaisedThisStreet,
               let target = view.minimumRaiseTo { return .raise(to: target) }
            if playRange.contains(cards) { return view.toCall > 0 ? .call : .check }
            return view.toCall > 0 ? .fold : .check
        }
        guard let board = Card.parse(view.board.joined()) else {
            return view.toCall == 0 ? .check : .fold
        }
        let bucket = madeHand(hand: cards, board: board)
        let policy = view.style.postflop
        if view.toCall == 0 {
            if policy.opens(with: bucket), !view.hasRaisedThisStreet,
               let target = view.minimumRaiseTo { return .raise(to: target) }
            return .check
        }
        switch policy.response(toBetWith: bucket) {
        case .fold: return .fold
        case .call: return .call
        case .raise:
            if !view.hasRaisedThisStreet, let target = view.minimumRaiseTo { return .raise(to: target) }
            return .call
        }
    }
}

public extension PracticeTableState {
    /// Stops on the learner's next decision, or at settlement. Safe to call again on resume.
    mutating func advanceBots() throws {
        var guardCount = 0
        while let seat = currentSeat, seat != 0, street != .finished {
            guardCount += 1
            // Each of three bots may raise once per street. Each raise can require
            // at most three responses; four streets therefore need at most 48 actions
            // before returning to the learner or settling, regardless of stack sizes.
            guard guardCount <= 48 else { throw PracticeTableError.invalidState }
            let actions = legalActions
            let owed = max(0, (actions.contains(.call) ? 1 : 0))
            let target = actions.compactMap { action -> Int? in
                if case let .raise(to: amount) = action { return amount }
                return nil
            }.first
            // The public view uses only the bot's hole and the public table state.
            let view = PracticeBotView(seat: seat,
                                       style: Archetype(rawValue: styles[seat - 1]) ?? .tag,
                                       hole: seats[seat].hole, board: visibleBoard,
                                       street: street, pot: pot,
                                       toCall: owed == 0 ? 0 : max(0, currentStreetBet - seats[seat].streetCommitted),
                                       stack: seats[seat].stack, minimumRaiseTo: target,
                                       hasRaisedThisStreet: events.contains {
                                           guard $0.seat == seat, $0.street == street else { return false }
                                           if case .raise = $0.action { return true }
                                           return false
                                       })
            let choice = PracticeBotPolicy.action(for: view)
            try apply(choice, actionID: "\(handID)-bot-\(events.count)")
        }
    }
}
