// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Names are chosen from model values. Never translate a composed Korean sentence.
public enum DrillTerms {
    public static func actor(_ actor: PotMathSpot.Actor, in language: LearningLanguage) -> String {
        guard language == .english else { return actor.rawValue }
        switch actor {
        case .sb: return "SB"
        case .bb: return "BB"
        case .opener: return "Player A"
        case .caller1: return "Player B"
        case .caller2: return "Player C"
        }
    }

    public static func hand(_ hand: HandBrief, in language: LearningLanguage) -> String {
        guard language == .english else { return handName(hand) }
        let rank = Card.displayRanks[hand.topRank - 2]
        switch hand.category {
        case 0: return "\(rank) high"
        case 1: return "Pair of \(rank)s"
        case 2: return "Two pair, \(rank) high"
        case 3: return "Three \(rank)s"
        case 4: return "\(rank)-high straight"
        case 5: return "\(rank)-high flush"
        case 6: return "Full house, \(rank)s"
        case 7: return "Four \(rank)s"
        default: return hand.topRank == 14 ? "Royal flush" : "\(rank)-high straight flush"
        }
    }

    public static func action(_ action: DefendAction, in language: LearningLanguage) -> String {
        guard language == .english else { return action.rawValue }
        switch action {
        case .fold: return "Fold"
        case .call: return "Call"
        case .threeBet: return "Raise again"
        }
    }

    public static func madeHand(_ hand: MadeHand, in language: LearningLanguage) -> String {
        guard language == .english else { return hand.korean }
        switch hand {
        case .air: return "No pair"
        case .weakPair: return "Weak pair"
        case .topPair: return "Top pair"
        case .strong: return "Two pair or better"
        case .draw: return "Draw"
        }
    }

    public static func tendency(_ tendency: RangeTendency, in language: LearningLanguage) -> String {
        guard language == .english else { return tendencyWord(tendency) }
        switch tendency {
        case .pairs: return "Pairs"
        case .suited: return "Same-suit hands"
        case .offsuitBroadway: return "High cards of different suits"
        case .connectors: return "Neighboring ranks"
        }
    }

    public static func suit(_ suit: Int, in language: LearningLanguage) -> String {
        guard language == .english else { return suitKoreanName(suit) }
        return ["clubs", "diamonds", "hearts", "spades"][suit]
    }

    public static func board(_ texture: BoardTexture, in language: LearningLanguage) -> String {
        guard language == .english else { return texture.summary }
        let suitShape: String
        if texture.topSuitCount == texture.cardCount { suitShape = "one suit" }
        else if texture.topSuitCount >= 3 { suitShape = "flush possible" }
        else if texture.topSuitCount == 2 { suitShape = "two suits" }
        else { suitShape = "three suits" }
        var parts = ["\(Card.displayRanks[texture.highCard - 2]) high", suitShape]
        if texture.isPaired { parts.append("paired board") }
        if texture.straightiness >= 2 { parts.append("straight friendly") }
        return parts.joined(separator: " · ")
    }

    /// The hand's score worked out with the rule card's own words, ending on the score.
    public static func chen(_ hand: HandClass, in language: LearningLanguage) -> String {
        let english = language == .english
        let high = hand.high
        let rank = Card.displayRanks[high - 2]
        let base: Double = high == 14 ? 10 : high == 13 ? 8 : high == 12 ? 7
            : high == 11 ? 6 : Double(high) / 2
        let score = signed(Chen.score(hand))
        if hand.isPair {
            let points = english ? (base == 1 ? " point" : " points") : "점"
            var line = "\(rank) \(pctText(base))\(points) × 2 = \(pctText(base * 2))"
            if base * 2 < 5 { line += english ? " → pair minimum 5" : " → 페어 최소 5" }
            return line + (base * 2 < 5 ? " = \(score)" : "")
        }
        let penalty = hand.gap == 0 ? 0 : hand.gap == 1 ? 1 : hand.gap == 2 ? 2
            : hand.gap == 3 ? 4 : 5
        var parts = ["\(rank) \(pctText(base))"]
        if hand.suited { parts.append(english ? "same suit +2" : "같은 무늬 +2") }
        if hand.gap == 0 {
            parts.append(english ? "no gap" : "간격 없음")
        } else if english {
            parts.append("\(hand.gap) missing rank\(hand.gap == 1 ? "" : "s") −\(penalty)")
        } else {
            parts.append("빈 숫자 \(hand.gap)개 −\(penalty)")
        }
        if hand.gap <= 1 && hand.high < 12 { parts.append(english ? "both below Q +1" : "둘 다 Q보다 낮음 +1") }
        return parts.joined(separator: " · ") + " = \(score)"
    }

    /// A score with a typographic minus, matching the rule card.
    private static func signed(_ x: Double) -> String {
        x < 0 ? "−" + pctText(-x) : pctText(x)
    }
}
