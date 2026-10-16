// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// The rule card that explains the starting-hand score behind the open chart.
public enum ChenScoreCopy {
    public static func title(in language: LearningLanguage) -> String {
        language.text("점수 계산법", "How the score works")
    }

    public static func intro(in language: LearningLanguage) -> String {
        language.text("차트는 169가지 시작 패를 빌 첸(Bill Chen)의 어림 규칙을 바탕으로 한 점수로 줄 세워요. 높을수록 좋아요.",
                      "The chart ranks all 169 starting hands by a score based on Bill Chen's rule of thumb. Higher is better.")
    }

    public static func rules(in language: LearningLanguage) -> [String] {
        language == .english ? [
            "Start from your higher card: A 10 · K 8 · Q 7 · J 6 · 10 to 2 count half (9 = 4.5)",
            "Pair: double it, at least 5",
            "Same suit: +2",
            "Missing ranks between: 1 → −1 · 2 → −2 · 3 → −4 · 4+ → −5",
            "Both below Q, at most one missing rank, not a pair: +1",
        ] : [
            "높은 카드 한 장으로 시작: A 10 · K 8 · Q 7 · J 6 · 10~2는 숫자의 절반 (9 = 4.5)",
            "페어: 두 배, 최소 5",
            "같은 무늬: +2",
            "두 숫자 사이 빈 숫자: 1개 −1 · 2개 −2 · 3개 −4 · 4개 이상 −5",
            "둘 다 Q보다 낮고 빈 숫자 1개 이하(페어 제외): +1",
        ]
    }

    /// "Your hand A♠K♠: …", worked out for the cards actually dealt.
    public static func handLine(_ cards: [Card], in language: LearningLanguage) -> String {
        guard let hand = HandClass(cards) else { return "" }
        // Higher card first, the same order as the line's starting card.
        let shown = cards.sorted { $0.rank > $1.rank }.map(\.display).joined()
        return language.text("내 패 \(shown): ", "Your hand \(shown): ") + DrillTerms.chen(hand, in: language)
    }

    public static func closing(in language: LearningLanguage) -> String {
        language.text("차트용으로 패를 줄 세우는 점수예요. 이길 확률이 아니에요.",
                      "It sorts hands for the chart. It is not your chance of winning.")
    }
}
