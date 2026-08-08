// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// How many distinct ranks would complete a straight if added to these cards.
///
/// Derived by asking the question directly, one rank at a time, rather than by pattern
/// matching four consecutive cards. That gets the awkward ends right for free: 6789 has
/// two completing ranks (5 and T), A234 has one (5, because the ace is already the low
/// end), and JQKA has one.
public func straightCompletingRanks(_ cards: [Card]) -> [Int] {
    let mask = rankMask(cards)
    guard !maskHasStraight(mask) else { return [] }
    var out: [Int] = []
    for rank in 2...14 where mask & (1 << rank) == 0 {
        var m = mask | (1 << rank)
        if rank == 14 { m |= 1 << 1 }
        if maskHasStraight(m) { out.append(rank) }
    }
    return out
}

/// Bit `r` set for every rank present; bit 1 mirrors the ace so the wheel needs no
/// special case downstream.
@inline(__always)
func rankMask(_ cards: [Card]) -> Int {
    var m = 0
    for c in cards { m |= 1 << c.rank }
    if m & (1 << 14) != 0 { m |= 1 << 1 }
    return m
}

/// Five consecutive bits anywhere in 1...14.
@inline(__always)
func maskHasStraight(_ mask: Int) -> Bool {
    let m = mask & (mask >> 1) & (mask >> 2) & (mask >> 3) & (mask >> 4)
    return m != 0
}

/// True when some five of these ranks are consecutive. The wheel counts: an ace plays
/// low in A-2-3-4-5.
func isStraight(_ cards: [Card]) -> Bool {
    maskHasStraight(rankMask(cards))
}

/// Whether *any* rank completes a straight — the question `drawOrAir` actually asks.
/// Short-circuits, and never allocates the list of ranks.
@inline(__always)
func hasStraightDrawOrBetter(_ cards: [Card]) -> Bool {
    let mask = rankMask(cards)
    if maskHasStraight(mask) { return false }   // already made; not a draw
    for rank in 2...14 where mask & (1 << rank) == 0 {
        var m = mask | (1 << rank)
        if rank == 14 { m |= 1 << 1 }
        if maskHasStraight(m) { return true }
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
    var s0 = 0, s1 = 0, s2 = 0, s3 = 0
    for c in cards {
        switch c.suit {
        case 0: s0 += 1
        case 1: s1 += 1
        case 2: s2 += 1
        default: s3 += 1
        }
    }
    return s0 == 4 || s1 == 4 || s2 == 4 || s3 == 4
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
        var topBoard = 0
        var boardMask = 0
        for c in board {
            if c.rank > topBoard { topBoard = c.rank }
            boardMask |= 1 << c.rank
        }
        var paired = 0
        if boardMask & (1 << hand[0].rank) != 0 { paired = hand[0].rank }
        if boardMask & (1 << hand[1].rank) != 0, hand[1].rank > paired { paired = hand[1].rank }
        if paired != 0 {
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
    return hasStraightDrawOrBetter(cards) ? .draw : .air
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
    var bySuit = (0, 0, 0, 0)
    var highCard = 0
    var distinct = 0
    var seen = 0
    for c in board {
        switch c.suit {
        case 0: bySuit.0 += 1
        case 1: bySuit.1 += 1
        case 2: bySuit.2 += 1
        default: bySuit.3 += 1
        }
        if c.rank > highCard { highCard = c.rank }
        if seen & (1 << c.rank) == 0 { distinct += 1; seen |= 1 << c.rank }
    }
    let present = rankMask(board)
    var windows = 0
    for low in 1...10 {
        var have = 0
        for r in low..<(low + 5) where present & (1 << r) != 0 { have += 1 }
        if have >= 3 { windows += 1 }
    }

    return BoardTexture(isPaired: distinct < board.count,
                        topSuitCount: max(max(bySuit.0, bySuit.1), max(bySuit.2, bySuit.3)),
                        highCard: highCard,
                        straightiness: windows,
                        cardCount: board.count)
}
