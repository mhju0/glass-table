// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableDrills

/// Semantic keys for the bounded first-lesson localization surface. Korean remains
/// the only reviewed language; these calls let Xcode extract translator-ready keys
/// later without scattering the lesson script through its layout.
enum FirstLessonCopy {
    enum Key {
        case title, skip, close, exampleProgress, transferProgress, introductionProgress
        case exampleQuestion, transferQuestion, examplePrompt, transferPrompt, pairRule
        case sharedCards, heroCards, villainCards, choiceHint, selectWinnerHint
        case correctTitle, retryTitle, explanationTitle, higherPair, lowerPair
        case tryTransfer, seeIntroduction, beginCourse, returnToLearning
        case introductionTitle, introductionBody
    }

    static func text(_ key: Key, in language: LearningLanguage) -> String {
        switch key {
        case .title: language.text(title, "Try your first hand")
        case .skip: language.text(skip, "Skip")
        case .close: language.text(close, "Close")
        case .exampleProgress: language.text(exampleProgress, "Let's solve one together")
        case .transferProgress: language.text(transferProgress, "Now choose on your own")
        case .introductionProgress: language.text(introductionProgress, "You're ready for the lessons")
        case .exampleQuestion: language.text(exampleQuestion, "Which hand wins?")
        case .transferQuestion: language.text(transferQuestion, "Use the same rule with new cards")
        case .examplePrompt: language.text(examplePrompt, "The five cards in the middle are shared. Choose the stronger hand.")
        case .transferPrompt: language.text(transferPrompt, "Only the cards changed. Find the higher pair.")
        case .pairRule: language.text(pairRule, "Two cards of the same rank make one pair.\nAn ace is higher than a king.")
        case .sharedCards: language.text(sharedCards, "Shared cards")
        case .heroCards: language.text(heroCards, "My cards")
        case .villainCards: language.text(villainCards, "Opponent's cards")
        case .choiceHint: language.text(choiceHint, "This hand is stronger")
        case .selectWinnerHint: language.text(selectWinnerHint, "Choose this hand as the winner")
        case .correctTitle: language.text(correctTitle, "You got it")
        case .retryTitle: language.text(retryTitle, "Let's look at the cards again")
        case .explanationTitle: language.text(explanationTitle, "Why?")
        case .higherPair: language.text(higherPair, "Higher pair")
        case .lowerPair: language.text(lowerPair, "Lower pair")
        case .tryTransfer: language.text(tryTransfer, "Try different cards")
        case .seeIntroduction: language.text(seeIntroduction, "See how learning works")
        case .beginCourse: language.text(beginCourse, "Start the first lesson")
        case .returnToLearning: language.text(returnToLearning, "Back to Learn")
        case .introductionTitle: language.text(introductionTitle, "Learn one decision at a time")
        case .introductionBody: language.text(introductionBody, "Watch the reasoning, try with help, then solve a different hand on your own. Later, return to review what you learned.")
        }
    }
    static let title = String(localized: "firstLesson.title",
                              defaultValue: "첫 문제 풀어보기",
                              comment: "Title of the hands-on first lesson")
    static let skip = String(localized: "firstLesson.action.skip",
                             defaultValue: "건너뛰기",
                             comment: "Skip the optional first lesson")
    static let close = String(localized: "firstLesson.action.close",
                              defaultValue: "닫기",
                              comment: "Close a replay of the first lesson")
    static let exampleProgress = String(localized: "firstLesson.progress.example",
                                        defaultValue: "하나만 같이 풀어봐요")
    static let transferProgress = String(localized: "firstLesson.progress.transfer",
                                         defaultValue: "이번에는 혼자 골라봐요")
    static let introductionProgress = String(localized: "firstLesson.progress.introduction",
                                             defaultValue: "이제 공부를 시작할 준비가 됐어요")
    static let exampleQuestion = String(localized: "firstLesson.example.question",
                                        defaultValue: "어느 쪽이 이길까요?")
    static let transferQuestion = String(localized: "firstLesson.transfer.question",
                                         defaultValue: "같은 규칙으로 골라보세요")
    static let examplePrompt = String(localized: "firstLesson.example.prompt",
                                      defaultValue: "가운데 다섯 장은 함께 쓰는 카드예요. 더 강한 패를 골라보세요.")
    static let transferPrompt = String(localized: "firstLesson.transfer.prompt",
                                       defaultValue: "카드만 바뀌었어요. 더 높은 원 페어를 찾아보세요.")
    static let pairRule = String(localized: "firstLesson.example.rule",
                                 defaultValue: "같은 숫자 두 장은 원 페어예요.\nA는 K보다 높아요.")
    static let sharedCards = String(localized: "firstLesson.label.sharedCards",
                                    defaultValue: "공용 카드")
    static let heroCards = String(localized: "firstLesson.label.heroCards",
                                  defaultValue: "내 카드")
    static let villainCards = String(localized: "firstLesson.label.villainCards",
                                     defaultValue: "상대 카드")
    static let choiceHint = String(localized: "firstLesson.choice.hint",
                                   defaultValue: "이 패가 더 높아요")
    static let selectWinnerHint = String(localized: "firstLesson.choice.accessibilityHint",
                                         defaultValue: "이 패를 승자로 선택")
    static let correctTitle = String(localized: "firstLesson.feedback.correctTitle",
                                     defaultValue: "맞았어요")
    static let retryTitle = String(localized: "firstLesson.feedback.retryTitle",
                                   defaultValue: "괜찮아요. 카드부터 다시 볼게요")
    static let explanationTitle = String(localized: "firstLesson.feedback.explanationTitle",
                                         defaultValue: "왜 그럴까요?")
    static let higherPair = String(localized: "firstLesson.feedback.higherPair",
                                   defaultValue: "더 높은 원 페어")
    static let lowerPair = String(localized: "firstLesson.feedback.lowerPair",
                                  defaultValue: "더 낮은 원 페어")
    static let tryTransfer = String(localized: "firstLesson.action.tryTransfer",
                                    defaultValue: "다른 카드로 풀어보기")
    static let seeIntroduction = String(localized: "firstLesson.action.seeIntroduction",
                                        defaultValue: "앱 둘러보기")
    static let beginCourse = String(localized: "firstLesson.action.beginCourse",
                                    defaultValue: "첫 레슨 시작")
    static let returnToLearning = String(localized: "firstLesson.action.returnToLearning",
                                         defaultValue: "학습 화면으로 돌아가기")
    static let introductionTitle = String(localized: "firstLesson.introduction.title",
                                          defaultValue: "이렇게 한 결정씩 배워요")
    static let introductionBody = String(localized: "firstLesson.introduction.body",
                                         defaultValue: "풀이를 보고, 도움을 받으며 풀고, 다른 상황을 혼자 해결해요. 잊을 만할 때는 오늘 화면에서 다시 만나요.")
}
