// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Three tabs, icon + label (spec §9). 오늘 is home; 길 and 기록 are one tap away.
/// Free play is never a tab — it lives under 길.
enum Tab: Hashable { case path, today, records }

struct RootView: View {
    @State private var model = ProgressionModel()
    @State private var tab: Tab = .today
    @State private var openNode: CurriculumNode?
    @State private var showFreePlay = false
    @State private var showSettings = false

    var body: some View {
        Group {
            if model.unreadable != nil {
                // Spec §8.2: a store that exists but will not parse must never be
                // silently replaced with empty progress.
                StoreRecoveryView()
            } else {
                tabs
            }
        }
        .environment(model)
        .tint(GT.onFelt)
    }


    private var tabs: some View {
        TabView(selection: $tab) {
            NavigationStack {
                PathView(onOpenNode: { openNode = $0 },
                         onOpenFreePlay: { showFreePlay = true })
                    .modifier(RootChrome(showSettings: $showSettings))
            }
            .tabItem { Label("길", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
            .tag(Tab.path)

            NavigationStack {
                TodayView(onOpenNode: { openNode = $0 },
                          onOpenReview: { tab = .path })
                    .modifier(RootChrome(showSettings: $showSettings))
            }
            .tabItem { Label("오늘", systemImage: "target") }
            .tag(Tab.today)

            NavigationStack {
                RecordsView()
                    .modifier(RootChrome(showSettings: $showSettings))
            }
            .tabItem { Label("기록", systemImage: "chart.bar.fill") }
            .tag(Tab.records)
        }
        .sheet(item: $openNode) { node in
            NavigationStack { NodeSessionView(node: node) }
                .environment(model)
        }
        .sheet(isPresented: $showFreePlay) {
            NavigationStack { FreePlayView() }.environment(model)
        }
        .onAppear {
            #if DEBUG
            // Screenshot hooks, same pattern as M1's GT_DEMO_*: synthetic taps never
            // reach Simulator content, so any screen past the first tab is otherwise
            // unverifiable (spec §10.6).
            //   GT_DEMO_TAB=path|today|records
            //   GT_DEMO_NODE=<node id>   opens that node's session
            //   GT_DEMO_FREEPLAY=1
            let env = ProcessInfo.processInfo.environment
            switch env["GT_DEMO_TAB"] {
            case "path": tab = .path
            case "records": tab = .records
            case "today": tab = .today
            default: break
            }
            if let id = env["GT_DEMO_NODE"] { openNode = Curriculum.node(id: id) }
            if env["GT_DEMO_FREEPLAY"] != nil { showFreePlay = true }
            #endif
        }
    }
}

/// Shared toolbar so every tab reaches 설정 without three copies of the button.
private struct RootChrome: ViewModifier {
    @Binding var showSettings: Bool
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GT.onFelt)
                    }
                    .accessibilityLabel("설정")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
    }
}

/// Spec §8.2. The bytes are preserved either way — recovery is the user's choice,
/// never a silent reset.
struct StoreRecoveryView: View {
    @Environment(ProgressionModel.self) private var model
    @State private var importing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("기록을 열 수 없어요").font(GT.title(20)).foregroundStyle(GT.onFelt)
            Text("저장된 파일이 손상됐어요. 파일은 지우지 않고 그대로 두었어요. "
                 + "백업이 있으면 불러오고, 없으면 새로 시작할 수 있어요.")
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
            FeltCTAButton(title: "백업 불러오기") { importing = true }
            Button("새로 시작하기") { model.discardUnreadableStore() }
                .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FeltBackground())
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            guard case let .success(url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) { try? model.importData(data) }
        }
    }
}
