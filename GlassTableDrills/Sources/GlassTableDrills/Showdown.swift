// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// One 쇼다운 spot: two hands on a complete five-card board. "Who wins?"
///
/// The root node of the whole curriculum. Everything downstream assumes the user can
/// read a board, and an honest beginner often can't — counterfeited two pair and a
/// board that plays are the classic misreads, so the generator seeks them out.
public struct ShowdownSpot: Equatable {
    public let hero: [Card]      // 2
    public let villain: [Card]   // 2
    public let board: [Card]     // 5

    public init(hero: [Card], villain: [Card], board: [Card]) {
        self.hero = hero; self.villain = villain; self.board = board
    }

    /// Beginner-facing summaries, for display only. `HandBrief` is deliberately lossy
    /// (category + defining rank), so it must never decide the winner: two different
    /// two-pair hands can share a category and top rank and still not be a chop.
    public var heroBest: HandBrief { bestHand(hero + board) }
    public var villainBest: HandBrief { bestHand(villain + board) }

    /// 0 = hero wins, 1 = villain wins, 2 = chop.
    ///
    /// Decided by the engine's exact equity on a complete board, which is a single
    /// enumerated trial (`forEachCombination(choose: 0)` runs the body once). That
    /// routes through the same full 7-card evaluator the equity core is
    /// correctness-proven against, instead of re-deriving comparison logic here.
    public var winner: Int {
        let r = exactEquityHeadsUp(hero: hero, villain: villain, board: board)
        if r.ties == 1 { return 2 }
        return r.wins == 1 ? 0 : 1
    }
}

public enum ShowdownSpotGenerator {
    #if DEBUG
    /// Screenshot and UI-test hook, set once at launch from `GT_DEMO_SHOWDOWN_SPOT`.
    /// It replaces every generated spot, so the question, its reveal and a restored
    /// answer all read the same cards. Debug builds only.
    nonisolated(unsafe) public static var demoSpot: ShowdownSpot?
    #endif

    public static func spot(baseSeed: UInt64, index: Int) -> ShowdownSpot {
        #if DEBUG
        if let demoSpot { return demoSpot }
        #endif
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        var deck = Deck.all
        deck.shuffle(using: &rng)
        return ShowdownSpot(hero: Array(deck[0..<2]),
                            villain: Array(deck[2..<4]),
                            board: Array(deck[4..<9]))
    }
}

public struct ShowdownReveal: Equatable {
    public let band: GradeBand
    public let answer: Int
    public let winner: Int
    public let heroName: String
    public let villainName: String
    public let whyText: String
}

// Hand naming reuses the shipped `handName` in Reveal.swift — the outs reveal and the
// showdown drill must never name the same hand two different ways.

public func gradeShowdown(answer: Int, spot: ShowdownSpot,
                          language: LearningLanguage = .korean) -> ShowdownReveal {
    let w = spot.winner
    let hName = DrillTerms.hand(spot.heroBest, in: language)
    let vName = DrillTerms.hand(spot.villainBest, in: language)
    let why: String
    switch w {
    case 0: why = showdownWhy(winner: spot.heroBest, loser: spot.villainBest, spot: spot, heroWon: true, language: language)
    case 1: why = showdownWhy(winner: spot.villainBest, loser: spot.heroBest, spot: spot, heroWon: false, language: language)
    default: why = showdownTieWhy(spot, language: language)
    }
    return ShowdownReveal(band: answer == w ? .spotOn : .off,
                          answer: answer, winner: w,
                          heroName: hName, villainName: vName, whyText: why)
}

/// A tie means the two exact best-five strengths match. It does not necessarily
/// mean the board plays: two players can use different hole cards to make the same
/// straight, flush, or kicked hand.
func showdownTieWhy(_ spot: ShowdownSpot, language: LearningLanguage = .korean) -> String {
    let name = DrillTerms.handInSentence(spot.heroBest, in: language)
    if language == .english {
        return showdownBoardPlays(spot)
            ? "The five shared cards make the best hand for both players: \(name). It is a tie."
            : "Both players make equally strong five-card hands: \(name). It is a tie."
    }
    if showdownBoardPlays(spot) {
        return "공용 카드 다섯 장이 두 사람의 가장 강한 패라서 비겨요. 완성한 패는 둘 다 \(KO.copula(name))"
    }
    return "두 사람이 가장 강한 다섯 장으로 만든 패의 세기가 같아서 비겨요. 완성한 패는 둘 다 \(KO.copula(name))"
}

/// `HandBrief` omits kickers, so identifying a board-play tie also compares the
/// ranks in the exact five cards selected by the evaluator.
func showdownBoardPlays(_ spot: ShowdownSpot) -> Bool {
    let boardFive = bestFiveCards(spot.board)
    let boardBrief = bestHandOfAny(boardFive)
    let boardRanks = boardFive.map(\.rank).sorted(by: >)

    func matchesBoard(_ cards: [Card]) -> Bool {
        let five = bestFiveCards(cards)
        return bestHandOfAny(five) == boardBrief
            && five.map(\.rank).sorted(by: >) == boardRanks
    }

    return matchesBoard(spot.hero + spot.board)
        && matchesBoard(spot.villain + spot.board)
}

/// When both hands share a name — two players on the same trips, say — "3 트리플이 3
/// 트리플을 이겨요" is true and useless. The card that decided it — a kicker, the second
/// pair of two pair, or the pair of a full house — is what the sentence has to name.
func showdownWhy(winner: HandBrief, loser: HandBrief, spot: ShowdownSpot, heroWon: Bool,
                 language: LearningLanguage = .korean) -> String {
    showdownWhy(winner: winner, loser: loser,
                winFive: bestFiveCards((heroWon ? spot.hero : spot.villain) + spot.board),
                loseFive: bestFiveCards((heroWon ? spot.villain : spot.hero) + spot.board),
                winnerSide: heroWon ? .learner : .opponent,
                loserSide: heroWon ? .opponent : .learner, language: language)
}

func showdownWhy(winner winnerHand: HandBrief, loser loserHand: HandBrief, winFive: [Card], loseFive: [Card],
                 winnerSide: BestFiveOwner, loserSide: BestFiveOwner,
                 language: LearningLanguage) -> String {
    let winner = DrillTerms.handInSentence(winnerHand, in: language)
    let loser = DrillTerms.handInSentence(loserHand, in: language)
    guard winner == loser else {
        if language == .english {
            return "\(winnerSide.englishPossessive(capitalized: true)) \(DrillTerms.closingAside(winner)) beats \(loserSide.englishPossessive(capitalized: false)) \(loser)."
        }
        return "\(winnerSide.koreanPossessive) \(KO.subject(winner)) \(loserSide.koreanPossessive) \(KO.object(loser)) 이겨요."
    }
    if let i = decidingIndex(winFive, loseFive) {
        let w = rankLabel(winFive[i].rank), l = rankLabel(loseFive[i].rank)
        // Same name, so the top group matched: positions 2-3 of two pair are the second
        // pair and 3-4 of a full house its pair. Only a leftover card is a kicker.
        let secondPair = winnerHand.category == 2 && i < 4
        let fullHousePair = winnerHand.category == 6
        if language == .english {
            let both = "Both have \(DrillTerms.handWithArticle(winnerHand, in: language))."
            let mine = winnerSide.englishPossessive(capitalized: false)
            let theirs = loserSide.englishPossessive(capitalized: false)
            // The shared part is named the way the comparison reads ("two pair, Js up",
            // "a full house of 5s"), not with the hand-name label used elsewhere.
            let top = rankLabel(winnerHand.topRank)
            if secondPair {
                return "Both have two pair, \(top)s up. The second pair decides it: \(mine) \(w)s beat \(theirs) \(l)s."
            }
            if fullHousePair {
                return "Both have a full house of \(top)s. The pair decides it: \(mine) \(w)s beat \(theirs) \(l)s."
            }
            return "\(both) The kicker decides it: \(mine) \(w) beats \(theirs) \(l)."
        }
        let decider = secondPair ? "두 번째 페어가" : fullHousePair ? "함께 쓰는 페어가" : "키커가"
        let pairWord = secondPair ? " 페어" : ""
        let last = l + pairWord
        return "둘 다 \(KO.copula(winner)) \(decider) 승부를 갈랐어요. "
             + "\(winnerSide.koreanPossessive) \(w)\(pairWord), \(loserSide.koreanPossessive) \(last)\(KO.endsInConsonant(last) ? "이라서" : "라서") \(winnerSide.koreanSide) 쪽이 이겨요."
    }
    return language == .english ? "Both players have \(DrillTerms.handWithArticle(winnerHand, in: language))." : "둘 다 \(KO.copula(winner))"
}

/// The first position where two best fives differ in rank. `bestFiveCards` lists
/// cards in the order hands are compared (bigger groups first, then rank), so this is
/// the rank that decided it; sorting high to low would pit a pair against a kicker.
func decidingIndex(_ a: [Card], _ b: [Card]) -> Int? {
    a.indices.first { $0 < b.count && a[$0].rank != b[$0].rank }
}

/// Rank as the app prints it on a card face ("10", "Q"), not the parse letter.
func rankLabel(_ r: Int) -> String {
    ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"][r - 2]
}
