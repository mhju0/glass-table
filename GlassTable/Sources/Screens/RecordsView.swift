// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableDrills

/// Two numbers that only grow lead (owner, R3·G); the numbers that can drop wait
/// under "Where to look next".
struct RecordsView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var clockRefresh = 0
    @State private var detailsExpanded = false
    var onContinue: () -> Void = {}
    var onOpenReview: () -> Void = {}
    @State private var replay: Concept?
    @State private var replaySeed: UInt64 = 0
    @State private var selectedPracticeConcept: Concept?

    /// Only concepts the user has actually met. An untouched roster reads as a
    /// to-do list, which is the path's job, not this screen's.
    private var studied: [Concept] {
        Concept.allCases.filter { model.record(for: $0).total > 0 }
    }

    var body: some View {
        ScrollView {
            TimelineView(.everyMinute) { _ in
                let _ = clockRefresh
                let now = Date()
                VStack(alignment: .leading, spacing: GT.Space.section) {
                    Text(language.text("학습 기록", "Progress"))
                        .font(GT.title(textSize.isAccessibilitySize ? 22 : 30))
                        .foregroundStyle(GT.onFelt)
                        .padding(.top, 14)
                    ProgressSummaryView(overview: ProgressOverview(state: model.state, now: now, calendar: .current),
                                        onContinue: onContinue, onOpenReview: onOpenReview)
                    DisclosureGroup(isExpanded: $detailsExpanded) {
                        VStack(alignment: .leading, spacing: GT.Space.section) {
                            practiceCard(now: now)
                            styleCard
                            calibrationCard
                            evLossCard
                            if studied.isEmpty { emptyState } else { conceptList(now: now) }
                        }.padding(.top, 12)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.text("더 살펴볼 곳", "Where to look next"))
                            Text(language.text("목표 안 비율, 테이블 습관", "On target, table habits"))
                                .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                        }
                    }
                    .font(GT.semibold(16)).tint(GT.onFelt)
                    .accessibilityIdentifier("records-details")
                }
                .padding(.horizontal, GT.Space.edge)
            }
        }
        .gtTabBarClearance()
        .background(FeltBackground())
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { clockRefresh += 1 }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            clockRefresh += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)) { _ in
            clockRefresh += 1
        }
        .onAppear {
            clockRefresh += 1
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
                                     seed: 0x7EAC &+ replaySeed,
                                     index: 0, language: language)
            NavigationStack {
                WalkthroughView(title: conceptName(concept), concept: concept,
                                purpose: ConceptIntroduction.make(concept, language: language).why,
                                beats: w.beats, rows: w.rows,
                                onFinish: {
                                    model.completeWalkthrough(concept: concept)
                                    replay = nil
                                })
                .gtChrome(trailing: {
                    ChromeTextButton(title: WalkthroughView.skipTitle(language)) { replay = nil }
                })
            }
            .gtSheetSurface()
        }
    }

    private func conceptName(_ concept: Concept) -> String {
        skillNames(concept, language: language).lead
    }

    private var practiceConcepts: [Concept] {
        Concept.allCases.filter { concept in
            model.state.dailySummaries.contains { $0.key.concept == concept.rawValue }
        }
    }

    @ViewBuilder
    private func practiceCard(now: Date) -> some View {
        let available = practiceConcepts
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: language.text("연습 변화", "Practice over time"), onDark: false)
            if let concept = selectedPracticeConcept.flatMap({ available.contains($0) ? $0 : nil })
                ?? available.first,
               let latest = latestSummary(for: concept) {
                Menu {
                    ForEach(available, id: \.self) { option in
                        Button(conceptName(option)) { selectedPracticeConcept = option }
                    }
                } label: {
                    HStack {
                        Text(conceptName(concept)).font(GT.title(18))
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .foregroundStyle(GT.ink)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background { GTControlBackground() }
                }
                .accessibilityLabel(language.text("연습 주제: \(conceptName(concept))", "Practice topic: \(conceptName(concept))"))

                let comparable = model.state.dailySummaries.filter {
                    $0.key.concept == latest.key.concept &&
                    $0.key.mode == latest.key.mode &&
                    $0.key.formatVersion == latest.key.formatVersion &&
                    $0.key.language == latest.key.language
                }
                let today = DayKey(now)
                let todayTotals = totals(comparable, from: 0, through: 0, today: today)
                let recent = totals(comparable, from: 0, through: 6, today: today)
                let earlier = totals(comparable, from: 7, through: 13, today: today)
                Text(practiceLane(latest.key))
                    .font(GT.body(12)).foregroundStyle(GT.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                practiceRow(language.text("오늘", "Today"), todayTotals)
                practiceRow(language.text("최근 7일", "Last 7 days"), recent)
                practiceRow(language.text("그 전 7일", "Previous 7 days"), earlier)
                if concept == .evLoss, recent.decisionLossCount > 0 {
                    let average = recent.decisionLossBB / Double(recent.decisionLossCount)
                    Text(language.text(
                        "최근 7일 선택당 평균 손실 \(bbText(average))bb · \(recent.decisionLossCount)개 결정",
                        "Last 7 days: \(bbText(average))bb average loss per choice · \(recent.decisionLossCount) decisions"))
                        .font(GT.semibold(13)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if recent.eligibleCorrectCount >= 10, earlier.eligibleCorrectCount >= 10,
                   recent.eligibleDays >= 3, earlier.eligibleDays >= 3 {
                    let current = recent.eligibleCorrectSeconds / Double(recent.eligibleCorrectCount)
                    let prior = earlier.eligibleCorrectSeconds / Double(earlier.eligibleCorrectCount)
                    Text(language.text(
                        "목표 안에 든 답의 평균 시간: 최근 \(String(format: "%.1f", current))초 · 이전 \(String(format: "%.1f", prior))초",
                        "Average time on on-target answers: \(String(format: "%.1f", current))s recently · \(String(format: "%.1f", prior))s before"))
                        .font(GT.semibold(13)).foregroundStyle(GT.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(language.text(
                    "속도는 도움 없이 중단되지 않고 목표 안에 든 답만 세어요. 충분한 답과 날짜가 쌓인 같은 유형의 연습끼리만 비교해요.",
                    "Timing counts only uninterrupted, unassisted on-target answers. A comparison appears after enough answers and days in the same practice format."))
                    .font(GT.body(12)).foregroundStyle(GT.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(language.text("한 문제를 풀면 날짜별 연습 기록이 여기에 쌓여요.",
                                   "Answer a question to start a daily record."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            }
            if let started = model.state.detailedTrackingStartedAt {
                Text(language.text("자세한 기록은 \(DayKey(started).raw)부터예요. 이전 답변은 날짜별로 추정하지 않아요.",
                                   "Detailed tracking began \(DayKey(started).raw). Earlier answers are not reconstructed by day."))
                    .font(GT.body(12)).foregroundStyle(GT.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .gtInset(GT.Space.card, firstText: .semibold(13)).frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.Radius.panel)
    }

    /// The newest day's lane; on the same day, practice without help comes first.
    private func latestSummary(for concept: Concept) -> DailyPracticeSummary? {
        let matches = model.state.dailySummaries.filter { $0.key.concept == concept.rawValue }
        let older: (DailyPracticeSummary, DailyPracticeSummary) -> Bool = {
            $0.key.day != $1.key.day ? $0.key.day < $1.key.day
                : $0.key.assisted && !$1.key.assisted
        }
        return matches.filter { $0.key.language == language.rawValue }.max(by: older)
            ?? matches.max(by: older)
    }

    private func practiceLane(_ key: DailyPracticeKey) -> String {
        let mode: String
        switch key.mode {
        case "single-skill": mode = language.text("연습", "Practice")
        case "path": mode = language.text("레슨", "Lesson")
        case "review": mode = language.text("복습", "Review")
        default: mode = language.text("연습", "Practice")
        }
        let lang = key.language == "ko" ? language.text("한국어", "Korean")
                    : language.text("영어", "English")
        return "\(mode) · \(lang) · \(language.text("같은 문제 유형", "Same question format"))"
    }

    private func totals(_ summaries: [DailyPracticeSummary], from firstAge: Int,
                        through lastAge: Int, today: DayKey) -> PracticeTotals {
        var result = PracticeTotals()
        for summary in summaries {
            guard let age = summary.key.day.daysBetween(today),
                  (firstAge...lastAge).contains(age) else { continue }
            result.exact += summary.exact
            result.near += summary.near
            result.miss += summary.miss
            result.eligibleCorrectSeconds += summary.eligibleCorrectSeconds
            result.eligibleCorrectCount += summary.eligibleCorrectCount
            if summary.eligibleCorrectCount > 0 { result.eligibleDays += 1 }
            result.decisionLossBB += summary.decisionLossBB
            result.decisionLossCount += summary.decisionLossCount
        }
        return result
    }

    private func practiceRow(_ period: String, _ totals: PracticeTotals) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(period).font(GT.semibold(14)).foregroundStyle(GT.ink)
                Spacer(minLength: 8)
                Text(language.text("\(totals.total)문제", "\(totals.total) answers"))
                    .font(GT.semibold(13).monospacedDigit()).foregroundStyle(GT.inkSecondary)
            }
            Text(language.text("목표 안 \(totals.exact) · 근접 \(totals.near) · 놓침 \(totals.miss)",
                               "On target \(totals.exact) · Near \(totals.near) · Missed \(totals.miss)"))
                .font(GT.body(12)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if totals.total > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GT.surface)
                        Capsule().fill(GT.green)
                            .frame(width: geometry.size.width * CGFloat(totals.exact) / CGFloat(totals.total))
                    }
                }.frame(height: 7)
                .accessibilityHidden(true)
            }
        }
    }

    private var styleCard: some View {
        let report = model.observedStyle()
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: language.text("테이블에서 보인 습관", "Observed table habits"), onDark: false)
            Text(styleHeadline(report)).font(GT.title(20)).foregroundStyle(GT.ink)
            Text(styleSummary(report))
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            // The evidence stays disclosed, one tap down, so the card reads at a glance.
            DisclosureGroup(language.text("어떻게 정하나요", "How this works")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.text("최근 30일, 현재 컴퓨터 규칙 · 최대 200핸드 중 \(report.hands)핸드 · \(report.days)일",
                                       "Last 30 days, current bot rules · \(report.hands) of up to 200 recent hands · \(report.days) days"))
                    if report.hands > 0 {
                        Text(EnteredHandsText.entriesDetail(entries: report.voluntaryEntries, hands: report.hands,
                                                            raises: report.preflopRaises, language: language))
                        if let participation = report.participationInterval {
                            Text(language.text(
                                "참여 비율의 95% 추정 구간 \(Int((participation.lowerBound * 100).rounded()))–\(Int((participation.upperBound * 100).rounded()))%",
                                "Estimated 95% interval for entering: \(Int((participation.lowerBound * 100).rounded()))–\(Int((participation.upperBound * 100).rounded()))%"))
                        }
                        if let raises = report.raiseShareInterval {
                            Text(language.text(
                                "참여 후 레이즈 비율의 95% 추정 구간 \(Int((raises.lowerBound * 100).rounded()))–\(Int((raises.upperBound * 100).rounded()))%",
                                "Estimated 95% interval for raising after entering: \(Int((raises.lowerBound * 100).rounded()))–\(Int((raises.upperBound * 100).rounded()))%"))
                        }
                    }
                    if let first = report.firstDay, let last = report.lastDay {
                        Text("\(first) – \(last)")
                    }
                    Text(language.text(
                        "공개된 컴퓨터 규칙 아래에서 시작 전 행동만 묘사해요. 최소 100핸드, 5일, 자발적 참여 40번이 필요하고, 경계에 걸치면 이름을 붙이지 않아요. 실력 평가는 아니에요.",
                        "Describes preflop play under the published bot rules. Labels need 100 hands, 5 days, 40 voluntary entries; borderline cases stay unnamed. Not a skill rating."))
                }
                .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            }
            .accessibilityIdentifier("records-style-details")
        }
        .gtInset(GT.Space.card, firstText: .semibold(13)).frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.Radius.panel)
    }

    /// The label thresholds from `PracticeStyleAnalysis`, restated for the progress line.
    private func styleIsUnlocked(_ report: PracticeStyleReport) -> Bool {
        report.hands >= 100 && report.days >= 5 && report.voluntaryEntries >= 40
    }

    private func styleHeadline(_ report: PracticeStyleReport) -> String {
        if let style = report.style { return styleName(style) }
        return styleIsUnlocked(report)
            ? language.text("아직 뚜렷한 습관이 없어요", "No clear pattern yet")
            : language.text("아직 핸드가 부족해요", "Not enough hands yet")
    }

    private func styleSummary(_ report: PracticeStyleReport) -> String {
        if styleIsUnlocked(report) {
            return language.text("\(report.days)일 동안 \(report.hands)핸드 기준",
                                 "Based on \(report.hands) hands over \(report.days) days")
        }
        if report.hands >= 100, report.days >= 5 {
            return language.text("참여한 핸드 \(report.voluntaryEntries)/40",
                                 "\(report.voluntaryEntries) of 40 hands joined")
        }
        return language.text("\(min(report.hands, 100))/100핸드 · \(min(report.days, 5))/5일",
                             "\(min(report.hands, 100)) of 100 hands · \(min(report.days, 5)) of 5 days")
    }

    private func styleName(_ style: PracticeObservedStyle) -> String {
        switch style {
        case .selectiveRaiser: language.text("골라서 자주 올림", "Selective raiser")
        case .selectiveCaller: language.text("골라서 자주 따라감", "Selective caller")
        case .wideRaiser: language.text("여러 핸드로 자주 올림", "Frequent raiser")
        case .wideCaller: language.text("여러 핸드로 자주 따라감", "Frequent caller")
        case .mixed: language.text("참여와 레이즈 모두 중간", "Midrange participation and raising")
        }
    }

    @ViewBuilder
    private var calibrationCard: some View {
        let sampleCount = model.state.answers.filter { $0.interval != nil }.count
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: language.text("확신 점검", "Confidence check"), onDark: false)
            if let rate = model.calibrationHitRate {
                Text(language.text("정답이 내가 예상한 90% 범위에 들어온 비율",
                                   "Answers inside your 90% range"))
                    .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int((rate * 100).rounded()))%")
                        .font(GT.title(28).monospacedDigit()).foregroundStyle(GT.ink)
                    Text(language.text("\(sampleCount)개 답변 · 기준 90%",
                                       "\(sampleCount) answers · 90% target"))
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
                DisclosureGroup(language.text("이 수치의 뜻", "What this means")) {
                    Text(calibrationDescription(count: sampleCount))
                        .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                        .lineSpacing(GT.Typography.explanationLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
                .accessibilityIdentifier("records-calibration-details")
            } else {
                Text(language.text("범위로 답하는 문제의 기록이 여기에 쌓여요.",
                                   "Your range answers collect here."))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .gtInset(GT.Space.card, firstText: .semibold(13))
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
                SectionLabel(text: language.text("결정", "Decisions"), onDark: false)
                Text(language.text("최근 저장된 결정의 평균 EV 손실",
                                   "Average value lost on recent saved decisions"))
                    .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(bbText(mean))bb")
                        .font(GT.title(28).monospacedDigit()).foregroundStyle(GT.ink)
                    Text(language.text("\(count)개 결정 · 낮을수록 좋아요",
                                       "\(count) decisions · lower is better"))
                        .font(GT.semibold(12)).foregroundStyle(GT.inkMuted)
                }
                Text(language.text("이 값은 공개된 체크다운 가정으로 채점한 연습 기록이에요.",
                                   "This practice result uses the app's disclosed checkdown assumption."))
                    .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                    .lineSpacing(GT.Typography.explanationLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .gtInset(GT.Space.card, firstText: .semibold(13))
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtCard(radius: GT.Radius.panel)
        }
    }

    private func calibrationDescription(count: Int) -> String {
        language.text("최근 저장된 \(count)개 구간 답변의 결과예요. 표본이 적을 때는 이 수치만으로 실력을 판단하지 않아요.",
                      "This uses \(count) recent saved interval answers. A small sample cannot establish skill on its own.")
    }

    private var emptyState: some View {
        Text(language.text("아직 기록이 없어요. 한 문제를 풀면 답변 수와 다음 복습 시점을 여기에서 확인할 수 있어요.",
                           "No answers yet. After one question, your answer count and next review date appear here."))
            .font(GT.body(14)).foregroundStyle(GT.onFeltSecondary)
            .padding(.top, 4)
    }

    private func conceptList(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: language.text("개념별", "By topic")).padding(.bottom, 8)
            VStack(spacing: 0) {
                ForEach(Array(studied.enumerated()), id: \.element) { i, concept in
                    row(concept, now: now)
                    if i != studied.count - 1 {
                        Rectangle().fill(GT.surface).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func row(_ concept: Concept, now: Date) -> some View {
        let r = model.record(for: concept)
        let stuck = model.shouldOfferWalkthrough(concept)
        let line = HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(conceptName(concept)).font(GT.title(16)).foregroundStyle(GT.onFelt)
                Text(subtitle(r, stuck: stuck, now: now))
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
        .accessibilityLabel("\(conceptName(concept)). \(tierWord(r.tier)). \(subtitle(r, stuck: stuck, now: now))")
        .accessibilityIdentifier("record-\(concept.rawValue)")

        if stuck {
            Button { replaySeed = GuideExampleRotation.next("records-" + concept.rawValue); replay = concept } label: { line.contentShape(Rectangle()) }
                .buttonStyle(GTPress())
                .accessibilityHint(language.text("따라 배우기 열기", "Open guided walkthrough"))
        } else {
            line
        }
    }

    private func subtitle(_ r: ConceptRecord, stuck: Bool, now: Date) -> String {
        if stuck { return language.text("\(r.consecutiveMisses)번 놓침 · 따라 배우기",
                                        "\(r.consecutiveMisses) misses in a row · guided walkthrough") }
        let accepted = Int((r.accuracy * 100).rounded())
        guard let due = r.review.due else {
            return language.text("\(r.total)문제 · 정확 \(accepted)%",
                                 "\(r.total) answers · exact \(accepted)%")
        }
        let when = ReviewTiming.text(due: due, now: now, language: language)
        return language.text("\(r.total)문제 · 정확 \(accepted)% · \(when)",
                             "\(r.total) answers · exact \(accepted)% · \(when)")
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
        case .attempted:  return language.text("막 시작", "Just started")
        case .familiar:   return language.text("익히는 중", "Getting familiar")
        case .proficient: return language.text("능숙 단계", "Strong in app")
        case .mastered:   return language.text("숙달 단계", "Mastered in app")
        }
    }
}

private struct PracticeTotals {
    var exact = 0
    var near = 0
    var miss = 0
    var eligibleCorrectSeconds = 0.0
    var eligibleCorrectCount = 0
    var eligibleDays = 0
    var decisionLossBB = 0.0
    var decisionLossCount = 0
    var total: Int { exact + near + miss }
}
