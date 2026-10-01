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

    var body: some View {
        Group {
            if let table = model.state.tableState {
                content(table)
            } else {
                FeltBackground()
            }
        }
        .background(FeltBackground())
        .onAppear {
            TableHaptics.prepare()
            guard let table = model.state.tableState else { return }
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
        Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: 0) {
                    ScrollView { tableSurface(table).padding(.horizontal, 8) }
                    ActionSheet { controls(table) }
                }
            } else {
                VStack(spacing: 12) {
                    tableSurface(table).padding(.horizontal, 8)
                    Spacer(minLength: 0)
                    ActionSheet { controls(table) }
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

    private func controls(_ table: PracticeTableState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            statusRow(table)
            if isReplaying(table) {
                actionRow(table, enabled: false)
            } else if let review = table.review {
                result(review, table: table)
            } else if raising {
                raisePanel(table)
            } else {
                actionRow(table, enabled: table.currentSeat == 0)
            }
        }
        .disabled(model.saveError != nil)
        .animation(reduceMotion ? nil : GT.Motion.change, value: raising)
        .animation(reduceMotion ? nil : GT.Motion.change, value: isReplaying(table))
    }

    private func statusRow(_ table: PracticeTableState) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if let thinking = thinkingSeat {
                    Text(language.text("\(seatName(thinking)) 차례", "\(seatName(thinking))'s turn"))
                        .font(GT.title(18)).foregroundStyle(GT.ink)
                } else if isReplaying(table) {
                    Text(language.text("카드를 나눠요", "Dealing")).font(GT.title(18)).foregroundStyle(GT.ink)
                } else if table.review != nil {
                    Text(language.text("핸드가 끝났어요", "Hand over")).font(GT.title(18)).foregroundStyle(GT.ink)
                } else if table.currentSeat == 0 {
                    Text(language.text("내 차례예요", "Your turn")).font(GT.title(18)).foregroundStyle(GT.ink)
                    Text(table.amountToCall > 0
                         ? language.text("따라가려면 \(table.amountToCall)칩", "\(table.amountToCall) chips to call")
                         : language.text("더 내지 않고 넘길 수 있어요", "You can check for free"))
                        .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                }
            }
            .contentTransition(.opacity)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("free-table-status")
            Spacer(minLength: 0)
            Button {
                helpTab = table.review != nil ? .hand : .hint
                showHelp = true
            } label: {
                Label(language.text("힌트", "Hint"), systemImage: "lightbulb")
                    .font(GT.semibold(14)).foregroundStyle(GT.ink)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .background(GT.surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(GT.borderStrong, lineWidth: 1))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
            .accessibilityLabel(language.text("힌트와 이번 핸드 보기", "Hint and hand details"))
            .accessibilityIdentifier("free-table-help")
        }
    }

    private func actionRow(_ table: PracticeTableState, enabled: Bool) -> some View {
        let actions = table.legalActions
        let minimumRaise = actions.compactMap { action -> Int? in
            if case let .raise(to: amount) = action { return amount }; return nil
        }.first
        let facingBet = table.amountToCall > 0
        return HStack(spacing: 8) {
            if actions.contains(.fold) {
                GTActionButton(title: language.text("폴드", "Fold"), price: language.text("0칩", "0 chips"),
                               role: .fold, minHeight: 87, cornerSide: .leading) { choose(.fold, table: table) }
                    .accessibilityIdentifier("free-fold")
            }
            if actions.contains(.check) {
                GTActionButton(title: language.text("체크", "Check"), price: language.text("0칩", "0 chips"),
                               role: .passive, minHeight: 87) { choose(.check, table: table) }
                    .accessibilityIdentifier("free-check")
            }
            if actions.contains(.call) {
                GTActionButton(title: language.text("콜", "Call"),
                               price: language.text("\(table.amountToCall)칩", "\(table.amountToCall) chips"),
                               role: .passive, minHeight: 87) { choose(.call, table: table) }
                    .accessibilityIdentifier("free-call")
            }
            if let minimumRaise {
                GTActionButton(title: facingBet ? language.text("레이즈", "Raise") : language.text("베팅", "Bet"),
                               price: language.text("\(minimumRaise)칩부터", "from \(minimumRaise)"),
                               role: .aggressive, minHeight: 87, cornerSide: .trailing) {
                    raiseAmount = minimumRaise
                    TableHaptics.pass()
                    raising = true
                }
                .accessibilityIdentifier("free-raise")
            }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }

    private func raisePanel(_ table: PracticeTableState) -> some View {
        let minimum = table.legalActions.compactMap { action -> Int? in
            if case let .raise(to: amount) = action { return amount }; return nil
        }.first ?? 0
        let me = table.seats[0]
        let maximum = me.stack + me.streetCommitted
        let currentBet = me.streetCommitted + table.amountToCall
        let potAfterCall = table.pot + table.amountToCall
        let amount = max(minimum, min(maximum, raiseAmount))
        let presets: [(String, Int)] = [
            (language.text("최소", "Min"), minimum),
            (language.text("½ 팟", "½ pot"), currentBet + potAfterCall / 2),
            (language.text("팟", "Pot"), currentBet + potAfterCall),
            (language.text("올인", "All-in"), maximum),
        ].map { ($0.0, max(minimum, min(maximum, $0.1))) }
            // Small pots make several presets the same amount; keep the first name for each.
            .reduce(into: [(String, Int)]()) { kept, preset in
                if !kept.contains(where: { $0.1 == preset.1 }) { kept.append(preset) }
            }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(language.text("총 \(amount)칩까지", "To \(amount) chips"))
                    .font(GT.title(20).monospacedDigit()).foregroundStyle(GT.ink)
                    .contentTransition(.numericText())
                Spacer()
                Button(language.text("취소", "Cancel")) { raising = false }
                    .font(GT.semibold(15)).foregroundStyle(GT.inkSecondary)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("free-raise-cancel")
            }
            HStack(spacing: 6) {
                ForEach(presets, id: \.0) { preset in
                    GTChoiceButton(title: preset.0, selected: amount == preset.1, minHeight: 40) {
                        TableHaptics.pass()
                        withAnimation(GT.Motion.change) { raiseAmount = preset.1 }
                    }
                }
            }
            if minimum < maximum {
                HStack(spacing: 10) {
                    Slider(value: Binding(get: { Double(amount) }, set: { raiseAmount = Int($0) }),
                           in: Double(minimum)...Double(maximum), step: 1)
                        .accessibilityLabel(language.text("올릴 총 금액", "Total raise amount"))
                        .accessibilityValue(language.text("\(amount)칩", "\(amount) chips"))
                    AdjustmentButtons(label: language.text("금액", "Amount"),
                                      decrement: { raiseAmount = max(minimum, amount - 1) },
                                      increment: { raiseAmount = min(maximum, amount + 1) })
                }
            }
            PrimaryCTAButton(title: language.text("\(amount)칩까지 올리기", "Raise to \(amount)")) {
                raising = false
                choose(.raise(to: amount), table: table)
            }
            .accessibilityIdentifier("free-raise-confirm")
        }
    }

    private func result(_ review: PracticeTableReview, table: PracticeTableState) -> some View {
        let net = review.endingStacks[0] - review.startingStacks[0]
        let winners = (0..<table.seatCount).filter { review.payouts[$0] > 0 }
        return VStack(alignment: .leading, spacing: 10) {
            Text(net > 0 ? language.text("+\(net)칩", "+\(net) chips")
                 : net < 0 ? language.text("−\(-net)칩", "−\(-net) chips")
                 : language.text("±0칩", "±0 chips"))
                .font(GT.title(26).monospacedDigit())
                .foregroundStyle(net > 0 ? GT.cta : GT.ink)
                .accessibilityIdentifier("free-table-net")
            ForEach(winners, id: \.self) { seat in
                Text(winnerLine(seat, review: review, table: table))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if table.seats.contains(where: { $0.stack == 0 }) {
                Text(language.text("칩이 없는 자리는 다음 핸드 전에 100칩을 새로 받아요.",
                                   "Seats with no chips get 100 before the next hand."))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            }
            PrimaryCTAButton(title: language.text("다음 핸드", "Next hand")) {
                TableHaptics.commit()
                perform {
                    try model.nextTableHand(handID: UUID().uuidString, after: table.handID,
                                            expectedEpoch: epoch)
                }
            }
            .accessibilityIdentifier("free-next-hand")
            HStack(spacing: 8) {
                SecondaryCTAButton(title: language.text("핸드 돌아보기", "Review this hand")) {
                    helpTab = .hand; showHelp = true
                }
                .accessibilityIdentifier("free-review")
                SecondaryCTAButton(title: language.text("테이블 바꾸기", "Change the table")) {
                    confirmNewTable = true
                }
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
        let scale = reduceMotion ? 0.5 : 1.0
        try? await Task.sleep(for: .milliseconds(Int(Double(beat.milliseconds) * scale)))
        return !Task.isCancelled
    }

    /// Steps the screen from what it shows to what the model holds.
    private func startReplay() {
        replay?.cancel()
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
