import SwiftUI
import GlassTableDrills

struct LearnView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.leadsWithTerms) private var termsLead
    @State private var pickingLevel = false
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenReview: () -> Void
    let onOpenPractice: () -> Void
    let onOpenBasics: () -> Void
    let onOpenGuidedHand: () -> Void
    var onResumeOpening: () -> Void = {}

    private var due: [Concept] { model.dueConcepts() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.text("배우기", "Learn")).font(GT.title(30))
                    Text(language.text("추천부터 시작하거나, 직접 골라요.", "Follow a suggestion or choose any lesson."))
                        .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                    levelChip
                }
                if let opening = model.state.pendingFirstLesson {
                    Button(action: onResumeOpening) {
                        learningRow(language.text("시작 안내 이어서 보기", "Continue the opening guide"),
                                    language.text("예시 \(opening.exploredCount)/5개를 살펴봤어요. 저장한 카드에서 이어가요.", "\(opening.exploredCount)/5 examples explored. Resume with your saved cards."), icon: "rectangle.stack")
                    }.buttonStyle(GTPress()).accessibilityIdentifier("learn-resume-opening")
                }
                recommendation
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("내 방식으로 연습", "Practice your way")).font(GT.title(20))
                    NavigationLink {
                        PathView(onOpenNode: onOpenNode, onOpenFreePlay: onOpenPractice,
                                 onOpenBasics: onOpenBasics)
                    } label: {
                        learningRow(language.text("전체 레슨", "All lessons"),
                                    language.text("짧은 트랙 네 개. 모든 레슨이 처음부터 열려 있어요.", "Four short tracks. Every lesson is open."), icon: "point.topleft.down.to.point.bottomright.curvepath")
                    }
                    .buttonStyle(GTPress())
                    .accessibilityIdentifier("learn-path")
                    Button(action: onOpenGuidedHand) {
                        learningRow(language.text("함께 한 판", "A hand together"),
                                    language.text("기초 다음에, 블라인드부터 카드 공개까지 천천히 따라가요.", "After the basics, follow a hand from blinds to showdown."), icon: "hand.draw")
                    }.buttonStyle(GTPress()).accessibilityIdentifier("learn-guided-hand")
                    Button(action: onOpenPractice) {
                        learningRow(language.text("한 가지 집중 연습", "Practice one skill"),
                                    language.text("원하는 주제를 골라 다섯 문제씩 풀어요.", "Five questions on a topic you pick."), icon: "rectangle.stack")
                    }.buttonStyle(GTPress())
                    if !due.isEmpty {
                        Button(action: onOpenReview) {
                            learningRow(language.text("배운 내용 복습", "Review topics"),
                                        language.text("복습할 주제 \(due.count)개", "\(due.count) topics ready for review"), icon: "arrow.clockwise")
                        }.buttonStyle(GTPress())
                    }
                }
            }.padding(18)
        }
        .gtTabBarClearance()
        .background(FeltBackground())
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
            } else if model.shouldSuggestBasicsLesson {
                Text(language.text("홀덤 기초", "Hold'em basics")).font(GT.title(24))
                Text(language.text("어떤 패가 더 강한지, 족보부터 알아봐요.", "Start with which hands beat which."))
                    .font(GT.body(15)).foregroundStyle(GT.inkSecondary)
                FeltCTAButton(title: language.text("레슨 시작", "Start lesson"), action: onOpenBasics)
                    .accessibilityIdentifier("learn-basics-start")
            } else if let next = model.nextNode {
                Text(learningNodeTitle(next, language: language, termsLead: termsLead)).font(GT.title(24))
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
        .gtInset(GT.Space.card, firstText: .semibold(13)).frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.Radius.panel)
    }

    /// The level only moves the suggestion, the help that starts switched on and which
    /// words lead, so changing it is one tap and never touches finished lessons.
    private var levelChip: some View {
        Button { pickingLevel = true } label: {
            HStack(spacing: 6) {
                Text(language.text("내 수준: \(model.state.level.levelName(in: language))",
                                   "My level: \(model.state.level.levelName(in: language))"))
                    .font(GT.semibold(13))
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(GT.ink)
            .padding(.horizontal, 12).frame(minHeight: 44)
            .background(GT.glass, in: Capsule())
            .overlay(Capsule().strokeBorder(GT.borderStrong, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityHint(language.text("수준을 바꿔요", "Changes your level"))
        .accessibilityIdentifier("learn-level")
        .confirmationDialog(language.text("어느 쪽에 가까운가요?", "Which fits you best?"),
                            isPresented: $pickingLevel, titleVisibility: .visible) {
            ForEach(PlacementSelfReport.allCases, id: \.self) { level in
                Button(level.levelName(in: language)) {
                    _ = model.setPlacement(report: level, answers: [:], skipped: true,
                                           expectedEpoch: model.epoch)
                }
            }
            Button(language.text("취소", "Cancel"), role: .cancel) {}
        } message: {
            Text(language.text("추천 레슨, 기본으로 켜지는 도움, 먼저 나오는 말만 달라져요. 끝낸 레슨과 기록은 그대로예요.",
                               "This changes only the suggested lesson, how much help starts on, and which words lead. Finished lessons and progress stay as they are."))
        }
    }

    private func learningRow(_ title: String, _ detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(GT.inkSecondary)
                .frame(width: 24).padding(.top, 2).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(GT.semibold(17)).foregroundStyle(GT.onFelt)
                Text(detail).font(GT.body(15)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GT.onFeltSecondary).accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(GT.border).frame(height: 1) }
        .contentShape(Rectangle())
    }
}

func learningNodeTitle(_ node: CurriculumNode, language: LearningLanguage,
                       termsLead: Bool = false) -> String {
    if let concept = Curriculum.taughtConcept(of: node) {
        return skillNames(concept, language: language, termsLead: termsLead).lead
    }
    return language.text("섞어서 확인하기", "Mixed practice")
}

func learningNodeDescription(_ node: CurriculumNode, language: LearningLanguage) -> String {
    if let concept = Curriculum.taughtConcept(of: node) {
        return ConceptIntroduction.make(concept, language: language).why
    }
    return language.text("여러 주제를 새로운 상황에서 함께 써 봐요.", "Use several skills in a new spot.")
}
