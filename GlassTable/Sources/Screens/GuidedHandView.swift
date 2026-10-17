// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// A disposable first hand on the Play table, against one scripted opponent. The learner
/// makes real choices; the opponent always stays in, so every path reaches the showdown
/// unless the learner gives up. Nothing here reaches progression or a saved table.
struct GuidedHandState: Equatable {
    enum Stage: Int, CaseIterable { case seats, blinds, preflop, flop, turn, river, showdown, summary }
    enum Move: String { case fold, call, check, raise }

    static let startingStack = 20
    static let hero = [Card(rank: 14, suit: 0), Card(rank: 13, suit: 2)]
    static let opponent = [Card(rank: 12, suit: 1), Card(rank: 11, suit: 0)]
    static let board = [Card(rank: 14, suit: 1), Card(rank: 12, suit: 3), Card(rank: 7, suit: 2),
                        Card(rank: 2, suit: 0), Card(rank: 3, suit: 3)]

    private(set) var stage: Stage = .seats
    /// Chips each player has put in this hand: the learner, then the opponent.
    private(set) var paid = [1, 2]
    /// Chips each has in front of them on the current street.
    private(set) var street = [1, 2]
    private(set) var confirmingFold = false
    private(set) var folded = false
    /// The learner's choice on each street they have played.
    private(set) var moves: [Stage: Move] = [:]
    /// What the opponent did last, for their seat.
    private(set) var opponentMove: (move: Move, chips: Int)?

    static func == (a: Self, b: Self) -> Bool {
        a.stage == b.stage && a.paid == b.paid && a.street == b.street && a.folded == b.folded
            && a.confirmingFold == b.confirmingFold && a.moves == b.moves
    }

    var showdown: ShowdownSpot { ShowdownSpot(hero: Self.hero, villain: Self.opponent, board: Self.board) }
    var isDecision: Bool { [.preflop, .flop, .turn, .river].contains(stage) }
    var owed: Int { isDecision ? street[1] - street[0] : 0 }
    var pot: Int { paid[0] + paid[1] }
    var settled: Bool { stage == .summary }
    var heroWon: Bool { !folded && showdown.winner == 0 }
    var stacks: [Int] {
        var stacks = paid.map { Self.startingStack - $0 }
        if settled { stacks[heroWon ? 0 : 1] += pot }
        return stacks
    }
    var visibleBoard: [Card] {
        if folded { return Array(Self.board.prefix(boardCount(before: foldedAt ?? .preflop))) }
        return Array(Self.board.prefix(boardCount(before: stage)))
    }
    private var foldedAt: Stage? { moves.first { $0.value == .fold }?.key }
    private func boardCount(before stage: Stage) -> Int {
        switch stage {
        case .seats, .blinds, .preflop: 0
        case .flop: 3
        case .turn: 4
        default: 5
        }
    }

    /// The total the learner's street bet reaches after a raise or a bet.
    var raiseTo: Int { owed > 0 ? street[1] * 2 + (stage == .turn ? 2 : 0) : 2 }
    var choices: [Move] { owed > 0 ? [.fold, .call, .raise] : [.check, .raise] }
    /// The choice the coach marks. One example line through the hand, not advice for every hand.
    var coachPick: Move? {
        switch stage {
        case .preflop, .turn: .call
        case .flop: .raise
        case .river: .check
        default: nil
        }
    }

    mutating func next() {
        switch stage {
        case .seats: stage = .blinds
        case .blinds: stage = .preflop
        case .showdown: stage = .summary
        default: break
        }
    }

    mutating func choose(_ move: Move) {
        guard isDecision, choices.contains(move), !confirmingFold || move == .fold else { return }
        if move == .fold, !confirmingFold { confirmingFold = true; return }
        confirmingFold = false
        moves[stage] = move
        switch move {
        case .fold:
            folded = true; stage = .summary; return
        case .call:
            pay(0, owed)
        case .check:
            break
        case .raise:
            pay(0, raiseTo - street[0])
            let call = street[0] - street[1]
            pay(1, call); opponentMove = (.call, call)
        }
        advanceStreet()
    }

    mutating func cancelFold() { confirmingFold = false }

    /// Follows the guide's own line one step: Next where there is one, else the coach's pick.
    mutating func follow() {
        if let coachPick { choose(coachPick) } else { next() }
    }

    private mutating func pay(_ seat: Int, _ chips: Int) { paid[seat] += chips; street[seat] += chips }

    private mutating func advanceStreet() {
        street = [0, 0]
        switch stage {
        case .preflop: stage = .flop; opponentMove = (.check, 0)
        case .flop: stage = .turn; pay(1, 2); opponentMove = (.raise, 2)
        case .turn: stage = .river; opponentMove = (.check, 0)
        default: stage = .showdown
        }
    }
}

struct GuidedHandView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hand = GuidedHandState()
    let onClose: () -> Void
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        table.id("table")
                        coach
                        if textSize.isAccessibilitySize { controls }
                    }
                    .padding(.horizontal, 8).padding(.bottom, 12)
                }
                .onChange(of: hand) {
                    withAnimation(reduceMotion ? nil : GT.Motion.change) { proxy.scrollTo("table", anchor: .top) }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !textSize.isAccessibilitySize {
                ActionSheet(collapsible: false) { controls }
            }
        }
        .foregroundStyle(GT.ink).background(FeltBackground())
        .onAppear {
            #if DEBUG
            if let raw = ProcessInfo.processInfo.environment["GT_DEMO_GUIDED_HAND_STEP"], let steps = Int(raw) {
                for _ in 0..<min(7, max(0, steps)) { hand.follow() }
            }
            if ProcessInfo.processInfo.environment["GT_DEMO_GUIDED_HAND_FOLD"] != nil { hand.choose(.fold) }
            #endif
        }
    }

    private var header: some View {
        GTChromeBar(leading: ChromeButton.close(onClose).accessibilityIdentifier("guided-hand-close"),
                    trailing: EmptyView())
            .frame(minHeight: 52)
            .overlay {
                // The stage names the screen, so the coach card below keeps its room for the guide.
                if !textSize.isAccessibilitySize {
                    Text(stageTitle).font(GT.semibold(16)).lineLimit(1).minimumScaleFactor(0.8)
                        .padding(.horizontal, 52).allowsHitTesting(false)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("guided-hand-stage-\(hand.stage)")
                }
            }
    }

    // MARK: Table

    private var opponentName: String { FreeTableWords.seatName(1, language: language) }

    private var table: some View {
        let showCards = hand.stage == .showdown || (hand.settled && !hand.folded)
        let opponentStatus: String? = if hand.settled {
            hand.heroWon ? nil : "+\(hand.pot - hand.paid[1])"
        } else if let last = hand.opponentMove {
            switch last.move {
            case .check: language.text("체크", "Check")
            case .call: language.text("콜 \(last.chips)", "Call \(last.chips)")
            default: language.text("벳 \(last.chips)", "Bet \(last.chips)")
            }
        } else {
            language.text("블라인드 2칩", "Blind 2")
        }
        let heroStatus: String? = if hand.settled {
            hand.heroWon ? "+\(hand.pot - hand.paid[0])" : hand.folded ? language.text("폴드", "Fold") : nil
        } else if hand.stage.rawValue <= GuidedHandState.Stage.preflop.rawValue {
            language.text("블라인드 1칩", "Blind 1")
        } else { nil }
        let potText = hand.settled ? language.text("팟 지급 완료", "Pot paid out")
                                   : language.text("팟 \(hand.pot)칩", "Pot \(hand.pot)")
        return TableSurface(
            seats: [
                TableSeat(id: "guided-opponent", place: .topLeading, name: opponentName,
                          status: opponentStatus, tone: hand.settled ? .action : .neutral,
                          hand: showCards ? .faceUp(GuidedHandState.opponent) : .faceDown,
                          stack: hand.stacks[1], committed: hand.settled ? 0 : hand.street[1]),
                TableSeat(id: "guided-hero", place: .bottomTrailing, name: language.text("나", "You"),
                          status: heroStatus, tone: hand.settled ? .action : .neutral,
                          isActive: hand.isDecision, isFolded: hand.folded, isDealer: true,
                          hand: .faceUp(GuidedHandState.hero),
                          stack: hand.stacks[0], committed: hand.settled ? 0 : hand.street[0], isHero: true),
            ],
            center: TableCenter(board: hand.visibleBoard, reservesBoard: true, potTotal: potText,
                                potSpoken: hand.settled ? potText : nil),
            spotlight: spotlight, ringed: ringed)
            .accessibilityIdentifier("guided-hand-table")
            .animation(reduceMotion ? nil : GT.Motion.change, value: hand)
    }

    /// The first three beats dim the table down to the one thing to look at.
    private var spotlight: Set<TableSpot>? {
        switch hand.stage {
        case .seats: [.seat("guided-hero")]
        case .blinds: [.chips, .pot]
        case .preflop where !hand.confirmingFold: [.chips, .seat("guided-hero")]
        default: nil
        }
    }

    private var ringed: Set<TableSpot> {
        switch hand.stage {
        case .blinds: [.pot]
        case .flop, .river, .showdown: [.board]
        case .turn: [.pot]
        default: []
        }
    }

    // MARK: Coach

    private var stageTitle: String {
        switch hand.stage {
        case .seats: language.text("두 사람이 한 판을 해요", "Two players, one hand")
        case .blinds: language.text("블라인드", "The blinds")
        case .preflop: language.text("플랍 전", "Before the flop")
        case .flop: language.text("플랍 · 세 장", "Flop · three cards")
        case .turn: language.text("턴 · 한 장 더", "Turn · one more card")
        case .river: language.text("리버 · 마지막 한 장", "River · the final card")
        case .showdown: language.text("쇼다운 · 카드 공개", "Showdown · cards shown")
        case .summary: language.text("한 판 돌아보기", "Review the hand")
        }
    }

    private var coach: some View {
        VStack(alignment: .leading, spacing: 10) {
            if hand.confirmingFold {
                Text(language.text("포기하기 전에", "Before you give up"))
                    .font(GT.title(20)).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("guided-hand-fold-question")
            } else if textSize.isAccessibilitySize {
                Text(stageTitle).font(GT.title(20)).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("guided-hand-stage-\(hand.stage)")
            }
            ForEach(Array(coachLines.enumerated()), id: \.offset) { _, line in
                coachRow(line.label, line.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GT.Space.card)
        .gtCard(radius: GT.Radius.control)
        .overlay {
            RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                .strokeBorder(GT.cta, lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("guided-hand-coach")
    }

    @ViewBuilder private func coachRow(_ label: String?, _ text: String) -> some View {
        let body = Text(text).font(GT.body(16)).fixedSize(horizontal: false, vertical: true)
        if let label {
            let tag = Text(label).font(GT.semibold(13)).foregroundStyle(GT.cta)
            if textSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) { tag; body }
                    .accessibilityElement(children: .combine)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    tag.frame(width: 58, alignment: .leading)
                    body
                }
                .accessibilityElement(children: .combine)
            }
        } else {
            body
        }
    }

    private var coachLines: [(label: String?, text: String)] {
        let now = language.text("지금", "Now"), look = language.text("볼 곳", "Look at")
        let think = language.text("생각", "Think")
        let name = opponentName
        let pot = hand.pot
        if hand.confirmingFold {
            return [(nil, language.text(
                "포기(폴드)하면 이번 판이 바로 끝나고 \(KO.subject(name)) 팟 \(pot)칩을 가져가요. 이미 낸 칩은 돌아오지 않아요.",
                "Giving up (folding) ends the hand now and \(name) takes the pot of \(pot). The chips you already put in do not come back.")),
                    (nil, hand.stage == .preflop
                        ? language.text("A-K는 가장 좋은 시작 패 중 하나이고, 계속하는 데 1칩이면 돼요.",
                                        "A-K is one of the best starting hands, and staying in costs only 1 chip.")
                        : language.text("에이스 원 페어를 들고 있고, 계속하는 데 \(hand.owed)칩이면 돼요.",
                                        "You hold a pair of aces, and staying in costs \(hand.owed) chips."))]
        }
        switch hand.stage {
        case .seats:
            return [(look, language.text("밝게 보이는 내 자리예요. 카드 두 장은 나만 볼 수 있어요.",
                                         "Your seat, the bright one. Only you can see your two cards.")),
                    (nil, language.text("\(name)도 두 장을 받았지만 뒤집혀 있어요. 둘 다 칩 20개로 시작해요.",
                                        "\(name) has two cards as well, face down. You each start with 20 chips.")),
                    (nil, language.text("D는 딜러 표시예요. 누가 먼저 행동할지 정해요.",
                                        "The D marks the dealer. It decides who acts first."))]
        case .blinds:
            return [(look, language.text("자리 옆의 칩 1개와 2개, 그리고 가운데 팟이에요.",
                                         "The 1 and the 2 beside the seats, and the pot in the middle.")),
                    (nil, language.text("카드를 보기 전에 두 사람이 꼭 내야 하는 칩이 블라인드예요. 나는 1칩, \(KO.topic(name)) 2칩을 냈어요.",
                                        "Before any cards are played, both players must put chips in. These are the blinds. You paid 1, \(name) paid 2.")),
                    (nil, language.text("그래서 팟은 3칩이에요. 이기는 사람이 팟을 가져가요.",
                                        "So the pot is 3 chips. Whoever wins the hand takes the pot."))]
        case .preflop:
            return [(now, language.text("\(KO.topic(name)) 2칩, 나는 1칩을 냈어요. 내 차례예요.",
                                        "\(name) has 2 chips in, you have 1. It is your turn.")),
                    (look, language.text("아래의 ‘콜하려면 1칩’. 2 − 1 = 1칩을 더 내면 같은 금액이 돼요.",
                                         "“To call: 1 chip” below. 2 − 1 = 1 more chip matches \(name).")),
                    (think, language.text("A-K는 좋은 시작 패예요. 1칩으로 공용 카드 세 장을 볼 수 있어요.",
                                          "A-K is a strong start. One chip lets you see three shared cards."))]
        case .flop:
            return [(now, language.text("공용 카드 세 장(플랍)이 나왔어요. \(KO.topic(name)) 체크했어요. 팟은 \(pot)칩.",
                                        "Three shared cards came out: the flop. \(name) checked. The pot is \(pot).")),
                    (look, language.text("공용 카드의 A와 내 A. 에이스 원 페어가 됐어요.",
                                         "The A on the table and your A. You have a pair of aces.")),
                    (think, language.text("받을 벳이 없어서 그냥 넘길(체크) 수 있어요. 좋은 패라면 먼저 걸어(벳) 팟을 키울 수도 있어요.",
                                          "Nothing to match, so you can pass (check) for free. Or bet first to grow the pot."))]
        case .turn:
            return [(now, language.text("네 번째 카드(턴)가 나왔고 \(KO.subject(name)) 2칩을 걸었어요. 팟은 \(pot)칩.",
                                        "The fourth card came: the turn. \(name) bet 2. The pot is \(pot).")),
                    (look, language.text("‘콜하려면 2칩’과 팟. 2칩을 내면 팟 \(pot)칩을 두고 계속해요.",
                                         "“To call: 2 chips” and the pot. Two chips keep you in for a pot of \(pot).")),
                    (think, language.text("에이스 원 페어는 여전히 좋은 패예요. 같은 금액을 내고(콜) 계속할 만해요.",
                                          "A pair of aces is still a good hand. Matching the bet (a call) is reasonable."))]
        case .river:
            return [(now, language.text("마지막 카드(리버)가 나왔어요. \(KO.topic(name)) 체크했어요. 팟은 \(pot)칩.",
                                        "The last card came: the river. \(name) checked. The pot is \(pot).")),
                    (look, language.text("공용 카드 다섯 장. 내 두 장과 합쳐 가장 좋은 다섯 장을 만들어요.",
                                         "All five shared cards. With your two, you make your best five.")),
                    (think, language.text("체크하면 칩을 더 내지 않고 카드를 공개해요. 벳을 해도 돼요.",
                                          "A check shows the cards with no more chips. You may also bet."))]
        case .showdown:
            let result = gradeShowdown(answer: 0, spot: hand.showdown, language: language)
            return [(look, language.text("\(name)의 카드가 공개됐어요. 각자 가장 좋은 다섯 장을 비교해요.",
                                         "\(name)’s cards are face up. Each player’s best five cards are compared.")),
                    (nil, language.text("내 패: \(result.heroName) · \(name): \(result.villainName)",
                                        "You: \(result.heroName) · \(name): \(result.villainName)")),
                    (nil, language.text("더 높은 쌍이 이겨요. 내가 팟 \(pot)칩을 가져가요.",
                                        "The higher pair wins. You take the pot of \(pot)."))]
        case .summary:
            var lines: [(String?, String)] = []
            if hand.folded {
                lines.append((nil, language.text("포기해서 \(KO.subject(name)) 팟 \(pot)칩을 가져갔어요. 나는 \(hand.stacks[0])칩이 남았어요.",
                                                 "You gave up, so \(name) took the pot of \(pot). You have \(hand.stacks[0]) chips left.")))
            } else {
                lines.append((nil, language.text("팟 \(pot)칩을 가져와서 \(hand.stacks[0])칩이 됐어요. \(KO.topic(name)) \(hand.stacks[1])칩이에요.",
                                                 "You took the pot of \(pot) and now have \(hand.stacks[0]) chips. \(name) has \(hand.stacks[1]).")))
            }
            for stage in [GuidedHandState.Stage.preflop, .flop, .turn, .river] {
                guard let move = hand.moves[stage] else { continue }
                lines.append((streetName(stage), moveName(move, bet: stage == .flop || stage == .river)))
            }
            lines.append((nil, language.text("이번 판은 하나의 예시예요. 모든 판에서 이렇게 하라는 뜻은 아니에요.",
                                             "This was one example hand, not advice for every hand.")))
            return lines.map { (label: $0.0, text: $0.1) }
        }
    }

    private func streetName(_ stage: GuidedHandState.Stage) -> String {
        switch stage {
        case .preflop: language.text("플랍 전", "Pre-flop")
        case .flop: language.text("플랍", "Flop")
        case .turn: language.text("턴", "Turn")
        default: language.text("리버", "River")
        }
    }

    private func moveName(_ move: GuidedHandState.Move, bet: Bool) -> String {
        switch move {
        case .fold: language.text("포기했어요 (폴드)", "You gave up (fold)")
        case .call: language.text("같은 금액을 냈어요 (콜)", "You matched the bet (call)")
        case .check: language.text("칩 없이 넘겼어요 (체크)", "You passed for free (check)")
        case .raise: bet ? language.text("먼저 걸었어요 (벳)", "You bet first (bet)")
                         : language.text("더 올렸어요 (레이즈)", "You increased the bet (raise)")
        }
    }

    // MARK: Controls

    @ViewBuilder private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hand.confirmingFold {
                GTChoiceButton(title: language.text("그래도 포기하기", "Give up anyway"), minHeight: 52) { act(.fold) }
                    .accessibilityIdentifier("guided-hand-fold-confirm")
                PrimaryCTAButton(title: language.text("돌아가서 다시 고르기", "Go back and choose again")) {
                    withAnimation(reduceMotion ? nil : GT.Motion.change) { hand.cancelFold() }
                }
                .accessibilityIdentifier("guided-hand-fold-cancel")
            } else if hand.isDecision {
                facts
                actionRow
            } else if hand.stage == .summary {
                let layout = textSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 8))
                layout {
                    SecondaryCTAButton(title: language.text("다시 하기", "Play again")) {
                        withAnimation(reduceMotion ? nil : GT.Motion.change) { hand = GuidedHandState() }
                    }
                    .accessibilityIdentifier("guided-hand-replay")
                    PrimaryCTAButton(title: language.text("플레이로 이동", "Go to Play"), action: onPlay)
                        .accessibilityIdentifier("guided-hand-play")
                }
            } else {
                PrimaryCTAButton(title: language.text("다음", "Next")) {
                    withAnimation(reduceMotion ? nil : GT.Motion.change) { hand.next() }
                }
                .accessibilityIdentifier("guided-hand-next")
            }
        }
    }

    private var facts: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 28))
        return layout {
            fact(language.text("콜하려면", "To call"),
                 hand.owed == 0 ? language.text("낼 칩 없음", "Nothing")
                                : language.text("\(hand.owed)칩", "\(hand.owed) \(hand.owed == 1 ? "chip" : "chips")"))
            fact(language.text("팟", "Pot"), language.text("\(hand.pot)칩", "\(hand.pot) chips"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("guided-hand-facts")
    }

    private func fact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label).font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            Text(value).font(GT.title(20).monospacedDigit()).foregroundStyle(GT.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private var actionRow: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 14))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(hand.choices, id: \.self) { move in
                let words = actionWords(move)
                GTActionButton(title: words.plain, price: "", role: words.role,
                               freeTablePresentation: true, secondaryTitle: words.term,
                               minHeight: 87) { act(move) }
                    .overlay(alignment: .top) {
                        if move == hand.coachPick {
                            Text(language.text("코치 추천", "Coach’s pick"))
                                .font(GT.semibold(12)).foregroundStyle(GT.onTable)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(GT.tableFelt, in: Capsule())
                                .fixedSize()
                                .offset(y: -10)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityHint(move == hand.coachPick ? language.text("코치 추천", "Coach’s pick") : "")
                    .accessibilityIdentifier("guided-hand-\(move.rawValue)")
            }
        }
        .padding(.top, 6)
    }

    private func actionWords(_ move: GuidedHandState.Move) -> (plain: String, term: String, role: GTActionRole) {
        switch move {
        case .fold: (language.text("포기", "Give up"), language.text("폴드", "Fold"), .fold)
        case .call: (language.text("\(hand.owed)칩 내기", "Add \(hand.owed)"), language.text("콜", "Call"), .passive)
        case .check: (language.text("넘기기", "Pass"), language.text("체크", "Check"), .passive)
        case .raise: hand.owed == 0
            ? (language.text("먼저 걸기", "Bet first"), language.text("벳 \(hand.raiseTo)", "Bet \(hand.raiseTo)"), .aggressive)
            : (language.text("더 올리기", "Increase"), language.text("\(hand.raiseTo)까지 레이즈", "Raise to \(hand.raiseTo)"), .aggressive)
        }
    }

    private func act(_ move: GuidedHandState.Move) {
        AppFeedback.table(kind: move == .check ? .tick : .chip(allIn: false))
        withAnimation(reduceMotion ? nil : GT.Motion.change) { hand.choose(move) }
    }
}
