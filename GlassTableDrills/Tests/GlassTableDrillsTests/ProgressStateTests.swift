import XCTest
@testable import GlassTableDrills

final class ProgressStateTests: XCTestCase {
    func testEmptyStateHasCurrentSchemaVersionAndNoRecords() {
        let s = ProgressState()
        XCTAssertEqual(s.schemaVersion, ProgressState.currentSchemaVersion)
        XCTAssertEqual(s.schemaVersion, 2)
        XCTAssertTrue(s.concepts.isEmpty)
        XCTAssertTrue(s.nodes.isEmpty)
        XCTAssertTrue(s.answers.isEmpty)
        XCTAssertNil(s.firstLessonCompleted)
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
        s.firstLessonCompleted = true
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

    func testSchemaOneStateWithoutFirstLessonMarkerStillDecodes() throws {
        let json = Data(#"{"schemaVersion":1,"concepts":{},"nodes":{},"streak":{"current":0,"longest":0,"freezesRemaining":2},"answers":[]}"#.utf8)

        let state = try JSONDecoder().decode(ProgressState.self, from: json)

        XCTAssertNil(state.firstLessonCompleted)
        XCTAssertNil(state.basicsLessonCompleted)
        XCTAssertEqual(state.schemaVersion, 1)
    }

    func testBasicsLessonMarkerSurvivesEncoding() throws {
        var s = ProgressState()
        s.basicsLessonCompleted = true
        let data = try JSONEncoder().encode(s)
        XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("\"basicsLessonCompleted\":true"))
        XCTAssertEqual(try JSONDecoder().decode(ProgressState.self, from: data).basicsLessonCompleted, true)
    }

    func testOpeningSnapshotRoundTripPreservesSeedAndResponses() throws {
        var state = ProgressState()
        state.openingDismissed = true
        state.pendingFirstLesson = FirstLessonSnapshot(variationSeed: UInt64.max,
            step: .checkpoint, responses: [0: .choice(2), 1: .demonstrated])
        let decoded = try JSONDecoder().decode(ProgressState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(decoded, state)
        XCTAssertNil(decoded.firstLessonCompleted)
        XCTAssertEqual(decoded.schemaVersion, 2)
    }

    func testOldStatesDecodeWithoutInventingOpeningEvidence() throws {
        for schema in 1...2 {
            for marker in ["", ",\"firstLessonCompleted\":true"] {
                let json = Data("{\"schemaVersion\":\(schema),\"concepts\":{},\"nodes\":{},\"streak\":{\"current\":0,\"longest\":0,\"freezesRemaining\":2},\"answers\":[]\(marker)}".utf8)
                let decoded = try JSONDecoder().decode(ProgressState.self, from: json)
                XCTAssertNil(decoded.openingDismissed)
                XCTAssertNil(decoded.pendingFirstLesson)
                XCTAssertEqual(decoded.firstLessonCompleted, marker.isEmpty ? nil : true)
            }
        }
    }

    func testInvalidOpeningSnapshotsAreRejectedOnDecode() throws {
        let invalid = [
            FirstLessonSnapshot(variationSeed: 0, step: .exampleAnswer),
            FirstLessonSnapshot(variationSeed: 0, responses: [5: .demonstrated]),
            FirstLessonSnapshot(variationSeed: 0, responses: [0: .choice(3)]),
            FirstLessonSnapshot(variationSeed: 0, step: .checkpoint, responses: [0: .choice(0)]),
            FirstLessonSnapshot(variationSeed: 0, step: .wrapUp, responses: [0: .choice(0)])
        ]
        for snapshot in invalid {
            XCTAssertFalse(snapshot.isValid)
            let encoded = try JSONEncoder().encode(snapshot)
            XCTAssertThrowsError(try JSONDecoder().decode(FirstLessonSnapshot.self, from: encoded))
        }
    }

    func testOpeningStagesRequireTheirExploredPrefixAndAllowBackWithLaterResponses() throws {
        let stages: [(FirstLessonSnapshot.Step, Int)] = [
            (.welcome, 0), (.teachPair, 0), (.example, 0),
            (.exampleAnswer, 1), (.transfer, 1),
            (.transferAnswer, 2), (.checkpoint, 2), (.preference, 2), (.comparison0, 2),
            (.comparisonAnswer0, 3), (.comparison1, 3),
            (.comparisonAnswer1, 4), (.comparison2, 4),
            (.comparisonAnswer2, 5), (.actions, 5), (.wrapUp, 5),
            (.pot, 5), (.blinds, 5), (.flow, 5), (.bestFive, 5)
        ]
        let allResponses = Dictionary(uniqueKeysWithValues:
            (0..<5).map { ($0, FirstLessonSnapshot.Response.demonstrated) })
        for (step, requiredCount) in stages {
            let prefix = Dictionary(uniqueKeysWithValues:
                (0..<requiredCount).map { ($0, FirstLessonSnapshot.Response.choice(1)) })
            let valid = FirstLessonSnapshot(variationSeed: 9, step: step, responses: prefix)
            XCTAssertTrue(valid.isValid, "\(step) accepts its full prerequisite prefix")
            XCTAssertEqual(try JSONDecoder().decode(FirstLessonSnapshot.self,
                from: JSONEncoder().encode(valid)), valid)
            let backward = FirstLessonSnapshot(variationSeed: 9, step: step, responses: allResponses)
            XCTAssertTrue(backward.isValid, "\(step) preserves later responses on Back")
            XCTAssertEqual(try JSONDecoder().decode(FirstLessonSnapshot.self,
                from: JSONEncoder().encode(backward)), backward)
            for missing in 0..<requiredCount {
                var incomplete = backward
                incomplete.responses.removeValue(forKey: missing)
                XCTAssertFalse(incomplete.isValid, "\(step) must reject missing comparison \(missing)")
                let encoded = try JSONEncoder().encode(incomplete)
                XCTAssertThrowsError(try JSONDecoder().decode(FirstLessonSnapshot.self, from: encoded))
            }
        }
    }

    func testOpeningActionTrapCannotBeImportedEvenWithHistoricalRecords() throws {
        let store = ProgressionStore(url: URL(fileURLWithPath: "/unused-opening-import.json"))
        for step in [FirstLessonSnapshot.Step.actions, .pot, .blinds, .flow, .bestFive] {
            var invalid = ProgressState(firstLessonCompleted: true)
            invalid.nodes["retired-node"] = NodeRecord(cleared: true, attempts: 3)
            invalid.pendingFirstLesson = FirstLessonSnapshot(variationSeed: 17, step: step,
                responses: [0: .choice(0), 1: .demonstrated])
            XCTAssertThrowsError(try store.importData(JSONEncoder().encode(invalid)))
        }
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
          "nodes": {
            "retired-node": {"cleared":true,"attempts":3,"clearedAt":1000}
          },
          "streak": {"current":0,"longest":0,"freezesRemaining":2},
          "answers": []
        }
        """.utf8)
        let s = try JSONDecoder().decode(ProgressState.self, from: json)
        XCTAssertEqual(s.record(for: .outs).tier, .familiar)
        XCTAssertEqual(s.concepts.count, 2)                 // the unknown key is preserved
        XCTAssertNotNil(s.concepts["someRetiredConcept"])
        XCTAssertEqual(s.nodes["retired-node"]?.attempts, 3)

        let roundTripped = try JSONDecoder().decode(
            ProgressState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(roundTripped, s)
        XCTAssertEqual(roundTripped.concepts["someRetiredConcept"]?.tier, .mastered)
        XCTAssertEqual(roundTripped.nodes["retired-node"]?.clearedAt,
                       Date(timeIntervalSinceReferenceDate: 1000))
    }
}
