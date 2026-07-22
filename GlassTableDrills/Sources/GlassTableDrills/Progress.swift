// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// Per-drill local progress. Named `DrillProgress` to avoid colliding with `Foundation.Progress`.
public struct DrillProgress: Codable, Equatable {
    public var streak: Int
    public var correct: Int   // count of 정확 (spot-on)
    public var total: Int

    public init(streak: Int = 0, correct: Int = 0, total: Int = 0) {
        self.streak = streak; self.correct = correct; self.total = total
    }

    public var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }

    /// Progress after one graded answer. Streak counts consecutive non-off answers
    /// (정확 or 근접); a 빗나감 resets it.
    public func recording(_ band: GradeBand) -> DrillProgress {
        var p = self
        p.total += 1
        if band == .spotOn { p.correct += 1 }
        p.streak = (band == .off) ? 0 : p.streak + 1
        return p
    }
}

public struct ProgressStore {
    let url: URL
    public init(url: URL) { self.url = url }

    public func load() -> DrillProgress {
        (try? JSONDecoder().decode(DrillProgress.self, from: Data(contentsOf: url))) ?? DrillProgress()
    }
    public func save(_ p: DrillProgress) {
        try? JSONEncoder().encode(p).write(to: url)
    }

    /// Default on-device store in Application Support.
    public static func standard() -> ProgressStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return ProgressStore(url: dir.appendingPathComponent("outs-progress.json"))
    }
}
