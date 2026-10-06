import SwiftUI
import GlassTableDrills

/// The method stays in the task layout. Generated answers stay hidden until commitment.
struct ContextualHintCue: View {
    @Environment(\.learningLanguage) private var language
    let concept: Concept

    var body: some View {
        Label(ConceptIntroduction.make(concept, language: language).how, systemImage: "lightbulb")
            .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
            .lineSpacing(GT.Typography.bodyLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .gtInset(GT.Space.card, firstText: .body(15))
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtPanel()
            .accessibilityIdentifier("contextual-hint-cue")
    }
}
