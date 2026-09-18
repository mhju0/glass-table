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
    @State private var replay: Concept?

    /// Only concepts the user has actually met. An untouched roster reads as a
    /// to-do list, which is the path's job, not this screen's.
    private var studied: [Concept] {
        Concept.allCases.filter { model.record(for: $0).total > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GT.Space.section) {
                Text("학습 기록").font(GT.title(30)).foregroundStyle(GT.onFelt)
                    .padding(.top, 14)
                headline
                Text("능숙·숙달은 앱 안에서 쌓인 학습 단계예요. 실제 포커 실력을 인증하지 않아요.")
                    .font(GT.body(12.5)).foregroundStyle(GT.onFeltSecondary)
                    .lineSpacing(GT.Typography.bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                calibrationCard
                evLossCard
                if studied.isEmpty { emptyState } else { conceptList }
            }
            .padding(.horizontal, 18)
        }
        .gtTabBarClearance()
        .background(FeltBackground())
        .onAppear {
            #if DEBUG
            if let raw = ProcessInfo.processInfo.environment["GT_DEMO_REPLAY"] {
                replay = Concept(rawValue: raw)
            }
            #endif
        }
        // Same replay the 오늘 stuck panel offers, so the subtitle's promise holds
        // wherever it appears. Seed rule mirrors TodayView's: progress-salted, off
        // free play's base, so the narrated answer never doubles as a review question.
        .sheet(item: $replay) { concept in
            let w = Walkthrough.make(concept: concept,
                                     seed: 0x7EAC &+ UInt64(model.record(for: concept).total),
                                     index: 0)
            NavigationStack {
                WalkthroughView(title: conceptTitle(concept), beats: w.beats, rows: w.rows,
                                onFinish: {
                                    model.completeWalkthrough(concept: concept)
                                    replay = nil
                                },
                                onSkip: { replay = nil })
            }
        }
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
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var calibrationCard: some View {
        let sampleCount = model.state.answers.filter { $0.interval != nil }.count
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "확신 점검", onDark: false)
            if let rate = model.calibrationHitRate {
                Text("정답이 내가 예상한 90% 범위에 들어온 비율")
                    .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int((rate * 100).rounded()))%")
                        .font(GT.title(28).monospacedDigit()).foregroundStyle(GT.ink)
                    Text("\(sampleCount)개 답변 · 기준 90%")
                        .font(GT.semibold(12)).foregroundStyle(GT.inkMuted)
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
                Text(calibrationDescription(count: sampleCount))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("아웃, 에퀴티 감각, EV 계산에서 예상 범위를 답하면 여기에 기록돼요.")
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.Radius.panel)
    }

    /// decisions.md §D asks for a rolling EV-loss-per-hand alongside accuracy. Shown
    /// only once there is one, because a 0.0bb average with no answers behind it would
    /// read as a perfect record.
    @ViewBuilder
    private var evLossCard: some View {
        if let mean = meanEVLoss(in: model.state) {
            let count = model.state.answers.filter { $0.evLoss != nil }.count
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "결정", onDark: false)
                Text("기록된 결정의 평균 EV 손실")
                    .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(bbText(mean))bb")
                        .font(GT.title(28).monospacedDigit()).foregroundStyle(GT.ink)
                    Text("\(count)개 결정 · 낮을수록 좋아요")
                        .font(GT.semibold(12)).foregroundStyle(GT.inkMuted)
                }
                Text("이 값은 공개된 체크다운 가정으로 채점한 연습 기록이에요.")
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private func calibrationDescription(count: Int) -> String {
        "지금까지 답한 \(count)개 문제의 결과예요. 표본이 적을 때는 이 수치만으로 실력을 판단하지 않아요."
    }

    private var emptyState: some View {
        Text("아직 기록이 없어요. 한 문제를 풀면 답변 수와 다음 복습 시점이 여기에 쌓여요.")
            .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
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
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func row(_ concept: Concept) -> some View {
        let r = model.record(for: concept)
        let stuck = model.shouldOfferWalkthrough(concept)
        let line = HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(conceptTitle(concept)).font(GT.title(16)).foregroundStyle(GT.onFelt)
                Text(subtitle(r, stuck: stuck))
                    .font(GT.body(12.5))
                    .foregroundStyle(stuck ? GTBand.offInk : GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            // The subtitle advertises 천천히 다시 보기, so a stuck row must be a door,
            // not a caption — the glyph marks the one row here that acts on a tap.
            if stuck {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 17)).foregroundStyle(GTBand.offInk)
            }
            pips(r.tier)
        }
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(conceptTitle(concept)). \(tierWord(r.tier)). \(subtitle(r, stuck: stuck))")

        if stuck {
            Button { replay = concept } label: { line.contentShape(Rectangle()) }
                .buttonStyle(GTPress())
                .accessibilityHint("천천히 다시 보기 열기")
        } else {
            line
        }
    }

    private func subtitle(_ r: ConceptRecord, stuck: Bool) -> String {
        if stuck { return "\(r.consecutiveMisses)번 놓침 · 천천히 다시 보기" }
        let accepted = Int((r.accuracy * 100).rounded())
        guard let due = r.review.due else { return "\(r.total)문제 · 정확·근접 \(accepted)%" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        let when = days <= 0 ? "지금 복습" : "\(days)일 후 복습"
        return "\(r.total)문제 · 정확·근접 \(accepted)% · \(when)"
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
        case .attempted:  return "기록 시작"
        case .familiar:   return "반복 중"
        case .proficient: return "능숙 단계"
        case .mastered:   return "숙달 단계"
        }
    }
}
