// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Reopens a skill's explanation from a graded question: what it is, why it matters,
/// how to work it out, and a worked example on a different spot. It defines the
/// skill and never touches the current question, so opening it is not help.
struct ConceptExplainView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    let concept: Concept
    let onClose: () -> Void
    @State private var showingExample = false
    @State private var exampleSeed: UInt64?
    @State private var chartPrimerExpanded = true
    @State private var notationExpanded = false

    var body: some View {
        let intro = ConceptIntroduction.make(concept, language: language)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(intro.title).font(GT.title(26)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if concept == .defend { DefendChartPrimer(expanded: $chartPrimerExpanded) }
                    if concept == .combos { CombinationExampleView() }
                    section(language.text("왜 중요할까요", "Why it matters"), intro.why)
                    section(language.text("이렇게 풀어요", "How to work it out"), intro.how)
                    if let example = Self.ruleExample(concept, language: language) {
                        section(language.text("예시", "Example"), example)
                            .accessibilityIdentifier("explain-rule-example")
                    }
                    if let note = Self.notationNote(concept, language: language) {
                        DisclosureGroup(isExpanded: $notationExpanded) {
                            Text(note).font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
                        } label: {
                            Text(language.text("표기 더 보기", "More about notation"))
                                .font(GT.semibold(15)).frame(minHeight: 44)
                        }
                        .foregroundStyle(GT.ink).padding(.horizontal, 14).gtPanel()
                    }
                    if concept == .rfi || concept == .rangeNotation { LessonChartPrimer() }
                }
                .gtContentEdge()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionSheet {
                    PrimaryCTAButton(title: language.text("예시 보기", "Watch an example")) {
                        exampleSeed = GuideExampleRotation.next("explain-" + concept.rawValue)
                        showingExample = true
                    }
                        .accessibilityIdentifier("explain-example")
                }
            }
            .background(FeltBackground())
            .gtChrome(leading: { ChromeButton.close(onClose) })
            .gtSheetSurface()
            .navigationDestination(isPresented: $showingExample) { example }
        }
        .accessibilityIdentifier("concept-explain")
    }

    private func section(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label, onDark: false)
            Text(text).font(GT.body(16)).foregroundStyle(GT.ink)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .gtInset(GT.Space.card, firstText: .semibold(13))
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
    }

    /// Seeded off every question base (0x5EED, lessons, reviews), so the narrated
    /// answer is never the question on screen.
    private var example: some View {
        let w = Walkthrough.make(concept: concept,
                                 seed: exampleSeed ?? (0xE9A1 &+ UInt64(model.seedCount(for: concept))),
                                 index: 0, language: language)
        return WalkthroughView(title: ConceptIntroduction.make(concept, language: language).title,
                               concept: concept, beats: w.beats, rows: w.rows,
                               onFinish: { showingExample = false })
            .gtChrome(leading: {
                ChromeButton.back(language.text("설명으로", "Back to explanation")) { showingExample = false }
            }, trailing: {
                // Back returns to the explanation; close returns to the question.
                ChromeButton.close(onClose)
            })
            .gtSheetSurface()
    }

    static func ruleExample(_ concept: Concept, language: LearningLanguage) -> String? {
        switch concept {
        case .position:
            return language.text(
                "공용 카드 전에는 큰 블라인드가 마지막이에요. 공용 카드 뒤에는 딜러 왼쪽의 참여 중인 자리부터 행동해요.",
                "Before shared cards, the big blind acts last. After them, begin left of the dealer among active seats.")
        default:
            return nil
        }
    }

    static func notationNote(_ concept: Concept, language: LearningLanguage) -> String? {
        switch concept {
        case .combos, .rangeNotation, .rfi, .defend, .rangeRead, .hitFrequency,
             .rangeAdvantage, .actionRead:
            return language.text(
                "K♠와 6♠는 같은 무늬예요. K6s의 s는 스페이드가 아니라 같은 무늬를 뜻해요. K6o는 다른 무늬, KK는 페어예요. 99+는 99 이상의 모든 페어예요.",
                "K♠ and 6♠ share a suit. In K6s, s means suited, not spades. K6o means different suits; KK is a pair. 99+ means every pair from 99 up.")
        case .potOdds, .mdf, .callFold, .evCall, .evLoss:
            return language.text("bb는 빅 블라인드 한 개만큼의 칩이에요.",
                                 "bb is the chip amount of one big blind.")
        case .showdown, .potMath, .position, .outs, .equitySense:
            return nil
        }
    }
}
