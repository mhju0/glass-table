// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Per-drill progress read from the same per-drill stores the drills write.
struct StatsView: View {
    @State private var progress: [DrillKind: DrillProgress] = [:]

    private var totals: (answered: Int, correct: Int) {
        progress.values.reduce((0, 0)) { ($0.0 + $1.total, $0.1 + $1.correct) }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(GT.title(26)).foregroundStyle(.white)
            Text(label).font(GT.semibold(11)).foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ kind: DrillKind) -> some View {
        let p = progress[kind] ?? DrillProgress()
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(kind.name).font(GT.title(14)).foregroundStyle(GT.ink)
                    if let en = kind.nameEn {
                        Text("· \(en)").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                    }
                }
                Text(p.total == 0 ? "아직 기록 없음" : "\(p.total)문제 풀이")
                    .font(GT.body(12)).foregroundStyle(GT.inkMuted)
            }
            Spacer()
            if p.total > 0 {
                Text("🔥 \(p.streak)").font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                Text("\(Int(p.accuracy * 100))%").font(GT.title(15)).foregroundStyle(GT.green)
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
        .padding(.vertical, 13)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("통계").font(GT.title(16)).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 6)

            let t = totals
            HStack(spacing: 0) {
                stat("\(t.answered)", "푼 문제")
                stat(t.answered == 0 ? "—" : "\(Int(Double(t.correct) / Double(t.answered) * 100))%",
                     "정확 비율")
                stat("\(progress.values.map(\.streak).max() ?? 0)", "현재 최고 스트릭")
            }
            .padding(.horizontal, 18).padding(.vertical, 24)

            VStack(spacing: 0) {
                ForEach(DrillKind.allCases, id: \.self) { kind in
                    row(kind)
                    if kind != DrillKind.allCases.last { Divider() }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18).padding(.top, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                    .fill(.white).ignoresSafeArea(edges: .bottom))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GT.green.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            for k in DrillKind.allCases {
                progress[k] = ProgressStore.standard(drill: k.rawValue).load()
            }
        }
    }
}

#Preview { NavigationStack { StatsView() } }
