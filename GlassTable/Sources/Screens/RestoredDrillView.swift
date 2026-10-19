// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

typealias DrillStoredReveal = SavedDrillReveal

extension SavedDrillReveal {
    init(_ outcome: DrillOutcome) {
        self.init(band: outcome.band.rawValue, interval: outcome.interval,
                  evLoss: outcome.evLoss)
    }
}

/// A committed answer replays from the original seed and semantic input. No
/// translated sentence is saved, so switching language regenerates the explanation.
struct RestoredDrillView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.simpleQuestions) private var simple
    @State private var calculationExpanded = false
    let concept: Concept
    let seed: UInt64
    let index: Int
    /// The step the answer was dealt at (D53); its spot and reveal are that step's.
    let level: DrillLevel
    let progressText: String
    let answer: RoundAnswer
    let onNext: (DrillOutcome) -> Void

    var body: some View {
        let stored = try? JSONDecoder().decode(DrillStoredReveal.self, from: answer.reveal)
        let input = try? JSONDecoder().decode(DrillSubmittedInput.self, from: answer.input)
        let detail = input.flatMap { input in
            ConceptReveal(concept: concept, seed: seed, index: index, level: level, input: input,
                          openerEquityPct: stored?.interval?.truth, language: language,
                          // Stored wire ranges do not record whether confidence was solicited.
                          namesRange: false)
        }
        let band = GradeBand(rawValue: answer.band) ?? .off
        // The EV loss verdict shows a small loss as close, as its live reveal does.
        let shown: GradeBand = if concept == .evLoss, case let .boolean(calls)? = input {
            gradeEVLoss(userCalls: calls, spot: EVLossSpotGenerator.spot(baseSeed: seed, index: index),
                        language: language).shownBand
        } else { band }
        let next = {
            onNext(DrillOutcome(band: band, interval: stored?.interval,
                                evLoss: stored?.evLoss, submittedInput: input))
        }
        // The same shell as the question, so an answer restored after a relaunch keeps
        // the question's header and puts its explanation in the graded sheet.
        return DrillShell(title: ConceptDrillView.drillTitle(for: concept),
                          progressText: progressText, foldsOnReveal: concept == .outs) {
            RestoredDrillContextView(concept: concept, seed: seed, index: index,
                                     assisted: answer.isAssisted, input: input,
                                     answerID: "saved-answer-\(concept.rawValue)/\(seed)/\(index)")
                .padding(.bottom, 12)
        } sheet: {
            VStack(alignment: .leading, spacing: GT.Space.related) {
                verdict(band: band, detail: detail, input: input)
                RevealDetail { explanation(detail: detail, input: input, band: band) }
                nextButton(next)
            }
            .preference(key: GradedBandKey.self, value: shown)
        }
        .background(FeltBackground())
    }

    @ViewBuilder
    private func explanation(detail: ConceptReveal?, input: DrillSubmittedInput?, band: GradeBand) -> some View {
        if concept == .evLoss, case let .boolean(calls)? = input {
            RestoredEVLossResult(seed: seed, index: index, calls: calls)
        } else if concept == .potMath {
            DisclosureGroup(language.text("계산 보기", "See the calculation"),
                            isExpanded: $calculationExpanded) {
                Text(detail?.why ?? "").font(GT.body(15).monospacedDigit())
                    .foregroundStyle(GT.ink)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(GT.semibold(15)).foregroundStyle(GT.ink)
            .gtInset(GT.Space.card, firstText: .semibold(15))
            .gtExplanation(band: band)
        } else if concept == .showdown {
            // The sentence under the best-five rows already says why; the sheet does not repeat it.
            EmptyView()
        } else {
            Text(detail?.why ?? language.text(
                "답은 저장됐어요. 다음 문제로 이어가세요.",
                "Your answer was saved. Continue to the next question."))
                .font(GT.body(GT.Typography.explanationSize))
                .foregroundStyle(GT.ink)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .gtInset(GT.Space.card, firstText: .body(16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .gtExplanation(band: band)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The same verdict row as the live reveal of each drill.
    @ViewBuilder
    private func verdict(band: GradeBand, detail: ConceptReveal?,
                         input: DrillSubmittedInput?) -> some View {
        let mine = detail?.mine ?? language.text("답변 저장됨", "Answer saved")
        let correct = detail?.correct ?? language.text("결과 저장됨", "Result saved")
        switch concept {
        case .defend:
            VerdictRow(band: band, mine: mine, correct: correct,
                       title: band == .spotOn ? language.text("차트와 일치해요", "Matches the chart")
                                              : language.text("차트와 달라요", "Different from the chart"),
                       mineTitle: language.text("선택한 답", "Your answer"),
                       correctTitle: language.text("차트", "Chart"))
        case .rangeRead:
            VerdictRow(band: band, mine: mine, correct: correct,
                       title: rangeMatchTitle(band, language: language))
        case .evLoss:
            if case let .boolean(calls)? = input {
                RestoredEVLossVerdict(seed: seed, index: index, calls: calls)
            } else {
                VerdictRow(band: band, mine: mine, correct: correct)
            }
        case .rangeAdvantage:
            VerdictRow(band: band, mine: mine, correct: correct,
                       title: practiceFeedbackTitle(concept, band: band, language: language),
                       correctTitle: language.text("오프너 승률", "Raiser's win rate"))
        default:
            VerdictRow(band: band, mine: mine, correct: correct,
                       title: practiceFeedbackTitle(concept, band: band, language: language))
        }
    }

    private func nextButton(_ action: @escaping () -> Void) -> some View {
        PrimaryCTAButton(title: language.text("다음 문제", "Next question"), action: action)
            .accessibilityIdentifier("drill-completion-\(concept.rawValue)/\(seed)/\(index)")
    }
}

/// The EV loss verdict as the live reveal draws it: the loss named, then your choice
/// against the best one.
private struct RestoredEVLossVerdict: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64
    let index: Int
    let calls: Bool

    var body: some View {
        let reveal = gradeEVLoss(userCalls: calls,
                                 spot: EVLossSpotGenerator.spot(baseSeed: seed, index: index),
                                 language: language)
        VerdictRow(band: reveal.shownBand, mine: action(calls), correct: action(reveal.grade.best.ev > 0),
                   title: evLossLabel(loss: reveal.grade.loss, language: language),
                   mineTitle: language.text("선택한 답", "Your answer"),
                   correctTitle: language.text("최선", "Best"))
    }

    private func action(_ isCall: Bool) -> String {
        isCall ? language.text("콜", "Call") : language.text("폴드", "Fold")
    }
}

private struct RestoredEVLossResult: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64
    let index: Int
    let calls: Bool

    private var spot: EVLossSpot { EVLossSpotGenerator.spot(baseSeed: seed, index: index) }
    private var reveal: EVLossReveal {
        gradeEVLoss(userCalls: calls, spot: spot, language: language)
    }

    var body: some View {
        let outcome = reveal
        let grade = outcome.grade
        let bestCalls = grade.best.ev > 0
        let chosenValue = bbText(grade.chosen.ev)
        let chosenTerm = grade.chosen.ev < 0 ? "(\(chosenValue))" : chosenValue
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                row(language.text("최선", "Best"), action(bestCalls), grade.best.ev)
                Divider().overlay(GT.border)
                row(language.text("선택한 답", "Your choice"), action(calls), grade.chosen.ev)
                Text(language.text("최선 EV \(bbText(grade.best.ev))bb − 선택한 답 EV \(chosenTerm)bb = 손실 \(bbText(grade.loss))bb",
                                   "Best value \(bbText(grade.best.ev))bb − your value \(chosenTerm)bb = \(bbText(grade.loss))bb lost"))
                    .font(GT.body(11).monospacedDigit()).foregroundStyle(GT.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .gtInset(GT.Space.card, firstText: .semibold(13))
            .gtExplanation()
            Text(outcome.whyText)
                .font(GT.body(GT.Typography.explanationSize))
                .foregroundStyle(GT.ink)
                .gtInset(GT.Space.card, firstText: .body(16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .gtExplanation(band: outcome.shownBand)
        }
    }

    private func action(_ isCall: Bool) -> String {
        isCall ? language.text("콜", "Call") : language.text("폴드", "Fold")
    }

    private func row(_ tag: String, _ action: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(tag) · \(action)").font(GT.semibold(13)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(bbText(value))bb").font(GT.title(14).monospacedDigit()).foregroundStyle(GT.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Rebuilds the question's visible evidence from its stable seed. A saved result
/// should not become an orphaned explanation after a relaunch.
private struct RestoredDrillContextView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillLevel) private var level
    @State private var potStepIndex = 0
    @State private var showingPotHelp = false
    let concept: Concept
    let seed: UInt64
    let index: Int
    let assisted: Bool
    let input: DrillSubmittedInput?
    let answerID: String

    private var script: (beats: [Beat], rows: [(String, [Card])]) {
        Walkthrough.make(concept: concept, seed: seed, index: index, level: level, language: language)
    }

    var body: some View {
        if concept == .showdown {
            showdownTable
        } else if concept == .outs {
            // A saved answer was already locked in, so the rivers are never early.
            OutsRiverReveal(spot: OutsSpotGenerator.spot(baseSeed: seed, index: index, level: level))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(answerID)
        } else {
            replayPanel
        }
    }

    /// The question's own table, with the winning five lit as the live reveal lights them.
    private var showdownTable: some View {
        let spot = ShowdownSpotGenerator.spot(baseSeed: seed, index: index, level: level)
        let winner: Int? = {
            guard case let .integer(answer)? = input else { return nil }
            return gradeShowdown(answer: answer, spot: spot, language: language).winner
        }()
        let pair = BestFivePair(spot)
        let winningFive: [Card] = switch winner {
        case 0: pair.first.used
        case 1: pair.second.used
        default: []
        }
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            ThreeRegionCardTable(
                opponent: spot.villain, board: spot.board, hero: spot.hero,
                opponentTitle: winner == 1 ? language.text("상대 카드 · 승", "Opponent · won")
                                           : language.text("상대 카드", "Opponent's cards"),
                heroTitle: winner == 0 ? language.text("내 카드 · 승", "Your cards · won")
                                       : language.text("내 카드", "Your cards"),
                highlight: winningFive, sideBySide: true)
            // A saved answer was already locked in, so the comparison is never early.
            if winner != nil {
                BestFiveComparison(pair: pair)
                    .gtInset(GT.Space.card, firstText: .semibold(13))
                    .gtCard(radius: GT.Radius.panel)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(answerID)
    }

    private var replayPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("문제에서 본 상황", "The situation you saw"))
                .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                .accessibilityIdentifier(answerID)
            questionContext
            ForEach(Array((concept == .defend ? [] : script.rows).enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel(text: row.0)
                    HStack(spacing: 6) {
                        ForEach(Array(row.1.enumerated()), id: \.offset) { _, card in
                            PlayingCardView(card: card)
                        }
                    }
                }
            }
            if concept == .rangeRead, let input,
                      let result = RestoredLessonEvidence.rangeReveal(seed: seed, index: index, level: level,
                                                                      input: input, language: language) {
                Text(language.text("색: 정답 · 테두리: 선택한 답", "Fill: answer · outline: your estimate"))
                    .font(GT.body(14)).foregroundStyle(GT.onFelt)
                RangeGridView(range: result.truth, outline: result.guess).frame(maxWidth: 350)
                RangeDifferenceList(truth: result.truth, guess: result.guess)
            } else if let focus = script.beats.last?.focus {
                focusView(focus)
            }
        }
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.07), in: RoundedRectangle(cornerRadius: GT.Radius.control))
        .sheet(isPresented: $showingPotHelp) {
            NavigationStack {
                PotMathIntroView { showingPotHelp = false }
                    .gtChrome(leading: { ChromeButton.close { showingPotHelp = false } })
                    .gtSheetSurface()
            }
        }
    }

    @ViewBuilder
    private var questionContext: some View {
        switch concept {
        case .potMath:
            let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(language.text("팟 계산", "Count the pot"))
                .font(GT.title(18)).foregroundStyle(GT.onFelt)
            PotMathReplayView(spot: spot, stepIndex: $potStepIndex, revealedPot: spot.pot,
                              showsPaidTotals: assisted) {
                showingPotHelp = true
            }
            .onAppear { potStepIndex = max(0, spot.replaySteps.count - 1) }
        case .position:
            let spot = PositionSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            switch spot.question {
            case let .behind(seat, preflop):
                LessonSeatLoop(active: seat, markers: [seat: language.text("나", "You")], postflop: !preflop)
                Text(language.text("\(seat.seatLabel(in: language)) · \(preflop ? "플랍 전" : "플랍 이후")",
                                   "\(seat.seatLabel(in: language)) · \(preflop ? "before" : "after") the flop"))
                    .font(GT.body(15)).foregroundStyle(GT.onFelt)
            case let .behindInHand(seat, stillIn):
                LessonSeatLoop(active: seat, markers: Dictionary(uniqueKeysWithValues:
                    [(seat, language.text("나", "You"))] + stillIn.map { ($0, language.text("참여", "In")) }),
                               showsOrder: false, postflop: true)
                Text(language.text("\(seat.seatLabel(in: language)) · 플랍 이후 · 남은 상대 \(stillIn.count)명",
                                   "\(seat.seatLabel(in: language)) · after the flop · \(stillIn.count) still in"))
                    .font(GT.body(15)).foregroundStyle(GT.onFelt)
            case let .whichIsLater(a, b):
                LessonSeatLoop(markers: [a: "A", b: "B"])
                Text(language.text("A와 B 중 나중에 행동하는 자리는 어디일까요?", "Which acts later, A or B?"))
                    .font(GT.body(15)).foregroundStyle(GT.onFelt)
            }
        case .evCall:
            let spot = EVCallSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb · 내 에퀴티 \(pctText(spot.equityPct))% (무승부 몫 포함)",
                               "Pot \(spot.pot)bb · Bet \(spot.bet)bb · Equity \(pctText(spot.equityPct))% (including tie shares)"))
                .font(GT.body(15)).foregroundStyle(GT.onFelt)
        case .potOdds, .mdf:
            let spot = BetSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb",
                               "Pot \(spot.pot)bb · Opponent bets \(spot.bet)bb"))
                .font(GT.body(15)).foregroundStyle(GT.onFelt)
            if spot.callers > 0 {
                Text(language.text("다른 한 명이 먼저 \(spot.bet)bb 콜했어요",
                                   "Another player has already called \(spot.bet)bb"))
                    .font(GT.body(15)).foregroundStyle(GT.onFelt)
            }
            PriceBarView.priced(pot: spot.pot, bet: spot.bet, withCall: concept == .potOdds, callers: spot.callers)
        case .rangeNotation:
            let spot = RangeNotationSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(spot.notation).font(GT.title(27).monospaced())
                .foregroundStyle(GT.onFelt)
        case .rangeRead:
            let spot = RangeReadSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(spot.archetypeShown ? spot.archetype.beginnerTitle(in: language)
                                     : spot.gradingAssumption(in: language))
                .font(GT.title(16)).foregroundStyle(GT.onFelt)
                .accessibilityIdentifier("range-read-opponent")
            ForEach(Array(spot.actionLines(in: language).enumerated()), id: \.offset) { _, line in
                Text(line).font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
            }
        case .callFold:
            let spot = CallFoldSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb",
                               "Pot \(spot.pot)bb · Opponent bets \(spot.bet)bb"))
                .font(GT.body(15)).foregroundStyle(GT.onFelt)
        case .evLoss:
            let spot = EVLossSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("\(spot.rangeLabel) · \(Int(spot.villainRange.comboCount))콤보",
                               "\(spot.rangeLabel(in: language)) · \(Int(spot.villainRange.comboCount)) combinations"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
            Text(language.text("리버에서 어떻게 좁혔는지는 아직 안 따져요",
                               "River narrowing is not counted yet"))
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
            RangeGridView(range: spot.villainRange)
                .frame(maxWidth: 350)
            Text(language.text("팟 \(spot.pot)bb · 벳 \(spot.bet)bb",
                               "Pot \(spot.pot)bb · Bet \(spot.bet)bb"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .defend:
            let spot = DefendSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(language.text("\(KO.subject(spot.opener.rawValue)) 3bb 오픈",
                               "\(spot.opener.rawValue) raises first to 3bb"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .combos:
            let spot = BlockerSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            Text(spot.className).font(GT.title(18)).foregroundStyle(GT.onFelt)
        case .hitFrequency:
            let spot = HitFrequencySpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("\(spot.seat.rawValue) 오픈 · 상위 약 \(pctText(RFIChart.openPercent[spot.seat] ?? 0))%",
                               "\(spot.seat.rawValue) raises first · about \(pctText(RFIChart.openPercent[spot.seat] ?? 0))% of hands"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .rangeAdvantage:
            let spot = RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("\(spot.openerSeat.rawValue) 오픈 · \(spot.callerSeat.rawValue) 콜",
                               "\(spot.openerSeat.rawValue) raises first · \(spot.callerSeat.rawValue) calls"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .actionRead:
            let spot = ActionReadSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            if level == .sharp {
                Text(spot.gradingAssumption(in: language))
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .accessibilityIdentifier("action-read-opponent")
                Text(spot.policyAssumption(in: language))
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .accessibilityIdentifier("action-read-policy")
            }
            Text(language.text("\(spot.villainSeat.rawValue) 오픈 → \(spot.actionLine)",
                               "\(spot.villainSeat.rawValue) raises first → \(spot.actionLine(in: language))"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .rfi:
            let spot = RFISpotGenerator.spot(baseSeed: seed, index: index, level: level)
            // The third step asked for the first seat, so the hand is the question.
            Text(level == .sharp
                 ? language.text("\(spot.handClass.description) · 먼저 올리는 첫 자리", "\(spot.handClass.description) · first seat to raise")
                 : language.text("내 자리 · \(spot.seat.rawValue)", "Your seat · \(spot.seat.rawValue)"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .showdown, .outs, .equitySense: EmptyView()
        }
    }

    @ViewBuilder
    private func focusView(_ focus: BeatFocus) -> some View {
        switch focus {
        case .none, .table: EmptyView()
        case let .grid(cards):
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 7)], spacing: 7) {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    PlayingCardView(card: card)
                }
            }
        case let .rangeGrid(range, highlight):
            RangeGridView(range: range, highlight: highlight)
                .frame(maxWidth: 350)
        case let .defendChart(opener, highlight):
            DefendGridView(opener: opener, highlight: highlight,
                           cards: concept == .defend
                            ? DefendSpotGenerator.spot(baseSeed: seed, index: index, level: level).hand : [])
                .frame(maxWidth: 350)
        case let .actionList(lines, _):
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line).font(GT.body(13)).foregroundStyle(GT.onFelt)
                }
            }
        case let .buckets(bars):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    BucketBarView(label: bar.label, distribution: bar.distribution,
                                  showsHeadline: concept != .rangeAdvantage)
                }
            }
        }
    }
}

/// Semantic evidence shared by restored rendering and replay tests.
enum RestoredLessonEvidence {
    static func rangeReveal(seed: UInt64, index: Int, level: DrillLevel = .learn, input: DrillSubmittedInput,
                            language: LearningLanguage) -> RangeReadReveal? {
        let estimate: RangeEstimate
        switch input {
        case let .range(width, tendencies):
            estimate = RangeEstimate(width: width, tendencies: Set(tendencies.compactMap(RangeTendency.init(rawValue:))))
        case let .rangeBand(width, excludedTop, tendencies):
            estimate = RangeEstimate(width: width, tendencies: Set(tendencies.compactMap(RangeTendency.init(rawValue:))), excludedTop: excludedTop)
        default: return nil
        }
        return gradeRangeRead(estimate: estimate, spot: RangeReadSpotGenerator.spot(baseSeed: seed, index: index, level: level),
                              language: language)
    }
}
