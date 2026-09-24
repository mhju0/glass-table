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
    @State private var hand: TableHand?
    @State private var options: [GradedOption]?
    @State private var lastTurn: TurnRecord?
    @State private var decisions: [TurnRecord] = []
    @State private var baseSeed = UInt64.random(in: 0..<UInt64.max)
    @State private var handIndex = 0
    @State private var villainPick: Archetype?
    @State private var pickerSelection: OpponentSelection?

    private enum OpponentSelection: Equatable {
        case archetype(Archetype)
        case random
    }

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
        .sheet(isPresented: $showChart) {
            if let hand {
                ScrollView {
                  VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        ChromeButton.close { showChart = false }
                        Spacer()
                    }
                    Text(language.text("디펜드 차트 · \(hand.villainSeat.rawValue) 오픈에 맞서",
                                       "Defend chart · facing a \(hand.villainSeat.rawValue) open"))
                        .font(GT.title(16)).foregroundStyle(GT.onFelt)
                        .padding(.horizontal, 18)
                    Text(language.text("오픈 레인지 폭에서 유도한 기준선이에요. 자세한 방법은 앱이 다 보여드려요.",
                                       "A baseline from this seat's opening range. The app shows how."))
                        .font(GT.body(11)).foregroundStyle(GT.onFeltSecondary)
                        .padding(.horizontal, 18)
                    DefendGridView(opener: hand.villainSeat,
                                   highlight: HandClass(hand.hero), cards: hand.hero)
                        .padding(18)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FeltBackground())
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
            }
            #endif
        }
    }

    // MARK: picker

    private var picker: some View {
        ScrollView {
            OpponentPickerView { start(vs: $0) }
                .padding(18)
        }
        .gtTabBarClearance(20)
    }

    private func start(vs villain: Archetype?) {
        villainPick = villain
        decisions = []; lastTurn = nil; options = nil
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
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .gtCard(radius: GT.Radius.panel)
                    }
                    .padding(.horizontal, 18).padding(.bottom, 28)
                }
            } else {
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
                    }
                    ActionSheet { sheet(hand) }.layoutPriority(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Which street we are on, from `hand.street` — not parsed back out of the history
    /// lines, which are display strings and would be the wrong thing to depend on.
    private func streetStrip(_ hand: TableHand) -> some View {
        let streets: [(name: String, n: Int)] =
            [(language.text("프리플랍", "Before"), 0),
             (language.text("플랍", "Flop"), 3),
             (language.text("턴", "Turn"), 4),
             (language.text("리버", "River"), 5)]
        return HStack(spacing: 6) {
            ForEach(streets, id: \.n) { s in
                let live = hand.street == s.n
                let past = hand.street > s.n
                Text(s.name)
                    .font(GT.semibold(10.5))
                    .foregroundStyle(live ? GT.mint : (past ? GT.onFeltSecondary : GT.onFeltMuted))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .background(live ? GT.mint.opacity(0.14) : Color.clear, in: Capsule())
                    .overlay(Capsule().strokeBorder(live ? GT.mint.opacity(0.55) : GT.hairlineFelt,
                                                    lineWidth: 1))
            }
        }
        .padding(.top, 8)
        // Four streets in fixed order, so this is a one-row diagram for the same reason
        // the drills' seat strip is: 프리플랍 was breaking across two lines and taking
        // the row's height with it.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.text("현재 스트리트 ", "Current round: ")
            + (streets.first { $0.n == hand.street }?.name ?? ""))
    }

    /// The board, and directly beneath it the money it is being played for. 팟 used to
    /// sit in the opposite corner of the screen from 콜, so reading a price meant
    /// crossing the whole viewport for its other half.
    private func boardBlock(_ hand: TableHand) -> some View {
        VStack(spacing: 12) {
            SectionLabel(text: language.text("공용 카드", "Shared cards"))
            boardRow(hand)
            if let toCall = hand.toCall, hand.street == 0 {
                preflopPriceReference(pot: hand.pot, toCall: toCall)
            } else if let toCall = hand.toCall {
                priceStrip(pot: hand.pot, toCall: toCall)
            } else {
                // Nothing owed: no price to read, so the pot stands on its own.
                Text(language.text("팟 \(bbText(hand.pot))bb", "Pot \(bbText(hand.pot))bb"))
                    .font(GT.title(21).monospacedDigit()).foregroundStyle(GT.onFelt)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Rectangle().fill(GT.hairlineFelt).frame(height: 1)
        }
    }

    /// Preflop choices are graded by the published defend chart, not by raw pot odds.
    /// Keep the actual chips visible while withholding a threshold that would read as
    /// a second recommendation beside the chart verdict.
    private func preflopPriceReference(pot: Double, toCall: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(language.text("참고", "For reference"))
                .font(GT.semibold(11)).foregroundStyle(GT.mint)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(GT.mint.opacity(0.14), in: Capsule())
            Text(language.text("현재 팟 \(bbText(pot))bb · 콜 \(bbText(toCall))bb",
                               "Pot now \(bbText(pot))bb · Call \(bbText(toCall))bb"))
                .font(GT.body(14).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(language.text(
            "참고. 현재 팟 \(bbText(pot)) 빅블라인드, 콜 \(bbText(toCall)) 빅블라인드. 프리플랍 판정은 디펜드 차트 기준.",
            "For reference. Pot now \(bbText(pot)) big blinds; call \(bbText(toCall)) big blinds. Before the flop, the defend chart grades your choice."))
    }

    /// The pot-odds shape at a glance: what is already out there against what continuing
    /// costs, plus the equity that price demands.
    ///
    /// Drawn here rather than with `PriceBarView` because that one is built for the
    /// drill — 58pt tall with stacked numerals, and typed in whole bb. The table's pots
    /// are fractional (13.1bb, not 13bb) and its vertical budget is a strip, so it reuses
    /// the segment *tokens* to keep one colour language and nothing else.
    private func priceStrip(pot: Double, toCall: Double) -> some View {
        // Round to the printed precision *first*, then do the arithmetic on the values
        // actually on screen. Rounding each term independently let the addends disagree
        // with their own total — 13.1 and 5.6 printed under a total of 18.8 — and a
        // division the user cannot reproduce is the one thing this screen cannot ship.
        let p = (pot * 10).rounded() / 10
        let c = (toCall * 10).rounded() / 10
        let total = p + c
        let required = c / total * 100
        return VStack(spacing: 8) {
            // Widths are proportional, so the price is legible as a share of the bar
            // before it is read as a number — the same claim `PriceBarView` makes.
            // `layoutPriority` cannot do this: it decides who gets its ideal size
            // first, so with two greedy segments the larger one simply took the row.
            GeometryReader { geo in
                HStack(spacing: 3) {
                    segment(language.text("팟 \(bbText(p))", "Pot \(bbText(p))"), fill: GT.segPot,
                            width: geo.size.width * p / total)
                    segment(language.text("콜 \(bbText(c))", "Call \(bbText(c))"), fill: GT.segCall,
                            width: geo.size.width * c / total)
                }
            }
            .frame(height: 30)
            Text(language.text("\(bbText(c)) / \(bbText(total)) · 필요 에퀴티 \(pctText(required))%",
                               "\(bbText(c)) / \(bbText(total)) · Need \(pctText(required))% chance to win"))
                .font(GT.body(14).monospacedDigit())
                .foregroundStyle(GT.onFeltSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.text(
            "팟 \(bbText(p)) 빅블라인드, 콜 \(bbText(c)) 빅블라인드. 필요 에퀴티 \(pctText(required)) 퍼센트.",
            "Pot \(bbText(p)) big blinds; call \(bbText(c)) big blinds. Need \(pctText(required)) percent chance to win."))
    }

    private func segment(_ text: String, fill: Color, width: CGFloat) -> some View {
        Text(text)
            .font(GT.semibold(14).monospacedDigit()).foregroundStyle(GT.onTable)
            .lineLimit(1).minimumScaleFactor(0.8)
            .frame(width: max(38, width - 3), height: 30)
            .background(fill, in: RoundedRectangle(cornerRadius: 8))
    }

    private func heroBlock(_ hand: TableHand) -> some View {
        VStack(spacing: 7) {
            SectionLabel(text: language.text("내 카드 · \(hand.heroSeat.rawValue)",
                                             "Your cards · \(hand.heroSeat.rawValue)"))
            CardRow(cards: hand.hero)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-hero-cards")
    }

    /// Opponent cards stay centered as the first of the table's three reading regions.
    /// The action history remains directly below so it does not compete with ownership.
    private func seatRow(_ hand: TableHand) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(language.text("상대 카드 · \(hand.villainSeat.rawValue) · \(hand.villain.beginnerTitle(in: language))",
                                   "Opponent cards · \(hand.villainSeat.rawValue) · \(hand.villain.beginnerTitle(in: language))"))
                    .font(GT.title(16)).foregroundStyle(GT.onFelt)
                Spacer(minLength: 8)
                // The bot's live range, always countable — the printable claim at
                // the table (spec §4).
                Button { showPolicyReference = true } label: {
                    HStack(spacing: 4) {
                        Text(language.text("레인지 \(hand.villainCombos.count)콤보",
                                           "Possible hands \(hand.villainCombos.count)"))
                            .font(GT.semibold(14).monospacedDigit())
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(GT.mint)
                }
                .buttonStyle(GTPress())
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel(language.text(
                    "상대 전략과 레인지 보기, 현재 \(hand.villainCombos.count)콤보",
                    "View opponent strategy and possible hands; \(hand.villainCombos.count) possible hands"))
            }
            VStack(spacing: 0) {
                if case let .over(o) = hand.phase {
                    CardRow(cards: o.villainHand)
                } else {
                    HStack(spacing: 8) {
                        PlayingCardView(card: Card(rank: 2, suit: 0), faceDown: true)
                        PlayingCardView(card: Card(rank: 2, suit: 0), faceDown: true)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(hand.events.suffix(3).enumerated()), id: \.offset) { _, event in
                    Text(event.text(in: language)).font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                        .fixedSize(horizontal: false, vertical: dynamicTypeSize.isAccessibilitySize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 4).padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            Rectangle().fill(GT.hairlineFelt).frame(height: 1)
        }
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
        if case let .over(outcome) = hand.phase {
            summary(hand, outcome)
        } else if let lastTurn {
            turnReveal(lastTurn)
        } else if case .hero(.open(let b)) = hand.phase {
            preflopButtons(hand, open: b)
        } else if let options {
            actionButtons(hand, options)
        } else {
            HStack(spacing: 10) {
                ProgressView().tint(GT.inkMuted)
                Text(language.text("계산 중…", "Calculating…"))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        }
    }

    private func actionButtons(_ hand: TableHand, _ options: [GradedOption]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(options.filter(\.isCompact), id: \.choice) { opt in
                    GTActionButton(title: opt.actionName(in: language), price: opt.priceText,
                                   role: opt.role) { act(opt.choice) }
                }
            }
            let bets = options.filter { !$0.isCompact }
            if !bets.isEmpty {
                // §A: headline is the pro unit (% of pot), resolved bb underneath.
                HStack(spacing: 8) {
                    ForEach(bets, id: \.choice) { opt in bviewButton(opt) }
                }
            }
            Text(language.text("체크다운 근사 · 이후 베팅 없음, 레이크 제외",
                               "Estimate: no later bets, fees excluded"))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// A bet keeps its own emphasis order — §A puts the pro unit (% of pot) on top and
    /// the resolved bb underneath, the reverse of `GTActionButton` — so it stays a
    /// separate view. It takes the aggressive accent so the row still reads as one set.
    private func bviewButton(_ opt: GradedOption) -> some View {
        Button { act(opt.choice) } label: {
            VStack(spacing: 3) {
                Text(opt.headline(in: language)).font(GT.title(15)).foregroundStyle(GT.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(opt.subline(in: language)).font(GT.body(14).monospacedDigit())
                    .foregroundStyle(GT.inkMuted)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Capsule().fill(GTActionRole.aggressive.accent)
                    .frame(height: 3).padding(.horizontal, 8).padding(.top, 1)
            }
            .padding(.horizontal, 6).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(language.text("벳 \(opt.headline(in: language)), \(opt.subline(in: language))",
                                           "Bet \(opt.headline(in: language)), \(opt.subline(in: language))"))
    }

    /// 폴드 / 콜 3bb / 3벳 9bb. No pricing pass — the grade here is the chart.
    private func preflopButtons(_ hand: TableHand, open b: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                GTActionButton(title: language.text("폴드", "Fold"), price: "0bb", role: .fold) {
                    actPreflop(.fold, hand)
                }
                GTActionButton(title: language.text("콜", "Call"), price: "\(bbText(b))bb", role: .passive) {
                    actPreflop(.call, hand)
                }
                GTActionButton(title: language.text("3벳", "3-bet"),
                               price: "\(bbText(b * TableHand.raiseFactor))bb",
                               role: .aggressive) { actPreflop(.raise, hand) }
            }
            Text(language.text("프리플랍은 앱의 디펜드 차트와 비교해요. 최적 전략은 아니에요.",
                               "Preflop is graded on the app's defend chart, not perfect play."))
                .font(GT.body(11)).foregroundStyle(GT.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The reveal, lesson first.
    ///
    /// The old order led with the score at 28pt and dropped the lesson — "최선은 폴드" —
    /// into 12pt grey underneath, which is backwards: the number is the mark, the
    /// sentence is the thing worth carrying to the next hand. The severity keeps its
    /// band ink and glyph but moves to a pill beside the headline.
    ///
    /// Exact and near-best choices share a progression band, while the pill names the
    /// distinction directly. The cost below remains the evidence for that judgment.
    private func turnReveal(_ turn: TurnRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                headlineText(turn).font(GT.title(20))
                bandPill(turn)
                Spacer(minLength: 0)
            }
            evPrices(turn)
            if case .chart = turn.verdict {
                SecondaryCTAButton(title: language.text("차트 보기", "View chart")) { showChart = true }
            }
            PrimaryCTAButton(title: language.text("계속", "Continue")) {
                lastTurn = nil
                if let hand { prepareOptions(for: hand) }
            }
        }
    }

    /// 은/는 attaches to 최선, a fixed word, so the opponent's action never needs a
    /// computed particle — the reason this phrasing survived from the old reveal.
    private func headlineText(_ turn: TurnRecord) -> Text {
        switch turn.verdict {
        case let .ev(loss, best):
            if loss <= 0 { return Text(language.text("최선의 선택", "Best choice")).foregroundStyle(GT.ink) }
            return Text(language.text("최선은 ", "Better choice: ")).foregroundStyle(GT.ink)
                 + Text(best.label(in: language)).foregroundStyle(GT.green)
        case let .chart(v):
            if v.matched { return Text(language.text("차트대로", "Matches the chart")).foregroundStyle(GT.ink) }
            return Text(language.text("차트는 ", "Chart suggests: ")).foregroundStyle(GT.ink)
                 + Text(chartAction(v.chart)).foregroundStyle(GT.green)
        }
    }

    private func bandPill(_ turn: TurnRecord) -> some View {
        let word: String = {
            if case let .ev(loss, _) = turn.verdict {
                return language == .korean ? evLossLabel(loss: loss)
                    : (loss <= 0 ? "Best" : loss <= 0.5 ? "Close" : "Needs work")
            }
            return turn.band == .spotOn ? language.text("일치", "Match")
                : language.text("불일치", "Different")
        }()
        return HStack(spacing: 4) {
            Image(systemName: turn.band.glyph).font(.system(size: 10, weight: .bold))
            Text(word).font(GT.semibold(11))
        }
        .foregroundStyle(turn.band.ink)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(turn.band.tint, in: Capsule())
        .accessibilityLabel(language.text("판정 \(word)", "Result: \(word)"))
    }

    /// Where the number came from: the best line and the chosen line, side by side.
    /// A bare "\u{2212}4.1bb" is a verdict; the same figure against 폴드 0bb is a
    /// subtraction the user can check, which is what the app claims to be for.
    @ViewBuilder
    private func evPrices(_ turn: TurnRecord) -> some View {
        if case let .ev(loss, best) = turn.verdict, loss > 0 {
            VStack(spacing: 8) {
                priceRow(tag: language.text("최선", "Best"), action: best.label(in: language),
                         amount: "0bb", ink: GTBand.spotOnInk)
                Divider().overlay(GT.border)
                priceRow(tag: language.text("내 선택", "You"), action: turn.label(in: language),
                         amount: "\u{2212}\(bbText(loss))bb", ink: turn.band.ink)
                Text(language.text("숫자는 최선 대비 손실이에요",
                                   "This is the estimated value lost versus the best choice."))
                    .font(GT.body(10)).foregroundStyle(GT.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
        }
    }

    private func priceRow(tag: String, action: String,
                          amount: String, ink: Color) -> some View {
        HStack(spacing: 8) {
            Text(tag).font(GT.semibold(11)).foregroundStyle(GT.inkMuted)
                .frame(width: 46, alignment: .leading)
            Text(action).font(GT.semibold(13)).foregroundStyle(GT.ink)
            Spacer(minLength: 6)
            Text(amount).font(GT.title(14).monospacedDigit()).foregroundStyle(ink)
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
        _ = current
    }

    /// The tallest sheet in the app — net result, a row per decision, and two actions —
    /// so it is also the one that decides how much band the table above it gets. Its
    /// spacings are tighter than the other sheets on purpose.
    private func summary(_ hand: TableHand, _ outcome: TableHand.Outcome) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(outcome.heroNet >= 0 ? "+\(bbText(outcome.heroNet))bb"
                                          : "\(bbText(outcome.heroNet))bb")
                    .font(GT.title(26).monospacedDigit()).foregroundStyle(GT.ink)
                Text(resultLine(outcome))
                    .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
                Spacer(minLength: 0)
            }
            // Result and decision quality, side by side — the gap between them is
            // the thing poker teaches slowest (spec §4).
            let evDecisions = decisions.compactMap { decision -> (TurnRecord, Double)? in
                guard case let .ev(loss, _) = decision.verdict else { return nil }
                return (decision, loss)
            }
            let lost = evDecisions.reduce(0.0) { $0 + $1.1 }
            let highestCost = evDecisions.max { $0.1 < $1.1 }

            VStack(alignment: .leading, spacing: 4) {
                Text(language.text("결과와 결정은 따로 봐요", "Result and decisions are different"))
                    .font(GT.title(15)).foregroundStyle(GT.ink)
                Text(language.text(
                    "이번 결과는 \(resultLine(outcome)) · \(outcome.heroNet >= 0 ? "+" : "")\(bbText(outcome.heroNet))bb예요.",
                    "This hand: \(resultLine(outcome)) · \(outcome.heroNet >= 0 ? "+" : "")\(bbText(outcome.heroNet))bb."))
                    .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if evDecisions.isEmpty {
                    Text(language.text("프리플랍 결정은 공개된 디펜드 차트와 비교했어요. EV 손실은 측정하지 않았어요.",
                                       "The before-flop choice used the published defend chart. No value loss was estimated."))
                        .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(language.text("포스트플랍 체크다운 근사로 측정한 EV 손실은 \(bbText(lost))bb예요.",
                                       "EV lost after the flop, by checkdown estimate: \(bbText(lost))bb."))
                        .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let highestCost, highestCost.1 > 0 {
                    Text(language.text(
                        "가장 큰 비용 · \(TableEvent.streetName(highestCost.0.street, in: language)) \(highestCost.0.label(in: language)), −\(bbText(highestCost.1))bb",
                        "Largest missed value · \(TableEvent.streetName(highestCost.0.street, in: language)) \(highestCost.0.label(in: language)), −\(bbText(highestCost.1))bb"))
                        .font(GT.semibold(12.5)).foregroundStyle(highestCost.0.band.ink)
                }
            }
            .padding(12)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                         style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(decisions.enumerated()), id: \.offset) { _, d in
                    HStack {
                        Text("\(TableEvent.streetName(d.street, in: language)) · \(d.label(in: language))")
                            .font(GT.body(11.5)).foregroundStyle(GT.inkSecondary)
                        Spacer(minLength: 6)
                        Group {
                            switch d.verdict {
                            case let .ev(loss, _):
                                Text(loss <= 0 ? language.text("최선", "Best") : "\u{2212}\(bbText(loss))bb")
                            case let .chart(v):
                                Text(v.matched ? language.text("차트대로", "Chart match")
                                     : language.text("차트: \(v.chart.rawValue)", "Chart: \(chartAction(v.chart))"))
                            }
                        }
                        .font(GT.semibold(11.5).monospacedDigit())
                        .foregroundStyle(d.band.ink)
                    }
                }
                if decisions.count > 1 {
                    Divider()
                    HStack {
                        Text(language.text("이 핸드에서 버린 EV", "Value lost this hand"))
                            .font(GT.semibold(11.5))
                            .foregroundStyle(GT.ink)
                        Spacer(minLength: 6)
                        Text("\(bbText(lost))bb")
                            .font(GT.semibold(11.5).monospacedDigit()).foregroundStyle(GT.ink)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
            PrimaryCTAButton(title: language.text("다음 핸드", "Next hand")) { start(vs: villainPick) }
            // Text rather than a filled secondary: it is the rarer of the two actions,
            // and a full 50pt surface here bought nothing but height on the sheet that
            // can least afford it. The row keeps the 44pt tap target.
            Button { hand2Picker() } label: {
                Text(language.text("상대 바꾸기", "Change opponent"))
                    .font(GT.semibold(13.5))
                    .foregroundStyle(GT.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
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
        Task.detached(priority: .userInitiated) {
            let priced = hand.gradedOptions()
            await MainActor.run {
                // A stale computation must never price a different node.
                if self.hand == hand { self.options = priced }
            }
        }
    }
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
