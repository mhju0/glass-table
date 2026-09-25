// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Tier promotion and answer recording (spec §4.3, §4.6).
///
/// Promotion is one-way: a bad session lowers accuracy but never takes back a tier
/// the user earned. Demotion would make the top tier feel like a leaderboard
/// position rather than a thing they learned, and the review scheduler is already
/// the mechanism that brings a decayed concept back around.
public enum Mastery {
    /// Accuracy needed to leave 시도 for 익숙.
    public static let familiarThreshold = 0.7
    /// Spec §4.3 — 숙달 waits at least this long after 능숙, which is spacing
    /// enforcement disguised as a cooldown.
    public static let masteryCooldown: TimeInterval = 12 * 3600
    /// Spec §4.6.
    public static let missesBeforeWalkthroughOffer = 3
    public static let missesBeforeStopDrilling = 8

    /// Promotion uses only this concept's answers from the completed session. The
    /// lifetime aggregate still includes `.close` answers for the familiar tier and
    /// scheduling, but a proficiency claim requires every current answer to be spot-on.
    public static func promote(_ r: inout ConceptRecord, evidence: SessionEvidence,
                               viaBoss: Bool, now: Date) {
        guard evidence.isComplete else { return }
        let wasProficient = r.tier >= .proficient
        var earned: MasteryTier = r.accuracy >= familiarThreshold ? .familiar : .attempted

        if evidence.isPerfect, earned >= .familiar { earned = .proficient }

        if viaBoss, evidence.isPerfect, wasProficient,
           let since = r.proficientAt,
           now.timeIntervalSince(since) >= masteryCooldown {
            earned = .mastered
        }

        guard earned > r.tier else { return }   // never regress
        r.tier = earned
        if earned >= .proficient, r.proficientAt == nil { r.proficientAt = now }
        if earned == .mastered, r.masteredAt == nil { r.masteredAt = now }
    }

    /// Records one graded answer against a concept and appends it to the calibration log.
    public static func record(_ state: inout ProgressState, concept: Concept,
                              correct: Bool, interval: IntervalAnswer?, now: Date,
                              evLoss: Double? = nil) {
        state.updateRecord(for: concept) {
            $0.total += 1
            if correct {
                $0.correct += 1
                $0.consecutiveMisses = 0
            } else {
                $0.consecutiveMisses += 1
            }
        }
        state.append(AnswerRecord(concept: concept, at: now,
                                  correct: correct, interval: interval, evLoss: evLoss))
    }

    /// Spec §4.6: three misses in a row means the explanation didn't land, so offer
    /// 천천히 rather than another rep.
    public static func shouldOfferWalkthrough(_ r: ConceptRecord) -> Bool {
        r.consecutiveMisses >= missesBeforeWalkthroughOffer
    }

    /// Spec §4.6: at eight, stop drilling entirely. Failure this deep is a content
    /// gap, not a desirable difficulty — grinding it harder is the wrong response.
    public static func shouldStopDrilling(_ r: ConceptRecord) -> Bool {
        r.consecutiveMisses >= missesBeforeStopDrilling
    }

    /// Completing the full explainer releases a concept from the stop-drilling state.
    /// It is study support, not a graded attempt, so no other field changes.
    public static func completeWalkthrough(_ state: inout ProgressState, concept: Concept) {
        state.updateRecord(for: concept) { $0.consecutiveMisses = 0 }
    }
}

/// Ephemeral, per-concept evidence from one node session. This deliberately stays
/// outside `ProgressState`, preserving the schema-1 file format and old records.
public struct SessionEvidence: Equatable, Sendable {
    /// Independent answers only. Answers given with calculation help are practice and
    /// count in `assisted`, never here.
    public var attempted: Int
    public var spotOn: Int
    public var assisted: Int

    public init(attempted: Int = 0, spotOn: Int = 0, assisted: Int = 0) {
        self.attempted = attempted
        self.spotOn = spotOn
        self.assisted = assisted
    }

    public var isComplete: Bool { attempted > 0 && spotOn >= 0 && spotOn <= attempted }
    /// A perfect session is fully independent: one answer with help rules it out.
    public var isPerfect: Bool { isComplete && spotOn == attempted && assisted == 0 }

    public mutating func record(spotOn: Bool, assisted: Bool = false) {
        if assisted { self.assisted += 1; return }
        attempted += 1
        if spotOn { self.spotOn += 1 }
    }

    /// Requires exactly one recorded answer, independent or with help, for every
    /// scheduled entry, with no missing or extra concepts. Clearing and promotion share
    /// this gate; promotion additionally needs independent answers (`isComplete`).
    public static func validates(_ evidence: [Concept: SessionEvidence],
                                 scheduled: [Concept]) -> Bool {
        guard !scheduled.isEmpty else { return false }
        let expected = Dictionary(grouping: scheduled, by: { $0 }).mapValues(\.count)
        guard evidence.count == expected.count else { return false }
        return expected.allSatisfy { concept, count in
            guard let item = evidence[concept] else { return false }
            return item.attempted >= 0 && item.assisted >= 0
                && item.spotOn >= 0 && item.spotOn <= item.attempted
                && item.attempted + item.assisted == count
        }
    }
}
