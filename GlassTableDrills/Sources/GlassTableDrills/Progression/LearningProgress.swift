// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// Stable identifiers for summary comparisons. Language is a BCP-47 primary tag.
public struct DailyPracticeKey: Codable, Equatable, Hashable, Sendable {
    public var day: DayKey
    public var concept: String
    public var mode: String
    public var formatVersion: Int
    public var language: String
    public var assisted: Bool

    public init(day: DayKey, concept: String, mode: String, formatVersion: Int,
                language: String, assisted: Bool) {
        self.day = day; self.concept = concept; self.mode = mode
        self.formatVersion = formatVersion; self.language = language
        self.assisted = assisted
    }
}

public struct DailyPracticeSummary: Codable, Equatable, Sendable {
    public var key: DailyPracticeKey
    public var exact = 0
    public var near = 0
    public var miss = 0
    public var eligibleCorrectSeconds = 0.0
    public var eligibleCorrectCount = 0
    public var decisionLossBB = 0.0
    public var decisionLossCount = 0

    public init(key: DailyPracticeKey) { self.key = key }

    public var total: Int { exact + near + miss }
}

/// Recent detail is bounded; summaries above retain all earlier daily totals.
public struct PracticeEvidence: Codable, Equatable, Sendable {
    public var attemptID: String
    public var key: DailyPracticeKey
    public var at: Date
    public var band: String
    public var eligibleCorrectSeconds: Double?
    public var decisionLossBB: Double?

    public init(attemptID: String, key: DailyPracticeKey, at: Date, band: GradeBand,
                eligibleCorrectSeconds: Double?, decisionLossBB: Double?) {
        self.attemptID = attemptID; self.key = key; self.at = at; self.band = band.rawValue
        self.eligibleCorrectSeconds = eligibleCorrectSeconds
        self.decisionLossBB = decisionLossBB
    }
}

public struct RoundAnswer: Codable, Equatable, Sendable {
    public var attemptID: String
    public var ordinal: Int
    public var band: String
    public var submittedAt: Date
    /// The committed input and reveal payload are UI-owned, versioned JSON bytes.
    public var input: Data
    public var reveal: Data

    public init(attemptID: String, ordinal: Int, band: GradeBand, submittedAt: Date,
                input: Data, reveal: Data) {
        self.attemptID = attemptID; self.ordinal = ordinal; self.band = band.rawValue
        self.submittedAt = submittedAt; self.input = input; self.reveal = reveal
    }
}

/// A question that has not been submitted. No score or review credit is inferred
/// from it; it can be discarded if the learner explicitly changes sessions.
public enum SavedDrillDraftInput: Codable, Equatable, Sendable {
    case integerText(String)
    case integer(Int)
    case interval(point: Double, halfWidth: Double)
    case range(width: Double, tendencies: [String])
    case potReplay(stepIndex: Int)

    public func isValid(for concept: Concept) -> Bool {
        switch self {
        case let .integerText(text):
            guard text.utf8.allSatisfy({ (48...57).contains($0) }) else { return false }
            switch concept {
            case .rangeNotation:
                return text.count <= 4 && (text.isEmpty || (Int(text) ?? 1_327) <= 1_326)
            case .outs, .combos:
                return text.count <= 3 && (text.isEmpty || (Int(text) ?? 1_000) <= 999)
            default: return false
            }
        case let .integer(value):
            return SavedDrillInput.integer(value).isValid(for: concept)
        case let .interval(point, halfWidth):
            guard [.equitySense, .evCall, .hitFrequency, .rangeAdvantage,
                   .actionRead].contains(concept),
                  point.isFinite, halfWidth.isFinite else { return false }
            return concept == .evCall
                ? (-20...20).contains(point) && (0...20).contains(halfWidth)
                : (0...100).contains(point) && (0...50).contains(halfWidth)
        case let .range(width, tendencies):
            return SavedDrillInput.range(width: width, tendencies: tendencies)
                .isValid(for: concept)
        case let .potReplay(stepIndex):
            return concept == .potMath && (0...32).contains(stepIndex)
        }
    }
}

public struct SavedDrillDraft: Codable, Equatable, Sendable {
    public var ordinal: Int
    public var concept: String
    public var input: SavedDrillDraftInput
    public init(ordinal: Int, concept: String, input: SavedDrillDraftInput) {
        self.ordinal = ordinal; self.concept = concept; self.input = input
    }
}

/// The generator is deterministic from seed, concept, ordinal and format version.
/// An answered question remains in `reveal` until an explicit Next command.
public struct PracticeRound: Codable, Equatable, Sendable {
    public enum IntroPhase: String, Codable, Sendable { case show, together }
    public var id: String
    public var concept: String
    public var seed: UInt64
    public var formatVersion: Int
    public var ordinal: Int
    public var questionCount: Int
    public var answers: [RoundAnswer]
    public var phase: Phase
    public var draft: SavedDrillDraft?
    public var introPhase: IntroPhase?
    public var showBeatIndex: Int?
    public var guidedDraft: SavedDrillDraft?
    public var guidedAnswer: RoundAnswer?

    public enum Phase: String, Codable, Sendable { case question, reveal, finished }

    public init(id: String, concept: String, seed: UInt64, formatVersion: Int = 1,
                questionCount: Int = 5, introPhase: IntroPhase? = nil) {
        self.id = id; self.concept = concept; self.seed = seed
        self.formatVersion = formatVersion; self.ordinal = 0
        self.questionCount = questionCount; self.answers = []; self.phase = .question
        self.draft = nil
        self.introPhase = introPhase
        self.showBeatIndex = 0
        self.guidedDraft = nil
        self.guidedAnswer = nil
    }
}

public struct NodeGradedAnswer: Codable, Equatable, Sendable {
    public var concept: String
    public var answer: RoundAnswer

    public init(concept: String, answer: RoundAnswer) {
        self.concept = concept; self.answer = answer
    }
}

public struct NodeSessionSnapshot: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Sendable {
        case show, together, question, reveal, finished
    }

    public var id: String
    public var nodeID: String
    public var seed: UInt64
    public var formatVersion: Int
    public var scheduledConcepts: [String]
    public var ordinal: Int
    public var phase: Phase
    public var answers: [NodeGradedAnswer]
    public var draft: SavedDrillDraft?
    public var showBeatIndex: Int?
    public var guidedDraft: SavedDrillDraft?
    public var guidedAnswer: RoundAnswer?

    public init(id: String, nodeID: String, seed: UInt64,
                scheduledConcepts: [String], phase: Phase,
                formatVersion: Int = 1) {
        self.id = id; self.nodeID = nodeID; self.seed = seed
        self.formatVersion = formatVersion
        self.scheduledConcepts = scheduledConcepts
        self.ordinal = 0; self.phase = phase; self.answers = []; self.draft = nil
        self.showBeatIndex = 0; self.guidedDraft = nil; self.guidedAnswer = nil
    }
}

/// The due list is frozen at the start. A committed reveal stays visible until
/// the learner explicitly advances, even after the app restarts.
public struct ReviewSessionSnapshot: Codable, Equatable, Sendable {
    public var id: String
    public var seed: UInt64
    public var formatVersion: Int
    public var scheduledConcepts: [String]
    public var ordinal: Int
    public var phase: PracticeRound.Phase
    public var answers: [NodeGradedAnswer]
    public var draft: SavedDrillDraft?

    public init(id: String, seed: UInt64, scheduledConcepts: [String],
                formatVersion: Int = 1) {
        self.id = id; self.seed = seed; self.formatVersion = formatVersion
        self.scheduledConcepts = scheduledConcepts; self.ordinal = 0
        self.phase = .question; self.answers = []; self.draft = nil
    }
}

public enum PlacementSelfReport: String, Codable, CaseIterable, Sendable {
    case newToPoker, knowRules, playRegularly
}

/// A suggestion only: never used to clear curriculum nodes or award mastery.
public struct PlacementState: Codable, Equatable, Sendable {
    public var assessmentVersion: Int
    public var selfReport: PlacementSelfReport?
    public var answers: [String: String]
    public var recommendedConcept: String?
    public var completedAt: Date?
    public var skipped: Bool

    public init(assessmentVersion: Int = PlacementGuide.version,
                selfReport: PlacementSelfReport? = nil, answers: [String: String] = [:],
                recommendedConcept: String? = nil, completedAt: Date? = nil,
                skipped: Bool = false) {
        self.assessmentVersion = assessmentVersion
        self.selfReport = selfReport; self.answers = answers
        self.recommendedConcept = recommendedConcept
        self.completedAt = completedAt; self.skipped = skipped
    }
}

public enum PlacementGuide {
    public static let version = 1
    /// Bundled, untimed prompts. Unknown answers can be omitted without penalty.
    public static let questionIDs = ["showdown", "pot", "price"]

    public static func recommendation(report: PlacementSelfReport?,
                                      answers: [String: String]) -> Concept {
        if answers["showdown"] != "pair" { return .showdown }
        if answers["pot"] != "include-blinds" { return .potMath }
        if answers["price"] != "compare-call-to-pot" { return .potOdds }
        return report == .playRegularly ? .rangeRead : .position
    }
}

public extension ProgressState {
    mutating func appendHandObservation(_ observation: PracticeHandObservation) {
        guard !recentHands.contains(where: { $0.handID == observation.handID }) else { return }
        recentHands.append(observation)
        if recentHands.count > 200 { recentHands.removeFirst(recentHands.count - 200) }
    }

    mutating func recordDetailedAttempt(_ evidence: PracticeEvidence) {
        let key = evidence.key
        let index = dailySummaries.firstIndex { $0.key == key }
        var summary = index.map { dailySummaries[$0] } ?? DailyPracticeSummary(key: key)
        switch evidence.band {
        case GradeBand.spotOn.rawValue: summary.exact += 1
        case GradeBand.close.rawValue: summary.near += 1
        default: summary.miss += 1
        }
        if let seconds = evidence.eligibleCorrectSeconds {
            summary.eligibleCorrectSeconds += seconds
            summary.eligibleCorrectCount += 1
        }
        if let loss = evidence.decisionLossBB {
            summary.decisionLossBB += loss
            summary.decisionLossCount += 1
        }
        if let index { dailySummaries[index] = summary }
        else { dailySummaries.append(summary) }
        recentEvidence.append(evidence)
        if recentEvidence.count > 500 {
            recentEvidence.removeFirst(recentEvidence.count - 500)
        }
    }
}
