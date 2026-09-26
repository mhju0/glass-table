// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// Pot counting on the shared table. Seats show who is acting and who folded, never
/// a running total: the learner adds the actions. The middle names the total only
/// once `revealedPot` is set, after the answer. `showsPaidTotals` is the help the
/// learner opts into: each seat shows what it has paid so far, and the question then
/// counts as practice with help.
struct PotMathReplayView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.learningLanguage) private var language

    let spot: PotMathSpot
    @Binding var stepIndex: Int
    var revealedPot: Int?
    var showsPaidTotals = false
    /// Offered only before the answer on graded questions; nil hides the control.
    var showTotals: (() -> Void)?
    let showHelp: () -> Void

    @State private var movingChip: (seatID: String, arrived: Bool)?

    private var steps: [PotMathReplayStep] { spot.replaySteps }
    private var visibleStepIndex: Int { min(max(0, stepIndex), steps.count - 1) }
    private var currentStep: PotMathReplayStep { steps[visibleStepIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Side by side the two help buttons break words at accessibility sizes.
            (dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .trailing, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 8))) {
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                if let showTotals, !showsPaidTotals {
                    helpButton(language.text("합계 보기", "Show totals"), symbol: "sum",
                               action: showTotals)
                        .accessibilityIdentifier("pot-show-totals")
                }
                helpButton(language.text("계산 방법", "How to count"),
                           symbol: "questionmark.circle", action: showHelp)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            TableSurface(seats: seats,
                         center: TableCenter(potTotal: revealedPot.map {
                             language.text("\($0)칩", englishChips($0))
                         }),
                         movingChip: movingChip)
                .accessibilityIdentifier("pot-table-replay")

            actionLine
            replayControls
        }
        .onChange(of: stepIndex) { previous, next in
            guard next > previous, steps[next].addedChips > 0, !reduceMotion else {
                movingChip = nil
                return
            }
            let seatID = steps[next].actor.rawValue
            movingChip = (seatID, false)
            withAnimation(.timingCurve(0.77, 0, 0.175, 1, duration: 0.22)) {
                movingChip = (seatID, true)
            }
        }
        .task(id: stepIndex) {
            guard movingChip != nil else { return }
            do {
                try await Task.sleep(for: .milliseconds(220))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            movingChip = nil
        }
    }

    private func helpButton(_ title: String, symbol: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(GT.semibold(14)).foregroundStyle(GT.ink)
                .padding(.horizontal, 14).frame(minHeight: 44)
                .background(GT.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(GT.borderStrong, lineWidth: 1))
        }
        .buttonStyle(GTPress())
    }

    private var seats: [TableSeat] {
        let others = spot.actors.filter { $0 != .sb && $0 != .bb }
        return spot.actors.map { actor in
            let place: TableSeat.Place
            switch actor {
            case .sb: place = .topLeading
            case .bb: place = .topTrailing
            default:
                // Clockwise after the blinds: the first non-blind sits bottom right,
                // or alone at the bottom in a three-player hand.
                let order = others.firstIndex(of: actor) ?? 0
                place = others.count == 1 ? .bottomCenter
                    : order == 0 ? .bottomTrailing : .bottomLeading
            }
            let shown = steps.prefix(visibleStepIndex + 1)
            let folded = shown.contains { $0.actor == actor && $0.kind == .fold }
            let paid = shown.filter { $0.actor == actor }.reduce(0) { $0 + $1.addedChips }
            let paidText = showsPaidTotals
                ? language.text("낸 칩 \(paid)", "Paid \(paid)") : nil
            let foldText = folded ? language.text("폴드", "Folded") : nil
            let status = [foldText, paidText].compactMap { $0 }.joined(separator: " · ")
            return TableSeat(id: actor.rawValue, place: place, name: actorName(actor),
                             status: status.isEmpty ? nil : status,
                             tone: .neutral,
                             isActive: currentStep.actor == actor,
                             isFolded: folded)
        }
    }

    /// One short description beside the table for the acting seat, in place of
    /// captions scattered over every seat.
    private var actionLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(language.text("행동 \(visibleStepIndex + 1)/\(steps.count)",
                               "Action \(visibleStepIndex + 1)/\(steps.count)"))
                .font(GT.body(14).monospacedDigit())
                .foregroundStyle(GT.inkSecondary)
                .fixedSize()
            Text("\(actorName(currentStep.actor)): \(caption(for: currentStep))")
                .font(GT.semibold(15))
                .foregroundStyle(GT.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("pot-active-action")
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
