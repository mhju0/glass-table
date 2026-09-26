// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import GlassTableEngine
import GlassTableDrills

/// Cards and numbers for the Hold'em basics lesson. Every hand name and share shown
/// on screen is derived from the engine; `HoldemBasicsContentTests` pins the examples
/// to the categories their rows claim.
enum HoldemBasics {
    /// The hand dealt on the first page and read on the second: a heart flush that
    /// uses both private cards and leaves two shared cards out.
    static let hole = Card.parse("AhTh")!
    static let board = Card.parse("Kh9h2c4hJs")!
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
        let koreanDetail: String
        let englishDetail: String
        let example: [Card]

        var share: Double {
            if isRoyal { return HandFrequency.royalFlushShare }
            if category == 8 { return HandFrequency.straightFlushWithoutRoyalShare }
            return HandFrequency.share(ofCategory: category)
        }

        func name(in language: LearningLanguage) -> String { language.text(korean, english) }
        func detail(in language: LearningLanguage) -> String {
            language.text(koreanDetail, englishDetail)
        }
    }

    /// Strongest first.
    static let ladder: [Rank] = [
        Rank(id: "royal", category: 8, isRoyal: true, korean: "로열 플러시", english: "Royal flush",
             koreanDetail: "같은 무늬 A·K·Q·J·10", englishDetail: "A K Q J 10, one suit",
             example: Card.parse("AsKsQsJsTs")!),
        Rank(id: "straightFlush", category: 8, isRoyal: false, korean: "스트레이트 플러시",
             english: "Straight flush",
             koreanDetail: "한 무늬로 이어진 5장", englishDetail: "Five in a row, one suit",
             example: Card.parse("9h8h7h6h5h")!),
        Rank(id: "quads", category: 7, isRoyal: false, korean: "포카드", english: "Four of a kind",
             koreanDetail: "같은 숫자 4장", englishDetail: "Four of one rank",
             example: Card.parse("QsQhQdQc7s")!),
        Rank(id: "fullHouse", category: 6, isRoyal: false, korean: "풀하우스", english: "Full house",
             koreanDetail: "트리플과 원페어", englishDetail: "Three of a kind and a pair",
             example: Card.parse("8s8h8dKcKs")!),
        Rank(id: "flush", category: 5, isRoyal: false, korean: "플러시", english: "Flush",
             koreanDetail: "같은 무늬 5장", englishDetail: "Five of one suit",
             example: Card.parse("AdJd8d6d3d")!),
        Rank(id: "straight", category: 4, isRoyal: false, korean: "스트레이트", english: "Straight",
             koreanDetail: "이어진 숫자 5장", englishDetail: "Five ranks in a row",
             example: Card.parse("Tc9d8h7s6c")!),
        Rank(id: "trips", category: 3, isRoyal: false, korean: "트리플", english: "Three of a kind",
             koreanDetail: "같은 숫자 3장", englishDetail: "Three of one rank",
             example: Card.parse("7c7d7hKs2d")!),
        Rank(id: "twoPair", category: 2, isRoyal: false, korean: "투페어", english: "Two pair",
             koreanDetail: "페어 두 쌍", englishDetail: "Two different pairs",
             example: Card.parse("JsJd4c4hAs")!),
        Rank(id: "pair", category: 1, isRoyal: false, korean: "원페어", english: "One pair",
             koreanDetail: "같은 숫자 2장", englishDetail: "Two of one rank",
             example: Card.parse("ThTcKs6d3c")!),
        Rank(id: "highCard", category: 0, isRoyal: false, korean: "하이 카드", english: "High card",
             koreanDetail: "위 조합이 하나도 없음", englishDetail: "None of the above",
             example: Card.parse("AhJc8s5d2c")!),
    ]

    static func rank(_ id: String) -> Rank { ladder.first { $0.id == id }! }

    /// Two significant figures below 1%, one decimal place above: 0.0032%, 0.17%, 4.6%.
    static func percentText(_ share: Double) -> String {
        let percent = share * 100
        if percent >= 1 { return String(format: "%.1f%%", percent) }
        let digits = max(0, 1 - Int(floor(log10(percent))))
        return String(format: "%.\(digits)f%%", percent)
    }

    /// The check question: a flush against a straight on the same page.
    static let checkFlush = rank("flush")
    static let checkStraight = rank("straight")
}
