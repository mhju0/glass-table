// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// A compact table replay for pot counting. The middle never prints the aggregate
/// before commitment; the learner has to add the visible seat contributions.
struct PotMathReplayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language

    let spot: PotMathSpot
    @Binding var stepIndex: Int
    let showHelp: () -> Void

    @State private var flyingActor: PotMathSpot.Actor?
    @State private var chipReachedCenter = false

    private var steps: [PotMathReplayStep] { spot.replaySteps }
    private var visibleStepIndex: Int { min(max(0, stepIndex), steps.count - 1) }
    private var currentStep: PotMathReplayStep { steps[visibleStepIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(language.text("자리별로 낸 칩", "Chips paid by each seat"))
                    .font(GT.semibold(14))
                    .foregroundStyle(GT.inkSecondary)
                Spacer(minLength: 12)
                Button(language.text("계산 방법", "How to count"), action: showHelp)
                    .font(GT.semibold(14))
                    .foregroundStyle(GT.cta)
                    .frame(minHeight: 44)
            }

            if dynamicTypeSize.isAccessibilitySize || dynamicTypeSize >= .xxLarge {
                accessibleSeatList
            } else {
                table
            }

            replayControls
        }
        .onChange(of: stepIndex) { previous, next in
            guard next > previous, steps[next].addedChips > 0, !reduceMotion else {
                flyingActor = nil
                return
            }
            flyingActor = steps[next].actor
            chipReachedCenter = false
            withAnimation(.timingCurve(0.77, 0, 0.175, 1, duration: 0.22)) {
                chipReachedCenter = true
            }
        }
        .task(id: stepIndex) {
            guard flyingActor != nil else { return }
            do {
                try await Task.sleep(for: .milliseconds(220))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            flyingActor = nil
        }
    }

    private var table: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                RoundedRectangle(cornerRadius: 88, style: .continuous)
                    .fill(GT.tableFelt)
                    .overlay {
                        RoundedRectangle(cornerRadius: 88, style: .continuous)
                            .strokeBorder(GT.tableHairline, lineWidth: 3)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)

                Text(centerPrompt)
                    .font(GT.semibold(12))
                    .foregroundStyle(GT.onTableSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: size.width * 0.34)
                    .accessibilityIdentifier("pot-table-center-prompt")

                ForEach(spot.actors, id: \.self) { actor in
                    seat(actor)
                        .frame(width: size.width * 0.42)
                        .position(point(for: actor, in: size))
                }

                if let flyingActor {
                    Circle()
                        .fill(GT.tableAccent)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(GT.onTableAccent.opacity(0.45), lineWidth: 1))
                        .position(chipReachedCenter
                                  ? CGPoint(x: size.width / 2, y: size.height / 2)
                                  : point(for: flyingActor, in: size))
                        .opacity(chipReachedCenter ? 0.35 : 1)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: spot.participantCount == 3 ? 286 : 310)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pot-table-replay")
    }

    private var accessibleSeatList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(spot.actors, id: \.self) { actor in
                seat(actor)
            }
            if spot.participantCount == 4, visibleStepIndex == steps.count - 1 {
                Text(language.text("다음은 플레이어 B 차례예요", "Player B acts next"))
                    .font(GT.body(14))
                    .foregroundStyle(GT.onTableSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(GT.tableFelt,
                    in: RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
                .strokeBorder(GT.tableHairline, lineWidth: 2)
        }
        .accessibilityIdentifier("pot-table-replay")
    }

    private func seat(_ actor: PotMathSpot.Actor) -> some View {
        let isActive = currentStep.actor == actor
        let contributed = spot.contribution(of: actor, throughReplayStep: visibleStepIndex)
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(actorName(actor))
                    .font(GT.semibold(13))
                Spacer(minLength: 6)
                Text(language.text("낸 칩 \(contributed)", "Paid \(englishChips(contributed))"))
                    .font(GT.semibold(13).monospacedDigit())
            }
            .foregroundStyle(GT.onTable)

            Text(isActive ? caption(for: currentStep) : " ")
                .font(GT.body(12))
                .foregroundStyle(isActive ? GT.tableAccent : GT.onTableMuted)
                .modifier(PotCaptionLayout(accessibilitySize: dynamicTypeSize.isAccessibilitySize))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.tableFeltDeep,
                    in: RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                .strokeBorder(isActive ? GT.tableAccent : GT.tableHairline,
                              lineWidth: isActive ? 2 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.text("\(actor.rawValue), 낸 칩 \(contributed)칩",
                                          "\(actorName(actor)), paid \(englishChips(contributed))")
                            + (isActive ? ", \(caption(for: currentStep))" : ""))
    }

    private var replayControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == visibleStepIndex ? GT.cta : GT.borderStrong)
                        .frame(width: index == visibleStepIndex ? 18 : 7, height: 7)
                        .accessibilityHidden(true)
                }
            }

            HStack(spacing: 12) {
                replayButton(title: language.text("이전 행동", "Previous action"), symbol: "chevron.left",
                             enabled: visibleStepIndex > 0) {
                    stepIndex = visibleStepIndex - 1
                }
                replayButton(title: language.text("다음 행동", "Next action"), symbol: "chevron.right",
                             enabled: visibleStepIndex < steps.count - 1) {
                    stepIndex = visibleStepIndex + 1
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.text("행동 \(visibleStepIndex + 1) / \(steps.count)",
                                          "Action \(visibleStepIndex + 1) of \(steps.count)"))
    }

    private func replayButton(title: String, symbol: String, enabled: Bool,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(GT.semibold(14))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(enabled ? GT.ink : GT.inkMuted)
                .background(GT.surface,
                            in: RoundedRectangle(cornerRadius: GT.Radius.control,
                                                 style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
                        .strokeBorder(GT.borderStrong, lineWidth: 1)
                }
        }
        .buttonStyle(GTPress())
        .disabled(!enabled)
    }

    private var centerPrompt: String {
        if spot.participantCount == 4, visibleStepIndex == steps.count - 1 {
            return language.text("다음\n플레이어 B 차례", "Next\nPlayer B acts")
        }
        return language.text("행동 \(visibleStepIndex + 1) / \(steps.count)",
                             "Action \(visibleStepIndex + 1) / \(steps.count)")
    }

    private func caption(for step: PotMathReplayStep) -> String {
        switch step.kind {
        case .post: return language.text("\(step.addedChips)칩 먼저 내요", "Posts \(englishChips(step.addedChips))")
        case .bet: return language.text("\(step.addedChips)칩 벳해요", "Bets \(englishChips(step.addedChips))")
        case .call: return language.text("\(step.addedChips)칩 더 내요 · 콜", "Adds \(englishChips(step.addedChips)) to call")
        case let .raiseTo(total):
            return language.text("\(step.addedChips)칩 더 내요 · 총 \(total)칩으로 레이즈",
                                 "Adds \(step.addedChips), raising to \(total) chips total")
        case .fold: return language.text("폴드 · 이미 낸 칩은 남아요", "Folds · paid chips stay in the pot")
        }
    }

    private func englishChips(_ count: Int) -> String {
        "\(count) \(count == 1 ? "chip" : "chips")"
    }

    private func actorName(_ actor: PotMathSpot.Actor) -> String {
        switch actor {
        case .sb: return "SB"
        case .bb: return "BB"
        case .opener: return language.text("플레이어 A", "Player A")
        case .caller1: return language.text("플레이어 B", "Player B")
        case .caller2: return language.text("플레이어 C", "Player C")
        }
    }

    private func point(for actor: PotMathSpot.Actor, in size: CGSize) -> CGPoint {
        let normalized: CGPoint
        switch (spot.participantCount, actor) {
        case (_, .sb): normalized = CGPoint(x: 0.25, y: 0.22)
        case (_, .bb): normalized = CGPoint(x: 0.75, y: 0.22)
        case (3, .opener): normalized = CGPoint(x: 0.5, y: 0.79)
        case (_, .opener): normalized = CGPoint(x: 0.75, y: 0.78)
        case (_, .caller1): normalized = CGPoint(x: 0.25, y: 0.78)
        default: normalized = CGPoint(x: 0.5, y: 0.78)
        }
        return CGPoint(x: size.width * normalized.x, y: size.height * normalized.y)
    }
}

private struct PotCaptionLayout: ViewModifier {
    let accessibilitySize: Bool

    func body(content: Content) -> some View {
        if accessibilitySize {
            content.fixedSize(horizontal: false, vertical: true)
        } else {
            content
                .lineLimit(2)
                .frame(minHeight: 30, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PotMathIntroView: View {
    @Environment(\.learningLanguage) private var language
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.section) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.text("팟 계산", "Count the pot"))
                        .font(GT.title(30))
                        .foregroundStyle(GT.ink)
                    Text(language.text("테이블에 들어온 칩을 놓치지 않는 연습이에요.",
                                       "Practice tracking every chip in the pot."))
                        .font(GT.body(17))
                        .foregroundStyle(GT.inkSecondary)
                }

                introBlock(title: language.text("왜 배우나요?", "Why count?"),
                           body: language.text("팟을 알아야 콜 가격과 벳 크기를 비교해요.",
                                               "The pot lets you judge calls and bets."))
                introBlock(title: language.text("어떻게 푸나요?", "How do I count?"),
                           body: language.text("각 자리의 ‘낸 칩’을 한 번씩 더해요. ‘총 18칩으로 레이즈’는 전에 낸 칩까지 포함해요.",
                                               "Add each seat's paid chips once. 'Raise to 18 total' includes chips paid before."))
                introBlock(title: language.text("SB와 BB", "Small and big blinds"),
                           body: language.text("SB는 딜러 왼쪽 첫 자리, BB는 그 다음 자리예요. 카드를 받기 전에 1칩과 2칩을 먼저 내요.",
                                               "The small blind sits left of the dealer, the big blind next. They post 1 and 2 before the deal."))

                VStack(alignment: .leading, spacing: 6) {
                    Text(language.text("짧은 예", "A quick example"))
                        .font(GT.semibold(14))
                        .foregroundStyle(GT.inkSecondary)
                    Text(language.text("SB 1 + BB 2 + A 4 + B 4 = 11칩",
                                       "SB 1 + BB 2 + A 4 + B 4 = 11 chips"))
                        .font(GT.title(19).monospacedDigit())
                        .foregroundStyle(GT.ink)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GT.surface,
                            in: RoundedRectangle(cornerRadius: GT.Radius.panel,
                                                 style: .continuous))

                PrimaryCTAButton(title: language.text("문제 풀기", "Try a question"), action: onStart)
            }
            .padding(20)
        }
        .accessibilityIdentifier("pot-math-intro")
    }

    private func introBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(GT.title(18))
                .foregroundStyle(GT.ink)
            Text(body)
                .font(GT.body(16))
                .foregroundStyle(GT.inkSecondary)
                .lineSpacing(GT.Typography.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
