import XCTest
import GlassTableDrills
import GlassTableEngine
@testable import GlassTable

@MainActor
final class ProgressionModelTests: XCTestCase {
    private var dir: URL!
    private var store: ProgressionStore!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gt-model-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        store = ProgressionStore(url: dir.appendingPathComponent("progression.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testFreshProgressPresentsFirstLesson() {
        let model = ProgressionModel(store: store)

        XCTAssertTrue(model.shouldPresentFirstLesson)
    }

    func testRoundCommitAndNextAreDurableAndIdempotent() throws {
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        XCTAssertTrue(model.beginRound(concept: .showdown, seed: 77,
                                       roundID: "round-1", expectedEpoch: epoch))
        XCTAssertTrue(model.advanceRoundIntroduction(roundID: "round-1", skip: true,
            expectedEpoch: epoch))
        let winner = gradeShowdown(answer: 0,
            spot: ShowdownSpotGenerator.spot(baseSeed: 77, index: 2)).winner
        let input = try JSONEncoder().encode(SavedDrillInput.integer(winner))
        let reveal = try JSONEncoder().encode(SavedDrillReveal(band: "spotOn"))
        XCTAssertTrue(model.commitRoundAnswer(roundID: "round-1", attemptID: "attempt-1",
            ordinal: 0, band: .spotOn, language: "ko", assisted: false,
            input: input, reveal: reveal, eligibleSeconds: 3, expectedEpoch: epoch))
        XCTAssertTrue(model.commitRoundAnswer(roundID: "round-1", attemptID: "attempt-1",
            ordinal: 0, band: .spotOn, language: "ko", assisted: false,
            input: input, reveal: reveal, eligibleSeconds: 3, expectedEpoch: epoch))
        XCTAssertEqual(model.record(for: .showdown).total, 1)
        XCTAssertEqual(model.state.dailySummaries.first?.exact, 1)
        XCTAssertEqual(model.state.dailySummaries.first?.eligibleCorrectSeconds, 3)
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.phase, .reveal)
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.answers.first?.input, input)
        XCTAssertTrue(model.nextRoundQuestion(roundID: "round-1", afterOrdinal: 0,
                                               expectedEpoch: epoch))
        XCTAssertTrue(model.nextRoundQuestion(roundID: "round-1", afterOrdinal: 0,
                                               expectedEpoch: epoch))
        XCTAssertEqual(model.state.activeRound?.ordinal, 1)
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.ordinal, 1)
    }

    func testRoundIntroAndDraftResumeWithoutGrading() throws {
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        XCTAssertTrue(model.beginRound(concept: .outs, seed: 18, roundID: "intro-round",
                                       expectedEpoch: epoch))
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.introPhase, .show)
        XCTAssertTrue(model.setRoundShowBeat(roundID: "intro-round", index: 1,
            expectedEpoch: epoch))
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.showBeatIndex, 1)
        XCTAssertTrue(model.advanceRoundIntroduction(roundID: "intro-round", skip: false,
            expectedEpoch: epoch))
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.introPhase, .together)
        XCTAssertTrue(model.saveRoundGuidedDraft(roundID: "intro-round",
            input: .integerText("0"), expectedEpoch: epoch))
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.guidedDraft?.input,
                       .integerText("0"))
        let guidedBand = gradeOuts(estimate: 0,
            spot: OutsSpotGenerator.spot(baseSeed: 18, index: 1)).band
        let guidedInput = try JSONEncoder().encode(SavedDrillInput.integer(0))
        let guidedReveal = try JSONEncoder().encode(SavedDrillReveal(
            band: guidedBand.rawValue))
        XCTAssertTrue(model.commitRoundGuidedAnswer(roundID: "intro-round",
            band: guidedBand,
            input: guidedInput,
            reveal: guidedReveal,
            expectedEpoch: epoch))
        XCTAssertEqual(ProgressionModel(store: store).state.activeRound?.guidedAnswer?.band,
                       guidedBand.rawValue)
        XCTAssertEqual(model.record(for: .outs).total, 0)
        XCTAssertTrue(model.advanceRoundIntroduction(roundID: "intro-round", skip: true,
            expectedEpoch: epoch))
        XCTAssertNil(model.state.activeRound?.guidedAnswer)
        XCTAssertTrue(model.saveRoundDraft(roundID: "intro-round", ordinal: 0,
            input: .integerText("12"), expectedEpoch: epoch))
        let relaunched = ProgressionModel(store: store)
        XCTAssertEqual(relaunched.state.activeRound?.draft?.input, .integerText("12"))
        XCTAssertTrue(relaunched.state.introducedConcepts.contains(Concept.outs.rawValue))
        XCTAssertEqual(relaunched.record(for: .outs).total, 0)
        XCTAssertFalse(model.saveRoundDraft(roundID: "intro-round", ordinal: 1,
            input: .integerText("13"), expectedEpoch: epoch))
    }

    func testReviewCommitResumeAndNextAreAtomicAndIdempotent() throws {
        let yesterday = Date().addingTimeInterval(-86_400)
        var initial = ProgressState()
        initial.concepts[Concept.showdown.rawValue] = ConceptRecord(
            review: ReviewState(stability: 1, difficulty: 5,
                lastReview: yesterday.addingTimeInterval(-86_400),
                due: yesterday, reps: 1), correct: 1, total: 1)
        try store.save(initial)
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        XCTAssertTrue(model.beginReviewSession(seed: 17, expectedEpoch: epoch))
        let id = try XCTUnwrap(model.state.activeReviewSession?.id)
        let winner = gradeShowdown(answer: 0,
            spot: ShowdownSpotGenerator.spot(baseSeed: 17, index: 2)).winner
        let input = try JSONEncoder().encode(SavedDrillInput.integer(winner))
        let reveal = try JSONEncoder().encode(SavedDrillReveal(band: "spotOn"))
        XCTAssertTrue(model.commitReviewAnswer(sessionID: id, attemptID: "review-a",
            ordinal: 0, band: .spotOn, input: input, reveal: reveal,
            language: .english, expectedEpoch: epoch))
        XCTAssertTrue(model.commitReviewAnswer(sessionID: id, attemptID: "review-a",
            ordinal: 0, band: .spotOn, input: input, reveal: reveal,
            language: .english, expectedEpoch: epoch))
        XCTAssertEqual(model.record(for: .showdown).total, 2)
        XCTAssertEqual(ProgressionModel(store: store).state.activeReviewSession?.phase, .reveal)
        XCTAssertTrue(model.nextReviewQuestion(sessionID: id, afterOrdinal: 0,
            expectedEpoch: epoch))
        XCTAssertEqual(model.state.activeReviewSession?.phase, .finished)
        XCTAssertTrue(model.dismissFinishedReviewSession(sessionID: id,
            expectedEpoch: epoch))
        XCTAssertNil(ProgressionModel(store: store).state.activeReviewSession)
    }

    func testFailedRoundWriteBlocksLaterAnswersUntilRetry() throws {
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        XCTAssertTrue(model.beginRound(concept: .outs, seed: 1, expectedEpoch: epoch))
        let id = try XCTUnwrap(model.state.activeRound?.id)
        XCTAssertTrue(model.advanceRoundIntroduction(roundID: id, skip: true,
            expectedEpoch: epoch))
        let input = try JSONEncoder().encode(SavedDrillInput.integer(999))
        let reveal = try JSONEncoder().encode(SavedDrillReveal(band: "off"))
        let prior = try store.exportData()
        try withReadOnlyDirectory {
            XCTAssertFalse(model.commitRoundAnswer(roundID: id, attemptID: "a1",
                ordinal: 0, band: .off, language: "en", assisted: false,
                input: input, reveal: reveal, expectedEpoch: epoch))
            XCTAssertNotNil(model.saveError)
            XCTAssertEqual(try store.exportData(), prior)
            XCTAssertEqual(model.record(for: .outs).total, 0)
            XCTAssertFalse(model.commitRoundAnswer(roundID: id, attemptID: "a2",
                ordinal: 0, band: .off, language: "en", assisted: false,
                input: input, reveal: reveal, expectedEpoch: epoch))
            XCTAssertEqual(try store.importData(model.exportData()).activeRound?.answers.count, 1)
        }
        model.retrySave()
        XCTAssertNil(model.saveError)
        XCTAssertEqual(ProgressionModel(store: store).record(for: .outs).total, 1)
        XCTAssertTrue(model.commitRoundAnswer(roundID: id, attemptID: "a1",
            ordinal: 0, band: .off, language: "en", assisted: false,
            input: input, reveal: reveal, expectedEpoch: epoch))
        XCTAssertEqual(model.record(for: .outs).total, 1)
    }

    func testResetInvalidatesOldRoundAndPlacementNeverAwardsProgress() throws {
        let model = ProgressionModel(store: store)
        let oldEpoch = model.epoch
        XCTAssertTrue(model.setPlacement(report: .playRegularly,
            answers: ["showdown": "pair", "pot": "include-blinds",
                      "price": "compare-call-to-pot"], skipped: false,
            expectedEpoch: oldEpoch))
        XCTAssertEqual(model.state.placement?.recommendedConcept, Concept.rangeRead.rawValue)
        XCTAssertTrue(model.state.nodes.isEmpty)
        XCTAssertTrue(model.state.concepts.isEmpty)
        try model.resetProgress()
        XCTAssertNotEqual(model.epoch, oldEpoch)
        XCTAssertFalse(model.beginRound(concept: .showdown, seed: 1,
                                        expectedEpoch: oldEpoch))
        XCTAssertNil(model.state.placement)
    }

    func testDemoStateRoundTripsThroughTheProductionStore() throws {
        let demo = ProgressionModel.demoState()

        try store.save(demo)

        guard case let .loaded(reloaded) = store.load() else {
            return XCTFail("The seeded demo state must be valid persisted progress")
        }
        XCTAssertEqual(reloaded, demo)
    }

    func testCompletingFirstLessonPersistsOnlyItsMarker() throws {
        let model = ProgressionModel(store: store)
        let before = model.state

        model.completeFirstLesson()

        XCTAssertFalse(model.shouldPresentFirstLesson)
        XCTAssertEqual(model.state.firstLessonCompleted, true)
        XCTAssertEqual(model.state.concepts, before.concepts)
        XCTAssertEqual(model.state.nodes, before.nodes)
        XCTAssertEqual(model.state.answers, before.answers)
        XCTAssertEqual(model.state.streak, before.streak)
        XCTAssertEqual(ProgressionModel(store: store).state.firstLessonCompleted, true)
    }

    func testBasicsLessonIsSuggestedUntilFinishedAndWritesOnlyItsMarker() throws {
        let model = ProgressionModel(store: store)
        let before = model.state
        XCTAssertTrue(model.shouldSuggestBasicsLesson)

        model.completeBasicsLesson()

        XCTAssertFalse(model.shouldSuggestBasicsLesson)
        XCTAssertEqual(model.state.basicsLessonCompleted, true)
        XCTAssertEqual(model.state.concepts, before.concepts)
        XCTAssertEqual(model.state.nodes, before.nodes)
        XCTAssertEqual(model.state.answers, before.answers)
        XCTAssertEqual(model.state.streak, before.streak)
        XCTAssertEqual(ProgressionModel(store: store).state.basicsLessonCompleted, true)
    }

    func testLearnerWithAClearedLessonIsNotSentBackToBasics() throws {
        var started = ProgressState()
        started.nodes["u1-showdown"] = NodeRecord(cleared: true, attempts: 1)
        try store.save(started)

        XCTAssertFalse(ProgressionModel(store: store).shouldSuggestBasicsLesson)
    }

    func testFailedFirstLessonCompletionKeepsSavedProgressAndCanRetry() throws {
        let model = ProgressionModel(store: store)
        let savedBefore = try store.exportData()

        try withReadOnlyDirectory {
            model.completeFirstLesson()

            XCTAssertNil(model.state.firstLessonCompleted)
            XCTAssertNotNil(model.saveError)
            XCTAssertEqual(try store.exportData(), savedBefore)
            XCTAssertEqual(try store.importData(model.exportData()).firstLessonCompleted, true)
        }

        model.retrySave()

        XCTAssertNil(model.saveError)
        XCTAssertEqual(ProgressionModel(store: store).state.firstLessonCompleted, true)
    }

    func testHistoricalProgressSkipsFirstLessonWithoutRewritingIt() throws {
        var historical = ProgressState()
        historical.concepts["retired-concept"] = ConceptRecord()
        try store.save(historical)

        let model = ProgressionModel(store: store)

        XCTAssertFalse(model.shouldPresentFirstLesson)
        XCTAssertNil(model.state.firstLessonCompleted)
    }

    func testLegacyMigratedTotalsSkipFirstLesson() throws {
        let legacy = try JSONSerialization.data(withJSONObject: [
            "streak": 2, "correct": 4, "total": 6,
        ])
        try legacy.write(to: dir.appendingPathComponent("outs-progress.json"))

        let model = ProgressionModel(store: store)

        XCTAssertEqual(model.record(for: .outs).total, 6)
        XCTAssertFalse(model.shouldPresentFirstLesson)
        XCTAssertNil(model.state.firstLessonCompleted)
    }

    func testImportedHistoricalProgressSkipsFirstLesson() throws {
        let model = ProgressionModel(store: store)
        var imported = ProgressState()
        imported.answers.append(AnswerRecord(concept: .showdown, at: Date(), correct: true))

        try model.importData(JSONEncoder().encode(imported))

        XCTAssertFalse(model.shouldPresentFirstLesson)
        XCTAssertNil(model.state.firstLessonCompleted)
    }

    func testUnreadableStoreStillRequiresRecoveryBeforeFirstLesson() throws {
        try Data("{ damaged".utf8).write(to: store.url)
        let model = ProgressionModel(store: store)

        XCTAssertNotNil(model.unreadable)
        XCTAssertFalse(model.shouldPresentFirstLesson)
    }

    func testFailedImportLeavesDisplayedProgressUnchanged() throws {
        var original = ProgressState()
        original.streak.current = 7
        try store.save(original)
        let model = ProgressionModel(store: store)
        // An unavailable destination reproduces a write failure after valid decoding.
        let moved = dir.appendingPathExtension("unavailable")
        try FileManager.default.moveItem(at: dir, to: moved)
        defer { try? FileManager.default.removeItem(at: moved) }
        try Data("blocked directory".utf8).write(to: dir)
        var replacement = ProgressState()
        replacement.streak.current = 99

        XCTAssertThrowsError(try model.importData(JSONEncoder().encode(replacement)))
        XCTAssertEqual(model.state, original)
        XCTAssertEqual(try JSONDecoder().decode(ProgressState.self,
            from: Data(contentsOf: moved.appendingPathComponent("progression.json"))), original)
    }

    func testFutureStoreRequiresRecoveryAndRetainsItsBytes() throws {
        var future = ProgressState()
        future.schemaVersion = ProgressState.currentSchemaVersion + 1
        let bytes = try JSONEncoder().encode(future)
        try bytes.write(to: store.url)

        let model = ProgressionModel(store: store)

        XCTAssertNotNil(model.unreadable)
        XCTAssertEqual(try Data(contentsOf: store.url), bytes)
    }

    func testFailedInitialSaveIsVisibleAndCanBeRetried() throws {
        try FileManager.default.removeItem(at: dir)
        try Data("blocked directory".utf8).write(to: dir)
        let model = ProgressionModel(store: store)
        XCTAssertNotNil(model.saveError)

        try FileManager.default.removeItem(at: dir)
        model.retrySave()

        XCTAssertNil(model.saveError)
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
    }

    func testFailedAnswerSaveCanBeExportedAndRetriedWithoutLosingAnswers() throws {
        let model = ProgressionModel(store: store)
        let previousBytes = try store.exportData()
        try withReadOnlyDirectory {
            model.record(concept: .outs, band: .spotOn)
            model.record(concept: .potOdds, band: .close)

            XCTAssertNotNil(model.saveError)
            XCTAssertEqual(try store.exportData(), previousBytes)
            let exported = try store.importData(model.exportData())
            XCTAssertEqual(exported.record(for: .outs).total, 1)
            XCTAssertEqual(exported.record(for: .potOdds).total, 0)
        }

        model.retrySave()

        XCTAssertNil(model.saveError)
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
        XCTAssertEqual(model.record(for: .outs).total, 1)
        XCTAssertEqual(model.record(for: .potOdds).total, 0)
    }

    func testFailedResetKeepsDisplayedAndSavedProgress() throws {
        let model = ProgressionModel(store: store)
        model.record(concept: .outs, band: .spotOn)
        let original = model.state
        let bytes = try store.exportData()

        try withReadOnlyDirectory {
            XCTAssertThrowsError(try model.resetProgress())
            XCTAssertEqual(model.state, original)
            XCTAssertEqual(try store.exportData(), bytes)
        }
    }

    func testFailedRecoveryKeepsRecoveryScreenAndOriginalBytes() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        try withReadOnlyDirectory {
            XCTAssertThrowsError(try model.resetProgress())
            XCTAssertThrowsError(try model.importData(JSONEncoder().encode(ProgressState())))
            XCTAssertNotNil(model.unreadable)
            XCTAssertEqual(try store.exportData(), bytes)
        }
    }

    func testSuccessfulRecoveryPreservesOriginalAndSurvivesRelaunch() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        try model.resetProgress()

        XCTAssertNil(model.unreadable)
        XCTAssertNil(model.saveError)
        XCTAssertEqual(model.state, ProgressState())
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
        let recovery = try XCTUnwrap(FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil).first {
                $0.lastPathComponent != store.url.lastPathComponent
            })
        XCTAssertEqual(try Data(contentsOf: recovery), bytes)
    }

    func testSuccessfulImportUpdatesBothMemoryAndDisk() throws {
        let model = ProgressionModel(store: store)
        var replacement = ProgressState()
        replacement.streak.current = 9

        try model.importData(JSONEncoder().encode(replacement))

        XCTAssertEqual(model.state, replacement)
        XCTAssertEqual(ProgressionModel(store: store).state, replacement)
        XCTAssertNil(model.unreadable)
        XCTAssertNil(model.saveError)
    }

    func testInvalidImportDoesNotChangeRecoveryStateOrBytes() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        XCTAssertThrowsError(try model.importData(Data("not a backup".utf8)))

        XCTAssertNotNil(model.unreadable)
        XCTAssertEqual(try model.exportData(), bytes)
    }

    func testSemanticallyInvalidImportLeavesHealthyProgressAndBytesUnchanged() throws {
        var original = ProgressState()
        original.streak.current = 4
        original.streak.longest = 4
        try store.save(original)
        let originalBytes = try store.exportData()
        let model = ProgressionModel(store: store)
        var invalid = ProgressState()
        invalid.concepts[Concept.outs.rawValue] = ConceptRecord(
            review: ReviewState(stability: 1e100, difficulty: 5,
                                lastReview: Date(), due: Date(), reps: 1),
            correct: 1, total: 1)

        XCTAssertThrowsError(try model.importData(JSONEncoder().encode(invalid))) { error in
            XCTAssertEqual(error as? StoreError, .invalidProgress)
        }
        XCTAssertEqual(model.state, original)
        XCTAssertEqual(try store.exportData(), originalBytes)
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil).contains {
                $0.lastPathComponent.contains("recovery-")
            })
    }

    func testProgressFileReaderReadsSmallFileOffTheViewCallback() async throws {
        let url = dir.appendingPathComponent("backup.json")
        let bytes = try JSONEncoder().encode(ProgressState())
        try bytes.write(to: url)

        let target = ProgressionModel(store: store)
        let prepared = try await ProgressFileReader.readAndValidate(
            url, expectedEpoch: target.epoch, expectedRevision: target.state.revision)
        try target.importPrepared(prepared)
        XCTAssertEqual(target.state, ProgressState())
    }

    func testProgressFileReaderRejectsOversizedFile() async throws {
        let url = dir.appendingPathComponent("oversized.json")
        try Data(repeating: 0, count: ProgressionStore.maximumFileBytes + 1).write(to: url)

        do {
            _ = try await ProgressFileReader.readAndValidate(
                url, expectedEpoch: UUID(), expectedRevision: 0)
            XCTFail("oversized imports must be rejected before decoding")
        } catch {
            XCTAssertEqual(error as? StoreError,
                           .fileTooLarge(maximumBytes: ProgressionStore.maximumFileBytes))
        }
    }

    func testPreparedImportDoesNotChangeMemoryWhenReplacementWriteFails() async throws {
        var replacement = ProgressState()
        replacement.streak.current = 9
        replacement.streak.longest = 9
        let source = dir.appendingPathComponent("prepared-backup.json")
        try JSONEncoder().encode(replacement).write(to: source)
        let model = ProgressionModel(store: store)
        let prepared = try await ProgressFileReader.readAndValidate(
            source, expectedEpoch: model.epoch, expectedRevision: model.state.revision)
        let original = model.state

        try withReadOnlyDirectory {
            XCTAssertThrowsError(try model.importPrepared(prepared))
            XCTAssertEqual(model.state, original)
        }
    }

    func testPreparedImportCannotReplaceAnUnsavedAnswerWithSamePublishedRevision() throws {
        let model = ProgressionModel(store: store)
        var replacement = ProgressState()
        replacement.streak.current = 4
        replacement.streak.longest = 4
        let prepared = PreparedProgressImport(state: replacement,
            expectedEpoch: model.epoch, expectedRevision: model.state.revision)
        let originalBytes = try store.exportData()

        try withReadOnlyDirectory {
            XCTAssertFalse(model.record(concept: .outs, band: .spotOn))
            XCTAssertNotNil(model.saveError)
            XCTAssertThrowsError(try model.importPrepared(prepared)) { error in
                XCTAssertEqual(error as? ProgressCommandError, .staleImport)
            }
            XCTAssertEqual(try store.exportData(), originalBytes)
            XCTAssertEqual(try store.importData(model.exportData()).record(for: .outs).total, 1)
        }
        model.retrySave()
        XCTAssertEqual(model.record(for: .outs).total, 1)
        XCTAssertThrowsError(try model.importPrepared(prepared))
    }

    func testFilePickerCancellationIsNotPresentedAsFailure() {
        let cancellation = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        XCTAssertTrue(ProgressFileFailure.isCancellation(cancellation))
        XCTAssertTrue(ProgressFileFailure.isCancellation(CancellationError()))
    }

    func testUnreadableStoreExposesOriginalFileForRecoveryExport() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)

        let model = ProgressionModel(store: store)

        XCTAssertEqual(model.recoveryFileURL, store.url)
        XCTAssertEqual(try Data(contentsOf: try XCTUnwrap(model.recoveryFileURL)), bytes)
    }

    func testOrdinaryWritesCannotOverwriteAnUnreadableStore() throws {
        let bytes = Data("{ damaged".utf8)
        try bytes.write(to: store.url)
        let model = ProgressionModel(store: store)

        model.record(concept: .outs, band: .spotOn)
        let node = try XCTUnwrap(Curriculum.node(id: "u1-showdown"))
        let scheduled = Curriculum.sessionConcepts(for: node)
        model.completeNode(node, scheduled: scheduled,
                           evidence: [.showdown: SessionEvidence(attempted: 5, spotOn: 5)])
        model.retrySave()

        XCTAssertNotNil(model.unreadable)
        XCTAssertNil(model.saveError)
        XCTAssertEqual(model.state, ProgressState())
        XCTAssertEqual(try store.exportData(), bytes)
    }

    func testDueAnswerPersistsStreakCreditWithTheAnswer() throws {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        var original = ProgressState()
        for concept in [Concept.outs, .combos] {
            original.updateRecord(for: concept) {
                $0.total = 5
                $0.review = ReviewState(stability: 5, difficulty: 5,
                    lastReview: now.addingTimeInterval(-172800),
                    due: now.addingTimeInterval(-86400), reps: 2)
            }
        }
        try store.save(original)
        let model = ProgressionModel(store: store)

        model.record(concept: .outs, band: .spotOn, now: now)

        XCTAssertEqual(model.state.streak.current, 1)
        XCTAssertEqual(model.dueConcepts(now: now), [.combos])
        XCTAssertEqual(ProgressionModel(store: store).state, model.state)
    }

    func testUnitTwoBossPracticesPositionBeforeAwardingMastery() throws {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        var original = ProgressState()
        original.updateRecord(for: .position) {
            $0.total = 5; $0.correct = 5; $0.tier = .proficient
            $0.proficientAt = now.addingTimeInterval(-86400)
        }
        try store.save(original)
        let model = ProgressionModel(store: store)
        let boss = try XCTUnwrap(Curriculum.node(id: "u2-boss"))
        let concepts = Curriculum.sessionConcepts(for: boss, seed: 7)
        XCTAssertEqual(concepts.count, 7)
        XCTAssertTrue(concepts.contains(.callFold))
        var evidence: [Concept: SessionEvidence] = [:]
        for concept in concepts {
            model.record(concept: concept, band: .spotOn, now: now)
            evidence[concept, default: SessionEvidence()].record(spotOn: true)
        }
        model.completeNode(boss, scheduled: concepts, evidence: evidence, now: now)

        XCTAssertEqual(model.record(for: .position).total, 6)
        XCTAssertEqual(model.record(for: .position).tier, .mastered)
    }

    func testCompletedAllWrongLessonClearsWithoutClaimingProficiency() throws {
        let model = ProgressionModel(store: store)
        let node = try XCTUnwrap(Curriculum.node(id: "u1-showdown"))
        let scheduled = Curriculum.sessionConcepts(for: node)
        for _ in scheduled { model.record(concept: .showdown, band: .off) }

        XCTAssertTrue(model.completeNode(node, scheduled: scheduled,
                                         evidence: [.showdown: SessionEvidence(
                                            attempted: scheduled.count, spotOn: 0)]))
        XCTAssertEqual(model.status(of: node), .cleared)
        XCTAssertEqual(model.record(for: .showdown).tier, .attempted)
    }

    func testIncompleteEvidenceCannotClearNode() throws {
        let model = ProgressionModel(store: store)
        let node = try XCTUnwrap(Curriculum.node(id: "u1-showdown"))
        let scheduled = Curriculum.sessionConcepts(for: node)

        XCTAssertFalse(model.completeNode(node, scheduled: scheduled, evidence: [:]))
        XCTAssertEqual(model.status(of: node), .available)
        XCTAssertNil(model.state.nodes[node.id])
    }

    func testMixedBossPromotesOnlyTheSpotOnConcept() throws {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        var original = ProgressState()
        for concept in [Concept.showdown, .potMath, .position, .combos] {
            original.updateRecord(for: concept) {
                $0.tier = .proficient
                $0.correct = 10
                $0.total = 10
                $0.proficientAt = now.addingTimeInterval(-86400)
            }
        }
        try store.save(original)
        let model = ProgressionModel(store: store)
        let boss = try XCTUnwrap(Curriculum.node(id: "u1-boss"))
        let scheduled = Curriculum.sessionConcepts(for: boss, seed: 2)
        var evidence: [Concept: SessionEvidence] = [:]
        for concept in scheduled {
            let exact = concept == .showdown
            model.record(concept: concept, band: exact ? .spotOn : .close, now: now)
            evidence[concept, default: SessionEvidence()].record(spotOn: exact)
        }

        XCTAssertTrue(model.completeNode(boss, scheduled: scheduled,
                                         evidence: evidence, now: now))
        XCTAssertEqual(model.record(for: .showdown).tier, .mastered)
        XCTAssertEqual(model.record(for: .potMath).tier, .proficient)
        XCTAssertEqual(model.record(for: .position).tier, .proficient)
        XCTAssertEqual(model.record(for: .combos).tier, .proficient)
    }

    func testCompleteWalkthroughPersistsOnlyMissReset() throws {
        var original = ProgressState()
        original.updateRecord(for: .outs) {
            $0.correct = 2; $0.total = 10; $0.consecutiveMisses = 8
            let due = Date(timeIntervalSince1970: 1_785_000_000)
            $0.review = ReviewState(stability: 5, difficulty: 5,
                                    lastReview: due.addingTimeInterval(-86_400),
                                    due: due, reps: 1)
        }
        try store.save(original)
        let model = ProgressionModel(store: store)
        let before = model.record(for: .outs)

        model.completeWalkthrough(concept: .outs)

        let after = model.record(for: .outs)
        XCTAssertEqual(after.consecutiveMisses, 0)
        XCTAssertEqual(after.correct, before.correct)
        XCTAssertEqual(after.total, before.total)
        XCTAssertEqual(after.review, before.review)
        XCTAssertTrue(model.state.answers.isEmpty)
        XCTAssertEqual(ProgressionModel(store: store).record(for: .outs), after)
    }

    func testAttemptLedgerRequiresCommitAndRejectsDuplicateCommitAndAdvance() {
        var ledger = SessionAttemptLedger()
        let first = SessionAttemptID(concept: .showdown, seed: 9, index: 2)
        let second = SessionAttemptID(concept: .showdown, seed: 9, index: 3)

        XCTAssertFalse(ledger.advance(first), "Next before reveal commit must be ignored")
        XCTAssertTrue(ledger.commit(first))
        XCTAssertFalse(ledger.commit(first))
        XCTAssertTrue(ledger.advance(first))
        XCTAssertFalse(ledger.advance(first), "Repeated Next must not skip a question")
        XCTAssertTrue(ledger.commit(second), "The next spot of the same concept is distinct")
        XCTAssertTrue(ledger.advance(second))
        XCTAssertEqual(ledger.committed.count, 2)
        XCTAssertEqual(ledger.advanced.count, 2)
    }

    func testInterruptedBossAnswerChangesRestartSeedAndShuffledPrefix() throws {
        let boss = try XCTUnwrap(Curriculum.node(id: "u1-boss"))
        let beforeSeed = NodeSessionSeed.make(nodeID: boss.id,
                                              conceptTotals: [10, 0, 0, 0])
        let before = Curriculum.sessionConcepts(for: boss, seed: beforeSeed)
        XCTAssertEqual(before, [.potMath, .position, .combos,
                                .showdown, .position, .combos])
        let answered = try XCTUnwrap(before.first)
        let concepts = Curriculum.concepts(of: boss)
        let afterTotals = concepts.map { concept in
            concept == answered ? 1 + (concept == .showdown ? 10 : 0)
                                : (concept == .showdown ? 10 : 0)
        }
        let afterSeed = NodeSessionSeed.make(nodeID: boss.id, conceptTotals: afterTotals)
        let after = Curriculum.sessionConcepts(for: boss, seed: afterSeed)

        XCTAssertNotEqual(beforeSeed, afterSeed)
        XCTAssertNotEqual(Array(before.prefix(3)), Array(after.prefix(3)),
                          "Restarting after a committed prefix must not expose the same prefix")
    }

    func testCommittedFinalAnswerPersistsBeforeNodeCompletion() throws {
        let model = ProgressionModel(store: store)
        let node = try XCTUnwrap(Curriculum.node(id: "u1-showdown"))
        let scheduled = Curriculum.sessionConcepts(for: node)

        model.record(concept: .showdown, band: .spotOn)

        XCTAssertEqual(ProgressionModel(store: store).record(for: .showdown).total, 1)
        XCTAssertEqual(model.status(of: node), .available)
        XCTAssertNil(model.state.nodes[node.id])

        XCTAssertFalse(model.completeNode(node, scheduled: scheduled,
                                          evidence: [.showdown: SessionEvidence(
                                            attempted: 1, spotOn: 1)]))
        XCTAssertEqual(model.status(of: node), .available)
    }

    // MARK: - help that shows a question's calculation (issue 04)

    private func showdownAnswer(seed: UInt64, index: Int) throws -> (Data, Data, GradeBand) {
        let spot = ShowdownSpotGenerator.spot(baseSeed: seed, index: index)
        let winner = gradeShowdown(answer: 0, spot: spot).winner
        let band = gradeShowdown(answer: winner, spot: spot).band
        return (try JSONEncoder().encode(SavedDrillInput.integer(winner)),
                try JSONEncoder().encode(SavedDrillReveal(band: band.rawValue)), band)
    }

    func testRoundHelpIsPracticeWithoutAccuracyScheduleOrTiming() throws {
        let now = Date(timeIntervalSince1970: 1_785_000_000)
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        XCTAssertTrue(model.beginRound(concept: .showdown, seed: 77, roundID: "r",
                                       expectedEpoch: epoch))
        XCTAssertTrue(model.advanceRoundIntroduction(roundID: "r", skip: false,
                                                     expectedEpoch: epoch))
        XCTAssertFalse(model.markHelpUsed(.round, sessionID: "r", ordinal: 0,
                                          expectedEpoch: epoch),
                       "the guided together step is never marked")
        XCTAssertTrue(model.advanceRoundIntroduction(roundID: "r", skip: true,
                                                     expectedEpoch: epoch))
        XCTAssertTrue(model.markHelpUsed(.round, sessionID: "r", ordinal: 0, expectedEpoch: epoch))
        XCTAssertTrue(model.markHelpUsed(.round, sessionID: "r", ordinal: 0, expectedEpoch: epoch))
        XCTAssertTrue(ProgressionModel(store: store).helpUsed(.round, sessionID: "r", ordinal: 0))

        // The screen forgets the flag; the stored help still decides.
        let (input, reveal, band) = try showdownAnswer(seed: 77, index: 2)
        XCTAssertEqual(band, .spotOn)
        XCTAssertTrue(model.commitRoundAnswer(roundID: "r", attemptID: "a", ordinal: 0,
            band: band, language: "ko", assisted: false, input: input, reveal: reveal,
            eligibleSeconds: 3, now: now, expectedEpoch: epoch))
        XCTAssertTrue(model.commitRoundAnswer(roundID: "r", attemptID: "a", ordinal: 0,
            band: band, language: "ko", assisted: false, input: input, reveal: reveal,
            eligibleSeconds: 3, now: now, expectedEpoch: epoch))

        let relaunched = ProgressionModel(store: store)
        XCTAssertEqual(relaunched.record(for: .showdown), ConceptRecord())
        XCTAssertEqual(relaunched.state.dailySummaries.count, 1)
        XCTAssertEqual(relaunched.state.dailySummaries.first?.key.assisted, true)
        XCTAssertEqual(relaunched.state.dailySummaries.first?.exact, 1)
        XCTAssertEqual(relaunched.state.dailySummaries.first?.eligibleCorrectCount, 0)
        XCTAssertEqual(relaunched.state.activeRound?.answers.first?.isAssisted, true)
        XCTAssertEqual(relaunched.state.streak.current, 1)
        XCTAssertEqual(relaunched.seedCount(for: .showdown), 1)
        XCTAssertFalse(model.markHelpUsed(.round, sessionID: "r", ordinal: 0, expectedEpoch: epoch),
                       "help after the answer changes nothing")

        XCTAssertTrue(model.nextRoundQuestion(roundID: "r", afterOrdinal: 0, expectedEpoch: epoch))
        XCTAssertNil(model.state.activeRound?.helpOrdinal)
        let (input2, reveal2, band2) = try showdownAnswer(seed: 77, index: 3)
        XCTAssertTrue(model.commitRoundAnswer(roundID: "r", attemptID: "b", ordinal: 1,
            band: band2, language: "ko", assisted: false, input: input2, reveal: reveal2,
            now: now, expectedEpoch: epoch))
        XCTAssertEqual(model.record(for: .showdown).total, 1)
        XCTAssertNil(model.state.activeRound?.answers.last?.assisted)
    }

    func testReviewHelpLeavesTheConceptDue() throws {
        let yesterday = Date().addingTimeInterval(-86_400)
        var initial = ProgressState()
        let record = ConceptRecord(
            review: ReviewState(stability: 1, difficulty: 5,
                lastReview: yesterday.addingTimeInterval(-86_400),
                due: yesterday, reps: 1), correct: 1, total: 1)
        initial.concepts[Concept.showdown.rawValue] = record
        try store.save(initial)
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        XCTAssertTrue(model.beginReviewSession(seed: 17, expectedEpoch: epoch))
        let id = try XCTUnwrap(model.state.activeReviewSession?.id)
        XCTAssertTrue(model.markHelpUsed(.review, sessionID: id, ordinal: 0, expectedEpoch: epoch))
        let (input, reveal, band) = try showdownAnswer(seed: 17, index: 2)
        XCTAssertTrue(model.commitReviewAnswer(sessionID: id, attemptID: "rv", ordinal: 0,
            band: band, input: input, reveal: reveal, language: .english,
            expectedEpoch: epoch))

        XCTAssertEqual(model.record(for: .showdown), record)
        XCTAssertEqual(model.dueConcepts(), [.showdown])
        XCTAssertEqual(model.state.activeReviewSession?.answers.first?.answer.isAssisted, true)
        XCTAssertEqual(model.state.streak.current, 1)
        XCTAssertEqual(model.seedCount(for: .showdown), 2)
    }

    func testLessonWithHelpClearsButDoesNotReachProficient() throws {
        var initial = ProgressState()
        initial.updateRecord(for: .showdown) { $0.correct = 10; $0.total = 10; $0.tier = .familiar }
        try store.save(initial)
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        let node = try XCTUnwrap(Curriculum.node(id: "u1-showdown"))
        XCTAssertTrue(model.beginNodeSession(node, seed: 5, expectedEpoch: epoch))
        let session = try XCTUnwrap(model.state.activeNodeSession)
        XCTAssertEqual(session.phase, .question)
        for ordinal in session.scheduledConcepts.indices {
            if ordinal == 0 {
                XCTAssertTrue(model.markHelpUsed(.lesson, sessionID: session.id,
                                                 ordinal: 0, expectedEpoch: epoch))
            }
            let (input, reveal, band) = try showdownAnswer(seed: 5, index: ordinal + 2)
            XCTAssertTrue(model.commitNodeAnswer(sessionID: session.id,
                attemptID: "n\(ordinal)", ordinal: ordinal, band: band,
                input: input, reveal: reveal, language: .korean, expectedEpoch: epoch))
            XCTAssertTrue(model.nextNodeQuestion(sessionID: session.id,
                afterOrdinal: ordinal, expectedEpoch: epoch))
        }
        XCTAssertEqual(model.status(of: node), .cleared)
        XCTAssertEqual(model.record(for: .showdown).total, 10 + session.scheduledConcepts.count - 1)
        XCTAssertEqual(model.record(for: .showdown).tier, .familiar)
    }

    func testLessonAnsweredOnlyWithHelpClearsWithoutWritingARecord() throws {
        let model = ProgressionModel(store: store)
        let epoch = model.epoch
        let node = try XCTUnwrap(Curriculum.node(id: "u1-showdown"))
        XCTAssertTrue(model.beginNodeSession(node, seed: 5, expectedEpoch: epoch))
        let id = try XCTUnwrap(model.state.activeNodeSession?.id)
        XCTAssertTrue(model.advanceNodeTeaching(sessionID: id, skip: true, expectedEpoch: epoch))
        let count = try XCTUnwrap(model.state.activeNodeSession?.scheduledConcepts.count)
        for ordinal in 0..<count {
            XCTAssertTrue(model.markHelpUsed(.lesson, sessionID: id, ordinal: ordinal,
                                             expectedEpoch: epoch))
            let (input, reveal, band) = try showdownAnswer(seed: 5, index: ordinal + 2)
            XCTAssertTrue(model.commitNodeAnswer(sessionID: id, attemptID: "h\(ordinal)",
                ordinal: ordinal, band: band, input: input, reveal: reveal,
                language: .korean, expectedEpoch: epoch))
            XCTAssertTrue(model.nextNodeQuestion(sessionID: id, afterOrdinal: ordinal,
                                                 expectedEpoch: epoch))
        }
        XCTAssertEqual(model.status(of: node), .cleared)
        XCTAssertNil(model.state.concepts[Concept.showdown.rawValue])
        XCTAssertEqual(model.seedCount(for: .showdown), count)
    }

    func testSeedsMoveAfterHelpSoRestartingDealsANewSpot() throws {
        let node = try XCTUnwrap(Curriculum.node(id: "u1-showdown"))
        let model = ProgressionModel(store: store)
        let before = NodeSessionSeed.make(nodeID: node.id,
            conceptTotals: Curriculum.concepts(of: node).map { model.seedCount(for: $0) })
        model.record(concept: .showdown, band: .spotOn, attemptID: "x", mode: "path",
                     assisted: true)
        XCTAssertEqual(model.record(for: .showdown).total, 0)
        let after = NodeSessionSeed.make(nodeID: node.id,
            conceptTotals: Curriculum.concepts(of: node).map { model.seedCount(for: $0) })
        XCTAssertNotEqual(before, after)
    }

    private func withReadOnlyDirectory(_ body: () throws -> Void) throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
        }
        try body()
    }
}
