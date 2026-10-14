// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// What a graded concept answer shows: the learner's answer, the correct one, and why.
///
/// Built from the seed and the submitted input alone, so a live reveal, an answer
/// restored after a relaunch and a language switch all read the same words, and the
/// words always describe the spot that was graded.
public struct ConceptReveal: Equatable, Sendable {
    public let mine: String
    public let correct: String
    public let why: String

    /// - Parameters:
    ///   - openerEquityPct: the saved truth of a range-advantage answer, which is
    ///     estimated by simulation and so cannot be recomputed exactly.
    ///   - namesRange: whether the learner gave a 90% range; only then is it judged.
    /// Returns nil when the input does not fit the concept.
    public init?(concept: Concept, seed: UInt64, index: Int, input: SavedDrillInput,
                 openerEquityPct: Double? = nil, language: LearningLanguage, namesRange: Bool = false) {
        func choice(_ isCall: Bool) -> String { isCall ? language.text("콜", "Call") : language.text("폴드", "Fold") }
        switch (concept, input) {
        case let (.showdown, .integer(value)):
            let spot = ShowdownSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradeShowdown(answer: value, spot: spot, language: language)
            guard (0..<3).contains(value), (0..<3).contains(result.winner) else { return nil }
            self.init(mine: HandOutcomeCopy.answer(value, in: language),
                      correct: HandOutcomeCopy.answer(result.winner, in: language), why: result.whyText)
        case let (.potMath, .integer(value)):
            let result = gradePotMath(answer: value,
                spot: PotMathSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            let unit = language.text("칩", " chips")
            self.init(mine: "\(value)\(unit)", correct: "\(result.correct)\(unit)", why: result.whyText)
        case let (.position, .integer(value)):
            let spot = PositionSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradePosition(answer: value, spot: spot, language: language)
            func label(_ value: Int) -> String {
                switch spot.question {
                case .behind: language.text("\(value)명", "\(value) players")
                case let .whichIsLater(a, b): (value == 0 ? a : b).seatLabel(in: language)
                }
            }
            self.init(mine: label(value), correct: label(result.correct), why: result.whyText)
        case let (.outs, .integer(value)):
            let spot = OutsSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradeOuts(estimate: value, spot: spot, language: language)
            let unit = language.text("장", " cards")
            self.init(mine: "\(value)\(unit)", correct: "\(spot.outCount)\(unit)", why: result.whyText)
        case let (.combos, .integer(value)):
            let spot = BlockerSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradeBlocker(estimate: value, spot: spot, language: language)
            let unit = language.text("개", " combos")
            self.init(mine: "\(value)\(unit)", correct: "\(result.count)\(unit)", why: result.whyText)
        case let (.potOdds, .integer(value)), let (.mdf, .integer(value)):
            let spot = BetSpotGenerator.spot(baseSeed: seed, index: index)
            let result = concept == .mdf
                ? gradeMDF(estimatePct: value, spot: spot, language: language)
                : gradePotOdds(estimatePct: value, spot: spot, language: language)
            self.init(mine: "\(value)%", correct: "\(pctText(result.correctPct))%", why: result.whyText)
        case let (.callFold, .boolean(value)):
            let result = gradeCallFold(userCalls: value,
                spot: CallFoldSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            self.init(mine: choice(value), correct: choice(result.correctIsCall), why: result.whyText)
        case let (.rangeNotation, .integer(value)):
            let result = gradeRangeNotation(estimate: value,
                spot: RangeNotationSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            let unit = language.text(" 콤보", " combos")
            self.init(mine: "\(value)\(unit)", correct: "\(result.count)\(unit)", why: result.whyText)
        case let (.rfi, .boolean(value)):
            let result = gradeRFI(userOpens: value,
                spot: RFISpotGenerator.spot(baseSeed: seed, index: index), language: language)
            func open(_ opens: Bool) -> String { opens ? language.text("오픈", "Raise") : language.text("폴드", "Fold") }
            self.init(mine: open(value), correct: open(result.correctOpens), why: result.whyText)
        case let (.rangeRead, .range(width, tendencies)):
            let result = gradeRangeRead(
                estimate: RangeEstimate(width: width, tendencies: Set(tendencies.compactMap(RangeTendency.init(rawValue:)))),
                spot: RangeReadSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            self.init(mine: "\(pctText(result.guess.percent))%", correct: "\(pctText(result.truth.percent))%",
                      why: result.whyText)
        case let (.rangeRead, .rangeBand(width, excludedTop, tendencies)):
            let result = gradeRangeRead(
                estimate: RangeEstimate(width: width, tendencies: Set(tendencies.compactMap(RangeTendency.init(rawValue:))),
                                        excludedTop: excludedTop),
                spot: RangeReadSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            self.init(mine: "\(pctText(result.guess.percent))%", correct: "\(pctText(result.truth.percent))%",
                      why: result.whyText)
        case let (.evLoss, .boolean(value)):
            let result = gradeEVLoss(userCalls: value,
                spot: EVLossSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            self.init(mine: choice(value), correct: choice(result.grade.best.ev > 0), why: result.whyText)
        case let (.defend, .action(raw)):
            guard let selected = DefendAction(rawValue: raw) else { return nil }
            let result = gradeDefend(chosen: selected,
                spot: DefendSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            func label(_ action: DefendAction) -> String {
                switch action {
                case .fold: language.text("폴드", "Fold")
                case .call: language.text("콜", "Call")
                case .threeBet: language.text("3벳", "Re-raise")
                }
            }
            self.init(mine: label(selected), correct: label(result.correct), why: result.whyText)
        case let (.equitySense, .interval(point, lo, hi)):
            self.init(estimate: gradeEquitySense(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: EquitySenseSpotGenerator.spot(baseSeed: seed, index: index), language: language),
                unit: "%", language: language, namesRange: namesRange)
        case let (.evCall, .interval(point, lo, hi)):
            self.init(estimate: gradeEVCall(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: EVCallSpotGenerator.spot(baseSeed: seed, index: index), language: language),
                unit: "bb", language: language, namesRange: namesRange)
        case let (.hitFrequency, .interval(point, lo, hi)):
            self.init(estimate: gradeHitFrequency(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: HitFrequencySpotGenerator.spot(baseSeed: seed, index: index), language: language),
                unit: "%", language: language, namesRange: namesRange)
        case let (.rangeAdvantage, .interval(point, lo, hi)):
            guard let openerEquityPct else { return nil }
            self.init(estimate: gradeRangeAdvantage(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index),
                openerEquityPct: openerEquityPct, language: language),
                unit: "%", language: language, namesRange: namesRange)
        case let (.actionRead, .interval(point, lo, hi)):
            self.init(estimate: gradeActionRead(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: ActionReadSpotGenerator.spot(baseSeed: seed, index: index), language: language),
                unit: "%", language: language, namesRange: namesRange)
        default: return nil
        }
    }

    init(mine: String, correct: String, why: String) {
        self.mine = mine; self.correct = correct; self.why = why
    }

    private init(estimate result: EstimateReveal, unit: String, language: LearningLanguage, namesRange: Bool) {
        self.init(mine: "\(pctText(result.estimate.point))\(unit)",
                  correct: "\(pctText(result.correct))\(unit)",
                  // A learner who was never asked for a range is not told how it did.
                  why: !namesRange ? result.whyText : result.whyText + language.text(
                      result.intervalHit ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요.",
                      result.intervalHit ? " The answer was inside your 90% range."
                                         : " The answer was outside your 90% range."))
    }
}

public enum HandOutcomeCopy {
    public static func answer(_ winner: Int, in language: LearningLanguage) -> String {
        switch winner {
        case 0: language.text("이겼어요", "You win")
        case 1: language.text("상대가 이겼어요", "Opponent wins")
        default: language.text("무승부", "Tie")
        }
    }
}
