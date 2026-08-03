// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Raise-first-in charts: which hands you open when nobody has entered the pot.
///
/// Derived, never copied. Each seat's chart is the top N% of hands by Chen score,
/// with N set by how many players still act behind you — the fewer, the wider. No
/// public chart is redistributable, so the app names what it was checked against
/// (Upswing's free 9-handed RFI PDF, PokerCoaching's free charts) and reproduces
/// neither. See `docs/specs/2026-08-04-r2-range-primitive-design.md` §1.
public enum RFIChart {
    /// **8-handed has no canonical public chart**, so these are interpolated between
    /// 9-max and 6-max conventions — wider than 9-max at the same seat, tighter than
    /// 6-max. The app discloses that it interpolated; the disclosure *is* the
    /// transparency feature (`decisions.md` §E).
    ///
    /// BB is absent on purpose: folded to the big blind ends the hand, so there is no
    /// raise-first-in decision to make.
    public static let openPercent: [Position: Double] = [
        .utg: 15, .utg1: 17, .lj: 20, .hj: 23, .co: 28, .btn: 42, .sb: 36,
    ]

    /// Seats that actually have an RFI decision, in order of action.
    public static let seats: [Position] = Position.preflopOrder.filter { $0 != .bb }

    /// Computed once — `Chen.ranked` is already a stored constant, but seven charts
    /// get read on every grid render.
    private static let charts: [Position: HandRange] = openPercent.mapValues {
        HandRange.topByChen(percent: $0)
    }

    /// The opening range for a seat. Empty for BB, which never opens first in.
    public static func range(for seat: Position) -> HandRange {
        charts[seat] ?? HandRange()
    }

    public static func opens(_ hand: [Card], from seat: Position) -> Bool {
        range(for: seat).contains(hand)
    }

    /// The narrowest seat that would open this hand — "이 핸드는 CO부터 열어요".
    /// Nil when no seat opens it at all.
    public static func earliestSeatOpening(_ hand: [Card]) -> Position? {
        seats.first { opens(hand, from: $0) }
    }
}
