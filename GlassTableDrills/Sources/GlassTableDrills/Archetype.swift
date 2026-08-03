// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// The five opponents, with the strategies they publish.
///
/// This is the product's thesis in one type: because the archetype *declares* what it
/// plays, "what does his call mean?" has an answer the app can grade numerically.
/// A solver would be opaque and a neural bot would not tell you what it had.
///
/// VPIP/PFR come from `decisions.md` §C, which sourced them from the literature. The
/// ranges are **derived** from those two numbers rather than authored, so the rule and
/// the resulting grid are both printable in-app.
public enum Archetype: String, CaseIterable, Sendable {
    case nit, tag, lag, station, maniac

    /// Voluntarily put money in pot — everything it plays, raised or called.
    public var vpip: Double {
        switch self {
        case .nit: return 12; case .tag: return 20; case .lag: return 27
        case .station: return 40; case .maniac: return 55
        }
    }

    /// Preflop raise — the part it raises rather than calls.
    public var pfr: Double {
        switch self {
        case .nit: return 9; case .tag: return 17; case .lag: return 22
        case .station: return 10; case .maniac: return 40
        }
    }

    /// TAG/LAG stay Latin — Hangul 태그/래그 collide with everyday words
    /// (`decisions.md` §F).
    public var name: String {
        switch self {
        case .nit: return "Nit"; case .tag: return "TAG"; case .lag: return "LAG"
        case .station: return "콜링 스테이션"; case .maniac: return "매니악"
        }
    }

    public var blurb: String {
        switch self {
        case .nit: return "좋은 패만 아주 좁게 플레이해요"
        case .tag: return "좁게 들어오지만 들어오면 공격적이에요"
        case .lag: return "넓게 들어오고 공격적이에요"
        case .station: return "아주 넓게 들어오지만 거의 레이즈하지 않아요"
        case .maniac: return "넓게 들어오고 대부분 레이즈해요"
        }
    }

    /// The gap is the discriminator: tiny for TAG and LAG, enormous for the Station.
    /// Everything the archetype *is* falls out of it.
    public var passiveGap: Double { vpip - pfr }

    // MARK: derived ranges

    /// Raises the top `pfr`% by Chen, scaled for the seat.
    public func raiseRange(from seat: Position) -> HandRange {
        HandRange.topByChen(percent: pfr * Archetype.seatFactor(seat))
    }

    /// Calls the band between raising and folding — good enough to play, not good
    /// enough to raise. For the Station that band is most of its range, which is what
    /// makes it a Station rather than a loose raiser.
    public func callRange(from seat: Position) -> HandRange {
        let play = HandRange.topByChen(percent: vpip * Archetype.seatFactor(seat))
        return play.subtracting(raiseRange(from: seat))
    }

    /// Everything it plays at all.
    public func playRange(from seat: Position) -> HandRange {
        HandRange.topByChen(percent: vpip * Archetype.seatFactor(seat))
    }

    /// Seat widens or tightens the headline number. Normalised so the average across
    /// the seven acting seats returns the archetype's declared VPIP/PFR — otherwise
    /// the published statistic would not describe the player the app actually deals.
    static func seatFactor(_ seat: Position) -> Double {
        let raw = rawFactor(seat)
        let mean = RFIChart.seats.map(rawFactor).reduce(0, +) / Double(RFIChart.seats.count)
        return raw / mean
    }

    /// Fewer players behind → wider. Same shape R2's charts use.
    private static func rawFactor(_ seat: Position) -> Double {
        let behind = Double(seat.playersBehind(preflop: true))
        return 1.0 / (0.55 + 0.10 * behind)
    }
}
