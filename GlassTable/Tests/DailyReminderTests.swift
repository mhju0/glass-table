// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Testing
import UserNotifications
import GlassTableDrills
@testable import GlassTable

@MainActor
struct DailyReminderTests {
    private func makeSettings() -> (DailyReminderSettings, DelayedReminderClient, UserDefaults) {
        let defaults = UserDefaults(suiteName: "DailyReminderTests.\(UUID())")!
        let client = DelayedReminderClient()
        return (DailyReminderSettings(client: client, defaults: defaults), client, defaults)
    }

    @Test func offDuringAuthorizationPreventsAnAddAndStaleRefusal() async throws {
        let (settings, client, defaults) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        let authorization = try await client.authorization(at: 0)
        #expect(settings.isEnabled)
        #expect(!defaults.bool(forKey: DailyReminder.enabledKey))
        settings.disable()
        authorization.resume(returning: true)
        await operation.value
        #expect(client.requests.isEmpty)
        #expect(client.pending == nil)
        #expect(!settings.isEnabled)
        #expect(!settings.isRefused)
        #expect(!defaults.bool(forKey: DailyReminder.enabledKey))
    }

    @Test func offDuringAddRemovesTheRequestAfterItsDelayedSideEffect() async throws {
        let (settings, client, defaults) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        try await client.authorization(at: 0).resume(returning: true)
        let add = try await client.addition(at: 0)
        settings.disable()
        let removalsBeforeCompletion = client.removals
        add.resume()
        await operation.value
        #expect(client.removals > removalsBeforeCompletion)
        #expect(client.pending == nil)
        #expect(!settings.isEnabled)
        #expect(!settings.isRefused)
        #expect(!defaults.bool(forKey: DailyReminder.enabledKey))
    }

    @Test func latestTimeAndLanguageWinWhileAuthorizationIsPending() async throws {
        let (settings, client, defaults) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        let oldAuthorization = try await client.authorization(at: 0)
        settings.enable(minutes: 8 * 60 + 15, language: .english)
        oldAuthorization.resume(returning: true)
        try await client.authorization(at: 1).resume(returning: true)
        try await client.addition(at: 0).resume()
        await operation.value
        #expect(client.requests.count == 1)
        checkLatestRequest(client.pending, minutes: 8 * 60 + 15, language: .english)
        #expect(settings.isEnabled)
        #expect(defaults.bool(forKey: DailyReminder.enabledKey))
    }

    @Test func oldAddThenOffThenNewOnCannotRemoveTheNewRequest() async throws {
        let (settings, client, defaults) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        try await client.authorization(at: 0).resume(returning: true)
        let oldAdd = try await client.addition(at: 0)
        settings.disable()
        settings.enable(minutes: 7 * 60 + 30, language: .english)
        #expect(client.requests.count == 1)
        oldAdd.resume()
        try await client.authorization(at: 1).resume(returning: true)
        #expect(client.pending == nil)
        try await client.addition(at: 1).resume()
        await operation.value
        checkLatestRequest(client.pending, minutes: 7 * 60 + 30, language: .english)
        #expect(settings.isEnabled)
        #expect(!settings.isRefused)
        #expect(defaults.bool(forKey: DailyReminder.enabledKey))
    }

    @Test func rapidEditsDuringAddConvergeToTheLastSelection() async throws {
        let (settings, client, _) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        try await client.authorization(at: 0).resume(returning: true)
        let oldAdd = try await client.addition(at: 0)
        settings.enable(minutes: 800, language: .english)
        settings.enable(minutes: 900, language: .korean)
        oldAdd.resume()
        try await client.authorization(at: 1).resume(returning: true)
        try await client.addition(at: 1).resume()
        await operation.value
        #expect(client.requests.count == 2)
        checkLatestRequest(client.pending, minutes: 900, language: .korean)
    }

    @Test func staleDenialCannotRefuseANewerEnable() async throws {
        let (settings, client, _) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        let oldAuthorization = try await client.authorization(at: 0)
        settings.enable(minutes: 600, language: .english)
        oldAuthorization.resume(returning: false)
        try await client.authorization(at: 1).resume(returning: true)
        try await client.addition(at: 0).resume()
        await operation.value
        #expect(settings.isEnabled)
        #expect(!settings.isRefused)
        checkLatestRequest(client.pending, minutes: 600, language: .english)
    }

    @Test func staleAddFailureCannotRefuseANewerEnable() async throws {
        let (settings, client, _) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        try await client.authorization(at: 0).resume(returning: true)
        let oldAdd = try await client.addition(at: 0)
        settings.enable(minutes: 600, language: .english)
        oldAdd.resume(throwing: DelayedReminderClient.Failure.unavailable)
        try await client.authorization(at: 1).resume(returning: true)
        try await client.addition(at: 1).resume()
        await operation.value
        #expect(settings.isEnabled)
        #expect(!settings.isRefused)
        checkLatestRequest(client.pending, minutes: 600, language: .english)
    }

    @Test(arguments: [false, true])
    func currentPermissionFailureShowsRefusalAndOffClearsIt(throwsError: Bool) async throws {
        let (settings, client, defaults) = makeSettings()
        let operation = settings.enable(minutes: 1200, language: .korean)
        let authorization = try await client.authorization(at: 0)
        if throwsError {
            authorization.resume(throwing: DelayedReminderClient.Failure.unavailable)
        } else {
            authorization.resume(returning: false)
        }
        await operation.value
        #expect(!settings.isEnabled)
        #expect(settings.isRefused)
        #expect(client.requests.isEmpty)
        #expect(!defaults.bool(forKey: DailyReminder.enabledKey))
        settings.disable()
        #expect(!settings.isRefused)
    }

    @Test func currentAddFailureShowsRefusalAndRemovesThePreviousRequest() async throws {
        let (settings, client, defaults) = makeSettings()
        client.pending = DailyReminder.request(minutes: 600, language: .english)
        let operation = settings.enable(minutes: 1200, language: .korean)
        try await client.authorization(at: 0).resume(returning: true)
        try await client.addition(at: 0).resume(throwing: DelayedReminderClient.Failure.unavailable)
        await operation.value
        #expect(!settings.isEnabled)
        #expect(settings.isRefused)
        #expect(client.pending == nil)
        #expect(!defaults.bool(forKey: DailyReminder.enabledKey))
    }

    @Test func savedOptInAndTimeArePreservedUntilAnExplicitChange() {
        let defaults = UserDefaults(suiteName: "DailyReminderTests.\(UUID())")!
        defaults.set(true, forKey: DailyReminder.enabledKey)
        defaults.set(450, forKey: DailyReminder.minutesKey)
        let client = DelayedReminderClient()
        let settings = DailyReminderSettings(client: client, defaults: defaults)
        #expect(settings.isEnabled)
        #expect(!settings.isRefused)
        #expect(client.requests.isEmpty)
        #expect(defaults.integer(forKey: DailyReminder.minutesKey) == 450)
        settings.disable()
        #expect(!defaults.bool(forKey: DailyReminder.enabledKey))
        #expect(defaults.integer(forKey: DailyReminder.minutesKey) == 450)
    }

    @Test func workerFinishesCompensationAfterTheViewReleasesItsOwner() async throws {
        let defaults = UserDefaults(suiteName: "DailyReminderTests.\(UUID())")!
        let client = DelayedReminderClient()
        var viewOwner: DailyReminderSettings? = DailyReminderSettings(client: client, defaults: defaults)
        weak var observedOwner = viewOwner
        let operation = try #require(viewOwner).enable(minutes: 1200, language: .korean)
        try await client.authorization(at: 0).resume(returning: true)
        let add = try await client.addition(at: 0)
        viewOwner?.disable()
        viewOwner = nil
        #expect(observedOwner != nil)
        add.resume()
        await operation.value
        #expect(client.pending == nil)
        #expect(observedOwner == nil)
        #expect(!defaults.bool(forKey: DailyReminder.enabledKey))
    }

    private func checkLatestRequest(_ request: UNNotificationRequest?, minutes: Int,
                                    language: LearningLanguage) {
        let trigger = request?.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.dateComponents.hour == minutes / 60)
        #expect(trigger?.dateComponents.minute == minutes % 60)
        #expect(trigger?.repeats == true)
        #expect(request?.content.body == DailyReminder.request(minutes: minutes, language: language).content.body)
    }
}

@MainActor
private final class DelayedReminderClient: DailyReminderClient {
    enum Failure: Error { case unavailable }
    private var authorizations: [CheckedContinuation<Bool, Error>] = []
    private var additions: [CheckedContinuation<Void, Error>] = []
    private(set) var requests: [UNNotificationRequest] = []
    var pending: UNNotificationRequest?
    private(set) var removals = 0

    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { authorizations.append($0) }
    }

    func add(_ request: UNNotificationRequest) async throws {
        requests.append(request)
        try await withCheckedThrowingContinuation { additions.append($0) }
        pending = request
    }

    func remove() {
        removals += 1
        pending = nil
    }

    func authorization(at index: Int) async throws -> CheckedContinuation<Bool, Error> {
        for _ in 0..<1000 {
            if authorizations.indices.contains(index) { return authorizations[index] }
            await Task.yield()
        }
        return try #require(authorizations.indices.contains(index) ? authorizations[index] : nil)
    }

    func addition(at index: Int) async throws -> CheckedContinuation<Void, Error> {
        for _ in 0..<1000 {
            if additions.indices.contains(index) { return additions[index] }
            await Task.yield()
        }
        return try #require(additions.indices.contains(index) ? additions[index] : nil)
    }
}
