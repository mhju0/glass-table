// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private static let privacyURL =
        URL(string: "https://mhju0.github.io/glass-table/privacy-policy.html")!
    private static let feedbackURL =
        URL(string: "mailto:michaelju0418@gmail.com?subject=Glass%20Table%20%ED%94%BC%EB%93%9C%EB%B0%B1")!
    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("설정").font(GT.title(26)).foregroundStyle(GT.onFelt)
                    .padding(.top, 20)
                VStack(spacing: 0) {
                    NavigationLink { GlossaryView() } label: {
                        row("book.fill", "용어집", "포커 용어 한국어·영어 정리", chevron: true)
                    }
                    .buttonStyle(GTPress())
                    // 통계 and 첫 핸드 are gone. StatsView read the M1 per-drill stores
                    // that nothing writes any more, and 첫 핸드 is superseded by first
                    // run — 천천히 replays any concept's walkthrough on demand instead.
                }
                .gtCard(radius: 20)
                VStack(spacing: 0) {
                    Link(destination: Self.feedbackURL) {
                        row("envelope.fill", "피드백 보내기", "버그·아이디어를 메일로",
                            chevron: false, external: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
                    Link(destination: Self.privacyURL) {
                        // arrow.up.right = leaves the app (Safari), unlike chevron rows.
                        row("doc.text", "개인정보 처리방침", nil, chevron: false, external: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
                    HStack(spacing: 14) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GT.green).frame(width: 28)
                        Text("버전").font(GT.semibold(15)).foregroundStyle(GT.ink)
                        Spacer()
                        Text(version).font(GT.body(14)).foregroundStyle(GT.inkMuted)
                            .monospacedDigit()
                    }
                    .padding(16)
                }
                .gtCard(radius: 20)
            }
            .padding(.horizontal, 18)
        }
        .background(FeltBackground())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("닫기") { dismiss() }
                    .font(GT.semibold(15)).foregroundStyle(GT.onFelt)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func row(_ icon: String, _ title: String, _ sub: String?,
                     chevron: Bool, external: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(GT.green).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(GT.semibold(15)).foregroundStyle(GT.ink)
                if let sub { Text(sub).font(GT.body(12)).foregroundStyle(GT.inkMuted) }
            }
            Spacer()
            if chevron || external {
                Image(systemName: external ? "arrow.up.right" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GT.inkMuted)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

#Preview { NavigationStack { SettingsView() } }
