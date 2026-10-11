// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

public struct OutsReveal: Equatable {
    public let band: GradeBand
    public let estimate: Int
    public let outs: [Card]
    public let excluded: [Card]
    public let improvementPct: Double
    public let whyText: String
}

/// Grade an out-count estimate against a spot. Bands: exact = 정확, ±2 = 근접, else = 빗나감.
public func gradeOuts(estimate: Int, spot: OutsSpot,
                      language: LearningLanguage = .korean) -> OutsReveal {
    let band = gradeEstimate(user: Double(estimate), correct: Double(spot.outCount),
                             closeWithin: 2, spotOnWithin: 0)
    return OutsReveal(band: band, estimate: estimate, outs: spot.outs, excluded: spot.excluded,
                      improvementPct: spot.improvementPct, whyText: whyText(for: spot, language: language))
}

/// What a tapped river card does for both players, including a split pot.
public struct RiverExplanation: Equatable {
    public let hero: HandBrief
    public let villain: HandBrief
    public let heroWins: Bool
    public let isTie: Bool
}

public func explainRiver(spot: OutsSpot, river: Card) -> RiverExplanation {
    let full = spot.board + [river]
    return RiverExplanation(hero: bestHand(spot.hero + full),
                            villain: bestHand(spot.villain + full),
                            heroWins: spot.outs.contains(river),
                            isTie: compareHands(hero: spot.hero + full, villain: spot.villain + full) == 2)
}

/// Beginner-facing Korean hand name, using the same letter ranks as the cards.
public func handName(_ b: HandBrief) -> String {
    let ranks = [2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8", 9: "9",
                 10: "10", 11: "J", 12: "Q", 13: "K", 14: "A"]
    let r = ranks[b.topRank] ?? "?"
    switch b.category {
    case 0: return "\(r) 하이"
    case 1: return "\(r) 원 페어"
    case 2: return "\(r) 투 페어"
    case 3: return "\(r) 트리플"
    case 4: return "\(r) 하이 스트레이트"
    case 5: return "\(r) 하이 플러시"
    case 6: return "\(r) 풀하우스"
    case 7: return "\(r) 포카드"
    default: return b.topRank == 14 ? "로열 플러시" : "\(r) 하이 스트레이트 플러시"
    }
}

func whyText(for spot: OutsSpot, language: LearningLanguage = .korean) -> String {
    if language == .english {
        guard !spot.excluded.isEmpty else { return "\(spot.outCount) winning river cards." }
        let apparent = spot.outCount + spot.excluded.count
        return "\(apparent) cards look promising. \(excludedRiverReasons(spot, language: language)) There are \(spot.outCount) winning river cards."
    }
    guard !spot.excluded.isEmpty else { return "이기는 리버 카드 \(spot.outCount)장." }
    let apparent = spot.outCount + spot.excluded.count
    return "\(apparent) 아웃처럼 보이지만, \(excludedRiverReasons(spot, language: language)) 이기는 리버 카드는 \(spot.outCount)장."
}

func excludedRiverReasons(_ spot: OutsSpot, language: LearningLanguage) -> String {
    let ties = spot.excluded.filter { explainRiver(spot: spot, river: $0).isTie }
    let losses = spot.excluded.filter { !ties.contains($0) }
    var reasons: [String] = []
    if !ties.isEmpty {
        let cards = ties.map(\.display).joined(separator: " · ")
        reasons.append(language.text("\(KO.topic(cards)) 무승부라서 이기는 아웃에서 제외돼요.",
                                     "\(cards) tie the hand, so they are not outright winning outs."))
    }
    if !losses.isEmpty {
        let cards = losses.map(\.display).joined(separator: " · ")
        reasons.append(language.text("\(KO.topic(cards)) 상대가 이겨서 아웃에서 제외돼요.",
                                     "\(cards) leave the opponent ahead, so they are not winning outs."))
    }
    return reasons.joined(separator: " ")
}

func currentOutsSituation(_ spot: OutsSpot, language: LearningLanguage) -> String {
    switch compareHands(hero: spot.hero + spot.board, villain: spot.villain + spot.board) {
    case 0: return language.text("지금은 앞서 있어요. 리버에서도 단독으로 이기는 카드를 세어요.",
                                 "You are ahead now. Count river cards where you still win outright.")
    case 1: return language.text("지금은 상대가 앞서 있어요. 리버에서 단독으로 이기는 카드를 세어요.",
                                 "The opponent is ahead now. Count river cards where you win outright.")
    default: return language.text("지금은 무승부예요. 리버에서 단독으로 이기는 카드를 세어요.",
                                  "You are tied now. Count river cards where you win outright.")
    }
}
