// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// Where a saved question sequence stands between questions.
public enum GradedStep: Equatable, Sendable { case question, reveal, finished }

/// A saved sequence of graded questions answered one at a time: a lesson, a review
/// session or a single-skill round. The rules for drafts, answers and moving on are
/// written once here, so the three kinds cannot drift apart.
public protocol GradedSession {
    var id: String { get }
    var ordinal: Int { get set }
    var draft: SavedDrillDraft? { get set }
    var helpOrdinal: Int? { get set }
    var formatVersion: Int { get }
    /// nil while a lesson is still teaching, before its first question.
    var step: GradedStep? { get set }
    var questionTotal: Int { get }
    func concept(at ordinal: Int) -> Concept?
    func contains(attemptID: String) -> Bool
    mutating func append(_ answer: RoundAnswer, concept: Concept)
}

/// The outcome of asking a session to take a command.
public enum GradedSessionChange: Equatable, Sendable {
    /// The command does not fit the session's state.
    case refused
    /// The same command was already applied; repeating it changes nothing.
    case alreadyApplied
    case apply
}

extension GradedSession {
    /// The draft to keep for the open question, or nil when `ordinal` is not open or
    /// the input does not fit its concept.
    public func draft(for ordinal: Int, input: SavedDrillDraftInput) -> SavedDrillDraft? {
        guard self.ordinal == ordinal, step == .question,
              let concept = concept(at: ordinal), input.isValid(for: concept) else { return nil }
        return SavedDrillDraft(ordinal: ordinal, concept: concept.rawValue, input: input)
    }

    /// Whether an answer with this attempt may be recorded for `ordinal`.
    public func acceptsAnswer(attemptID: String, ordinal: Int) -> GradedSessionChange {
        if contains(attemptID: attemptID) { return .alreadyApplied }
        guard step == .question, self.ordinal == ordinal, concept(at: ordinal) != nil else { return .refused }
        return .apply
    }

    /// Help opened on this question keeps the answer assisted, even after a relaunch.
    public func isAssisted(_ assisted: Bool, ordinal: Int) -> Bool {
        assisted || helpOrdinal == ordinal
    }

    /// Keeps the answer and shows its reveal.
    public mutating func reveal(_ answer: RoundAnswer, concept: Concept) {
        append(answer, concept: concept)
        step = .reveal
        draft = nil
    }

    /// Whether the learner may move on from the reveal of `ordinal`.
    public func acceptsNext(afterOrdinal ordinal: Int) -> GradedSessionChange {
        if self.ordinal > ordinal || step == .finished { return .alreadyApplied }
        guard self.ordinal == ordinal, step == .reveal else { return .refused }
        return .apply
    }

    /// Moves from the reveal to the next question, or finishes after the last one.
    public mutating func moveOn() {
        if ordinal + 1 == questionTotal { step = .finished }
        else { ordinal += 1; step = .question }
        draft = nil
        helpOrdinal = nil
    }
}

extension ProgressState {
    /// Records one answer in the concept's schedule and in daily practice. An answer
    /// given with help counts as practice and leaves the schedule alone.
    public mutating func recordGradedAnswer(concept: Concept, band: GradeBand, mode: String,
                                            formatVersion: Int, language: String, assisted: Bool,
                                            attemptID: String, interval: IntervalAnswer?, evLoss: Double?,
                                            eligibleSeconds: Double?, now: Date, scheduler: FSRSScheduler) {
        if assisted {
            ReviewQueue.recordAssistedPractice(&self, concept: concept, now: now)
        } else {
            ReviewQueue.recordReview(&self, concept: concept, rating: .forBand(band), interval: interval,
                                     now: now, scheduler: scheduler, evLoss: evLoss)
        }
        let key = DailyPracticeKey(day: DayKey(now), concept: concept.rawValue, mode: mode,
                                   formatVersion: formatVersion, language: language, assisted: assisted)
        // Only an unassisted, exact answer can show how quickly a skill is recalled.
        let seconds = !assisted && band == .spotOn && (evLoss == nil || evLoss == 0) ? eligibleSeconds : nil
        recordDetailedAttempt(PracticeEvidence(attemptID: attemptID, key: key, at: now, band: band,
                                               eligibleCorrectSeconds: seconds, decisionLossBB: evLoss))
    }
}

extension PracticeRound: GradedSession {
    public var step: GradedStep? {
        get {
            switch phase {
            case .question: .question
            case .reveal: .reveal
            case .finished: .finished
            }
        }
        set {
            switch newValue {
            case .question?: phase = .question
            case .reveal?: phase = .reveal
            case .finished?: phase = .finished
            case nil: break
            }
        }
    }
    public var questionTotal: Int { questionCount }
    public func concept(at ordinal: Int) -> Concept? { Concept(rawValue: concept) }
    public func contains(attemptID: String) -> Bool { answers.contains { $0.attemptID == attemptID } }
    public mutating func append(_ answer: RoundAnswer, concept: Concept) { answers.append(answer) }
}

extension ReviewSessionSnapshot: GradedSession {
    public var step: GradedStep? {
        get {
            switch phase {
            case .question: .question
            case .reveal: .reveal
            case .finished: .finished
            }
        }
        set {
            switch newValue {
            case .question?: phase = .question
            case .reveal?: phase = .reveal
            case .finished?: phase = .finished
            case nil: break
            }
        }
    }
    public var questionTotal: Int { scheduledConcepts.count }
    public func concept(at ordinal: Int) -> Concept? {
        scheduledConcepts.indices.contains(ordinal) ? Concept(rawValue: scheduledConcepts[ordinal]) : nil
    }
    public func contains(attemptID: String) -> Bool { answers.contains { $0.answer.attemptID == attemptID } }
    public mutating func append(_ answer: RoundAnswer, concept: Concept) {
        answers.append(NodeGradedAnswer(concept: concept.rawValue, answer: answer))
    }
}

extension NodeSessionSnapshot: GradedSession {
    public var step: GradedStep? {
        get {
            switch phase {
            case .question: .question
            case .reveal: .reveal
            case .finished: .finished
            case .show, .together: nil
            }
        }
        set {
            switch newValue {
            case .question?: phase = .question
            case .reveal?: phase = .reveal
            case .finished?: phase = .finished
            case nil: break
            }
        }
    }
    public var questionTotal: Int { scheduledConcepts.count }
    public func concept(at ordinal: Int) -> Concept? {
        scheduledConcepts.indices.contains(ordinal) ? Concept(rawValue: scheduledConcepts[ordinal]) : nil
    }
    public func contains(attemptID: String) -> Bool { answers.contains { $0.answer.attemptID == attemptID } }
    public mutating func append(_ answer: RoundAnswer, concept: Concept) {
        answers.append(NodeGradedAnswer(concept: concept.rawValue, answer: answer))
    }
}
