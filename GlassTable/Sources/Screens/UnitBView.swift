// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct UnitBView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    @AccessibilityFocusState(for: .voiceOver) private var focus: Focus?
    @State private var openingEpoch: UUID?

    let onOpenPair: () -> Void
    let onReview: (CourseReviewScope) -> Void

    private enum Focus: Hashable { case heading, feedback }
    private enum ScrollTarget: Hashable { case start, feedback }
    private struct Position: Equatable {
        let phase: UnitBPhase
        let activityID: String?
    }

    var body: some View {
        Group {
            if let progress = model.state.unitB { page(progress) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { GT.felt.ignoresSafeArea() }
        .gtChrome(leading: {
            ChromeButton.close { dismiss() }
                .accessibilityIdentifier("unit-b-close")
        })
        .onAppear { openingEpoch = model.epoch }
        .onChange(of: model.epoch) { _, _ in dismiss() }
    }

    private func page(_ progress: UnitBProgress) -> some View {
        let position = Position(phase: progress.phase, activityID: progress.activity?.id)
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    indicator(progress).id(ScrollTarget.start)
                    if let activity = progress.activity {
                        activityContent(activity, progress: progress)
                    } else if progress.phase == .pairLesson {
                        pairLesson
                    } else {
                        results(progress)
                    }
                }
                .padding(.horizontal, GT.Space.edge)
                .padding(.vertical, GT.Space.related)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("unit-b-scroll")
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

    private func indicator(_ progress: UnitBProgress) -> some View {
        let step = progress.stepNumber
        let total = progress.stepCount
        let label = switch progress.phase {
        case .lesson: progress.lesson.title(in: language)
        case .pairLesson: language.text("레슨 2 / 13", "Lesson 2 of 13")
        case .retry: language.text("틀린 문제 다시 풀기", "Correction practice")
        case .results, .finished: language.text("이기는 패 찾기", "Decide who wins")
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
                .accessibilityIdentifier("unit-b-phase")
        }
    }

    @ViewBuilder
    private func activityContent(_ activity: UnitBActivity, progress: UnitBProgress) -> some View {
        let options = activity.choices(in: language)
        let detail = activity.detail(in: language)
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            heading(activity.title(in: language))
                .accessibilityIdentifier("unit-b-activity-\(activity.id)")
            if !detail.isEmpty { prose(detail) }
            if activity.kind == .bestFive && !progress.revealed {
                let count = progress.selectedCardIndices.count
                Text(language.text("선택 \(count)/5", "Selected \(count)/5"))
                    .font(GT.semibold(16).monospacedDigit())
                    .foregroundStyle(GT.ink)
                    .accessibilityIdentifier("unit-b-selection-count")
            }
        }
        table(activity, progress: progress)
        if progress.revealed {
            feedback(activity.explanation(in: language), correct: progress.answeredCorrectly == true,
                     chosen: progress.selection.flatMap { options.indices.contains($0) ? options[$0] : nil })
                .id(ScrollTarget.feedback)
        } else if activity.kind == .example {
            prose(activity.explanation(in: language))
                .accessibilityIdentifier("unit-b-example-explanation")
        } else if !options.isEmpty {
            choices(options, progress: progress)
        }
    }

    private func table(_ activity: UnitBActivity, progress: UnitBProgress) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        let showsFive = activity.kind == .example || progress.revealed || activity.showsBestFivesBeforeAnswer
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            if activity.opponent.isEmpty {
                singleHand(activity, showsFive: showsFive, progress: progress)
            } else {
                comparisonRow(language.text("내 카드", "My hand"), id: "learner",
                              hole: activity.learner, board: activity.board,
                              bestFive: showsFive ? activity.correctFive : [])
                Rectangle().fill(GT.tableHairline).frame(height: 1).accessibilityHidden(true)
                comparisonRow(language.text("상대 카드", "Opponent’s hand"), id: "opponent",
                              hole: activity.opponent, board: activity.board,
                              bestFive: showsFive ? activity.opponentFive : [])
            }
            if showsFive {
                VStack(alignment: .leading, spacing: GT.Space.compact) {
                    Text(textSize.isAccessibilitySize
                         ? language.text("표시된 5장", "Best five outlined")
                         : language.text("테두리로 가장 좋은 5장을 표시했어요.", "The outlines mark each best five."))
                    if activity.kind == .bestFive && progress.answeredCorrectly == false {
                        HStack(alignment: .firstTextBaseline, spacing: GT.Space.compact) {
                            submittedMark
                            Text(language.text("내가 고른 카드", "Your picks"))
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .font(GT.body(14)).foregroundStyle(GT.onTableSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(GT.Space.related)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.tableFeltDeep, in: shape)
        .overlay(shape.strokeBorder(GT.tableHairline, lineWidth: 1))
    }

    private func comparisonRow(_ name: String, id: String, hole: [Card],
                               board: [Card], bestFive: [Card]) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(name).font(GT.semibold(14)).foregroundStyle(GT.onTable)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if id == "learner" {
                Text(textSize.isAccessibilitySize
                     ? language.text("개인 카드 2장\n공용 카드 5장", "2 private cards\n5 shared cards")
                     : language.text("개인 카드 2장 · 공용 카드 5장", "2 private cards · 5 shared cards"))
                    .font(GT.body(13)).foregroundStyle(GT.onTableSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SevenCardRow(hole: hole, board: board, used: bestFive.isEmpty ? hole + board : bestFive,
                         comparisonCards: bestFive, size: 46)
                .id(bestFive.isEmpty)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("unit-b-cards-\(id)")
    }

    private func singleHand(_ activity: UnitBActivity, showsFive: Bool,
                            progress: UnitBProgress) -> some View {
        let cards = activity.learner + activity.board
        let chosenFive = cards.enumerated().compactMap { progress.selectedCardIndices.contains($0.offset) ? $0.element : nil }
        let shownFive = activity.kind == .bestFive && progress.answeredCorrectly == true
            ? chosenFive : activity.correctFive
        let canPick = activity.kind == .bestFive && !progress.revealed
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            cardGroup(language.text("내 카드", "My cards"), id: "learner",
                      cards: activity.learner, startIndex: 0, canPick: canPick,
                      highlighted: showsFive ? shownFive : [], progress: progress)
            Rectangle().fill(GT.tableHairline).frame(height: 1).accessibilityHidden(true)
            cardGroup(language.text("공용 카드", "Shared cards"), id: "board",
                      cards: activity.board, startIndex: activity.learner.count, canPick: canPick,
                      highlighted: showsFive ? shownFive : [], progress: progress)
        }
    }

    private func cardGroup(_ name: String, id: String, cards: [Card], startIndex: Int, canPick: Bool,
                           highlighted: [Card], progress: UnitBProgress) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(name).font(GT.semibold(14)).foregroundStyle(GT.onTable)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: GT.Space.compact) {
                ForEach(cards.indices, id: \.self) { index in
                    let card = cards[index]
                    let selectionIndex = index + startIndex
                    let selected = progress.selectedCardIndices.contains(selectionIndex)
                    if canPick {
                        Button {
                            apply(.toggleCard(selectionIndex), from: progress)
                        } label: {
                            handCard(card, outlined: selected)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(GTPress())
                        .disabled(model.saveError != nil || (!selected && progress.selectedCardIndices.count == 5))
                        .accessibilityLabel(card.spoken(in: language))
                        .accessibilityAddTraits(selected ? .isSelected : [])
                        .accessibilityIdentifier("unit-b-card-\(selectionIndex)")
                    } else {
                        let plays = highlighted.contains(card)
                        let submitted = progress.answeredCorrectly == false && selected
                        let label = card.spoken(in: language)
                            + (submitted ? language.text(", 내가 고른 카드", ", your pick") : "")
                            + (plays ? language.text(", 가장 좋은 5장에 포함", ", in the best five") : "")
                        handCard(card, outlined: plays, submitted: submitted)
                            .accessibilityLabel(label)
                            .accessibilityIdentifier("unit-b-evidence-\(selectionIndex)")
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("unit-b-cards-\(id)")
    }

    private func handCard(_ card: Card, outlined: Bool, submitted: Bool = false) -> some View {
        let size: CGFloat = 58
        let shape = RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
        return PlayingCardView(card: card, size: size)
            .overlay {
                if outlined {
                    shape.strokeBorder(GT.diagramCardEdge, lineWidth: 3)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if submitted { submittedMark.offset(x: 2, y: 2) }
            }
            .frame(minWidth: 44, minHeight: 44)
    }

    private var submittedMark: some View {
        Image(systemName: "checkmark.circle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(GT.tableFeltDeep, GT.tableAccent)
            .font(.system(size: 14, weight: .semibold))
            .accessibilityHidden(true)
    }

    private func choices(_ options: [String], progress: UnitBProgress) -> some View {
        let layout = textSize.isAccessibilitySize || options.count != 2
            ? AnyLayout(VStackLayout(spacing: GT.Space.compact))
            : AnyLayout(HStackLayout(spacing: GT.Space.compact))
        return layout {
            ForEach(options.indices, id: \.self) { index in
                let selected = index == progress.selection
                GTChoiceButton(title: options[index], selected: selected) { apply(.select(index), from: progress) }
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("unit-b-choice-\(index)")
            }
        }
        .disabled(model.saveError != nil)
    }

    private func feedback(_ note: String, correct: Bool, chosen: String?) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(correct ? language.text("맞았어요", "Correct") : language.text("다시 확인해요", "Not quite"))
                .font(GT.title(22))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($focus, equals: .feedback)
                .accessibilityIdentifier("unit-b-feedback")
            Text(note).font(GT.body(16))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .accessibilityIdentifier("unit-b-explanation")
            if !correct, let chosen {
                Text(language.text("고른 답 · \(chosen)", "You chose · \(chosen)")).font(GT.body(14))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(correct ? GT.supportInk : GT.retryInk)
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correct ? GT.supportFill : GT.retryFill, in: shape)
        .overlay(shape.strokeBorder(correct ? GT.supportEdge : GT.retryEdge, lineWidth: 1))
    }

    private var passedPairScore: Int? {
        guard let score = model.state.pairLesson?.bestFirstRight, score >= 6 else { return nil }
        return score
    }

    private var pairLesson: some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            heading(language.text("원 페어 비교하기", "Compare pairs"))
                .accessibilityIdentifier("unit-b-title")
            if let score = passedPairScore {
                scoreCard(textSize.isAccessibilitySize
                          ? language.text("힌트 없이 낸 최고 점수", "Best unaided score")
                          : language.text("이전 최고 기록 (힌트 없이)", "Previous best without hints"),
                          language.text("\(score)/8 정답", "\(score) of 8 correct"), id: "unit-b-pair-score")
            } else {
                prose(language.text("둘 다 원 페어라면 어느 쪽이 이길까요? 8문제 중 6문제를 힌트 없이 맞혀 보세요.",
                                    "Both players have a pair.\nGet 6 of 8 right without hints."))
            }
        }
    }

    private func results(_ progress: UnitBProgress) -> some View {
        let finished = progress.phase == .finished
        let checkpoint = progress.lesson == .checkpoint
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            heading(finished ? language.text("단원을 마쳤어요", "Unit complete")
                    : checkpoint ? language.text("복습 결과", "Checkpoint results")
                    : language.text("레슨 결과", "Lesson results"))
                .accessibilityIdentifier("unit-b-title")
            scoreCard(checkpoint ? language.text("복습 첫 답변", "Checkpoint first answers")
                      : language.text("첫 답변", "First answers"),
                      language.text("\(progress.questionCount)개 중 \(progress.firstRight)개 정답",
                                    "\(progress.firstRight) of \(progress.questionCount) correct"),
                      id: "unit-b-first-score")
            if progress.retryCount > 0 {
                scoreCard(language.text("다시 풀기", "Corrections"),
                          language.text("\(progress.retryCount)개 중 \(progress.retryRight)개 정답",
                                        "\(progress.retryRight) of \(progress.retryCount) correct"),
                          id: "unit-b-retry-score")
            }
            if checkpoint {
                reviewButton(.unitB, unit: true)
            } else if let skill = CourseReviewSkill(rawValue: progress.lesson.rawValue) {
                reviewButton(.lesson(skill), unit: false)
            }
            if finished {
                earlierResults(progress.completedResults.filter { $0.lesson != .checkpoint })
            }
        }
    }

    private func reviewButton(_ scope: CourseReviewScope, unit: Bool) -> some View {
        Button(unit ? language.text("단원 복습", "Review this unit")
                    : language.text("레슨 복습", "Review this lesson")) {
            onReview(scope)
        }
        .buttonStyle(GTOutlinedAction(fills: true))
        .accessibilityIdentifier("unit-b-review")
    }

    private func earlierResults(_ results: [UnitBLessonResult]) -> some View {
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
                            Text(result.lesson == .pairComparison
                                 ? language.text("이전 최고 기록 \(result.firstRight)/\(result.questionCount)",
                                                 "Previous best \(result.firstRight)/\(result.questionCount)")
                                 : language.text("첫 답변 \(result.firstRight)/\(result.questionCount)",
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
                .accessibilityIdentifier("unit-b-earlier-\(result.lesson.rawValue)")
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
    private func action(_ progress: UnitBProgress) -> some View {
        if progress.phase == .pairLesson {
            if let score = passedPairScore {
                PrimaryCTAButton(title: language.text("계속하기", "Continue")) {
                    apply(.completePairLesson(bestFirstRight: score), from: progress)
                }
                .disabled(model.saveError != nil)
                .accessibilityIdentifier("unit-b-continue-pair")
            } else {
                PrimaryCTAButton(title: language.text("레슨 열기", "Open pair lesson"), action: onOpenPair)
                    .disabled(model.saveError != nil)
                    .accessibilityIdentifier("unit-b-open-pair")
            }
        } else if let activity = progress.activity, activity.kind != .example, !progress.revealed {
            PrimaryCTAButton(title: language.text("답 확인", "Check answer")) { apply(.submit, from: progress) }
                .disabled(!progress.canSubmit || model.saveError != nil)
                .accessibilityIdentifier("unit-b-submit")
        } else if progress.phase == .finished {
            PrimaryCTAButton(title: language.text("완료", "Done")) { dismiss() }
                .accessibilityIdentifier("unit-b-done")
        } else {
            let label = progress.phase == .results
                ? (progress.lesson == .checkpoint ? language.text("마치기", "Finish unit")
                   : language.text("다음 레슨", "Next lesson"))
                : language.text("다음", "Next")
            PrimaryCTAButton(title: label) { apply(.advance, from: progress) }
                .disabled(model.saveError != nil)
                .accessibilityIdentifier("unit-b-next")
        }
    }

    private func apply(_ action: UnitBAction, from progress: UnitBProgress) {
        guard let openingEpoch else { return }
        _ = model.applyUnitB(action, from: progress, expectedEpoch: openingEpoch)
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
