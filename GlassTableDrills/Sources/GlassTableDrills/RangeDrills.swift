// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

// MARK: - 레인지 표기법

/// "22+, ATs+" → how many combos is that?
///
/// Only the combo count is asked, not the percentage. Counting combos is mental
/// arithmetic a player actually does at the table (6 per pair, 4 suited, 12 offsuit);
/// converting to a percentage means dividing by 1326, which nobody does in their head
/// and which would make an "exact answer" drill a calculator test.
public struct RangeNotationSpot: Equatable {
    public let notation: String
    public let range: HandRange

    public init(notation: String, range: HandRange) {
        self.notation = notation; self.range = range
    }

    public var comboCount: Int { Int(range.comboCount) }
}

public enum RangeNotationSpotGenerator {
    /// Built from templates rather than a fixed list, so the drill never runs out.
    public static func spot(baseSeed: UInt64, index: Int) -> RangeNotationSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let r = HandClass.rankChars

        var tokens: [String] = []
        switch Int.random(in: 0..<4, using: &rng) {
        case 0:   // a pair and better
            tokens = ["\(r[Int.random(in: 4...11, using: &rng)])" .duplicated() + "+"]
        case 1:   // suited group off one high card
            let hi = Int.random(in: 11...12, using: &rng)
            let lo = Int.random(in: 6...(hi - 2), using: &rng)
            tokens = ["\(r[hi])\(r[lo])s+"]
        case 2:   // one pair group plus one suited class
            let p = Int.random(in: 6...10, using: &rng)
            let hi = Int.random(in: 10...12, using: &rng)
            let lo = Int.random(in: 5...(hi - 1), using: &rng)
            tokens = ["\(r[p])".duplicated() + "+", "\(r[hi])\(r[lo])s"]
        default:  // two explicit classes, one suited one offsuit
            let hi = Int.random(in: 8...12, using: &rng)
            let lo = Int.random(in: 3...(hi - 1), using: &rng)
            tokens = ["\(r[hi])\(r[lo])s", "\(r[hi])\(r[lo])o"]
        }
        let notation = tokens.joined(separator: ", ")
        // The generator only emits forms the parser accepts, so a throw here would be
        // a bug rather than bad input — fall back to a known-good spot instead of
        // shipping a crash.
        let range = (try? RangeNotation.parse(notation)) ?? HandRange([HandClass.all[0]])
        return RangeNotationSpot(notation: notation, range: range)
    }
}

private extension String {
    func duplicated() -> String { self + self }
}

public struct RangeNotationReveal: GradedReveal {
    public let band: GradeBand
    public let estimate: Int
    public let count: Int
    public let whyText: String
}

public func gradeRangeNotation(estimate: Int, spot: RangeNotationSpot) -> RangeNotationReveal {
    let parts = spot.range.classes.map { "\($0.description) \($0.comboCount)" }
    return RangeNotationReveal(
        band: gradeBinary(userChose: estimate == spot.comboCount, correct: true),
        estimate: estimate, count: spot.comboCount,
        whyText: "\(parts.joined(separator: " + ")) = \(spot.comboCount) 콤보. "
               + "페어 6개, 수티드 4개, 오프수트 12개예요.")
}

// MARK: - RFI 차트

/// A hand and a seat: do you open, or fold?
public struct RFISpot: Equatable {
    public let hand: [Card]
    public let seat: Position

    public init(hand: [Card], seat: Position) {
        self.hand = hand; self.seat = seat
    }

    public var handClass: HandClass { HandClass(hand)! }
    public var opens: Bool { RFIChart.opens(hand, from: seat) }
}

public enum RFISpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> RFISpot {
        var attempt = 0
        while true {
            var rng = SplitMix64(seed: baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt))
            let deck = Deck.all.shuffled(using: &rng)
            let hand = Array(deck[0..<2])
            let seat = RFIChart.seats.randomElement(using: &rng)!
            let spot = RFISpot(hand: hand, seat: seat)
            // Skip the hands where the answer is obvious from a glance — the top and
            // bottom of the chart teach nothing. Keep spots near the seat's boundary,
            // which is where the chart actually has to be known.
            let score = Chen.score(spot.handClass)
            if (2.0...12.0).contains(score) || attempt > 40 { return spot }
            attempt += 1
        }
    }
}

public struct RFIReveal: GradedReveal {
    public let band: GradeBand
    public let userOpens: Bool
    public let correctOpens: Bool
    public let whyText: String
}

public func gradeRFI(userOpens: Bool, spot: RFISpot) -> RFIReveal {
    let h = spot.handClass
    let pct = RFIChart.openPercent[spot.seat] ?? 0
    var why = "\(h.description) · \(Chen.explain(h))\n"
        + "\(spot.seat.rawValue)는 상위 \(Int(pct))%를 열어요."
    if spot.opens {
        why += " \(h.description)는 그 안에 들어와요."
    } else if let earliest = RFIChart.earliestSeatOpening(spot.hand) {
        why += " \(h.description)는 \(earliest.rawValue)부터 열어요."
    } else {
        why += " \(h.description)는 어느 자리에서도 열지 않아요."
    }
    return RFIReveal(band: gradeBinary(userChose: userOpens, correct: spot.opens),
                     userOpens: userOpens, correctOpens: spot.opens, whyText: why)
}
