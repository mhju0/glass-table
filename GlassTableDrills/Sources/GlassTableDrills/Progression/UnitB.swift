// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum UnitBLesson: String, CaseIterable, Codable, Identifiable, Sendable {
    case pairBeatsHighCard = "b1"
    case pairComparison = "b2"
    case twoPair = "b3"
    case threeOfAKind = "b4"
    case straight = "b5"
    case flush = "b6"
    case fullHouse = "b7"
    case fourOfAKind = "b8"
    case straightFlush = "b9"
    case bestFive = "b10"
    case kickers = "b11"
    case boardPlays = "b12"
    case checkpoint = "b13"

    public var id: String { rawValue }

    public func title(in language: LearningLanguage) -> String {
        switch self {
        case .pairBeatsHighCard: language.text("원 페어와 하이 카드", "A pair beats high card")
        case .pairComparison: language.text("원 페어 비교하기", "Compare one-pair hands")
        case .twoPair: language.text("투 페어 찾기", "Find two pair")
        case .threeOfAKind: language.text("트리플 찾기", "Find three of a kind")
        case .straight: language.text("스트레이트 찾기", "Find a straight")
        case .flush: language.text("플러시 찾기", "Find a flush")
        case .fullHouse: language.text("풀하우스 찾기", "Find a full house")
        case .fourOfAKind: language.text("포카드 찾기", "Find four of a kind")
        case .straightFlush: language.text("스트레이트 플러시", "Find a straight flush")
        case .bestFive: language.text("가장 좋은 다섯 장 고르기", "Pick the best five")
        case .kickers: language.text("같은 족보 비교하기", "Compare the same hand type")
        case .boardPlays: language.text("공용 카드로 비길 때", "When the board plays")
        case .checkpoint: language.text("승부 가리기 복습", "Decide who wins")
        }
    }

    fileprivate var index: Int { Self.allCases.firstIndex(of: self)! }
}

public enum UnitBPhase: Equatable, Sendable {
    case lesson, pairLesson, retry, results, finished
}

public enum UnitBAction: Equatable, Sendable {
    case select(Int)
    /// Card position in the learner's two cards followed by the five board cards.
    case toggleCard(Int)
    case submit
    case advance
    /// Accepts a completed score from the existing one-pair lesson.
    case completePairLesson(bestFirstRight: Int)
}

public struct UnitBLessonResult: Codable, Equatable, Sendable {
    public let lesson: UnitBLesson
    public let firstRight: Int
    public let questionCount: Int
    public let retryRight: Int
    public let retryCount: Int
}

private enum UnitBAnswer: Codable, Equatable, Sendable {
    case choice(Int)
    case cards([Int])

    func isValid(for activity: UnitBActivity, submitted: Bool) -> Bool {
        switch self {
        case .choice(let index):
            return activity.kind == .choice && activity.choices(in: .english).indices.contains(index)
        case .cards(let indices):
            let available = activity.learner.count + activity.board.count
            return activity.kind == .bestFive
                && (submitted ? indices.count == 5 : (1...5).contains(indices.count))
                && indices == Set(indices).sorted()
                && indices.allSatisfy { (0..<available).contains($0) }
        }
    }

    func isCorrect(for activity: UnitBActivity) -> Bool {
        guard isValid(for: activity, submitted: true) else { return false }
        switch self {
        case .choice(let index):
            return index == activity.correctChoice
        case .cards(let indices):
            let available = activity.learner + activity.board
            return compareHands(hero: indices.map { available[$0] }, villain: available) == 2
        }
    }
}

/// Code and saved answers refer to the same versioned cards and option order.
public struct UnitBProgress: Codable, Equatable, Sendable {
    private static let currentContentVersion = 1
    private static let pairQuestionCount = 8
    private static let pairPassMark = PassMark.required(questions: pairQuestionCount)

    private var contentVersion = Self.currentContentVersion
    public private(set) var lesson: UnitBLesson = .pairBeatsHighCard
    private var activityIndex = 0
    private var firstAnswers: [UnitBAnswer] = []
    private var retryIndex = 0
    private var retryAnswers: [UnitBAnswer] = []
    private var draft: UnitBAnswer?
    private var finished = false
    private var priorResults: [UnitBLessonResult] = []

    public init() {}

    private var activities: [UnitBActivity] { UnitBContentV1.activities(for: lesson) }
    private var questions: [UnitBActivity] { activities.filter { $0.kind != .example } }

    private var missedActivities: [UnitBActivity] {
        zip(questions, firstAnswers).compactMap { question, answer in
            answer.isCorrect(for: question) ? nil : question
        }
    }

    public var phase: UnitBPhase {
        if finished { return .finished }
        if lesson == .pairComparison { return .pairLesson }
        if activityIndex < activities.count { return .lesson }
        if retryIndex < missedActivities.count { return .retry }
        return .results
    }

    public var activity: UnitBActivity? {
        switch phase {
        case .lesson:
            return activities.indices.contains(activityIndex) ? activities[activityIndex] : nil
        case .retry:
            let missed = missedActivities
            return missed.indices.contains(retryIndex) ? missed[retryIndex] : nil
        case .pairLesson, .results, .finished:
            return nil
        }
    }

    public var selection: Int? {
        if case let .choice(choice) = draft { return choice }
        return nil
    }

    public var selectedCardIndices: Set<Int> {
        if case let .cards(indices) = draft { return Set(indices) }
        return []
    }

    public var revealed: Bool {
        switch phase {
        case .lesson:
            guard let activity, activity.kind != .example else { return false }
            return firstAnswers.count == priorQuestionCount + 1
        case .retry:
            return retryAnswers.count == retryIndex + 1
        case .pairLesson, .results, .finished:
            return false
        }
    }

    public var canSubmit: Bool {
        guard !revealed, let draft, let activity else { return false }
        return draft.isValid(for: activity, submitted: true)
    }

    public var answeredCorrectly: Bool? {
        guard revealed, let activity, let draft else { return nil }
        return draft.isCorrect(for: activity)
    }

    public var firstRight: Int {
        zip(questions, firstAnswers).filter { question, answer in answer.isCorrect(for: question) }.count
    }

    public var questionCount: Int {
        lesson == .pairComparison ? Self.pairQuestionCount : questions.count
    }

    public var retryRight: Int {
        zip(missedActivities, retryAnswers).filter { question, answer in answer.isCorrect(for: question) }.count
    }

    public var retryCount: Int { missedActivities.count }

    public var completedLessons: Int {
        phase == .results || phase == .finished ? lesson.index + 1 : lesson.index
    }

    public var completedResults: [UnitBLessonResult] {
        phase == .results || phase == .finished ? priorResults + [currentResult] : priorResults
    }

    public var pairBestFirstRight: Int? {
        priorResults.first(where: { $0.lesson == .pairComparison })?.firstRight
    }

    private var currentResult: UnitBLessonResult {
        UnitBLessonResult(lesson: lesson, firstRight: firstRight, questionCount: questionCount,
                          retryRight: retryRight, retryCount: retryCount)
    }

    public var stepNumber: Int {
        switch phase {
        case .retry: retryIndex + 1
        case .lesson: activityIndex + 1
        case .pairLesson: 0
        case .results, .finished: activities.count
        }
    }

    public var stepCount: Int { phase == .retry ? retryCount : activities.count }

    private var priorQuestionCount: Int {
        activities.prefix(activityIndex).filter { $0.kind != .example }.count
    }

    private var priorResultsAreValid: Bool {
        let expected = UnitBLesson.allCases.prefix(lesson.index)
        guard priorResults.count == expected.count else { return false }
        return zip(priorResults, expected).allSatisfy { result, expectedLesson in
            guard result.lesson == expectedLesson else { return false }
            if expectedLesson == .pairComparison {
                // The separate lesson owns retry evidence. This summary carries its best solo score.
                return result.questionCount == Self.pairQuestionCount
                    && (Self.pairPassMark...Self.pairQuestionCount).contains(result.firstRight)
                    && result.retryCount == 0 && result.retryRight == 0
            }
            let count = UnitBContentV1.activities(for: expectedLesson).filter { $0.kind != .example }.count
            return result.questionCount == count
                && (0...count).contains(result.firstRight)
                && result.retryCount == count - result.firstRight
                && (0...result.retryCount).contains(result.retryRight)
        }
    }

    public var isValid: Bool {
        guard contentVersion == Self.currentContentVersion, priorResultsAreValid,
              !finished || lesson == .checkpoint
        else { return false }

        if lesson == .pairComparison {
            return activityIndex == 0 && firstAnswers.isEmpty
                && retryIndex == 0 && retryAnswers.isEmpty && draft == nil
        }

        guard (0...activities.count).contains(activityIndex),
              firstAnswers.count <= questions.count,
              zip(questions, firstAnswers).allSatisfy({ $1.isValid(for: $0, submitted: true) })
        else { return false }

        let missed = missedActivities
        guard (0...missed.count).contains(retryIndex), retryAnswers.count <= missed.count,
              zip(missed, retryAnswers).allSatisfy({ $1.isValid(for: $0, submitted: true) })
        else { return false }

        if activityIndex < activities.count {
            guard !finished, retryIndex == 0, retryAnswers.isEmpty else { return false }
            let current = activities[activityIndex]
            let prior = priorQuestionCount
            if current.kind == .example { return draft == nil && firstAnswers.count == prior }
            return draftMatches(activity: current, answers: firstAnswers, prior: prior)
        }

        guard firstAnswers.count == questions.count else { return false }
        if retryIndex == missed.count { return retryAnswers.count == missed.count && draft == nil }
        return !finished && draftMatches(activity: missed[retryIndex], answers: retryAnswers, prior: retryIndex)
    }

    private func draftMatches(activity: UnitBActivity, answers: [UnitBAnswer], prior: Int) -> Bool {
        if answers.count == prior {
            return draft?.isValid(for: activity, submitted: false) ?? true
        }
        return answers.count == prior + 1 && draft == answers.last
    }

    @discardableResult
    public mutating func apply(_ action: UnitBAction) -> Bool {
        guard isValid, phase != .finished else { return false }
        switch action {
        case .select(let choice):
            let answer = UnitBAnswer.choice(choice)
            guard let activity, !revealed, answer != draft,
                  answer.isValid(for: activity, submitted: false)
            else { return false }
            draft = answer
        case .toggleCard(let index):
            guard let activity, activity.kind == .bestFive, !revealed,
                  (0..<(activity.learner.count + activity.board.count)).contains(index)
            else { return false }
            var indices = selectedCardIndices
            if indices.remove(index) == nil {
                guard indices.count < 5 else { return false }
                indices.insert(index)
            }
            draft = indices.isEmpty ? nil : .cards(indices.sorted())
        case .submit:
            guard canSubmit, let draft else { return false }
            if phase == .retry { retryAnswers.append(draft) }
            else { firstAnswers.append(draft) }
        case .advance:
            switch phase {
            case .lesson:
                guard activity?.kind == .example || revealed else { return false }
                activityIndex += 1
            case .retry:
                guard revealed else { return false }
                retryIndex += 1
            case .results:
                if lesson == .checkpoint {
                    finished = true
                } else {
                    moveToNextLesson(recording: currentResult)
                }
            case .pairLesson, .finished:
                return false
            }
            draft = nil
        case .completePairLesson(let bestFirstRight):
            guard phase == .pairLesson,
                  (Self.pairPassMark...Self.pairQuestionCount).contains(bestFirstRight)
            else { return false }
            moveToNextLesson(recording: UnitBLessonResult(
                lesson: .pairComparison, firstRight: bestFirstRight, questionCount: Self.pairQuestionCount,
                retryRight: 0, retryCount: 0))
        }
        return true
    }

    private mutating func moveToNextLesson(recording result: UnitBLessonResult) {
        priorResults.append(result)
        lesson = UnitBLesson.allCases[lesson.index + 1]
        activityIndex = 0
        firstAnswers = []
        retryIndex = 0
        retryAnswers = []
    }
}
