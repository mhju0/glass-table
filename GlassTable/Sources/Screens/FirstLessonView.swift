// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// Learn five hand comparisons, then the actions on a turn.
/// The broader pot, blinds and street sequence stays available as optional depth.
struct FirstLessonView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.learningLanguage) private var language
    @Environment(ProgressionModel.self) private var model
    enum Context { case firstRun, resume, replay }
    private enum Step: Hashable {
        case welcome, teachPair, pot, blinds, actions, flow, bestFive
        case example, exampleAnswer, transfer, transferAnswer, wrapUp
        case comparison(Int), comparisonAnswer(Int)
    }

    let context: Context
    let onFinish: () -> Void
    let onSkip: () -> Void

    @State private var step: Step = .welcome
    @State private var answer: Int?
    @State private var pulse = false
    @State private var history: [Step] = []
    @State private var returning = false
    @State private var submitted: [Step: Int] = [:]
    @State private var helped: Set<Step> = []
    @State private var comparisonVersion = FirstLesson.currentComparisonVersion
    @State private var variationSeed: UInt64 = 0
    @State private var rotationLoaded = false
    @State private var openingEpoch: UUID?
    @State private var pendingTransition: (step: Step, response: FirstLessonSnapshot.Response?)?
    @State private var pendingStop = false

    private var requiredComparisons: [FirstLesson.Comparison] { FirstLesson.requiredComparisons(seed: variationSeed, version: comparisonVersion) }
    private var exampleSpot: ShowdownSpot { requiredComparisons[0].spot }
    private var transferSpot: ShowdownSpot { requiredComparisons[1].spot }
    private var comparisons: [ShowdownSpot] { Array(requiredComparisons.dropFirst(2)).map(\.spot) }

    init(context: Context, startsAtExample: Bool = false, onFinish: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.context = context
        self.onFinish = onFinish
        self.onSkip = onSkip
        _step = State(initialValue: startsAtExample || context != .firstRun ? .teachPair : .welcome)
    }

    private func copy(_ key: FirstLessonCopy.Key) -> String {
        FirstLessonCopy.text(key, in: language)
    }

    var body: some View {
        VStack(spacing: 0) {
            // The brand screen has no bar; its Skip sits under Start.
            if step == .welcome { Color.clear.frame(height: 44) }
            else { header.dynamicTypeSize(...DynamicTypeSize.accessibility1) }
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: GT.Space.section) {
                            content
                            if dynamicTypeSize.isAccessibilitySize, step != .welcome {
                                ActionSheet(band: panelBand) { panel }
                            }
                        }
                            .padding(.horizontal, 18).padding(.vertical, 12)
                            .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: step == .welcome ? .center : .top)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    // Every answer includes a reveal, including the neutral demonstration.
                    .onChange(of: step) { _, nextStep in
                        guard responseIndex(nextStep) != nil else { return }
                        withAnimation(reduceMotion ? nil : GT.Motion.change) {
                            proxy.scrollTo(Self.resultEnd, anchor: .bottom)
                        }
                    }
                }
            }
            if step == .welcome {
                brandStart
            } else if !dynamicTypeSize.isAccessibilitySize {
                ActionSheet(band: panelBand) {
                    VStack(alignment: .leading, spacing: GT.Space.related) { panel }
                }
                .layoutPriority(1)
            }
        }
        .disabled(model.saveError != nil)
        .background {
            if step == .welcome { Color(hex: 0x153D33).ignoresSafeArea() }
            else { FeltBackground() }
        }
        .modifier(ProgressSaveNotice())
        .onChange(of: model.saveError) { previous, current in
            if previous != nil, current == nil { continueAfterRetry() }
        }
        .onChange(of: model.epoch) { _, _ in
            pendingTransition = nil
            pendingStop = false
        }
        .onDisappear { model.isShowingBrandWelcome = false }
        .onChange(of: step) { old, next in
            model.isShowingBrandWelcome = next == .welcome
            if returning { returning = false }
            else if old != .welcome { history.append(old) }
        }
        .overlay(alignment: .leading) {
            Color.clear.frame(width: 28)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 45).onEnded { gesture in
                    if gesture.translation.width > 80,
                       abs(gesture.translation.height) < 70 { previous() }
                })
                .allowsHitTesting(!history.isEmpty)
                .accessibilityHidden(true)
        }
        .onAppear {
            if !rotationLoaded {
                openingEpoch = model.epoch
                if context != .replay, let saved = model.state.pendingFirstLesson {
                    restore(saved)
                } else {
                    variationSeed = GuideExampleRotation.next("firstLesson")
                    if context != .replay {
                        _ = model.beginFirstLesson(seed: variationSeed, expectedEpoch: model.epoch)
                    }
                }
                rotationLoaded = true
            }
            #if DEBUG
            switch ProcessInfo.processInfo.environment["GT_DEMO_FIRST_LESSON"] {
            case "pot": step = .pot
            case "blinds": step = .blinds
            case "actions": step = .actions
            case "flow": step = .flow
            case "best": step = .bestFive
            case "wrap-up": step = .wrapUp
            case "teach-pair": step = .teachPair
            case "checkpoint", "preference": step = .comparison(0)
            case "example-help": answer = nil; helped.insert(.exampleAnswer); step = .exampleAnswer
            case "example": step = .example
            case "example-answer": answer = 0; step = .exampleAnswer
            case "example-wrong": answer = 1; step = .exampleAnswer
            case "transfer": step = .transfer
            case "transfer-answer": answer = 1; step = .transferAnswer
            default:
                let capture = ProcessInfo.processInfo.environment["GT_DEMO_FIRST_LESSON"] ?? ""
                let answered = capture.hasPrefix("comparison-answer-")
                let prefix = answered ? "comparison-answer-" : "comparison-"
                if capture.hasPrefix(prefix), let index = Int(capture.dropFirst(prefix.count)), (0..<5).contains(index) {
                    variationSeed = 0
                    if answered { answer = requiredComparisons[index].spot.winner }
                    switch index {
                    case 0: step = answered ? .exampleAnswer : .example
                    case 1: step = answered ? .transferAnswer : .transfer
                    default: step = answered ? .comparisonAnswer(index - 2) : .comparison(index - 2)
                    }
                }
            }
            #endif
            model.isShowingBrandWelcome = step == .welcome
        }
    }

    // MARK: Header

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    headerTitle
                    headerAction.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .center) {
                    headerTitle
                    Spacer(minLength: 12)
                    headerAction
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
    }

    private func stop() {
        guard model.saveError == nil, context == .replay || openingEpoch == model.epoch else { return }
        pendingStop = context != .replay
        onSkip()
        if model.saveError == nil { pendingStop = false }
    }

    private func continueAfterRetry() {
        guard context != .replay, openingEpoch == model.epoch else { return }
        if pendingStop {
            pendingStop = false
            if model.state.openingDismissed == true { onSkip() }
        } else if let pendingTransition {
            if let saved = model.state.pendingFirstLesson,
               saved.variationSeed == variationSeed,
               saved.step == savedStep(pendingTransition.step),
               pendingTransition.response == nil || responseIndex(pendingTransition.step).map({ saved.responses[$0] == pendingTransition.response }) == true {
                self.pendingTransition = nil
                restore(saved)
            } else {
                self.pendingTransition = nil
                transition(to: pendingTransition.step, response: pendingTransition.response)
            }
        }
    }

    private func finish() {
        guard model.saveError == nil, context == .replay || openingEpoch == model.epoch else { return }
        onFinish()
    }

    private func previous() {
        guard let prior = history.last else { return }
        guard transition(to: prior) else { return }
        history.removeLast()
        returning = true
        answer = submitted[prior]
    }

    private func savedStep(_ value: Step) -> FirstLessonSnapshot.Step {
        switch value {
        case .welcome: .welcome
        case .teachPair: .teachPair
        case .example: .example
        case .exampleAnswer: .exampleAnswer
        case .transfer: .transfer
        case .transferAnswer: .transferAnswer
        case .comparison(0): .comparison0
        case .comparison(1): .comparison1
        case .comparison: .comparison2
        case .comparisonAnswer(0): .comparisonAnswer0
        case .comparisonAnswer(1): .comparisonAnswer1
        case .comparisonAnswer: .comparisonAnswer2
        case .actions: .actions
        case .wrapUp: .wrapUp
        case .pot: .pot
        case .blinds: .blinds
        case .flow: .flow
        case .bestFive: .bestFive
        }
    }

    private func localStep(_ value: FirstLessonSnapshot.Step) -> Step {
        switch value.rawValue {
        case "welcome": .teachPair
        case "teachPair": .teachPair
        case "example": .example
        case "exampleAnswer": .exampleAnswer
        case "transfer": .transfer
        case "transferAnswer": .transferAnswer
        case "checkpoint", "preference": .comparison(0)
        case "comparison0": .comparison(0)
        case "comparison1": .comparison(1)
        case "comparison2": .comparison(2)
        case "comparisonAnswer0": .comparisonAnswer(0)
        case "comparisonAnswer1": .comparisonAnswer(1)
        case "comparisonAnswer2": .comparisonAnswer(2)
        case "actions": .actions
        case "pot": .pot
        case "blinds": .blinds
        case "flow": .flow
        case "bestFive": .bestFive
        default: .wrapUp
        }
    }

    private func answerStep(_ index: Int) -> Step {
        switch index {
        case 0: .exampleAnswer
        case 1: .transferAnswer
        default: .comparisonAnswer(index - 2)
        }
    }

    private func responseIndex(_ value: Step) -> Int? {
        switch value {
        case .exampleAnswer: 0
        case .transferAnswer: 1
        case .comparisonAnswer(let index): index + 2
        default: nil
        }
    }

    private func restore(_ saved: FirstLessonSnapshot) {
        variationSeed = saved.variationSeed
        comparisonVersion = saved.comparisonVersion
        submitted = [:]
        helped = []
        returning = localStep(saved.step) != step
        step = localStep(saved.step)
        for (index, response) in saved.responses {
            let target = answerStep(index)
            switch response {
            case .choice(let choice): submitted[target] = choice
            case .demonstrated: helped.insert(target)
            }
        }
        answer = submitted[step]
        let route: [Step] = [.teachPair, .example, .exampleAnswer, .transfer, .transferAnswer,
                             .comparison(0), .comparisonAnswer(0), .comparison(1),
                             .comparisonAnswer(1), .comparison(2), .comparisonAnswer(2), .actions, .wrapUp]
        if let index = route.firstIndex(of: step) { history = Array(route.prefix(index)) }
        else {
            let optional: [Step] = [.wrapUp, .pot, .blinds, .flow, .bestFive]
            history = Array(route.dropLast()) + Array(optional.prefix { $0 != step })
        }
    }

    @discardableResult
    private func transition(to target: Step, response: FirstLessonSnapshot.Response? = nil) -> Bool {
        guard model.saveError == nil else { return false }
        var responses: [Int: FirstLessonSnapshot.Response] = [:]
        for index in 0..<5 {
            let target = answerStep(index)
            if helped.contains(target) { responses[index] = .demonstrated }
            else if let value = submitted[target] { responses[index] = .choice(value) }
        }
        if let response, let index = responseIndex(target) { responses[index] = response }
        if context != .replay {
            guard let openingEpoch else { return false }
            if model.state.pendingFirstLesson == nil {
                guard model.beginFirstLesson(seed: variationSeed, expectedEpoch: openingEpoch) else {
                    pendingTransition = (target, response)
                    return false
                }
            }
            let snapshot = FirstLessonSnapshot(variationSeed: variationSeed, step: savedStep(target), responses: responses, comparisonVersion: comparisonVersion)
            guard model.saveFirstLesson(snapshot, expectedEpoch: openingEpoch) else {
                pendingTransition = (target, response)
                return false
            }
        }
        pendingTransition = nil
        if let response {
            switch response {
            case .choice(let value): submitted[target] = value; helped.remove(target); answer = value
            case .demonstrated: submitted.removeValue(forKey: target); helped.insert(target); answer = nil
            }
        } else { answer = submitted[target] }
        step = target
        return true
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(copy(.title))
                .font(GT.title(22)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            if let progressText {
                Text(progressText)
                    .font(GT.body(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(progressSpoken ?? progressText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerAction: some View {
        ChromeTextButton(title: context == .firstRun ? copy(.skip) : copy(.close), action: stop)
            .accessibilityIdentifier(context == .firstRun ? "firstLesson.skip" : "firstLesson.close")
    }

    private func withPrevious(@ViewBuilder _ action: () -> some View) -> some View {
        GTStepRow(previous: history.isEmpty ? nil : previous, previousID: "firstLesson.previous",
                  action: action)
    }

    /// Optional table rules have their own count, separate from the warm-up.
    private var rulePage: Int? {
        switch step {
        case .pot: 1
        case .blinds: 2
        case .flow: 3
        case .bestFive: 4
        default: nil
        }
    }

    private var progressText: String? {
        switch step {
        case .welcome: return nil
        case .teachPair: return language.text("페어 알아보기", "Explore a pair")
        case .example, .exampleAnswer: return language.text("비교 1/5", "Comparison 1/5")
        case .transfer, .transferAnswer: return language.text("비교 2/5", "Comparison 2/5")
        case .comparison(let i), .comparisonAnswer(let i): return language.text("비교 \(i + 3)/5", "Comparison \(i + 3)/5")
        case .actions: return language.text("내 차례의 행동", "Actions on your turn")
        case .wrapUp: return language.text("안내 마치기", "Finish the guide")
        default: return rulePage.map { language.text("테이블 규칙 \($0)/4", "Table rules \($0)/4") }
        }
    }

    private var progressSpoken: String? {
        rulePage.map { language.text("추가 안내 4단계 중 \($0)단계", "Optional step \($0) of 4") }
    }

    // MARK: Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: welcome
        case .teachPair: teachPair
        case .pot: potPage
        case .blinds: blindsPage
        case .actions: actionsPage
        case .flow: flowPage
        case .bestFive: bestFivePage
        case .wrapUp: wrapUpPage
        case .example: question(spot: exampleSpot, guided: true)
        case .exampleAnswer: answerContent(spot: exampleSpot, guided: true)
        case .transfer: question(spot: transferSpot, guided: false)
        case .transferAnswer: answerContent(spot: transferSpot, guided: false)
        case .comparison(let i): question(spot: comparisons[i], guided: false)
        case .comparisonAnswer(let i): answerContent(spot: comparisons[i], guided: false)
        }
    }

    @ViewBuilder
    private var panel: some View {
        switch step {
        case .welcome:
            PrimaryCTAButton(title: copy(.startWelcome)) {
                transition(to: .teachPair)
            }
            .accessibilityIdentifier("firstLesson.start")
        case .teachPair: nextButton { transition(to: .example) }
        case .pot: nextButton { transition(to: .blinds) }
        case .blinds: nextButton { transition(to: .flow) }
        case .actions: nextButton { transition(to: .wrapUp) }
        case .flow: nextButton { transition(to: .bestFive) }
        case .bestFive: nextButton { transition(to: .wrapUp) }
        case .wrapUp:
            withPrevious {
                PrimaryCTAButton(title: finishTitle, action: finish)
                    .accessibilityIdentifier("firstLesson.finish")
            }
        case .example: handChoices(exampleSpot)
        case .transfer: handChoices(transferSpot)
        case .exampleAnswer: nextComparisonButton(isTransfer: false)
        case .transferAnswer: nextComparisonButton(isTransfer: true)
        case .comparison(let i): handChoices(comparisons[i])
        case .comparisonAnswer: nextComparisonButton(isTransfer: true)
        }
    }

    /// Green after a right answer, red after a wrong one; the neutral glass otherwise.
    private var panelBand: GradeBand? {
        switch step {
        case _ where helped.contains(step): nil
        case .exampleAnswer: isCorrect(exampleSpot) ? .spotOn : .off
        case .transferAnswer: isCorrect(transferSpot) ? .spotOn : .off
        case .comparisonAnswer(let i): isCorrect(comparisons[i]) ? .spotOn : .off
        default: nil
        }
    }

    private func isCorrect(_ spot: ShowdownSpot) -> Bool { answer == spot.winner }

    private var brandStart: some View {
        VStack(spacing: 8) {
            Button { transition(to: .teachPair) } label: {
                Text(language.text("시작하기", "Start"))
                    .font(GT.semibold(GT.Typography.buttonSize))
                    .foregroundStyle(Color(hex: 0x241B0E))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 16).padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color(hex: 0xEDC17F), in: RoundedRectangle(cornerRadius: GT.Radius.control))
            }
            .buttonStyle(GTPress())
            .accessibilityIdentifier("firstLesson.start")
            Button(action: stop) {
                Text(language.text("홀덤을 이미 알아요 · 안내 건너뛰기",
                                   "I already know Hold'em · Skip the guide"))
                    .font(GT.semibold(15)).foregroundStyle(Color(hex: 0xC8D6D0))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 12).padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: GT.Radius.control)
                            .strokeBorder(Color(hex: 0xC8D6D0).opacity(0.35), lineWidth: 1)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(GTPress())
            .accessibilityIdentifier("firstLesson.skip")
        }
        .padding(.horizontal, GT.Space.screen).padding(.vertical, GT.Space.screen)
    }

    private var welcome: some View {
        VStack(spacing: 32) {
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(Color(hex: 0xC8D6D0), lineWidth: 1.5)
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Color(hex: 0x547A70), lineWidth: 1)
                        .padding(8)
                }
                .overlay {
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 44)).foregroundStyle(Color(hex: 0xF4F0E6))
                }
                .frame(width: 104, height: 146)
                .accessibilityHidden(true)
            Text("Glass Table")
                .font(GT.semibold(34)).foregroundStyle(Color(hex: 0xF4F0E6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("firstLesson.welcome")
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GT.Space.screen)
    }

    private var teachPair: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: GT.Space.section) { pairSignature }
                VStack(alignment: .leading, spacing: GT.Space.related) { pairSignature }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, GT.Space.related)
            .overlay(alignment: .bottom) { Rectangle().fill(GT.border).frame(height: 1) }
            intro(language.text("같은 숫자 두 장이 페어예요", "Two matching ranks make a pair"),
                  language.text("페어는 한 쌍이 없는 패보다 강해요. 다음에는 두 패를 직접 비교해 봐요.",
                                "A pair beats a hand with no pair. Next, compare two hands yourself."), identifier: "firstLesson.teachPair.heading")
            Text(language.text("A, K, Q, J도 같은 글자 두 장이면 페어예요.",
                               "A, K, Q and J count too: two matching letters make a pair."))
                .font(GT.body(17)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("firstLesson.teachPair.letters")
        }
    }

    @ViewBuilder
    private var pairSignature: some View {
        CardRow(cards: [Card(rank: 14, suit: 0), Card(rank: 14, suit: 1)])
        Text(language.text("페어", "A pair"))
            .font(GT.semibold(24)).foregroundStyle(GT.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Rule screens

    private func intro(_ title: String, _ body: String, identifier: String = "") -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Group {
                switch identifier {
                case "firstLesson.teachPair.heading":
                    LessonPairedText(korean: ["같은 숫자나 글자", "두 장이면 페어예요"], english: ["Two matching numbers", "or letters make a pair"])
                default: Text(title).fixedSize(horizontal: false, vertical: true)
                }
            }
                .accessibilityIdentifier(identifier)
                .font(GT.title(28)).foregroundStyle(GT.onFelt)
                .accessibilityAddTraits(.isHeader)
            Text(body).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier.replacingOccurrences(of: ".heading", with: ".body"))
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
        }
    }

    private var potPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("포커는 팟을 가져가는 게임이에요", "Poker is about winning the pot"),
                  language.text("매 판 가운데 모이는 칩을 팟이라고 해요. 팟을 가져가는 방법은 두 가지예요.",
                                "The chips in the middle of each hand are the pot. There are two ways to win it."))
            VStack(alignment: .leading, spacing: 16) {
                numberedRow(1, title: language.text("모두 폴드시키기", "Everyone else folds"),
                            detail: language.text("다른 사람이 모두 카드를 내려놓으면(폴드) 카드를 보여주지 않고 이겨요.",
                                                  "If everyone else gives up their cards (folds), you win without showing yours."))
                numberedRow(2, title: language.text("끝까지 가서 비교하기", "Best hand at the end"),
                            detail: language.text("마지막까지 남은 사람끼리 패를 보여주고, 더 좋은 패가 이겨요.",
                                                  "Players still in at the end show their hands, and the better hand wins."))
            }
            .gtInset(GT.Space.card, firstText: .title(16)).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private func numberedRow(_ number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(GT.title(15).monospacedDigit()).foregroundStyle(GT.green)
                .frame(minWidth: 20, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(GT.title(16)).foregroundStyle(GT.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var blindsPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("블라인드를 내고 카드 2장을 받아요", "Blinds go in, then two cards each"),
                  language.text("카드를 받기 전에 두 사람이 1칩, 2칩을 먼저 내요. 그래서 팟은 처음부터 비어 있지 않아요.",
                                "Before the deal, two players put in 1 chip and 2 chips, so the pot is never empty."))
            VStack(spacing: GT.Space.section) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { blindTokens }
                    VStack(spacing: 10) { blindTokens }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(language.text("작은 블라인드 1칩, 큰 블라인드 2칩, 팟 3칩",
                                                  "Small blind 1 chip, big blind 2 chips, pot 3 chips"))
                Text(language.text("SB는 작은 블라인드, BB는 큰 블라인드예요.",
                                   "SB is the small blind; BB is the big blind."))
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 9) {
                    SectionLabel(text: copy(.heroCards))
                    CardRow(cards: HoldemBasics.hole)
                }
                .accessibilityElement(children: .contain)
            }
            .frame(maxWidth: .infinity)
            Text(language.text("내 카드 2장은 나만 봐요. 다른 사람도 각자 2장씩 받아요.",
                               "Only you see your two cards. Everyone else gets two of their own."))
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var blindTokens: some View {
        chipToken("SB", language.text("1칩", "1 chip"))
        chipToken("BB", language.text("2칩", "2 chips"))
        Image(systemName: "arrow.right")
            .font(.system(size: 15, weight: .semibold)).foregroundStyle(GT.onFeltSecondary)
            .rotationEffect(dynamicTypeSize.isAccessibilitySize ? .degrees(90) : .zero)
        chipToken(language.text("팟", "Pot"), language.text("3칩", "3 chips"), filled: true)
    }

    private func chipToken(_ name: String, _ amount: String, filled: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text(name).font(GT.title(16))
            Text(amount).font(GT.body(13).monospacedDigit())
        }
        .foregroundStyle(filled ? GT.onCTA : GT.onFelt)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .frame(minWidth: 72)
        .background(filled ? AnyShapeStyle(GT.cta) : AnyShapeStyle(Color.clear),
                    in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                .strokeBorder(filled ? Color.clear : GT.border, lineWidth: 1)
        }
    }

    private var actionsPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("내 차례엔 넷 중 하나를 골라요", "On your turn, pick one of four"),
                  language.text("행동은 한 사람씩 돌아가며 해요.", "Players act one at a time, in turn."))
            VStack(spacing: 0) {
                let rows = [
                    (language.text("폴드", "Fold"),
                     language.text("카드를 내려놓고 이번 판을 포기해요.", "Give up your cards and this hand.")),
                    (language.text("체크", "Check"),
                     language.text("아무도 걸지 않았으면, 칩을 내지 않고 넘겨요.", "If no one has bet, pass without adding chips.")),
                    (language.text("콜", "Call"),
                     language.text("앞사람이 건 만큼 똑같이 내요.", "Match the chips someone has bet.")),
                    (language.text("벳 · 레이즈", "Bet · Raise"),
                     language.text("먼저 걸거나, 이미 건 금액을 올려요.", "Put chips in first, or raise a bet already made.")),
                ]
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    actionRow(row.0, row.1)
                    if index < rows.count - 1 { Rectangle().fill(GT.border).frame(height: 1) }
                }
            }
            .padding(.horizontal, GT.Space.card)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    @ViewBuilder
    private func actionRow(_ name: String, _ detail: String) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 3) { actionRowContent(name, detail) }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) { actionRowContent(name, detail) }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func actionRowContent(_ name: String, _ detail: String) -> some View {
        Text(name).font(GT.title(16)).foregroundStyle(GT.ink)
            .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 86, alignment: .leading)
        Text(detail).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            .lineSpacing(GT.Typography.bodyLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The whole hand on one screen: each street's cards, then its betting round.
    private var flowPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("카드가 나올 때마다 베팅해요", "A round of betting after each deal"),
                  language.text("공용 카드 5장은 세 번에 나눠 펼쳐요. 펼칠 때마다 한 바퀴씩 베팅하고, 폴드하지 않은 사람만 다음으로 가요.",
                                "The five shared cards arrive in three steps. Each step gets a round of betting, and only players who haven't folded go on."))
            VStack(spacing: 0) {
                let board = HoldemBasics.board
                let streets: [(String, String, [Card])] = [
                    (language.text("프리플랍", "Preflop"), language.text("내 카드 2장만 보고", "Your two cards only"), HoldemBasics.hole),
                    (language.text("플랍", "Flop"), language.text("공용 카드 3장", "Three shared cards"), Array(board[0..<3])),
                    (language.text("턴", "Turn"), language.text("공용 카드 1장 더", "One more shared card"), [board[3]]),
                    (language.text("리버", "River"), language.text("마지막 공용 카드", "The last shared card"), [board[4]]),
                ]
                ForEach(Array(streets.enumerated()), id: \.offset) { _, street in
                    streetRow(street.0, street.1, cards: street.2)
                    Rectangle().fill(GT.border).frame(height: 1)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text("쇼다운", "Showdown")).font(GT.title(16)).foregroundStyle(GT.ink)
                    Text(language.text("남은 사람끼리 패를 비교해요", "Players still in compare hands"))
                        .font(GT.body(13.5)).foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, GT.Space.card)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private func streetRow(_ name: String, _ detail: String, cards: [Card]) -> some View {
        let label = VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(name).font(GT.title(16)).foregroundStyle(GT.ink)
                Text(language.text("→ 베팅", "→ betting"))
                    .font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .overlay(Capsule().strokeBorder(GT.border, lineWidth: 1))
            }
            Text(detail).font(GT.body(13.5)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        let row = HStack(spacing: 4) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                PlayingCardView(card: card, size: 40)
            }
        }
        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) { label; row }
            } else {
                HStack(spacing: 10) { label; Spacer(minLength: 6); row }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([name, detail, cards.map { $0.spoken(in: language) }.joined(separator: ", "),
                             language.text("베팅", "betting")].joined(separator: ", "))
    }

    private var bestFivePage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("7장 중 가장 좋은 5장만 세요", "Only your best five of seven count"),
                  language.text("내 카드 2장과 공용 카드 5장, 모두 7장이에요. 이 중 가장 좋은 5장으로만 겨루고, 나머지 2장은 쓰지 않아요.",
                                "Your two cards plus five shared cards make seven. Only the best five compete; the other two don't count."))
            VStack(alignment: .center, spacing: 12) {
                VStack(spacing: 9) {
                    sevenCards(hole: HoldemBasics.hole, board: HoldemBasics.board, size: 54)
                    if dynamicTypeSize.isAccessibilitySize {
                        // The fixed-width captions would break words at these sizes.
                        Text(language.text("앞의 2장이 내 카드예요.", "The first two are yours."))
                            .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityHidden(true)
                    } else {
                        sevenCardCaptions(size: 54)
                    }
                }
                Text(DrillTerms.hand(HoldemBasics.bestBrief, in: language))
                    .font(GT.title(20)).foregroundStyle(GT.onFelt)
                    .accessibilityIdentifier("firstLesson.bestHand")
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                Text(language.text("테두리가 있는 5장만 이 패에 들어가요. 흐린 2장은 이번에 쓰지 않아요.",
                                   "Only the five outlined cards make this hand. The two faded cards don't play."))
                Text(language.text("내 카드는 2장, 1장, 또는 하나도 안 써도 돼요.",
                                   "Your hand may use both of your cards, one, or neither."))
                Text(language.text("두 사람의 가장 좋은 5장이 같으면 팟을 나눠요.",
                                   "If both best fives are equal, the pot is split."))
                    .accessibilityIdentifier("firstLesson.splitPot")
            }
            .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.ink)
            .lineSpacing(GT.Typography.explanationLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .gtInset(GT.Space.card, firstText: .body(16)).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private var wrapUpPage: some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            intro(language.text("다섯 가지 비교를 해 봤어요", "You tried five hand comparisons"),
                  language.text("레슨에서는 풀이를 보고 다른 상황을 내 속도로 풀어요. 도움은 언제든 볼 수 있어요. 나중에 다시 복습해요.",
                                "Watch the reasoning, then try a new situation at your own pace. Help stays available, and you can return to review."))
            VStack(alignment: .leading, spacing: 14) {
                checkRow(language.text("같은 족보라면 높은 숫자부터 비교", "Compare ranks when hand types match"))
                checkRow(language.text("내 차례에 할 수 있는 행동", "The actions on your turn"))
                SecondaryCTAButton(title: language.text("한 판의 흐름 더 보기", "Explore how a hand runs")) { transition(to: .pot) }
                    .accessibilityIdentifier("firstLesson.moreRules")
            }
            .gtInset(GT.Space.card, firstText: .semibold(15)).frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
            if opensBasics {
                Text(language.text("다음은 족보예요. 어떤 5장이 더 강한지 알아봐요.",
                                   "Next: hand ranks, and which five beats which."))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(copy(.responsibleNote))
                .font(GT.body(13)).foregroundStyle(GT.onFeltMuted)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("wrapUp-responsible")
        }
    }

    private func checkRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold)).foregroundStyle(GT.green)
                .accessibilityHidden(true)
            Text(text).font(GT.semibold(15)).foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The first run goes on to the hand-ranks lesson unless it is already done.
    private var opensBasics: Bool {
        context != .replay && model.state.basicsLessonCompleted != true
    }

    private var finishTitle: String {
        if context == .replay { return copy(.returnToLearning) }
        return opensBasics ? language.text("족보 보기", "See the hand ranks") : copy(.beginCourse)
    }

    private func nextButton(_ action: @escaping () -> Void) -> some View {
        withPrevious {
            PrimaryCTAButton(title: language.text("다음", "Next"), action: action)
                .accessibilityIdentifier("firstLesson.next")
        }
    }

    private var comparisonRule: FirstLesson.Rule {
        switch step {
        case .example, .exampleAnswer: .pairOverHighCard
        case .transfer, .transferAnswer: .higherPair
        case .comparison(let i), .comparisonAnswer(let i): requiredComparisons[i + 2].rule
        default: .higherPair
        }
    }

    private var comparisonTitle: String {
        switch comparisonRule {
        case .pairOverHighCard: language.text("어느 쪽이 이길까요", "Which hand wins?")
        case .higherPair: language.text("두 페어를 비교해요", "Compare two pairs")
        case .trips: language.text("같은 숫자 세 장", "Three of one rank")
        case .straight: language.text("이어지는 숫자 다섯 장", "Five ranks in a row")
        case .flush: language.text("같은 무늬 다섯 장", "Five of one suit")
        }
    }

    private var comparisonRuleText: String {
        switch comparisonRule {
        case .pairOverHighCard:
            return language.text("숫자나 글자가 같은 두 장이 페어예요. 페어는 한 쌍이 없는 패보다 강해요.",
                                 "Two matching numbers or letters make a pair. A pair beats a hand with no pair.")
        case .higherPair:
            return language.text("둘 다 페어이면 높은 페어가 이겨요. A가 가장 높고, K, Q, J, 10, 9부터 2까지 차례로 낮아져요.",
                                 "When both hands have a pair, the higher pair wins. Ace is highest, then K, Q, J, 10, 9 and so on down to 2.")
        case .trips:
            return language.text("같은 숫자 3장이면 트리플이에요. 트리플은 원페어와 투페어보다 강해요.",
                                 "Three cards of one rank make three of a kind, or trips. Trips beat one pair and two pair.")
        case .straight:
            return language.text("숫자가 이어지는 5장이면 스트레이트예요. 스트레이트는 트리플보다 강해요.",
                                 "Five consecutive ranks make a straight. A straight beats trips.")
        case .flush:
            return language.text("같은 무늬 5장이면 플러시예요. 플러시는 스트레이트보다 강해요.",
                                 "Five cards of one suit make a flush. A flush beats a straight.")
        }
    }

    /// Side facts kept out of the rule above the question; shown after answering.
    private var comparisonSideFact: String? {
        switch comparisonRule {
        case .pairOverHighCard, .higherPair:
            return nil
        case .trips:
            return language.text("내 카드와 공용 카드를 함께 살펴보세요.",
                                 "Look at your cards together with the shared cards.")
        case .straight:
            return language.text("무늬는 달라도 돼요. A는 A·2·3·4·5에서 낮게도 쓰여요.",
                                 "The suits can differ. An ace can also be low in A, 2, 3, 4, 5.")
        case .flush:
            return language.text("숫자가 이어질 필요는 없어요. 7장 중 가장 좋은 5장을 찾아보세요.",
                                 "The ranks need not be consecutive. Find the best five of your seven cards.")
        }
    }

    private func question(spot: ShowdownSpot, guided: Bool) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            VStack(alignment: .leading, spacing: 7) {
                Text(comparisonTitle)
                    .accessibilityIdentifier("firstLesson.heading")
                    .font(GT.title(28)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(comparisonRuleText)
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("firstLesson.rule")
                // The offer to see the answer first is made once, on the first comparison.
                Text(step == .example
                     ? language.text("이길 패를 골라요. 설명부터 봐도 괜찮아요.",
                                     "Choose the winning hand, or see the explanation first.")
                     : language.text("이길 패를 골라요.", "Choose the winning hand."))
                    .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("firstLesson.question")
            }
            board(spot.board)

        }
    }

    private func board(_ cards: [Card]) -> some View {
        VStack(alignment: .center, spacing: 9) {
            SectionLabel(text: copy(.sharedCards))
            CardRow(cards: cards)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: Choosing

    private func handChoices(_ spot: ShowdownSpot) -> some View {
        VStack(spacing: 10) {
            handButton(title: copy(.heroCards), cards: spot.hero, answer: 0, spot: spot)
            handButton(title: copy(.villainCards), cards: spot.villain, answer: 1, spot: spot)
            withPrevious {
                SecondaryCTAButton(title: language.text("먼저 설명해 주세요", "Show me first")) {
                    let result = answerStepForCurrentQuestion
                    transition(to: result, response: .demonstrated)
                }.accessibilityIdentifier("firstLesson.help")
            }
        }
    }

    private var answerStepForCurrentQuestion: Step {
        switch step {
        case .example: .exampleAnswer
        case .comparison(let index): .comparisonAnswer(index)
        default: .transferAnswer
        }
    }

    private func handButton(title: String, cards: [Card], answer value: Int, spot: ShowdownSpot) -> some View {
        Button {
            let result = answerStepForCurrentQuestion
            if transition(to: result, response: .choice(value)) {
                AppFeedback.answer(correct: value == spot.winner)
                pulse = !reduceMotion
            }
        } label: {
            handLayout(label: handChoiceLabel(title), cards: cards)
                .gtInset(GT.Space.card, firstText: dynamicTypeSize.isAccessibilitySize ? .title(17) : nil).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
                .background(GT.surface,
                            in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                    .strokeBorder(GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress())
        .accessibilityIdentifier("firstLesson.choice.\(value)")
        .accessibilityLabel("\(title), \(spoken(cards))")
        .accessibilityHint(copy(.selectWinnerHint))
    }

    private func handChoiceLabel(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(GT.title(17)).foregroundStyle(GT.ink)
            Text(copy(.choiceHint))
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
        }
    }

    // MARK: Result

    private static var resultEnd: String { "first-lesson-result-end" }

    /// The question stays where it was; the two hands, now marked, are added below it.
    /// The explanation sits with the verdict in the sheet, as in every lesson.
    private func answerContent(spot: ShowdownSpot, guided: Bool) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.section) {
            question(spot: spot, guided: guided)
            VStack(spacing: 12) {
                resultHand(title: language.text("내 카드", "Your cards"), cards: spot.hero, value: 0, spot: spot)
                resultHand(title: copy(.villainCards), cards: spot.villain, value: 1, spot: spot)
            }
            verdict(spot: spot, isTransfer: !guided)
                .gtInset(GT.Space.card, firstText: .title(GT.Typography.resultSize))
                .gtCard(radius: GT.Radius.panel)
                .id(Self.resultEnd)
        }
    }

    /// The pick carries its verdict: green ✓ when right, red ✗ when wrong, and the
    /// winning hand is marked ✓ 정답 after a miss. Shape and words back the colour.
    private func resultHand(title: String, cards: [Card], value: Int, spot: ShowdownSpot) -> some View {
        // The row shows all seven with the five that play outlined, so the answer
        // reads as the rule it tests.
        let picked = answer == value
        let wins = spot.winner == value
        let mark: (text: String, spoken: String, band: GradeBand)? =
            helped.contains(step) ? nil : picked ? (copy(.myPick), wins ? copy(.pickCorrect) : copy(.pickWrong), wins ? .spotOn : .off)
                   : (wins ? (copy(.rightAnswer), copy(.rightAnswer), .spotOn) : nil)
        // At accessibility sizes the badge would cover the title, so it sits above it.
        let inline = dynamicTypeSize.isAccessibilitySize
        return VStack(alignment: .leading, spacing: 10) {
            if inline, let mark { markBadge(mark.text, band: mark.band) }
            resultLabel(title: title, hand: value == 0 ? spot.heroBest : spot.villainBest)
            sevenCards(hole: cards, board: spot.board, size: 44)
                .frame(maxWidth: .infinity)
        }
            .gtInset(GT.Space.card, firstText: inline && mark != nil ? .semibold(12) : .title(16)).frame(maxWidth: .infinity, alignment: .leading)
            .background(mark?.band.tint ?? GT.glass,
                        in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                    .strokeBorder(mark?.band.ink ?? GT.border, lineWidth: mark == nil ? 1 : 2.5)
            }
            .shadow(color: picked && pulse ? (mark?.band.ink ?? .clear).opacity(0.55) : .clear,
                    radius: picked && pulse ? 12 : 0)
            .overlay(alignment: .topTrailing) {
                if !inline, let mark { markBadge(mark.text, band: mark.band).offset(x: -12, y: -11) }
            }
            .padding(.top, mark == nil || inline ? 0 : 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([title, spoken(cards), DrillTerms.hand(value == 0 ? spot.heroBest : spot.villainBest, in: language), mark?.spoken]
                .compactMap { $0 }.joined(separator: ", "))
            .onAppear {
                guard picked, pulse else { return }
                withAnimation(.easeOut(duration: 1.2)) { pulse = false }
            }
    }

    private func markBadge(_ text: String, band: GradeBand) -> some View {
        Label(text, systemImage: band.glyph)
            .font(GT.semibold(12)).foregroundStyle(band.ink)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(GT.felt, in: Capsule())
            .overlay(Capsule().strokeBorder(band.ink, lineWidth: 1.5))
    }

    private func resultLabel(title: String, hand: HandBrief) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(GT.title(16)).foregroundStyle(GT.ink)
            Text(DrillTerms.hand(hand, in: language))
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
        }
    }

    private func verdict(spot: ShowdownSpot, isTransfer: Bool) -> some View {
        let usedHelp = helped.contains(step)
        let correct = isCorrect(spot)
        let band: GradeBand = correct ? .spotOn : .off
        let outcome = { (value: Int) in
            switch value {
            case 0: return language.text("내 카드 쪽이 이겨요", "Your hand wins")
            case 1: return language.text("상대 패가 이겨요", "Opponent wins")
            default: return language.text("무승부", "Tie")
            }
        }
        let headline = usedHelp ? language.text("함께 살펴볼게요", "Let’s look together") : correct ? copy(.correctTitle) + " · " + outcome(spot.winner) : copy(.retryTitle)
        let detail: String
        switch step {
        case .comparisonAnswer:
            detail = language.text("7장 중 가장 좋은 5장의 족보와 숫자를 비교해요.",
                                   "Compare the hand types and ranks of each best five.")
        default:
            detail = [comparisonRuleText, comparisonSideFact].compactMap { $0 }.joined(separator: " ")
        }
        return VStack(alignment: .leading, spacing: GT.Space.related) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: usedHelp ? "info.circle" : band.glyph)
                    .font(.system(size: 26, weight: .semibold)).foregroundStyle(usedHelp ? GT.inkSecondary : band.ink)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(headline)
                        .font(GT.title(GT.Typography.resultSize)).foregroundStyle(usedHelp ? GT.ink : band.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(GT.body(15)).foregroundStyle(GT.ink)
                        .lineSpacing(GT.Typography.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("firstLesson.verdict")
            comparisonReason(spot)
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.inkSecondary)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("firstLesson.reason")
        }
    }

    @ViewBuilder
    private func comparisonReason(_ spot: ShowdownSpot) -> some View {
        if spot.winner != 2, spot.heroBest != spot.villainBest {
            let winner = spot.winner == 0 ? spot.heroBest : spot.villainBest
            let loser = spot.winner == 0 ? spot.villainBest : spot.heroBest
            Text(language.text(
                "\(KO.subject(DrillTerms.hand(winner, in: .korean))) \(DrillTerms.hand(loser, in: .korean))보다 강해요.",
                "\(DrillTerms.hand(winner, in: .english)) beats \(DrillTerms.hand(loser, in: .english))."))
        } else {
            Text(gradeShowdown(answer: spot.winner, spot: spot, language: language).whyText)
        }
    }

    @ViewBuilder
    private func nextComparisonButton(isTransfer: Bool) -> some View {
        withPrevious {
            if isTransfer {
                PrimaryCTAButton(title: language.text("다음", "Next")) {
                    if case .comparisonAnswer(let i) = step {
                        transition(to: i < comparisons.count - 1 ? .comparison(i + 1) : .actions)
                    } else { transition(to: .comparison(0)) }
                }
                .accessibilityIdentifier("firstLesson.next")
            } else {
                PrimaryCTAButton(title: language.text("다음 비교", "Next comparison")) {
                    transition(to: .transfer)
                }
                .accessibilityIdentifier("firstLesson.next")
            }
        }
    }

    // MARK: Shared

    @ViewBuilder
    private func handLayout(label: some View, cards: [Card]) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                label
                CardRow(cards: cards)
            }
        } else {
            HStack(spacing: 14) {
                label
                Spacer(minLength: 6)
                CardRow(cards: cards)
            }
        }
    }

    private func spoken(_ cards: [Card]) -> String {
        cards.map { language == .korean ? $0.spokenKorean : $0.description }.joined(separator: ", ")
    }

    /// Seven cards, the five that play outlined; the rest step back but stay readable.
    /// The two private cards come first, set apart from the shared five.
    private func sevenCards(hole: [Card], board: [Card], size: CGFloat) -> some View {
        let seven = hole + board
        let best = bestFiveCards(seven)
        return HStack(spacing: 5) {
            ForEach(Array(seven.enumerated()), id: \.offset) { index, card in
                sevenCard(card, plays: best.contains(card), index: index, size: size)
            }
        }
    }

    private func sevenCard(_ card: Card, plays: Bool, index: Int, size: CGFloat) -> some View {
        let unused = plays ? "" : language.text(", 쓰지 않음", ", not used")
        return PlayingCardView(card: card, size: size)
            .overlay {
                if plays {
                    RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
                        .strokeBorder(GT.mint, lineWidth: 3)
                }
            }
            .opacity(plays ? 1 : 0.55)
            .padding(.leading, index == 2 ? 8 : 0)
            .accessibilityLabel(card.spoken(in: language) + unused)
    }

    private func sevenCardCaptions(size: CGFloat) -> some View {
        let cardWidth = size * 0.72
        return HStack(spacing: 0) {
            Text(language.text("내 카드", "Mine"))
                .frame(width: 2 * cardWidth + 5, alignment: .center)
            Spacer(minLength: 8)
            Text(language.text("공용 카드", "Shared"))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
        .frame(width: 7 * cardWidth + 6 * 5 + 8)
        .accessibilityHidden(true)
    }
}
