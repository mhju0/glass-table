// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Observation
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
    @MainActor static let shared = DailyReminderSettings()

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
}

@MainActor
protocol DailyReminderClient {
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func remove()
}

@MainActor
private struct SystemDailyReminderClient: DailyReminderClient {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }

    func remove() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [DailyReminder.identifier])
    }
}

/// Lives beyond Settings so an in-flight system add is reconciled even after navigation.
@MainActor @Observable
final class DailyReminderSettings {
    private(set) var isEnabled: Bool
    private(set) var isRefused = false
    private let client: any DailyReminderClient
    private let defaults: UserDefaults
    private var generation = 0
    private var selection: (minutes: Int, language: LearningLanguage)?
    private var worker: Task<Void, Never>?

    init(client: any DailyReminderClient, defaults: UserDefaults) {
        self.client = client
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: DailyReminder.enabledKey)
    }

    convenience init() {
        self.init(client: SystemDailyReminderClient(), defaults: .standard)
    }

    @discardableResult
    func enable(minutes: Int, language: LearningLanguage) -> Task<Void, Never> {
        generation += 1
        selection = (minutes, language)
        isEnabled = true
        isRefused = false
        if let worker { return worker }
        let task = Task { await reconcile() }
        worker = task
        return task
    }

    func disable() {
        generation += 1
        selection = nil
        isEnabled = false
        isRefused = false
        defaults.set(false, forKey: DailyReminder.enabledKey)
        client.remove()
    }

    private func reconcile() async {
        defer { worker = nil }
        while let selection {
            let expected = generation
            let granted = (try? await client.requestAuthorization()) ?? false
            guard expected == generation else { continue }
            guard granted else {
                refuse()
                return
            }
            client.remove()
            let scheduled: Bool
            do {
                try await client.add(DailyReminder.request(minutes: selection.minutes,
                                                          language: selection.language))
                scheduled = true
            } catch {
                scheduled = false
            }
            // Cancellation cannot retract an add already submitted to the system.
            // No newer add starts until this one finishes and its stale result is removed.
            guard expected == generation else {
                client.remove()
                continue
            }
            if scheduled {
                defaults.set(true, forKey: DailyReminder.enabledKey)
            } else {
                refuse()
            }
            return
        }
    }

    private func refuse() {
        selection = nil
        isEnabled = false
        isRefused = true
        defaults.set(false, forKey: DailyReminder.enabledKey)
        client.remove()
    }

    #if DEBUG
    func showPreview(enabled: Bool, refused: Bool) {
        isEnabled = enabled
        isRefused = refused
    }
    #endif
}
