// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct CourseReviewView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    @AccessibilityFocusState(for: .voiceOver) private var focus: Focus?
    @State private var openingEpoch: UUID?
    @State private var showsSession = false

    var initialScope: CourseReviewScope? = nil
    var onStartLesson: () -> Void = {}

    private enum Focus: Hashable { case heading, feedback }
    private enum ScrollTarget: Hashable { case start, feedback }
    private struct Position: Equatable {
        let phase: CourseReviewPhase
        let set: Int
        let step: Int
    }

    var body: some View {
        Group {
            if showsSession, let session = model.state.courseReview {
                review(session)
            } else {
                hub
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { GT.felt.ignoresSafeArea() }
        .gtChrome(leading: {
            ChromeButton.close { dismiss() }
                .accessibilityIdentifier("course-review-close")
        })
        .onAppear {
            guard openingEpoch == nil else { return }
            openingEpoch = model.epoch
            if let initialScope { open(initialScope) }
        }
        .onChange(of: model.epoch) { _, _ in dismiss() }
        .onChange(of: model.state.courseReview == nil) { _, cleared in
            if cleared { showsSession = false }
        }
    }

    private var hub: some View {
        let skills = CourseReviewSession.eligibleSkills(in: model.state)
        return ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.section) {
                heading(language.text("복습", "Review"), id: "course-review-title")
                if let session = model.state.courseReview {
                    let finished = session.phase == .finished
                    destination(finished ? language.text("복습 결과 보기", "View review results")
                                : language.text("복습 이어서 하기", "Resume review"),
                                detail: finished ? scopeTitle(session.scope)
                                : "\(scopeTitle(session.scope))\n\(setLabel(session))",
                                id: "course-review-resume", prominent: true) {
                        showsSession = true
                    }
                } else if skills.isEmpty {
                    emptyState
                } else {
                    destination(scopeTitle(.all), detail: studiedCount(skills.count),
                                id: "course-review-all", prominent: true) { open(.all) }
                    unitOptions
                    lessonOptions
                }
            }
            .padding(.horizontal, GT.Space.edge)
            .padding(.vertical, GT.Space.related)
            .frame(maxWidth: 580)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("course-review-hub")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            Text(language.text("레슨 먼저", "Ready after a lesson"))
                .font(GT.title(19))
                .foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("course-review-empty")
            prose(language.text("레슨을 마치면\n복습할 수 있어요.",
                                "Finish a lesson to practise with new cards."))
            PrimaryCTAButton(title: language.text("첫 레슨 시작", "Start a lesson"), action: onStartLesson)
                .disabled(model.saveError != nil)
                .accessibilityIdentifier("course-review-start-lesson")
        }
        .padding(GT.Space.card)
        .gtPanel()
    }

    private var unitOptions: some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            sectionTitle(language.text("단원 복습", "Review a unit"))
            unitOption(.unitA, id: "course-review-unit-a")
            unitOption(.unitB, id: "course-review-unit-b")
        }
    }

    @ViewBuilder
    private func unitOption(_ scope: CourseReviewScope, id: String) -> some View {
        let count = CourseReviewSession.eligibleSkills(in: model.state, scope: scope).count
        if count > 0 {
            destination(scopeTitle(scope), detail: studiedCount(count), id: id) { open(scope) }
        }
    }

    private var lessonOptions: some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            sectionTitle(language.text("레슨 복습", textSize.isAccessibilitySize ? "Lessons" : "Review a lesson"))
            ForEach(CourseReviewSession.studiedLessons(in: model.state), id: \.rawValue) { skill in
                destination(skill.lessonTitle(in: language), id: "course-review-lesson-\(skill.rawValue)") { open(.lesson(skill)) }
            }
        }
    }

    private func destination(_ title: String, detail: String? = nil, id: String,
                             prominent: Bool = false, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        return Button(action: action) {
            HStack(spacing: GT.Space.related) {
                VStack(alignment: .leading, spacing: GT.Space.compact) {
                    Text(title)
                        .font(prominent ? GT.title(21) : GT.semibold(16))
                        .foregroundStyle(prominent ? GT.actionInk : GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail {
                        Text(detail)
                            .font(GT.body(14))
                            .foregroundStyle(prominent ? GT.actionInk : GT.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(prominent ? GT.actionInk : GT.inkSecondary)
                    .accessibilityHidden(true)
            }
            .padding(GT.Space.related)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(prominent ? GT.actionFill : GT.glass, in: shape)
            .overlay(shape.strokeBorder(prominent ? GT.actionEdge : GT.borderStrong, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress(raised: prominent))
        .disabled(model.saveError != nil)
        .accessibilityIdentifier(id)
    }

    private func review(_ session: CourseReviewSession) -> some View {
        let position = Position(phase: session.phase, set: session.setNumber, step: session.stepNumber)
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    progress(session).id(ScrollTarget.start)
                    if let activity = session.activity {
                        question(activity, in: session)
                    } else {
                        results(session)
                    }
                }
                .padding(.horizontal, GT.Space.edge)
                .padding(.vertical, GT.Space.related)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("course-review-scroll")
            .onAppear {
                if session.revealed { proxy.scrollTo(ScrollTarget.feedback, anchor: .bottom) }
                focus = session.revealed ? .feedback : .heading
            }
            .onChange(of: position) { _, _ in
                proxy.scrollTo(ScrollTarget.start, anchor: .top)
                focus = .heading
            }
            .onChange(of: session.revealed) { _, revealed in
                if revealed {
                    proxy.scrollTo(ScrollTarget.feedback, anchor: .bottom)
                    focus = .feedback
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionDock(session)
                .padding(.horizontal, GT.Space.edge)
                .padding(.vertical, GT.Space.compact)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
                .background {
                    GT.glass.ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .top) { Rectangle().fill(GT.border).frame(height: 1) }
                }
        }
    }

    private func progress(_ session: CourseReviewSession) -> some View {
        let inQuestion = session.activity != nil
        let complete = inQuestion ? session.stepNumber - (session.revealed ? 0 : 1) : session.stepCount
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(scopeTitle(session.scope))
                .font(GT.semibold(15))
                .foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("course-review-scope")
            if session.phase != .finished {
                Text(setLabel(session))
                    .font(GT.semibold(14).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary)
                    .accessibilityIdentifier("course-review-set")
                Text(coverageLabel(session))
                    .font(GT.body(14).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("course-review-coverage")
            }
            if session.stepCount > 0 && session.phase != .finished {
                LessonProgressSegments(total: session.stepCount,
                                       current: inQuestion ? session.stepNumber - 1 : -1,
                                       completed: Set(0..<max(0, min(complete, session.stepCount))))
            }
            if inQuestion {
                Text(session.phase == .retry
                     ? language.text("다시 풀기 \(session.stepNumber)/\(session.stepCount)",
                                     "Correction \(session.stepNumber) of \(session.stepCount)")
                     : language.text("문제 \(session.stepNumber)/\(session.stepCount)",
                                     "Question \(session.stepNumber) of \(session.stepCount)"))
                    .font(GT.body(14).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("course-review-step")
            }
        }
    }

    @ViewBuilder
    private func question(_ activity: CourseReviewActivity, in session: CourseReviewSession) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            heading(activity.title(in: language), id: "course-review-activity-\(activity.id)")
            let note = activity.detail(in: language)
            if !note.isEmpty { prose(note) }
            if activity.kind == .bestFive && !session.revealed {
                Text(language.text("선택 \(session.selectedCardIndices.count)/5",
                                   "Selected \(session.selectedCardIndices.count)/5"))
                    .font(GT.semibold(16).monospacedDigit())
                    .foregroundStyle(GT.ink)
                    .accessibilityIdentifier("course-review-selection-count")
            }
        }
        if !activity.learner.isEmpty || !activity.board.isEmpty {
            cardPanel(activity, session: session)
        }
        if session.revealed {
            feedback(activity, session: session).id(ScrollTarget.feedback)
        } else if activity.kind == .choice {
            choices(activity.choices(in: language), session: session)
        }
    }

    private func cardPanel(_ activity: CourseReviewActivity, session: CourseReviewSession) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        let marksFive = session.revealed && !activity.correctFive.isEmpty
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            if !activity.opponent.isEmpty {
                comparisonRow(language.text("내 카드", "My hand"), hole: activity.learner,
                              board: activity.board, five: marksFive ? activity.correctFive : [])
                rule
                comparisonRow(language.text("상대 카드", "Opponent’s hand"), hole: activity.opponent,
                              board: activity.board, five: marksFive ? activity.opponentFive : [])
            } else {
                let cards = activity.learner + activity.board
                let picks = session.selectedCardIndices
                let chosen = cards.enumerated().compactMap { picks.contains($0.offset) ? $0.element : nil }
                let outlined = !marksFive ? [] : session.answeredCorrectly == true && activity.kind == .bestFive
                    ? chosen : activity.correctFive
                cardRow(activity.board.isEmpty ? language.text("카드", "Cards") : language.text("내 카드", "My cards"),
                        cards: activity.learner, startIndex: 0, outlined: outlined, activity: activity, session: session)
                if !activity.board.isEmpty {
                    if !activity.learner.isEmpty { rule }
                    cardRow(language.text("공용 카드", "Shared cards"), cards: activity.board,
                            startIndex: activity.learner.count, outlined: outlined, activity: activity, session: session)
                }
            }
            if marksFive {
                Text(language.text("테두리 · 가장 좋은 5장", "Gold outline · Best five"))
                    .font(GT.body(14)).foregroundStyle(GT.onTableSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if activity.kind == .bestFive && session.answeredCorrectly == false {
                    Label(language.text("내가 고른 카드", "Your picks"), systemImage: "checkmark.circle.fill")
                        .font(GT.body(14)).foregroundStyle(GT.onTableSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(GT.Space.related)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.tableFeltDeep, in: shape)
        .overlay(shape.strokeBorder(GT.tableHairline, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("course-review-cards")
    }

    private var rule: some View {
        Rectangle().fill(GT.tableHairline).frame(height: 1).accessibilityHidden(true)
    }

    private func comparisonRow(_ title: String, hole: [Card], board: [Card], five: [Card]) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            cardLabel(title)
            SevenCardRow(hole: hole, board: board, used: five.isEmpty ? hole + board : five,
                         comparisonCards: five, size: 46)
                .id(five.isEmpty)
        }
    }

    private func cardRow(_ title: String, cards: [Card], startIndex: Int, outlined: [Card],
                         activity: CourseReviewActivity, session: CourseReviewSession) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            cardLabel(title)
            HStack(spacing: GT.Space.compact) {
                ForEach(cards.indices, id: \.self) { index in
                    let card = cards[index]
                    let choice = startIndex + index
                    let selected = session.selectedCardIndices.contains(choice)
                    if activity.kind == .bestFive && !session.revealed {
                        Button {
                            apply(.toggleCard(choice), to: session)
                        } label: {
                            cardFace(card, outlined: selected)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(GTPress())
                        .disabled(model.saveError != nil || (!selected && session.selectedCardIndices.count == 5))
                        .accessibilityLabel(card.spoken(in: language))
                        .accessibilityAddTraits(selected ? .isSelected : [])
                        .accessibilityIdentifier("course-review-card-\(choice)")
                    } else {
                        let isBest = outlined.contains(card)
                        let wasPicked = activity.kind == .bestFive && session.answeredCorrectly == false && selected
                        cardFace(card, outlined: isBest, picked: wasPicked)
                            .accessibilityLabel(card.spoken(in: language)
                                                + (wasPicked ? language.text(", 내가 고른 카드", ", your pick") : "")
                                                + (isBest ? language.text(", 가장 좋은 5장에 포함", ", in the best five") : ""))
                            .accessibilityIdentifier("course-review-evidence-\(choice)")
                    }
                }
            }
        }
    }

    private func cardFace(_ card: Card, outlined: Bool, picked: Bool = false) -> some View {
        let size: CGFloat = 56
        return PlayingCardView(card: card, size: size)
            .overlay {
                if outlined {
                    RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
                        .strokeBorder(GT.diagramCardEdge, lineWidth: 3)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if picked {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(GT.tableFeltDeep, GT.tableAccent)
                        .font(.system(size: 14, weight: .semibold))
                        .accessibilityHidden(true)
                }
            }
            .frame(minWidth: 44, minHeight: 44)
    }

    private func choices(_ options: [String], session: CourseReviewSession) -> some View {
        let horizontal = options.count == 2 && !textSize.isAccessibilitySize
            && options.allSatisfy { $0.count <= 15 }
        let layout = horizontal ? AnyLayout(HStackLayout(spacing: GT.Space.compact))
            : AnyLayout(VStackLayout(spacing: GT.Space.compact))
        return layout {
            ForEach(options.indices, id: \.self) { index in
                let selected = session.selection == index
                GTChoiceButton(title: options[index], selected: selected) { apply(.select(index), to: session) }
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("course-review-choice-\(index)")
            }
        }
        .disabled(model.saveError != nil)
    }

    private func feedback(_ activity: CourseReviewActivity, session: CourseReviewSession) -> some View {
        let correct = session.answeredCorrectly == true
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        let options = activity.choices(in: language)
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(correct ? language.text("맞았어요", "Correct") : language.text("다시 확인해요", "Not quite"))
                .font(GT.title(22))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($focus, equals: .feedback)
                .accessibilityIdentifier("course-review-feedback")
            Text(activity.explanation(in: language))
                .font(GT.body(16))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("course-review-explanation")
            if let selected = session.selection, options.indices.contains(selected), !correct {
                Text(language.text("내 답 · \(options[selected])", "Your answer · \(options[selected])"))
                    .font(GT.body(14))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(correct ? GT.supportInk : GT.retryInk)
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correct ? GT.supportFill : GT.retryFill, in: shape)
        .overlay(shape.strokeBorder(correct ? GT.supportEdge : GT.retryEdge, lineWidth: 1))
    }

    private func results(_ session: CourseReviewSession) -> some View {
        let finished = session.phase == .finished
        let results = session.completedResults
        let firstRight = finished ? results.reduce(0) { $0 + $1.firstRight } : session.firstRight
        let questionCount = finished ? session.itemCount : session.questionCount
        let retryRight = finished ? results.reduce(0) { $0 + $1.retryRight } : session.retryRight
        let retryCount = finished ? results.reduce(0) { $0 + $1.retryCount } : session.retryCount
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            heading(finished ? language.text("복습 완료", "Review complete")
                    : language.text("세트 완료", "Set complete"), id: "course-review-title")
            if finished {
                Text(completedCoverageLabel(session))
                    .font(GT.semibold(16))
                    .foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("course-review-coverage")
            }
            scoreCard(language.text("첫 답변", "First answers"), value: score(firstRight, questionCount),
                      id: "course-review-first-score")
            scoreCard(language.text("다시 풀기", "Corrections"),
                      value: retryCount == 0 ? language.text("다시 풀 문제 없음", "No missed questions")
                      : score(retryRight, retryCount), id: "course-review-retry-score")
        }
    }

    private func scoreCard(_ label: String, value: String, id: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(label).font(GT.semibold(15)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value).font(GT.title(21).monospacedDigit()).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(id)
        }
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.glass, in: shape)
        .overlay(shape.strokeBorder(GT.borderStrong, lineWidth: 1))
    }

    @ViewBuilder
    private func actionDock(_ session: CourseReviewSession) -> some View {
        if session.phase == .finished {
            PrimaryCTAButton(title: language.text("완료", "Done")) {
                guard let openingEpoch else { return }
                _ = model.closeFinishedCourseReview(from: session, expectedEpoch: openingEpoch)
            }
            .disabled(model.saveError != nil)
            .accessibilityIdentifier("course-review-done")
        } else if session.activity != nil && !session.revealed {
            PrimaryCTAButton(title: language.text("답 확인", "Check answer")) { apply(.submit, to: session) }
                .disabled(!session.canSubmit || model.saveError != nil)
                .accessibilityIdentifier("course-review-submit")
        } else {
            PrimaryCTAButton(title: advanceLabel(session)) { apply(.advance, to: session) }
                .disabled(model.saveError != nil)
                .accessibilityIdentifier("course-review-next")
        }
    }

    private func advanceLabel(_ session: CourseReviewSession) -> String {
        if session.phase == .setResults {
            return session.setNumber < session.setCount
                ? language.text("다음 세트", "Next set")
                : language.text("결과 보기", "See results")
        }
        if session.stepNumber == session.stepCount {
            return session.phase == .question && session.retryCount > 0
                ? language.text("틀린 문제 다시 풀기", "Retry missed questions")
                : language.text("세트 결과", "Set results")
        }
        return language.text("다음", "Next")
    }

    private func open(_ scope: CourseReviewScope) {
        guard let openingEpoch else { return }
        if let existing = model.state.courseReview {
            showsSession = existing.scope == scope
        } else if model.beginCourseReview(scope, expectedEpoch: openingEpoch) {
            showsSession = true
        }
    }

    private func apply(_ action: CourseReviewAction, to session: CourseReviewSession) {
        guard let openingEpoch else { return }
        _ = model.applyCourseReview(action, from: session, expectedEpoch: openingEpoch)
    }

    private func setLabel(_ session: CourseReviewSession) -> String {
        language.text("세트 \(session.setNumber)/\(session.setCount)", "Set \(session.setNumber) of \(session.setCount)")
    }

    private func scopeTitle(_ scope: CourseReviewScope) -> String {
        if scope == .all && textSize.isAccessibilitySize {
            return language.text("전체 복습", "Review all")
        }
        return scope.title(in: language)
    }

    private func studiedCount(_ count: Int) -> String {
        language.text("배운 개념 \(count)개", count == 1 ? "1 skill studied" : "\(count) skills studied")
    }

    private func coverageLabel(_ session: CourseReviewSession) -> String {
        let count = "\(session.coveredCount)/\(session.itemCount)"
        if case .lesson = session.scope {
            return language.text("답한 문제 \(count)", "Answered \(count)")
        }
        return language.text("복습한 개념 \(count)", "Skills practised \(count)")
    }

    private func completedCoverageLabel(_ session: CourseReviewSession) -> String {
        if case .lesson = session.scope {
            return language.text("문제 \(session.itemCount)개 풀이", "\(session.itemCount) questions answered")
        }
        return language.text("개념 \(session.skills.count)개 복습",
                             session.skills.count == 1 ? "1 skill practised" : "\(session.skills.count) skills practised")
    }

    private func score(_ right: Int, _ total: Int) -> String {
        language.text("\(total)개 중 \(right)개 정답", "\(right) of \(total) correct")
    }

    private func heading(_ title: String, id: String) -> some View {
        Text(title).font(GT.title(26)).foregroundStyle(GT.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($focus, equals: .heading)
            .accessibilityIdentifier(id)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(GT.title(19)).foregroundStyle(GT.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func cardLabel(_ title: String) -> some View {
        Text(title).font(GT.semibold(14)).foregroundStyle(GT.onTable)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func prose(_ text: String) -> some View {
        Text(text).font(GT.body(16)).foregroundStyle(GT.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(GT.Typography.bodyLineSpacing)
    }
}
