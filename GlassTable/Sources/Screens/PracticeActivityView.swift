import SwiftUI
import GlassTableDrills

struct PracticeActivityView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    let overview: PracticeActivityOverview
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            Text(language.text("통과한 레슨", "Passed lessons"))
                .font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
            Text("\(overview.mainCourseCompletedLessons) / \(overview.mainCourseLessonCount)")
                .font(GT.title(30).monospacedDigit()).foregroundStyle(GT.ink)
                .accessibilityLabel(language.text("기본 레슨 \(overview.mainCourseLessonCount)개 중 \(overview.mainCourseCompletedLessons)개 통과",
                                                  "\(overview.mainCourseCompletedLessons) of \(overview.mainCourseLessonCount) main lessons passed"))
                .accessibilityIdentifier("records-completion")
            if overview.deeperCompletedLessons > 0 {
                Text(language.text("더 깊이 배우기 \(overview.deeperCompletedLessons)/\(overview.deeperLessonCount)개 통과",
                                   "Deeper lessons: \(overview.deeperCompletedLessons)/\(overview.deeperLessonCount) passed"))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            }
            Text(overview.distinctRecentDayCount == 0 && overview.recentTopics.isEmpty
                 ? language.text("한 문제부터 가볍게 시작해요.", "Start with one question.")
                 : overview.todayAnswerCount == 0
                 ? language.text("다시 오셨네요. 지난 주제부터 이어가요.", "Welcome back. Pick up a recent topic.")
                 : language.text("최근 7일 동안 \(overview.distinctRecentDayCount)일 연습했어요.",
                                 "Practised \(overview.distinctRecentDayCount) of the last 7 days."))
                .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if textSize.isAccessibilitySize {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    dates
                }
            } else {
                HStack(alignment: .top, spacing: 4) { dates }
            }
            PrimaryCTAButton(title: overview.mainCourseCompletedLessons >= overview.mainCourseLessonCount
                          ? language.text("다시 연습하기", "Practice again")
                          : language.text("이어서 배우기", "Continue learning"), action: onContinue)
                .accessibilityIdentifier("records-continue")
            DisclosureGroup(language.text("기록은 어떻게 세나요?", "What counts as practice?")) {
                Text(language.text("레슨, 연습, 복습에서 답을 제출한 날짜를 세요. 예시 보기와 자유 대전은 포함하지 않아요. 레슨 통과와 실력은 다른 기록이에요.",
                                   "A submitted answer in a lesson, practice or review records the date. Worked examples and the free table are excluded. Passing a lesson is separate from proficiency."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
            .font(GT.semibold(14)).tint(GT.inkSecondary)
        }
        .gtInset(GT.Space.card, firstText: .semibold(13))
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.Radius.panel)
    }

    private var dates: some View {
        ForEach(overview.last7, id: \.day) { cell in
            VStack(spacing: 7) {
                Text(String(cell.day.raw.suffix(2))).font(GT.semibold(13).monospacedDigit())
                    .foregroundStyle(GT.inkSecondary)
                Group {
                    if cell.isToday && overview.todayFlameBool {
                        Image(systemName: "flame.fill").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GT.cta)
                    } else if cell.isRecorded {
                        Circle().fill(GT.cta).frame(width: 10, height: 10)
                    } else {
                        Circle().strokeBorder(GT.borderStrong, lineWidth: 1.5).frame(width: 10, height: 10)
                    }
                }
                .frame(width: 20, height: 20)
                if cell.isToday {
                    Text(language.text("오늘", "Today")).font(GT.body(11))
                        .foregroundStyle(GT.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(dateLabel(cell))
            .accessibilityIdentifier("records-day-\(cell.day.raw)")
        }
    }

    private func dateLabel(_ cell: PracticeActivityOverview.DayCell) -> String {
        let status = cell.isRecorded ? language.text("연습 기록 있음", "Practice recorded")
                                     : language.text("연습 기록 없음", "No practice recorded")
        let today = cell.isToday ? language.text("오늘, ", "Today, ") : ""
        let continuity = cell.isToday && overview.todayFlameBool
            ? language.text(", \(overview.consecutivePracticeDays)일 연속 연습",
                            ", \(overview.consecutivePracticeDays) consecutive practice days") : ""
        return "\(today)\(cell.day.raw), \(status)\(continuity)"
    }
}
