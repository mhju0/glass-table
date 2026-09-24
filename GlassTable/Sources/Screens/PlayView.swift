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

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_TABLE"] != nil { TableView() }
            else { playContent }
            #else
            playContent
            #endif
        }
    }

    private var playContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(language.text("플레이", "Play")).font(GT.title(30))
                if let table = model.state.tableState {
                    HStack {
                        Text(language.text("네 명의 연습 테이블", "Four-player practice")).font(GT.title(20))
                        Spacer()
                        Text(language.text("\(table.handNumber + 1)번째 핸드", "Hand \(table.handNumber + 1)"))
                            .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    }
                    tableDiagram(table)
                    if let review = table.review {
                        reviewContent(review)
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
                        Button(language.text("다른 상대 고르기", "Choose another opponent")) {
                            chooseNewOpponent = true
                        }
                        .frame(minHeight: 44)
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
                } else {
                    Text(language.text("컴퓨터 세 명과 천천히 연습해요. 각자 100칩, 블라인드는 1·2칩이에요. 실제 돈은 쓰지 않아요.", "Play three computers at your pace. Each has 100 chips; blinds are 1 and 2. No real money."))
                        .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                    OpponentPickerView { opponent in
                        perform {
                            try model.startTable(seed: UInt64.random(in: 0..<UInt64.max),
                                                 styles: [opponent, .station, .tag],
                                                 expectedEpoch: epoch ?? model.epoch)
                        }
                    }
                    Text(language.text("고른 스타일은 컴퓨터 1이에요. 컴퓨터 2는 콜 위주형, 컴퓨터 3은 선별형이에요.", "Your choice sets Computer 1. Computer 2 is Caller; Computer 3 is Selective."))
                        .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                }
                Divider()
                NavigationLink {
                    TableView()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(language.text("선택의 이유를 배우고 싶다면", "Want feedback on each decision?")).font(GT.title(18))
                        Text(language.text("일대일 판단 연습 · 공개된 차트와 평균값으로 채점해요", "Heads-up decision exercise · Graded against a published chart and average-value model"))
                            .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
                }.buttonStyle(GTPress())
            }.padding(18)
        }
        .background(FeltBackground())
        .gtTabBarClearance()
        .modifier(ProgressSaveNotice())
        .onAppear {
            if epoch == nil { epoch = model.epoch }
            #if DEBUG
            if ProcessInfo.processInfo.environment["GT_DEMO_PRACTICE"] != nil,
               model.state.tableState == nil {
                perform { try model.startTable(seed: 97, styles: [.tag, .station, .lag], expectedEpoch: model.epoch) }
            }
            #endif
        }
        .onChange(of: model.epoch) { _, value in epoch = value; revealAllCards = false }
        .confirmationDialog(language.text("새 테이블을 시작할까요?", "Start a fresh table?"),
                            isPresented: $chooseNewOpponent, titleVisibility: .visible) {
            Button(language.text("상대 다시 고르기", "Choose new opponents")) {
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

    private func perform(_ operation: () throws -> Bool) {
        do { if try !operation(), model.saveError == nil { failure = true } }
        catch { failure = true }
    }

    private func tableDiagram(_ table: PracticeTableState) -> some View {
        TableSurface(seats: (0..<4).map { tableSeat($0, table: table) },
                     center: TableCenter(board: table.visibleBoard.compactMap(Card.init),
                                         reservesBoard: true,
                                         potTotal: language.text("\(table.pot)칩", "\(table.pot) chips")))
            .accessibilityIdentifier("practice-table")
    }

    /// Clockwise from the learner: you bottom left, then the computers in seat order.
    private func tableSeat(_ seat: Int, table: PracticeTableState) -> TableSeat {
        let player = table.seats[seat]
        let places: [TableSeat.Place] = [.bottomLeading, .topLeading, .topTrailing, .bottomTrailing]
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
            name: seatName(seat),
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

    private func reviewContent(_ review: PracticeTableReview) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(language.text("이번 핸드 돌아보기", "Review this hand")).font(GT.title(22))
            Text(language.text("이긴 결과와 좋은 결정은 달라요. 여기서는 실제 칩 이동만 확인해요.", "Winning a hand and making a good decision aren't the same. This review shows the actual chip movement."))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            ForEach(0..<4, id: \.self) { seat in
                VStack(alignment: .leading, spacing: 5) {
                    Text(seatName(seat)).font(GT.semibold(16))
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
