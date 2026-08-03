// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Interval scoring and the calibration readout (spec §5.4, §7.1).
///
/// This is the app's one defensible efficacy claim, so the scoring rule has to be
/// *proper*: it must be impossible to score well by hedging. The Winkler interval
/// score does that — a 0–100 interval always contains the truth but is punished for
/// its width, so "just say a huge range" loses to an honest tight one.
public enum Calibration {
    /// The confidence every interval in the app is stated at.
    public static let nominalConfidence = 0.9

    public enum Verdict: Equatable, Sendable {
        case overconfident    // intervals too tight — the truth escapes them too often
        case calibrated
        case underconfident   // intervals too wide — hedging
    }

    /// Lower is better. Width when the truth is contained; width plus a shortfall
    /// penalty scaled by 2/α when it is not.
    public static func winklerScore(_ iv: IntervalAnswer,
                                    confidence: Double = nominalConfidence) -> Double {
        let width = iv.hi - iv.lo
        let alpha = 1 - confidence
        guard alpha > 0 else { return width }
        if iv.truth < iv.lo { return width + (2 / alpha) * (iv.lo - iv.truth) }
        if iv.truth > iv.hi { return width + (2 / alpha) * (iv.truth - iv.hi) }
        return width
    }

    /// Share of stated intervals that actually contained the truth. `nil` until the
    /// user has answered at least one estimation item — an empty readout is honest,
    /// a 0% one is a lie.
    public static func hitRate(in state: ProgressState) -> Double? {
        let intervals = state.answers.compactMap(\.interval)
        guard !intervals.isEmpty else { return nil }
        return Double(intervals.filter(\.containsTruth).count) / Double(intervals.count)
    }

    /// Mean Winkler score across the log; `nil` with no estimation answers.
    public static func meanScore(in state: ProgressState,
                                 confidence: Double = nominalConfidence) -> Double? {
        let intervals = state.answers.compactMap(\.interval)
        guard !intervals.isEmpty else { return nil }
        return intervals.reduce(0) { $0 + winklerScore($1, confidence: confidence) }
            / Double(intervals.count)
    }

    /// Tolerance band around the nominal rate before we call it either way. Wide
    /// enough that a handful of answers doesn't produce a confident-sounding verdict.
    public static let tolerance = 0.05

    public static func verdict(hitRate: Double,
                               nominal: Double = nominalConfidence) -> Verdict {
        if hitRate < nominal - tolerance { return .overconfident }
        if hitRate > nominal + tolerance { return .underconfident }
        return .calibrated
    }
}
