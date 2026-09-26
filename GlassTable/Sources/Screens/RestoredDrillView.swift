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
    @State private var calculationExpanded = false
    let concept: Concept
    let seed: UInt64
    let index: Int
    let progressText: String
    let answer: RoundAnswer
    let onNext: (DrillOutcome) -> Void

    var body: some View {
        let stored = try? JSONDecoder().decode(DrillStoredReveal.self, from: answer.reveal)
        let input = try? JSONDecoder().decode(DrillSubmittedInput.self, from: answer.input)
        let detail = input.flatMap { input in
            RestoredDrillDescription.make(concept: concept, seed: seed, index: index,
                                          input: input, stored: stored, language: language)
        }
        let band = GradeBand(rawValue: answer.band) ?? .off
        let next = {
            onNext(DrillOutcome(band: band, interval: stored?.interval,
                                evLoss: stored?.evLoss, submittedInput: input))
        }
        // The same shell as the question, so an answer restored after a relaunch keeps
        // the question's header and puts its explanation in the graded sheet.
        return DrillShell(title: ConceptDrillView.drillTitle(for: concept),
                          progressText: progressText) {
            RestoredDrillContextView(concept: concept, seed: seed, index: index,
                                     assisted: answer.isAssisted, input: input,
                                     answerID: "saved-answer-\(concept.rawValue)/\(seed)/\(index)")
                .padding(.bottom, 12)
        } sheet: {
            VStack(alignment: .leading, spacing: GT.Space.related) {
                if answer.isAssisted { SolvedWithHelpLabel() }
                verdict(band: band, detail: detail, input: input)
                RevealDetail { explanation(detail: detail, input: input) }
                nextButton(next)
            }
            .preference(key: GradedBandKey.self, value: band)
        }
        .background(FeltBackground())
    }

    @ViewBuilder
    private func explanation(detail: RestoredDrillDescription?, input: DrillSubmittedInput?) -> some View {
        if concept == .evLoss, case let .boolean(calls)? = input {
            RestoredEVLossResult(seed: seed, index: index, calls: calls)
        } else if concept == .potMath {
            DisclosureGroup(language.text("계산 보기", "See the calculation"),
                            isExpanded: $calculationExpanded) {
                Text(detail?.why ?? "").font(GT.body(15).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(GT.semibold(15)).foregroundStyle(GT.ink)
            .padding(14)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                         style: .continuous))
        } else {
            Text(detail?.why ?? language.text(
                "답은 저장됐어요. 다음 문제로 이어가세요.",
                "Your answer was saved. Continue to the next question."))
                .font(GT.body(GT.Typography.explanationSize))
                .foregroundStyle(GT.inkSecondary)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                             style: .continuous))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The same verdict row as the live reveal of each drill.
    @ViewBuilder
    private func verdict(band: GradeBand, detail: RestoredDrillDescription?,
                         input: DrillSubmittedInput?) -> some View {
        let mine = detail?.mine ?? language.text("답변 저장됨", "Answer saved")
        let correct = detail?.correct ?? language.text("결과 저장됨", "Result saved")
        switch concept {
        case .defend:
            VerdictRow(band: band, mine: mine, correct: correct,
                       title: band == .spotOn ? language.text("차트와 일치해요", "Matches the chart")
                                              : language.text("차트와 달라요", "Different from the chart"),
                       mineTitle: language.text("내 선택", "You chose"),
                       correctTitle: language.text("차트", "Chart"))
        case .evLoss:
            if case let .boolean(calls)? = input {
                RestoredEVLossVerdict(seed: seed, index: index, calls: calls)
            } else {
                VerdictRow(band: band, mine: mine, correct: correct)
            }
        default:
            VerdictRow(band: band, mine: mine, correct: correct)
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
        VerdictRow(band: reveal.band, mine: action(calls), correct: action(reveal.grade.best.ev > 0),
                   title: evLossLabel(loss: reveal.grade.loss, language: language),
                   mineTitle: language.text("내 선택", "You chose"),
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
                row(language.text("내 선택", "You"), action(calls), grade.chosen.ev)
                Text(language.text("최선 EV \(bbText(grade.best.ev))bb − 내 선택 EV \(chosenTerm)bb = 손실 \(bbText(grade.loss))bb",
                                   "Best value \(bbText(grade.best.ev))bb − your value \(chosenTerm)bb = \(bbText(grade.loss))bb lost"))
                    .font(GT.body(11).monospacedDigit()).foregroundStyle(GT.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control))
            Text(outcome.whyText)
                .font(GT.body(GT.Typography.explanationSize))
                .foregroundStyle(GT.inkSecondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control))
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

struct RestoredDrillDescription {
    let mine: String
    let correct: String
    let why: String

    static func make(concept: Concept, seed: UInt64, index: Int,
                     input: DrillSubmittedInput, stored: DrillStoredReveal?,
                     language: LearningLanguage) -> Self? {
        switch (concept, input) {
        case let (.showdown, .integer(value)):
            let spot = ShowdownSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradeShowdown(answer: value, spot: spot, language: language)
            let labels = language == .korean
                ? ["내가 이김", "상대가 이김", "무승부"]
                : ["I win", "Opponent wins", "Tie"]
            guard (0..<3).contains(value), (0..<3).contains(result.winner) else { return nil }
            return Self(mine: labels[value], correct: labels[result.winner], why: result.whyText)
        case let (.potMath, .integer(value)):
            let result = gradePotMath(answer: value,
                spot: PotMathSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            let unit = language.text("칩", " chips")
            return Self(mine: "\(value)\(unit)", correct: "\(result.correct)\(unit)",
                        why: result.whyText)
        case let (.position, .integer(value)):
            let spot = PositionSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradePosition(answer: value, spot: spot, language: language)
            func label(_ value: Int) -> String {
                switch spot.question {
                case .behind: return language.text("\(value)명", "\(value) players")
                case let .whichIsLater(a, b): return value == 0 ? a.rawValue : b.rawValue
                }
            }
            return Self(mine: label(value), correct: label(result.correct), why: result.whyText)
        case let (.outs, .integer(value)):
            let spot = OutsSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradeOuts(estimate: value, spot: spot, language: language)
            let unit = language.text("장", " cards")
            return Self(mine: "\(value)\(unit)", correct: "\(spot.outCount)\(unit)",
                        why: result.whyText)
        case let (.combos, .integer(value)):
            let spot = BlockerSpotGenerator.spot(baseSeed: seed, index: index)
            let result = gradeBlocker(estimate: value, spot: spot, language: language)
            let unit = language.text("개", " combos")
            return Self(mine: "\(value)\(unit)", correct: "\(result.count)\(unit)",
                        why: result.whyText)
        case let (.potOdds, .integer(value)), let (.mdf, .integer(value)):
            let spot = BetSpotGenerator.spot(baseSeed: seed, index: index)
            let result = concept == .mdf
                ? gradeMDF(estimatePct: value, spot: spot, language: language)
                : gradePotOdds(estimatePct: value, spot: spot, language: language)
            return Self(mine: "\(value)%", correct: "\(pctText(result.correctPct))%",
                        why: result.whyText)
        case let (.callFold, .boolean(value)):
            let result = gradeCallFold(userCalls: value,
                spot: CallFoldSpotGenerator.spot(baseSeed: seed, index: index), language: language)
            return Self(mine: value ? language.text("콜", "Call") : language.text("폴드", "Fold"),
                        correct: result.correctIsCall ? language.text("콜", "Call")
                            : language.text("폴드", "Fold"), why: result.whyText)
        case let (.rangeNotation, .integer(value)):
            let result = gradeRangeNotation(estimate: value,
                spot: RangeNotationSpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            let unit = language.text(" 콤보", " combos")
            return Self(mine: "\(value)\(unit)", correct: "\(result.count)\(unit)",
                        why: result.whyText)
        case let (.rfi, .boolean(value)):
            let result = gradeRFI(userOpens: value,
                spot: RFISpotGenerator.spot(baseSeed: seed, index: index), language: language)
            return Self(mine: value ? language.text("오픈", "Raise") : language.text("폴드", "Fold"),
                        correct: result.correctOpens ? language.text("오픈", "Raise")
                            : language.text("폴드", "Fold"), why: result.whyText)
        case let (.rangeRead, .range(width, tendencies)):
            let selected = Set(tendencies.compactMap(RangeTendency.init(rawValue:)))
            let result = gradeRangeRead(
                estimate: RangeEstimate(width: width, tendencies: selected),
                spot: RangeReadSpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            let prefix = language.text("상위 ", "Top ")
            return Self(mine: "\(prefix)\(pctText(result.guess.percent))%",
                        correct: "\(prefix)\(pctText(result.truth.percent))%",
                        why: result.whyText)
        case let (.evLoss, .boolean(value)):
            let result = gradeEVLoss(userCalls: value,
                spot: EVLossSpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            let bestCalls = result.grade.best.ev > 0
            return Self(mine: value ? language.text("콜", "Call") : language.text("폴드", "Fold"),
                        correct: bestCalls ? language.text("콜", "Call") : language.text("폴드", "Fold"),
                        why: result.whyText)
        case let (.defend, .action(raw)):
            guard let selected = DefendAction(rawValue: raw) else { return nil }
            let result = gradeDefend(chosen: selected,
                spot: DefendSpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            func label(_ action: DefendAction) -> String {
                switch action {
                case .fold: return language.text("폴드", "Fold")
                case .call: return language.text("콜", "Call")
                case .threeBet: return language.text("3벳", "Re-raise")
                }
            }
            return Self(mine: label(selected), correct: label(result.correct),
                        why: result.whyText)
        case let (.equitySense, .interval(point, lo, hi)):
            let result = gradeEquitySense(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: EquitySenseSpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            return interval(result, unit: "%", language: language)
        case let (.evCall, .interval(point, lo, hi)):
            let result = gradeEVCall(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: EVCallSpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            return interval(result, unit: "bb", language: language)
        case let (.hitFrequency, .interval(point, lo, hi)):
            let result = gradeHitFrequency(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: HitFrequencySpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            return interval(result, unit: "%", language: language)
        case let (.rangeAdvantage, .interval(point, lo, hi)):
            guard let truth = stored?.interval?.truth else { return nil }
            let result = gradeRangeAdvantage(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index),
                openerEquityPct: truth, language: language)
            return interval(result, unit: "%", language: language)
        case let (.actionRead, .interval(point, lo, hi)):
            let result = gradeActionRead(estimate: Estimate(point: point, lo: lo, hi: hi),
                spot: ActionReadSpotGenerator.spot(baseSeed: seed, index: index),
                language: language)
            return interval(result, unit: "%", language: language)
        default: return nil
        }
    }

    private static func interval(_ result: EstimateReveal, unit: String,
                                 language: LearningLanguage) -> Self {
        Self(mine: "\(pctText(result.estimate.point))\(unit)",
             correct: "\(pctText(result.correct))\(unit)",
             why: result.whyText + language.text(
                result.intervalHit ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요.",
                result.intervalHit ? " The answer was inside your 90% range."
                                   : " The answer was outside your 90% range."))
    }
}

/// Rebuilds the question's visible evidence from its stable seed. A saved result
/// should not become an orphaned explanation after a relaunch.
private struct RestoredDrillContextView: View {
    @Environment(\.learningLanguage) private var language
    @State private var potStepIndex = 0
    @State private var showingPotHelp = false
    @State private var selectedRiver: Card?
    let concept: Concept
    let seed: UInt64
    let index: Int
    let assisted: Bool
    let input: DrillSubmittedInput?
    let answerID: String

    private var script: (beats: [Beat], rows: [(String, [Card])]) {
        Walkthrough.make(concept: concept, seed: seed, index: index, language: language)
    }

    var body: some View {
        if concept == .showdown {
            showdownTable
        } else {
            replayPanel
        }
    }

    /// The question's own table, with the winning five lit as the live reveal lights them.
    private var showdownTable: some View {
        let spot = ShowdownSpotGenerator.spot(baseSeed: seed, index: index)
        let winner: Int? = {
            guard case let .integer(answer)? = input else { return nil }
            return gradeShowdown(answer: answer, spot: spot, language: language).winner
        }()
        let winningFive: [Card] = switch winner {
        case 0: bestFiveCards(spot.hero + spot.board)
        case 1: bestFiveCards(spot.villain + spot.board)
        default: []
        }
        return ThreeRegionCardTable(
            opponent: spot.villain, board: spot.board, hero: spot.hero,
            opponentTitle: winner == 1 ? language.text("상대 카드 · 승", "Opponent · won")
                                       : language.text("상대 카드", "Opponent's cards"),
            heroTitle: winner == 0 ? language.text("내 카드 · 승", "Your cards · won")
                                   : language.text("내 카드", "Your cards"),
            highlight: winningFive)
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
            if concept == .outs {
                let spot = OutsSpotGenerator.spot(baseSeed: seed, index: index)
                Text(language.text("이기는 마지막 카드 · 눌러서 확인", "Winning final cards · tap to explore"))
                    .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                riverCards(spot.outs, excluded: false)
                if !spot.excluded.isEmpty {
                    Text(language.text("제외 · 상대도 더 좋아져요", "Excluded · the opponent improves too"))
                        .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                    riverCards(spot.excluded, excluded: true)
                }
                if let selectedRiver { RiverExplainPanel(spot: spot, river: selectedRiver) }
            } else if let focus = script.beats.last?.focus {
                focusView(focus)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.07), in: RoundedRectangle(cornerRadius: GT.Radius.control))
        .sheet(isPresented: $showingPotHelp) {
            PotMathIntroView { showingPotHelp = false }
        }
    }

    private func riverCards(_ cards: [Card], excluded: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 9)], spacing: 9) {
            ForEach(cards, id: \.self) { card in
                Button { selectedRiver = card } label: {
                    PlayingCardView(card: card, dead: excluded)
                        .overlay {
                            if selectedRiver == card {
                                RoundedRectangle(cornerRadius: 5).strokeBorder(GT.cta, lineWidth: 3)
                            }
                        }
                }.buttonStyle(GTPress())
                    .accessibilityHint(language.text("리버 완성 핸드 보기", "See the completed river hand"))
            }
        }
    }

    @ViewBuilder
    private var questionContext: some View {
        switch concept {
        case .potMath:
            let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("팟 계산", "Count the pot"))
                .font(GT.title(18)).foregroundStyle(GT.onFelt)
            PotMathReplayView(spot: spot, stepIndex: $potStepIndex, revealedPot: spot.pot,
                              showsPaidTotals: assisted) {
                showingPotHelp = true
            }
            .onAppear { potStepIndex = max(0, spot.replaySteps.count - 1) }
        case .position:
            let spot = PositionSpotGenerator.spot(baseSeed: seed, index: index)
            HStack(spacing: 5) {
                ForEach(Position.preflopOrder, id: \.self) { seat in
                    Text(seat.rawValue).font(GT.semibold(10))
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .foregroundStyle(GT.onFelt)
                        .background(GT.onFelt.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            if case let .behind(seat, preflop) = spot.question {
                Text(language.text("\(seat.rawValue) · \(preflop ? "프리플랍" : "플랍 이후")",
                                   "\(seat.rawValue) · \(preflop ? "before" : "after") the flop"))
                    .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
            } else if case let .whichIsLater(a, b) = spot.question {
                Text(language.text("\(a.rawValue)와 \(b.rawValue) 중 늦은 자리",
                                   "Which acts later: \(a.rawValue) or \(b.rawValue)?"))
                    .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
            }
        case .evCall:
            let spot = EVCallSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb · 내 에퀴티 \(pctText(spot.equityPct))%",
                               "Pot \(spot.pot)bb · Bet \(spot.bet)bb · Win chance \(pctText(spot.equityPct))%"))
                .font(GT.body(15)).foregroundStyle(GT.onFelt)
        case .potOdds, .mdf:
            let spot = BetSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb",
                               "Pot \(spot.pot)bb · Opponent bets \(spot.bet)bb"))
                .font(GT.body(15)).foregroundStyle(GT.onFelt)
            PriceBarView.priced(pot: spot.pot, bet: spot.bet, withCall: concept == .potOdds)
        case .rangeNotation:
            let spot = RangeNotationSpotGenerator.spot(baseSeed: seed, index: index)
            Text(spot.notation).font(GT.title(27).monospaced())
                .foregroundStyle(GT.onFelt)
        case .rangeRead:
            let spot = RangeReadSpotGenerator.spot(baseSeed: seed, index: index)
            Text(spot.archetypeShown ? spot.archetype.beginnerTitle(in: language)
                                     : language.text("모르는 상대", "Unknown opponent"))
                .font(GT.title(16)).foregroundStyle(GT.onFelt)
            ForEach(Array(spot.actionLines(in: language).enumerated()), id: \.offset) { _, line in
                Text(line).font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
            }
        case .callFold:
            let spot = CallFoldSpotGenerator.spot(baseSeed: seed, index: index)
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
            let spot = DefendSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("\(spot.opener.rawValue)가 3bb 오픈",
                               "\(spot.opener.rawValue) raises first to 3bb"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .combos:
            let spot = BlockerSpotGenerator.spot(baseSeed: seed, index: index)
            Text(spot.className).font(GT.title(18)).foregroundStyle(GT.onFelt)
        case .hitFrequency:
            let spot = HitFrequencySpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("\(spot.seat.rawValue) 오픈 · 상위 \(pctText(spot.range.percent))%",
                               "\(spot.seat.rawValue) raises first · top \(pctText(spot.range.percent))%"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .rangeAdvantage:
            let spot = RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("\(spot.openerSeat.rawValue) 오픈 · \(spot.callerSeat.rawValue) 콜",
                               "\(spot.openerSeat.rawValue) raises first · \(spot.callerSeat.rawValue) calls"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .actionRead:
            let spot = ActionReadSpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("\(spot.villainSeat.rawValue) 오픈 → \(spot.actionLine)",
                               "\(spot.villainSeat.rawValue) raises first → \(spot.actionLine(in: language))"))
                .font(GT.body(14)).foregroundStyle(GT.onFelt)
        case .rfi:
            let spot = RFISpotGenerator.spot(baseSeed: seed, index: index)
            Text(language.text("내 자리 · \(spot.seat.rawValue)", "Your seat · \(spot.seat.rawValue)"))
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
                            ? DefendSpotGenerator.spot(baseSeed: seed, index: index).hand : [])
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
                    BucketBarView(label: bar.label, distribution: bar.distribution)
                }
            }
        }
    }
}
