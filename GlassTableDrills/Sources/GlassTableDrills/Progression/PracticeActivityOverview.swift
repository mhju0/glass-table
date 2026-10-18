// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// A read-only view of recorded practice. Historical day keys stay in their
/// original calendar dates; answer logs and unfinished sessions add no credit.
public struct PracticeActivityOverview: Equatable, Sendable {
    public struct DayCell: Equatable, Sendable {
        public let day: DayKey
        public let isRecorded: Bool
        public let isToday: Bool
    }

    public struct RecentTopic: Equatable, Sendable {
        public let concept: Concept
        public let lastPracticedDay: DayKey
    }

    public let today: DayKey
    /// Oldest to newest, including today.
    public let last7: [DayCell]
    public let distinctRecentDayCount: Int
    public let todayAnswerCount: Int
    /// Zero unless today has recorded practice. May extend beyond the seven cells.
    public let consecutivePracticeDays: Int
    public let todayFlameBool: Bool
    /// Latest recorded day first, with concept identifiers breaking same-day ties.
    public let recentTopics: [RecentTopic]
    public let mainCourseCompletedLessons: Int
    public let mainCourseLessonCount: Int
    public let deeperCompletedLessons: Int
    public let deeperLessonCount: Int

    public init(state: ProgressState, now: Date, calendar: Calendar) {
        let today = DayKey(now, calendar: calendar)
        self.today = today
        let practiceModes: Set<String> = ["path", "single-skill", "review", "practice", "table"]
        let summaries = state.dailySummaries.filter {
            $0.total > 0 && $0.key.day <= today && practiceModes.contains($0.key.mode)
        }
        let recordedDays = Set(summaries.map(\.key.day))
        let start = calendar.startOfDay(for: now)
        let cells = (-6...0).compactMap { offset -> DayCell? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let day = DayKey(date, calendar: calendar)
            return DayCell(day: day, isRecorded: recordedDays.contains(day), isToday: day == today)
        }
        last7 = cells
        distinctRecentDayCount = cells.filter(\.isRecorded).count
        todayAnswerCount = summaries.filter { $0.key.day == today }.reduce(0) { $0 + $1.total }

        var consecutive = 0
        var cursor = start
        while recordedDays.contains(DayKey(cursor, calendar: calendar)) {
            consecutive += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        consecutivePracticeDays = consecutive
        todayFlameBool = consecutive >= 4

        var latestDays: [Concept: DayKey] = [:]
        for summary in summaries {
            guard let concept = Concept(rawValue: summary.key.concept) else { continue }
            if latestDays[concept].map({ $0 < summary.key.day }) ?? true {
                latestDays[concept] = summary.key.day
            }
        }
        recentTopics = latestDays.map { RecentTopic(concept: $0.key, lastPracticedDay: $0.value) }
            .sorted {
                if $0.lastPracticedDay != $1.lastPracticedDay { return $0.lastPracticedDay > $1.lastPracticedDay }
                return $0.concept.rawValue < $1.concept.rawValue
            }

        let mainLessons = Curriculum.tracks.filter { !$0.isOptional }.flatMap(\.lessons)
        let deeperLessons = Curriculum.tracks.filter(\.isOptional).flatMap(\.lessons)
        mainCourseLessonCount = mainLessons.count
        mainCourseCompletedLessons = mainLessons.filter { state.nodes[$0.id]?.cleared == true }.count
        deeperLessonCount = deeperLessons.count
        deeperCompletedLessons = deeperLessons.filter { state.nodes[$0.id]?.cleared == true }.count
    }
}
