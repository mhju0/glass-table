// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct PairLessonView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.learningLanguage) private var language
    @AccessibilityFocusState(for: .voiceOver) private var focus: Focus?
    @State private var openingEpoch: UUID?

    private enum Focus: Hashable { case heading, feedback }
    private enum ScrollTarget: Hashable { case start, table }

    private let plannedCount = 11
    private let soloCount = 8
    private let passMark = 6

    var body: some View {
        Group {
            if let lesson = model.state.pairLesson {
                lessonPage(lesson)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { GT.felt.ignoresSafeArea() }
        .gtChrome(leading: {
            ChromeButton.close { dismiss() }
                .accessibilityIdentifier("pair-lesson-close")
        })
        .onAppear { openingEpoch = model.epoch }
        .onChange(of: model.epoch) { _, _ in dismiss() }
    }

    private func lessonPage(_ lesson: PairLessonProgress) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    progress(lesson)
                        .id(ScrollTarget.start)
                    if let question = lesson.currentQuestion {
                        questionContent(question, in: lesson)
                    } else if lesson.phase == .finished {
                        result(lesson)
                    }
                }
                .padding(.horizontal, GT.Space.edge)
                .padding(.vertical, GT.Space.related)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("pair-lesson-scroll")
            .onChange(of: phaseTitle(lesson)) { _, _ in
                proxy.scrollTo(ScrollTarget.start, anchor: .top)
                focus = .heading
            }
            .onChange(of: lesson.revealed) { _, revealed in
                guard revealed else { return }
                proxy.scrollTo(ScrollTarget.table, anchor: .top)
                focus = .feedback
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { actionDock(lesson) }
    }

    private func progress(_ lesson: PairLessonProgress) -> some View {
        let completed = lesson.completedActivities
        let current = lesson.revealed || completed == plannedCount ? -1 : completed
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            LessonProgressSegments(total: plannedCount, current: current,
                                   completed: Set(0..<completed))
            Text(phaseTitle(lesson))
                .font(GT.semibold(14).monospacedDigit())
                .foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityValue(language.text("\(plannedCount)단계 중 \(completed)단계 완료",
                                                  "\(completed) of \(plannedCount) lesson steps complete"))
                .accessibilityIdentifier("pair-lesson-phase")
        }
    }

    private func phaseTitle(_ lesson: PairLessonProgress) -> String {
        switch lesson.phase {
        case .example:
            language.text("풀이 예제", "Worked example")
        case .guided:
            language.text("안내 연습 \(lesson.guidedNumber) / 2", "Guided \(lesson.guidedNumber) of 2")
        case .solo:
            language.text("혼자 풀기 \(lesson.soloNumber) / \(soloCount)",
                          "Independent \(lesson.soloNumber) of \(soloCount)")
        case .retry:
            language.text("다시 풀기 \(lesson.retryNumber) / \(lesson.retryCount)",
                          "Correction \(lesson.retryNumber) of \(lesson.retryCount)")
        case .finished:
            language.text("원 페어 비교하기", "Compare one-pair hands")
        }
    }

    @ViewBuilder
    private func questionContent(_ question: PairLessonQuestion, in lesson: PairLessonProgress) -> some View {
        let example = lesson.phase == .example
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            if example {
                heading(language.text("원 페어 비교하기",
                                      textSize.isAccessibilitySize ? "Higher pair" : "Compare one-pair hands"))
                prose(language.text("같은 숫자나 글자 두 장이 페어예요.\n두 사람 모두 원 페어면 높은 페어가 이겨요.",
                                    textSize.isAccessibilitySize
                                    ? "A pair has two\nmatching ranks.\nThe higher pair\nwins the hand."
                                    : "Two cards of the same rank make a pair.\nIf both have one pair, the higher pair wins."))
            } else {
                heading(language.text("누가 더 높은 페어로 이길까요?", "Who wins with the higher pair?"))
                if lesson.phase == .guided && !lesson.revealed {
                    prose(language.text("각자 같은 숫자나 글자 두 장을 찾아 높은 쪽을 골라요.",
                                        "Find the matching ranks in each hand, then choose the higher one."))
                }
            }
        }
        table(question, showsPairs: example || lesson.revealed)
            .id(ScrollTarget.table)
        if example || lesson.revealed {
            evidence(question, in: lesson, example: example)
        } else {
            choices(lesson)
            if lesson.phase == .guided || lesson.phase == .solo { help(lesson) }
        }
    }

    private func table(_ question: PairLessonQuestion, showsPairs: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        let hands = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: GT.Space.related))
            : AnyLayout(HStackLayout(alignment: .top, spacing: GT.Space.related))
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            cards(language.text("공용 카드", "Shared cards"), question.board, marked: false)
                .accessibilityIdentifier("pair-lesson-board")
            Rectangle().fill(GT.tableHairline).frame(height: 1).accessibilityHidden(true)
            hands {
                cards(sideTitle(.learner), question.learner, marked: showsPairs)
                    .accessibilityIdentifier("pair-lesson-learner-cards")
                cards(sideTitle(.opponent), question.opponent, marked: showsPairs)
                    .accessibilityIdentifier("pair-lesson-opponent-cards")
            }
        }
        .padding(GT.Space.related)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.tableFeltDeep, in: shape)
        .overlay(shape.strokeBorder(GT.tableHairline, lineWidth: 1))
    }

    private func cards(_ label: String, _ cards: [Card], marked: Bool) -> some View {
        let size: CGFloat = 60
        let pairName = cards.first.map { language.text("\(rankSymbol($0)) 페어", "Pair of \(rankName($0))") }
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(label)
                .font(GT.semibold(14))
                .foregroundStyle(GT.onTable)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: GT.Space.compact) {
                ForEach(cards, id: \.self) { card in
                    PlayingCardView(card: card, size: size)
                        .overlay {
                            if marked {
                                RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
                                    .strokeBorder(GT.diagramCardEdge, lineWidth: 3)
                                    .accessibilityHidden(true)
                            }
                        }
                }
            }
            if marked, let pairName {
                Text(pairName)
                    .font(GT.semibold(14))
                    .foregroundStyle(GT.tableAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue((cards.map { $0.spoken(in: language) } + [marked ? pairName : nil].compactMap { $0 })
            .joined(separator: ", "))
    }

    private func choices(_ lesson: PairLessonProgress) -> some View {
        let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: GT.Space.compact))
            : AnyLayout(HStackLayout(spacing: GT.Space.compact))
        return layout {
            choice(.learner, identifier: "pair-lesson-choose-learner", in: lesson)
            choice(.opponent, identifier: "pair-lesson-choose-opponent", in: lesson)
        }
        .disabled(model.saveError != nil)
    }

    private func choice(_ side: PairLessonSide, identifier: String, in lesson: PairLessonProgress) -> some View {
        let selected = lesson.selection == side
        return GTChoiceButton(title: sideTitle(side), selected: selected) {
            apply(.select(side), to: lesson)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func help(_ lesson: PairLessonProgress) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            if lesson.phase == .solo {
                prose(lesson.currentHelpUsed
                      ? language.text("이 문제에서 힌트를 열었어요.", "You used help on this hand.")
                      : language.text("힌트를 쓰면 맞혀도 혼자 풀기 점수에 들어가지 않아요.",
                                      "A correct answer with a hint earns no independent credit."),
                      secondary: true)
            }
            Button(lesson.hintVisible ? language.text("힌트 닫기", "Hide hint")
                   : language.text("힌트 보기", "Show hint")) {
                apply(.hint, to: lesson)
            }
            .buttonStyle(GTOutlinedAction())
            .disabled(model.saveError != nil)
            .accessibilityIdentifier("pair-lesson-hint")
            if lesson.hintVisible {
                prose(language.text("두 사람의 패에서 같은 숫자나 글자 두 장을 찾아요. 높은 순서는 A, K, Q, J, 10부터 2까지예요.",
                                    "Find two cards of the same rank for each player. The order starts A, K, Q, J, then 10 down to 2."))
                    .accessibilityIdentifier("pair-lesson-hint-content")
            }
        }
    }

    @ViewBuilder
    private func evidence(_ question: PairLessonQuestion, in lesson: PairLessonProgress, example: Bool) -> some View {
        if let yours = question.learner.first, let other = question.opponent.first {
            let learnerWon = question.winner == .learner
            let higher = learnerWon ? yours : other
            let lower = learnerWon ? other : yours
            let correct = lesson.selection == question.winner
            let line = language.text("\(KO.subject(rankSymbol(higher))) 더 높아요.",
                                     "A pair of \(rankName(higher)) beats a pair of \(rankName(lower)).")
            let winner = learnerWon ? language.text("내가 이겨요", "You win")
                : language.text("상대가 이겨요", "The opponent wins")
            let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
            VStack(alignment: .leading, spacing: GT.Space.compact) {
                Text(example ? winner : correct
                     ? language.text("맞았어요", "Correct") : language.text("틀렸어요", "Incorrect"))
                    .font(GT.title(22))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($focus, equals: .feedback)
                    .accessibilityIdentifier("pair-lesson-feedback")
                prose(example ? line : "\(winner).\n\(line)")
                    .accessibilityIdentifier("pair-lesson-explanation")
                if let selected = lesson.selection {
                    prose(language.text("고른 답 · \(sideTitle(selected))", "Your answer · \(sideTitle(selected))"),
                          secondary: true)
                        .accessibilityIdentifier("pair-lesson-submitted-choice")
                }
            }
            .padding(GT.Space.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(example || correct ? GT.supportFill : GT.retryFill, in: shape)
            .overlay(shape.strokeBorder(example || correct ? GT.supportEdge : GT.retryEdge, lineWidth: 1))
            .foregroundStyle(example || correct ? GT.supportInk : GT.retryInk)
        }
    }

    private func result(_ lesson: PairLessonProgress) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            heading(language.text("레슨 결과", "Lesson results"))
            resultCard(language.text("혼자 풀기 점수", "Independent score")) {
                Text(language.text("\(soloCount)개 중 \(lesson.firstRight)개 정답",
                                   "\(lesson.firstRight) of \(soloCount) correct"))
                    .font(GT.title(22).monospacedDigit())
                    .accessibilityIdentifier("pair-lesson-first-score")
                prose(lesson.passed
                      ? language.text("레슨 통과 · \(passMark)개 이상 정답", "Lesson passed · \(passMark) or more correct")
                      : language.text("\(passMark)개를 맞히면 통과예요.", "Get \(passMark) correct to pass."))
                if lesson.assistedSoloCount > 0 {
                    prose(language.text("힌트를 본 문제 \(lesson.assistedSoloCount)개",
                                        "Hints used on \(lesson.assistedSoloCount) of \(soloCount) hands"), secondary: true)
                        .accessibilityIdentifier("pair-lesson-assisted-count")
                }
            }
            resultCard(language.text("틀린 핸드 다시 풀기", "Corrections")) {
                prose(lesson.retryCount == 0
                      ? language.text("다시 풀 핸드가 없어요.", "No missed hands to retry.")
                      : language.text("\(lesson.retryCount)개 중 \(lesson.retryRight)개 정답",
                                      "\(lesson.retryRight) of \(lesson.retryCount) correct on the second try"))
                    .accessibilityIdentifier("pair-lesson-retry-score")
            }
            Button(language.text("새 카드로 다시 풀기", "Replay with new cards")) {
                guard let openingEpoch else { return }
                _ = model.restartPairLesson(from: lesson, expectedEpoch: openingEpoch)
            }
            .buttonStyle(GTOutlinedAction(fills: true))
            .disabled(model.saveError != nil)
            .accessibilityIdentifier("pair-lesson-replay")
        }
    }

    private func resultCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel)
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(title)
                .font(GT.semibold(16))
                .foregroundStyle(GT.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(GT.Space.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(GT.ink)
        .background(GT.glass, in: shape)
        .overlay(shape.strokeBorder(GT.borderStrong, lineWidth: 1))
    }

    private func actionDock(_ lesson: PairLessonProgress) -> some View {
        Group {
            if lesson.phase == .finished {
                PrimaryCTAButton(title: language.text("완료", "Done")) { dismiss() }
                    .accessibilityIdentifier("pair-lesson-done")
            } else if lesson.revealed || lesson.phase == .example {
                let label = lesson.phase == .example && !textSize.isAccessibilitySize
                    ? language.text("안내 연습 시작", "Start guided practice") : language.text("다음", "Next")
                PrimaryCTAButton(title: label) { apply(.advance, to: lesson) }
                    .disabled(model.saveError != nil)
                    .accessibilityIdentifier("pair-lesson-next")
            } else {
                PrimaryCTAButton(title: language.text("답 확인", "Check answer")) { apply(.submit, to: lesson) }
                    .disabled(lesson.selection == nil || model.saveError != nil)
                    .accessibilityIdentifier("pair-lesson-submit")
            }
        }
        .padding(.horizontal, GT.Space.edge)
        .padding(.vertical, GT.Space.compact)
        .frame(maxWidth: 580)
        .frame(maxWidth: .infinity)
        .background {
            GT.glass.ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) { Rectangle().fill(GT.border).frame(height: 1) }
        }
    }

    private func apply(_ action: PairLessonAction, to lesson: PairLessonProgress) {
        guard let openingEpoch else { return }
        _ = model.applyPairLesson(action, from: lesson, expectedEpoch: openingEpoch)
    }

    private func heading(_ title: String) -> some View {
        Text(title)
            .font(GT.title(26))
            .foregroundStyle(GT.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($focus, equals: .heading)
            .accessibilityIdentifier("pair-lesson-heading")
    }

    private func prose(_ text: String, secondary: Bool = false) -> some View {
        Text(text)
            .font(GT.body(16))
            .foregroundStyle(secondary ? GT.inkSecondary : GT.ink)
            .lineSpacing(GT.Typography.bodyLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func sideTitle(_ side: PairLessonSide) -> String {
        switch side {
        case .learner: language.text("내 카드", "My cards")
        case .opponent: language.text("상대 카드", "Opponent")
        }
    }

    private func rankSymbol(_ card: Card) -> String { String(card.display.dropLast()) }

    private func rankName(_ card: Card) -> String {
        ["twos", "threes", "fours", "fives", "sixes", "sevens", "eights", "nines",
         "tens", "jacks", "queens", "kings", "aces"][card.rank - 2]
    }
}
