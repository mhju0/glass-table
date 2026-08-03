// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Standard chart notation: `"22+, ATs+, KQs, 76s"`.
///
/// Supported because these are the forms every published chart actually uses:
/// - `QQ` — one pair · `77+` — that pair and every better one
/// - `AKs` / `AKo` — one suited or offsuit class
/// - `ATs+` — same high card, low card walking up to one below it
/// - `T9s-76s` — a run of equally-gapped classes stepping down
public enum RangeNotation {
    public enum ParseError: Error, Equatable {
        case unrecognizedToken(String)
        case mismatchedRun(String)
    }

    public static func parse(_ text: String) throws -> HandRange {
        var classes: [HandClass] = []
        for raw in text.split(whereSeparator: { $0 == "," || $0 == " " }) {
            let token = String(raw).trimmingCharacters(in: .whitespaces)
            if token.isEmpty { continue }
            classes.append(contentsOf: try parseToken(token))
        }
        return HandRange(classes)
    }

    private static func parseToken(_ token: String) throws -> [HandClass] {
        if token.contains("-") {
            let sides = token.split(separator: "-").map(String.init)
            guard sides.count == 2,
                  let hi = single(sides[0]), let lo = single(sides[1]),
                  hi.suited == lo.suited, hi.isPair == lo.isPair
            else { throw ParseError.mismatchedRun(token) }
            return try run(from: hi, to: lo, token: token)
        }
        if token.hasSuffix("+") {
            guard let base = single(String(token.dropLast())) else {
                throw ParseError.unrecognizedToken(token)
            }
            return plus(base)
        }
        guard let one = single(token) else { throw ParseError.unrecognizedToken(token) }
        return [one]
    }

    /// "22+" walks the pairs up; "ATs+" walks the *low* card up, since the high card
    /// is what names the group.
    private static func plus(_ base: HandClass) -> [HandClass] {
        if base.isPair {
            return (base.high...14).compactMap { HandClass(high: $0, low: $0, suited: false) }
        }
        return (base.low..<base.high).compactMap {
            HandClass(high: base.high, low: $0, suited: base.suited)
        }
    }

    /// A run like "T9s-76s": both endpoints must share a gap, and the run steps both
    /// ranks down together.
    private static func run(from hi: HandClass, to lo: HandClass,
                            token: String) throws -> [HandClass] {
        guard hi.gap == lo.gap, hi.high >= lo.high else {
            throw ParseError.mismatchedRun(token)
        }
        var out: [HandClass] = []
        var h = hi.high, l = hi.low
        while h >= lo.high, l >= lo.low {
            if let c = HandClass(high: h, low: l, suited: hi.suited) { out.append(c) }
            h -= 1; l -= 1
        }
        return out
    }

    private static func single(_ token: String) -> HandClass? {
        let chars = Array(token.uppercased())
        guard chars.count == 2 || chars.count == 3 else { return nil }
        guard let hi = rank(chars[0]), let lo = rank(chars[1]) else { return nil }
        if chars.count == 2 {
            // Two characters is only a pair; "AK" without a suffix is ambiguous.
            guard hi == lo else { return nil }
            return HandClass(high: hi, low: lo, suited: false)
        }
        guard hi != lo else { return nil }
        switch chars[2] {
        case "S": return HandClass(high: max(hi, lo), low: min(hi, lo), suited: true)
        case "O": return HandClass(high: max(hi, lo), low: min(hi, lo), suited: false)
        default: return nil
        }
    }

    private static func rank(_ c: Character) -> Int? {
        HandClass.rankChars.firstIndex(of: String(c)).map { $0 + 2 }
    }

    /// Every class listed explicitly, best-first.
    ///
    /// Deliberately *not* collapsed back into "22+, ATs+" form. Compacting is a
    /// presentation nicety with real edge cases, nothing in R2 needs it, and an
    /// expanded list round-trips through `parse` exactly — which is the property that
    /// actually matters.
    public static func print(_ range: HandRange) -> String {
        range.classes.map(\.description).joined(separator: ", ")
    }
}
