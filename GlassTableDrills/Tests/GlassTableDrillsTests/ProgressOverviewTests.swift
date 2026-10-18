// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Testing
import GlassTableEngine
@testable import GlassTableDrills

/// The Progress tab reads only saved state. Its headline numbers only grow, its week
/// line starts again each Monday, and nothing it shows is a zero streak.
struct ProgressOverviewTests {
    private func calendar(_ zone: String = "Asia/Seoul", firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    /// Sunday 2026-10-18, noon in Seoul. The week started on Monday 2026-10-12.
    private let sunday = "2026-10-18T12:00:00+09:00"

    private func row(_ day: String, concept: String = "outs", mode: String = "path",
                     assisted: Bool = false, exact: Int = 1, near: Int = 0,
                     miss: Int = 0) -> DailyPracticeSummary {
        var row = DailyPracticeSummary(key: DailyPracticeKey(
            day: DayKey(raw: day)!, concept: concept, mode: mode,
            formatVersion: 1, language: "ko", assisted: assisted))
        row.exact = exact; row.near = near; row.miss = miss
        return row
    }

    private func overview(_ state: ProgressState, at instant: String? = nil,
                          calendar: Calendar? = nil) -> ProgressOverview {
        ProgressOverview(state: state, now: date(instant ?? sunday), calendar: calendar ?? self.calendar())
    }

    private func record(_ tier: MasteryTier, total: Int = 5, proficientAt: Date? = nil,
                        masteredAt: Date? = nil, due: Date? = nil) -> ConceptRecord {
        var r = ConceptRecord(tier: tier, total: total, proficientAt: proficientAt, masteredAt: masteredAt)
        if let due {
            r.review = ReviewState(stability: 3, difficulty: 5,
                                   lastReview: due.addingTimeInterval(-86_400 * 3), due: due, reps: 2)
        }
        return r
    }

    // MARK: decisions studied

    @Test func decisionsCountEverySummaryIncludingHelpWrongAndEveryMode() {
        let state = ProgressState(dailySummaries: [
            row("2026-10-18", exact: 2),
            row("2026-10-18", mode: "single-skill", assisted: true, exact: 0, miss: 3),
            row("2026-10-17", mode: "review", exact: 0, near: 1),
            row("2026-09-01", mode: "practice", miss: 4),
        ])
        #expect(overview(state).decisionsStudied == 2 + 3 + 1 + 5)
    }

    @Test func decisionsNeverComeFromTheCappedAnswerLog() {
        var state = ProgressState()
        for i in 0..<ProgressState.answerLogCap {
            state.append(AnswerRecord(concept: .outs, at: date(sunday).addingTimeInterval(-Double(i)),
                                      correct: true))
        }
        state.updateRecord(for: .outs) { $0.total = 900 }
        #expect(overview(state).decisionsStudied == 0)
    }

    @Test func decisionsOnlyGrowAsAnswersAreRecorded() {
        var state = ProgressState(dailySummaries: [row("2026-10-12", exact: 3)])
        var last = overview(state).decisionsStudied
        let bands: [GradeBand] = [.off, .spotOn, .close, .off]
        for (i, band) in bands.enumerated() {
            let key = row("2026-10-18", assisted: i.isMultiple(of: 2)).key
            state.recordDetailedAttempt(PracticeEvidence(attemptID: "a\(i)", key: key, at: date(sunday),
                band: band, eligibleCorrectSeconds: nil, decisionLossBB: nil))
            let now = overview(state).decisionsStudied
            #expect(now == last + 1)
            last = now
        }
    }

    // MARK: skills at Strong

    @Test func strongCountsOnlyTheCurriculumSkills() {
        var state = ProgressState()
        for retired in [Concept.mdf, .evLoss, .hitFrequency, .rangeAdvantage] {
            state.concepts[retired.rawValue] = record(.mastered)
        }
        state.concepts[Concept.outs.rawValue] = record(.proficient)
        state.concepts[Concept.showdown.rawValue] = record(.mastered)
        state.concepts[Concept.combos.rawValue] = record(.proficient)     // Go deeper
        state.concepts[Concept.potMath.rawValue] = record(.familiar)
        let result = overview(state)
        #expect(Curriculum.skills.count == 14)
        #expect(Set(Curriculum.skills).count == 14)
        #expect(!Curriculum.skills.contains(.mdf) && !Curriculum.skills.contains(.evLoss))
        #expect(result.skillCount == 14)
        #expect(result.strongSkills == 3)
        #expect(result.masteredSkills == 1)
        #expect(ProgressOverview.strongCount(in: state) == 3)
    }

    @Test func strongNeverDropsAfterALaterRoughSession() {
        var state = ProgressState()
        state.updateRecord(for: .outs) {
            $0.total = 5; $0.correct = 5
            Mastery.promote(&$0, evidence: SessionEvidence(attempted: 3, spotOn: 3), viaBoss: false,
                            now: date(sunday))
        }
        #expect(overview(state).strongSkills == 1)
        state.updateRecord(for: .outs) {
            $0.total = 20
            Mastery.promote(&$0, evidence: SessionEvidence(attempted: 3, spotOn: 0), viaBoss: false,
                            now: date(sunday))
        }
        #expect(overview(state).strongSkills == 1)
    }

    // MARK: this week

    @Test func weekCountsDistinctDaysSinceMondayAndIgnoresEmptyAndFutureRows() {
        let state = ProgressState(dailySummaries: [
            row("2026-10-11"),                                // last Sunday: last week
            row("2026-10-12"),                                // Monday
            row("2026-10-14"), row("2026-10-14", mode: "review", assisted: true, exact: 0, miss: 1),
            row("2026-10-15", exact: 0),                      // nothing answered
            row("2026-10-19", exact: 9),                      // a clock that ran ahead
        ])
        #expect(overview(state).daysThisWeek == 2)
    }

    @Test func weekStartsOnMondayWhateverTheLocaleWeekStart() {
        let state = ProgressState(dailySummaries: [row("2026-10-12"), row("2026-10-18")])
        for firstWeekday in 1...7 {
            #expect(overview(state, calendar: calendar(firstWeekday: firstWeekday)).daysThisWeek == 2)
        }
    }

    @Test func mondayIsAFreshStart() {
        let state = ProgressState(dailySummaries: (12...18).map { row("2026-10-\($0)") })
        #expect(overview(state).daysThisWeek == 7)
        #expect(overview(state, at: "2026-10-19T08:00:00+09:00").daysThisWeek == 0)
        #expect(overview(state, at: "2026-10-19T08:00:00+09:00").decisionsStudied == 7)
    }

    // MARK: time away

    @Test func daysAwayReadsTheLatestPractisedDay() {
        let away = ProgressState(dailySummaries: [row("2026-10-01"), row("2026-10-08")])
        #expect(overview(away).daysAway == 10)
        #expect(overview(away).isReturning)
        let recent = ProgressState(dailySummaries: [row("2026-10-16")])
        #expect(overview(recent).daysAway == 2)
        #expect(!overview(recent).isReturning)
        let today = ProgressState(dailySummaries: [row("2026-10-08"), row("2026-10-18")])
        #expect(overview(today).daysAway == 0)
        #expect(!overview(today).isReturning)
        #expect(overview(ProgressState()).daysAway == nil)
        #expect(!overview(ProgressState()).isReturning)
    }

    @Test func historyIsAnySavedPracticeOrStage() {
        #expect(!overview(ProgressState()).hasHistory)
        #expect(overview(ProgressState(dailySummaries: [row("2026-10-18")])).hasHistory)
        var legacy = ProgressState()
        legacy.concepts[Concept.showdown.rawValue] = record(.familiar)
        #expect(overview(legacy).hasHistory)
    }

    // MARK: skill bars

    @Test func skillsSortStrongestFirstThenInPathOrderAndMarkDueOnes() {
        let now = date(sunday)
        var state = ProgressState()
        state.concepts[Concept.potMath.rawValue] = record(.proficient, due: now.addingTimeInterval(-3600))
        state.concepts[Concept.showdown.rawValue] = record(.mastered, due: now.addingTimeInterval(86_400))
        state.concepts[Concept.outs.rawValue] = record(.proficient)
        state.concepts[Concept.rangeRead.rawValue] = record(.attempted)
        state.concepts[Concept.combos.rawValue] = record(.familiar)
        state.concepts[Concept.mdf.rawValue] = record(.mastered)
        let result = overview(state)
        #expect(result.skills.count == 14)
        #expect(Array(result.skills.prefix(5).map(\.concept)) == [.showdown, .outs, .potMath, .combos, .rangeRead])
        #expect(result.skills.map(\.stage).prefix(6) == [4, 3, 3, 2, 1, 0])
        #expect(result.skills.first { $0.concept == .potMath }?.isDue == true)
        #expect(result.skills.first { $0.concept == .showdown }?.isDue == false)
        #expect(result.skills.first { $0.concept == .combos }?.isOptional == true)
        #expect(result.skills.first { $0.concept == .outs }?.isOptional == false)
        #expect(result.due == [.potMath])
        #expect(result.skills.allSatisfy { $0.stageCount == 4 })
        #expect(!result.skills.contains { $0.concept == .mdf })
    }

    // MARK: journal

    @Test func journalIsDerivedFromSavedDatesNewestFirst() {
        let day = { (d: Int, h: Int) in self.date(String(format: "2026-10-%02dT%02d:00:00+09:00", d, h)) }
        var state = ProgressState()
        state.concepts[Concept.showdown.rawValue] = record(.mastered, proficientAt: day(5, 10), masteredAt: day(14, 9))
        state.concepts[Concept.outs.rawValue] = record(.proficient, proficientAt: day(17, 20))
        state.concepts[Concept.mdf.rawValue] = record(.mastered, proficientAt: day(1, 9), masteredAt: day(2, 9))
        state.nodes["u1-boss"] = NodeRecord(cleared: true, clearedAt: day(9, 15), attempts: 1)
        state.nodes["u3-boss"] = NodeRecord(cleared: false, attempts: 2)
        state.dailySummaries = [row("2026-10-03", exact: 60), row("2026-10-11", exact: 50),
                                row("2026-10-16", exact: 150), row("2026-10-18", exact: 152)]
        let result = overview(state)
        #expect(result.decisionsStudied == 412)
        #expect(result.journal == [
            .init(day: DayKey(raw: "2026-10-16")!, milestone: .decisions(250)),
            .init(day: DayKey(raw: "2026-10-14")!, milestone: .mastered(.showdown)),
            .init(day: DayKey(raw: "2026-10-11")!, milestone: .decisions(100)),
            .init(day: DayKey(raw: "2026-10-09")!, milestone: .trackPassed(.basics)),
            .init(day: DayKey(raw: "2026-10-05")!, milestone: .firstStrong(.showdown)),
        ])
        #expect(result.nextDecisionMilestone == 500)
    }

    @Test func journalSkipsUndatedStagesAndStopsAtTheLastDecisionMilestone() {
        var state = ProgressState()
        state.concepts[Concept.outs.rawValue] = record(.mastered)      // legacy: no dates
        state.dailySummaries = [row("2026-10-18", exact: 1_200)]
        let result = overview(state)
        #expect(result.journal.map(\.milestone) == [.decisions(1_000), .decisions(500),
                                                     .decisions(250), .decisions(100)])
        #expect(result.nextDecisionMilestone == nil)
        #expect(overview(ProgressState()).nextDecisionMilestone == 100)
    }

    @Test func readingTheOverviewDoesNotChangeSavedState() throws {
        var state = ProgressState(dailySummaries: [row("2026-10-12"), row("2026-10-19")])
        state.concepts[Concept.outs.rawValue] = record(.proficient, proficientAt: date(sunday))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(state)
        _ = overview(state)
        #expect(try encoder.encode(state) == before)
    }
}
