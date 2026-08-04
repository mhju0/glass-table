// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// 기록 — mastery per concept plus calibration.
///
/// The hero number is **concepts at 능숙/숙달**, not XP and not streak (spec §4.3).
/// Streak is present but subordinate: it measures showing up, which is a precondition
/// for learning rather than evidence of it.
struct RecordsView: View {
    @Environment(ProgressionModel.self) private var model

    /// Only concepts the user has actually met. An untouched roster reads as a
    /// to-do list, which is the path's job, not this screen's.
    private var studied: [Concept] {
        Concept.allCases.filter { model.record(for: $0).total > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("기록").font(GT.title(24)).foregroundStyle(GT.onFelt)
                    .padding(.top, 14)
                headline
                calibrationCard
                evLossCard
                if studied.isEmpty { emptyState } else { conceptList }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 96)   // clears the floating tab bar
        }
        .background(FeltBackground())
    }

    private var headline: some View {
        HStack(spacing: 9) {
            stat("\(model.masteredCount)", "능숙 이상")
            stat("\(model.state.streak.current)", "연속 일수")
            stat("\(model.dueConcepts().count)", "오늘 복습")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(GT.title(22).monospacedDigit()).foregroundStyle(GT.ink)
            Text(label).font(GT.semibold(10)).foregroundStyle(GT.inkMuted)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .gtCard(radius: 15)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "캘리브레이션", onDark: false)
            if let rate = model.calibrationHitRate, let verdict = model.calibrationVerdict {
                Text("90% 구간이 정답을 담은 비율")
                    .font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int((rate * 100).rounded()))%")
                        .font(GT.title(24).monospacedDigit()).foregroundStyle(GT.ink)
                    Text("· 목표 90%").font(GT.semibold(11)).foregroundStyle(GT.inkMuted)
                }
                // The target sits as a mark on the track, so being under it is a
                // visible distance rather than a number to interpret.
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GT.surface).frame(height: 6)
                        Capsule().fill(GT.cta)
                            .frame(width: geo.size.width * rate, height: 6)
                        Rectangle().fill(GT.suitRed)
                            .frame(width: 2, height: 11)
                            .offset(x: geo.size.width * Calibration.nominalConfidence - 1)
                    }
                }
                .frame(height: 11)
                Text(verdictLine(verdict))
                    .font(GT.body(11.5)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("아웃 · 에퀴티 감각 · EV 계산에서 구간을 답하면 여기에 쌓여요")
                    .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: 18)
    }

    /// decisions.md §D asks for a rolling EV-loss-per-hand alongside accuracy. Shown
    /// only once there is one, because a 0.0bb average with no answers behind it would
    /// read as a perfect record.
    @ViewBuilder
    private var evLossCard: some View {
        if let mean = meanEVLoss(in: model.state) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "결정", onDark: false)
                Text("핸드당 버린 EV").font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(bbText(mean))bb")
                        .font(GT.title(24).monospacedDigit()).foregroundStyle(GT.ink)
                    Text("· 낮을수록 좋아요").font(GT.semibold(11)).foregroundStyle(GT.inkMuted)
                }
                Text(mean <= 0.5 ? "고를 때마다 거의 최선을 고르고 있어요."
                     : (mean <= 2 ? "큰 실수는 없지만 조금씩 새고 있어요."
                                  : "가끔 크게 버리고 있어요. 가격을 먼저 확인해 보세요."))
                    .font(GT.body(11.5)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: 18)
        }
    }

    private func verdictLine(_ v: Calibration.Verdict) -> String {
        switch v {
        case .overconfident:
            return "구간을 너무 좁게 잡고 있어요. 확신이 실제 실력보다 앞서 있어요."
        case .underconfident:
            return "구간이 넓어요. 조금 더 좁혀도 정답을 담을 수 있어요."
        case .calibrated:
            return "구간이 잘 맞고 있어요. 이 감각을 유지해요."
        }
    }

    private var emptyState: some View {
        Text("아직 기록이 없어요. 오늘 한 문제만 풀어도 여기부터 채워져요.")
            .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
            .padding(.top, 4)
    }

    private var conceptList: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "개념별").padding(.bottom, 8)
            VStack(spacing: 0) {
                ForEach(Array(studied.enumerated()), id: \.element) { i, concept in
                    row(concept)
                    if i != studied.count - 1 {
                        Rectangle().fill(GT.surface).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 14)
            .gtCard(radius: 18)
        }
    }

    private func row(_ concept: Concept) -> some View {
        let r = model.record(for: concept)
        let stuck = model.shouldOfferWalkthrough(concept)
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(conceptTitle(concept)).font(GT.title(13)).foregroundStyle(GT.ink)
                Text(subtitle(r, stuck: stuck))
                    .font(GT.body(10.5))
                    .foregroundStyle(stuck ? GT.suitRed : GT.inkMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            pips(r.tier)
        }
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(conceptTitle(concept)). \(tierWord(r.tier)). \(subtitle(r, stuck: stuck))")
    }

    private func subtitle(_ r: ConceptRecord, stuck: Bool) -> String {
        if stuck { return "\(r.consecutiveMisses)번 놓침 · 천천히 다시 보기" }
        let accuracy = Int((r.accuracy * 100).rounded())
        guard let due = r.review.due else { return "\(r.total)문제 · \(accuracy)%" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        let when = days <= 0 ? "지금 복습" : "\(days)일 후 복습"
        return "\(tierWord(r.tier)) · \(when)"
    }

    /// Four filled pips, so the tier survives greyscale and reads without the word.
    private func pips(_ tier: MasteryTier) -> some View {
        let filled = (MasteryTier.allCases.firstIndex(of: tier) ?? 0) + 1
        return HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filled ? GT.cta : GT.surface)
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }

    private func tierWord(_ t: MasteryTier) -> String {
        switch t {
        case .attempted:  return "시도"
        case .familiar:   return "익숙"
        case .proficient: return "능숙"
        case .mastered:   return "숙달"
        }
    }
}
