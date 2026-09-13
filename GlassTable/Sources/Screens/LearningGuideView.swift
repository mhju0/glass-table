// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// Short orientation and study habits. These examples never award course credit.
struct LearningGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var answer: Int?

    private var lesson: StudyNote { StudyNote.lessons[page] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("시작 안내 · \(page + 1)/\(StudyNote.lessons.count)")
                    .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                Text(lesson.title).font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .accessibilityAddTraits(.isHeader)
                Text(lesson.body).font(GT.body(17)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(lesson.example).font(GT.semibold(19)).foregroundStyle(GT.onFelt)
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(GT.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                if let question = lesson.question {
                    Text(question).font(GT.semibold(17)).foregroundStyle(GT.onFelt)
                    VStack(spacing: 12) {
                        ForEach(Array(lesson.choices.enumerated()), id: \.offset) { index, choice in
                            Button { answer = index } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: answer == index ? "checkmark.circle.fill" : "circle")
                                    Text(choice).multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .font(GT.semibold(16)).foregroundStyle(GT.onFelt)
                                .padding(16).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                .background(GT.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(answer == index ? GT.mint : GT.borderStrong, lineWidth: 1))
                            }
                            .buttonStyle(GTPress())
                            .accessibilityAddTraits(answer == index ? .isSelected : [])
                            .disabled(answer != nil)
                        }
                    }
                    if let answer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(answer == lesson.correct ? "맞아요" : "이렇게 생각해 봐요")
                                .font(GT.semibold(18)).foregroundStyle(GT.onFelt)
                            Text(lesson.explanation).font(GT.body(16)).foregroundStyle(GT.onFeltSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(24)
            .id(page)
        }
        .background(FeltBackground())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                FeltCTAButton(title: page == StudyNote.lessons.count - 1 ? "연습하러 가기" : "다음 이야기") {
                    if page == StudyNote.lessons.count - 1 { dismiss() }
                    else { page += 1; answer = nil }
                }
                .disabled(lesson.question != nil && answer == nil)
                if page > 0 {
                    Button("이전 이야기") { page -= 1; answer = nil }
                        .font(GT.semibold(15)).foregroundStyle(GT.onFeltSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(GTPress())
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 12).background(GT.felt)
        }
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
        .onAppear {
            #if DEBUG
            if let requested = ProcessInfo.processInfo.environment["GT_DEMO_GUIDE_PAGE"].flatMap(Int.init) {
                page = min(max(requested, 0), StudyNote.lessons.count - 1)
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

    static let lessons: [StudyNote] = [
        StudyNote(title: "한 번에 한 가지씩 배워요",
                  body: "홀덤이 처음이어도 괜찮아요. 먼저 풀이를 보고, 도움을 받으며 풀고, 다른 문제를 혼자 풀어요. 익숙해지면 여러 개념을 섞어서 연습해요.",
                  example: "풀이 보기 → 함께 풀기 → 혼자 풀기\n\n나중에 다시 떠올리는 복습까지가 한 번의 학습이에요."),
        StudyNote(title: "가장 좋은 다섯 장을 찾아요",
                  body: "홀덤은 내 카드 2장과 모두가 함께 쓰는 보드 5장 중 가장 좋은 5장으로 승부해요. 내 카드를 반드시 두 장 다 쓸 필요는 없어요. 끝까지 남은 사람들이 패를 비교하는 순간이 쇼다운이에요.",
                  example: "블라인드 → 프리플랍 → 플랍 3장 → 턴 1장 → 리버 1장\n\n폴드는 포기, 체크는 추가로 내지 않고 넘기기, 콜은 상대 금액에 맞추기, 레이즈는 더 올리기예요.",
                  question: "보드 다섯 장이 내 최선의 조합일 수도 있을까요?",
                  choices: ["네, 보드만 쓸 수도 있어요", "아니요, 내 카드 두 장을 꼭 써야 해요"],
                  explanation: "일곱 장 중 최선의 다섯 장을 골라요. 두 사람의 최선의 다섯 장이 같으면 팟을 나누는 찹이에요."),
        StudyNote(title: "족보는 위에서부터 강해요",
                  body: "먼저 조합을 비교하고, 같은 조합이면 그 조합을 만든 카드의 숫자를 비교해요. 그래도 같으면 남는 높은 카드인 키커를 비교해요. 무늬 자체에는 우열이 없어요.",
                  example: "스트레이트 플러시 · 같은 무늬의 연속 5장\n포카드 · 같은 숫자 4장\n풀하우스 · 트리플과 페어\n플러시 · 같은 무늬 5장\n스트레이트 · 연속된 숫자 5장\n트리플 · 같은 숫자 3장\n투페어 · 페어 두 쌍\n원페어 · 같은 숫자 2장\n하이 카드 · 위 조합이 없는 패\n\nA·K·Q·J·10의 같은 무늬는 가장 높은 스트레이트 플러시예요."),
        StudyNote(title: "늦게 결정할수록 정보가 많아요",
                  body: "포지션은 결정하는 순서예요. 프리플랍에는 빅 블라인드 왼쪽부터, 플랍 이후에는 버튼 왼쪽의 남은 사람부터 행동해요. 헤즈업에서는 버튼이 스몰 블라인드이고, 프리플랍에는 먼저, 이후에는 나중에 행동해요.",
                  example: "같은 카드라도 내 뒤에 남은 사람이 많으면 더 조심해야 해요. 연습 차트가 자리마다 다른 이유예요."),
        StudyNote(title: "이길 확률과 낼 가격을 비교해요",
                  body: "콜을 결정할 때는 앞으로 낼 돈을 콜한 뒤의 전체 팟과 비교해요. 이미 팟에 들어간 돈과 지금 추가로 낼 돈을 구분해 보세요.",
                  example: "기존 팟 12bb + 상대 벳 4bb + 내 콜 4bb\n\n콜한 뒤 팟은 20bb예요. bb는 빅 블라인드를 1로 보는 단위예요.",
                  question: "추가 베팅과 수수료가 없다면 필요한 에퀴티는 얼마일까요?",
                  choices: ["25%", "20%"], correct: 1,
                  explanation: "낼 돈 4 ÷ 콜한 뒤 팟 20 = 20%예요. 실제 여러 스트리트의 결정에는 이후 베팅도 영향을 줘요."),
        StudyNote(title: "좋은 결정도 질 수 있어요",
                  body: "기댓값(EV)은 같은 조건에서 결정을 반복했을 때의 평균이에요. 한 번의 승패와는 달라요. 테이블에서는 실제 결과와 결정의 EV 손실을 따로 살펴봐요.",
                  example: "유리한 확률로 콜했지만 이번 리버에서 졌어요.",
                  question: "이 결과만으로 콜이 잘못됐다고 할 수 있을까요?",
                  choices: ["네, 졌으니 잘못된 콜이에요", "아니요, 결정 당시의 확률과 가격을 봐야 해요"], correct: 1,
                  explanation: "결정할 때 알 수 있었던 정보로 평가해요. 결과만 보고 판단을 바꾸면 운과 실력을 혼동하기 쉬워요."),
        StudyNote(title: "정답이 성립하는 조건도 배워요",
                  body: "이 앱의 상대는 전략이 공개된 연습용 모델이에요. 프리플랍은 앱의 차트로, 포스트플랍 EV는 현재 베팅이 끝난 뒤 추가 베팅 없이 끝까지 간다는 가정으로 평가해요. 실제 상대의 전략이나 완전한 GTO 해답은 아니에요.",
                  example: "확인할 것\n어떤 레인지인가요?\n어떤 행동과 크기를 허용하나요?\n이후 베팅을 어떻게 가정하나요?",
                  question: "여기서 배운 차트를 모든 게임의 정답으로 써도 될까요?",
                  choices: ["아니요, 조건과 상대가 달라지면 다시 생각해요", "네, 차트의 답은 항상 같아요"],
                  explanation: "차트와 모델은 생각하는 법을 익히는 도구예요. 조건이 달라지면 최선의 결정도 달라질 수 있어요."),
        StudyNote(title: "더 깊이 공부하는 순서예요",
                  body: "기초를 익힌 뒤에는 한 번에 한 조건을 바꿔 보세요. 답을 보기 전에 달라질 방향을 예상하고, 이유를 설명한 뒤, 며칠 후 다시 풀어 보세요.",
                  example: "기초와 가격 → 포지션과 레인지 → 보드와 행동 → EV 결정 → 핸드 복기\n\n그다음 공부할 것: 스택 깊이, 베팅 크기, 레이크, 여러 스트리트의 전략과 분산. 코스 완주는 프로 실력이나 수익을 보장하지 않아요.")
    ]
}
