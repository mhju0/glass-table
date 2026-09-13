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
    /// The complete store is normally about 50 KB. Five MiB leaves ample room for
    /// retired dictionary entries while bounding work on an untrusted import.
    public static let maximumFileBytes = 5 * 1024 * 1024
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
            let state = try importData(Self.readData(at: url, maximumBytes: Self.maximumFileBytes))
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
        let state: ProgressState
        do { state = try JSONDecoder().decode(ProgressState.self, from: data) }
        catch { throw StoreError.notDecodable }
        guard state.schemaVersion <= ProgressState.currentSchemaVersion else {
            throw StoreError.unsupportedSchemaVersion(
                found: state.schemaVersion, supported: ProgressState.currentSchemaVersion)
        }
        try Self.validate(state)
        return state
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

    private static func validate(_ state: ProgressState) throws {
        guard state.schemaVersion >= 1,
              state.schemaVersion <= ProgressState.currentSchemaVersion,
              state.concepts.values.allSatisfy(validate),
              state.nodes.values.allSatisfy(validate),
              validate(state.streak),
              state.answers.count <= ProgressState.answerLogCap,
              state.answers.allSatisfy(validate)
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
}
