// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills
import GlassTableEngine

/// A finished hand retold one decision at a time: what you held, what the others had
/// done, what it cost, what the beginner chart suggests, and how your choice compares.
/// The last page shows showdown cards and the hand category at each wager.
struct FreeTableHandCoachView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let table: PracticeTableState
    let onClose: () -> Void
    @State private var page = 0

    private var steps: [PracticeCoachStep] { PracticeHandCoach.steps(for: table) }

    var body: some View {
        let steps = steps
        let last = page >= steps.count
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(language.text("\(page + 1) / \(steps.count + 1)", "Step \(page + 1) of \(steps.count + 1)"))
                        .font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
                        .accessibilityIdentifier("coach-progress")
                    if last { summary } else { decision(steps[page]) }
                }
                .gtContentEdge()
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(page)
                .transition(.opacity)
            }
            .accessibilityIdentifier("coach-scroll")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GTStepRow(previous: page > 0 ? { move(-1) } : nil, previousID: "coach-back") {
                FeltCTAButton(title: last ? language.text("완료", "Done") : language.text("다음", "Next")) {
                    if last { onClose() } else { move(1) }
                }
                .accessibilityIdentifier(last ? "coach-done" : "coach-next")
            }
            .padding(.horizontal, GT.Space.edge).padding(.top, 10).padding(.bottom, 12)
            .background(GT.felt)
        }
        .background(FeltBackground())
        .gtChrome(leading: { ChromeButton.close(onClose).accessibilityIdentifier("coach-close") })
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hand-coach")
    }

    private func move(_ delta: Int) {
        withAnimation(reduceMotion ? nil : GT.Motion.fade) { page += delta }
    }

    // MARK: One decision

    @ViewBuilder
    private func decision(_ step: PracticeCoachStep) -> some View {
        let board = Array((table.review?.board ?? []).prefix(table.frame(after: step.stepIndex).boardCount))
        Text(FreeTableWords.street(step.street, language: language)).font(GT.title(28))
        section(language.text("선택 당시 카드", "What you had")) {
            cards(table.learnerHole.highCardFirst, size: 54)
            if !board.isEmpty {
                cards(board, size: 40)
                    .accessibilityLabel(language.text("공용 카드 \(board.count)장", "\(board.count) shared cards"))
            }
            Text(strengthLine(step)).font(GT.body(15))
            if step.facts.startingHandTopPercent != nil {
                Text(language.text("시작 패 순위는 이길 확률이 아니에요.", "Starting-hand rank is separate from winning probability."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            }
        }
        if !step.pressure.isEmpty {
            section(language.text("차례 전에", "Before your turn")) {
                ForEach(step.pressure, id: \.seat) { pressure in
                    Text(pressureLine(pressure, street: step.street)).font(GT.body(15))
                }
            }
        }
        if step.facts.toCall > 0 {
            section(language.text("가격", "The price")) {
                Text(priceLine(step)).font(GT.body(15)).monospacedDigit()
            }
        }
        section(language.text("초보자 차트", "The beginner chart says")) {
            Text(FreeTableWords.chartAdvice(step.strength, language: language)).font(GT.body(15))
        }
        section(language.text("선택한 행동", "You chose")) {
            Text(actionLine(step)).font(GT.semibold(17))
            Text(verdictLine(step.verdict)).font(GT.semibold(15))
                .foregroundStyle(step.verdict == .risky ? GT.cta : GT.ink)
                .accessibilityIdentifier("coach-verdict")
        }
    }

    private func strengthLine(_ step: PracticeCoachStep) -> String {
        let top = step.facts.startingHandTopPercent ?? 0
        let made = step.facts.madeHand.map { DrillTerms.hand($0, in: language) } ?? ""
        return switch step.strength {
        case .premium: language.text("시작 패 상위 \(top)%. 아주 좋은 패예요.", "Top \(top)% of starting hands. A very good hand.")
        case .playable: language.text("시작 패 상위 \(top)%. 해 볼 만한 패예요.", "Top \(top)% of starting hands. Worth playing.")
        case .weak: language.text("시작 패 상위 \(top)%. 약한 쪽에 속해요.", "Top \(top)% of starting hands. On the weak side.")
        case .strong: language.text("\(made). 강한 패예요.", "\(made). A strong hand.")
        case .topPair: language.text("\(made). 보드에서 가장 높은 페어예요.", "\(made). The best pair on the board.")
        case .weakPair: language.text("\(made). 페어지만 더 높은 페어에 져요.", "\(made). A pair, but higher pairs beat it.")
        case .draw: language.text("아직 완성되지 않았어요. 카드 한 장이 더 맞으면 강해져요(드로우).", "Not made yet. One more matching card makes it strong (a draw).")
        case .air: language.text("페어도 드로우도 없어요.", "No pair and no draw.")
        }
    }

    /// What a bet from this player usually means, read from the habits it publishes.
    private func pressureLine(_ pressure: PracticeCoachStep.Pressure, street: PracticeStreet) -> String {
        let name = FreeTableWords.seatName(pressure.seat, language: language)
        let style = table.computerSeats.first { $0.seat == pressure.seat }?.style
        switch pressure.label {
        case "fold": return language.text("\(KO.topic(name)) 포기했어요.", "\(name) folded.")
        case "check": return language.text("\(KO.topic(name)) 체크했어요. 강한 패라면 보통 벳했을 거예요.",
                                           "\(name) checked. With a strong hand they would usually bet.")
        case "call": return language.text("\(KO.topic(name)) \(pressure.chips)칩을 콜했어요. 계속할 만한 패라는 뜻이에요.",
                                          "\(name) called \(pressure.chips). They have something worth continuing with.")
        default:
            let amount = language.text("\(KO.topic(name)) \(pressure.chips)칩을 걸었어요.", "\(name) put in \(pressure.chips).")
            guard street != .preflop, let style else {
                return amount + " " + language.text("시작 패가 좋다는 뜻이에요.", "That says their starting hand is good.")
            }
            if style == .casual {
                return amount + " " + language.text("보통 탑 페어 이상이지만, 가끔은 아무것도 없이 걸어요(블러프).",
                                                    "Usually top pair or better, but sometimes nothing at all (a bluff).")
            }
            let holds = MadeHand.allCases.filter { style.postflop.bets.contains($0) }
                .map { DrillTerms.madeHand($0, in: language) }.joined(separator: ", ")
            return amount + " " + language.text("이 스타일이 먼저 거는 패: \(holds).", "This style bets first with: \(holds).")
        }
    }

    private func priceLine(_ step: PracticeCoachStep) -> String {
        guard let need = step.facts.requiredEquityPercent else {
            return language.text("팟 \(step.facts.pot)칩 · 콜 \(step.facts.toCall)칩",
                                 "Pot \(step.facts.pot) · \(step.facts.toCall) to call")
        }
        return language.text("팟 \(step.facts.pot)칩 · 콜 \(step.facts.toCall)칩. ",
                             "Pot \(step.facts.pot) · \(step.facts.toCall) to call. ")
            + PracticePriceCopy.threshold(need, language: language)
    }

    private func actionLine(_ step: PracticeCoachStep) -> String {
        switch step.action {
        case .fold: language.text("포기", "Fold")
        case .check: language.text("체크", "Check")
        case .call: language.text("콜 \(step.chips)칩", "Call \(step.chips)")
        case .raise: step.facts.toCall == 0 && step.street != .preflop
            ? language.text("벳 \(step.chips)칩", "Bet \(step.chips)")
            : language.text("레이즈 · \(step.chips)칩 더 냄", "Raise · \(step.chips) more in")
        }
    }

    private func verdictLine(_ verdict: PracticeCoachStep.Verdict) -> String {
        switch verdict {
        case .good: language.text("초보자 차트와 같은 선택이에요.", "Good: this choice matches the beginner chart.")
        case .fine: language.text("초보자 차트에서 괜찮은 선택으로 봐요.", "Fine: the beginner chart accepts this choice.")
        case .risky: language.text("초보자 차트는 다른 선택을 권해요.", "Risky: the beginner chart recommends another choice.")
        }
    }

    // MARK: Last page

    @ViewBuilder private var summary: some View {
        Text(language.text("결과", "How it ended")).font(GT.title(28))
        if let review = table.review {
            let net = review.endingStacks[0] - review.startingStacks[0]
            section(language.text("칩", "Chips")) {
                Text(net > 0 ? language.text("+\(net)칩", "+\(net) chips")
                     : net < 0 ? language.text("−\(-net)칩", "−\(-net) chips") : language.text("±0칩", "±0 chips"))
                    .font(GT.title(24).monospacedDigit())
                Text(language.text("칩 결과와 초보자 차트의 평가는 달라요. 이 차트는 몇 가지 단순한 규칙이며, 최적의 선택을 계산한 것은 아니에요.",
                                   "Chip results and beginner-chart reviews measure different things. This chart uses a few simple rules and does not calculate optimal play."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            }
            let shown = (1..<table.seatCount).filter { seat in
                review.pots.contains { $0.eligibleSeats.count > 1 && $0.eligibleSeats.contains(seat) }
            }
            let reveals = PracticeHandCoach.reveals(for: table)
            if shown.isEmpty {
                section(language.text("상대 카드", "Their cards")) {
                    Text(language.text("쇼다운까지 가지 않아서 상대 카드는 공개되지 않았어요.",
                                       "The hand ended before a showdown, so their cards stayed hidden."))
                        .font(GT.body(15))
                }
            }
            ForEach(shown, id: \.self) { seat in
                section(FreeTableWords.seatName(seat, language: language)) {
                    cards(review.holeCards[seat], size: 54)
                    if review.board.count == 5,
                       let all = Card.parse((review.holeCards[seat] + review.board).joined()) {
                        Text(DrillTerms.hand(bestHandOfAny(all), in: language)).font(GT.semibold(15))
                    }
                    ForEach(reveals.filter { $0.seat == seat }, id: \.eventIndex) { reveal in
                        Text(revealLine(reveal)).font(GT.body(15))
                            .foregroundStyle(GT.ink)
                            .accessibilityIdentifier(reveal.wasBluff ? "coach-bluff" : "coach-honest-bet")
                    }
                }
            }
        }
    }

    private func revealLine(_ reveal: PracticeCoachReveal) -> String {
        FreeTableCoachWords.revealLine(street: reveal.street, held: reveal.held,
            raised: table.events[reveal.eventIndex].label == "raise", language: language)
    }

    // MARK: Pieces

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            content()
        }
        .foregroundStyle(GT.ink)
        .fixedSize(horizontal: false, vertical: true)
        .gtInset(GT.Space.card, firstText: .semibold(13))
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
    }

    private func cards(_ raw: [String], size: CGFloat) -> some View {
        HStack(spacing: 5) {
            ForEach(raw, id: \.self) { text in
                if let card = Card(text) { PlayingCardView(card: card, size: size) }
            }
        }
    }
}

enum FreeTableCoachWords {
    static func revealLine(street: PracticeStreet, held: MadeHand, raised: Bool,
                           language: LearningLanguage) -> String {
        let streetName = FreeTableWords.street(street, language: language)
        let action = raised ? language.text("레이즈", "raise") : language.text("벳", "bet")
        let category = held == .air
            ? language.text("페어·드로우 없음", "no pair and no draw")
            : DrillTerms.madeHand(held, in: language).lowercased()
        return language.text("\(streetName) \(action) 당시 패: \(category)",
                             "\(streetName) \(action): \(category)")
    }
}
