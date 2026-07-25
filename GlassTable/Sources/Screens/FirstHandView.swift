// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// 첫 핸드 — first-run onboarding as one authored hand that asks each drill's own
/// question in the order the hand asks it, replacing the old text guide.
///
/// Two rules hold the screen together:
///  1. **Guess before every explanation.** A failed retrieval attempt is what makes the
///     answer land (the pretesting effect), so no beat explains before it asks.
///  2. **The hand zone never re-lays-out.** Five concepts share one scene, so working
///     memory holds a hand instead of five diagrams.
///
/// The hand is the repo's own `RevealTests` fixture (and `RevealView`'s `#Preview`), so
/// every number is pinned by existing tests rather than authored here: 7 outs of 44
/// unseen, and 2♥/3♥ look like outs but pair the board into a Q full house.
/// Nothing here writes to `ProgressStore` — a 🔥 handed out for free is a lie.
struct FirstHandView: View {
    /// Popping resets Home's `showFirstHand` binding, so the same exit works whether this
    /// was auto-presented on first launch, tapped from Home, or reopened from Settings.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Step: Int, CaseIterable {
        case outs, potOdds, callFold, mdf, blockers, handoff

        var label: String {
            switch self {
            case .outs: return "아웃 카운팅"
            case .potOdds: return "팟 오즈"
            case .callFold: return "콜/폴드"
            case .mdf: return "MDF"
            case .blockers: return "블로커"
            case .handoff: return "정리"
            }
        }
    }

    @State private var step: Step = .outs
    @State private var revealed = false
    @State private var picked: [Step: Int] = [:]
    /// Which draw cards have taken the strike — drives the 9 → 7 edit.
    @State private var struck: Set<Card> = []
    @State private var liveCount = 0
    @State private var tapped: Card?
    @State private var blockersResolved = false

    /// Smaller than the drills' 64: the hand zone has to hold three rows *and* the beat's
    /// diagram without the diagram sliding under the sheet.
    private static let cardSize: CGFloat = 48

    // MARK: - The hand (authored once, every number derived from it)

    private let hand = OutsSpot(
        hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
        board: Card.parse("Qh7h2s3c")!,
        outs: Card.parse("4h5h6h8h9hThJh")!, excluded: Card.parse("2h3h")!)
    private let priced = BetSpot(pot: 10, bet: 5)

    /// 52 − 8 shown = 44. Computed, never typed: 47 is the flop number.
    private var unseen: Int { 52 - Set(hand.hero + hand.villain + hand.board).count }
    /// The 9 cards that complete the flush, lowest first — so the two that lose are adjacent.
    private var draws: [Card] { (hand.outs + hand.excluded).sorted { $0.rank < $1.rank } }
    private var requiredPct: Int { Int(priced.requiredPct.rounded()) }
    /// 25% of 44 lands on exactly 11 cards, which is why call/fold can be a count.
    private var requiredCards: Int {
        Int((priced.requiredPct / 100 * Double(unseen)).rounded())
    }
    /// bb lost per 100 calls at this price. Exact, not an estimate: with one card to come
    /// equity *is* outs ÷ unseen, so this is the product's "EV, not equity" line, earned.
    private var lossPer100: Int {
        let equity = Double(hand.outCount) / Double(unseen)
        let finalPot = Double(priced.pot + 2 * priced.bet)
        return Int((-(equity * finalPot - Double(priced.bet)) * 100).rounded())
    }
    /// The four queens paired up: 6 combos, with the ones this board already kills last.
    private var qqCombos: [(cards: [Card], blocked: Bool)] {
        let queens = (0..<4).map { Card(rank: 12, suit: $0) }
        let shown = Set(hand.board + hand.hero)
        var out: [(cards: [Card], blocked: Bool)] = []
        for i in 0..<4 {
            for j in (i + 1)..<4 {
                let pair = [queens[i], queens[j]]
                out.append((pair, pair.contains { shown.contains($0) }))
            }
        }
        return out.sorted { !$0.blocked && $1.blocked }
    }

    // MARK: - Body

    var body: some View {
        DrillScaffold(title: "첫 핸드",
                      subtitle: "\(step.rawValue + 1) / \(Step.allCases.count) · \(step.label)",
                      streak: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    handZone
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: tapped) { _, new in
                    if new != nil { withAnimation { proxy.scrollTo("explain", anchor: .bottom) } }
                }
            }
        } sheet: {
            // Must be one view: DrillScaffold applies its white background to whatever it
            // is handed, and a bare ViewBuilder tuple gets it applied per member.
            VStack(alignment: .leading, spacing: 12) { sheetContent }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(step == .handoff ? "닫기" : "건너뛰기") { dismiss() }
                    .font(GT.semibold(14)).foregroundStyle(.white)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            #if DEBUG
            // GT_DEMO_FH_STEP=<0…5> jumps to a beat, +GT_DEMO_FH_REVEAL=1 shows its
            // reveal, +GT_DEMO_FH_PICK=<chip index> chooses the answer. Same reason
            // GT_DEMO_TAP exists: synthetic taps never reach Simulator content, so beats
            // past the first are otherwise unscreenshottable.
            let env = ProcessInfo.processInfo.environment
            if let raw = env["GT_DEMO_FH_STEP"].flatMap(Int.init),
               let jumped = Step(rawValue: raw) {
                step = jumped
                if env["GT_DEMO_FH_REVEAL"] != nil {
                    picked[jumped] = env["GT_DEMO_FH_PICK"].flatMap(Int.init) ?? 1
                    revealed = true
                    blockersResolved = jumped == .blockers
                }
            }
            #endif
        }
    }

    /// Villain / board / hero, identical to the real drill (`DecideView`), plus one
    /// per-step addition below it. These three rows never move.
    private var handZone: some View {
        VStack(alignment: .leading, spacing: 6) {
            if step == .handoff {
                // The summary sheet is tall, and by the last beat the hand has done its
                // work — it collapses to one strip instead of being cut in half.
                SectionLabel(text: "이번 핸드")
                HStack(spacing: 12) {
                    CardRow(cards: hand.villain, maxSize: 34)
                    CardRow(cards: hand.board, maxSize: 34)
                    CardRow(cards: hand.hero, maxSize: 34)
                }
            } else {
                threeRows
            }
        }
    }

    private var threeRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "상대 · VILLAIN")
            if step == .blockers {
                // The only place in the app cards go face down — it reframes the four
                // beats that assumed you could see villain's hand.
                FaceDownRow(count: 2, size: Self.cardSize)
                    .transition(.opacity)
            } else {
                CardRow(cards: hand.villain, maxSize: Self.cardSize)
            }
            SectionLabel(text: "보드 · 턴").padding(.top, 10)
            CardRow(cards: hand.board, maxSize: Self.cardSize)
            SectionLabel(text: "내 핸드 · HERO").padding(.top, 10)
            CardRow(cards: hand.hero, maxSize: Self.cardSize)
            stepExtra.padding(.top, 12)
        }
    }

    @ViewBuilder
    private var stepExtra: some View {
        switch step {
        case .outs:
            if revealed { drawTray }
        case .potOdds:
            HStack(spacing: 8) {
                feltChip("팟", "\(priced.pot)bb", mine: false)
                feltChip("상대 벳", "\(priced.bet)bb", mine: false)
            }
        case .callFold:
            // Both earned numbers sit on the felt *during* the decision, so a wrong
            // answer is diagnostic of reasoning, not of a missing input.
            HStack(spacing: 8) {
                feltChip("내 아웃", "\(hand.outCount)장", mine: true)
                feltChip("필요", "\(requiredCards)장", mine: false)
            }
        case .mdf:
            VStack(alignment: .leading, spacing: 8) {
                feltChip("이번엔 내가 벳", "\(priced.bet)bb", mine: true)
                DefenseTiles(defended: revealed ? 2 : nil)
            }
        case .blockers:
            VStack(alignment: .leading, spacing: 7) {
                SectionLabel(text: "상대가 QQ일 조합 · \(qqCombos.count)")
                ComboGrid(combos: qqCombos, resolved: blockersResolved)
            }
        case .handoff:
            EmptyView()
        }
    }

    /// The signature: 9 hearts fan up, the count reads 9, then 2♥/3♥ take the strike and
    /// the count rolls down to 7 — the user's own number edited in front of them.
    private var drawTray: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("\(liveCount)")
                    .font(GT.title(30).monospacedDigit())
                    .contentTransition(.numericText(value: Double(liveCount)))
                    .foregroundStyle(.white)
                Text(struck.isEmpty ? "하트 · 세는 중" : "진짜 아웃")
                    .font(GT.semibold(12)).foregroundStyle(.white.opacity(0.72))
            }
            HStack(spacing: 6) {
                ForEach(Array(draws.enumerated()), id: \.offset) { _, card in
                    let dead = struck.contains(card)
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            tapped = tapped == card ? nil : card
                        }
                    } label: {
                        PlayingCardView(card: card, size: 38, dead: dead)
                            .overlay {
                                if tapped == card {
                                    RoundedRectangle(cornerRadius: 38 * 0.17)
                                        .stroke(GT.cta, lineWidth: 2.5)
                                }
                            }
                    }
                    .buttonStyle(GTPress())
                    .disabled(!dead)
                    .accessibilityHint(dead ? "완성해도 지는 이유 보기" : "")
                }
            }
            // The label always reads the settled lesson, so the timed roll is never the
            // only channel carrying it.
            .accessibilityElement(children: .contain)
            .accessibilityLabel("하트 9장 중 진짜 아웃은 \(hand.outCount)장. "
                                + "2♥·3♥는 상대가 풀하우스가 되어 제외돼요.")
            if let tapped {
                RiverExplainPanel(spot: hand, river: tapped).padding(.top, 4).id("explain")
            }
        }
        .task(id: revealed) {
            guard revealed else { return }
            liveCount = draws.count
            guard !reduceMotion else {
                struck = Set(hand.excluded); liveCount = hand.outCount; return
            }
            // Let them be right first: the count holds at 9 before anything is edited.
            try? await Task.sleep(for: .milliseconds(450))
            for card in hand.excluded.sorted(by: { $0.rank < $1.rank }) {
                withAnimation(.snappy) {
                    struck.insert(card)
                    liveCount -= 1
                }
                try? await Task.sleep(for: .milliseconds(160))
            }
        }
    }

    // MARK: - Sheet

    @ViewBuilder
    private var sheetContent: some View {
        switch (step, revealed) {
        case (.outs, false):
            ask("리버 한 장이면 끝나요.\n몇 장이 오면 이겨요?", "How many river cards win?")
            chips(["5장", "7장", "9장"])
        case (.outs, true):
            let est = [5, 7, 9][picked[.outs] ?? 2]
            grade(gradeOuts(estimate: est, spot: hand).band, "내 답 \(est)장 · 정답 \(hand.outCount)장")
            headline("남은 \(unseen)장 중 \(hand.outCount)장")
            approx("룰 오브 2로 약 \(Int(hand.improvementPct))% · 근사예요")
            // Credit the correct half before editing it — never 틀렸어요.
            why(est == 9
                ? "**하트 9장, 맞게 셌어요.** 그중 2♥·3♥는 보드를 페어로 만들어서 상대가 풀하우스가 돼요. 진짜 아웃은 \(hand.outCount)장이에요."
                : "하트는 9장이에요. 그중 2♥·3♥는 보드를 페어로 만들어서 상대가 풀하우스가 돼요. **진짜 아웃은 \(hand.outCount)장이에요.**")
            approx("지워진 카드를 눌러보면 왜인지 보여요")
            approx("정확 · 근접 · 빗나감으로 채점해요 · 첫 핸드는 기록에 넣지 않아요")
            advance()

        case (.potOdds, false):
            ask("상대가 \(priced.bet)bb를 벳했어요.\n콜하려면 몇 % 이상 이겨야 해요?", "Required equity")
            chips(["20%", "25%", "33%"])
        case (.potOdds, true):
            let est = [20, 25, 33][picked[.potOdds] ?? 1]
            grade(gradePotOdds(estimatePct: est, spot: priced).band,
                  "내 답 \(est)% · 정답 \(requiredPct)%")
            PriceBar(pot: priced.pot, bet: priced.bet)
            approx("내가 낼 \(priced.bet)bb도 팟에 들어가요 · 합계 \(priced.pot + 2 * priced.bet)bb")
            why(est == 33
                ? "**33%는 내가 낼 \(priced.bet)bb를 안 더한 값이에요.** 내 콜도 팟에 들어가서, \(priced.pot + 2 * priced.bet)으로 나눠요."
                : "**네 번에 한 번은 이겨야 본전이에요.** \(requiredPct)%는 \(unseen)장 중 \(requiredCards)장 — 리버 한 장 남았을 때만 이렇게 장수로 바꿀 수 있어요.")
            GlossaryChip(term: DrillKind.potodds.term)
            advance()

        case (.callFold, false):
            ask("콜? 폴드?", "Call or fold?")
            // Equal weight, same rule as the real drill: a primary/secondary pair would
            // recommend an answer in an unbiased decision.
            HStack(spacing: 10) {
                SecondaryCTAButton(title: "폴드") { commit(0) }
                SecondaryCTAButton(title: "콜") { commit(1) }
            }
        case (.callFold, true):
            let folded = (picked[.callFold] ?? 0) == 0
            grade(folded ? .spotOn : .off, "내 답 \(folded ? "폴드" : "콜") · 정답 폴드")
            headline("\(hand.outCount)장 < \(requiredCards)장 → 폴드")
            // Name the gap instead of leaving the reader to measure it.
            shortfall("\(requiredCards - hand.outCount)장 부족")
            why(folded
                ? "**가격은 \(requiredCards)장을 원하는데, 내 아웃은 \(hand.outCount)장이에요.** 이번 한 판이 아니라, 백 번의 평균이 손해예요."
                : "**콜을 골랐어요.** 가격은 \(requiredCards)장을 원하는데, 내 아웃은 \(hand.outCount)장이에요.")
            GlossaryChip(term: DrillKind.callfold.term)
            advance()

        case (.mdf, false):
            // Villain's price first, then the question — MDF is a fact about someone
            // else's incentive, so asking about my own frequency teaches the notation.
            why("**내가 \(priced.bet)bb를 걸어 \(priced.pot)bb를 노려요 — 세 번에 한 번만 통하면 본전이에요.**")
            ask("그럼 상대는 세 번에 몇 번을\n지켜야 할까요?", "Minimum defense frequency")
            chips(["한 번", "두 번", "세 번 모두"])
        case (.mdf, true):
            let saidTimes = ["한 번", "두 번", "세 번 모두"][picked[.mdf] ?? 1]
            grade(saidTimes == "두 번" ? .spotOn : .off, "내 답 \(saidTimes) · 정답 두 번")
            headline("세 번에 두 번 · 약 \(Int(priced.mdfPct.rounded()))%")
            approx("팟 \(priced.pot) ÷ (팟 \(priced.pot) + 벳 \(priced.bet)) = \(pctText(priced.mdfPct))%")
            why("상대가 **세 번에 한 번보다 자주 접으면** 내 블러프는 카드와 상관없이 공짜예요. 그래서 최소 \(Int(priced.mdfPct.rounded()))%는 지켜야 해요 — **MDF는 내 확률이 아니라 상대의 가격이에요.**")
            GlossaryChip(term: DrillKind.mdf.term)
            advance()

        case (.blockers, false):
            why("**지금까지는 상대 카드를 봤어요. 실전에서는 안 보여요.**")
            ask("상대가 QQ일 조합은 몇 개일까요?", "How many QQ combos?")
            chips(["6조합", "3조합", "1조합"])
        case (.blockers, true):
            let est = [6, 3, 1][picked[.blockers] ?? 1]
            let live = qqCombos.filter { !$0.blocked }.count
            grade(est == live ? .spotOn : .off, "내 답 \(est)조합 · 정답 \(live)조합")
            headline("\(qqCombos.count)조합 중 \(live)조합")
            why("포켓 페어는 원래 \(qqCombos.count)조합이에요. 보드에 **Q♥**가 이미 깔려 있어서 \(live)조합만 남아요 — **보드도 블로커예요.** 내 카드가 지우는 조합을 세는 게 블로커 훈련이에요.")
            GlossaryChip(term: DrillKind.blockers.term)
            advance()

        case (.handoff, _):
            headline("한 판으로 다섯 가지를 봤어요")
            tally
            verdict
            approx("스트릭과 정답률은 실제 드릴에서 쌓여요")
            NavigationLink(value: DrillKind.outs) {
                Text("아웃 카운팅 시작하기").font(GT.title(15)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(GT.cta, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(GTPress())
            SecondaryCTAButton(title: "홈으로") { dismiss() }
        }
    }

    private var tally: some View {
        VStack(spacing: 7) {
            row("아웃", "\(hand.outCount)장")
            row("필요 에퀴티", "\(requiredPct)% · \(requiredCards)장")
            row("결정", "폴드")
            row("상대 MDF", "\(Int(priced.mdfPct.rounded()))%")
            row("상대 QQ 조합", "\(qqCombos.filter { !$0.blocked }.count)개")
        }
        .padding(13)
        .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            Spacer()
            Text(v).font(GT.title(13).monospacedDigit()).foregroundStyle(GT.ink)
        }
    }

    /// The honest hand folds, which is emotionally flat — so it closes on EV, where
    /// folding is the win, rather than on a rigged winner.
    private var verdict: some View {
        VStack(spacing: 3) {
            Text("이 콜을 100번 하면 약 \(lossPer100)bb를 잃어요.")
                .font(GT.title(14)).foregroundStyle(Color(hex: 0x12864E))
            Text("폴드가 이긴 거예요.")
                .font(GT.title(14)).foregroundStyle(Color(hex: 0x12864E))
            Text("이기는 법이 아니라, 결정하는 법을 훈련해요")
                .font(GT.body(11.5)).foregroundStyle(GT.inkSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(12).frame(maxWidth: .infinity)
        .background(Color(hex: 0xE7F7EF), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Sheet pieces

    private func ask(_ ko: String, _ en: String) -> some View {
        VStack(spacing: 3) {
            Text(ko).font(GT.title(15)).foregroundStyle(GT.ink)
            Text(en).font(GT.body(11)).foregroundStyle(GT.inkMuted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func chips(_ labels: [String]) -> some View {
        // Same ladder trick CardRow uses: three chips side by side, stacked when Dynamic
        // Type makes them too wide.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 9) { chipButtons(labels) }
            VStack(spacing: 9) { chipButtons(labels) }
        }
    }

    private func chipButtons(_ labels: [String]) -> some View {
        ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
            Button { commit(i) } label: {
                Text(label).font(GT.title(16)).foregroundStyle(GT.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(GTPress())
        }
    }

    private func grade(_ band: GradeBand, _ said: String) -> some View {
        HStack(spacing: 9) {
            GradePill(band: band)
            Text(said).font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
        }
    }

    private func headline(_ s: String) -> some View {
        Text(s).font(GT.title(17)).foregroundStyle(GT.ink)
    }

    private func approx(_ s: String) -> some View {
        Text(s).font(GT.semibold(12)).foregroundStyle(GT.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func why(_ markdown: String) -> some View {
        Text(.init(markdown))
            .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary).lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func shortfall(_ s: String) -> some View {
        Text(s).font(GT.title(13)).foregroundStyle(Color(hex: 0xC77700))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(hex: 0xFEF0DA), in: RoundedRectangle(cornerRadius: 10))
    }

    private func advance() -> some View {
        PrimaryCTAButton(title: "계속") {
            tapped = nil
            struck = []
            blockersResolved = false
            withAnimation(.easeOut(duration: 0.25)) {
                revealed = false
                step = Step(rawValue: step.rawValue + 1) ?? .handoff
            }
        }
    }

    private func feltChip(_ label: String, _ value: String, mine: Bool) -> some View {
        HStack(spacing: 5) {
            Text(label).font(GT.semibold(11)).foregroundStyle(.white.opacity(0.7))
            Text(value).font(GT.title(15).monospacedDigit()).foregroundStyle(.white)
        }
        .padding(.horizontal, 11).padding(.vertical, 7)
        .background(mine ? GT.cta.opacity(0.55) : Color.white.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 11))
    }

    private func commit(_ index: Int) {
        picked[step] = index
        withAnimation(.easeOut(duration: 0.25)) { revealed = true }
        if step == .blockers {
            Task {
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 500))
                withAnimation(.snappy) { blockersResolved = true }
            }
        }
    }
}

// MARK: - Private pieces (promote to DesignSystem only when a second caller exists)

/// Face-down cards, sized to match `PlayingCardView`. Never names the card it hides.
private struct FaceDownRow: View {
    let count: Int
    let size: CGFloat
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: size * 0.17)
                    .fill(LinearGradient(colors: [Color(hex: 0x1F6D4A), Color(hex: 0x0C3F28)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: size * 0.17)
                        .stroke(.white.opacity(0.34), lineWidth: 1.5))
                    .frame(width: size * 0.72, height: size)
                    .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("상대 카드 \(count)장, 뒷면")
    }
}

/// Three tiles: villain must defend two of them. Thirds are exact here because the
/// authored bet is half pot (bluff risks 5 to win 10) — not a general widget.
private struct DefenseTiles: View {
    let defended: Int?
    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 9)
                    .fill(defended.map { i < $0 } == true
                          ? GT.cta.opacity(0.9) : Color.white.opacity(0.16))
                    .frame(width: 52, height: 34)
                    .overlay {
                        if let defended, i < defended {
                            Image(systemName: "shield.fill").font(.system(size: 13))
                                .foregroundStyle(.white)
                        }
                    }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(defended == nil
                            ? "세 번의 기회" : "세 번 중 \(defended!)번은 지켜야 해요")
    }
}

/// Pot / bet / call as one aligned bar with the numbers printed *inside* the segments —
/// the beginner's error is the denominator, so the third term has to be visible.
private struct PriceBar: View {
    let pot: Int
    let bet: Int
    private var total: Int { pot + 2 * bet }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                seg("팟 \(pot)", GT.green, geo.size.width * Double(pot) / Double(total))
                seg("벳 \(bet)", Color(hex: 0x2FA26B), geo.size.width * Double(bet) / Double(total))
                seg("콜 \(bet)", GT.cta, geo.size.width * Double(bet) / Double(total))
            }
        }
        .frame(height: 46)
        .accessibilityElement()
        .accessibilityLabel("팟 \(pot), 상대 벳 \(bet), 내 콜 \(bet). 합계 \(total)")
    }

    private func seg(_ label: String, _ color: Color, _ width: Double) -> some View {
        Text(label).font(GT.semibold(12).monospacedDigit()).foregroundStyle(.white)
            .lineLimit(1).minimumScaleFactor(0.6)
            .frame(width: max(0, width - 2), height: 46)
            .background(color)
    }
}

/// The six ways to hold QQ, with the ones this board already kills struck through.
private struct ComboGrid: View {
    let combos: [(cards: [Card], blocked: Bool)]
    let resolved: Bool

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3),
                  spacing: 7) {
            ForEach(Array(combos.enumerated()), id: \.offset) { _, combo in
                let gone = resolved && combo.blocked
                HStack(spacing: 3) {
                    ForEach(Array(combo.cards.enumerated()), id: \.offset) {
                        PlayingCardView(card: $0.element, size: 32, dead: gone)
                    }
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(gone ? 0.06 : 0.11),
                            in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview { NavigationStack { FirstHandView() } }
