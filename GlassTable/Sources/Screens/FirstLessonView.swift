// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableEngine
import GlassTableDrills

/// The first-run guide: a welcome, how learning works, then two warm-up hands.
/// Content sits above; everything the learner taps sits in the bottom panel.
struct FirstLessonView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.learningLanguage) private var language
    enum Context { case firstRun, replay }
    private enum Step { case welcome, introduction, example, exampleAnswer, transfer, transferAnswer }

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
                    ScrollView {
                        VStack(alignment: .leading, spacing: GT.Space.section) { content }
                            .padding(.horizontal, 18).padding(.vertical, 12)
                            .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
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
            case "introduction": step = .introduction
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
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var progressText: String? {
        switch step {
        case .welcome, .introduction: return nil
        case .example, .exampleAnswer: return copy(.exampleProgress)
        case .transfer, .transferAnswer: return copy(.transferProgress)
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: welcome
        case .introduction: introduction
        case .example: question(spot: FirstLesson.example, guided: true)
        case .exampleAnswer: answerContent(spot: FirstLesson.example)
        case .transfer: question(spot: FirstLesson.transfer, guided: false)
        case .transferAnswer: answerContent(spot: FirstLesson.transfer)
        }
    }

    @ViewBuilder
    private var panel: some View {
        switch step {
        case .welcome:
            PrimaryCTAButton(title: copy(.startWelcome)) { step = .introduction }
        case .introduction:
            Text(copy(.warmUpNote))
                .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryCTAButton(title: copy(.startWarmUp)) { step = .example }
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

    private var introduction: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 7) {
                Text(copy(.introductionTitle))
                    .font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                Text(copy(.introductionBody))
                    .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 16) {
                lessonRow(symbol: "eye.fill", title: language.text("먼저 이해해요", "See the reasoning"),
                          detail: language.text("카드와 숫자를 보며 풀이 과정을 따라가요.", "Follow a worked hand, card by card."))
                lessonRow(symbol: "hand.tap.fill", title: language.text("직접 골라봐요", "Choose for yourself"),
                          detail: language.text("답을 보기 전에 먼저 골라요.", "Choose, then see the answer."))
                lessonRow(symbol: "arrow.clockwise", title: language.text("나중에 다시 풀어요", "Come back later"),
                          detail: language.text("배운 내용을 다시 풀며 익혀요.", "Try the skill again after some time away."))
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
            Spacer(minLength: 0)
        }
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
            Spacer(minLength: 0)
            board(spot.board)
            if guided {
                Label(copy(.pairRule),
                      systemImage: "lightbulb.fill")
                    .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .gtPanel()
            }
            Spacer(minLength: 0)
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
                .padding(14).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
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

    private func answerContent(spot: ShowdownSpot) -> some View {
        let reveal = gradeShowdown(answer: answer ?? -1, spot: spot, language: language)
        return VStack(alignment: .leading, spacing: GT.Space.section) {
            board(spot.board)
            VStack(spacing: 12) {
                resultHand(title: copy(.heroCards), cards: spot.hero, value: 0, spot: spot)
                resultHand(title: copy(.villainCards), cards: spot.villain, value: 1, spot: spot)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(copy(.explanationTitle)).font(GT.title(18)).foregroundStyle(GT.ink)
                Text(reveal.whyText)
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    /// The pick carries its verdict: green ✓ when right, red ✗ when wrong, and the
    /// winning hand is marked ✓ 정답 after a miss. Shape and words back the colour.
    private func resultHand(title: String, cards: [Card], value: Int, spot: ShowdownSpot) -> some View {
        let picked = answer == value
        let wins = spot.winner == value
        let mark: (text: String, spoken: String, band: GradeBand)? =
            picked ? (copy(.myPick), wins ? copy(.pickCorrect) : copy(.pickWrong), wins ? .spotOn : .off)
                   : (wins ? (copy(.rightAnswer), copy(.rightAnswer), .spotOn) : nil)
        return handLayout(label: resultLabel(title: title, wins: wins), cards: cards)
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
                if let mark {
                    Label(mark.text, systemImage: mark.band.glyph)
                        .font(GT.semibold(12)).foregroundStyle(mark.band.ink)
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(GT.felt, in: Capsule())
                        .overlay(Capsule().strokeBorder(mark.band.ink, lineWidth: 1.5))
                        .offset(x: -12, y: -11)
                }
            }
            .padding(.top, mark == nil ? 0 : 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([title, spoken(cards), wins ? copy(.higherPair) : copy(.lowerPair), mark?.spoken]
                .compactMap { $0 }.joined(separator: ", "))
            .onAppear {
                guard picked, pulse else { return }
                withAnimation(.easeOut(duration: 1.2)) { pulse = false }
            }
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
               : language.text("핵심은 같은 족보끼리 숫자를 비교하는 거예요.", "When both hands have a pair, compare the ranks."))
            : language.text("처음에는 어떤 숫자가 더 높은지만 찾아도 충분해요.", "Start by finding which pair has the higher rank.")
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
            if isTransfer {
                PrimaryCTAButton(title: context == .firstRun ? copy(.beginCourse)
                                                              : copy(.returnToLearning)) {
                    onFinish()
                }
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

    private func lessonRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(GT.green)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(GT.title(16)).foregroundStyle(GT.ink)
                Text(detail).font(GT.body(13.5)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
