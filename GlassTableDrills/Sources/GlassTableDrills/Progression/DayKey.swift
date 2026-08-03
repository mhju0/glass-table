// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// A calendar day in the user's own timezone, stored as "yyyy-MM-dd".
///
/// Streaks compare days, not instants. Doing that with `Date` and 86400-second
/// arithmetic is wrong twice a year: a spring-forward day is 23 hours long, so two
/// consecutive days can measure less than one day apart and silently break a streak.
/// Every day comparison in the app goes through this type.
///
/// The raw form is zero-padded so lexicographic order matches chronological order,
/// and it stays human-readable in the JSON store — which is half the point of
/// choosing a plain file (spec §8.1).
public struct DayKey: Codable, Hashable, Comparable, CustomStringConvertible, Sendable {
    public let raw: String

    public init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.raw = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Fails on anything that isn't a real "yyyy-MM-dd" date, so a hand-edited or
    /// corrupted store can't smuggle in a key that later comparisons misread.
    public init?(raw: String) {
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              (1...12).contains(m), (1...31).contains(d)
        else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        // Round-trip through the calendar so 2026-02-30 is rejected rather than
        // silently normalised to March.
        let comps = DateComponents(year: y, month: m, day: d)
        guard let made = cal.date(from: comps),
              cal.dateComponents([.year, .month, .day], from: made) == comps
        else { return nil }
        self.raw = raw
    }

    public var description: String { raw }
    public static func < (a: DayKey, b: DayKey) -> Bool { a.raw < b.raw }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let key = DayKey(raw: raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "bad DayKey \(raw)"))
        }
        self = key
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }

    /// Whole calendar days from `self` to `other`; negative if `other` is earlier.
    public func daysBetween(_ other: DayKey, calendar: Calendar = .current) -> Int? {
        guard let a = startOfDay(calendar), let b = other.startOfDay(calendar) else { return nil }
        return calendar.dateComponents([.day], from: a, to: b).day
    }

    private func startOfDay(_ calendar: Calendar) -> Date? {
        let p = raw.split(separator: "-")
        guard p.count == 3, let y = Int(p[0]), let m = Int(p[1]), let d = Int(p[2])
        else { return nil }
        return calendar.date(from: DateComponents(year: y, month: m, day: d))
    }
}
