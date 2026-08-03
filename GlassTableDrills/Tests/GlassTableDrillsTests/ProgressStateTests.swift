import XCTest
@testable import GlassTableDrills

final class ProgressStateTests: XCTestCase {
    func testEmptyStateHasCurrentSchemaVersionAndNoRecords() {
        let s = ProgressState()
        XCTAssertEqual(s.schemaVersion, ProgressState.currentSchemaVersion)
        XCTAssertEqual(s.schemaVersion, 1)
        XCTAssertTrue(s.concepts.isEmpty)
        XCTAssertTrue(s.nodes.isEmpty)
        XCTAssertTrue(s.answers.isEmpty)
        XCTAssertEqual(s.streak.current, 0)
        XCTAssertEqual(s.streak.freezesRemaining, 2)   // spec §7.1: two auto freezes
    }

    /// An untouched concept reads as a default record rather than nil, so callers
    /// never branch on "has this been seen" just to read a count.
    func testUntouchedConceptReadsAsDefaultRecord() {
        let s = ProgressState()
        XCTAssertEqual(s.record(for: .outs), ConceptRecord())
        XCTAssertEqual(s.record(for: .outs).tier, .attempted)
        XCTAssertEqual(s.record(for: .outs).total, 0)
    }

    func testUpdateRecordWritesThrough() {
        var s = ProgressState()
        s.updateRecord(for: .outs) { $0.total = 4; $0.correct = 3 }
        XCTAssertEqual(s.record(for: .outs).total, 4)
        XCTAssertEqual(s.record(for: .outs).correct, 3)
        XCTAssertEqual(s.concepts["outs"]?.total, 4)
    }

    func testAnswerLogIsACappedRingBufferKeepingTheNewest() {
        var s = ProgressState()
        for i in 0..<(ProgressState.answerLogCap + 50) {
            s.append(AnswerRecord(concept: .outs,
                                  at: Date(timeIntervalSince1970: Double(i)),
                                  correct: true))
        }
        XCTAssertEqual(s.answers.count, ProgressState.answerLogCap)
        // Oldest dropped, newest kept, order preserved.
        XCTAssertEqual(s.answers.first?.at, Date(timeIntervalSince1970: 50))
        XCTAssertEqual(s.answers.last?.at,
                       Date(timeIntervalSince1970: Double(ProgressState.answerLogCap + 49)))
    }

    func testRoundTripsThroughCodable() throws {
        var s = ProgressState()
        s.updateRecord(for: .equitySense) {
            $0.tier = .proficient
            $0.total = 12; $0.correct = 10; $0.consecutiveMisses = 1
            $0.review.stability = 4.5; $0.review.difficulty = 6.0; $0.review.reps = 3
        }
        s.nodes["u1-position"] = NodeRecord(cleared: true, attempts: 2)
        s.streak.current = 12
        s.append(AnswerRecord(concept: .equitySense, at: Date(timeIntervalSince1970: 1),
                              correct: false,
                              interval: IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 52)))
        let decoded = try JSONDecoder().decode(
            ProgressState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(decoded, s)
    }

    func testIntervalKnowsWhetherItContainedTheTruth() {
        XCTAssertTrue(IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 44).containsTruth)
        XCTAssertTrue(IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 35).containsTruth)
        XCTAssertFalse(IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 52).containsTruth)
    }

    /// A concept removed in a future version must not make the whole store unreadable.
    func testUnknownConceptKeysSurviveDecodingAndAreIgnoredByTypedAccess() throws {
        let review = #"{"stability":0,"difficulty":5,"reps":0,"lapses":0}"#
        let json = Data("""
        {
          "schemaVersion": 1,
          "concepts": {
            "outs": {"tier":"familiar","review":\(review),
                     "correct":1,"total":2,"consecutiveMisses":0},
            "someRetiredConcept": {"tier":"mastered","review":\(review),
                     "correct":9,"total":9,"consecutiveMisses":0}
          },
          "nodes": {},
          "streak": {"current":0,"longest":0,"freezesRemaining":2},
          "answers": []
        }
        """.utf8)
        let s = try JSONDecoder().decode(ProgressState.self, from: json)
        XCTAssertEqual(s.record(for: .outs).tier, .familiar)
        XCTAssertEqual(s.concepts.count, 2)                 // the unknown key is preserved
        XCTAssertNotNil(s.concepts["someRetiredConcept"])
    }
}
