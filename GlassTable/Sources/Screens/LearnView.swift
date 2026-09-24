import SwiftUI
import GlassTableDrills

struct LearnView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenReview: () -> Void
    let onOpenPractice: () -> Void
    @State private var showPlacement = false

    private var due: [Concept] { model.dueConcepts() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.text("배우기", "Learn")).font(GT.title(30))
                    Text(language.text("추천부터 시작하거나, 직접 골라요.", "Follow a suggestion or choose any lesson."))
                        .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                }
                recommendation
                if !hasFinishedALesson { startingPointCard }
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("내 방식으로 연습", "Practice your way")).font(GT.title(20))
                    NavigationLink {
                        PathView(onOpenNode: onOpenNode, onOpenFreePlay: onOpenPractice)
                    } label: {
                        learningRow(language.text("전체 학습 경로", "Full learning path"),
                                    language.text("기초부터 깊이 있는 판단까지. 모든 레슨이 처음부터 열려 있어요.", "From the basics to deeper decisions. Every lesson is open now."), icon: "point.topleft.down.to.point.bottomright.curvepath")
                    }
                    .buttonStyle(GTPress())
                    .accessibilityIdentifier("learn-path")
                    Button(action: onOpenPractice) {
                        learningRow(language.text("한 가지 집중 연습", "Practice one skill"),
                                    language.text("원하는 주제를 골라 다섯 문제씩 풀어요.", "Pick a topic for a five-question round."), icon: "rectangle.stack")
                    }.buttonStyle(GTPress())
                    if !due.isEmpty {
                        Button(action: onOpenReview) {
                            learningRow(language.text("배운 내용 복습", "Review what you've learned"),
                                        language.text("복습할 주제 \(due.count)개", "\(due.count) topics ready for review"), icon: "arrow.clockwise")
                        }.buttonStyle(GTPress())
                    }
                    if hasFinishedALesson {
                        Button { showPlacement = true } label: {
                            learningRow(language.text("시작점 찾아보기", "Find a starting point"),
                                        language.text("짧은 확인으로 시작할 주제를 추천받아요.", "A short check suggests a topic to start from."),
                                        icon: "scope")
                        }
                        .buttonStyle(GTPress())
                        .accessibilityIdentifier("placement-row")
                    }
                }
            }.padding(18)
        }
        .gtTabBarClearance()
        .background(FeltBackground())
        .sheet(isPresented: $showPlacement) {
            NavigationStack { PlacementView() }
        }
    }

    private var recommendation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(language.text("다음 추천", "Suggested next"))
                .font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            if let session = model.state.activeNodeSession,
               let node = Curriculum.allNodes.first(where: { $0.id == session.nodeID }) {
                Text(learningNodeTitle(node, language: language)).font(GT.title(24))
                Text(language.text("저장한 레슨을 이어가요. \(session.answers.count)/\(session.scheduledConcepts.count)문제 답했어요.", "Resume your saved lesson. \(session.answers.count) of \(session.scheduledConcepts.count) answered."))
                    .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                FeltCTAButton(title: language.text("레슨 이어서 하기", "Resume lesson")) { onOpenNode(node) }
            } else if let round = model.state.activeRound,
               let concept = Concept(rawValue: round.concept) {
                Text(ConceptIntroduction.make(concept, language: language).title).font(GT.title(24))
                Text(language.text("저장한 연습을 이어가요. \(round.answers.count)/\(round.questionCount)문제 답했어요.", "Resume your saved round. \(round.answers.count) of \(round.questionCount) answered."))
                    .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                FeltCTAButton(title: language.text("이어서 연습", "Resume practice"), action: onOpenPractice)
            } else if let review = model.state.activeReviewSession {
                Text(language.text("복습 이어서 하기", "Resume your review")).font(GT.title(24))
                Text(language.text("\(review.answers.count)/\(review.scheduledConcepts.count)문제 답했어요.", "\(review.answers.count) of \(review.scheduledConcepts.count) answered."))
                    .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                FeltCTAButton(title: language.text("복습 이어서 하기", "Resume review"), action: onOpenReview)
            } else if !due.isEmpty {
                Text(language.text("기억을 다시 꺼내 봐요", "Bring it back to mind"))
                    .font(GT.title(24))
                Text(due.prefix(3).map { ConceptIntroduction.make($0, language: language).title }.joined(separator: " · "))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                FeltCTAButton(title: language.text("복습 \(min(5, due.count))개 시작", "Review \(min(5, due.count)) topics"), action: onOpenReview)
            } else if let next = recommendedNode {
                Text(learningNodeTitle(next, language: language)).font(GT.title(24))
                Text(learningNodeDescription(next, language: language))
                    .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                FeltCTAButton(title: language.text("레슨 시작", "Start lesson")) { onOpenNode(next) }
            } else {
                Text(language.text("모든 레슨을 마쳤어요", "You've completed every lesson"))
                    .font(GT.title(24))
                Text(language.text("궁금한 주제를 다시 연습하거나 복습이 생길 때 돌아와요.", "Revisit a topic you enjoy, or return when a review is ready."))
                    .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                FeltCTAButton(title: language.text("주제 골라 연습", "Choose a skill"), action: onOpenPractice)
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: 22)
    }

    /// The starting-point check leads until the learner finishes a lesson; after that
    /// they have a place to begin, so it steps down to an ordinary row.
    private var hasFinishedALesson: Bool {
        Curriculum.allNodes.contains { model.status(of: $0) == .cleared }
    }

    private var startingPointCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text("어디서 시작할지 고민되나요?", "Not sure where to start?"))
                .font(GT.title(19))
            Text(language.text("짧은 확인으로 시작할 주제를 추천해 드려요. 점수나 자격시험이 아니라 출발점을 찾는 과정이에요.", "A short check suggests a starting topic. It isn't a score or a qualification, just a place to begin."))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
            SecondaryCTAButton(title: language.text("시작점 찾아보기", "Find a starting point")) {
                showPlacement = true
            }
            .accessibilityIdentifier("placement-start")
            .padding(.top, 4)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
    }

    private var recommendedNode: CurriculumNode? {
        if let raw = model.state.placement?.recommendedConcept,
           let concept = Concept(rawValue: raw),
           let node = Curriculum.allNodes.first(where: { Curriculum.taughtConcept(of: $0) == concept }),
           model.status(of: node) != .cleared {
            return node
        }
        return model.nextNode
    }

    private func learningRow(_ title: String, _ detail: String, icon: String) -> some View {
        TapCardLabel(title: title, detail: detail, icon: icon)
    }
}

func learningNodeTitle(_ node: CurriculumNode, language: LearningLanguage) -> String {
    if let concept = Curriculum.taughtConcept(of: node) {
        return ConceptIntroduction.make(concept, language: language).title
    }
    return language.text("섞어서 확인하기", "Mixed practice")
}

func learningNodeDescription(_ node: CurriculumNode, language: LearningLanguage) -> String {
    if let concept = Curriculum.taughtConcept(of: node) {
        return ConceptIntroduction.make(concept, language: language).why
    }
    return language.text("여러 주제를 새로운 상황에서 함께 써 봐요.", "Use several skills in a new spot.")
}
