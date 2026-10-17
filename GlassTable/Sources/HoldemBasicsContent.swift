// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import GlassTableDrills

/// Cards and numbers for the Hold'em basics lesson. Every hand name and share shown
/// on screen is derived from the engine; `HoldemBasicsContentTests` pins the examples
/// to the categories their rows claim.
enum HoldemBasics {
    /// The hand the first-run guide follows from the deal to the showdown: a pair of
    /// kings that uses both private cards and leaves two shared cards out.
    static let hole = Card.parse("AsKh")!
    static let board = Card.parse("Kd7c2h9sQh")!
    static var seven: [Card] { hole + board }
    static var bestFive: [Card] { bestFiveCards(seven) }
    static var bestBrief: HandBrief { bestHand(seven) }

    struct Rank: Identifiable {
        let id: String
        /// `HandBrief.category`; royal flush shares 8 with the straight flush.
        let category: Int
        let isRoyal: Bool
        let korean: String
        let english: String
        /// The English name inside a sentence: "flush", "two pair, K high".
        let englishInSentence: String
        let koreanDetail: String
        let englishDetail: String
        let example: [Card]

        var share: Double {
            if isRoyal { return HandFrequency.royalFlushShare }
            if category == 8 { return HandFrequency.straightFlushWithoutRoyalShare }
            return HandFrequency.share(ofCategory: category)
        }

        func name(in language: LearningLanguage) -> String { language.text(korean, english) }
        func sentenceName(in language: LearningLanguage) -> String { language.text(korean, englishInSentence) }
        func detail(in language: LearningLanguage) -> String {
            language.text(koreanDetail, englishDetail)
        }
    }

    /// Strongest first.
    static let ladder: [Rank] = [
        Rank(id: "royal", category: 8, isRoyal: true, korean: "로열 플러시", english: "Royal flush",
             englishInSentence: "royal flush",
             koreanDetail: "같은 무늬 A·K·Q·J·10", englishDetail: "A K Q J 10, one suit",
             example: Card.parse("AsKsQsJsTs")!),
        Rank(id: "straightFlush", category: 8, isRoyal: false, korean: "스트레이트 플러시",
             english: "Straight flush",
             englishInSentence: "straight flush",
             koreanDetail: "한 무늬로 이어진 5장", englishDetail: "Five in a row, one suit",
             example: Card.parse("9h8h7h6h5h")!),
        Rank(id: "quads", category: 7, isRoyal: false, korean: "포카드", english: "Four of a kind",
             englishInSentence: "four of a kind",
             koreanDetail: "같은 숫자 4장", englishDetail: "Four of one rank",
             example: Card.parse("QsQhQdQc7s")!),
        Rank(id: "fullHouse", category: 6, isRoyal: false, korean: "풀하우스", english: "Full house",
             englishInSentence: "full house",
             koreanDetail: "트리플과 원 페어", englishDetail: "Three of a kind and a pair",
             example: Card.parse("8s8h8dKcKs")!),
        Rank(id: "flush", category: 5, isRoyal: false, korean: "플러시", english: "Flush",
             englishInSentence: "flush",
             koreanDetail: "같은 무늬 5장", englishDetail: "Five of one suit",
             example: Card.parse("AdJd8d6d3d")!),
        Rank(id: "straight", category: 4, isRoyal: false, korean: "스트레이트", english: "Straight",
             englishInSentence: "straight",
             koreanDetail: "이어진 숫자 5장", englishDetail: "Five ranks in a row",
             example: Card.parse("Tc9d8h7s6c")!),
        Rank(id: "trips", category: 3, isRoyal: false, korean: "트리플", english: "Three of a kind",
             englishInSentence: "three of a kind",
             koreanDetail: "같은 숫자 3장", englishDetail: "Three of one rank",
             example: Card.parse("7c7d7hKs2d")!),
        Rank(id: "twoPair", category: 2, isRoyal: false, korean: "투 페어", english: "Two pair",
             englishInSentence: "two pair",
             koreanDetail: "페어 두 쌍", englishDetail: "Two different pairs",
             example: Card.parse("JsJd4c4hAs")!),
        Rank(id: "pair", category: 1, isRoyal: false, korean: "원 페어", english: "One pair",
             englishInSentence: "one pair",
             koreanDetail: "같은 숫자 2장", englishDetail: "Two of one rank",
             example: Card.parse("ThTcKs6d3c")!),
        Rank(id: "highCard", category: 0, isRoyal: false, korean: "하이 카드", english: "High card",
             englishInSentence: "high card",
             koreanDetail: "위 조합이 하나도 없음", englishDetail: "None of the above",
             example: Card.parse("AhJc8s5d2c")!),
    ]

    static func rank(_ id: String) -> Rank { ladder.first { $0.id == id }! }

    /// "1 in N hands", N to two significant figures: 2.3, 39, 600, 31,000.
    static func frequencyText(_ share: Double, in language: LearningLanguage) -> String {
        let hands = 1 / share
        let step = pow(10, floor(log10(hands)) - 1)
        let rounded = (hands / step).rounded() * step
        let number = rounded < 10 ? String(format: "%.1f", rounded)
            : Int(rounded).formatted(.number.locale(Locale(identifier: "en_US")))
        return language.text("\(number)판에 한 번", "1 in \(number) hands")
    }

    /// The check question: a flush against a straight on the same page.
    static let checkFlush = rank("flush")
    static let checkStraight = rank("straight")

    /// A later check's row, named after the hand it shows ("Two pair, K high").
    static func checkRank(id: String, hand: HandBrief, example: [Card]) -> Rank {
        let template = ladder.first { $0.category == hand.category && !$0.isRoyal }!
        return Rank(id: id, category: template.category, isRoyal: false,
                    korean: DrillTerms.hand(hand, in: .korean), english: DrillTerms.hand(hand, in: .english),
                    englishInSentence: DrillTerms.handInSentence(hand, in: .english),
                    koreanDetail: template.koreanDetail, englishDetail: template.englishDetail, example: example)
    }

    /// The line under the check's verdict. The English names the winner mid-sentence.
    static func answerText(winner: Rank, in language: LearningLanguage) -> String {
        language.text("\(winner.name(in: .korean)) 쪽이 이겨요. 먼저 족보를 비교하고, 같은 족보라면 조합을 만든 숫자부터 비교해요. 무늬에는 우열이 없어요.",
                      "The \(DrillTerms.closingAside(winner.sentenceName(in: .english))) wins. Compare the hand types first; when they match, compare the combination’s ranks. Suits have no ranking.")
    }

    /// The first check, dealt from seven cards like every later one: my A-high flush
    /// (A♦ J♦ with K♦ 8♦ 6♦) against the opponent's 9-high straight (9♣ 5♥ with
    /// 8♦ 7♠ 6♦). Both use their two private cards; nothing pairs and the board alone
    /// is only a high card.
    static let firstCheck = ShowdownSpot(hero: Card.parse("AdJd")!, villain: Card.parse("9c5h")!,
                                         board: Card.parse("Kd8d7s6d2c")!)

    /// The third check: the same pair of Js on both sides, A♠ J♥ against Q♦ J♣ on
    /// J♠ 8♦ 5♣ 3♥ 2♠. The pair cannot settle it; the A kicker does.
    static let kickerCheck = ShowdownSpot(hero: Card.parse("AsJh")!, villain: Card.parse("QdJc")!,
                                          board: Card.parse("Js8d5c3h2s")!)

    /// The cards of a one-pair hand's pair, from the five that play.
    static func pairCards(_ hand: BestFiveHand) -> [Card] {
        hand.used.filter { $0.rank == hand.brief.topRank }
    }

    /// "J 페어는 같아요" over the kicker duel.
    static func samePairLine(_ hand: BestFiveHand, in language: LearningLanguage) -> String {
        let rank = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"][hand.brief.topRank - 2]
        return language.text("\(rank) 페어는 같아요", "The pair of \(rank)s is the same")
    }
}
