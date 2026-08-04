// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// The R1 concept vocabulary. Concepts are what mastery, review scheduling and
/// calibration are tracked against — *not* drills and *not* nodes, because the same
/// concept can be exercised by several nodes (spec §4.3).
///
/// `mdf` has no path node in R1 (spec §3.2 parks it for Block B) but keeps a concept
/// so 자유 연습 progress on the shipped MDF drill is still recorded.
public enum Concept: String, CaseIterable, Codable, Sendable {
    case showdown, potMath, position, combos
    case potOdds, outs, equitySense, evCall, callFold
    case rangeNotation, rfi, rangeRead
    case hitFrequency, rangeAdvantage
    case evLoss, actionRead, defend
    case mdf
}

extension Concept {
    /// Spec §5.4. `true` → answered with a point estimate plus a 90% interval and
    /// scored by the Winkler rule; `false` → single exact value, binary grade.
    ///
    /// `outs` is here for its *equity* half only. The out **count** is exact and is
    /// graded exactly; the rule-of-2/4 equity derived from it is explicitly an
    /// approximation, which is already how the reveal presents it.
    ///
    /// `rangeRead` is emphatically an estimate but is **not** here: it is answered
    /// with a width and a shape, never a point plus a 90% interval, so there is no
    /// Winkler score to feed calibration. Its softness is carried by the overlap
    /// bands instead.
    /// `evLoss` is not here either, and for a different reason than `rangeRead`: the
    /// answer is a *choice*, not a number. What is continuous is the grade, not the
    /// answer, so there is nothing to put an interval around.
    public var isEstimation: Bool {
        switch self {
        case .equitySense, .evCall, .outs, .hitFrequency, .rangeAdvantage,
             .actionRead: return true
        case .showdown, .potMath, .position, .combos, .potOdds, .callFold,
             .rangeNotation, .rfi, .rangeRead, .evLoss, .defend, .mdf: return false
        }
    }
}

/// Spec §4.3. Ordered low → high; `mastered` is reachable only through a boss node.
public enum MasteryTier: String, Codable, CaseIterable, Comparable, Sendable {
    case attempted, familiar, proficient, mastered

    public static func < (a: MasteryTier, b: MasteryTier) -> Bool {
        guard let i = allCases.firstIndex(of: a), let j = allCases.firstIndex(of: b)
        else { return false }
        return i < j
    }
}
