import GlassTableDrills
import GlassTableEngine

enum GradedTableLearning {
    static func takeaway(_ turn: TableView.TurnRecord, hand: TableHand?, language: LearningLanguage) -> String {
        switch turn.verdict {
        case let .chart(verdict):
            // The opener's rule and this hand's place in it, as the defend lesson shows.
            if let hand, let handClass = HandClass(hand.hero) {
                return DefendChart.reason(for: handClass, vsOpenFrom: hand.villainSeat, language: language)
            }
            switch verdict.chart {
            case .fold:
                return language.text("이 시작 패는 차트에서 내려놓는 쪽에 속해요.",
                                     "The chart puts this starting hand in the fold group.")
            case .call:
                return language.text("이 시작 패는 차트에서 따라가는 쪽에 속해요. 다시 올리는 패와는 구분해요.",
                                     "The chart puts this starting hand in the call group, separate from hands that raise again.")
            case .threeBet:
                return language.text("이 시작 패는 차트에서 다시 올리는 쪽에 속해요. 공용 카드가 나오기 전의 기준이에요.",
                                     "The chart puts this starting hand in the raise-again group. This rule applies before the shared cards.")
            }
        case let .ev(_, best):
            return language.text("이후 베팅이 없다고 보면, \(KO.subject(best.label(in: language))) 평균적으로 가장 많은 값을 남겨요. 실제 플레이에서는 이후 행동도 중요해요.",
                                 "With no later bets, \(best.label(in: language)) has the highest average value here. Later actions matter in real play.")
        }
    }

    static func basis(_ turn: TableView.TurnRecord, language: LearningLanguage) -> String {
        switch turn.verdict {
        case .chart:
            return language.text("앱의 공개된 디펜드 차트와 비교했어요. 칩 손실을 계산한 점수는 아니에요. bb는 빅 블라인드 한 개만큼의 칩이에요.",
                                 "Compared with the app's published defend chart, not an estimate of chips lost. bb is the chip amount of one big blind.")
        case .ev:
            return language.text("현재 상대 레인지와 공개된 규칙으로 계산해요. 이후 베팅과 레이크는 제외하며, 플랍은 표본 추정이에요. 값은 지금부터 받을 칩에서 더 넣을 칩을 뺀 평균이에요. 이미 팟에 넣은 칩은 세지 않아서 폴드는 0bb예요. bb는 빅 블라인드 한 개만큼의 칩이에요.",
                                 "Uses the current possible opponent hands and published rules. Later bets and fees are excluded; the flop uses a sampled estimate. Values average the chips you collect from here minus the chips you add from here. Chips already in the pot don't count, so folding is 0bb. bb is the chip amount of one big blind.")
        }
    }
}
