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

/// One graded answer. `interval` is nil for exact concepts, `evLoss` for everything not
/// graded by what the decision cost (decisions.md §D).
///
/// Both are Optionals, so a store written before either existed decodes unchanged —
/// synthesised `Decodable` uses `decodeIfPresent` for Optional properties — and
/// `schemaVersion` does not move.
public struct AnswerRecord: Codable, Equatable, Sendable {
    public var concept: String
    public var at: Date
    public var correct: Bool
    public var interval: IntervalAnswer?
    /// Big blinds given up against the best available option. Never negative.
    public var evLoss: Double?

    public init(concept: Concept, at: Date, correct: Bool,
                interval: IntervalAnswer? = nil, evLoss: Double? = nil) {
        self.concept = concept.rawValue; self.at = at
        self.correct = correct; self.interval = interval; self.evLoss = evLoss
    }
}

/// Everything the app persists, as one value type. Schema 2 keeps durable summaries
/// alongside the bounded answer log, so older history is never inferred from a ring.
public struct ProgressState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2
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
    /// `nil` means this file predates the hands-on introduction. It stays optional so
    /// existing schema-1 backups decode without a migration; historical activity is
    /// handled by the app and also suppresses the introduction.
    public var firstLessonCompleted: Bool?
    /// The ungraded Hold'em basics lesson. `nil` means not finished yet, which is also
    /// how every file written before the lesson existed reads.
    public var basicsLessonCompleted: Bool?
    /// Monotonic for each local snapshot. Reset/import changes the model epoch too.
    public var revision: Int
    public var detailedTrackingStartedAt: Date?
    public var introducedConcepts: Set<String>
    public var placement: PlacementState?
    public var activeRound: PracticeRound?
    public var activeNodeSession: NodeSessionSnapshot?
    public var activeReviewSession: ReviewSessionSnapshot?
    public var dailySummaries: [DailyPracticeSummary]
    public var recentEvidence: [PracticeEvidence]
    public var tableState: PracticeTableState?
    public var recentHands: [PracticeHandObservation]
    public var processedAttemptIDs: Set<String>

    public init(schemaVersion: Int = ProgressState.currentSchemaVersion,
                concepts: [String: ConceptRecord] = [:],
                nodes: [String: NodeRecord] = [:],
                streak: StreakRecord = StreakRecord(),
                answers: [AnswerRecord] = [],
                firstLessonCompleted: Bool? = nil, revision: Int = 0,
                detailedTrackingStartedAt: Date? = nil,
                introducedConcepts: Set<String> = [], placement: PlacementState? = nil,
                activeRound: PracticeRound? = nil,
                activeNodeSession: NodeSessionSnapshot? = nil,
                activeReviewSession: ReviewSessionSnapshot? = nil,
                dailySummaries: [DailyPracticeSummary] = [],
                recentEvidence: [PracticeEvidence] = [],
                tableState: PracticeTableState? = nil,
                recentHands: [PracticeHandObservation] = [],
                processedAttemptIDs: Set<String> = [],
                basicsLessonCompleted: Bool? = nil) {
        self.schemaVersion = schemaVersion; self.concepts = concepts
        self.nodes = nodes; self.streak = streak; self.answers = answers
        self.firstLessonCompleted = firstLessonCompleted
        self.revision = revision
        self.detailedTrackingStartedAt = detailedTrackingStartedAt
        self.introducedConcepts = introducedConcepts
        self.placement = placement; self.activeRound = activeRound
        self.activeNodeSession = activeNodeSession
        self.activeReviewSession = activeReviewSession
        self.dailySummaries = dailySummaries; self.recentEvidence = recentEvidence
        self.tableState = tableState; self.recentHands = recentHands
        self.processedAttemptIDs = processedAttemptIDs
        self.basicsLessonCompleted = basicsLessonCompleted
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, concepts, nodes, streak, answers, firstLessonCompleted
        case revision, detailedTrackingStartedAt, introducedConcepts, placement
        case activeRound, activeNodeSession, activeReviewSession, dailySummaries, recentEvidence,
             tableState, recentHands
        case processedAttemptIDs, basicsLessonCompleted
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        concepts = try c.decode([String: ConceptRecord].self, forKey: .concepts)
        nodes = try c.decode([String: NodeRecord].self, forKey: .nodes)
        streak = try c.decode(StreakRecord.self, forKey: .streak)
        answers = try c.decode([AnswerRecord].self, forKey: .answers)
        firstLessonCompleted = try c.decodeIfPresent(Bool.self, forKey: .firstLessonCompleted)
        revision = try c.decodeIfPresent(Int.self, forKey: .revision) ?? 0
        detailedTrackingStartedAt = try c.decodeIfPresent(Date.self,
                                                           forKey: .detailedTrackingStartedAt)
        introducedConcepts = try c.decodeIfPresent(Set<String>.self,
                                                   forKey: .introducedConcepts) ?? []
        placement = try c.decodeIfPresent(PlacementState.self, forKey: .placement)
        activeRound = try c.decodeIfPresent(PracticeRound.self, forKey: .activeRound)
        activeNodeSession = try c.decodeIfPresent(NodeSessionSnapshot.self,
                                                  forKey: .activeNodeSession)
        activeReviewSession = try c.decodeIfPresent(ReviewSessionSnapshot.self,
                                                    forKey: .activeReviewSession)
        dailySummaries = try c.decodeIfPresent([DailyPracticeSummary].self,
                                              forKey: .dailySummaries) ?? []
        recentEvidence = try c.decodeIfPresent([PracticeEvidence].self,
                                               forKey: .recentEvidence) ?? []
        tableState = try c.decodeIfPresent(PracticeTableState.self, forKey: .tableState)
        recentHands = try c.decodeIfPresent([PracticeHandObservation].self,
                                            forKey: .recentHands) ?? []
        processedAttemptIDs = try c.decodeIfPresent(Set<String>.self,
                                                    forKey: .processedAttemptIDs) ?? []
        basicsLessonCompleted = try c.decodeIfPresent(Bool.self, forKey: .basicsLessonCompleted)
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
