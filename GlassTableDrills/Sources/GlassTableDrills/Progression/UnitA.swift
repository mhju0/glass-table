// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum UnitALesson: String, CaseIterable, Codable, Identifiable, Sendable {
    case privateCards = "a1"
    case rankAndSuit = "a2"
    case findPair = "a3"
    case streets = "a4"
    case endings = "a5"

    public var id: String { rawValue }

    public func title(in language: LearningLanguage) -> String {
        switch self {
        case .privateCards: language.text("내 카드와 공용 카드", "Your cards and shared cards")
        case .rankAndSuit: language.text("숫자와 무늬", "Rank and suit")
        case .findPair: language.text("페어 찾기", "Find a pair")
        case .streets: language.text("프리플랍부터 리버까지", "From preflop to river")
        case .endings: language.text("핸드가 끝나는 두 가지 방법", "Two ways a hand ends")
        }
    }

    fileprivate var index: Int { Self.allCases.firstIndex(of: self)! }
}

public enum UnitAPhase: Equatable, Sendable {
    case lesson, retry, results, finished
}

public enum UnitAAction: Equatable, Sendable {
    case select(Int), submit, advance
}

public struct UnitACardGroup: Equatable, Sendable {
    public enum Role: Hashable, Sendable {
        case mine, shared, opponent, example
    }

    public let role: Role
    public let cards: [Card]
    public let highlighted: [Card]

    public func title(in language: LearningLanguage) -> String {
        switch role {
        case .mine: language.text("내 카드", "My cards")
        case .shared: language.text("공용 카드", "Shared cards")
        case .opponent: language.text("상대 카드", "Opponent's cards")
        case .example: language.text("살펴볼 카드", "Example cards")
        }
    }
}

struct UnitACopy: Equatable, Sendable {
    let korean: String
    let english: String

    init(_ korean: String, _ english: String) {
        self.korean = korean
        self.english = english
    }

    func text(in language: LearningLanguage) -> String { language.text(korean, english) }
}

public struct UnitAActivity: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case example, question, branch }

    public let id: String
    public let kind: Kind
    public let cards: [UnitACardGroup]
    let heading: UnitACopy
    let detail: UnitACopy
    let choices: [UnitACopy]
    let rightIndex: Int?
    let responses: [UnitACopy]
    let revealGroups: [[UnitACardGroup]]

    public func title(in language: LearningLanguage) -> String { heading.text(in: language) }
    public func body(in language: LearningLanguage) -> String { detail.text(in: language) }
    public func options(in language: LearningLanguage) -> [String] { choices.map { $0.text(in: language) } }

    public func feedback(in language: LearningLanguage, for selection: Int) -> String {
        guard choices.indices.contains(selection) else { return "" }
        let response = responses.count == 1 ? responses[0] : responses[selection]
        return response.text(in: language)
    }

    public func feedbackCards(for selection: Int) -> [UnitACardGroup] {
        guard choices.indices.contains(selection) else { return cards }
        if revealGroups.count == 1 { return revealGroups[0] }
        return revealGroups.indices.contains(selection) ? revealGroups[selection] : cards
    }
}

public struct UnitALessonResult: Codable, Equatable, Sendable {
    public let lesson: UnitALesson
    public let firstRight: Int
    public let questionCount: Int
    public let retryRight: Int
    public let retryCount: Int
}

/// One ordered unit with a versioned catalogue. The saved position and answer refer
/// to the same authored cards and choice order after a close, language change or relaunch.
public struct UnitAProgress: Codable, Equatable, Sendable {
    private var contentVersion = UnitAContentV1.version
    public private(set) var lesson: UnitALesson = .privateCards
    private var activityIndex = 0
    private var firstAnswers: [Int] = []
    private var retryIndex = 0
    private var retryAnswers: [Int] = []
    public private(set) var selection: Int?
    private var finished = false
    private var priorResults: [UnitALessonResult]?

    public init() {}

    private var activities: [UnitAActivity] { UnitAContentV1.activities(for: lesson) }
    private var choiceActivities: [UnitAActivity] { activities.filter { $0.kind != .example } }
    private var missedActivities: [UnitAActivity] {
        zip(choiceActivities, firstAnswers).compactMap { activity, answer in
            guard let right = activity.rightIndex, answer != right else { return nil }
            return activity
        }
    }

    public var phase: UnitAPhase {
        if finished { return .finished }
        if activityIndex < activities.count { return .lesson }
        if retryIndex < missedActivities.count { return .retry }
        return .results
    }

    public var activity: UnitAActivity? {
        switch phase {
        case .lesson:
            return activities.indices.contains(activityIndex) ? activities[activityIndex] : nil
        case .retry:
            let missed = missedActivities
            return missed.indices.contains(retryIndex) ? missed[retryIndex] : nil
        case .results, .finished:
            return nil
        }
    }

    public var revealed: Bool {
        switch phase {
        case .lesson:
            guard let activity, activity.kind != .example else { return false }
            return firstAnswers.count == priorChoiceCount + 1
        case .retry: return retryAnswers.count == retryIndex + 1
        case .results, .finished: return false
        }
    }

    public var answeredCorrectly: Bool? {
        guard revealed, let right = activity?.rightIndex else { return nil }
        return selection == right
    }

    public var firstRight: Int {
        zip(choiceActivities, firstAnswers).filter { activity, answer in activity.rightIndex == answer }.count
    }

    public var questionCount: Int { choiceActivities.filter { $0.kind == .question }.count }
    public var retryRight: Int { zip(missedActivities, retryAnswers).filter { activity, answer in activity.rightIndex == answer }.count }
    public var retryCount: Int { missedActivities.count }

    public var completedLessons: Int {
        switch phase {
        case .lesson, .retry: lesson.index
        case .results, .finished: lesson.index + 1
        }
    }

    public var completedResults: [UnitALessonResult] {
        let prior = priorResults ?? []
        switch phase {
        case .lesson, .retry: return prior
        case .results, .finished: return prior + [currentResult]
        }
    }

    private var currentResult: UnitALessonResult {
        UnitALessonResult(lesson: lesson, firstRight: firstRight, questionCount: questionCount,
                          retryRight: retryRight, retryCount: retryCount)
    }

    public var stepNumber: Int {
        switch phase {
        case .retry: retryIndex + 1
        case .lesson: activityIndex + 1
        case .results, .finished: activities.count
        }
    }

    public var stepCount: Int { phase == .retry ? retryCount : activities.count }

    private var priorChoiceCount: Int {
        activities.prefix(activityIndex).filter { $0.kind != .example }.count
    }

    private var priorResultsAreValid: Bool {
        let prior = priorResults ?? []
        let expected = UnitALesson.allCases.prefix(lesson.index)
        guard prior.count == expected.count else { return false }
        return zip(prior, expected).allSatisfy { result, lesson in
            let count = UnitAContentV1.activities(for: lesson).filter { $0.kind == .question }.count
            return result.lesson == lesson && result.questionCount == count
                && (0...count).contains(result.firstRight)
                && result.retryCount == count - result.firstRight
                && (0...result.retryCount).contains(result.retryRight)
        }
    }

    public var isValid: Bool {
        guard contentVersion == UnitAContentV1.version, priorResultsAreValid,
              (0...activities.count).contains(activityIndex),
              firstAnswers.count <= choiceActivities.count,
              zip(choiceActivities, firstAnswers).allSatisfy({ $0.choices.indices.contains($1) })
        else { return false }

        let missed = missedActivities
        guard (0...missed.count).contains(retryIndex), retryAnswers.count <= missed.count,
              zip(missed, retryAnswers).allSatisfy({ $0.choices.indices.contains($1) }),
              !finished || lesson == .endings
        else { return false }

        if activityIndex < activities.count {
            guard !finished, retryIndex == 0, retryAnswers.isEmpty, let activity else { return false }
            let choicesBefore = priorChoiceCount
            if activity.kind == .example { return selection == nil && firstAnswers.count == choicesBefore }
            guard (choicesBefore...choicesBefore + 1).contains(firstAnswers.count),
                  selection.map(activity.choices.indices.contains) ?? true
            else { return false }
            return firstAnswers.count == choicesBefore || selection == firstAnswers.last
        }

        guard firstAnswers.count == choiceActivities.count else { return false }
        if retryIndex == missed.count { return retryAnswers.count == missed.count && selection == nil }

        guard !finished, (retryIndex...retryIndex + 1).contains(retryAnswers.count),
              selection.map(missed[retryIndex].choices.indices.contains) ?? true
        else { return false }
        return retryAnswers.count == retryIndex || selection == retryAnswers.last
    }

    @discardableResult
    public mutating func apply(_ action: UnitAAction) -> Bool {
        guard isValid, phase != .finished else { return false }
        switch action {
        case let .select(choice):
            guard let activity, activity.choices.indices.contains(choice),
                  !revealed, selection != choice
            else { return false }
            selection = choice
        case .submit:
            guard let selection, !revealed else { return false }
            if phase == .retry { retryAnswers.append(selection) }
            else { firstAnswers.append(selection) }
        case .advance:
            switch phase {
            case .lesson:
                guard activity?.kind == .example || revealed else { return false }
                activityIndex += 1
            case .retry:
                guard revealed else { return false }
                retryIndex += 1
            case .results:
                if lesson == .endings {
                    finished = true
                } else {
                    priorResults = completedResults
                    lesson = UnitALesson.allCases[lesson.index + 1]
                    activityIndex = 0
                    firstAnswers = []
                    retryIndex = 0
                    retryAnswers = []
                }
            case .finished:
                return false
            }
            selection = nil
        }
        return true
    }
}
