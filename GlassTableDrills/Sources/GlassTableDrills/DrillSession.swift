// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// A drill's graded result. Each drill's Reveal carries the user's answer plus
/// whatever its reveal screen needs; `band` is what progress tracking consumes.
public protocol GradedReveal: Equatable { var band: GradeBand { get } }

/// Pure state machine for one drill run, shared by all drills. In-progress input
/// is view state; the session only sees the committed answer.
public struct DrillSession<Spot: Equatable, Answer, Reveal: GradedReveal> {
    public enum Phase: Equatable {
        case deciding(spot: Spot)
        case revealed(spot: Spot, reveal: Reveal)
    }

    public let baseSeed: UInt64
    public private(set) var index: Int
    public private(set) var phase: Phase
    public private(set) var progress: DrillProgress
    private let generate: (UInt64, Int) -> Spot
    private let grade: (Answer, Spot) -> Reveal

    public init(baseSeed: UInt64, progress: DrillProgress = DrillProgress(),
                generate: @escaping (UInt64, Int) -> Spot,
                grade: @escaping (Answer, Spot) -> Reveal) {
        self.baseSeed = baseSeed
        self.index = 0
        self.progress = progress
        self.generate = generate
        self.grade = grade
        self.phase = .deciding(spot: generate(baseSeed, 0))
    }

    public mutating func commit(_ answer: Answer) {
        guard case let .deciding(spot) = phase else { return }
        let reveal = grade(answer, spot)
        progress = progress.recording(reveal.band)
        phase = .revealed(spot: spot, reveal: reveal)
    }

    public mutating func next() {
        index += 1
        phase = .deciding(spot: generate(baseSeed, index))
    }
}
