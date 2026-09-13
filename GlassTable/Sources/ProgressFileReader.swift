// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableDrills

struct PreparedProgressImport: Sendable {
    let state: ProgressState
}

enum ProgressFileReader {
    static func readAndValidate(_ url: URL) async throws -> PreparedProgressImport {
        try await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try ProgressionStore.readImportData(at: url)
            let state = try ProgressionStore(url: url).importData(data)
            try Task.checkCancellation()
            return PreparedProgressImport(state: state)
        }.value
    }
}
