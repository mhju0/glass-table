import SwiftUI
import GlassTableDrills
import GlassTableEngine

struct PlayView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @State private var failure = false
    @State private var revealAllCards = false
    @State private var raiseAmount = 0.0
    @State private var epoch: UUID?
    @State private var chooseNewOpponent = false
    @State private var showSetup = false
    @State private var showGraded = false
    @State private var showTableGuide = false

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

    private var playContent: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(language.text("플레이", "Play")).font(GT.title(30))
                    if let table = model.state.tableState {
                        // The title keeps one line beside the controls when it fits;
                        // otherwise it takes its own row and wraps between words.
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                tableTitleText(table).fixedSize()
                                tableHeaderControls(table)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                tableTitleText(table).fixedSize(horizontal: false, vertical: true)
                                HStack { tableHeaderControls(table) }
                            }
                        }
                        tableDiagram(table)
                        if let review = table.review {
                            reviewContent(review, table: table)
                            if table.seats.contains(where: { $0.stack == 0 }) {
                                Text(language.text("칩이 없는 자리는 다음 핸드 전에 100칩을 새로 받아요. 이 칩은 이익으로 세지 않아요.", "Seats with no chips receive 100 before the next hand. Refills aren't counted as winnings."))
                                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                            }
                            FeltCTAButton(title: language.text("다음 핸드", "Next hand")) {
                                perform {
                                    try model.nextTableHand(handID: UUID().uuidString, after: table.handID,
                                                            expectedEpoch: epoch ?? model.epoch)
                                }
                                revealAllCards = false
                            }
                            .disabled(model.saveError != nil)
                            SecondaryCTAButton(title: language.text("테이블 바꾸기", "Change the table")) {
                                chooseNewOpponent = true
                            }
                            .disabled(model.saveError != nil)
                        } else {
                            actions(table)
                        }
                        DisclosureGroup(language.text("행동 순서", "Action history")) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(table.events.enumerated()), id: \.element.id) { index, event in
                                    Text("\(index + 1). \(seatName(event.seat)) · \(eventDescription(event))")
                                        .font(GT.body(14)).frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }.padding(.top, 12)
                        }
                        policyDetails(table)
                        gradedCard
                    } else {
                        Text(language.text("컴퓨터와 한 판씩 연습해요. 실제 돈은 쓰지 않아요.",
                                           "Practice against computers. No real money."))
                            .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                            .lineSpacing(GT.Typography.bodyLineSpacing)
                        Spacer(minLength: 12)
                        VStack(spacing: 12) {
                            Button { showSetup = true } label: {
                                TapCardLabel(title: language.text("자유 대전", "Free table"),
                                             detail: language.text("컴퓨터 한 명에서 세 명과 한 판을 끝까지 쳐요. 여기서는 채점하지 않아요.",
                                                                   "Play whole hands against one to three computers. No grading here."),
                                             emphasized: true)
                            }
                            .buttonStyle(GTPress())
                            .accessibilityIdentifier("play-free")
                            .disabled(model.saveError != nil)
                            gradedCard
                        }
                    }
                }
                .padding(18)
                .frame(minHeight: viewport.size.height, alignment: .top)
            }
        }
        .background(FeltBackground())
        .gtTabBarClearance()
        .navigationDestination(isPresented: $showSetup) { TableSetupView(epoch: epoch ?? model.epoch) }
        .navigationDestination(isPresented: $showGraded) { TableView() }
        .modifier(ProgressSaveNotice())
        .onAppear {
            if epoch == nil { epoch = model.epoch }
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_PRACTICE"] != nil,
               model.state.tableState == nil {
                let players = ProcessInfo.processInfo.environment["GT_DEMO_PLAYERS"].flatMap(Int.init) ?? 4
                let styles = Array([Archetype.tag, .station, .lag].prefix(max(1, min(3, players - 1))))
                perform { try model.startTable(seed: 97, styles: styles, expectedEpoch: model.epoch) }
            }
            #endif
        }
        .onChange(of: model.epoch) { _, value in epoch = value; revealAllCards = false }
        .onChange(of: model.state.tableState != nil, initial: true) { _, hasTable in
            // The first table explains itself once; the info button reopens it.
            guard hasTable, !Self.guideSeen else { return }
            #if DEBUG
            // Demo tables are for screenshots of the table itself unless asked.
            let env = ProcessInfo.processInfo.environment
            if env["GT_DEMO_PRACTICE"] != nil, env["GT_DEMO_PLAY_GUIDE"] == nil { return }
            #endif
            Self.guideSeen = true
            showTableGuide = true
        }
        .sheet(isPresented: $showTableGuide) {
            PlayTableGuideView { showTableGuide = false }
        }
        .confirmationDialog(language.text("새 테이블을 시작할까요?", "Start a fresh table?"),
                            isPresented: $chooseNewOpponent, titleVisibility: .visible) {
            Button(language.text("테이블 다시 만들기", "Set up a new table")) {
                guard let table = model.state.tableState else { return }
                _ = model.leaveFinishedTable(handID: table.handID, expectedEpoch: epoch ?? model.epoch)
                revealAllCards = false
            }
            Button(language.text("취소", "Cancel"), role: .cancel) {}
        } message: {
            Text(language.text("지금까지의 핸드 기록은 남아요. 새 테이블은 각자 100칩으로 시작해요.", "Your hand history stays saved. The new table starts everyone at 100 chips."))
        }
        .alert(language.text("선택을 처리하지 못했어요", "Couldn't apply that choice"), isPresented: $failure) {
            Button(language.text("확인", "OK"), role: .cancel) {}
        } message: {
            Text(language.text("저장된 테이블은 그대로예요. 현재 차례와 가능한 선택을 다시 확인해 주세요.", "Your saved table is unchanged. Check the current turn and available choices."))
        }
    }

    private static var guideKey: String {
        #if DEBUG
        let suffix = ProcessInfo.processInfo.environment["GT_TEST_STORE_ID"] ?? "shared"
        #else
        let suffix = "shared"
        #endif
        return "play.tableGuideSeen.v1.\(suffix)"
    }

    private static var guideSeen: Bool {
        get { UserDefaults.standard.bool(forKey: guideKey) }
        set { UserDefaults.standard.set(newValue, forKey: guideKey) }
    }

    private func tableTitleText(_ table: PracticeTableState) -> some View {
        Text(tableTitle(table.seatCount)).font(GT.title(20))
    }

    @ViewBuilder private func tableHeaderControls(_ table: PracticeTableState) -> some View {
        Button { showTableGuide = true } label: {
            Image(systemName: "info.circle")
                .font(GT.title(18))
                .foregroundStyle(GT.inkSecondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(language.text("테이블 보는 법", "How to read the table"))
        .accessibilityIdentifier("play-table-guide")
        Spacer()
        Text(language.text("\(table.handNumber + 1)번째 핸드", "Hand \(table.handNumber + 1)"))
            .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            .fixedSize()
    }

    private func tableTitle(_ players: Int) -> String {
        switch players {
        case 2: language.text("두 명의 연습 테이블", "Two-player practice")
        case 3: language.text("세 명의 연습 테이블", "Three-player practice")
        default: language.text("네 명의 연습 테이블", "Four-player practice")
        }
    }

    /// The graded 1:1 exercise lives in Play as its own mode, beside the free table.
    private var gradedCard: some View {
        Button { showGraded = true } label: {
            TapCardLabel(title: language.text("1:1 채점 연습", "Graded 1:1 practice"),
                         detail: language.text("상대 한 명과 쳐요. 판단마다 공개된 차트와 평균값으로 채점해요.",
                                               "One opponent. Each decision is graded by a published chart and EV."))
        }
        .buttonStyle(GTPress())
        .accessibilityIdentifier("play-graded")
    }

    private func perform(_ operation: () throws -> Bool) {
        do { if try !operation(), model.saveError == nil { failure = true } }
        catch { failure = true }
    }

    private func tableDiagram(_ table: PracticeTableState) -> some View {
        TableSurface(seats: (0..<table.seatCount).map { tableSeat($0, table: table) },
                     center: TableCenter(board: table.visibleBoard.compactMap(Card.init),
                                         reservesBoard: true,
                                         potTotal: language.text("\(table.pot)칩", "\(table.pot) chips")))
            .accessibilityIdentifier("practice-table")
    }

    /// Clockwise from the learner: you bottom left, then the computers in seat order.
    private func tableSeat(_ seat: Int, table: PracticeTableState) -> TableSeat {
        let player = table.seats[seat]
        let places: [TableSeat.Place] = switch table.seatCount {
        case 2: [.bottomLeading, .topTrailing]
        case 3: [.bottomLeading, .topLeading, .topTrailing]
        default: [.bottomLeading, .topLeading, .topTrailing, .bottomTrailing]
        }
        let hand: TableSeat.Hand
        if seat == 0 {
            hand = .faceUp(table.learnerHole.compactMap(Card.init))
        } else if revealAllCards, let review = table.review {
            hand = .faceUp(review.holeCards[seat].compactMap(Card.init))
        } else {
            hand = .faceDown
        }
        return TableSeat(
            id: "practice-\(seat)",
            place: places[seat],
            name: seatName(seat, styledBy: table),
            detail: table.street == .finished
                ? language.text("남은 칩 \(player.stack)", "\(player.stack) chips left")
                : language.text("남은 칩 \(player.stack) · 낸 칩 \(player.committed)",
                                "\(player.stack) left · \(player.committed) in"),
            status: table.events.last(where: { $0.seat == seat }).map(eventDescription),
            tone: .neutral,
            isActive: table.currentSeat == seat,
            isFolded: player.folded,
            isDealer: table.dealer == seat,
            hand: hand)
    }

    private func actions(_ table: PracticeTableState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("내 차례예요", "Your turn")).font(GT.title(22))
            Text(language.text("포기는 폴드, 같은 금액까지 따라가기는 콜이에요.", "Fold to leave the hand; call to match the current price."))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            ForEach(Array(table.legalActions.enumerated()), id: \.offset) { _, action in
                if case .raise = action {} else {
                    Button { choose(action, table: table) } label: {
                        Text(action == .call
                             ? language.text("\(table.amountToCall)칩 내기 · 콜", "Call · pay \(table.amountToCall) chips")
                             : actionTitle(action)).font(GT.semibold(17))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(GTPress())
                }
            }
            if let minimum = table.legalActions.compactMap({ action -> Int? in
                if case let .raise(to: amount) = action { return amount }; return nil
            }).first {
                let maximum = table.seats[0].stack + table.seats[0].streetCommitted
                let amount = max(minimum, min(maximum, Int(raiseAmount)))
                DisclosureGroup(language.text("금액 올리기", "Raise the price")) {
                    VStack(spacing: 12) {
                        Text(language.text("이번 차례 총 \(amount)칩까지", "To \(amount) chips this round"))
                            .font(GT.semibold(17))
                        if minimum < maximum {
                            Slider(value: Binding(get: { Double(amount) }, set: { raiseAmount = $0 }),
                                   in: Double(minimum)...Double(maximum), step: 1)
                            .accessibilityLabel(language.text("올릴 총 금액", "Total raise amount"))
                        }
                        Button { choose(.raise(to: amount), table: table) } label: {
                            Text(language.text("\(amount)칩까지 올리기", "Raise to \(amount)"))
                                .font(GT.semibold(17)).frame(maxWidth: .infinity, minHeight: 52)
                        }.buttonStyle(GTPress())
                    }.padding(.top, 12)
                }
            }
        }
        .disabled(model.saveError != nil || table.currentSeat != 0)
    }

    private func choose(_ action: PracticeAction, table: PracticeTableState) {
        perform {
            try model.applyTableAction(action, actionID: "\(table.handID)-learner-\(table.events.count)",
                                       handID: table.handID, expectedEpoch: epoch ?? model.epoch)
        }
        raiseAmount = 0
    }

    private func reviewContent(_ review: PracticeTableReview, table: PracticeTableState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(language.text("이번 핸드 돌아보기", "Review this hand")).font(GT.title(22))
            Text(language.text("이긴 결과와 좋은 결정은 달라요. 여기서는 실제 칩 이동만 확인해요.", "Winning a hand and making a good decision aren't the same. This review shows the actual chip movement."))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            ForEach(0..<table.seatCount, id: \.self) { seat in
                VStack(alignment: .leading, spacing: 5) {
                    Text(seatName(seat, styledBy: table)).font(GT.semibold(16))
                    Text(language.text("낸 칩 \(review.contributions[seat]) · 반환 \(review.refunds[seat]) · 받은 팟 \(review.payouts[seat])", "Paid \(review.contributions[seat]) · Returned \(review.refunds[seat]) · Won from pots \(review.payouts[seat])"))
                        .font(GT.body(14))
                    if revealAllCards || seat == 0 {
                        HStack(spacing: 5) {
                            ForEach(review.holeCards[seat], id: \.self) { raw in
                                if let card = Card(raw) { PlayingCardView(card: card, size: 48) }
                            }
                        }
                        if review.board.count == 5,
                           let cards = Card.parse((review.holeCards[seat] + review.board).joined()) {
                            Text(DrillTerms.hand(bestHand(cards), in: language))
                                .font(GT.semibold(14))
                            HStack(spacing: 4) {
                                ForEach(bestFiveCards(cards), id: \.self) { card in
                                    PlayingCardView(card: card, size: 36)
                                }
                            }
                            .accessibilityLabel(language.text("끝난 보드에서 만든 가장 좋은 다섯 장", "Best five cards on the final board"))
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle(language.text("끝난 뒤 상대 카드 보기", "Reveal opponents' cards after the hand"), isOn: $revealAllCards)
                .font(GT.body(14))
            Text(language.text("상대 카드는 플레이할 때 알 수 없었던 정보예요.", "Opponent cards were not available to you while playing."))
                .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
        }
    }

    private func policyDetails(_ table: PracticeTableState) -> some View {
        DisclosureGroup(language.text("컴퓨터는 어떻게 고를까요?", "How do the computers choose?")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text("규칙 \(PracticeTableState.rulesVersion) · 상대 정책 \(PracticeTableState.policyVersion)", "Rules \(PracticeTableState.rulesVersion) · Bot policy \(PracticeTableState.policyVersion)"))
                ForEach(1..<4, id: \.self) { seat in
                    if let style = Archetype(rawValue: table.styles[seat - 1]) {
                        Text("\(seatName(seat)): \(style.beginnerTitle(in: language))")
                            .font(GT.semibold(16))
                        Text(language.text("처음 들어오는 핸드: Chen 점수 상위 \(Int(style.vpip))%, 올리는 핸드: 상위 \(Int(style.pfr))%", "Starting hands: top \(Int(style.vpip))% by Chen score; raising hands: top \(Int(style.pfr))%"))
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
                }
                Text(language.text("공용 카드 전에는 Chen 점수 순으로 고른 핸드를 사용해요. 이후에는 공개된 족보별 행동 규칙을 따라 최소 금액으로 베팅하거나 올려요. 자기 카드와 공개된 정보만 보고 골라요. 최적 전략이라는 뜻은 아니에요.", "Before shared cards, bots select hands ranked by Chen score. Afterward, they follow published hand-category rules and bet or raise the minimum. They see only their own cards and public information. This is not an optimal-strategy claim."))
                Text(language.text("D는 딜러 버튼이에요. 버튼 다음 두 사람이 1칩과 2칩을 먼저 내요. 매 핸드 버튼이 이동해요.", "D is the dealer button. The next two players post 1 and 2 chips. The button moves after each hand."))
                Text(language.text("컴퓨터는 각 베팅 라운드에 베팅하거나 올리는 행동을 한 번만 해요. 그 뒤에는 콜하거나 체크해요. 사람의 베팅 횟수를 제한하는 규칙은 아니에요.", "Each computer bets or raises at most once per betting round. After that, it calls or checks. This is a bot policy, not a limit on your raises."))
            }.font(GT.body(14)).padding(.top, 12)
        }
    }

    private func responseName(_ response: PostflopPolicy.FacingBetResponse) -> String {
        switch response {
        case .fold: language.text("포기", "fold")
        case .call: language.text("콜", "call")
        case .raise: language.text("최소 금액으로 올리기. 올릴 수 없으면 콜", "minimum raise; call if raising is not allowed")
        }
    }

    private func seatName(_ seat: Int) -> String {
        seat == 0 ? language.text("나", "You") : language.text("컴퓨터 \(seat)", "Computer \(seat)")
    }

    /// A computer's seat also names its style, since each seat can play differently.
    private func seatName(_ seat: Int, styledBy table: PracticeTableState) -> String {
        guard seat > 0, let style = Archetype(rawValue: table.styles[seat - 1]) else { return seatName(seat) }
        return "\(seatName(seat)) · \(style.beginnerTitle(in: language))"
    }

    private func actionTitle(_ action: PracticeAction) -> String {
        switch action {
        case .fold: language.text("포기하기 · 폴드", "Fold · leave this hand")
        case .check: language.text("더 내지 않고 넘기기 · 체크", "Check · pass without paying")
        case .call: language.text("같은 금액까지 따라가기 · 콜", "Call · match the price")
        case .raise(let amount): language.text("\(amount)칩까지 올리기", "Raise to \(amount)")
        }
    }

    private func eventDescription(_ event: PracticeEvent) -> String {
        switch event.label {
        case "small blind": language.text("시작 칩 +\(event.chips) · SB", "Small blind +\(event.chips)")
        case "big blind": language.text("시작 칩 +\(event.chips) · BB", "Big blind +\(event.chips)")
        case "fold": language.text("포기", "Folded")
        case "check": language.text("더 내지 않고 넘김", "Checked")
        case "call": language.text("따라가기 +\(event.chips)", "Called +\(event.chips)")
        case "bet": language.text("베팅 +\(event.chips)", "Bet +\(event.chips)")
        default: language.text("올리기 +\(event.chips)", "Raised +\(event.chips)")
        }
    }
}

/// What each part of the free table shows, in the order a new player looks at it.
private struct PlayTableGuideView: View {
    @Environment(\.learningLanguage) private var language
    let onClose: () -> Void

    private var items: [(symbol: String, title: String, detail: String)] {
        [
            ("person.crop.square", language.text("내 카드", "Your cards"),
             language.text("왼쪽 아래 자리가 나예요. 내 카드 두 장은 나만 볼 수 있어요.",
                           "You sit bottom left. Only you can see your two cards.")),
            ("rectangle.on.rectangle", language.text("상대 카드", "Opponents' cards"),
             language.text("상대 카드는 뒤집혀 있어요. 핸드가 끝나면 볼 수 있어요.",
                           "Opponents' cards stay face down until the hand ends.")),
            ("square.grid.3x1.below.line.grid.1x2", language.text("공용 카드", "Shared cards"),
             language.text("가운데 카드는 모두가 함께 써요. 세 장, 한 장, 한 장씩 펼쳐져요.",
                           "Everyone uses the middle cards. They come out three, then one, then one.")),
            ("circle.grid.cross", language.text("팟", "The pot"),
             language.text("가운데 숫자는 이번 핸드에 모인 칩이에요. 이긴 사람이 가져가요.",
                           "The middle number is every chip bet this hand. The winner takes it.")),
            ("hand.point.right", language.text("차례", "Whose turn"),
             language.text("밝게 표시된 자리가 행동할 차례예요. 내 차례에만 버튼이 열려요.",
                           "The highlighted seat acts next. Your buttons open on your turn.")),
            ("arrow.up.arrow.down", language.text("행동의 가격", "What each action costs"),
             language.text("폴드는 무료로 핸드를 떠나요. 콜은 버튼에 적힌 칩을 내고, 레이즈는 가격을 더 올려요.",
                           "Folding leaves the hand for free. Calling pays the chips on the button; raising sets a higher price.")),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(language.text("테이블 보는 법", "How to read the table"))
                        .font(GT.title(26)).foregroundStyle(GT.ink)
                    Text(language.text("실제 돈은 쓰지 않아요. 칩은 연습용이에요.",
                                       "No real money. The chips are for practice."))
                        .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
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
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .gtPanel()
                        .accessibilityElement(children: .combine)
                    }
                    FeltCTAButton(title: language.text("테이블로 가기", "Go to the table"), action: onClose)
                        .accessibilityIdentifier("play-table-guide-close")
                }
                .padding(20)
            }
            .background(FeltBackground())
            .gtChrome(.topBarTrailing) { ChromeButton.close(onClose) }
        }
        .accessibilityIdentifier("play-table-guide-sheet")
    }
}
