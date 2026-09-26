// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableEngine
import GlassTableDrills

/// What one answered spot reports upward.
struct DrillOutcome {
    let band: GradeBand
    /// Present only for estimation concepts (spec §5.4).
    let interval: IntervalAnswer?
    /// Big blinds given up. Present only where the grade *is* a cost (R4-S2), so the
    /// rolling 기록 average never counts an ungraded concept as a perfect 0bb.
    var evLoss: Double? = nil
    var submittedInput: DrillSubmittedInput? = nil
}

/// A language-independent answer. The seed and index regenerate the question;
/// the answer regenerates the reveal in whichever language is currently selected.
typealias DrillSubmittedInput = SavedDrillInput

/// Renders one spot for any concept and reports the graded result.
///
/// Deliberately thin: every concept's spot generation and grading already lives in
/// `GlassTableDrills` and is tested there. This file only chooses a layout.
struct ConceptDrillView: View {
    @State private var answerCommitted = false
    let concept: Concept
    let seed: UInt64
    let index: Int
    let progressText: String
    let restoredAnswer: RoundAnswer?
    let initialDraft: SavedDrillDraftInput?
    let onDraft: (SavedDrillDraftInput) -> Void
    let onQuestionReady: () -> Void
    let onCommit: (DrillOutcome) -> Bool
    let onAnswer: (DrillOutcome) -> Void
    let help: DrillHelp?

    private var questionID: String { "\(concept.rawValue)/\(seed)/\(index)" }

    init(concept: Concept, seed: UInt64, index: Int, progressText: String,
         restoredAnswer: RoundAnswer? = nil,
         initialDraft: SavedDrillDraftInput? = nil,
         help: DrillHelp? = nil,
         onDraft: @escaping (SavedDrillDraftInput) -> Void = { _ in },
         onQuestionReady: @escaping () -> Void = {},
         onCommit: @escaping (DrillOutcome) -> Bool = { _ in true },
         onAnswer: @escaping (DrillOutcome) -> Void) {
        self.concept = concept
        self.seed = seed
        self.index = index
        self.progressText = progressText
        self.restoredAnswer = restoredAnswer
        self.initialDraft = initialDraft
        self.onDraft = onDraft
        self.onQuestionReady = onQuestionReady
        self.onCommit = onCommit
        self.onAnswer = onAnswer
        self.help = help
    }

    var body: some View {
        Group {
            if let restoredAnswer {
                RestoredDrillView(concept: concept, seed: seed, index: index,
                                  progressText: progressText, answer: restoredAnswer,
                                  onNext: onAnswer)
            } else {
                // The reveal sheets read these once; the drill views stay focused
                // on spot generation and input.
                drill
                    .environment(\.glossaryTerm, Self.glossaryTerm(for: concept))
                    .environment(\.drillCommit, commit)
                    .environment(\.drillInitialDraft, initialDraft)
                    .environment(\.drillSaveDraft, scheduleDraft)
                    .environment(\.drillQuestionReady, onQuestionReady)
                    .environment(\.drillQuestionID, questionID)
                    .environment(\.drillHelp, help)
                    .environment(\.drillExplain, help == nil ? nil : concept)
                    .environment(\.drillReplayContext,
                                  DrillReplayContext(concept: concept, seed: seed, index: index))
            }
        }
        .onChange(of: questionID) { _, _ in
            answerCommitted = false
        }
    }

    private func scheduleDraft(_ input: SavedDrillDraftInput) {
        guard !answerCommitted else { return }
        onDraft(input)
    }

    private func commit(_ outcome: DrillOutcome) -> Bool {
        let saved = onCommit(outcome)
        if saved { answerCommitted = true }
        return saved
    }

    /// Stable glossary IDs, independent of the current display language.
    private static func glossaryTerm(for concept: Concept) -> String? {
        switch concept {
        case .showdown, .position: return nil   // no matching glossary entry
        case .potMath:             return "chip"
        case .evLoss:              return "big-blind"
        case .equitySense, .evCall, .rangeAdvantage: return "equity"
        case .combos, .rangeNotation: return "combo"
        case .outs:     return "outs"
        case .potOdds:  return "pot-odds"
        case .mdf:      return "mdf"
        case .callFold: return "required-equity"
        case .rfi, .rangeRead, .hitFrequency, .actionRead: return "range"
        case .defend:   return "three-bet"
        }
    }

    @ViewBuilder
    private var drill: some View {
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
        case .evLoss:
            EVLossDrill(seed: seed, index: index,
                        progressText: progressText, onAnswer: onAnswer)
        case .actionRead:
            ActionReadDrill(seed: seed, index: index,
                            progressText: progressText, onAnswer: onAnswer)
        case .defend:
            DefendDrill(seed: seed, index: index,
                        progressText: progressText, onAnswer: onAnswer)
        }
    }
}

// MARK: - shared chrome

/// Set once by `ConceptDrillView`, read by the reveal sheets. An environment value
/// rather than a parameter so the eighteen drill structs stay untouched.
private struct GlossaryTermKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

private struct DrillCommitKey: EnvironmentKey {
    static let defaultValue: (DrillOutcome) -> Bool = { _ in true }
}

private struct DrillReplayContext {
    let concept: Concept
    let seed: UInt64
    let index: Int
}

private struct DrillReplayContextKey: EnvironmentKey {
    static let defaultValue: DrillReplayContext? = nil
}

private struct DrillInitialDraftKey: EnvironmentKey {
    static let defaultValue: SavedDrillDraftInput? = nil
}

private struct DrillSaveDraftKey: EnvironmentKey {
    static let defaultValue: (SavedDrillDraftInput) -> Void = { _ in }
}

private struct DrillQuestionReadyKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

/// Help that shows the current question's calculation. Only graded questions pass it;
/// guided steps and replays leave it nil, so the control does not appear there.
/// `mark` records the help and returns false when it can't be saved, in which case
/// the help stays hidden.
struct DrillHelp {
    let isUsed: Bool
    let mark: () -> Bool
}

private struct DrillHelpKey: EnvironmentKey {
    static let defaultValue: DrillHelp? = nil
}

/// The skill a graded question can explain again. Guided steps leave it nil; they
/// have their own hint.
private struct DrillExplainKey: EnvironmentKey {
    static let defaultValue: Concept? = nil
}

private struct DrillQuestionIDKey: EnvironmentKey {
    static let defaultValue = "unknown"
}

extension EnvironmentValues {
    fileprivate var glossaryTerm: String? {
        get { self[GlossaryTermKey.self] }
        set { self[GlossaryTermKey.self] = newValue }
    }

    fileprivate var drillCommit: (DrillOutcome) -> Bool {
        get { self[DrillCommitKey.self] }
        set { self[DrillCommitKey.self] = newValue }
    }

    fileprivate var drillReplayContext: DrillReplayContext? {
        get { self[DrillReplayContextKey.self] }
        set { self[DrillReplayContextKey.self] = newValue }
    }

    fileprivate var drillInitialDraft: SavedDrillDraftInput? {
        get { self[DrillInitialDraftKey.self] }
        set { self[DrillInitialDraftKey.self] = newValue }
    }

    fileprivate var drillSaveDraft: (SavedDrillDraftInput) -> Void {
        get { self[DrillSaveDraftKey.self] }
        set { self[DrillSaveDraftKey.self] = newValue }
    }

    fileprivate var drillQuestionReady: () -> Void {
        get { self[DrillQuestionReadyKey.self] }
        set { self[DrillQuestionReadyKey.self] = newValue }
    }

    fileprivate var drillHelp: DrillHelp? {
        get { self[DrillHelpKey.self] }
        set { self[DrillHelpKey.self] = newValue }
    }

    fileprivate var drillExplain: Concept? {
        get { self[DrillExplainKey.self] }
        set { self[DrillExplainKey.self] = newValue }
    }

    fileprivate var drillQuestionID: String {
        get { self[DrillQuestionIDKey.self] }
        set { self[DrillQuestionIDKey.self] = newValue }
    }
}

/// The reveal moment gets one notification tap: ✓/±/✕ as success/warning/error.
/// No app toggle — the system Reduce Haptics setting is the opt-out.
private func gradeHaptic(_ band: GradeBand) {
    let type: UINotificationFeedbackGenerator.FeedbackType =
        switch band { case .spotOn: .success; case .close: .warning; case .off: .error }
    UINotificationFeedbackGenerator().notificationOccurred(type)
}

/// A graded reveal reports its band so the sheet around it can take the verdict's tint.
private struct GradedBandKey: PreferenceKey {
    static let defaultValue: GradeBand? = nil
    static func reduce(value: inout GradeBand?, nextValue: () -> GradeBand?) {
        value = value ?? nextValue()
    }
}

/// Every drill shares the same skeleton: felt content zone, cream answer sheet.
private struct DrillShell<Content: View, Sheet: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.drillExplain) private var explainConcept
    @State private var gradedBand: GradeBand?
    @State private var explaining = false
    let title: String
    let progressText: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var sheet: () -> Sheet

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: GT.Space.section) {
                        header
                        content().frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: GT.Space.related) { sheet() }
                            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .gtCard(radius: GT.Radius.panel, band: gradedBand)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(sheetIdentifier)
                    }
                    .padding(.horizontal, 18).padding(.bottom, 28)
                }
            } else {
                VStack(spacing: 0) {
                    header.padding(.horizontal, 18)
                    GeometryReader { geo in
                        ScrollView {
                            content()
                                .padding(.horizontal, 18)
                                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    ActionSheet(band: gradedBand) { sheet() }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(sheetIdentifier)
                        .layoutPriority(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onPreferenceChange(GradedBandKey.self) { gradedBand = $0 }
        .sheet(isPresented: $explaining) {
            if let explainConcept {
                ConceptExplainView(concept: explainConcept) { explaining = false }
            }
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_EXPLAIN"] != nil,
               explainConcept != nil { explaining = true }
            #endif
        }
    }

    private var sheetIdentifier: String {
        gradedBand.map { "graded-sheet-\($0)" } ?? "answer-sheet"
    }

    /// The title stays on one line beside the explain button and counter when it fits.
    /// Otherwise it takes a full row, so a large text size wraps it between words.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 8) {
                titleText.fixedSize()
                headerControls
            }
            VStack(alignment: .leading, spacing: 4) {
                titleText.fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .center, spacing: 8) { headerControls }
            }
        }
        .padding(.top, 6).padding(.bottom, 12)
    }

    private var titleText: some View {
        Text(localizedTitle).font(GT.title(19)).foregroundStyle(GT.onFelt)
    }

    @ViewBuilder private var headerControls: some View {
        if explainConcept != nil {
            Button { explaining = true } label: {
                Image(systemName: "info.circle")
                    .font(GT.title(18))
                    .foregroundStyle(GT.onFeltSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
            .accessibilityLabel(language.text("개념 설명", "Explain this skill"))
            .accessibilityIdentifier("drill-explain")
        }
        Spacer(minLength: 12)
        Text(progressText).font(GT.semibold(14).monospacedDigit())
            .foregroundStyle(GT.onFeltSecondary)
            .fixedSize()
            .accessibilityIdentifier("drill-question-\(questionID)")
    }

    private var localizedTitle: String {
        guard language == .english else { return title }
        switch title {
        case "쇼다운": return "Showdown"
        case "팟 계산": return "Count the pot"
        case "포지션": return "Position"
        case "에퀴티 감각": return "Chance to win"
        case "EV 계산": return "Value of a call"
        case "콜/폴드": return "Call or fold"
        case "레인지 표기법": return "Hand ranges"
        case "RFI 차트": return "First raise"
        case "레인지 리드": return "Read a range"
        case "히트 프리퀀시": return "Made hands"
        case "레인지 어드밴티지": return "Range advantage"
        case "EV 손실": return "Value lost"
        case "액션 리드": return "Read an action"
        case "디펜드 차트": return "Defend chart"
        case "아웃": return "Outs"
        case "콤보": return "Combos"
        case "팟 오즈": return "Pot odds"
        case "MDF": return "Minimum defense"
        default: return title
        }
    }
}

/// Reveal panel shared by every drill: verdict, the "why", then advance.
private struct RevealSheet: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillReplayContext) private var replayContext
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.glossaryTerm) private var term
    @Environment(\.drillCommit) private var onCommit
    @Environment(ProgressionModel.self) private var model
    @State private var saved = false
    let band: GradeBand
    let mine: String
    let correct: String
    let why: String
    var interval: IntervalAnswer? = nil
    var evLoss: Double? = nil
    let submittedInput: DrillSubmittedInput
    let onNext: () -> Void

    private var localized: RestoredDrillDescription? {
        guard let replayContext else { return nil }
        let stored = DrillStoredReveal(DrillOutcome(band: band, interval: interval,
                                                    evLoss: evLoss, submittedInput: submittedInput))
        return RestoredDrillDescription.make(concept: replayContext.concept,
            seed: replayContext.seed, index: replayContext.index, input: submittedInput,
            stored: stored, language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VerdictRow(band: band, mine: localized?.mine ?? mine,
                       correct: localized?.correct ?? correct)
            Text(localized?.why ?? why)
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                             style: .continuous))
                .fixedSize(horizontal: false, vertical: true)
            if let term { GlossaryChip(term: term) }
            PrimaryCTAButton(title: language.text("다음 문제", "Next question"), action: onNext)
                .disabled(!saved)
                .accessibilityIdentifier("drill-completion-\(questionID)")
            if !saved {
                SecondaryCTAButton(title: language.text("저장 다시 시도", "Retry saving")) {
                    model.retrySave()
                    if model.saveError == nil {
                        saved = onCommit(DrillOutcome(band: band, interval: interval,
                                                       evLoss: evLoss,
                                                       submittedInput: submittedInput))
                    }
                }
                .frame(minHeight: 44)
                .accessibilityIdentifier("retry-answer-save")
            }
        }
        .preference(key: GradedBandKey.self, value: band)
        .onAppear {
            saved = onCommit(DrillOutcome(band: band, interval: interval, evLoss: evLoss,
                                          submittedInput: submittedInput))
            if saved { gradeHaptic(band) }
        }
    }
}

/// Point estimate plus the 90% interval, for the three estimation concepts.
/// The interval is what makes the calibration screen possible (spec §5.4).
private struct IntervalInput: View {
    @Environment(\.learningLanguage) private var language
    @Binding var point: Double
    @Binding var halfWidth: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(language.text("추정", "Estimate"))
                    .font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                Spacer()
                Text("\(fmt(point))\(unit)")
                    .font(GT.title(20).monospacedDigit()).foregroundStyle(GT.ink)
            }
            HStack(spacing: 10) {
                Slider(value: $point, in: range, step: step).tint(GT.cta)
                AdjustmentButtons(label: language.text("추정값", "Estimate"),
                                  decrement: { point = max(range.lowerBound, point - step) },
                                  increment: { point = min(range.upperBound, point + step) })
            }
            HStack {
                Text(language.text("90% 구간", "90% range"))
                    .font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                Spacer()
                Text("\(fmt(max(range.lowerBound, point - halfWidth)))–\(fmt(min(range.upperBound, point + halfWidth)))\(unit)")
                    .font(GT.semibold(14).monospacedDigit()).foregroundStyle(GT.inkSecondary)
            }
            HStack(spacing: 10) {
                Slider(value: $halfWidth,
                       in: step...(range.upperBound - range.lowerBound) / 2,
                       step: step).tint(GT.inkMuted)
                AdjustmentButtons(label: language.text("구간 너비", "Range width"),
                                  decrement: { halfWidth = max(step, halfWidth - step) },
                                  increment: {
                                      halfWidth = min((range.upperBound - range.lowerBound) / 2,
                                                      halfWidth + step)
                                  })
            }
            Text(language.text("정답이 들어갈 범위를 잡아요. 10번 중 약 9번 포함된다고 생각하는 구간이에요.",
                               "Pick a range you expect to contain the answer 9 times in 10."))
                .font(GT.body(10.5)).foregroundStyle(GT.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func fmt(_ x: Double) -> String {
        abs(x - x.rounded()) < 0.05 ? "\(Int(x.rounded()))" : String(format: "%.1f", x)
    }
}

private struct IntervalDraftModifier: ViewModifier {
    @Environment(\.drillInitialDraft) private var initialDraft
    @Environment(\.drillSaveDraft) private var saveDraft
    @State private var restored = false
    @Binding var point: Double
    @Binding var halfWidth: Double

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !restored else { return }
                restored = true
                if case let .interval(savedPoint, savedWidth)? = initialDraft {
                    point = savedPoint; halfWidth = savedWidth
                }
            }
            .onChange(of: point) { _, newValue in
                if restored { saveDraft(.interval(point: newValue, halfWidth: halfWidth)) }
            }
            .onChange(of: halfWidth) { _, newValue in
                if restored { saveDraft(.interval(point: point, halfWidth: newValue)) }
            }
    }
}

private struct IntegerDraftModifier: ViewModifier {
    @Environment(\.drillInitialDraft) private var initialDraft
    @Environment(\.drillSaveDraft) private var saveDraft
    @State private var restored = false
    @Binding var value: Int

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !restored else { return }
                restored = true
                if case let .integer(saved)? = initialDraft { value = saved }
            }
            .onChange(of: value) { _, newValue in
                if restored { saveDraft(.integer(newValue)) }
            }
    }
}

// MARK: - 쇼다운

private struct ShowdownDrill: View {
    @Environment(\.learningLanguage) private var language
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
        default: return []
        }
    }

    var body: some View {
        DrillShell(title: "쇼다운", progressText: progressText) {
            ThreeRegionCardTable(
                opponent: spot.villain, board: spot.board, hero: spot.hero,
                opponentTitle: reveal?.winner == 1 ? language.text("상대 카드 · 승", "Opponent · won")
                                                    : language.text("상대 카드", "Opponent's cards"),
                heroTitle: reveal?.winner == 0 ? language.text("내 카드 · 승", "Your cards · won")
                                            : language.text("내 카드", "Your cards"),
                highlight: winningFive)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: ["내가 이김", "상대가 이김", "무승부"][reveal.answer],
                            correct: ["내가 이김", "상대가 이김", "무승부"][reveal.winner],
                            why: reveal.whyText,
                            submittedInput: .integer(reveal.answer)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(language.text("누가 이겼나요?", "Who won this hand?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    ForEach(Array(["내가 이김", "상대가 이김", "무승부"].enumerated()), id: \.offset) { i, label in
                        GTChoiceButton(title: language == .korean ? label
                            : ["I win", "Opponent wins", "Tie"][i]) {
                            reveal = gradeShowdown(answer: i, spot: spot, language: language)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 팟 계산

private struct PotMathDrill: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.drillInitialDraft) private var initialDraft
    @Environment(\.drillSaveDraft) private var saveDraft
    @Environment(\.drillHelp) private var help
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    private let spot: PotMathSpot
    private let introKey: String
    @State private var showingIntro: Bool
    @State private var showingHelp = false
    @State private var confirmingTotals = false
    @State private var stepIndex: Int
    @State private var reveal: PotMathReveal?

    init(seed: UInt64, index: Int, progressText: String,
         onAnswer: @escaping (DrillOutcome) -> Void) {
        self.seed = seed
        self.index = index
        self.progressText = progressText
        self.onAnswer = onAnswer

        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        #else
        let environment: [String: String] = [:]
        #endif
        let spot = Self.makeSpot(seed: seed, index: index, environment: environment)
        self.spot = spot
        // Every question starts at the blind posts: the seats carry no totals, so
        // opening at the last action would hide the hand the learner has to count.
        #if DEBUG
        let opensAtLastAction = environment["GT_DEMO_POT_STATE"] == "question"
            || environment["GT_DEMO_POT_STATE"] == "reveal"
        #else
        let opensAtLastAction = false
        #endif
        _stepIndex = State(initialValue: opensAtLastAction ? max(0, spot.replaySteps.count - 1) : 0)

        #if DEBUG
        let storeSuffix = environment["GT_TEST_STORE_ID"] ?? "shared"
        #else
        let storeSuffix = "shared"
        #endif
        let introKey = "potMath.introSeen.v1.\(storeSuffix)"
        self.introKey = introKey
        #if DEBUG
        let forcedIntro = environment["GT_DEMO_POT_STATE"] == "intro"
        let bypassIntro = environment["GT_DEMO_POT_STATE"] == "question"
            || environment["GT_DEMO_POT_STATE"] == "reveal"
        #else
        let forcedIntro = false
        let bypassIntro = false
        #endif
        _showingIntro = State(initialValue: forcedIntro
                              || (!bypassIntro && !UserDefaults.standard.bool(forKey: introKey)))
    }

    private var question: String {
        switch spot.question {
        case .potNow: return language.text("지금 팟은 몇 칩인가요?", "How many chips are in the pot now?")
        case let .fractionOfPot(f):
            return language.text("현재 팟의 \(Int((f * 100).rounded()))%는 몇 칩인가요?",
                                 "How many chips is \(Int((f * 100).rounded()))% of the pot now?")
        }
    }

    var body: some View {
        Group {
            if showingIntro {
                PotMathIntroView(onStart: finishIntro)
            } else {
                // Choices and the verdict sit in the bottom sheet like every other drill;
                // the replay above them scrolls when it needs the room.
                DrillShell(title: "팟 계산", progressText: progressText) {
                    VStack(alignment: .leading, spacing: GT.Space.section) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(question)
                                .font(GT.title(GT.Typography.questionSize))
                                .foregroundStyle(GT.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if case .fractionOfPot = spot.question {
                                Text(language.text("가장 가까운 한 칩으로 반올림해요.",
                                                   "Round to the nearest chip."))
                                    .font(GT.body(14))
                                    .foregroundStyle(GT.inkSecondary)
                            }
                        }

                        PotMathReplayView(spot: spot, stepIndex: $stepIndex,
                                          revealedPot: reveal == nil ? nil : spot.pot,
                                          showsPaidTotals: help?.isUsed == true,
                                          showTotals: help == nil || reveal != nil ? nil : {
                                              confirmingTotals = true
                                          }) {
                            showingHelp = true
                        }
                    }
                    .padding(.bottom, 12)
                } sheet: {
                    if let reveal {
                        PotMathRevealSheet(reveal: reveal) {
                            onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                            self.reveal = nil
                        }
                    } else {
                        PotMathChoicesView(spot: spot, stepIndex: stepIndex) { choice in
                            reveal = gradePotMath(answer: choice, spot: spot, language: language)
                        }
                    }
                }
            }
        }
        .alert(language.text("합계를 볼까요?", "Show the totals?"), isPresented: $confirmingTotals) {
            Button(language.text("합계 보기", "Show totals")) { _ = help?.mark() }
            Button(language.text("직접 세기", "Keep counting"), role: .cancel) {}
        } message: {
            Text(language.text("이 문제는 도움 받은 연습으로 기록돼요.",
                               "This counts as practice with help."))
        }
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                PotMathIntroView { showingHelp = false }
                    .navigationTitle(language.text("계산 방법", "How to count"))
                    .navigationBarTitleDisplayMode(.inline)
                    .gtChrome(.topBarTrailing) { ChromeButton.close { showingHelp = false } }
            }
        }
        .onChange(of: index) { _, _ in
            stepIndex = 0
            reveal = nil
            restoreReplayDraft()
        }
        .onChange(of: stepIndex) { _, next in
            saveDraft(.potReplay(stepIndex: next))
        }
        .onAppear {
            restoreReplayDraft()
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_POT_STATE"] == "reveal",
               reveal == nil {
                reveal = gradePotMath(answer: spot.correctAnswer, spot: spot, language: language)
            }
            switch ProcessInfo.processInfo.environment["GT_DEMO_POT_TOTALS"] {
            case "confirm": confirmingTotals = true
            case "shown": _ = help?.mark()
            default: break
            }
            #endif
        }
    }

    private func restoreReplayDraft() {
        if case let .potReplay(saved)? = initialDraft {
            stepIndex = min(max(0, saved), spot.replaySteps.count - 1)
            showingIntro = false
        }
    }

    private func finishIntro() {
        UserDefaults.standard.set(true, forKey: introKey)
        stepIndex = 0
        showingIntro = false
    }

    private static func makeSpot(seed: UInt64, index: Int,
                                 environment: [String: String]) -> PotMathSpot {
        let generated = PotMathSpotGenerator.spot(baseSeed: seed, index: index)
        #if DEBUG
        guard let rawCount = environment["GT_DEMO_POT_PLAYERS"],
              let count = Int(rawCount), (3...4).contains(count),
              generated.participantCount != count else { return generated }
        for candidate in (index + 1)...(index + 64) {
            let spot = PotMathSpotGenerator.spot(baseSeed: seed, index: candidate)
            if spot.participantCount == count { return spot }
        }
        #endif
        return generated
    }
}

private struct PotMathChoicesView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    let spot: PotMathSpot
    let stepIndex: Int
    let onChoose: (Int) -> Void

    private var reachedLastAction: Bool { stepIndex >= spot.replaySteps.count - 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !reachedLastAction {
                Text(language.text("마지막 행동까지 넘기면 답을 고를 수 있어요.",
                                   "Follow the actions to the end, then choose an answer."))
                    .font(GT.body(14))
                    .foregroundStyle(GT.inkSecondary)
            }
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) { choices }
            } else {
                HStack(spacing: 8) { choices }
            }
        }
    }

    @ViewBuilder
    private var choices: some View {
        ForEach(spot.answerChoices, id: \.self) { choice in
            GTChoiceButton(title: language.text("\(choice)칩", "\(choice) chips"), minHeight: 52) {
                onChoose(choice)
            }
            .accessibilityIdentifier("pot-answer-\(choice)")
            .disabled(!reachedLastAction)
        }
    }
}

private struct PotMathRevealSheet: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillReplayContext) private var replayContext
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.glossaryTerm) private var term
    @Environment(\.drillCommit) private var onCommit
    @Environment(\.drillHelp) private var help
    @Environment(ProgressionModel.self) private var model
    @State private var saved = false
    let reveal: PotMathReveal
    private var submittedInput: DrillSubmittedInput { .integer(reveal.answer) }
    let onNext: () -> Void
    @State private var calculationExpanded = false

    private var localizedWhy: String {
        guard let replayContext else { return reveal.whyText }
        return RestoredDrillDescription.make(concept: replayContext.concept,
            seed: replayContext.seed, index: replayContext.index, input: submittedInput,
            stored: nil, language: language)?.why ?? reveal.whyText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if help?.isUsed == true { SolvedWithHelpLabel() }
            Text(reveal.band == .spotOn ? language.text("맞았어요", "That's right")
                 : language.text("정답은 \(reveal.correct)칩이에요", "The answer is \(reveal.correct) chips"))
                .font(GT.title(GT.Typography.resultSize))
                .foregroundStyle(reveal.band == .spotOn ? GTBand.spotOnInk : GTBand.offInk)
            if reveal.band != .spotOn {
                Text(language.text("각 자리가 실제로 더 낸 칩만 한 번씩 세어요.",
                                   "Count only the chips each seat actually added, once."))
                    .font(GT.body(GT.Typography.explanationSize))
                    .foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            DisclosureGroup(language.text("계산 보기", "See the calculation"),
                            isExpanded: $calculationExpanded) {
                Text(localizedWhy)
                    .font(GT.body(15).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(GT.semibold(15))
            .foregroundStyle(GT.ink)
            .padding(14)
            .background(GT.surface,
                        in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                             style: .continuous))
            if let term { GlossaryChip(term: term) }
            PrimaryCTAButton(title: language.text("다음 문제", "Next question"), action: onNext)
                .disabled(!saved)
                .accessibilityIdentifier("drill-completion-\(questionID)")
            if !saved {
                SecondaryCTAButton(title: language.text("저장 다시 시도", "Retry saving")) {
                    model.retrySave()
                    if model.saveError == nil {
                        saved = onCommit(DrillOutcome(band: reveal.band, interval: nil,
                                                       submittedInput: submittedInput))
                    }
                }.frame(minHeight: 44)
            }
        }
        .preference(key: GradedBandKey.self, value: reveal.band)
        .onAppear {
            saved = onCommit(DrillOutcome(band: reveal.band, interval: nil,
                                          submittedInput: submittedInput))
            if saved { gradeHaptic(reveal.band) }
        }
    }
}

// MARK: - 포지션

private struct PositionDrill: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: PositionReveal?

    private var spot: PositionSpot { PositionSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "포지션", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: language.text("8맥스 테이블 · 행동 순서", "8-player table · action order"))
                seatStrip
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: answerLabel(reveal.answer),
                            correct: answerLabel(reveal.correct), why: reveal.whyText,
                            submittedInput: .integer(reveal.answer)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(questionText).font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
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
                    .font(GT.semibold(10)).foregroundStyle(p == mine ? GT.onCTA : GT.onFelt)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(p == mine ? GT.cta : GT.onFelt.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 8))
            }
        }
        // The strip is a diagram of the eight seats in order, so it has to stay one
        // row: reading it depends on seeing every seat at once. The labels still grow,
        // but stop short of the accessibility sizes, where "UTG+1" was breaking into
        // three stacked lines. VoiceOver reads the seat regardless.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var questionText: String {
        switch spot.question {
        case let .behind(p, preflop):
            return language.text(
                "\(p.rawValue) 자리예요. \(preflop ? "프리플랍" : "플랍 이후")에 내 뒤에 몇 명이 남았나요?",
                "You are in \(p.rawValue). How many players act after you \(preflop ? "before the flop" : "after the flop")?")
        case let .whichIsLater(a, b):
            return language.text("\(a.rawValue)와 \(b.rawValue) 중 어느 쪽이 더 늦게 행동하나요?",
                                 "Which seat acts later: \(a.rawValue) or \(b.rawValue)?")
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
                        reveal = gradePosition(answer: n, spot: spot, language: language)
                    }
                }
            }
        case let .whichIsLater(a, b):
            HStack(spacing: 10) {
                ForEach(Array([a, b].enumerated()), id: \.offset) { i, p in
                    GTChoiceButton(title: p.rawValue, minHeight: 54) {
                        reveal = gradePosition(answer: i, spot: spot, language: language)
                    }
                }
            }
        }
    }

    private func answerLabel(_ n: Int) -> String {
        switch spot.question {
        case .behind: return language.text("\(n)명", "\(n) players")
        case let .whichIsLater(a, b): return (n == 0 ? a : b).rawValue
        }
    }
}

// MARK: - 에퀴티 감각

private struct EquitySenseDrill: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 50.0
    @State private var halfWidth = 10.0
    @State private var reveal: EstimateReveal?

    private var spot: EquitySenseSpot { EquitySenseSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "에퀴티 감각", progressText: progressText) {
            if dynamicTypeSize.isAccessibilitySize {
                ThreeRegionCardTable(opponent: spot.villain, board: spot.board, hero: spot.hero)
            } else {
                VStack(spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        compactRegion(language.text("내 카드", "My cards"),
                                      cards: spot.hero, identifier: "equity-hero-cards")
                        compactRegion(language.text("상대 카드", "Opponent's cards"),
                                      cards: spot.villain, identifier: "equity-opponent-cards")
                    }
                    Rectangle().fill(GT.hairlineFelt).frame(height: 1)
                        .accessibilityHidden(true)
                    compactRegion(language.text("공용 카드", "Shared cards"),
                                  cards: spot.board, identifier: "equity-board-cards")
                }
                .frame(maxWidth: .infinity)
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(Int(reveal.estimate.point))%",
                            correct: "\(pctText(reveal.correct))%",
                            why: reveal.whyText + (reveal.intervalHit
                                 ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요."),
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 50; halfWidth = 10
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("쇼다운까지 갔을 때 내가 이길 확률은?",
                                       "How often do you win at showdown?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: 1, unit: "%")
                    PrimaryCTAButton(title: language.text("확인", "Check answer")) {
                        reveal = gradeEquitySense(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot, language: language)
                    }
                }
            }
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }

    private func compactRegion(_ title: String, cards: [Card], identifier: String) -> some View {
        VStack(spacing: 9) {
            SectionLabel(text: title)
            CardRow(cards: cards)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - EV 계산

private struct EVCallDrill: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 0.0
    @State private var halfWidth = 1.0
    @State private var reveal: EstimateReveal?

    private var spot: EVCallSpot { EVCallSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "EV 계산", progressText: progressText) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: language.text("상황", "Situation"))
                VStack(alignment: .leading, spacing: 6) {
                    Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb",
                                       "Pot \(spot.pot)bb · Opponent bets \(spot.bet)bb"))
                        .font(GT.title(16)).foregroundStyle(GT.onFelt)
                    Text(language.text("내 에퀴티 \(pctText(spot.equityPct))%",
                                       "Your chance to win \(pctText(spot.equityPct))%"))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                }
                Text(language.text("콜하면 \(spot.pot + spot.bet)bb를 걸고 \(spot.bet)bb를 잃을 수 있어요.",
                                   "Calling can win \(spot.pot + spot.bet)bb or cost \(spot.bet)bb."))
                    .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: "\(pctText(reveal.estimate.point))bb",
                            correct: "\(pctText(reveal.correct))bb",
                            why: reveal.whyText,
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 0; halfWidth = 1
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("이 콜의 EV는 몇 bb인가요?",
                                       "What is this call's EV in bb?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: -20...20, step: 0.5, unit: "bb")
                    PrimaryCTAButton(title: language.text("확인", "Check answer")) {
                        reveal = gradeEVCall(
                            estimate: Estimate(point: point, lo: point - halfWidth,
                                               hi: point + halfWidth),
                            spot: spot, language: language)
                    }
                }
            }
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }
}

// MARK: - the four M1 concepts, rendered natively in the new shell

/// 아웃 and 콤보: both answer with a whole-number count, so they share a screen and
/// differ only in what is shown above it and which grader runs.
private struct CountDrill: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillInitialDraft) private var initialDraft
    @Environment(\.drillSaveDraft) private var saveDraft
    enum Kind { case outs, combos }
    let kind: Kind
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var countEntry = ""
    @State private var result: (band: GradeBand, mine: String, correct: String, why: String)?
    @State private var tappedOut: Card?

    /// Generated per use rather than held in a computed property, and never both at
    /// once: only the kind on screen is built, and the outs generator walks the deck
    /// looking for a spot with a countable number of outs.
    private func makeOutsSpot() -> OutsSpot {
        OutsSpotGenerator.spot(baseSeed: seed, index: index)
    }
    private func makeComboSpot() -> BlockerSpot {
        BlockerSpotGenerator.spot(baseSeed: seed, index: index)
    }

    var body: some View {
        DrillShell(title: kind == .outs ? "아웃" : "콤보", progressText: progressText) {
            if kind == .outs {
                // After the reveal the outs become tappable, so an abstract count turns
                // into a hand you can actually see finish. Counting 9 teaches less than
                // watching one of the nine win.
                let spot = makeOutsSpot()
                if result != nil { outsReveal(spot) } else { outsContent(spot) }
            } else {
                comboContent(makeComboSpot())
            }
        } sheet: {
            if let result {
                RevealSheet(band: result.band, mine: result.mine,
                            correct: result.correct, why: result.why,
                            submittedInput: .integer(Int(countEntry) ?? 0)) {
                    onAnswer(DrillOutcome(band: result.band, interval: nil))
                    self.result = nil; countEntry = ""; tappedOut = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(kind == .outs
                        ? language.text("리버에 나를 이기게 해주는 카드는 몇 장인가요?",
                                        "How many river cards make you win?")
                        : language.text("상대가 들 수 있는 이 핸드 콤보는 몇 개인가요?",
                                        "How many combos can they hold?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    CountEntryView(entry: $countEntry,
                                   suffix: kind == .outs ? language.text("장", " cards")
                                                         : language.text("개", " ways"),
                                   onSubmit: submit)
                }
            }
        }
        .onAppear {
            if case let .integerText(saved)? = initialDraft { countEntry = saved }
        }
        .onChange(of: countEntry) { _, value in saveDraft(.integerText(value)) }
    }

    private func submit() {
        guard let value = countValue else { return }
        switch kind {
        case .outs:
            let spot = makeOutsSpot()
            let r = gradeOuts(estimate: value, spot: spot, language: language)
            result = (r.band, "\(value)장", "\(spot.outCount)장", r.whyText)
        case .combos:
            let spot = makeComboSpot()
            let r = gradeBlocker(estimate: value, spot: spot, language: language)
            result = (r.band, "\(value)개", "\(spot.count)개", r.whyText)
        }
    }

    private var countValue: Int? {
        countEntry.isEmpty ? nil : Int(countEntry)
    }

    private func outsContent(_ spot: OutsSpot) -> some View {
        ThreeRegionCardTable(opponent: spot.villain, board: spot.board, hero: spot.hero)
    }

    /// The restored affordance from the M1 outs reveal: every out is tappable and
    /// shows the finished river hand for both players via `RiverExplainPanel`.
    private func outsReveal(_ spot: OutsSpot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ThreeRegionCardTable(opponent: spot.villain, board: spot.board, hero: spot.hero)

            SectionLabel(text: language.text("리버 아웃 · \(spot.outCount)장 · 눌러서 확인",
                                              "Winning river cards · \(spot.outCount) · Tap a card"))
                .padding(.top, 12)
            outsGrid(spot.outs, dead: false)
            if !spot.excluded.isEmpty {
                SectionLabel(text: language.text("제외 · 상대 핸드 개선",
                                                 "Excluded · also helps the opponent"))
                    .padding(.top, 10)
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
                    withAnimation(GT.Motion.change) {
                        tappedOut = tappedOut == card ? nil : card
                    }
                } label: {
                    PlayingCardView(card: card, dead: dead)
                        .overlay {
                            if tappedOut == card {
                                RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: PlayingCardView.canonicalSize))
                                    .strokeBorder(GT.mint, lineWidth: 3)
                            }
                        }
                }
                .buttonStyle(GTPress())
                .accessibilityHint(language.text("리버 완성 핸드 보기", "See the completed river hand"))
            }
        }
    }

    private func comboContent(_ spot: BlockerSpot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: language.text("상대 핸드 클래스", "Opponent hand type"))
            Text(spot.className).font(GT.title(26)).foregroundStyle(GT.onFelt)
            SectionLabel(text: language.text("보이는 카드", "Visible cards"))
            CardRow(cards: spot.removed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 팟 오즈 and MDF: the same percent estimate against the same `BetSpot`.
private struct PercentDrill: View {
    @Environment(\.learningLanguage) private var language
    let isMDF: Bool
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var value = 30
    @State private var reveal: PercentReveal?

    private var spot: BetSpot { BetSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: isMDF ? "MDF" : "팟 오즈", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: language.text("상황", "Situation"))
                Text(language.text("팟 \(spot.pot)bb", "Pot \(spot.pot)bb"))
                    .font(GT.title(22)).foregroundStyle(GT.onFelt)
                Text(language.text("상대 벳 \(spot.bet)bb", "Opponent bets \(spot.bet)bb"))
                    .font(GT.title(18))
                    .foregroundStyle(GT.onFeltSecondary)
                // The price as a picture: the answer is a share of this bar, so the
                // proportion can be *read* before it is computed — which is the drill.
                // MDF's bar has no 콜 segment; its denominator is only the money
                // already out there.
                PriceBarView.priced(pot: spot.pot, bet: spot.bet, withCall: !isMDF)
                    .padding(.top, 12)
                // Explains the dash, not which share is the answer — that stays the
                // drill's job. MDF's bar needs no caption at all.
                if !isMDF {
                    Text(language.text("콜 \(spot.bet)bb는 아직 내지 않은 돈이라 점선이에요",
                                       "The \(spot.bet)bb call is dashed because you have not paid it yet."))
                        .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(reveal.answerPct)%",
                            correct: "\(pctText(reveal.correctPct))%", why: reveal.whyText,
                            submittedInput: .integer(reveal.answerPct)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; value = 30
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isMDF
                        ? language.text("이 벳에 최소 몇 %를 지켜야 하나요?",
                                        "What minimum share do you defend?")
                        : language.text("콜하려면 최소 몇 %의 에퀴티가 필요한가요?",
                                        "What equity does this call need?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack { Spacer()
                        EstimateStepper(value: value, step: 5, suffix: "%") {
                            value = min(100, max(0, value + $0))
                        }
                        Spacer() }
                    PrimaryCTAButton(title: language.text("확인", "Check answer")) {
                        reveal = isMDF ? gradeMDF(estimatePct: value, spot: spot, language: language)
                                       : gradePotOdds(estimatePct: value, spot: spot, language: language)
                    }
                }
            }
        }
        .modifier(IntegerDraftModifier(value: $value))
    }
}

/// 콜/폴드 — the Block A boss concept: equity vs price, decided.
private struct CallFoldDrill: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: CallFoldReveal?

    /// Bound once per render: the generator runs an exact equity per candidate spot
    /// and rejects the lopsided ones, and `body` reads it five times.
    private func makeSpot() -> CallFoldSpot {
        CallFoldSpotGenerator.spot(baseSeed: seed, index: index)
    }

    var body: some View {
        let spot = makeSpot()
        return DrillShell(title: "콜/폴드", progressText: progressText) {
            VStack(alignment: .leading, spacing: 6) {
                ThreeRegionCardTable(opponent: spot.villain, board: spot.board, hero: spot.hero)
                Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb",
                                   "Pot \(spot.pot)bb · Opponent bets \(spot.bet)bb"))
                    .font(GT.title(15)).foregroundStyle(GT.onFelt).padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: reveal.userCalls ? "콜" : "폴드",
                            correct: reveal.correctIsCall ? "콜" : "폴드",
                            why: reveal.whyText,
                            submittedInput: .boolean(reveal.userCalls)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("콜인가요, 폴드인가요?", "Call or fold?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    HStack(spacing: 10) {
                        // Equal weight on both, so the layout carries no bias toward
                        // calling — the same rule the M1 screen already followed.
                        ForEach([("폴드", false), ("콜", true)], id: \.0) { label, calls in
                            GTChoiceButton(title: language == .korean ? label
                                : (calls ? "Call" : "Fold"), minHeight: 56) {
                                reveal = gradeCallFold(userCalls: calls, spot: spot, language: language)
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
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.drillInitialDraft) private var initialDraft
    @Environment(\.drillSaveDraft) private var saveDraft
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var countEntry = ""
    @State private var reveal: RangeNotationReveal?

    private var spot: RangeNotationSpot {
        RangeNotationSpotGenerator.spot(baseSeed: seed, index: index)
    }

    var body: some View {
        DrillShell(title: "레인지 표기법", progressText: progressText) {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: language.text("레인지", "Possible hands"))
                if reveal != nil {
                    Text(spot.notation)
                        .font(GT.title(30).monospaced()).foregroundStyle(GT.onFelt)
                        .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.8)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                        .fixedSize(horizontal: false,
                                   vertical: dynamicTypeSize.isAccessibilitySize)
                    SectionLabel(text: language.text("표에서 보면", "On the chart"))
                        .padding(.top, 6)
                    RangeGridView(range: spot.range)
                        .frame(maxWidth: 320)
                } else {
                    // Pre-answer the notation IS the whole screen, so it is staged
                    // like one — the hero treatment `.none` beats get — instead of two
                    // small lines adrift on an empty felt. The grid stays post-reveal
                    // on purpose: shown earlier it turns combo arithmetic into cell
                    // counting.
                    Spacer(minLength: 60)
                    Text(spot.notation)
                        .font(GT.title(38).monospaced()).foregroundStyle(GT.onFelt)
                        .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.8)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 4)
                        .fixedSize(horizontal: false,
                                   vertical: dynamicTypeSize.isAccessibilitySize)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                    Text(language.text("페어 6 · 수티드 4 · 오프수트 12",
                                       "Pair 6 · same suit 4 · different suits 12"))
                        .font(GT.semibold(12)).foregroundStyle(GT.onFeltMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(reveal.estimate) 콤보",
                            correct: "\(reveal.count) 콤보", why: reveal.whyText,
                            submittedInput: .integer(reveal.estimate)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; countEntry = ""
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("이 레인지는 몇 콤보인가요?",
                                       "How many combos is this range?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    CountEntryView(entry: $countEntry, suffix: language.text("개", " combinations"),
                                   onSubmit: {
                        guard let value = Int(countEntry) else { return }
                        reveal = gradeRangeNotation(estimate: value, spot: spot, language: language)
                    }, maximumDigits: 4, maximumValue: 1326)
                }
            }
        }
        .onAppear {
            if case let .integerText(saved)? = initialDraft { countEntry = saved }
        }
        .onChange(of: countEntry) { _, value in saveDraft(.integerText(value)) }
    }
}

// MARK: - RFI 차트

private struct RFIDrill: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: RFIReveal?

    private var spot: RFISpot { RFISpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "RFI 차트", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: language.text("내 핸드", "Your hand"))
                CardRow(cards: spot.hand)
                SectionLabel(text: language.text("내 자리", "Your seat"))
                    .padding(.top, 8)
                seatStrip
                if reveal != nil {
                    SectionLabel(text: language.text("\(spot.seat.rawValue) 오픈 레인지",
                                                      "\(spot.seat.rawValue) first-raise hands"))
                        .padding(.top, 10)
                    RangeGridView(range: RFIChart.range(for: spot.seat),
                                  highlight: spot.handClass)
                        .frame(maxWidth: 320)
                    Text(language.text("8핸드 차트는 공개된 9맥스·6맥스 사이를 보간한 값이에요.",
                                       "The 8-player practice chart sits between published 9- and 6-player ranges."))
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
                            why: reveal.whyText,
                            submittedInput: .boolean(reveal.userOpens)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("\(spot.seat.rawValue)에서 이 핸드, 오픈인가요?",
                                       "In \(spot.seat.rawValue), raise first with this hand?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    HStack(spacing: 10) {
                        ForEach([("폴드", false), ("오픈", true)], id: \.0) { label, opens in
                            GTChoiceButton(title: language == .korean ? label
                                : (opens ? "Raise" : "Fold"), minHeight: 56) {
                                reveal = gradeRFI(userOpens: opens, spot: spot, language: language)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var seatStrip: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2),
                      spacing: 6) {
                ForEach(Position.preflopOrder, id: \.self) { seatChip($0, compact: false) }
            }
        } else {
            HStack(spacing: 4) {
                ForEach(Position.preflopOrder, id: \.self) { seatChip($0, compact: true) }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }

    private func seatChip(_ position: Position, compact: Bool) -> some View {
        Text(position.rawValue)
            .font(GT.semibold(compact ? 9.5 : 12))
            .foregroundStyle(position == spot.seat ? GT.onCTA : GT.onFelt.opacity(0.75))
            .lineLimit(1).minimumScaleFactor(compact ? 0.8 : 1)
            .frame(maxWidth: .infinity, minHeight: compact ? 32 : 44)
            .background(position == spot.seat ? GT.cta : GT.onFelt.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 7))
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
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillInitialDraft) private var initialDraft
    @Environment(\.drillSaveDraft) private var saveDraft
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
                SectionLabel(text: reveal == nil
                    ? language.text("내가 보는 범위", "My possible hands")
                    : language.text("정답 · 내 답 비교", "Answer · my estimate"))
                    .padding(.top, 4)
                // The legend goes *above* the grid. Below it, the one thing that makes
                // a two-channel grid readable sat under the answer sheet and was never
                // seen — found by looking at the sweep rather than by reasoning.
                if reveal != nil { legend }
                RangeGridView(range: reveal?.truth ?? estimate.range,
                              outline: reveal?.guess)
                    .frame(maxWidth: 250)
                    .animation(GT.Motion.change, value: width)
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
                    reveal = gradeRangeRead(estimate: RangeEstimate(width: w), spot: spot,
                                            language: language)
                }
                #endif
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            mine: "상위 \(pctText(reveal.guess.percent))%",
                            correct: "상위 \(pctText(reveal.truth.percent))%",
                            why: reveal.whyText,
                            submittedInput: .range(width: width,
                                tendencies: tendencies.map(\.rawValue).sorted())) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; width = 20; tendencies = []
                }
            } else {
                input
            }
        }
        .onAppear { restoreDraft() }
        .onChange(of: index) { _, _ in restoreDraft() }
        .onChange(of: width) { _, _ in saveRangeDraft() }
        .onChange(of: tendencies) { _, _ in saveRangeDraft() }
    }

    private func restoreDraft() {
        if case let .range(savedWidth, raw)? = initialDraft {
            width = savedWidth
            tendencies = Set(raw.compactMap(RangeTendency.init(rawValue:)))
        }
    }

    private func saveRangeDraft() {
        saveDraft(.range(width: width, tendencies: tendencies.map(\.rawValue).sorted()))
    }

    // MARK: what the user is told

    private var opponentLine: some View {
        // Hidden archetype is the harder band, and it must not read as a bug: say
        // outright that the identification is part of the question.
        VStack(alignment: .leading, spacing: 1) {
            Text(spot.archetypeShown ? spot.archetype.beginnerTitle(in: language)
                                    : language.text("모르는 상대", "Unknown opponent"))
                .font(GT.title(19)).foregroundStyle(GT.onFelt)
            Text(spot.archetypeShown ? spot.archetype.beginnerDescription(in: language)
                                     : language.text("어떤 사람인지도 액션으로 판단해야 해요.",
                                                     "Use their actions to judge how they play."))
                .font(GT.body(11.5)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionList: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(spot.actionLines(in: language).enumerated()), id: \.offset) { _, line in
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
            key(filled: true, ringed: true, language.text("맞음", "Both"))
            key(filled: true, ringed: false, language.text("놓침", "Missed"))
            key(filled: false, ringed: true, language.text("넘침", "Extra"))
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
        // The cut is built once and asked about four times. Each `isSaturated(atWidth:)`
        // used to build its own, so dragging the slider re-sorted 169 classes up to
        // eight times a frame.
        let plain = HandRange.shaped(width: width)
        let saturated = Set(RangeTendency.allCases.filter { $0.isSaturated(in: plain) })
        return VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text(language.text("상대는 몇 %로 \(actionVerb)했을까요?",
                                   "What % would they \(actionVerb)?"))
                    .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                Spacer(minLength: 8)
                Text("\(pctText(width))%")
                    .font(GT.title(24).monospacedDigit()).foregroundStyle(GT.ink)
                    .contentTransition(.numericText())
            }
            Slider(value: $width, in: 3...80, step: 1).tint(GT.cta)
                .accessibilityLabel(language.text("범위 넓이", "Range width"))
                .accessibilityValue(language.text("상위 \(pctText(width))퍼센트",
                                                   "Top \(pctText(width)) percent"))
            AdjustmentButtons(label: language.text("범위 넓이", "Range width"),
                              decrement: { width = max(3, width - 1) },
                              increment: { width = min(80, width + 1) })

            SectionLabel(text: language.text("어디에 몰려 있나요 (선택)",
                                             "Which hands are more common? (optional)"), onDark: false)
            chips(saturated)
            if !saturated.isEmpty {
                Text(language.text("\u{2261} 표시는 이 넓이에 이미 전부 들어 있어서 모양이 바뀌지 않는다는 뜻이에요.",
                                   "The ≡ mark means that group is already fully included at this width."))
                    .font(GT.body(10)).foregroundStyle(GT.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PrimaryCTAButton(title: language.text("확인", "Check answer")) {
                reveal = gradeRangeRead(estimate: estimate, spot: spot, language: language)
            }
        }
    }

    private var actionVerb: String {
        if case .opened = spot.action { return language.text("오픈", "raise first") }
        return language.text("콜", "call")
    }

    /// Two rows of two, because four chips across a mini would each be ~78pt and the
    /// longest label is 오프수트 브로드웨이.
    private func chips(_ saturated: Set<RangeTendency>) -> some View {
        let all = RangeTendency.allCases
        return VStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(all[(r * 2)..<(r * 2 + 2)], id: \.self) {
                        chip($0, saturated: saturated.contains($0))
                    }
                }
            }
        }
    }

    /// Chip labels are shortened from the prose names — 오프수트 브로드웨이 does not
    /// fit a half-width chip, and 수티드 already carries the suited half of broadway.
    /// `tendencyWord` stays long, because the reveal sentence has room.
    private func chipLabel(_ t: RangeTendency) -> String {
        t == .offsuitBroadway ? language.text("브로드웨이", "Broadway")
            : DrillTerms.tendency(t, in: language)
    }

    /// `saturated`: a category entirely inside the cut has nothing left to prefer, so
    /// the chip genuinely does nothing at this width. Say so rather than letting it
    /// read as a dead control. Passed in because the whole row shares one cut.
    private func chip(_ t: RangeTendency, saturated: Bool) -> some View {
        let on = tendencies.contains(t)
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
        .accessibilityLabel(DrillTerms.tendency(t, in: language))
        .accessibilityValue(on ? language.text("선택됨", "Selected")
                               : language.text("선택 안 됨", "Not selected"))
        .accessibilityHint(saturated ? language.text("이 넓이에서는 모양이 바뀌지 않아요",
                                                      "The shape does not change at this width") : "")
    }
}

// MARK: - 히트 프리퀀시

/// The first postflop drill: not "what should I do" — that needs S2's EV-loss grading —
/// but "what is even out there", which is the question every postflop decision starts
/// from and the one beginners skip.
private struct HitFrequencyDrill: View {
    @Environment(\.learningLanguage) private var language
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
                SectionLabel(text: language.text("보드 · 플랍", "Shared cards · flop"))
                CardRow(cards: spot.board)
                Text(DrillTerms.board(spot.texture, in: language))
                    .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                SectionLabel(text: language.text("상대 레인지", "Opponent's possible hands"))
                    .padding(.top, 8)
                Text(language.text("\(spot.seat.rawValue) 오픈 · 상위 \(pctText(spot.range.percent))%",
                                   "\(spot.seat.rawValue) raised first · top \(pctText(spot.range.percent))%"))
                    .font(GT.title(17)).foregroundStyle(GT.onFelt)
                if reveal != nil {
                    BucketBarView(label: language.text("\(spot.seat.rawValue) 오픈 레인지",
                                                       "\(spot.seat.rawValue) first-raise hands"),
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
                        spot: spot, language: language)
                }
                #endif
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(Int(reveal.estimate.point))%",
                            correct: "\(pctText(reveal.correct))%",
                            why: reveal.whyText + (reveal.intervalHit
                                 ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요."),
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 35; halfWidth = 12
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("이 레인지의 몇 %가 페어 이상을 만들었을까요?",
                                       "What share made a pair or better?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: 1, unit: "%")
                    PrimaryCTAButton(title: language.text("확인", "Check answer")) {
                        reveal = gradeHitFrequency(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot, language: language)
                    }
                }
            }
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }
}

// MARK: - 레인지 어드밴티지

private struct RangeAdvantageDrill: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillQuestionReady) private var questionReady
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 50.0
    @State private var halfWidth = 10.0
    @State private var reveal: EstimateReveal?
    /// Sampled off the main thread the moment the spot appears, so it is already
    /// waiting by the time the sliders have been set. Computing it *during* the tap
    /// froze the screen for three seconds under a debug build.
    @State private var equity: Double?
    /// The two bucket bars, computed beside the equity rather than in `body`. They
    /// depend only on the spot, so recomputing them per render — two passes over a
    /// whole range's combos, on the main thread — bought nothing.
    @State private var buckets: (opener: RangeOnBoard, caller: RangeOnBoard)?

    private func makeSpot() -> RangeAdvantageSpot {
        RangeAdvantageSpotGenerator.spot(baseSeed: seed, index: index)
    }

    private func submit(_ v: Double) {
        guard let equity else { return }
        reveal = gradeRangeAdvantage(
            estimate: Estimate(point: v, lo: max(0, v - halfWidth),
                               hi: min(100, v + halfWidth)),
            spot: makeSpot(), openerEquityPct: equity, language: language)
    }

    var body: some View {
        let spot = makeSpot()
        return DrillShell(title: "레인지 어드밴티지", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: language.text("보드 · 플랍", "Shared cards · flop"))
                CardRow(cards: spot.board)
                Text(DrillTerms.board(spot.texture, in: language))
                    .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                SectionLabel(text: language.text("액션", "Actions")).padding(.top, 8)
                VStack(alignment: .leading, spacing: 5) {
                    Text(language.text("\(spot.openerSeat.rawValue) 오픈 3bb",
                                       "\(spot.openerSeat.rawValue) raises first to 3bb"))
                    Text(language.text("\(spot.callerSeat.rawValue) 콜 · \(spot.caller.name)",
                                       "\(spot.callerSeat.rawValue) calls · \(spot.caller.beginnerTitle(in: language))"))
                }
                .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                if reveal != nil, let buckets {
                    VStack(alignment: .leading, spacing: 18) {
                        BucketBarView(label: language.text("\(spot.openerSeat.rawValue) 오픈",
                                                           "\(spot.openerSeat.rawValue) first raise"),
                                      distribution: buckets.opener)
                        BucketBarView(label: language.text("\(spot.callerSeat.rawValue) 콜",
                                                           "\(spot.callerSeat.rawValue) call"),
                                      distribution: buckets.caller)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .task(id: index) {
                equity = nil
                buckets = nil
                let s = seed, i = index
                // One detached pass produces both the sampled equity and the bars, off
                // a single generated spot.
                let computed = await Task.detached(priority: .userInitiated) {
                    let sp = RangeAdvantageSpotGenerator.spot(baseSeed: s, index: i)
                    return (sp.openerEquityPct,
                            rangeOnBoard(sp.openerRange, board: sp.board),
                            rangeOnBoard(sp.callerRange, board: sp.board))
                }.value
                guard !Task.isCancelled else { return }
                equity = computed.0
                buckets = (opener: computed.1, caller: computed.2)
                questionReady()
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
                                 ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요."),
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    // Disable submission synchronously before the next spot appears;
                    // its task must supply its own equity, not reuse this answer's.
                    equity = nil
                    buckets = nil
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 50; halfWidth = 10
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("쇼다운까지 가면 오프너의 승률은 몇 %일까요?",
                                       "What's the raiser's showdown win rate?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: 1, unit: "%")
                    if equity == nil {
                        Text(language.text("계산 중…", "Calculating…"))
                            .font(GT.semibold(13)).foregroundStyle(GT.inkMuted)
                            .frame(maxWidth: .infinity, minHeight: 54)
                    } else {
                        PrimaryCTAButton(title: language.text("확인", "Check answer")) { submit(point) }
                    }
                }
            }
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }
}

// MARK: - EV 손실

/// Lead with the better action, then make the EV subtraction inspectable.
///
/// The progression band remains visible as a small severity label, while the selected
/// and best lines carry the teaching claim. A near-best choice never reads as best.
private struct EVLossRevealSheet: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillReplayContext) private var replayContext
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.glossaryTerm) private var term
    @Environment(\.drillCommit) private var onCommit
    @Environment(ProgressionModel.self) private var model
    @State private var saved = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let reveal: EVLossReveal
    let submittedInput: DrillSubmittedInput
    let onNext: () -> Void

    private var chosenCalls: Bool {
        if case let .boolean(value) = submittedInput { return value }
        return false
    }

    private var bestCalls: Bool { reveal.grade.best.ev > 0 }

    private var localizedWhy: String {
        guard let replayContext else { return reveal.whyText }
        return RestoredDrillDescription.make(concept: replayContext.concept,
            seed: replayContext.seed, index: replayContext.index, input: submittedInput,
            stored: nil, language: language)?.why ?? reveal.whyText
    }

    private func action(_ calls: Bool) -> String {
        calls ? language.text("콜", "Call") : language.text("폴드", "Fold")
    }

    private var lesson: String {
        reveal.grade.loss <= 0
            ? language.text("\(KO.subject(action(chosenCalls))) 최선이에요",
                            "\(action(chosenCalls)) is best here")
            : language.text("최선은 \(action(bestCalls))",
                            "Better choice: \(action(bestCalls))")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(lesson)
                    .font(GT.title(20))
                    .foregroundStyle(GT.ink)
                Spacer(minLength: 6)
                Image(systemName: reveal.band.glyph)
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(reveal.band.ink)
                Text(evLossLabel(loss: reveal.grade.loss, language: language))
                    .font(GT.semibold(12)).foregroundStyle(reveal.band.ink)
            }
            evComparison

            Text(localizedWhy)
                .font(GT.body(GT.Typography.explanationSize))
                .foregroundStyle(GT.inkSecondary)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control)
                    .strokeBorder(GT.border, lineWidth: 1))
                .fixedSize(horizontal: false, vertical: true)
            if let term { GlossaryChip(term: term) }
            PrimaryCTAButton(title: language.text("다음 문제", "Next question"), action: onNext)
                .disabled(!saved)
                .accessibilityIdentifier("drill-completion-\(questionID)")
            if !saved {
                SecondaryCTAButton(title: language.text("저장 다시 시도", "Retry saving")) {
                    model.retrySave()
                    if model.saveError == nil {
                        saved = onCommit(DrillOutcome(band: reveal.band, interval: nil,
                                                       evLoss: reveal.grade.loss,
                                                       submittedInput: submittedInput))
                    }
                }.frame(minHeight: 44)
            }
        }
        .accessibilityElement(children: .contain)
        .preference(key: GradedBandKey.self, value: reveal.band)
        .onAppear {
            saved = onCommit(DrillOutcome(band: reveal.band, interval: nil,
                                          evLoss: reveal.grade.loss,
                                          submittedInput: submittedInput))
            if saved { gradeHaptic(reveal.band) }
        }
    }

    private var evComparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            evRow(tag: language.text("최선", "Best"), option: reveal.grade.best,
                  calls: bestCalls, ink: GTBand.spotOnInk)
            Divider().overlay(GT.border)
            evRow(tag: language.text("내 선택", "You"), option: reveal.grade.chosen,
                  calls: chosenCalls, ink: reveal.band.ink)
            HStack {
                Text(language.text("최선 대비 손실", "Value lost versus best"))
                    .font(GT.semibold(12)).foregroundStyle(GT.inkMuted)
                Spacer(minLength: 8)
                Text("\(bbText(reveal.grade.loss))bb")
                    .font(GT.title(15).monospacedDigit()).foregroundStyle(reveal.band.ink)
            }
            .accessibilityElement(children: .combine)
            Text(lossEquation)
                .font(GT.body(11).monospacedDigit()).foregroundStyle(GT.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
    }

    private var lossEquation: String {
        let best = bbText(reveal.grade.best.ev)
        let chosen = bbText(reveal.grade.chosen.ev)
        let chosenTerm = reveal.grade.chosen.ev < 0 ? "(\(chosen))" : chosen
        return language.text(
            "최선 EV \(best)bb − 내 선택 EV \(chosenTerm)bb = 손실 \(bbText(reveal.grade.loss))bb",
            "Best value \(best)bb − your value \(chosenTerm)bb = \(bbText(reveal.grade.loss))bb lost")
    }

    private func evRow(tag: String, option: DecisionOption, calls: Bool, ink: Color) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(tag) · \(action(calls))")
                        .font(GT.semibold(11))
                        .foregroundStyle(GT.inkMuted)
                    Text("\(bbText(option.ev))bb")
                        .font(GT.title(14).monospacedDigit())
                        .foregroundStyle(ink)
                }
            } else {
                HStack(spacing: 8) {
                    Text(tag).font(GT.semibold(11)).foregroundStyle(GT.inkMuted)
                        .frame(width: 46, alignment: .leading)
                    Text(action(calls)).font(GT.semibold(13)).foregroundStyle(GT.ink)
                    Spacer(minLength: 6)
                    Text("\(bbText(option.ev))bb")
                        .font(GT.title(14).monospacedDigit()).foregroundStyle(ink)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct EVLossDrill: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: EVLossReveal?
    @State private var chosenCalls = false

    /// Exact, and 1ms on a river — no sampling and no off-thread dance, unlike
    /// 레인지 어드밴티지 (spec §3.2).
    ///
    /// Bound once per render, never as a computed property: the generator rejects
    /// spots until it finds a decision-worthy one, and `body` reads the spot five
    /// times, so a computed property paid for five rejection loops per frame.
    private func makeSpot() -> EVLossSpot {
        EVLossSpotGenerator.spot(baseSeed: seed, index: index)
    }

    var body: some View {
        let spot = makeSpot()
        return DrillShell(title: "EV 손실", progressText: progressText) {
            VStack(alignment: .leading, spacing: 6) {
                if reveal != nil {
                    evRangeEvidence(spot)
                        .padding(.bottom, 10)
                }
                SectionLabel(text: language.text("보드 · 리버", "Shared cards · river"))
                CardRow(cards: spot.board)
                SectionLabel(text: language.text("내 핸드", "Your hand"))
                    .padding(.top, 10)
                CardRow(cards: spot.hero)
                // The range is stated, never guessed (spec §3.1). Printing it as the
                // premise is the difference between this and 콜/폴드, where the
                // villain's two cards are face up.
                if reveal == nil {
                    evRangeEvidence(spot)
                        .padding(.top, 10)
                }
                Text(language.text("팟 \(spot.pot)bb · 상대 벳 \(spot.bet)bb",
                                   "Pot \(spot.pot)bb · Opponent bets \(spot.bet)bb"))
                    .font(GT.title(15)).foregroundStyle(GT.onFelt).padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                EVLossRevealSheet(reveal: reveal, submittedInput: .boolean(chosenCalls)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil,
                                          evLoss: reveal.grade.loss))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("콜인가요, 폴드인가요?", "Call or fold?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    HStack(spacing: 10) {
                        ForEach([("폴드", false), ("콜", true)], id: \.0) { label, calls in
                            GTChoiceButton(title: language == .korean ? label
                                : (calls ? "Call" : "Fold"), minHeight: 56) {
                                chosenCalls = calls
                                reveal = gradeEVLoss(userCalls: calls, spot: spot, language: language)
                            }
                        }
                    }
                }
                .task {
                    #if DEBUG
                    // GT_DEMO_REVEAL=1 answers 콜, =0 answers 폴드 — the sweep needs both
                    // sides because the headline differs on each.
                    if let v = ProcessInfo.processInfo.environment["GT_DEMO_REVEAL"] {
                        chosenCalls = v != "0"
                        reveal = gradeEVLoss(userCalls: v != "0", spot: spot, language: language)
                    }
                    #endif
                }
            }
        }
    }

    private func evRangeEvidence(_ spot: EVLossSpot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: reveal == nil
                ? language.text("상대 레인지", "Opponent's possible hands")
                : language.text("채점에 사용한 상대 레인지", "Hands used to grade this"))
            Text(language.text("\(spot.rangeLabel) · \(Int(spot.villainRange.comboCount))콤보",
                               "\(spot.rangeLabel(in: language)) · \(Int(spot.villainRange.comboCount)) combinations"))
                .font(GT.title(15)).foregroundStyle(GT.onFelt)
            Text(language.text("리버에서 어떻게 좁혔는지는 아직 안 따져요",
                               "River narrowing is not counted yet"))
                .font(GT.body(11)).foregroundStyle(GT.onFeltMuted)
            // Drawn, not just named. A stated range the user cannot see is still a
            // number handed down — showing the 169 cells the equity came from is the
            // whole transparency claim (spec §3.1).
            RangeGridView(range: spot.villainRange)
                .frame(height: 230)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("ev-range-evidence")
    }
}

// MARK: - 액션 리드

private struct ActionReadDrill: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var point = 40.0
    @State private var halfWidth = 12.0
    @State private var reveal: EstimateReveal?

    /// Bound once per render — `body` reads the spot nine times, and the generator
    /// reseeds past the archetype/action pairs whose answer is a certainty, narrowing
    /// the range on each attempt to find out.
    private func makeSpot() -> ActionReadSpot {
        ActionReadSpotGenerator.spot(baseSeed: seed, index: index)
    }

    var body: some View {
        let spot = makeSpot()
        return DrillShell(title: "액션 리드", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: language.text("보드 · 플랍", "Shared cards · flop"))
                CardRow(cards: spot.board)
                Text(DrillTerms.board(spot.texture, in: language))
                    .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                SectionLabel(text: language.text("행동", "Action")).padding(.top, 8)
                Text(language.text("\(spot.villainSeat.rawValue) 오픈 → \(spot.actionLine)",
                                   "\(spot.villainSeat.rawValue) raises first → \(spot.actionLine(in: language))"))
                    .font(GT.title(17)).foregroundStyle(GT.onFelt)
                Text("\(spot.villain.beginnerTitle(in: language)) · \(spot.villain.beginnerDescription(in: language))")
                    .font(GT.body(11)).foregroundStyle(GT.onFeltMuted)
                if reveal != nil {
                    // The payload: the same range before and after the action. The
                    // number is graded, but the shape change is the lesson.
                    BucketBarView(label: language.text("오픈 레인지 전체", "All first-raise hands"),
                                  distribution: spot.full)
                        .padding(.top, 6)
                    BucketBarView(label: language.text("\(spot.action.rawValue) 이후",
                                                       spot.action == .bet ? "After betting" : "After checking"),
                                  distribution: spot.acted.distribution)
                        .padding(.top, 8)
                } else {
                    // Pre-answer, the grid is fair game — the preflop range is the
                    // stated premise, the same way EV 손실 prints it.
                    RangeGridView(range: spot.range)
                        .frame(height: 230)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                #if DEBUG
                // GT_DEMO_REVEAL=<point> — same hook as the other estimation drills:
                // the before/after bars are the payload and synthetic taps never
                // reach Simulator content.
                if let v = ProcessInfo.processInfo.environment["GT_DEMO_REVEAL"]
                    .flatMap(Double.init) {
                    point = v
                    reveal = gradeActionRead(
                        estimate: Estimate(point: v, lo: max(0, v - halfWidth),
                                           hi: min(100, v + halfWidth)),
                        spot: spot, language: language)
                }
                #endif
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band, mine: "\(Int(reveal.estimate.point))%",
                            correct: "\(pctText(reveal.correct))%",
                            why: reveal.whyText + (reveal.intervalHit
                                 ? " 구간 안에 들어왔어요." : " 구간을 벗어났어요."),
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 40; halfWidth = 12
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("\(KO.subject(spot.action.rawValue)) 남긴 레인지의 몇 %가 페어 이상일까요?",
                                       "What share left has a pair or better?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: 1, unit: "%")
                    PrimaryCTAButton(title: language.text("확인", "Check answer")) {
                        reveal = gradeActionRead(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot, language: language)
                    }
                }
            }
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }
}

// MARK: - 디펜드 차트

private struct DefendDrill: View {
    @Environment(\.learningLanguage) private var language
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: DefendReveal?

    private var spot: DefendSpot { DefendSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "디펜드 차트", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                if reveal != nil {
                    // Lead with the evidence used to grade this exact hand. On a
                    // compact screen the full 13×13 chart can extend below the fold;
                    // the selected cell and its action must not.
                    DefendGridView(opener: spot.opener, highlight: spot.handClass)
                        .frame(maxWidth: 320)
                        .padding(.bottom, 10)
                }
                SectionLabel(text: language.text("내 핸드", "Your hand"))
                CardRow(cards: spot.hand)
                SectionLabel(text: language.text("상황", "Situation")).padding(.top, 8)
                Text(language.text("\(spot.opener.rawValue)가 3bb 오픈했어요",
                                   "\(spot.opener.rawValue) raises first to 3bb"))
                    .font(GT.title(17)).foregroundStyle(GT.onFelt)
                Text(language.text("상위 \(pctText(RFIChart.openPercent[spot.opener] ?? 0))%를 여는 자리예요",
                                   "This seat starts with roughly the top \(pctText(RFIChart.openPercent[spot.opener] ?? 0))% of hands."))
                    .font(GT.body(11)).foregroundStyle(GT.onFeltMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                #if DEBUG
                // GT_DEMO_REVEAL=<0|1|2> answers 폴드/콜/3벳 — the chart is the payload
                // and synthetic taps never reach Simulator content.
                if let v = ProcessInfo.processInfo.environment["GT_DEMO_REVEAL"]
                    .flatMap(Int.init) {
                    let chosen: DefendAction = v == 0 ? .fold : (v == 1 ? .call : .threeBet)
                    reveal = gradeDefend(chosen: chosen, spot: spot, language: language)
                }
                #endif
            }
        } sheet: {
            if let reveal {
                DefendRevealSheet(reveal: reveal) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("이 핸드로 어떻게 맞서나요?", "What would you do with this hand?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    HStack(spacing: 10) {
                        ForEach(DefendAction.allCases.reversed(), id: \.self) { a in
                            GTChoiceButton(title: defendAction(a), minHeight: 56) {
                                reveal = gradeDefend(chosen: a, spot: spot, language: language)
                            }
                        }
                    }
                }
            }
        }
    }

    private func defendAction(_ action: DefendAction) -> String {
        switch action {
        case .fold: return language.text("폴드", "Fold")
        case .call: return language.text("콜", "Call")
        case .threeBet: return language.text("3벳", "Re-raise")
        }
    }
}

/// Defend grading retains the chart's ordinal progression bands, but the learner-facing
/// claim is only whether their action agrees with this published teaching chart. A
/// one-band miss is not evidence that the monetary mistake was small.
private struct DefendRevealSheet: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillReplayContext) private var replayContext
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.glossaryTerm) private var term
    @Environment(\.drillCommit) private var onCommit
    @Environment(ProgressionModel.self) private var model
    @State private var saved = false
    let reveal: DefendReveal
    private var submittedInput: DrillSubmittedInput { .action(reveal.chosen.rawValue) }
    let onNext: () -> Void

    private var matched: Bool { reveal.chosen == reveal.correct }

    private func action(_ value: DefendAction) -> String {
        switch value {
        case .fold: return language.text("폴드", "Fold")
        case .call: return language.text("콜", "Call")
        case .threeBet: return language.text("3벳", "Re-raise")
        }
    }

    private var localizedWhy: String {
        guard let replayContext else { return reveal.whyText }
        return RestoredDrillDescription.make(concept: replayContext.concept,
            seed: replayContext.seed, index: replayContext.index, input: submittedInput,
            stored: nil, language: language)?.why ?? reveal.whyText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(matched ? language.text("차트와 일치해요", "Matches the chart")
                             : language.text("차트와 달라요", "Different from the chart"))
                    .font(GT.title(18))
                    .foregroundStyle(matched ? GTBand.spotOnInk : GTBand.offInk)
                if matched {
                    Text(language.text("차트 판정 · \(action(reveal.correct))",
                                       "Chart choice · \(action(reveal.correct))"))
                        .font(GT.title(15)).foregroundStyle(GT.ink)
                } else {
                    HStack(spacing: 6) {
                        Text(language.text("내 선택 \(action(reveal.chosen))",
                                           "You chose \(action(reveal.chosen))"))
                            .font(GT.body(13)).foregroundStyle(GT.inkMuted)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(GT.inkMuted)
                        Text(language.text("차트 \(action(reveal.correct))",
                                           "Chart \(action(reveal.correct))"))
                            .font(GT.title(15)).foregroundStyle(GT.ink)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((matched ? GTBand.spotOnTint : GTBand.offTint),
                        in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .combine)

            Text(localizedWhy)
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control))
                .fixedSize(horizontal: false, vertical: true)
            if let term { GlossaryChip(term: term) }
            PrimaryCTAButton(title: language.text("다음 문제", "Next question"), action: onNext)
                .disabled(!saved)
                .accessibilityIdentifier("drill-completion-\(questionID)")
            if !saved {
                SecondaryCTAButton(title: language.text("저장 다시 시도", "Retry saving")) {
                    model.retrySave()
                    if model.saveError == nil {
                        saved = onCommit(DrillOutcome(band: reveal.band, interval: nil,
                                                       submittedInput: submittedInput))
                    }
                }.frame(minHeight: 44)
            }
        }
        .preference(key: GradedBandKey.self, value: reveal.band)
        .onAppear {
            saved = onCommit(DrillOutcome(band: reveal.band, interval: nil,
                                          submittedInput: submittedInput))
            if saved { gradeHaptic(reveal.band) }
        }
    }
}
