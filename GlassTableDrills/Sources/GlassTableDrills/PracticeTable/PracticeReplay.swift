import GlassTableEngine

/// One beat of a hand as the table shows it: a seat acting, or shared cards arriving.
/// The model applies every bot action at once; the screen steps through these so the
/// learner sees each seat act in turn.
public enum PracticeReplayStep: Equatable, Sendable {
    case action(eventIndex: Int)
    case deal(PracticeStreet)
    /// The hand is settled: stacks become the ending stacks and the pot is paid out.
    case settle
}

/// The public table after some prefix of the replay steps.
public struct PracticeTableFrame: Equatable, Sendable {
    public var stacks: [Int]
    public var committed: [Int]
    public var streetCommitted: [Int]
    public var folded: [Bool]
    public var street: PracticeStreet
    public var boardCount: Int
    /// Each seat's latest action on the current street; a new street clears it.
    public var lastEvent: [PracticeEvent?]
    public var settled: Bool
    public var pot: Int { settled ? 0 : committed.reduce(0, +) }
}

extension PracticeTableState {
    /// Every step of the current hand, blinds first. A live hand ends with the cards the
    /// seat to act can see; a settled hand ends with its final board and the payout.
    public var replaySteps: [PracticeReplayStep] {
        var steps: [PracticeReplayStep] = []
        var dealt = 0
        func deal(upTo count: Int) {
            for (street, cards) in [(PracticeStreet.flop, 3), (.turn, 4), (.river, 5)]
            where cards > dealt && cards <= count {
                steps.append(.deal(street)); dealt = cards
            }
        }
        for (index, event) in events.enumerated() {
            deal(upTo: Self.boardCount(event.street))
            steps.append(.action(eventIndex: index))
        }
        deal(upTo: review?.board.count ?? visibleBoard.count)
        if review != nil { steps.append(.settle) }
        return steps
    }

    /// The table after the first `count` replay steps.
    public func frame(after count: Int) -> PracticeTableFrame {
        let starting = review?.startingStacks ?? seats.map { $0.stack + $0.committed }
        var frame = PracticeTableFrame(
            stacks: starting, committed: Array(repeating: 0, count: seatCount),
            streetCommitted: Array(repeating: 0, count: seatCount),
            folded: Array(repeating: false, count: seatCount), street: .preflop,
            boardCount: 0, lastEvent: Array(repeating: nil, count: seatCount), settled: false)
        for step in replaySteps.prefix(max(0, count)) {
            switch step {
            case let .action(index):
                let event = events[index]
                frame.stacks[event.seat] -= event.chips
                frame.committed[event.seat] += event.chips
                frame.streetCommitted[event.seat] += event.chips
                if event.label == "fold" { frame.folded[event.seat] = true }
                frame.lastEvent[event.seat] = event
            case let .deal(street):
                frame.street = street
                frame.boardCount = Self.boardCount(street)
                frame.streetCommitted = Array(repeating: 0, count: seatCount)
                frame.lastEvent = Array(repeating: nil, count: seatCount)
            case .settle:
                if let review { frame.stacks = review.endingStacks }
                frame.street = .finished
                frame.settled = true
            }
        }
        return frame
    }

    /// Each computer's seat with its style. Seat 0 is the learner, so a table with
    /// `n` players has `n - 1` of these.
    public var computerSeats: [(seat: Int, style: Archetype)] {
        styles.enumerated().compactMap { index, raw in
            Archetype(rawValue: raw).map { (seat: index + 1, style: $0) }
        }
    }

    static func boardCount(_ street: PracticeStreet) -> Int {
        switch street {
        case .preflop: 0
        case .flop: 3
        case .turn: 4
        case .river, .finished: 5
        }
    }
}

/// Facts about the learner's decision that a hint may show. None of them is a
/// recommendation: the hint names what the hand is and what each choice costs.
public struct PracticeDecisionFacts: Equatable {
    /// Share of all starting hands at least as strong by Chen score, e.g. 12 for the
    /// top 12%. Present before the flop only.
    public let startingHandTopPercent: Int?
    public let startingHand: String?
    /// The best made hand with the shared cards, after the flop.
    public let madeHand: HandBrief?
    public let toCall: Int
    public let pot: Int
    /// Share of the final pot a call must win to break even, as a whole percent.
    public let requiredEquityPercent: Int?

    public init?(table: PracticeTableState) {
        guard table.street != .finished, table.currentSeat == 0 else { return nil }
        self.init(frame: table.frame(after: table.replaySteps.count),
                  learnerHole: table.learnerHole, visibleBoard: table.visibleBoard)
    }

    /// Uses only the rendered public prefix, even when the model has already settled.
    public init?(frame: PracticeTableFrame, learnerHole: [String], visibleBoard: [String]) {
        guard let hole = Card.parse(learnerHole.joined()), hole.count == 2 else { return nil }
        let board = Card.parse(visibleBoard.prefix(frame.boardCount).joined()) ?? []
        if board.isEmpty, let hand = HandClass(hole),
           let rank = Chen.ranked.firstIndex(of: hand) {
            let combos = Chen.ranked.prefix(rank + 1).reduce(0) { $0 + $1.comboCount }
            startingHandTopPercent = max(1, Int((Double(combos) / Double(HandClass.totalCombos) * 100).rounded()))
            startingHand = hand.description
        } else {
            startingHandTopPercent = nil
            startingHand = nil
        }
        madeHand = board.count >= 3 ? bestHandOfAny(hole + board) : nil
        let currentBet = max(frame.street == .preflop ? 2 : 0, frame.streetCommitted.max() ?? 0)
        toCall = frame.settled || frame.folded[0] ? 0
            : min(frame.stacks[0], max(0, currentBet - frame.streetCommitted[0]))
        pot = frame.pot
        requiredEquityPercent = Self.requiredEquityPercent(contributions: frame.committed, call: toCall)
    }

    /// Only the learner's contestable chips count; unmatched excess is returned.
    public static func requiredEquityPercent(contributions: [Int], call: Int) -> Int? {
        guard call > 0, let hero = contributions.first else { return nil }
        let opponents = contributions.dropFirst()
        let maximum = opponents.max() ?? 0
        let after = hero + call
        let refundBefore = max(0, hero - maximum)
        let refundAfter = max(0, after - maximum)
        let contestable = after + opponents.reduce(0) { $0 + min($1, after) } - refundAfter
        guard contestable > 0 else { return nil }
        let cost = call - (refundAfter - refundBefore)
        return Int((Double(cost) / Double(contestable) * 100).rounded())
    }
}
