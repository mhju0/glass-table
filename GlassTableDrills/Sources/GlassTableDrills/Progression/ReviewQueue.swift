// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// Selects what to practise: the due queue, the daily set, and the streak test
/// (spec §4.5, §4.6, §7.1).
///
/// Everything here works on *concepts*. Nothing stores a spot, because a due concept
/// gets a freshly generated one from the seeded generators — the structural advantage
/// over a flashcard app, which can only replay the card it saved.
public enum ReviewQueue {
    /// Studied concepts whose review date has passed, most overdue first.
    ///
    /// Untouched concepts are excluded: never having been taught is not the same as
    /// being due, and surfacing one in review would be teaching by ambush. Concepts
    /// past the stop-drilling threshold are excluded too (spec §4.6).
    public static func dueConcepts(in state: ProgressState, at now: Date,
                                   scheduler: FSRSScheduler) -> [Concept] {
        Concept.allCases
            .compactMap { concept -> (Concept, Date)? in
                guard let r = state.concepts[concept.rawValue], r.total > 0,
                      !Mastery.shouldStopDrilling(r),
                      let due = r.review.due, due <= now
                else { return nil }
                return (concept, due)
            }
            .sorted { $0.1 < $1.1 }      // earliest due date = most overdue
            .map(\.0)
    }

    /// Concepts that have failed too often to keep drilling. The app owes these an
    /// explainer instead of another rep (spec §4.6).
    public static func needingExplainer(in state: ProgressState) -> [Concept] {
        Concept.allCases.filter {
            guard let r = state.concepts[$0.rawValue] else { return false }
            return Mastery.shouldStopDrilling(r)
        }
    }

    /// Records one graded review: advances the FSRS schedule, updates counts and miss
    /// streaks, and logs the answer for calibration.
    public static func recordReview(_ state: inout ProgressState, concept: Concept,
                                    rating: FSRS.Rating, interval: IntervalAnswer?,
                                    now: Date, scheduler: FSRSScheduler,
                                    evLoss: Double? = nil) {
        Mastery.record(&state, concept: concept, correct: rating != .again,
                       interval: interval, now: now, evLoss: evLoss)
        state.updateRecord(for: concept) {
            scheduler.review(&$0.review, rating: rating, now: now)
        }
    }

    // MARK: - the daily set

    /// Spec §7.1: the Wordle trick. The seed is derived only from the date and the
    /// content version, so every user sees a comparable set with no server involved.
    public static func dailySeed(day: DayKey, contentVersion: Int) -> UInt64 {
        // FNV-1a over the day string, then mixed with the content version so a
        // rebuilt spot set reshuffles the day instead of replaying yesterday's.
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in day.raw.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01b3
        }
        hash ^= UInt64(bitPattern: Int64(contentVersion))
        hash &*= 0x0000_0100_0000_01b3
        return hash
    }

    /// Today's practice set: due concepts first (most overdue leading), topped up with
    /// studied-but-not-due material. Never includes anything untaught.
    public static func dailySet(in state: ProgressState, at now: Date,
                                scheduler: FSRSScheduler, size: Int) -> [Concept] {
        var out = dueConcepts(in: state, at: now, scheduler: scheduler)
        guard out.count < size else { return Array(out.prefix(size)) }

        let chosen = Set(out)
        // Weakest first, so a top-up is still the most useful thing available.
        let topUp = Concept.allCases
            .filter { concept in
                guard let r = state.concepts[concept.rawValue], r.total > 0,
                      !chosen.contains(concept), !Mastery.shouldStopDrilling(r)
                else { return false }
                return true
            }
            .sorted { a, b in
                state.record(for: a).accuracy < state.record(for: b).accuracy
            }
        out.append(contentsOf: topUp.prefix(size - out.count))
        return out
    }

    /// Spec §7.1: a streak day is a session that included at least one due item — not
    /// a volume target, so the streak can't be farmed on mastered material.
    ///
    /// A user with nothing due yet (a first session, or someone fully caught up) still
    /// qualifies on any answer; otherwise the streak would punish being up to date.
    public static func sessionQualifiesForStreak(answered: [Concept], in state: ProgressState,
                                                 at now: Date,
                                                 scheduler: FSRSScheduler) -> Bool {
        guard !answered.isEmpty else { return false }
        let due = Set(dueConcepts(in: state, at: now, scheduler: scheduler))
        return due.isEmpty || !due.isDisjoint(with: answered)
    }
}
