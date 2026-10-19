// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Readable Settings reference. Opening help never changes a learning session.
struct LearningGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    @State private var page = 0

    private var topics: [LearningGuideTopic] { LearningGuideContent.topics }
    private var topic: LearningGuideTopic { topics[page] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("\(language.text("공부 방법", "How learning works")) · \(page + 1)/\(topics.count)")
                    .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                    .accessibilityIdentifier("guide-page-count")
                Text(topic.title.text(in: language))
                    .font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("guide-topic-\(topic.id)")
                ForEach(Array(topic.paragraphs.enumerated()), id: \.offset) { index, paragraph in
                    Text(paragraph.text(in: language))
                        .font(GT.body(18)).foregroundStyle(GT.onFelt)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("guide-\(topic.id)-paragraph-\(index)")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text("용어 찾아보기", "Look up the terms"))
                        .font(GT.semibold(14)).foregroundStyle(GT.onFeltSecondary)
                    ForEach(topic.termIDs, id: \.self) { term in
                        GlossaryChip(term: term)
                            .accessibilityIdentifier("guide-term-\(term)")
                    }
                }
                .accessibilityIdentifier("guide-topic-terms")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtContentEdge()
            .id(page)
        }
        .accessibilityIdentifier("guide-content")
        .simultaneousGesture(DragGesture().onEnded { gesture in
            if gesture.startLocation.x < 24, gesture.translation.width > 70, page > 0 { page -= 1 }
        })
        .background(FeltBackground())
        .safeAreaInset(edge: .bottom) {
            GTStepRow(previous: page > 0 ? { page -= 1 } : nil, previousID: "guide-previous") {
                PrimaryCTAButton(title: page == topics.count - 1
                                 ? language.text("닫기", "Done") : language.text("다음 이야기", "Next topic")) {
                    if page == topics.count - 1 { dismiss() }
                    else { page += 1 }
                }
                .accessibilityIdentifier("guide-next")
            }
            .padding(.horizontal, GT.Space.sheet).padding(.vertical, 12).background(GT.felt)
        }
        .gtChrome(leading: {
            ChromeButton.close { dismiss() }.accessibilityIdentifier("guide-close")
        })
        .gtSheetSurface()
        .onAppear {
            #if DEBUG
            if let requested = ProcessInfo.processInfo.environment["GT_DEMO_GUIDE_PAGE"].flatMap(Int.init) {
                page = min(max(requested, 0), topics.count - 1)
            }
            #endif
        }
    }
}
