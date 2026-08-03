// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// Korean particles agree with whether the preceding syllable ends in a consonant.
///
/// Hand names are assembled at runtime, so the particle cannot be baked into the
/// string: "3 트리플" ends in ㄹ and takes 이/을, while "A 하이" ends in a vowel and takes
/// 가/를. Writing one of them literally produces "트리플가", which is what shipped.
public enum KO {
    /// True when the last Hangul syllable has a final consonant (종성).
    /// Non-Hangul tails (a digit, a latin letter) fall back to the vowel form, which
    /// is right for the rank letters this app pairs with hand names.
    public static func endsInConsonant(_ s: String) -> Bool {
        guard let last = s.unicodeScalars.last else { return false }
        let v = last.value
        guard (0xAC00...0xD7A3).contains(v) else { return false }
        return (v - 0xAC00) % 28 != 0
    }

    /// Subject particle: 이 after a consonant, 가 after a vowel.
    public static func subject(_ s: String) -> String { s + (endsInConsonant(s) ? "이" : "가") }
    /// Object particle: 을 after a consonant, 를 after a vowel.
    public static func object(_ s: String) -> String { s + (endsInConsonant(s) ? "을" : "를") }
    /// Topic particle: 은 after a consonant, 는 after a vowel.
    public static func topic(_ s: String) -> String { s + (endsInConsonant(s) ? "은" : "는") }
    /// Copula, sentence-final: 이에요 after a consonant, 예요 after a vowel.
    public static func copula(_ s: String) -> String { s + (endsInConsonant(s) ? "이에요." : "예요.") }
}
