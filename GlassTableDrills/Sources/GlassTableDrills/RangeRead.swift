// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine

/// One Range Read spot: you see the action, never the cards, and estimate what the
/// villain holds.
public struct RangeReadSpot: Equatable {
    public enum Action: Equatable, Sendable {
        /// Villain opened first in from `seat`.
        case opened(Position)
        /// Villain called an open that came from `opener`.
        case called(seat: Position, opener: Position)
    }

    public let archetype: Archetype
    public let action: Action
    /// Whether the drill names the opponent. Reading *which* opponent this is from
    /// their actions is most of the skill, but hiding it makes a first exposure
    /// nearly impossible — so it is a difficulty band, not a fixed choice.
    public let archetypeShown: Bool

    public init(archetype: Archetype, action: Action, archetypeShown: Bool) {
        self.archetype = archetype; self.action = action
        self.archetypeShown = archetypeShown
    }

    /// The declared range the estimate is graded against.
    public var trueRange: HandRange {
        switch action {
        case let .opened(seat): return archetype.raiseRange(from: seat)
        case let .called(seat, _): return archetype.callRange(from: seat)
        }
    }

    public var seat: Position {
        switch action {
        case let .opened(s): return s
        case let .called(s, _): return s
        }
    }

    /// Plain-Korean action history, the only thing the user gets to see.
    public var actionLines: [String] {
        actionLines(in: .korean)
    }

    public func actionLines(in language: LearningLanguage) -> [String] {
        switch action {
        case let .opened(seat):
            return language == .korean
                ? ["\(seat.plainName(in: language)): 빅 블라인드 3개(3bb)로 먼저 올림", "이후 전원 폴드"]
                : ["\(seat.plainName(in: language)) raises first to 3 big blinds (3bb)", "Everyone else folds"]
        case let .called(seat, opener):
            return language == .korean
                ? ["\(opener.plainName(in: language)): 빅 블라인드 3개(3bb)로 먼저 올림",
                   "\(seat.plainName(in: language)): 콜", "이후 전원 폴드"]
                : ["\(opener.plainName(in: language)) raises first to 3 big blinds (3bb)",
                   "\(seat.plainName(in: language)) calls", "Everyone else folds"]
        }
    }
}

public enum RangeReadSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int, level: DrillLevel = .learn) -> RangeReadSpot {
        if level > .learn { return laterStep(baseSeed: baseSeed, index: index, level: level) }
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let archetype = Archetype.allCases.randomElement(using: &rng)!
        let seat = RFIChart.seats.randomElement(using: &rng)!
        // A call needs somebody to have opened in front, so it needs a seat that acts
        // after one. Opening is always available.
        let openersBefore = RFIChart.seats.filter {
            $0.playersBehind(preflop: true) > seat.playersBehind(preflop: true)
        }
        let action: RangeReadSpot.Action
        if let opener = openersBefore.randomElement(using: &rng), Bool.random(using: &rng) {
            action = .called(seat: seat, opener: opener)
        } else {
            action = .opened(seat)
        }
        // Named for the first exposures, hidden later — the band the spec calls for.
        return RangeReadSpot(archetype: archetype, action: action,
                             archetypeShown: index < 3 || Int.random(in: 0..<3, using: &rng) > 0)
    }

    /// Later steps deal from their own stream (D53). The second names the opponent one
    /// time in three; the third never names them and deals only calls, where the
    /// raising hands have to come off the top.
    private static func laterStep(baseSeed: UInt64, index: Int, level: DrillLevel) -> RangeReadSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(level.rawValue) &* 0xD1B5_4A32_D192_ED03
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let archetype = Archetype.allCases.randomElement(using: &rng)!
        if level == .sharp {
            let seat = RFIChart.seats.dropFirst().randomElement(using: &rng)!
            let opener = RFIChart.seats.prefix { $0 != seat }.randomElement(using: &rng)!
            return RangeReadSpot(archetype: archetype, action: .called(seat: seat, opener: opener),
                                 archetypeShown: false)
        }
        let seat = RFIChart.seats.randomElement(using: &rng)!
        let openersBefore = RFIChart.seats.prefix { $0 != seat }
        let action: RangeReadSpot.Action
        if let opener = openersBefore.randomElement(using: &rng), Bool.random(using: &rng) {
            action = .called(seat: seat, opener: opener)
        } else {
            action = .opened(seat)
        }
        return RangeReadSpot(archetype: archetype, action: action,
                             archetypeShown: Int.random(in: 0..<3, using: &rng) == 0)
    }
}

/// The range-read answer choices at each step (D53). The first step's are
/// `BeginnerQuestionChoices.rangeEstimates`. Later steps come closer: each wrong
/// choice is 0.6× or 1.6× its neighbour toward the answer (a further step where a
/// narrow band would still grade right), three choices at the second step and four
/// at the third, with the answer's place among them varied.
public enum RangeReadChoices {
    public static func estimates(spot: RangeReadSpot, seed: UInt64, level: DrillLevel) -> [RangeEstimate] {
        guard level > .learn else { return BeginnerQuestionChoices.rangeEstimates(spot: spot, seed: seed) }
        let factor = Archetype.seatFactor(spot.seat)
        let raising = spot.archetype.pfr * factor
        let calling: Bool
        if case .called = spot.action { calling = true } else { calling = false }
        let truth = RangeEstimate(width: min(80, max(3, calling ? spot.archetype.passiveGap * factor : raising)),
                                  excludedTop: calling ? raising : 0)
        let wrong = level == .sharp ? 3 : 2
        // A narrow band shares most hand types with one a step away, so a step that
        // would still grade right is passed over for the next one out.
        func ladder(_ ratio: Double, _ steps: ClosedRange<Int>) -> [Double] {
            steps.map { truth.width * pow(ratio, Double($0)) }.filter { width in
                (3...80).contains(width) && gradeRangeRead(
                    estimate: RangeEstimate(width: width, excludedTop: truth.excludedTop), spot: spot).band != .spotOn
            }.prefix(wrong).map { $0 }
        }
        let below = ladder(0.6, 1...4), above = ladder(1.6, 1...8)
        var rng = SplitMix64(seed: seed)
        let lower = Int.random(in: max(0, wrong - above.count)...min(wrong, below.count), using: &rng)
        let widths = below.prefix(lower) + above.prefix(wrong - lower)
        return ([truth] + widths.map { RangeEstimate(width: $0, excludedTop: truth.excludedTop) })
            .shuffled(using: &rng)
    }
}

/// What the user built with the slider and the chips.
public struct RangeEstimate: Equatable, Sendable {
    public let width: Double
    public let tendencies: Set<RangeTendency>
    /// For a call: the strongest hands, as a percent of all hands, that would have
    /// raised instead. The estimate is then the band of `width` directly below them.
    /// Zero reads the range from the top, which is what an open is.
    public let excludedTop: Double

    public init(width: Double, tendencies: Set<RangeTendency> = [], excludedTop: Double = 0) {
        self.width = width; self.tendencies = tendencies; self.excludedTop = excludedTop
    }

    public var range: HandRange {
        guard excludedTop > 0 else { return .shaped(width: width, tendencies: tendencies) }
        return HandRange.shaped(width: excludedTop + width, tendencies: tendencies)
            .subtracting(.topByChen(percent: excludedTop))
    }
}

/// Input bounds shared by the drill and saved-answer validation.
public enum RangeReadInput {
    /// The most a call read can take off the top: past the widest raising range.
    public static let excludedTopLimit = 100.0
}

public struct RangeReadReveal: Equatable {
    public let band: GradeBand
    public let overlap: Double
    public let guess: HandRange
    public let truth: HandRange
    public let whyText: String
}

/// Overlap thresholds. Estimation bands rather than pass/fail, because a read *is* an
/// estimate — the same rule that keeps 근접 off the exact drills keeps it on this one.
public enum RangeReadGrading {
    public static let spotOn = 0.70
    public static let close = 0.45
}

public func gradeRangeRead(estimate: RangeEstimate, spot: RangeReadSpot,
                           language: LearningLanguage = .korean) -> RangeReadReveal {
    let guess = estimate.range
    let truth = spot.trueRange
    let overlap = guess.jaccard(truth)

    let band: GradeBand = overlap >= RangeReadGrading.spotOn ? .spotOn
        : (overlap >= RangeReadGrading.close ? .close : .off)

    return RangeReadReveal(band: band, overlap: overlap, guess: guess, truth: truth,
                           whyText: explain(guess: guess, truth: truth, spot: spot, band: band,
                                            language: language))
}

/// "0.52" teaches nothing. Name the direction: too wide, too tight, the raising hands
/// left in a call, or the right width with the wrong shape. The sentence follows the
/// band, so a 정답 is never told it misread and a miss is never told it matched.
func explain(guess: HandRange, truth: HandRange, spot: RangeReadSpot, band: GradeBand,
             language: LearningLanguage = .korean) -> String {
    let gw = guess.percent, tw = truth.percent
    let missed = truth.subtracting(guess), extra = guess.subtracting(truth)
    let raised: HandRange? = if case .called = spot.action {
        spot.archetype.raiseRange(from: spot.seat)
    } else { nil }
    // The raising hands a call estimate still holds, as a share of the estimate.
    let keptRaises = raised.map { guess.comboCount > 0
        ? guess.intersection($0).comboCount / guess.comboCount : 0 } ?? 0
    // The category that holds most of what was missed, if one clearly does.
    let missedTendency = RangeTendency.allCases
        .map { t in (t, missed.comboCount > 0 ? missed.tendencyShare(t) : 0) }
        .max { $0.1 < $1.1 }
        .flatMap { $0.1 >= 0.5 ? $0.0 : nil }

    enum Story { case match, wide, narrow, raises, shape(RangeTendency?) }
    let story: Story
    if band == .spotOn { story = .match }
    else if gw > tw * 1.2, extra.comboCount >= missed.comboCount { story = .wide }
    else if gw < tw * 0.8, missed.comboCount >= extra.comboCount { story = .narrow }
    else if keptRaises > 0.15 { story = .raises }
    else { story = .shape(missedTendency) }

    if language == .english {
        var text = "\(spot.archetype.beginnerTitle(in: language))'s \(actionWord(spot, language: language)) range is \(pctText(tw))% of all hands. You estimated \(pctText(gw))%."
        if raised != nil { text += " The strongest hands raise instead, so they are not in a calling range." }
        switch story {
        case .match: text += " Most hands overlap: a good read."
        case .wide: text += " Your range was too wide."
        case .narrow: text += " Your range was too narrow."
        case .raises: text += " Your estimate kept hands this player would have raised. Take more off the top."
        case .shape(let t?): text += " The width is close, but the shape differs. Most missed hands are \(DrillTerms.tendencyInSentence(t, in: language))."
        case .shape(nil): text += " The width is close, but few of the same hands overlap."
        }
        return text
    }
    var text = "\(spot.archetype.beginnerTitle(in: .korean))의 \(actionWord(spot)) 레인지는 전체 조합의 "
        + "\(pctText(tw))%예요. 내 추정은 \(pctText(gw))%."
    if raised != nil { text += " 가장 강한 핸드는 콜 대신 레이즈하니까 콜 레인지에는 없어요." }
    switch story {
    case .match: text += " 대부분 겹쳐요. 잘 읽었어요."
    case .wide: text += " 너무 넓게 봤어요. \(spot.archetype.blurb)."
    case .narrow: text += " 너무 좁게 봤어요. \(spot.archetype.blurb)."
    case .raises: text += " 이 상대라면 레이즈했을 핸드까지 넣었어요. 위쪽을 더 빼 보세요."
    case .shape(let t?): text += " 넓이는 비슷한데 모양이 달라요. 놓친 핸드는 주로 \(tendencyWord(t))예요."
    case .shape(nil): text += " 넓이는 비슷한데 겹치는 핸드가 적어요."
    }
    return text
}

func actionWord(_ spot: RangeReadSpot, language: LearningLanguage = .korean) -> String {
    switch spot.action {
    case .opened: return language.text("오픈", "opening")
    case .called: return language.text("콜", "calling")
    }
}

public func tendencyWord(_ t: RangeTendency,
                         language: LearningLanguage = .korean) -> String {
    if language == .english { return DrillTerms.tendency(t, in: language) }
    switch t {
    case .pairs: return "페어"
    case .suited: return "수티드"
    case .offsuitBroadway: return "오프수트 브로드웨이"
    case .connectors: return "커넥터"
    }
}
