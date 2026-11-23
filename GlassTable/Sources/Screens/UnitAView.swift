// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct UnitAView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState(for: .voiceOver) private var focus: Focus?
    @State private var openingEpoch: UUID?
    let onReview: (CourseReviewScope) -> Void

    private enum Focus: Hashable { case heading, feedback }
    private enum ScrollTarget: Hashable { case start, feedback }
    private struct Position: Equatable {
        let phase: UnitAPhase
        let activityID: String?
    }

    var body: some View {
        Group {
            if let progress = model.state.unitA { page(progress) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { GT.felt.ignoresSafeArea() }
        .gtChrome(leading: {
            ChromeButton.close { dismiss() }
                .accessibilityIdentifier("unit-a-close")
        })
        .onAppear { openingEpoch = model.epoch }
        .onChange(of: model.epoch) { _, _ in dismiss() }
    }

    private func page(_ progress: UnitAProgress) -> some View {
        let position = Position(phase: progress.phase, activityID: progress.activity?.id)
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    indicator(progress).id(ScrollTarget.start)
                    if let activity = progress.activity {
                        activityContent(activity, progress: progress)
                    } else {
                        results(progress)
                    }
                }
                .padding(.horizontal, GT.Space.edge)
                .padding(.vertical, GT.Space.related)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("unit-a-scroll")
            .onAppear {
                if progress.revealed { proxy.scrollTo(ScrollTarget.feedback, anchor: .top) }
                focus = progress.revealed ? .feedback : .heading
            }
            .onChange(of: position) { _, _ in
                proxy.scrollTo(ScrollTarget.start, anchor: .top)
                focus = .heading
            }
            .onChange(of: progress.revealed) { _, revealed in
                if revealed {
                    proxy.scrollTo(ScrollTarget.feedback, anchor: .top)
                    focus = .feedback
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            action(progress)
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

    private func indicator(_ progress: UnitAProgress) -> some View {
        let step = progress.stepNumber
        let total = progress.stepCount
        let label = switch progress.phase {
        case .lesson: progress.lesson.title(in: language)
        case .retry: language.text("틀린 문제 다시 풀기", "Try the missed question again")
        case .results, .finished: language.text("한 판 따라가기", "Follow a hand")
        }
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            if total > 0 {
                let complete = progress.phase == .results || progress.phase == .finished
                let answered = min(total, max(0, step - (progress.revealed ? 0 : 1)))
                LessonProgressSegments(total: total, current: complete ? -1 : step - 1,
                                       completed: Set(0..<(complete ? total : answered)))
            }
            Text(label).font(GT.semibold(14))
                .foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityValue(progress.activity == nil ? "" : language.text(
                    "\(total)단계 중 \(step)단계", "Step \(step) of \(total)"))
                .accessibilityIdentifier("unit-a-phase")
        }
    }

    @ViewBuilder
    private func activityContent(_ activity: UnitAActivity, progress: UnitAProgress) -> some View {
        let options = activity.options(in: language)
        let body = activity.body(in: language)
        let shownCards = progress.selection.flatMap { progress.revealed ? activity.feedbackCards(for: $0) : nil }
            ?? activity.cards
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            heading(activity.title(in: language))
                .accessibilityIdentifier("unit-a-activity-\(activity.id)")
            if !body.isEmpty { prose(body) }
            if activity.id == "A2-example" { suitLegend }
        }
        if !shownCards.isEmpty {
            table(shownCards, reserveBoard: progress.lesson == .streets && activity.kind == .example)
        }
        if progress.revealed, let selected = progress.selection, options.indices.contains(selected) {
            feedback(activity.feedback(in: language, for: selected),
                     correct: progress.answeredCorrectly, chosen: options[selected])
                .id(ScrollTarget.feedback)
        } else if !options.isEmpty {
            choices(options, progress: progress)
        }
    }

    private var suitLegend: some View {
        let columns = Array(repeating: GridItem(.flexible(), alignment: .leading),
                            count: textSize.isAccessibilitySize ? 1 : 2)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: GT.Space.compact) {
            suit(language.text("하트", "Hearts"), symbol: "suit.heart.fill", color: GT.suitRed)
            suit(language.text("다이아몬드", "Diamonds"), symbol: "suit.diamond.fill", color: GT.suitRed)
            suit(language.text("클럽", "Clubs"), symbol: "suit.club.fill", color: GT.ink)
            suit(language.text("스페이드", "Spades"), symbol: "suit.spade.fill", color: GT.ink)
        }
    }

    private func suit(_ title: String, symbol: String, color: Color) -> some View {
        Label {
            Text(title).foregroundStyle(GT.ink)
        } icon: {
            Image(systemName: symbol).foregroundStyle(color).accessibilityHidden(true)
        }
        .font(GT.semibold(15))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func table(_ groups: [UnitACardGroup], reserveBoard: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            ForEach(Array(groups.enumerated()), id: \.element.role) { offset, group in
                if offset > 0 {
                    Rectangle().fill(GT.tableHairline).frame(height: 1).accessibilityHidden(true)
                }
                cardGroup(group, reserveBoard: reserveBoard && group.role == .shared)
            }
        }
        .padding(GT.Space.related)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.tableFeltDeep, in: shape)
        .overlay(shape.strokeBorder(GT.tableHairline, lineWidth: 1))
    }

    private func cardGroup(_ group: UnitACardGroup, reserveBoard: Bool) -> some View {
        let minimum = reserveBoard ? 5 : 0
        let count = max(group.cards.count, minimum)
        let spoken = group.cards.isEmpty ? language.text("아직 없어요", "No cards yet")
            : group.cards.map { card in
                let name = card.spoken(in: language)
                return group.highlighted.contains(card) ? name + language.text(", 강조", ", highlighted") : name
            }.joined(separator: ", ")
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(group.title(in: language)).font(GT.semibold(14))
                .foregroundStyle(GT.onTable)
                .fixedSize(horizontal: false, vertical: true)
            if count == 0 {
                Text(spoken).font(GT.body(14)).foregroundStyle(GT.onTable)
            } else {
                ForEach(Array(stride(from: 0, to: count, by: 5)), id: \.self) { start in
                    HStack(spacing: GT.Space.compact) {
                        ForEach(start..<min(start + 5, count), id: \.self) { index in
                            cardSlot(index, group: group)
                        }
                    }
                    .animation(reduceMotion ? nil : GT.Motion.change, value: group.cards.count)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(group.title(in: language))
        .accessibilityValue(spoken)
        .accessibilityIdentifier("unit-a-cards-\(group.role)")
    }

    private func cardSlot(_ i: Int, group: UnitACardGroup) -> some View {
        let size: CGFloat = 58
        let shape = RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
        return ZStack {
            if group.cards.indices.contains(i) {
                let card = group.cards[i]
                PlayingCardView(card: card, size: size)
                    .overlay {
                        if group.highlighted.contains(card) {
                            shape.strokeBorder(GT.diagramCardEdge, lineWidth: 3)
                        }
                    }
                    .transition(.opacity)
            } else {
                shape.strokeBorder(GT.tableHairline, style: StrokeStyle(lineWidth: 1.25, dash: [4, 3]))
                    .frame(width: size * 0.72, height: size)
                    .transition(.opacity)
            }
        }
        .accessibilityHidden(true)
    }

    private func choices(_ options: [String], progress: UnitAProgress) -> some View {
        let layout = textSize.isAccessibilitySize || options.count != 2
            ? AnyLayout(VStackLayout(spacing: GT.Space.compact))
            : AnyLayout(HStackLayout(spacing: GT.Space.compact))
        return layout {
            ForEach(options.indices, id: \.self) { index in
                let selected = index == progress.selection
                GTChoiceButton(title: options[index], selected: selected) { apply(.select(index), from: progress) }
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("unit-a-choice-\(index)")
            }
        }
        .disabled(model.saveError != nil)
    }

    private func feedback(_ note: String, correct: Bool?, chosen: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        let missed = correct == false
        let title = switch correct {
        case .some(true): language.text("맞았어요", "Correct")
        case .some(false): language.text("다시 살펴봐요", "Take another look")
        case .none: language.text("핸드 종료", "This hand has ended")
        }
        let ink = missed ? GT.retryInk : GT.supportInk
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(title).font(GT.title(22))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($focus, equals: .feedback)
                .accessibilityIdentifier("unit-a-feedback")
            Text(note).font(GT.body(16))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .accessibilityIdentifier("unit-a-explanation")
            if missed {
                Text(language.text("고른 답 · \(chosen)", "You chose · \(chosen)")).font(GT.body(14))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(ink)
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(missed ? GT.retryFill : GT.supportFill, in: shape)
        .overlay(shape.strokeBorder(missed ? GT.retryEdge : GT.supportEdge, lineWidth: 1))
    }

    @ViewBuilder
    private func results(_ progress: UnitAProgress) -> some View {
        let finished = progress.phase == .finished
        let lastLesson = progress.lesson == .endings
        VStack(alignment: .leading, spacing: GT.Space.related) {
            heading(finished ? language.text("첫 단원을 마쳤어요", "Unit complete")
                    : lastLesson ? language.text("복습 결과", "Checkpoint results")
                    : language.text("레슨 결과", "Lesson results"))
                .accessibilityIdentifier("unit-a-title")
            scoreCard(lastLesson ? language.text("복습 첫 답변", "Checkpoint first answers")
                      : language.text("첫 답변", "First answers"),
                      language.text("\(progress.questionCount)개 중 \(progress.firstRight)개 정답",
                                    "\(progress.firstRight) of \(progress.questionCount) correct"),
                      id: "unit-a-first-score")
            if progress.retryCount > 0 {
                scoreCard(language.text("다시 풀기", "Corrections"),
                          language.text("\(progress.retryCount)개 중 \(progress.retryRight)개 정답",
                                        "\(progress.retryRight) of \(progress.retryCount) correct"),
                          id: "unit-a-retry-score")
            }
            if lastLesson {
                reviewButton(.unitA, unit: true)
            } else if let skill = CourseReviewSkill(rawValue: progress.lesson.rawValue) {
                reviewButton(.lesson(skill), unit: false)
            }
            if finished {
                earlierResults(progress.completedResults.filter { $0.lesson != .endings })
            }
        }
    }

    private func reviewButton(_ scope: CourseReviewScope, unit: Bool) -> some View {
        Button(unit ? language.text("단원 복습", "Review this unit")
                    : language.text("레슨 복습", "Review this lesson")) {
            onReview(scope)
        }
        .buttonStyle(GTOutlinedAction(fills: true))
        .accessibilityIdentifier("unit-a-review")
    }

    private func earlierResults(_ results: [UnitALessonResult]) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            Text(language.text("앞 레슨 결과", "Earlier lessons"))
                .font(GT.title(19)).foregroundStyle(GT.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(results, id: \.lesson) { result in
                Button {
                    if let skill = CourseReviewSkill(rawValue: result.lesson.rawValue) {
                        onReview(.lesson(skill))
                    }
                } label: {
                    HStack(alignment: .top, spacing: GT.Space.related) {
                        VStack(alignment: .leading, spacing: GT.Space.compact) {
                            Text(result.lesson.title(in: language))
                                .font(GT.semibold(16)).foregroundStyle(GT.ink)
                            Text(language.text("첫 답변 \(result.firstRight)/\(result.questionCount)",
                                               "First answers \(result.firstRight)/\(result.questionCount)"))
                                .font(GT.body(14).monospacedDigit()).foregroundStyle(GT.inkSecondary)
                            if result.retryCount > 0 {
                                Text(language.text("다시 풀기 \(result.retryRight)/\(result.retryCount)",
                                                   "Corrections \(result.retryRight)/\(result.retryCount)"))
                                    .font(GT.body(14).monospacedDigit()).foregroundStyle(GT.inkSecondary)
                            }
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.clockwise")
                            .font(GT.semibold(14))
                            .foregroundStyle(GT.inkSecondary)
                            .accessibilityHidden(true)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(GTPress())
                .accessibilityElement(children: .combine)
                .accessibilityHint(language.text("이 레슨을 복습해요.", "Review this lesson."))
                .accessibilityIdentifier("unit-a-earlier-\(result.lesson.id)")
                Divider().overlay(GT.border)
            }
        }
    }

    private func scoreCard(_ label: String, _ value: String, id: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(label).font(GT.semibold(15)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value).font(GT.title(22).monospacedDigit()).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(id)
        }
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.glass, in: shape)
        .overlay(shape.strokeBorder(GT.borderStrong, lineWidth: 1))
    }

    @ViewBuilder
    private func action(_ progress: UnitAProgress) -> some View {
        if let activity = progress.activity, activity.kind != .example, !progress.revealed {
            let label = activity.kind == .branch
                ? language.text("결말 보기", "See the ending") : language.text("답 확인", "Check answer")
            PrimaryCTAButton(title: label) { apply(.submit, from: progress) }
                .disabled(progress.selection == nil || model.saveError != nil)
                .accessibilityIdentifier("unit-a-submit")
        } else if progress.phase == .finished {
            PrimaryCTAButton(title: language.text("완료", "Done")) { dismiss() }
                .accessibilityIdentifier("unit-a-done")
        } else {
            PrimaryCTAButton(title: nextTitle(progress)) { apply(.advance, from: progress) }
                .disabled(model.saveError != nil)
                .accessibilityIdentifier("unit-a-next")
        }
    }

    private func nextTitle(_ progress: UnitAProgress) -> String {
        if progress.phase == .results {
            return progress.lesson == .endings ? language.text("마치기", "Finish unit") : language.text("다음 레슨", "Next lesson")
        }
        switch progress.activity?.id {
        case "A4-preflop": return language.text("플랍 보기", "Show the flop")
        case "A4-flop": return language.text("턴 보기", "Show the turn")
        case "A4-turn": return language.text("리버 보기", "Show the river")
        case "A4-river": return language.text("연습하기", "Practice")
        default: return language.text("다음", "Next")
        }
    }

    private func apply(_ action: UnitAAction, from progress: UnitAProgress) {
        guard let openingEpoch else { return }
        _ = model.applyUnitA(action, from: progress, expectedEpoch: openingEpoch)
    }

    private func heading(_ title: String) -> some View {
        Text(title).font(GT.title(26)).foregroundStyle(GT.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($focus, equals: .heading)
    }

    private func prose(_ text: String) -> some View {
        Text(text).font(GT.body(16)).foregroundStyle(GT.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(GT.Typography.bodyLineSpacing)
    }
}
