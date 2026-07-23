// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

struct SettingsView: View {
    private static let privacyURL =
        URL(string: "https://mhju0.github.io/glass-table/privacy-policy.html")!
    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("설정").font(GT.title(26)).foregroundStyle(.white)
                    .padding(.top, 20)
                VStack(spacing: 0) {
                    NavigationLink { GlossaryView() } label: {
                        row("book.fill", "용어집", "포커 용어 한국어·영어 정리", chevron: true)
                    }
                    .buttonStyle(GTPress())
                    Divider().padding(.leading, 56)
                    NavigationLink { StatsView() } label: {
                        row("chart.bar.fill", "통계", "드릴별 스트릭과 정답률", chevron: true)
                    }
                    .buttonStyle(GTPress())
                }
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                VStack(spacing: 0) {
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
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 18)
        }
        .background(FeltBackground())
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
