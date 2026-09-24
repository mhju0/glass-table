// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// Fixed-blind practice for two to four seats: the learner plus one computer per style.
/// Seat zero is the learner. All money is integer chips.
public enum PracticeAction: Equatable, Sendable, Codable {
    case fold, check, call
    /// Total committed on this street, rather than an increment.
    case raise(to: Int)
}

public enum PracticeTableError: Error, Equatable {
    case handStillRunning, handFinished, wrongSeat, illegalAction, duplicateHandID, invalidState
}

public enum PracticeStreet: String, Codable, Sendable { case preflop, flop, turn, river, finished }

public struct PracticeSeat: Codable, Equatable, Sendable {
    public var stack: Int
    var hole: [String]
    public var committed: Int
    public var streetCommitted: Int
    public var folded: Bool
    public var enteredVoluntarily: Bool
    public var raisedPreflop: Bool

    public init(stack: Int) {
        self.stack = stack; hole = []
        committed = 0; streetCommitted = 0; folded = false
        enteredVoluntarily = false; raisedPreflop = false
    }
}

public struct PracticeEvent: Codable, Equatable, Sendable {
    public let id: String
    public let seat: Int
    public let street: PracticeStreet
    public let action: PracticeAction?
    public let chips: Int
    public let label: String
}

public struct PracticePot: Codable, Equatable, Sendable {
    public let amount: Int
    public let eligibleSeats: [Int]
    public let winners: [Int]
}

public struct PracticeTableReview: Codable, Equatable, Sendable {
    public let settlementID: String
    public let handID: String
    public let board: [String]
    public let holeCards: [[String]]
    public let contributions: [Int]
    public let refunds: [Int]
    public let payouts: [Int]
    public let pots: [PracticePot]
    public let events: [PracticeEvent]
    public let startingStacks: [Int]
    public let endingStacks: [Int]
    public let learnerEnteredVoluntarily: Bool
    public let learnerRaisedPreflop: Bool
}

/// Persist this entire value after each accepted command. No global RNG or clock is used.
public struct PracticeTableState: Codable, Equatable, Sendable {
    public static let rulesVersion = 1
    public static let policyVersion = 1
    public let storedRulesVersion: Int
    public let storedPolicyVersion: Int
    public let seed: UInt64
    public let styles: [String]
    public private(set) var seats: [PracticeSeat]
    public private(set) var dealer: Int
    public private(set) var handNumber: Int
    public private(set) var handID: String
    public private(set) var street: PracticeStreet
    private var board: [String]
    public private(set) var currentSeat: Int?
    public private(set) var events: [PracticeEvent]
    public private(set) var review: PracticeTableReview?
    public private(set) var refills: [Int]
    public private(set) var appliedActionIDs: [String]
    private var deck: [String]
    private var needsAction: [Bool]
    private var lastActedFacing: [Int?]
    private var currentBet: Int
    private var fullRaise: Int
    private var startingStacks: [Int]
    private var revealedCount: Int

    public var settlementID: String? { review?.settlementID }
    var currentStreetBet: Int { currentBet }
    public var amountToCall: Int {
        guard let currentSeat else { return 0 }
        return min(seats[currentSeat].stack, max(0, currentBet - seats[currentSeat].streetCommitted))
    }
    public var pot: Int { seats.reduce(0) { $0 + $1.committed } }
    public var learnerHole: [String] { seats[0].hole }
    public var visibleBoard: [String] { Array(board.prefix(revealedCount)) }
    /// The learner plus one seat per computer style.
    public var seatCount: Int { styles.count + 1 }

    /// Call after decoding an imported snapshot before it replaces live progress.
    public func validate() throws {
        let chipBound = Int.max / 64
        guard storedRulesVersion == Self.rulesVersion,
              storedPolicyVersion == Self.policyVersion,
              (1...3).contains(styles.count), styles.allSatisfy({ Archetype(rawValue: $0) != nil }),
              seats.count == seatCount, refills.count == seatCount, needsAction.count == seatCount,
              lastActedFacing.count == seatCount, startingStacks.count == seatCount,
              (0..<seatCount).contains(dealer), (0..<Int.max / 64).contains(handNumber),
              !handID.isEmpty,
              refills.allSatisfy({ (0...chipBound).contains($0) }),
              startingStacks.allSatisfy({ (1...chipBound).contains($0) }),
              deck.count == 52, Set(deck).count == 52,
              deck.allSatisfy({ Card($0) != nil }),
              board.count == 5, (0...5).contains(revealedCount),
              board.allSatisfy({ deck.contains($0) }),
              seats.allSatisfy({ $0.hole.count == 2 && (0...chipBound).contains($0.stack)
                                && (0...chipBound).contains($0.committed)
                                && (0...$0.committed).contains($0.streetCommitted)
                                && $0.hole.allSatisfy(deck.contains) }),
              Set(seats.flatMap(\.hole)).count == 2 * seatCount,
              Set(board).count == 5,
              Set(seats.flatMap(\.hole) + board).count == 2 * seatCount + 5,
              Set(appliedActionIDs).count == appliedActionIDs.count,
              (0...chipBound).contains(currentBet), (2...chipBound).contains(fullRaise),
              lastActedFacing.allSatisfy({ $0.map { (0...chipBound).contains($0) } ?? true }),
              events.allSatisfy({ (0..<seatCount).contains($0.seat) && (0...chipBound).contains($0.chips)
                                  && !$0.id.isEmpty }),
              Set(events.map(\.id)).count == events.count
        else { throw PracticeTableError.invalidState }
        let initial = startingStacks.reduce(0, +)
        let stacks = seats.map(\.stack).reduce(0, +)
        if street == .finished {
            guard currentSeat == nil, review?.handID == handID,
                  review?.settlementID == "\(handID)-settled",
                  stacks == initial else { throw PracticeTableError.invalidState }
        } else {
            guard let currentSeat, (0..<seatCount).contains(currentSeat), review == nil,
                  stacks + pot == initial else { throw PracticeTableError.invalidState }
        }
        // Imported state must be reachable by the versioned rules, not merely add
        // up. Replaying also verifies private deck order and every payout/review row.
        var replay = Self(seed: seed, styles: styles.compactMap(Archetype.init(rawValue:)), handID: handID)
        replay.dealer = dealer
        replay.handNumber = handNumber
        replay.refills = refills
        for seat in 0..<seatCount { replay.seats[seat].stack = startingStacks[seat] }
        replay.deal()
        guard events.count >= 2, Array(events.prefix(2)) == replay.events else {
            throw PracticeTableError.invalidState
        }
        for event in events.dropFirst(2) {
            guard replay.currentSeat == event.seat, replay.street == event.street,
                  let action = event.action else { throw PracticeTableError.invalidState }
            try replay.apply(action, actionID: event.id)
        }
        guard replay == self else { throw PracticeTableError.invalidState }
    }

    public init(seed: UInt64, styles: [Archetype] = [.tag, .station, .lag], handID: String = "hand-0") {
        precondition((1...3).contains(styles.count), "Practice seats one to three bots")
        self.seed = seed
        storedRulesVersion = Self.rulesVersion
        storedPolicyVersion = Self.policyVersion
        self.styles = styles.map(\.rawValue)
        let count = styles.count + 1
        seats = (0..<count).map { _ in PracticeSeat(stack: 100) }
        dealer = 0; handNumber = 0; self.handID = handID
        street = .preflop; board = []; currentSeat = nil; events = []; review = nil
        refills = Array(repeating: 0, count: count); appliedActionIDs = []
        deck = []; needsAction = Array(repeating: false, count: count)
        lastActedFacing = Array(repeating: nil, count: count); currentBet = 0; fullRaise = 2
        startingStacks = Array(repeating: 100, count: count)
        revealedCount = 0
        deal()
    }

    public var legalActions: [PracticeAction] {
        guard let seat = currentSeat, street != .finished else { return [] }
        let s = seats[seat]
        let owed = max(0, currentBet - s.streetCommitted)
        var result: [PracticeAction] = owed > 0 ? [.fold, .call] : [.check]
        if canRaise(seat), s.stack > owed {
            let minimum = currentBet == 0 ? 2 : currentBet + fullRaise
            if s.streetCommitted + s.stack >= minimum {
                result.append(.raise(to: minimum))
            } else {
                result.append(.raise(to: s.streetCommitted + s.stack)) // short all-in
            }
        }
        return result
    }

    /// A duplicate command is a no-op, including after a hand has settled.
    public mutating func apply(_ action: PracticeAction, actionID: String) throws {
        guard !actionID.isEmpty else { throw PracticeTableError.illegalAction }
        if appliedActionIDs.contains(actionID) { return }
        guard street != .finished else { throw PracticeTableError.handFinished }
        guard let actor = currentSeat else { throw PracticeTableError.invalidState }
        let owed = max(0, currentBet - seats[actor].streetCommitted)
        let oldBet = currentBet
        let committed: Int
        let label: String
        switch action {
        case .fold:
            guard owed > 0 else { throw PracticeTableError.illegalAction }
            seats[actor].folded = true; committed = 0; label = "fold"
        case .check:
            guard owed == 0 else { throw PracticeTableError.illegalAction }
            committed = 0; label = "check"
        case .call:
            guard owed > 0 else { throw PracticeTableError.illegalAction }
            committed = min(owed, seats[actor].stack); label = "call"
        case .raise(let target):
            guard canRaise(actor), target > currentBet,
                  target > seats[actor].streetCommitted,
                  target <= seats[actor].streetCommitted + seats[actor].stack else {
                throw PracticeTableError.illegalAction
            }
            let increment = target - currentBet
            guard increment >= fullRaise || target == seats[actor].streetCommitted + seats[actor].stack else {
                throw PracticeTableError.illegalAction
            }
            committed = target - seats[actor].streetCommitted
            currentBet = target
            if increment >= fullRaise { fullRaise = increment }
            label = oldBet == 0 ? "bet" : "raise"
        }
        seats[actor].stack -= committed
        seats[actor].committed += committed
        seats[actor].streetCommitted += committed
        if street == .preflop && committed > 0 { seats[actor].enteredVoluntarily = true }
        if street == .preflop && label == "raise" { seats[actor].raisedPreflop = true }
        lastActedFacing[actor] = currentBet
        needsAction[actor] = false
        if currentBet > oldBet {
            for i in 0..<seatCount where i != actor && mayAct(i) && seats[i].streetCommitted < currentBet {
                needsAction[i] = true
            }
        }
        events.append(PracticeEvent(id: actionID, seat: actor, street: street,
                                    action: action, chips: committed, label: label))
        appliedActionIDs.append(actionID)
        progress(after: actor)
    }

    public mutating func nextHand(handID newID: String) throws {
        guard !newID.isEmpty else { throw PracticeTableError.invalidState }
        if newID == handID { return }
        guard street == .finished else { throw PracticeTableError.handStillRunning }
        for i in 0..<seatCount where seats[i].stack == 0 {
            seats[i].stack = 100; refills[i] += 100
        }
        dealer = (dealer + 1) % seatCount; handNumber += 1; handID = newID
        deal()
    }

    private mutating func deal() {
        var rng = SplitMix64(seed: seed &+ UInt64(handNumber) &* 0x9E37_79B9_7F4A_7C15)
        var cards = Deck.all
        cards.shuffle(using: &rng)
        deck = cards.map(\.description)
        let count = seatCount
        for i in 0..<count {
            seats[i].hole = Array(deck[(i * 2)..<(i * 2 + 2)])
            seats[i].committed = 0; seats[i].streetCommitted = 0
            seats[i].folded = false; seats[i].enteredVoluntarily = false
            seats[i].raisedPreflop = false
        }
        board = Array(deck[(count * 2)..<(count * 2 + 5)]); street = .preflop; review = nil; revealedCount = 0
        events = []; appliedActionIDs = []; startingStacks = seats.map(\.stack)
        needsAction = Array(repeating: true, count: count)
        lastActedFacing = Array(repeating: nil, count: count)
        // Heads-up, the button is the small blind and speaks first before the flop.
        let sb = count == 2 ? dealer : (dealer + 1) % count
        let bb = (sb + 1) % count
        postBlind(sb, amount: 1, label: "small blind")
        postBlind(bb, amount: 2, label: "big blind")
        currentBet = 2; fullRaise = 2
        currentSeat = (bb + 1) % count
        if !mayAct(currentSeat!) { progress(after: (currentSeat! + count - 1) % count) }
    }

    /// Internal deterministic rules fixture; production starts every seat at 100.
    static func fixture(seed: UInt64, stacks: [Int], dealer: Int = 0) -> Self {
        precondition(stacks.count == 4 && stacks.allSatisfy { $0 > 0 } && (0..<4).contains(dealer))
        var table = Self(seed: seed)
        for i in 0..<4 { table.seats[i].stack = stacks[i] }
        table.dealer = dealer
        table.deal()
        return table
    }

    static func settlementFixture(contributions: [Int], folded: [Bool],
                                  holes: [[String]], board: [String], dealer: Int) -> Self {
        precondition(contributions.count == 4 && folded.count == 4 && holes.count == 4
                     && board.count == 5 && (0..<4).contains(dealer))
        var table = Self(seed: 0)
        table.dealer = dealer; table.board = board; table.revealedCount = 5
        table.street = .river
        for i in 0..<4 {
            table.seats[i].hole = holes[i]
            table.seats[i].committed = contributions[i]
            table.seats[i].folded = folded[i]
            table.seats[i].stack = max(0, 100 - contributions[i])
        }
        table.settle()
        return table
    }

    private mutating func postBlind(_ seat: Int, amount: Int, label: String) {
        let chips = min(amount, seats[seat].stack)
        seats[seat].stack -= chips; seats[seat].committed += chips
        seats[seat].streetCommitted += chips
        if chips == seats[seat].stack + chips { needsAction[seat] = false }
        events.append(PracticeEvent(id: "\(handID)-blind-\(seat)", seat: seat,
                                    street: .preflop, action: nil, chips: chips, label: label))
    }

    private func mayAct(_ seat: Int) -> Bool { !seats[seat].folded && seats[seat].stack > 0 }
    private func canRaise(_ seat: Int) -> Bool {
        // A wager needs someone who can answer it. All-in seats may contest the
        // existing pot, but no additional chips can be wagered against them.
        guard (0..<seatCount).contains(where: { $0 != seat && mayAct($0) }) else { return false }
        guard let seen = lastActedFacing[seat] else { return true }
        return currentBet - seen >= fullRaise
    }

    private mutating func progress(after actor: Int) {
        let live = (0..<seatCount).filter { !seats[$0].folded }
        if live.count == 1 { settle(); return }
        if let next = (1...seatCount).map({ (actor + $0) % seatCount }).first(where: { needsAction[$0] && mayAct($0) }) {
            currentSeat = next; return
        }
        if street == .river { settle(); return }
        while true {
            switch street {
            case .preflop: street = .flop; revealedCount = 3
            case .flop: street = .turn; revealedCount = 4
            case .turn: street = .river; revealedCount = 5
            case .river, .finished: settle(); return
            }
            for i in 0..<seatCount { seats[i].streetCommitted = 0 }
            currentBet = 0; fullRaise = 2
            lastActedFacing = Array(repeating: nil, count: seatCount)
            needsAction = (0..<seatCount).map { mayAct($0) }
            let active = (0..<seatCount).filter { mayAct($0) }
            if active.count > 1 {
                currentSeat = (1...seatCount).map({ (dealer + $0) % seatCount }).first(where: { mayAct($0) })
                return
            }
            if street == .river { settle(); return }
        }
    }

    private mutating func settle() {
        let contributions = seats.map(\.committed)
        var refunds = [Int](repeating: 0, count: seatCount)
        var payouts = [Int](repeating: 0, count: seatCount)
        var pots: [PracticePot] = []
        var previous = 0
        for level in Set(contributions).filter({ $0 > 0 }).sorted() {
            let contributors = (0..<seatCount).filter { contributions[$0] >= level }
            let amount = (level - previous) * contributors.count
            let eligible = contributors.filter { !seats[$0].folded }
            if contributors.count == 1 {
                refunds[contributors[0]] += amount
            } else if eligible.count == 1 {
                payouts[eligible[0]] += amount
                pots.append(PracticePot(amount: amount, eligibleSeats: eligible, winners: eligible))
            } else if !eligible.isEmpty {
                var winners = [eligible[0]]
                for seat in eligible.dropFirst() {
                    let a = cardList(seats[seat].hole), b = cardList(seats[winners[0]].hole)
                    let result = exactEquityHeadsUp(hero: a, villain: b, board: cardList(board))
                    if result.wins == 1 { winners = [seat] }
                    else if result.ties == 1 { winners.append(seat) }
                }
                let share = amount / winners.count
                for winner in winners { payouts[winner] += share }
                var remainder = amount % winners.count
                for seat in (1...seatCount).map({ (dealer + $0) % seatCount }) where winners.contains(seat) && remainder > 0 {
                    payouts[seat] += 1; remainder -= 1
                }
                pots.append(PracticePot(amount: amount, eligibleSeats: eligible, winners: winners))
            }
            previous = level
        }
        for i in 0..<seatCount { seats[i].stack += refunds[i] + payouts[i] }
        let exposedBoard = visibleBoard
        street = .finished; currentSeat = nil; needsAction = Array(repeating: false, count: seatCount)
        review = PracticeTableReview(settlementID: "\(handID)-settled", handID: handID,
                                     board: exposedBoard, holeCards: seats.map(\.hole),
                                     contributions: contributions, refunds: refunds,
                                     payouts: payouts, pots: pots, events: events,
                                     startingStacks: startingStacks, endingStacks: seats.map(\.stack),
                                     learnerEnteredVoluntarily: seats[0].enteredVoluntarily,
                                     learnerRaisedPreflop: seats[0].raisedPreflop)
    }
}

private func cardList(_ IDs: [String]) -> [Card] {
    IDs.compactMap(Card.init)
}
