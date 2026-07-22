// Copyright (c) 2026 Michael Ju

/// Grading band. UI renders: spotOn -> 정확, close -> 근접, off -> 빗나감.
public enum GradeBand: String {
    case spotOn, close, off
}

/// Band a numeric estimate by absolute error against the correct value.
public func gradeEstimate(user: Double, correct: Double,
                          closeWithin: Double, spotOnWithin: Double) -> GradeBand {
    let err = abs(user - correct)
    if err <= spotOnWithin { return .spotOn }
    if err <= closeWithin { return .close }
    return .off
}

/// Band a binary decision (e.g. call/fold): correct -> spotOn, wrong -> off.
public func gradeBinary(userChose: Bool, correct: Bool) -> GradeBand {
    userChose == correct ? .spotOn : .off
}
