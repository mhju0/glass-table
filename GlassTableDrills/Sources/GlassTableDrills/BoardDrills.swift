// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

// MARK: - 히트 프리퀀시

/// A board plus a named opening range: *what share of that range has a pair or better?*
///
/// The range is always one the app can print — a seat's RFI chart — so the reveal can
/// show the exact 169 cells the number came from. That is the transparency claim the
/// whole product rests on, applied to a postflop question.
public struct HitFrequencySpot: Equatable {
    public let seat: Position
    public let board: [Card]

    public init(seat: Position, board: [Card]) {
        self.seat = seat; self.board = board
    }

    public var range: HandRange { RFIChart.range(for: seat) }
    public var distribution: RangeOnBoard { rangeOnBoard(range, board: board) }
    public var texture: BoardTexture { boardTexture(board) }

    /// Graded on pair-or-better, not on `hitRate` — a draw is not a made hand, and the
    /// number that drives a bet is the made one (spec §1).
    public var pairOrBetterPct: Double { distribution.pairOrBetter * 100 }
}

public enum HitFrequencySpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> HitFrequencySpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        var deck = Deck.all
        deck.shuffle(using: &rng)
        return HitFrequencySpot(seat: RFIChart.seats.randomElement(using: &rng)!,
                                board: Array(deck[0..<3]))
    }
}

public func gradeHitFrequency(estimate: Estimate, spot: HitFrequencySpot) -> EstimateReveal {
    // One pass over the range's combos, not two: `pairOrBetterPct` is a reading off
    // this same distribution, and building it twice was half the cost of grading.
    let d = spot.distribution
    let correct = d.pairOrBetter * 100
    return EstimateReveal(
        // Wider than the equity bands: this is a distribution read, not a calculation,
        // and nobody counts 1326 combos in their head.
        band: gradeEstimate(user: estimate.point, correct: correct,
                            closeWithin: 12, spotOnWithin: 5),
        estimate: estimate, correct: correct,
        intervalAnswer: estimate.answer(truth: correct),
        whyText: "\(spot.seat.rawValue) 오픈 레인지 \(d.liveCombos)콤보 중 "
               + "\(pctText(correct))%가 페어 이상이에요. "
               + "드로우까지 포함하면 \(pctText(d.hitRate * 100))%. "
               + "\(spot.texture.summary).")
}

// MARK: - 레인지 어드밴티지

/// Two ranges on one board: *whose range does this flop favour?*
///
/// The opener holds a seat's RFI chart; the caller holds an archetype's calling band,
/// so both sides are declared and printable — the same construction R3 grades reads
/// against.
public struct RangeAdvantageSpot: Equatable {
    public let openerSeat: Position
    public let callerSeat: Position
    public let caller: Archetype
    public let board: [Card]

    public init(openerSeat: Position, callerSeat: Position, caller: Archetype,
                board: [Card]) {
        self.openerSeat = openerSeat; self.callerSeat = callerSeat
        self.caller = caller; self.board = board
    }

    public var openerRange: HandRange { RFIChart.range(for: openerSeat) }
    public var callerRange: HandRange { caller.callRange(from: callerSeat) }

    /// The opener's share of the pot at showdown. Sampled — see `rangeEquity`.
    public var openerEquityPct: Double {
        rangeEquity(hero: openerRange, villain: callerRange, board: board) * 100
    }

    public var texture: BoardTexture { boardTexture(board) }
}

public enum RangeAdvantageSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> RangeAdvantageSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        var deck = Deck.all
        deck.shuffle(using: &rng)
        // The caller has to act after the opener, so the opener cannot be the last
        // seat that opens. Picking the opener freely and falling back to a fixed seat
        // was wrong in exactly that case: an SB open has nobody behind it but the big
        // blind, and the fallback handed back a seat that acts *earlier*.
        let openers = RFIChart.seats.filter { seat in
            RFIChart.seats.contains {
                $0.playersBehind(preflop: true) < seat.playersBehind(preflop: true)
            }
        }
        let opener = openers.randomElement(using: &rng)!
        let caller = RFIChart.seats.filter {
            $0.playersBehind(preflop: true) < opener.playersBehind(preflop: true)
        }.randomElement(using: &rng)!
        return RangeAdvantageSpot(openerSeat: opener, callerSeat: caller,
                                  caller: Archetype.allCases.randomElement(using: &rng)!,
                                  board: Array(deck[0..<3]))
    }
}

/// `openerEquityPct` may be passed in when the caller already computed it off the main
/// thread — the sampling is milliseconds in release but over a second in debug, so the
/// UI computes it ahead of the tap rather than during it.
public func gradeRangeAdvantage(estimate: Estimate, spot: RangeAdvantageSpot,
                                openerEquityPct: Double? = nil) -> EstimateReveal {
    let correct = openerEquityPct ?? spot.openerEquityPct
    let o = rangeOnBoard(spot.openerRange, board: spot.board)
    let c = rangeOnBoard(spot.callerRange, board: spot.board)
    let who = correct > 52 ? "오프너가 앞서요" : (correct < 48 ? "콜러가 앞서요" : "거의 반반이에요")
    return EstimateReveal(
        band: gradeEstimate(user: estimate.point, correct: correct,
                            closeWithin: 10, spotOnWithin: 4),
        estimate: estimate, correct: correct,
        intervalAnswer: estimate.answer(truth: correct),
        whyText: "\(spot.texture.summary). \(who) — 오프너 \(pctText(correct))%. "
               + widestGapSentence(opener: o, caller: c) + " "
               + "표본 추출로 계산한 값이라 ±1% 정도 오차가 있어요.")
}

/// Names whichever bucket the two ranges differ on **most**, rather than always
/// reporting two-pair-plus.
///
/// Hardcoding 투페어 이상 produced headlines like "2.7% 대 0%" on boards where the real
/// story was top pair 24% against nothing — comparing two near-zero numbers and calling
/// it the lesson.
func widestGapSentence(opener: RangeOnBoard, caller: RangeOnBoard) -> String {
    let bucket = MadeHand.allCases.max {
        abs(opener.share($0) - caller.share($0)) < abs(opener.share($1) - caller.share($1))
    } ?? .strong
    let a = opener.share(bucket) * 100, b = caller.share(bucket) * 100
    return "가장 크게 갈리는 건 \(bucket.korean) — "
         + "오프너 \(pctText(a))% 대 콜러 \(pctText(b))%."
}
