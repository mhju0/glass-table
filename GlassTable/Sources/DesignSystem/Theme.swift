// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit

/// A colour that resolves per interface style.
///
/// Chosen over asset-catalog colour sets because the whole palette then lives in one
/// readable file where a light/dark pair sits on one line — the same reason the store
/// is a plain JSON file.
private func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
}

/// 펠트 + 카드지 — felt surface with warm cards laid on it (spec §9), in two schemes.
///
/// Light is a card room by day: deep desaturated felt, cream paper. Dark is the same
/// room at night — the felt drops further, the "cream" card becomes an elevated dark
/// green surface, and the ink inverts. Playing-card faces stay the lightest thing on
/// screen in both, because a card is paper; but in dark they dim to a bone so a grid
/// of nine outs isn't nine little floodlights.
enum GT {
    // Felt — the surface everything sits on.
    static let felt         = dyn(0x1B4234, 0x0F211A)
    static let feltDeep     = dyn(0x14382B, 0x0A1811)
    static let hairlineFelt = dyn(0x2A5546, 0x244134)

    // Ink on felt.
    static let onFelt          = dyn(0xF2EFE7, 0xE8EFE9)
    static let onFeltSecondary = dyn(0x8CA396, 0x8CA396)
    static let onFeltMuted     = dyn(0x7E978A, 0x6E8579)

    // Cards laid on the felt.
    static let card     = dyn(0xF4F1E9, 0x1A2E25)
    static let cardFace = dyn(0xF7F5EF, 0xDAD6CA)
    /// Inset block *inside* a card (the "why" panel, stepper keys, dividers).
    static let surface  = dyn(0xEBE7DA, 0x24382E)

    // Ink on a card.
    static let ink          = dyn(0x1A2621, 0xE8EFE9)
    static let inkSecondary = dyn(0x5D6B64, 0xA8BBAF)
    static let inkMuted     = dyn(0x98A199, 0x7B9086)

    /// Primary action sitting on a card. Light: deep felt. Dark: mint — deep felt on a
    /// dark card would be invisible.
    static let cta = dyn(0x1B4234, 0x6FD3A0)
    /// Lettering *on* `cta`. It flips with the fill, which is why it is its own token
    /// rather than reusing `onFelt`: cream on mint is the palette's one unreadable pair.
    static let onCTA = dyn(0xF4F1E9, 0x0F211A)
    /// Accent for icons and live values on a card.
    static let green = dyn(0x1B4234, 0x6FD3A0)
    /// Accents drawn *on felt*, where the deep felt greens vanish. Any highlight,
    /// stroke or progress fill over felt uses this — never `cta`/`green`.
    static let mint = dyn(0x6FD3A0, 0x6FD3A0)

    /// Price-bar segments, drawn on felt with `onFelt` numerals inside them. Measured
    /// against `onFelt` at 7.1 / 4.9 / 5.4:1, so every segment clears WCAG AA for
    /// normal-size text. (The M1 pair reached only ~2.8:1 — those numerals were below
    /// AA before the retint.) 콜 takes a different hue because the denominator is the
    /// term beginners miss.
    static let segPot  = dyn(0x24593F, 0x24593F)
    static let segBet  = dyn(0x2F7352, 0x2F7352)
    static let segCall = dyn(0x7A5C18, 0x7A5C18)

    static let suitRed = dyn(0xC0392B, 0xE06B60)

    // relativeTo: .body → all text scales with the user's Dynamic Type setting.
    static func title(_ s: CGFloat) -> Font    { .custom("Pretendard-Bold", size: s, relativeTo: .body) }
    static func semibold(_ s: CGFloat) -> Font { .custom("Pretendard-SemiBold", size: s, relativeTo: .body) }
    static func body(_ s: CGFloat) -> Font     { .custom("Pretendard-Regular", size: s, relativeTo: .body) }
}

/// Grade band colours, scheme-aware.
///
/// The band inks were measured against their own light tints at 4.95–5.12:1. In dark
/// the tints become deep washes and the inks lighten to keep that ratio, so the
/// verdict stays AA in both schemes — and structure/shape/text still carry it even if
/// colour is stripped entirely.
enum GTBand {
    static let spotOnInk  = dyn(0x0F7645, 0x5FD79B)
    static let closeInk   = dyn(0x9C5700, 0xE0A85A)
    static let offInk     = dyn(0xC02A2A, 0xF08A80)
    static let spotOnTint = dyn(0xE7F7EF, 0x13322A)
    static let closeTint  = dyn(0xFEF0DA, 0x33291A)
    static let offTint    = dyn(0xFDECEC, 0x361F1F)
}

/// Home/settings backdrop. Flat rather than gradient — M1's spanned `#1B8A52`→
/// `#0E5A34`, which is a lot of moving luminance behind text you read for an hour.
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
