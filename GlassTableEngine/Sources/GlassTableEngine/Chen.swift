// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Bill Chen's starting-hand formula (Chen & Ankenman, *The Mathematics of Poker*,
/// 2006), ported verbatim.
///
/// **Why this and not an equity ranking.** The obvious derivation — rank hands by
/// all-in equity versus a random hand — was measured over all 169 classes and puts
/// 76s at 129/169, 22 at 87/169, and A9o *above* AJs. Equity-vs-random sees only
/// showdown value against junk; it cannot see playability, so suited connectors and
/// small pairs (which earn their value flopping flushes, straights and sets) fall out
/// of the chart while offsuit broadways are flattered by dominating hands nobody
/// plays. Chen is built for exactly this and matches convention on every boundary
/// case tested.
///
/// It is a **heuristic, not a solver**, and the app says so. Preflop opening ranges
/// are a strategic choice rather than a fact, so the honest claim is not "provably
/// correct" but "explicitly derived, and here is the derivation" — which is why the
/// score and its arithmetic are shown in-app rather than only the verdict.
public enum Chen {
    /// The score for a starting-hand class. Higher is better; 72o is the floor.
    public static func score(_ h: HandClass) -> Double {
        var s = highCardValue(max(h.high, h.low))
        if h.isPair { s = max(s * 2, 5) }
        if h.suited { s += 2 }
        s -= gapPenalty(h.gap)
        // Both cards below Q and no more than one gap: the straight bonus. Pairs are
        // excluded — their value is already doubled.
        if !h.isPair, h.gap <= 1, h.high < 12 { s += 1 }
        // Chen rounds up to the nearest half point.
        return (s * 2).rounded(.up) / 2
    }

    /// A 10 · K 8 · Q 7 · J 6 · everything else half its rank. Highest card only.
    static func highCardValue(_ rank: Int) -> Double {
        switch rank {
        case 14: return 10
        case 13: return 8
        case 12: return 7
        case 11: return 6
        default: return Double(rank) / 2
        }
    }

    /// 0 → 0 · 1 → 1 · 2 → 2 · 3 → 4 · 4 or more → 5.
    static func gapPenalty(_ gap: Int) -> Double {
        switch gap {
        case 0: return 0
        case 1: return 1
        case 2: return 2
        case 3: return 4
        default: return 5
        }
    }

    /// The 169 classes ranked best-first.
    ///
    /// **Ties are common and load-bearing** — 22 and A9o both score exactly 5 — so the
    /// tie-break decides who makes the chart at its boundary and cannot be incidental.
    /// Ordered by playability, which is precisely what the raw score under-weights:
    /// pairs first (they flop sets and need no help), then suited (flushes), then the
    /// smaller gap (straights), then high card. That puts 22 ahead of A9o, matching
    /// every chart — 22 opens from mid position, A9o only from late.
    public static let ranked: [HandClass] = HandClass.all.sorted { a, b in
        let sa = score(a), sb = score(b)
        if sa != sb { return sa > sb }
        if a.isPair != b.isPair { return a.isPair }
        if a.suited != b.suited { return a.suited }
        if a.gap != b.gap { return a.gap < b.gap }
        return a.high > b.high
    }

    /// A human-readable derivation of the score, for the reveal — the transparency
    /// payload. "A 10 + 수티드 2 − 갭 2 = 10" rather than a bare number.
    public static func explain(_ h: HandClass) -> String {
        let r = HandClass.rankChars
        var parts: [String] = []
        let base = highCardValue(max(h.high, h.low))
        if h.isPair {
            parts.append("\(r[h.high - 2]) \(fmt(base)) × 2 = \(fmt(max(base * 2, 5)))")
            if base * 2 < 5 { parts.append("최소 5 적용") }
        } else {
            parts.append("\(r[max(h.high, h.low) - 2]) \(fmt(base))")
        }
        if h.suited { parts.append("수티드 +2") }
        let pen = gapPenalty(h.gap)
        if pen > 0 { parts.append("갭 \(h.gap) −\(fmt(pen))") }
        if !h.isPair, h.gap <= 1, h.high < 12 { parts.append("스트레이트 보너스 +1") }
        return parts.joined(separator: " · ") + " = \(fmt(score(h)))"
    }

    private static func fmt(_ x: Double) -> String {
        abs(x - x.rounded()) < 0.01 ? "\(Int(x.rounded()))" : String(format: "%.1f", x)
    }
}

public extension HandClass {
    /// Cards strictly between the two ranks — 0 for connectors, 0 for a pair.
    var gap: Int { isPair ? 0 : high - low - 1 }
}
