// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableEngine
import GlassTableDrills

/// The first-run guide follows one hand in the order it is played: the pot and two ways
/// to win, blinds and the deal, the four actions, a betting round on each street, and
/// best five of seven at the showdown. Two warm-up hands then test that last rule, and a
/// wrap-up says how lessons work before the hand-ranks lesson.
/// Content sits above; everything the learner taps sits in the bottom panel.
struct FirstLessonView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model
    enum Context { case firstRun, replay }
    private enum Step {
        case welcome, pot, blinds, actions, flow, bestFive
        case example, exampleAnswer, transfer, transferAnswer, wrapUp
    }

    let context: Context
    let onFinish: () -> Void
    let onSkip: () -> Void

    @State private var step: Step = .welcome
    @State private var answer: Int?
    @State private var pulse = false

    private func copy(_ key: FirstLessonCopy.Key) -> String {
        FirstLessonCopy.text(key, in: language)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: GT.Space.section) {
                        content
                        VStack(alignment: .leading, spacing: GT.Space.related) { panel }
                            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .background(panelBand?.tint ?? GT.glass,
                                        in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                                    .strokeBorder(panelBand?.ink ?? GT.border, lineWidth: panelBand == nil ? 1 : 2)
                            }
                    }
                    .padding(.horizontal, 18).padding(.bottom, 28)
                }
            } else {
                GeometryReader { geo in
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: GT.Space.section) { content }
                                .padding(.horizontal, 18).padding(.vertical, 12)
                                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        // The result hands are added below the question; bring them into view.
                        .onChange(of: panelBand) { _, band in
                            guard band != nil else { return }
                            withAnimation(reduceMotion ? nil : GT.Motion.change) {
                                proxy.scrollTo(Self.resultEnd, anchor: .bottom)
                            }
                        }
                    }
                }
                ActionSheet(band: panelBand) {
                    VStack(alignment: .leading, spacing: GT.Space.related) { panel }
                }
                .layoutPriority(1)
            }
        }
        .background(FeltBackground())
        .modifier(ProgressSaveNotice())
        .onAppear {
            #if DEBUG
            switch ProcessInfo.processInfo.environment["GT_DEMO_FIRST_LESSON"] {
            case "pot": step = .pot
            case "blinds": step = .blinds
            case "actions": step = .actions
            case "flow": step = .flow
            case "best": step = .bestFive
            case "wrap-up": step = .wrapUp
            case "example": step = .example
            case "example-answer": answer = 0; step = .exampleAnswer
            case "example-wrong": answer = 1; step = .exampleAnswer
            case "transfer": step = .transfer
            case "transfer-answer": answer = 1; step = .transferAnswer
            default: break
            }
            #endif
        }
    }

    // MARK: Header

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    headerTitle
                    HStack {
                        Spacer(minLength: 0)
                        headerAction
                    }
                }
            } else {
                HStack(alignment: .center) {
                    headerTitle
                    Spacer(minLength: 12)
                    headerAction
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(copy(.title))
                .font(GT.title(22)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            if let progressText {
                Text(progressText)
                    .font(GT.body(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(progressSpoken ?? progressText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerAction: some View {
        Button(context == .firstRun ? copy(.skip) : copy(.close),
               action: onSkip)
            .font(GT.semibold(14)).foregroundStyle(GT.onFeltSecondary)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier(context == .firstRun
                                     ? "firstLesson.skip" : "firstLesson.close")
    }

    /// The six rule screens are numbered; the warm-ups keep their own count.
    private var rulePage: Int? {
        switch step {
        case .pot: 1
        case .blinds: 2
        case .actions: 3
        case .flow: 4
        case .bestFive: 5
        case .wrapUp: 6
        default: nil
        }
    }

    private var progressText: String? {
        switch step {
        case .welcome: return nil
        case .example, .exampleAnswer: return copy(.exampleProgress)
        case .transfer, .transferAnswer: return copy(.transferProgress)
        default: return rulePage.map { "\($0)/6" }
        }
    }

    private var progressSpoken: String? {
        rulePage.map { language.text("6단계 중 \($0)단계", "Step \($0) of 6") }
    }

    // MARK: Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: welcome
        case .pot: potPage
        case .blinds: blindsPage
        case .actions: actionsPage
        case .flow: flowPage
        case .bestFive: bestFivePage
        case .wrapUp: wrapUpPage
        case .example: question(spot: FirstLesson.example, guided: true)
        case .exampleAnswer: answerContent(spot: FirstLesson.example, guided: true)
        case .transfer: question(spot: FirstLesson.transfer, guided: false)
        case .transferAnswer: answerContent(spot: FirstLesson.transfer, guided: false)
        }
    }

    @ViewBuilder
    private var panel: some View {
        switch step {
        case .welcome:
            PrimaryCTAButton(title: copy(.startWelcome)) { step = .pot }
        case .pot: nextButton { step = .blinds }
        case .blinds: nextButton { step = .actions }
        case .actions: nextButton { step = .flow }
        case .flow: nextButton { step = .bestFive }
        case .bestFive:
            Text(copy(.warmUpNote))
                .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryCTAButton(title: copy(.startWarmUp)) { step = .example }
        case .wrapUp:
            PrimaryCTAButton(title: finishTitle, action: onFinish)
                .accessibilityIdentifier("firstLesson.finish")
        case .example: handChoices(FirstLesson.example)
        case .transfer: handChoices(FirstLesson.transfer)
        case .exampleAnswer: verdict(spot: FirstLesson.example, isTransfer: false)
        case .transferAnswer: verdict(spot: FirstLesson.transfer, isTransfer: true)
        }
    }

    /// Green after a right answer, red after a wrong one; the neutral glass otherwise.
    private var panelBand: GradeBand? {
        switch step {
        case .exampleAnswer: isCorrect(FirstLesson.example) ? .spotOn : .off
        case .transferAnswer: isCorrect(FirstLesson.transfer) ? .spotOn : .off
        default: nil
        }
    }

    private func isCorrect(_ spot: ShowdownSpot) -> Bool { answer == spot.winner }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer(minLength: 0)
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 44, weight: .semibold)).foregroundStyle(GT.green)
                .accessibilityHidden(true)
            Text(copy(.welcomeTitle))
                .font(GT.title(30)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            Text(copy(.welcomeBody))
                .font(GT.body(17)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { promises }
                VStack(alignment: .leading, spacing: 8) { promises }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var promises: some View {
        ForEach([copy(.noMoney), copy(.noAccount), copy(.offline)], id: \.self) { item in
            Text(item)
                .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .overlay(Capsule().strokeBorder(GT.border, lineWidth: 1))
        }
    }

    // MARK: Rule screens

    private func intro(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(GT.title(28)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(body)
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var potPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("포커는 팟을 가져가는 게임이에요", "Poker is about winning the pot"),
                  language.text("매 판 가운데 모이는 칩을 팟이라고 해요. 팟을 가져가는 방법은 두 가지예요.",
                                "The chips in the middle of each hand are the pot. There are two ways to win it."))
            VStack(alignment: .leading, spacing: 16) {
                numberedRow(1, title: language.text("모두 폴드시키기", "Everyone else folds"),
                            detail: language.text("다른 사람이 모두 카드를 내려놓으면(폴드) 카드를 보여주지 않고 이겨요.",
                                                  "If everyone else gives up their cards (folds), you win without showing yours."))
                numberedRow(2, title: language.text("끝까지 가서 비교하기", "Best hand at the end"),
                            detail: language.text("마지막까지 남은 사람끼리 패를 보여주고, 더 좋은 패가 이겨요.",
                                                  "Players still in at the end show their hands, and the better hand wins."))
            }
            .gtInset(GT.Space.card).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private func numberedRow(_ number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(GT.title(15).monospacedDigit()).foregroundStyle(GT.green)
                .frame(minWidth: 20, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(GT.title(16)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var blindsPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("블라인드를 내고 카드 2장을 받아요", "Blinds go in, then two cards each"),
                  language.text("카드를 받기 전에 두 사람이 1칩, 2칩을 먼저 내요. 그래서 팟은 처음부터 비어 있지 않아요.",
                                "Before the deal, two players put in 1 chip and 2 chips, so the pot is never empty."))
            VStack(spacing: GT.Space.section) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { blindTokens }
                    VStack(spacing: 10) { blindTokens }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(language.text("SB 1칩, BB 2칩, 팟 3칩", "SB 1 chip, BB 2 chips, pot 3 chips"))
                VStack(spacing: 9) {
                    SectionLabel(text: copy(.heroCards))
                    CardRow(cards: HoldemBasics.hole)
                }
                .accessibilityElement(children: .contain)
            }
            .frame(maxWidth: .infinity)
            Text(language.text("내 카드 2장은 나만 봐요. 다른 사람도 각자 2장씩 받아요.",
                               "Only you see your two cards. Everyone else gets two of their own."))
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var blindTokens: some View {
        chipToken("SB", language.text("1칩", "1 chip"))
        chipToken("BB", language.text("2칩", "2 chips"))
        Image(systemName: "arrow.right")
            .font(.system(size: 15, weight: .semibold)).foregroundStyle(GT.onFeltSecondary)
            .rotationEffect(dynamicTypeSize.isAccessibilitySize ? .degrees(90) : .zero)
        chipToken(language.text("팟", "Pot"), language.text("3칩", "3 chips"), filled: true)
    }

    private func chipToken(_ name: String, _ amount: String, filled: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text(name).font(GT.title(16))
            Text(amount).font(GT.body(13).monospacedDigit())
        }
        .foregroundStyle(filled ? GT.onCTA : GT.onFelt)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .frame(minWidth: 72)
        .background(filled ? AnyShapeStyle(GT.cta) : AnyShapeStyle(Color.clear),
                    in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                .strokeBorder(filled ? Color.clear : GT.border, lineWidth: 1)
        }
    }

    private var actionsPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("내 차례엔 넷 중 하나를 골라요", "On your turn, pick one of four"),
                  language.text("베팅은 한 사람씩 돌아가며 해요.", "Players act one at a time, in turn."))
            VStack(spacing: 0) {
                let rows = [
                    (language.text("폴드", "Fold"),
                     language.text("카드를 내려놓고 이번 판을 포기해요.", "Give up your cards and this hand.")),
                    (language.text("체크", "Check"),
                     language.text("아무도 걸지 않았으면, 칩을 내지 않고 넘겨요.", "If no one has bet, pass without adding chips.")),
                    (language.text("콜", "Call"),
                     language.text("앞사람이 건 만큼 똑같이 내요.", "Match the chips someone has bet.")),
                    (language.text("벳 · 레이즈", "Bet · Raise"),
                     language.text("먼저 걸거나, 이미 건 금액을 올려요.", "Put chips in first, or raise a bet already made.")),
                ]
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    actionRow(row.0, row.1)
                    if index < rows.count - 1 { Rectangle().fill(GT.border).frame(height: 1) }
                }
            }
            .padding(.horizontal, GT.Space.card)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    @ViewBuilder
    private func actionRow(_ name: String, _ detail: String) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 3) { actionRowContent(name, detail) }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) { actionRowContent(name, detail) }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func actionRowContent(_ name: String, _ detail: String) -> some View {
        Text(name).font(GT.title(16)).foregroundStyle(GT.ink)
            .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 86, alignment: .leading)
        Text(detail).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            .lineSpacing(GT.Typography.bodyLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The whole hand on one screen: each street's cards, then its betting round.
    private var flowPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("카드가 나올 때마다 베팅해요", "A round of betting after each deal"),
                  language.text("공용 카드 5장은 세 번에 나눠 펼쳐요. 펼칠 때마다 한 바퀴씩 베팅하고, 폴드하지 않은 사람만 다음으로 가요.",
                                "The five shared cards arrive in three steps. Each step gets a round of betting, and only players who haven't folded go on."))
            VStack(spacing: 0) {
                let board = HoldemBasics.board
                let streets: [(String, String, [Card])] = [
                    (language.text("프리플랍", "Preflop"), language.text("내 카드 2장만 보고", "Your two cards only"), HoldemBasics.hole),
                    (language.text("플랍", "Flop"), language.text("공용 카드 3장", "Three shared cards"), Array(board[0..<3])),
                    (language.text("턴", "Turn"), language.text("공용 카드 1장 더", "One more shared card"), [board[3]]),
                    (language.text("리버", "River"), language.text("마지막 공용 카드", "The last shared card"), [board[4]]),
                ]
                ForEach(Array(streets.enumerated()), id: \.offset) { _, street in
                    streetRow(street.0, street.1, cards: street.2)
                    Rectangle().fill(GT.border).frame(height: 1)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text("쇼다운", "Showdown")).font(GT.title(16)).foregroundStyle(GT.ink)
                    Text(language.text("남은 사람끼리 패를 비교해요", "Players still in compare hands"))
                        .font(GT.body(13.5)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, GT.Space.card)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private func streetRow(_ name: String, _ detail: String, cards: [Card]) -> some View {
        let label = VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(name).font(GT.title(16)).foregroundStyle(GT.ink)
                Text(language.text("→ 베팅", "→ betting"))
                    .font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .overlay(Capsule().strokeBorder(GT.border, lineWidth: 1))
            }
            Text(detail).font(GT.body(13.5)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        let row = HStack(spacing: 4) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                PlayingCardView(card: card, size: 40)
            }
        }
        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) { label; row }
            } else {
                HStack(spacing: 10) { label; Spacer(minLength: 6); row }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([name, detail, cards.map { $0.spoken(in: language) }.joined(separator: ", "),
                             language.text("베팅", "betting")].joined(separator: ", "))
    }

    private var bestFivePage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("7장 중 가장 좋은 5장만 세요", "Only your best five of seven count"),
                  language.text("내 카드 2장과 공용 카드 5장, 모두 7장이에요. 이 중 가장 좋은 5장으로만 겨루고, 나머지 2장은 쓰지 않아요.",
                                "Your two cards plus five shared cards make seven. Only the best five compete; the other two don't count."))
            VStack(alignment: .center, spacing: 12) {
                VStack(spacing: 9) {
                    sevenCards(hole: HoldemBasics.hole, board: HoldemBasics.board, size: 54)
                    if dynamicTypeSize.isAccessibilitySize {
                        // The fixed-width captions would break words at these sizes.
                        Text(language.text("앞의 2장이 내 카드예요.", "The first two are yours."))
                            .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityHidden(true)
                    } else {
                        sevenCardCaptions(size: 54)
                    }
                }
                Text(DrillTerms.hand(HoldemBasics.bestBrief, in: language))
                    .font(GT.title(20)).foregroundStyle(GT.onFelt)
                    .accessibilityIdentifier("firstLesson.bestHand")
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                Text(language.text("테두리가 있는 5장만 이 패에 들어가요. 흐린 2장은 이번에 쓰지 않아요.",
                                   "Only the five outlined cards make this hand. The two faded cards don't play."))
                Text(language.text("내 카드는 2장, 1장, 또는 하나도 안 써도 돼요.",
                                   "Your hand may use both of your cards, one, or neither."))
                Text(language.text("두 사람의 가장 좋은 5장이 같으면 팟을 나눠요.",
                                   "If both best fives are equal, the pot is split."))
                    .accessibilityIdentifier("firstLesson.splitPot")
            }
            .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.ink)
            .lineSpacing(GT.Typography.explanationLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .gtInset(GT.Space.card).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private var wrapUpPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("이제 한 판의 흐름을 알아요", "Now you know how a hand runs"),
                  language.text("레슨에서는 풀이를 보고, 도움을 받으며 풀고, 다른 상황을 혼자 해결해요. 잊을 만할 때 다시 풀어요.",
                                "In each lesson you watch the reasoning, try with help, then solve a new hand alone. Later, you come back to review it."))
            VStack(alignment: .leading, spacing: 14) {
                checkRow(language.text("팟 · 블라인드 · 네 가지 행동", "The pot, blinds and four actions"))
                checkRow(language.text("프리플랍 · 플랍 · 턴 · 리버마다 베팅", "A betting round on every street"))
                checkRow(language.text("7장 중 가장 좋은 5장", "Best five of seven"))
            }
            .gtInset(GT.Space.card).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
            if opensBasics {
                Text(language.text("다음은 족보예요. 어떤 5장이 더 강한지 알아봐요.",
                                   "Next: hand ranks, and which five beats which."))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(copy(.responsibleNote))
                .font(GT.body(13)).foregroundStyle(GT.onFeltMuted)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("wrapUp-responsible")
        }
    }

    private func checkRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold)).foregroundStyle(GT.green)
                .accessibilityHidden(true)
            Text(text).font(GT.semibold(15)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The first run goes on to the hand-ranks lesson unless it is already done.
    private var opensBasics: Bool {
        context == .firstRun && model.state.basicsLessonCompleted != true
    }

    private var finishTitle: String {
        if context == .replay { return copy(.returnToLearning) }
        return opensBasics ? language.text("족보 보기", "See the hand ranks") : copy(.beginCourse)
    }

    private func nextButton(_ action: @escaping () -> Void) -> some View {
        PrimaryCTAButton(title: language.text("다음", "Next"), action: action)
            .accessibilityIdentifier("firstLesson.next")
    }

    private func question(spot: ShowdownSpot, guided: Bool) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            VStack(alignment: .leading, spacing: 7) {
                Text(guided ? copy(.exampleQuestion) : copy(.transferQuestion))
                    .font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                Text(guided ? copy(.examplePrompt) : copy(.transferPrompt))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            board(spot.board)
            if guided {
                Label(copy(.pairRule),
                      systemImage: "lightbulb.fill")
                    .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .gtPanel()
            }
        }
    }

    private func board(_ cards: [Card]) -> some View {
        VStack(alignment: .center, spacing: 9) {
            SectionLabel(text: copy(.sharedCards))
            CardRow(cards: cards)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: Choosing

    private func handChoices(_ spot: ShowdownSpot) -> some View {
        VStack(spacing: 10) {
            handButton(title: copy(.heroCards), cards: spot.hero, answer: 0, spot: spot)
            handButton(title: copy(.villainCards), cards: spot.villain, answer: 1, spot: spot)
        }
    }

    private func handButton(title: String, cards: [Card], answer value: Int, spot: ShowdownSpot) -> some View {
        Button {
            answer = value
            let correct = value == spot.winner
            UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
            step = step == .example ? .exampleAnswer : .transferAnswer
            pulse = !reduceMotion
        } label: {
            handLayout(label: handChoiceLabel(title), cards: cards)
                .gtInset(GT.Space.card).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
                .background(GT.surface,
                            in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                    .strokeBorder(GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress())
        .accessibilityLabel("\(title), \(spoken(cards))")
        .accessibilityHint(copy(.selectWinnerHint))
    }

    private func handChoiceLabel(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(GT.title(17)).foregroundStyle(GT.ink)
            Text(copy(.choiceHint))
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
        }
    }

    // MARK: Result

    private static var resultEnd: String { "first-lesson-result-end" }

    /// The question stays where it was; the two hands, now marked, are added below it.
    /// The explanation sits with the verdict in the sheet, as in every lesson.
    private func answerContent(spot: ShowdownSpot, guided: Bool) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            question(spot: spot, guided: guided)
            VStack(spacing: 12) {
                resultHand(title: copy(.heroCards), cards: spot.hero, value: 0, spot: spot)
                resultHand(title: copy(.villainCards), cards: spot.villain, value: 1, spot: spot)
            }
            .id(Self.resultEnd)
        }
    }

    /// The pick carries its verdict: green ✓ when right, red ✗ when wrong, and the
    /// winning hand is marked ✓ 정답 after a miss. Shape and words back the colour.
    private func resultHand(title: String, cards: [Card], value: Int, spot: ShowdownSpot) -> some View {
        // The row shows all seven with the five that play outlined, so the answer
        // reads as the rule it tests.
        let picked = answer == value
        let wins = spot.winner == value
        let mark: (text: String, spoken: String, band: GradeBand)? =
            picked ? (copy(.myPick), wins ? copy(.pickCorrect) : copy(.pickWrong), wins ? .spotOn : .off)
                   : (wins ? (copy(.rightAnswer), copy(.rightAnswer), .spotOn) : nil)
        // At accessibility sizes the badge would cover the title, so it sits above it.
        let inline = dynamicTypeSize.isAccessibilitySize
        return VStack(alignment: .leading, spacing: 10) {
            if inline, let mark { markBadge(mark.text, band: mark.band) }
            resultLabel(title: title, wins: wins)
            sevenCards(hole: cards, board: spot.board, size: 44)
                .frame(maxWidth: .infinity)
        }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(mark?.band.tint ?? GT.glass,
                        in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                    .strokeBorder(mark?.band.ink ?? GT.border, lineWidth: mark == nil ? 1 : 2.5)
            }
            .shadow(color: picked && pulse ? (mark?.band.ink ?? .clear).opacity(0.55) : .clear,
                    radius: picked && pulse ? 12 : 0)
            .overlay(alignment: .topTrailing) {
                if !inline, let mark { markBadge(mark.text, band: mark.band).offset(x: -12, y: -11) }
            }
            .padding(.top, mark == nil || inline ? 0 : 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([title, spoken(cards), wins ? copy(.higherPair) : copy(.lowerPair), mark?.spoken]
                .compactMap { $0 }.joined(separator: ", "))
            .onAppear {
                guard picked, pulse else { return }
                withAnimation(.easeOut(duration: 1.2)) { pulse = false }
            }
    }

    private func markBadge(_ text: String, band: GradeBand) -> some View {
        Label(text, systemImage: band.glyph)
            .font(GT.semibold(12)).foregroundStyle(band.ink)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(GT.felt, in: Capsule())
            .overlay(Capsule().strokeBorder(band.ink, lineWidth: 1.5))
    }

    private func resultLabel(title: String, wins: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(GT.title(16)).foregroundStyle(GT.ink)
            Text(wins ? copy(.higherPair) : copy(.lowerPair))
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
        }
    }

    private func verdict(spot: ShowdownSpot, isTransfer: Bool) -> some View {
        let correct = isCorrect(spot)
        let band: GradeBand = correct ? .spotOn : .off
        let headline = correct ? copy(.correctTitle) : copy(.retryTitle)
        let detail = correct
            ? (isTransfer
               ? language.text("방금 배운 규칙을 다른 카드에도 적용했어요.", "You used the same rule with a new hand.")
               : language.text("핵심은 같은 족보끼리 숫자를 비교하는 거예요.", "Same hand type? Compare the ranks."))
            : language.text("처음에는 어느 쪽 숫자가 더 높은지만 알아봐도 충분해요.", "To begin, it's enough to spot which pair has the higher rank of the two.")
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: band.glyph)
                    .font(.system(size: 26, weight: .semibold)).foregroundStyle(band.ink)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(headline)
                        .font(GT.title(GT.Typography.resultSize)).foregroundStyle(band.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(GT.body(15)).foregroundStyle(GT.ink)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("firstLesson.verdict")
            RevealDetail {
                Text(gradeShowdown(answer: answer ?? -1, spot: spot, language: language).whyText)
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if isTransfer {
                PrimaryCTAButton(title: language.text("다음", "Next")) {
                    answer = nil
                    step = .wrapUp
                }
                .accessibilityIdentifier("firstLesson.next")
            } else {
                PrimaryCTAButton(title: copy(.tryTransfer)) {
                    answer = nil
                    step = .transfer
                }
            }
        }
    }

    // MARK: Shared

    @ViewBuilder
    private func handLayout(label: some View, cards: [Card]) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                label
                CardRow(cards: cards)
            }
        } else {
            HStack(spacing: 14) {
                label
                Spacer(minLength: 6)
                CardRow(cards: cards)
            }
        }
    }

    private func spoken(_ cards: [Card]) -> String {
        cards.map { language == .korean ? $0.spokenKorean : $0.description }.joined(separator: ", ")
    }

    /// Seven cards, the five that play outlined; the rest step back but stay readable.
    /// The two private cards come first, set apart from the shared five.
    private func sevenCards(hole: [Card], board: [Card], size: CGFloat) -> some View {
        let seven = hole + board
        let best = bestFiveCards(seven)
        return HStack(spacing: 5) {
            ForEach(Array(seven.enumerated()), id: \.offset) { index, card in
                sevenCard(card, plays: best.contains(card), index: index, size: size)
            }
        }
    }

    private func sevenCard(_ card: Card, plays: Bool, index: Int, size: CGFloat) -> some View {
        let unused = plays ? "" : language.text(", 쓰지 않음", ", not used")
        return PlayingCardView(card: card, size: size)
            .overlay {
                if plays {
                    RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
                        .strokeBorder(GT.mint, lineWidth: 3)
                }
            }
            .opacity(plays ? 1 : 0.55)
            .padding(.leading, index == 2 ? 8 : 0)
            .accessibilityLabel(card.spoken(in: language) + unused)
    }

    private func sevenCardCaptions(size: CGFloat) -> some View {
        let cardWidth = size * 0.72
        return HStack(spacing: 0) {
            Text(language.text("내 카드", "Mine"))
                .frame(width: 2 * cardWidth + 5, alignment: .center)
            Spacer(minLength: 8)
            Text(language.text("공용 카드", "Shared"))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
        .frame(width: 7 * cardWidth + 6 * 5 + 8)
        .accessibilityHidden(true)
    }
}
