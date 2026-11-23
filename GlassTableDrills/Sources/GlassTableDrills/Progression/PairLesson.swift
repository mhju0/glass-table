// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum PairLessonSide: String, Codable, Sendable {
    case learner, opponent
}

public enum PairLessonPhase: Equatable, Sendable {
    case example, guided, solo, retry, finished
}

public enum PairLessonAction: Equatable, Sendable {
    case select(PairLessonSide)
    case hint
    case submit
    case advance
}

public struct PairLessonQuestion: Identifiable, Equatable, Sendable {
    public let id: String
    public let board: [Card]
    public let learner: [Card]
    public let opponent: [Card]
    public let winner: PairLessonSide
}

public struct PairLessonProgress: Codable, Equatable, Sendable {
    private static let guidedTotal = 2
    private static let soloTotal = 8
    private static let answerTotal = guidedTotal + soloTotal
    private static let activityTotal = 1 + answerTotal

    private let contentVersion: Int
    let seed: UInt64
    private let excludedSoloIDs: [String]?
    private let schedule: [PairLessonCardTokens]
    private var activityIndex: Int
    private var retryIndex = 0
    private var firstAnswers: [PairLessonSide] = []
    private var retryAnswers: [PairLessonSide] = []
    private var helpUsedAt: [Int] = []
    private var previousBestFirstRight: Int?
    public private(set) var selection: PairLessonSide?
    public private(set) var hintVisible = false

    public init(seed: UInt64, exampleAlreadySeen: Bool = false) {
        self.init(seed: seed, exampleAlreadySeen: exampleAlreadySeen, excludedSoloIDs: nil, previousBest: nil)
    }

    private init(seed: UInt64, exampleAlreadySeen: Bool, excludedSoloIDs: [String]?, previousBest: Int?) {
        self.seed = seed
        self.excludedSoloIDs = excludedSoloIDs
        contentVersion = PairLessonContentV1.version
        schedule = PairLessonContentV1.schedule(seed: seed, excluding: Set(excludedSoloIDs ?? []))
        activityIndex = exampleAlreadySeen ? 1 : 0
        previousBestFirstRight = previousBest
    }

    public var phase: PairLessonPhase {
        switch activityIndex {
        case 0: return .example
        case 1...Self.guidedTotal: return .guided
        case (Self.guidedTotal + 1)...Self.answerTotal: return .solo
        default: return retryIndex < missedActivities.count ? .retry : .finished
        }
    }

    public var currentQuestion: PairLessonQuestion? {
        switch phase {
        case .example, .guided, .solo:
            return question(at: activityIndex)
        case .retry:
            let misses = missedActivities
            guard misses.indices.contains(retryIndex) else { return nil }
            return question(at: misses[retryIndex])
        case .finished:
            return nil
        }
    }

    public var revealed: Bool { submittedAnswer != nil }

    public var currentHelpUsed: Bool {
        (1...Self.answerTotal).contains(activityIndex) && helpUsedAt.contains(activityIndex)
    }

    public var firstRight: Int {
        firstAnswers.enumerated().filter { index, answer in
            let activity = index + 1
            return activity > Self.guidedTotal && !helpUsedAt.contains(activity)
                && question(at: activity)?.winner == answer
        }.count
    }

    public var assistedSoloCount: Int {
        helpUsedAt.filter { $0 > Self.guidedTotal && $0 <= firstAnswers.count }.count
    }

    public var retryRight: Int {
        zip(missedActivities, retryAnswers).filter { activity, answer in
            question(at: activity)?.winner == answer
        }.count
    }

    public var retryCount: Int { missedActivities.count }
    public var retryNumber: Int { min(Self.answerTotal, max(0, retryIndex)) + 1 }
    public var guidedNumber: Int { min(Self.guidedTotal, max(1, activityIndex)) }
    public var soloNumber: Int { min(Self.answerTotal, max(Self.guidedTotal + 1, activityIndex)) - Self.guidedTotal }
    public var completedActivities: Int {
        guard activityIndex > 0 else { return 0 }
        return min(Self.activityTotal, firstAnswers.count + 1)
    }

    public var bestFirstRight: Int? {
        guard phase == .finished else { return previousBestFirstRight }
        return max(previousBestFirstRight ?? 0, firstRight)
    }

    public var passed: Bool { firstAnswers.count == Self.answerTotal && firstRight >= 6 }

    public var isValid: Bool {
        guard contentVersion == PairLessonContentV1.version,
              (0...Self.activityTotal).contains(activityIndex),
              (0...Self.answerTotal).contains(retryIndex),
              schedule.count == Self.activityTotal,
              firstAnswers.count <= Self.answerTotal,
              retryAnswers.count <= Self.answerTotal,
              helpUsedAt.count <= Self.answerTotal,
              helpUsedAt.allSatisfy({ $0 >= 1 && $0 <= min(Self.answerTotal, activityIndex) }),
              zip(helpUsedAt, helpUsedAt.dropFirst()).allSatisfy({ first, second in first < second }),
              hasValidReplayHistory,
              schedule == PairLessonContentV1.schedule(seed: seed, excluding: Set(excludedSoloIDs ?? []))
        else { return false }

        switch phase {
        case .example:
            return firstAnswers.isEmpty && retryIndex == 0 && retryAnswers.isEmpty
                && selection == nil && !hintVisible
        case .guided, .solo:
            guard (activityIndex - 1...activityIndex).contains(firstAnswers.count),
                  retryIndex == 0, retryAnswers.isEmpty,
                  !hintVisible || currentHelpUsed
            else { return false }
        case .retry, .finished:
            guard firstAnswers.count == Self.answerTotal, !hintVisible else { return false }
            if phase == .finished {
                return retryIndex == retryCount && retryAnswers.count == retryCount && selection == nil
            }
            guard (retryIndex...retryIndex + 1).contains(retryAnswers.count) else { return false }
        }
        if let submittedAnswer {
            return submittedAnswer == selection && !hintVisible
        }
        return true
    }

    @discardableResult
    public mutating func apply(_ action: PairLessonAction) -> Bool {
        guard isValid else { return false }
        let phase = self.phase
        let isQuestion = phase == .guided || phase == .solo || phase == .retry
        switch action {
        case let .select(side):
            guard isQuestion, !revealed, selection != side else { return false }
            selection = side
        case .hint:
            guard (phase == .guided || phase == .solo), !revealed else { return false }
            if !currentHelpUsed { helpUsedAt.append(activityIndex) }
            hintVisible.toggle()
        case .submit:
            guard isQuestion, !revealed, let selection else { return false }
            if phase == .retry {
                retryAnswers.append(selection)
            } else {
                firstAnswers.append(selection)
            }
            hintVisible = false
        case .advance:
            guard phase == .example || revealed else { return false }
            if phase == .retry {
                retryIndex += 1
            } else {
                activityIndex += 1
            }
            selection = nil
            hintVisible = false
        }
        return true
    }

    @discardableResult
    public mutating func restart(seed: UInt64) -> Bool {
        guard isValid, phase == .finished else { return false }
        self = PairLessonProgress(seed: seed, exampleAlreadySeen: false,
                                  excludedSoloIDs: schedule.suffix(Self.soloTotal).map(\.id),
                                  previousBest: bestFirstRight)
        return true
    }

    private var hasValidReplayHistory: Bool {
        switch (excludedSoloIDs, previousBestFirstRight) {
        case (nil, nil):
            return true
        case let (.some(ids), .some(best)):
            return ids.count == Self.soloTotal && (0...Self.soloTotal).contains(best)
                && PairLessonContentV1.isValidExclusion(Set(ids))
        default:
            return false
        }
    }

    private var submittedAnswer: PairLessonSide? {
        switch phase {
        case .guided, .solo:
            return firstAnswers.indices.contains(activityIndex - 1) ? firstAnswers[activityIndex - 1] : nil
        case .retry:
            return retryAnswers.indices.contains(retryIndex) ? retryAnswers[retryIndex] : nil
        case .example, .finished:
            return nil
        }
    }

    private var missedActivities: [Int] {
        firstAnswers.enumerated().compactMap { index, answer in
            let activity = index + 1
            guard let question = question(at: activity), question.winner != answer else { return nil }
            return activity
        }
    }

    private func question(at index: Int) -> PairLessonQuestion? {
        guard contentVersion == PairLessonContentV1.version, schedule.indices.contains(index) else { return nil }
        return PairLessonContentV1.question(for: schedule[index])
    }
}

struct PairLessonCardTokens: Codable, Equatable, Sendable {
    let id: String
    let board: String
    let learner: String
    let opponent: String

    init(_ id: String, _ board: String, _ learner: String, _ opponent: String) {
        self.id = id
        self.board = board
        self.learner = learner
        self.opponent = opponent
    }

    func question() -> PairLessonQuestion {
        guard let board = Card.parse(board), board.count == 5,
              let learner = Card.parse(learner), learner.count == 2,
              let opponent = Card.parse(opponent), opponent.count == 2,
              Set(board + learner + opponent).count == 9
        else { preconditionFailure("Invalid B2 cards: \(id)") }

        let player = bestHand(board + learner)
        let rival = bestHand(board + opponent)
        precondition(player.category == 1 && rival.category == 1 && player.topRank != rival.topRank,
                     "B2 must compare two different one-pair ranks: \(id)")
        precondition(learner.allSatisfy { $0.rank == player.topRank }
                     && opponent.allSatisfy { $0.rank == rival.topRank },
                     "B2 uses pocket pairs so the deciding cards are always in the players' hands: \(id)")
        let winner: PairLessonSide = compareHands(hero: board + learner, villain: board + opponent) == 0
            ? .learner : .opponent
        return PairLessonQuestion(id: id, board: board, learner: learner, opponent: opponent, winner: winner)
    }
}

private enum PairLessonContentV1 {
    static let version = 1

    // Saved sessions use these exact tokens and the seeded ordering below.
    private static let opening = [
        PairLessonCardTokens("example", "2c4d7s9hQc", "KhKd", "JcJs"),
        PairLessonCardTokens("guided-1", "2d5c7h9sKd", "8h8s", "JhJc"),
        PairLessonCardTokens("guided-2", "3h5s8cTcQd", "9s9d", "6c6h"),
    ]
    private static let solo = [
        PairLessonCardTokens("solo-01", "2h5d7cTsQs", "6d6s", "JdJc"),
        PairLessonCardTokens("solo-02", "2c4s8hJcAs", "5h5d", "ThTd"),
        PairLessonCardTokens("solo-03", "2s4c7dThKc", "QhQs", "9d9c"),
        PairLessonCardTokens("solo-04", "2d4h7sTcAc", "8c8s", "6d6h"),
        PairLessonCardTokens("solo-05", "2h5d8sJcKc", "TsTd", "7d7h"),
        PairLessonCardTokens("solo-06", "3c5s8dThQc", "6c6s", "KhKd"),
        PairLessonCardTokens("solo-07", "2s6d8hJdQc", "3c3h", "9c9s"),
        PairLessonCardTokens("solo-08", "2d4s7cTsQh", "AdAh", "KdKs"),
        PairLessonCardTokens("solo-09", "2c4s6h9dJh", "KcKs", "5d5s"),
        PairLessonCardTokens("solo-10", "3s6d8cThKs", "4h4s", "QhQc"),
        PairLessonCardTokens("solo-11", "2h5c7dTsQh", "JcJs", "4c4d"),
        PairLessonCardTokens("solo-12", "3c5h8sJdKc", "2c2s", "9h9d"),
        PairLessonCardTokens("solo-13", "2s4d6c9hQs", "TdTc", "7s7h"),
        PairLessonCardTokens("solo-14", "3d5s7cThAh", "6h6s", "QsQd"),
        PairLessonCardTokens("solo-15", "2d5c8sTdKh", "AhAd", "7h7s"),
        PairLessonCardTokens("solo-16", "3h5d8sJsQd", "TcTh", "KcKd"),
        PairLessonCardTokens("solo-17", "2s5d7hJcKh", "QcQd", "8s8h"),
        PairLessonCardTokens("solo-18", "3h6d8sTcAh", "5d5c", "QdQs"),
        PairLessonCardTokens("solo-19", "4d6s9hJcKs", "QdQs", "5c5h"),
        PairLessonCardTokens("solo-20", "3d5c8sJdKh", "4h4c", "9c9s"),
        PairLessonCardTokens("solo-21", "2h5s7cTdAh", "KcKd", "9d9h"),
        PairLessonCardTokens("solo-22", "4s6h8cJdQh", "7c7s", "TcTh"),
        PairLessonCardTokens("solo-23", "3c6s9hTdQc", "AcAd", "7d7h"),
        PairLessonCardTokens("solo-24", "2d4h8cJdKs", "5c5s", "QhQs"),
    ]
    private static let catalog = Dictionary(
        uniqueKeysWithValues: (opening + solo).map { ($0.id, (tokens: $0, question: $0.question())) }
    )

    private static let learnerWins = solo.filter { question(for: $0)?.winner == .learner }
    private static let opponentWins = solo.filter { question(for: $0)?.winner == .opponent }

    static func question(for tokens: PairLessonCardTokens) -> PairLessonQuestion? {
        guard let entry = catalog[tokens.id], entry.tokens == tokens else { return nil }
        return entry.question
    }

    static func isValidExclusion(_ ids: Set<String>) -> Bool {
        ids.count == 8 && learnerWins.filter { ids.contains($0.id) }.count == 4
            && opponentWins.filter { ids.contains($0.id) }.count == 4
    }

    static func schedule(seed: UInt64, excluding ids: Set<String>) -> [PairLessonCardTokens] {
        var rng = SplitMix64(seed: seed)
        let eligibleLearnerWins = learnerWins.filter { !ids.contains($0.id) }
        let eligibleOpponentWins = opponentWins.filter { !ids.contains($0.id) }
        let selected = shuffled(eligibleLearnerWins, using: &rng).prefix(4)
            + shuffled(eligibleOpponentWins, using: &rng).prefix(4)
        var ordered: [PairLessonCardTokens]
        var winners: [PairLessonSide]
        repeat {
            ordered = shuffled(Array(selected), using: &rng)
            winners = ordered.compactMap { question(for: $0)?.winner }
        } while !zip(winners, winners.dropFirst()).contains(where: { first, second in first == second })
            || (0...4).contains(where: { Set(winners[$0..<$0 + 4]).count == 1 })
        return opening + ordered
    }

    private static func shuffled<T>(_ values: [T], using rng: inout SplitMix64) -> [T] {
        var result = values
        for index in result.indices.dropFirst().reversed() {
            let swap = Int(rng.next() % UInt64(index + 1))
            result.swapAt(index, swap)
        }
        return result
    }
}
