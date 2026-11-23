// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public enum CourseReviewSkill: String, CaseIterable, Codable, Identifiable, Sendable {
    case privateCards = "a1"
    case fiveCardHand = "a1-five-cards"
    case sharedBestFive = "a1-shared-five"
    case rankAndSuit = "a2"
    case cardSuit = "a2-suit"
    case suitStrength = "a2-suit-strength"
    case findPair = "a3"
    case streets = "a4"
    case endings = "a5"
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
    case highCardRanks = "b11-high-card"
    case twoPairRanks = "b11-two-pair"
    case fullHouseRanks = "b11-full-house"
    case boardPlays = "b12"

    public var id: String { rawValue }
    public var isUnitA: Bool { rawValue.hasPrefix("a") }
    public var isLessonEntry: Bool { self == lessonEntry }

    private var lessonEntry: Self {
        switch self {
        case .fiveCardHand, .sharedBestFive: .privateCards
        case .cardSuit, .suitStrength: .rankAndSuit
        case .highCardRanks, .twoPairRanks, .fullHouseRanks: .kickers
        default: self
        }
    }

    public func lessonTitle(in language: LearningLanguage) -> String {
        let lessonID = lessonEntry.rawValue
        return UnitALesson(rawValue: lessonID)?.title(in: language)
            ?? UnitBLesson(rawValue: lessonID)?.title(in: language)
            ?? lessonID
    }

    public func title(in language: LearningLanguage) -> String {
        switch self {
        case .fiveCardHand: language.text("다섯 장으로 만든 패", "Five-card hands")
        case .sharedBestFive: language.text("공용 카드 다섯 장", "Using only the board")
        case .rankAndSuit: language.text("카드의 숫자와 글자", "Card ranks")
        case .cardSuit: language.text("카드 무늬", "Card suits")
        case .suitStrength: language.text("같은 힘의 무늬", "Equal suit strength")
        case .kickers: language.text("원 페어의 키커", "Pair kickers")
        case .highCardRanks: language.text("하이 카드의 순서", "High-card order")
        case .twoPairRanks: language.text("투 페어의 순서", "Two-pair order")
        case .fullHouseRanks: language.text("풀하우스의 순서", "Full-house order")
        default: lessonTitle(in: language)
        }
    }

    fileprivate var lessonObjectives: [Self] {
        Self.allCases.filter { $0.lessonEntry == self }
    }
}

public enum CourseReviewScope: Codable, Equatable, Hashable, Sendable {
    case all
    case unitA
    case unitB
    case lesson(CourseReviewSkill)

    public func title(in language: LearningLanguage) -> String {
        switch self {
        case .all: language.text("지금까지 배운 내용 복습", "Review everything so far")
        case .unitA: language.text("A단원 복습", "Unit A review")
        case .unitB: language.text("B단원 복습", "Unit B review")
        case .lesson(let skill): skill.lessonTitle(in: language)
        }
    }

    fileprivate func contains(_ skill: CourseReviewSkill) -> Bool {
        switch self {
        case .all: true
        case .unitA: skill.isUnitA
        case .unitB: !skill.isUnitA
        case .lesson(let entry): entry.lessonObjectives.contains(skill)
        }
    }
}

public enum CourseReviewPhase: Equatable, Sendable {
    case question, retry, setResults, finished
}

public enum CourseReviewAction: Equatable, Sendable {
    case select(Int)
    /// Card position in the learner's private cards followed by the board.
    case toggleCard(Int)
    case submit
    case advance
}

public struct CourseReviewSetResult: Codable, Equatable, Sendable {
    public let firstRight: Int
    public let questionCount: Int
    public let retryRight: Int
    public let retryCount: Int
}

private struct CourseReviewItem: Codable, Equatable, Sendable {
    let skill: CourseReviewSkill
    let variant: Int

    var activity: CourseReviewActivity? {
        CourseReviewContent.activity(for: skill, variant: variant)
    }
}

private enum CourseReviewAnswer: Codable, Equatable, Sendable {
    case choice(Int)
    case cards([Int])

    func isValid(for activity: CourseReviewActivity, submitted: Bool) -> Bool {
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

    func isCorrect(for activity: CourseReviewActivity) -> Bool {
        guard isValid(for: activity, submitted: true) else { return false }
        switch self {
        case .choice(let index):
            return index == activity.correctChoice
        case .cards(let indices):
            let cards = activity.learner + activity.board
            return compareHands(hero: indices.map { cards[$0] }, villain: cards) == 2
        }
    }
}

/// Frozen optional review. First answers bind to selected variants, while corrections
/// derive their item order from the actual misses in the current set.
public struct CourseReviewSession: Codable, Equatable, Sendable {
    public static let maximumSetSize = 5
    private static let singleLessonItemCount = 3

    public let scope: CourseReviewScope
    public let seed: UInt64
    private let contentVersion: Int
    private let items: [CourseReviewItem]
    private var setIndex = 0
    private var itemIndex = 0
    private var retryIndex = 0
    private var firstAnswers: [CourseReviewAnswer] = []
    private var retryAnswers: [CourseReviewAnswer] = []
    private var priorResults: [CourseReviewSetResult] = []
    private var draft: CourseReviewAnswer?
    private var finished = false

    public static func eligibleSkills(in state: ProgressState, scope: CourseReviewScope = .all) -> [CourseReviewSkill] {
        var studied = Set(state.unitA?.completedResults.map { $0.lesson.rawValue } ?? [])
        studied.formUnion(state.unitB?.completedResults.map { $0.lesson.rawValue } ?? [])
        if let a = state.unitA,
           a.phase == .retry || (a.phase == .lesson && a.stepNumber == a.stepCount && a.revealed) {
            studied.insert(a.lesson.rawValue)
        }
        if let b = state.unitB,
           b.phase == .retry || (b.phase == .lesson && b.stepNumber == b.stepCount && b.revealed) {
            studied.insert(b.lesson.rawValue)
        }
        if let pair = state.pairLesson, pair.bestFirstRight != nil || pair.completedActivities == 11 {
            studied.insert(CourseReviewSkill.pairComparison.rawValue)
        }
        let taught = CourseReviewSkill.allCases.filter {
            $0.isLessonEntry && studied.contains($0.rawValue)
        }.flatMap(\.lessonObjectives)
        return taught.filter(scope.contains)
    }

    public static func studiedLessons(in state: ProgressState, scope: CourseReviewScope = .all) -> [CourseReviewSkill] {
        eligibleSkills(in: state, scope: scope).filter(\.isLessonEntry)
    }

    public init?(scope: CourseReviewScope, eligibleSkills: [CourseReviewSkill], seed: UInt64) {
        let eligible = Set(eligibleSkills)
        let skills = CourseReviewSkill.allCases.filter { eligible.contains($0) && scope.contains($0) }
        guard let items = Self.makeItems(scope: scope, skills: skills, seed: seed) else { return nil }
        self.scope = scope
        self.seed = seed
        contentVersion = CourseReviewContent.version
        self.items = items
    }

    private static func makeItems(scope: CourseReviewScope, skills: [CourseReviewSkill],
                                  seed: UInt64) -> [CourseReviewItem]? {
        guard !skills.isEmpty else { return nil }
        if case .lesson(let entry) = scope, skills != entry.lessonObjectives { return nil }
        var rng = SplitMix64(seed: seed)
        var items: [CourseReviewItem] = []
        for skill in scheduledSkills(scope: scope, skills: skills, rng: &rng) {
            let count = CourseReviewContent.variantCount(for: skill)
            let needed: Int
            if case .lesson = scope, skills.count == 1 {
                needed = singleLessonItemCount
            } else {
                needed = 1
            }
            guard count >= needed else { return nil }
            let first = Int(rng.next() % UInt64(count))
            for offset in 0..<needed {
                items.append(CourseReviewItem(skill: skill, variant: (first + offset) % count))
            }
        }
        return items
    }

    private static func scheduledSkills(scope: CourseReviewScope, skills: [CourseReviewSkill],
                                        rng: inout SplitMix64) -> [CourseReviewSkill] {
        switch scope {
        case .lesson:
            return skills
        case .unitA, .unitB:
            return shuffledSkills(skills, rng: &rng)
        case .all:
            var first = shuffledSkills(skills.filter(\.isUnitA), rng: &rng)
            var second = shuffledSkills(skills.filter { !$0.isUnitA }, rng: &rng)
            guard !first.isEmpty && !second.isEmpty else { return first + second }
            if rng.next() & 1 == 1 { swap(&first, &second) }

            var mixed: [CourseReviewSkill] = []
            while !first.isEmpty && !second.isEmpty {
                mixed.append(first.removeLast())
                mixed.append(second.removeLast())
            }
            mixed.append(contentsOf: first.reversed())
            mixed.append(contentsOf: second.reversed())
            return mixed
        }
    }

    private static func shuffledSkills(_ skills: [CourseReviewSkill], rng: inout SplitMix64)
        -> [CourseReviewSkill] {
        var shuffled = skills
        for index in shuffled.indices.dropFirst().reversed() {
            let other = Int(rng.next() % UInt64(index + 1))
            shuffled.swapAt(index, other)
        }
        return shuffled
    }

    public var skills: [CourseReviewSkill] {
        let enrolled = Set(items.map(\.skill))
        return CourseReviewSkill.allCases.filter(enrolled.contains)
    }

    public var itemCount: Int { items.count }
    public var setCount: Int { (itemCount + Self.maximumSetSize - 1) / Self.maximumSetSize }
    public var setNumber: Int { setItems.isEmpty ? 0 : setIndex + 1 }
    public var coveredCount: Int {
        priorResults.reduce(firstAnswers.count) { $0 + $1.questionCount }
    }

    private var setItems: ArraySlice<CourseReviewItem> {
        guard (0..<setCount).contains(setIndex) else { return [] }
        let start = setIndex * Self.maximumSetSize
        return items[start..<min(start + Self.maximumSetSize, itemCount)]
    }

    private var missedItems: [CourseReviewItem] {
        zip(setItems, firstAnswers).compactMap { item, answer in
            guard let activity = item.activity, !answer.isCorrect(for: activity) else { return nil }
            return item
        }
    }

    public var phase: CourseReviewPhase {
        if finished { return .finished }
        if itemIndex < setItems.count { return .question }
        return retryIndex < missedItems.count ? .retry : .setResults
    }

    private var currentItem: CourseReviewItem? {
        switch phase {
        case .question:
            guard (0..<setItems.count).contains(itemIndex) else { return nil }
            return setItems[setItems.startIndex + itemIndex]
        case .retry:
            let missed = missedItems
            return missed.indices.contains(retryIndex) ? missed[retryIndex] : nil
        case .setResults, .finished:
            return nil
        }
    }

    public var activity: CourseReviewActivity? { currentItem?.activity }
    public var currentSkill: CourseReviewSkill? { currentItem?.skill }
    public var selection: Int? {
        if case .choice(let index) = draft { return index }
        return nil
    }

    public var selectedCardIndices: Set<Int> {
        if case .cards(let indices) = draft { return Set(indices) }
        return []
    }

    public var revealed: Bool {
        guard currentItem != nil else { return false }
        switch phase {
        case .question: return firstAnswers.count > itemIndex
        case .retry: return retryAnswers.count > retryIndex
        case .setResults, .finished: return false
        }
    }

    public var canSubmit: Bool {
        guard !revealed, let activity, let draft else { return false }
        return draft.isValid(for: activity, submitted: true)
    }

    public var answeredCorrectly: Bool? {
        guard revealed, let activity, let draft else { return nil }
        return draft.isCorrect(for: activity)
    }

    public var stepCount: Int { phase == .retry ? retryCount : questionCount }
    public var stepNumber: Int {
        switch phase {
        case .question: return currentItem == nil ? 0 : itemIndex + 1
        case .retry: return currentItem == nil ? 0 : retryIndex + 1
        case .setResults, .finished: return questionCount
        }
    }

    public var questionCount: Int { setItems.count }
    public var firstRight: Int {
        zip(setItems, firstAnswers).filter { item, answer in
            item.activity.map { answer.isCorrect(for: $0) } ?? false
        }.count
    }
    public var retryCount: Int { missedItems.count }
    public var retryRight: Int {
        zip(missedItems, retryAnswers).filter { item, answer in
            item.activity.map { answer.isCorrect(for: $0) } ?? false
        }.count
    }

    private var currentResult: CourseReviewSetResult {
        CourseReviewSetResult(firstRight: firstRight, questionCount: questionCount,
                              retryRight: retryRight, retryCount: retryCount)
    }

    public var completedResults: [CourseReviewSetResult] {
        phase == .setResults || phase == .finished ? priorResults + [currentResult] : priorResults
    }

    public var isValid: Bool {
        guard contentVersion == CourseReviewContent.version,
              (1...CourseReviewSkill.allCases.count).contains(itemCount),
              skills.allSatisfy(scope.contains),
              items == Self.makeItems(scope: scope, skills: skills, seed: seed),
              items.allSatisfy({ $0.activity != nil }),
              (0..<setCount).contains(setIndex), priorResults.count == setIndex,
              priorResults.allSatisfy({ result in
                  result.questionCount == Self.maximumSetSize
                      && (0...result.questionCount).contains(result.firstRight)
                      && result.retryCount == result.questionCount - result.firstRight
                      && (0...result.retryCount).contains(result.retryRight)
              }),
              !finished || setIndex == setCount - 1,
              (0...setItems.count).contains(itemIndex),
              firstAnswers.count <= setItems.count,
              Self.answersAreValid(firstAnswers, for: setItems)
        else { return false }

        let missed = missedItems
        guard (0...missed.count).contains(retryIndex), retryAnswers.count <= missed.count,
              Self.answersAreValid(retryAnswers, for: missed)
        else { return false }

        if itemIndex < setItems.count {
            return !finished && retryIndex == 0 && retryAnswers.isEmpty
                && draftMatches(firstAnswers, cursor: itemIndex)
        }
        guard firstAnswers.count == setItems.count else { return false }
        if retryIndex < missed.count {
            return !finished && draftMatches(retryAnswers, cursor: retryIndex)
        }
        return retryAnswers.count == missed.count && draft == nil
    }

    public func isValid(in state: ProgressState) -> Bool {
        isValid && Set(skills).isSubset(of: Set(Self.eligibleSkills(in: state)))
    }

    private static func answersAreValid<Items: Collection>(_ answers: [CourseReviewAnswer], for items: Items)
        -> Bool where Items.Element == CourseReviewItem {
        zip(items, answers).allSatisfy { item, answer in
            item.activity.map { answer.isValid(for: $0, submitted: true) } ?? false
        }
    }

    private func draftMatches(_ answers: [CourseReviewAnswer], cursor: Int) -> Bool {
        guard let activity else { return false }
        if answers.count == cursor {
            return draft?.isValid(for: activity, submitted: false) ?? true
        }
        return answers.count == cursor + 1 && draft == answers.last
    }

    @discardableResult
    public mutating func apply(_ action: CourseReviewAction) -> Bool {
        guard isValid, phase != .finished else { return false }
        switch action {
        case .select(let index):
            let answer = CourseReviewAnswer.choice(index)
            guard !revealed, let activity, answer != draft,
                  answer.isValid(for: activity, submitted: false)
            else { return false }
            draft = answer
        case .toggleCard(let index):
            guard !revealed, let activity, activity.kind == .bestFive,
                  (0..<(activity.learner.count + activity.board.count)).contains(index)
            else { return false }
            var selected = selectedCardIndices
            if selected.remove(index) == nil {
                guard selected.count < 5 else { return false }
                selected.insert(index)
            }
            draft = selected.isEmpty ? nil : .cards(selected.sorted())
        case .submit:
            guard canSubmit, let draft else { return false }
            if phase == .retry { retryAnswers.append(draft) }
            else { firstAnswers.append(draft) }
        case .advance:
            switch phase {
            case .question:
                guard revealed else { return false }
                itemIndex += 1
            case .retry:
                guard revealed else { return false }
                retryIndex += 1
            case .setResults:
                if setIndex + 1 == setCount {
                    finished = true
                } else {
                    priorResults.append(currentResult)
                    setIndex += 1
                    itemIndex = 0
                    retryIndex = 0
                    firstAnswers = []
                    retryAnswers = []
                }
            case .finished:
                return false
            }
            draft = nil
        }
        return true
    }
}
