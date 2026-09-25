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

    var body: some View {
        let intro = ConceptIntroduction.make(concept, language: language)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(intro.title).font(GT.title(26)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    section(language.text("왜 중요할까요", "Why it matters"), intro.why)
                    section(language.text("이렇게 풀어요", "How to work it out"), intro.how)
                    if let example = Self.ruleExample(concept, language: language) {
                        section(language.text("예시", "Example"), example)
                            .accessibilityIdentifier("explain-rule-example")
                    }
                    if let note = Self.notationNote(concept, language: language) {
                        section(language.text("표기", "Notation"), note)
                    }
                    PrimaryCTAButton(title: language.text("예시 보기", "Watch an example")) {
                        showingExample = true
                    }
                    .accessibilityIdentifier("explain-example")
                }
                .padding(20)
            }
            .background(FeltBackground())
            .gtChrome(.topBarTrailing) { ChromeButton.close(onClose) }
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
    }

    /// Seeded off every question base (0x5EED, lessons, reviews), so the narrated
    /// answer is never the question on screen.
    private var example: some View {
        let w = Walkthrough.make(concept: concept,
                                 seed: 0xE9A1 &+ UInt64(model.seedCount(for: concept)),
                                 index: 0, language: language)
        return WalkthroughView(title: ConceptIntroduction.make(concept, language: language).title,
                               beats: w.beats, rows: w.rows,
                               onFinish: { showingExample = false },
                               onSkip: { showingExample = false })
    }

    static func ruleExample(_ concept: Concept, language: LearningLanguage) -> String? {
        switch concept {
        case .position:
            return language.text(
                "공용 카드 전에는 BB가 마지막이에요. 공용 카드 뒤에는 SB부터 시계 방향으로 행동해요.",
                "Before shared cards, BB acts last. After them, play goes clockwise from SB.")
        default:
            return nil
        }
    }

    static func notationNote(_ concept: Concept, language: LearningLanguage) -> String? {
        switch concept {
        case .combos, .rangeNotation, .rfi, .defend, .rangeRead, .hitFrequency,
             .rangeAdvantage, .actionRead:
            return language.text(
                "AKs는 같은 무늬, AKo는 다른 무늬예요. 99+는 99 이상의 모든 페어예요.",
                "AKs means the same suit and AKo different suits. 99+ means every pair from 99 up.")
        case .potOdds, .mdf, .callFold, .evCall, .evLoss:
            return language.text("bb는 빅 블라인드 한 개만큼의 칩이에요.",
                                 "bb means the chips in one big blind.")
        case .showdown, .potMath, .position, .outs, .equitySense:
            return nil
        }
    }
}
