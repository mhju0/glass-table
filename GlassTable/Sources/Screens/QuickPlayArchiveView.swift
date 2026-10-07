// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills
import GlassTableEngine

struct QuickPlayArchiveView: View {
    @Environment(\.learningLanguage) private var language
    let sessions: [QuickPlaySession]
    let onClose: () -> Void
    @State private var selectedHand: ArchivedHandSelection?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(language.text("게임 돌아보기", "Game review")).font(GT.title(28))
                    Text(language.text("한 핸드씩 선택을 돌아보며 감을 익혀요.",
                                       "Build a feel for the game by reviewing one hand at a time."))
                        .font(GT.body(16)).foregroundStyle(GT.inkSecondary)
                    Text(language.text("최근에 마친 20게임과 현재 게임의 기록을 보관해요. 새 기록이 쌓이면 가장 오래된 완료 게임부터 삭제돼요.",
                                       "History keeps the latest 20 ended games plus the current game. Older ended games are removed as new games are saved."))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                        .accessibilityIdentifier("quick-game-retention")
                    ForEach(sessions.reversed()) { session in
                        sessionCard(session)
                    }
                }
                .gtContentEdge()
            }
            .accessibilityIdentifier("quick-game-scroll")
            .background(FeltBackground())
            .gtChrome(leading: { ChromeButton.close(onClose).accessibilityIdentifier("quick-game-close") })
            .fullScreenCover(item: $selectedHand) { hand in
                FreeTableHandCoachView(table: hand.table) { selectedHand = nil }
            }
        }
        .accessibilityIdentifier("quick-game-review")
    }

    private func sessionCard(_ session: QuickPlaySession) -> some View {
        let metrics = session.metrics
        return VStack(alignment: .leading, spacing: 14) {
            Text(status(session)).font(GT.title(22))
            Text(QuickPlayRecapWords.headline(folds: metrics.folds, checks: metrics.checks,
                calls: metrics.calls, bets: metrics.bets, raises: metrics.raises, language: language))
                .font(GT.semibold(17)).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("quick-game-headline")
            Text(language.text("저장된 핸드 \(session.coverageStartHandNumber + 1)–\(session.coverageStartHandNumber + metrics.hands) · \(metrics.hands)핸드",
                               "Saved hands \(session.coverageStartHandNumber + 1)–\(session.coverageStartHandNumber + metrics.hands) · \(metrics.hands) hands"))
                .font(GT.semibold(15)).accessibilityIdentifier("quick-game-coverage")
            if session.coverageStartHandNumber > 0 {
                Text(language.text("이 게임의 이전 핸드는 저장되지 않았어요. 아래 수치는 저장된 핸드만 포함해요.",
                                   "Earlier hands from this game were not saved. These counts cover only the saved hands."))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            }
            metric(language.text("칩 변화", "Chip change"), "\(metrics.netChips >= 0 ? "+" : "")\(metrics.netChips)")
            metric(language.text("자발적으로 참여한 핸드 / 저장된 핸드", "Voluntary entries / saved hands"), "\(metrics.voluntaryEntries) / \(metrics.hands)")
            metric(language.text("프리플랍에서 올린 핸드 / 참여한 핸드", "Preflop raises / entered hands"), "\(metrics.preflopRaises) / \(metrics.voluntaryEntries)")
            Text(language.text("각 행동 횟수 / 전체 선택 \(metrics.decisions)회", "Action counts / all \(metrics.decisions) decisions"))
                .font(GT.semibold(15))
            Text(language.text("폴드 \(metrics.folds) · 체크 \(metrics.checks) · 콜 \(metrics.calls) · 벳 \(metrics.bets) · 레이즈 \(metrics.raises)",
                               "Fold \(metrics.folds) · Check \(metrics.checks) · Call \(metrics.calls) · Bet \(metrics.bets) · Raise \(metrics.raises)"))
                .font(GT.body(15)).fixedSize(horizontal: false, vertical: true)
            Text(language.text("초보자 차트로 돌아본 선택 \(metrics.reviewedDecisions)회", "\(metrics.reviewedDecisions) decisions reviewed against the beginner chart"))
                .font(GT.semibold(15))
            Text(language.text("좋아요 \(metrics.good) / \(metrics.reviewedDecisions) · 괜찮아요 \(metrics.fine) / \(metrics.reviewedDecisions) · 신중히 \(metrics.risky) / \(metrics.reviewedDecisions)",
                               "Good \(metrics.good) / \(metrics.reviewedDecisions) · Fine \(metrics.fine) / \(metrics.reviewedDecisions) · Risky \(metrics.risky) / \(metrics.reviewedDecisions)"))
                .font(GT.body(15)).fixedSize(horizontal: false, vertical: true)
            Text(language.text("앱의 단순한 초보자 차트 기준이에요. 칩 결과와 선택 평가는 서로 달라요.",
                               "These labels use the app's simplified beginner chart. Chip results and decision reviews measure different things."))
                .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            ForEach(session.hands, id: \.handID) { hand in
                SecondaryCTAButton(title: language.text("\(hand.handNumber + 1)번째 핸드 돌아보기", "Review hand \(hand.handNumber + 1)")) {
                    selectedHand = ArchivedHandSelection(table: hand)
                }
                .accessibilityIdentifier("archive-hand-\(hand.handNumber + 1)")
            }
        }
        .gtInset(GT.Space.card, firstText: .title(22)).gtPanel()
    }

    private func metric(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name).font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            Text(value).font(GT.semibold(17)).monospacedDigit()
        }
    }

    private func status(_ session: QuickPlaySession) -> String {
        let reason = session.endReason ?? session.hands.last.flatMap { hand in
            hand.isGameOver ? (hand.seats[0].stack == 0 ? QuickPlayEndReason.learnerBusted : .completed) : nil
        }
        return switch reason {
        case .completed: language.text("게임 완료", "Game complete")
        case .learnerBusted: language.text("칩을 모두 써서 마친 게임", "Game ended with no chips remaining")
        case .endedEarly: language.text("중간에 마친 게임", "Game ended early")
        case nil: language.text("현재 게임", "Current game")
        }
    }
}

private struct ArchivedHandSelection: Identifiable {
    let table: PracticeTableState
    var id: String { table.handID }
}

/// Describes this game's saved actions only; tied actions share the same denominator.
enum QuickPlayRecapWords {
    static func headline(folds: Int, checks: Int, calls: Int, bets: Int, raises: Int,
                         language: LearningLanguage) -> String {
        let actions = [("폴드", "fold", folds), ("체크", "check", checks),
                       ("콜", "call", calls), ("벳", "bet", bets), ("레이즈", "raise", raises)]
        let total = actions.reduce(0) { $0 + $1.2 }
        guard let most = actions.map(\.2).max(), most > 0 else {
            return language.text("이 게임의 저장된 핸드에서는 직접 고른 행동이 없어요 · 0회",
                                 "No player decisions in this game's saved hands · 0 decisions")
        }
        let leaders = actions.filter { $0.2 == most }
        let names = leaders.map { language.text($0.0, $0.1) }
            .joined(separator: language == .korean ? "·" : ", ")
        if leaders.count == 1 {
            return language.text("이 게임의 저장된 핸드에서는 \(KO.object(names)) 가장 많이 골랐어요 · 전체 선택 \(total)번 중 \(most)번",
                                 "You chose to \(names) most often in this game's saved hands · \(most) of \(total) decisions")
        }
        return language.text("이 게임의 저장된 핸드에서는 \(KO.subject(names)) 가장 많았어요 · 각각 전체 선택 \(total)번 중 \(most)번",
                             "The most frequent choices in this game's saved hands were tied: \(names) · \(most) of \(total) decisions each")
    }
}
