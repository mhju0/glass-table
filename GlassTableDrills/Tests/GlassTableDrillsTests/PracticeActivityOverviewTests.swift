import Foundation
import Testing
@testable import GlassTableDrills

struct PracticeActivityOverviewTests {
    private func calendar(_ zone: String = "Asia/Seoul") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private func row(_ day: String, concept: String = "outs", mode: String = "path",
                     version: Int = 1, language: String = "ko", assisted: Bool = false,
                     exact: Int = 1, near: Int = 0, miss: Int = 0) -> DailyPracticeSummary {
        var row = DailyPracticeSummary(key: DailyPracticeKey(
            day: DayKey(raw: day)!, concept: concept, mode: mode,
            formatVersion: version, language: language, assisted: assisted))
        row.exact = exact; row.near = near; row.miss = miss
        return row
    }

    private func overview(_ rows: [DailyPracticeSummary]) -> PracticeActivityOverview {
        PracticeActivityOverview(state: ProgressState(dailySummaries: rows),
                                 now: date("2026-10-06T12:00:00+09:00"), calendar: calendar())
    }

    @Test func emptyHistoryHasSevenOrderedUnrecordedDates() {
        let result = overview([])
        #expect(result.today.raw == "2026-10-06")
        #expect(result.last7.map(\.day.raw) == ["2026-09-30", "2026-10-01", "2026-10-02",
                                                  "2026-10-03", "2026-10-04", "2026-10-05", "2026-10-06"])
        #expect(result.last7.filter(\.isToday).map(\.day) == [result.today])
        #expect(result.last7.allSatisfy { !$0.isRecorded })
        #expect(result.distinctRecentDayCount == 0)
        #expect(result.todayAnswerCount == 0)
        #expect(result.consecutivePracticeDays == 0)
        #expect(!result.todayFlameBool)
        #expect(result.recentTopics.isEmpty)
    }

    @Test func mixesLanguageModeFormatAndHelpWithoutDuplicatingDates() {
        let result = overview([
            row("2026-10-06", exact: 2),
            row("2026-10-06", mode: "single-skill", version: 2, language: "en", assisted: true,
                exact: 0, miss: 3),
            row("2026-10-06", mode: "review", exact: 0, near: 1),
            row("2026-10-05", exact: 0, miss: 1),
        ])
        #expect(result.todayAnswerCount == 6)
        #expect(result.distinctRecentDayCount == 2)
        #expect(result.consecutivePracticeDays == 2)
        #expect(result.recentTopics.map(\.concept) == [.outs])
    }

    @Test func zeroFutureAndUnsupportedModesDoNotGrantPractice() {
        let result = overview([
            row("2026-10-06", exact: 0), row("2026-10-07", exact: 100),
            row("2026-10-06", mode: "free-play"), row("2026-10-06", mode: "table"),
            row("2026-10-06", mode: "guided"), row("2026-10-06", mode: "future-mode"),
            row("2026-10-05", concept: "potMath"),
        ])
        #expect(result.todayAnswerCount == 0)
        #expect(result.distinctRecentDayCount == 1)
        #expect(result.consecutivePracticeDays == 0)
        #expect(!result.todayFlameBool)
        #expect(result.recentTopics.map(\.concept) == [.potMath])
    }

    @Test func genericLegacyPracticeRemainsRecordedActivity() {
        let result = overview([row("2026-10-06", mode: "practice", exact: 0, miss: 2)])
        #expect(result.todayAnswerCount == 2)
        #expect(result.distinctRecentDayCount == 1)
        #expect(result.consecutivePracticeDays == 1)
        #expect(result.recentTopics.map(\.concept) == [.outs])
    }

    @Test func flameRequiresFourConsecutiveDatesEndingToday() {
        let four = (3...6).map { row("2026-10-0\($0)", exact: 0, miss: 1) }
        #expect(overview(four).todayFlameBool)
        #expect(overview(Array(four.dropFirst())).consecutivePracticeDays == 3)
        #expect(!overview(Array(four.dropFirst())).todayFlameBool)
        #expect(overview(Array(four.dropLast())).consecutivePracticeDays == 0)
        #expect(!overview(Array(four.dropLast())).todayFlameBool)
    }

    @Test func sparsePracticeDoesNotBecomeAConsecutiveRun() {
        let result = overview([row("2026-09-30"), row("2026-10-02"),
                               row("2026-10-04"), row("2026-10-06")])
        #expect(result.distinctRecentDayCount == 4)
        #expect(result.consecutivePracticeDays == 1)
        #expect(!result.todayFlameBool)
    }

    @Test func consecutiveRunCanExtendBeyondSevenDays() {
        let rows = (27...30).map { row("2026-09-\($0)") }
            + (1...6).map { row("2026-10-0\($0)") }
        let result = overview(rows)
        #expect(result.distinctRecentDayCount == 7)
        #expect(result.consecutivePracticeDays == 10)
        #expect(result.todayFlameBool)
    }

    @Test func topicDatesAreLatestEligibleDayWithStableTies() {
        let rows = [row("2026-10-01", concept: "outs"), row("2026-10-06", concept: "outs"),
                    row("2026-10-06", concept: "potMath"), row("2026-10-05", concept: "showdown"),
                    row("2026-10-07", concept: "showdown"), row("2026-10-06", concept: "mdf", exact: 0),
                    row("2026-10-06", concept: "retired-topic")]
        let result = overview(rows)
        #expect(result.recentTopics.map(\.concept) == [.outs, .potMath, .showdown])
        #expect(result.recentTopics.map(\.lastPracticedDay.raw) == ["2026-10-06", "2026-10-06", "2026-10-05"])
        #expect(overview(rows.reversed()).recentTopics == result.recentTopics)
    }

    @Test func lessonCompletionUsesOnlyActualTrackLessonFlagsIncludingLegacyClears() {
        var state = ProgressState(nodes: [
            "u1-showdown": NodeRecord(cleared: true),
            "u1-potMath": NodeRecord(cleared: false, attempts: 10),
            "u3-boss": NodeRecord(cleared: true),
            "u1-combos": NodeRecord(cleared: true),
            "u5-hitFrequency": NodeRecord(cleared: true),
            "retired-node": NodeRecord(cleared: true),
        ])
        state.dailySummaries = [row("2026-10-06", concept: "potMath", exact: 100)]
        let result = PracticeActivityOverview(state: state, now: date("2026-10-06T12:00:00+09:00"),
                                              calendar: calendar())
        #expect(result.mainCourseCompletedLessons == 1)
        #expect(result.mainCourseLessonCount == 10)
        #expect(result.deeperCompletedLessons == 1)
        #expect(result.deeperLessonCount == 3)
        #expect(state.nodes["u1-showdown"]?.clearedAt == nil)
    }

    @Test(arguments: ["2026-03-09T12:00:00-04:00", "2026-11-02T12:00:00-05:00"])
    func calendarDaysSurviveBothDSTTransitions(instant: String) {
        let cal = calendar("America/New_York")
        let now = date(instant)
        let rows = (0...9).map { offset in
            row(DayKey(cal.date(byAdding: .day, value: -offset, to: now)!, calendar: cal).raw)
        }
        let result = PracticeActivityOverview(state: ProgressState(dailySummaries: rows), now: now, calendar: cal)
        #expect(result.last7.count == 7)
        #expect(Set(result.last7.map(\.day)).count == 7)
        #expect(result.distinctRecentDayCount == 7)
        #expect(result.consecutivePracticeDays == 10)
        for pair in zip(result.last7, result.last7.dropFirst()) {
            #expect(pair.0.day.daysBetween(pair.1.day, calendar: cal) == 1)
        }
    }

    @Test func midnightRefreshAndTimeZoneUseRawHistoricalDates() {
        let state = ProgressState(dailySummaries: [row("2026-10-06")])
        let before = PracticeActivityOverview(state: state, now: date("2026-10-06T23:59:59+09:00"), calendar: calendar())
        let after = PracticeActivityOverview(state: state, now: date("2026-10-07T00:00:01+09:00"), calendar: calendar())
        #expect(before.todayAnswerCount == 1)
        #expect(after.todayAnswerCount == 0)
        #expect(after.consecutivePracticeDays == 0)
        #expect(after.last7[5].isRecorded)
        let inNewYork = PracticeActivityOverview(state: state, now: date("2026-10-06T00:00:01+09:00"),
                                                calendar: calendar("America/New_York"))
        #expect(inNewYork.today.raw == "2026-10-05")
        #expect(inNewYork.distinctRecentDayCount == 0)
        #expect(state.dailySummaries.first?.key.day.raw == "2026-10-06")
    }

    @Test func guidedActiveAnswersAndRecentEvidenceCannotFillMissingDailyRows() throws {
        let now = date("2026-10-06T12:00:00+09:00")
        let answer = RoundAnswer(attemptID: "unsaved", ordinal: 0, band: .spotOn,
                                 submittedAt: now, input: Data(), reveal: Data())
        var round = PracticeRound(id: "active", concept: "outs", seed: 1, introPhase: .together)
        round.guidedAnswer = answer
        round.answers = [answer]
        let key = row("2026-10-06").key
        let evidence = PracticeEvidence(attemptID: "detail-only", key: key, at: now,
                                        band: .spotOn, eligibleCorrectSeconds: nil, decisionLossBB: nil)
        let state = ProgressState(nodes: ["u1-showdown": NodeRecord(cleared: true)],
                                  activeRound: round, recentEvidence: [evidence])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(state)
        let result = PracticeActivityOverview(state: state, now: now, calendar: calendar())
        #expect(result.todayAnswerCount == 0)
        #expect(result.distinctRecentDayCount == 0)
        #expect(result.recentTopics.isEmpty)
        #expect(try encoder.encode(state) == before)
    }

    @Test func freeTableHistoryAloneDoesNotGrantLearningActivity() {
        let state = ProgressState(recentHands: [PracticeHandObservation(
            handID: "table-only", day: "2026-10-06", voluntarilyEntered: true, raisedPreflop: true)])
        let result = PracticeActivityOverview(state: state, now: date("2026-10-06T12:00:00+09:00"),
                                              calendar: calendar())
        #expect(result.todayAnswerCount == 0)
        #expect(result.distinctRecentDayCount == 0)
        #expect(result.consecutivePracticeDays == 0)
        #expect(result.recentTopics.isEmpty)
    }

    @Test func derivingActivityPreservesEncodedPastFutureAndLegacyState() throws {
        let state = ProgressState(schemaVersion: 2,
                                  nodes: ["u1-showdown": NodeRecord(cleared: true)],
                                  dailySummaries: [row("2026-10-05", assisted: true, exact: 0, miss: 2),
                                                   row("2026-10-06", version: 2, language: "en"),
                                                   row("2026-10-07", exact: 10),
                                                   row("2026-10-06", mode: "future-mode")])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(state)
        let result = PracticeActivityOverview(state: state, now: date("2026-10-06T12:00:00+09:00"),
                                              calendar: calendar())
        #expect(result.todayAnswerCount == 1)
        #expect(result.mainCourseCompletedLessons == 1)
        #expect(try encoder.encode(state) == before)
        #expect(try JSONDecoder().decode(ProgressState.self, from: before) == state)
    }
}
