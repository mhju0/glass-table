// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// FSRS-6, ported from the reference implementation
/// (open-spaced-repetition/py-fsrs, `fsrs/scheduler.py`, MIT).
///
/// Only the DSR core is ported. Anki's learning/relearning step machine is not —
/// Glass Table has no card states, and a concept that comes due simply gets a freshly
/// generated spot (spec §4.5). What is kept is exactly the memory model: stability,
/// difficulty, retrievability, and the interval that follows from them.
///
/// Weights are the published defaults, unmodified. Spec §4.5 explicitly rules out
/// per-user parameter optimisation in R1 — that needs a review history far longer
/// than a new user has, and a wrong optimiser is worse than no optimiser.
public enum FSRS {
    /// Published FSRS-6 defaults, verbatim from `DEFAULT_PARAMETERS`.
    /// The 21st element is the decay term, `FSRS_DEFAULT_DECAY`.
    public static let defaultParameters: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001,
        1.8722, 0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014,
        1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
    ]

    public static let minDifficulty = 1.0
    public static let maxDifficulty = 10.0
    public static let minStability = 0.001

    /// How FSRS grades one review. Glass Table never emits `.easy`: it has no signal
    /// that separates "right" from "effortlessly right". Adding one later (a tight
    /// interval that contained the truth, say) is a pure extension — nothing here
    /// assumes the rating set is closed.
    public enum Rating: Int, Sendable {
        case again = 1, hard = 2, good = 3, easy = 4
    }
}

/// A configured FSRS scheduler. Value type, no state of its own beyond configuration,
/// so it is trivially testable with injected dates.
public struct FSRSScheduler: Sendable {
    public let parameters: [Double]
    /// Spec §4.5: the single exposed knob.
    public let desiredRetention: Double
    public let maximumInterval: Int

    private let decay: Double
    private let factor: Double

    public init(parameters: [Double] = FSRS.defaultParameters,
                desiredRetention: Double = 0.9,
                maximumInterval: Int = 36500) {
        precondition(parameters.count == 21, "FSRS-6 takes 21 parameters")
        self.parameters = parameters
        self.desiredRetention = desiredRetention
        self.maximumInterval = maximumInterval
        self.decay = -parameters[20]
        self.factor = pow(0.9, 1 / -parameters[20]) - 1
    }

    // MARK: - memory model

    /// Probability the concept is still recallable after `elapsedDays`.
    public func retrievability(stability: Double, elapsedDays: Double) -> Double {
        guard stability > 0 else { return 0 }
        return pow(1 + factor * max(0, elapsedDays) / stability, decay)
    }

    /// Days until retrievability decays to `desiredRetention`. At least 1, because a
    /// sub-day interval would mean re-drilling a concept inside the same session.
    public func nextInterval(stability: Double) -> Int {
        let raw = (stability / factor) * (pow(desiredRetention, 1 / decay) - 1)
        guard raw.isFinite else { return maximumInterval }
        return min(max(Int(raw.rounded()), 1), maximumInterval)
    }

    // MARK: - the update

    /// Advances a concept's memory state by one graded review.
    public func review(_ state: inout ReviewState, rating: FSRS.Rating, now: Date) {
        if state.reps == 0 || state.lastReview == nil {
            state.stability = initialStability(rating)
            state.difficulty = initialDifficulty(rating)
        } else {
            let elapsed = max(0, now.timeIntervalSince(state.lastReview!) / 86400)
            let r = retrievability(stability: state.stability, elapsedDays: elapsed)
            let nextD = nextDifficulty(state.difficulty, rating)
            // Under a day means the user is re-drilling inside one session, which is
            // a much weaker memory signal than a spaced review; FSRS models it
            // separately rather than letting same-day reps inflate stability.
            state.stability = elapsed < 1
                ? shortTermStability(state.stability, rating)
                : nextStability(difficulty: nextD, stability: state.stability,
                                retrievability: r, rating: rating)
            state.difficulty = nextD
        }

        if rating == .again { state.lapses += 1 }
        state.reps += 1
        state.lastReview = now
        state.due = Calendar.current.date(byAdding: .day,
                                          value: nextInterval(stability: state.stability),
                                          to: now) ?? now
    }

    public func isDue(_ state: ReviewState, at now: Date) -> Bool {
        guard let due = state.due else { return state.reps == 0 }
        return due <= now
    }

    // MARK: - formulas (py-fsrs parity)

    func initialStability(_ rating: FSRS.Rating) -> Double {
        clampStability(parameters[rating.rawValue - 1])
    }

    func initialDifficulty(_ rating: FSRS.Rating, clamp: Bool = true) -> Double {
        let d = parameters[4] - pow(M_E, parameters[5] * Double(rating.rawValue - 1)) + 1
        return clamp ? clampDifficulty(d) : d
    }

    func nextDifficulty(_ difficulty: Double, _ rating: FSRS.Rating) -> Double {
        let deltaD = -(parameters[6] * Double(rating.rawValue - 3))
        // Linear damping: a card already near maximum difficulty moves less.
        let damped = difficulty + (10.0 - difficulty) * deltaD / 9.0
        // Mean reversion toward the difficulty an "easy" first review would imply.
        let target = initialDifficulty(.easy, clamp: false)
        return clampDifficulty(parameters[7] * target + (1 - parameters[7]) * damped)
    }

    func shortTermStability(_ stability: Double, _ rating: FSRS.Rating) -> Double {
        var increase = pow(M_E, parameters[17] * (Double(rating.rawValue) - 3 + parameters[18]))
            * pow(stability, -parameters[19])
        if rating != .again { increase = max(increase, 1.0) }
        return clampStability(stability * increase)
    }

    func nextStability(difficulty: Double, stability: Double,
                       retrievability: Double, rating: FSRS.Rating) -> Double {
        let s = rating == .again
            ? forgetStability(difficulty: difficulty, stability: stability,
                              retrievability: retrievability)
            : recallStability(difficulty: difficulty, stability: stability,
                              retrievability: retrievability, rating: rating)
        return clampStability(s)
    }

    func forgetStability(difficulty: Double, stability: Double,
                         retrievability: Double) -> Double {
        let longTerm = parameters[11]
            * pow(difficulty, -parameters[12])
            * (pow(stability + 1, parameters[13]) - 1)
            * pow(M_E, (1 - retrievability) * parameters[14])
        let shortTerm = stability / pow(M_E, parameters[17] * parameters[18])
        return min(longTerm, shortTerm)
    }

    func recallStability(difficulty: Double, stability: Double,
                         retrievability: Double, rating: FSRS.Rating) -> Double {
        let hardPenalty = rating == .hard ? parameters[15] : 1
        let easyBonus = rating == .easy ? parameters[16] : 1
        return stability * (1
            + pow(M_E, parameters[8])
            * (11 - difficulty)
            * pow(stability, -parameters[9])
            * (pow(M_E, (1 - retrievability) * parameters[10]) - 1)
            * hardPenalty * easyBonus)
    }

    private func clampDifficulty(_ d: Double) -> Double {
        min(max(d, FSRS.minDifficulty), FSRS.maxDifficulty)
    }
    private func clampStability(_ s: Double) -> Double { max(s, FSRS.minStability) }
}

// MARK: - Glass Table's grades → FSRS ratings

extension FSRS.Rating {
    /// Exact concepts are binary, so they only ever produce `.again` or `.good`.
    public static func forExact(correct: Bool) -> FSRS.Rating { correct ? .good : .again }

    /// Estimation concepts carry the three-band grade, which maps cleanly onto the
    /// bottom three ratings. `.easy` stays unused (see `FSRS.Rating`).
    public static func forBand(_ band: GradeBand) -> FSRS.Rating {
        switch band {
        case .spotOn: return .good
        case .close:  return .hard
        case .off:    return .again
        }
    }
}
