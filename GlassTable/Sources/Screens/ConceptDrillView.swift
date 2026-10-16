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
    @State private var defendChartPractice = DefendChartPracticeState()
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
    let showsContextualHint: Bool

    private var questionID: String { "\(concept.rawValue)/\(seed)/\(index)" }

    init(concept: Concept, seed: UInt64, index: Int, progressText: String,
         restoredAnswer: RoundAnswer? = nil,
         initialDraft: SavedDrillDraftInput? = nil,
         help: DrillHelp? = nil,
         showsContextualHint: Bool = false,
         chartStartsFolded: Bool = false,
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
        self.showsContextualHint = showsContextualHint
        _defendChartPractice = State(initialValue: DefendChartPracticeState(chartVisible: !chartStartsFolded))
    }

    var body: some View {
        Group {
            // An answer given on this screen keeps its own reveal, so the cards stay where
            // the question put them. The saved reveal is only for an answer made before a
            // relaunch.
            if let restoredAnswer, !answerCommitted {
                RestoredDrillView(concept: concept, seed: seed, index: index,
                                  progressText: progressText, answer: restoredAnswer,
                                  onNext: onAnswer)
                    .environment(\.drillQuestionID, questionID)
                    .environment(\.drillExplain, help == nil ? nil : concept)
            } else {
                // The reveal sheets read these once; the drill views stay focused
                // on spot generation and input.
                drill
                    .id(questionID)
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
        .environment(\.drillHintConcept, showsContextualHint || help != nil ? concept : nil)
        .environment(\.lessonGuidedChart, showsContextualHint && help == nil)
        .onChange(of: questionID) { _, _ in
            answerCommitted = false
        }
        .onAppear {
            #if DEBUG
            let environment = ProcessInfo.processInfo.environment
            if environment["GT_TEST_STORE_ID"] != nil,
               environment["GT_TEST_DEFEND_CHART_INVITATION"] == "1" {
                defendChartPractice.correctDecisions = 3
            }
            #endif
        }
    }

    private func scheduleDraft(_ input: SavedDrillDraftInput) {
        guard !answerCommitted else { return }
        onDraft(input)
    }

    private func commit(_ outcome: DrillOutcome) -> Bool {
        let saved = onCommit(outcome)
        if saved {
            if !answerCommitted, concept == .defend, outcome.band == .spotOn {
                defendChartPractice.correctDecisions += 1
            }
            answerCommitted = true
        }
        return saved
    }

    /// The title each drill shows above its question; `DrillShell` translates it.
    static func drillTitle(for concept: Concept) -> String {
        switch concept {
        case .showdown: "쇼다운"
        case .potMath: "팟 계산"
        case .position: "포지션"
        case .equitySense: "에퀴티 감각"
        case .evCall: "EV 계산"
        case .combos: "콤보"
        case .outs: "아웃"
        case .potOdds: "팟 오즈"
        case .mdf: "MDF"
        case .callFold: "콜/폴드"
        case .rangeNotation: "레인지 표기법"
        case .rfi: "RFI 차트"
        case .rangeRead: "레인지 리드"
        case .hitFrequency: "히트 프리퀀시"
        case .rangeAdvantage: "레인지 어드밴티지"
        case .evLoss: "EV 손실"
        case .actionRead: "액션 리드"
        case .defend: "디펜드 차트"
        }
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
                        progressText: progressText, onAnswer: onAnswer,
                        chartPractice: $defendChartPractice)
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

private struct DrillHintConceptKey: EnvironmentKey {
    static let defaultValue: Concept? = nil
}

private extension EnvironmentValues {
    var drillHintConcept: Concept? {
        get { self[DrillHintConceptKey.self] }
        set { self[DrillHintConceptKey.self] = newValue }
    }
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

@MainActor private func gradeHaptic(_ band: GradeBand) {
    AppFeedback.answer(correct: band == .spotOn)
}

/// Marks where the evidence a reveal adds begins. On reveal the shell scrolls that
/// point to the top, so the evidence reads from its start; without a mark it scrolls
/// to the end of the content.
private struct RevealEvidenceKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private let revealEvidenceID = "drill-reveal-evidence"

private extension View {
    func revealEvidenceStart() -> some View {
        id(revealEvidenceID).preference(key: RevealEvidenceKey.self, value: true)
    }
}

/// A graded reveal reports its band so the sheet around it can take the verdict's tint.
struct GradedBandKey: PreferenceKey {
    static let defaultValue: GradeBand? = nil
    static func reduce(value: inout GradeBand?, nextValue: () -> GradeBand?) {
        value = value ?? nextValue()
    }
}

/// Every drill shares the same skeleton: felt content zone, cream answer sheet.
struct DrillShell<Content: View, Sheet: View>: View {
    private static var contentEnd: String { "drill-content-end" }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.drillExplain) private var explainConcept
    @Environment(\.drillHintConcept) private var hintConcept
    @State private var gradedBand: GradeBand?
    @State private var hasEvidenceStart = false
    @State private var explaining = false
    let title: String
    let progressText: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var sheet: () -> Sheet

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: GT.Space.section) {
                            VStack(alignment: .leading, spacing: 10) {
                                titleText.fixedSize(horizontal: false, vertical: true)
                                HStack(alignment: .top, spacing: 16) {
                                    if explainConcept != nil {
                                        Button { explaining = true } label: {
                                            ChromeGlyph(symbol: "info.circle")
                                        }
                                        .buttonStyle(GTPress())
                                        .accessibilityLabel(language.text("개념 설명", "Explain this skill"))
                                        .accessibilityIdentifier("drill-explain")
                                    }
                                    Text(progressText).font(GT.semibold(14).monospacedDigit())
                                        .foregroundStyle(GT.onFeltSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .accessibilityIdentifier("drill-question-\(questionID)")
                                }
                            }.padding(.bottom, 12)
                            if let hintConcept { CompactLessonCue(concept: hintConcept) }
                            content().frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .leading, spacing: GT.Space.related) { sheet() }
                                .padding(GT.Space.sheet).frame(maxWidth: .infinity, alignment: .leading)
                                .gtCard(radius: GT.Radius.panel, band: gradedBand)
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier(sheetIdentifier)
                        }
                        .frame(width: max(0, geometry.size.width - 36), alignment: .leading)
                        .padding(.horizontal, 18).padding(.bottom, 28)
                    }
                    .accessibilityIdentifier("drill-accessibility-scroll")
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: GT.Space.related) {
                            header
                            if let hintConcept { CompactLessonCue(concept: hintConcept) }
                            content()
                            Color.clear.frame(height: 1).id(Self.contentEnd)
                        }.padding(.horizontal, 18).padding(.bottom, 24)
                    }
                    .accessibilityIdentifier("drill-content-scroll")
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        ActionSheet(band: gradedBand) { sheet() }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(sheetIdentifier)
                    }
                    .onChange(of: gradedBand) { _, band in
                        guard band != nil else { return }
                        withAnimation(reduceMotion ? nil : GT.Motion.change) {
                            proxy.scrollTo(hasEvidenceStart ? revealEvidenceID : Self.contentEnd,
                                           anchor: hasEvidenceStart ? .top : .bottom)
                        }
                    }
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onPreferenceChange(GradedBandKey.self) { gradedBand = $0 }
        .onPreferenceChange(RevealEvidenceKey.self) { hasEvidenceStart = $0 }
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
        VStack(alignment: .leading, spacing: 10) {
            titleText.fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .center, spacing: 16) { headerControls }
        }
        .padding(.bottom, 12)
    }

    private var titleText: some View {
        Text(localizedTitle).font(GT.title(19)).foregroundStyle(GT.onFelt)
    }

    @ViewBuilder private var headerControls: some View {
        if explainConcept != nil {
            Button { explaining = true } label: {
                ChromeGlyph(symbol: "info.circle")
            }
            .buttonStyle(GTPress())
            // The 44 pt target overhangs the row, so the row is as tall as the title
            // whether or not this button is shown.

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
        guard let concept = Concept.allCases.first(where: {
            ConceptDrillView.drillTitle(for: $0) == title
        }) else { return title }
        return skillNames(concept, language: language, termsLead: termsLead).lead
    }

}

/// Reveal panel shared by every drill: verdict, the "why", then advance.
private struct RevealSheet: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.drillReplayContext) private var replayContext
    @Environment(\.drillQuestionID) private var questionID
    @Environment(\.glossaryTerm) private var term
    @Environment(\.drillCommit) private var onCommit
    @Environment(\.revealCollapsed) private var collapsed
    @Environment(ProgressionModel.self) private var model
    @Environment(\.simpleQuestions) private var simple
    @State private var saved = false
    @State private var showingWorkedExample = false
    @State private var workedExampleSeed: UInt64 = 0
    let band: GradeBand
    var interval: IntervalAnswer? = nil
    var evLoss: Double? = nil
    var correctTitle: String? = nil
    let submittedInput: DrillSubmittedInput
    let onNext: () -> Void

    /// Rebuilt from the spot, so the words follow the language and describe what was graded.
    private var reveal: ConceptReveal? {
        guard let replayContext else { return nil }
        return ConceptReveal(concept: replayContext.concept, seed: replayContext.seed,
                             index: replayContext.index, input: submittedInput,
                             openerEquityPct: interval?.truth, language: language, namesRange: !simple)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VerdictRow(band: band, mine: reveal?.mine ?? language.text("답변 저장됨", "Answer saved"),
                       correct: reveal?.correct ?? language.text("결과 저장됨", "Result saved"),
                       title: replayContext.flatMap {
                            practiceFeedbackTitle($0.concept, band: band, language: language)
                       },
                       correctTitle: correctTitle)
            if !collapsed {
                Text(reveal?.why ?? language.text("답은 저장됐어요. 다음 문제로 이어가세요.",
                                                  "Your answer was saved. Continue to the next question."))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.ink)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .gtInset(GT.Space.card, firstText: .body(16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gtExplanation(band: band)
                    .fixedSize(horizontal: false, vertical: true)
                if let term { GlossaryChip(term: term) }
            }
            if saved, band == .off, let replayContext,
               model.record(for: replayContext.concept).consecutiveMisses >= 2 {
                SecondaryCTAButton(title: language.text("예제를 함께 보고 다른 패로 다시 해봐요", "Try a worked example, then another hand")) {
                    workedExampleSeed = GuideExampleRotation.next("retry-" + replayContext.concept.rawValue)
                    showingWorkedExample = true
                }
                .accessibilityIdentifier("drill-worked-example")
            }
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
        .sheet(isPresented: $showingWorkedExample) {
            if let replayContext {
                let concept = replayContext.concept
                let worked = Walkthrough.make(concept: concept,
                    seed: 0xE9A1 &+ workedExampleSeed, index: 0, language: language)
                NavigationStack {
                    WalkthroughView(title: skillNames(concept, language: language, termsLead: false).lead,
                                    concept: concept, beats: worked.beats, rows: worked.rows,
                                    onFinish: { showingWorkedExample = false })
                        .gtChrome(leading: { ChromeButton.close { showingWorkedExample = false } })
                }.gtSheetSurface()
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
    /// Says the estimate in words instead of as a bare number.
    var describe: ((Double) -> String)?
    @Environment(\.simpleQuestions) private var simple

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(language.text("추정", "Estimate"))
                    .font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                Spacer()
                Text(describe?(point) ?? "\(fmt(point))\(unit)")
                    .font(GT.title(20).monospacedDigit()).foregroundStyle(GT.ink)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("estimate-value")
            }
            HStack(spacing: 10) {
                Slider(value: $point, in: range, step: step).tint(GT.cta)
                AdjustmentButtons(label: language.text("추정값", "Estimate"),
                                  decrement: { point = max(range.lowerBound, point - step) },
                                  increment: { point = min(range.upperBound, point + step) })
            }
            // The range feeds calibration, which is a later skill. A newer player just
            // guesses the number.
            if !simple {
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
            VStack(alignment: .leading, spacing: GT.Space.related) {
            ThreeRegionCardTable(
                opponent: spot.villain, board: spot.board, hero: spot.hero,
                opponentTitle: reveal?.winner == 1 ? language.text("상대 카드 · 승", "Opponent · won")
                                                    : language.text("상대 카드", "Opponent's cards"),
                heroTitle: reveal?.winner == 0 ? language.text("내 카드 · 승", "Your cards · won")
                                            : language.text("내 카드", "Your cards"),
                highlight: winningFive, sideBySide: true)
                if reveal != nil {
                    Text(language.text("각자 7장 중 가장 좋은 다섯 장으로 비교해요. 내 카드는 0장, 1장, 2장 모두 가능해요.",
                                       "Compare each player's best five of seven. Your hand can use neither, one or both of your cards."))
                        .font(GT.body(16)).foregroundStyle(GT.onFeltSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("showdown-best-five-rule")
                    Text(language.text("가장 좋은 5장", "Your best five"))
                        .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                    CardRow(cards: bestFiveCards(spot.hero + spot.board))
                    Text(language.text("상대의 가장 좋은 다섯 장", "Opponent's best five"))
                        .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                    CardRow(cards: bestFiveCards(spot.villain + spot.board))
                }
            }
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            submittedInput: .integer(reveal.answer)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(language.text("가장 좋은 다섯 장으로 누가 이길까요?", "Who wins with their best five cards?"))
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
                                          showsReplayControls: false,
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
                        PotMathReplayControls(steps: spot.replaySteps.count, stepIndex: $stepIndex)
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
            Text(language.text("각 사람이 지금까지 낸 칩을 보여줘요. 현재 팟을 함께 확인할 수 있어요.",
                               "Show each player's contributions so you can check the current pot."))
        }
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                PotMathIntroView { showingHelp = false }
                    .gtChrome(leading: { ChromeButton.close { showingHelp = false } })
                    .gtSheetSurface()
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
        VStack(alignment: .leading, spacing: 12) {
            // Stays at the last action too, so the sheet never changes height mid-question.
            Label(reachedLastAction
                  ? language.text("이제 답을 고를 수 있어요.", "Now choose an answer.")
                  : language.text("마지막 행동까지 넘기면 답을 고를 수 있어요.",
                                  "Follow the actions to the end, then choose an answer."),
                  systemImage: reachedLastAction ? "lock.open" : "lock")
                .font(GT.body(14))
                .foregroundStyle(reachedLastAction ? GT.ink : GT.inkSecondary)
                .contentTransition(.opacity)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) { choices }
            } else {
                HStack(spacing: 8) { choices }
            }
        }
        .padding(.top, 8)
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
    @Environment(\.revealCollapsed) private var collapsed
    @Environment(ProgressionModel.self) private var model
    @State private var saved = false
    let reveal: PotMathReveal
    private var submittedInput: DrillSubmittedInput { .integer(reveal.answer) }
    let onNext: () -> Void
    @State private var calculationExpanded = false

    private var localizedWhy: String {
        guard let replayContext else { return reveal.whyText }
        return ConceptReveal(concept: replayContext.concept, seed: replayContext.seed,
            index: replayContext.index, input: submittedInput, language: language)?.why ?? reveal.whyText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VerdictRow(band: reveal.band,
                       mine: language.text("\(reveal.answer)칩", "\(reveal.answer) chips"),
                       correct: language.text("\(reveal.correct)칩", "\(reveal.correct) chips"))
            if !collapsed {
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
                        .foregroundStyle(GT.ink)
                        .lineSpacing(GT.Typography.explanationLineSpacing)
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(GT.semibold(15))
                .foregroundStyle(GT.ink)
                .gtInset(GT.Space.card, firstText: .semibold(15))
                .gtExplanation(band: reveal.band)
                if let term { GlossaryChip(term: term) }
            }
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
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(\.simpleQuestions) private var simple
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: PositionReveal?

    private var spot: PositionSpot { PositionSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "포지션", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: reveal == nil
                    ? language.text(termsLead ? "8맥스 테이블 · 버튼부터 시계 방향" : "8명 테이블 · 딜러 버튼부터 시계 방향", "8-player table · clockwise from the button")
                    : language.text(termsLead ? "8맥스 테이블 · 행동 순서" : "8명 테이블 · 행동 순서", "8-player table · action order"))
                seatDiagram
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
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

    private var seatOrder: [Position] {
        reveal == nil ? [.btn, .sb, .bb, .utg, .utg1, .lj, .hj, .co]
            : (isPreflop ? Position.preflopOrder : Position.postflopOrder)
    }

    /// Before the answer the seats are drawn as they sit, from the dealer button; the
    /// action order is the answer, so it appears only in the reveal. Until the learner
    /// asks for poker terms, seats are grouped as early, middle, late and blinds and the
    /// eight codes wait for the reveal.
    private var seatStrip: some View {
        let order = seatOrder
        return Grid(horizontalSpacing: 5, verticalSpacing: 4) {
            if !termsLead {
                GridRow {
                    ForEach(Array(groupRuns(order).enumerated()), id: \.offset) { _, run in
                        Text(run.name)
                            .font(GT.semibold(10)).foregroundStyle(GT.onFeltSecondary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .gridCellColumns(run.count)
                            .accessibilityHidden(true)
                    }
                }
            }
            GridRow {
                ForEach(order, id: \.self) { p in
                    let marked = marker(p) != nil
                    Text(termsLead || reveal != nil ? p.rawValue : (marker(p) ?? ""))
                        .font(GT.semibold(10)).foregroundStyle(marked ? GT.cardInk : GT.onFelt)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(marked ? Color(hex: 0xF3EDE0) : GT.onFelt.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel([marker(p), p.plainName(in: language)]
                            .compactMap { $0 }.joined(separator: ", "))
                }
            }
        }
        // The strip is a diagram of the eight seats in order, so it has to stay one
        // row: reading it depends on seeing every seat at once. The labels still grow,
        // but stop short of the accessibility sizes, where "UTG+1" was breaking into
        // three stacked lines. VoiceOver reads the seat regardless.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    @ViewBuilder private var seatDiagram: some View {
        LessonSeatLoop(markers: Dictionary(uniqueKeysWithValues: Position.allCases.compactMap { position in
            marker(position).map { (position, $0) }
        }), showsOrder: reveal != nil, postflop: !isPreflop)
    }

    /// The seat the question is about. With codes showing, a two-seat question names
    /// its seats in the text, so only "my seat" is marked.
    private func marker(_ p: Position) -> String? {
        switch spot.question {
        case let .behind(mine, _): return p == mine ? language.text("나", "You") : nil
        case let .whichIsLater(a, b):
            guard !termsLead else { return nil }
            return p == a ? "A" : (p == b ? "B" : nil)
        }
    }

    private func groupName(_ p: Position) -> String {
        switch p {
        case .utg, .utg1: language.text("앞자리", "Early")
        case .lj, .hj: language.text("중간", "Middle")
        case .co, .btn: language.text("뒷자리", "Late")
        case .sb, .bb: language.text("블라인드", "Blinds")
        }
    }

    private func groupRuns(_ order: [Position]) -> [(name: String, count: Int)] {
        order.reduce(into: []) { runs, p in
            let name = groupName(p)
            if runs.last?.name == name { runs[runs.count - 1].count += 1 }
            else { runs.append((name, 1)) }
        }
    }

    private var questionText: String {
        switch spot.question {
        case let .behind(p, preflop):
            guard termsLead else {
                return language.text(
                    "내 자리: \(p.plainName(in: language)). \(preflop ? "프리플랍" : "플랍 이후")에 내 뒤에 몇 명이 남았나요?",
                    "Your seat: \(p.plainName(in: language)). How many players act after you \(preflop ? "before the flop" : "after the flop")?")
            }
            return language.text(
                "\(p.rawValue) 자리예요. \(preflop ? "프리플랍" : "플랍 이후")에 내 뒤에 몇 명이 남았나요?",
                "You are in \(p.rawValue). How many players act after you \(preflop ? "before the flop" : "after the flop")?")
        case let .whichIsLater(a, b):
            guard termsLead else {
                return language.text("A와 B 중 어느 자리가 더 늦게 행동하나요?", "Which seat acts later: A or B?")
            }
            return language.text("\(KO.and(a.rawValue)) \(b.rawValue) 중 어느 쪽이 더 늦게 행동하나요?",
                                 "Which seat acts later: \(a.rawValue) or \(b.rawValue)?")
        }
    }

    @ViewBuilder
    private var answerControls: some View {
        switch spot.question {
        case .behind:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: simple ? 3 : 4),
                      spacing: 8) {
                ForEach(simple ? BeginnerQuestionChoices.integers(answer: spot.correctAnswer, bounds: 0...7, seed: seed &+ UInt64(index)) : Array(0...7), id: \.self) { n in
                    GTChoiceButton(title: "\(n)", minHeight: 50) {
                        reveal = gradePosition(answer: n, spot: spot, language: language)
                    }
                }
            }
        case let .whichIsLater(a, b):
            HStack(spacing: 10) {
                ForEach(Array([a, b].enumerated()), id: \.offset) { i, p in
                    GTChoiceButton(title: termsLead ? p.rawValue : ["A", "B"][i], minHeight: 54) {
                        reveal = gradePosition(answer: i, spot: spot, language: language)
                    }
                }
            }
        }
    }

}

// MARK: - 에퀴티 감각

private struct EquitySenseDrill: View {
    @Environment(\.simpleQuestions) private var simple
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
                RevealSheet(band: reveal.band,
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 50; halfWidth = 10
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("끝까지 가면 이긴 몫과 무승부에서 나눈 몫을 합쳐 몇 %일까요?",
                                       "At showdown, what percentage is your wins plus your share of ties?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                    Text(language.text("이기면 100%, 둘이 비기면 50%, 지면 0%로 계산해요.",
                                       "A win counts as 100%, a two-player tie as 50%, and a loss as 0%."))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if simple {
                        LessonEstimateChoices(values: BeginnerQuestionChoices.percentages(answer: spot.equityPct, seed: seed &+ UInt64(index)), suffix: "%") { value in
                            point = value

                        reveal = gradeEquitySense(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot, language: language)

                        }
                    } else {
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
    @Environment(\.simpleQuestions) private var simple
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
                    Text(language.text(simple ? "내가 이길 확률 \(pctText(spot.equityPct))%" : "내 에퀴티 \(pctText(spot.equityPct))%",
                                       "Your chance to win \(pctText(spot.equityPct))%"))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    if simple {
                        Text(language.text("bb는 빅 블라인드 한 개만큼의 칩이에요.", "bb is the chip amount of one big blind."))
                            .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                    }
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
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 0; halfWidth = 1
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(simple
                        ? language.text("이 콜을 여러 번 하면 평균 몇 bb를 얻거나 잃을까요? 가장 가까운 값을 골라요. (EV)",
                                        "Over many tries, how many bb does this call win or lose on average? Pick the closest value. (its EV)")
                        : language.text("이 콜의 EV는 몇 bb인가요?",
                                        "What is this call's EV in bb?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if simple {
                        LessonEstimateChoices(values: LessonEstimateChoices.evValues(answer: spot.evBB, seed: seed &+ UInt64(index)), suffix: "bb") { value in
                            point = value

                        reveal = gradeEVCall(
                            estimate: Estimate(point: point, lo: point - halfWidth,
                                               hi: point + halfWidth),
                            spot: spot, language: language)

                        }
                    } else {
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
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }
}

// MARK: - the four M1 concepts, rendered natively in the new shell

/// 아웃 and 콤보: both answer with a whole-number count, so they share a screen and
/// differ only in what is shown above it and which grader runs.
private struct CountDrill: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.simpleQuestions) private var simple
    @Environment(\.drillInitialDraft) private var initialDraft
    @Environment(\.drillSaveDraft) private var saveDraft
    enum Kind { case outs, combos }
    let kind: Kind
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var countEntry = ""
    @State private var result: GradeBand?
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
                RevealSheet(band: result,
                            submittedInput: .integer(Int(countEntry) ?? 0)) {
                    onAnswer(DrillOutcome(band: result, interval: nil))
                    self.result = nil; countEntry = ""; tappedOut = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(kind == .outs
                        ? language.text("리버에 나를 이기게 해주는 카드는 몇 장인가요?",
                                        "How many river cards make you win?")
                        : simple
                        ? language.text("상대가 이 패를 들 수 있는 두 장 조합(콤보)은 몇 가지인가요?",
                                        "How many exact two-card hands (combos) can they hold?")
                        : language.text("상대가 들 수 있는 이 핸드 콤보는 몇 개인가요?",
                                        "How many combos can they hold?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if simple {
                        LessonCountChoices(values: BeginnerQuestionChoices.integers(
                            answer: kind == .outs ? makeOutsSpot().outCount : makeComboSpot().count,
                            bounds: kind == .outs ? 0...46 : 0...1326, seed: seed &+ UInt64(index)),
                            suffix: kind == .outs ? language.text("장", " cards") : language.text("개", " ways")) { value in
                            countEntry = String(value); submit()
                        }
                    } else {
                    CountEntryView(entry: $countEntry,
                                   suffix: kind == .outs ? language.text("장", " cards")
                                                         : language.text("개", " ways"),
                                   onSubmit: submit)
                    }
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
            result = r.band
        case .combos:
            let spot = makeComboSpot()
            let r = gradeBlocker(estimate: value, spot: spot, language: language)
            result = r.band
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
            ForEach(Array(OutsOutcomeGroups.make(hero: spot.hero, villain: spot.villain, board: spot.board, candidates: spot.outs).enumerated()), id: \.offset) { _, group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(outsGroupTitle(group, spot: spot)).font(GT.semibold(16))
                        .fixedSize(horizontal: false, vertical: true)
                    outsGrid(group.cards, dead: false)
                    if let representative = group.cards.first {
                        let completed = ShowdownSpot(hero: spot.hero, villain: spot.villain, board: spot.board + [representative])
                        Text(gradeShowdown(answer: completed.winner, spot: completed, language: language).whyText)
                            .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .foregroundStyle(GT.ink).frame(maxWidth: .infinity, alignment: .leading)
                .padding(12).gtCard()
                if let representative = group.cards.first {
                    Button(language.text("대표 카드로 비교", "Compare a representative")) { tappedOut = representative }
                        .buttonStyle(GTOutlinedAction())
                }
            }
            if !spot.excluded.isEmpty {
                SectionLabel(text: language.text("제외 · 무승부 또는 패배",
                                                 "Excluded · ties or losses"))
                    .padding(.top, 10)
                outsGrid(spot.excluded.sorted(by: BeatScript.byRank), dead: true)
            }
            if let tappedOut {
                RiverExplainPanel(spot: spot, river: tappedOut).padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func outsGroupTitle(_ group: OutsOutcomeGroup, spot: OutsSpot) -> String {
        guard let card = group.cards.first else { return "" }
        let completed = ShowdownSpot(hero: spot.hero, villain: spot.villain, board: spot.board + [card])
        let result = gradeShowdown(answer: completed.winner, spot: completed, language: language)
        return result.heroName + language.text(" · \(group.cards.count)장", " · \(group.cards.count) cards")
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
    @Environment(\.simpleQuestions) private var simple
    private var unit: String { simple ? language.text("칩", " chips") : "bb" }
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
                Text(language.text("팟 \(spot.pot)\(unit)", "Pot \(spot.pot)\(unit)"))
                    .font(GT.title(22)).foregroundStyle(GT.onFelt)
                Text(language.text("상대 벳 \(spot.bet)\(unit)", "Opponent bets \(spot.bet)\(unit)"))
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
                    Text(simple
                        ? language.text("콜 \(spot.bet)칩은 아직 내지 않아서 점선이에요",
                                        "The \(spot.bet)-chip call is dashed because you have not paid it yet.")
                        : language.text("콜 \(spot.bet)bb는 아직 내지 않은 돈이라 점선이에요",
                                        "The \(spot.bet)bb call is dashed because you have not paid it yet."))
                        .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            submittedInput: .integer(reveal.answerPct)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; value = 30
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isMDF
                        ? language.text("이 벳에 최소 몇 %를 지켜야 하나요?",
                                        "What minimum share do you defend?")
                        : simple
                        ? language.text("이 콜이 손해가 아니려면 얼마나 자주 이겨야 할까요?",
                                        "How often must you win for this call to break even?")
                        : language.text("콜하려면 최소 몇 %의 에퀴티가 필요한가요?",
                                        "What equity does this call need?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if simple {
                        LessonCountChoices(values: BeginnerQuestionChoices.shares(
                            answer: isMDF ? spot.mdfPct : spot.requiredPct,
                            seed: seed &+ UInt64(index)), suffix: "%") { choice in
                            value = choice
                            reveal = isMDF ? gradeMDF(estimatePct: choice, spot: spot, language: language)
                                           : gradePotOdds(estimatePct: choice, spot: spot, language: language)
                        }
                    } else {
                    // A count first: "1 in 4" is easier to picture than "25%".
                    if simple, !isMDF {
                        Text(oddsWords(value, language: language))
                            .font(GT.title(22).monospacedDigit()).foregroundStyle(GT.ink)
                            .frame(maxWidth: .infinity)
                            .contentTransition(.numericText())
                            .accessibilityIdentifier("odds-words")
                    }
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
        }
        .modifier(IntegerDraftModifier(value: $value))
    }
}

/// 콜/폴드 — the Block A boss concept: equity vs price, decided.
private struct CallFoldDrill: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.simpleQuestions) private var simple
    @Environment(\.lessonCallFoldNumbers) private var lessonNumbers
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
                let unit = simple ? language.text("칩", " chips") : "bb"
                Text(language.text("팟 \(spot.pot)\(unit) · 상대 벳 \(spot.bet)\(unit)",
                                   "Pot \(spot.pot)\(unit) · Opponent bets \(spot.bet)\(unit)"))
                    .font(GT.title(15)).foregroundStyle(GT.onFelt).padding(.top, 12)
                if lessonNumbers {
                    Text(callFoldLessonNumbers(spot: spot, language: language))
                        .font(GT.semibold(15)).foregroundStyle(GT.mint)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("callfold-lesson-numbers")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
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
    @Environment(\.simpleQuestions) private var simple
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
                SectionLabel(text: language.text(simple ? "가능한 패(레인지)" : "레인지", "Possible hands"))
                // One layout before and after the answer; the reveal only adds the grid.
                // The grid stays post-reveal on purpose: shown earlier it turns combo
                // arithmetic into cell counting.
                Text(spot.notation)
                    .font(GT.title(30).monospaced()).foregroundStyle(GT.onFelt)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.8)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                    .fixedSize(horizontal: false,
                               vertical: dynamicTypeSize.isAccessibilitySize)
                Text(language.text("페어 6 · 수티드 4 · 오프수트 12",
                                   "Pair 6 · same suit 4 · different suits 12"))
                    .font(GT.semibold(12)).foregroundStyle(GT.onFeltMuted)
                if reveal != nil {
                    SectionLabel(text: language.text("표에서 보면", "On the chart"))
                        .padding(.top, 6)
                        .revealEvidenceStart()
                    RangeGridView(range: spot.range)
                        .frame(maxWidth: 320)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            submittedInput: .integer(reveal.estimate)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; countEntry = ""
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(simple
                        ? language.text("이 표기에 들어가는 두 장 조합(콤보)은 모두 몇 가지인가요?",
                                        "How many exact two-card hands (combos) does this shorthand cover?")
                        : language.text("이 레인지는 몇 콤보인가요?",
                                        "How many combos is this range?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if simple {
                        LessonCountChoices(values: BeginnerQuestionChoices.integers(answer: spot.comboCount,
                            bounds: 0...1326, seed: seed &+ UInt64(index)), suffix: language.text("개", " combos")) { choice in
                            countEntry = String(choice)
                            reveal = gradeRangeNotation(estimate: choice, spot: spot, language: language)
                        }
                    } else {
                    CountEntryView(entry: $countEntry, suffix: language.text("개", " combinations"),
                                   onSubmit: {
                        guard let value = Int(countEntry) else { return }
                        reveal = gradeRangeNotation(estimate: value, spot: spot, language: language)
                    }, maximumDigits: 4, maximumValue: 1326)
                    }
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
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(\.simpleQuestions) private var simple
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @State private var reveal: RFIReveal?

    private var spot: RFISpot { RFISpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "RFI 차트", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: language.text("내 핸드", "Your hand"))
                if simple { LessonHandNotation(cards: spot.hand) }
                else { CardRow(cards: spot.hand) }
                SectionLabel(text: language.text("내 자리", "Your seat"))
                    .padding(.top, 8)
                if simple {
                    LessonSeatLoop(active: spot.seat, showsOrder: false)
                } else {
                    seatStrip
                }
                if let reveal {
                    if simple {
                        groupLine(opens: reveal.correctOpens)
                            .padding(.top, 10)
                            .revealEvidenceStart()
                        DisclosureGroup(language.text("전체 차트 보기", "See the full chart")) { chart }
                            .foregroundStyle(GT.onFelt)
                            .accessibilityIdentifier("rfi-chart-detail")
                    } else {
                        chart.padding(.top, 10).revealEvidenceStart()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } sheet: {
            if let reveal {
                RevealSheet(band: reveal.band,
                            submittedInput: .boolean(reveal.userOpens)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(termsLead
                        ? language.text("\(spot.seat.rawValue)에서 이 핸드, 오픈인가요?",
                                        "In \(spot.seat.rawValue), raise first with this hand?")
                        : language.text("내 자리: \(spot.seat.plainName(in: language)). 이 패로 먼저 올릴까요?",
                                        "Your seat: \(spot.seat.plainName(in: language)). Raise first with this hand?"))
                        .fixedSize(horizontal: false, vertical: true)
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
    private var chart: some View {
        SectionLabel(text: language.text("\(spot.seat.rawValue) 오픈 레인지",
                                          "\(spot.seat.rawValue) first-raise hands"))
        RangeGridView(range: RFIChart.range(for: spot.seat),
                      highlight: spot.handClass)
            .frame(maxWidth: 320)
        Text(language.text("8핸드 차트는 공개된 9맥스·6맥스 사이를 보간한 값이에요.",
                           "The 8-player practice chart sits between published 9- and 6-player ranges."))
            .font(GT.body(10.5)).foregroundStyle(GT.onFeltMuted)
            .padding(.top, 2)
    }

    /// The chart as three groups, then what it says for this seat. Both come from the
    /// same published chart the answer was graded against.
    private func groupLine(opens: Bool) -> some View {
        let group = RFIChart.group(of: spot.hand)
        let seat = spot.seat.plainName(in: language)
        let name: String
        let detail: String
        switch group {
        case .always:
            name = language.text("항상 들어가는 패", "Always play")
            detail = language.text("차트는 어느 자리에서든 이 패로 먼저 올려요.",
                                   "The chart raises first with this hand from every seat.")
        case .late:
            name = language.text("뒷자리에서 들어가는 패", "Play late")
            detail = opens
                ? language.text("차트는 일부 자리에서만 이 패로 올려요. \(seat)에서는 올려요.",
                                "The chart raises first with this hand from some seats only. From \(seat) it raises.")
                : language.text("차트는 일부 자리에서만 이 패로 올려요. \(seat)에서는 접어요.",
                                "The chart raises first with this hand from some seats only. From \(seat) it folds.")
        case .fold:
            name = language.text("접는 패", "Fold")
            detail = language.text("차트는 어느 자리에서도 이 패로 먼저 올리지 않아요.",
                                   "The chart does not raise first with this hand from any seat.")
        }
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle().fill(group == .always ? GT.mint : (group == .late ? GT.cta : GT.onFeltMuted))
                    .frame(width: 10, height: 10).accessibilityHidden(true)
                Text(name).font(GT.semibold(15)).foregroundStyle(GT.onFelt)
            }
            Text(detail).font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("rfi-group")
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
            .foregroundStyle(position == spot.seat ? GT.cardInk : GT.onFelt.opacity(0.75))
            .lineLimit(1).minimumScaleFactor(compact ? 0.8 : 1)
            .frame(maxWidth: .infinity, minHeight: compact ? 32 : 44)
            .background(position == spot.seat ? Color(hex: 0xF3EDE0) : GT.onFelt.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: GT.Radius.tile))
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
    /// Calls only: the strongest hands taken off the top, because they would raise.
    @State private var excludedTop: Double = 0
    @State private var reveal: RangeReadReveal?
    @Environment(\.simpleQuestions) private var simple
    /// The chart stays hidden until a beginner commits to a complete range estimate.
    @State private var pickedStart = false
    private var asksInWords: Bool { simple && !pickedStart && reveal == nil }

    private var spot: RangeReadSpot { RangeReadSpotGenerator.spot(baseSeed: seed, index: index) }
    private var isCall: Bool { if case .called = spot.action { true } else { false } }
    private var estimate: RangeEstimate {
        RangeEstimate(width: width, tendencies: tendencies, excludedTop: isCall ? excludedTop : 0)
    }
    private var submitted: DrillSubmittedInput {
        let raw = tendencies.map(\.rawValue).sorted()
        return isCall && excludedTop > 0
            ? .rangeBand(width: width, excludedTop: excludedTop, tendencies: raw)
            : .range(width: width, tendencies: raw)
    }

    var body: some View {
        DrillShell(title: "레인지 리드", progressText: progressText) {
            VStack(alignment: .leading, spacing: 9) {
                opponentLine
                actionList
                if !asksInWords {
                SectionLabel(text: reveal == nil
                    ? language.text("내가 보는 범위", "My possible hands")
                    : language.text("정답 · 선택한 답 비교", "Answer · your estimate"))
                    .padding(.top, 4)
                    .revealEvidenceStart()
                // The legend goes *above* the grid. Below it, the one thing that makes
                // a two-channel grid readable sat under the answer sheet and was never
                // seen — found by looking at the sweep rather than by reasoning.
                if reveal != nil { legend }
                RangeGridView(range: reveal?.truth ?? estimate.range,
                              outline: reveal?.guess)
                    .frame(maxWidth: 250)
                    .animation(GT.Motion.change, value: width)
                    .animation(GT.Motion.change, value: excludedTop)
                }
                if let reveal { RangeDifferenceList(truth: reveal.truth, guess: reveal.guess) }
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
                            submittedInput: submitted) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: nil))
                    self.reveal = nil; width = 20; tendencies = []; excludedTop = 0
                    pickedStart = false
                }
            } else if simple {
                beginnerRanges
            } else {
                input
            }
        }
        .onAppear { restoreDraft() }
        .onChange(of: index) { _, _ in restoreDraft() }
        .onChange(of: width) { _, _ in saveRangeDraft() }
        .onChange(of: tendencies) { _, _ in saveRangeDraft() }
        .onChange(of: excludedTop) { _, _ in saveRangeDraft() }
    }

    private func restoreDraft() {
        switch initialDraft {
        case let .range(savedWidth, raw)?:
            width = savedWidth; pickedStart = true
            tendencies = Set(raw.compactMap(RangeTendency.init(rawValue:)))
        case let .rangeBand(savedWidth, top, raw)?:
            width = savedWidth; excludedTop = top; pickedStart = true
            tendencies = Set(raw.compactMap(RangeTendency.init(rawValue:)))
        default: break
        }
    }

    private var beginnerRanges: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("이 행동에 맞는 패 범위는 어느 쪽일까요?", "Which range fits these actions?"))
                .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(BeginnerQuestionChoices.rangeEstimates(spot: spot, seed: seed &+ UInt64(index)).enumerated()), id: \.offset) { option, candidate in
                GTChoiceButton(title: language.text("가능한 패 약 \(pctText(candidate.range.percent))%", "About \(pctText(candidate.range.percent))% of hands"), minHeight: 52) {
                    width = candidate.width
                    tendencies = candidate.tendencies
                    excludedTop = candidate.excludedTop
                    pickedStart = true
                    reveal = gradeRangeRead(estimate: candidate, spot: spot, language: language)
                    if let reveal { gradeHaptic(reveal.band) }
                }.accessibilityIdentifier("range-estimate-choice-\(option)")
            }
            if isCall {
                Text(language.text("레이즈할 가장 강한 패를 뺀 콜 범위예요.", "These calling ranges exclude the strongest raising hands."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func saveRangeDraft() {
        let raw = tendencies.map(\.rawValue).sorted()
        saveDraft(isCall && excludedTop > 0
                  ? .rangeBand(width: width, excludedTop: excludedTop, tendencies: raw)
                  : .range(width: width, tendencies: raw))
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
        .gtInset(GT.Space.card, firstText: .semibold(13))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: GT.Radius.control))
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
                .accessibilityValue(language.text("전체의 \(pctText(width))퍼센트",
                                                   "\(pctText(width)) percent of hands"))
            AdjustmentButtons(label: language.text("범위 넓이", "Range width"),
                              decrement: { width = max(3, width - 1) },
                              increment: { width = min(80, width + 1) })
            if isCall { raisedTopControl }

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

    /// A caller's best hands raise instead, so a calling range is a band with the top
    /// taken off. This control is that top; without it no call read could match.
    private var raisedTopControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(language.text("레이즈했을 강한 핸드 빼기", "Take off hands they'd raise"))
                    .font(GT.semibold(15)).foregroundStyle(GT.ink)
                Spacer(minLength: 8)
                Text(language.text("상위 \(pctText(excludedTop))%", "Top \(pctText(excludedTop))%"))
                    .font(GT.title(17).monospacedDigit()).foregroundStyle(GT.ink)
                    .contentTransition(.numericText())
            }
            Text(language.text("가장 강한 핸드는 보통 콜하지 않고 레이즈해요. 위에서부터 몇 %를 뺄지 정해요.",
                               "The strongest hands usually raise instead of calling. Choose how much to take off the top."))
                .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Slider(value: $excludedTop, in: 0...RangeReadInput.excludedTopLimit, step: 1).tint(GT.cta)
                    .accessibilityLabel(language.text("위에서 뺄 넓이", "Hands taken off the top"))
                    .accessibilityValue(language.text("상위 \(pctText(excludedTop))퍼센트",
                                                       "Top \(pctText(excludedTop)) percent"))
                AdjustmentButtons(label: language.text("위에서 뺄 넓이", "Hands taken off the top"),
                                  decrement: { excludedTop = max(0, excludedTop - 1) },
                                  increment: { excludedTop = min(RangeReadInput.excludedTopLimit,
                                                                 excludedTop + 1) })
            }
        }
        .accessibilityIdentifier("range-read-excluded-top")
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
                        in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
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
    @Environment(\.simpleQuestions) private var simple
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
                Text(language.text("\(spot.seat.rawValue) 오픈 · 상위 약 \(pctText(RFIChart.openPercent[spot.seat] ?? 0))%",
                                   "\(spot.seat.rawValue) raised first · about \(pctText(RFIChart.openPercent[spot.seat] ?? 0))% of hands"))
                    .font(GT.title(17)).foregroundStyle(GT.onFelt)
                if reveal != nil {
                    BucketBarView(label: language.text("\(spot.seat.rawValue) 오픈 레인지",
                                                       "\(spot.seat.rawValue) first-raise hands"),
                                  distribution: spot.distribution)
                        .padding(.top, 6)
                        .revealEvidenceStart()
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
                RevealSheet(band: reveal.band,
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
                    if simple {
                        LessonEstimateChoices(values: BeginnerQuestionChoices.percentages(answer: spot.pairOrBetterPct, seed: seed &+ UInt64(index)), suffix: "%") { value in
                            point = value

                        reveal = gradeHitFrequency(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot, language: language)

                        }
                    } else {
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
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }
}

// MARK: - 레인지 어드밴티지

private struct RangeAdvantageDrill: View {
    @Environment(\.simpleQuestions) private var simple
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
                    Text(language.text("\(spot.callerSeat.rawValue) 콜 · \(spot.caller.beginnerTitle(in: .korean))",
                                       "\(spot.callerSeat.rawValue) calls · \(spot.caller.beginnerTitle(in: language))"))
                }
                .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                .gtInset(GT.Space.card, firstText: .semibold(14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.onFelt.opacity(0.10), in: RoundedRectangle(cornerRadius: GT.Radius.control))
                if reveal != nil, let buckets {
                    VStack(alignment: .leading, spacing: 18) {
                        BucketBarView(label: language.text("\(spot.openerSeat.rawValue) 오픈",
                                                           "\(spot.openerSeat.rawValue) first raise"),
                                      distribution: buckets.opener, showsHeadline: false)
                        BucketBarView(label: language.text("\(spot.callerSeat.rawValue) 콜",
                                                           "\(spot.callerSeat.rawValue) call"),
                                      distribution: buckets.caller, showsHeadline: false)
                    }
                    .padding(.top, 8)
                    .revealEvidenceStart()
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
                RevealSheet(band: reveal.band,
                            interval: reveal.intervalAnswer,
                            correctTitle: language.text("오프너 승률", "Raiser's win rate"),
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
                    if simple {
                        LessonEstimateChoices(values: BeginnerQuestionChoices.percentages(answer: equity ?? 50, seed: seed &+ UInt64(index)), suffix: "%") { value in
                            point = value

                        submit(value)
                        }.disabled(equity == nil)
                    } else {
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
        }
        .modifier(IntervalDraftModifier(point: $point, halfWidth: $halfWidth))
    }
}

// MARK: - EV 손실

extension EVLossReveal {
    /// How the verdict looks and sounds. A choice that gave up any value is never shown
    /// as right: a small loss is stored as `.spotOn` but reads and counts as close.
    var shownBand: GradeBand { band.counted(evLoss: grade.loss) }
}

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
    @Environment(\.revealCollapsed) private var collapsed
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
        return ConceptReveal(concept: replayContext.concept, seed: replayContext.seed,
            index: replayContext.index, input: submittedInput, language: language)?.why ?? reveal.whyText
    }

    private func action(_ calls: Bool) -> String {
        calls ? language.text("콜", "Call") : language.text("폴드", "Fold")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VerdictRow(band: reveal.shownBand, mine: action(chosenCalls), correct: action(bestCalls),
                       title: evLossLabel(loss: reveal.grade.loss, language: language),
                       mineTitle: language.text("선택한 답", "Your answer"),
                       correctTitle: language.text("최선", "Best"))
            if !collapsed {
                evComparison

                Text(localizedWhy)
                    .font(GT.body(GT.Typography.explanationSize))
                    .foregroundStyle(GT.ink)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .gtInset(GT.Space.card, firstText: .body(16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gtExplanation(band: reveal.shownBand)
                    .fixedSize(horizontal: false, vertical: true)
                if let term { GlossaryChip(term: term) }
            }
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
        .preference(key: GradedBandKey.self, value: reveal.shownBand)
        .onAppear {
            saved = onCommit(DrillOutcome(band: reveal.band, interval: nil,
                                          evLoss: reveal.grade.loss,
                                          submittedInput: submittedInput))
            if saved { AppFeedback.answer(correct: reveal.shownBand == .spotOn) }
        }
    }

    private var evComparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            evRow(tag: language.text("최선", "Best"), option: reveal.grade.best,
                  calls: bestCalls, ink: GTBand.spotOnInk)
            Divider().overlay(GT.border)
            evRow(tag: language.text("선택한 답", "Your choice"), option: reveal.grade.chosen,
                  calls: chosenCalls, ink: reveal.shownBand.ink)
            HStack {
                Text(language.text("최선 대비 손실", "Value lost versus best"))
                    .font(GT.semibold(12)).foregroundStyle(GT.inkMuted)
                Spacer(minLength: 8)
                Text("\(bbText(reveal.grade.loss))bb")
                    .font(GT.title(15).monospacedDigit()).foregroundStyle(reveal.shownBand.ink)
            }
            .accessibilityElement(children: .combine)
            Text(lossEquation)
                .font(GT.body(11).monospacedDigit()).foregroundStyle(GT.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .gtInset(GT.Space.card, firstText: dynamicTypeSize.isAccessibilitySize ? .semibold(11) : .title(14))
        .gtExplanation()
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
                SectionLabel(text: language.text("보드 · 리버", "Shared cards · river"))
                CardRow(cards: spot.board)
                SectionLabel(text: language.text("내 핸드", "Your hand"))
                    .padding(.top, 10)
                CardRow(cards: spot.hero)
                // The range is stated, never guessed (spec §3.1). Printing it as the
                // premise is the difference between this and 콜/폴드, where the
                // villain's two cards are face up. It stays in place after the answer,
                // so the question does not rearrange under the reveal.
                evRangeEvidence(spot)
                    .padding(.top, 10)
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
    @Environment(\.simpleQuestions) private var simple
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
                Text(language.text("\(spot.villainSeat.plainName(in: language)) 먼저 올림 → \(spot.actionLine)",
                                   "\(spot.villainSeat.plainName(in: language)) raises first → \(spot.actionLine(in: language))"))
                    .font(GT.title(17)).foregroundStyle(GT.onFelt)
                Text("\(spot.villain.beginnerTitle(in: language)) · \(spot.villain.beginnerDescription(in: language))")
                    .font(GT.body(11)).foregroundStyle(GT.onFeltMuted)
                // The grid is fair game before the answer: the preflop range is the
                // stated premise, the same way EV 손실 prints it. A newer player is
                // asked in words first and sees it with the answer.
                if !simple || reveal != nil {
                    RangeGridView(range: spot.range)
                        .frame(height: 230)
                        .padding(.top, 6)
                }
                if reveal != nil {
                    // The payload: the same range before and after the action. The
                    // number is graded, but the shape change is the lesson.
                    BucketBarView(label: language.text("오픈 레인지 전체", "All first-raise hands"),
                                  distribution: spot.full)
                        .padding(.top, 6)
                        .revealEvidenceStart()
                    BucketBarView(label: language.text("\(spot.action.rawValue) 이후",
                                                       spot.action == .bet ? "After betting" : "After checking"),
                                  distribution: spot.acted.distribution)
                        .padding(.top, 8)
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
                RevealSheet(band: reveal.band,
                            interval: reveal.intervalAnswer,
                            submittedInput: .interval(point: reveal.estimate.point,
                                                      lo: reveal.estimate.lo,
                                                      hi: reveal.estimate.hi)) {
                    onAnswer(DrillOutcome(band: reveal.band, interval: reveal.intervalAnswer))
                    self.reveal = nil; point = 40; halfWidth = 12
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(simple
                        ? (spot.action == .bet
                            ? language.text("벳은 무엇을 말해 줄까요? 벳한 뒤 상대가 페어 이상을 들고 있을 때는 얼마나 될까요?",
                                            "What does a bet tell you? After betting, how often do they have a pair or better?")
                            : language.text("체크는 무엇을 말해 줄까요? 체크한 뒤 상대가 페어 이상을 들고 있을 때는 얼마나 될까요?",
                                            "What does a check tell you? After checking, how often do they have a pair or better?"))
                        : language.text("\(KO.subject(spot.action.rawValue)) 남긴 레인지의 몇 %가 페어 이상일까요?",
                                        "What share left has a pair or better?"))
                        .font(GT.title(GT.Typography.questionSize)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    // Steps of ten keep every answer within the on-target band of some
                    // choice, so the words never cost a learner the grade.
                    if simple {
                        LessonEstimateChoices(values: BeginnerQuestionChoices.percentages(answer: spot.pairOrBetterPct, seed: seed &+ UInt64(index)), suffix: "%") { value in
                            point = value

                        reveal = gradeActionRead(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot, language: language)

                        }
                    } else {
                    IntervalInput(point: $point, halfWidth: $halfWidth,
                                  range: 0...100, step: simple ? 10 : 1, unit: "%",
                                  describe: simple ? { value in
                                      "\(frequencyWord(value, language: language)) · \(oddsWords(Int(value), language: language))"
                                  } : nil)
                    PrimaryCTAButton(title: language.text("확인", "Check answer")) {
                        reveal = gradeActionRead(
                            estimate: Estimate(point: point, lo: max(0, point - halfWidth),
                                               hi: min(100, point + halfWidth)),
                            spot: spot, language: language)
                    }
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
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(\.simpleQuestions) private var simple
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.lessonGuidedChart) private var guidedChart
    @Environment(\.drillHelp) private var help
    let seed: UInt64; let index: Int; let progressText: String
    let onAnswer: (DrillOutcome) -> Void
    @Binding var chartPractice: DefendChartPracticeState
    @State private var reveal: DefendReveal?

    private var spot: DefendSpot { DefendSpotGenerator.spot(baseSeed: seed, index: index) }

    var body: some View {
        DrillShell(title: "디펜드 차트", progressText: progressText) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: language.text("내 핸드", "Your hand"))
                CardRow(cards: spot.hand)
                SectionLabel(text: language.text("상황", "Situation")).padding(.top, 8)
                LessonPairedText(
                    korean: ["상대: \(seatName)",
                             termsLead && !simple ? "3bb로 먼저 올렸어요" : "빅 블라인드 3개로 먼저 올렸어요"],
                    english: ["Opponent: \(seatName)",
                              termsLead && !simple ? "Raises first to 3bb" : "Raises first to 3 big blinds"])
                    .font(GT.title(17)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                Text(language.text("상위 약 \(pctText(RFIChart.openPercent[spot.opener] ?? 0))%를 여는 자리예요",
                                   "This seat starts with about \(pctText(RFIChart.openPercent[spot.opener] ?? 0))% of hands, strongest first."))
                    .font(GT.body(11)).foregroundStyle(GT.onFeltMuted)
                if reveal == nil {
                    DefendChartPrimer(expanded: $chartPractice.primerExpanded)
                    if simple, chartPractice.offersIndependentTry {
                        chartInvitation
                    }
                    Button(language.text(chartPractice.chartVisible && (guidedChart || help?.isUsed == true) ? "차트 접기" : "차트 보기",
                                         chartPractice.chartVisible && (guidedChart || help?.isUsed == true) ? "Hide chart" : "Show chart")) {
                        if guidedChart || help?.isUsed == true { chartPractice.chartVisible.toggle() }
                        else if help?.mark() == true { chartPractice.chartVisible = true }
                    }.buttonStyle(GTOutlinedAction()).accessibilityIdentifier("defend-practice-chart-toggle")
                    if chartPractice.chartVisible, guidedChart || help?.isUsed == true {
                        DefendGridView(opener: spot.opener, highlight: nil).frame(maxWidth: 320)
                    }
                }
                if reveal != nil {
                    // The evidence used to grade this exact hand, added below the
                    // question. The shell scrolls its start to the top, and the graded
                    // sheet folds down if the chart runs under it.
                    DefendGridView(opener: spot.opener, highlight: spot.handClass, folded: simple)
                        .frame(maxWidth: 320)
                        .padding(.top, 10)
                        .revealEvidenceStart()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                // A beginner sees the chart unasked, and seeing it is help; a folded
                // chart leaves the answer the learner's own.
                if simple, !guidedChart, chartPractice.chartVisible, help?.isUsed != true { _ = help?.mark() }
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
                    let choices = textSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
                    choices {
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

    private var seatName: String {
        if termsLead && !simple { return spot.opener.rawValue }
        let number = spot.opener.seatNumber
        let name = spot.opener.seatName(in: language)
            .replacingOccurrences(of: "\n", with: " ")
        return language.text("\(number)번 자리 · \(name)", "Seat \(number) · \(name)")
    }

    private var chartInvitation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language.text("몇 번 잘 맞췄어요. 원하면 차트를 접고 한 번 생각해 보세요. 언제든 다시 펼칠 수 있어요.",
                               "You’ve matched several choices. If you like, hide the chart and try one from memory. You can reopen it anytime."))
                .font(GT.body(15)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
            SecondaryCTAButton(title: language.text("차트 접고 해보기", "Try with the chart folded")) {
                chartPractice.chartVisible = false
                chartPractice.invitationDismissed = true
            }.accessibilityIdentifier("defend-chart-try-folded")
            Button(language.text("차트 계속 보기", "Keep the chart open")) {
                chartPractice.invitationDismissed = true
            }
            .buttonStyle(GTOutlinedAction())
            .accessibilityIdentifier("defend-chart-keep-open")
        }.padding(14).gtPanel()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("defend-chart-invitation")
    }

    private func defendAction(_ action: DefendAction) -> String {
        switch action {
        case .fold: return language.text("폴드", "Fold")
        case .call: return language.text("콜", "Call")
        case .threeBet: return language.text("다시 올리기", "Raise again")
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
    @Environment(\.revealCollapsed) private var collapsed
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
        return ConceptReveal(concept: replayContext.concept, seed: replayContext.seed,
            index: replayContext.index, input: submittedInput, language: language)?.why ?? reveal.whyText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VerdictRow(band: reveal.band, mine: action(reveal.chosen),
                       correct: action(reveal.correct),
                       title: matched ? language.text("차트와 일치해요", "Matches the chart")
                                      : language.text("차트와 달라요", "Different from the chart"),
                       mineTitle: language.text("선택한 답", "Your answer"),
                       correctTitle: language.text("차트", "Chart"))
            if !collapsed {
                Text(localizedWhy)
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.ink)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .gtInset(GT.Space.card, firstText: .body(16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gtExplanation(band: reveal.band)
                    .fixedSize(horizontal: false, vertical: true)
                if let term { GlossaryChip(term: term) }
            }
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
            // One step off the chart is amber, not right: it gets the review sound.
            if saved { AppFeedback.answer(correct: reveal.band == .spotOn) }
        }
    }
}
