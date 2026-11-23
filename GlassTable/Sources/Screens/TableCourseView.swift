// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct TableCourseView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @AccessibilityFocusState(for: .voiceOver) private var focus: Focus?
    @State private var epoch: UUID?
    @State private var showCoach = false

    let unit: TableCourseUnit
    let onContinue: (TableCourseUnit) -> Void
    let onReview: (CourseReviewScope) -> Void

    private enum Focus: Hashable { case prompt, feedback }
    private enum Anchor: Hashable { case top, feedback }

    var body: some View {
        Group {
            if let progress = model.state.progress(in: unit) { page(progress) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { GT.felt.ignoresSafeArea() }
        .gtChrome(leading: {
            ChromeButton.close { dismiss() }.accessibilityIdentifier("table-course-close")
        })
        .onAppear { epoch = model.epoch }
        .onChange(of: model.epoch) { _, _ in dismiss() }
        .fullScreenCover(isPresented: $showCoach) {
            FreeTableHandCoachView(table: ChipUnitContent.coachHand, isExample: true) { showCoach = false }
        }
    }

    private func page(_ progress: TableCourseProgress) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    indicator(progress).id(Anchor.top)
                    if let activity = progress.activity {
                        question(activity, progress: progress) {
                            proxy.scrollTo(TableCourseEvidenceView.chartAnchor, anchor: .top)
                        }
                    } else {
                        results(progress)
                    }
                }
                .padding(.horizontal, GT.Space.edge)
                .padding(.vertical, GT.Space.related)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("table-course-scroll")
            .onAppear {
                if progress.revealed { proxy.scrollTo(Anchor.feedback, anchor: .bottom) }
                focus = progress.revealed ? .feedback : .prompt
            }
            .onChange(of: progress.activity?.id) { _, _ in
                proxy.scrollTo(Anchor.top, anchor: .top)
                focus = .prompt
            }
            .onChange(of: progress.revealed) { _, revealed in
                if revealed {
                    proxy.scrollTo(Anchor.feedback, anchor: .bottom)
                    focus = .feedback
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            dock(progress)
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

    private func indicator(_ progress: TableCourseProgress) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            let total = progress.stepCount
            let index = progress.stepNumber
            let complete = progress.activity == nil
            if total > 0 {
                let answered = complete ? total : max(0, index - (progress.revealed ? 0 : 1))
                LessonProgressSegments(total: total, current: complete ? -1 : index - 1,
                                       completed: Set(0..<min(answered, total)))
            }
            if progress.phase == .retry {
                Text(language.text("정정 \(index)/\(total)", "Correction \(index) of \(total)"))
                    .accessibilityIdentifier("table-course-retry")
            } else {
                Text(progress.lesson.title(in: language))
                    .accessibilityIdentifier("table-course-lesson")
            }
        }
        .font(GT.semibold(14))
        .foregroundStyle(GT.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func question(_ activity: TableCourseActivity, progress: TableCourseProgress,
                          showChart: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            heading(activity.title(in: language), id: "table-course-activity-\(activity.id)")
                .accessibilityFocused($focus, equals: .prompt)
            if let prompt = activity.prompt(in: language) { prose(prompt) }
            TableCourseEvidenceView(evidence: progress.revealed ? activity.revealedEvidence ?? activity.evidence
                                                              : activity.evidence)
            if progress.revealed, let explanation = activity.explanation(in: language) {
                TableCourseFeedback(note: explanation, correct: progress.answeredCorrectly == true)
                    .id(Anchor.feedback)
                    .accessibilityFocused($focus, equals: .feedback)
                if activity.evidence.chart != nil {
                    link(language.text("차트 다시 보기", "See the chart"), id: "table-course-show-chart", action: showChart)
                }
            } else if activity.isExample, let explanation = activity.explanation(in: language) {
                prose(explanation)
            } else if !activity.isExample {
                ForEach(Array(activity.choices(in: language).enumerated()), id: \.offset) { index, choice in
                    let selected = progress.selection == index
                    GTChoiceButton(title: choice, selected: selected) { apply(.select(index), from: progress) }
                        .disabled(model.saveError != nil)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                        .accessibilityIdentifier("table-course-choice-\(index)")
                }
            }
        }
    }

    private func results(_ progress: TableCourseProgress) -> some View {
        let finished = progress.phase == .finished
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            heading(finished ? language.text("마쳤어요", "Unit complete")
                             : language.text("레슨 결과", "Lesson results"), id: "table-course-results")
            score(language.text("첫 답변", "First answers"), right: progress.firstRight,
                  total: progress.questionCount, id: "table-course-first-score")
            if progress.retryCount > 0 {
                score(language.text("정정", "Corrections"), right: progress.retryRight,
                      total: progress.retryCount, id: "table-course-retry-score")
            }
            if finished && unit == .chips {
                link(language.text("시작 핸드로 이동", "Go to starting hands"), id: "table-course-skip-guide") {
                    onContinue(.startingHands)
                }
            }
            if finished && unit == .milestone {
                link(language.text("코치와 예시 보기", "Review with the coach"), id: "table-course-coach") {
                    showCoach = true
                }
            }
            if unit != .milestone, let scope = reviewScope(progress) {
                link(scope == .all ? language.text("전체 복습", "Review everything so far")
                                   : progress.phase == .finished ? language.text("단원 복습", "Review this unit")
                                                                 : language.text("레슨 복습", "Review this lesson"),
                     id: "table-course-review") { onReview(scope) }
            }
            if finished && progress.completedResults.count > 1 {
                Text(language.text("앞 레슨", "Earlier lessons")).font(GT.title(19))
                    .foregroundStyle(GT.ink).accessibilityAddTraits(.isHeader)
                ForEach(progress.completedResults.dropLast(), id: \.lesson) { result in
                    if let skill = CourseReviewSkill(rawValue: result.lesson.rawValue) {
                        link(result.lesson.title(in: language), id: "table-course-review-\(skill.rawValue)") {
                            onReview(.lesson(skill))
                        }
                    }
                }
            }
        }
    }

    private func reviewScope(_ progress: TableCourseProgress) -> CourseReviewScope? {
        if progress.phase == .finished || progress.lesson == .d6 || progress.lesson == .e7 {
            return unit == .turns ? .all : .tableUnit(unit)
        }
        return CourseReviewSkill(rawValue: progress.lesson.rawValue).map { .lesson($0) }
    }

    private func score(_ title: String, right: Int, total: Int, id: String) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(title).font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
            Text(language.text("\(total)개 중 \(right)개 정답", "\(right) of \(total) correct"))
                .font(GT.title(21).monospacedDigit()).foregroundStyle(GT.ink)
                .accessibilityIdentifier(id)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtPanel()
    }

    private func link(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(GTOutlinedAction(fills: true))
            .accessibilityIdentifier(id)
    }

    @ViewBuilder private func dock(_ progress: TableCourseProgress) -> some View {
        if progress.phase == .finished {
            let next: TableCourseUnit? = switch unit {
            case .turns: .chips
            case .chips: .milestone
            case .milestone: .startingHands
            case .startingHands: nil
            }
            let title = unit == .chips ? language.text("안내 핸드 연습", "Try the guided hand")
                : next == nil ? language.text("완료", "Done") : language.text("계속", "Continue")
            PrimaryCTAButton(title: title) {
                if let next { onContinue(next) } else { dismiss() }
            }
            .accessibilityIdentifier("table-course-done")
        } else if let activity = progress.activity, !activity.isExample, !progress.revealed {
            PrimaryCTAButton(title: language.text("답 확인", "Check answer")) { apply(.submit, from: progress) }
                .disabled(!progress.canSubmit || model.saveError != nil)
                .accessibilityIdentifier("table-course-submit")
        } else {
            let last = progress.lesson == unit.lessons.last
            let title = progress.phase == .results
                ? (last ? language.text("마치기", "Finish") : language.text("다음 레슨", "Next lesson"))
                : language.text("다음", "Next")
            PrimaryCTAButton(title: title) { apply(.advance, from: progress) }
                .disabled(model.saveError != nil)
                .accessibilityIdentifier("table-course-next")
        }
    }

    private func apply(_ action: TableCourseAction, from progress: TableCourseProgress) {
        guard let epoch else { return }
        _ = model.applyTableCourse(action, from: progress, expectedEpoch: epoch)
    }

    private func heading(_ title: String, id: String) -> some View {
        Text(title).font(GT.title(26)).foregroundStyle(GT.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(id)
    }

    private func prose(_ text: String) -> some View {
        Text(text).font(GT.body(16)).foregroundStyle(GT.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct TableCourseFeedback: View {
    @Environment(\.learningLanguage) private var language
    let note: String
    let correct: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(correct ? language.text("맞았어요", "Correct") : language.text("다시 볼까요?", "Take another look"))
                .font(GT.title(20)).accessibilityAddTraits(.isHeader)
            Text(note).font(GT.body(16))
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(correct ? GT.supportInk : GT.retryInk)
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correct ? GT.supportFill : GT.retryFill, in: shape)
        .overlay(shape.strokeBorder(correct ? GT.supportEdge : GT.retryEdge, lineWidth: 1))
        .accessibilityIdentifier("table-course-feedback")
    }
}
