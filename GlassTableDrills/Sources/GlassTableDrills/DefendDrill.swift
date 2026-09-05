// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

// MARK: - 디펜드 차트

/// A seat opens 3bb; hero holds two cards. 폴드, 콜, or 3벳? (R5b spec §1.)
///
/// Hero's own seat is deliberately absent: the chart's bands depend only on the
/// opener's width — R5's disclosed simplification — and staging a seat that changes
/// nothing would imply it does.
public struct DefendSpot: Equatable {
    public let hand: [Card]
    public let opener: Position

    public init(hand: [Card], opener: Position) {
        self.hand = hand; self.opener = opener
    }

    public var handClass: HandClass { HandClass(hand)! }
    /// The same function the table grades with, so drill and table cannot disagree.
    public var correct: DefendAction { DefendChart.action(for: hand, vsOpenFrom: opener) }
}

public enum DefendSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> DefendSpot {
        var attempt = 0
        while true {
            var rng = SplitMix64(seed: baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt))
            let deck = Deck.all.shuffled(using: &rng)
            let spot = DefendSpot(hand: Array(deck[0..<2]),
                                  opener: RFIChart.seats.randomElement(using: &rng)!)
            // Same boundary bias as the RFI drill: AA and 72o teach nothing; the
            // chart has to be *known* only near its edges.
            let score = Chen.score(spot.handClass)
            if (2.0...12.0).contains(score) || attempt > 40 { return spot }
            attempt += 1
        }
    }
}

public struct DefendReveal: Equatable {
    public let band: GradeBand
    public let chosen: DefendAction
    public let correct: DefendAction
    public let whyText: String
}

/// The three actions are ordered (3벳 > 콜 > 폴드), so a one-band miss is 근접 and a
/// two-band miss is 빗나감 — the same softness the estimation drills have, ordinally.
func defendDistance(_ a: DefendAction, _ b: DefendAction) -> Int {
    func rank(_ x: DefendAction) -> Int {
        switch x { case .fold: return 0; case .call: return 1; case .threeBet: return 2 }
    }
    return abs(rank(a) - rank(b))
}

public func gradeDefend(chosen: DefendAction, spot: DefendSpot) -> DefendReveal {
    let correct = spot.correct
    let openPct = RFIChart.openPercent[spot.opener] ?? 0
    let band: GradeBand
    switch defendDistance(chosen, correct) {
    case 0: band = .spotOn
    case 1: band = .close
    default: band = .off
    }
    // The numbers derive from the same constants the chart uses (spec §4.3) — the
    // reveal shows the rule, not just the verdict.
    let why = "\(spot.opener.rawValue)는 상위 \(pctText(openPct))%를 열어요. "
        + "그 폭의 상위 \(pctText(openPct * DefendChart.threeBetShare))%는 3벳, "
        + "\(pctText(openPct * DefendChart.defendShare))%까지는 콜이에요. "
        + "\(KO.topic(spot.handClass.description)) \(correct.rawValue) 밴드예요."
    return DefendReveal(band: band, chosen: chosen, correct: correct, whyText: why)
}
