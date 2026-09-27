// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Korean particles agree with whether the preceding syllable ends in a consonant.
///
/// Hand names are assembled at runtime, so the particle cannot be baked into the
/// string: "3 트리플" ends in ㄹ and takes 이/을, while "A 하이" ends in a vowel and takes
/// 가/를. Writing one of them literally produces "트리플가", which is what shipped.
public enum KO {
    /// True when the last syllable, as read aloud, has a final consonant (종성).
    ///
    /// Latin and digits are judged by their Korean reading. Capitals are read as letter
    /// names: L, M, N and R end in a consonant (엘, 엠, 엔, 알), so BTN takes 은, while the
    /// rank letters A, K, Q, J and T do not. Two or more trailing lowercase letters are an
    /// English word read as one (Nit is 닛), ending in a consonant unless the last letter
    /// is a vowel letter; a single lowercase suffix (the s and o of AKs, AKo) is a letter
    /// name. A digit tail is read by its last digit: 0, 1, 3, 6, 7 and 8 end in a
    /// consonant (영/십, 일, 삼, 육, 칠, 팔), so UTG+1 and 10 take 은. Anything else (a
    /// suit symbol, %) falls back to the vowel form.
    public static func endsInConsonant(_ s: String) -> Bool {
        finalSound(s) != .none
    }

    private enum FinalSound { case none, rieul, other }

    private static func finalSound(_ s: String) -> FinalSound {
        guard let last = s.unicodeScalars.last else { return .none }
        let v = last.value
        if (0xAC00...0xD7A3).contains(v) {
            switch (v - 0xAC00) % 28 {
            case 0: return .none
            case 8: return .rieul
            default: return .other
            }
        }
        guard last.isASCII else { return .none }
        let c = Character(last)
        if c.isLowercase {
            let run = s.reversed().prefix { $0.isASCII && $0.isLowercase }
            if run.count >= 2 { return "aeiouy".contains(c) ? .none : (c == "l" ? .rieul : .other) }
        }
        switch c.uppercased() {
        case "L", "R", "1", "7", "8": return .rieul
        case "M", "N", "0", "3", "6": return .other
        default: return .none
        }
    }

    /// Subject particle: 이 after a consonant, 가 after a vowel.
    public static func subject(_ s: String) -> String { s + (endsInConsonant(s) ? "이" : "가") }
    /// Object particle: 을 after a consonant, 를 after a vowel.
    public static func object(_ s: String) -> String { s + (endsInConsonant(s) ? "을" : "를") }
    /// Joining particle: 과 after a consonant, 와 after a vowel.
    public static func and(_ s: String) -> String { s + (endsInConsonant(s) ? "과" : "와") }
    /// Instrumental particle: 으로 after a consonant other than ㄹ, 로 otherwise.
    public static func instrumental(_ s: String) -> String { s + (finalSound(s) == .other ? "으로" : "로") }
    /// Topic particle: 은 after a consonant, 는 after a vowel.
    public static func topic(_ s: String) -> String { s + (endsInConsonant(s) ? "은" : "는") }
    /// Copula, sentence-final: 이에요 after a consonant, 예요 after a vowel.
    public static func copula(_ s: String) -> String { s + (endsInConsonant(s) ? "이에요." : "예요.") }

    /// Joins a latin letter, digit, % or ) to the Hangul syllable after it with an
    /// invisible word joiner (U+2060).
    ///
    /// iOS allows a line break at that boundary, so "최소 100핸드" could wrap as
    /// "최소 100 / 핸드" and "상위 9%를" as "상위 9% / 를", splitting one 어절.
    /// Spaces are untouched, so ordinary word breaks still happen.
    public static func wordJoined(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        var previous: Unicode.Scalar?
        var changed = false
        for scalar in s.unicodeScalars {
            if let p = previous, joinsForward(p), (0xAC00...0xD7A3).contains(scalar.value) {
                out.append("\u{2060}")
                changed = true
            }
            out.append(scalar)
            previous = scalar
        }
        return changed ? String(out) : s
    }

    private static func joinsForward(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isASCII && (scalar.properties.isAlphabetic || ("0"..."9").contains(scalar)
                           || scalar == "%" || scalar == ")")
    }
}
