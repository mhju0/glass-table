// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// The learner's level is the answer they gave at the starting check, or picked by
/// hand later. It changes which lesson is suggested, how much help is on by default
/// and which words lead. It never clears a lesson or awards mastery.
public extension PlacementSelfReport {
    /// The first lesson suggested when the starting check was skipped.
    var startingConcept: Concept {
        switch self {
        case .newToPoker: .showdown
        case .knowRules: .position
        case .playRegularly: .rangeRead
        }
    }

    /// Whether poker terms lead and plain words follow, unless the learner chose.
    var leadsWithTerms: Bool { self == .playRegularly }
}

public extension ProgressState {
    static let lessonTrendRange = -9...9

    var level: PlacementSelfReport { placement?.selfReport ?? .newToPoker }

    /// Two rough lessons in a row: help comes back on until a lesson goes better.
    var guidanceIsUp: Bool { (lessonTrend ?? 0) <= -2 }

    /// Three clean lessons in a row: the track's challenge is offered as a shortcut.
    var offersSkipAhead: Bool { (lessonTrend ?? 0) >= 3 }

    /// Whether a lesson's first question starts with the hint open.
    var helpsFirstQuestion: Bool { level != .playRegularly || guidanceIsUp }

    /// `missed` counts answers given without help that were off target. Rough is more
    /// than half of those missed; clean is none missed with at least one answered alone.
    mutating func recordLessonResult(questions: Int, missed: Int, helped: Int) {
        let trend = lessonTrend ?? 0
        if missed * 2 > questions - helped {
            lessonTrend = max(Self.lessonTrendRange.lowerBound, min(trend, 0) - 1)
        } else if missed == 0, helped < questions {
            lessonTrend = min(Self.lessonTrendRange.upperBound, max(trend, 0) + 1)
        } else {
            lessonTrend = 0
        }
    }
}
