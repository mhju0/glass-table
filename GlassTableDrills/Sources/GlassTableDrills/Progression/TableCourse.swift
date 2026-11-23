// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum TableCourseUnit: String, CaseIterable, Codable, Identifiable, Sendable {
    case turns
    case chips
    case milestone
    case startingHands
    case possibleHands
    case winningCards
    case priceChance
    case capstone
    case combinations

    /// Keep the lesson path order independent of the optional guided hand and electives.
    public static let corePath: [Self] = [
        .turns, .chips, .startingHands, .possibleHands, .winningCards, .priceChance, .capstone,
    ]

    var minimumSchemaVersion: Int {
        switch self {
        case .turns, .chips, .milestone, .startingHands: 11
        case .possibleHands, .winningCards, .priceChance, .capstone, .combinations: 12
        }
    }

    public var id: String { rawValue }

    public var lessons: [TableCourseLesson] {
        TableCourseLesson.allCases.filter { $0.unit == self }
    }

    public func title(in language: LearningLanguage) -> String {
        switch self {
        case .turns: language.text("차례와 행동", "Turns and legal moves")
        case .chips: language.text("칩 세기", "Count chips")
        case .milestone: language.text("한 판 따라가기", "Follow a practice hand")
        case .startingHands: language.text("시작 핸드", "Choose starting hands")
        case .possibleHands: language.text("상대의 가능한 핸드", "Read possible hands")
        case .winningCards: language.text("이기는 카드", "Count ways to win")
        case .priceChance: language.text("가격과 확률", "Compare price and chance")
        case .capstone: language.text("한 판에 적용하기", "Put it together")
        case .combinations: language.text("콤보와 레인지", "Combinations and ranges")
        }
    }

    public func activities(for lesson: TableCourseLesson) -> [TableCourseActivity] {
        guard lesson.unit == self else { return [] }
        switch self {
        case .turns: return Self.turnsActivities[lesson, default: []]
        case .chips: return Self.chipActivities[lesson, default: []]
        case .milestone: return ChipUnitContent.milestone
        case .startingHands: return Self.startingHandActivities[lesson, default: []]
        case .possibleHands: return Self.possibleHandActivities[lesson, default: []]
        case .winningCards: return Self.winningCardActivities[lesson, default: []]
        case .priceChance: return Self.priceChanceActivities[lesson, default: []]
        case .capstone: return Self.capstoneActivities[lesson, default: []]
        case .combinations: return Self.combinationActivities[lesson, default: []]
        }
    }

    private static let turnsActivities = TableCourseUnit.turns.catalog(using: BettingUnitContent.activities(for:))
    private static let chipActivities = TableCourseUnit.chips.catalog(using: ChipUnitContent.activities(for:))
    private static let startingHandActivities =
        TableCourseUnit.startingHands.catalog(using: StartingHandUnitContent.activities(for:))

    private static let possibleHandActivities =
        TableCourseUnit.possibleHands.catalog(using: PossibleHandsUnitContent.activities(for:))
    private static let winningCardActivities =
        TableCourseUnit.winningCards.catalog(using: WinningCardsUnitContent.activities(for:))
    private static let priceChanceActivities =
        TableCourseUnit.priceChance.catalog(using: PriceChanceUnitContent.activities(for:))
    private static let capstoneActivities =
        TableCourseUnit.capstone.catalog(using: CapstoneUnitContent.activities(for:))
    private static let combinationActivities =
        TableCourseUnit.combinations.catalog(using: CombinationUnitContent.activities(for:))

    private func catalog(using content: (TableCourseLesson) -> [TableCourseActivity])
        -> [TableCourseLesson: [TableCourseActivity]] {
        Dictionary(uniqueKeysWithValues: lessons.map { ($0, content($0)) })
    }
}

public enum TableCourseLesson: String, CaseIterable, Codable, Identifiable, Sendable {
    case c1, c2, c3, c4, c5, c6, c7, c8, c9
    case d1, d2, d3, d4, d5, d6
    case tableMilestone = "d-table"
    case e1, e2, e3, e4, e5, e6, e7
    case f1, f2, f3, f4, f5, f6
    case g1, g2, g3, g4, g5, g6, g7
    case h1, h2, h3, h4, h5, h6, h7
    case i1, i2, i3, i4, i5, i6
    case j1, j2, j3, j4, j5

    public var id: String { rawValue }

    public var unit: TableCourseUnit {
        switch self {
        case .c1, .c2, .c3, .c4, .c5, .c6, .c7, .c8, .c9: .turns
        case .d1, .d2, .d3, .d4, .d5, .d6: .chips
        case .tableMilestone: .milestone
        case .e1, .e2, .e3, .e4, .e5, .e6, .e7: .startingHands
        case .f1, .f2, .f3, .f4, .f5, .f6: .possibleHands
        case .g1, .g2, .g3, .g4, .g5, .g6, .g7: .winningCards
        case .h1, .h2, .h3, .h4, .h5, .h6, .h7: .priceChance
        case .i1, .i2, .i3, .i4, .i5, .i6: .capstone
        case .j1, .j2, .j3, .j4, .j5: .combinations
        }
    }

    public func title(in language: LearningLanguage) -> String {
        switch self {
        case .c1: language.text("딜러 버튼과 블라인드", "Button and blinds")
        case .c2: language.text("플랍 전 첫 차례", "First to act before the flop")
        case .c3: language.text("플랍 이후 첫 차례", "First to act after the flop")
        case .c4: language.text("체크 또는 베팅", "Check or bet")
        case .c5: language.text("콜, 폴드 또는 레이즈", "Call, fold, or raise")
        case .c6: language.text("최소 베팅과 레이즈", "Minimum bets and raises")
        case .c7: language.text("차례에 따라 아는 것", "First and last to act")
        case .c8: language.text("두 명일 때의 딜러 버튼", "The button heads-up")
        case .c9: language.text("다음 차례와 다음 카드", "Next turn or next card")
        case .d1: language.text("스택과 팟", "The stack and the pot")
        case .d2: language.text("낸 칩은 한 번씩만", "Count each contribution once")
        case .d3: language.text("차이만큼 더 내기", "Add the difference")
        case .d4: language.text("폴드해도 팟에 남는 칩", "Folded chips stay in the pot")
        case .d5: language.text("콜에 필요한 칩", "Find the call amount")
        case .d6: language.text("한 판의 팟 따라가기", "Follow a pot across streets")
        case .tableMilestone: language.text("연습 핸드 한 판", "One guided practice hand")
        case .e1: language.text("페어, 수티드, 오프수트", "Pair, suited, or offsuit")
        case .e2: language.text("레인지란 무엇일까?", "What a range means")
        case .e3: language.text("차트에서 한 칸 읽기", "Read one chart cell")
        case .e4: language.text("처음으로 참여하기", "Enter first")
        case .e5: language.text("자리가 바뀌면 차트도 바뀌어요", "Change seats, change the chart")
        case .e6: language.text("레이즈를 마주했을 때", "Someone already raised")
        case .e7: language.text("맞는 차트 고르기", "Choose the right chart")
        case .f1: language.text("보이는 카드와 추측", "Known cards and guesses")
        case .f2: language.text("불가능한 조합 빼기", "Rule out impossible hands")
        case .f3: language.text("완성된 패와 드로우", "Made hands and draws")
        case .f4: language.text("공용 카드 읽기", "Read the board")
        case .f5: language.text("상대의 행동 규칙", "Use an opponent’s rule")
        case .f6: language.text("가능한 설명 비교하기", "Compare possible hands")
        case .g1: language.text("이기는 리버 카드", "Find winning river cards")
        case .g2: language.text("좋아져도 질 수 있어요", "Improving can still lose")
        case .g3: language.text("카드는 한 번씩", "Count each card once")
        case .g4: language.text("무승부와 팟 나누기", "Ties split the pot")
        case .g5: language.text("남은 카드 중 몇 장?", "How many cards are left?")
        case .g6: language.text("레인지와 승산", "Equity against a range")
        case .g7: language.text("리버 카드 종합 연습", "One card left")
        case .h1: language.text("콜 가격", "Find the call price")
        case .h2: language.text("콜한 뒤의 팟", "Pot after calling")
        case .h3: language.text("본전에 필요한 몫", "Find the break-even share")
        case .h4: language.text("확률과 가격 비교", "Compare chance to price")
        case .h5: language.text("같은 카드, 다른 가격", "Same cards, different price")
        case .h6: language.text("같은 가격, 다른 확률", "Same price, different chance")
        case .h7: language.text("콜할까요, 폴드할까요?", "Call or fold?")
        case .i1: language.text("첫 참여 결정하기", "Decide whether to open")
        case .i2: language.text("처음 나온 레이즈에 대응", "Respond to the first raise")
        case .i3: language.text("플랍에서 다시 보기", "Read a new flop")
        case .i4: language.text("리버에서 가격 판단", "Decide at the river price")
        case .i5: language.text("쇼다운 설명하기", "Explain a showdown")
        case .i6: language.text("한 판 끝까지", "Play a whole hand")
        case .j1: language.text("시작 핸드별 콤보", "Count starting-hand combos")
        case .j2: language.text("보이는 카드 빼기", "Remove visible cards")
        case .j3: language.text("레인지의 콤보 세기", "Count a written range")
        case .j4: language.text("가중치가 있는 레인지", "Compare weighted ranges")
        case .j5: language.text("빠지거나 더한 콤보", "Find a missing or extra combo")
        }
    }

    fileprivate var indexInUnit: Int {
        // Every case declares exactly one unit, and that unit lists it.
        unit.lessons.firstIndex(of: self)!
    }
}

public struct TableCourseText: Equatable, Sendable {
    private let korean: String
    private let english: String

    public init(_ korean: String, _ english: String) {
        self.korean = korean
        self.english = english
    }

    public func text(in language: LearningLanguage) -> String {
        language.text(korean, english)
    }
}

public struct TableCourseSeat: Equatable, Sendable {
    public let label: TableCourseText
    public let detail: TableCourseText?
    public let chips: Int?
    public let folded: Bool
    public let highlighted: Bool

    public init(_ label: TableCourseText, detail: TableCourseText? = nil,
                chips: Int? = nil, folded: Bool = false, highlighted: Bool = false) {
        self.label = label
        self.detail = detail
        self.chips = chips
        self.folded = folded
        self.highlighted = highlighted
    }
}

public struct TableCourseRow: Equatable, Sendable {
    public let label: TableCourseText
    public let value: TableCourseText

    public init(_ label: TableCourseText, _ value: TableCourseText) {
        self.label = label
        self.value = value
    }
}

public struct TableCourseChartCell: Equatable, Sendable {
    public let label: String
    public let active: Bool
    public let secondary: Bool
    public let highlighted: Bool

    public init(_ label: String, active: Bool = false, secondary: Bool = false, highlighted: Bool = false) {
        self.label = label
        self.active = active
        self.secondary = secondary
        self.highlighted = highlighted
    }
}

public struct TableCourseChart: Equatable, Sendable {
    public let title: TableCourseText
    public let rows: [[TableCourseChartCell]]
    public let activeLabel: TableCourseText?
    public let secondaryLabel: TableCourseText?
    public let inactiveLabel: TableCourseText?

    public init(title: TableCourseText, rows: [[TableCourseChartCell]], activeLabel: TableCourseText? = nil,
                secondaryLabel: TableCourseText? = nil, inactiveLabel: TableCourseText? = nil) {
        self.title = title
        self.rows = rows
        self.activeLabel = activeLabel
        self.secondaryLabel = secondaryLabel
        self.inactiveLabel = inactiveLabel
    }
}

public struct TableCourseEvidence: Equatable, Sendable {
    /// Seats are in clockwise order.
    public let seats: [TableCourseSeat]
    public let cards: [Card]
    public let board: [Card]
    public let opponent: [Card]
    public let rows: [TableCourseRow]
    public let chart: TableCourseChart?

    public init(seats: [TableCourseSeat] = [], cards: [Card] = [], board: [Card] = [],
                opponent: [Card] = [], rows: [TableCourseRow] = [], chart: TableCourseChart? = nil) {
        self.seats = seats
        self.cards = cards
        self.board = board
        self.opponent = opponent
        self.rows = rows
        self.chart = chart
    }
}

public struct TableCourseActivity: Identifiable, Equatable, Sendable {
    public let id: String
    public let evidence: TableCourseEvidence
    public let correctChoice: Int?
    public let revealedEvidence: TableCourseEvidence?
    private let activityTitle: TableCourseText
    private let activityPrompt: TableCourseText?
    private let options: [TableCourseText]
    private let answerExplanation: TableCourseText?

    public init(id: String, title: TableCourseText, prompt: TableCourseText? = nil,
                evidence: TableCourseEvidence = .init(), choices: [TableCourseText] = [],
                correctChoice: Int? = nil, explanation: TableCourseText? = nil,
                revealedEvidence: TableCourseEvidence? = nil) {
        self.id = id
        self.activityTitle = title
        self.activityPrompt = prompt
        self.evidence = evidence
        self.options = choices
        self.correctChoice = correctChoice
        self.answerExplanation = explanation
        self.revealedEvidence = revealedEvidence
    }

    public var isExample: Bool { correctChoice == nil }
    public var optionCount: Int { options.count }

    public func title(in language: LearningLanguage) -> String { activityTitle.text(in: language) }
    public func prompt(in language: LearningLanguage) -> String? { activityPrompt?.text(in: language) }
    public func choices(in language: LearningLanguage) -> [String] { options.map { $0.text(in: language) } }
    public func explanation(in language: LearningLanguage) -> String? { answerExplanation?.text(in: language) }

    fileprivate func acceptsChoice(_ index: Int) -> Bool {
        !isExample && options.indices.contains(index)
    }
}

public enum TableCoursePhase: Equatable, Sendable {
    case lesson, retry, results, finished
}

public enum TableCourseAction: Equatable, Sendable {
    case select(Int), submit, advance
}

public struct TableCourseLessonResult: Codable, Equatable, Sendable {
    public let lesson: TableCourseLesson
    public let firstRight: Int
    public let questionCount: Int
    public let retryRight: Int
    public let retryCount: Int
}

/// Saved indices refer to the authored activity and option order for this version.
/// Staged examples and retries use the same cursor contract as ordinary questions.
public struct TableCourseProgress: Codable, Equatable, Sendable {
    private static let currentContentVersion = 1

    private let contentVersion: Int
    public let unit: TableCourseUnit
    public private(set) var lesson: TableCourseLesson
    private var activityIndex = 0
    private var firstAnswers: [Int] = []
    private var retryIndex = 0
    private var retryAnswers: [Int] = []
    public private(set) var selection: Int?
    private var finished = false
    private var priorResults: [TableCourseLessonResult] = []

    public init(unit: TableCourseUnit) {
        contentVersion = Self.currentContentVersion
        self.unit = unit
        lesson = unit.lessons[0]
    }

    private var activities: [TableCourseActivity] { unit.activities(for: lesson) }
    private var questions: [TableCourseActivity] { activities.filter { !$0.isExample } }
    private var missedActivities: [TableCourseActivity] {
        zip(questions, firstAnswers).compactMap { activity, answer in
            activity.correctChoice == answer ? nil : activity
        }
    }

    public var phase: TableCoursePhase {
        if finished { return .finished }
        if activityIndex < activities.count { return .lesson }
        if retryIndex < missedActivities.count { return .retry }
        return .results
    }

    public var activity: TableCourseActivity? {
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

    private var priorQuestionCount: Int {
        activities.prefix(activityIndex).filter { !$0.isExample }.count
    }

    public var revealed: Bool {
        guard let activity, !activity.isExample else { return false }
        switch phase {
        case .lesson: return firstAnswers.count == priorQuestionCount + 1
        case .retry: return retryAnswers.count == retryIndex + 1
        case .results, .finished: return false
        }
    }

    public var canSubmit: Bool {
        guard !revealed, let activity, let selection else { return false }
        return activity.acceptsChoice(selection)
    }

    public var answeredCorrectly: Bool? {
        guard revealed, let selection else { return nil }
        return selection == activity?.correctChoice
    }

    public var questionCount: Int { questions.count }
    public var hasAnsweredLessonQuestions: Bool {
        questionCount > 0 && firstAnswers.count == questionCount
    }
    public var firstRight: Int {
        zip(questions, firstAnswers).filter { $0.correctChoice == $1 }.count
    }
    public var retryCount: Int { missedActivities.count }
    public var retryRight: Int {
        zip(missedActivities, retryAnswers).filter { $0.correctChoice == $1 }.count
    }

    private var currentResult: TableCourseLessonResult {
        TableCourseLessonResult(lesson: lesson, firstRight: firstRight, questionCount: questionCount,
                                retryRight: retryRight, retryCount: retryCount)
    }

    public var completedResults: [TableCourseLessonResult] {
        switch phase {
        case .results, .finished: priorResults + [currentResult]
        case .lesson, .retry: priorResults
        }
    }

    public var completedLessons: Int { completedResults.count }
    public var stepCount: Int { phase == .retry ? retryCount : activities.count }
    public var stepNumber: Int {
        switch phase {
        case .lesson: activityIndex + 1
        case .retry: retryIndex + 1
        case .results, .finished: activities.count
        }
    }

    public var isValid: Bool {
        guard contentVersion == Self.currentContentVersion,
              lesson.unit == unit,
              !finished || lesson == unit.lessons.last,
              priorResultsAreValid,
              !questions.isEmpty,
              (0...activities.count).contains(activityIndex),
              firstAnswers.count <= questions.count,
              zip(questions, firstAnswers).allSatisfy({ $0.acceptsChoice($1) })
        else { return false }

        let missed = missedActivities
        guard (0...missed.count).contains(retryIndex),
              retryAnswers.count <= missed.count,
              zip(missed, retryAnswers).allSatisfy({ $0.acceptsChoice($1) })
        else { return false }

        if activityIndex < activities.count {
            guard !finished, retryIndex == 0, retryAnswers.isEmpty else { return false }
            let current = activities[activityIndex]
            let prior = priorQuestionCount
            if current.isExample { return selection == nil && firstAnswers.count == prior }
            return draftMatches(activity: current, answers: firstAnswers, prior: prior)
        }

        guard hasAnsweredLessonQuestions else { return false }
        if retryIndex == missed.count { return retryAnswers.count == missed.count && selection == nil }
        return !finished && draftMatches(activity: missed[retryIndex], answers: retryAnswers, prior: retryIndex)
    }

    private var priorResultsAreValid: Bool {
        let expected = unit.lessons.prefix(lesson.indexInUnit)
        guard priorResults.count == expected.count else { return false }
        return zip(priorResults, expected).allSatisfy { result, expectedLesson in
            let count = unit.activities(for: expectedLesson).filter { !$0.isExample }.count
            return result.lesson == expectedLesson
                && result.questionCount == count
                && (0...count).contains(result.firstRight)
                && result.retryCount == count - result.firstRight
                && (0...result.retryCount).contains(result.retryRight)
        }
    }

    private func draftMatches(activity: TableCourseActivity, answers: [Int], prior: Int) -> Bool {
        if answers.count == prior {
            return selection.map { activity.acceptsChoice($0) } ?? true
        }
        return answers.count == prior + 1 && selection == answers.last
    }

    @discardableResult
    public mutating func apply(_ action: TableCourseAction) -> Bool {
        guard isValid, phase != .finished else { return false }
        switch action {
        case .select(let choice):
            guard let activity, !revealed, selection != choice, activity.acceptsChoice(choice) else { return false }
            selection = choice
        case .submit:
            guard canSubmit, let selection else { return false }
            if phase == .retry { retryAnswers.append(selection) }
            else { firstAnswers.append(selection) }
        case .advance:
            switch phase {
            case .lesson:
                guard activity?.isExample == true || revealed else { return false }
                activityIndex += 1
            case .retry:
                guard revealed else { return false }
                retryIndex += 1
            case .results:
                if lesson == unit.lessons.last {
                    finished = true
                } else {
                    moveToNextLesson()
                }
            case .finished:
                return false
            }
            selection = nil
        }
        return true
    }

    private mutating func moveToNextLesson() {
        priorResults.append(currentResult)
        lesson = unit.lessons[lesson.indexInUnit + 1]
        activityIndex = 0
        firstAnswers = []
        retryIndex = 0
        retryAnswers = []
    }
}
