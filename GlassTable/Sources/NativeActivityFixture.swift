#if DEBUG
import Foundation
import GlassTableDrills

/// In-memory states for disposable demo stores. No fixture is written on launch.
enum NativeActivityFixture {
    static func make(_ name: String, now: Date = Date(), calendar: Calendar = .current) -> ProgressState {
        var state = ProgressState()
        state.firstLessonCompleted = true
        state.basicsLessonCompleted = true
        func row(_ offset: Int, _ concept: Concept = .showdown, assisted: Bool = false,
                 exact: Int = 1, miss: Int = 0, mode: String = "path") -> DailyPracticeSummary {
            let date = calendar.date(byAdding: .day, value: offset, to: now)!
            var summary = DailyPracticeSummary(key: DailyPracticeKey(day: DayKey(date, calendar: calendar),
                concept: concept.rawValue, mode: mode, formatVersion: 1, language: "ko", assisted: assisted))
            summary.exact = exact; summary.miss = miss
            return summary
        }
        switch name {
        case "records-time":
            for (concept, due) in [(Concept.potOdds, now.addingTimeInterval(6 * 3600)),
                                   (.combos, calendar.date(byAdding: .day, value: 1, to: now)!),
                                   (.outs, calendar.date(byAdding: .day, value: 3, to: now)!)] {
                state.updateRecord(for: concept) {
                    $0.total = 5
                    $0.correct = 4
                    $0.review.due = due
                }
            }
            state.streak = StreakRecord(current: 12, longest: 12,
                lastSessionDay: DayKey(calendar.date(byAdding: .day, value: -10, to: now)!, calendar: calendar))
        case "help-only": state.dailySummaries = [row(0, assisted: true, exact: 0)]
        case "wrong": state.dailySummaries = [row(0, exact: 0, miss: 1)]
        case "helped": state.dailySummaries = [row(0, assisted: true, exact: 0, miss: 1)]
        case "four-days": state.dailySummaries = (-3...0).map { row($0, assisted: true, exact: 0, miss: 1) }
        case "before-fourth": state.dailySummaries = (-3...(-1)).map { row($0) }
        case "sparse-future": state.dailySummaries = [row(-12), row(-4, .potMath), row(1, .outs)]
        case "returning": state.dailySummaries = [row(-10, .potMath), row(-2, .showdown)]
        case "mixed": state.dailySummaries = [row(0), row(0, .potMath, assisted: true, mode: "single-skill"), row(-1, .outs, exact: 0, miss: 1)]
        case "completed":
            state.dailySummaries = [row(0)]
            for node in Curriculum.tracks.filter({ !$0.isOptional }).flatMap(\.lessons) {
                state.nodes[node.id] = NodeRecord(cleared: true, clearedAt: now, attempts: 1)
            }
        case "progress-today": progressLearner(&state, away: 0, now: now, calendar: calendar)
        case "progress-away": progressLearner(&state, away: 10, now: now, calendar: calendar)
        case "progress-large-count":
            progressLearner(&state, away: 0, now: now, calendar: calendar)
            state.dailySummaries = [row(0, exact: 1_234_567)]
        default: break
        }
        return state
    }

    /// The learner on the Progress boards (R3·G): 412 decisions, five path skills at
    /// Strong, one Mastered, the basics challenge passed. `away` moves every saved date
    /// back that many days, so the same learner opens the app after time away.
    private static func progressLearner(_ state: inout ProgressState, away: Int, now: Date, calendar: Calendar) {
        let back = { (days: Int) in calendar.date(byAdding: .day, value: -(days + away), to: now)! }
        let skills: [(Concept, MasteryTier, Int, Int?, Int?)] = [
            // concept, tier, review in days (from today when not away), Strong and Mastered days ago
            (.showdown, .mastered, 14, 13, 4), (.position, .proficient, 9, 8, nil),
            (.rfi, .proficient, 15, 6, nil), (.outs, .proficient, 8, 1, nil),
            (.potMath, .proficient, 0, 9, nil), (.rangeRead, .familiar, 12, nil, nil),
            (.defend, .familiar, 13, nil, nil), (.equitySense, .familiar, 16, nil, nil),
            (.actionRead, .attempted, 11, nil, nil),
        ]
        for (concept, tier, dueIn, strong, mastered) in skills {
            let due = calendar.date(byAdding: .day, value: dueIn - away, to: now)!.addingTimeInterval(dueIn == 0 ? -3600 : 0)
            state.updateRecord(for: concept) {
                $0.tier = tier; $0.total = 30; $0.correct = 25
                $0.proficientAt = strong.map(back); $0.masteredAt = mastered.map(back)
                $0.review = ReviewState(stability: 6, difficulty: 5, lastReview: min(back(1), due.addingTimeInterval(-86_400)),
                                        due: due, reps: 3)
            }
        }
        state.nodes["u1-showdown"] = NodeRecord(cleared: true, clearedAt: back(12), attempts: 1)
        state.nodes["u1-position"] = NodeRecord(cleared: true, clearedAt: back(10), attempts: 1)
        state.nodes["u1-boss"] = NodeRecord(cleared: true, clearedAt: back(9), attempts: 1)
        state.dailySummaries = [(14, Concept.showdown, 60), (11, .position, 50), (7, .rfi, 150), (0, .outs, 152)].map { days, concept, count in
            var summary = DailyPracticeSummary(key: DailyPracticeKey(day: DayKey(back(days), calendar: calendar),
                concept: concept.rawValue, mode: "path", formatVersion: 1, language: "ko", assisted: false))
            summary.exact = count
            return summary
        }
        state.streak = StreakRecord(current: away == 0 ? 1 : 3, longest: 6, lastSessionDay: DayKey(back(0), calendar: calendar))
    }
}
#endif
