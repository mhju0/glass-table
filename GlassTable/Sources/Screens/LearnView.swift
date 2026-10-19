import SwiftUI
import GlassTableDrills

/// Learn is the lesson list (owner, 2026-10-17, variant A2): the tracks in path order,
/// every lesson a diagram, a title and one line on what it practises. One row is marked
/// in amber (`MarkedLesson`); passed rows get a green ✓ and a "연습" round.
struct LearnView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onOpenNode: (CurriculumNode) -> Void
    let onOpenReview: () -> Void
    /// Five questions on one skill, the round the practice screen runs.
    let onOpenPractice: (Concept) -> Void
    /// The practice screen's skill picker, the way on once every lesson is passed (D38).
    let onChoosePractice: () -> Void
    let onOpenBasics: () -> Void
    let onOpenGuidedHand: () -> Void
    var onResumeOpening: () -> Void = {}
    @State private var didScrollToMarkedRow = false
    /// A lesson opened ahead of the suggested order, awaiting the learner's choice.
    @State private var early: CurriculumNode?

    private var due: [Concept] { model.dueConcepts() }
    private var marked: MarkedLesson? { model.markedLesson }
    private var stacks: Bool { dynamicTypeSize.isAccessibilitySize }
    private static let basicsRowID = "learn-basics-row"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(language.text("배우기", "Learn")).font(GT.title(30))
                        .padding(.bottom, 12)
                    if let opening = model.state.pendingFirstLesson {
                        Button(action: onResumeOpening) {
                            learningRow(language.text("시작 안내 이어서 보기", "Continue the opening guide"),
                                        language.text("예시 \(opening.exploredCount)/5개를 살펴봤어요. 저장한 카드에서 이어가요.", "\(opening.exploredCount)/5 examples explored. Resume with your saved cards."), icon: "rectangle.stack")
                        }.buttonStyle(GTPress()).accessibilityIdentifier("learn-resume-opening")
                    }
                    reviewLine
                    if marked == nil { allDoneLine }
                    // A lesson kept from an older path has no row below, so its resume leads here.
                    if case .inProgress(let node)? = marked, Curriculum.track(containing: node) == nil {
                        lessonRow(node)
                    }
                    if case .basics? = marked { basicsRow }
                    ForEach(Curriculum.tracks.filter { !$0.isOptional }) { trackSection($0) }
                    sectionHeader(language.text("더 해보기", "More to try"), count: nil)
                    if marked != .basics { basicsRow }
                    guidedHandRow
                    ForEach(Curriculum.tracks.filter(\.isOptional)) { trackSection($0) }
                }
                .padding(18)
            }
            .gtTabBarClearance()
            .background(FeltBackground())
            .onAppear { scrollToMarkedRowOnce(using: proxy) }
        }
        .confirmationDialog(language.text("앞 레슨부터 해 볼까요?", "Start with an earlier lesson?"),
                            isPresented: Binding(get: { early != nil }, set: { if !$0 { early = nil } }),
                            titleVisibility: .visible, presenting: early) { node in
            if let first = Curriculum.unfinishedGroundwork(for: node, in: model.state).first {
                Button(language.text("‘\(learningNodeTitle(first, language: language))’부터",
                                     "Start with “\(learningNodeTitle(first, language: language))”")) { onOpenNode(first) }
            }
            Button(language.text("그래도 이 레슨 시작", "Open this lesson anyway")) { onOpenNode(node) }
            Button(language.text("취소", "Cancel"), role: .cancel) {}
        } message: { node in
            let count = Curriculum.unfinishedGroundwork(for: node, in: model.state).count
            Text(language.text("이 레슨은 앞의 레슨 \(count)개에서 배운 내용을 써요. 어느 쪽이든 고를 수 있어요.",
                               "This lesson uses ideas from \(count) earlier lessons. You can pick either way."))
        }
    }

    // MARK: Top

    /// One line, only when there is a review to start or to finish.
    @ViewBuilder private var reviewLine: some View {
        let open = model.state.activeReviewSession != nil
        if open || !due.isEmpty {
            let text = open ? language.text("↻ 복습 진행 중", "↻ Review in progress")
                : language.text("↻ 복습 \(due.count)개가 준비됐어요", "↻ \(due.count) reviews are ready")
            let action = open ? language.text("이어서", "Continue") : language.text("시작", "Start")
            Button(action: onOpenReview) {
                layoutStack(spacing: 10) {
                    Text(text).font(GT.semibold(15)).foregroundStyle(GT.onFelt)
                        .fixedSize(horizontal: false, vertical: true)
                    if !stacks { Spacer(minLength: 8) }
                    pill(action, filled: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) { Rectangle().fill(GT.border).frame(height: 1) }
                .contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(open ? language.text("복습 이어서", "Continue review")
                                     : "\(text.dropFirst(2)), \(action)")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("learn-review")
        }
    }

    /// Nothing left to mark: say so, and still lead somewhere (D38).
    private var allDoneLine: some View {
        Button(action: onChoosePractice) {
            layoutStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("모든 레슨을 마쳤어요", "You've passed every lesson"))
                        .font(GT.semibold(15)).foregroundStyle(GT.onFelt)
                    Text(language.text("궁금한 주제를 다시 연습하거나 복습이 생길 때 돌아와요.",
                                       "Practise a topic again, or come back when a review is ready."))
                        .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                if !stacks { Spacer(minLength: 8) }
                pill(language.text("연습", "Practice"), filled: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(GT.border).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityIdentifier("learn-all-done")
    }

    // MARK: Tracks

    private func trackSection(_ track: LearningTrack) -> some View {
        // Each lesson counts once per step (D53); a track without steps counts lessons.
        let steps = track.lessons.flatMap(Curriculum.lessonSteps(for:))
        let cleared = steps.filter { model.state.nodes[$0.id]?.cleared == true }.count
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(track.id.title(in: language), count: (cleared, steps.count),
                          countsSteps: steps.count > track.lessons.count)
            ForEach(track.lessons, id: \.id) { lessonRow($0) }
            if let challenge = track.challenge { challengeLine(challenge) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("track-\(track.id.rawValue)")
    }

    private func sectionHeader(_ title: String, count: (passed: Int, of: Int)?,
                               countsSteps: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(GT.title(17)).foregroundStyle(GT.onFelt)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let count {
                Text("\(count.passed)/\(count.of)")
                    .font(GT.semibold(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                    .accessibilityLabel(countsSteps
                        ? language.text("\(count.of)단계 중 \(count.passed)단계 통과",
                                        "\(count.passed) of \(count.of) steps passed")
                        : language.text("\(count.of)개 중 \(count.passed)개 통과",
                                        "\(count.passed) of \(count.of) passed"))
            }
        }
        .padding(.top, 22).padding(.bottom, 4)
    }

    private func lessonRow(_ node: CurriculumNode) -> some View {
        let concept = Curriculum.taughtConcept(of: node)
        let title = concept.map { skillNames($0, language: language).lead }
            ?? learningNodeTitle(node, language: language)
        let detail = concept.map { skillNames($0, language: language).tag + " · " + conceptBlurb($0, language: language) }
            ?? learningNodeDescription(node, language: language)
        let steps = Curriculum.lessonSteps(for: node)
        let passedSteps = steps.filter { model.state.nodes[$0.id]?.cleared == true }.count
        let target = rowTarget(node, steps: steps)
        return row(id: node.id, title: title, detail: detail,
                   passed: model.state.nodes[node.id]?.cleared == true,
                   best: bestLine(target), mark: mark(for: target), markedStep: target.level,
                   steps: steps.count > 1 ? (passedSteps, steps.count) : nil, practice: concept,
                   open: { open(target) }, buttonID: "lesson-\(node.id)") {
            if let concept { SkillGlyph(concept: concept) } else { tile("crown.fill") }
        }
    }

    /// The step a lesson's row opens: the marked one, else the first not passed, else
    /// the first step, to play again.
    private func rowTarget(_ node: CurriculumNode, steps: [CurriculumNode]) -> CurriculumNode {
        switch marked {
        case .inProgress(let open)? where open.baseID == node.id && open.kind == node.kind: return open
        case .next(let next)? where next.baseID == node.id && next.kind == node.kind: return next
        default: break
        }
        return steps.first { model.state.nodes[$0.id]?.cleared != true } ?? node
    }

    /// A challenge is optional, so it stays one quiet line unless it is the open lesson.
    @ViewBuilder private func challengeLine(_ challenge: CurriculumNode) -> some View {
        // Once passed, a challenge with a third step offers that step (D53).
        let sharp = Curriculum.stepNode(challenge, at: .sharp)
        let node = sharp.flatMap { step in
            model.state.nodes[challenge.id]?.cleared == true || mark(for: step) != nil ? step : nil
        } ?? challenge
        let title = learningNodeTitle(node, language: language, asChallenge: true)
        if let mark = mark(for: node) {
            row(id: challenge.id, title: title,
                detail: learningNodeDescription(node, language: language, asChallenge: true),
                passed: false, best: bestLine(node), mark: mark, markedStep: node.level,
                practice: nil, open: { open(node) },
                buttonID: "lesson-\(challenge.id)") {
                tile("crown.fill")
            }
        } else {
            let passed = model.state.nodes[node.id]?.cleared == true
            let optional = node.level > .learn
                ? language.text("선택 도전 · \(node.level.rawValue)단계", "Optional challenge · Step \(node.level.rawValue)")
                : language.text("선택 도전", "Optional challenge")
            let best = bestLine(node)
            Button { open(node) } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: passed ? "checkmark" : "crown.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(passed ? GT.green : GT.onFeltSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(title) · \(optional)").font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let best {
                            Text(best).font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([title, optional, passed ? language.text("통과", "Passed") : nil, best]
                .compactMap { $0 }.joined(separator: ", "))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("lesson-\(challenge.id)")
            .id(challenge.id)
        }
    }

    // MARK: More to try

    /// Ungraded and outside the tracks. A new player starts here, so it is listed first
    /// while it is the marked row.
    private var basicsRow: some View {
        let isMarked = marked == .basics
        return row(id: Self.basicsRowID, title: language.text("홀덤 기초", "Hold'em basics"),
                   detail: language.text("족보와 확인 문제", "Hand ranks and a quick check"),
                   passed: model.state.basicsLessonCompleted == true, best: nil,
                   mark: isMarked ? .basics : nil, practice: nil, open: onOpenBasics,
                   buttonID: "path-basics", actionID: "learn-basics-start") {
            tile("suit.spade.fill")
        }
    }

    private var guidedHandRow: some View {
        row(id: "learn-guided-hand-row", title: language.text("함께 한 판", "A hand together"),
            detail: language.text("블라인드부터 카드 공개까지 따라가요", "Follow a hand from blinds to showdown"),
            passed: false, best: nil, mark: nil, practice: nil, open: onOpenGuidedHand,
            buttonID: "learn-guided-hand") {
            tile("hand.draw")
        }
    }

    // MARK: Rows

    private enum RowMark {
        case inProgress, basics, next

        /// The step joins the tag above the first step: "다음 · 2단계" (D53).
        func tag(_ language: LearningLanguage, step: DrillLevel = .learn) -> String {
            let tag = switch self {
            case .inProgress: language.text("진행 중", "In progress")
            case .basics: language.text("여기서 시작", "Start here")
            case .next: language.text("다음", "Next")
            }
            guard step > .learn else { return tag }
            return tag + language.text(" · \(step.rawValue)단계", " · Step \(step.rawValue)")
        }

        func action(_ language: LearningLanguage) -> String {
            self == .inProgress ? language.text("이어서", "Continue") : language.text("시작", "Start")
        }

        var actionID: String { self == .inProgress ? "learn-continue" : "learn-start" }
    }

    private func mark(for node: CurriculumNode) -> RowMark? {
        switch marked {
        case .inProgress(let open)? where open == node: .inProgress
        case .next(let next)? where next == node: .next
        default: nil
        }
    }

    /// D47: tried but under the pass mark, with the best run so far.
    private func bestLine(_ node: CurriculumNode) -> String? {
        guard model.state.nodes[node.id]?.cleared != true else { return nil }
        return model.state.nodes[node.id]?.best.map {
            language.text("통과 전 · 최고 \($0.right)/\($0.questions)",
                          "Not passed · best \($0.right)/\($0.questions)")
        }
    }

    /// Diagram, title, description and status; then the row's one action. At the
    /// accessibility sizes everything stacks and the action spans the row.
    private func row<Glyph: View>(id: String, title: String, detail: String, passed: Bool,
                                  best: String?, mark: RowMark?, markedStep: DrillLevel = .learn,
                                  steps: (passed: Int, of: Int)? = nil, practice: Concept?,
                                  open: @escaping () -> Void, buttonID: String, actionID: String? = nil,
                                  @ViewBuilder glyph: () -> Glyph) -> some View {
        let round = practice.flatMap { concept in
            model.state.activeRound.map { $0.concept == concept.rawValue && $0.phase != .finished }
        } ?? false
        let practiceTitle = round ? language.text("연습 이어서", "Continue practice") : language.text("연습", "Practice")
        let showsPractice = mark == nil && practice != nil && (passed || round)
        let status = [mark?.tag(language, step: markedStep), best].compactMap { $0 }
        let stepsLabel = steps.map {
            language.text("\($0.of)단계 중 \($0.passed)단계 통과", "\($0.passed) of \($0.of) steps passed")
        }
        let label = [title, detail, passed ? language.text("통과", "Passed") : nil, stepsLabel].compactMap { $0 }
            + status
        let glyphView = glyph()
            .overlay(alignment: .topTrailing) {
                if passed {
                    Circle().fill(GT.green).frame(width: 18, height: 18)
                        .overlay(Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                            .foregroundStyle(GT.surface))
                        .offset(x: 5, y: -5)
                        .accessibilityHidden(true)
                }
            }
        let text = VStack(alignment: .leading, spacing: 2) {
            Text(title).font(GT.title(15)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail).font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
            if let steps { stepPips(steps) }
            if let mark {
                Text(mark.tag(language, step: markedStep)).font(GT.semibold(12)).foregroundStyle(GT.cta)
            }
            if let best {
                Text(best).font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
            }
        }
        let main = Button(action: open) {
            layoutStack(spacing: stacks ? 8 : 12) {
                glyphView
                text
                if !stacks {
                    Spacer(minLength: 0)
                    if mark == nil, !showsPractice {
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GT.onFeltSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(buttonID)

        return layoutStack(spacing: 10) {
            main
            if let mark {
                Button(action: open) { pill(mark.action(language), filled: true) }
                    .buttonStyle(GTPress())
                    .accessibilityLabel("\(mark.action(language)), \(title)")
                    .accessibilityIdentifier(actionID ?? mark.actionID)
            } else if showsPractice, let practice {
                Button { onOpenPractice(practice) } label: { pill(practiceTitle, filled: false) }
                    .buttonStyle(GTPress())
                    .accessibilityLabel("\(practiceTitle), \(title)")
                    .accessibilityIdentifier("practice-\(practice.rawValue)")
            }
        }
        .padding(.vertical, mark == nil ? 10 : 8)
        .padding(.horizontal, mark == nil ? 0 : 8)
        .background {
            if mark != nil {
                let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                // The same inset amber outline as a deciding card: drawn inside the shape.
                shape.fill(GT.glass).overlay(shape.strokeBorder(GT.cta, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, mark == nil ? 0 : -8)
        .padding(.vertical, mark == nil ? 0 : 2)
        .overlay(alignment: .bottom) {
            if mark == nil {
                Rectangle().fill(GT.border).frame(height: 1).padding(.leading, stacks ? 0 : 76)
            }
        }
        .accessibilityElement(children: .contain)
        .id(id)
    }

    /// One dot per step, filled once passed (D53). Read out in the row's label.
    private func stepPips(_ steps: (passed: Int, of: Int)) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<steps.of, id: \.self) { step in
                Circle()
                    .fill(step < steps.passed ? GT.green : Color.clear)
                    .overlay(Circle().strokeBorder(step < steps.passed ? GT.green : GT.onFeltSecondary,
                                                   lineWidth: 1))
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.top, 3)
        .accessibilityHidden(true)
    }

    /// A stack across the row, or down it at the accessibility sizes.
    private func layoutStack<Content: View>(spacing: CGFloat, @ViewBuilder _ content: () -> Content) -> some View {
        let layout = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
                            : AnyLayout(HStackLayout(alignment: .center, spacing: spacing))
        return layout(content)
    }

    /// The filled action belongs to the marked row only; everything else is outlined.
    private func pill(_ title: String, filled: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        return Text(title).font(GT.semibold(14))
            .foregroundStyle(filled ? GT.onCTA : GT.onFelt)
            .fixedSize(horizontal: !stacks, vertical: true)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .frame(maxWidth: stacks ? .infinity : nil, minHeight: 36)
            .background {
                if filled { shape.fill(GT.cta) }
                else { shape.fill(GT.surface).overlay(shape.strokeBorder(GT.border, lineWidth: 1)) }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }

    /// A diagram tile for the rows that teach no single skill.
    private func tile(_ symbol: String) -> some View {
        Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
            .foregroundStyle(GT.onFeltSecondary)
            .frame(width: 64, height: 48)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.tile, style: .continuous))
            .accessibilityHidden(true)
    }

    // MARK: Actions

    /// Every lesson stays open; one ahead of the suggested order asks first.
    private func open(_ node: CurriculumNode) {
        if model.state.nodes[node.id]?.cleared != true, mark(for: node) == nil,
           !Curriculum.unfinishedGroundwork(for: node, in: model.state).isEmpty {
            early = node
        } else {
            onOpenNode(node)
        }
    }

    private func scrollToMarkedRowOnce(using proxy: ScrollViewProxy) {
        guard !didScrollToMarkedRow, let marked else { return }
        didScrollToMarkedRow = true
        let id: String = switch marked {
        case .inProgress(let node), .next(let node): node.baseID
        case .basics: Self.basicsRowID
        }
        // Defer the one initial scroll until layout has produced the row; later
        // renders do not move the learner away from where they scrolled. The bottom
        // anchor moves only a row below the fold, so the review line stays in view.
        DispatchQueue.main.async { proxy.scrollTo(id, anchor: .bottom) }
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
                       asChallenge: Bool = false) -> String {
    if !asChallenge, let concept = Curriculum.taughtConcept(of: node) {
        return skillNames(concept, language: language).lead
    }
    return language.text("섞어서 확인하기", "Mixed practice")
}

func learningNodeDescription(_ node: CurriculumNode, language: LearningLanguage,
                             asChallenge: Bool = false) -> String {
    if !asChallenge, let concept = Curriculum.taughtConcept(of: node) {
        return ConceptIntroduction.make(concept, language: language).why
    }
    return language.text("여러 주제를 새로운 상황에서 함께 써 봐요.", "Use several skills in a new spot.")
}
