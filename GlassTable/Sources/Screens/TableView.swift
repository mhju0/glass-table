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
    @State private var hand: TableHand?
    @State private var options: [GradedOption]?
    @State private var lastTurn: TurnRecord?
    @State private var decisions: [TurnRecord] = []
    @State private var baseSeed = UInt64.random(in: 0..<UInt64.max)
    @State private var handIndex = 0
    @State private var villainPick: Archetype?

    /// One graded hero decision, kept for the pill and the summary. Postflop
    /// decisions carry a bb price; the preflop one carries the chart verdict —
    /// future-value is exactly what the checkdown model cannot price (R5 §3).
    struct TurnRecord: Equatable {
        let street: String
        let label: String
        enum Verdict: Equatable {
            case ev(loss: Double, best: String)
            case chart(TableHand.PreflopVerdict)
        }
        let verdict: Verdict

        var band: GradeBand {
            switch verdict {
            case let .ev(loss, _): return evLossBand(bb: loss)
            case let .chart(v): return v.matched ? .spotOn : .off
            }
        }
    }
    @State private var showChart = false

    var body: some View {
        Group {
            if let hand { table(hand) } else { picker }
        }
        .background(FeltBackground())
        .sheet(isPresented: $showChart) {
            if let hand {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        ChromeButton.close { showChart = false }
                        Spacer()
                    }
                    Text("디펜드 차트 · \(hand.villainSeat.rawValue) 오픈에 맞서")
                        .font(GT.title(16)).foregroundStyle(GT.onFelt)
                        .padding(.horizontal, 18)
                    Text("오픈 레인지 폭에서 유도한 기준선이에요. 자세한 방법은 앱이 다 보여드려요.")
                        .font(GT.body(11)).foregroundStyle(GT.onFeltSecondary)
                        .padding(.horizontal, 18)
                    DefendGridView(opener: hand.villainSeat,
                                   highlight: HandClass(hand.hero))
                        .padding(18)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FeltBackground())
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
                            decisions.append(TurnRecord(street: "프리플랍", label: "콜",
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
                prepareOptions(for: h)
            }
            #endif
        }
    }

    // MARK: picker

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("테이블").font(GT.title(24)).foregroundStyle(GT.onFelt)
                    .padding(.top, 14)
                Text("선언된 상대와 한 핸드씩. 모든 결정을 bb로 채점해요.")
                    .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                    .padding(.bottom, 8)
                ForEach(Archetype.allCases, id: \.self) { a in
                    Button { start(vs: a) } label: { archetypeRow(a) }
                        .buttonStyle(GTPress())
                }
                Button { start(vs: nil) } label: {
                    HStack {
                        Text("랜덤 상대").font(GT.title(13.5)).foregroundStyle(GT.ink)
                        Spacer(minLength: 0)
                        Image(systemName: "dice.fill")
                            .font(.system(size: 13)).foregroundStyle(GT.inkMuted)
                    }
                    .padding(14).frame(maxWidth: .infinity)
                    .gtCard(radius: 14)
                }
                .buttonStyle(GTPress())
            }
            .padding(.horizontal, 18)
        }
        .gtTabBarClearance()
    }

    private func archetypeRow(_ a: Archetype) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(a.name).font(GT.title(13.5)).foregroundStyle(GT.ink)
                Text(a.blurb).font(GT.body(11)).foregroundStyle(GT.inkMuted).lineLimit(1)
            }
            Spacer(minLength: 0)
            Text("VPIP \(Int(a.vpip)) · PFR \(Int(a.pfr))")
                .font(GT.semibold(10).monospacedDigit()).foregroundStyle(GT.inkMuted)
        }
        .padding(14).frame(maxWidth: .infinity)
        .gtCard(radius: 14)
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
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        seatRow(hand)
                        streetStrip(hand)
                        Spacer(minLength: 14)
                        boardBlock(hand)
                        Spacer(minLength: 14)
                        heroBlock(hand)
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            // The sheet is sized first and the reader takes what is left. A
            // GeometryReader is greedy in a VStack, so without this it claimed the
            // height the sheet needed and the action buttons clipped their price line
            // at the accessibility text sizes.
            ActionSheet { sheet(hand) }.layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Which street we are on, from `hand.street` — not parsed back out of the history
    /// lines, which are display strings and would be the wrong thing to depend on.
    private func streetStrip(_ hand: TableHand) -> some View {
        let streets: [(name: String, n: Int)] =
            [("프리플랍", 0), ("플랍", 3), ("턴", 4), ("리버", 5)]
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
        .padding(.top, 12)
        // Four streets in fixed order, so this is a one-row diagram for the same reason
        // the drills' seat strip is: 프리플랍 was breaking across two lines and taking
        // the row's height with it.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("현재 스트리트 "
            + (streets.first { $0.n == hand.street }?.name ?? ""))
    }

    /// The board, and directly beneath it the money it is being played for. 팟 used to
    /// sit in the opposite corner of the screen from 콜, so reading a price meant
    /// crossing the whole viewport for its other half.
    private func boardBlock(_ hand: TableHand) -> some View {
        VStack(spacing: 12) {
            boardRow(hand)
            if let toCall = hand.toCall {
                priceStrip(pot: hand.pot, toCall: toCall)
            } else {
                // Nothing owed: no price to read, so the pot stands on its own.
                Text("팟 \(bbText(hand.pot))bb")
                    .font(GT.title(21).monospacedDigit()).foregroundStyle(GT.onFelt)
            }
        }
        .frame(maxWidth: .infinity)
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
                    segment("팟 \(bbText(p))", fill: GT.segPot,
                            width: geo.size.width * p / total)
                    segment("콜 \(bbText(c))", fill: GT.segCall,
                            width: geo.size.width * c / total)
                }
            }
            .frame(height: 30)
            Text("\(bbText(c)) / \(bbText(total)) — \(pctText(required))% 이상이면 콜")
                .font(GT.body(10.5).monospacedDigit())
                .foregroundStyle(GT.onFeltSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("팟 \(bbText(p)) 빅블라인드, 콜 \(bbText(c)) 빅블라인드. "
                            + "필요 에퀴티 \(pctText(required)) 퍼센트.")
    }

    private func segment(_ text: String, fill: Color, width: CGFloat) -> some View {
        Text(text)
            .font(GT.semibold(12).monospacedDigit()).foregroundStyle(GT.onFelt)
            .lineLimit(1).minimumScaleFactor(0.6)
            .frame(width: max(38, width - 3), height: 30)
            .background(fill, in: RoundedRectangle(cornerRadius: 8))
    }

    private func heroBlock(_ hand: TableHand) -> some View {
        VStack(spacing: 7) {
            CardRow(cards: hand.hero, maxSize: 74)
            Text("내 핸드 · \(hand.heroSeat.rawValue)")
                .font(GT.semibold(10)).tracking(0.4)
                .foregroundStyle(GT.onFelt.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    /// Villain, and what has happened so far. The action log used to run as four full
    /// lines under hero's cards; the band beside two 60pt card backs was empty, and it
    /// holds the same lines at the same size.
    private func seatRow(_ hand: TableHand) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("vs \(hand.villain.name)").font(GT.title(16)).foregroundStyle(GT.onFelt)
                Spacer(minLength: 8)
                // The bot's live range, always countable — the printable claim at
                // the table (spec §4).
                Text("레인지 \(hand.villainCombos.count)콤보")
                    .font(GT.semibold(11).monospacedDigit())
                    .foregroundStyle(GT.mint)
            }
            HStack(alignment: .top, spacing: 10) {
                if case let .over(o) = hand.phase {
                    CardRow(cards: o.villainHand, maxSize: 60)
                } else {
                    PlayingCardView(card: Card(rank: 2, suit: 0), size: 60, faceDown: true)
                    PlayingCardView(card: Card(rank: 2, suit: 0), size: 60, faceDown: true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel(text: "\(hand.villainSeat.rawValue) · \(hand.villain.name)")
                    ForEach(Array(hand.history.suffix(3).enumerated()), id: \.offset) { _, line in
                        Text(line).font(GT.body(10.5)).foregroundStyle(GT.onFeltSecondary)
                            .lineLimit(1).minimumScaleFactor(0.75)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.top, 6)
    }

    private func boardRow(_ hand: TableHand) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                if i < hand.board.count {
                    PlayingCardView(card: hand.board[i], size: 64)
                } else {
                    PlayingCardView(card: Card(rank: 2, suit: 0), size: 64, faceDown: true)
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
                Text("계산 중…").font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        }
    }

    private func actionButtons(_ hand: TableHand, _ options: [GradedOption]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(options.filter(\.isCompact), id: \.choice) { opt in
                    GTActionButton(title: opt.actionName, price: opt.priceText,
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
            Text("채점은 이 스트리트 이후 베팅이 없다고 가정해요")
                .font(GT.body(10)).foregroundStyle(GT.inkMuted)
        }
    }

    /// A bet keeps its own emphasis order — §A puts the pro unit (% of pot) on top and
    /// the resolved bb underneath, the reverse of `GTActionButton` — so it stays a
    /// separate view. It takes the aggressive accent so the row still reads as one set.
    private func bviewButton(_ opt: GradedOption) -> some View {
        Button { act(opt.choice) } label: {
            VStack(spacing: 3) {
                Text(opt.headline).font(GT.title(13)).foregroundStyle(GT.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(opt.subline).font(GT.body(10).monospacedDigit())
                    .foregroundStyle(GT.inkMuted)
                    .lineLimit(1).minimumScaleFactor(0.6)
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
        .accessibilityLabel("벳 \(opt.headline), \(opt.subline)")
    }

    /// 폴드 / 콜 3bb / 3벳 9bb. No pricing pass — the grade here is the chart.
    private func preflopButtons(_ hand: TableHand, open b: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                GTActionButton(title: "폴드", price: "0bb", role: .fold) {
                    actPreflop(.fold, hand)
                }
                GTActionButton(title: "콜", price: "\(bbText(b))bb", role: .passive) {
                    actPreflop(.call, hand)
                }
                GTActionButton(title: "3벳",
                               price: "\(bbText(b * TableHand.raiseFactor))bb",
                               role: .aggressive) { actPreflop(.raise, hand) }
            }
            Text("프리플랍은 디펜드 차트로 채점해요 — 답한 뒤에 차트를 보여드려요")
                .font(GT.body(10)).foregroundStyle(GT.inkMuted)
        }
    }

    /// The reveal, lesson first.
    ///
    /// The old order led with the score at 28pt and dropped the lesson — "최선은 폴드" —
    /// into 12pt grey underneath, which is backwards: the number is the mark, the
    /// sentence is the thing worth carrying to the next hand. The severity keeps its
    /// band ink and glyph but moves to a pill beside the headline.
    ///
    /// §D's 최선 band is "optimal *or near-optimal*", so it can sit beside a headline
    /// naming a different action as best. That pairing is only readable because the
    /// cost is printed directly under it — which is what `evPrices` is for, and why it
    /// is not optional decoration.
    private func turnReveal(_ turn: TurnRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                headlineText(turn).font(GT.title(20))
                bandPill(turn)
                Spacer(minLength: 0)
            }
            evPrices(turn)
            if case .chart = turn.verdict {
                SecondaryCTAButton(title: "차트 보기") { showChart = true }
            }
            PrimaryCTAButton(title: "계속") {
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
            if loss <= 0 { return Text("최선의 선택").foregroundStyle(GT.ink) }
            return Text("최선은 ").foregroundStyle(GT.ink)
                 + Text(best).foregroundStyle(GT.green)
        case let .chart(v):
            if v.matched { return Text("차트대로").foregroundStyle(GT.ink) }
            return Text("차트는 ").foregroundStyle(GT.ink)
                 + Text(v.chart.rawValue).foregroundStyle(GT.green)
        }
    }

    private func bandPill(_ turn: TurnRecord) -> some View {
        let word: String = {
            if case .ev = turn.verdict { return turn.band.evLossLabel }
            return turn.band == .spotOn ? "일치" : "불일치"
        }()
        return HStack(spacing: 4) {
            Image(systemName: turn.band.glyph).font(.system(size: 10, weight: .bold))
            Text(word).font(GT.semibold(11))
        }
        .foregroundStyle(turn.band.ink)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(turn.band.tint, in: Capsule())
        .accessibilityLabel("판정 \(word)")
    }

    /// Where the number came from: the best line and the chosen line, side by side.
    /// A bare "\u{2212}4.1bb" is a verdict; the same figure against 폴드 0bb is a
    /// subtraction the user can check, which is what the app claims to be for.
    @ViewBuilder
    private func evPrices(_ turn: TurnRecord) -> some View {
        if case let .ev(loss, best) = turn.verdict, loss > 0 {
            VStack(spacing: 8) {
                priceRow(tag: "최선", action: best,
                         amount: "0bb", ink: GTBand.spotOnInk)
                Divider().overlay(GT.border)
                priceRow(tag: "내 선택", action: turn.label,
                         amount: "\u{2212}\(bbText(loss))bb", ink: turn.band.ink)
                Text("숫자는 최선 대비 손실이에요")
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
        let label: String
        switch choice {
        case .fold: label = "폴드"
        case .call: label = "콜"
        default: label = "3벳"
        }
        decisions.append(TurnRecord(street: "프리플랍", label: label, verdict: .chart(v)))
        h.play(choice)
        hand = h
        lastTurn = decisions.last
        options = nil
        _ = current
    }

    private func summary(_ hand: TableHand, _ outcome: TableHand.Outcome) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
            let lost = decisions.reduce(0.0) {
                if case let .ev(loss, _) = $1.verdict { return $0 + loss }
                return $0
            }
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(decisions.enumerated()), id: \.offset) { _, d in
                    HStack {
                        Text("\(d.street) · \(d.label)")
                            .font(GT.body(11.5)).foregroundStyle(GT.inkSecondary)
                        Spacer(minLength: 6)
                        Group {
                            switch d.verdict {
                            case let .ev(loss, _):
                                Text(loss <= 0 ? "최선" : "\u{2212}\(bbText(loss))bb")
                            case let .chart(v):
                                Text(v.matched ? "차트대로" : "차트: \(v.chart.rawValue)")
                            }
                        }
                        .font(GT.semibold(11.5).monospacedDigit())
                        .foregroundStyle(d.band.ink)
                    }
                }
                if decisions.count > 1 {
                    Divider()
                    HStack {
                        Text("이 핸드에서 버린 EV").font(GT.semibold(11.5))
                            .foregroundStyle(GT.ink)
                        Spacer(minLength: 6)
                        Text("\(bbText(lost))bb")
                            .font(GT.semibold(11.5).monospacedDigit()).foregroundStyle(GT.ink)
                    }
                }
            }
            .padding(12)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
            PrimaryCTAButton(title: "다음 핸드") { start(vs: villainPick) }
            SecondaryCTAButton(title: "상대 바꾸기") { hand2Picker() }
        }
    }

    private func hand2Picker() {
        hand = nil; options = nil; lastTurn = nil; decisions = []
    }

    private func resultLine(_ o: TableHand.Outcome) -> String {
        if o.heroWon == nil { return "무승부" }
        if !o.wentToShowdown { return o.heroWon! ? "상대 폴드" : "폴드" }
        return o.heroWon! ? "쇼다운 승리" : "쇼다운 패배"
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
        let street = hand.street == 3 ? "플랍" : (hand.street == 4 ? "턴" : "리버")
        decisions.append(TurnRecord(street: street, label: chosen.label,
                                    verdict: .ev(loss: grade.loss, best: grade.best.label)))
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
    var headline: String {
        if case let .bet(f) = choice { return "\(pctText(f * 100))%" }
        return label
    }
    /// The resolved amount, already in the label: "벳 5.6bb (75%)" → "5.6bb".
    var subline: String {
        label.split(separator: " ").dropFirst().first.map(String.init) ?? ""
    }
    /// The verb on its own — "콜 5.6bb" → "콜". The price gets its own line so the
    /// three amounts form a column instead of hiding inside three sentences.
    var actionName: String {
        label.split(separator: " ").first.map(String.init) ?? label
    }
    /// What committing costs. 폴드 and 체크 are stated as 0bb rather than left blank:
    /// it is the number the reveal's EV comparison is read against.
    var priceText: String {
        switch choice {
        case .fold, .check: return "0bb"
        default: return subline.isEmpty ? "0bb" : subline
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
