// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// The app-wide loop layout: a green content zone on top, a white action sheet on the
/// bottom. Every drill/reveal screen composes this so the app feels like one system.
struct DrillScaffold<Content: View, Sheet: View>: View {
    let title: String
    let streak: Int
    let content: Content
    let sheet: Sheet

    init(title: String, streak: Int,
         @ViewBuilder content: () -> Content,
         @ViewBuilder sheet: () -> Sheet) {
        self.title = title; self.streak = streak
        self.content = content(); self.sheet = sheet()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(GT.title(16)).foregroundStyle(.white)
                Spacer()
                Text("🔥 \(streak)").font(GT.semibold(12)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.white.opacity(0.16), in: Capsule())
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 6)

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
