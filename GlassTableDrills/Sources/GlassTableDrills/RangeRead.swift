// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// One Range Read spot: you see the action, never the cards, and estimate what the
/// villain holds.
public struct RangeReadSpot: Equatable {
    public enum Action: Equatable, Sendable {
        /// Villain opened first in from `seat`.
        case opened(Position)
        /// Villain called an open that came from `opener`.
        case called(seat: Position, opener: Position)
    }

    public let archetype: Archetype
    public let action: Action
    /// Whether the drill names the opponent. Reading *which* opponent this is from
    /// their actions is most of the skill, but hiding it makes a first exposure
    /// nearly impossible — so it is a difficulty band, not a fixed choice.
    public let archetypeShown: Bool

    public init(archetype: Archetype, action: Action, archetypeShown: Bool) {
        self.archetype = archetype; self.action = action
        self.archetypeShown = archetypeShown
    }

    /// The declared range the estimate is graded against.
    public var trueRange: HandRange {
        switch action {
        case let .opened(seat): return archetype.raiseRange(from: seat)
        case let .called(seat, _): return archetype.callRange(from: seat)
        }
    }

    public var seat: Position {
        switch action {
        case let .opened(s): return s
        case let .called(s, _): return s
        }
    }

    /// Plain-Korean action history, the only thing the user gets to see.
    public var actionLines: [String] {
        switch action {
        case let .opened(seat):
            return ["\(seat.rawValue) 오픈 3bb", "이후 전원 폴드"]
        case let .called(seat, opener):
            return ["\(opener.rawValue) 오픈 3bb", "\(seat.rawValue) 콜", "이후 전원 폴드"]
        }
    }
}

public enum RangeReadSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> RangeReadSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let archetype = Archetype.allCases.randomElement(using: &rng)!
        let seat = RFIChart.seats.randomElement(using: &rng)!
        // A call needs somebody to have opened in front, so it needs a seat that acts
        // after one. Opening is always available.
        let openersBefore = RFIChart.seats.filter {
            $0.playersBehind(preflop: true) > seat.playersBehind(preflop: true)
        }
        let action: RangeReadSpot.Action
        if let opener = openersBefore.randomElement(using: &rng), Bool.random(using: &rng) {
            action = .called(seat: seat, opener: opener)
        } else {
            action = .opened(seat)
        }
        // Named for the first exposures, hidden later — the band the spec calls for.
        return RangeReadSpot(archetype: archetype, action: action,
                             archetypeShown: index < 3 || Int.random(in: 0..<3, using: &rng) > 0)
    }
}

/// What the user built with the slider and the chips.
public struct RangeEstimate: Equatable, Sendable {
    public let width: Double
    public let tendencies: Set<RangeTendency>

    public init(width: Double, tendencies: Set<RangeTendency> = []) {
        self.width = width; self.tendencies = tendencies
    }

    public var range: HandRange { .shaped(width: width, tendencies: tendencies) }
}

public struct RangeReadReveal: GradedReveal {
    public let band: GradeBand
    public let overlap: Double
    public let guess: HandRange
    public let truth: HandRange
    public let whyText: String
}

/// Overlap thresholds. Estimation bands rather than pass/fail, because a read *is* an
/// estimate — the same rule that keeps 근접 off the exact drills keeps it on this one.
public enum RangeReadGrading {
    public static let spotOn = 0.70
    public static let close = 0.45
}

public func gradeRangeRead(estimate: RangeEstimate, spot: RangeReadSpot) -> RangeReadReveal {
    let guess = estimate.range
    let truth = spot.trueRange
    let overlap = guess.jaccard(truth)

    let band: GradeBand = overlap >= RangeReadGrading.spotOn ? .spotOn
        : (overlap >= RangeReadGrading.close ? .close : .off)

    return RangeReadReveal(band: band, overlap: overlap, guess: guess, truth: truth,
                           whyText: explain(guess: guess, truth: truth, spot: spot))
}

/// "0.52" teaches nothing. Name the direction: too wide, too tight, or the right width
/// with the wrong shape — and when it is shape, name the category that differed most.
func explain(guess: HandRange, truth: HandRange, spot: RangeReadSpot) -> String {
    let gw = guess.percent, tw = truth.percent
    let head = "\(spot.archetype.name)의 \(actionWord(spot)) 레인지는 상위 "
             + "\(pctText(tw))%예요. 내 추정은 \(pctText(gw))%."

    // A fifth off in width is the line where width, rather than shape, is the story.
    if gw > tw * 1.2 {
        return head + " 너무 넓게 봤어요 — \(spot.archetype.blurb)."
    }
    if gw < tw * 0.8 {
        return head + " 너무 좁게 봤어요 — \(spot.archetype.blurb)."
    }
    // Similar widths: whichever category the truth leans on hardest that the guess
    // does not is the thing that was actually misread.
    let worst = RangeTendency.allCases.max {
        (truth.tendencyShare($0) - guess.tendencyShare($0))
            < (truth.tendencyShare($1) - guess.tendencyShare($1))
    }
    if let t = worst, truth.tendencyShare(t) - guess.tendencyShare(t) > 0.08 {
        return head + " 넓이는 비슷한데 모양이 달라요 — \(tendencyWord(t))가 더 많아요."
    }
    return head + " 모양도 비슷해요."
}

func actionWord(_ spot: RangeReadSpot) -> String {
    switch spot.action {
    case .opened: return "오픈"
    case .called: return "콜"
    }
}

public func tendencyWord(_ t: RangeTendency) -> String {
    switch t {
    case .pairs: return "페어"
    case .suited: return "수티드"
    case .offsuitBroadway: return "오프수트 브로드웨이"
    case .connectors: return "커넥터"
    }
}
