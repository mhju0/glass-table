// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

enum DrillKind: String, CaseIterable {
    case outs, potodds, callfold, mdf, blockers

    var name: String {
        switch self {
        case .outs: return "아웃 카운팅"
        case .potodds: return "팟 오즈"
        case .callfold: return "콜/폴드"
        case .mdf: return "MDF"
        case .blockers: return "블로커"
        }
    }
    /// English pair for learning-critical concept terms (glossary rule 3); nil where
    /// the name is an action (콜/폴드) or already Latin (MDF).
    var nameEn: String? {
        switch self {
        case .outs: return "Outs"
        case .potodds: return "Pot Odds"
        case .blockers: return "Blockers"
        case .callfold, .mdf: return nil
        }
    }
    var subtitle: String {
        switch self {
        case .outs: return "리버에서 몇 장이면 이기나"
        case .potodds: return "콜에 필요한 에퀴티"
        case .callfold: return "가격 대비 콜/폴드 판단"
        case .mdf: return "최소 방어 빈도"
        case .blockers: return "남은 콤보 세기"
        }
    }
}

struct HomeView: View {
    @State private var path: [DrillKind] = []
    @State private var progress: [DrillKind: DrillProgress] = [:]
    @State private var showStats = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Glass Table").font(GT.title(24)).foregroundStyle(GT.ink)
                        Spacer()
                        Button { showStats = true } label: {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(GT.inkSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 12)
                    Text("레인지와 EV로 생각하는 홀덤 훈련")
                        .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                        .padding(.bottom, 8)
                    ForEach(DrillKind.allCases, id: \.self, content: row)
                }
                .padding(.horizontal, 18)
            }
            .background(Color.white)
            .navigationDestination(for: DrillKind.self, destination: drillView)
            .navigationDestination(isPresented: $showStats) { StatsView() }
            .onAppear {
                for k in DrillKind.allCases {
                    progress[k] = ProgressStore.standard(drill: k.rawValue).load()
                }
                #if DEBUG
                let env = ProcessInfo.processInfo.environment
                if let slug = env["GT_DEMO_DRILL"],
                   let kind = DrillKind(rawValue: slug), path.isEmpty {
                    path = [kind]
                }
                if env["GT_DEMO_STATS"] != nil { showStats = true }
                #endif
            }
        }
        .tint(.white)  // white back chevron over the green drill zone
    }

    private func row(_ kind: DrillKind) -> some View {
        NavigationLink(value: kind) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(kind.name).font(GT.title(15)).foregroundStyle(GT.ink)
                        if let en = kind.nameEn {
                            Text("· \(en)").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        }
                    }
                    Text(kind.subtitle).font(GT.body(12)).foregroundStyle(GT.inkMuted)
                }
                Spacer()
                if let p = progress[kind], p.total > 0 {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("🔥 \(p.streak)").font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                        Text("\(Int(p.accuracy * 100))%").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(GT.inkMuted)
            }
            .padding(16)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func drillView(_ kind: DrillKind) -> some View {
        switch kind {
        case .outs: OutsDrillView()
        case .potodds: PercentDrillView(config: .potOdds)
        case .callfold: CallFoldView()
        case .mdf: PercentDrillView(config: .mdf)
        case .blockers: BlockerView()
        }
    }
}

#Preview { HomeView() }
