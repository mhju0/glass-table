// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

/// `sheet(item:)` currency for the replay sheets in 기록.
extension Concept: @retroactive Identifiable {
    public var id: String { rawValue }
}

/// Korean title for a concept, taken from the node that teaches it so the path and
/// every other surface can never drift apart.
func conceptTitle(_ c: Concept) -> String {
    Curriculum.allNodes.first { Curriculum.taughtConcept(of: $0) == c }?.title
        ?? c.rawValue
}

func conceptBlurb(_ c: Concept, language: LearningLanguage = .korean) -> String {
    switch c {
    case .showdown:    return language.text("누가 이겼는지 읽어요", "Read who won the hand")
    case .potMath:     return language.text("팟이 얼마인지 세요", "Count the chips in the pot")
    case .position:    return language.text("내 뒤에 몇 명이 남았는지 세요", "Count the players still to act")
    case .combos:      return language.text("내 카드가 지운 상대 콤보를 세요", "Count the combos your cards remove")
    case .potOdds:     return language.text("낼 가격을 필요 에퀴티로 바꿔요", "Turn the price into needed equity")
    case .outs:        return language.text("이기는 카드를 세서 확률로 바꿔요", "Count winning cards, then the chance")
    case .equitySense: return language.text("이길 확률을 눈대중으로 맞춰요", "Estimate your chance to win")
    case .evCall:      return language.text("콜했을 때의 기대값을 계산해요", "Work out what a call is worth")
    case .callFold:    return language.text("이길 확률과 낼 가격을 비교해요", "Compare your chance to win with the price")
    case .rangeNotation: return language.text("핸드 묶음이 몇 콤보인지 세요", "Count the combos in hand shorthand")
    case .rfi:           return language.text("이 자리에서 열 핸드인지 판단해요", "Decide whether to open from this seat")
    case .rangeRead:     return language.text("상대의 행동을 보고 가능한 패를 좁혀요", "Narrow their hands from their actions")
    case .hitFrequency:  return language.text("이 보드가 레인지의 몇 %를 맞혔는지 세요", "Count how much of a range this board hits")
    case .rangeAdvantage: return language.text("이 보드가 누구에게 유리한지 판단해요", "Decide who this board favors")
    case .evLoss:      return language.text("고른 쪽이 몇 bb를 버렸는지 확인해요", "See how many bb a choice gave up")
    case .actionRead:  return language.text("벳과 체크 뒤에 남는 패의 범위를 읽어요", "Read the hands behind a bet or check")
    case .defend:      return language.text("오픈에 맞서 폴드·콜·3벳을 판단해요", "Fold, call or 3-bet against a raise")
    case .mdf:         return language.text("얼마나 자주 지켜야 하는지 계산해요", "Work out how often to continue")
    }
}
