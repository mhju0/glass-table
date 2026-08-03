// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// FSRS memory state for one concept (spec §4.5). Shapes only — the scheduler that
/// advances these lives in sub-project 2.
public struct ReviewState: Codable, Equatable, Sendable {
    public var stability: Double     // days
    public var difficulty: Double    // 1...10, FSRS scale
    public var lastReview: Date?
    public var due: Date?
    public var reps: Int
    public var lapses: Int

    public init(stability: Double = 0, difficulty: Double = 5, lastReview: Date? = nil,
                due: Date? = nil, reps: Int = 0, lapses: Int = 0) {
        self.stability = stability; self.difficulty = difficulty
        self.lastReview = lastReview; self.due = due
        self.reps = reps; self.lapses = lapses
    }
}

/// Per-concept mastery and scheduling (spec §4.3, §4.5, §4.6).
public struct ConceptRecord: Codable, Equatable, Sendable {
    public var tier: MasteryTier
    public var review: ReviewState
    public var correct: Int
    public var total: Int
    /// Drives the 3-miss 천천히 offer and the 8-miss stop-drilling rule (spec §4.6).
    public var consecutiveMisses: Int
    /// When 능숙 was reached — the 12h 숙달 cooldown counts from here (spec §4.3).
    public var proficientAt: Date?
    public var masteredAt: Date?

    public init(tier: MasteryTier = .attempted, review: ReviewState = ReviewState(),
                correct: Int = 0, total: Int = 0, consecutiveMisses: Int = 0,
                proficientAt: Date? = nil, masteredAt: Date? = nil) {
        self.tier = tier; self.review = review
        self.correct = correct; self.total = total
        self.consecutiveMisses = consecutiveMisses
        self.proficientAt = proficientAt; self.masteredAt = masteredAt
    }

    public var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}

/// Per-node completion. Unlock state is *derived* from the curriculum plus these
/// flags rather than stored, so there is no second source of truth to drift.
public struct NodeRecord: Codable, Equatable, Sendable {
    public var cleared: Bool
    public var clearedAt: Date?
    public var attempts: Int

    public init(cleared: Bool = false, clearedAt: Date? = nil, attempts: Int = 0) {
        self.cleared = cleared; self.clearedAt = clearedAt; self.attempts = attempts
    }
}

/// Spec §7.1: a streak day is "a session including at least one due item", and
/// forgiveness is silent — two auto-equipped freezes with a 48h earn-back.
public struct StreakRecord: Codable, Equatable, Sendable {
    public var current: Int
    public var longest: Int
    public var lastSessionDay: DayKey?
    public var freezesRemaining: Int
    public var lastFreezeEarnedDay: DayKey?

    public static let maxFreezes = 2

    public init(current: Int = 0, longest: Int = 0, lastSessionDay: DayKey? = nil,
                freezesRemaining: Int = StreakRecord.maxFreezes,
                lastFreezeEarnedDay: DayKey? = nil) {
        self.current = current; self.longest = longest
        self.lastSessionDay = lastSessionDay
        self.freezesRemaining = freezesRemaining
        self.lastFreezeEarnedDay = lastFreezeEarnedDay
    }
}

/// A point estimate plus its stated 90% interval, and the truth it was scored against
/// (spec §5.4). Kept alongside the answer so calibration can be recomputed if the
/// scoring rule is ever retuned.
public struct IntervalAnswer: Codable, Equatable, Sendable {
    public var point: Double
    public var lo: Double
    public var hi: Double
    public var truth: Double

    public init(point: Double, lo: Double, hi: Double, truth: Double) {
        self.point = point; self.lo = lo; self.hi = hi; self.truth = truth
    }

    public var containsTruth: Bool { truth >= lo && truth <= hi }
}

/// One graded answer. `interval` is nil for exact concepts.
public struct AnswerRecord: Codable, Equatable, Sendable {
    public var concept: String
    public var at: Date
    public var correct: Bool
    public var interval: IntervalAnswer?

    public init(concept: Concept, at: Date, correct: Bool, interval: IntervalAnswer? = nil) {
        self.concept = concept.rawValue; self.at = at
        self.correct = correct; self.interval = interval
    }
}

/// Everything the app persists, as one value type (spec §8.1). Roughly 50 KB at full
/// size, so it is loaded whole and kept in memory; no query here needs an index.
public struct ProgressState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    /// Ring-buffer cap for the answer log. Bounded on purpose — an unbounded history
    /// is the one thing that would make a single-file store the wrong choice.
    public static let answerLogCap = 500

    public var schemaVersion: Int
    /// Keyed by `Concept.rawValue` rather than by `Concept` so a concept retired in a
    /// later version can't make the whole store fail to decode.
    public var concepts: [String: ConceptRecord]
    public var nodes: [String: NodeRecord]
    public var streak: StreakRecord
    public var answers: [AnswerRecord]

    public init(schemaVersion: Int = ProgressState.currentSchemaVersion,
                concepts: [String: ConceptRecord] = [:],
                nodes: [String: NodeRecord] = [:],
                streak: StreakRecord = StreakRecord(),
                answers: [AnswerRecord] = []) {
        self.schemaVersion = schemaVersion; self.concepts = concepts
        self.nodes = nodes; self.streak = streak; self.answers = answers
    }

    public func record(for concept: Concept) -> ConceptRecord {
        concepts[concept.rawValue] ?? ConceptRecord()
    }

    public mutating func updateRecord(for concept: Concept,
                                      _ mutate: (inout ConceptRecord) -> Void) {
        var r = record(for: concept)
        mutate(&r)
        concepts[concept.rawValue] = r
    }

    /// Appends and trims from the front, so the log always holds the newest
    /// `answerLogCap` answers in chronological order.
    public mutating func append(_ answer: AnswerRecord) {
        answers.append(answer)
        if answers.count > Self.answerLogCap {
            answers.removeFirst(answers.count - Self.answerLogCap)
        }
    }
}
