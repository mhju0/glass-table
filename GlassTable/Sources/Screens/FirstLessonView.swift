// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct FirstLessonView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    enum Context { case firstRun, replay }
    private enum Step { case example, exampleAnswer, transfer, transferAnswer, introduction }

    let context: Context
    let onFinish: () -> Void
    let onSkip: () -> Void

    @State private var step: Step = .example
    @State private var answer: Int?

    private func copy(_ key: FirstLessonCopy.Key) -> String {
        FirstLessonCopy.text(key, in: language)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    switch step {
                    case .example: question(spot: FirstLesson.example, guided: true)
                    case .exampleAnswer: answerView(spot: FirstLesson.example, isTransfer: false)
                    case .transfer: question(spot: FirstLesson.transfer, guided: false)
                    case .transferAnswer: answerView(spot: FirstLesson.transfer, isTransfer: true)
                    case .introduction: introduction
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .background(FeltBackground())
        .modifier(ProgressSaveNotice())
        .onAppear {
            #if DEBUG
            switch ProcessInfo.processInfo.environment["GT_DEMO_FIRST_LESSON"] {
            case "example-answer": answer = 0; step = .exampleAnswer
            case "transfer": step = .transfer
            case "transfer-answer": answer = 0; step = .transferAnswer
            case "intro": step = .introduction
            default: break
            }
            #endif
        }
    }

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
            Text(progressText)
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
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

    private var progressText: String {
        switch step {
        case .example, .exampleAnswer: return copy(.exampleProgress)
        case .transfer, .transferAnswer: return copy(.transferProgress)
        case .introduction: return copy(.introductionProgress)
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
            board(spot.board)
            if guided {
                Label(copy(.pairRule),
                      systemImage: "lightbulb.fill")
                    .font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .gtPanel()
            }
            handChoices(spot)
        }
        .padding(.top, 10)
    }

    private func board(_ cards: [Card]) -> some View {
        VStack(alignment: .center, spacing: 9) {
            SectionLabel(text: copy(.sharedCards))
            CardRow(cards: cards)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func handChoices(_ spot: ShowdownSpot) -> some View {
        VStack(spacing: 12) {
            handButton(title: copy(.heroCards), cards: spot.hero, answer: 0)
            handButton(title: copy(.villainCards), cards: spot.villain, answer: 1)
        }
    }

    private func handButton(title: String, cards: [Card], answer value: Int) -> some View {
        Button {
            answer = value
            step = step == .example ? .exampleAnswer : .transferAnswer
        } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 10) {
                        handChoiceLabel(title)
                        CardRow(cards: cards)
                    }
                } else {
                    HStack(spacing: 14) {
                        handChoiceLabel(title)
                        Spacer(minLength: 6)
                        CardRow(cards: cards)
                    }
                }
            }
            .padding(14).frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(GT.surface,
                        in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                .strokeBorder(GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress())
        .accessibilityLabel("\(title), \(cards.map { language == .korean ? $0.spokenKorean : $0.description }.joined(separator: ", "))")
        .accessibilityHint(copy(.selectWinnerHint))
    }

    private func answerView(spot: ShowdownSpot, isTransfer: Bool) -> some View {
        let selected = answer ?? -1
        let reveal = gradeShowdown(answer: selected, spot: spot, language: language)
        let correct = selected == spot.winner
        return VStack(alignment: .leading, spacing: GT.Space.section) {
            VStack(alignment: .leading, spacing: 6) {
                Text(correct ? copy(.correctTitle) : copy(.retryTitle))
                    .font(GT.title(27)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                Text(correct
                     ? (isTransfer
                        ? language.text("방금 배운 규칙을 다른 카드에도 적용했어요.", "You used the same rule with a new hand.")
                        : language.text("핵심은 같은 족보끼리 숫자를 비교하는 거예요.", "When both hands have a pair, compare the ranks."))
                     : language.text("처음에는 족보 이름보다 어떤 숫자가 더 높은지만 찾아도 충분해요.", "Start by finding which pair has the higher rank."))
                    .font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            board(spot.board)
            resultHands(spot)
            VStack(alignment: .leading, spacing: 10) {
                Text(copy(.explanationTitle)).font(GT.title(18)).foregroundStyle(GT.ink)
                Text(reveal.whyText)
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
            FeltCTAButton(title: isTransfer ? copy(.seeIntroduction)
                                            : copy(.tryTransfer)) {
                answer = nil
                step = isTransfer ? .introduction : .transfer
            }
        }
        .padding(.top, 10)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
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
                          detail: language.text("카드와 숫자를 보며 풀이 과정을 따라가요.", "Follow the cards and numbers through a worked hand."))
                lessonRow(symbol: "hand.tap.fill", title: language.text("직접 골라봐요", "Choose for yourself"),
                          detail: language.text("답을 보기 전에 내 판단을 먼저 남겨요.", "Make your choice before seeing the answer."))
                lessonRow(symbol: "arrow.clockwise", title: language.text("나중에 다시 풀어요", "Come back later"),
                          detail: language.text("배운 내용을 다시 풀며 익혀요.", "Try the skill again after some time away."))
            }
            .padding(18).gtCard(radius: GT.Radius.panel)
            FeltCTAButton(title: context == .firstRun ? copy(.beginCourse)
                                                       : copy(.returnToLearning)) {
                onFinish()
            }
        }
        .padding(.top, 18)
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

    private func handChoiceLabel(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(GT.title(17)).foregroundStyle(GT.ink)
            Text(copy(.choiceHint))
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
        }
    }

    private func resultHands(_ spot: ShowdownSpot) -> some View {
        VStack(spacing: 12) {
            resultHand(title: copy(.heroCards), cards: spot.hero, wins: spot.winner == 0)
            resultHand(title: copy(.villainCards), cards: spot.villain, wins: spot.winner == 1)
        }
    }

    private func resultHand(title: String, cards: [Card], wins: Bool) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    resultLabel(title: title, wins: wins)
                    CardRow(cards: cards, highlight: wins ? cards : [])
                }
            } else {
                HStack(spacing: 14) {
                    resultLabel(title: title, wins: wins)
                    Spacer(minLength: 6)
                    CardRow(cards: cards, highlight: wins ? cards : [])
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
        .accessibilityElement(children: .combine)
    }

    private func resultLabel(title: String, wins: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(GT.title(16)).foregroundStyle(GT.onFelt)
            Text(wins ? copy(.higherPair) : copy(.lowerPair))
                .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
        }
    }
}
