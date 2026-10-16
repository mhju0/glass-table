// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Whose seven cards a best-five row reads, for its count line and the why sentence.
public enum BestFiveOwner: Equatable, Sendable {
    case learner
    case opponent
    /// A named seat at the free table ("토마스", "Tom").
    case seat(korean: String, english: String)

    public func title(in language: LearningLanguage) -> String {
        switch self {
        case .learner: language.text("내 패", "Your hand")
        case .opponent: language.text("상대 패", "Opponent's hand")
        case let .seat(korean, english): language.text(korean, english)
        }
    }

    /// "내 K 투 페어", "토마스의 A"
    var koreanPossessive: String {
        switch self {
        case .learner: "내"
        case .opponent: "상대"
        case let .seat(korean, _): korean + "의"
        }
    }

    /// "내 쪽", "토마스 쪽"
    var koreanSide: String {
        switch self {
        case .learner: "내"
        case .opponent: "상대"
        case let .seat(korean, _): korean
        }
    }

    func englishPossessive(capitalized: Bool) -> String {
        switch self {
        case .learner: capitalized ? "Your" : "your"
        case .opponent: capitalized ? "The opponent's" : "the opponent's"
        case let .seat(_, english): english + "'s"
        }
    }
}

/// One player's seven cards read as the five that play.
public struct BestFiveHand: Equatable {
    public let owner: BestFiveOwner
    public let hole: [Card]
    public let board: [Card]
    /// The five that play, in the order hands are compared.
    public let used: [Card]
    /// Cards whose rank broke a tie between two same-name hands (a kicker, or the
    /// second pair). Empty when the hand names differ or the pot is split.
    public let deciding: [Card]
    public let brief: HandBrief

    public var seven: [Card] { hole + board }
    public var unused: [Card] { seven.filter { !used.contains($0) } }
    public var holeCardsUsed: Int { used.filter(hole.contains).count }
    public var boardCardsUsed: Int { used.count - holeCardsUsed }

    public func name(in language: LearningLanguage) -> String { DrillTerms.hand(brief, in: language) }

    /// "내 카드 2장 · 공용 카드 3장" / "2 of your cards · 3 board cards"
    public func countLine(in language: LearningLanguage) -> String {
        let mine = holeCardsUsed, shared = boardCardsUsed
        if language == .english {
            return "\(mine) of \(owner.englishPossessive(capitalized: false)) cards · \(shared) board cards"
        }
        return "\(owner.koreanPossessive) 카드 \(mine)장 · 공용 카드 \(shared)장"
    }
}

/// Two players' best fives side by side, for the explanation shown after an answer
/// is locked in. Pure data: which five of seven each player uses, the card that
/// decided a same-name contest, and the sentence under the rows.
public struct BestFivePair: Equatable {
    public let first: BestFiveHand
    public let second: BestFiveHand
    /// 0 when the first hand wins, 1 when the second does, 2 for a split pot.
    public let winner: Int
    /// Both players' best five is the board itself.
    public let boardPlays: Bool

    public var rows: [BestFiveHand] { [first, second] }

    /// The lesson reading: the learner's hand first, the opponent's second.
    public init(_ spot: ShowdownSpot) {
        self.init(first: spot.hero, firstOwner: .learner,
                  second: spot.villain, secondOwner: .opponent, board: spot.board)
    }

    public init(first: [Card], firstOwner: BestFiveOwner,
                second: [Card], secondOwner: BestFiveOwner, board: [Card]) {
        precondition(first.count == 2 && second.count == 2 && board.count == 5)
        let spot = ShowdownSpot(hero: first, villain: second, board: board)
        let winner = compareHands(hero: first + board, villain: second + board)
        let boardPlays = showdownBoardPlays(spot)
        // Board cards first, so a hole card that only repeats a board rank is not
        // counted as used: the evaluator keeps the first of equal fives it meets.
        let boardFive = bestFiveCards(board)
        let firstFive = boardPlays ? boardFive : bestFiveCards(board + first)
        let secondFive = boardPlays ? boardFive : bestFiveCards(board + second)
        var firstDeciding: [Card] = [], secondDeciding: [Card] = []
        if winner != 2, spot.heroBest == spot.villainBest,
           let i = decidingIndex(firstFive, secondFive) {
            firstDeciding = firstFive.filter { $0.rank == firstFive[i].rank }
            secondDeciding = secondFive.filter { $0.rank == secondFive[i].rank }
        }
        self.first = BestFiveHand(owner: firstOwner, hole: first, board: board, used: firstFive,
                                  deciding: firstDeciding, brief: spot.heroBest)
        self.second = BestFiveHand(owner: secondOwner, hole: second, board: board, used: secondFive,
                                   deciding: secondDeciding, brief: spot.villainBest)
        self.winner = winner
        self.boardPlays = boardPlays
    }

    /// The line under the rows. A win or a tie with hole cards reads exactly as the
    /// reveal does; a board that plays says plainly that the pot is split.
    public func why(in language: LearningLanguage) -> String {
        if boardPlays {
            let addressesLearner = first.owner == .learner || second.owner == .learner
            return language.text("둘 다 공용 카드 다섯 장을 써서 팟을 나눠요.",
                                 addressesLearner ? "You both play the board, so the pot is split."
                                                  : "Both players play the board, so the pot is split.")
        }
        if winner == 2 {
            return showdownTieWhy(ShowdownSpot(hero: first.hole, villain: second.hole, board: first.board),
                                  language: language)
        }
        let (win, lose) = winner == 0 ? (first, second) : (second, first)
        return showdownWhy(winner: win.name(in: language), loser: lose.name(in: language),
                           winFive: win.used, loseFive: lose.used,
                           winnerSide: win.owner, loserSide: lose.owner, language: language)
    }
}

extension PracticeTableReview {
    /// The main pot's winner and whoever came closest to beating them, for the
    /// best-five comparison in the hand review. In a split the learner comes first.
    /// Nil unless the hand reached a showdown on a full board.
    public var bestFiveShowdownPair: (winner: Int, rival: Int)? {
        guard board.count == 5, let boardCards = Card.parse(board.joined()),
              let main = pots.filter({ $0.eligibleSeats.count > 1 })
                  .max(by: { $0.eligibleSeats.count < $1.eligibleSeats.count }),
              let first = main.winners.min() else { return nil }
        func seven(_ seat: Int) -> [Card]? {
            guard holeCards.indices.contains(seat), let hole = Card.parse(holeCards[seat].joined()),
                  hole.count == 2 else { return nil }
            return hole + boardCards
        }
        if main.winners.count > 1 {
            let others = main.winners.filter { $0 != first }.sorted()
            return (first, others[0])
        }
        // Strongest first; equal hands keep the lower seat, so the learner leads a tie.
        let rivals = main.eligibleSeats.filter { $0 != first }.sorted()
        var best: Int?
        for seat in rivals {
            guard let mine = seven(seat) else { continue }
            if let current = best, let theirs = seven(current),
               compareHands(hero: mine, villain: theirs) != 0 { continue }
            best = seat
        }
        guard let rival = best, seven(first) != nil else { return nil }
        return (first, rival)
    }
}
