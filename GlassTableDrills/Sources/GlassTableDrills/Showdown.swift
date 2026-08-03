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
    public static func spot(baseSeed: UInt64, index: Int) -> ShowdownSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        var deck = Deck.all
        deck.shuffle(using: &rng)
        return ShowdownSpot(hero: Array(deck[0..<2]),
                            villain: Array(deck[2..<4]),
                            board: Array(deck[4..<9]))
    }
}

public struct ShowdownReveal: GradedReveal {
    public let band: GradeBand
    public let answer: Int
    public let winner: Int
    public let heroName: String
    public let villainName: String
    public let whyText: String
}

// Hand naming reuses the shipped `handName` in Reveal.swift — the outs reveal and the
// showdown drill must never name the same hand two different ways.

public func gradeShowdown(answer: Int, spot: ShowdownSpot) -> ShowdownReveal {
    let w = spot.winner
    let hName = handName(spot.heroBest), vName = handName(spot.villainBest)
    let why: String
    switch w {
    case 0: why = "내 \(hName)가 상대 \(vName)를 이겨요."
    case 1: why = "상대 \(vName)가 내 \(hName)를 이겨요."
    default: why = "둘 다 \(hName) — 보드가 그대로 플레이돼서 찹이에요."
    }
    return ShowdownReveal(band: gradeBinary(userChose: answer == w, correct: true),
                          answer: answer, winner: w,
                          heroName: hName, villainName: vName, whyText: why)
}
