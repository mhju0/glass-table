import XCTest
import UserNotifications
import GlassTableEngine
import GlassTableDrills
@testable import GlassTable

final class MilestoneTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func finishedSession(_ nodeID: String, concepts: [Concept],
                                 answeredFrom start: Date) -> NodeSessionSnapshot {
        var session = NodeSessionSnapshot(id: "s", nodeID: nodeID, seed: 1,
            scheduledConcepts: concepts.map(\.rawValue), phase: .finished)
        session.answers = concepts.enumerated().map { index, concept in
            NodeGradedAnswer(concept: concept.rawValue, answer: RoundAnswer(
                attemptID: "a\(index)", ordinal: index, band: .spotOn,
                submittedAt: start.addingTimeInterval(Double(index) * 10),
                input: Data([1]), reveal: Data([1])))
        }
        return session
    }

    func testFirstClearOfAUnitsLastNodeIsAMilestoneButARerunIsNot() {
        let boss = Curriculum.units[0].nodes.last!
        let session = finishedSession(boss.id, concepts: [.showdown, .potMath],
                                      answeredFrom: start)
        var state = ProgressState()
        state.nodes[boss.id] = NodeRecord(cleared: true, clearedAt: start.addingTimeInterval(10),
                                          attempts: 1)
        XCTAssertEqual(LearningMilestone.reached(in: session, state: state),
                       [.unitFinished(unitIndex: 0)])

        state.nodes[boss.id]?.clearedAt = start.addingTimeInterval(-86_400)
        XCTAssertEqual(LearningMilestone.reached(in: session, state: state), [])
    }

    func testOrdinaryLessonClearIsNotAMilestone() {
        let lesson = Curriculum.units[0].nodes[0]
        let session = finishedSession(lesson.id, concepts: [.showdown], answeredFrom: start)
        var state = ProgressState()
        state.nodes[lesson.id] = NodeRecord(cleared: true, clearedAt: start, attempts: 1)
        XCTAssertEqual(LearningMilestone.reached(in: session, state: state), [])
    }

    func testMasteryReachedInThisSessionCountsOnceAndOlderMasteryDoesNot() {
        let boss = Curriculum.units[0].nodes.last!
        let session = finishedSession(boss.id, concepts: [.showdown, .showdown, .combos],
                                      answeredFrom: start)
        var state = ProgressState()
        state.updateRecord(for: .showdown) { $0.masteredAt = self.start.addingTimeInterval(20) }
        state.updateRecord(for: .combos) { $0.masteredAt = self.start.addingTimeInterval(-60) }
        XCTAssertEqual(LearningMilestone.reached(in: session, state: state),
                       [.skillMastered(.showdown)])
    }

    func testUnfinishedOrUnansweredSessionHasNoMilestone() {
        let boss = Curriculum.units[0].nodes.last!
        var state = ProgressState()
        state.nodes[boss.id] = NodeRecord(cleared: true, clearedAt: start, attempts: 1)
        var session = finishedSession(boss.id, concepts: [.showdown], answeredFrom: start)
        session.phase = .reveal
        XCTAssertEqual(LearningMilestone.reached(in: session, state: state), [])
        session.phase = .finished
        session.answers = []
        XCTAssertEqual(LearningMilestone.reached(in: session, state: state), [])
    }

    func testEveryUnitHasAnEnglishTitle() {
        XCTAssertEqual(LearningMilestone.unitTitlesEnglish.count, Curriculum.units.count)
    }

    func testRatingAsksOncePerVersionOnlyAfterAMilestoneAndNeverInUITests() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MilestoneTests-\(UUID())"))
        let milestone: [LearningMilestone] = [.unitFinished(unitIndex: 0)]
        XCTAssertFalse(RatingPrompt.shouldRequest(milestones: [], version: "1.0",
                                                  defaults: defaults, environment: [:]))
        XCTAssertFalse(RatingPrompt.shouldRequest(milestones: milestone, version: "1.0",
            defaults: defaults, environment: ["GT_TEST_STORE_ID": UUID().uuidString]))
        XCTAssertTrue(RatingPrompt.shouldRequest(milestones: milestone, version: "1.0",
                                                 defaults: defaults, environment: [:]))
        RatingPrompt.markRequested(version: "1.0", defaults: defaults)
        XCTAssertFalse(RatingPrompt.shouldRequest(milestones: milestone, version: "1.0",
                                                  defaults: defaults, environment: [:]))
        XCTAssertTrue(RatingPrompt.shouldRequest(milestones: milestone, version: "1.1",
                                                 defaults: defaults, environment: [:]))
    }

    func testReminderRepeatsDailyAtTheChosenTimeInEitherLanguage() throws {
        let korean = DailyReminder.request(minutes: 7 * 60 + 30, language: .korean)
        XCTAssertEqual(korean.identifier, DailyReminder.identifier)
        let trigger = try XCTUnwrap(korean.trigger as? UNCalendarNotificationTrigger)
        XCTAssertTrue(trigger.repeats)
        XCTAssertEqual(trigger.dateComponents.hour, 7)
        XCTAssertEqual(trigger.dateComponents.minute, 30)
        XCTAssertNil(trigger.dateComponents.day)
        XCTAssertTrue(korean.content.body.contains("테이블"))
        let english = DailyReminder.request(minutes: DailyReminder.defaultMinutes, language: .english)
        XCTAssertEqual(english.content.body, "Your table is ready. A few minutes is plenty.")
        XCTAssertEqual((english.trigger as? UNCalendarNotificationTrigger)?.dateComponents.hour, 20)
    }
}
