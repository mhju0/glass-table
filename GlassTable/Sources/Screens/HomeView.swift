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
    /// One-line beginner explanation shown on the home box.
    var explain: String {
        switch self {
        case .outs: return "이기는 카드를 세고 룰 오브 2/4로 에퀴티 추정"
        case .potodds: return "콜 가격을 필요 에퀴티 %로 바꾸기"
        case .callfold: return "에퀴티와 가격을 비교해 콜/폴드 결정"
        case .mdf: return "벳 사이즈에 맞는 최소 방어 빈도 계산"
        case .blockers: return "블로커로 남은 콤보 세기"
        }
    }
    var glyph: String {
        switch self {
        case .outs: return "suit.spade.fill"
        case .potodds: return "percent"
        case .callfold: return "arrow.left.arrow.right"
        case .mdf: return "shield.fill"
        case .blockers: return "square.grid.2x2.fill"
        }
    }
}

struct HomeView: View {
    @State private var path: [DrillKind] = []
    @State private var progress: [DrillKind: DrillProgress] = [:]
    @State private var showSettings = false
    @State private var showGuide = false
    // showStats/showGlossary exist only for the DEBUG screenshot hooks below;
    // the user path to those screens is Settings.
    @State private var showStats = false
    @State private var showGlossary = false
    @AppStorage("gt.seen_guide") private var seenGuide = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    masthead
                    guidePill
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible())], spacing: 12) {
                        ForEach(DrillKind.allCases, id: \.self, content: box)
                    }
                }
                .padding(.horizontal, 18)
            }
            .background(FeltBackground())
            .navigationDestination(for: DrillKind.self, destination: drillView)
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(isPresented: $showGuide) { GuideView() }
            .navigationDestination(isPresented: $showStats) { StatsView() }
            .navigationDestination(isPresented: $showGlossary) { GlossaryView() }
            .onAppear {
                for k in DrillKind.allCases {
                    progress[k] = ProgressStore.standard(drill: k.rawValue).load()
                }
                var demoRun = false
                #if DEBUG
                let env = ProcessInfo.processInfo.environment
                demoRun = env.keys.contains { $0.hasPrefix("GT_DEMO") }
                if let slug = env["GT_DEMO_DRILL"],
                   let kind = DrillKind(rawValue: slug), path.isEmpty {
                    path = [kind]
                }
                if env["GT_DEMO_STATS"] != nil { showStats = true }
                if env["GT_DEMO_GLOSSARY"] != nil { showGlossary = true }
                if env["GT_DEMO_SETTINGS"] != nil { showSettings = true }
                if env["GT_DEMO_GUIDE"] != nil { showGuide = true }
                #endif
                // First launch opens the guide once (never during screenshot runs —
                // GT_DEMO_HOME suppresses without other effects).
                if !seenGuide, !demoRun {
                    seenGuide = true
                    showGuide = true
                }
            }
        }
        .tint(.white)  // white back chevron over the green zones
    }

    private var suitRule: some View {
        HStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { i in
                Image(systemName: ["suit.spade.fill", "suit.heart.fill",
                                   "suit.diamond.fill", "suit.club.fill"][i % 4])
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 0) {
            suitRule
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Glass Table")
                        .font(.system(size: 36, weight: .heavy, design: .serif).italic())
                        .foregroundStyle(.white)
                    Text("레인지와 EV로 생각하는 홀덤 훈련")
                        .font(GT.body(14)).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(GTPress())
                .accessibilityLabel("설정")
            }
            .padding(.vertical, 20)
            suitRule
        }
        .padding(.top, 24)
    }

    private var guidePill: some View {
        Button { showGuide = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "book.fill").font(.system(size: 13))
                Text("처음이신가요? · 3분 시작 가이드").font(GT.semibold(13))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(.white.opacity(0.14), in: Capsule())
        }
        .buttonStyle(GTPress())
        .padding(.bottom, 4)
    }

    private func box(_ kind: DrillKind) -> some View {
        NavigationLink(value: kind) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: kind.glyph)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(GT.green)
                        .frame(width: 34, height: 34)
                        .background(GT.green.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 10))
                    Text(kind.name).font(GT.title(15)).foregroundStyle(GT.ink)
                    Text(kind.explain).font(GT.body(12))
                        .foregroundStyle(GT.inkSecondary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                // Same rule as the drill header: 🔥 appears only with a live streak.
                if let p = progress[kind], p.streak > 0 {
                    Text("🔥 \(p.streak)").font(GT.semibold(11))
                        .foregroundStyle(GT.inkSecondary)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(GT.surface, in: Capsule())
                        .padding(10)
                }
            }
            .frame(minHeight: 150)
            .background(.white, in: RoundedRectangle(cornerRadius: 19))
            .padding(5)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color(hex: 0x06301C).opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(GTPress())
        .accessibilityLabel("\(kind.name). \(kind.explain)")
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
