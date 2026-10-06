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
        default: break
        }
        return state
    }
}
#endif
