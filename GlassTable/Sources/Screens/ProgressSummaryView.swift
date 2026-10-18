// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// The top of Progress (owner's pick R3·G, 2026-10-18): two numbers that only grow,
/// the week so far, one refresh card, stage bars and the journal. Every value is read
/// from `ProgressOverview`; nothing here saves.
struct ProgressSummaryView: View {
    @Environment(ProgressionModel.self) private var model
    @Environment(\.learningLanguage) private var language
    @Environment(\.leadsWithTerms) private var termsLead
    @Environment(\.dynamicTypeSize) private var textSize
    let overview: ProgressOverview
    let onContinue: () -> Void
    let onOpenReview: () -> Void
    @State private var showsAllSkills = false
    @State private var showsWholeJournal = false

    private static let visibleSkills = 6
    private static let visibleJournal = 3
    private var stacks: Bool { textSize.isAccessibilitySize }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if overview.hasHistory {
                hero
                weekLine
                if overview.isReturning { welcomeBack } else { refreshCard }
                skills
                Text(language.text("능숙·숙달은 앱 안에서 쌓인 학습 단계예요. 실력 인증은 아니에요.",
                                   "Stages describe practice in this app, not proven skill."))
                    .font(GT.body(12)).foregroundStyle(GT.onFeltMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                journal
            } else {
                startCard
            }
        }
    }

    // MARK: Two numbers that only grow

    private var hero: some View {
        let decisions = cell(value: overview.decisionsStudied,
                             label: language.text("공부한 결정",
                                                   overview.decisionsStudied == 1 ? "decision studied" : "decisions studied"),
                             detail: language.text("지금까지 모두", "in all, since you started"),
                             placeholder: language.text("다음 답부터 세어요", "Counting starts with your next answer"))
            .accessibilityIdentifier("progress-decisions")
        let mastered = overview.masteredSkills
        let strong = cell(value: overview.strongSkills,
                          label: language.text("능숙 이상 기술",
                                                overview.strongSkills == 1 ? "skill at Strong" : "skills at Strong"),
                          detail: mastered > 0
                            ? language.text("\(overview.skillCount)개 중 · 숙달 \(mastered)개",
                                            "of \(overview.skillCount) · \(mastered) Mastered")
                            : language.text("\(overview.skillCount)개 중 · 다음은 숙달",
                                            "of \(overview.skillCount) · next: Mastered"),
                          placeholder: language.text("첫 능숙 단계가 다음이에요", "Your first Strong skill is next"))
            .accessibilityIdentifier("progress-strong")
        return Group {
            if stacks {
                VStack(alignment: .leading, spacing: 0) {
                    decisions
                    Rectangle().fill(GT.border).frame(height: 1)
                    strong
                }
            } else {
                HStack(alignment: .center, spacing: 14) {
                    decisions
                    Rectangle().fill(GT.border).frame(width: 1).padding(.vertical, 10)
                    strong
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(GT.border).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(GT.border).frame(height: 1) }
        .padding(.top, 12)
    }

    /// A count, or before the first one a line about what comes next: never a bare 0.
    private func cell(value: Int, label: String, detail: String, placeholder: String) -> some View {
        Group {
            if value > 0 {
                let count = Text(value.formatted())
                    .font(GT.title(44).monospacedDigit()).foregroundStyle(GT.onFelt)
                let description = VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                    Text(detail).font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Group {
                    if stacks {
                        VStack(alignment: .leading, spacing: 4) {
                            count.fixedSize(horizontal: false, vertical: true)
                            description
                        }
                    } else {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .center, spacing: 10) {
                                count.fixedSize()
                                description.fixedSize()
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                count.fixedSize(horizontal: false, vertical: true)
                                description
                            }
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(value.formatted()) \(label), \(detail)")
            } else {
                Text(placeholder).font(GT.semibold(15)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(placeholder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }

    // MARK: This week

    /// Days this week, from Monday. Before the first one it encourages instead of
    /// showing a 0, and it never mentions a streak.
    private var weekLine: some View {
        let days = overview.daysThisWeek
        let text = days > 0
            ? language.text("이번 주 · \(days)일 연습", days == 1 ? "This week · 1 day" : "This week · \(days) days")
            : language.text("새로운 한 주예요. 한 문제면 시작이에요.", "A new week. One question gets you going.")
        return HStack(alignment: .center, spacing: 8) {
            if days > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<min(days, 7), id: \.self) { _ in
                        Circle().fill(GT.green).frame(width: 9, height: 9)
                    }
                }
                .accessibilityHidden(true)
            }
            Text(text).font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { Rectangle().fill(GT.border).frame(height: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("progress-week")
    }

    // MARK: Refresh

    private var reviewOpen: Bool { model.state.activeReviewSession != nil }

    @ViewBuilder private var refreshCard: some View {
        if reviewOpen || !overview.due.isEmpty {
            let due = overview.due
            let title = due.count == 1 ? skillName(due[0]) : language.text("기술 \(due.count)개", "\(due.count) skills")
            let detail = reviewOpen
                ? language.text("멈춘 문제부터 이어서 풀어요.", "Pick up the question you stopped on.")
                : due.count == 1
                ? stageWord(model.record(for: due[0]).tier)
                : due.prefix(3).map(skillName).joined(separator: " · ") + (due.count > 3 ? " …" : "")
            card(highlighted: true, kicker: reviewOpen ? language.text("복습 진행 중", "Review in progress")
                                                        : language.text("다시 볼 때예요", "Ready for a refresh"),
                 title: title, detail: detail,
                 action: reviewOpen ? language.text("이어서", "Continue") : language.text("시작", "Start"),
                 filled: true, actionID: "progress-refresh-start", perform: onOpenReview)
                .accessibilityIdentifier("progress-refresh")
        } else {
            card(highlighted: false, kicker: nil, title: language.text("모두 복습했어요", "All caught up"),
                 detail: language.text("오늘 다시 볼 기술은 없어요.", "No skill needs a refresh today."),
                 action: language.text("이어서 배우기", "Continue learning"),
                 filled: false, actionID: "records-continue", perform: onContinue)
                .accessibilityIdentifier("progress-caught-up")
        }
    }

    /// After time away: the progress is kept, and the due skills are a quick refresh.
    @ViewBuilder private var welcomeBack: some View {
        let due = overview.due.count
        if reviewOpen || due > 0 {
            card(highlighted: true, kicker: nil,
                 title: language.text("다시 오셨네요. 기록은 그대로예요.", "Welcome back. Your progress is kept."),
                 detail: reviewOpen
                    ? language.text("멈춘 복습부터 이어서 풀어요.", "Pick up the review where you stopped.")
                    : language.text("기술 \(due)개를 가볍게 다시 볼 수 있어요.",
                                    due == 1 ? "1 skill is ready for a quick refresh."
                                             : "\(due) skills are ready for a quick refresh."),
                 action: reviewOpen ? language.text("이어서", "Continue") : language.text("복습 시작", "Start a refresh"),
                 filled: true, actionID: "progress-refresh-start", perform: onOpenReview)
                .accessibilityIdentifier("progress-welcome-back")
        } else {
            card(highlighted: true, kicker: nil,
                 title: language.text("다시 오셨네요. 기록은 그대로예요.", "Welcome back. Your progress is kept."),
                 detail: language.text("멈춘 곳부터 이어가요.", "Pick up where you left off."),
                 action: language.text("이어서 배우기", "Continue learning"),
                 filled: true, actionID: "records-continue", perform: onContinue)
                .accessibilityIdentifier("progress-welcome-back")
        }
    }

    private var startCard: some View {
        card(highlighted: true, kicker: nil,
             title: language.text("첫 문제를 풀면 여기에 기록이 쌓여요.", "Your progress starts with your first question."),
             detail: language.text("공부한 결정과 능숙 단계에 오른 기술이 여기에 보여요.",
                                   "Decisions studied and skills at Strong collect here."),
             action: language.text("배우기 시작", "Start learning"),
             filled: true, actionID: "records-continue", perform: onContinue)
            .padding(.top, 12)
            .accessibilityIdentifier("progress-start")
    }

    private func card(highlighted: Bool, kicker: String?, title: String, detail: String,
                      action: String, filled: Bool, actionID: String,
                      perform: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.panel, style: .continuous)
        let layout = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 3) {
                if let kicker {
                    Text(kicker).font(GT.semibold(12)).foregroundStyle(GT.cta)
                }
                Text(title).font(GT.title(16)).foregroundStyle(GT.ink)
                Text(detail).font(GT.body(13)).foregroundStyle(GT.inkSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            Button(action: perform) { pill(action, filled: filled) }
                .buttonStyle(GTPress())
                .accessibilityIdentifier(actionID)
        }
        .padding(12)
        .background {
            shape.fill(GT.glass)
                .overlay(shape.strokeBorder(highlighted ? GT.cta : GT.border, lineWidth: highlighted ? 1.5 : 1))
        }
        .padding(.top, 12)
        .accessibilityElement(children: .contain)
    }

    /// Learn's pill: filled for the one action that needs attention, outlined otherwise.
    private func pill(_ title: String, filled: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control, style: .continuous)
        return Text(title).font(GT.semibold(14))
            .foregroundStyle(filled ? GT.onCTA : GT.onFelt)
            .fixedSize(horizontal: !stacks, vertical: true)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .frame(maxWidth: stacks ? .infinity : nil, minHeight: 36)
            .background {
                if filled { shape.fill(GT.cta) }
                else { shape.fill(GT.surface).overlay(shape.strokeBorder(GT.border, lineWidth: 1)) }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }

    // MARK: Skills

    /// Path skills always; a "Go deeper" skill once it has been started.
    private var listedSkills: [ProgressOverview.Skill] {
        overview.skills.filter { !$0.isOptional || $0.tier != nil }
    }

    private var skills: some View {
        let all = listedSkills
        let shown = showsAllSkills ? all : Array(all.prefix(Self.visibleSkills))
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(language.text("기술", "Skills"), aside: language.text("강한 것부터", "strongest first"))
            Text(MasteryTier.allCases.map(stageWord).joined(separator: " → "))
                .font(GT.body(12)).foregroundStyle(GT.onFeltSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
            ForEach(shown, id: \.concept) { skillRow($0) }
            if all.count > Self.visibleSkills {
                moreButton(expanded: showsAllSkills, count: all.count, id: "progress-skills-more") {
                    showsAllSkills.toggle()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("progress-skills")
    }

    private func skillRow(_ skill: ProgressOverview.Skill) -> some View {
        let name = skillName(skill.concept)
        let refresh = language.text("복습", "refresh")
        let layout = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                            : AnyLayout(HStackLayout(alignment: .center, spacing: 10))
        return layout {
            HStack(alignment: .center, spacing: 6) {
                Text(name).font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                    .fixedSize(horizontal: false, vertical: true)
                if skill.isDue {
                    Label(refresh, systemImage: "arrow.clockwise")
                        .font(GT.semibold(11)).foregroundStyle(GT.cta)
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .overlay(Capsule().strokeBorder(GT.cta, lineWidth: 1))
                        .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StageBar(filled: skill.stage, of: skill.stageCount)
                .frame(width: stacks ? nil : 92)
                .frame(maxWidth: stacks ? .infinity : nil)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(GT.border).frame(height: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([name, skill.tier.map(stageWord) ?? language.text("시작 전", "Not started"),
                             skill.isDue ? language.text("다시 볼 때예요", "Ready for a refresh") : nil]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityIdentifier("progress-skill-\(skill.concept.rawValue)")
    }

    // MARK: Journal

    private var journal: some View {
        let entries = overview.journal
        let shown = showsWholeJournal ? entries : Array(entries.prefix(Self.visibleJournal))
        let aside = overview.nextDecisionMilestone.map { next in
            language.text("결정 \(next.formatted())개까지 \((next - overview.decisionsStudied).formatted())개",
                          "\(next.formatted()) decisions: \((next - overview.decisionsStudied).formatted()) to go")
        }
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(language.text("학습 일지", "Journal"), aside: aside)
            if entries.isEmpty {
                Text(language.text("첫 능숙 단계, 통과한 트랙 도전, 결정 100개 같은 순간이 날짜와 함께 남아요.",
                                   "Your first Strong skill, passed track challenges and decision milestones are kept here with their dates."))
                    .font(GT.body(13)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
            }
            ForEach(Array(shown.enumerated()), id: \.offset) { index, entry in
                journalRow(entry, isLast: index == shown.count - 1)
            }
            if entries.count > Self.visibleJournal {
                moreButton(expanded: showsWholeJournal, count: entries.count, id: "progress-journal-more") {
                    showsWholeJournal.toggle()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("progress-journal")
    }

    private func journalRow(_ entry: ProgressOverview.JournalEntry, isLast: Bool) -> some View {
        let (kind, title) = milestoneText(entry.milestone)
        let date = dayText(entry.day)
        let text = VStack(alignment: .leading, spacing: 1) {
            Text(kind).font(GT.semibold(11)).foregroundStyle(GT.green)
            Text(title).font(GT.semibold(14)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
        }
        return HStack(alignment: .top, spacing: 8) {
            if !stacks {
                Text(date).font(GT.semibold(12).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
                    .frame(width: 56, alignment: .leading)
            }
            ZStack(alignment: .top) {
                if !isLast { Rectangle().fill(GT.border).frame(width: 2).padding(.top, 12) }
                Circle().fill(GT.green).frame(width: 12, height: 12).padding(.top, 3)
            }
            .frame(width: 14)
            .frame(maxHeight: .infinity, alignment: .top)
            VStack(alignment: .leading, spacing: 2) {
                if stacks {
                    Text(date).font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                }
                text
            }
            .padding(.bottom, 10)
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(date), \(kind), \(title)")
    }

    private func milestoneText(_ milestone: ProgressOverview.Milestone) -> (String, String) {
        switch milestone {
        case let .firstStrong(concept):
            (language.text("첫 능숙", "First Strong"), skillName(concept))
        case let .mastered(concept):
            (language.text("숙달 단계", "Mastered in app"), skillName(concept))
        case let .trackPassed(id):
            (language.text("트랙 도전 통과", "Track challenge passed"), id.title(in: language))
        case let .decisions(count):
            (language.text("결정 \(count.formatted())개", "\(count.formatted()) decisions"),
             language.text("시작부터 공부한 결정", "studied since you started"))
        }
    }

    /// "10월 17일" / "Oct 17". The stored key is an ISO day, which reads as data.
    private func dayText(_ day: DayKey) -> String {
        let parts = day.raw.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]) else { return day.raw }
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return language.text("\(parts[1])월 \(parts[2])일", "\(months[parts[1] - 1]) \(parts[2])")
    }

    // MARK: Shared

    private func sectionHeader(_ title: String, aside: String?) -> some View {
        let layout = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        return layout {
            Text(title).font(GT.title(17)).foregroundStyle(GT.onFelt)
                .accessibilityAddTraits(.isHeader)
            if !stacks { Spacer(minLength: 8) }
            if let aside {
                Text(aside).font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 22).padding(.bottom, 4)
    }

    private func moreButton(expanded: Bool, count: Int, id: String, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                Text(expanded ? language.text("접기", "Show fewer")
                              : language.text("\(count)개 모두 보기", "Show all \(count)"))
                    .font(GT.semibold(13))
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(GT.onFeltSecondary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityIdentifier(id)
    }

    private func skillName(_ concept: Concept) -> String {
        skillNames(concept, language: language, termsLead: termsLead).lead
    }

    private func stageWord(_ tier: MasteryTier) -> String {
        switch tier {
        case .attempted:  language.text("막 시작", "Just started")
        case .familiar:   language.text("익히는 중", "Getting familiar")
        case .proficient: language.text("능숙 단계", "Strong in app")
        case .mastered:   language.text("숙달 단계", "Mastered in app")
        }
    }
}

/// A skill's stage as filled segments. The count comes from the caller, so another
/// stage (a lesson step, say) can join the bar without changing its look.
struct StageBar: View {
    let filled: Int
    let of: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<of, id: \.self) { index in
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: index == 0 ? 4 : 0,
                                                          bottomLeading: index == 0 ? 4 : 0,
                                                          bottomTrailing: index == of - 1 ? 4 : 0,
                                                          topTrailing: index == of - 1 ? 4 : 0))
                    .fill(index < filled ? GT.green : GT.surface)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}
