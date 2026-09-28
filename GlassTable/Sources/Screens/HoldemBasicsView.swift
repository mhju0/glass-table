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

    private let pageCount = 2

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
        .gtChrome(leading: {
            ChromeButton.close(onClose).accessibilityIdentifier("basics.close")
        })
        .onAppear {
            #if DEBUG
            switch ProcessInfo.processInfo.environment["GT_DEMO_BASICS"] {
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
        headerTitle
            .frame(maxWidth: .infinity, alignment: .leading)
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
            intro(language.text("족보: 위로 갈수록 강해요", "Hand ranks, top down"),
                  language.text("대체로 드문 조합일수록 강해요. 하이 카드만 예외예요. 7장으로 아무 조합도 못 만드는 경우가 오히려 드물거든요. 무늬에는 우열이 없어요.",
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
                  language.text("플러시 대 스트레이트예요. 족보를 떠올려 보세요.",
                                "A flush against a straight. Recall the ladder."))
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
        case .ladder:
            PrimaryCTAButton(title: language.text("확인 문제 풀기", "Try a quick check")) { page = .check }
                .accessibilityIdentifier("basics.next")
        case .check:
            if let answer { verdict(correct: answer == HoldemBasics.checkFlush.id) }
            else { checkChoices }
        }
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
                Text(correct ? language.text("맞았어요", "That's right")
                             : language.text("플러시가 이겨요", "The flush wins"))
                    .font(GT.title(GT.Typography.resultSize)).foregroundStyle(band.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("basics.verdict")
            RevealDetail {
                Text(language.text("플러시(\(flush))가 스트레이트(\(straight))보다 드물어서 족보에서도 한 단계 더 위에 있어요.",
                                   "A flush (\(flush)) is rarer than a straight (\(straight)), so it sits one step higher on the ladder."))
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
