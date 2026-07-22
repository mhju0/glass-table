// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Pure state machine for one Outs-drill run. The app wraps this in an @Observable model.
public struct DrillSession: Equatable {
    public enum Phase: Equatable {
        case deciding(spot: OutsSpot, estimate: Int)
        case revealed(spot: OutsSpot, estimate: Int, reveal: Reveal)
    }

    public let baseSeed: UInt64
    public private(set) var index: Int
    public private(set) var phase: Phase
    public private(set) var progress: DrillProgress

    static let initialEstimate = 8

    public init(baseSeed: UInt64, progress: DrillProgress = DrillProgress()) {
        self.baseSeed = baseSeed
        self.index = 0
        self.progress = progress
        self.phase = .deciding(spot: OutsSpotGenerator.spot(baseSeed: baseSeed, index: 0),
                               estimate: Self.initialEstimate)
    }

    public mutating func adjustEstimate(_ delta: Int) {
        guard case let .deciding(spot, estimate) = phase else { return }
        phase = .deciding(spot: spot, estimate: max(0, min(21, estimate + delta)))
    }

    public mutating func commit() {
        guard case let .deciding(spot, estimate) = phase else { return }
        let reveal = gradeOuts(estimate: estimate, spot: spot)
        progress = progress.recording(reveal.band)
        phase = .revealed(spot: spot, estimate: estimate, reveal: reveal)
    }

    public mutating func next() {
        index += 1
        phase = .deciding(spot: OutsSpotGenerator.spot(baseSeed: baseSeed, index: index),
                          estimate: Self.initialEstimate)
    }
}
