// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

public enum StoreError: Error, Equatable {
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case notDecodable
    case invalidProgress
    case fileTooLarge(maximumBytes: Int)
}

/// Outcome of reading the store. The three cases exist so that "no file yet" and
/// "file is there but unreadable" can never be confused: the M1 store answered both
/// with empty progress, which silently erased a returning user (spec §8.2).
public enum StoreLoad {
    case fresh
    case loaded(ProgressState)
    case unreadable(String)
}

/// The one on-device file, replacing the five per-drill `<drill>-progress.json`
/// stores. Everything is loaded whole and kept in memory — at ~50 KB there is no
/// query here that would benefit from an index (spec §8.1).
public struct ProgressionStore {
    private struct SchemaHeader: Decodable { let schemaVersion: Int }
    /// Daily history is unbounded by age; a capacity failure is surfaced instead of
    /// silently deleting old days. Large imports are decoded off the UI thread.
    public static let maximumFileBytes = 64 * 1024 * 1024
    static let maximumStoredCount = 1_000_000_000

    public let url: URL

    public init(url: URL) { self.url = url }

    public static func standard() -> ProgressionStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask)[0]
        return ProgressionStore(url: dir.appendingPathComponent("progression.json"))
    }

    public func load() -> StoreLoad {
        guard FileManager.default.fileExists(atPath: url.path) else { return .fresh }
        do {
            let original = try Self.readData(at: url, maximumBytes: Self.maximumFileBytes)
            let source = try Self.decodeAndValidate(original)
            let state = Self.upgrade(source)
            if source.schemaVersion < ProgressState.currentSchemaVersion {
                // Copy exact bytes before writing. If either step fails the original
                // remains at its original location and load reports recovery.
                let backup = url.deletingPathExtension()
                    .appendingPathExtension("schema-1-\(UUID().uuidString).json")
                try FileManager.default.copyItem(at: url, to: backup)
                try save(state)
            }
            return .loaded(state)
        } catch {
            return .unreadable(String(describing: error))
        }
    }

    /// Atomic so a kill mid-write can never truncate the live file: Foundation writes
    /// to a sibling temp file and renames, and rename is atomic on APFS. Throws rather
    /// than swallowing, because a save that silently fails is how progress disappears.
    public func save(_ state: ProgressState) throws {
        try Self.validate(state)
        try write(exportData(state))
    }

    /// Preserve the existing bytes before an explicit reset or import. Copy rather
    /// than move: if the replacement write fails (or the app exits), the live file
    /// still contains the original progress. A failed copy must abort replacement.
    @discardableResult
    public func replace(with state: ProgressState) throws -> URL? {
        try Self.validate(state)
        let data = try exportData(state)
        var recovery: URL?
        if FileManager.default.fileExists(atPath: url.path) {
            let destination = url.deletingPathExtension()
                .appendingPathExtension("recovery-\(UUID().uuidString).json")
            try FileManager.default.copyItem(at: url, to: destination)
            recovery = destination
        }
        try write(data)
        return recovery
    }

    private func write(_ data: Data) throws {
        // Retry directory creation too: first-launch storage may have been unavailable.
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic])
    }

    /// The store file *is* the export format (spec §8.1), so this is a straight read.
    public func exportData() throws -> Data {
        try Self.readData(at: url, maximumBytes: Self.maximumFileBytes)
    }

    /// Encode in-memory progress too, including answers awaiting a successful save.
    public func exportData(_ state: ProgressState) throws -> Data {
        try Self.validate(state)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if #available(macOS 10.15, iOS 13, *) {
            encoder.outputFormatting.insert(.withoutEscapingSlashes)
        }
        let data = try encoder.encode(state)
        guard data.count <= Self.maximumFileBytes else {
            throw StoreError.fileTooLarge(maximumBytes: Self.maximumFileBytes)
        }
        return data
    }

    /// Validates before returning; the caller decides whether to `save` the result.
    public func importData(_ data: Data) throws -> ProgressState {
        guard data.count <= Self.maximumFileBytes else {
            throw StoreError.fileTooLarge(maximumBytes: Self.maximumFileBytes)
        }
        return Self.upgrade(try Self.decodeAndValidate(data))
    }

    private static func decodeAndValidate(_ data: Data) throws -> ProgressState {
        // Inspect the version before decoding the rest. A future file can have fields
        // this binary cannot decode, but its error must still identify the version.
        guard let version = try? JSONDecoder().decode(SchemaHeader.self, from: data)
            .schemaVersion
        else { throw StoreError.notDecodable }
        guard version <= ProgressState.currentSchemaVersion else {
            throw StoreError.unsupportedSchemaVersion(
                found: version, supported: ProgressState.currentSchemaVersion)
        }
        let state: ProgressState
        do { state = try JSONDecoder().decode(ProgressState.self, from: data) }
        catch { throw StoreError.notDecodable }
        guard state.schemaVersion <= ProgressState.currentSchemaVersion else {
            throw StoreError.unsupportedSchemaVersion(
                found: state.schemaVersion, supported: ProgressState.currentSchemaVersion)
        }
        try Self.validate(state, verifyAnswers: true)
        return state
    }

    private static func upgrade(_ state: ProgressState) -> ProgressState {
        guard state.schemaVersion == 1 else { return state }
        var upgraded = state
        upgraded.schemaVersion = ProgressState.currentSchemaVersion
        // Existing correct includes accepted near answers. The old 500-answer ring
        // cannot reconstruct the full daily history, so tracking begins now.
        upgraded.detailedTrackingStartedAt = Date()
        return upgraded
    }

    /// Bounded raw read for file-importer callers. Pair with `importData` on a
    /// background task before offering replacement confirmation.
    public static func readImportData(at url: URL) throws -> Data {
        try readData(at: url, maximumBytes: maximumFileBytes)
    }

    static func readData(at url: URL, maximumBytes: Int) throws -> Data {
        if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           size > maximumBytes {
            throw StoreError.fileTooLarge(maximumBytes: maximumBytes)
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer {
            if #available(macOS 10.15, iOS 13, *) { try? handle.close() }
            else { handle.closeFile() }
        }
        var result = Data()
        result.reserveCapacity(min(maximumBytes, 64 * 1024))
        while true {
            let remaining = maximumBytes - result.count
            guard remaining >= 0 else {
                throw StoreError.fileTooLarge(maximumBytes: maximumBytes)
            }
            let readCount = min(64 * 1024, remaining + 1)
            let chunk: Data
            if #available(macOS 10.15.4, iOS 13.4, *) {
                chunk = try handle.read(upToCount: readCount) ?? Data()
            } else {
                chunk = handle.readData(ofLength: readCount)
            }
            if chunk.isEmpty { return result }
            guard chunk.count <= remaining else {
                throw StoreError.fileTooLarge(maximumBytes: maximumBytes)
            }
            result.append(chunk)
        }
    }

    private static func validate(_ state: ProgressState,
                                 verifyAnswers: Bool = false) throws {
        guard state.schemaVersion >= 1,
              state.schemaVersion <= ProgressState.currentSchemaVersion,
              state.concepts.values.allSatisfy(validate),
              state.nodes.values.allSatisfy(validate),
              validate(state.streak),
              state.answers.count <= ProgressState.answerLogCap,
              state.answers.allSatisfy(validate),
              validCount(state.revision),
              validDate(state.detailedTrackingStartedAt),
              state.introducedConcepts.allSatisfy({ !$0.isEmpty }),
              state.processedAttemptIDs.allSatisfy({ !$0.isEmpty }),
              state.dailySummaries.allSatisfy(validate),
              Set(state.dailySummaries.map(\.key)).count == state.dailySummaries.count,
              state.recentEvidence.count <= 500,
              state.recentEvidence.allSatisfy(validate),
              state.activeRound.map({ validate($0, verifyAnswers: verifyAnswers) }) ?? true,
              state.activeNodeSession.map({ validate($0, verifyAnswers: verifyAnswers) }) ?? true,
              state.activeReviewSession.map({ validate($0, verifyAnswers: verifyAnswers) }) ?? true,
              state.placement.map(validate) ?? true,
              state.recentHands.count <= 200,
              Set(state.recentHands.map(\.handID)).count == state.recentHands.count,
              state.recentHands.allSatisfy({ DayKey(raw: $0.day) != nil }),
              (try? state.tableState?.validate()) != nil || state.tableState == nil
        else { throw StoreError.invalidProgress }
    }

    private static func validCount(_ value: Int) -> Bool {
        (0...maximumStoredCount).contains(value)
    }

    private static func validDate(_ date: Date?) -> Bool {
        guard let date else { return true }
        return date.timeIntervalSinceReferenceDate.isFinite
            && date >= .distantPast && date <= .distantFuture
    }

    private static func validate(_ record: ConceptRecord) -> Bool {
        let review = record.review
        let reviewShapeIsValid: Bool
        if review.reps == 0 {
            reviewShapeIsValid = review.stability == 0
                && review.lastReview == nil && review.due == nil && review.lapses == 0
        } else {
            reviewShapeIsValid = review.stability >= FSRS.minStability
                && review.stability <= FSRS.maxStability
                && review.lastReview != nil && review.due != nil
                && review.due! >= review.lastReview!
        }
        return validCount(record.correct) && validCount(record.total)
            && record.correct <= record.total
            && validCount(record.consecutiveMisses)
            && record.consecutiveMisses <= record.total
            && review.stability.isFinite && review.difficulty.isFinite
            && (FSRS.minDifficulty...FSRS.maxDifficulty).contains(review.difficulty)
            && validCount(review.reps) && validCount(review.lapses)
            && review.lapses <= review.reps && review.reps <= record.total
            && reviewShapeIsValid
            && validDate(review.lastReview) && validDate(review.due)
            && validDate(record.proficientAt) && validDate(record.masteredAt)
    }

    private static func validate(_ record: NodeRecord) -> Bool {
        validCount(record.attempts) && validDate(record.clearedAt)
    }

    private static func validate(_ record: StreakRecord) -> Bool {
        validCount(record.current) && validCount(record.longest)
            && (0...StreakRecord.maxFreezes).contains(record.freezesRemaining)
    }

    private static func validate(_ answer: AnswerRecord) -> Bool {
        guard !answer.concept.isEmpty, validDate(answer.at) else { return false }
        if let loss = answer.evLoss {
            guard loss.isFinite, (0...1_000_000).contains(loss) else { return false }
        }
        if let interval = answer.interval {
            let values = [interval.point, interval.lo, interval.hi, interval.truth]
            guard values.allSatisfy(\.isFinite),
                  values.allSatisfy({ (-1_000_000...1_000_000).contains($0) }),
                  interval.lo <= interval.point, interval.point <= interval.hi
            else { return false }
        }
        return true
    }

    private static func validate(_ summary: DailyPracticeSummary) -> Bool {
        let key = summary.key
        return !key.concept.isEmpty && !key.mode.isEmpty
            && (1...1_000_000).contains(key.formatVersion)
            && ["ko", "en"].contains(key.language)
            && validCount(summary.exact) && validCount(summary.near)
            && validCount(summary.miss) && validCount(summary.eligibleCorrectCount)
            && summary.eligibleCorrectCount <= summary.exact + summary.near
            && summary.eligibleCorrectSeconds.isFinite
            && summary.eligibleCorrectSeconds >= 0
            && summary.decisionLossBB.isFinite && summary.decisionLossBB >= 0
            && validCount(summary.decisionLossCount)
            && summary.decisionLossCount <= summary.total
    }

    private static func validate(_ evidence: PracticeEvidence) -> Bool {
        !evidence.attemptID.isEmpty && validate(DailyPracticeSummary(key: evidence.key))
            && validDate(evidence.at)
            && ["spotOn", "close", "off"].contains(evidence.band)
            && evidence.eligibleCorrectSeconds.map { $0.isFinite && $0 >= 0 } ?? true
            && evidence.decisionLossBB.map { $0.isFinite && $0 >= 0 } ?? true
    }

    private static func validate(_ round: PracticeRound, verifyAnswers: Bool) -> Bool {
        guard !round.id.isEmpty, let concept = Concept(rawValue: round.concept),
              round.formatVersion == 1,
              round.questionCount == 5,
              (0..<round.questionCount).contains(round.ordinal),
              round.answers.count <= round.questionCount,
              (round.introPhase == nil || (round.ordinal == 0
                  && round.phase == .question && round.answers.isEmpty)),
              validTeaching(round.showBeatIndex, concept: concept,
                  seed: round.seed, verifyAnswers: verifyAnswers),
              validateGuided(draft: round.guidedDraft, answer: round.guidedAnswer,
                  concept: concept, seed: round.seed,
                  isTogether: round.introPhase == .together,
                  verifyAnswers: verifyAnswers),
              Set(round.answers.map(\.attemptID)).count == round.answers.count,
              validHelp(round.helpOrdinal, ordinal: round.ordinal,
                        count: round.questionCount)
                  && (round.helpOrdinal == nil || round.introPhase == nil),
              round.guidedAnswer?.assisted == nil,
              validateDraft(round.draft, ordinal: round.ordinal, concept: concept,
                            phaseIsQuestion: round.phase == .question
                                && round.introPhase == nil),
              round.answers.enumerated().allSatisfy({ index, answer in
                  answer.ordinal == index && !answer.attemptID.isEmpty
                      && validDate(answer.submittedAt)
                      && ["spotOn", "close", "off"].contains(answer.band)
                      && validateSavedAnswer(answer, concept: concept,
                          seed: round.seed, index: index + 2, verifyAnswers: verifyAnswers)
              })
        else { return false }
        switch round.phase {
        case .question: return round.answers.count == round.ordinal
        case .reveal: return round.answers.count == round.ordinal + 1
        case .finished: return round.answers.count == round.questionCount
        }
    }

    private static func validate(_ placement: PlacementState) -> Bool {
        placement.assessmentVersion == PlacementGuide.version
            && validDate(placement.completedAt)
            && placement.answers.keys.allSatisfy({ PlacementGuide.questionIDs.contains($0) })
            && placement.answers.values.allSatisfy({ $0.count <= 100 })
            && (placement.recommendedConcept == nil
                || Concept.allCases.contains { $0.rawValue == placement.recommendedConcept })
    }

    private static func validate(_ session: NodeSessionSnapshot,
                                 verifyAnswers: Bool) -> Bool {
        guard !session.id.isEmpty, let node = Curriculum.node(id: session.nodeID),
              let taught = Curriculum.taughtConcept(of: node)
                ?? Curriculum.concepts(of: node).first,
              session.formatVersion == 1,
              !session.scheduledConcepts.isEmpty,
              session.scheduledConcepts == Curriculum.sessionConcepts(for: node, seed: session.seed)
                .map(\.rawValue),
              session.answers.count <= session.scheduledConcepts.count,
              validTeaching(session.showBeatIndex, concept: taught,
                  seed: session.seed, verifyAnswers: verifyAnswers),
              validateGuided(draft: session.guidedDraft, answer: session.guidedAnswer,
                  concept: taught, seed: session.seed,
                  isTogether: session.phase == .together,
                  verifyAnswers: verifyAnswers),
              Set(session.answers.map(\.answer.attemptID)).count == session.answers.count,
              validHelp(session.helpOrdinal, ordinal: session.ordinal,
                        count: session.scheduledConcepts.count),
              session.guidedAnswer?.assisted == nil,
              (0..<session.scheduledConcepts.count).contains(session.ordinal),
              Concept(rawValue: session.scheduledConcepts[session.ordinal])
                .map({ validateDraft(session.draft, ordinal: session.ordinal,
                    concept: $0, phaseIsQuestion: session.phase == .question) }) == true,
              session.answers.enumerated().allSatisfy({ index, graded in
                  graded.concept == session.scheduledConcepts[index]
                      && graded.answer.ordinal == index
                      && !graded.answer.attemptID.isEmpty
                      && validDate(graded.answer.submittedAt)
                      && Concept(rawValue: graded.concept)
                        .map({ validateSavedAnswer(graded.answer, concept: $0,
                            seed: session.seed, index: index + 2,
                            verifyAnswers: verifyAnswers) }) == true
              }) else { return false }
        switch session.phase {
        case .show, .together, .question:
            return session.answers.count == session.ordinal
        case .reveal:
            return session.answers.count == session.ordinal + 1
        case .finished:
            return session.answers.count == session.scheduledConcepts.count
        }
    }

    /// Help belongs to one question that has already been reached.
    private static func validHelp(_ helpOrdinal: Int?, ordinal: Int, count: Int) -> Bool {
        guard let helpOrdinal else { return true }
        return (0..<count).contains(helpOrdinal) && helpOrdinal <= ordinal
    }

    private static func validateSavedAnswer(_ answer: RoundAnswer, concept: Concept,
                                            seed: UInt64, index: Int,
                                            verifyAnswers: Bool) -> Bool {
        guard answer.assisted != false,
              answer.input.count <= 4_096, answer.reveal.count <= 4_096,
              let input = try? JSONDecoder().decode(SavedDrillInput.self, from: answer.input),
              let reveal = try? JSONDecoder().decode(SavedDrillReveal.self, from: answer.reveal),
              input.isValid(for: concept), reveal.isValid, reveal.band == answer.band
        else { return false }
        let needsInterval: Bool
        switch concept {
        case .equitySense, .evCall, .hitFrequency, .rangeAdvantage, .actionRead:
            needsInterval = true
        default: needsInterval = false
        }
        guard (reveal.interval != nil) == needsInterval else { return false }
        guard (reveal.evLoss != nil) == (concept == .evLoss) else { return false }
        return !verifyAnswers || SavedDrillScore.matches(
            concept: concept, seed: seed, index: index, input: input, reveal: reveal)
    }

    private static func validateDraft(_ draft: SavedDrillDraft?, ordinal: Int,
                                      concept: Concept, phaseIsQuestion: Bool) -> Bool {
        guard let draft else { return true }
        return phaseIsQuestion && draft.ordinal == ordinal
            && draft.concept == concept.rawValue && draft.input.isValid(for: concept)
    }

    private static func validTeaching(_ beatIndex: Int?, concept: Concept,
                                      seed: UInt64, verifyAnswers: Bool) -> Bool {
        let index = beatIndex ?? 0
        guard (0...100).contains(index) else { return false }
        return !verifyAnswers || index < TeachingBeatCount.count(concept, seed: seed)
    }

    private static func validateGuided(draft: SavedDrillDraft?, answer: RoundAnswer?,
                                       concept: Concept, seed: UInt64,
                                       isTogether: Bool, verifyAnswers: Bool) -> Bool {
        guard isTogether else { return draft == nil && answer == nil }
        guard !(draft != nil && answer != nil),
              validateDraft(draft, ordinal: 0, concept: concept,
                            phaseIsQuestion: answer == nil) else { return false }
        guard let answer else { return true }
        return answer.ordinal == 0 && !answer.attemptID.isEmpty
            && validDate(answer.submittedAt)
            && validateSavedAnswer(answer, concept: concept, seed: seed,
                                   index: 1, verifyAnswers: verifyAnswers)
    }

    private static func validate(_ session: ReviewSessionSnapshot,
                                 verifyAnswers: Bool) -> Bool {
        guard !session.id.isEmpty, session.formatVersion == 1,
              (1...5).contains(session.scheduledConcepts.count),
              session.scheduledConcepts.allSatisfy({ Concept(rawValue: $0) != nil }),
              Set(session.scheduledConcepts).count == session.scheduledConcepts.count,
              (0..<session.scheduledConcepts.count).contains(session.ordinal),
              session.answers.count <= session.scheduledConcepts.count,
              Set(session.answers.map(\.answer.attemptID)).count == session.answers.count,
              validHelp(session.helpOrdinal, ordinal: session.ordinal,
                        count: session.scheduledConcepts.count),
              Concept(rawValue: session.scheduledConcepts[session.ordinal])
                .map({ validateDraft(session.draft, ordinal: session.ordinal,
                    concept: $0, phaseIsQuestion: session.phase == .question) }) == true,
              session.answers.enumerated().allSatisfy({ index, graded in
                  graded.concept == session.scheduledConcepts[index]
                      && graded.answer.ordinal == index
                      && !graded.answer.attemptID.isEmpty
                      && validDate(graded.answer.submittedAt)
                      && Concept(rawValue: graded.concept)
                        .map({ validateSavedAnswer(graded.answer, concept: $0,
                            seed: session.seed, index: index + 2,
                            verifyAnswers: verifyAnswers) }) == true
              }) else { return false }
        switch session.phase {
        case .question: return session.answers.count == session.ordinal
        case .reveal: return session.answers.count == session.ordinal + 1
        case .finished: return session.answers.count == session.scheduledConcepts.count
        }
    }
}
