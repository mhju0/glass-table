import XCTest
@testable import GlassTableDrills

final class DayKeyTests: XCTestCase {
    /// Fixed calendar so these assertions can't drift with the machine's locale.
    private func seoul() -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return c
    }
    private func date(_ iso: String, _ cal: Calendar) -> Date {
        let f = ISO8601DateFormatter()
        f.timeZone = cal.timeZone
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)!
    }

    func testRawIsSortableYearMonthDay() {
        let cal = seoul()
        XCTAssertEqual(DayKey(date("2026-08-03T09:00:00+09:00", cal), calendar: cal).raw,
                       "2026-08-03")
        // Zero-padded so lexicographic order matches chronological order.
        XCTAssertEqual(DayKey(date("2026-01-05T23:59:00+09:00", cal), calendar: cal).raw,
                       "2026-01-05")
    }

    func testSameCalendarDayAcrossHoursIsOneKey() {
        let cal = seoul()
        let morning = DayKey(date("2026-08-03T00:00:00+09:00", cal), calendar: cal)
        let night = DayKey(date("2026-08-03T23:59:59+09:00", cal), calendar: cal)
        XCTAssertEqual(morning, night)
    }

    func testMidnightRollsToTheNextDay() {
        let cal = seoul()
        let before = DayKey(date("2026-08-03T23:59:59+09:00", cal), calendar: cal)
        let after = DayKey(date("2026-08-04T00:00:01+09:00", cal), calendar: cal)
        XCTAssertNotEqual(before, after)
        XCTAssertLessThan(before, after)
        XCTAssertEqual(before.daysBetween(after, calendar: cal), 1)
    }

    /// The reason DayKey exists: a DST "spring forward" day is 23 hours long, so
    /// dividing an interval by 86400 would report 0 days between consecutive days.
    func testDSTTransitionStillCountsAsOneDay() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        // 2026-03-08 is US spring-forward; that local day is only 23 hours long.
        let before = DayKey(date("2026-03-08T12:00:00-05:00", cal), calendar: cal)
        let after = DayKey(date("2026-03-09T12:00:00-04:00", cal), calendar: cal)
        XCTAssertEqual(before.raw, "2026-03-08")
        XCTAssertEqual(after.raw, "2026-03-09")
        XCTAssertEqual(before.daysBetween(after, calendar: cal), 1)
    }

    func testGapOfMoreThanOneDay() {
        let cal = seoul()
        let a = DayKey(date("2026-08-01T10:00:00+09:00", cal), calendar: cal)
        let b = DayKey(date("2026-08-05T10:00:00+09:00", cal), calendar: cal)
        XCTAssertEqual(a.daysBetween(b, calendar: cal), 4)
        XCTAssertEqual(b.daysBetween(a, calendar: cal), -4)
    }

    func testRoundTripsThroughCodableAndRawString() throws {
        let cal = seoul()
        let key = DayKey(date("2026-08-03T09:00:00+09:00", cal), calendar: cal)
        let decoded = try JSONDecoder().decode(DayKey.self,
                                               from: JSONEncoder().encode(key))
        XCTAssertEqual(decoded, key)
        XCTAssertEqual(DayKey(raw: "2026-08-03"), key)
        XCTAssertNil(DayKey(raw: "not-a-day"))
        XCTAssertNil(DayKey(raw: "2026-13-01"))
    }
}
