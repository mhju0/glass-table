// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

public enum QuickPlayEndReason: String, Codable, Sendable {
    case completed, learnerBusted, endedEarly
}

/// Settled snapshots only. A session identity is independent of its deterministic seed.
public struct QuickPlaySession: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let seed: UInt64
    public let styles: [String]
    public let startingStack: Int
    public let handLimit: Int
    public let coverageStartHandNumber: Int
    public private(set) var hands: [PracticeTableState]
    public private(set) var endReason: QuickPlayEndReason?

    public init(id: String = UUID().uuidString, table: PracticeTableState) {
        precondition(table.handLimit != nil)
        self.id = id; seed = table.seed; styles = table.styles
        startingStack = table.startingStack; handLimit = table.handLimit!
        coverageStartHandNumber = table.handNumber
        hands = []; endReason = nil
    }

    public mutating func capture(_ table: PracticeTableState) {
        guard table.review != nil, !hands.contains(where: { $0.settlementID == table.settlementID }) else { return }
        hands.append(table)
    }

    public mutating func finish(table: PracticeTableState) {
        endReason = table.isGameOver
            ? (table.seats[0].stack == 0 ? .learnerBusted : .completed) : .endedEarly
    }

    public func validate() throws {
        guard UUID(uuidString: id) != nil, (1...3).contains(styles.count),
              styles.allSatisfy({ Archetype(rawValue: $0) != nil }),
              (2...Int.max / 64).contains(startingStack), (1...100).contains(handLimit),
              (0..<handLimit).contains(coverageStartHandNumber),
              hands.count <= handLimit - coverageStartHandNumber,
              endReason == nil || !hands.isEmpty else { throw PracticeTableError.invalidState }
        for (index, hand) in hands.enumerated() {
            try hand.validate()
            guard hand.review != nil, hand.seed == seed, hand.styles == styles,
                  hand.startingStack == startingStack, hand.handLimit == handLimit,
                  hand.handNumber == coverageStartHandNumber + index else { throw PracticeTableError.invalidState }
            if index > 0 { try Self.validateTransition(from: hands[index - 1], to: hand) }
            else if coverageStartHandNumber == 0 { try Self.validateInitial(hand) }
        }
        if let last = hands.last {
            switch endReason {
            case .completed: guard last.isGameOver, last.seats[0].stack > 0 else { throw PracticeTableError.invalidState }
            case .learnerBusted: guard last.isGameOver, last.seats[0].stack == 0 else { throw PracticeTableError.invalidState }
            case .endedEarly: guard !last.isGameOver else { throw PracticeTableError.invalidState }
            case nil: break
            }
        }
    }

    static func validateInitial(_ table: PracticeTableState) throws {
        func matches(startingStack: Int?) throws -> Bool {
            var replay = PracticeTableState(seed: table.seed,
                styles: table.styles.compactMap(Archetype.init(rawValue:)), handID: table.handID,
                startingStack: startingStack, handLimit: table.handLimit)
            guard replay.events == Array(table.events.prefix(2)) else { return false }
            for event in table.events.dropFirst(2) {
                guard replay.currentSeat == event.seat, let action = event.action else { return false }
                try replay.apply(action, actionID: event.id)
            }
            return replay == table
        }
        if try matches(startingStack: table.startingStack) { return }
        // The original API also permits a hand limit with its default 100-chip stack.
        if table.startingStack == 100, try matches(startingStack: nil) { return }
        throw PracticeTableError.invalidState
    }

    static func validateTransition(from previous: PracticeTableState, to next: PracticeTableState) throws {
        var replay = previous
        try replay.nextHand(handID: next.handID)
        guard replay.events == Array(next.events.prefix(2)) else { throw PracticeTableError.invalidState }
        for event in next.events.dropFirst(2) {
            guard replay.currentSeat == event.seat, let action = event.action else { throw PracticeTableError.invalidState }
            try replay.apply(action, actionID: event.id)
        }
        guard replay == next else { throw PracticeTableError.invalidState }
    }

    public var metrics: QuickPlayMetrics { QuickPlayMetrics(hands: hands) }
}

public struct QuickPlayMetrics: Equatable, Sendable {
    public let hands: Int
    public let voluntaryEntries: Int
    public let preflopRaises: Int
    public let decisions: Int
    public let folds: Int
    public let checks: Int
    public let calls: Int
    public let bets: Int
    public let raises: Int
    public let good: Int
    public let fine: Int
    public let risky: Int
    public let netChips: Int

    public init(hands snapshots: [PracticeTableState]) {
        let reviews = snapshots.compactMap(\.review)
        let actions = snapshots.flatMap(\.events).filter { $0.seat == 0 && $0.action != nil }
        let steps = snapshots.flatMap { PracticeHandCoach.steps(for: $0) }
        hands = reviews.count
        voluntaryEntries = reviews.filter(\.learnerEnteredVoluntarily).count
        preflopRaises = reviews.filter(\.learnerRaisedPreflop).count
        decisions = actions.count
        folds = actions.filter { $0.label == "fold" }.count
        checks = actions.filter { $0.label == "check" }.count
        calls = actions.filter { $0.label == "call" }.count
        bets = actions.filter { $0.label == "bet" }.count
        raises = actions.filter { $0.label == "raise" }.count
        good = steps.filter { $0.verdict == .good }.count
        fine = steps.filter { $0.verdict == .fine }.count
        risky = steps.filter { $0.verdict == .risky }.count
        netChips = reviews.reduce(0) { $0 + $1.endingStacks[0] - $1.startingStacks[0] }
    }
    public var reviewedDecisions: Int { good + fine + risky }
}

extension ProgressState {
    public static let quickPlayCompletedSessionCap = 20

    /// Called inside the same transaction as tableState and recentHands.
    public mutating func captureQuickPlay(_ table: PracticeTableState) {
        guard table.handLimit != nil else { return }
        if activeQuickPlaySessionID == nil {
            let session = QuickPlaySession(table: table)
            quickPlaySessions.append(session); activeQuickPlaySessionID = session.id
        }
        guard let index = quickPlaySessions.firstIndex(where: { $0.id == activeQuickPlaySessionID }) else { return }
        quickPlaySessions[index].capture(table)
    }

    public mutating func finishQuickPlay(_ table: PracticeTableState) {
        captureQuickPlay(table)
        if let index = quickPlaySessions.firstIndex(where: { $0.id == activeQuickPlaySessionID }) {
            if quickPlaySessions[index].hands.isEmpty { quickPlaySessions.remove(at: index) }
            else { quickPlaySessions[index].finish(table: table) }
        }
        activeQuickPlaySessionID = nil
        while quickPlaySessions.filter({ $0.endReason != nil }).count > Self.quickPlayCompletedSessionCap {
            if let oldest = quickPlaySessions.firstIndex(where: { $0.endReason != nil }) {
                quickPlaySessions.remove(at: oldest)
            }
        }
    }

    public func validateQuickPlayArchive() throws {
        guard quickPlaySessions.count <= Self.quickPlayCompletedSessionCap + 1,
              Set(quickPlaySessions.map(\.id)).count == quickPlaySessions.count,
              quickPlaySessions.filter({ $0.endReason != nil }).count <= Self.quickPlayCompletedSessionCap,
              quickPlaySessions.filter({ $0.endReason == nil }).count == (activeQuickPlaySessionID == nil ? 0 : 1)
        else { throw PracticeTableError.invalidState }
        let handIDs = quickPlaySessions.flatMap(\.hands).map(\.handID)
        guard Set(handIDs).count == handIDs.count else { throw PracticeTableError.invalidState }
        for session in quickPlaySessions { try session.validate() }
        if let activeQuickPlaySessionID {
            guard let session = quickPlaySessions.first(where: { $0.id == activeQuickPlaySessionID }),
                  session.endReason == nil, let table = tableState,
                  table.handLimit == session.handLimit, table.seed == session.seed,
                  table.styles == session.styles, table.startingStack == session.startingStack
            else { throw PracticeTableError.invalidState }
            if let last = session.hands.last {
                if table.handID == last.handID {
                    guard table == last else { throw PracticeTableError.invalidState }
                } else { try QuickPlaySession.validateTransition(from: last, to: table) }
            } else {
                guard table.handNumber == session.coverageStartHandNumber, table.review == nil else {
                    throw PracticeTableError.invalidState
                }
                if session.coverageStartHandNumber == 0 { try QuickPlaySession.validateInitial(table) }
            }
        }
    }
}
