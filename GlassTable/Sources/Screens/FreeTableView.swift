// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableDrills
import GlassTableEngine

/// The free table: the felt, your turn, and three buttons. Explanations
/// wait in a panel the learner opens only when they want one.
///
/// The model settles every computer action the moment the learner acts. This screen
/// replays those actions one seat at a time, so each move has a moment of its own and
/// the turn visibly comes back before the buttons open.
struct FreeTableView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    let epoch: UUID
    /// A table that was just dealt replays from the blinds; a reopened one does not.
    var replayFromStart = false
    let onClose: () -> Void
    /// The finished table was left; the caller opens table setup.
    let onNewTable: () -> Void

    @State private var shownSteps = 0
    @State private var shownHandID = ""
    @State private var thinkingSeat: Int?
    @State private var replay: Task<Void, Never>?
    @State private var replayPlan: FreeTableReplayPlan?
    @State private var replayCursor = FreeTableReplayCursor()
    @State private var replayGeneration = 0
    @State private var previousHand: PracticeTableState?
    @State private var feedback = TableFeedbackCoalescer()
    @State private var feedbackTask: Task<Void, Never>?
    @State private var feedbackPulse: TableFeedbackPulse?
    @State private var lastTurn = ""
    @State private var raising = false
    @State private var raiseAmount = 0
    @State private var showHelp = false
    @State private var helpTab = FreeTableHelpTab.hint
    @State private var revealFolded = false
    @State private var confirmNewTable = false
    @State private var confirmEndGame = false
    @State private var showGameReview = false
    @State private var showCoach = false
    @State private var failure = false
    @State private var replaySpeed = 1.0
    @ScaledMetric(relativeTo: .body) private var resultProseHeight = 51
    @ScaledMetric(relativeTo: .title) private var resultNetHeight = 36
    @ScaledMetric(relativeTo: .title2) private var raiseAmountHeight = 36
    @ScaledMetric(relativeTo: .body) private var frontTitleMetric = 18
    @ScaledMetric(relativeTo: .title2) private var raiseTitleMetric = 24
    @ScaledMetric(relativeTo: .body) private var raiseContextHeight = 32
    #if DEBUG
    @State private var demoTable: PracticeTableState?
    @State private var motionStarted = false
    @State private var pausedSnapshot = ""
    @State private var resumedSnapshot = ""
    #endif

    private var presentationTable: PracticeTableState? {
        #if DEBUG
        if let demoTable { return demoTable }
        #endif
        return model.state.tableState
    }

    private var reduceMotion: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["GT_DEMO_REDUCE_MOTION"] == "1" { return true }
        #endif
        return systemReduceMotion
    }

    var body: some View {
        Group {
            if let table = presentationTable {
                content(table)
            } else {
                FeltBackground()
            }
        }
        .background(FeltBackground())
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_FREE_MOTION_MANUAL"] != nil, !motionStarted {
                Button("Start replay") { motionStarted = true; startReplay() }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("motion-start")
            }
            #endif
        }
        .onAppear {
            guard let table = model.state.tableState else { return }
            #if DEBUG
            if configureMotion() { return }
            if configureDemoPhase(table) { return }
            #endif
            shownHandID = table.handID
            shownSteps = replayFromStart ? 0 : table.replaySteps.count
            resetPlan(table, shown: shownSteps)
            startReplay()
            if !PlayTableGuide.seen {
                #if DEBUG
                let env = ProcessInfo.processInfo.environment
                if env["GT_DEMO_PRACTICE"] != nil, env["GT_DEMO_PLAY_GUIDE"] == nil { return }
                #endif
                PlayTableGuide.seen = true
                helpTab = .rules
                showHelp = true
            }
        }
        .onDisappear {
            stopReplay()
            cancelFeedback()
        }
        .simultaneousGesture(DragGesture(minimumDistance: 45).onEnded { gesture in
            if gesture.startLocation.x < 24, gesture.translation.width > 80,
               abs(gesture.translation.height) < 60 { onClose() }
        })
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                startReplay()
                #if DEBUG
                resumedSnapshot = replaySnapshot
                #endif
            } else {
                #if DEBUG
                pausedSnapshot = replaySnapshot
                #endif
                stopReplay(); cancelFeedback()
            }
        }
        .onChange(of: reduceMotion) { _, _ in cancelFeedback(); startReplay() }
        .onChange(of: showHelp) { _, _ in requestFeedback(.tick) }
        .onChange(of: helpTab) { _, _ in requestFeedback(.tick) }
        .onChange(of: raiseAmount) { old, new in if old != new, raising { requestFeedback(.tick) } }
        .sensoryFeedback(trigger: feedbackPulse) { _, pulse in
            AppFeedback.hapticsEnabled ? pulse?.kind.sensory : nil
        }
        .onChange(of: feedbackPulse) { _, pulse in
            if let pulse { AppFeedback.table(kind: pulse.kind) }
        }
        .onChange(of: replayKey) { _, _ in
            guard let table = presentationTable else { return }
            if table.handID != shownHandID {
                shownHandID = table.handID
                shownSteps = 0
                revealFolded = false
                replaySpeed = 1
                resetPlan(table, shown: 0)
            }
            startReplay()
        }
        .onChange(of: model.epoch) { _, _ in onClose() }
        .fullScreenCover(isPresented: $showCoach) {
            if let table = presentationTable {
                FreeTableHandCoachView(table: table) { showCoach = false }
            }
        }
        .fullScreenCover(isPresented: $showGameReview) {
            QuickPlayArchiveView(sessions: currentReviewSessions) { showGameReview = false }
        }
        .confirmationDialog(language.text("게임을 마칠까요?", "End this game?"),
                            isPresented: $confirmEndGame, titleVisibility: .visible) {
            Button(language.text("게임 마치기", "End game"), role: .destructive) {
                guard let table = model.state.tableState,
                      model.endTable(handID: table.handID, expectedEpoch: epoch) else { return }
                onClose()
            }
            Button(language.text("계속하기", "Keep playing"), role: .cancel) {}
        } message: { Text(endGameMessage) }
        .confirmationDialog(language.text("새 게임을 시작할까요?", "Start a new game?"),
                            isPresented: $confirmNewTable, titleVisibility: .visible) {
            Button(language.text("새 게임 시작", "Start new game")) {
                guard let table = model.state.tableState,
                      model.endTable(handID: table.handID, expectedEpoch: epoch) else { return }
                onNewTable()
            }
            Button(language.text("취소", "Cancel"), role: .cancel) {}
        } message: {
            Text(endGameMessage)
        }
        .alert(language.text("선택을 처리하지 못했어요", "Couldn't apply that choice"), isPresented: $failure) {
            Button(language.text("확인", "OK"), role: .cancel) {}
        } message: {
            Text(language.text("저장된 테이블은 그대로예요. 현재 차례와 가능한 선택을 다시 확인해 주세요.",
                               "Your saved table is unchanged. Check the current turn and available choices."))
        }
        .modifier(ProgressSaveNotice())
    }

    private var currentReviewSessions: [QuickPlaySession] {
        let saved = model.state.quickPlaySessions.filter {
            $0.id == model.state.activeQuickPlaySessionID && !$0.hands.isEmpty
        }
        if !saved.isEmpty { return saved }
        guard let table = presentationTable, table.handLimit != nil, table.review != nil else { return [] }
        // A pre-archive game can still review its current settled hand before the next save.
        var legacy = QuickPlaySession(table: table)
        legacy.capture(table)
        return [legacy]
    }

    private var endGameMessage: String {
        if presentationTable?.street == .finished {
            return language.text("끝난 빠른 게임 핸드는 기록에 남아요.", "Settled Quick Game hands stay in history.")
        }
        return language.text("진행 중인 핸드는 버리고, 끝난 빠른 게임 핸드는 기록에 남아요. 닫기는 게임을 잠시 멈추고 이어 할 수 있어요.",
                             "The unfinished hand will be discarded. Settled Quick Game hands stay in history. Close pauses the game so you can resume.")
    }

    private var replayKey: String {
        guard let table = presentationTable else { return "" }
        return "\(table.handID)-\(table.replaySteps.count)"
    }

    private func isReplaying(_ table: PracticeTableState) -> Bool {
        table.handID != shownHandID || shownSteps < table.replaySteps.count
            || (replayPlan?.table.handID == table.handID && replayCursor.elapsed < (replayPlan?.duration ?? 0))
            || (table.review != nil && visualProjection(table)?.frame.settled == false)
    }

    // MARK: Layout

    @ViewBuilder
    private func content(_ table: PracticeTableState) -> some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            Group {
            if typeSize.isAccessibilitySize {
                ScrollView { tableSurface(table).padding(.horizontal, 8) }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        stableDock(table, heightLimit: availableHeight * 0.55 - 40)
                    }
            } else {
                tableSurface(table, fillsHeight: true)
                    .padding(.horizontal, 8).padding(.bottom, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    stableDock(table, heightLimit: nil)
                }
            }
        }
        }
        .gtChrome(leading: {
            HStack(alignment: typeSize.isAccessibilitySize ? .top : .center, spacing: 10) {
                ChromeButton.close(onClose)
                GTActionCaption(text: title(table), weight: .semibold, baseSize: 15, ink: GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }, trailing: {
            Menu {
                Button(language.text("게임 마치기", "End game"), role: .destructive) { confirmEndGame = true }
                Button(language.text("새 게임 시작", "Start new game")) { confirmNewTable = true }
                if !currentReviewSessions.isEmpty {
                    Button(language.text("게임 돌아보기", "Game review")) { showGameReview = true }
                }
            } label: {
                ChromeGlyph(symbol: "ellipsis")
            }
            .accessibilityLabel(language.text("게임 메뉴", "Game menu"))
            .accessibilityIdentifier("free-game-menu")
        })
    }

    private func title(_ table: PracticeTableState) -> String {
        let players = switch table.seatCount {
        case 2: language.text("두 명", "Two players")
        case 3: language.text("세 명", "Three players")
        default: language.text("네 명", "Four players")
        }
        if let limit = table.handLimit {
            return language.text("\(players) · 핸드 \(table.handNumber + 1)/\(limit)",
                                 "\(players) · Hand \(table.handNumber + 1) of \(limit)")
        }
        return language.text("\(players) · \(table.handNumber + 1)번째 핸드",
                             "\(players) · Hand \(table.handNumber + 1)")
    }

    // MARK: Table

    private func tableSurface(_ table: PracticeTableState, fillsHeight: Bool = false) -> some View {
        let projection = visualProjection(table)
        let frame = projection?.frame ?? table.frame(after: shownCount(table))
        let board = projection?.visibleBoard ?? Array((table.review?.board ?? table.visibleBoard).prefix(frame.boardCount))
        let pot = projection?.pot ?? frame.pot
        let sidePotText = projection?.potIndex.map { index in
            let remaining = projection!.remainingPots[index]
            let name = index == 0 ? language.text("메인 팟 · \(remaining)칩", "Main pot · \(remaining)")
                : language.text("사이드 팟 \(index) · \(remaining)칩", "Side pot \(index) · \(remaining)")
            return name + language.text("\n전체 \(pot)칩", "\nTotal \(pot)")
        }
        let paidOut = frame.settled && pot == 0 && table.review != nil
        let potText = sidePotText ?? (paidOut ? language.text("팟 지급 완료", "Pot paid out")
                                              : language.text("팟 \(pot)칩", "Pot \(pot)"))
        let potSpoken = sidePotText ?? (paidOut ? potText
            : language.text("팟 \(pot)칩", "Pot, \(pot) \(pot == 1 ? "chip" : "chips")"))
        return TableSurface(
            seats: (0..<table.seatCount).map { seat($0, table: table, frame: frame) },
            center: TableCenter(board: board.compactMap(Card.init), reservesBoard: true,
                                potTotal: potText, potSpoken: potSpoken),
            freeVisuals: projection?.visuals,
            freeReduceMotion: reduceMotion,
            freeHoles: (projection?.transitioning == true ? projection!.visibleHole : table.review?.holeCards ?? [table.learnerHole]).map(\.highCardFirst),
            freeBoard: projection?.transitioning == true ? projection!.visibleBoard : table.review?.board ?? table.visibleBoard,
            fillsHeight: fillsHeight)
            .accessibilityIdentifier("practice-table")
            .accessibilityValue(replayDebugValue)
    }

    private func shownCount(_ table: PracticeTableState) -> Int {
        table.handID == shownHandID ? min(shownSteps, table.replaySteps.count) : 0
    }

    /// Clockwise from the learner at the bottom right.
    private func seat(_ seat: Int, table: PracticeTableState, frame: PracticeTableFrame) -> TableSeat {
        let projection = visualProjection(table)
        let places: [TableSeat.Place] = switch table.seatCount {
        case 2: [.bottomTrailing, .topLeading]
        case 3: [.bottomTrailing, .topLeading, .topTrailing]
        default: [.bottomTrailing, .bottomLeading, .topLeading, .topTrailing]
        }
        let review = frame.settled ? table.review : nil
        let hand: TableSeat.Hand
        if let projection, !projection.visuals.exposed.contains(seat), !(frame.settled && revealFolded) {
            hand = .faceDown
        } else if let projection, projection.visuals.exposed.contains(seat) {
            hand = .faceUp(projection.visibleHole[seat].highCardFirst.compactMap(Card.init))
        } else if seat == 0 {
            hand = .faceUp(table.learnerHole.highCardFirst.compactMap(Card.init))
        } else if let review, revealFolded || (Self.wentToShowdown(review) && !frame.folded[seat]) {
            hand = .faceUp(review.holeCards[seat].highCardFirst.compactMap(Card.init))
        } else {
            hand = .faceDown
        }
        let won = review?.pots.contains { $0.winners.contains(seat) } == true
        let style = table.computerSeats.first(where: { $0.seat == seat })?.style
        let status: String?
        if projection?.oddAward.contains(seat) == true {
            status = "+1"
        } else if let amount = projection?.refilling[seat] {
            status = language.text("+\(amount) 채움", "+\(amount) refill")
        } else if let amount = projection?.returned[seat], frame.settled == false {
            status = language.text("반환 \(amount)", "Returned \(amount)")
        } else if let amount = projection?.credits[seat], frame.settled == false {
            status = "+\(amount)"
        } else if won, let review {
            // The seat shows the hand's net, the same number as the result headline.
            // A payout includes the winner's own chips, so it read as a second total.
            let net = review.endingStacks[seat] - review.startingStacks[seat]
            status = net > 0 ? "+\(net)" : net < 0 ? "−\(-net)" : "±0"
        } else if thinkingSeat == seat {
            status = language.text("생각 중…", "Thinking…")
        } else if frame.stacks[seat] == 0, !frame.folded[seat] {
            let amount = replayPlan?.allInAmount(seat: seat, after: shownCount(table)) ?? frame.streetCommitted[seat]
            status = amount > 0 ? language.text("올인 \(amount)", "All in \(amount)") : language.text("올인", "All in")
        } else if let event = frame.lastEvent[seat], event.action != nil {
            if frame.stacks[seat] == 0, event.chips > 0 {
                status = language.text("올인 \(frame.streetCommitted[seat])", "All in \(frame.streetCommitted[seat])")
            } else if event.label == "raise" {
                status = language.text("\(frame.streetCommitted[seat])까지 레이즈", "Raise to \(frame.streetCommitted[seat])")
            } else if event.label == "bet" {
                status = language.text("벳 \(event.chips)", "Bet \(event.chips)")
            } else if event.label == "fold" {
                status = language.text("폴드", "Fold")
            } else if event.label == "check" {
                status = language.text("체크", "Check")
            } else if event.label == "call" {
                status = language.text("콜 \(event.chips)", "Call \(event.chips)")
            } else {
                status = eventDescription(event)
            }
        } else if let event = frame.lastEvent[seat], event.chips > 0, !frame.settled {
            // A posted blind is the chip marker beside the seat. Unnamed, it was a dot
            // and a number with no reason to be there.
            status = language.text("블라인드 \(event.chips)칩", "Blind \(event.chips)")
        } else {
            status = seat == 0 ? nil : style?.beginnerTitle(in: language)
        }
        let myTurn = seat == 0 && !isReplaying(table) && table.currentSeat == 0
        return TableSeat(
            id: "practice-\(seat)",
            place: places[seat],
            name: seatName(seat),
            status: status,
            tone: thinkingSeat == seat || won ? .action : .neutral,
            isActive: thinkingSeat == seat || myTurn,
            isFolded: frame.folded[seat],
            isDealer: table.dealer == seat && projection?.visuals.dealerMoving != true,
            hand: hand,
            stack: frame.stacks[seat],
            committed: frame.streetCommitted[seat],
            isHero: seat == 0)
    }

    static func wentToShowdown(_ review: PracticeTableReview) -> Bool {
        review.pots.contains { $0.eligibleSeats.count > 1 }
    }

    // MARK: Controls

    private func stableDock(_ table: PracticeTableState, heightLimit: CGFloat?) -> some View {
        ActionSheet {
            GTStableDockLayout(heightLimit: heightLimit) {
                GeometryReader { geometry in
                    if heightLimit != nil {
                        ScrollView { dockFace(table, minimumHeight: geometry.size.height) }
                            .accessibilityIdentifier("free-dock-content")
                    } else {
                        dockFace(table, minimumHeight: geometry.size.height)
                    }
                }
                dockSizingTemplates
                    .hidden().accessibilityHidden(true).allowsHitTesting(false)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("free-dock-faces")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("free-dock")
    }

    @ViewBuilder
    private func dockFace(_ table: PracticeTableState, minimumHeight: CGFloat) -> some View {
        ZStack(alignment: .top) {
            if !showHelp {
                controls(table, minimumHeight: minimumHeight)
                    .transition(.opacity)
            }
            if showHelp {
                FreeTableBackFace(table: table, frame: factsFrame(table),
                                  shownSteps: shownCount(table), heroExposed: visualProjection(table)?.heroExposed ?? true,
                                  shownPot: visualProjection(table)?.pot, tab: $helpTab,
                                  revealFolded: $revealFolded, minimumHeight: minimumHeight,
                                  onNext: {
                                      showHelp = false
                                      continueAfterHand(table)
                                  }) { showHelp = false }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 16)))
            }
        }
        .animation(GT.Motion.fade, value: showHelp)
    }

    // Reachable structures share the live presentation views; sizing never reads future cards.
    @ViewBuilder
    private var dockSizingTemplates: some View {
        ForEach([nil, language.text("남은 칩 전부로 콜해요", "Calling puts you all in"),
                 language.text("올인이 작아서 다시 올릴 수 없어요", "Their all-in was short, so no re-raise")], id: \.self) { warning in
            VStack(alignment: .leading, spacing: 12) {
                dockHeader(language.text("선택할 차례", "Your turn"), warning: warning, onMath: {})
                actionSlots(owed: 14, price: 14, allIn: true, bet: false,
                            foldEnabled: false, middleEnabled: false, raiseEnabled: false,
                            reason: "", onFold: {}, onMiddle: {}, onRaise: {})
            }
        }
        ForEach([language.text("\(seatName(3)) 차례", "\(seatName(3))'s turn"),
                 language.text("카드를 나눠요", "Dealing"),
                 language.text("끝까지 펼쳐요", "Running it out")], id: \.self) { title in
            VStack(alignment: .leading, spacing: 12) {
                dockHeader(title, warning: nil, onMath: {})
                actionSlots(owed: 14, price: 14, allIn: true, bet: false,
                            foldEnabled: false, middleEnabled: false, raiseEnabled: false,
                            reason: "", onFold: {}, onMiddle: {}, onRaise: {})
                skipLink(enabled: false, action: {})
            }
        }
        VStack(alignment: .leading, spacing: 12) {
            let sizing = FreeRaisePresentation(street: .preflop, minimum: 4, maximum: 100,
                                               committed: 0, currentBet: 2, pot: 3, toCall: 2)
            raiseHeader(sizing, amount: 100, onCancel: {}, onMath: {})
            raiseBody(sizing, amount: 100, onAmount: { _ in }, onStep: { _ in }, onConfirm: {})
        }
        VStack(alignment: .leading, spacing: 12) {
            dockHeader(language.text("핸드가 끝났어요", "Hand over"), warning: nil, onMath: {})
            resultBody(netText: language.text("+100칩", "+100 chips"), positive: true,
                       onNext: {}, onReview: {}, onChange: {}) { Color.clear }
        }
        VStack(alignment: .leading, spacing: 12) {
            FreeTableBackHeader(tab: .constant(.hint), onClose: {})
            FreeTableMathSummary(pot: 100, call: 14, need: 25,
                                 hand: language.text("Q 원페어", "Pair of queens"), top: nil, hole: [])
        }
    }

    private func skipLink(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(language.text("결과로 넘기기", "Skip to result"), action: action)
            .buttonStyle(GTOutlinedAction()).accessibilityIdentifier("free-skip-result")
            .disabled(!enabled)
    }

    private func controls(_ table: PracticeTableState, minimumHeight: CGFloat) -> some View {
        GTAnchoredDockFaceLayout(minimumHeight: minimumHeight,
                                 scrollsBody: !isReplaying(table) && table.review != nil) {
            if raising && !isReplaying(table), table.review == nil {
                raiseHeader(FreeRaisePresentation(table: table), amount: raiseAmount,
                            onCancel: { raising = false }, onMath: { helpTab = .hint; showHelp = true })
            } else if !isReplaying(table), table.review == nil, table.currentSeat == 0 {
                VStack(alignment: .leading, spacing: 14) {
                    statusRow(table)
                    turnFacts(table)
                }
            } else {
                statusRow(table)
            }
            Group {
            if isReplaying(table) {
                VStack(alignment: .leading, spacing: 12) {
                actionRow(table, enabled: false)
                if table.frame(after: shownCount(table)).folded[0] {
                    skipLink(enabled: replaySpeed != 3) {
                        replaySpeed = 3
                        startReplay()
                    }
                }
                }
            } else if let review = table.review {
                ScrollView { result(review, table: table).frame(maxWidth: .infinity, alignment: .leading) }
                    .accessibilityIdentifier("free-result-body")
            } else if raising {
                raisePanel(table)
            } else {
                actionRow(table, enabled: table.currentSeat == 0)
            }
            }
        }
        .disabled(model.saveError != nil)
        .animation(reduceMotion ? nil : GT.Motion.change, value: raising)
        .animation(reduceMotion ? nil : GT.Motion.change, value: isReplaying(table))
    }

    private func dockTitle(_ table: PracticeTableState) -> String {
        if let thinkingSeat {
            return language.text("\(seatName(thinkingSeat)) 차례", "\(seatName(thinkingSeat))'s turn")
        }
        if isReplaying(table) {
            let frame = table.frame(after: shownCount(table))
            let live = frame.folded.indices.filter { !frame.folded[$0] }
            let funded = live.filter { frame.stacks[$0] > 0 }
            let shownBet = max(frame.street == .preflop ? 2 : 0, frame.streetCommitted.max() ?? 0)
            let runningOut = live.count > 1 && funded.count <= 1
                && funded.allSatisfy { frame.streetCommitted[$0] >= shownBet }
            return runningOut ? language.text("끝까지 펼쳐요", "Running it out")
                : language.text("카드를 나눠요", "Dealing")
        }
        return table.review == nil ? language.text("선택할 차례", "Your turn")
            : table.isGameOver ? language.text("게임이 끝났어요", "Game over")
            : language.text("핸드가 끝났어요", "Hand over")
    }

    private func warning(_ table: PracticeTableState) -> String? {
        guard !isReplaying(table), table.review == nil, table.currentSeat == 0,
              table.legalActions.contains(.call) else { return nil }
        if table.amountToCall >= table.seats[0].stack {
            return language.text("남은 칩 전부로 콜해요", "Calling puts you all in")
        }
        if table.raiseBlock == .shortAllInDidNotReopen {
            return language.text("올인이 작아서 다시 올릴 수 없어요", "Their all-in was short, so no re-raise")
        }
        return nil
    }

    private func statusRow(_ table: PracticeTableState) -> some View {
        dockHeader(dockTitle(table), warning: warning(table)) {
            helpTab = .hint
            showHelp = true
        }
    }

    /// What the choice costs and what is in the middle, in the dock's otherwise blank area.
    private func turnFacts(_ table: PracticeTableState) -> some View {
        let frame = table.frame(after: shownCount(table))
        let price = FreeDockChoices(frame: frame).price
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 28))
        return layout {
            turnFact(language.text("콜하려면", "To call"),
                     price == 0 ? language.text("낼 칩 없음", "Nothing")
                                : language.text("\(price)칩", "\(price) \(price == 1 ? "chip" : "chips")"))
            turnFact(language.text("팟", "Pot"),
                     language.text("\(frame.pot)칩", "\(frame.pot) \(frame.pot == 1 ? "chip" : "chips")"))
        }
        .accessibilityIdentifier("free-turn-facts")
    }

    private func turnFact(_ label: String, _ value: String) -> some View {
        // At accessibility sizes a stacked label and value push the actions off the screen.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
        return layout {
            Text(label).font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            Text(value).font(GT.title(22).monospacedDigit()).foregroundStyle(GT.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private func dockHeader(_ title: String, warning: String?, onMath: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Beside the pill a large title is left one letter wide, so it goes above.
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
            layout {
                Text(title).font(GT.title(18)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("free-table-status")
                if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                mathPill(onMath: onMath)
            }
            if let warning {
                Text(warning).font(GT.body(13)).foregroundStyle(GT.cta)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func actionRow(_ table: PracticeTableState, enabled: Bool) -> some View {
        let frame = table.frame(after: shownCount(table))
        let choices = FreeDockChoices(frame: frame)
        let owed = choices.owed
        let price = choices.price
        let allIn = choices.allIn
        let bet = choices.bet
        let actions = table.legalActions
        let minimumRaise = actions.compactMap { action -> Int? in
            if case let .raise(to: amount) = action { return amount }; return nil
        }.first
        let reason: String
        if model.saveError != nil {
            reason = language.text("저장 문제를 해결한 뒤 선택해 주세요", "Resolve the save problem before choosing")
        } else if frame.folded[0] {
            reason = language.text("이미 폴드했어요", "You have folded")
        } else if isReplaying(table) {
            reason = thinkingSeat.map { language.text("\(seatName($0)) 차례예요", "\(seatName($0)) is taking their turn") }
                ?? language.text("카드를 나누는 동안 기다려 주세요", "Wait while the cards are dealt")
        } else {
            reason = language.text("현재 차례에 선택할 수 없어요", "Unavailable on this turn")
        }
        let raiseReason: String
        switch enabled && model.saveError == nil ? table.raiseBlock : nil {
        case .noChipsBeyondCall:
            raiseReason = language.text("콜 뒤에 더 낼 칩이 없어요", "You have no chips beyond the call")
        case .noOpponentCanAnswer:
            raiseReason = language.text("추가 벳을 받을 상대 칩이 없어요", "No opponent has chips to answer another wager")
        case .shortAllInDidNotReopen:
            raiseReason = language.text("작은 올인으로 레이즈가 다시 열리지 않았어요", "The short all-in did not reopen raising")
        case nil:
            raiseReason = reason
        }
        let canAct = enabled && model.saveError == nil
        return actionSlots(owed: owed, price: price, allIn: allIn, bet: bet,
                           foldEnabled: canAct && actions.contains(.fold),
                           middleEnabled: canAct && actions.contains(owed == 0 ? .check : .call),
                           raiseEnabled: canAct && minimumRaise != nil,
                           reason: reason, raiseReason: raiseReason,
                           onFold: { choose(.fold, table: table) },
                           onMiddle: { choose(owed == 0 ? .check : .call, table: table) },
                           onRaise: {
            guard let minimumRaise else { return }
            raiseAmount = minimumRaise
            requestFeedback(.tick)
            raising = true
        })
    }

    private func actionSlots(owed: Int, price: Int, allIn: Bool, bet: Bool,
                             foldEnabled: Bool, middleEnabled: Bool, raiseEnabled: Bool,
                             reason: String, raiseReason: String? = nil, onFold: @escaping () -> Void,
                             onMiddle: @escaping () -> Void, onRaise: @escaping () -> Void) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            freeAction(language.text("폴드", "Fold"), price: "", role: .fold,
                       enabled: foldEnabled,
                       reason: owed == 0 ? language.text("따라갈 금액이 없어 폴드할 수 없어요", "Fold is unavailable because nothing is owed") : reason,
                       action: onFold)
                .accessibilityIdentifier("free-fold")
            freeAction(owed == 0 ? language.text("체크", "Check")
                       : allIn ? language.text("올인", "All in") : language.text("콜", "Call"),
                       price: owed == 0 ? "" : language.text("\(price)칩", "\(price)"), role: .passive,
                       enabled: middleEnabled, reason: reason, action: onMiddle)
                .accessibilityIdentifier(owed == 0 ? "free-check" : "free-call")
            freeAction(bet ? language.text("벳", "Bet") : language.text("레이즈", "Raise"),
                       price: "", role: .aggressive, enabled: raiseEnabled,
                       reason: raiseReason ?? reason,
                       action: onRaise)
                .accessibilityIdentifier("free-raise")
        }
    }

    private func freeAction(_ title: String, price: String, role: GTActionRole,
                            enabled: Bool, reason: String,
                            action: @escaping () -> Void) -> some View {
        let plain: String = switch role {
        case .fold: language.text("포기", "Give up")
        case .passive: price.isEmpty ? language.text("넘기기", "Pass") : language.text("\(price) 내기", "Add \(price)")
        case .aggressive: title == language.text("벳", "Bet")
            ? language.text("먼저 걸기", "Bet first") : language.text("더 올리기", "Increase")
        }
        return GTActionButton(title: termsLead ? title : plain, price: termsLead ? price : "", role: role,
                       freeTablePresentation: true, secondaryTitle: termsLead ? nil : title,
                       minHeight: 87, action: action)
            .disabled(!enabled).opacity(enabled ? 1 : 0.45)
            .accessibilityHint(enabled ? actionMeaning(role, price: price) : reason)
    }

    private func actionMeaning(_ role: GTActionRole, price: String) -> String {
        switch role {
        case .fold: language.text("카드를 내려놓고 이번 핸드를 포기해요", "Give up your cards and this hand")
        case .passive: price.isEmpty
            ? language.text("칩을 더 내지 않고 넘겨요", "Pass without adding chips")
            : language.text("\(price)을 내고 계속해요", "Add \(price) chips to stay in")
        case .aggressive: language.text("금액을 골라 더 올려요", "Choose an amount to increase the bet")
        }
    }

    private func mathPill(onMath: @escaping () -> Void) -> some View {
        Button(action: onMath) {
            Label(language.text("선택 도움말", "Decision help"), systemImage: "lightbulb")
                .fixedSize(horizontal: true, vertical: false)
                .font(GT.semibold(14)).foregroundStyle(GT.ink)
                .padding(.horizontal, 12).frame(minHeight: 36)
                .background(GT.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(GT.borderStrong, lineWidth: 1))
                .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityIdentifier("free-table-help")
    }

    private func raiseHeader(_ sizing: FreeRaisePresentation, amount: Int,
                             onCancel: @escaping () -> Void, onMath: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if typeSize.isAccessibilitySize {
                HStack(alignment: .top) {
                    raiseBack(onCancel: onCancel)
                    Spacer(minLength: 8)
                    mathPill(onMath: onMath)
                }
                raiseAmountTitle(sizing, amount: amount, besideControls: false)
            } else {
                HStack(alignment: .center, spacing: 8) {
                    raiseBack(onCancel: onCancel)
                    raiseAmountTitle(sizing, amount: amount, besideControls: true)
                    mathPill(onMath: onMath)
                }
            }
            ScrollView {
                Text(sizing.context(amount: amount, language: language))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("free-raise-context")
            }
            .frame(height: raiseContextHeight)
            .accessibilityIdentifier("free-raise-context-scroll")
        }
        .padding(.top, typeSize.isAccessibilitySize
                 ? min(GT.Space.sheet, GT.TextRole.title(18).inkLeading(in: language) * frontTitleMetric / 18) : 0)
    }

    private func raiseBack(onCancel: @escaping () -> Void) -> some View {
        Button(action: onCancel) {
            ChromeGlyph(symbol: "chevron.left")
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(language.text("금액 선택 닫기", "Back to actions"))
        .accessibilityIdentifier("free-raise-cancel")
    }

    private func raiseAmountTitle(_ sizing: FreeRaisePresentation, amount: Int,
                                  besideControls: Bool) -> some View {
        ScrollView {
            Text(sizing.title(amount: amount, language: language))
                .font(GT.title(24).monospacedDigit()).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, minHeight: besideControls ? raiseAmountHeight : nil, alignment: .leading)
                .accessibilityIdentifier("free-raise-amount")
        }
        .frame(height: raiseAmountHeight)
        // Beside the back arrow and the help pill the title shares their centre line.
        .offset(y: besideControls ? 0 : GT.TextRole.title(18).inkLeading(in: language) * frontTitleMetric / 18
                - GT.TextRole.title(24).inkLeading(in: language) * raiseTitleMetric / 24)
        .accessibilityIdentifier("free-raise-amount-scroll")
    }

    private func raisePanel(_ table: PracticeTableState) -> some View {
        let sizing = FreeRaisePresentation(table: table)
        let amount = max(sizing.minimum, min(sizing.maximum, raiseAmount))
        return raiseBody(sizing, amount: amount, onAmount: { raiseAmount = $0 }, onStep: { delta in
            let current = max(sizing.minimum, min(sizing.maximum, raiseAmount))
            if delta < 0, current > sizing.minimum { raiseAmount = current - 1 }
            if delta > 0, current < sizing.maximum { raiseAmount = current + 1 }
        }, onConfirm: {
            raising = false
            choose(.raise(to: amount), table: table)
        })
    }

    private func raiseBody(_ sizing: FreeRaisePresentation, amount: Int,
                           onAmount: @escaping (Int) -> Void, onStep: @escaping (Int) -> Void,
                           onConfirm: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if typeSize.isAccessibilitySize {
                ScrollView(.horizontal) { raisePresets(sizing, amount: amount, width: nil, onAmount: onAmount) }
                    .accessibilityIdentifier("free-raise-presets")
            } else {
                GeometryReader { geometry in
                    raisePresets(sizing, amount: amount, width: max(0, (geometry.size.width - 24) / 5), onAmount: onAmount)
                }
                .frame(height: 62)
            }
            HStack(alignment: .bottom, spacing: 8) {
                raiseStep("−", enabled: amount > sizing.minimum, spoken: language.text("1칩 줄이기", "Decrease by 1 chip")) { onStep(-1) }
                    .accessibilityIdentifier("free-raise-minus")
                PrimaryCTAButton(title: amount == sizing.maximum
                    ? language.text("올인 \(amount)", "All in \(amount)")
                    : sizing.title(amount: amount, language: language), action: onConfirm)
                    .accessibilityIdentifier("free-raise-confirm")
                raiseStep("+", enabled: amount < sizing.maximum, spoken: language.text("1칩 늘리기", "Increase by 1 chip")) { onStep(1) }
                    .accessibilityIdentifier("free-raise-plus")
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func raisePresets(_ sizing: FreeRaisePresentation, amount: Int, width: CGFloat?,
                              onAmount: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(sizing.presets.enumerated()), id: \.offset) { index, preset in
                let legal = (sizing.minimum...sizing.maximum).contains(preset.amount)
                Button { if legal { onAmount(preset.amount) } } label: {
                    VStack(spacing: 4) {
                        Text(language.text("\(preset.amount)칩", "\(preset.amount)")).font(GT.title(14).monospacedDigit())
                        Text(language == .korean ? preset.korean : preset.english).font(GT.semibold(11))
                    }
                    .fixedSize(horizontal: typeSize.isAccessibilitySize, vertical: true)
                    .padding(.horizontal, 8).padding(.vertical, 10)
                    .frame(width: width).frame(minHeight: 44)
                    .foregroundStyle(amount == preset.amount ? GT.onCTA : GT.ink)
                    .background(amount == preset.amount ? GT.cta : GT.surface,
                                in: RoundedRectangle(cornerRadius: GT.Radius.control))
                    .overlay(RoundedRectangle(cornerRadius: GT.Radius.control)
                        .strokeBorder(GT.borderStrong, lineWidth: 1))
                }
                .buttonStyle(GTPress()).disabled(!legal).opacity(legal ? 1 : 0.45)
                .accessibilityIdentifier("free-raise-preset-\(index)")
                .accessibilityAddTraits(amount == preset.amount ? .isSelected : [])
                .accessibilityHint(legal ? "" : preset.amount < sizing.minimum
                    ? language.text("최소 레이즈 금액보다 작아요", "Below the minimum raise")
                    : language.text("남은 칩보다 커요", "More than your remaining chips"))
            }
        }
    }

    private func raiseStep(_ title: String, enabled: Bool, spoken: String,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: title == "−" ? "minus" : "plus")
                .font(.system(size: 24, weight: .semibold)).foregroundStyle(GT.ink)
                .frame(width: 54).frame(minHeight: 54, maxHeight: .infinity)
                .background { GTDockControlBackground() }
        }
        .buttonStyle(GTHoldStepStyle(enabled: enabled)).disabled(!enabled).opacity(enabled ? 1 : 0.45)
        .accessibilityLabel(spoken)
        .accessibilityHint(enabled ? "" : title == "−"
            ? language.text("최소 레이즈 금액이에요", "At the minimum raise")
            : language.text("남은 칩 전부를 선택했어요", "All your remaining chips are selected"))
    }

    private func continueAfterHand(_ table: PracticeTableState) {
            if table.isGameOver {
                if model.leaveFinishedTable(handID: table.handID, expectedEpoch: epoch) { onNewTable() }
                return
            }
            previousHand = table
            #if DEBUG
            if demoTable != nil, ProcessInfo.processInfo.environment["GT_DEMO_FREE_MOTION"] != nil {
                var next = table
                do {
                    try next.nextHand(handID: "\(table.handID)-next")
                    demoTable = next
                } catch { failure = true }
                return
            }
            #endif
            if perform({
                try model.nextTableHand(handID: UUID().uuidString, after: table.handID, expectedEpoch: epoch)
            }) { requestFeedback(.commit(allIn: false)) }
    }

    private func result(_ review: PracticeTableReview, table: PracticeTableState) -> some View {
        let net = review.endingStacks[0] - review.startingStacks[0]
        let text = net > 0 ? language.text("+\(net)칩", "+\(net) chips")
            : net < 0 ? language.text("−\(-net)칩", "−\(-net) chips") : language.text("±0칩", "±0 chips")
        let winners = (0..<table.seatCount).filter { review.payouts[$0] > 0 }
        return resultBody(netText: text, positive: net > 0, gameOver: table.isGameOver, onNext: {
            continueAfterHand(table)
        }, onReview: { showCoach = true }, onChange: { confirmNewTable = true }) {
            ForEach(winners, id: \.self) { seat in
                Text(winnerLine(seat, review: review, table: table))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if table.isGameOver {
                Text(gameOverLine(table))
                    .font(GT.semibold(14)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("free-game-over")
                Button(language.text("전체 게임 돌아보기", "Review the whole game")) { showGameReview = true }
                    .buttonStyle(GTOutlinedAction())
                    .accessibilityIdentifier("free-review-game")
            } else if table.seats.contains(where: { $0.stack == 0 }) {
                Text(language.text("칩이 없는 자리는 다음 핸드 전에 \(table.startingStack)칩을 새로 받아요.",
                                   "Seats with no chips get \(table.startingStack) before the next hand."))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Chips a seat was topped up with don't count toward its finish.
    private func gameOverLine(_ table: PracticeTableState) -> String {
        let earned = (0..<table.seatCount).map { table.seats[$0].stack - table.refills[$0] }
        let place = 1 + earned.filter { $0 > earned[0] }.count
        let chips = table.seats[0].stack
        let ordinal = ["1st", "2nd", "3rd", "4th"][place - 1]
        return language.text("\(table.seatCount)명 중 \(place)등 · \(chips)칩으로 마쳤어요",
                             "You finished \(ordinal) of \(table.seatCount) with \(chips) chips")
    }

    private func resultBody<Prose: View>(netText: String, positive: Bool, gameOver: Bool = false,
                                        onNext: @escaping () -> Void, onReview: @escaping () -> Void,
                                        onChange: @escaping () -> Void, @ViewBuilder prose: () -> Prose) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                Text(netText).font(GT.title(26).monospacedDigit())
                    .foregroundStyle(positive ? GT.cta : GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("free-table-net")
            }
            .frame(height: resultNetHeight)
            ScrollView {
                VStack(alignment: .leading, spacing: 10, content: prose)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: resultProseHeight)
            .accessibilityIdentifier("free-result-prose")
            PrimaryCTAButton(title: gameOver ? language.text("새 게임", "New game")
                                             : language.text("다음 핸드", "Next hand"), action: onNext)
                .accessibilityIdentifier(gameOver ? "free-new-game" : "free-next-hand")
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
            layout {
                SecondaryCTAButton(title: language.text("핸드 돌아보기", "Review this hand"), action: onReview)
                    .accessibilityIdentifier("free-review")
                if !gameOver {
                    SecondaryCTAButton(title: language.text("새 게임 시작", "Start new game"), action: onChange)
                        .accessibilityIdentifier("free-change-table")
                }
            }
        }
    }

    private func winnerLine(_ seat: Int, review: PracticeTableReview, table: PracticeTableState) -> String {
        let name = seatName(seat)
        // Net and pot differ by the winner's own chips. Saying so keeps the headline,
        // the seat and this line from reading as three different results.
        let own = review.payouts[seat] - (review.endingStacks[seat] - review.startingStacks[seat])
        let pot = own > 0
            ? language.text("팟 \(review.payouts[seat])칩 (낸 칩 \(own) 포함)",
                            "won \(review.payouts[seat]) chips (\(own) their own)")
            : language.text("팟 \(review.payouts[seat])칩", "won \(review.payouts[seat]) chips")
        guard Self.wentToShowdown(review), review.board.count == 5,
              let cards = Card.parse((review.holeCards[seat] + review.board).joined()) else {
            return "\(name) · \(pot)"
        }
        let brief = bestHand(cards)
        let hand = DrillTerms.hand(brief, in: language)
        // Same named hand on both sides means the side cards decided it. Without this
        // the line gives no reason one pair beat the other.
        let rivals = Set(review.pots.filter { $0.winners.contains(seat) }.flatMap(\.eligibleSeats))
            .subtracting(review.pots.flatMap(\.winners))
        let kicker = rivals.contains { rival in
            guard let theirs = Card.parse((review.holeCards[rival] + review.board).joined()) else { return false }
            let other = bestHand(theirs)
            return other.category == brief.category && other.topRank == brief.topRank
        }
        return "\(name) · \(pot) · \(hand)"
            + (kicker ? language.text(" · 나머지 카드(키커)가 더 높아요", " · higher side card (kicker)") : "")
    }

    // MARK: Acting

    private func choose(_ action: PracticeAction, table: PracticeTableState) {
        let allIn: Bool
        switch action {
        case .call: allIn = table.amountToCall == table.seats[0].stack
        case let .raise(to: amount): allIn = amount == table.seats[0].streetCommitted + table.seats[0].stack
        default: allIn = false
        }
        if perform({
            try model.applyTableAction(action, actionID: "\(table.handID)-learner-\(table.events.count)",
                                       handID: table.handID, expectedEpoch: epoch)
        }) { requestFeedback(.commit(allIn: allIn)) }
    }

    @discardableResult private func perform(_ operation: () throws -> Bool) -> Bool {
        do {
            let accepted = try operation()
            if !accepted, model.saveError == nil { failure = true }
            return accepted
        } catch { failure = true; return false }
    }

    // MARK: Replay

    private func resetPlan(_ table: PracticeTableState, shown: Int) {
        let plan = FreeTableReplayPlan(table: table, previous: previousHand, reduceMotion: reduceMotion)
        replayPlan = plan
        replayCursor = FreeTableReplayCursor(elapsed: plan.boundary(after: shown),
            cueIndex: plan.cues.prefix { $0.time <= plan.boundary(after: shown) }.count)
    }

    private func visualProjection(_ table: PracticeTableState) -> FreeTableReplayProjection? {
        guard let plan = replayPlan, plan.table.handID == table.handID else { return nil }
        return replayCursor.projection(plan: plan)
    }

    private func factsFrame(_ table: PracticeTableState) -> PracticeTableFrame {
        var frame = table.frame(after: shownCount(table))
        if let projection = visualProjection(table) {
            frame.boardCount = projection.visibleBoard.count
            if frame.street != projection.frame.street {
                frame.streetCommitted = Array(repeating: 0, count: table.seatCount)
                frame.lastEvent = Array(repeating: nil, count: table.seatCount)
            }
            frame.street = projection.frame.street
        }
        return frame
    }

    private func stopReplay() {
        replayGeneration += 1
        replay?.cancel()
        replay = nil
    }

    /// One active clock owns all visual progress. Inactivity leaves its cursor in place.
    private func startReplay() {
        stopReplay()
        guard scenePhase == .active else { return }
        #if DEBUG
        if demoTable != nil, ProcessInfo.processInfo.environment["GT_DEMO_FREE_MOTION"] == nil { return }
        if ProcessInfo.processInfo.environment["GT_DEMO_FREE_MOTION_FREEZE"] != nil { return }
        if ProcessInfo.processInfo.environment["GT_DEMO_FREE_MOTION_MANUAL"] != nil, !motionStarted { return }
        #endif
        guard let table = presentationTable else { return }
        var plan = FreeTableReplayPlan(table: table, previous: previousHand, reduceMotion: reduceMotion)
        if let old = replayPlan, old.table.handID == table.handID {
            plan.preservePrefix(from: old, at: replayCursor.elapsed)
        }
        replayPlan = plan
        let generation = replayGeneration
        replay = Task { @MainActor in
            var last = ProcessInfo.processInfo.systemUptime
            while !Task.isCancelled, generation == replayGeneration, scenePhase == .active,
                  replayCursor.elapsed < plan.duration {
                do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
                guard !Task.isCancelled, generation == replayGeneration, scenePhase == .active else { return }
                let now = ProcessInfo.processInfo.systemUptime
                let requests = replayCursor.advance(by: (now - last) * 1000 * replaySpeed, plan: plan)
                last = now
                let projection = replayCursor.projection(plan: plan)
                shownSteps = projection.shownSteps
                thinkingSeat = projection.thinkingSeat
                for request in requests { requestFeedback(request) }
            }
            guard !Task.isCancelled, generation == replayGeneration else { return }
            thinkingSeat = nil
            if table.currentSeat == 0, table.review == nil, !table.legalActions.isEmpty {
                let decision = "\(table.handID)-\(table.events.count)"
                if decision != lastTurn { lastTurn = decision; requestFeedback(.yourTurn) }
            }
        }
    }

    private func cancelFeedback() {
        feedbackTask?.cancel()
        feedbackTask = nil
        feedback.invalidate()
    }

    private func requestFeedback(_ kind: TableFeedbackKind) {
        guard scenePhase == .active else { return }
        feedback.request(kind, at: ProcessInfo.processInfo.systemUptime * 1000)
        guard feedbackTask == nil, let deadline = feedback.deadline else { return }
        let generation = feedback.generation
        feedbackTask = Task { @MainActor in
            let remaining = max(0, deadline - ProcessInfo.processInfo.systemUptime * 1000)
            do { try await Task.sleep(for: .milliseconds(remaining)) } catch { return }
            guard !Task.isCancelled, scenePhase == .active, generation == feedback.generation else { return }
            feedbackPulse = feedback.emit(at: ProcessInfo.processInfo.systemUptime * 1000, generation: generation)
            feedbackTask = nil
        }
    }

    #if DEBUG
    private func configureMotion() -> Bool {
        let env = ProcessInfo.processInfo.environment
        guard let kind = env["GT_DEMO_FREE_MOTION"] else { return false }
        do {
            let table: PracticeTableState
            if kind.hasPrefix("deal-") {
                var fresh = PracticeTableState(seed: 97, styles: Array(repeating: .station, count: max(1, (Int(kind.suffix(1)) ?? 4) - 1)), handID: kind)
                try fresh.advanceBots()
                table = fresh
            } else { table = try FreeTableReplayFixtures.table(kind) }
            demoTable = table
            shownHandID = table.handID
            shownSteps = 0
            replaySpeed = env["GT_DEMO_FREE_MOTION_SPEED"].flatMap(Double.init) ?? 1
            resetPlan(table, shown: 0)
            if let start = env["GT_DEMO_FREE_MOTION_START"], let plan = replayPlan {
                let phase = plan.phases.first { String(describing: $0.work).hasPrefix(start) }
                let fraction = env["GT_DEMO_FREE_MOTION_FRACTION"].flatMap(Double.init) ?? 0
                let time = (phase?.start ?? 0) + (phase?.duration ?? 0) * max(0, min(1, fraction))
                replayCursor.elapsed = time
                replayCursor.cueIndex = plan.cues.prefix { $0.time < time }.count
                shownSteps = plan.projection(at: time).shownSteps
            }
            if let time = env["GT_DEMO_FREE_MOTION_TIME"].flatMap(Double.init), let plan = replayPlan {
                replayCursor.elapsed = time
                shownSteps = plan.projection(at: time).shownSteps
            }
            startReplay()
            return true
        } catch { preconditionFailure("Invalid legal motion fixture: \(kind): \(error)") }
    }

    /// Frozen public replay prefixes for screenshot inspection; never writes the app store.
    private func configureDemoPhase(_ current: PracticeTableState) -> Bool {
        guard let phase = ProcessInfo.processInfo.environment["GT_DEMO_FREE_PHASE"] else { return false }
        let styles = current.computerSeats.map(\.style)
        let backTab = ProcessInfo.processInfo.environment["GT_DEMO_FREE_BACK"]
        var fixture = PracticeTableState(seed: 97, styles: styles, handID: "demo-face")
        if phase == "result-fold" {
            fixture = PracticeTableState(seed: 31, styles: [.station], handID: "demo-fold-review")
            try? fixture.apply(.fold, actionID: "demo-hero-fold")
            precondition(fixture.review != nil, "Fold review fixture must settle")
        } else if phase == "result-review" {
            fixture = PracticeTableState(seed: 31, styles: [.station], handID: "demo-review-one")
            try? fixture.apply(.fold, actionID: "demo-hand-one-fold")
            try? fixture.nextHand(handID: "demo-review-two")
            try? fixture.apply(.call, actionID: "demo-computer-limp")
            try? fixture.apply(.check, actionID: "demo-hero-check")
            for index in 0..<3 {
                try? fixture.apply(.check, actionID: "demo-hero-check-\(index)")
                try? fixture.apply(.raise(to: 2), actionID: "demo-computer-bet-\(index)")
                try? fixture.apply(.call, actionID: "demo-hero-call-\(index)")
            }
            precondition(fixture.review?.board.count == 5, "Review fixture must be a legal settled showdown")
        } else if phase == "result-tie" {
            fixture = PracticeTableState(seed: 311, styles: [.station, .station, .station], handID: "demo-tie")
        }
        if phase.hasPrefix("raise-postflop") {
            fixture = PracticeTableState(seed: phase == "raise-postflop-raise" ? 99 : 97,
                                         styles: [.nit, .station, .lag], handID: "demo-postflop")
        }
        try? fixture.advanceBots()
        if phase == "raise-short-stack" {
            fixture = PracticeTableState(seed: 97, styles: [.station, .station, .station], handID: "demo-short-stack")
            for (index, action) in [PracticeAction.call, .raise(to: 97), .call, .call, .raise(to: 100), .fold].enumerated() {
                try? fixture.apply(action, actionID: "demo-short-\(index)")
            }
            try? fixture.advanceBots()
            try? fixture.nextHand(handID: "demo-short-next")
            precondition(fixture.currentSeat == 0 && fixture.seats[0].stack == 3, "Short-stack fixture must preserve a legal three-chip learner stack")
        } else if phase == "raise-facing" {
            fixture = PracticeTableState(seed: 31, styles: [.station], handID: "demo-raise-facing")
            try? fixture.apply(.call, actionID: "demo-hero-call")
            try? fixture.apply(.raise(to: 4), actionID: "demo-computer-raise")
        } else if phase == "all-in-call" {
            fixture = PracticeTableState(seed: 97, styles: styles, handID: "demo-face")
            try? fixture.apply(.raise(to: 100), actionID: "demo-bot-all-in")
            try? fixture.advanceBots()
        } else if phase == "runout" || phase == "result-all-in" || phase == "short-all-in" {
            for seed in 97..<147 {
                var candidate = PracticeTableState(seed: UInt64(seed), styles: styles, handID: "demo-face")
                try? candidate.advanceBots()
                guard candidate.legalActions.contains(where: { if case .raise = $0 { true } else { false } }) else { continue }
                try? candidate.apply(.raise(to: candidate.seats[0].stack + candidate.seats[0].streetCommitted), actionID: "demo-all-in")
                try? candidate.advanceBots()
                if candidate.review?.board.count == 5,
                   phase != "short-all-in" || (candidate.review?.endingStacks[0] ?? 0) > 100 {
                    fixture = candidate
                    break
                }
            }
        } else if phase == "dealing" || phase == "result" || phase == "result-tie" || phase.hasPrefix("raise-postflop") {
            for index in 0..<40 where fixture.review == nil {
                let action: PracticeAction = fixture.legalActions.contains(.check) ? .check : .call
                try? fixture.apply(action, actionID: "demo-\(index)")
                try? fixture.advanceBots()
                if (phase == "dealing" || phase.hasPrefix("raise-postflop")), fixture.visibleBoard.count > 0 { break }
            }
        }
        if phase == "short-all-in" {
            try? fixture.nextHand(handID: "demo-short-all-in")
            try? fixture.apply(.raise(to: 80), actionID: "demo-hero-raise")
            try? fixture.apply(.call, actionID: "demo-bot-1-call")
            try? fixture.apply(.call, actionID: "demo-bot-2-call")
            try? fixture.apply(.raise(to: 100), actionID: "demo-bot-short-all-in")
        }
        precondition(phase != "all-in-call" || (fixture.currentSeat == 0 && fixture.amountToCall >= fixture.seats[0].stack), "All-in call demo must require the learner's remaining stack")
        precondition(phase != "short-all-in" || (fixture.currentSeat == 0 && fixture.seats[0].stack > fixture.amountToCall && !fixture.legalActions.contains(where: { if case .raise = $0 { true } else { false } })), "Short all-in demo must block reopening with chips left")
        precondition((phase != "runout" && phase != "result-all-in") || fixture.review?.board.count == 5, "Run-out demo requires a real all-in showdown")
        precondition(phase != "result" || fixture.review != nil, "Result demo must settle")
        precondition(phase != "result-tie" || (fixture.review?.payouts.filter { $0 > 0 }.count ?? 0) >= 3,
                     "Result tie demo must have three public winners")
        let steps = fixture.replaySteps
        let count: Int
        if phase == "computer", let index = steps.firstIndex(where: { step in
            if case let .action(index) = step { return fixture.events[index].seat != 0 && fixture.events[index].action != nil }
            return false
        }), case let .action(eventIndex) = steps[index] {
            count = index
            thinkingSeat = fixture.events[eventIndex].seat
        } else if phase == "dealing" || phase == "runout" {
            count = steps.firstIndex(where: { if case .deal = $0 { true } else { false } }) ?? steps.count
        } else {
            count = steps.count
        }
        precondition(phase != "computer" || thinkingSeat != nil, "Computer demo requires an actual bot action")
        precondition(phase != "dealing" || count < steps.count, "Dealing demo requires an actual deal")
        print("Free dock demo phase=\(phase), shown=\(count)/\(steps.count), seed=\(fixture.seed)")
        if phase.hasPrefix("raise-") {
            let sizing = FreeRaisePresentation(table: fixture)
            precondition(fixture.currentSeat == 0 && sizing.minimum > 0, "Raise demo must be an actual legal learner decision")
            raising = true
            raiseAmount = sizing.minimum
        }
        if let backTab {
            showHelp = true
            helpTab = backTab == "rules" ? .rules : backTab == "hand" ? .hand : .hint
        }
        demoTable = fixture
        shownHandID = fixture.handID
        shownSteps = count
        return true
    }
    #endif

    private var replaySnapshot: String {
        #if DEBUG
        if ProcessInfo.processInfo.environment["GT_DEMO_FREE_MOTION"] != nil,
           let plan = replayPlan {
            let p = replayCursor.projection(plan: plan)
            let phase = plan.phases.first { $0.end > replayCursor.elapsed }
            return "\(phase.map { String(describing: $0.work) } ?? "finished")|\(Int(replayCursor.elapsed))|\(p.shownSteps)|\(p.frame.stacks)|\(p.pot)|\(p.inTransit)|cue=\(replayCursor.cueIndex)|credits=\(p.credits.sorted { $0.key < $1.key })"
        }
        #endif
        return ""
    }

    private var replayDebugValue: String {
        #if DEBUG
        if ProcessInfo.processInfo.environment["GT_DEMO_FREE_MOTION"] != nil {
            return replaySnapshot + "#paused=" + pausedSnapshot + "#resumed=" + resumedSnapshot
                + "#feedback=\(feedbackPulse?.sequence ?? 0):\(String(describing: feedbackPulse?.kind))"
        }
        #endif
        return ""
    }

    // MARK: Words

    private func seatName(_ seat: Int) -> String {
        FreeTableWords.seatName(seat, language: language)
    }

    private func eventDescription(_ event: PracticeEvent) -> String {
        FreeTableWords.event(event, language: language)
    }
}

struct FreeDockChoices: Equatable {
    let owed: Int
    let price: Int
    let allIn: Bool
    let bet: Bool

    init(frame: PracticeTableFrame) {
        let publicBet = max(frame.street == .preflop ? 2 : 0, frame.streetCommitted.max() ?? 0)
        owed = max(0, publicBet - frame.streetCommitted[0])
        price = min(owed, frame.stacks[0])
        allIn = owed > 0 && price == frame.stacks[0]
        bet = frame.street != .preflop && publicBet == 0
    }
}

enum FreeTableWords {
    /// The computers have names, so a hand reads like a story about people.
    static func seatName(_ seat: Int, language: LearningLanguage) -> String {
        switch seat {
        case 0: language.text("나", "You")
        case 1: language.text("토마스", "Tom")
        case 2: language.text("마이클", "Mike")
        default: language.text("알렉스", "Alex")
        }
    }

    /// The beginner chart's rule for a hand of this strength. The hint and the hand
    /// review both read it from here.
    static func chartAdvice(_ strength: PracticeCoachStep.Strength, language: LearningLanguage) -> String {
        switch strength {
        case .premium: language.text("가장 좋은 시작 패(상위 \(PracticeHandCoach.premiumPercent)%)는 레이즈해요.",
                                     "Raise your best starting hands (the top \(PracticeHandCoach.premiumPercent)%).")
        case .playable: language.text("괜찮은 시작 패는 싸게 들어가요. 콜이나 체크가 기본이에요.",
                                      "Play decent starting hands cheaply. Calling or checking is the default.")
        case .weak: language.text("약한 시작 패는 칩이 들면 포기해요. 공짜면 체크해요.",
                                  "Fold weak starting hands when they cost chips. Check when it's free.")
        case .strong, .topPair: language.text("탑 페어 이상이면 벳하거나 레이즈해서 팟을 키워요.",
                                              "With top pair or better, bet or raise to build the pot.")
        case .weakPair: language.text("약한 페어는 체크하고, 작은 벳만 콜해요.",
                                      "With a weak pair, check, and call only small bets.")
        case .draw: language.text("드로우는 가격이 쌀 때만 콜해요. 카드 두 장이 남았으면 세 번에 한 번, 한 장이면 다섯 번에 한 번쯤 완성돼요.",
                                  "Call with a draw only when it's cheap. It comes in about 1 time in 3 with two cards to come, 1 in 5 with one.")
        case .air: language.text("아무것도 없으면 체크하거나 포기해요.", "With nothing, check or fold.")
        }
    }

    static func event(_ event: PracticeEvent, language: LearningLanguage) -> String {
        switch event.label {
        case "small blind": language.text("스몰 블라인드 +\(event.chips)", "Small blind +\(event.chips)")
        case "big blind": language.text("빅 블라인드 +\(event.chips)", "Big blind +\(event.chips)")
        case "fold": language.text("포기", "Folded")
        case "check": language.text("체크", "Checked")
        case "call": language.text("콜 +\(event.chips)", "Called +\(event.chips)")
        case "bet": language.text("벳 +\(event.chips)", "Bet +\(event.chips)")
        default: language.text("레이즈 +\(event.chips)", "Raised +\(event.chips)")
        }
    }

    static func street(_ street: PracticeStreet, language: LearningLanguage) -> String {
        switch street {
        case .preflop: language.text("프리플랍", "Preflop")
        case .flop: language.text("플랍", "Flop")
        case .turn: language.text("턴", "Turn")
        case .river, .finished: language.text("리버", "River")
        }
    }
}

// MARK: - Help panel

enum FreeTableHelpTab: Hashable { case hint, hand, rules }

@MainActor
enum FreeTableCloseSymbol {
    private static let cropped = crop()
    static var image: UIImage { cropped.image }
    static var sourceBounds: CGRect { cropped.bounds }
    static var opaquePixelCount: Int { cropped.count }

    // SF Symbols include transparent alignment gutters. Crop only those pixels,
    // then let the body-scaled canvas and the minimum target size handle layout.
    private static func crop() -> (image: UIImage, bounds: CGRect, count: Int) {
        let symbol = UIImage(systemName: "arrow.clockwise",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 128, weight: .regular))
        guard let symbol else { return (UIImage(), .zero, 0) }
        let template = symbol.withTintColor(.white, renderingMode: .alwaysOriginal)
        let raster = UIGraphicsImageRenderer(size: template.size).image { _ in template.draw(at: .zero) }
        guard let source = raster.cgImage else { return (symbol.withRenderingMode(.alwaysTemplate), .zero, 0) }
        let width = source.width, height = source.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &bytes, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return (symbol.withRenderingMode(.alwaysTemplate), .zero, 0)
        }
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        var left = width, top = height, right = 0, bottom = 0, count = 0
        for y in 0..<height {
            for x in 0..<width where bytes[(y * width + x) * 4 + 3] > 0 {
                left = min(left, x); top = min(top, y)
                right = max(right, x + 1); bottom = max(bottom, y + 1); count += 1
            }
        }
        let bounds = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        guard let visible = source.cropping(to: bounds) else {
            return (symbol.withRenderingMode(.alwaysTemplate), .zero, 0)
        }
        let image = UIImage(cgImage: visible, scale: raster.scale,
                            orientation: .up).withRenderingMode(.alwaysTemplate)
        return (image, bounds, count)
    }
}

private struct FreeTableBackHeader: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var firstRoleMetric = 18
    @ScaledMetric(relativeTo: .body) private var closeSymbolSize = 17
    @Binding var tab: FreeTableHelpTab
    let onClose: () -> Void
    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    close
                    ScrollView(.horizontal) { tabs }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("free-back-tabs")
                }
            } else {
                HStack(alignment: .top, spacing: 6) { tabs; close }
            }
        }
        .padding(.top, min(GT.Space.sheet,
            GT.TextRole.title(18).inkLeading(in: language) * firstRoleMetric / 18))
    }
    private var tabs: some View {
        HStack(spacing: 6) {
            button(.hint, language.text("선택 도움말", "Help"))
            button(.hand, language.text("핸드 기록", "History"))
            button(.rules, language.text("테이블 안내", "Guide"))
        }
    }
    private var close: some View {
        Button(action: onClose) {
            let tile = max(ChromeGlyph.tile, closeSymbolSize + 22)
            Image(uiImage: FreeTableCloseSymbol.image).resizable().scaledToFit()
                .frame(width: closeSymbolSize, height: closeSymbolSize)
                .frame(width: tile, height: tile)
                .background { GTControlBackground() }
                .frame(minWidth: 44, minHeight: 44,
                       alignment: typeSize.isAccessibilitySize ? .topLeading : .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
            .foregroundStyle(GT.ink).accessibilityLabel(language.text("테이블로 돌아가기", "Back to table"))
            .accessibilityIdentifier("free-table-back-close")
    }
    private func button(_ value: FreeTableHelpTab, _ title: String) -> some View {
        GTChoiceButton(title: title, selected: tab == value, minHeight: 44) { tab = value }
            .fixedSize(horizontal: typeSize.isAccessibilitySize, vertical: false)
            .accessibilityIdentifier("free-back-\(value)")
            .accessibilityHint(destinationHint(value))
            .accessibilityAddTraits(tab == value ? .isSelected : [])
    }
    private func destinationHint(_ value: FreeTableHelpTab) -> String {
        switch value {
        case .hint: language.text("콜 가격과 선택 가능한 초보자 차트 도움말을 봐요", "See the call price and optional beginner-chart suggestion")
        case .hand: language.text("행동 순서와 칩 이동을 돌아봐요", "Review actions and chip movement")
        case .rules: language.text("테이블과 컴퓨터의 선택 방식을 알아봐요", "Learn the table and computer choices")
        }
    }
}

struct FreeMathDots {
    static func count(neededPercent: Int?) -> Int? {
        guard let neededPercent, Double(neededPercent) >= 100.0 / 6 else { return nil }
        return (2...6).min { abs(Double(neededPercent) / 100 - 1.0 / Double($0))
            < abs(Double(neededPercent) / 100 - 1.0 / Double($1)) }
    }
}

private struct FreeTableMathTiles: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var dotSize = 6
    @ScaledMetric(relativeTo: .body) private var dotGap = 4
    let pot: Int
    let call: Int
    let need: Int?
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if typeSize.isAccessibilitySize {
                ScrollView(.horizontal) { tiles }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("free-math-row")
            } else { tiles }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("free-math-tiles")
    }
    private var tiles: some View {
        HStack(alignment: .top, spacing: 6) {
            tile(language.text("팟", "Pot"), value: "\(pot)", id: "pot",
                 background: GT.tableFelt, ink: .white)
            tile(language.text("콜", "Call"), value: "\(call)", id: "call",
                 labelInk: scheme == .dark ? GT.cta : Color(hex: 0x8A5500),
                 background: scheme == .dark ? GT.cta.opacity(0.12) : Color(hex: 0xF5E6C8),
                 ink: scheme == .dark ? GT.cta : Color(hex: 0x6B4300))
            tile(language.text("필요 지분", "Need equity"), value: need.map { "\($0)%" } ?? "—", id: "need",
                 background: scheme == .dark ? GT.glass : .white, ink: GT.ink,
                 dots: FreeMathDots.count(neededPercent: need))
        }
    }
    private func tile(_ label: String, value: String, id: String, labelInk: Color? = nil,
                      background: Color, ink: Color, dots: Int? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(GT.semibold(13)).foregroundStyle(labelInk ?? ink)
                .fixedSize(horizontal: typeSize.isAccessibilitySize, vertical: true)
            HStack(spacing: 6) {
                Text(value).font(GT.title(24)).monospacedDigit()
                    .fixedSize(horizontal: typeSize.isAccessibilitySize, vertical: true)
                if let dots { dotGrid(dots) }
            }
        }
        .frame(maxWidth: typeSize.isAccessibilitySize ? nil : .infinity, alignment: .leading)
        .gtInset(10, firstText: .semibold(13))
        .fixedSize(horizontal: typeSize.isAccessibilitySize, vertical: false)
        .foregroundStyle(ink).background(background, in: RoundedRectangle(cornerRadius: GT.Radius.tile))
        .overlay(RoundedRectangle(cornerRadius: GT.Radius.tile)
            .strokeBorder(scheme == .dark ? GT.border : Color(hex: 0xE3DAC7), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("free-math-\(id)")
    }
    private func dotGrid(_ count: Int) -> some View {
        VStack(spacing: dotGap) {
            ForEach(0..<((count + 1) / 2), id: \.self) { row in
                HStack(spacing: dotGap) {
                    ForEach(0..<2, id: \.self) { column in
                        let index = row * 2 + column
                        if index < count {
                            if index == 0 {
                                Circle().fill(Color(hex: 0xB37A12)).frame(width: dotSize, height: dotSize)
                            } else {
                                Circle().strokeBorder(GT.borderStrong, lineWidth: 1)
                                    .frame(width: dotSize, height: dotSize)
                            }
                        } else { Color.clear.frame(width: dotSize, height: dotSize) }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.text("무승부가 없다면 약 \(count)번 중 1번", "Without ties, about 1 in \(count)"))
    }
}

private struct FreeTableMathSummary: View {
    @Environment(\.learningLanguage) private var language
    let pot: Int
    let call: Int
    let need: Int?
    let hand: String?
    let top: Int?
    let hole: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FreeTableMathTiles(pot: pot, call: call, need: need)
            if let need {
                Text(PracticePriceCopy.threshold(need, language: language))
                    .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(language.text("점은 무승부가 없을 때의 대략적인 비율이에요.",
                                   "The dots illustrate an approximate fraction without ties."))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top, spacing: 8) {
                Text(language.text("현재 패", "Hand")).font(GT.semibold(13))
                if let hand { Text(hand).font(GT.semibold(15)) }
                else {
                    ForEach(hole, id: \.self) { raw in
                        if let card = Card(raw) { PlayingCardView(card: card, size: 36) }
                    }
                    if let top {
                        Text(language.text("상위 \(top)%", "Top \(top)%")).font(GT.semibold(13))
                            .padding(6).background(GT.glass, in: Capsule())
                    }
                }
            }.foregroundStyle(GT.ink).fixedSize(horizontal: false, vertical: true)
             .accessibilityElement(children: .contain)
             .accessibilityIdentifier("free-math-hand")
        }
    }
}

private struct FreeTableBackFace: View {
    @Environment(\.learningLanguage) private var language
    let table: PracticeTableState
    let frame: PracticeTableFrame
    let shownSteps: Int
    var heroExposed = true
    var shownPot: Int?
    @Binding var tab: FreeTableHelpTab
    @Binding var revealFolded: Bool
    let minimumHeight: CGFloat
    let onNext: () -> Void
    let onClose: () -> Void
    /// The decision the learner asked for a suggestion on. A later decision starts hidden again.
    @State private var suggestedAt: Int?

    var body: some View {
        GTAnchoredDockFaceLayout(minimumHeight: minimumHeight, scrollsBody: true) {
            FreeTableBackHeader(tab: $tab, onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch tab {
                    case .hint: hint
                    case .hand: hand
                    case .rules: rules
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("free-back-content")
            .clipped()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("free-table-help-sheet")
    }

    private func panel<C: View>(_ label: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label, onDark: false)
            content()
        }
        .font(GT.body(15)).foregroundStyle(GT.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
    }

    // MARK: Hint

    @ViewBuilder private var hint: some View {
        if frame.settled {
            panel(language.text("이 핸드를 돌아봐요", "Review this hand")) {
                Text(language.text("지금은 고를 행동이 없어요. ‘핸드 기록’에서 선택과 칩 이동을 확인해요.",
                                   "There is no decision left. Open History to review your choices and chip movement."))
                    .font(GT.body(16)).fixedSize(horizontal: false, vertical: true)
                SecondaryCTAButton(title: language.text("이 핸드 보기", "Review this hand")) { tab = .hand }
                    .accessibilityIdentifier("free-finished-help-review")
                SecondaryCTAButton(title: table.isGameOver
                    ? language.text("새 게임 시작", "Start new game")
                    : language.text("다음 핸드", "Next hand"), action: onNext)
                    .accessibilityIdentifier("free-finished-help-next")
            }
        } else if heroExposed, let facts = PracticeDecisionFacts(frame: frame, learnerHole: table.learnerHole,
                                             visibleBoard: table.review?.board ?? table.visibleBoard) {
            if table.currentSeat == 0, shownSteps == table.replaySteps.count {
                panel(language.text("선택의 뜻", "What each action means")) {
                    Text(language.text(facts.toCall > 0
                        ? "폴드: 이번 핸드를 포기해요. 콜: \(facts.toCall)칩을 따라 내요. 레이즈: 금액을 골라 더 올려요."
                        : "체크: 칩을 더 내지 않고 넘겨요. 벳: 금액을 골라 먼저 걸어요.",
                        facts.toCall > 0
                        ? "Fold: give up this hand. Call: add \(facts.toCall) chips. Raise: choose an amount to increase the bet."
                        : "Check: pass without adding chips. Bet: choose an amount to put in first."))
                        .font(GT.body(16)).fixedSize(horizontal: false, vertical: true)
                }
            }
            FreeTableMathSummary(pot: shownPot ?? facts.pot, call: facts.toCall, need: facts.requiredEquityPercent,
                                 hand: facts.madeHand.map { DrillTerms.hand($0, in: language) },
                                 top: facts.startingHandTopPercent, hole: table.learnerHole)
            if table.street != .finished, table.currentSeat == 0, shownSteps == table.replaySteps.count,
               let hole = Card.parse(table.learnerHole.joined()),
               let board = Card.parse(table.visibleBoard.joined()) {
                let strength = PracticeHandCoach.strength(hole: hole, board: board,
                                                          topPercent: facts.startingHandTopPercent)
                if suggestedAt == table.events.count {
                    panel(language.text("초보자 차트의 제안", "The beginner chart suggests")) {
                        if let pick = PracticeHandCoach.suggestion(strength: strength, toCall: facts.toCall,
                               needed: facts.requiredEquityPercent, boardCount: board.count,
                               legal: table.legalActions) {
                            Text(suggestionName(pick, toCall: facts.toCall)).font(GT.semibold(17))
                        }
                        Text(FreeTableWords.chartAdvice(strength, language: language))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(language.text("몇 가지 쉬운 규칙이에요. 따르지 않아도 괜찮아요.",
                                           "A few simple rules. You don't have to follow them."))
                            .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("free-hint")
                } else {
                    SecondaryCTAButton(title: language.text("초보자 차트는 어떻게 할까요?",
                                                            "What would the beginner chart do?")) {
                        suggestedAt = table.events.count
                    }
                    .accessibilityIdentifier("free-hint-show")
                }
            }
        }
    }

    private func suggestionName(_ action: PracticeAction, toCall: Int) -> String {
        switch action {
        case .fold: language.text("포기", "Fold")
        case .check: language.text("체크", "Check")
        case .call: language.text("콜", "Call")
        case .raise: toCall == 0 && table.street != .preflop ? language.text("벳", "Bet") : language.text("레이즈", "Raise")
        }
    }

    // MARK: This hand

    @ViewBuilder private var hand: some View {
        let visibleIndices = table.replaySteps.prefix(shownSteps).compactMap { step -> Int? in
            if case let .action(index) = step { return index }; return nil
        }
        let events = visibleIndices.map { table.events[$0] }
        panel(language.text("행동 순서", "Action history")) {
            ForEach(Array(Dictionary(grouping: events.indices, by: { events[$0].street })
                .sorted { order($0.key) < order($1.key) }), id: \.key) { street, indices in
                Text(FreeTableWords.street(street, language: language)).font(GT.semibold(14))
                    .padding(.top, 4)
                ForEach(indices, id: \.self) { index in
                    let event = events[index]
                    Text("\(seatName(event.seat)) · \(FreeTableWords.event(event, language: language))")
                        .font(GT.body(14))
                }
            }
        }
        .accessibilityIdentifier("free-table-history")
        ForEach(table.computerSeats, id: \.seat) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text(seatName(entry.seat)).font(GT.semibold(15))
                Text(entry.style.beginnerDescription(in: language)).font(GT.body(14))
            }.foregroundStyle(GT.ink)
        }
        if let review = table.review, frame.settled {
            FreeTableDecisionReview(table: table)
            panel(language.text("칩 이동", "Chip movement")) {
                Text(language.text("이긴 결과와 좋은 결정은 달라요. 여기서는 실제 칩 이동만 확인해요.",
                                   "Winning a hand and making a good decision aren't the same. This shows the actual chip movement."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(0..<table.seatCount, id: \.self) { seat in
                    seatReview(seat, review: review)
                }
                if review.refunds.contains(where: { $0 > 0 }) {
                    Text(language.text("반환은 아무도 따라오지 않은 칩이에요. 팟에 들어가지 않고 낸 사람에게 돌아가요.",
                                       "Returned chips are the part of a bet nobody matched. They go back to the player who bet them."))
                        .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("free-table-refund-note")
                }
            }
            Toggle(language.text("폴드한 상대 카드도 보기", "Show folded opponents' cards"), isOn: $revealFolded)
                .accessibilityIdentifier("free-review-folded")
                .font(GT.body(14)).foregroundStyle(GT.ink)
            Text(language.text("상대 카드는 플레이할 때 알 수 없었던 정보예요.",
                               "Opponent cards were not available to you while playing."))
                .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
        }
    }

    private func order(_ street: PracticeStreet) -> Int {
        switch street {
        case .preflop: 0
        case .flop: 1
        case .turn: 2
        case .river: 3
        case .finished: 4
        }
    }

    private func seatReview(_ seat: Int, review: PracticeTableReview) -> some View {
        let shown = seat == 0 || revealFolded || (FreeTableView.wentToShowdown(review) && review.pots.contains { $0.eligibleSeats.contains(seat) })
        return VStack(alignment: .leading, spacing: 5) {
            Text(seatName(seat)).font(GT.semibold(15))
            Text(review.refunds[seat] > 0
                 ? language.text("낸 칩 \(review.contributions[seat]) · 반환 \(review.refunds[seat]) · 받은 팟 \(review.payouts[seat])",
                                 "Paid \(review.contributions[seat]) · Returned \(review.refunds[seat]) · Won \(review.payouts[seat])")
                 : language.text("낸 칩 \(review.contributions[seat]) · 받은 팟 \(review.payouts[seat])",
                                 "Paid \(review.contributions[seat]) · Won \(review.payouts[seat])"))
                .font(GT.body(14)).monospacedDigit()
            if shown {
                HStack(spacing: 5) {
                    ForEach(review.holeCards[seat].highCardFirst, id: \.self) { raw in
                        if let card = Card(raw) { PlayingCardView(card: card, size: 44) }
                    }
                }
                if review.board.count == 5,
                   let cards = Card.parse((review.holeCards[seat] + review.board).joined()) {
                    Text(DrillTerms.hand(bestHand(cards), in: language)).font(GT.semibold(14))
                    HStack(spacing: 4) {
                        ForEach(bestFiveCards(cards), id: \.self) { PlayingCardView(card: $0, size: 34) }
                    }
                    .accessibilityLabel(language.text("끝난 보드에서 만든 가장 좋은 다섯 장", "Best five cards on the final board"))
                }
            }
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func seatName(_ seat: Int) -> String {
        guard let style = table.computerSeats.first(where: { $0.seat == seat })?.style else {
            return language.text("나", "You")
        }
        return "\(FreeTableWords.seatName(seat, language: language)) · \(style.beginnerTitle(in: language))"
    }

    // MARK: Help

    @ViewBuilder private var rules: some View {
        PlayTableGuideList()
        DisclosureGroup {
            FreeTablePolicyDetails(table: table).padding(.top, 12)
        } label: {
            Text(language.text("컴퓨터 선택", "Computer choices"))
                .accessibilityIdentifier("free-table-policy-toggle")
        }
        .font(GT.semibold(15)).foregroundStyle(GT.ink)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("free-table-policy")
    }
}

/// How the computers pick, one block per computer actually at the table.
private struct FreeTablePolicyDetails: View {
    @Environment(\.learningLanguage) private var language
    let table: PracticeTableState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("규칙 \(PracticeTableState.rulesVersion) · 상대 정책 \(PracticeTableState.policyVersion)",
                               "Rules \(PracticeTableState.rulesVersion) · Bot policy \(PracticeTableState.policyVersion)"))
            ForEach(table.computerSeats, id: \.seat) { entry in
                let style = entry.style
                Text("\(FreeTableWords.seatName(entry.seat, language: language)): \(style.beginnerTitle(in: language))")
                    .font(GT.semibold(16))
                Text(language.text("처음 들어오는 핸드: Chen 점수 상위 \(Int(style.vpip))%, 올리는 핸드: 상위 \(Int(style.pfr))%",
                                   "Starting hands: top \(Int(style.vpip))% by Chen score; raising hands: top \(Int(style.pfr))%"))
                if style == .casual {
                    Text(language.text("공용 카드가 나온 뒤에는 탑 페어 이상이면 팟의 절반을 걸어요. 아무것도 없을 때도 일곱 번에 한 번쯤은 같은 금액을 걸어요(블러프). 페어나 드로우가 있으면 콜하고, 아무것도 없으면 대부분 포기해요. 이 선택은 자기 카드와 공개된 정보, 그리고 테이블마다 정해진 주사위 값으로만 정해져요.",
                                       "After the shared cards, it bets half the pot with top pair or better. About one time in seven it bets the same amount with nothing (a bluff). It calls with a pair or a draw, and mostly folds with nothing. These choices use only its own cards, public information and a dice roll fixed for each table."))
                }
                ForEach(style == .casual ? [] : MadeHand.allCases, id: \.self) { bucket in
                    let policy = style.postflop
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DrillTerms.madeHand(bucket, in: language)).font(GT.semibold(14))
                        Text(language.text("먼저 행동: ", "When checked to: ")
                             + (policy.opens(with: bucket) ? language.text("최소 벳", "minimum bet") : language.text("체크", "check")))
                        Text(language.text("상대가 걸면: ", "Facing a bet: ") + responseName(policy.response(toBetWith: bucket)))
                    }.padding(.vertical, 5)
                }
                Divider()
            }
            Text(language.text("공용 카드 전에는 Chen 점수 순으로 고른 핸드를 사용해요. 이후에는 공개된 족보별 행동 규칙을 따라, ‘재미로’ 스타일이 아니면 최소 금액으로 벳하거나 올려요. 자기 카드와 공개된 정보만 보고 골라요. 최적 전략이라는 뜻은 아니에요.", "Before shared cards, bots select hands ranked by Chen score. Afterward, they follow published hand-category rules and, unless they play just for fun, bet or raise the minimum. They see only their own cards and public information. This is not an optimal-strategy claim."))
            GlossaryChip(term: "시작 패 점수 (Chen)").accessibilityIdentifier("free-policy-chen-glossary")
            Text(language.text("D는 딜러 버튼이에요. 버튼 다음 두 사람이 1칩과 2칩을 먼저 내요. 매 핸드 버튼이 이동해요.", "D is the dealer button. The next two players post 1 and 2 chips. The button moves after each hand."))
            Text(language.text("컴퓨터는 각 베팅 라운드에 벳하거나 올리는 행동을 한 번만 해요. 그 뒤에는 콜하거나 체크해요. 사람의 벳 횟수를 제한하는 규칙은 아니에요.", "Each computer bets or raises at most once per betting round. After that, it calls or checks. This is a bot policy, not a limit on your raises."))
        }
        .font(GT.body(14)).foregroundStyle(GT.ink)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func responseName(_ response: PostflopPolicy.FacingBetResponse) -> String {
        switch response {
        case .fold: language.text("포기", "fold")
        case .call: language.text("콜", "call")
        case .raise: language.text("최소 금액으로 올리기. 올릴 수 없으면 콜", "minimum raise; call if raising is not allowed")
        }
    }
}

struct FreeRaisePresentation {
    struct Preset: Equatable {
        let korean: String
        let english: String
        let amount: Int
    }
    let street: PracticeStreet
    let minimum: Int
    let maximum: Int
    let committed: Int
    let currentBet: Int
    let pot: Int
    let toCall: Int

    init(street: PracticeStreet, minimum: Int, maximum: Int, committed: Int,
         currentBet: Int, pot: Int, toCall: Int) {
        self.street = street; self.minimum = minimum; self.maximum = maximum
        self.committed = committed; self.currentBet = currentBet; self.pot = pot; self.toCall = toCall
    }

    init(table: PracticeTableState) {
        let me = table.seats[0]
        self.init(street: table.street,
                  minimum: table.legalActions.compactMap { if case let .raise(to: value) = $0 { value } else { nil } }.first ?? 0,
                  maximum: me.stack + me.streetCommitted, committed: me.streetCommitted,
                  currentBet: me.streetCommitted + table.amountToCall, pot: table.pot, toCall: table.amountToCall)
    }

    var isBet: Bool { street != .preflop && currentBet == 0 }

    var presets: [Preset] {
        let allIn = Preset(korean: "올인", english: "All in", amount: maximum)
        if street == .preflop, currentBet <= 2 {
            return [2.0, 2.5, 3.0, 4.0].map { factor in
                let number = factor == factor.rounded() ? "\(Int(factor))" : "2.5"
                return Preset(korean: "\(number)배", english: "\(number)×", amount: rounded(factor * 2))
            } + [allIn]
        }
        if street == .preflop {
            return [2.5, 3.0, 4.0].map { factor in
                let number = factor == factor.rounded() ? "\(Int(factor))" : "2.5"
                return Preset(korean: "\(number)배", english: "\(number)×", amount: rounded(factor * Double(currentBet)))
            } + [Preset(korean: "팟", english: "Pot", amount: potTarget(1)), allIn]
        }
        return [Preset(korean: "⅓", english: "⅓", amount: potTarget(1.0 / 3)),
                Preset(korean: "½", english: "½", amount: potTarget(0.5)),
                Preset(korean: "¾", english: "¾", amount: potTarget(0.75)),
                Preset(korean: "팟", english: "Pot", amount: potTarget(1)), allIn]
    }

    func title(amount: Int, language: LearningLanguage) -> String {
        isBet ? language.text("\(amount)칩 벳", "Bet \(amount)")
            : language.text("\(amount)칩까지 레이즈", "Raise to \(amount)")
    }

    func context(amount: Int, language: LearningLanguage) -> String {
        let cost = max(0, amount - committed)
        if street == .preflop {
            // Say what the multiple is a multiple of, in chips.
            let base = currentBet <= 2 ? 2 : currentBet
            let ratio = Double(amount) / Double(base)
            let value = ratio == ratio.rounded() ? "\(Int(ratio))" : String(format: "%.1f", ratio)
            return currentBet <= 2
                ? language.text("내 칩에서 \(cost)칩 · 빅 블라인드(2칩)의 \(value)배",
                                "\(cost) from your chips · \(value)× the big blind (2)")
                : language.text("내 칩에서 \(cost)칩 · 앞 벳 \(base)칩의 \(value)배",
                                "\(cost) from your chips · \(value)× the bet of \(base)")
        }
        let denominator = isBet ? pot : pot + toCall
        let percent = denominator > 0 ? rounded(Double(amount - currentBet) * 100 / Double(denominator)) : 0
        return language.text("내 칩에서 \(cost)칩 · 팟의 \(percent)%", "\(cost) from your chips · \(percent)% of pot")
    }

    private func potTarget(_ fraction: Double) -> Int {
        let increment = rounded(fraction * Double(isBet ? pot : pot + toCall))
        let addition = currentBet.addingReportingOverflow(increment)
        return addition.overflow ? Int.max : addition.partialValue
    }

    private func rounded(_ value: Double) -> Int {
        guard value < Double(Int.max) else { return Int.max }
        return max(0, Int(value.rounded()))
    }
}

extension Array where Element == String {
    /// Hole cards in reading order, higher card first, as lessons and guides show them.
    /// The table state keeps the dealt order.
    var highCardFirst: [String] {
        sorted { a, b in
            guard let x = Card(a), let y = Card(b) else { return false }
            return BeatScript.byRank(x, y)
        }
    }
}
