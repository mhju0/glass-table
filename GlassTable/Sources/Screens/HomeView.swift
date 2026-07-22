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

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Glass Table").font(GT.title(24)).foregroundStyle(GT.ink)
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
            .onAppear {
                for k in DrillKind.allCases {
                    progress[k] = ProgressStore.standard(drill: k.rawValue).load()
                }
                #if DEBUG
                if let slug = ProcessInfo.processInfo.environment["GT_DEMO_DRILL"],
                   let kind = DrillKind(rawValue: slug), path.isEmpty {
                    path = [kind]
                }
                #endif
            }
        }
        .tint(.white)  // white back chevron over the green drill zone
    }

    private func row(_ kind: DrillKind) -> some View {
        NavigationLink(value: kind) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.name).font(GT.title(15)).foregroundStyle(GT.ink)
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
