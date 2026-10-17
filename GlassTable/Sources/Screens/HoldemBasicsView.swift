// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableEngine
import GlassTableDrills

/// The ungraded lesson before 쇼다운: the hand-ranking ladder with engine-counted
/// frequencies, a check question, and a same-pair check that introduces the kicker. How a hand is dealt and best five of seven are
/// taught in the first-run guide.
/// Content sits above; everything the learner taps sits in the bottom panel.
struct HoldemBasicsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model

    private enum Page: Int { case ladder, check, kicker }

    let onClose: () -> Void
    /// `true` when the learner chose to go straight on to the first course lesson.
    let onFinish: (_ startNextLesson: Bool) -> Void

    @State private var page: Page = .ladder
    @State private var answer: String?
    /// The same-pair page's pick: 0 my cards, 1 the opponent's, 2 a tie, as `BestFivePair.winner`.
    @State private var kickerAnswer: Int?

    @State private var variationSeed: UInt64 = 0
    @State private var rotationLoaded = false

    private var checkSpot: ShowdownSpot {
        if variationSeed == 0 { return HoldemBasics.firstCheck }
        let rules: [FirstLesson.Rule] = [.flush, .trips, .straight, .pairOverHighCard, .higherPair]
        let variants = FirstLesson.bank(for: rules[Int(variationSeed % UInt64(rules.count))])
        return variants[Int((variationSeed / UInt64(rules.count)) % UInt64(variants.count))]
    }

    private var checkRanks: [HoldemBasics.Rank] {
        let spot = checkSpot
        let hands = [(spot.heroBest, bestFiveCards(spot.hero + spot.board)),
                     (spot.villainBest, bestFiveCards(spot.villain + spot.board))]
        if variationSeed == 0 {
            // The first check keeps the ladder's names and its flush/straight ids.
            return zip([HoldemBasics.checkFlush, HoldemBasics.checkStraight], hands).map { rank, hand in
                HoldemBasics.Rank(id: rank.id, category: rank.category, isRoyal: false,
                    korean: rank.korean, english: rank.english, englishInSentence: rank.englishInSentence,
                    koreanDetail: rank.koreanDetail, englishDetail: rank.englishDetail, example: hand.1)
            }
        }
        return hands.enumerated().map { index, hand in
            HoldemBasics.checkRank(id: "check-\(index)", hand: hand.0, example: hand.1)
        }
    }

    private var winningCheck: HoldemBasics.Rank {
        checkRanks[checkSpot.winner]
    }

    private let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            header
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: GT.Space.section) {
                        content
                        VStack(alignment: .leading, spacing: GT.Space.related) { panel }
                            .gtInset(GT.Space.card, firstText: .title(18)).frame(maxWidth: .infinity, alignment: .leading)
                            .background(band?.tint ?? GT.glass,
                                        in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                                    .strokeBorder(band?.ink ?? GT.border, lineWidth: band == nil ? 1 : 2)
                            }
                    }
                    .padding(.horizontal, GT.Space.edge).padding(.bottom, 28)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: GT.Space.section) { content }
                        .padding(.horizontal, GT.Space.edge).padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
                ActionSheet(band: band) {
                    VStack(alignment: .leading, spacing: GT.Space.related) { panel }
                }
                .layoutPriority(1)
            }
        }
        .background(FeltBackground())
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { value in
            guard value.startLocation.x < 24, value.translation.width > 80,
                  abs(value.translation.height) < 60, page != .ladder else { return }
            page = page == .kicker ? .check : .ladder
        })
        .gtChrome(leading: {
            ChromeButton.close(onClose).accessibilityIdentifier("basics.close")
        })
        .onAppear {
            if !rotationLoaded {
                variationSeed = GuideExampleRotation.next("basics")
                rotationLoaded = true
            }
            #if DEBUG
            // GT_DEMO_BASICS_SEED picks a check; 0 is the first (flush against straight).
            let environment = ProcessInfo.processInfo.environment
            let demoSeed = environment["GT_DEMO_BASICS_SEED"].flatMap(UInt64.init) ?? 0
            switch environment["GT_DEMO_BASICS"] {
            case "check":
                if environment["GT_DEMO_BASICS_SEED"] != nil { variationSeed = demoSeed }
                page = .check
            case "check-right": variationSeed = demoSeed; page = .check; answer = winningCheck.id
            case "check-wrong":
                variationSeed = demoSeed; page = .check
                answer = checkRanks.first { $0.id != winningCheck.id }?.id
            case "kicker": page = .kicker
            case "kicker-right": page = .kicker; kickerAnswer = kickerPair.winner
            case "kicker-wrong": page = .kicker; kickerAnswer = (kickerPair.winner + 1) % 3
            default: break
            }
            #endif
        }
    }

    private var band: GradeBand? {
        switch page {
        case .ladder: return nil
        case .check: return answer.map { $0 == winningCheck.id ? .spotOn : .off }
        case .kicker: return kickerAnswer.map { $0 == kickerPair.winner ? .spotOn : .off }
        }
    }

    private var kickerPair: BestFivePair { BestFivePair(HoldemBasics.kickerCheck) }

    // MARK: Header

    private var header: some View {
        headerTitle.frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(GT.onFelt)
        .padding(.horizontal, GT.Space.edge).padding(.bottom, 10)
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(language.text("홀덤 기초", "Hold'em basics"))
                .font(GT.title(22)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(page.rawValue + 1)/\(pageCount)")
                .font(GT.body(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                .accessibilityLabel(language.text("\(pageCount)쪽 중 \(page.rawValue + 1)쪽",
                                                  "Page \(page.rawValue + 1) of \(pageCount)"))
        }
    }

    // MARK: Pages

    @ViewBuilder
    private var content: some View {
        switch page {
        case .ladder: ladderPage
        case .check: checkPage
        case .kicker: kickerPage
        }
    }

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

    private var ladderPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("족보 순서, 강한 패부터", "Hand ranks, strongest first"),
                  language.text("위에 있을수록 강해요. 무늬에는 우열이 없어요.",
                                "Higher on the list is stronger. Suits never rank."))
            VStack(spacing: 0) {
                ForEach(Array(HoldemBasics.ladder.enumerated()), id: \.element.id) { index, rank in
                    ladderRow(rank, position: index + 1)
                    if index < HoldemBasics.ladder.count - 1 {
                        Rectangle().fill(GT.border).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, GT.Space.card).gtCard(radius: GT.Radius.panel)
            Text(language.text("오른쪽 숫자는 7장으로 그 족보가 가장 좋은 패가 되는 빈도예요. 이길 확률은 아니에요.",
                               "The number on the right is how often that hand is your best out of seven cards. It is not your chance to win."))
                .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("basics.occurrence")
        }
    }

    private func ladderRow(_ rank: HoldemBasics.Rank, position: Int) -> some View {
        let frequency = Text(HoldemBasics.frequencyText(rank.share, in: language))
            .font(GT.semibold(13).monospacedDigit()).foregroundStyle(GT.inkSecondary)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(position)").font(GT.semibold(13).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary).frame(minWidth: 18, alignment: .leading)
                Text(rank.name(in: language)).font(GT.title(17)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if !dynamicTypeSize.isAccessibilitySize {
                    frequency.fixedSize().layoutPriority(1)
                }
            }
            if dynamicTypeSize.isAccessibilitySize {
                frequency.fixedSize(horizontal: false, vertical: true)
            }
            Text(rank.detail(in: language)).font(GT.body(13.5)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 4) {
                ForEach(Array(rank.example.enumerated()), id: \.offset) { _, card in
                    PlayingCardView(card: card, size: 40)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("basics.rank.\(rank.id)")
    }

    private var checkPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("어느 쪽이 이길까요?", "Which hand wins?"),
                  language.text("두 조합의 족보를 먼저 비교하고, 같으면 조합을 만든 숫자를 비교해요.",
                                "Compare hand types first. If they match, compare the ranks."))
            VStack(spacing: 12) {
                ForEach(checkRanks) { rank in checkHand(rank) }
            }
            // Only once the pick is in.
            if answer != nil {
                BestFiveComparison(pair: BestFivePair(checkSpot))
                    .gtInset(GT.Space.card, firstText: .semibold(13))
                    .gtCard(radius: GT.Radius.panel)
            }
        }
    }

    /// Before the answer both hands look the same. After it, the pick carries its
    /// verdict and the winner is marked, in shape and words as well as colour.
    private func checkHand(_ rank: HoldemBasics.Rank) -> some View {
        let picked = answer == rank.id
        let wins = rank.id == winningCheck.id
        let mark: (text: String, band: GradeBand)? = answer == nil ? nil
            : picked ? (language.text(wins ? "선택한 답, 맞았어요" : "선택한 답, 다시 확인해요",
                                      wins ? "Your answer, correct" : "Your answer, incorrect"), wins ? .spotOn : .off)
            : wins ? (language.text("정답", "Correct"), .spotOn) : nil
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(rank.name(in: language)).font(GT.title(18)).foregroundStyle(GT.ink)
                Spacer(minLength: 8)
                if let mark {
                    Label(mark.text, systemImage: mark.band.glyph)
                        .font(GT.semibold(12)).foregroundStyle(mark.band.ink)
                }
            }
            HStack(spacing: 5) {
                ForEach(Array(rank.example.enumerated()), id: \.offset) { _, card in
                    PlayingCardView(card: card, size: 50)
                }
            }

        }
        .gtInset(GT.Space.card, firstText: .title(18)).frame(maxWidth: .infinity, alignment: .leading)
        .background(mark?.band.tint ?? GT.glass,
                    in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                .strokeBorder(mark?.band.ink ?? GT.border, lineWidth: mark == nil ? 1 : 2.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([rank.name(in: language),
                             rank.example.map { $0.spoken(in: language) }.joined(separator: ", "),
                             mark?.text].compactMap { $0 }.joined(separator: ", "))
    }

    /// Both hands share a pair of Js. Before the pick only the cards show; after it the
    /// rows, the engine's line, and the duel that settles it: the equal pairs set aside,
    /// then the kicker against the kicker.
    private var kickerPage: some View {
        let spot = HoldemBasics.kickerCheck
        return VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("같은 페어라면?", "Same pair?"),
                  language.text("둘 다 J 원 페어를 만들었어요. 어느 쪽이 이길까요?",
                                "Both make a pair of Js. Which side wins?"))
            if kickerAnswer == nil {
                VStack(alignment: .leading, spacing: 12) {
                    kickerCards(language.text("내 카드", "My cards"), spot.hero)
                    kickerCards(language.text("상대 카드", "Opponent's cards"), spot.villain)
                    kickerCards(language.text("공용 카드", "Board"), spot.board)
                }
                .gtInset(GT.Space.card, firstText: .semibold(13))
                .frame(maxWidth: .infinity, alignment: .leading)
                .gtCard(radius: GT.Radius.panel)
            } else {
                BestFiveComparison(pair: kickerPair)
                    .gtInset(GT.Space.card, firstText: .semibold(13))
                    .gtCard(radius: GT.Radius.panel)
                kickerDuel
            }
        }
    }

    private func kickerCards(_ title: String, _ cards: [Card]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            HStack(spacing: 5) {
                ForEach(cards, id: \.self) { PlayingCardView(card: $0, size: 50) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(cards.map { $0.spoken(in: language) }.joined(separator: ", "))")
    }

    /// K2: the equal pairs small and dimmed, then the two kickers large, the winning
    /// one outlined like a deciding card in the rows above.
    private var kickerDuel: some View {
        let pair = kickerPair
        let mine = pair.first, theirs = pair.second
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(language.text("키커", "Kicker")).font(GT.title(17)).foregroundStyle(GT.ink)
                Text(language.text("kicker", "키커")).font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            }
            .accessibilityElement(children: .combine)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    duelCards(HoldemBasics.pairCards(mine))
                    Text("=").font(GT.title(17)).foregroundStyle(GT.inkSecondary)
                    duelCards(HoldemBasics.pairCards(theirs))
                }
                .opacity(0.55)
                .accessibilityHidden(true)
                Text(HoldemBasics.samePairLine(mine, in: language))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .center, spacing: 14) {
                duelKicker(mine, wins: pair.winner == 0)
                Text(pair.winner == 0 ? ">" : pair.winner == 1 ? "<" : "=")
                    .font(GT.title(28)).foregroundStyle(GT.ink)
                    .accessibilityHidden(true)
                duelKicker(theirs, wins: pair.winner == 1)
            }
            GlossaryChip(term: "키커").accessibilityIdentifier("basics.kicker-glossary")
        }
        .gtInset(GT.Space.card, firstText: .title(17))
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.Radius.panel)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("basics.kicker-duel")
    }

    private func duelCards(_ cards: [Card]) -> some View {
        HStack(spacing: 3) {
            ForEach(cards, id: \.self) { PlayingCardView(card: $0, size: 30) }
        }
    }

    private static let duelCardSize: CGFloat = 56

    private func duelKicker(_ hand: BestFiveHand, wins: Bool) -> some View {
        VStack(spacing: 4) {
            ForEach(hand.deciding, id: \.self) { card in
                PlayingCardView(card: card, size: Self.duelCardSize)
                    .overlay {
                        if wins {
                            RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: Self.duelCardSize))
                                .strokeBorder(GT.cta, lineWidth: 2.5)
                        }
                    }
            }
            Text(hand.owner.title(in: language))
                .font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Bottom panel

    @ViewBuilder
    private var panel: some View {
        switch page {
        case .ladder:
            PrimaryCTAButton(title: language.text("확인 문제 풀기", "Try a quick check")) { page = .check }
                .accessibilityIdentifier("basics.next")
        case .check:
            // Previous never stands alone; it returns beside the next step once answered.
            if let answer { verdict(correct: answer == winningCheck.id) }
            else { checkChoices }
        case .kicker:
            if let kickerAnswer { kickerVerdict(correct: kickerAnswer == kickerPair.winner) }
            else { kickerChoices }
        }
    }

    private var kickerChoices: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text("이기는 쪽을 골라요", "Choose the winner"))
                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
            layout {
                let choices = [("mine", language.text("내 카드", "My cards")),
                               ("theirs", language.text("상대 카드", "Opponent's cards")),
                               ("tie", language.text("비겨요", "Tie"))]
                ForEach(choices.indices, id: \.self) { index in
                    GTChoiceButton(title: choices[index].1) {
                        kickerAnswer = index
                        AppFeedback.answer(correct: index == kickerPair.winner)
                    }
                    .accessibilityIdentifier("basics.kicker.choice.\(choices[index].0)")
                }
            }
        }
    }

    private var checkChoices: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text("이기는 쪽을 골라요", "Choose the winner"))
                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
            layout {
                ForEach(checkRanks) { rank in
                    GTChoiceButton(title: rank.name(in: language)) {
                        answer = rank.id
                        AppFeedback.answer(correct: rank.id == winningCheck.id)
                    }
                    .accessibilityIdentifier("basics.choice.\(rank.id)")
                }
            }
        }
    }

    private var startsCourse: Bool {
        guard let first = Curriculum.allNodes.first else { return false }
        return model.status(of: first) != .cleared
    }

    private func verdictTitle(correct: Bool, wrong: String) -> some View {
        let band: GradeBand = correct ? .spotOn : .off
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: band.glyph)
                .font(.system(size: 26, weight: .semibold)).foregroundStyle(band.ink)
                .accessibilityHidden(true)
            Text(correct ? language.text("맞았어요", "That's right") : wrong)
                .font(GT.title(GT.Typography.resultSize)).foregroundStyle(band.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("basics.verdict")
    }

    /// The line is the rows' own (`BestFivePair.why`), already shown with them above.
    private func kickerVerdict(correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            verdictTitle(correct: correct, wrong: language.text("이기는 쪽을 확인해요", "Check the winning side"))
            GTStepRow(previous: { page = .check }, previousID: "basics.previous") {
                PrimaryCTAButton(title: startsCourse ? language.text("다음 레슨 시작", "Start the next lesson")
                                                     : language.text("마치기", "Done")) {
                    onFinish(startsCourse)
                }
                .accessibilityIdentifier("basics.finish")
            }
        }
    }

    private func verdict(correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            verdictTitle(correct: correct, wrong: language.text("이기는 패를 확인해요", "Check the winning hand"))
            RevealDetail {
                Text(HoldemBasics.answerText(winner: winningCheck, in: language))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            GTStepRow(previous: { page = .ladder }, previousID: "basics.previous") {
                PrimaryCTAButton(title: language.text("다음", "Next")) { page = .kicker }
                    .accessibilityIdentifier("basics.check-next")
            }
            if !correct {
                // A miss gets a fresh pair of hands, since this one is already explained.
                SecondaryCTAButton(title: language.text("다른 문제로 다시 풀기", "Try another one")) {
                    variationSeed += 1
                    answer = nil
                }
                .accessibilityIdentifier("basics.retry")
            }
        }
    }
}
