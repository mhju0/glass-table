// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import UserNotifications
import GlassTableDrills

/// One opt-in local notification a day. No server, and no streak wording: the learner
/// chose the time, so the text only says the table is there.
enum DailyReminder {
    static let identifier = "daily-reminder"
    static let enabledKey = "reminder.enabled"
    static let minutesKey = "reminder.minutes"
    /// 20:00, as minutes after midnight.
    static let defaultMinutes = 20 * 60

    static func request(minutes: Int, language: LearningLanguage) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Glass Table"
        content.body = language.text("오늘의 테이블이 준비됐어요. 몇 분이면 충분해요.",
                                     "Your table is ready. A few minutes is plenty.")
        var time = DateComponents()
        time.hour = minutes / 60
        time.minute = minutes % 60
        return UNNotificationRequest(identifier: identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: time, repeats: true))
    }

    /// Asks for permission when needed. Returns false when notifications are refused.
    static func enable(minutes: Int, language: LearningLanguage) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        do {
            try await center.add(request(minutes: minutes, language: language))
            return true
        } catch {
            return false
        }
    }

    static func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
