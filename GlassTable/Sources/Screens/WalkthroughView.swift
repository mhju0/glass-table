// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// 천천히 — the micro-step player (spec §5.2).
///
/// The board is the teaching surface; the text is the caption. Highlighted cards glow
/// and everything else dims, the layout holds still between beats so consecutive
/// beats read as a comparison, and dead cards strike through **in place** rather than
/// disappearing — seeing what was removed and why is the lesson.
///
/// Highlights are stable. A beat change moves only the card or value that changed.
struct WalkthroughView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.learningLanguage) private var language
    @Environment(\.simpleQuestions) private var simple
    let title: String
    let concept: Concept?
    /// One sentence on why the concept matters, shown on the first step.
    let purpose: String?
    let beats: [Beat]
    /// Card rows to show for `.table` beats: (label, cards), top to bottom.
    let rows: [(String, [Card])]
    let initialIndex: Int
    let onStep: (Int) -> Bool
    let onFinish: () -> Void

    @State private var index = 0
    @State private var positionTeachingStep: Int?
    /// The learner's one action in the example: the first computed value stays covered
    /// until they tap it, and Next waits for that tap.
    @State private var practiceRevealed = false
    @State private var workedAnswer: Int?
    @State private var chenRulesOpen = true

    init(title: String, concept: Concept? = nil, purpose: String? = nil, beats: [Beat], rows: [(String, [Card])],
         initialIndex: Int = 0, onStep: @escaping (Int) -> Bool = { _ in true },
         onFinish: @escaping () -> Void) {
        self.title = title; self.concept = concept; self.purpose = purpose; self.beats = beats; self.rows = rows
        self.initialIndex = initialIndex; self.onStep = onStep
        self.onFinish = onFinish
        _positionTeachingStep = State(initialValue: concept == .position && initialIndex == 0 ? 0 : nil)
    }

    private var orientation: [Beat] {
            var beats = [Beat(language.text("여덟 자리를 살펴봐요", "Explore eight seats"),
                              detail: language.text("6번이 딜러예요. 그 왼쪽이 작은 블라인드, 다음이 큰 블라인드예요.", "Seat 6 is the dealer. Next are the small blind and big blind.")),
                         Beat(language.text("차례 전에 칩을 내요", "Post before taking turns"),
                              detail: language.text("작은 블라인드는 1칩, 큰 블라인드는 2칩을 먼저 내요. 미리 내는 것과 차례에 행동하는 것은 달라요.", "The small blind posts 1 chip and the big blind 2. Posting is different from taking a turn."))]
            for position in Position.preflopOrder {
                let number = position.seatNumber
                beats.append(Beat(language.text("플랍 전 · 자리 \(number)", "Before flop · Seat \(number)"),
                                  detail: language.text("큰 블라인드 다음인 1번부터 시계 방향으로 행동해요. 이번은 \(number)번 차례예요.", "Start at seat 1 after the big blind and move clockwise. Seat \(number) acts now.")))
            }
            for position in Position.postflopOrder {
                let number = position.seatNumber
                beats.append(Beat(language.text("플랍 이후 · 자리 \(number)", "After flop · Seat \(number)"),
                                  detail: language.text("딜러 왼쪽부터 참여 중인 자리가 행동해요. 모두 참여 중이면 7번부터 시작해요. 지금은 \(number)번 차례예요. 폴드한 자리는 건너뛰어요.", "Begin left of the dealer among active seats. With all eight active, start at seat 7. Seat \(number) acts now. Skip folded seats.")))
            }
            return beats
    }
    private var beat: Beat {
        if let positionTeachingStep { return orientation[positionTeachingStep] }
        let original = beats[min(index, beats.count - 1)]
        guard concept == .position else { return original }
        func plain(_ text: String) -> String {
            Position.allCases.sorted { $0.rawValue.count > $1.rawValue.count }.reduce(text) { text, position in
                text.replacingOccurrences(of: position.rawValue, with: language.text("자리 \(position.seatNumber)", "Seat \(position.seatNumber)"))
            }
        }
        return Beat(plain(original.caption), value: original.value.map(plain), detail: original.detail.map(plain), focus: original.focus)
    }
    private var isLast: Bool { positionTeachingStep == nil && index >= beats.count - 1 }

    /// The last step that carries a value: the example's conclusion (the count, the
    /// percentage, the call). Every concept's script has one after its opening step
    /// (`WalkthroughPracticeTests`), so each example asks for a tap.
    static func practiceIndex(in beats: [Beat]) -> Int? {
        beats.indices.last { $0 > 0 && beats[$0].value != nil }
    }

    private var isCovered: Bool {
        positionTeachingStep == nil && !practiceRevealed && index == Self.practiceIndex(in: beats)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.section) {
                header
                content.frame(maxWidth: .infinity, alignment: .leading)
                // The pot example's steps are cards already; its caption card would only
                // repeat the last step's title, so it shows just the instruction.
                if concept != .potMath || isCovered {
                    VStack(alignment: .leading, spacing: GT.Space.related) { sheet }
                        .gtInset(GT.Space.card, firstText: sheetFirstText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .gtCard(radius: GT.Radius.panel)
                }
            }.padding(.horizontal, 18).padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { navigationActions }
        .simultaneousGesture(DragGesture().onEnded { gesture in
            if gesture.startLocation.x < 24, gesture.translation.width > 70 { previousStep() }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FeltBackground())
        .onAppear {
            index = min(max(0, initialIndex), max(0, beats.count - 1))
            #if DEBUG
            if let n = ProcessInfo.processInfo.environment["GT_DEMO_BEAT"].flatMap(Int.init) {
                index = min(max(0, n), beats.count - 1)
            }
            #endif
        }
    }

    private func previousStep() {
        if let step = positionTeachingStep {
            if step > 0 { positionTeachingStep = step - 1 }
            return
        }
        if concept == .position, index == 0 { positionTeachingStep = orientation.count - 1; return }
        guard index > 0, onStep(index - 1) else { return }
        withAnimation(reduceMotion ? nil : GT.Motion.change) { index -= 1 }
    }

    /// The pot example's one question: its total, on the step that asks for it.
    private var potCheck: Int? {
        guard concept == .potMath, positionTeachingStep == nil, index == Self.practiceIndex(in: beats) else { return nil }
        return beat.value.flatMap { Int($0.filter(\.isNumber)) }
    }

    /// The choices stay where they are once answered: the pick and the right total are
    /// marked in place and the whole panel takes the verdict's colour.
    private var navigationActions: some View {
        let correct = potCheck
        let picked = correct == nil ? nil : workedAnswer
        return ActionSheet(band: picked.map { $0 == correct ? .spotOn : .off }, collapsible: false) {
            VStack(alignment: .leading, spacing: 12) {
                if let picked {
                    LessonAnswerVerdict(correct: picked == correct) {
                        Text(picked == correct ? language.text("계산을 이어갈 수 있어요.", "You followed the contributions.")
                                               : language.text("기여액을 다시 더해 봐요.", "Add the contributions again."))
                            .font(GT.body(16)).fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("walkthrough-pot-feedback")
                    }
                }
                if let correct {
                    LessonCountChoices(values: BeginnerQuestionChoices.integers(answer: correct, bounds: 0...max(1326, correct + 10), seed: UInt64(index)),
                                       suffix: language.text("칩", " chips"), picked: picked, correct: correct) { chosen in
                        AppFeedback.answer(correct: chosen == correct)
                        withAnimation(reduceMotion ? nil : GT.Motion.change) {
                            workedAnswer = chosen
                            practiceRevealed = true
                        }
                    }.accessibilityIdentifier("walkthrough-pot-check")
                }
                let firstStep = positionTeachingStep == 0 || (positionTeachingStep == nil && index == 0 && concept != .position)
                GTStepRow(previous: firstStep ? nil : previousStep, previousID: "walkthrough-previous") {
                    PrimaryCTAButton(title: isCovered && concept != .potMath
                                     ? language.text("예시 확인", "Check example")
                                     : isLast ? language.text("예시 마치기", "Finish example")
                                              : language.text("다음", "Next")) {
                        if isCovered, concept != .potMath {
                            withAnimation(reduceMotion ? nil : GT.Motion.change) { practiceRevealed = true }
                        } else if let step = positionTeachingStep {
                            positionTeachingStep = step + 1 < orientation.count ? step + 1 : nil
                        } else if isLast { onFinish() }
                        else if onStep(index + 1) {
                            withAnimation(reduceMotion ? nil : GT.Motion.change) { index += 1 }
                        }
                    }.disabled(isCovered && concept == .potMath).accessibilityIdentifier("walkthrough-next")
                }
            }
        }
    }

    /// Skipping stays a word: it is a decision, not a direction, and an arrow would
    /// leave the learner guessing what they were giving up. The screen hosting the
    /// walkthrough puts it in its top bar, opposite the close control.
    static func skipTitle(_ language: LearningLanguage) -> String {
        language.text("건너뛰기", "Skip")
    }

    private var header: some View {
        let step: Int = (positionTeachingStep ?? index) + 1
        let stepCount: Int = positionTeachingStep == nil ? beats.count : orientation.count
        let progressStep: Double = Double(step)
        let progressCount: Double = Double(stepCount)
        let stepLabel: String = language.text("\(stepCount)단계 중 \(step)단계", "Step \(step) of \(stepCount)")
        let purposeLabel: String = index == 0 ? purpose.map { ". " + $0 } ?? "" : ""
        let accessibilityLabel: String = title + ", " + stepLabel + purposeLabel
        return VStack(spacing: 8) {
            HStack {
                Text("\(title) · \(language.text("따라 배우기", "Worked example"))").font(GT.semibold(14))
                    .foregroundStyle(GT.onFeltSecondary)
                Spacer()
                Text("\(step)/\(stepCount)")
                    .font(GT.semibold(14).monospacedDigit())
                    .foregroundStyle(GT.onFeltSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(GT.hairlineFelt).frame(height: 2)
                    Capsule().fill(GT.onFelt)
                        .frame(width: geo.size.width * progressStep / progressCount,
                               height: 2)
                }
            }
            .frame(height: 2)
            if index == 0, let purpose {
                Text(purpose)
                    .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .accessibilityIdentifier("walkthrough-purpose")
            }
        }
        .padding(.horizontal, 18).padding(.top, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("walkthrough-step-\(index)")
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            if concept == .combos, index == 0 { CombinationExampleView() }
            if concept == .position {
                LessonSeatLoop(active: positionActiveSeat, showsOrder: true, postflop: (positionTeachingStep ?? -1) >= 10)
            } else if concept == .potMath {
                VStack(alignment: .leading, spacing: 12) {
                    LessonPairedText(korean: ["블라인드는 차례 전에 내는 칩이에요.", "딜러 왼쪽 두 자리가 1칩과 2칩을 내요."],
                                    english: ["Blinds are chips posted before turns.", "Two seats left of the dealer post 1 and 2."])
                        .font(GT.body(15)).foregroundStyle(GT.ink)
                    ForEach(0...index, id: \.self) { step in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(beats[step].caption).font(GT.semibold(15))
                            if let detail = beats[step].detail {
                                Text(step == beats.count - 2 && !practiceRevealed
                                     ? detail.components(separatedBy: "=").dropLast().joined(separator: "=") + " = ?"
                                     : detail).font(GT.body(15))
                            }
                            if let value = beats[step].value {
                                if step == Self.practiceIndex(in: beats), !practiceRevealed { Text(language.text("합계는?", "Total?" )).font(GT.title(22)) }
                                else { Text(value).font(GT.title(22)) }
                            }
                        }.foregroundStyle(GT.ink).padding(14).frame(maxWidth: .infinity, alignment: .leading).gtCard()
                            .overlay {
                                if step == index {
                                    RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                                        .strokeBorder(GT.cta, lineWidth: 2)
                                }
                            }
                    }
                }
            } else if concept == .rfi, simple, index == 0 || index == 2 {
                if let hand = rows.first?.1 { LessonHandNotation(cards: hand) }
                if index == 2 {
                    LessonPairedText(korean: ["높은 숫자, 같은 무늬, 숫자 간격을 봐요.", "선택할 때는 이 자리의 차트를 사용해요."],
                                    english: ["Look at high ranks, shared suit and gaps.", "Use this seat’s chart for the decision."])
                        .font(GT.body(16)).foregroundStyle(GT.ink)
                }
            } else { beatContent }
        }
    }

    private var positionActiveSeat: Position? {
        guard let step = positionTeachingStep else { return nil }
        if (2...9).contains(step) { return Position.preflopOrder[step - 2] }
        return (10...17).contains(step) ? Position.postflopOrder[step - 10] : nil
    }

    @ViewBuilder
    private var beatContent: some View {
        switch beat.focus {
        case .none:
            // A concept with no cards — EV, pot odds, position — otherwise left the
            // whole content area empty, which reads as a broken screen rather than a
            // text beat. The payload moves up onto the felt so the beat has a subject;
            // the sheet keeps the label, the reasoning and the button.
            VStack(alignment: .leading, spacing: 10) {

                if isCovered {
                    revealTile
                } else {
                    Text(beat.value ?? beat.caption)
                        .font(GT.title(34)).foregroundStyle(GT.onFelt)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.numericText())
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .table:
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { offset, row in
                    VStack(spacing: 9) {
                        SectionLabel(text: row.0)
                        cardRow(row.1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    if offset < rows.count - 1 {
                        Rectangle().fill(GT.hairlineFelt).frame(height: 1)
                            .padding(.horizontal, 10)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        case let .rangeGrid(range, highlight):
            VStack(alignment: .leading, spacing: 14) {
            LessonChartPrimer()
            RangeGridView(range: range, highlight: highlight)
                .frame(maxWidth: 330)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case let .actionList(lines, lit):
            // Centred rather than pinned to the top: the action history is only a few
            // short lines, and a small box top-left under an empty felt reads as a
            // screen that failed to load.
            VStack(alignment: .leading, spacing: 9) {
                SectionLabel(text: language.text("액션", "Actions"))
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    HStack(spacing: 9) {
                        Circle()
                            .fill(i == lit ? GT.mint : GT.onFelt.opacity(0.35))
                            .frame(width: i == lit ? 7 : 4, height: i == lit ? 7 : 4)
                        Text(line)
                            .font(i == lit ? GT.title(19) : GT.semibold(17))
                            .foregroundStyle(i == lit ? GT.onFelt : GT.onFeltSecondary)
                    }
                }
            }
            .gtInset(GT.Space.card, firstText: .semibold(13))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: GT.Radius.panel))
        case let .buckets(bars):
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    BucketBarView(label: bar.label, distribution: bar.distribution)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        case let .defendChart(opener, highlight):
            VStack(alignment: .leading, spacing: 14) {
            LessonChartPrimer()
            DefendGridView(opener: opener, highlight: highlight)
                .frame(maxWidth: 330)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case let .grid(cards):
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 9)],
                      alignment: .leading, spacing: 8) {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    cardView(card, size: PlayingCardView.canonicalSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cardRow(_ cards: [Card]) -> some View {
        HStack(spacing: 7) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                cardView(card, size: PlayingCardView.canonicalSize)
            }
        }
    }

    /// Three states, and none of them removes the card from the layout.
    private func cardView(_ card: Card, size: CGFloat) -> some View {
        let lit = beat.highlight.contains(card)
        let dead = beat.struck.contains(card)
        // Only dim when something is actually singled out, or a beat with no
        // highlight would grey the whole board for no reason.
        let dim = !beat.highlight.isEmpty && !lit
        return PlayingCardView(card: card, size: size)
            .overlay {
                if dead {
                    // Strike + a red bar, so "removed" survives greyscale.
                    Rectangle().fill(GT.suitRed)
                        .frame(height: 2.5)
                        .rotationEffect(.degrees(-16))
                }
            }
            // A dimmed card must stay *readable* — the beat is a comparison, and you
            // cannot compare against something you cannot read. At 0.26 the face
            // measured ~3.7:1 against its own ink over the dark felt; 0.62 puts it
            // near 7:1 while still sitting clearly behind the highlighted cards,
            // which now carry the emphasis themselves rather than borrowing it from
            // everything else being crushed.
            .opacity(dead ? 0.5 : (dim ? 0.62 : 1))
            .overlay {
                if lit {
                    RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
                        .strokeBorder(GT.mint, lineWidth: 3)
                }
            }
            .animation(reduceMotion ? nil : GT.Motion.change, value: lit)
            .animation(reduceMotion ? nil : GT.Motion.change, value: index)
            .accessibilityLabel(accessibilityText(card, lit: lit, dead: dead))
    }

    private func accessibilityText(_ card: Card, lit: Bool, dead: Bool) -> String {
        if dead { return "\(card.description), \(language.text("제외됨", "excluded"))" }
        if lit { return "\(card.description), \(language.text("강조됨", "highlighted"))" }
        return card.description
    }

    /// Hierarchy follows the payload, not the sentence order. When a beat carries a
    /// `value` the caption demotes to a small label above it and the value becomes the
    /// biggest thing on screen — "지금 내 패" is the label, "10 하이" is the lesson, and
    /// the previous layout had those the wrong way round.
    private var sheetFirstText: GT.TextRole? {
        if beat.value != nil, beat.focus != .none { return .semibold(13) }
        if beat.focus == .none {
            if beat.value != nil { return .semibold(15) }
            return beat.detail != nil ? .body(GT.Typography.explanationSize) : nil
        }
        return .title(GT.Typography.resultSize)
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            if concept == .rfi, simple, index == 2 {
                chenRuleCard
            } else if let value = beat.value, beat.focus != .none {
                Text(beat.caption)
                    .font(GT.semibold(13)).tracking(0.3)
                    .foregroundStyle(GT.inkMuted)
                if isCovered {
                    revealTile
                } else {
                    Text(value).font(GT.title(26)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.numericText())
                }
            } else if beat.focus == .none {
                // The payload is already large on the felt. Repeating it here is the
                // same sentence twice; only its label belongs in the sheet.
                if beat.value != nil {
                    Text(beat.caption).font(GT.semibold(15)).foregroundStyle(GT.inkMuted)
                }
            } else {
                Text(beat.caption).font(GT.title(GT.Typography.resultSize)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if isCovered {
                Text(language.text(concept == .potMath ? "앞의 기여액을 더한 뒤 아래에서 합계를 골라요." : "먼저 스스로 계산해 본 뒤 눌러서 확인해요.",
                                   concept == .potMath ? "Add the contributions, then choose the total below." : "Work it out first, then tap to check."))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if concept != .potMath, !(concept == .rfi && simple && index == 2), let detail = beat.detail {
                Text(detail).font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                if concept == .rfi, index == 2 { chenRuleCard }
            }

        }
    }

    /// How the starting-hand score is built, open until the learner closes it. The last line
    /// works the rules through for the hand on the table.
    private var chenRuleCard: some View {
        DisclosureGroup(ChenScoreCopy.title(in: language), isExpanded: $chenRulesOpen) {
            VStack(alignment: .leading, spacing: 8) {
                Text(ChenScoreCopy.intro(in: language))
                ForEach(Array(ChenScoreCopy.rules(in: language).enumerated()), id: \.offset) { number, rule in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(number + 1).").monospacedDigit()
                        Text(rule).fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
                Text(ChenScoreCopy.handLine(beat.highlight, in: language))
                    .font(GT.semibold(15)).foregroundStyle(GT.ink)
                Text(ChenScoreCopy.closing(in: language))
            }
            .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("chen-rule-card")
        }.foregroundStyle(GT.ink)
    }

    /// Covers the step's value until the learner taps it. The caption above it says
    /// what the value is; the detail that explains it appears with it.
    private var revealTile: some View {
        Button {
            withAnimation(reduceMotion ? nil : GT.Motion.change) { practiceRevealed = true }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "hand.tap.fill").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GT.cta)
                Text(language.text("눌러서 확인하기", "Tap to check"))
                    .font(GT.semibold(GT.Typography.buttonSize)).foregroundStyle(GT.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                .strokeBorder(GT.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(language.text("가려진 결과. 눌러서 확인하기", "Hidden result. Tap to check"))
        .accessibilityIdentifier("walkthrough-reveal")
    }
}

/// Builds the walkthrough for a concept at a given spot index, including the card
/// rows a `.table` beat needs. Keeping this beside the player means a new concept
/// only has to be added in one place on the app side.
enum Walkthrough {
    /// `level` is the step a restored answer was dealt at (D53), so its replay shows
    /// that question's spot; teaching and worked examples use the first step.
    static func make(concept: Concept, seed: UInt64, index: Int, level: DrillLevel = .learn,
                     language: LearningLanguage = .korean)
        -> (beats: [Beat], rows: [(String, [Card])]) {
        let opponent = language.text("상대 카드", "Opponent's cards")
        let shared = language.text("공용 카드", "Shared cards")
        let mine = language.text("내 카드", "My cards")
        let flop = language.text("플랍", "flop")
        let turn = language.text("턴", "turn")
        let river = language.text("리버", "river")
        switch concept {
        case .showdown:
            let s = ShowdownSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.showdown(s, language: language),
                    [(opponent, s.villain), (shared, s.board), (mine, s.hero)])
        case .outs:
            let s = OutsSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.outs(s, language: language),
                    [(opponent, s.villain), ("\(shared) · \(turn)", s.board), (mine, s.hero)])
        case .equitySense:
            let s = EquitySenseSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.equitySense(s, language: language),
                    [(opponent, s.villain),
                     ("\(shared) · \(s.board.count == 3 ? flop : turn)", s.board),
                     (mine, s.hero)])
        case .callFold:
            let s = CallFoldSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.callFold(s, language: language),
                    [(opponent, s.villain), ("\(shared) · \(turn)", s.board), (mine, s.hero)])
        case .combos:
            let s = BlockerSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.combos(s, language: language), [(language.text("보이는 카드", "Visible cards"), s.removed)])
        case .potMath:
            return (BeatScript.potMath(PotMathSpotGenerator.spot(baseSeed: seed, index: index), language: language), [])
        case .position:
            return (BeatScript.position(PositionSpotGenerator.spot(baseSeed: seed, index: index, level: level), language: language), [])
        case .potOdds:
            return (BeatScript.potOdds(BetSpotGenerator.spot(baseSeed: seed, index: index), language: language), [])
        case .mdf:
            return (BeatScript.mdf(BetSpotGenerator.spot(baseSeed: seed, index: index), language: language), [])
        case .evCall:
            return (BeatScript.evCall(EVCallSpotGenerator.spot(baseSeed: seed, index: index), language: language), [])
        case .rangeNotation:
            return (BeatScript.rangeNotation(
                RangeNotationSpotGenerator.spot(baseSeed: seed, index: index), language: language), [])
        case .rfi:
            let s = RFISpotGenerator.spot(baseSeed: seed, index: index, level: level)
            return (BeatScript.rfi(s, language: language), [(mine, s.hand)])
        case .rangeRead:
            // No card rows on purpose: seeing no cards *is* the drill.
            return (BeatScript.rangeRead(
                RangeReadSpotGenerator.spot(baseSeed: seed, index: index, level: level), language: language), [])
        case .hitFrequency:
            let s = HitFrequencySpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.hitFrequency(s, language: language), [("\(shared) · \(flop)", s.board)])
        case .rangeAdvantage:
            let s = RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.rangeAdvantage(s, language: language), [("\(shared) · \(flop)", s.board)])
        case .evLoss:
            let s = EVLossSpotGenerator.spot(baseSeed: seed, index: index)
            return (BeatScript.evLoss(s, language: language), [("\(shared) · \(river)", s.board), (mine, s.hero)])
        case .actionRead:
            let s = ActionReadSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            return (BeatScript.actionRead(s, language: language), [("\(shared) · \(flop)", s.board)])
        case .defend:
            let s = DefendSpotGenerator.spot(baseSeed: seed, index: index, level: level)
            return (BeatScript.defend(s, language: language), [(mine, s.hand)])
        }
    }
}
