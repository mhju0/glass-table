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
                Text("\(language.text("공부 방법", "How learning works")) · \(page + 1)/\(lessons.count)")
                    .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                Text(lesson.title).font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .accessibilityAddTraits(.isHeader)
                Text(lesson.body).font(GT.body(17)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(lesson.steps.enumerated()), id: \.offset) { index, step in
                        // The number hangs, so a wrapped step lines up under its own text.
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(index + 1).").monospacedDigit()
                            Text(step).fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if !lesson.example.isEmpty {
                        Text(lesson.example).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(GT.semibold(19)).foregroundStyle(GT.onFelt)
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
    var steps: [String] = []
    var example: String = ""
    var question: String? = nil
    var choices: [String] = []
    var correct: Int = 0
    var explanation: String = ""

    static func rotatedLessons(seed: UInt64, language: LearningLanguage) -> [StudyNote] {
        var notes = language == .korean ? lessons : englishLessons
        if seed % 2 == 1 {
            notes[1] = StudyNote(title: notes[1].title, body: notes[1].body,
                example: language.text("가격에 비해 낮은 확률로 콜했지만 이번에는 마지막 카드에서 이겼어요.",
                                       "You called at poor odds for the price, but the last card won this hand."),
                question: language.text("이번에 이겼다는 이유만으로 좋은 콜이었다고 할 수 있을까요?", "Does winning this time prove it was a good call?"),
                choices: [language.text("네, 이겼으니 좋은 결정이에요", "Yes, a win means a good decision"),
                          language.text("아니요, 결정할 때의 확률과 가격을 봐요", "No, judge the odds and price then")], correct: 1,
                explanation: language.text("결과에는 운도 들어가요. 결정을 내릴 때의 정보와 가격으로 평가해요.",
                                           "Results include luck. Judge the information and price when the decision was made."))
            notes = notes.map { note in
                guard note.question != nil else { return note }
                return StudyNote(title: note.title, body: note.body, steps: note.steps, example: note.example,
                    question: note.question, choices: Array(note.choices.reversed()),
                    correct: note.choices.count - 1 - note.correct, explanation: note.explanation)
            }
        }
        return notes
    }

    static let lessons: [StudyNote] = [
        StudyNote(title: "한 번에 한 가지씩 배워요",
                  body: "홀덤이 처음이어도 괜찮아요. 먼저 풀이를 보고, 다른 문제를 내 속도로 풀어요. 도움은 언제든 볼 수 있어요. 익숙해지면 여러 개념을 섞어서 연습해요.",
                  steps: ["풀이를 먼저 봐요", "다른 카드로 직접 풀어요", "나중에 다시 떠올려요"]),
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
                  steps: ["기초와 가격", "포지션과 레인지", "보드와 행동", "EV 결정", "핸드 복기"],
                  example: "그다음 공부할 것: 스택 깊이, 벳 크기, 레이크, 여러 스트리트의 전략과 분산. 코스를 마쳐도 프로 실력이나 수익이 보장되지는 않아요.")
    ]

    static let englishLessons: [StudyNote] = [
        StudyNote(title: "One decision at a time",
                  body: "New to Hold'em? Watch a worked example, then try new cards at your own pace. Help stays available. Later, mix the ideas.",
                  steps: ["Watch a worked example", "Try it with new cards", "Recall it later"]),
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
                  steps: ["Price", "Position and ranges", "Board and action", "EV", "Review"],
                  example: "Next: stack depth, bet sizes, fees, multi-round play and variance. The course does not promise expert skill or profit.")
    ]
}
