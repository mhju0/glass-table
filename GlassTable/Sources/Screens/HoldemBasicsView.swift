// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableEngine
import GlassTableDrills

/// The ungraded lesson before 쇼다운: the hand-ranking ladder with engine-counted
/// shares, and one check question. How a hand is dealt and best five of seven are
/// taught in the first-run guide.
/// Content sits above; everything the learner taps sits in the bottom panel.
struct HoldemBasicsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model

    private enum Page: Int { case ladder, check }

    let onClose: () -> Void
    /// `true` when the learner chose to go straight on to the first course lesson.
    let onFinish: (_ startNextLesson: Bool) -> Void

    @State private var page: Page = .ladder
    @State private var answer: String?

    @State private var variationSeed: UInt64 = 0
    @State private var rotationLoaded = false

    private var checkSpot: ShowdownSpot {
        let rules: [FirstLesson.Rule] = [.flush, .trips, .straight, .pairOverHighCard, .higherPair]
        let variants = FirstLesson.bank(for: rules[Int(variationSeed % UInt64(rules.count))])
        return variants[Int((variationSeed / UInt64(rules.count)) % UInt64(variants.count))]
    }

    private var checkRanks: [HoldemBasics.Rank] {
        if variationSeed == 0 { return [HoldemBasics.checkFlush, HoldemBasics.checkStraight] }
        let spot = checkSpot
        let hands = [(spot.heroBest, bestFiveCards(spot.hero + spot.board)),
                     (spot.villainBest, bestFiveCards(spot.villain + spot.board))]
        return hands.enumerated().map { index, hand in
            let template = HoldemBasics.ladder.first { $0.category == hand.0.category && !$0.isRoyal }!
            return HoldemBasics.Rank(id: "check-\(index)", category: template.category, isRoyal: false,
                korean: DrillTerms.hand(hand.0, in: .korean), english: DrillTerms.hand(hand.0, in: .english),
                koreanDetail: template.koreanDetail, englishDetail: template.englishDetail, example: hand.1)
        }
    }

    private var winningCheck: HoldemBasics.Rank {
        variationSeed == 0 ? HoldemBasics.checkFlush : checkRanks[checkSpot.winner]
    }

    private let pageCount = 2

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
                  abs(value.translation.height) < 60, page == .check else { return }
            page = .ladder
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
            switch ProcessInfo.processInfo.environment["GT_DEMO_BASICS"] {
            case "check": page = .check
            case "check-right": variationSeed = 0; page = .check; answer = HoldemBasics.checkFlush.id
            case "check-wrong": variationSeed = 0; page = .check; answer = HoldemBasics.checkStraight.id
            default: break
            }
            #endif
        }
    }

    private var band: GradeBand? {
        guard page == .check, let answer else { return nil }
        return answer == winningCheck.id ? .spotOn : .off
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            if page == .check {
                Button { page = .ladder } label: {
                    Image(systemName: "chevron.left").font(GT.semibold(18))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(language.text("이전 안내", "Previous guide"))
                .accessibilityIdentifier("basics.previous")
            }
            headerTitle.frame(maxWidth: .infinity, alignment: .leading)
        }
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
            intro(language.text("한 쌍은 높은 카드보다 강해요", "A pair beats a high card"),
                  language.text("먼저 두 예를 비교해 봐요. 족보는 패의 순서예요. 무늬에는 우열이 없어요.",
                                "Compare these two examples first. Hand ranks set the order; suits never rank."))
            VStack(spacing: 0) {
                if let pair = HoldemBasics.ladder.first(where: { $0.id == "pair" }) {
                    ladderRow(pair, position: 1)
                }
                if let high = HoldemBasics.ladder.first(where: { $0.id == "highCard" }) {
                    Rectangle().fill(GT.border).frame(height: 1)
                    ladderRow(high, position: 2)
                }
            }
            .padding(.horizontal, GT.Space.card).gtCard(radius: GT.Radius.panel)
            DisclosureGroup(language.text("족보 순서 보기", "See the rank order")) {
                VStack(spacing: 0) {
                    ForEach(Array(HoldemBasics.ladder.enumerated()), id: \.element.id) { index, rank in
                        ladderRow(rank, position: index + 1, reference: true)
                        if index < HoldemBasics.ladder.count - 1 {
                            Rectangle().fill(GT.border).frame(height: 1)
                        }
                    }
                }.padding(.top, 8)
            }
            .font(GT.semibold(16)).tint(GT.ink)
            .gtInset(GT.Space.card, firstText: .semibold(16)).gtCard(radius: GT.Radius.panel)
            .accessibilityIdentifier("basics.rank-order")
            DisclosureGroup(language.text("얼마나 자주 나올까요?", "How often do these hands occur?")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(language.text("7장으로 각 족보가 가장 좋은 패가 되는 비율이에요. 이길 확률은 아니에요. 앱 엔진으로 가능한 1억 3,378만 가지를 모두 세었어요.",
                                       "These shares count each best hand among all seven-card sets, not your chance to win. The engine counted all 133.8 million sets."))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(HoldemBasics.ladder) { rank in
                        Text("\(rank.name(in: language)) · \(HoldemBasics.percentText(rank.share))")
                            .font(GT.body(14).monospacedDigit()).foregroundStyle(GT.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }.padding(.top, 8)
            }
            .font(GT.semibold(16)).tint(GT.ink)
            .gtInset(GT.Space.card, firstText: .semibold(16)).gtCard(radius: GT.Radius.panel)
            .accessibilityIdentifier("basics.occurrence")
        }
    }

    private func ladderRow(_ rank: HoldemBasics.Rank, position: Int, reference: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(position)").font(GT.semibold(13).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary).frame(minWidth: 18, alignment: .leading)
                Text(rank.name(in: language)).font(GT.title(17)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)

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
        .accessibilityIdentifier("basics.\(reference ? "reference" : "rank").\(rank.id)")
    }

    private var checkPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("어느 쪽이 이길까요?", "Which hand wins?"),
                  language.text("두 조합의 족보를 먼저 비교하고, 같으면 조합을 만든 숫자를 비교해요.",
                                "Compare the hand types first. If they match, compare the ranks that form the combination."))
            VStack(spacing: 12) {
                ForEach(checkRanks) { rank in checkHand(rank) }
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

    // MARK: Bottom panel

    @ViewBuilder
    private var panel: some View {
        switch page {
        case .ladder:
            PrimaryCTAButton(title: language.text("확인 문제 풀기", "Try a quick check")) { page = .check }
                .accessibilityIdentifier("basics.next")
        case .check:
            if let answer { verdict(correct: answer == winningCheck.id) }
            else { checkChoices }
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

    private func verdict(correct: Bool) -> some View {
        let band: GradeBand = correct ? .spotOn : .off
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: band.glyph)
                    .font(.system(size: 26, weight: .semibold)).foregroundStyle(band.ink)
                    .accessibilityHidden(true)
                Text(correct ? language.text("맞았어요", "That's right")
                             : language.text("이기는 패를 확인해요", "Check the winning hand"))
                    .font(GT.title(GT.Typography.resultSize)).foregroundStyle(band.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("basics.verdict")
            RevealDetail {
                Text(language.text("\(winningCheck.name(in: language)) 쪽이 이겨요. 먼저 족보를 비교하고, 같은 족보라면 조합을 만든 숫자부터 비교해요. 무늬에는 우열이 없어요.",
                                   "The \(winningCheck.name(in: language)) wins. Compare the hand types first; when they match, compare the combination’s ranks. Suits have no ranking."))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PrimaryCTAButton(title: startsCourse ? language.text("다음 레슨 시작", "Start the next lesson")
                                                 : language.text("마치기", "Done")) {
                onFinish(startsCourse)
            }
            .accessibilityIdentifier("basics.finish")
        }
    }
}
