import GlassTableDrills

enum GradedTableLearning {
    static func takeaway(_ turn: TableView.TurnRecord, language: LearningLanguage) -> String {
        switch turn.verdict {
        case let .chart(verdict):
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
            return language.text("현재 상대 레인지와 공개된 규칙으로 계산해요. 이후 베팅과 레이크는 제외하며, 플랍은 표본 추정이에요. bb는 빅 블라인드 한 개만큼의 칩이에요.",
                                 "Uses the current possible opponent hands and published rules. Later bets and fees are excluded; the flop uses a sampled estimate. bb is the chip amount of one big blind.")
        }
    }
}
