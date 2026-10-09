// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Short orientation and study habits. These examples never award course credit.
struct LearningGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @State private var page = 0
    @State private var answer: Int?
    @State private var variationSeed: UInt64 = 0
    @State private var rotationLoaded = false

    private var questionChoices: some View {
        VStack(spacing: 12) {
            ForEach(Array(lesson.choices.enumerated()), id: \.offset) { index, choice in
                Button { answer = index } label: {
                    HStack(spacing: 12) {
                        Image(systemName: answer == index ? "checkmark.circle.fill" : "circle")
                        Text(choice).multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(GT.semibold(16)).foregroundStyle(GT.onFelt)
                    .gtInset(GT.Space.card, firstText: .semibold(16)).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                        .strokeBorder(answer == index ? GT.mint : GT.borderStrong, lineWidth: 1))
                }
                .buttonStyle(GTPress())
                .accessibilityAddTraits(answer == index ? .isSelected : [])
                .disabled(answer != nil)
            }
        }
    }
    private var lessons: [StudyNote] { StudyNote.rotatedLessons(seed: variationSeed, language: language) }
    private var lesson: StudyNote { lessons[page] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("\(language.text("시작 안내", "Getting started")) · \(page + 1)/\(lessons.count)")
                    .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                Text(lesson.title).font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .accessibilityAddTraits(.isHeader)
                Text(lesson.body).font(GT.body(17)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(lesson.example).font(GT.semibold(19)).foregroundStyle(GT.onFelt)
                    .gtInset(GT.Space.card, firstText: .semibold(19)).frame(maxWidth: .infinity, alignment: .leading)
                    .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
                if let question = lesson.question {
                    Text(question).font(GT.semibold(17)).foregroundStyle(GT.onFelt)
                    if let answer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(answer == lesson.correct
                                 ? language.text("맞아요", "That's right")
                                 : language.text("이렇게 생각해 봐요", "Think about it this way"))
                                .font(GT.semibold(18)).foregroundStyle(GT.onFelt)
                            Text(lesson.explanation).font(GT.body(16)).foregroundStyle(GT.onFeltSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if dynamicTypeSize.isAccessibilitySize, lesson.question != nil, answer == nil { questionChoices }
            }
            .gtContentEdge()
            .id(page)
        }
        .simultaneousGesture(DragGesture().onEnded { gesture in
            if gesture.startLocation.x < 24, gesture.translation.width > 70, page > 0 {
                page -= 1; answer = nil
            }
        })
        .background(FeltBackground())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if !dynamicTypeSize.isAccessibilitySize, lesson.question != nil, answer == nil { questionChoices }
                FeltCTAButton(title: page == lessons.count - 1
                              ? language.text("연습하러 가기", "Go to practice")
                              : language.text("다음 이야기", "Next topic")) {
                    if page == lessons.count - 1 { dismiss() }
                    else { page += 1; answer = nil }
                }
                .disabled(lesson.question != nil && answer == nil)
                if page > 0 {
                    SecondaryCTAButton(title: language.text("이전 이야기", "Previous topic")) {
                        page -= 1; answer = nil
                    }
                }
            }
            .padding(.horizontal, GT.Space.sheet).padding(.vertical, 12).background(GT.felt)
        }
        .gtChrome(leading: { ChromeButton.close { dismiss() } })
        .gtSheetSurface()
        .onAppear {
            if !rotationLoaded {
                variationSeed = GuideExampleRotation.next("learningGuide")
                rotationLoaded = true
            }
            #if DEBUG
            if let requested = ProcessInfo.processInfo.environment["GT_DEMO_GUIDE_PAGE"].flatMap(Int.init) {
                page = min(max(requested, 0), lessons.count - 1)
            }
            #endif
        }
    }
}

private struct StudyNote {
    let title: String
    let body: String
    let example: String
    var question: String? = nil
    var choices: [String] = []
    var correct: Int = 0
    var explanation: String = ""

    static func rotatedLessons(seed: UInt64, language: LearningLanguage) -> [StudyNote] {
        var notes = language == .korean ? lessons : englishLessons
        if seed % 3 == 1 {
            notes[1] = StudyNote(title: notes[1].title, body: notes[1].body,
                example: language.text("내 카드 A·K, 공용 카드 Q·J·10·4·2라면 내 카드 두 장으로 스트레이트를 만들어요.",
                                       "With A and K in your hand and Q, J, 10, 4, 2 shared, both of your cards complete a straight."),
                question: language.text("내 카드를 한 장만 쓰는 조합도 가능할까요?", "Can your best hand use just one of your cards?"),
                choices: [language.text("네, 가장 좋은 다섯 장만 골라요", "Yes, choose the best five"),
                          language.text("아니요, 두 장을 항상 써야 해요", "No, always use both")],
                explanation: language.text("내 카드를 두 장, 한 장 또는 하나도 쓰지 않을 수 있어요. 중요한 것은 일곱 장 중 가장 좋은 다섯 장이에요.",
                                           "You may use two, one or none of your cards. What matters is the best five of all seven."))
        } else if seed % 3 == 2 {
            notes[1] = StudyNote(title: notes[1].title, body: notes[1].body,
                example: language.text("공용 카드가 A·K·Q·J·10이고 두 사람 모두 이보다 강한 조합이 없다면, 같은 스트레이트를 써요.",
                                       "If the shared cards are A, K, Q, J, 10 and neither player has a stronger combination, both play the same straight."),
                question: language.text("내 카드 한 장의 숫자가 더 높으면 혼자 이길까요?", "Does a higher unused private card win the whole pot?"),
                choices: [language.text("아니요, 최선의 다섯 장이 같으면 나눠요", "No, equal best fives split the pot"),
                          language.text("네, 쓰지 않은 카드도 비교해요", "Yes, compare unused cards too")],
                explanation: language.text("최선의 다섯 장만 비교해요. 쓰지 않은 카드는 무승부를 깨지 않아요.",
                                           "Only the best five count. Unused cards do not break a tie."))
        }
        let prices = [(12, 4, 20, "20%", "25%"), (18, 6, 30, "20%", "33%"), (10, 5, 20, "25%", "50%")]
        let (pot, bet, total, correct, other) = prices[Int(seed % UInt64(prices.count))]
        notes[4] = StudyNote(title: notes[4].title, body: notes[4].body,
            example: language.text("팟 \(pot)bb + 상대 벳 \(bet)bb + 내 콜 \(bet)bb\n\n콜한 뒤 팟은 \(total)bb예요. bb는 빅 블라인드를 1로 보는 단위예요.",
                                   "Pot \(pot)bb + bet \(bet)bb + call \(bet)bb\n\nThe final pot is \(total)bb. One bb is the size of the big blind."),
            question: notes[4].question, choices: [other, correct], correct: 1,
            explanation: language.text("낼 돈 \(bet) ÷ 콜한 뒤 팟 \(total) = \(correct)예요. 이후 베팅이 있으면 판단이 달라질 수 있어요.",
                                       "Pay \(bet) to contest \(total): \(bet) ÷ \(total) = \(correct). Later betting can change the decision."))
        if seed % 2 == 1 {
            notes[5] = StudyNote(title: notes[5].title, body: notes[5].body,
                example: language.text("가격에 비해 낮은 확률로 콜했지만 이번에는 마지막 카드에서 이겼어요.",
                                       "You called at poor odds for the price, but the last card won this hand."),
                question: language.text("이번에 이겼다는 이유만으로 좋은 콜이었다고 할 수 있을까요?", "Does winning this time prove it was a good call?"),
                choices: [language.text("네, 이겼으니 좋은 결정이에요", "Yes, a win means a good decision"),
                          language.text("아니요, 결정할 때의 확률과 가격을 봐요", "No, judge the odds and price then")], correct: 1,
                explanation: language.text("결과에는 운도 들어가요. 결정을 내릴 때의 정보와 가격으로 평가해요.",
                                           "Results include luck. Judge the information and price when the decision was made."))
            notes = notes.map { note in
                guard note.question != nil else { return note }
                return StudyNote(title: note.title, body: note.body, example: note.example,
                    question: note.question, choices: Array(note.choices.reversed()),
                    correct: note.choices.count - 1 - note.correct, explanation: note.explanation)
            }
        }
        return notes
    }

    static let lessons: [StudyNote] = [
        StudyNote(title: "한 번에 한 가지씩 배워요",
                  body: "홀덤이 처음이어도 괜찮아요. 먼저 풀이를 보고, 다른 문제를 내 속도로 풀어요. 도움은 언제든 볼 수 있어요. 익숙해지면 여러 개념을 섞어서 연습해요.",
                  example: "풀이 보기 → 다른 카드로 연습 → 다시 떠올리기\n\n나중에 다시 떠올려 보는 복습도 있어요."),
        StudyNote(title: "가장 좋은 다섯 장을 찾아요",
                  body: "홀덤은 내 카드 2장과 모두가 함께 쓰는 보드 5장 중 가장 좋은 5장으로 승부해요. 내 카드를 반드시 두 장 다 쓸 필요는 없어요. 끝까지 남은 사람들이 패를 비교하는 순간이 쇼다운이에요.",
                  example: "블라인드 → 프리플랍 베팅 → 플랍 3장 → 턴 1장 → 리버 1장\n\n폴드는 포기, 체크는 칩을 더 내지 않고 넘기기, 콜은 상대 금액에 맞추기, 레이즈는 금액을 더 올리기예요.",
                  question: "보드 다섯 장이 내 최선의 조합일 수도 있을까요?",
                  choices: ["네, 보드만 쓸 수도 있어요", "아니요, 내 카드 두 장을 꼭 써야 해요"],
                  explanation: "일곱 장 중 최선의 다섯 장을 골라요. 두 사람의 최선의 다섯 장이 같으면 팟을 나누는 무승부예요."),
        StudyNote(title: "족보는 위에서부터 강해요",
                  body: "먼저 조합을 비교하고, 같으면 조합을 만든 카드의 숫자를 비교해요. 그래도 같으면 남은 가장 높은 카드인 키커를 비교해요. 무늬에는 우열이 없어요.",
                  example: "스트레이트 플러시 · 한 무늬 연속 5장\n포카드 · 같은 숫자 4장\n풀하우스 · 트리플과 페어\n플러시 · 같은 무늬 5장\n스트레이트 · 연속된 숫자 5장\n트리플 · 같은 숫자 3장\n투페어 · 페어 두 쌍\n원페어 · 같은 숫자 2장\n하이 카드 · 위 조합이 없는 패\n\nA·K·Q·J·10의 같은 무늬는 가장 높은 스트레이트 플러시예요."),
        StudyNote(title: "늦게 행동할수록 유리해요",
                  body: "포지션은 행동하는 순서예요. 프리플랍에는 빅 블라인드 왼쪽부터, 플랍 이후에는 버튼 왼쪽의 남은 사람부터 행동해요. 헤즈업에서는 버튼이 스몰 블라인드라서, 프리플랍에는 먼저 행동하고 이후에는 나중에 행동해요.",
                  example: "같은 카드라도 내 뒤에 남은 사람이 많으면 더 조심해야 해요. 연습 차트가 자리마다 다른 이유예요."),
        StudyNote(title: "승률과 가격을 비교해요",
                  body: "콜을 결정할 때는 앞으로 낼 돈을 콜한 뒤의 전체 팟과 비교해요. 이미 팟에 들어간 돈과 지금 추가로 낼 돈을 구분해 보세요.",
                  example: "팟 12bb + 상대 벳 4bb + 내 콜 4bb\n\n콜한 뒤 팟은 20bb예요. bb는 빅 블라인드를 1로 보는 단위예요.",
                  question: "추가 베팅과 수수료가 없다고 할 때, 이 콜에 필요한 에퀴티는 얼마일까요?",
                  choices: ["25%", "20%"], correct: 1,
                  explanation: "낼 돈 4 ÷ 콜한 뒤 팟 20 = 20%예요. 실제 여러 스트리트의 결정에는 이후 베팅도 영향을 줘요."),
        StudyNote(title: "좋은 결정도 질 수 있어요",
                  body: "기댓값(EV)은 같은 결정을 같은 조건에서 반복한 평균이에요. 한 번의 승패와는 달라요. 테이블은 실제 결과와 결정의 EV 손실을 따로 보여 줘요.",
                  example: "유리한 확률로 콜했지만 이번에는 마지막 카드에서 졌어요.",
                  question: "이 결과만으로 콜이 잘못됐다고 할 수 있을까요?",
                  choices: ["네, 졌으니 잘못된 콜이에요", "아니요, 결정할 때의 확률과 가격을 봐요"], correct: 1,
                  explanation: "결정할 때 알 수 있었던 정보로 평가해요. 결과만 보고 판단을 바꾸면 운과 실력을 혼동하기 쉬워요."),
        StudyNote(title: "정답의 조건도 배워요",
                  body: "이 앱의 상대는 전략이 공개된 연습용 모델이에요. 프리플랍은 앱의 차트로, 포스트플랍 EV는 현재 벳 뒤 추가 베팅이 없다는 가정으로 평가해요. 실제 상대의 전략이나 GTO 해답은 아니에요.",
                  example: "확인할 것\n어떤 레인지인가요?\n어떤 행동과 크기를 허용하나요?\n이후 베팅을 어떻게 가정하나요?",
                  question: "여기서 배운 차트가 모든 게임의 정답일까요?",
                  choices: ["아니요, 조건과 상대에 따라 달라져요", "네, 차트의 답은 항상 같아요"],
                  explanation: "차트와 모델은 생각하는 법을 익히는 도구예요. 조건이 달라지면 최선의 결정도 달라질 수 있어요."),
        StudyNote(title: "더 깊이 공부하는 순서예요",
                  body: "기초를 익힌 뒤에는 한 번에 한 조건을 바꿔 보세요. 답을 보기 전에 달라질 방향을 예상하고, 이유를 설명한 뒤, 며칠 후 다시 풀어 보세요.",
                  example: "기초와 가격 → 포지션과 레인지 → 보드와 행동 → EV 결정 → 핸드 복기\n\n그다음 공부할 것: 스택 깊이, 벳 크기, 레이크, 여러 스트리트의 전략과 분산. 코스를 마쳐도 프로 실력이나 수익이 보장되지는 않아요.")
    ]

    static let englishLessons: [StudyNote] = [
        StudyNote(title: "One decision at a time",
                  body: "New to Hold'em? Watch a worked example, then try new cards at your own pace. Help stays available. Later, mix the ideas.",
                  example: "Watch → try new cards → recall later\n\nComing back to a skill later is part of learning it."),
        StudyNote(title: "Find the best five cards",
                  body: "Make the best five-card hand from your two cards and the five shared cards. You need not use both of yours. Comparing hands at the end is the showdown.",
                  example: "Blinds → first bets → 3 shared cards → 1 more → last card\n\nFold: leave the hand. Check: pass without adding chips. Call: match a bet. Raise: bet more.",
                  question: "Can the shared five be your best hand?",
                  choices: ["Yes, the shared cards can play", "No, I must use both of my cards"],
                  explanation: "Pick the best five of all seven cards. If two players' best hands tie, they split the pot."),
        StudyNote(title: "Hand ranks, top down",
                  body: "Compare the hand type first, then its ranks. If those tie, compare the highest other card, the kicker. Suits never rank.",
                  example: "Straight flush · suited run of five\nFour of a kind · four of one rank\nFull house · three and a pair\nFlush · five of one suit\nStraight · five in sequence\nThree of a kind · three of a rank\nTwo pair · two different pairs\nOne pair · two of one rank\nHigh card · none of the above\n\nA, K, Q, J, 10 of one suit is the highest straight flush."),
        StudyNote(title: "Acting later helps",
                  body: "Position is the order of action. Preflop starts left of the big blind; after the flop, with the first player left of the dealer. Heads-up, the dealer is the small blind, acting first preflop and last after.",
                  example: "Same cards, more caution when more players act after you. So the chart varies by seat."),
        StudyNote(title: "Compare odds and price",
                  body: "Before calling, compare the chips you add with the whole pot after the call. Keep chips already in the pot apart.",
                  example: "Pot 12bb + bet 4bb + call 4bb\n\nThe final pot is 20bb. One bb is the size of the big blind.",
                  question: "With no later betting or fee, what winning share does this call need?",
                  choices: ["25%", "20%"], correct: 1,
                  explanation: "You pay 4 to contest 20: 4 ÷ 20 = 20%. Later bets can change a real multi-round decision."),
        StudyNote(title: "Good decisions can lose",
                  body: "Expected value (EV) is a decision's average over many repeats. One hand can differ; the table shows the two apart.",
                  example: "You called with good odds, but the last card beat you.",
                  question: "Does that loss prove the call was wrong?",
                  choices: ["Yes, because the hand lost", "No, judge the odds and price then"], correct: 1,
                  explanation: "Judge the decision using what you could know at the time. The final card includes luck."),
        StudyNote(title: "When answers apply",
                  body: "Opponents follow published practice rules. Preflop uses the app's chart; postflop EV assumes no betting after this action. Neither is GTO or a real opponent.",
                  example: "Ask\nWhich hands could they have?\nWhich actions and sizes count?\nWhat happens after this bet?",
                  question: "Is the chart answer right in every game?",
                  choices: ["No, conditions and opponents vary", "Yes, the chart is always right"],
                  explanation: "The chart is a tool for learning to think. New conditions can change the best choice."),
        StudyNote(title: "What to study next",
                  body: "After the basics, change one condition at a time. Predict the change before the answer, explain why, and retry days later.",
                  example: "Price → position and ranges → board and action → EV → review\n\nNext: stack depth, bet sizes, fees, multi-round play and variance. The course does not promise expert skill or profit.")
    ]
}
