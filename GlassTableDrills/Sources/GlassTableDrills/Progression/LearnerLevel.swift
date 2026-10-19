// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// The learner's level is the answer they gave at the starting check, or picked by
/// hand later. It changes which lesson is suggested and how much help is on by default.
/// It never clears a lesson or awards mastery.
public extension PlacementSelfReport {
    /// The first lesson suggested when the starting check was skipped.
    var startingConcept: Concept {
        switch self {
        case .newToPoker: .showdown
        case .knowRules: .position
        case .playRegularly: .rangeRead
        }
    }

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

/// A whole percentage as "1 in 4", reduced exactly, for learners who think in counts.
public func oddsWords(_ percent: Int, language: LearningLanguage) -> String {
    if percent <= 0 { return language.text("한 번도 아님", "never") }
    if percent >= 100 { return language.text("매번", "every time") }
    var (a, b) = (percent, 100)
    while b != 0 { (a, b) = (b, a % b) }
    return language.text("\(100 / a)번 중 \(percent / a)번", "\(percent / a) in \(100 / a)")
}

/// How often something happens, as a word to sit beside the number.
public func frequencyWord(_ percent: Double, language: LearningLanguage) -> String {
    switch percent {
    case ...20: language.text("드물게", "Rarely")
    case ...40: language.text("가끔", "Sometimes")
    case ...60: language.text("절반쯤", "About half the time")
    case ...80: language.text("자주", "Often")
    default: language.text("거의 항상", "Almost always")
    }
}
