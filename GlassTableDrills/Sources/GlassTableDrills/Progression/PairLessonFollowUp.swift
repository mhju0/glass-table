// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

public enum PairLessonFollowUpKind: String, Codable, Equatable, Identifiable, Sendable {
    case fresh, review

    public var id: Self { self }
}

public struct PairLessonFollowUpAttempt: Codable, Equatable, Sendable {
    private let deal: PairLessonCardTokens
    public let question: PairLessonQuestion
    public private(set) var selection: PairLessonSide?
    public private(set) var revealed = false
    public private(set) var finished = false

    public var correct: Bool? {
        revealed ? selection == question.winner : nil
    }

    fileprivate init(deal: PairLessonCardTokens) {
        self.deal = deal
        question = deal.question()
    }

    fileprivate mutating func apply(_ action: PairLessonAction) -> Bool {
        guard !finished else { return false }
        switch action {
        case let .select(side):
            guard !revealed, selection != side else { return false }
            selection = side
        case .submit:
            guard !revealed, selection != nil else { return false }
            revealed = true
        case .advance:
            guard revealed else { return false }
            finished = true
        case .hint:
            return false
        }
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case deal, selection, revealed, finished
    }

    public init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        let deal = try fields.decode(PairLessonCardTokens.self, forKey: .deal)
        guard PairLessonFollowUpContentV1.contains(deal) else {
            throw DecodingError.dataCorruptedError(forKey: .deal, in: fields,
                                                    debugDescription: "Unknown one-pair follow-up deal")
        }
        self.init(deal: deal)
        selection = try fields.decodeIfPresent(PairLessonSide.self, forKey: .selection)
        revealed = try fields.decode(Bool.self, forKey: .revealed)
        finished = try fields.decode(Bool.self, forKey: .finished)
        guard (!revealed || selection != nil), (!finished || revealed) else {
            throw DecodingError.dataCorruptedError(forKey: .selection, in: fields,
                                                    debugDescription: "Invalid one-pair follow-up answer")
        }
    }
}

/// Extra retrieval attempts hold their own answer evidence and never grade the base lesson.
public struct PairLessonFollowUpProgress: Codable, Equatable, Sendable {
    private let contentVersion: Int
    private let completionDay: DayKey
    public let reviewDueDay: DayKey
    private var fresh: PairLessonFollowUpAttempt?
    private var review: PairLessonFollowUpAttempt

    private init(completionDay: DayKey, reviewDueDay: DayKey,
                 fresh: PairLessonFollowUpAttempt?, review: PairLessonFollowUpAttempt) {
        contentVersion = PairLessonFollowUpContentV1.version
        self.completionDay = completionDay
        self.reviewDueDay = reviewDueDay
        self.fresh = fresh
        self.review = review
    }

    public var isValid: Bool {
        contentVersion == PairLessonFollowUpContentV1.version
            && completionDay.daysBetween(reviewDueDay, calendar: Self.utcCalendar) == 1
            && PairLessonFollowUpContentV1.contains(id: review.question.id, for: .review)
            && (fresh.map { PairLessonFollowUpContentV1.contains(id: $0.question.id, for: .fresh) } ?? true)
    }

    public func attempt(for kind: PairLessonFollowUpKind) -> PairLessonFollowUpAttempt? {
        switch kind {
        case .fresh: fresh
        case .review: review
        }
    }

    public func isAvailable(_ kind: PairLessonFollowUpKind, on today: DayKey) -> Bool {
        guard isValid, let attempt = attempt(for: kind), !attempt.finished else { return false }
        // A persisted draft is already underway, even if travel moves the local day back.
        return kind == .fresh || attempt.selection != nil || today >= reviewDueDay
    }

    public static func localDay(at date: Date, calendar: Calendar = .current) -> DayKey {
        DayKey(date, calendar: gregorian(in: calendar.timeZone))
    }

    public static func recordingCompletion(of lesson: PairLessonProgress, previous: Self?,
                                           at date: Date, calendar: Calendar = .current) -> Self {
        precondition(lesson.phase == .finished && lesson.isValid, "Only a completed one-pair lesson can be reviewed")
        var rng = SplitMix64(seed: lesson.seed)
        var fresh = previous?.fresh
        if lesson.assistedSoloCount > 0, fresh?.finished != false {
            fresh = PairLessonFollowUpContentV1.attempt(for: .fresh, seed: rng.next(),
                                                       avoiding: fresh?.question.id)
        }
        if var previous, !previous.review.finished {
            previous.fresh = fresh
            return previous
        }

        let local = gregorian(in: calendar.timeZone)
        let components = local.dateComponents([.year, .month, .day], from: date)
        let utc = utcCalendar
        // Add to the civil date in UTC, where every Gregorian date exists.
        guard let civilDate = utc.date(from: components),
              let tomorrow = utc.date(byAdding: .day, value: 1, to: civilDate) else {
            preconditionFailure("Could not schedule the next one-pair review day")
        }
        let review = PairLessonFollowUpContentV1.attempt(for: .review, seed: rng.next(),
                                                       avoiding: previous?.review.question.id)
        return Self(completionDay: DayKey(civilDate, calendar: utc),
                    reviewDueDay: DayKey(tomorrow, calendar: utc), fresh: fresh, review: review)
    }

    @discardableResult
    public mutating func apply(_ action: PairLessonAction, to kind: PairLessonFollowUpKind,
                               today: DayKey) -> Bool {
        guard isAvailable(kind, on: today) else { return false }
        switch kind {
        case .fresh: return fresh?.apply(action) ?? false
        case .review: return review.apply(action)
        }
    }

    private static var utcCalendar: Calendar {
        gregorian(in: TimeZone(secondsFromGMT: 0)!)
    }

    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}

private enum PairLessonFollowUpContentV1 {
    static let version = 1

    // These are held out from the lesson itself. Saved attempts pin the exact cards.
    static let fresh = [
        PairLessonCardTokens("fresh-01", "2s5c8dJhQs", "4h4c", "9h9d"),
        PairLessonCardTokens("fresh-02", "4d6h8cTsKc", "JdJs", "7s7d"),
        PairLessonCardTokens("fresh-03", "2h4d7sJcAc", "6d6s", "QhQd"),
        PairLessonCardTokens("fresh-04", "2c5s8hTdAh", "KcKd", "7s7c"),
    ]
    static let review = [
        PairLessonCardTokens("review-01", "3c6s9dJhAd", "8h8s", "4c4h"),
        PairLessonCardTokens("review-02", "2d5c8sQhKd", "7h7s", "JcJd"),
        PairLessonCardTokens("review-03", "3h5s8dTcAs", "KcKh", "6d6c"),
        PairLessonCardTokens("review-04", "4s6d8cThQs", "9s9c", "JdJh"),
    ]

    static func contains(_ deal: PairLessonCardTokens) -> Bool {
        fresh.contains(deal) || review.contains(deal)
    }

    static func contains(id: String, for kind: PairLessonFollowUpKind) -> Bool {
        deals(for: kind).contains { $0.id == id }
    }

    static func attempt(for kind: PairLessonFollowUpKind, seed: UInt64,
                        avoiding priorID: String?) -> PairLessonFollowUpAttempt {
        let options = deals(for: kind).filter { $0.id != priorID }
        return PairLessonFollowUpAttempt(deal: options[Int(seed % UInt64(options.count))])
    }

    private static func deals(for kind: PairLessonFollowUpKind) -> [PairLessonCardTokens] {
        switch kind {
        case .fresh: fresh
        case .review: review
        }
    }
}
