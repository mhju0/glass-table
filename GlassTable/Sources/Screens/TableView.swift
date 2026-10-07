// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// 테이블 — one postflop hand at a time against a declared opponent, every decision
/// priced in bb (spec §4).
///
/// The screen is honest about its two clocks: `TableHand.play` is instant and drives
/// the table; `gradedOptions()` is the slow part, so it runs off the main thread on a
/// copy the moment a decision node appears, and the buttons wait for it — the same
/// pattern 레인지 어드밴티지 uses for its sampling.
struct TableView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(\.dismiss) private var dismiss
    @State private var hand: TableHand?
    @State private var options: [GradedOption]?
    @State private var choosingBetSize = false
    @State private var footerContentHeight: CGFloat?
    @ScaledMetric(relativeTo: .body) private var sizeChooserHeight: CGFloat = 186
    @State private var lastTurn: TurnRecord?
    @State private var decisions: [TurnRecord] = []
    @State private var baseSeed = UInt64.random(in: 0..<UInt64.max)
    @State private var handIndex = 0
    @State private var villainPick: Archetype?

    /// One graded hero decision, kept for the pill and the summary. Postflop
    /// decisions carry a bb price; the preflop one carries the chart verdict —
    /// future-value is exactly what the checkdown model cannot price (R5 §3).
    struct TurnRecord: Equatable {
        let street: Int
        let choice: TableHand.HeroChoice
        let amount: Double?
        let fraction: Double?
        enum Verdict: Equatable {
            case ev(loss: Double, best: GradedOption)
            case chart(TableHand.PreflopVerdict)
        }
        let verdict: Verdict

        func label(in language: LearningLanguage) -> String {
            switch choice {
            case .fold: return language.text("폴드", "Fold")
            case .check: return language.text("체크", "Check")
            case .call:
                if let amount { return language.text("콜 \(bbText(amount))bb", "Call \(bbText(amount))bb") }
                return language.text("콜", "Call")
            case .raise:
                if street == 0 { return language.text("3벳", "3-bet") }
                return language.text("레이즈 \(bbText(amount ?? 0))bb", "Raise to \(bbText(amount ?? 0))bb")
            case let .bet(f):
                return language.text("벳 \(bbText(amount ?? 0))bb (\(pctText(f * 100))%)",
                                     "Bet \(bbText(amount ?? 0))bb (\(pctText(f * 100))% pot)")
            }
        }

        var band: GradeBand {
            switch verdict {
            case let .ev(loss, _): return evLossBand(bb: loss)
            case let .chart(v): return v.matched ? .spotOn : .off
            }
        }
    }
    @State private var showChart = false
    @State private var showPolicyReference = false

    var body: some View {
        Group {
            if let hand { table(hand) } else { picker }
        }
        .background(FeltBackground())
        // The table needs the whole height: the tab bar hid the hero's cards under the
        // sheet, and the felt strip keeps scrolled content off the status bar.
        .toolbar(.hidden, for: .tabBar)
        .gtChrome(leading: { ChromeButton.back(language.text("플레이로", "Back to Play")) { dismiss() } })
        .sheet(isPresented: $showChart) {
            if let hand {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(language.text("시작 패 차트", "Starting-hand chart"))
                            .font(GT.title(22)).foregroundStyle(GT.onFelt)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(language.text("상대가 \(hand.villainSeat.plainName(in: language))에서 먼저 올렸을 때의 기준이에요. 공용 카드가 나온 뒤의 행동을 알려주는 차트는 아니에요.",
                                           "A baseline against a raise from \(hand.villainSeat.plainName(in: language)). It does not advise decisions after the shared cards."))
                            .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                        DisclosureGroup(language.text("차트 읽는 법", "How to read the chart")) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(language.text("A는 에이스, K는 킹, Q는 퀸, J는 잭이에요. 숫자는 카드 숫자 그대로예요.",
                                                   "A is ace, K is king, Q is queen and J is jack. Numbers are the card ranks."))
                                LessonPairedText(korean: ["가로·세로는 각각 카드 숫자예요.", "두 숫자가 만나는 칸이 시작 패예요."],
                                                 english: ["Rows and columns show ranks.", "Their crossing shows two cards."])
                                Text(language.text("AA부터 22까지 대각선은 같은 숫자 두 장인 페어예요. 대각선 위의 s는 같은 무늬, 아래의 o는 다른 무늬예요.",
                                                   "The diagonal from AA to 22 holds pairs. Above it, s means the same suit; below it, o means different suits."))
                                Text(language.text("빨강은 다시 올리기, 주황은 콜, 회색은 폴드예요. 색 옆의 글자도 함께 보세요.",
                                                   "Red means raise again, amber means call and gray means fold. The legend names each color too."))
                            }
                            .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                        }
                        .font(GT.semibold(15)).foregroundStyle(GT.onFeltSecondary)
                        .accessibilityIdentifier("table-chart-reading-guide")
                        DefendGridView(opener: hand.villainSeat,
                                       highlight: decisions.contains { $0.street == 0 } ? HandClass(hand.hero) : nil,
                                       cards: decisions.contains { $0.street == 0 } ? hand.hero : [])
                            .padding(.top, 8)
                    }
                    .gtContentEdge()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FeltBackground())
                .gtChrome(leading: { ChromeButton.close { showChart = false } })
                .gtSheetSurface()
            }
        }
        .sheet(isPresented: $showPolicyReference) {
            if let hand {
                TablePolicyReferenceView(hand: hand) { showPolicyReference = false }
            }
        }
        .onAppear {
            #if DEBUG
            // GT_DEMO_TABLE=<archetype|random> starts a seeded hand;
            // GT_DEMO_TABLE_STEP=<n> plays n passive decisions with grading, so the
            // sweep can reach the pill and the summary. Synthetic taps never reach
            // Simulator content.
            let env = ProcessInfo.processInfo.environment
            if let pick = env["GT_DEMO_TABLE"] {
                baseSeed = 0x5EED
                let villain = Archetype(rawValue: pick)
                var h = TableDealer.deal(baseSeed: 0x5EED, index: 0, villain: villain)
                let steps = env["GT_DEMO_TABLE_STEP"].flatMap(Int.init) ?? 0
                for _ in 0..<steps {
                    guard case let .hero(facing) = h.phase else { break }
                    if case .open = facing {
                        if let v = h.preflopVerdict(for: .call) {
                            decisions.append(TurnRecord(street: 0, choice: .call,
                                                        amount: nil, fraction: nil,
                                                        verdict: .chart(v)))
                        }
                        h.play(.call)
                    } else {
                        let opts = h.gradedOptions()
                        let choice: TableHand.HeroChoice =
                            h.choices().contains(.check) ? .check : .call
                        record(choice, options: opts, of: h)
                        h.play(choice)
                    }
                }
                hand = h
                // Mid-hand after scripted steps → show the last grade's pill; a hand
                // that ended shows its summary by itself. CONTINUE simulates 계속, so
                // the sweep can also photograph the action buttons mid-hand.
                if steps > 0, case .hero = h.phase { lastTurn = decisions.last }
                if env["GT_DEMO_TABLE_CONTINUE"] != nil { lastTurn = nil }
                if env["GT_DEMO_TABLE_CHART"] != nil { showChart = true }
                if env["GT_DEMO_TABLE_POLICY"] != nil { showPolicyReference = true }
                prepareOptions(for: h)
                if env["GT_DEMO_TABLE_SIZES"] != nil,
                   h.choices().contains(where: { if case .bet = $0 { return true }; return false }) {
                    choosingBetSize = true
                }
            }
            #endif
        }
    }

    // MARK: picker

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(language.text("한 번씩 선택하며 배우기", "Learn one decision at a time"))
                    .font(GT.title(28)).foregroundStyle(GT.ink)
                Text(language.text("폴드, 콜, 올리기를 직접 골라 보세요. 매번 선택 뒤에 이유를 짧게 짚어드려요.",
                                   "Try folding, calling and raising. After each choice, get one short takeaway."))
                    .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                Text(language.text("시작 패는 앱 차트와 비교해요. 공용 카드 뒤에는 이후 베팅이 없다고 가정해 비교해요. 실제 포커의 정답은 아니에요.",
                                   "Starting hands use the app's chart. Later choices assume no more betting. These are practice rules, not perfect poker."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                Text(language.text("상대 고르기", "Choose an opponent"))
                    .font(GT.title(20)).foregroundStyle(GT.ink)
                Text(language.text("스타일이 달라요. 실력 순서는 아니에요.", "Different styles, not difficulty levels."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                ForEach(Archetype.allCases, id: \.self) { opponent in
                    Button { start(vs: opponent) } label: {
                        TapCardLabel(title: opponent.beginnerTitle(in: language),
                                     detail: opponent.beginnerDescription(in: language))
                    }
                    .buttonStyle(GTPress())
                    .accessibilityIdentifier("opponent-\(opponent.rawValue)")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(GT.Space.edge)
        }
        .gtTabBarClearance(20)
    }

    private func start(vs villain: Archetype?) {
        villainPick = villain
        decisions = []; lastTurn = nil; options = nil; choosingBetSize = false
        let h = TableDealer.deal(baseSeed: baseSeed, index: handIndex, villain: villain)
        handIndex += 1
        hand = h
        prepareOptions(for: h)
    }

    // MARK: the table

    /// Three fixed zones — villain at the top, the board floating in the middle, hero
    /// above the sheet — instead of one top-anchored column.
    ///
    /// The column left roughly a fifth of the screen as bare felt below the history and
    /// above the sheet, because a `ScrollView` hands its content unbounded height and
    /// the content simply stacked from the top. Pinning the stack to at least the
    /// viewport height lets the spacers distribute that slack around the board, and the
    /// scroll survives for the cases that actually need it — the largest Dynamic Type
    /// sizes, where the zones no longer fit.
    private func table(_ hand: TableHand) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(spacing: GT.Space.section) {
                        seatRow(hand)
                        if case .hero = hand.phase { streetStrip(hand) }
                        boardBlock(hand)
                        heroBlock(hand)
                        VStack(alignment: .leading, spacing: GT.Space.related) { sheet(hand) }
                            .gtInset(GT.Space.sheet, firstText: .title(18))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .gtCard(radius: GT.Radius.panel, band: sheetBand(hand))
                    }
                    .padding(.horizontal, 18).padding(.bottom, 28)
                }
                .accessibilityIdentifier("table-accessibility-scroll")
            } else {
                GeometryReader { viewport in
                VStack(spacing: 0) {
                    GeometryReader { geo in
                let compactHeight = geo.size.height < 430
                ScrollView {
                    VStack(spacing: 0) {
                        seatRow(hand)
                        // Spent once the hand is over: the summary beneath names every
                        // street already, so the strip is repeating the answer.
                        if case .hero = hand.phase { streetStrip(hand) }
                        Spacer(minLength: compactHeight ? 6 : 14)
                        boardBlock(hand)
                        Spacer(minLength: compactHeight ? 6 : 14)
                        heroBlock(hand)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                // When the zones overflow, the hero's own cards stay in view above the
                // sheet; the opponent row is the part that scrolls away.
                .defaultScrollAnchor(.bottom)
                    }
                    ActionSheet {
                        ScrollView {
                            VStack(alignment: .leading, spacing: GT.Space.related) { sheet(hand) }
                                .background {
                                    GeometryReader { content in
                                        Color.clear.preference(key: GradedFooterHeight.self, value: content.size.height)
                                    }
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier("table-footer-content")
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(height: min(footerContentHeight ?? viewport.size.height * 0.56,
                                           viewport.size.height * 0.56))
                        .onPreferenceChange(GradedFooterHeight.self) { height in
                            if height.isFinite, height > 0 { footerContentHeight = height }
                        }
                        .accessibilityIdentifier("table-footer-scroll")
                    }.layoutPriority(1)
                }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func streetStrip(_ hand: TableHand) -> some View {
        Text(TableEvent.streetName(hand.street, in: language))
            .font(GT.semibold(14)).foregroundStyle(GT.onFeltSecondary)
            .padding(.top, 6)
            .accessibilityLabel(language.text("현재 라운드: ", "Current round: ")
                                + TableEvent.streetName(hand.street, in: language))
    }

    private func boardBlock(_ hand: TableHand) -> some View {
        VStack(spacing: 10) {
            if !hand.board.isEmpty {
                SectionLabel(text: language.text("공용 카드", "Shared cards"))
                boardRow(hand)
            }
            Text(language.text("팟 \(bbText(hand.pot))bb", "Pot \(bbText(hand.pot))bb"))
                .font(GT.title(22).monospacedDigit()).foregroundStyle(GT.onFelt)
            if let toCall = hand.toCall, lastTurn == nil {
                Text(language.text("따라가려면 \(bbText(toCall))bb", "To call · \(bbText(toCall))bb"))
                    .font(GT.body(16).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func heroBlock(_ hand: TableHand) -> some View {
        VStack(spacing: 7) {
            SectionLabel(text: language.text("내 카드 · \(hand.heroSeat.plainName(in: language))",
                                             "Your cards · \(hand.heroSeat.plainName(in: language))"))
            CardRow(cards: hand.hero)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-hero-cards")
    }

    private func seatRow(_ hand: TableHand) -> some View {
        VStack(spacing: 8) {
            Text(hand.villain.beginnerTitle(in: language))
                .font(GT.title(18)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            if case let .over(outcome) = hand.phase {
                CardRow(cards: outcome.villainHand)
                    .accessibilityIdentifier("table-opponent-cards")
            } else {
                HStack(spacing: 8) {
                    PlayingCardView(card: Card(rank: 2, suit: 0), size: 46, faceDown: true)
                    PlayingCardView(card: Card(rank: 2, suit: 0), size: 46, faceDown: true)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("table-opponent-cards")
            }
            if let event = hand.events.last, lastTurn == nil {
                Text(event.text(in: language, plain: !termsLead))
                    .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var references: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            Button { showChart = true } label: {
                Label(language.text("차트", "Chart"), systemImage: "square.grid.3x3")
                    .font(GT.semibold(15)).frame(minHeight: 44)
            }
            .accessibilityIdentifier("table-chart")
            Button { showPolicyReference = true } label: {
                Label(language.text("상대 규칙", "Opponent rules"), systemImage: "info.circle")
                    .font(GT.semibold(15)).frame(minHeight: 44)
            }
            .accessibilityIdentifier("table-policy")
        }
        .foregroundStyle(GT.inkSecondary)
        .buttonStyle(GTPress())
    }

    private func boardRow(_ hand: TableHand) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                if i < hand.board.count {
                    PlayingCardView(card: hand.board[i])
                } else {
                    PlayingCardView(card: Card(rank: 2, suit: 0), faceDown: true)
                }
            }
        }
    }

    // MARK: the sheet

    @ViewBuilder
    private func sheet(_ hand: TableHand) -> some View {
        references
        if let lastTurn {
            turnReveal(lastTurn)
        } else if case let .over(outcome) = hand.phase {
            summary(hand, outcome)
        } else if case .hero(.open(let b)) = hand.phase {
            preflopButtons(hand, open: b)
        } else if let options {
            actionButtons(hand, options)
        } else {
            actionButtons(hand, [])
        }
    }

    private func actionButtons(_ hand: TableHand, _ options: [GradedOption]) -> some View {
        let fold = options.first { $0.choice == .fold }
        let passive = options.first { $0.choice == .check || $0.choice == .call }
        let raise = options.first { $0.choice == .raise }
        let bets = options.filter { if case .bet = $0.choice { return true }; return false }
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            if choosingBetSize {
                HStack {
                    Button { choosingBetSize = false } label: {
                        Label(language.text("뒤로", "Back"), systemImage: "chevron.left")
                            .font(GT.semibold(14)).foregroundStyle(GT.ink)
                            .frame(minHeight: 44)
                    }.buttonStyle(GTPress(pressedScale: 0.97))
                        .accessibilityIdentifier("table-size-back")
                    Spacer(minLength: 0)
                    Text(language.text("벳 크기", "Bet size")).font(GT.title(18)).foregroundStyle(GT.ink)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    betSizeButtons(bets)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("table-bet-sizes")
                } else {
                    ScrollView { betSizeButtons(bets) }
                        .frame(height: sizeChooserHeight)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("table-bet-sizes")
                }
            } else {
                Text(language.text("내 차례", "Your turn")).font(GT.title(18)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                actionLayout {
                    gradedAction(language.text("폴드", "Fold"), role: .fold, side: .leading,
                                 enabled: fold != nil,
                                 reason: options.isEmpty ? language.text("선택을 계산하고 있어요", "The choices are being calculated") : language.text("따라갈 금액이 없어 폴드할 수 없어요", "Fold is unavailable because nothing is owed")) {
                        if let fold { act(fold.choice) }
                    }.accessibilityIdentifier("table-fold")
                    gradedAction(passive?.actionName(in: language) ?? language.text("체크", "Check"),
                                 price: passive?.choice == .call ? (passive?.priceText ?? "") : "", role: .passive,
                                 enabled: passive != nil, reason: language.text("선택을 계산하고 있어요", "The choices are being calculated")) {
                        if let passive { act(passive.choice) }
                    }.accessibilityIdentifier("table-passive")
                    gradedAction(bets.isEmpty ? language.text("레이즈", "Raise") : language.text("벳", "Bet"),
                                 role: .aggressive, side: .trailing, enabled: raise != nil || !bets.isEmpty,
                                 reason: options.isEmpty ? language.text("선택을 계산하고 있어요", "The choices are being calculated") : language.text("이 결정에서는 레이즈가 허용되지 않아요", "This decision does not allow another raise")) {
                        if let raise { act(raise.choice) } else { choosingBetSize = true }
                    }.accessibilityIdentifier("table-aggressive")
                }
            }
            Text(language.text("이후 베팅이 없다는 가정으로 비교해요", "Compared assuming no later bets"))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func betSizeButtons(_ bets: [GradedOption]) -> some View {
        VStack(spacing: GT.Space.related) {
            ForEach(bets, id: \.choice) { option in
                PrimaryCTAButton(title: "\(option.headline(in: language)) · \(option.subline(in: language))") {
                    choosingBetSize = false
                    act(option.choice)
                }
                .accessibilityIdentifier("table-bet-size-\(option.headline(in: .english))")
            }
        }
    }

    private func gradedAction(_ title: String, price: String = "", role: GTActionRole,
                              side: GTCornerSide = .none, enabled: Bool = true,
                              reason: String = "", action: @escaping () -> Void) -> some View {
        GTActionButton(title: title, price: price, role: role, freeTablePresentation: true,
                       minHeight: 87, cornerSide: side, action: action)
            .disabled(!enabled).opacity(enabled ? 1 : 0.45)
            .accessibilityHint(enabled ? "" : reason)
    }

    private func preflopButtons(_ hand: TableHand, open b: Double) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            Text(language.text("내 차례", "Your turn")).font(GT.title(18)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
            actionLayout {
                gradedAction(language.text("폴드", "Fold"), role: .fold, side: .leading) {
                    actPreflop(.fold, hand)
                }.accessibilityIdentifier("table-fold")
                gradedAction(language.text("콜", "Call"), price: "\(bbText(b))bb", role: .passive) {
                    actPreflop(.call, hand)
                }.accessibilityIdentifier("table-passive")
                gradedAction(language.text("레이즈", "Raise"), role: .aggressive, side: .trailing) {
                    actPreflop(.raise, hand)
                }.accessibilityIdentifier("table-aggressive")
            }
            Text(language.text("시작 패는 앱 차트와 비교해요", "Starting hands are compared with the app's chart"))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Feedback belongs to the committed choice, including the hand-ending decision.
    private func turnReveal(_ turn: TurnRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            verdictRow(turn)
            Text(GradedTableLearning.takeaway(turn, language: language))
                .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("table-takeaway")
            DisclosureGroup(language.text("판정 자세히", "Decision details")) {
                VStack(alignment: .leading, spacing: 8) {
                    evPrices(turn)
                    Text(GradedTableLearning.basis(turn, language: language))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(.top, 8)
            }
            .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
            .accessibilityIdentifier("table-decision-details")
            PrimaryCTAButton(title: language.text("계속", "Continue")) {
                lastTurn = nil
                if let hand { prepareOptions(for: hand) }
            }
            .accessibilityIdentifier("table-continue")
        }
    }

    private func verdictRow(_ turn: TurnRecord) -> some View {
        let title: String
        let reference: String
        switch turn.verdict {
        case let .ev(loss, best):
            title = language.text("모델 기준 · ", "In this model · ") + evLossLabel(loss: loss, language: language)
            reference = language.text("모델 선택: ", "Model choice: ") + best.label(in: language)
        case let .chart(verdict):
            title = verdict.matched ? language.text("차트와 일치해요", "Matches the chart")
                                    : language.text("차트와 달라요", "Different from the chart")
            reference = language.text("차트: ", "Chart: ") + chartAction(verdict.chart)
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text(title).font(GT.title(20)).foregroundStyle(turn.band.ink)
            Text(language.text("내 선택: ", "Your choice: ") + turn.label(in: language))
                .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
            Text(reference).font(GT.semibold(15)).foregroundStyle(GT.ink)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("table-verdict")
    }

    private var actionLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    /// The graded sheet takes its verdict's tint; the action and summary sheets stay glass.
    private func sheetBand(_ hand: TableHand) -> GradeBand? {
        return lastTurn?.band
    }

    /// Absolute model values remain inspectable behind the optional explanation.
    @ViewBuilder
    private func evPrices(_ turn: TurnRecord) -> some View {
        if case let .ev(loss, best) = turn.verdict {
            VStack(spacing: 8) {
                priceRow(tag: language.text("모델 선택", "Model choice"), action: best.label(in: language),
                         amount: "\(bbText(best.ev))bb", ink: GTBand.spotOnInk)
                Divider().overlay(GT.border)
                priceRow(tag: language.text("선택한 답", "Your choice"), action: turn.label(in: language),
                         amount: "\(bbText(best.ev - loss))bb", ink: turn.band.ink)
                Text(language.text("모델 선택과 내 선택의 평균값 차이: \(bbText(loss))bb",
                                   "Difference in average value: \(bbText(loss))bb"))
                    .font(GT.body(10)).foregroundStyle(GT.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .gtInset(GT.Space.card, firstText: .semibold(12.5))
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control))
        }
    }

    private func priceRow(tag: String, action: String,
                          amount: String, ink: Color) -> some View {
        // At accessibility sizes the fixed tag column breaks 최선 and 내 선택 one syllable
        // per line, so the tag moves above the row instead.
        let stacked = dynamicTypeSize.isAccessibilitySize
        let tagText = Text(tag).font(GT.semibold(11)).foregroundStyle(GT.inkMuted)
        return VStack(alignment: .leading, spacing: 2) {
            if stacked { tagText }
            HStack(spacing: 8) {
                if !stacked { tagText.fixedSize(horizontal: true, vertical: false) }
                Text(action).font(GT.semibold(13)).foregroundStyle(GT.ink)
                Spacer(minLength: 6)
                Text(amount).font(GT.title(14).monospacedDigit()).foregroundStyle(ink)
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func actPreflop(_ choice: TableHand.HeroChoice, _ current: TableHand) {
        guard var h = hand, let v = h.preflopVerdict(for: choice) else { return }
        decisions.append(TurnRecord(street: 0, choice: choice, amount: nil,
                                    fraction: nil, verdict: .chart(v)))
        h.play(choice)
        hand = h
        lastTurn = decisions.last
        options = nil
        choosingBetSize = false
        _ = current
    }

    private func summary(_ hand: TableHand, _ outcome: TableHand.Outcome) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text("한 판 완료", "Hand complete"))
                .font(GT.title(22)).foregroundStyle(GT.ink)
            Text("\(resultLine(outcome)) · \(outcome.heroNet >= 0 ? "+" : "")\(bbText(outcome.heroNet))bb")
                .font(GT.body(16).monospacedDigit()).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(language.text("이긴 결과와 좋은 선택은 따로 봐요", "A winning result and a good decision are different"))
                .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            DisclosureGroup(language.text("선택 돌아보기", "Review decisions")) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(decisions.enumerated()), id: \.offset) { _, turn in
                        Text(TableEvent.streetName(turn.street, in: language))
                            .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                        verdictRow(turn)
                        Text(GradedTableLearning.takeaway(turn, language: language))
                            .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        evPrices(turn)
                    }
                }.padding(.top, 12)
            }
            .font(GT.semibold(15)).foregroundStyle(GT.inkSecondary)
            .accessibilityIdentifier("table-review-decisions")
            PrimaryCTAButton(title: language.text("다음 핸드", "Next hand")) { start(vs: villainPick) }
                .accessibilityIdentifier("table-next-hand")
            Button { hand2Picker() } label: {
                Text(language.text("상대 바꾸기", "Change opponent"))
                    .font(GT.semibold(15)).foregroundStyle(GT.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }.buttonStyle(GTPress())
        }
    }

    private func hand2Picker() {
        hand = nil; options = nil; lastTurn = nil; decisions = []
    }

    private func resultLine(_ o: TableHand.Outcome) -> String {
        if o.heroWon == nil { return language.text("무승부", "Tie") }
        if !o.wentToShowdown {
            return o.heroWon! ? language.text("상대 폴드", "Opponent folded")
                : language.text("폴드", "You folded")
        }
        return o.heroWon! ? language.text("쇼다운 승리", "Won at showdown")
            : language.text("쇼다운 패배", "Lost at showdown")
    }

    private func chartAction(_ action: DefendAction) -> String {
        switch action {
        case .fold: return language.text("폴드", "Fold")
        case .call: return language.text("콜", "Call")
        case .threeBet: return language.text("3벳", "3-bet")
        }
    }

    // MARK: acting

    private func act(_ choice: TableHand.HeroChoice) {
        guard var h = hand, let options else { return }
        record(choice, options: options, of: h)
        h.play(choice)
        hand = h
        lastTurn = decisions.last
        self.options = nil
    }

    private func record(_ choice: TableHand.HeroChoice, options: [GradedOption],
                        of hand: TableHand) {
        guard let grade = TableHand.graded(choice, with: options),
              let chosen = options.first(where: { $0.choice == choice }) else { return }
        let best = options.first { $0.label == grade.best.label } ?? chosen
        decisions.append(TurnRecord(street: hand.street, choice: choice,
                                    amount: chosen.amount,
                                    fraction: { if case let .bet(f) = choice { return f }; return nil }(),
                                    verdict: .ev(loss: grade.loss, best: best)))
    }

    /// The slow part, off the main thread on a copy (spec §3): exact on turn and
    /// river, sampled on the flop — a second or two in a debug build, milliseconds
    /// in release.
    private func prepareOptions(for hand: TableHand) {
        guard case .hero = hand.phase else { return }
        options = nil
        choosingBetSize = false
        Task.detached(priority: .userInitiated) {
            let priced = hand.gradedOptions()
            await MainActor.run {
                // A stale computation must never price a different node.
                if self.hand == hand { self.options = priced }
            }
        }
    }
}

private struct GradedFooterHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private extension GradedOption {
    /// Fold/check/call/raise sit on one compact row; bets get the two-line §A button.
    var isCompact: Bool {
        if case .bet = choice { return false }
        return true
    }
    /// "75%" for a bet — §A: the pro unit leads postflop.
    func headline(in language: LearningLanguage) -> String {
        if case let .bet(f) = choice { return "\(pctText(f * 100))%" }
        return label(in: language)
    }
    /// The resolved amount comes from the graded option, not its display copy.
    func subline(in language: LearningLanguage) -> String {
        _ = language
        return amount.map { "\(bbText($0))bb" } ?? ""
    }
    /// The verb on its own; prices form a separate visual column.
    func actionName(in language: LearningLanguage) -> String {
        switch choice {
        case .fold: return language.text("폴드", "Fold")
        case .check: return language.text("체크", "Check")
        case .call: return language.text("콜", "Call")
        case .raise: return language.text("레이즈", "Raise")
        case .bet: return language.text("벳", "Bet")
        }
    }
    /// What committing costs. 폴드 and 체크 are stated as 0bb rather than left blank:
    /// it is the number the reveal's EV comparison is read against.
    var priceText: String {
        switch choice {
        case .fold, .check: return "0bb"
        default: return amount.map { "\(bbText($0))bb" } ?? "0bb"
        }
    }
    /// Money class, not merit — see `GTActionRole`.
    var role: GTActionRole {
        switch choice {
        case .fold:         return .fold
        case .check, .call: return .passive
        case .raise, .bet:  return .aggressive
        }
    }
}
