// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Streak bookkeeping (spec §7.1).
///
/// A streak day is "a session that included at least one due item" — deliberately not
/// a volume target, so the streak can never be farmed by grinding already-mastered
/// material. Deciding *whether* a session qualifies is the caller's job; this type
/// only advances the record once it does.
///
/// Forgiveness is silent: freezes apply automatically with no dialog, because the
/// punitive version measurably reduces both streak length and retention.
public enum Streak {
    /// Spec §7.1: one freeze earned per 48h, capped at `StreakRecord.maxFreezes`.
    public static let freezeEarnDays = 2

    public static func recordSession(_ r: inout StreakRecord, on today: DayKey) {
        defer { r.longest = max(r.longest, r.current) }

        guard let last = r.lastSessionDay else {
            r.current = 1
            r.lastSessionDay = today
            r.lastFreezeEarnedDay = today
            return
        }

        guard let gap = last.daysBetween(today), gap > 0 else {
            // Same day → already counted. Earlier day → a clock that moved backwards,
            // which must not rewrite history.
            return
        }

        earnFreezes(&r, upTo: today)

        let missed = gap - 1
        if missed == 0 {
            r.current += 1
        } else if missed <= r.freezesRemaining {
            r.freezesRemaining -= missed
            r.current += 1
        } else {
            r.current = 1
        }
        r.lastSessionDay = today
    }

    /// Accrues any freezes earned since the last accrual, capped.
    ///
    /// The earn clock is reset to `today` whenever a freeze is granted, so a partial
    /// remainder is rounded away rather than carried. At a two-freeze cap that costs
    /// the user at most one extra day before the next freeze, and it keeps the rule
    /// something you can state in one sentence.
    private static func earnFreezes(_ r: inout StreakRecord, upTo today: DayKey) {
        // A record restored from a store written before freezes existed — or built
        // directly — has no clock. Start it at the last known activity.
        guard let since = r.lastFreezeEarnedDay ?? r.lastSessionDay else {
            r.lastFreezeEarnedDay = today
            return
        }
        guard r.freezesRemaining < StreakRecord.maxFreezes else {
            r.lastFreezeEarnedDay = today       // already full; the clock idles at now
            return
        }
        guard let elapsed = since.daysBetween(today), elapsed >= freezeEarnDays else {
            r.lastFreezeEarnedDay = since       // seed it if it was unset
            return
        }
        let granted = min(elapsed / freezeEarnDays,
                          StreakRecord.maxFreezes - r.freezesRemaining)
        r.freezesRemaining += granted
        r.lastFreezeEarnedDay = today
    }
}
