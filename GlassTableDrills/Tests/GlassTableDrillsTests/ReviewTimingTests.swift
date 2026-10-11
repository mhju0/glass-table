import XCTest
@testable import GlassTableDrills

final class ReviewTimingTests: XCTestCase {
    private func calendar(_ zone: String) -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: zone)!
        return result
    }

    private func instant(_ raw: String) -> Date { ISO8601DateFormatter().date(from: raw)! }

    func testOnlyAnExactDueInstantOrPastInstantSaysReviewNow() {
        let due = instant("2026-10-11T06:00:00Z")
        for language in LearningLanguage.allCases {
            let before = ReviewTiming.text(due: due, now: due.addingTimeInterval(-0.001), language: language)
            XCTAssertNotEqual(before, language.text("지금 복습", "review now"))
            for offset in [0.0, 0.001, 86_400] {
                XCTAssertEqual(ReviewTiming.text(due: due, now: due.addingTimeInterval(offset), language: language),
                               language.text("지금 복습", "review now"))
            }
        }
    }

    func testFutureLabelsUseCalendarDaysAcrossTimezones() {
        let now = instant("2026-10-11T14:00:00Z")
        let due = instant("2026-10-11T20:00:00Z")
        XCTAssertEqual(ReviewTiming.text(due: due, now: now, calendar: calendar("Asia/Seoul"), language: .english),
                       "review tomorrow")
        XCTAssertEqual(ReviewTiming.text(due: due, now: now, calendar: calendar("America/Los_Angeles"), language: .english),
                       "review later today")
        XCTAssertEqual(ReviewTiming.text(due: due, now: now, calendar: calendar("Asia/Seoul"), language: .korean),
                       "내일 복습")
    }

    func testReviewLabelAndQueueAgreeAtTheExactBoundary() {
        let due = instant("2026-10-11T06:00:00Z")
        var state = ProgressState()
        state.updateRecord(for: .potOdds) {
            $0.total = 5
            $0.correct = 4
            $0.review.due = due
        }
        let original = state.concepts
        for offset in [-0.001, 0, 0.001] {
            let now = due.addingTimeInterval(offset)
            let queued = ReviewQueue.dueConcepts(in: state, at: now).contains(.potOdds)
            XCTAssertEqual(ReviewTiming.text(due: due, now: now, language: .english) == "review now", queued)
            XCTAssertEqual(state.concepts, original)
        }
    }

    func testDSTDoesNotTurnTomorrowIntoTodayOrTwoDaysAway() {
        let cal = calendar("America/New_York")
        // Spring's consecutive noons are 23h apart; fall's are 25h apart.
        for (now, due) in [("2026-03-07T17:00:00Z", "2026-03-08T16:00:00Z"),
                           ("2026-10-31T16:00:00Z", "2026-11-01T17:00:00Z")] {
            XCTAssertEqual(ReviewTiming.text(due: instant(due), now: instant(now), calendar: cal, language: .english),
                           "review tomorrow")
        }
    }

    func testMoreDistantReviewUsesLocalizedFutureDate() {
        let now = instant("2026-10-11T14:00:00Z")
        let due = instant("2026-10-13T20:00:00Z")
        let cal = calendar("Asia/Seoul")
        XCTAssertEqual(ReviewTiming.text(due: due, now: now, calendar: cal, language: .english),
                       "review on Oct 14, 2026")
        XCTAssertEqual(ReviewTiming.text(due: due, now: now, calendar: cal, language: .korean),
                       "2026. 10. 14. 복습")
    }
}
