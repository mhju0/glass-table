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

    /// - Parameters:
    ///   - cleanRun: the concept's own drill was completed with no misses.
    ///   - viaBoss: this promotion is being evaluated at a mixed boss node. The
    ///     *only* route to 숙달, because blocked practice proves fluency, not transfer.
    public static func promote(_ r: inout ConceptRecord, cleanRun: Bool,
                               viaBoss: Bool, now: Date) {
        var earned: MasteryTier = r.accuracy >= familiarThreshold ? .familiar : .attempted

        if cleanRun, earned >= .familiar { earned = .proficient }

        if viaBoss, r.tier >= .proficient || earned >= .proficient,
           let since = r.proficientAt ?? (earned >= .proficient ? now : nil),
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
                              correct: Bool, interval: IntervalAnswer?, now: Date) {
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
                                  correct: correct, interval: interval))
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
}
