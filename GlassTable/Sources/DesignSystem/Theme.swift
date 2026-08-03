// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// 펠트 + 카드지 — felt surface with warm cream cards laid on it (spec §9).
///
/// The M1 palette put a bright, high-chroma green (`#157A47`, gradienting to
/// `#1B8A52`) across the full screen. That is the long-session fatigue source: a
/// large saturated field at high luminance. Real felt under room light is much darker
/// and greyer, and going deeper is what makes it read as a table rather than a green
/// app. Cards are cream rather than pure white for the same reason — white is the
/// brightest thing a phone can emit, and there is no reason for a study tool to.
enum GT {
    // Felt — the surface everything sits on.
    static let felt          = Color(hex: 0x1B4234)
    static let feltDeep      = Color(hex: 0x14382B)
    static let hairlineFelt  = Color(hex: 0x2A5546)

    // Ink on felt.
    static let onFelt          = Color(hex: 0xF2EFE7)
    static let onFeltSecondary = Color(hex: 0x8CA396)
    static let onFeltMuted     = Color(hex: 0x7E978A)

    // Cream — cards laid on the felt, and the paper of a playing card.
    static let card     = Color(hex: 0xF4F1E9)
    static let cardFace = Color(hex: 0xF7F5EF)
    /// Inset block *inside* a cream card (the "why" panel, stepper keys). Warm, so it
    /// doesn't read as a cool grey patch on warm paper.
    static let surface  = Color(hex: 0xEBE7DA)

    // Ink on cream.
    static let ink          = Color(hex: 0x1A2621)
    static let inkSecondary = Color(hex: 0x5D6B64)
    static let inkMuted     = Color(hex: 0x98A199)

    /// Primary action sitting on a cream card: deep felt with cream lettering.
    static let cta = Color(hex: 0x1B4234)
    /// Accent for icons and live values on cream. Same hue family as the felt so the
    /// app reads as one material.
    static let green = Color(hex: 0x1B4234)
    /// Progress fills, highlight strokes and live-node glow *on felt*, where the deep
    /// felt greens vanish. Any accent drawn on felt uses this, never `cta`/`green`.
    static let mint = Color(hex: 0x6FD3A0)

    /// Price-bar segments, drawn on felt with `onFelt` numerals printed inside them.
    /// Three separable values, each measured against `onFelt`: 7.1:1 / 4.9:1 / 5.4:1,
    /// so every segment clears WCAG AA for normal-size text. (The M1 pair reached only
    /// ~2.8:1 — the numbers inside were already below AA before this retint.)
    /// 콜 is deliberately a different hue: the beginner's error is the denominator,
    /// so the term the user actually pays has to separate from the two green ones.
    static let segPot  = Color(hex: 0x24593F)
    static let segBet  = Color(hex: 0x2F7352)
    static let segCall = Color(hex: 0x7A5C18)

    static let suitRed = Color(hex: 0xC0392B)

    // relativeTo: .body → all text scales with the user's Dynamic Type setting.
    static func title(_ s: CGFloat) -> Font    { .custom("Pretendard-Bold", size: s, relativeTo: .body) }
    static func semibold(_ s: CGFloat) -> Font { .custom("Pretendard-SemiBold", size: s, relativeTo: .body) }
    static func body(_ s: CGFloat) -> Font     { .custom("Pretendard-Regular", size: s, relativeTo: .body) }
}

/// Home/settings backdrop. Flat rather than gradient — the M1 gradient spanned
/// `#1B8A52`→`#0E5A34`, which is a lot of moving luminance behind text you read for
/// an hour.
struct FeltBackground: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GT.felt
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 300))
                .foregroundStyle(GT.onFelt.opacity(0.035))
                .rotationEffect(.degrees(-12))
                .offset(x: 60, y: 70)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8)  & 0xff) / 255,
                  blue:  Double( hex        & 0xff) / 255)
    }
}
