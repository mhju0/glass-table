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

            sheet()
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(GT.card)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
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

    var body: some View {
        DrillShell(title: "쇼다운", progressText: progressText) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "상대"); CardRow(cards: spot.villain, maxSize: 52)
                SectionLabel(text: "보드").padding(.top, 10)
                CardRow(cards: spot.board, maxSize: 44)
                SectionLabel(text: "내 핸드").padding(.top, 10)
                CardRow(cards: spot.hero, maxSize: 52)
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
                        Button { reveal = gradeShowdown(answer: i, spot: spot) } label: {
                            Text(label).font(GT.title(14)).foregroundStyle(GT.ink)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(GTPress())
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
                    Button { reveal = gradePosition(answer: n, spot: spot) } label: {
                        Text("\(n)").font(GT.title(15)).foregroundStyle(GT.ink)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(GTPress())
                }
            }
        case let .whichIsLater(a, b):
            HStack(spacing: 10) {
                ForEach(Array([a, b].enumerated()), id: \.offset) { i, p in
                    Button { reveal = gradePosition(answer: i, spot: spot) } label: {
                        Text(p.rawValue).font(GT.title(15)).foregroundStyle(GT.ink)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(GTPress())
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
                SectionLabel(text: "상대"); CardRow(cards: spot.villain, maxSize: 52)
                SectionLabel(text: spot.board.count == 3 ? "보드 · 플랍" : "보드 · 턴")
                    .padding(.top, 10)
                CardRow(cards: spot.board, maxSize: 46)
                SectionLabel(text: "내 핸드").padding(.top, 10)
                CardRow(cards: spot.hero, maxSize: 52)
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

    private var outsSpot: OutsSpot { OutsSpotGenerator.spot(baseSeed: seed, index: index) }
    private var comboSpot: BlockerSpot { BlockerSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: kind == .outs ? "아웃" : "콤보", progressText: progressText) {
            if kind == .outs { outsContent } else { comboContent }
        } sheet: {
            if let result {
                RevealSheet(band: result.band, mine: result.mine,
                            correct: result.correct, why: result.why) {
                    onAnswer(DrillOutcome(band: result.band, interval: nil))
                    self.result = nil; value = 8
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
            SectionLabel(text: "상대"); CardRow(cards: outsSpot.villain, maxSize: 52)
            SectionLabel(text: "보드 · 턴").padding(.top, 10)
            CardRow(cards: outsSpot.board, maxSize: 46)
            SectionLabel(text: "내 핸드").padding(.top, 10)
            CardRow(cards: outsSpot.hero, maxSize: 52)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var comboContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "상대 핸드 클래스")
            Text(comboSpot.className).font(GT.title(26)).foregroundStyle(GT.onFelt)
            SectionLabel(text: "보이는 카드").padding(.top, 6)
            CardRow(cards: comboSpot.removed, maxSize: 46)
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
                SectionLabel(text: "상대"); CardRow(cards: spot.villain, maxSize: 50)
                SectionLabel(text: "보드 · 턴").padding(.top, 10)
                CardRow(cards: spot.board, maxSize: 44)
                SectionLabel(text: "내 핸드").padding(.top, 10)
                CardRow(cards: spot.hero, maxSize: 50)
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
                            Button { reveal = gradeCallFold(userCalls: calls, spot: spot) } label: {
                                Text(label).font(GT.title(15)).foregroundStyle(GT.ink)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
                            }
                            .buttonStyle(GTPress())
                        }
                    }
                }
            }
        }
    }
}
