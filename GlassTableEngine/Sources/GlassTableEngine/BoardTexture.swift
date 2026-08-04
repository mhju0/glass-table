// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// How many distinct ranks would complete a straight if added to these cards.
///
/// Derived by asking the question directly, one rank at a time, rather than by pattern
/// matching four consecutive cards. That gets the awkward ends right for free: 6789 has
/// two completing ranks (5 and T), A234 has one (5, because the ace is already the low
/// end), and JQKA has one.
public func straightCompletingRanks(_ cards: [Card]) -> [Int] {
    guard !isStraight(cards) else { return [] }
    var out: [Int] = []
    for rank in 2...14 where !cards.contains(where: { $0.rank == rank }) {
        // Suit is irrelevant to a straight, so any suit stands in for the rank.
        if isStraight(cards + [Card(rank: rank, suit: 0)]) { out.append(rank) }
    }
    return out
}

/// True when some five of these ranks are consecutive. The wheel counts: an ace plays
/// low in A-2-3-4-5.
func isStraight(_ cards: [Card]) -> Bool {
    var present = Set(cards.map(\.rank))
    if present.contains(14) { present.insert(1) }
    for low in 1...10 {
        if (low..<(low + 5)).allSatisfy({ present.contains($0) }) { return true }
    }
    return false
}

public enum StraightDraw: Equatable, Sendable {
    case none, gutshot, openEnded

    /// Two or more completing ranks is the honest definition of open-ended — it is what
    /// "eight outs" actually means, and it stays correct for double gutshots.
    static func from(completingRanks: Int) -> StraightDraw {
        completingRanks >= 2 ? .openEnded : (completingRanks == 1 ? .gutshot : .none)
    }
}

/// Four to a flush. Five would already be a made flush, which the hand category catches.
public func hasFlushDraw(_ cards: [Card]) -> Bool {
    var bySuit = [Int](repeating: 0, count: 4)
    for c in cards { bySuit[c.suit] += 1 }
    return bySuit.contains(4)
}

// MARK: - what one hand is doing on a board

/// What a hand is, on a board, in the five buckets a learner acts on differently.
///
/// Ordered weakest to strongest so a distribution can be read as a ladder.
public enum MadeHand: Int, CaseIterable, Comparable, Sendable {
    case air, draw, weakPair, topPair, strong

    public static func < (a: MadeHand, b: MadeHand) -> Bool { a.rawValue < b.rawValue }

    public var korean: String {
        switch self {
        case .air:      return "노페어"
        case .draw:     return "드로우"
        case .weakPair: return "약한 페어"
        case .topPair:  return "탑 페어"
        case .strong:   return "투페어 이상"
        }
    }
}

/// Classify a two-card hand on a 3–5 card board.
///
/// **The made hand decides the bucket**; `draw` applies only when the made hand is worse
/// than a pair. A flopped set with a flush draw is `strong`, not `draw` — any other rule
/// needs a tiebreak table nobody can hold in their head (spec §1).
///
/// An **overpair counts as `topPair`**: it is stronger, but the street where that
/// difference changes an action belongs to S2, not to a hit-frequency bucket.
public func madeHand(hand: [Card], board: [Card]) -> MadeHand {
    precondition(hand.count == 2 && (3...5).contains(board.count))
    let all = hand + board
    let brief = bestHandOfAny(all)

    if brief.category >= 2 { return .strong }        // two pair, trips, straight, …

    if brief.category == 1 {
        // Which rank is the pair? A board pair everyone shares is not *this hand's*
        // pair, so read the pair off the hand rather than off `brief`.
        let topBoard = board.map(\.rank).max() ?? 0
        let boardRanks = board.map(\.rank)
        let paired = hand.filter { boardRanks.contains($0.rank) }.map(\.rank).max()
        if let paired {
            return paired == topBoard ? .topPair : .weakPair
        }
        // No hand card paired the board: either a pocket pair or the board is paired.
        if hand[0].rank == hand[1].rank {
            return hand[0].rank > topBoard ? .topPair : .weakPair   // overpair / underpair
        }
        // The pair is entirely on the board, so this hand has nothing of its own.
        return drawOrAir(all)
    }

    return drawOrAir(all)
}

private func drawOrAir(_ cards: [Card]) -> MadeHand {
    if hasFlushDraw(cards) { return .draw }
    return straightCompletingRanks(cards).isEmpty ? .air : .draw
}

// MARK: - the board itself

public struct BoardTexture: Equatable, Sendable {
    public let isPaired: Bool
    /// Largest number of cards sharing a suit.
    public let topSuitCount: Int
    public let highCard: Int
    /// How many of the ten five-rank straight windows the board already holds three of.
    public let straightiness: Int
    public let cardCount: Int

    /// Suitedness is relative to how many cards are out. Three of a suit is *monotone*
    /// on a flop and merely "a flush is possible" on a river — the first version used
    /// one fixed table and called a monotone flop two-tone.
    public var suitedness: String {
        if topSuitCount == cardCount { return "모노톤" }
        if topSuitCount >= 3 { return "플러시 가능" }
        return topSuitCount == 2 ? "투톤" : "레인보우"
    }

    /// One derived sentence, so a drill never authors a description of a board it
    /// generated at random.
    public var summary: String {
        var parts = ["\(HandClass.rankChars[highCard - 2]) 하이", suitedness]
        if isPaired { parts.append("페어 보드") }
        if straightiness >= 2 { parts.append("스트레이트 잘 붙는 보드") }
        return parts.joined(separator: " · ")
    }
}

public func boardTexture(_ board: [Card]) -> BoardTexture {
    precondition((3...5).contains(board.count))
    var bySuit = [Int](repeating: 0, count: 4)
    for c in board { bySuit[c.suit] += 1 }
    let ranks = board.map(\.rank)

    var present = Set(ranks)
    if present.contains(14) { present.insert(1) }
    var windows = 0
    for low in 1...10 where (low..<(low + 5)).filter({ present.contains($0) }).count >= 3 {
        windows += 1
    }

    return BoardTexture(isPaired: Set(ranks).count < ranks.count,
                        topSuitCount: bySuit.max() ?? 0,
                        highCard: ranks.max() ?? 0,
                        straightiness: windows,
                        cardCount: board.count)
}
