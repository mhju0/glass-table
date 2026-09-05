// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

public enum StoreError: Error, Equatable {
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case notDecodable
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
            let state = try importData(Data(contentsOf: url))
            return .loaded(state)
        } catch {
            return .unreadable(String(describing: error))
        }
    }

    /// Atomic so a kill mid-write can never truncate the live file: Foundation writes
    /// to a sibling temp file and renames, and rename is atomic on APFS. Throws rather
    /// than swallowing, because a save that silently fails is how progress disappears.
    public func save(_ state: ProgressState) throws {
        try write(exportData(state))
    }

    /// Preserve the existing bytes before an explicit reset or import. Copy rather
    /// than move: if the replacement write fails (or the app exits), the live file
    /// still contains the original progress. A failed copy must abort replacement.
    @discardableResult
    public func replace(with state: ProgressState) throws -> URL? {
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
    public func exportData() throws -> Data { try Data(contentsOf: url) }

    /// Encode in-memory progress too, including answers awaiting a successful save.
    public func exportData(_ state: ProgressState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(state)
    }

    /// Validates before returning; the caller decides whether to `save` the result.
    public func importData(_ data: Data) throws -> ProgressState {
        let state: ProgressState
        do { state = try JSONDecoder().decode(ProgressState.self, from: data) }
        catch { throw StoreError.notDecodable }
        guard state.schemaVersion <= ProgressState.currentSchemaVersion else {
            throw StoreError.unsupportedSchemaVersion(
                found: state.schemaVersion, supported: ProgressState.currentSchemaVersion)
        }
        return state
    }
}
