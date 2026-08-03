// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit

/// Resolves per interface style. Used for the *few* tokens that genuinely differ.
private func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
}

/// 펠트 + 카드지 — two materials, and only two.
///
/// **The rule: ink never flips, because the surface under it never flips.**
/// A thing is either on the *felt* (dark, always) or on *paper* (light, always), so
/// `onFelt*` and `ink*` are fixed values. Every colour bug so far came from breaking
/// this — near-white ink printed on a cream card, a dark button on dark felt — and
/// each was a scheme-aware ink sitting on a surface that stayed put.
///
/// Only the felt's depth and the paper's brightness follow the system scheme. Dark
/// mode is the same room at night, not an inverted one.
enum GT {
    // MARK: felt — the table

    static let felt         = dyn(0x1B4234, 0x0F211A)
    static let feltDeep     = dyn(0x14382B, 0x0A1811)
    static let hairlineFelt = dyn(0x2A5546, 0x244134)

    /// Ink on felt. Fixed.
    static let onFelt          = Color(hex: 0xF2EFE7)
    static let onFeltSecondary = Color(hex: 0x9DB3A6)
    static let onFeltMuted     = Color(hex: 0x7E978A)

    // MARK: paper — cards, sheets, anything you act on

    /// Dimmed at night so a full-width sheet is not a floodlight, but still paper.
    /// This is what gives separation from the felt: a different *material*, which
    /// reads at a glance in a way a hairline never does.
    static let card     = dyn(0xF4F1E9, 0xE4E0D4)
    static let cardFace = dyn(0xF7F5EF, 0xEFEBE0)
    /// Inset block inside paper — the "why" panel, stepper keys, unfilled pips.
    static let surface  = dyn(0xE9E4D6, 0xD8D3C4)

    /// Ink on paper. Fixed.
    static let ink          = Color(hex: 0x16211C)
    static let inkSecondary = Color(hex: 0x55635B)
    static let inkMuted     = Color(hex: 0x8B978D)

    /// Edges. Present but quiet — separation comes from the material change first.
    static let border       = Color(hex: 0xD8D2C1)
    static let borderStrong = Color(hex: 0xBDB6A2)

    // MARK: actions

    /// Primary action **on paper**: deep felt fill, cream lettering.
    static let cta   = Color(hex: 0x1B4234)
    static let onCTA = Color(hex: 0xF4F1E9)
    /// Accent for icons and live values on paper.
    static let green = Color(hex: 0x1B4234)
    /// Accents drawn **on felt**, where the deep greens vanish.
    static let mint  = Color(hex: 0x6FD3A0)

    /// Price-bar segments, on felt, with `onFelt` numerals inside. Measured against
    /// `onFelt` at 7.1 / 4.9 / 5.4:1 — all clear WCAG AA. 콜 is a different hue
    /// because the denominator is the term beginners miss.
    static let segPot  = Color(hex: 0x24593F)
    static let segBet  = Color(hex: 0x2F7352)
    static let segCall = Color(hex: 0x7A5C18)

    static let suitRed = Color(hex: 0xC0392B)
    /// Ink printed on a playing card. Fixed, for the same reason as everything above.
    static let cardInk     = Color(hex: 0x1A2621)
    static let cardSuitRed = Color(hex: 0xC0392B)

    // relativeTo: .body → all text scales with the user's Dynamic Type setting.
    static func title(_ s: CGFloat) -> Font    { .custom("Pretendard-Bold", size: s, relativeTo: .body) }
    static func semibold(_ s: CGFloat) -> Font { .custom("Pretendard-SemiBold", size: s, relativeTo: .body) }
    static func body(_ s: CGFloat) -> Font     { .custom("Pretendard-Regular", size: s, relativeTo: .body) }
}

/// Grade bands. Always on paper, so these are fixed too — the inks were measured
/// against their own tints at 4.95–5.12:1 and that no longer depends on the scheme.
enum GTBand {
    static let spotOnInk  = Color(hex: 0x0F7645)
    static let closeInk   = Color(hex: 0x9C5700)
    static let offInk     = Color(hex: 0xC02A2A)
    static let spotOnTint = Color(hex: 0xE0F2E7)
    static let closeTint  = Color(hex: 0xFAEBD4)
    static let offTint    = Color(hex: 0xF9E5E3)
}

/// Home/settings backdrop: flat felt plus a faint spade.
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
