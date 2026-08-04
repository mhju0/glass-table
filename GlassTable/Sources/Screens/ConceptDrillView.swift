// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// What one answered spot reports upward.
struct DrillOutcome {
    let band: GradeBand
    /// Present only for estimation concepts (spec §5.4).
    let interval: IntervalAnswer?
}

/// Renders one spot for any concept and reports the graded result.
///
/// Deliberately thin: every concept's spot generation and grading already lives in
/// `GlassTableDrills` and is tested there. This file only chooses a layout.
struct ConceptDrillView: View {
    let concept: Concept
    let seed: UInt64
    let index: Int
    let progressText: String
    let onAnswer: (DrillOutcome) -> Void

    var body: some View {
        switch concept {
        case .showdown:
            ShowdownDrill(seed: seed, index: index, progressText: progressText, onAnswer: onAnswer)
        case .potMath:
            PotMathDrill(seed: seed, index: index, progressText: progressText, onAnswer: onAnswer)
        case .position:
            PositionDrill(seed: seed, index: index, progressText: progressText, onAnswer: onAnswer)
        case .equitySense:
            EquitySenseDrill(seed: seed, index: index, progressText: progressText, onAnswer: onAnswer)
        case .evCall:
            EVCallDrill(seed: seed, index: index, progressText: progressText, onAnswer: onAnswer)
        case .combos:
            CountDrill(kind: .combos, seed: seed, index: index,
                       progressText: progressText, onAnswer: onAnswer)
        case .outs:
            CountDrill(kind: .outs, seed: seed, index: index,
                       progressText: progressText, onAnswer: onAnswer)
        case .potOdds:
            PercentDrill(isMDF: false, seed: seed, index: index,
                         progressText: progressText, onAnswer: onAnswer)
        case .mdf:
            PercentDrill(isMDF: true, seed: seed, index: index,
                         progressText: progressText, onAnswer: onAnswer)
        case .callFold:
            CallFoldDrill(seed: seed, index: index,
                          progressText: progressText, onAnswer: onAnswer)
        case .rangeNotation:
            RangeNotationDrill(seed: seed, index: index,
                               progressText: progressText, onAnswer: onAnswer)
        case .rfi:
            RFIDrill(seed: seed, index: index,
                     progressText: progressText, onAnswer: onAnswer)
        case .rangeRead:
            RangeReadDrill(seed: seed, index: index,
                           progressText: progressText, onAnswer: onAnswer)
        case .hitFrequency:
            HitFrequencyDrill(seed: seed, index: index,
                              progressText: progressText, onAnswer: onAnswer)
        case .rangeAdvantage:
            RangeAdvantageDrill(seed: seed, index: index,
                                progressText: progressText, onAnswer: onAnswer)
        }
    }
}

// MARK: - shared chrome

/// Every drill shares the same skeleton: felt content zone, cream answer sheet.
private struct DrillShell<Content: View, Sheet: View>: View {
    let title: String
    let progressText: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var sheet: () -> Sheet

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(GT.title(16)).foregroundStyle(GT.onFelt)
                Spacer()
                Text(progressText).font(GT.semibold(12).monospacedDigit())
                    .foregroundStyle(GT.onFeltSecondary)
            }
            .padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 12)

            ScrollView { content().padding(.horizontal, 18) }

            ActionSheet { sheet() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Reveal panel shared by every drill: verdict, the "why", then advance.
private struct RevealSheet: View {
    let band: GradeBand
    let mine: String
    let correct: String
    let why: String
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VerdictRow(band: band, mine: mine, correct: correct)
            Text(why).font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GT.border, lineWidth: 1))
                .fixedSize(horizontal: false, vertical: true)
            PrimaryCTAButton(title: "다음 문제", action: onNext)
        }
    }
}

/// Point estimate plus the 90% interval, for the three estimation concepts.
/// The interval is what makes the calibration screen possible (spec §5.4).
private struct IntervalInput: View {
    @Binding var point: Double
    @Binding var halfWidth: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("추정").font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                Spacer()
                Text("\(fmt(point))\(unit)")
                    .font(GT.title(20).monospacedDigit()).foregroundStyle(GT.ink)
            }
            Slider(value: $point, in: range, step: step).tint(GT.cta)
            HStack {
                Text("90% 구간").font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                Spacer()
                Text("\(fmt(max(range.lowerBound, point - halfWidth)))–\(fmt(min(range.upperBound, point + halfWidth)))\(unit)")
                    .font(GT.semibold(14).monospacedDigit()).foregroundStyle(GT.inkSecondary)
            }
            Slider(value: $halfWidth, in: step...(range.upperBound - range.lowerBound) / 2,
                   step: step).tint(GT.inkMuted)
            Text("좁을수록 점수가 좋아요. 다만 정답이 구간을 벗어나면 크게 깎여요.")
                .font(GT.body(10.5)).foregroundStyle(GT.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func fmt(_ x: Double) -> String {
        abs(x - x.rounded()) < 0.05 ? "\(Int(x.rounded()))" : String(format: "%.1f", x)
    }
}

// MARK: - 쇼다운

private struct ShowdownDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: ShowdownReveal?

    private var spot: ShowdownSpot { ShowdownSpotGenerator.spot(baseSeed: seed, index: index) }

    /// The five cards that actually won, lit once the answer is in. Getting it right
    /// should *show* you something — the previous reveal changed only the text.
    private var winningFive: [Card] {
        guard let reveal else { return [] }
        switch reveal.winner {
        case 0: return bestFiveCards(spot.hero + spot.board)
        case 1: return bestFiveCards(spot.villain + spot.board)
        default: return spot.board
        }
    }

    var body: some View {
        DrillShell(title: "쇼다운", progressText: progressText) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: reveal == nil ? "상대" : (reveal!.winner == 1 ? "상대 · 승" : "상대"))
                CardRow(cards: spot.villain, maxSize: 78, highlight: winningFive)
                SectionLabel(text: "보드").padding(.top, 10)
                CardRow(cards: spot.board, maxSize: 70, highlight: winningFive)
                SectionLabel(text: reveal == nil ? "내 핸드" : (reveal!.winner == 0 ? "내 핸드 · 승" : "내 핸드"))
                    .padding(.top, 10)
                CardRow(cards: spot.hero, maxSize: 78, highlight: winningFive)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: ["내가 이김", "상대가 이김", "찹"][reveal.answer],
                            correct: ["내가 이김", "상대가 이김", "찹"][reveal.winner],
                            why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("누가 이겼나요?").font(GT.title(15)).foregroundStyle(GT.ink)
                    ForEach(Array(["내가 이김", "상대가 이김", "찹"].enumerated()), id: \.offset) { i, label in
                        GTChoiceButton(title: label) {
                            reveal = gradeShowdown(answer: i, spot: spot)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 팟 계산

private struct PotMathDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var value = 10
    @State private var reveal: PotMathReveal?

    private var spot: PotMathSpot { PotMathSpotGenerator.spot(baseSeed: seed, index: index) }

    private var question: String {
        switch spot.question {
        case .potNow: return "지금 팟은 몇 bb인가요?"
        case let .fractionOfPot(f): return "팟의 \(Int((f * 100).rounded()))%는 몇 bb인가요?"
        }
    }

    var body: some View {
        DrillShell(title: "팟 계산", progressText: progressText) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "액션")
                ForEach(Array(actionLines.enumerated()), id: \.offset) { _, line in
                    Text(line).font(GT.body(13)).foregroundStyle(GT.onFelt)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(reveal.answer)bb",
                            correct: "\(reveal.correct)bb", why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; value = 10
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(question).font(GT.title(15)).foregroundStyle(GT.ink)
                    HStack {
                        Spacer()
                        EstimateStepper(value: value, suffix: "bb") {
                            value = max(0, value + $0)
                        }
                        Spacer()
                    }
                    PrimaryCTAButton(title: "확인") {
                        reveal = gradePotMath(answer: value, spot: spot)
                    }
                }
            }
        }
    }

    private var actionLines: [String] {
        spot.actions.map { action in
            switch action {
            case let .blinds(sb, bb): return "블라인드 \(sb) / \(bb)"
            case let .bet(n): return "벳 \(n)bb"
            case let .call(n): return "콜 \(n)bb"
            case let .raiseTo(to, from):
                return from == 0 ? "레이즈 \(to)bb" : "레이즈 \(to)bb (이미 \(from) 넣음)"
            }
        }
    }
}

// MARK: - 포지션

private struct PositionDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: PositionReveal?

    private var spot: PositionSpot { PositionSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "포지션", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "8맥스 테이블 · 행동 순서")
                seatStrip
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: answerLabel(reveal.answer),
                            correct: answerLabel(reveal.correct), why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(questionText).font(GT.title(15)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    answerControls
                }
            }
        }
    }

    private var isPreflop: Bool {
        if case let .behind(_, preflop) = spot.question { return preflop }
        return false
    }

    private var seatStrip: some View {
        let order = isPreflop ? Position.preflopOrder : Position.postflopOrder
        let mine: Position? = { if case let .behind(p, _) = spot.question { return p }; return nil }()
        return HStack(spacing: 5) {
            ForEach(order, id: \.self) { p in
                Text(p.rawValue)
                    .font(GT.semibold(10)).foregroundStyle(p == mine ? GT.felt : GT.onFelt)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(p == mine ? GT.mint : GT.onFelt.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var questionText: String {
        switch spot.question {
        case let .behind(p, preflop):
            return "\(p.rawValue) 자리예요. \(preflop ? "프리플랍" : "플랍 이후")에 내 뒤에 몇 명이 남았나요?"
        case let .whichIsLater(a, b):
            return "\(a.rawValue)와 \(b.rawValue) 중 어느 쪽이 더 늦게 행동하나요?"
        }
    }

    @ViewBuilder
    private var answerControls: some View {
        switch spot.question {
        case .behind:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                      spacing: 8) {
                ForEach(0...7, id: \.self) { n in
                    GTChoiceButton(title: "\(n)", minHeight: 50) {
                        reveal = gradePosition(answer: n, spot: spot)
                    }
                }
            }
        case let .whichIsLater(a, b):
            HStack(spacing: 10) {
                ForEach(Array([a, b].enumerated()), id: \.offset) { i, p in
                    GTChoiceButton(title: p.rawValue, minHeight: 54) {
                        reveal = gradePosition(answer: i, spot: spot)
                    }
                }
            }
        }
    }

    private func answerLabel(_ n: Int) -> String {
        switch spot.question {
        case .behind: return "\(n)명"
        case let .whichIsLater(a, b): return (n == 0 ? a : b).rawValue
        }
    }
}

// MARK: - 에퀴티 감각

private struct EquitySenseDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 50.0
    @State private var halfWidth = 10.0
    @State private var reveal: EstimateReveal?

    private var spot: EquitySenseSpot { EquitySenseSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "에퀴티 감각", progressText: progressText) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "상대"); CardRow(cards: spot.villain, maxSize: 78)
                SectionLabel(text: spot.board.count == 3 ? "보드 · 플랍" : "보드 · 턴")
                    .padding(.top, 10)
                CardRow(cards: spot.board, maxSize: 70)
                SectionLabel(text: "내 핸드").padding(.top, 10)
                CardRow(cards: spot.hero, maxSize: 78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(Int(reveal.estimate.point))%",
                            correct: "\(pctText(reveal.correct))%",
                            why: reveal.whyText + (reveal.intervalHit
                                 ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요.")) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 50; halfWidth = 10
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("쇼다운까지 갔을 때 내가 이길 확률은?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: 1, unit: "%")
                    PrimaryCTAButton(title: "확인") {
                        reveal = gradeEquitySense(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot)
                    }
                }
            }
        }
    }
}

// MARK: - EV 계산

private struct EVCallDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 0.0
    @State private var halfWidth = 1.0
    @State private var reveal: EstimateReveal?

    private var spot: EVCallSpot { EVCallSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "EV 계산", progressText: progressText) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "상황")
                VStack(alignment: .leading, spacing: 6) {
                    Text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb")
                        .font(GT.title(16)).foregroundStyle(GT.onFelt)
                    Text("내 에퀴티 \(pctText(spot.equityPct))%")
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                }
                Text("콜하면 \(spot.pot + spot.bet)bb를 걸고 \(spot.bet)bb를 잃을 수 있어요.")
                    .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: "\(pctText(reveal.estimate.point))bb",
                            correct: "\(pctText(reveal.correct))bb",
                            why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 0; halfWidth = 1
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("이 콜의 EV는 몇 bb인가요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: -20...20, step: 0.5, unit: "bb")
                    PrimaryCTAButton(title: "확인") {
                        reveal = gradeEVCall(
                            estimate: Estimate(point: point, lo: point - halfWidth,
                                               hi: point + halfWidth),
                            spot: spot)
                    }
                }
            }
        }
    }
}

// MARK: - the four M1 concepts, rendered natively in the new shell

/// 아웃 and 콤보: both answer with a whole-number count, so they share a screen and
/// differ only in what is shown above it and which grader runs.
private struct CountDrill: View {
    enum Kind { case outs, combos }
    let kind: Kind
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var value = 8
    @State private var result: (band: GradeBand, mine: String, correct: String, why: String)?
    @State private var tappedOut: Card?

    private var outsSpot: OutsSpot { OutsSpotGenerator.spot(baseSeed: seed, index: index) }
    private var comboSpot: BlockerSpot { BlockerSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: kind == .outs ? "아웃" : "콤보", progressText: progressText) {
            if kind == .outs {
                // After the reveal the outs become tappable, so an abstract count turns
                // into a hand you can actually see finish. Counting 9 teaches less than
                // watching one of the nine win.
                if result != nil { outsReveal } else { outsContent }
            } else {
                comboContent
            }
        } sheet: {
            if let result {
                RevealSheet(band: result.band, mine: result.mine,
                            correct: result.correct, why: result.why) {
                    onAnswer(DrillOutcome(band: result.band, interval: nil))
                    self.result = nil; value = 8; tappedOut = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(kind == .outs ? "리버에 나를 이기게 해주는 카드는 몇 장인가요?"
                                       : "상대가 이 핸드를 가질 수 있는 콤보는 몇 개인가요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack { Spacer()
                        EstimateStepper(value: value, suffix: kind == .outs ? "장" : "개") {
                            value = max(0, value + $0)
                        }
                        Spacer() }
                    PrimaryCTAButton(title: "확인", action: submit)
                }
            }
        }
    }

    private func submit() {
        switch kind {
        case .outs:
            let r = gradeOuts(estimate: value, spot: outsSpot)
            result = (r.band, "\(value)장", "\(outsSpot.outCount)장", r.whyText)
        case .combos:
            let r = gradeBlocker(estimate: value, spot: comboSpot)
            result = (r.band, "\(value)개", "\(comboSpot.count)개", r.whyText)
        }
    }

    private var outsContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "상대"); CardRow(cards: outsSpot.villain, maxSize: 78)
            SectionLabel(text: "보드 · 턴").padding(.top, 10)
            CardRow(cards: outsSpot.board, maxSize: 70)
            SectionLabel(text: "내 핸드").padding(.top, 10)
            CardRow(cards: outsSpot.hero, maxSize: 78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The restored affordance from the M1 outs reveal: every out is tappable and
    /// shows the finished river hand for both players via `RiverExplainPanel`.
    private var outsReveal: some View {
        let spot = outsSpot
        return VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "상대"); CardRow(cards: spot.villain, maxSize: 70)
            SectionLabel(text: "보드 · 턴").padding(.top, 8)
            CardRow(cards: spot.board, maxSize: 64)
            SectionLabel(text: "내 핸드").padding(.top, 8); CardRow(cards: spot.hero, maxSize: 70)

            SectionLabel(text: "리버 아웃 · \(spot.outCount)장 · 눌러서 확인").padding(.top, 12)
            outsGrid(spot.outs, dead: false)
            if !spot.excluded.isEmpty {
                SectionLabel(text: "제외 · 상대 핸드 개선").padding(.top, 10)
                outsGrid(spot.excluded, dead: true)
            }
            if let tappedOut {
                RiverExplainPanel(spot: spot, river: tappedOut).padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func outsGrid(_ cards: [Card], dead: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 9)],
                  alignment: .leading, spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        tappedOut = tappedOut == card ? nil : card
                    }
                } label: {
                    PlayingCardView(card: card, size: 58, dead: dead)
                        .overlay {
                            if tappedOut == card {
                                RoundedRectangle(cornerRadius: 58 * 0.17)
                                    .stroke(GT.mint, lineWidth: 3)
                            }
                        }
                }
                .buttonStyle(GTPress())
                .accessibilityHint("리버 완성 핸드 보기")
            }
        }
    }

    private var comboContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "상대 핸드 클래스")
            Text(comboSpot.className).font(GT.title(26)).foregroundStyle(GT.onFelt)
            SectionLabel(text: "보이는 카드").padding(.top, 6)
            CardRow(cards: comboSpot.removed, maxSize: 70)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 팟 오즈 and MDF: the same percent estimate against the same `BetSpot`.
private struct PercentDrill: View {
    let isMDF: Bool
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var value = 30
    @State private var reveal: PercentReveal?

    private var spot: BetSpot { BetSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: isMDF ? "MDF" : "팟 오즈", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "상황")
                Text("팟 \(spot.pot)bb").font(GT.title(22)).foregroundStyle(GT.onFelt)
                Text("상대 벳 \(spot.bet)bb").font(GT.title(18))
                    .foregroundStyle(GT.onFeltSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(reveal.answerPct)%",
                            correct: "\(pctText(reveal.correctPct))%", why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; value = 30
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isMDF ? "이 벳에 최소 몇 %를 지켜야 하나요?"
                               : "콜하려면 최소 몇 %의 에퀴티가 필요한가요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack { Spacer()
                        EstimateStepper(value: value, step: 5, suffix: "%") {
                            value = min(100, max(0, value + $0))
                        }
                        Spacer() }
                    PrimaryCTAButton(title: "확인") {
                        reveal = isMDF ? gradeMDF(estimatePct: value, spot: spot)
                                       : gradePotOdds(estimatePct: value, spot: spot)
                    }
                }
            }
        }
    }
}

/// 콜/폴드 — the Block A boss concept: equity vs price, decided.
private struct CallFoldDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: CallFoldReveal?

    private var spot: CallFoldSpot { CallFoldSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "콜/폴드", progressText: progressText) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "상대"); CardRow(cards: spot.villain, maxSize: 78)
                SectionLabel(text: "보드 · 턴").padding(.top, 10)
                CardRow(cards: spot.board, maxSize: 70)
                SectionLabel(text: "내 핸드").padding(.top, 10)
                CardRow(cards: spot.hero, maxSize: 78)
                Text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb")
                    .font(GT.title(15)).foregroundStyle(GT.onFelt).padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: reveal.userCalls ? "콜" : "폴드",
                            correct: reveal.correctIsCall ? "콜" : "폴드",
                            why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("콜인가요, 폴드인가요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                    HStack(spacing: 10) {
                        // Equal weight on both, so the layout carries no bias toward
                        // calling — the same rule the M1 screen already followed.
                        ForEach([("폴드", false), ("콜", true)], id: \.0) { label, calls in
                            GTChoiceButton(title: label, minHeight: 56) {
                                reveal = gradeCallFold(userCalls: calls, spot: spot)
                            }
                        }
                    }
                }
            }
        }
    }
}


// MARK: - 레인지 표기법

private struct RangeNotationDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var value = 12
    @State private var reveal: RangeNotationReveal?

    private var spot: RangeNotationSpot {
        RangeNotationSpotGenerator.spot(baseSeed: seed, index: index)
    }

    var body: some View {
        DrillShell(title: "레인지 표기법", progressText: progressText) {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "레인지")
                Text(spot.notation)
                    .font(GT.title(30).monospaced()).foregroundStyle(GT.onFelt)
                    .minimumScaleFactor(0.5).lineLimit(2)
                if reveal != nil {
                    SectionLabel(text: "표에서 보면").padding(.top, 6)
                    RangeGridView(range: spot.range)
                        .frame(maxWidth: 320)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(reveal.estimate) 콤보",
                            correct: "\(reveal.count) 콤보", why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; value = 12
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("이 레인지는 몇 콤보인가요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                    HStack { Spacer()
                        EstimateStepper(value: value, suffix: "") {
                            value = max(0, value + $0)
                        }
                        Spacer() }
                    PrimaryCTAButton(title: "확인") {
                        reveal = gradeRangeNotation(estimate: value, spot: spot)
                    }
                }
            }
        }
    }
}

// MARK: - RFI 차트

private struct RFIDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: RFIReveal?

    private var spot: RFISpot { RFISpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "RFI 차트", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "내 핸드")
                CardRow(cards: spot.hand, maxSize: 78)
                SectionLabel(text: "내 자리").padding(.top, 8)
                seatStrip
                if reveal != nil {
                    SectionLabel(text: "\(spot.seat.rawValue) 오픈 레인지").padding(.top, 10)
                    RangeGridView(range: RFIChart.range(for: spot.seat),
                                  highlight: spot.handClass)
                        .frame(maxWidth: 320)
                    Text("8핸드 차트는 공개된 9맥스·6맥스 사이를 보간한 값이에요.")
                        .font(GT.body(10.5)).foregroundStyle(GT.onFeltMuted)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: reveal.userOpens ? "오픈" : "폴드",
                            correct: reveal.correctOpens ? "오픈" : "폴드",
                            why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(spot.seat.rawValue)에서 이 핸드, 오픈인가요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                    HStack(spacing: 10) {
                        ForEach([("폴드", false), ("오픈", true)], id: \.0) { label, opens in
                            GTChoiceButton(title: label, minHeight: 56) {
                                reveal = gradeRFI(userOpens: opens, spot: spot)
                            }
                        }
                    }
                }
            }
        }
    }

    private var seatStrip: some View {
        HStack(spacing: 4) {
            ForEach(Position.preflopOrder, id: \.self) { p in
                Text(p.rawValue)
                    .font(GT.semibold(9.5))
                    .foregroundStyle(p == spot.seat ? GT.onCTA : GT.onFelt.opacity(0.75))
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(p == spot.seat ? GT.mint : GT.onFelt.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 7))
            }
        }
    }
}

// MARK: - 레인지 리드

/// The one drill where you never see a card. You get the action, and you build the
/// shape you think it means with a width and a set of tendencies.
///
/// The grid sits in the content zone and the controls in the sheet on purpose: both
/// are on screen at once, so dragging the slider *is* watching a range widen. That
/// live coupling is the whole reason the input is coarse — a number alone would teach
/// the arithmetic of a percentage rather than the look of a range.
private struct RangeReadDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var width: Double = 20
    @State private var tendencies: Set<RangeTendency> = []
    @State private var reveal: RangeReadReveal?

    private var spot: RangeReadSpot { RangeReadSpotGenerator.spot(baseSeed: seed, index: index) }
    private var estimate: RangeEstimate { RangeEstimate(width: width, tendencies: tendencies) }

    var body: some View {
        DrillShell(title: "레인지 리드", progressText: progressText) {
            VStack(alignment: .leading, spacing: 9) {
                opponentLine
                actionList
                SectionLabel(text: reveal == nil ? "내가 보는 범위" : "정답 · 내 답 비교")
                    .padding(.top, 4)
                // The legend goes *above* the grid. Below it, the one thing that makes
                // a two-channel grid readable sat under the answer sheet and was never
                // seen — found by looking at the sweep rather than by reasoning.
                if reveal != nil { legend }
                RangeGridView(range: reveal?.truth ?? estimate.range,
                              outline: reveal?.guess)
                    .frame(maxWidth: 250)
                    .animation(.easeOut(duration: 0.18), value: width)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                #if DEBUG
                // GT_DEMO_REVEAL=<width> answers with that width so the comparison
                // grid and its legend are reachable by screenshot. Same reason as
                // GT_DEMO_BEAT: synthetic taps never reach Simulator content, and the
                // reveal is the half of this screen most likely to be wrong.
                if let w = ProcessInfo.processInfo.environment["GT_DEMO_REVEAL"]
                    .flatMap(Double.init) {
                    width = w
                    reveal = gradeRangeRead(estimate: RangeEstimate(width: w), spot: spot)
                }
                #endif
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: "상위 \(pctText(reveal.guess.percent))%",
                            correct: "상위 \(pctText(reveal.truth.percent))%",
                            why: reveal.whyText) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; width = 20; tendencies = []
                }
            } else {
                input
            }
        }
    }

    // MARK: what the user is told

    private var opponentLine: some View {
        // Hidden archetype is the harder band, and it must not read as a bug: say
        // outright that the identification is part of the question.
        VStack(alignment: .leading, spacing: 1) {
            Text(spot.archetypeShown ? spot.archetype.name : "모르는 상대")
                .font(GT.title(19)).foregroundStyle(GT.onFelt)
            Text(spot.archetypeShown ? spot.archetype.blurb
                                     : "어떤 사람인지도 액션으로 판단해야 해요.")
                .font(GT.body(11.5)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionList: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(spot.actionLines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: 8) {
                    Circle().fill(GT.onFelt.opacity(0.35)).frame(width: 4, height: 4)
                    Text(line).font(GT.semibold(13)).foregroundStyle(GT.onFelt)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }

    /// Fill = truth, ring = your guess. Spelled out, because an unexplained two-channel
    /// grid is a puzzle rather than a reveal.
    private var legend: some View {
        HStack(spacing: 14) {
            key(filled: true, ringed: true, "맞음")
            key(filled: true, ringed: false, "놓침")
            key(filled: false, ringed: true, "넘침")
        }
        .padding(.top, 2)
    }

    private func key(filled: Bool, ringed: Bool, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(filled ? GT.mint.opacity(0.85) : GT.surface)
                .frame(width: 15, height: 15)
                .overlay {
                    if ringed { RoundedRectangle(cornerRadius: 3).strokeBorder(GT.ink, lineWidth: 2) }
                }
            Text(label).font(GT.semibold(11)).foregroundStyle(GT.onFeltSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: what the user answers with

    private var input: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("상대는 몇 %로 \(actionVerb)했을까요?")
                    .font(GT.title(15)).foregroundStyle(GT.ink)
                Spacer(minLength: 8)
                Text("\(pctText(width))%")
                    .font(GT.title(24).monospacedDigit()).foregroundStyle(GT.ink)
                    .contentTransition(.numericText())
            }
            Slider(value: $width, in: 3...80, step: 1).tint(GT.cta)
                .accessibilityLabel("범위 넓이")
                .accessibilityValue("상위 \(pctText(width))퍼센트")

            SectionLabel(text: "어디에 몰려 있나요 (선택)", onDark: false)
            chips
            if RangeTendency.allCases.contains(where: { $0.isSaturated(atWidth: width) }) {
                Text("\u{2261} 표시는 이 넓이에 이미 전부 들어 있어서 모양이 바뀌지 않는다는 뜻이에요.")
                    .font(GT.body(10)).foregroundStyle(GT.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PrimaryCTAButton(title: "확인") {
                reveal = gradeRangeRead(estimate: estimate, spot: spot)
            }
        }
    }

    private var actionVerb: String {
        if case .opened = spot.action { return "오픈" }
        return "콜"
    }

    /// Two rows of two, because four chips across a mini would each be ~78pt and the
    /// longest label is 오프수트 브로드웨이.
    private var chips: some View {
        let all = RangeTendency.allCases
        return VStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(all[(r * 2)..<(r * 2 + 2)], id: \.self) { chip($0) }
                }
            }
        }
    }

    /// Chip labels are shortened from the prose names — 오프수트 브로드웨이 does not
    /// fit a half-width chip, and 수티드 already carries the suited half of broadway.
    /// `tendencyWord` stays long, because the reveal sentence has room.
    private func chipLabel(_ t: RangeTendency) -> String {
        t == .offsuitBroadway ? "브로드웨이" : tendencyWord(t)
    }

    private func chip(_ t: RangeTendency) -> some View {
        let on = tendencies.contains(t)
        // A category entirely inside the cut has nothing left to prefer, so the chip
        // genuinely does nothing at this width. Say so rather than letting it read as
        // a dead control.
        let saturated = t.isSaturated(atWidth: width)
        return Button {
            if on { tendencies.remove(t) } else { tendencies.insert(t) }
        } label: {
            HStack(spacing: 4) {
                Text(chipLabel(t))
                    .font(on ? GT.title(13) : GT.semibold(13))
                    .foregroundStyle(on ? GT.onCTA : GT.ink)
                    .minimumScaleFactor(0.7).lineLimit(1)
                if saturated {
                    Image(systemName: "equal.circle.fill").font(.system(size: 11))
                        .foregroundStyle(on ? GT.onCTA.opacity(0.75) : GT.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 6)
            .background(on ? AnyShapeStyle(GT.cta) : AnyShapeStyle(GT.surface),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(on ? Color.clear : GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(tendencyWord(t))
        .accessibilityValue(on ? "선택됨" : "선택 안 됨")
        .accessibilityHint(saturated ? "이 넓이에서는 모양이 바뀌지 않아요" : "")
    }
}

// MARK: - 히트 프리퀀시

/// The first postflop drill: not "what should I do" — that needs S2's EV-loss grading —
/// but "what is even out there", which is the question every postflop decision starts
/// from and the one beginners skip.
private struct HitFrequencyDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 35.0
    @State private var halfWidth = 12.0
    @State private var reveal: EstimateReveal?

    private var spot: HitFrequencySpot {
        HitFrequencySpotGenerator.spot(baseSeed: seed, index: index)
    }

    var body: some View {
        DrillShell(title: "히트 프리퀀시", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "보드 · 플랍")
                CardRow(cards: spot.board, maxSize: 70)
                Text(spot.texture.summary)
                    .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                SectionLabel(text: "상대 레인지").padding(.top, 8)
                Text("\(spot.seat.rawValue) 오픈 · 상위 \(pctText(spot.range.percent))%")
                    .font(GT.title(17)).foregroundStyle(GT.onFelt)
                if reveal != nil {
                    BucketBarView(label: "\(spot.seat.rawValue) 오픈 레인지",
                                  distribution: spot.distribution)
                        .padding(.top, 6)
                    RangeGridView(range: spot.range).frame(maxWidth: 230).padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                #if DEBUG
                // GT_DEMO_REVEAL=<point> answers with that estimate, so the bucket
                // bars — the actual payload of both board drills — are reachable by
                // screenshot. Same reason as GT_DEMO_BEAT.
                if let v = ProcessInfo.processInfo.environment["GT_DEMO_REVEAL"]
                    .flatMap(Double.init) {
                    point = v
                    reveal = gradeHitFrequency(
                        estimate: Estimate(point: v, lo: max(0, v - halfWidth),
                                           hi: min(100, v + halfWidth)),
                        spot: spot)
                }
                #endif
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(Int(reveal.estimate.point))%",
                            correct: "\(pctText(reveal.correct))%",
                            why: reveal.whyText + (reveal.intervalHit
                                 ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요.")) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 35; halfWidth = 12
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("이 레인지의 몇 %가 페어 이상을 만들었을까요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: 1, unit: "%")
                    PrimaryCTAButton(title: "확인") {
                        reveal = gradeHitFrequency(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot)
                    }
                }
            }
        }
    }
}

// MARK: - 레인지 어드밴티지

private struct RangeAdvantageDrill: View {
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 50.0
    @State private var halfWidth = 10.0
    @State private var reveal: EstimateReveal?
    /// Sampled off the main thread the moment the spot appears, so it is already
    /// waiting by the time the sliders have been set. Computing it *during* the tap
    /// froze the screen for three seconds under a debug build.
    @State private var equity: Double?

    private var spot: RangeAdvantageSpot {
        RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index)
    }

    private func submit(_ v: Double) {
        guard let equity else { return }
        reveal = gradeRangeAdvantage(
            estimate: Estimate(point: v, lo: max(0, v - halfWidth),
                               hi: min(100, v + halfWidth)),
            spot: spot, openerEquityPct: equity)
    }

    var body: some View {
        DrillShell(title: "레인지 어드밴티지", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "보드 · 플랍")
                CardRow(cards: spot.board, maxSize: 70)
                Text(spot.texture.summary)
                    .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                SectionLabel(text: "액션").padding(.top, 8)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(spot.openerSeat.rawValue) 오픈 3bb")
                    Text("\(spot.callerSeat.rawValue) 콜 · \(spot.caller.name)")
                }
                .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                if reveal != nil {
                    VStack(alignment: .leading, spacing: 18) {
                        BucketBarView(label: "\(spot.openerSeat.rawValue) 오픈",
                                      distribution: rangeOnBoard(spot.openerRange,
                                                                 board: spot.board))
                        BucketBarView(label: "\(spot.callerSeat.rawValue) 콜",
                                      distribution: rangeOnBoard(spot.callerRange,
                                                                 board: spot.board))
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .task(id: index) {
                let s = seed, i = index
                equity = await Task.detached(priority: .userInitiated) {
                    RangeAdvantageSpotGenerator.spot(baseSeed: s, index: i).openerEquityPct
                }.value
                #if DEBUG
                // GT_DEMO_REVEAL=<point> answers with that estimate once the sampling
                // has landed, so the bucket bars are reachable by screenshot.
                if let v = ProcessInfo.processInfo.environment["GT_DEMO_REVEAL"]
                    .flatMap(Double.init) {
                    point = v
                    submit(v)
                }
                #endif
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(Int(reveal.estimate.point))%",
                            correct: "\(pctText(reveal.correct))%",
                            why: reveal.whyText + (reveal.intervalHit
                                 ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요.")) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 50; halfWidth = 10
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("쇼다운까지 가면 오프너의 승률은 몇 %일까요?")
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: 1, unit: "%")
                    if equity == nil {
                        Text("계산 중…").font(GT.semibold(13)).foregroundStyle(GT.inkMuted)
                            .frame(maxWidth: .infinity, minHeight: 54)
                    } else {
                        PrimaryCTAButton(title: "확인") { submit(point) }
                    }
                }
            }
        }
    }
}
