// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills
import GlassTableEngine

struct FreePlayProgressView: View {
    @Environment(\.learningLanguage) private var language
    let hands: Int
    let quest: FreePlayQuest?
    let canAnswer: Bool
    let disabled: Bool
    let onQuest: () -> Void

    var body: some View {
        HStack(spacing: GT.Space.related) {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text("마친 핸드 \(hands)개", hands == 1 ? "1 hand played" : "\(hands) hands played"))
                    .font(GT.semibold(13).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("free-session-count")
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Capsule().fill(index < hands ? GT.cta : GT.progressTrack)
                            .frame(width: 17, height: 4)
                    }
                }
                .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            Button(action: onQuest) {
                Text(questTitle)
                    .font(GT.semibold(13).monospacedDigit())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(GTOutlinedAction())
            .accessibilityIdentifier("free-quest")
            .disabled(disabled)
        }
        .gtTablePartTextCap()
        .padding(.horizontal, GT.Space.edge)
        .padding(.bottom, GT.Space.compact)
    }

    private var questTitle: String {
        if canAnswer { return language.text("퀘스트 답하기", "Answer quest") }
        guard let quest else { return language.text("퀘스트", "Quest") }
        return language.text("퀘스트 \(quest.correct)/2", "Quest \(quest.correct)/2")
    }
}

struct FreePlayQuestSheet: View {
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model
    let question: FreePlayQuestQuestion?
    let onJoin: () -> Void
    let onAnswer: (Int?) -> Void
    let onClose: () -> Void

    private var quest: FreePlayQuest? { model.state.freePlayQuest }
    private var saveBlocked: Bool { model.saveError != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.section) {
                Text(language.text("쇼다운 족보 읽기", "Read the showdown"))
                    .font(GT.title(28)).accessibilityAddTraits(.isHeader)
                if let quest {
                    Text(language.text("맞힌 횟수 \(quest.correct)/2", "Correct answers \(quest.correct)/2"))
                        .font(GT.semibold(16).monospacedDigit())
                        .accessibilityIdentifier("free-quest-progress")
                    if let response = quest.response, let question, let answer = response.category {
                        let right = answer == question.hand.category
                        Text(right ? language.text("맞혔어요.", "You got it.")
                             : language.text("가장 높은 족보를 확인해 보세요.", "Here’s the best hand you could make."))
                            .font(GT.body(16)).accessibilityIdentifier("free-quest-feedback")
                        Text(DrillTerms.hand(question.hand, in: language)).font(GT.title(20))
                        FreePlayCardRow(cards: bestFiveCards(question.board + question.hole))
                    } else if quest.isComplete {
                        Text(language.text("퀘스트를 마쳤어요.", "Quest complete.")).font(GT.body(16))
                    } else if quest.response != nil {
                        Text(language.text("이 핸드는 건너뛰었어요.", "You skipped this hand.")).font(GT.body(16))
                    } else if let question {
                        Text(language.text("내 카드와 공용 카드로 만들 수 있는 가장 높은 족보는 무엇인가요?",
                                           "What is the best hand you can make with your cards and the board?"))
                            .font(GT.body(16))
                        labeledCards(language.text("공용 카드", "Community cards"), question.board)
                        labeledCards(language.text("내 카드", "Your cards"), question.hole)
                        VStack(spacing: GT.Space.compact) {
                            ForEach(question.choices, id: \.self) { choice in
                                SecondaryCTAButton(title: categoryName(choice)) { onAnswer(choice) }
                                    .accessibilityIdentifier("free-quest-choice-\(choice)")
                                    .disabled(saveBlocked)
                            }
                        }
                    } else {
                        Text(language.text("쇼다운까지 간 핸드에서 내 패의 족보를 골라 보세요.",
                                           "After you reach a showdown, name the best hand you made.")).font(GT.body(16))
                    }
                } else {
                    Text(language.text("쇼다운에서 내 패의 족보를 두 번 맞혀 보세요. 핸드의 승패는 상관없어요.",
                                       "Name your best hand at two showdowns. Your answer counts whether you win or lose."))
                        .font(GT.body(16))
                    Text(language.text("평소처럼 플레이하세요. 돌아보기에서 정답을 먼저 본 핸드는 건너뛰어요.",
                                       "Play each hand as usual. If you review a hand first, the quest skips that hand."))
                        .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                }
            }
            .foregroundStyle(GT.ink)
            .padding(GT.Space.edge).padding(.top, GT.Space.related)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("free-quest-content")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: GT.Space.compact) {
                if quest == nil {
                    PrimaryCTAButton(title: language.text("퀘스트 시작", "Join quest"), action: onJoin)
                        .accessibilityIdentifier("free-quest-join").disabled(saveBlocked)
                } else if quest?.isComplete == false, quest?.response == nil, question != nil {
                    SecondaryCTAButton(title: language.text("이 핸드 건너뛰기", "Skip this hand")) { onAnswer(nil) }
                        .accessibilityIdentifier("free-quest-skip").disabled(saveBlocked)
                }
                SecondaryCTAButton(title: language.text("닫기", "Close"), action: onClose)
                    .accessibilityIdentifier("free-progress-close")
            }
            .padding(.horizontal, GT.Space.edge).padding(.vertical, GT.Space.compact)
            .background(GT.felt)
        }
        .background(FeltBackground())
        .modifier(ProgressSaveNotice())
    }

    private func labeledCards(_ label: String, _ cards: [Card]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            FreePlayCardRow(cards: cards)
        }
    }

    private func categoryName(_ category: Int) -> String {
        let korean = ["하이 카드", "원 페어", "투 페어", "트리플", "스트레이트", "플러시",
                      "풀 하우스", "포카드", "스트레이트 플러시"]
        let english = ["High card", "One pair", "Two pair", "Three of a kind", "Straight", "Flush",
                       "Full house", "Four of a kind", "Straight flush"]
        return language.text(korean[category], english[category])
    }
}

struct FreePlayReviewSheet: View {
    @Environment(\.learningLanguage) private var language
    let review: PracticeTableReview
    let onNext: (() -> Void)?
    let onDetail: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.section) {
                Text(language.text("핸드 돌아보기", "Review this hand"))
                    .font(GT.title(28)).accessibilityAddTraits(.isHeader)
                let net = review.endingStacks[0] - review.startingStacks[0]
                let delta = net > 0 ? "+\(net)" : "\(net)"
                Text(language.text("내 칩 \(delta)", "Your chips \(delta)"))
                    .font(GT.title(20).monospacedDigit())
                if let showdown = review.bestFiveShowdownPair,
                   review.holeCards.indices.contains(showdown.winner),
                   let cards = Card.parse((review.holeCards[showdown.winner] + review.board).joined()), cards.count == 7 {
                    let seat = FreeTableWords.seatName(showdown.winner, language: language)
                    let owner = showdown.winner == 0 ? "내" : "\(seat)의"
                    Text(language.text("\(owner) 가장 좋은 다섯 장", "\(seat) · Best five cards"))
                        .font(GT.semibold(16))
                    FreePlayCardRow(cards: bestFiveCards(cards))
                    Text(DrillTerms.hand(bestHand(cards), in: language)).font(GT.body(16))
                } else {
                    Text(language.text("쇼다운에서 비교할 카드가 없어요.",
                                       "There were no showdown cards to compare.")).font(GT.body(16))
                }
                SecondaryCTAButton(title: language.text("선택 하나씩 보기", "Review decisions"), action: onDetail)
                    .accessibilityIdentifier("free-review-decisions")
            }
            .foregroundStyle(GT.ink)
            .padding(GT.Space.edge).padding(.top, GT.Space.related)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("free-review-content")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: GT.Space.compact) {
                if let onNext {
                    PrimaryCTAButton(title: language.text("다음 핸드", "Next hand"), action: onNext)
                        .accessibilityIdentifier("free-review-next-hand")
                }
                SecondaryCTAButton(title: language.text("결과로 돌아가기", "Back to result"), action: onClose)
                    .accessibilityIdentifier("free-progress-close")
            }
            .padding(.horizontal, GT.Space.edge).padding(.vertical, GT.Space.compact)
            .background(GT.felt)
        }
        .background(FeltBackground())
    }
}

private struct FreePlayCardRow: View {
    let cards: [Card]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(cards, id: \.self) { PlayingCardView(card: $0, size: 43) }
        }
    }
}
