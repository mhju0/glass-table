// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// What the Progress tab shows, read from saved state only (owner, 2026-10-18). The two
/// headline numbers only grow; the week line starts again each Monday; the journal is
/// dated from records the app already keeps. Nothing here is saved.
public struct ProgressOverview: Equatable, Sendable {
    public struct Skill: Equatable, Sendable {
        public let concept: Concept
        /// Nil until the skill has a saved record.
        public let tier: MasteryTier?
        /// A review date has passed (`ReviewQueue.dueConcepts`).
        public let isDue: Bool
        /// A "Go deeper" skill.
        public let isOptional: Bool

        /// Filled segments of the stage bar: 0 not started, then one per tier.
        public var stage: Int { tier.map { (MasteryTier.allCases.firstIndex(of: $0) ?? 0) + 1 } ?? 0 }
        public var stageCount: Int { MasteryTier.allCases.count }
    }

    public enum Milestone: Equatable, Sendable {
        case firstStrong(Concept)
        case mastered(Concept)
        case trackPassed(LearningTrack.ID)
        case decisions(Int)
    }

    public struct JournalEntry: Equatable, Sendable {
        public let day: DayKey
        public let milestone: Milestone

        public init(day: DayKey, milestone: Milestone) {
            self.day = day; self.milestone = milestone
        }
    }

    public static let decisionMilestones = [100, 250, 500, 1_000]
    /// Whole days since the last practice after which the tab welcomes the learner back.
    public static let awayDays = 3

    /// Every answer in the daily summaries, with or without help, in every mode.
    /// Summaries keep every day, unlike the capped answer log.
    public let decisionsStudied: Int
    public let strongSkills: Int
    public let masteredSkills: Int
    public let skillCount: Int
    /// Days with an answer since Monday, today included.
    public let daysThisWeek: Int
    /// Days since the latest day with an answer; nil before the first one.
    public let daysAway: Int?
    public let hasHistory: Bool
    /// Strongest first, then in path order.
    public let skills: [Skill]
    public let due: [Concept]
    /// Newest first.
    public let journal: [JournalEntry]
    public let nextDecisionMilestone: Int?

    public var isReturning: Bool { (daysAway ?? 0) >= Self.awayDays }

    /// Skills at Strong or better, over the curriculum's skills only.
    public static func strongCount(in state: ProgressState) -> Int {
        Curriculum.skills.filter { state.record(for: $0).tier >= .proficient }.count
    }

    public init(state: ProgressState, now: Date, calendar: Calendar) {
        let today = DayKey(now, calendar: calendar)
        let answered = state.dailySummaries.filter { $0.total > 0 }
        let decisions = answered.reduce(0) { $0 + $1.total }
        decisionsStudied = decisions

        let skillSet = Curriculum.skills
        let records = skillSet.map { state.concepts[$0.rawValue] }
        strongSkills = Self.strongCount(in: state)
        masteredSkills = records.filter { $0?.tier == .mastered }.count
        skillCount = skillSet.count

        // The week starts on Monday wherever the phone's calendar starts it.
        var monday = calendar
        monday.firstWeekday = 2
        let weekStart = monday.dateInterval(of: .weekOfYear, for: now).map { DayKey($0.start, calendar: calendar) } ?? today
        let pastDays = Set(answered.map(\.key.day).filter { $0 <= today })
        daysThisWeek = pastDays.filter { $0 >= weekStart }.count
        daysAway = pastDays.max().flatMap { $0.daysBetween(today, calendar: calendar) }
        hasHistory = decisions > 0 || records.contains { $0 != nil }

        let due = ReviewQueue.dueConcepts(in: state, at: now)
        self.due = due.filter(skillSet.contains)
        let optional = Set(Curriculum.tracks.filter(\.isOptional).flatMap(\.concepts))
        let unsorted = zip(skillSet, records).map { concept, record in
            Skill(concept: concept, tier: record?.tier, isDue: due.contains(concept),
                  isOptional: optional.contains(concept))
        }
        skills = unsorted.enumerated()
            .sorted { $0.element.stage != $1.element.stage ? $0.element.stage > $1.element.stage : $0.offset < $1.offset }
            .map(\.element)

        var entries: [(JournalEntry, rank: Int)] = []
        let day = { (date: Date) in DayKey(date, calendar: calendar) }
        if let first = zip(skillSet, records)
            .compactMap({ concept, record in record?.proficientAt.map { (concept, $0) } })
            .min(by: { $0.1 < $1.1 }) {
            entries.append((JournalEntry(day: day(first.1), milestone: .firstStrong(first.0)), 0))
        }
        for track in Curriculum.tracks {
            guard let challenge = track.challenge, let record = state.nodes[challenge.id],
                  record.cleared, let at = record.clearedAt else { continue }
            entries.append((JournalEntry(day: day(at), milestone: .trackPassed(track.id)), 1))
        }
        for (concept, record) in zip(skillSet, records) {
            guard let at = record?.masteredAt else { continue }
            entries.append((JournalEntry(day: day(at), milestone: .mastered(concept)), 2))
        }
        var running = 0
        var remaining = Self.decisionMilestones[...]
        let byDay = Dictionary(grouping: answered.filter { $0.key.day <= today }, by: \.key.day)
        for key in byDay.keys.sorted() {
            running += byDay[key]!.reduce(0) { $0 + $1.total }
            while let next = remaining.first, running >= next {
                entries.append((JournalEntry(day: key, milestone: .decisions(next)), 3 + next))
                remaining = remaining.dropFirst()
            }
        }
        journal = entries
            .sorted { $0.0.day != $1.0.day ? $0.0.day > $1.0.day : $0.rank > $1.rank }
            .map(\.0)
        nextDecisionMilestone = Self.decisionMilestones.first { $0 > decisions }
    }
}
