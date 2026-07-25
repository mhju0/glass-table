// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// The app-wide loop layout: a green content zone on top, a white action sheet on the
/// bottom. Every drill/reveal screen composes this so the app feels like one system.
struct DrillScaffold<Content: View, Sheet: View>: View {
    let title: String
    /// One verb line answering "what does this drill train" — shown on *every* visit,
    /// which is why the starter guide no longer has to say it once and hope.
    let subtitle: String?
    let streak: Int
    let content: Content
    let sheet: Sheet

    init(title: String, subtitle: String? = nil, streak: Int,
         @ViewBuilder content: () -> Content,
         @ViewBuilder sheet: () -> Sheet) {
        self.title = title; self.subtitle = subtitle; self.streak = streak
        self.content = content(); self.sheet = sheet()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(GT.title(16)).foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle).font(GT.body(11.5))
                            .foregroundStyle(.white.opacity(0.66))
                    }
                }
                Spacer()
                // Same rule as home boxes: 🔥 appears only with a live streak.
                if streak > 0 {
                    Text("🔥 \(streak)").font(GT.semibold(12).monospacedDigit()).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.white.opacity(0.16), in: Capsule())
                }
            }
            // With a subtitle the header ends in small grey text, and so does the first
            // SectionLabel under it — they need separating.
            .padding(.horizontal, 18).padding(.top, 8)
            .padding(.bottom, subtitle == nil ? 6 : 13)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)

            Spacer(minLength: 12)

            sheet
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(.white)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GT.green.ignoresSafeArea())
    }
}
