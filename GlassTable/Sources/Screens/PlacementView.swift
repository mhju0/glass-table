import SwiftUI
import GlassTableDrills

struct PlacementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model
    @State private var report: PlacementSelfReport?
    @State private var answers: [String: String] = [:]
    @State private var question = -1
    @State private var completed = false
    @State private var epoch: UUID?

    private var questionID: String { PlacementGuide.questionIDs[max(0, min(question, 2))] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(language.text("시작점 찾기", "Find a starting point")).font(GT.title(28))
                if completed {
                    let recommendation = PlacementGuide.recommendation(report: report, answers: answers)
                    let intro = ConceptIntroduction.make(recommendation, language: language)
                    Text(language.text("여기부터 해 볼까요?", "How about starting here?")).font(GT.body(16))
                    Text(intro.title).font(GT.title(24))
                    Text(intro.why).font(GT.body(16))
                    Text(language.text("시작점 제안일 뿐이에요. 어떤 레슨이든 고를 수 있고, 이전 레슨은 완료로 바뀌지 않아요.", "This is only a starting suggestion. Every lesson stays open, and earlier lessons aren't marked complete."))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    FeltCTAButton(title: language.text("배우기로 돌아가기", "Return to Learn")) { dismiss() }
                } else if question < 0 {
                    Text(language.text("포커가 얼마나 익숙한가요?", "How familiar is poker?"))
                        .font(GT.title(22))
                    Text(language.text("시간 제한 없이 세 가지만 확인해요. 연습 기록이나 실력 단계에는 영향을 주지 않아요.", "Try three untimed questions. They won't change your practice results or skill level."))
                        .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                    ForEach(PlacementSelfReport.allCases, id: \.self) { option in
                        Button {
                            report = option
                            question = 0
                        } label: {
                            Text(reportTitle(option)).font(GT.semibold(17))
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                .padding(14).gtPanel()
                        }.buttonStyle(GTPress())
                    }
                } else {
                    Text(language.text("\(question + 1) / 3 · 천천히 생각해도 좋아요", "\(question + 1) of 3 · Take your time"))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    Text(prompt).font(GT.title(22))
                    ForEach(options, id: \.0) { option in
                        Button { answer(option.0) } label: {
                            Text(option.1).font(GT.semibold(17))
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                .padding(14).gtPanel()
                        }.buttonStyle(GTPress())
                    }
                    Button(language.text("아직 잘 모르겠어요", "I'm not sure yet")) { answer("unsure") }
                        .frame(minHeight: 44)
                }
                if !completed {
                    Button(language.text("확인 없이 시작하기", "Start without the check")) {
                        if model.setPlacement(report: report, answers: [:], skipped: true,
                                              expectedEpoch: epoch ?? model.epoch) { dismiss() }
                    }.frame(minHeight: 44)
                }
            }.padding(20)
        }
        .background(FeltBackground())
        .modifier(ProgressSaveNotice())
        .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
        .onAppear { if epoch == nil { epoch = model.epoch } }
        .onChange(of: model.epoch) { _, _ in dismiss() }
    }

    private func answer(_ value: String) {
        guard model.saveError == nil else { return }
        answers[questionID] = value
        if question < 2 { question += 1 }
        else if model.setPlacement(report: report, answers: answers, skipped: false,
                                   expectedEpoch: epoch ?? model.epoch) { completed = true }
    }

    private func reportTitle(_ value: PlacementSelfReport) -> String {
        switch value {
        case .newToPoker: language.text("처음 배워요", "I'm new to poker")
        case .knowRules: language.text("규칙은 알지만 선택이 어려워요", "I know the rules; decisions are harder")
        case .playRegularly: language.text("자주 하고 더 깊이 배우고 싶어요", "I play regularly and want to go deeper")
        }
    }

    private var prompt: String {
        switch question {
        case 0: language.text("두 패 모두 원 페어예요. 다른 조건이 같다면 어떤 페어가 더 높을까요?", "Both hands have one pair. With everything else equal, which pair ranks higher?")
        case 1: language.text("세 사람이 처음에 1칩, 2칩, 2칩을 냈어요. 첫 사람이 1칩을 더 냈다면 팟은 몇 칩일까요?", "Three players put in 1, 2 and 2 chips. The first player adds 1 more. How many chips are in the pot?")
        default: language.text("팟 10칩에 상대가 5칩을 걸었어요. 5칩을 콜하고 추가 베팅이 없다면, 최소 얼마나 자주 이겨야 손해가 아닐까요?", "The pot is 10 chips and an opponent bets 5. With no later betting, how often must you win to break even on a 5-chip call?")
        }
    }

    private var options: [(String, String)] {
        switch question {
        case 0: [("pair", language.text("A 두 장", "Two aces")),
                 ("low-pair", language.text("K 두 장", "Two kings")),
                 ("tie", language.text("항상 무승부", "Always a tie"))]
        case 1: [("exclude-blinds", language.text("4칩", "4 chips")),
                 ("include-blinds", language.text("6칩", "6 chips")),
                 ("winner-only", language.text("8칩", "8 chips"))]
        default: [("own-stack", "50%"), ("last-result", "33%"), ("compare-call-to-pot", "25%")]
        }
    }
}
