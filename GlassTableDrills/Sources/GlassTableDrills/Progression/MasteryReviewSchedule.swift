// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

public struct MasteryReviewAppointment: Codable, Equatable, Sendable {
    public let dueDay: DayKey
    public fileprivate(set) var finished: Bool
}

public extension ProgressState {
    /// The completion and its due day are committed with the same progress write.
    mutating func scheduleMasteryReview(for progress: TableCourseProgress, now: Date) {
        guard progress.unit.usesSpacedReview else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return }
        var appointments = masteryReview ?? [:]
        for result in progress.completedResults {
            if let skill = result.lesson.reviewSkill, appointments[skill.id] == nil {
                appointments[skill.id] = MasteryReviewAppointment(dueDay: DayKey(tomorrow, calendar: calendar),
                                                                finished: false)
            }
        }
        if !appointments.isEmpty { masteryReview = appointments }
    }

    func masteryReviewDue(on today: DayKey) -> [CourseReviewSkill] {
        CourseReviewSkill.allCases.filter { skill in
            guard let appointment = masteryReview?[skill.id] else { return false }
            return !appointment.finished && today >= appointment.dueDay
        }
    }

    var hasUpcomingMasteryReview: Bool {
        masteryReview?.values.contains { !$0.finished } ?? false
    }

    mutating func finishMasteryReview(_ review: CourseReviewSession) {
        guard review.scope == .spacedMastery, review.phase == .finished else { return }
        for skill in review.skills { masteryReview?[skill.id]?.finished = true }
    }

    internal var hasValidMasteryReview: Bool {
        guard let masteryReview else { return true }
        guard schemaVersion >= 15, !masteryReview.isEmpty else { return false }
        return masteryReview.keys.allSatisfy { id in
            guard let skill = CourseReviewSkill(rawValue: id), let lesson = skill.tableLesson,
                  lesson.unit.usesSpacedReview
            else { return false }
            return progress(in: lesson.unit)?.completedResults.contains { $0.lesson == lesson } == true
        }
    }
}
