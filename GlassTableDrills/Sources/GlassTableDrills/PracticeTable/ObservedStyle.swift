// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

public struct PracticeHandObservation: Codable, Equatable, Sendable {
    public let handID: String
    /// Local calendar day, YYYY-MM-DD. Set by the persistence owner at settlement.
    public let day: String
    public let rulesVersion: Int
    public let policyVersion: Int
    public let voluntarilyEntered: Bool
    public let raisedPreflop: Bool

    public init(handID: String, day: String, rulesVersion: Int = PracticeTableState.rulesVersion,
                policyVersion: Int = PracticeTableState.policyVersion,
                voluntarilyEntered: Bool, raisedPreflop: Bool) {
        self.handID = handID; self.day = day
        self.rulesVersion = rulesVersion; self.policyVersion = policyVersion
        self.voluntarilyEntered = voluntarilyEntered; self.raisedPreflop = raisedPreflop
    }
}

public enum PracticeObservedStyle: String, Codable, Sendable {
    case selectiveRaiser, selectiveCaller, wideRaiser, wideCaller, mixed
}

public struct PracticeStyleReport: Equatable, Sendable {
    public let style: PracticeObservedStyle?
    public let hands: Int
    public let days: Int
    public let voluntaryEntries: Int
    public let preflopRaises: Int
    public let participationInterval: ClosedRange<Double>?
    public let raiseShareInterval: ClosedRange<Double>?
    public let firstDay: String?
    public let lastDay: String?
}

public enum PracticeStyleAnalysis {
    /// Product heuristic v1. The Wilson interval quantifies uncertainty; it does not
    /// establish that repeated play against fixed bots is independent evidence.
    public static let version = 1

    public static func report(_ observations: [PracticeHandObservation], asOf day: String) -> PracticeStyleReport {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withFullDate]
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        let today = parser.date(from: day)
        let cutoff = today.flatMap { Calendar(identifier: .gregorian).date(byAdding: .day, value: -29, to: $0) }
        var seen = Set<String>()
        let evidence = observations.reversed().filter { item in
            guard item.rulesVersion == PracticeTableState.rulesVersion,
                  item.policyVersion == PracticeTableState.policyVersion,
                  let date = parser.date(from: item.day), let today, let cutoff,
                  date >= cutoff, date <= today, seen.insert(item.handID).inserted else { return false }
            return true
        }.prefix(200).reversed()
        let hands = evidence.count
        let days = Set(evidence.map(\.day)).count
        let entries = evidence.filter(\.voluntarilyEntered).count
        let raises = evidence.filter { $0.voluntarilyEntered && $0.raisedPreflop }.count
        let p = wilson(successes: entries, trials: hands)
        let r = wilson(successes: raises, trials: entries)
        var style: PracticeObservedStyle?
        if hands >= 100, days >= 5, entries >= 40, let p, let r,
           let entryBand = band(p, lower: 0.30, upper: 0.50),
           let raiseBand = band(r, lower: 0.40, upper: 0.70) {
            switch (entryBand, raiseBand) {
            case (.low, .high): style = .selectiveRaiser
            case (.low, .low): style = .selectiveCaller
            case (.high, .high): style = .wideRaiser
            case (.high, .low): style = .wideCaller
            default: style = .mixed
            }
        }
        return PracticeStyleReport(style: style, hands: hands, days: days,
                                   voluntaryEntries: entries, preflopRaises: raises,
                                   participationInterval: p, raiseShareInterval: r,
                                   firstDay: evidence.first?.day, lastDay: evidence.last?.day)
    }

    private enum Band { case low, middle, high }
    private static func band(_ interval: ClosedRange<Double>, lower: Double, upper: Double) -> Band? {
        if interval.upperBound < lower { return .low }
        if interval.lowerBound >= lower && interval.upperBound <= upper { return .middle }
        if interval.lowerBound > upper { return .high }
        return nil
    }

    private static func wilson(successes: Int, trials: Int) -> ClosedRange<Double>? {
        guard trials > 0 else { return nil }
        let n = Double(trials), p = Double(successes) / n, z = 1.959963984540054
        let z2 = z * z, denominator = 1 + z2 / n
        let center = (p + z2 / (2 * n)) / denominator
        let margin = z * sqrt((p * (1 - p) + z2 / (4 * n)) / n) / denominator
        return max(0, center - margin)...min(1, center + margin)
    }
}
