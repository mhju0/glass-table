// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableEngine
import GlassTableDrills

/// The ungraded lesson before 쇼다운: how a hand is dealt, best five of seven, the
/// hand-ranking ladder with engine-counted shares, and one check question.
/// Content sits above; everything the learner taps sits in the bottom panel.
struct HoldemBasicsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model

    private enum Page: Int { case deal, bestFive, ladder, check }

    let onClose: () -> Void
    /// `true` when the learner chose to go straight on to the first course lesson.
    let onFinish: (_ startNextLesson: Bool) -> Void

    @State private var page: Page = .deal
    /// Streets shown on the deal page: 0 preflop, 1 flop, 2 turn, 3 river.
    @State private var street = 0
    @State private var answer: String?

    private let pageCount = 4

    var body: some View {
        VStack(spacing: 0) {
            header
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: GT.Space.section) {
                        content
                        VStack(alignment: .leading, spacing: GT.Space.related) { panel }
                            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .background(band?.tint ?? GT.glass,
                                        in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                                    .strokeBorder(band?.ink ?? GT.border, lineWidth: band == nil ? 1 : 2)
                            }
                    }
                    .padding(.horizontal, 18).padding(.bottom, 28)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: GT.Space.section) { content }
                        .padding(.horizontal, 18).padding(.vertical, 12)
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
        .onAppear {
            #if DEBUG
            switch ProcessInfo.processInfo.environment["GT_DEMO_BASICS"] {
            case "flop": street = 1
            case "river": street = 3
            case "best": page = .bestFive
            case "ladder": page = .ladder
            case "check": page = .check
            case "check-right": page = .check; answer = HoldemBasics.checkFlush.id
            case "check-wrong": page = .check; answer = HoldemBasics.checkStraight.id
            default: break
            }
            #endif
        }
    }

    private var band: GradeBand? {
        guard page == .check, let answer else { return nil }
        return answer == HoldemBasics.checkFlush.id ? .spotOn : .off
    }

    // MARK: Header

    private var header: some View {
        Group {
            // Beside Close, the title breaks mid-word at accessibility sizes, so Close goes above it.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    closeButton.frame(maxWidth: .infinity, alignment: .trailing)
                    headerTitle
                }
            } else {
                HStack(alignment: .center) {
                    headerTitle.frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 12)
                    closeButton
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
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

    private var closeButton: some View {
        Button(language.text("닫기", "Close"), action: onClose)
            .font(GT.semibold(14)).foregroundStyle(GT.onFeltSecondary)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("basics.close")
    }

    // MARK: Pages

    @ViewBuilder
    private var content: some View {
        switch page {
        case .deal: dealPage
        case .bestFive: bestFivePage
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

    private var dealPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("카드는 이렇게 나와요", "How cards are dealt"),
                  language.text("나만 보는 카드 2장을 받아요. 모두가 함께 쓰는 카드 5장은 세 번에 나눠 펼쳐요.",
                                "You get two private cards. Five shared cards then arrive in three steps."))
            streetSteps
            VStack(alignment: .center, spacing: 16) {
                VStack(spacing: 9) {
                    SectionLabel(text: language.text("공용 카드", "Shared cards"))
                    HStack(spacing: 6) {
                        ForEach(Array(HoldemBasics.board.enumerated()), id: \.offset) { index, card in
                            PlayingCardView(card: card, size: 56, faceDown: index >= shownBoardCount)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                VStack(spacing: 9) {
                    SectionLabel(text: language.text("내 카드", "My cards"))
                    HStack(spacing: 8) {
                        ForEach(Array(HoldemBasics.hole.enumerated()), id: \.offset) { _, card in
                            PlayingCardView(card: card)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
            }
            .frame(maxWidth: .infinity)
            .animation(reduceMotion ? nil : GT.Motion.change, value: street)
            Label(streetCaption, systemImage: "info.circle.fill")
                .font(GT.semibold(15)).foregroundStyle(GT.onFelt)
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .gtPanel()
                .accessibilityIdentifier("basics.streetCaption")
        }
    }

    private var shownBoardCount: Int { [0, 3, 4, 5][street] }

    private var streetNames: [String] {
        [language.text("프리플랍", "Preflop"), language.text("플랍", "Flop"),
         language.text("턴", "Turn"), language.text("리버", "River")]
    }

    private var streetSteps: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { streetChips }
            VStack(alignment: .leading, spacing: 6) { streetChips }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.text("지금 단계: \(streetNames[street])",
                                          "Current step: \(streetNames[street])"))
    }

    @ViewBuilder
    private var streetChips: some View {
        ForEach(Array(streetNames.enumerated()), id: \.offset) { index, name in
            Text(name)
                .font(index == street ? GT.title(14) : GT.semibold(14))
                .foregroundStyle(index == street ? GT.onCTA : GT.onFeltSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(index == street ? AnyShapeStyle(GT.cta) : AnyShapeStyle(Color.clear),
                            in: Capsule())
                .overlay(Capsule().strokeBorder(index == street ? Color.clear : GT.border, lineWidth: 1))
        }
    }

    private var streetCaption: String {
        switch street {
        case 0: language.text("프리플랍 · 내 카드 2장만 보고 첫 베팅을 해요.",
                              "Preflop · See your two cards, then bet.")
        case 1: language.text("플랍 · 공용 카드 3장을 한 번에 펼치고 베팅해요.",
                              "Flop · Three shared cards at once, then bet.")
        case 2: language.text("턴 · 공용 카드 1장을 더 펼치고 베팅해요.",
                              "Turn · One more shared card, then bet.")
        default: language.text("리버 · 마지막 1장 뒤 베팅하고, 남은 사람끼리 패를 비교해요.",
                               "River · The last card and a bet, then hands are compared.")
        }
    }

    private var bestFivePage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("일곱 장 중 가장 좋은 다섯 장", "Best five of seven"),
                  language.text("내 카드 2장과 공용 카드 5장, 모두 7장에서 가장 좋은 5장으로 겨뤄요.",
                                "Your two cards and the five shared cards make seven. Your best five play."))
            VStack(alignment: .center, spacing: 12) {
                sevenCardRow
                Text(DrillTerms.hand(HoldemBasics.bestBrief, in: language))
                    .font(GT.title(20)).foregroundStyle(GT.onFelt)
                    .accessibilityIdentifier("basics.bestHand")
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                Text(language.text("하트 5장이 플러시를 만들어요. 테두리가 없는 두 장은 쓰지 않아요.",
                                   "Five hearts make a flush. The two unmarked cards don't play."))
                Text(language.text("내 카드를 꼭 두 장 다 쓸 필요는 없어요. 공용 카드 5장이 가장 좋으면 그대로 써요.",
                                   "You needn't use both of yours. If the shared five are best, they play."))
            }
            .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.ink)
            .lineSpacing(GT.Typography.explanationLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    /// Seven cards, the five that play outlined; the rest step back but stay readable.
    private var sevenCardRow: some View {
        let best = HoldemBasics.bestFive
        let cards = HoldemBasics.seven
        return VStack(spacing: 9) {
            HStack(spacing: 5) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    let plays = best.contains(card)
                    PlayingCardView(card: card, size: 54)
                        .overlay {
                            if plays {
                                RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: 54))
                                    .strokeBorder(GT.mint, lineWidth: 3)
                            }
                        }
                        .opacity(plays ? 1 : 0.55)
                        .padding(.leading, index == 2 ? 8 : 0)
                        .accessibilityLabel(card.spoken(in: language)
                                            + (plays ? "" : language.text(", 쓰지 않음", ", not used")))
                }
            }
            if dynamicTypeSize.isAccessibilitySize {
                // The fixed-width captions would break words at these sizes.
                Text(language.text("앞의 2장이 내 카드예요.", "The first two are yours."))
                    .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            } else {
            HStack(spacing: 0) {
                Text(language.text("내 카드", "Mine"))
                    .frame(width: 2 * 54 * 0.72 + 5, alignment: .center)
                Spacer(minLength: 8)
                Text(language.text("공용 카드", "Shared"))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
            .frame(width: 7 * 54 * 0.72 + 6 * 5 + 8)
            .accessibilityHidden(true)
            }
        }
    }

    private var ladderPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("족보: 위로 갈수록 강해요", "Hand ranks, top down"),
                  language.text("대체로 드문 조합일수록 강해요. 하이 카드만 예외예요. 7장으로 아무 조합도 못 만들기가 오히려 드물거든요. 무늬에는 우열이 없어요.",
                                "Rarer hands usually rank higher. High card is the exception: with seven cards, making nothing is uncommon. Suits never rank."))
            VStack(spacing: 0) {
                ForEach(Array(HoldemBasics.ladder.enumerated()), id: \.element.id) { index, rank in
                    ladderRow(rank, position: index + 1)
                    if index < HoldemBasics.ladder.count - 1 {
                        Rectangle().fill(GT.border).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .gtCard(radius: GT.Radius.panel)
            Text(language.text("비율은 7장으로 그 조합이 가장 좋은 패가 되는 확률이에요. 가능한 1억 3,378만 가지를 앱의 엔진으로 모두 세었어요.",
                               "Each share is how often seven cards make that hand as their best. The app's engine counted all 133.8 million sets."))
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ladderRow(_ rank: HoldemBasics.Rank, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(position)").font(GT.semibold(13).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary).frame(minWidth: 18, alignment: .leading)
                Text(rank.name(in: language)).font(GT.title(17)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(HoldemBasics.percentText(rank.share))
                    .font(GT.semibold(15).monospacedDigit()).foregroundStyle(GT.ink)
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
                  language.text("플러시와 스트레이트예요. 방금 본 족보를 떠올려 보세요.",
                                "A flush against a straight. Recall the ladder you just saw."))
            VStack(spacing: 12) {
                checkHand(HoldemBasics.checkFlush)
                checkHand(HoldemBasics.checkStraight)
            }
        }
    }

    /// Before the answer both hands look the same. After it, the pick carries its
    /// verdict and the winner is marked, in shape and words as well as colour.
    private func checkHand(_ rank: HoldemBasics.Rank) -> some View {
        let picked = answer == rank.id
        let wins = rank.id == HoldemBasics.checkFlush.id
        let mark: (text: String, band: GradeBand)? = answer == nil ? nil
            : picked ? (language.text(wins ? "내 답, 맞았어요" : "내 답, 틀렸어요",
                                      wins ? "My answer, correct" : "My answer, wrong"), wins ? .spotOn : .off)
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
            if answer != nil {
                Text(language.text("7장 중 \(HoldemBasics.percentText(rank.share))",
                                   "\(HoldemBasics.percentText(rank.share)) of seven-card hands"))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
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
        case .deal:
            PrimaryCTAButton(title: dealButtonTitle) {
                if street < 3 { street += 1 } else { page = .bestFive }
            }
            .accessibilityIdentifier("basics.next")
        case .bestFive:
            PrimaryCTAButton(title: language.text("족보 보기", "See the hand ranks")) { page = .ladder }
                .accessibilityIdentifier("basics.next")
            backButton { page = .deal }
        case .ladder:
            PrimaryCTAButton(title: language.text("확인 문제 풀기", "Try a quick check")) { page = .check }
                .accessibilityIdentifier("basics.next")
            backButton { page = .bestFive }
        case .check:
            if let answer { verdict(correct: answer == HoldemBasics.checkFlush.id) }
            else { checkChoices }
        }
    }

    private var dealButtonTitle: String {
        switch street {
        case 0: language.text("플랍 펼치기", "Deal the flop")
        case 1: language.text("턴 펼치기", "Deal the turn")
        case 2: language.text("리버 펼치기", "Deal the river")
        default: language.text("다음", "Next")
        }
    }

    private func backButton(_ action: @escaping () -> Void) -> some View {
        SecondaryCTAButton(title: language.text("이전", "Back"), action: action)
    }

    private var checkChoices: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text("이기는 쪽을 골라요", "Choose the winner"))
                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
            HStack(spacing: 10) {
                ForEach([HoldemBasics.checkFlush, HoldemBasics.checkStraight]) { rank in
                    GTChoiceButton(title: rank.name(in: language)) {
                        answer = rank.id
                        UINotificationFeedbackGenerator().notificationOccurred(
                            rank.id == HoldemBasics.checkFlush.id ? .success : .error)
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
        let flush = HoldemBasics.percentText(HoldemBasics.checkFlush.share)
        let straight = HoldemBasics.percentText(HoldemBasics.checkStraight.share)
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: band.glyph)
                    .font(.system(size: 26, weight: .semibold)).foregroundStyle(band.ink)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(correct ? language.text("맞았어요", "That's right")
                                 : language.text("플러시가 이겨요", "The flush wins"))
                        .font(GT.title(GT.Typography.resultSize)).foregroundStyle(band.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(language.text("플러시(\(flush))가 스트레이트(\(straight))보다 드물어서 더 강해요.",
                                       "A flush (\(flush)) is rarer than a straight (\(straight)), so it ranks higher."))
                        .font(GT.body(15)).foregroundStyle(GT.ink)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("basics.verdict")
            PrimaryCTAButton(title: startsCourse ? language.text("다음 레슨 시작", "Start the next lesson")
                                                 : language.text("마치기", "Done")) {
                onFinish(startsCourse)
            }
            .accessibilityIdentifier("basics.finish")
        }
    }
}
