// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

enum Tab: Hashable { case learn, play, progress, settings }

struct RootView: View {
    @State private var languageSettings = LanguageSettings()
    @State private var model = ProgressionModel()
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system
    @State private var tab: Tab = .learn
    @State private var showFreePlay = false
    @State private var showReview = false
    /// The skill a passed lesson's "연습" opens straight into.
    @State private var practiceConcept: Concept?
    @State private var showPlacement = false
    @State private var journey = BeginnerJourney()
    @State private var pendingOpeningFinishEpoch: UUID?
    @State private var pendingOpeningFinishResumed = false
    @State private var homeIndicatorInset: CGFloat = 0

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
        .onChange(of: model.saveError) { previous, current in
            if previous != nil, current == nil { routeSavedOpeningFinish() }
        }
        .onChange(of: model.epoch) { _, _ in pendingOpeningFinishEpoch = nil }
        .preferredColorScheme(model.isShowingBrandWelcome ? .dark : appearance.colorScheme)
        .environment(model)
        .environment(languageSettings)
        .environment(\.learningLanguage, language)
        .environment(\.locale, Locale(identifier: language.rawValue))
        .environment(\.simpleQuestions, level != .playRegularly)
        .environment(\.homeIndicatorInset, homeIndicatorInset)
        .tint(GT.onFelt)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom.rounded() } action: {
            homeIndicatorInset = $0
        }
    }

    private var language: LearningLanguage { languageSettings.resolved }

    private var level: PlacementSelfReport {
        #if DEBUG
        // GT_DEMO_LEVEL=newToPoker|knowRules|playRegularly shows a level's screens
        // without writing a starting check into the test store.
        if let raw = ProcessInfo.processInfo.environment["GT_DEMO_LEVEL"],
           let level = PlacementSelfReport(rawValue: raw) { return level }
        #endif
        return model.state.level
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
                                onFinish: { finishOpening() },
                                onSkip: {
                                    if model.state.openingDismissed != true { _ = model.dismissFirstLesson(expectedEpoch: model.epoch) }
                                })
            } else {
                tabs
            }
        }
    }


    private func finishOpening(resumed: Bool = false) {
        pendingOpeningFinishEpoch = model.epoch
        pendingOpeningFinishResumed = resumed
        if model.completeFirstLesson(expectedEpoch: model.epoch) { routeSavedOpeningFinish() }
        else if model.saveError == nil { pendingOpeningFinishEpoch = nil }
    }

    private func routeSavedOpeningFinish() {
        guard pendingOpeningFinishEpoch == model.epoch,
              model.saveError == nil,
              model.state.firstLessonCompleted == true,
              model.state.pendingFirstLesson == nil else { return }
        pendingOpeningFinishEpoch = nil
        let next: BeginnerJourney.Step? = model.state.basicsLessonCompleted == true
            ? model.nextNode.map { .lesson($0) } : .basics
        if pendingOpeningFinishResumed { journey.close(then: next) }
        else if let next { journey.present(next) }
    }

    /// A cover or sheet shown while the journey presents a matching step. A system
    /// dismissal (a swipe) closes the step without opening anything after it.
    private func showing(_ matches: @escaping (BeginnerJourney.Step) -> Bool) -> Binding<Bool> {
        Binding(get: { journey.presented.map(matches) ?? false },
                set: { if !$0, let shown = journey.presented, matches(shown) { journey.close(ifShowing: shown) } })
    }

    private var shownLesson: Binding<CurriculumNode?> {
        Binding(get: { if case let .lesson(node)? = journey.presented { node } else { nil } },
                set: { if $0 == nil, case let .lesson(node)? = journey.presented { journey.close(ifShowing: .lesson(node)) } })
    }

    /// An item binding keeps the sheet's content stable while it slides away.
    private var shownInvitation: Binding<GuidedHandOffer?> {
        Binding(get: { if case let .invitation(node)? = journey.presented { GuidedHandOffer(lessonAfter: node) } else { nil } },
                set: { if $0 == nil, case let .invitation(node)? = journey.presented { journey.close(ifShowing: .invitation(lessonAfter: node)) } })
    }

    private func afterDismiss() {
        if journey.didDismiss() == .play { tab = .play }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            NavigationStack {
                LearnView(onOpenNode: { journey.present(.lesson($0)) },
                          onOpenReview: { showReview = true },
                          onOpenPractice: { practiceConcept = $0 },
                          onChoosePractice: { showFreePlay = true },
                          onOpenBasics: { journey.present(.basics) },
                          onOpenGuidedHand: { journey.present(.guidedHand) },
                          onResumeOpening: { journey.present(.opening) })
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
                RecordsView(onContinue: { tab = .learn }, onOpenReview: { showReview = true })
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
        // Activities take the whole screen and leave only through their Close control;
        // each session saves its place, so closing never loses an answer.
        .fullScreenCover(isPresented: showing { $0 == .opening }, onDismiss: afterDismiss) {
            FirstLessonView(context: .resume, onFinish: { finishOpening(resumed: true) }, onSkip: {
                if model.state.openingDismissed == true || model.dismissFirstLesson(expectedEpoch: model.epoch) { journey.close(ifShowing: .opening) }
            })
        }
        .fullScreenCover(item: shownLesson, onDismiss: afterDismiss) { node in
            NavigationStack {
                NodeSessionView(node: node, onOpenLesson: { journey.present(.lesson($0)) }).modifier(ProgressSaveNotice())
            }.environment(model)
        }
        .fullScreenCover(isPresented: showing { $0 == .basics }, onDismiss: afterDismiss) {
            HoldemBasicsView(onClose: { journey.close(ifShowing: .basics) },
                             onFinish: { startNext in
                                 model.completeBasicsLesson()
                                 journey.close(then: .invitation(lessonAfter: startNext ? model.nextNode : nil))
                             })
                .modifier(ProgressSaveNotice())
                .environment(model)
        }
        // Only an explicit choice moves on; swiping the sheet away just closes it.
        .sheet(item: shownInvitation, onDismiss: afterDismiss) { offer in
            GuidedHandInvitationView(continuesLessons: offer.lessonAfter != nil, onHand: {
                journey.close(then: .guidedHand)
            }, onContinue: {
                journey.close(then: offer.lessonAfter.map { .lesson($0) })
            })
        }
        .fullScreenCover(isPresented: showing { $0 == .guidedHand }, onDismiss: afterDismiss) {
            GuidedHandView(onClose: { journey.close(ifShowing: .guidedHand) }, onPlay: {
                journey.close(then: .play)
            })
        }
        .fullScreenCover(isPresented: $showFreePlay) {
            NavigationStack {
                FreePlayView().modifier(ProgressSaveNotice())
            }.environment(model)
        }
        .fullScreenCover(item: $practiceConcept) { concept in
            NavigationStack {
                FreePlayView(startConcept: concept).modifier(ProgressSaveNotice())
            }.environment(model)
        }
        // Snapshot the five most-overdue concepts and ask one question for each.
        .fullScreenCover(isPresented: $showReview) {
            NavigationStack {
                ReviewSessionView().modifier(ProgressSaveNotice())
            }
            .environment(model)
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
            if let id = env["GT_DEMO_NODE"], let node = Curriculum.node(id: id) { journey.present(.lesson(node)) }
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
            if env["GT_DEMO_PLACEMENT"] != nil { showPlacement = true }
            if env["GT_DEMO_BASICS"] != nil { journey.present(.basics) }
            if env["GT_DEMO_GUIDED_HAND"] != nil { journey.present(.guidedHand) }
            if env["GT_DEMO_GUIDED_INVITATION"] != nil { journey.present(.invitation(lessonAfter: model.nextNode)) }
            #endif
        }
    }
}

private struct GuidedHandOffer: Identifiable {
    let lessonAfter: CurriculumNode?
    var id: String { lessonAfter?.id ?? "" }
}

private struct GuidedHandInvitationView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    let continuesLessons: Bool
    let onHand: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(language.text("기초를 한 판에 연결해 볼까요?", "Try the basics in a hand"))
                    .font(GT.title(24)).accessibilityIdentifier("guided-hand-invitation")
                Text(language.text("선택 사항이에요. 블라인드부터 카드 공개까지 함께 따라가거나 레슨을 계속할 수 있어요.",
                                   "Optional: follow a hand from blinds to showdown together, or continue your lessons."))
                    .font(GT.body(17)).fixedSize(horizontal: false, vertical: true)
                if textSize.isAccessibilitySize { actions }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GT.Space.sheet)
            // Clear the grabber, so the title does not crowd the top edge.
            .padding(.top, GT.Space.sheet)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Inset by the outline's width so the fill never paints over the side border.
            if !textSize.isAccessibilitySize {
                actions.padding(GT.Space.sheet).background { GT.glass.padding(.horizontal, 1) }
            }
        }
        .presentationDetents(textSize.isAccessibilitySize ? [.large] : [.medium, .large])
        // The same 10pt corners and outline as the app's own panels, one fill throughout.
        .presentationCornerRadius(GT.Radius.panel)
        .presentationBackground {
            RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                .fill(GT.glass)
                .overlay {
                    RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                        .strokeBorder(GT.border, lineWidth: 1)
                }
        }
        .gtSheetSurface()
    }
    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryCTAButton(title: language.text("함께 한 판", "A hand together"), action: onHand)
                .accessibilityIdentifier("guided-hand-invitation-start")
            GTChoiceButton(title: continuesLessons ? language.text("레슨 계속하기", "Continue lessons")
                                                    : language.text("지금은 닫기", "Close for now"),
                           minHeight: 52, action: onContinue)
                .accessibilityIdentifier("guided-hand-invitation-continue")
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
            PrimaryCTAButton(title: isReadingImport ? language.text("파일 확인 중", "Checking file") : language.text("백업 불러오기", "Import backup")) {
                importing = true
            }
            .disabled(isReadingImport)
            if let source = model.recoveryFileURL {
                ShareLink(item: source) {
                    Label(language.text("원본 파일 내보내기", "Export original file"), systemImage: "square.and.arrow.up")
                        .gtOutlinedLabel(fills: true)
                }
            }
            Button(language.text("새로 시작하기", "Start again")) {
                do { try model.resetProgress() }
                catch { fileFailure = .reset }
            }
                .buttonStyle(GTOutlinedAction(fills: true))
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
