// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// The image a learner can share after a milestone. It shows what they learned and
/// when, never chips, scores or money. Fixed table colors and text size, so the image
/// looks the same whatever the phone's appearance or text setting.
struct MilestoneCardView: View {
    let milestone: LearningMilestone
    let date: Date
    let language: LearningLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "suit.spade.fill").font(.system(size: 18))
                Text("Glass Table").font(GT.title(18))
            }
            .foregroundStyle(GT.onTableSecondary)
            Spacer(minLength: 24)
            Text(milestone.kind(in: language))
                .font(GT.semibold(17)).foregroundStyle(GT.tableAccent)
            Text(milestone.title(in: language))
                .font(GT.title(34)).foregroundStyle(GT.onTable)
                .lineLimit(3).minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            Text(milestone.detail(in: language))
                .font(GT.body(17)).foregroundStyle(GT.onTableSecondary)
                .padding(.top, 10)
            Spacer(minLength: 24)
            Text(date.formatted(.dateTime.year().month().day()
                .locale(Locale(identifier: language == .korean ? "ko_KR" : "en_US"))))
                .font(GT.body(15)).foregroundStyle(GT.onTableMuted)
        }
        .padding(32)
        .frame(width: 360, height: 360, alignment: .leading)
        .background(
            ZStack(alignment: .bottomTrailing) {
                GT.tableFelt
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 220))
                    .foregroundStyle(GT.onTable.opacity(0.05))
                    .rotationEffect(.degrees(-12))
                    .offset(x: 50, y: 50)
            }
        )
        .clipped()
        .environment(\.dynamicTypeSize, .large)
    }

    @MainActor
    static func render(_ milestone: LearningMilestone, date: Date,
                       language: LearningLanguage) -> UIImage? {
        let renderer = ImageRenderer(content: MilestoneCardView(
            milestone: milestone, date: date, language: language))
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// A preview of the card with a share button, for the lesson summary.
struct MilestoneShareSection: View {
    @Environment(\.learningLanguage) private var language
    let milestone: LearningMilestone
    let date: Date
    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(maxWidth: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("\(milestone.kind(in: language)): \(milestone.title(in: language))")
                ShareLink(item: Image(uiImage: image),
                          preview: SharePreview(milestone.title(in: language),
                                                image: Image(uiImage: image))) {
                    Label(language.text("공유하기", "Share"), systemImage: "square.and.arrow.up")
                        .font(GT.semibold(15)).foregroundStyle(GT.onFelt)
                        .padding(.horizontal, 16).frame(minHeight: 44)
                        .overlay(Capsule().stroke(GT.hairlineFelt))
                }
                .accessibilityIdentifier("milestone-share")
            }
        }
        .task(id: language) { image = MilestoneCardView.render(milestone, date: date, language: language) }
    }
}
