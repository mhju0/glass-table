// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Foreground, uninterrupted decision time only. A restored or interrupted
/// question never becomes eligible again; only a new ordinal can arm it.
struct QuestionTiming: Equatable {
    private(set) var eligibleKey: String?
    private(set) var startedAt: TimeInterval?

    mutating func beginNewQuestion(_ key: String) {
        eligibleKey = key
        startedAt = nil
    }

    mutating func ready(_ key: String, uptime: TimeInterval) {
        guard eligibleKey == key, startedAt == nil,
              uptime.isFinite, uptime >= 0 else { return }
        startedAt = uptime
    }

    mutating func clearClock() { startedAt = nil }

    mutating func interrupt() {
        eligibleKey = nil
        startedAt = nil
    }

    func elapsed(for key: String, at uptime: TimeInterval) -> TimeInterval? {
        guard eligibleKey == key, let startedAt,
              uptime.isFinite, uptime >= startedAt else { return nil }
        return uptime - startedAt
    }
}
