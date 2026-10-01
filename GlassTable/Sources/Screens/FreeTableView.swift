// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills
import GlassTableEngine

/// The free table, full screen: the felt, your turn, and three buttons. Explanations
/// wait in a panel the learner opens only when they want one.
///
/// The model settles every computer action the moment the learner acts. This screen
/// replays those actions one seat at a time, so each move has a moment of its own and
/// the turn visibly comes back before the buttons open.
struct FreeTableView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let epoch: UUID
    /// A table that was just dealt replays from the blinds; a reopened one does not.
    var replayFromStart = false
    let onClose: () -> Void
    /// The finished table was left; the caller opens table setup.
    let onNewTable: () -> Void

    @State private var shownSteps = 0
    @State private var shownHandID = ""
    @State private var thinkingSeat: Int?
    @State private var movingChip: (seatID: String, arrived: Bool)?
    @State private var chipFromPot = false
    @State private var replay: Task<Void, Never>?
    @State private var raising = false
    @State private var raiseAmount = 0
    @State private var showHelp = false
    @State private var helpTab = FreeTableHelpTab.hint
    @State private var revealFolded = false
    @State private var showGuide = false
    @State private var confirmNewTable = false
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
    #endif

    private var presentationTable: PracticeTableState? {
        #if DEBUG
        if let demoTable { return demoTable }
        #endif
        return model.state.tableState
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
        .onAppear {
            TableHaptics.prepare()
            guard let table = model.state.tableState else { return }
            #if DEBUG
            if configureDemoPhase(table) { return }
            #endif
            shownHandID = table.handID
            shownSteps = replayFromStart ? 0 : table.replaySteps.count
            startReplay()
            if !PlayTableGuide.seen {
                #if DEBUG
                let env = ProcessInfo.processInfo.environment
                if env["GT_DEMO_PRACTICE"] != nil, env["GT_DEMO_PLAY_GUIDE"] == nil { return }
                #endif
                PlayTableGuide.seen = true
                showGuide = true
            }
        }
        .onDisappear {
            replay?.cancel()
        }
        .onChange(of: replayKey) { _, _ in
            guard let table = model.state.tableState else { return }
            if table.handID != shownHandID {
                shownHandID = table.handID
                shownSteps = 0
                revealFolded = false
                replaySpeed = 1
            }
            startReplay()
        }
        .onChange(of: model.epoch) { _, _ in onClose() }
        .sheet(isPresented: $showHelp) {
            if let table = model.state.tableState {
                FreeTableHelpSheet(table: table, tab: $helpTab, revealFolded: $revealFolded,
                                   replaying: isReplaying(table)) { showHelp = false }
            }
        }
        .sheet(isPresented: $showGuide) { PlayTableGuideView { showGuide = false } }
        .confirmationDialog(language.text("새 테이블을 시작할까요?", "Start a fresh table?"),
                            isPresented: $confirmNewTable, titleVisibility: .visible) {
            Button(language.text("테이블 다시 만들기", "Set up a new table")) {
                guard let table = model.state.tableState,
                      model.leaveFinishedTable(handID: table.handID, expectedEpoch: epoch) else { return }
                onNewTable()
            }
            Button(language.text("취소", "Cancel"), role: .cancel) {}
        } message: {
            Text(language.text("지금까지의 핸드 기록은 남아요. 새 테이블은 각자 100칩으로 시작해요.",
                               "Your hand history stays saved. The new table starts everyone at 100 chips."))
        }
        .alert(language.text("선택을 처리하지 못했어요", "Couldn't apply that choice"), isPresented: $failure) {
            Button(language.text("확인", "OK"), role: .cancel) {}
        } message: {
            Text(language.text("저장된 테이블은 그대로예요. 현재 차례와 가능한 선택을 다시 확인해 주세요.",
                               "Your saved table is unchanged. Check the current turn and available choices."))
        }
        .modifier(ProgressSaveNotice())
    }

    private var replayKey: String {
        guard let table = model.state.tableState else { return "" }
        return "\(table.handID)-\(table.replaySteps.count)"
    }

    private func isReplaying(_ table: PracticeTableState) -> Bool {
        table.handID != shownHandID || shownSteps < table.replaySteps.count
    }

    // MARK: Layout

    @ViewBuilder
    private func content(_ table: PracticeTableState) -> some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: 0) {
                    ScrollView { tableSurface(table).padding(.horizontal, 8) }
                    stableDock(table, heightLimit: availableHeight * 0.55 - 40)
                }
            } else {
                VStack(spacing: 12) {
                    tableSurface(table).padding(.horizontal, 8)
                    Spacer(minLength: 0)
                    stableDock(table, heightLimit: nil)
                }
            }
        }
        }
        .gtChrome(leading: {
            HStack(alignment: .top, spacing: 10) {
                ChromeButton.close(onClose)
                Text(title(table)).font(GT.semibold(15)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }, trailing: { EmptyView() })
    }

    private func title(_ table: PracticeTableState) -> String {
        let players = switch table.seatCount {
        case 2: language.text("두 명", "Two players")
        case 3: language.text("세 명", "Three players")
        default: language.text("네 명", "Four players")
        }
        return language.text("\(players) · \(table.handNumber + 1)번째 핸드",
                             "\(players) · Hand \(table.handNumber + 1)")
    }

    // MARK: Table

    private func tableSurface(_ table: PracticeTableState) -> some View {
        let frame = table.frame(after: shownCount(table))
        let board = (table.review?.board ?? table.visibleBoard).prefix(frame.boardCount)
        return TableSurface(
            seats: (0..<table.seatCount).map { seat($0, table: table, frame: frame) }
                + (table.seatCount == 3 ? [TableSeat(id: "practice-empty", place: .bottomLeading,
                    name: language.text("빈 자리", "Empty seat"), isEmpty: true)] : []),
            center: TableCenter(board: board.compactMap(Card.init), reservesBoard: true,
                                potTotal: language.text("\(frame.committed.reduce(0, +))칩",
                                                        "\(frame.committed.reduce(0, +)) chips")),
            movingChip: movingChip, chipFromPot: chipFromPot)
            .accessibilityIdentifier("practice-table")
    }

    private func shownCount(_ table: PracticeTableState) -> Int {
        table.handID == shownHandID ? min(shownSteps, table.replaySteps.count) : 0
    }

    /// Clockwise from the learner at the bottom right.
    private func seat(_ seat: Int, table: PracticeTableState, frame: PracticeTableFrame) -> TableSeat {
        let places: [TableSeat.Place] = switch table.seatCount {
        case 2: [.bottomTrailing, .topLeading]
        case 3: [.bottomTrailing, .topLeading, .topTrailing]
        default: [.bottomTrailing, .bottomLeading, .topLeading, .topTrailing]
        }
        let review = frame.settled ? table.review : nil
        let hand: TableSeat.Hand
        if seat == 0 {
            hand = .faceUp(table.learnerHole.compactMap(Card.init))
        } else if let review, revealFolded || (Self.wentToShowdown(review) && !frame.folded[seat]) {
            hand = .faceUp(review.holeCards[seat].compactMap(Card.init))
        } else {
            hand = .faceDown
        }
        let won = review?.pots.contains { $0.winners.contains(seat) } == true
        let style = table.computerSeats.first(where: { $0.seat == seat })?.style
        let status: String?
        if won, let review {
            status = "+\(review.payouts[seat])"
        } else if thinkingSeat == seat {
            status = language.text("생각 중…", "Thinking…")
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
            isDealer: table.dealer == seat,
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
                        ScrollView { controls(table, minimumHeight: geometry.size.height) }
                            .accessibilityIdentifier("free-dock-content")
                    } else {
                        controls(table, minimumHeight: geometry.size.height)
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

    // Reachable structures share the live presentation views; sizing never reads future cards.
    @ViewBuilder
    private var dockSizingTemplates: some View {
        ForEach([nil, language.text("남은 칩 전부로 콜해요", "Calling puts you all in"),
                 language.text("올인이 작아서 다시 올릴 수 없어요", "Their all-in was short, so no re-raise")], id: \.self) { warning in
            VStack(alignment: .leading, spacing: 12) {
                dockHeader(language.text("내 차례", "Your turn"), warning: warning, onMath: {})
                actionSlots(owed: 14, price: 14, allIn: true, bet: false,
                            foldEnabled: false, middleEnabled: false, raiseEnabled: false,
                            reason: "", onFold: {}, onMiddle: {}, onRaise: {})
            }
        }
        ForEach([language.text("컴퓨터 3 차례", "Computer 3's turn"),
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
    }

    private func skipLink(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(language.text("결과로 넘기기", "Skip to result"), action: action)
            .font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            .frame(minHeight: 44).accessibilityIdentifier("free-skip-result")
            .disabled(!enabled)
    }

    private func controls(_ table: PracticeTableState, minimumHeight: CGFloat) -> some View {
        GTAnchoredDockFaceLayout(minimumHeight: minimumHeight,
                                 scrollsBody: !isReplaying(table) && table.review != nil) {
            if raising && !isReplaying(table), table.review == nil {
                raiseHeader(FreeRaisePresentation(table: table), amount: raiseAmount,
                            onCancel: { raising = false }, onMath: { helpTab = .hint; showHelp = true })
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
        return table.review == nil ? language.text("내 차례", "Your turn")
            : language.text("핸드가 끝났어요", "Hand over")
    }

    private func warning(_ table: PracticeTableState) -> String? {
        guard !isReplaying(table), table.review == nil, table.currentSeat == 0,
              table.legalActions.contains(.call) else { return nil }
        if table.amountToCall >= table.seats[0].stack {
            return language.text("남은 칩 전부로 콜해요", "Calling puts you all in")
        }
        if !table.legalActions.contains(where: { if case .raise = $0 { true } else { false } }),
           table.seats[0].stack > table.amountToCall, publicShortAllIn(table) {
            return language.text("올인이 작아서 다시 올릴 수 없어요", "Their all-in was short, so no re-raise")
        }
        return nil
    }

    private func publicShortAllIn(_ table: PracticeTableState) -> Bool {
        let frame = table.frame(after: shownCount(table))
        guard frame.stacks.indices.contains(where: { $0 != 0 && !frame.folded[$0] && frame.stacks[$0] > 0 })
        else { return false }
        var committed = Array(repeating: 0, count: table.seatCount)
        var currentBet = frame.street == .preflop ? 2 : 0
        var fullRaise = 2
        var heroFacing: Int?
        var shortAfterHero = false
        for event in table.events where event.street == frame.street {
            committed[event.seat] += event.chips
            if event.label == "raise" || event.label == "bet" {
                let increment = committed[event.seat] - currentBet
                if increment >= fullRaise {
                    fullRaise = increment
                    shortAfterHero = false
                } else if event.seat != 0, heroFacing != nil, frame.stacks[event.seat] == 0 {
                    shortAfterHero = true
                }
                currentBet = committed[event.seat]
            }
            if event.seat == 0, event.action != nil { heroFacing = currentBet }
        }
        return shortAfterHero && heroFacing.map { currentBet - $0 < fullRaise } == true
    }

    private func statusRow(_ table: PracticeTableState) -> some View {
        dockHeader(dockTitle(table), warning: warning(table)) {
            helpTab = table.review != nil && !isReplaying(table) ? .hand : .hint
            showHelp = true
        }
    }

    private func dockHeader(_ title: String, warning: String?, onMath: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(title).font(GT.title(18)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("free-table-status")
                Spacer(minLength: 0)
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
        if !enabled || model.saveError != nil {
            raiseReason = reason
        } else if frame.stacks[0] <= owed {
            raiseReason = language.text("콜 뒤에 더 낼 칩이 없어요", "You have no chips beyond the call")
        } else if !frame.stacks.indices.contains(where: { $0 != 0 && !frame.folded[$0] && frame.stacks[$0] > 0 }) {
            raiseReason = language.text("추가 벳을 받을 상대 칩이 없어요", "No opponent has chips to answer another wager")
        } else if publicShortAllIn(table) {
            raiseReason = language.text("작은 올인으로 레이즈가 다시 열리지 않았어요", "The short all-in did not reopen raising")
        } else {
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
            TableHaptics.pass()
            raising = true
        })
    }

    private func actionSlots(owed: Int, price: Int, allIn: Bool, bet: Bool,
                             foldEnabled: Bool, middleEnabled: Bool, raiseEnabled: Bool,
                             reason: String, raiseReason: String? = nil, onFold: @escaping () -> Void,
                             onMiddle: @escaping () -> Void, onRaise: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            freeAction(language.text("폴드", "Fold"), price: "", role: .fold, side: .leading,
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
                       price: "", role: .aggressive, side: .trailing, enabled: raiseEnabled,
                       reason: raiseReason ?? reason,
                       action: onRaise)
                .accessibilityIdentifier("free-raise")
        }
    }

    private func freeAction(_ title: String, price: String, role: GTActionRole,
                            side: GTCornerSide = .none, enabled: Bool, reason: String,
                            action: @escaping () -> Void) -> some View {
        GTActionButton(title: title, price: price, role: role, freeTablePresentation: true,
                       minHeight: 87, cornerSide: side, action: action)
            .disabled(!enabled).opacity(enabled ? 1 : 0.45)
            .accessibilityHint(enabled ? "" : reason)
    }

    private func mathPill(onMath: @escaping () -> Void) -> some View {
        Button(action: onMath) {
            Label(language.text("계산", "Math"), systemImage: "function")
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
                raiseAmountTitle(sizing, amount: amount)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    raiseBack(onCancel: onCancel)
                    raiseAmountTitle(sizing, amount: amount)
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
            Image(systemName: "chevron.left").font(GT.semibold(18))
                .frame(width: 44, height: 44, alignment: .leading).contentShape(Rectangle())
        }
        .foregroundStyle(GT.ink).buttonStyle(GTPress())
        .accessibilityLabel(language.text("금액 선택 닫기", "Back to actions"))
        .accessibilityIdentifier("free-raise-cancel")
    }

    private func raiseAmountTitle(_ sizing: FreeRaisePresentation, amount: Int) -> some View {
        ScrollView {
            Text(sizing.title(amount: amount, language: language))
                .font(GT.title(24).monospacedDigit()).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("free-raise-amount")
        }
        .frame(height: raiseAmountHeight)
        .offset(y: GT.TextRole.title(18).inkLeading(in: language) * frontTitleMetric / 18
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
        }
    }

    private func raisePresets(_ sizing: FreeRaisePresentation, amount: Int, width: CGFloat?,
                              onAmount: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(sizing.presets.enumerated()), id: \.offset) { index, preset in
                let legal = (sizing.minimum...sizing.maximum).contains(preset.amount)
                Button { if legal { onAmount(preset.amount) } } label: {
                    VStack(spacing: 4) {
                        Text(language == .korean ? preset.korean : preset.english).font(GT.semibold(12))
                        Text("\(preset.amount)").font(GT.title(13).monospacedDigit())
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
                .frame(width: 68, height: 68)
                .background { GTDockControlBackground(side: title == "−" ? .leading : .trailing) }
        }
        .buttonStyle(GTHoldStepStyle(enabled: enabled)).disabled(!enabled).opacity(enabled ? 1 : 0.45)
        .accessibilityLabel(spoken)
        .accessibilityHint(enabled ? "" : title == "−"
            ? language.text("최소 레이즈 금액이에요", "At the minimum raise")
            : language.text("남은 칩 전부를 선택했어요", "All your remaining chips are selected"))
    }

    private func result(_ review: PracticeTableReview, table: PracticeTableState) -> some View {
        let net = review.endingStacks[0] - review.startingStacks[0]
        let text = net > 0 ? language.text("+\(net)칩", "+\(net) chips")
            : net < 0 ? language.text("−\(-net)칩", "−\(-net) chips") : language.text("±0칩", "±0 chips")
        let winners = (0..<table.seatCount).filter { review.payouts[$0] > 0 }
        return resultBody(netText: text, positive: net > 0, onNext: {
            TableHaptics.commit()
            perform {
                try model.nextTableHand(handID: UUID().uuidString, after: table.handID, expectedEpoch: epoch)
            }
        }, onReview: { helpTab = .hand; showHelp = true }, onChange: { confirmNewTable = true }) {
            ForEach(winners, id: \.self) { seat in
                Text(winnerLine(seat, review: review, table: table))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if table.seats.contains(where: { $0.stack == 0 }) {
                Text(language.text("칩이 없는 자리는 다음 핸드 전에 100칩을 새로 받아요.",
                                   "Seats with no chips get 100 before the next hand."))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func resultBody<Prose: View>(netText: String, positive: Bool,
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
            PrimaryCTAButton(title: language.text("다음 핸드", "Next hand"), action: onNext)
                .accessibilityIdentifier("free-next-hand")
            HStack(spacing: 8) {
                SecondaryCTAButton(title: language.text("핸드 돌아보기", "Review this hand"), action: onReview)
                    .accessibilityIdentifier("free-review")
                SecondaryCTAButton(title: language.text("테이블 바꾸기", "Change the table"), action: onChange)
                    .accessibilityIdentifier("free-change-table")
            }
        }
    }

    private func winnerLine(_ seat: Int, review: PracticeTableReview, table: PracticeTableState) -> String {
        let name = seatName(seat)
        guard Self.wentToShowdown(review), review.board.count == 5,
              let cards = Card.parse((review.holeCards[seat] + review.board).joined()) else {
            return language.text("\(name) · 팟 \(review.payouts[seat])칩",
                                 "\(name) · won \(review.payouts[seat]) chips")
        }
        let hand = DrillTerms.hand(bestHand(cards), in: language)
        return language.text("\(name) · 팟 \(review.payouts[seat])칩 · \(hand)",
                             "\(name) · won \(review.payouts[seat]) chips · \(hand)")
    }

    // MARK: Acting

    private func choose(_ action: PracticeAction, table: PracticeTableState) {
        TableHaptics.commit()
        perform {
            try model.applyTableAction(action, actionID: "\(table.handID)-learner-\(table.events.count)",
                                       handID: table.handID, expectedEpoch: epoch)
        }
    }

    private func perform(_ operation: () throws -> Bool) {
        do { if try !operation(), model.saveError == nil { failure = true } }
        catch { failure = true }
    }

    // MARK: Replay

    private enum Beat {
        case think, blind, afterAction, beforeDeal, afterDeal, beforeSettle
        var milliseconds: Int {
            switch self {
            case .think: 650
            case .blind: 180
            case .afterAction: 280
            case .beforeDeal: 300
            case .afterDeal: 380
            case .beforeSettle: 450
            }
        }
    }

    private func pause(_ beat: Beat) async -> Bool {
        let scale = (reduceMotion ? 0.5 : 1.0) / replaySpeed
        try? await Task.sleep(for: .milliseconds(Int(Double(beat.milliseconds) * scale)))
        return !Task.isCancelled
    }

    /// Steps the screen from what it shows to what the model holds.
    private func startReplay() {
        replay?.cancel()
        #if DEBUG
        if demoTable != nil { return }
        #endif
        replay = Task { @MainActor in
            while let table = model.state.tableState, table.handID == shownHandID {
                let steps = table.replaySteps
                guard shownSteps < steps.count else { break }
                switch steps[shownSteps] {
                case let .action(index):
                    let event = table.events[index]
                    let isComputer = event.seat != 0 && event.action != nil
                    if isComputer {
                        withAnimation(GT.Motion.change) { thinkingSeat = event.seat }
                        guard await pause(.think) else { return }
                    } else if event.action == nil {
                        guard await pause(.blind) else { return }
                    }
                    withAnimation(GT.Motion.change) {
                        thinkingSeat = nil
                        shownSteps += 1
                    }
                    if event.chips > 0 { flyChip(seat: event.seat, fromPot: false) }
                    if isComputer { event.chips > 0 ? TableHaptics.chips() : TableHaptics.pass() }
                    guard await pause(.afterAction) else { return }
                case .deal:
                    guard await pause(.beforeDeal) else { return }
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.85)) {
                        shownSteps += 1
                    }
                    TableHaptics.deal()
                    guard await pause(.afterDeal) else { return }
                case .settle:
                    guard await pause(.beforeSettle) else { return }
                    withAnimation(GT.Motion.change) { shownSteps += 1 }
                    if let review = table.review {
                        if let winner = review.payouts.firstIndex(where: { $0 > 0 }) {
                            flyChip(seat: winner, fromPot: true)
                        }
                        if review.endingStacks[0] > review.startingStacks[0] { TableHaptics.won() }
                    }
                }
            }
            thinkingSeat = nil
            if let table = model.state.tableState, table.currentSeat == 0, table.review == nil,
               table.events.last?.seat != 0 {
                TableHaptics.yourTurn()
            }
        }
    }

    #if DEBUG
    /// Frozen public replay prefixes for screenshot inspection; never writes the app store.
    private func configureDemoPhase(_ current: PracticeTableState) -> Bool {
        guard let phase = ProcessInfo.processInfo.environment["GT_DEMO_FREE_PHASE"] else { return false }
        let styles = current.computerSeats.map(\.style)
        var fixture = PracticeTableState(seed: 97, styles: styles, handID: "demo-face")
        if phase == "result-tie" {
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
        demoTable = fixture
        shownHandID = fixture.handID
        shownSteps = count
        return true
    }
    #endif

    private func flyChip(seat: Int, fromPot: Bool) {
        guard !reduceMotion else { return }
        let id = "practice-\(seat)"
        chipFromPot = fromPot
        movingChip = (id, false)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.timingCurve(0.77, 0, 0.175, 1, duration: 0.32)) { movingChip = (id, true) }
            try? await Task.sleep(for: .milliseconds(340))
            if movingChip?.seatID == id { movingChip = nil }
        }
    }

    // MARK: Words

    private func seatName(_ seat: Int) -> String {
        seat == 0 ? language.text("나", "You") : language.text("컴퓨터 \(seat)", "Computer \(seat)")
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
    static func event(_ event: PracticeEvent, language: LearningLanguage) -> String {
        switch event.label {
        case "small blind": language.text("SB +\(event.chips)", "Small blind +\(event.chips)")
        case "big blind": language.text("BB +\(event.chips)", "Big blind +\(event.chips)")
        case "fold": language.text("포기", "Folded")
        case "check": language.text("체크", "Checked")
        case "call": language.text("콜 +\(event.chips)", "Called +\(event.chips)")
        case "bet": language.text("베팅 +\(event.chips)", "Bet +\(event.chips)")
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

/// The slide-up panel: facts about the current decision, this hand's story, and how the
/// table works. The hint never names an action to take.
private struct FreeTableHelpSheet: View {
    @Environment(\.learningLanguage) private var language
    let table: PracticeTableState
    @Binding var tab: FreeTableHelpTab
    @Binding var revealFolded: Bool
    let replaying: Bool
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        tabButton(.hint, language.text("힌트", "Hint"))
                        tabButton(.hand, language.text("이번 핸드", "This hand"))
                        tabButton(.rules, language.text("도움말", "Help"))
                    }
                    switch tab {
                    case .hint: hint
                    case .hand: hand
                    case .rules: rules
                    }
                }
                .gtContentEdge()
            }
            .background(FeltBackground())
            .gtChrome(leading: { ChromeButton.close(onClose) })
            .gtSheetSurface()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("free-table-help-sheet")
    }

    private func tabButton(_ value: FreeTableHelpTab, _ title: String) -> some View {
        GTChoiceButton(title: title, selected: tab == value, minHeight: 40) { tab = value }
            .accessibilityAddTraits(tab == value ? .isSelected : [])
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
        if !replaying, let facts = PracticeDecisionFacts(table: table) {
            panel(language.text("내 핸드", "Your hand")) {
                if let name = facts.startingHand, let top = facts.startingHandTopPercent {
                    Text(language.text("\(name) · 시작 핸드 중 상위 \(top)%", "\(name) · top \(top)% of starting hands"))
                        .font(GT.semibold(16))
                    Text(language.text("Chen 점수로 줄 세운 순서예요. 자리와 상대에 따라 같은 핸드도 다르게 쳐요.",
                                       "Ranked by Chen score. Seat and opponents change how the same hand plays."))
                        .foregroundStyle(GT.inkSecondary)
                } else if let made = facts.madeHand {
                    Text(DrillTerms.hand(made, in: language)).font(GT.semibold(16))
                    Text(language.text("내 카드 두 장과 공용 카드로 만든 지금의 족보예요.",
                                       "Your best hand right now with the shared cards."))
                        .foregroundStyle(GT.inkSecondary)
                }
            }
            panel(language.text("가격", "The price")) {
                if let equity = facts.requiredEquityPercent {
                    Text(language.text("콜 \(facts.toCall)칩 · 팟 \(facts.pot + facts.toCall)칩",
                                       "Call \(facts.toCall) · pot becomes \(facts.pot + facts.toCall)"))
                        .font(GT.semibold(16)).monospacedDigit()
                    Text(language.text("팟 오즈로 보면 이 콜은 끝까지 갔을 때 \(equity)% 넘게 이기면 본전 이상이에요. 앞으로 더 낼 칩은 빼고 본 값이에요.",
                                       "By pot odds, this call breaks even if you win more than \(equity)% of the time. It ignores chips still to come."))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(language.text("지금은 칩을 더 내지 않고 넘길 수 있어요.", "You can check without paying."))
                }
            }
            panel(language.text("상대", "Opponents")) {
                ForEach(table.computerSeats.filter { !table.seats[$0.seat].folded }, id: \.seat) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.text("컴퓨터 \(entry.seat) · \(entry.style.beginnerTitle(in: language))",
                                           "Computer \(entry.seat) · \(entry.style.beginnerTitle(in: language))"))
                            .font(GT.semibold(15))
                        Text(entry.style.beginnerDescription(in: language))
                            .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Text(language.text("힌트는 사실만 보여 줘요. 무엇을 고를지는 정해 주지 않아요.",
                               "Hints show facts only. They never pick for you."))
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
        } else {
            panel(language.text("힌트", "Hint")) {
                Text(table.review != nil
                     ? language.text("핸드가 끝났어요. ‘이번 핸드’에서 돌아볼 수 있어요.",
                                     "The hand is over. See ‘This hand’ to look back.")
                     : language.text("힌트는 내 차례에 열려요.", "Hints open on your turn."))
            }
        }
    }

    // MARK: This hand

    @ViewBuilder private var hand: some View {
        let events = table.review?.events ?? table.events
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
        if let review = table.review, !replaying {
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
                    ForEach(review.holeCards[seat], id: \.self) { raw in
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
        return language.text("컴퓨터 \(seat) · \(style.beginnerTitle(in: language))",
                             "Computer \(seat) · \(style.beginnerTitle(in: language))")
    }

    // MARK: Help

    @ViewBuilder private var rules: some View {
        PlayTableGuideList()
        DisclosureGroup(language.text("컴퓨터는 어떻게 고를까요?", "How do the computers choose?")) {
            FreeTablePolicyDetails(table: table).padding(.top, 12)
        }
        .font(GT.semibold(15)).foregroundStyle(GT.ink)
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
                Text(language.text("컴퓨터 \(entry.seat): \(style.beginnerTitle(in: language))",
                                   "Computer \(entry.seat): \(style.beginnerTitle(in: language))"))
                    .font(GT.semibold(16))
                Text(language.text("처음 들어오는 핸드: Chen 점수 상위 \(Int(style.vpip))%, 올리는 핸드: 상위 \(Int(style.pfr))%",
                                   "Starting hands: top \(Int(style.vpip))% by Chen score; raising hands: top \(Int(style.pfr))%"))
                ForEach(MadeHand.allCases, id: \.self) { bucket in
                    let policy = style.postflop
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DrillTerms.madeHand(bucket, in: language)).font(GT.semibold(14))
                        Text(language.text("먼저 행동: ", "When checked to: ")
                             + (policy.opens(with: bucket) ? language.text("최소 베팅", "minimum bet") : language.text("체크", "check")))
                        Text(language.text("상대가 걸면: ", "Facing a bet: ") + responseName(policy.response(toBetWith: bucket)))
                    }.padding(.vertical, 5)
                }
                Divider()
            }
            Text(language.text("공용 카드 전에는 Chen 점수 순으로 고른 핸드를 사용해요. 이후에는 공개된 족보별 행동 규칙을 따라 최소 금액으로 베팅하거나 올려요. 자기 카드와 공개된 정보만 보고 골라요. 최적 전략이라는 뜻은 아니에요.", "Before shared cards, bots select hands ranked by Chen score. Afterward, they follow published hand-category rules and bet or raise the minimum. They see only their own cards and public information. This is not an optimal-strategy claim."))
            Text(language.text("D는 딜러 버튼이에요. 버튼 다음 두 사람이 1칩과 2칩을 먼저 내요. 매 핸드 버튼이 이동해요.", "D is the dealer button. The next two players post 1 and 2 chips. The button moves after each hand."))
            Text(language.text("컴퓨터는 각 베팅 라운드에 베팅하거나 올리는 행동을 한 번만 해요. 그 뒤에는 콜하거나 체크해요. 사람의 베팅 횟수를 제한하는 규칙은 아니에요.", "Each computer bets or raises at most once per betting round. After that, it calls or checks. This is a bot policy, not a limit on your raises."))
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
                let label = factor == factor.rounded() ? "\(Int(factor))BB" : "2.5BB"
                return Preset(korean: label, english: label, amount: rounded(factor * 2))
            } + [allIn]
        }
        if street == .preflop {
            return [2.5, 3.0, 4.0].map { factor in
                let label = factor == factor.rounded() ? "\(Int(factor))×" : "2.5×"
                return Preset(korean: label, english: label, amount: rounded(factor * Double(currentBet)))
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
            let bb = Double(amount) / 2
            let value = bb == bb.rounded() ? "\(amount / 2)" : String(format: "%.1f", bb)
            return language.text("스택에서 \(cost) · \(value)BB", "\(cost) from your stack · \(value) BB")
        }
        let denominator = isBet ? pot : pot + toCall
        let percent = denominator > 0 ? rounded(Double(amount - currentBet) * 100 / Double(denominator)) : 0
        return language.text("스택에서 \(cost) · 팟의 \(percent)%", "\(cost) from your stack · \(percent)% of pot")
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
