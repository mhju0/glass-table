// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableDrills

/// Semantic keys for the bounded first-lesson localization surface. Korean remains
/// the only reviewed language; these calls let Xcode extract translator-ready keys
/// later without scattering the lesson script through its layout.
enum FirstLessonCopy {
    enum Key {
        case title, skip, close, exampleProgress, transferProgress
        case welcomeTitle, welcomeBody, noMoney, noAccount, offline, startWelcome
        case exampleQuestion, transferQuestion, examplePrompt, transferPrompt, pairRule
        case sharedCards, heroCards, villainCards, choiceHint, selectWinnerHint
        case correctTitle, retryTitle, higherPair, lowerPair
        case myPick, rightAnswer, pickCorrect, pickWrong
        case tryTransfer, beginCourse, returnToLearning
        case introductionTitle, introductionBody, responsibleNote, warmUpNote, startWarmUp
    }

    static func text(_ key: Key, in language: LearningLanguage) -> String {
        switch key {
        case .title: language.text(title, "Getting started")
        case .skip: language.text(skip, "Skip guide")
        case .close: language.text(close, "Close")
        case .exampleProgress: language.text(exampleProgress, "Warm-up 1/2")
        case .transferProgress: language.text(transferProgress, "Warm-up 2/2")
        case .welcomeTitle: language.text(welcomeTitle, "Welcome to Glass Table")
        case .welcomeBody: language.text(welcomeBody, "Learn Hold'em decisions one at a time, with cards and numbers.")
        case .noMoney: language.text(noMoney, "No real money")
        case .noAccount: language.text(noAccount, "No account")
        case .offline: language.text(offline, "Works offline")
        case .startWelcome: language.text(startWelcome, "Get started")
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
        case .higherPair: language.text(higherPair, "Higher pair")
        case .lowerPair: language.text(lowerPair, "Lower pair")
        case .myPick: language.text(myPick, "My answer")
        case .rightAnswer: language.text(rightAnswer, "Correct")
        case .pickCorrect: language.text(pickCorrect, "My answer, correct")
        case .pickWrong: language.text(pickWrong, "My answer, wrong")
        case .tryTransfer: language.text(tryTransfer, "Try different cards")
        case .beginCourse: language.text(beginCourse, "Start the first lesson")
        case .returnToLearning: language.text(returnToLearning, "Back to Learn")
        case .introductionTitle: language.text(introductionTitle, "How you'll learn")
        case .introductionBody: language.text(introductionBody, "Watch the reasoning, try with help, then solve a different hand on your own. Later, return to review what you learned.")
        case .responsibleNote: language.text(responsibleNote, "Need help with gambling? Settings has helplines.")
        case .warmUpNote: language.text(warmUpNote, "Start with two quick warm-up questions.")
        case .startWarmUp: language.text(startWarmUp, "Start the warm-up")
        }
    }
    static let title = String(localized: "firstLesson.title",
                              defaultValue: "시작 안내",
                              comment: "Title of the first-run guide")
    static let skip = String(localized: "firstLesson.action.skip",
                             defaultValue: "안내 건너뛰기",
                             comment: "Skip the optional first-run guide")
    static let close = String(localized: "firstLesson.action.close",
                              defaultValue: "닫기",
                              comment: "Close a replay of the first lesson")
    static let exampleProgress = String(localized: "firstLesson.progress.example",
                                        defaultValue: "워밍업 1/2")
    static let transferProgress = String(localized: "firstLesson.progress.transfer",
                                         defaultValue: "워밍업 2/2")
    static let welcomeTitle = String(localized: "firstLesson.welcome.title",
                                     defaultValue: "Glass Table에 오신 걸 환영해요")
    static let welcomeBody = String(localized: "firstLesson.welcome.body",
                                    defaultValue: "홀덤의 결정을 한 번에 하나씩, 카드와 숫자로 배워요.")
    static let noMoney = String(localized: "firstLesson.welcome.noMoney",
                                defaultValue: "실제 돈 없음")
    static let noAccount = String(localized: "firstLesson.welcome.noAccount",
                                  defaultValue: "계정 없음")
    static let offline = String(localized: "firstLesson.welcome.offline",
                                defaultValue: "오프라인")
    static let startWelcome = String(localized: "firstLesson.action.startWelcome",
                                     defaultValue: "시작하기")
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
    static let higherPair = String(localized: "firstLesson.feedback.higherPair",
                                   defaultValue: "더 높은 원 페어")
    static let lowerPair = String(localized: "firstLesson.feedback.lowerPair",
                                  defaultValue: "더 낮은 원 페어")
    static let tryTransfer = String(localized: "firstLesson.action.tryTransfer",
                                    defaultValue: "다른 카드로 풀어보기")
    static let myPick = String(localized: "firstLesson.feedback.myPick",
                               defaultValue: "내 답")
    static let rightAnswer = String(localized: "firstLesson.feedback.rightAnswer",
                                    defaultValue: "정답")
    static let pickCorrect = String(localized: "firstLesson.feedback.pickCorrect",
                                    defaultValue: "내 답, 맞았어요")
    static let pickWrong = String(localized: "firstLesson.feedback.pickWrong",
                                  defaultValue: "내 답, 틀렸어요")
    static let beginCourse = String(localized: "firstLesson.action.beginCourse",
                                    defaultValue: "첫 레슨 시작")
    static let returnToLearning = String(localized: "firstLesson.action.returnToLearning",
                                         defaultValue: "학습 화면으로 돌아가기")
    static let introductionTitle = String(localized: "firstLesson.introduction.title",
                                          defaultValue: "이렇게 배워요")
    static let introductionBody = String(localized: "firstLesson.introduction.body",
                                         defaultValue: "풀이를 보고, 도움을 받으며 풀고, 다른 상황을 혼자 해결해요. 잊을 만할 때는 배우기 화면에서 다시 만나요.")
    static let responsibleNote = String(localized: "firstLesson.introduction.responsibleNote",
                                        defaultValue: "도박이 부담된다면 설정에서 상담 번호를 볼 수 있어요.")
    static let warmUpNote = String(localized: "firstLesson.introduction.warmUpNote",
                                   defaultValue: "가볍게 몸풀기 문제 두 개로 시작해요.")
    static let startWarmUp = String(localized: "firstLesson.action.startWarmUp",
                                    defaultValue: "워밍업 시작")
}
