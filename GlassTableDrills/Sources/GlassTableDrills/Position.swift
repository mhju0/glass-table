// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Seats at an 8-max table, in preflop order of action.
///
/// **Lives in Drills, not Engine** — spec §8.4 put it in `GlassTableEngine`, but the
/// engine's stated job is "pure poker math, correctness-proven, release-mode gate"
/// and nothing here is math or used by the engine. Keeping it out also leaves
/// `git diff main -- GlassTableEngine` empty, so R1 never pays the slow release gate
/// for a table of seat names.
///
/// Names stay Latin per `decisions.md` §F — Korean players write the abbreviations.
public enum Position: String, CaseIterable, Sendable {
    case utg = "UTG", utg1 = "UTG+1", lj = "LJ", hj = "HJ"
    case co = "CO", btn = "BTN", sb = "SB", bb = "BB"

    /// Preflop: blinds are posted, so they act last.
    public static let preflopOrder: [Position] = allCases

    /// Postflop: the blinds act first, and the button acts last on every street.
    /// This inversion is the whole reason position is worth a drill.
    public static let postflopOrder: [Position] = [.sb, .bb, .utg, .utg1, .lj, .hj, .co, .btn]

    public var isBlind: Bool { self == .sb || self == .bb }

    /// How many seats still act after this one on the given street. The number a
    /// beginner has to feel before any range chart means anything.
    public func playersBehind(preflop: Bool) -> Int {
        let order = preflop ? Self.preflopOrder : Self.postflopOrder
        guard let i = order.firstIndex(of: self) else { return 0 }
        return order.count - 1 - i
    }

    /// Later position = more information = better. Compares on postflop order,
    /// because that is the order that holds for three of the four streets.
    public func actsAfter(_ other: Position) -> Bool {
        guard let a = Self.postflopOrder.firstIndex(of: self),
              let b = Self.postflopOrder.firstIndex(of: other) else { return false }
        return a > b
    }
}

/// One 포지션 spot: a seat, a street, and which of the two questions is asked.
public struct PositionSpot: Equatable {
    public enum Question: Equatable {
        /// "How many act after you?"
        case behind(Position, preflop: Bool)
        /// "Which of these two seats is better?" — better meaning acts later.
        case whichIsLater(Position, Position)
    }
    public let question: Question

    public init(question: Question) { self.question = question }

    /// The provably correct answer: a count, or the index of the better seat (0 or 1).
    public var correctAnswer: Int {
        switch question {
        case let .behind(p, preflop): return p.playersBehind(preflop: preflop)
        case let .whichIsLater(a, b): return b.actsAfter(a) ? 1 : 0
        }
    }
}

public enum PositionSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> PositionSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        // Two thirds counting, one third comparison — the count is the load-bearing
        // skill, the comparison is the check that it generalised.
        if Int.random(in: 0..<3, using: &rng) < 2 {
            let seat = Position.allCases.randomElement(using: &rng)!
            return PositionSpot(question: .behind(seat, preflop: Bool.random(using: &rng)))
        }
        var a = Position.allCases.randomElement(using: &rng)!
        var b = Position.allCases.randomElement(using: &rng)!
        while b == a { b = Position.allCases.randomElement(using: &rng)! }
        // Stable ordering from the seed so the same index always renders the same way.
        if Int.random(in: 0..<2, using: &rng) == 1 { swap(&a, &b) }
        return PositionSpot(question: .whichIsLater(a, b))
    }
}

public struct PositionReveal: Equatable {
    public let band: GradeBand
    public let answer: Int
    public let correct: Int
    public let whyText: String
}

public func gradePosition(answer: Int, spot: PositionSpot) -> PositionReveal {
    let correct = spot.correctAnswer
    let why: String
    switch spot.question {
    case let .behind(p, preflop):
        let order = preflop ? Position.preflopOrder : Position.postflopOrder
        let after = order.drop(while: { $0 != p }).dropFirst()
        why = after.isEmpty
            ? "\(p.rawValue)는 \(preflop ? "프리플랍" : "플랍 이후") 마지막이에요 — 뒤에 아무도 없어요."
            : "\(p.rawValue) 뒤: \(after.map(\.rawValue).joined(separator: " · ")) — \(correct)명."
    case let .whichIsLater(a, b):
        let later = correct == 1 ? b : a
        why = "\(later.rawValue)가 더 늦게 행동해요 — 정보를 더 보고 결정할 수 있어요."
    }
    return PositionReveal(band: answer == correct ? .spotOn : .off,
                          answer: answer, correct: correct, whyText: why)
}
