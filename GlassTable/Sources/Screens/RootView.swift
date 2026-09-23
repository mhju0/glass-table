// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

enum Tab: Hashable { case learn, play, progress, settings }

struct RootView: View {
    @Environment(\.learningLanguage) private var language
    @State private var model = ProgressionModel()
    @State private var tab: Tab = .learn
    @State private var openNode: CurriculumNode?
    @State private var showFreePlay = false
    @State private var showReview = false
    @State private var showPath = false
    @State private var showPlacement = false

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_CARD_DECK"] != nil {
                PlayingCardDeckSpecimen()
            } else {
                rootContent
            }
            #else
            rootContent
            #endif
        }
        .environment(model)
        .tint(GT.onFelt)
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
            if model.unreadable != nil {
                // Spec §8.2: a store that exists but will not parse must never be
                // silently replaced with empty progress.
                StoreRecoveryView()
            } else if model.shouldPresentFirstLesson {
                FirstLessonView(context: .firstRun,
                                onFinish: {
                                    model.completeFirstLesson()
                                    openNode = model.nextNode
                                },
                                onSkip: { model.completeFirstLesson() })
            } else {
                tabs
            }
        }
    }


    private var tabs: some View {
        TabView(selection: $tab) {
            NavigationStack {
                LearnView(onOpenNode: { openNode = $0 },
                          onOpenReview: { showReview = true },
                          onOpenPractice: { showFreePlay = true })
                    .modifier(ProgressSaveNotice())
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(language.text("배우기", "Learn"), systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
            .tag(Tab.learn)

            NavigationStack {
                PlayView()
                    .modifier(ProgressSaveNotice())
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(language.text("플레이", "Play"), systemImage: "suit.spade.fill") }
            .tag(Tab.play)

            NavigationStack {
                RecordsView()
                    .modifier(ProgressSaveNotice())
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(language.text("기록", "Progress"), systemImage: "chart.bar.fill") }
            .tag(Tab.progress)

            NavigationStack {
                SettingsView()
                    .modifier(ProgressSaveNotice())
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(language.text("설정", "Settings"), systemImage: "gearshape.fill") }
            .tag(Tab.settings)
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
        // Snapshot the five most-overdue concepts and ask one question for each.
        .sheet(isPresented: $showReview) {
            NavigationStack {
                ReviewSessionView().modifier(ProgressSaveNotice())
            }
            .environment(model)
        }
        .sheet(isPresented: $showPath) {
            NavigationStack {
                PathView(onOpenNode: { showPath = false; openNode = $0 },
                         onOpenFreePlay: { showPath = false; showFreePlay = true })
                    .gtChrome(.topBarLeading) { ChromeButton.close { showPath = false } }
            }
        }
        .sheet(isPresented: $showPlacement) { NavigationStack { PlacementView() } }
        .onAppear {
            #if DEBUG
            // Screenshot hooks, same pattern as M1's GT_DEMO_*: synthetic taps never
            // reach Simulator content, so any screen past the first tab is otherwise
            // unverifiable (spec §10.6).
            //   GT_DEMO_TAB=path|today|records|settings
            //   GT_DEMO_NODE=<node id>   opens that node's session
            //   GT_DEMO_FREEPLAY=1 · GT_DEMO_SETTINGS=1
            let env = ProcessInfo.processInfo.environment
            switch env["GT_DEMO_TAB"] {
            case "path", "today", "learn": tab = .learn
            case "records", "progress": tab = .progress
            case "table", "play": tab = .play
            case "settings": tab = .settings
            default: break
            }
            if env["GT_DEMO_TABLE"] != nil { tab = .play }
            if env["GT_DEMO_REPLAY"] != nil { tab = .progress }
            if let id = env["GT_DEMO_NODE"] { openNode = Curriculum.node(id: id) }
            if env["GT_DEMO_FREEPLAY"] != nil { showFreePlay = true }
            if let raw = env["GT_DEMO_CONCEPT"], let concept = Concept(rawValue: raw) {
                if model.state.activeRound == nil {
                    _ = model.beginRound(concept: concept, seed: 0x6AA,
                                         expectedEpoch: model.epoch)
                    if let round = model.state.activeRound, round.introPhase != nil {
                        _ = model.advanceRoundIntroduction(roundID: round.id, skip: true,
                                                          expectedEpoch: model.epoch)
                    }
                }
                showFreePlay = true
            }
            if env["GT_DEMO_REVIEW"] != nil { showReview = true }
            if env["GT_DEMO_SETTINGS"] != nil { tab = .settings }
            if env["GT_DEMO_TAB"] == "path" { showPath = true }
            if env["GT_DEMO_PLACEMENT"] != nil { showPlacement = true }
            #endif
        }
    }
}

/// Spec §8.2. The bytes are preserved either way — recovery is the user's choice,
/// never a silent reset.
struct StoreRecoveryView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @State private var importing = false
    @State private var fileFailure: ProgressFileFailure?
    @State private var importTask: Task<Void, Never>?
    @State private var importRequestID: UUID?
    @State private var isReadingImport = false

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
            Text(language.text("기록을 열 수 없어요", "Your progress could not be opened")).font(GT.title(20)).foregroundStyle(GT.onFelt)
            Text(language.text("저장된 파일을 읽을 수 없거나 더 새로운 앱 버전이 필요해요. 파일은 그대로 두었어요. 백업이 있으면 불러오고, 없으면 원본 파일을 보관한 뒤 새로 시작할 수 있어요.", "The file could not be read, or it needs a newer app. Your original file is unchanged. Import a backup, or keep a copy of the original before starting again."))
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
            FeltCTAButton(title: isReadingImport ? language.text("파일 확인 중", "Checking file") : language.text("백업 불러오기", "Import backup")) {
                importing = true
            }
            .disabled(isReadingImport)
            if let source = model.recoveryFileURL {
                ShareLink(item: source) {
                    Label(language.text("원본 파일 내보내기", "Export original file"), systemImage: "square.and.arrow.up")
                        .font(GT.semibold(13))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .foregroundStyle(GT.onFelt)
            }
            Button(language.text("새로 시작하기", "Start again")) {
                do { try model.resetProgress() }
                catch { fileFailure = .reset }
            }
                .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(isReadingImport)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
        .background(FeltBackground())
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case let .success(url):
                readImport(url)
            case let .failure(error):
                if !ProgressFileFailure.isCancellation(error) {
                    fileFailure = .read
                }
            }
        }
        .alert(item: $fileFailure) { failure in
            Alert(title: Text(language.text("기록 파일을 처리하지 못했어요", "The progress file could not be processed")), message: Text(failure.message(in: language)),
                  dismissButton: .default(Text(language.text("확인", "OK"))))
        }
        .onDisappear {
            importRequestID = nil
            importTask?.cancel()
            importTask = nil
        }
    }

    private func readImport(_ url: URL) {
        importTask?.cancel()
        let requestID = UUID()
        importRequestID = requestID
        isReadingImport = true
        let expectedEpoch = model.epoch
        let expectedRevision = model.state.revision
        importTask = Task {
            do {
                let prepared = try await ProgressFileReader.readAndValidate(
                    url, expectedEpoch: expectedEpoch, expectedRevision: expectedRevision)
                guard importRequestID == requestID else { return }
                try model.importPrepared(prepared)
            } catch {
                guard importRequestID == requestID,
                      !ProgressFileFailure.isCancellation(error) else { return }
                fileFailure = error is StoreError ? .importing(error) : .read
            }
            guard importRequestID == requestID else { return }
            isReadingImport = false
            importTask = nil
        }
    }
}
