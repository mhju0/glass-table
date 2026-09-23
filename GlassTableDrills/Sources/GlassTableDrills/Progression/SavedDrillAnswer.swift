// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// Version-1 wire form for a submitted answer. It contains only language-neutral
/// choices; spot generation and grading recreate display copy from seed and index.
public enum SavedDrillInput: Codable, Equatable, Sendable {
    case integer(Int)
    case boolean(Bool)
    case interval(point: Double, lo: Double, hi: Double)
    case range(width: Double, tendencies: [String])
    case action(String)

    public func isValid(for concept: Concept) -> Bool {
        switch (concept, self) {
        case let (.showdown, .integer(value)): return (0...2).contains(value)
        case let (.position, .integer(value)): return (0...7).contains(value)
        case let (.potMath, .integer(value)), let (.outs, .integer(value)),
             let (.combos, .integer(value)), let (.rangeNotation, .integer(value)):
            return (0...1_000_000).contains(value)
        case let (.potOdds, .integer(value)), let (.mdf, .integer(value)):
            return (0...100).contains(value)
        case (.callFold, .boolean), (.rfi, .boolean), (.evLoss, .boolean):
            return true
        case let (.rangeRead, .range(width, tendencies)):
            return width.isFinite && (3...80).contains(width)
                && tendencies.count <= RangeTendency.allCases.count
                && Set(tendencies).count == tendencies.count
                && tendencies.allSatisfy { RangeTendency(rawValue: $0) != nil }
        case let (.defend, .action(raw)):
            return DefendAction(rawValue: raw) != nil
        case let (.equitySense, .interval(point, lo, hi)),
             let (.hitFrequency, .interval(point, lo, hi)),
             let (.rangeAdvantage, .interval(point, lo, hi)),
             let (.actionRead, .interval(point, lo, hi)):
            return [point, lo, hi].allSatisfy(\.isFinite)
                && (0...100).contains(lo) && lo <= point && point <= hi
                && (0...100).contains(hi)
        case let (.evCall, .interval(point, lo, hi)):
            return [point, lo, hi].allSatisfy(\.isFinite)
                && (-100...100).contains(lo) && lo <= point && point <= hi
                && (-100...100).contains(hi)
        default: return false
        }
    }
}

public struct SavedDrillReveal: Codable, Equatable, Sendable {
    public let version: Int
    public let band: String
    public let interval: IntervalAnswer?
    public let evLoss: Double?

    public init(version: Int = 1, band: String,
                interval: IntervalAnswer? = nil, evLoss: Double? = nil) {
        self.version = version; self.band = band
        self.interval = interval; self.evLoss = evLoss
    }

    public var isValid: Bool {
        guard version == 1,
              GradeBand(rawValue: band) != nil,
              evLoss.map({ $0.isFinite && (0...1_000_000).contains($0) }) ?? true
        else { return false }
        guard let interval else { return true }
        return [interval.point, interval.lo, interval.hi, interval.truth]
            .allSatisfy { $0.isFinite && (-1_000_000...1_000_000).contains($0) }
            && interval.lo <= interval.point && interval.point <= interval.hi
    }
}

/// Used only when accepting bytes from disk or an import. Ordinary writes keep the
/// cheap shape check, while an untrusted saved reveal must agree with the real spot.
enum SavedDrillScore {
    static func matches(concept: Concept, seed: UInt64, index: Int,
                        input: SavedDrillInput, reveal: SavedDrillReveal) -> Bool {
        let actual: (band: GradeBand, interval: IntervalAnswer?, evLoss: Double?)?
        switch (concept, input) {
        case let (.showdown, .integer(value)):
            actual = (gradeShowdown(answer: value,
                spot: ShowdownSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.potMath, .integer(value)):
            actual = (gradePotMath(answer: value,
                spot: PotMathSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.position, .integer(value)):
            actual = (gradePosition(answer: value,
                spot: PositionSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.outs, .integer(value)):
            actual = (gradeOuts(estimate: value,
                spot: OutsSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.combos, .integer(value)):
            actual = (gradeBlocker(estimate: value,
                spot: BlockerSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.potOdds, .integer(value)):
            actual = (gradePotOdds(estimatePct: value,
                spot: BetSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.mdf, .integer(value)):
            actual = (gradeMDF(estimatePct: value,
                spot: BetSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.callFold, .boolean(value)):
            actual = (gradeCallFold(userCalls: value,
                spot: CallFoldSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.rangeNotation, .integer(value)):
            actual = (gradeRangeNotation(estimate: value,
                spot: RangeNotationSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.rfi, .boolean(value)):
            actual = (gradeRFI(userOpens: value,
                spot: RFISpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.rangeRead, .range(width, tendencies)):
            let selected = Set(tendencies.compactMap(RangeTendency.init(rawValue:)))
            actual = (gradeRangeRead(
                estimate: RangeEstimate(width: width, tendencies: selected),
                spot: RangeReadSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.evLoss, .boolean(value)):
            let result = gradeEVLoss(userCalls: value,
                spot: EVLossSpotGenerator.spot(baseSeed: seed, index: index))
            actual = (result.band, nil, result.grade.loss)
        case let (.defend, .action(raw)):
            guard let choice = DefendAction(rawValue: raw) else { return false }
            actual = (gradeDefend(chosen: choice,
                spot: DefendSpotGenerator.spot(baseSeed: seed, index: index)).band, nil, nil)
        case let (.equitySense, .interval(point, lo, hi)):
            let result = gradeEquitySense(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: EquitySenseSpotGenerator.spot(baseSeed: seed, index: index))
            actual = (result.band, result.intervalAnswer, nil)
        case let (.evCall, .interval(point, lo, hi)):
            let result = gradeEVCall(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: EVCallSpotGenerator.spot(baseSeed: seed, index: index))
            actual = (result.band, result.intervalAnswer, nil)
        case let (.hitFrequency, .interval(point, lo, hi)):
            let result = gradeHitFrequency(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: HitFrequencySpotGenerator.spot(baseSeed: seed, index: index))
            actual = (result.band, result.intervalAnswer, nil)
        case let (.rangeAdvantage, .interval(point, lo, hi)):
            let spot = RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradeRangeAdvantage(
                estimate: Estimate(point: point, lo: lo, hi: hi), spot: spot,
                openerEquityPct: spot.openerEquityPct)
            actual = (result.band, result.intervalAnswer, nil)
        case let (.actionRead, .interval(point, lo, hi)):
            let result = gradeActionRead(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: ActionReadSpotGenerator.spot(baseSeed: seed, index: index))
            actual = (result.band, result.intervalAnswer, nil)
        default:
            return false
        }
        guard let actual, actual.band.rawValue == reveal.band else { return false }
        if let expected = actual.interval, let saved = reveal.interval {
            return near(expected.point, saved.point)
                && near(expected.lo, saved.lo) && near(expected.hi, saved.hi)
                && near(expected.truth, saved.truth)
                && reveal.evLoss == nil
        }
        if actual.interval != nil || reveal.interval != nil { return false }
        if let expected = actual.evLoss, let saved = reveal.evLoss {
            return near(expected, saved)
        }
        return actual.evLoss == nil && reveal.evLoss == nil
    }

    private static func near(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) <= 0.000_001
    }
}
