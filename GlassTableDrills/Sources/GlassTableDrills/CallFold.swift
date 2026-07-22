// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Turn spot vs a face-up villain hand, with a price to call.
public struct CallFoldSpot: Equatable {
    public let hero: [Card]
    public let villain: [Card]
    public let board: [Card]      // 4 cards (turn)
    public let pot: Int           // before villain's bet, bb
    public let bet: Int
    public let equityPct: Double  // hero's exact equity over the remaining rivers, percent

    public var requiredPct: Double {
        requiredEquity(toCall: Double(bet), pot: Double(pot + bet)) * 100
    }
    public var correctIsCall: Bool {
        callIsProfitable(equity: equityPct / 100, toCall: Double(bet), pot: Double(pot + bet))
    }
}

/// Deterministic call/fold spots. Same (baseSeed, index) → same spot.
public enum CallFoldSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> CallFoldSpot {
        var attempt = 0
        while true {
            let seed = baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt)
            var rng = SplitMix64(seed: seed)
            let deck = Deck.all.shuffled(using: &rng)
            let hero = Array(deck[0..<2])
            let villain = Array(deck[2..<4])
            let board = Array(deck[4..<8])
            let equity = exactEquityHeadsUp(hero: hero, villain: villain, board: board).equity
            // ponytail: reject near-locks (5–95% passes most random deals, so no
            // widening valve like OutsSpotGenerator needs — reseeded retries suffice).
            if equity >= 0.05 && equity <= 0.95 {
                let pot = BetSpotGenerator.pots.randomElement(using: &rng)!
                let f = BetSpotGenerator.fractions.randomElement(using: &rng)!
                return CallFoldSpot(hero: hero, villain: villain, board: board,
                                    pot: pot, bet: max(1, Int((f * Double(pot)).rounded())),
                                    equityPct: equity * 100)
            }
            attempt += 1
        }
    }
}

public struct CallFoldReveal: GradedReveal {
    public let band: GradeBand
    public let userCalls: Bool
    public let correctIsCall: Bool
    public let equityPct: Double
    public let requiredPct: Double
    public let whyText: String
}

/// Binary grade: 정확 or 빗나감 — no 근접 band for a two-way decision.
public func gradeCallFold(userCalls: Bool, spot: CallFoldSpot) -> CallFoldReveal {
    let correct = spot.correctIsCall
    return CallFoldReveal(
        band: gradeBinary(userChose: userCalls, correct: correct),
        userCalls: userCalls, correctIsCall: correct,
        equityPct: spot.equityPct, requiredPct: spot.requiredPct,
        whyText: "에퀴티 \(pctText(spot.equityPct))% vs 필요 \(pctText(spot.requiredPct))% → \(correct ? "콜" : "폴드")")
}
