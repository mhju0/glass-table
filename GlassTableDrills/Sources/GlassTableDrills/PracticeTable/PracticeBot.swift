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
    /// Already in on this street; with `stack`, the most a raise can reach.
    public var streetCommitted = 0
    /// Seeded per decision. Only the casual style reads it.
    public var roll: UInt64 = 0
}

public enum PracticeBotPolicy {
    public static let version = PracticeTableState.policyVersion

    /// Authored, deterministic training opponent. Percentages are selection rules,
    /// not a claim that observed four-seat action rates equal the headline VPIP/PFR.
    public static func action(for view: PracticeBotView) -> PracticeAction {
        guard let cards = Card.parse(view.hole.joined()) else {
            return view.toCall == 0 ? .check : .fold
        }
        if view.style == .casual { return casualAction(for: view, cards: cards) }
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

    /// The friendly table's player: the same public information as every other style,
    /// plus one seeded roll, so it sizes bets like a person and now and then bluffs or
    /// calls out of curiosity. The same seed and actions always replay the same game.
    private static func casualAction(for view: PracticeBotView, cards: [Card]) -> PracticeAction {
        let chance = Double(view.roll % 1000) / 1000
        func raise(to wanted: Int) -> PracticeAction? {
            guard !view.hasRaisedThisStreet, let minimum = view.minimumRaiseTo else { return nil }
            return .raise(to: min(max(minimum, view.streetCommitted + view.stack), max(minimum, wanted)))
        }
        let passive: PracticeAction = view.toCall > 0 ? .call : .check
        if view.street == .preflop {
            if HandRange.topByChen(percent: view.style.pfr).contains(cards) {
                return raise(to: view.toCall <= 2 ? 6 : 0) ?? passive
            }
            if HandRange.topByChen(percent: view.style.vpip).contains(cards) { return passive }
            if view.toCall == 0 { return .check }
            return view.toCall <= 2 && chance < 0.12 ? .call : .fold
        }
        guard let board = Card.parse(view.board.joined()) else {
            return view.toCall == 0 ? .check : .fold
        }
        let bucket = madeHand(hand: cards, board: board)
        let halfPot = max(2, view.pot / 2)
        if view.toCall == 0 {
            if view.style.postflop.opens(with: bucket) || chance < 0.15 {
                return raise(to: halfPot) ?? .check
            }
            return .check
        }
        switch bucket {
        case .strong: return chance < 0.5 ? raise(to: 0) ?? .call : .call
        case .air: return view.toCall * 4 <= view.pot && chance < 0.10 ? .call : .fold
        default: return .call
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
            var roll = SplitMix64(seed: seed ^ UInt64(handNumber) &* 0x9E37_79B9_7F4A_7C15
                                  ^ UInt64(events.count) << 32 ^ UInt64(seat))
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
                                       },
                                       streetCommitted: seats[seat].streetCommitted,
                                       roll: roll.next())
            let choice = PracticeBotPolicy.action(for: view)
            try apply(choice, actionID: "\(handID)-bot-\(events.count)")
        }
    }
}
