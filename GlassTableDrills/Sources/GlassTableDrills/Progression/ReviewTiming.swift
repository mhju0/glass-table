// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Review eligibility uses instants; future labels use the learner's calendar.
public enum ReviewTiming {
    public static func text(due: Date, now: Date, calendar: Calendar = .current,
                            language: LearningLanguage) -> String {
        if due <= now { return language.text("지금 복습", "review now") }
        if calendar.isDate(due, inSameDayAs: now) {
            return language.text("오늘 나중에 복습", "review later today")
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(due, inSameDayAs: tomorrow) {
            return language.text("내일 복습", "review tomorrow")
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .korean ? "ko_KR" : "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let date = formatter.string(from: due)
        return language.text("\(date) 복습", "review on \(date)")
    }
}
