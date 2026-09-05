// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Four tabs, icon + label. 오늘 is home; 길, 테이블 and 기록 are one tap away.
/// Free play is never a tab — it lives under 길. 테이블 is one (R4-S4): it is the
/// mode Block C promised, a pillar rather than a sub-feature, and burying it under
/// another tab would price it as one.
enum Tab: Hashable { case path, today, table, records }

struct RootView: View {
    @State private var model = ProgressionModel()
    @State private var tab: Tab = .today
    @State private var openNode: CurriculumNode?
    @State private var showFreePlay = false
    @State private var showReview = false
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
                          onOpenReview: { showReview = true })
                    .modifier(RootChrome(showSettings: $showSettings))
            }
            .tabItem { Label("오늘", systemImage: "target") }
            .tag(Tab.today)

            NavigationStack {
                TableView()
                    .modifier(RootChrome(showSettings: $showSettings))
            }
            .tabItem { Label("테이블", systemImage: "suit.spade.fill") }
            .tag(Tab.table)

            NavigationStack {
                RecordsView()
                    .modifier(RootChrome(showSettings: $showSettings))
            }
            .tabItem { Label("기록", systemImage: "chart.bar.fill") }
            .tag(Tab.records)
        }
        .sheet(item: $openNode) { node in
            NavigationStack {
                NodeSessionView(node: node).modifier(ProgressSaveNotice())
            }.environment(model)
        }
        .sheet(isPresented: $showFreePlay) {
            NavigationStack {
                FreePlayView().modifier(ProgressSaveNotice())
            }.environment(model)
        }
        // 오늘's 복습 card used to dump the user on the 길 tab to hunt for the due
        // concepts themselves; this is the same free-play player narrowed to them.
        .sheet(isPresented: $showReview) {
            NavigationStack {
                FreePlayView(title: "복습",
                             blurb: "지금 복습 시점이 된 개념이에요. 몇 문제든 풀면 다음 복습이 뒤로 밀려요.",
                             concepts: model.dueConcepts(),
                             emptyText: "오늘 복습을 다 끝냈어요. 다음 복습은 내일 이후에 돌아와요.")
                    .modifier(ProgressSaveNotice())
            }
            .environment(model)
        }
        // Presented once, here, rather than inside each tab's NavigationStack. The
        // previous version bound one @State into three sibling stacks, so flipping it
        // pushed Settings onto *all three* — switching tabs worked but landed on
        // Settings every time, which read as the tab bar being dead. Presenting it as
        // a sheet also covers the tab bar, which is what a full-screen detail should do.
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView().modifier(ProgressSaveNotice())
            }.environment(model)
        }
        .onAppear {
            #if DEBUG
            // Screenshot hooks, same pattern as M1's GT_DEMO_*: synthetic taps never
            // reach Simulator content, so any screen past the first tab is otherwise
            // unverifiable (spec §10.6).
            //   GT_DEMO_TAB=path|today|records
            //   GT_DEMO_NODE=<node id>   opens that node's session
            //   GT_DEMO_FREEPLAY=1 · GT_DEMO_SETTINGS=1
            let env = ProcessInfo.processInfo.environment
            switch env["GT_DEMO_TAB"] {
            case "path": tab = .path
            case "records": tab = .records
            case "today": tab = .today
            case "table": tab = .table
            default: break
            }
            if env["GT_DEMO_TABLE"] != nil { tab = .table }
            if let id = env["GT_DEMO_NODE"] { openNode = Curriculum.node(id: id) }
            if env["GT_DEMO_FREEPLAY"] != nil { showFreePlay = true }
            if env["GT_DEMO_REVIEW"] != nil { showReview = true }
            if env["GT_DEMO_SETTINGS"] != nil { showSettings = true }
            #endif
        }
    }
}

/// Shared toolbar so every tab reaches 설정 without three copies of the button.
private struct RootChrome: ViewModifier {
    @Binding var showSettings: Bool
    func body(content: Content) -> some View {
        content.modifier(ProgressSaveNotice()).gtChrome(.topBarTrailing) {
            ChromeButton(symbol: "gearshape.fill", spoken: "설정") { showSettings = true }
        }
    }
}

/// Spec §8.2. The bytes are preserved either way — recovery is the user's choice,
/// never a silent reset.
struct StoreRecoveryView: View {
    @Environment(ProgressionModel.self) private var model
    @State private var importing = false
    @State private var fileFailure: ProgressFileFailure?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("기록을 열 수 없어요").font(GT.title(20)).foregroundStyle(GT.onFelt)
            Text("저장된 파일을 읽을 수 없거나 더 새로운 앱 버전이 필요해요. 파일은 그대로 두었어요. "
                 + "백업이 있으면 불러오고, 없으면 새로 시작할 수 있어요.")
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
            FeltCTAButton(title: "백업 불러오기") { importing = true }
            Button("새로 시작하기") {
                do { try model.discardUnreadableStore() }
                catch { fileFailure = .reset }
            }
                .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FeltBackground())
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            guard case let .success(url) = result else {
                fileFailure = .read
                return
            }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data: Data
            do { data = try Data(contentsOf: url) }
            catch { fileFailure = .read; return }
            do { try model.importData(data) }
            catch { fileFailure = .importing(error) }
        }
        .alert(item: $fileFailure) { failure in
            Alert(title: Text("기록 파일을 처리하지 못했어요"), message: Text(failure.message),
                  dismissButton: .default(Text("확인")))
        }
    }
}
