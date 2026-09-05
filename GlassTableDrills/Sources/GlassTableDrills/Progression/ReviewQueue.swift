// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// Selects due concepts and records study, scheduling, and streak credit together.
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
    public static func dueConcepts(in state: ProgressState, at now: Date) -> [Concept] {
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
        // Decide before rescheduling removes this concept from the due queue.
        // A committed answer counts as study even when wrong or the lesson is unfinished.
        let due = dueConcepts(in: state, at: now)
        if due.isEmpty || due.contains(concept) {
            Streak.recordSession(&state.streak, on: DayKey(now))
        }
        Mastery.record(&state, concept: concept, correct: rating != .again,
                       interval: interval, now: now, evLoss: evLoss)
        state.updateRecord(for: concept) {
            scheduler.review(&$0.review, rating: rating, now: now)
        }
    }

}
