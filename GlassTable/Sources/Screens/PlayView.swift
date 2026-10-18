import SwiftUI
import GlassTableDrills
import GlassTableEngine

struct PlayView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var failure = false
    @State private var epoch: UUID?
    @State private var showSetup = false
    /// The game length setup opens with: the row that was tapped.
    @State private var setupQuick = true
    /// A new table's length, waiting on the learner to end the open one.
    @State private var pendingNewTable: Bool?
    @State private var showStyles = false
    @State private var showGraded = false
    @State private var showTable = false
    @State private var showArchive = false
    /// A table just dealt from setup replays its blinds and the computers' first moves.
    @State private var replayFromStart = false
    /// Leaving a finished table lands on setup, not back here.
    @State private var setupAfterTable = false

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_TABLE"] != nil { TableView() }
            else if ProcessInfo.processInfo.environment["GT_DEMO_PLAY_SETUP"] != nil {
                TableSetupView(epoch: model.epoch)
            }
            else { playContent }
            #else
            playContent
            #endif
        }
    }

    private var stacks: Bool { dynamicTypeSize.isAccessibilitySize }
    private var savedGames: [QuickPlaySession] { model.state.quickPlaySessions.filter { !$0.hands.isEmpty } }

    /// The list in Learn's style (owner, 2026-10-18, P2·A): the open table alone under
    /// "Continue", then the ways to start one, then what can be looked back on.
    private var playContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(language.text("플레이", "Play")).font(GT.title(30))
                    .padding(.bottom, 12)
                if let table = model.state.tableState {
                    sectionHeader(language.text("이어하기", "Continue"))
                    continueRow(table)
                }
                sectionHeader(language.text("새 테이블 시작", "Start a new table"))
                VStack(spacing: 0) {
                    row(title: language.text("빠른 게임", "Quick game"),
                        detail: language.text("각자 \(TableSetupView.quickStack)칩. \(TableSetupView.quickHands)핸드 뒤에 끝나요.",
                                              "\(TableSetupView.quickStack) chips each. Ends after \(TableSetupView.quickHands) hands."),
                        id: "play-quick", open: { startNewTable(quick: true) }) { PlayGlyph(kind: .quick) }
                        .disabled(model.saveError != nil)
                    row(title: language.text("긴 테이블", "Long table"),
                        detail: language.text("각자 100칩. 그만할 때까지 계속해요.", "100 chips each. Keeps going until you stop."),
                        id: "play-long", open: { startNewTable(quick: false) }) { PlayGlyph(kind: .long) }
                        .disabled(model.saveError != nil)
                }
                // The same question the table asks before its own "Start new game".
                .confirmationDialog(language.text("새 게임을 시작할까요?", "Start a new game?"),
                                    isPresented: Binding(get: { pendingNewTable != nil }, set: { if !$0 { pendingNewTable = nil } }),
                                    titleVisibility: .visible, presenting: pendingNewTable) { quick in
                    Button(language.text("새 게임 시작", "Start new game")) {
                        guard let table = model.state.tableState,
                              model.endTable(handID: table.handID, expectedEpoch: epoch ?? model.epoch) else { return }
                        setupQuick = quick
                        showSetup = true
                    }
                    Button(language.text("취소", "Cancel"), role: .cancel) {}
                } message: { _ in
                    Text(model.state.tableState?.street == .finished
                         ? language.text("끝난 빠른 게임 핸드는 기록에 남아요.", "Settled Quick Game hands stay in history.")
                         : language.text("진행 중인 핸드는 버리고, 끝난 빠른 게임 핸드는 기록에 남아요.",
                                         "The unfinished hand will be discarded. Settled Quick Game hands stay in history."))
                }
                row(title: language.text("1:1 채점 연습", "Graded 1:1 practice"),
                    detail: language.text("상대 한 명. 고른 행동이 얼마나 좋았는지 봐요.",
                                          "One opponent. See how good each choice was."),
                    id: "play-graded", open: { showGraded = true }) { PlayGlyph(kind: .graded) }
                if !savedGames.isEmpty {
                    sectionHeader(language.text("돌아보기", "Look back"))
                    row(title: language.text("게임 돌아보기", "Game review"),
                        detail: language.text("저장된 게임 \(savedGames.count)개. 어느 핸드든 선택 하나씩 다시 봐요.",
                                              "\(savedGames.count) saved \(savedGames.count == 1 ? "game" : "games"). Replay any hand, one choice at a time."),
                        id: "play-quick-history", open: { showArchive = true }) { PlayGlyph(kind: .review) }
                }
                styleLink
            }
            .padding(18)
        }
        .background(FeltBackground())
        // Page ground behind the status bar, so nothing scrolls under the clock bare.
        .safeAreaInset(edge: .top, spacing: 0) {
            GT.felt.frame(height: 0).ignoresSafeArea(edges: .top)
        }
        .gtTabBarClearance()
        .navigationDestination(isPresented: $showSetup) {
            TableSetupView(epoch: epoch ?? model.epoch, quick: setupQuick) {
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { showSetup = false }
                replayFromStart = true
                showTable = true
            }
        }
        .navigationDestination(isPresented: $showGraded) { TableView() }
        .fullScreenCover(isPresented: $showTable, onDismiss: {
            replayFromStart = false
            if setupAfterTable { setupAfterTable = false; setupQuick = true; showSetup = true }
        }) {
            FreeTableView(epoch: epoch ?? model.epoch, replayFromStart: replayFromStart,
                          onClose: { showTable = false },
                          onNewTable: { setupAfterTable = true; showTable = false })
        }
        .fullScreenCover(isPresented: $showArchive) {
            QuickPlayArchiveView(sessions: savedGames) { showArchive = false }
        }
        .sheet(isPresented: $showStyles) { StyleGuideView { showStyles = false } }
        .modifier(ProgressSaveNotice())
        .onAppear {
            if epoch == nil { epoch = model.epoch }
            #if DEBUG
            // A quick game left open, after this many hands, at the next one that waits on the learner.
            if let hands = ProcessInfo.processInfo.environment["GT_DEMO_PLAY_OPEN"].flatMap(Int.init),
               ProcessInfo.processInfo.environment["GT_TEST_STORE_ID"].flatMap(UUID.init(uuidString:)) != nil,
               !Self.demoTableOpened {
                Self.demoTableOpened = true
                configureQuickReview(stopAtHand: hands)
            }
            if ProcessInfo.processInfo.environment["GT_DEMO_PRACTICE"] != nil {
                if ProcessInfo.processInfo.environment["GT_DEMO_QUICK_REVIEW"] == "1",
                   ProcessInfo.processInfo.environment["GT_TEST_STORE_ID"].flatMap(UUID.init(uuidString:)) != nil {
                    configureQuickReview()
                }
                if model.state.tableState == nil {
                    let players = ProcessInfo.processInfo.environment["GT_DEMO_PLAYERS"].flatMap(Int.init) ?? 4
                    let styles = Array([Archetype.tag, .station, .lag].prefix(max(1, min(3, players - 1))))
                    perform { try model.startTable(seed: 97, styles: styles, expectedEpoch: model.epoch) }
                }
                showTable = model.state.tableState != nil
            }
            #endif
        }
        .onChange(of: model.epoch) { _, value in epoch = value }
        .alert(language.text("테이블을 시작하지 못했어요", "Couldn't start the table"), isPresented: $failure) {
            Button(language.text("확인", "OK"), role: .cancel) {}
        }
    }

    #if DEBUG
    /// Once per launch, so a table the test ends is not dealt again when Play reappears.
    private static var demoTableOpened = false

    private func configureQuickReview(stopAtHand: Int? = nil) {
        do {
            if model.state.tableState == nil {
                guard try model.startTable(seed: 97, styles: [.tag, .station, .lag],
                    startingStack: 40, handLimit: 10, expectedEpoch: model.epoch) else { return }
            }
            for _ in 0..<200 {
                guard let table = model.state.tableState, !table.isGameOver else { return }
                if let stopAtHand, table.handNumber >= stopAtHand, table.review == nil { return }
                let saved: Bool
                if table.review != nil {
                    saved = try model.nextTableHand(handID: UUID().uuidString, after: table.handID,
                        expectedEpoch: model.epoch)
                } else {
                    saved = try model.applyTableAction(table.legalActions.contains(.check) ? .check : .call,
                        actionID: UUID().uuidString, handID: table.handID, expectedEpoch: model.epoch)
                }
                guard saved else { return }
            }
        } catch { failure = true }
    }
    #endif

    // MARK: Rows

    /// The open table, marked like Learn's open lesson: its own cards and hand count.
    private func continueRow(_ table: PracticeTableState) -> some View {
        let players = language.text("\(table.seatCount)명", "\(table.seatCount) players")
        let title = table.handLimit == nil
            ? language.text("긴 테이블 · \(players)", "Long table · \(players)")
            : language.text("빠른 게임 · \(players)", "Quick game · \(players)")
        let hand = table.handNumber + 1
        let detail = table.handLimit.map {
            language.text("핸드 \(hand)/\($0). 여기서는 채점하지 않아요.", "Hand \(hand) of \($0). No grading here.")
        } ?? language.text("\(hand)번째 핸드. 여기서는 채점하지 않아요.", "Hand \(hand). No grading here.")
        // Between hands the last hand's cards are no longer in play, so backs stand in.
        let hole = table.street == .finished ? [] : table.learnerHole.compactMap(Card.init)
        let cards = hole.count == 2
            ? language.text("내 카드 ", "Your cards: ") + hole.map { $0.spoken(in: language) }.joined(separator: ", ")
            : nil
        return row(title: title, detail: detail, id: "play-continue", spoken: cards, marked: true,
                   open: { showTable = true }) {
            PlayGlyph(kind: .open(hole: hole, hand: hand, of: table.handLimit))
        }
        .disabled(model.saveError != nil)
    }

    private func startNewTable(quick: Bool) {
        if model.state.tableState != nil {
            pendingNewTable = quick
        } else {
            setupQuick = quick
            showSetup = true
        }
    }

    /// A small link under the list, as on the board; table setup keeps its own.
    private var styleLink: some View {
        Button { showStyles = true } label: {
            HStack(spacing: 8) {
                Text(language.text("스타일 자세히 보기", "About the styles"))
                    .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GT.onFeltSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.top, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.text("스타일 자세히 보기", "About the styles"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("play-style-guide")
    }

    // Header, row, stack and pill follow LearnView's list, so the two tabs read alike.

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(GT.title(17)).foregroundStyle(GT.onFelt)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 22).padding(.bottom, 4)
    }

    /// Picture, title and description, then a chevron; the marked row has its action
    /// instead. At the accessibility sizes everything stacks and the action spans the row.
    private func row<Glyph: View>(title: String, detail: String, id: String, spoken: String? = nil,
                                  marked: Bool = false, open: @escaping () -> Void,
                                  @ViewBuilder glyph: () -> Glyph) -> some View {
        let text = VStack(alignment: .leading, spacing: 2) {
            Text(title).font(GT.title(15)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail).font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        let main = Button(action: open) {
            layoutStack(spacing: stacks ? 8 : 12) {
                glyph()
                text
                if !stacks {
                    Spacer(minLength: 0)
                    if !marked {
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GT.onFeltSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, detail, spoken].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(id)

        return layoutStack(spacing: 10) {
            main
            if marked {
                let action = language.text("이어서", "Continue")
                Button(action: open) { pill(action) }
                    .buttonStyle(GTPress())
                    .accessibilityLabel("\(action), \(title)")
                    .accessibilityIdentifier("\(id)-action")
            }
        }
        .padding(.vertical, marked ? 8 : 10)
        .padding(.horizontal, marked ? 8 : 0)
        .background {
            if marked {
                let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                shape.fill(GT.glass).overlay(shape.strokeBorder(GT.cta, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, marked ? -8 : 0)
        .padding(.vertical, marked ? 2 : 0)
        .overlay(alignment: .bottom) {
            if !marked {
                Rectangle().fill(GT.border).frame(height: 1).padding(.leading, stacks ? 0 : 76)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// A stack across the row, or down it at the accessibility sizes.
    private func layoutStack<Content: View>(spacing: CGFloat, @ViewBuilder _ content: () -> Content) -> some View {
        let layout = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
                            : AnyLayout(HStackLayout(alignment: .center, spacing: spacing))
        return layout(content)
    }

    /// The marked row's filled action.
    private func pill(_ title: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        return Text(title).font(GT.semibold(14))
            .foregroundStyle(GT.onCTA)
            .fixedSize(horizontal: !stacks, vertical: true)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .frame(maxWidth: stacks ? .infinity : nil, minHeight: 36)
            .background { shape.fill(GT.cta) }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }

    private func perform(_ operation: () throws -> Bool) {
        do { if try !operation(), model.saveError == nil { failure = true } }
        catch { failure = true }
    }
}

/// The first table explains itself once; the info button reopens it.
enum PlayTableGuide {
    private static var key: String {
        #if DEBUG
        let suffix = ProcessInfo.processInfo.environment["GT_TEST_STORE_ID"] ?? "shared"
        #else
        let suffix = "shared"
        #endif
        return "play.tableGuideSeen.v1.\(suffix)"
    }

    static var seen: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// What each part of the free table shows, in the order a new player looks at it.
struct PlayTableGuideList: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var items: [(symbol: String, title: String, detail: String)] {
        [
            ("person.crop.square", language.text("내 카드", "Your cards"),
             language.text(dynamicTypeSize.isAccessibilitySize
                ? "크림색 자리가 나예요. 내 카드 두 장은 나만 볼 수 있고, 상대는 못 봐요."
                : "오른쪽 아래 크림색 자리가 나예요. 내 카드 두 장은 나만 볼 수 있고, 상대는 못 봐요.",
                dynamicTypeSize.isAccessibilitySize
                ? "The cream seat is yours. Only you can see your two cards; others can't."
                : "The cream seat at the bottom right is yours. Only you can see your two cards; others can't.")),
            ("rectangle.on.rectangle", language.text("상대 카드", "Opponents' cards"),
             language.text("상대 카드는 뒤집혀 있어요. 끝까지 간 핸드는 끝날 때 공개돼요.",
                           "Opponents' cards stay face down. Hands that reach a showdown are shown at the end.")),
            ("square.grid.3x1.below.line.grid.1x2", language.text("공용 카드", "Shared cards"),
             language.text("가운데 카드는 모두가 함께 써요. 세 장, 한 장, 다시 한 장 순서로 펼쳐져요.",
                           "Everyone uses the middle cards. They come out three, one, one.")),
            ("circle.grid.cross", language.text("팟", "The pot"),
             language.text("가운데 숫자는 이번 핸드에 모인 칩이에요. 이긴 사람이 모두 가져가요.",
                           "The middle number is every chip bet this hand. The winner takes it.")),
            ("hand.point.right", language.text("차례", "Whose turn"),
             language.text("밝게 표시된 자리가 행동할 차례예요. 컴퓨터는 한 명씩 차례로 움직이고, 내 차례가 오면 버튼이 열려요.",
                           "The highlighted seat acts next. Computers move one at a time; your buttons open when the turn reaches you.")),
            ("arrow.up.arrow.down", language.text("행동의 가격", "What each action costs"),
             language.text("폴드는 무료로 핸드를 떠나요. 콜은 버튼에 적힌 칩을 내고, 레이즈는 가격을 더 올려요.",
                           "Folding leaves the hand for free. Calling pays the chips on the button; raising sets a higher price.")),
            ("circle.fill", language.text("자리 옆 칩", "Chips beside a seat"),
             language.text("자리 옆 작은 칩과 숫자는 그 사람이 이번 베팅에서 이미 낸 칩이에요. 처음 두 사람은 카드를 받기 전에 1칩, 2칩(블라인드)을 내요.",
                           "The small chip and number beside a seat are what that player has put in this round. The first two players post 1 and 2 chips (the blinds) before the cards.")),
            ("minus", language.text("버튼 아래 색", "Colour under each button"),
             language.text("회색은 포기, 주황은 그대로 따라가기, 초록은 금액을 올리는 선택이에요.",
                           "Grey gives up, amber stays in for the same price, green raises the price.")),
            ("lightbulb", language.text("계산", "Math"),
             language.text("계산 버튼은 필요할 때만 열어요. 내 핸드와 콜 가격 같은 사실을 보여 주고, 무엇을 고를지는 정해 주지 않아요.",
                           "Open Math only when you want it. It shows facts like your hand and the price to call, never a pick.")),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(items, id: \.title) { item in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GT.inkSecondary)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(GT.semibold(16)).foregroundStyle(GT.ink)
                        Text(item.detail).font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                            .lineSpacing(GT.Typography.bodyLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .gtInset(GT.Space.card, firstText: .semibold(16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .gtPanel()
                .accessibilityElement(children: .combine)
            }
        }
    }
}

struct PlayTableGuideView: View {
    @Environment(\.learningLanguage) private var language
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(language.text("테이블 보는 법", "How to read the table"))
                        .font(GT.title(26)).foregroundStyle(GT.ink)
                    PlayTableGuideList()
                    PrimaryCTAButton(title: language.text("테이블로 가기", "Go to the table"), action: onClose)
                        .accessibilityIdentifier("play-table-guide-close")
                }
                .gtContentEdge()
            }
            .background(FeltBackground())
            .gtChrome(leading: { ChromeButton.close(onClose) })
            .gtSheetSurface()
        }
        .accessibilityIdentifier("play-table-guide-sheet")
    }
}
