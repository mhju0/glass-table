// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit

/// Resolves per interface style. Used for the *few* tokens that genuinely differ.
private func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
}

/// Three materials, and only three.
///
/// - **Felt** — the table. Dark, matte, always.
/// - **Glass** — every elevated surface: sheets, cards, panels. A blur of the felt
///   beneath it, tinted green and veiled with warm ivory, lit along its top edge.
/// - **Paper** — playing-card faces, and nothing else. A card is paper in any light.
///
/// **The rule: ink never flips, because the surface under it never flips.** Every
/// colour bug in this app came from breaking it — near-white numerals printed on a
/// cream card, a card-container fill used as a button so it went dark-on-dark. Each
/// was a scheme-aware ink sitting on a surface that stayed put.
///
/// Only the felt's depth and the card stock's brightness follow the system scheme.
/// Dark mode is the same room at night, not an inverted one.
enum GT {
    // MARK: felt — the table

    static let felt         = dyn(0x1B4234, 0x0F211A)
    static let feltDeep     = dyn(0x14382B, 0x0A1811)
    static let hairlineFelt = dyn(0x2A5546, 0x244134)

    /// Ink on felt. Fixed.
    static let onFelt          = Color(hex: 0xF2EFE7)
    static let onFeltSecondary = Color(hex: 0x9DB3A6)
    static let onFeltMuted     = Color(hex: 0x7E978A)

    // MARK: glass — every elevated surface

    /// Warm ivory veil laid **over** a blur rather than a solid fill. That is what
    /// keeps the surface dark enough for white text while still reading as ivory:
    /// a solid ivory would lighten it past the point where white survives, and the
    /// only fix there is dark text, which is the flat-paper look this replaces.
    ///
    /// Measured 8.4:1 for `ink` on the resulting surface. The ceiling is ~40% veil,
    /// past which white text drops under WCAG AA.
    static let glassVeil = LinearGradient(
        colors: [Color(hex: 0xF4F1E9).opacity(0.20), Color(hex: 0xF4F1E9).opacity(0.09)],
        startPoint: .top, endPoint: .bottom)
    /// Green tint under the veil, so the glass belongs to the table it floats over.
    static let glassTint = Color(hex: 0x1A3026).opacity(0.68)
    /// The lit edge that sells elevation — light catching the lip of a raised surface.
    static let glassEdge = Color(hex: 0x6FD3A0).opacity(0.40)

    /// Playing-card faces stay **paper**. A card is paper in any light; it is the one
    /// surface in the app that is not glass, and that is the point of the metaphor.
    static let cardFace = dyn(0xF7F5EF, 0xEFEBE0)

    /// Inset block inside glass — the "why" panel, stepper keys, unfilled pips.
    static let surface  = Color(hex: 0xF7F4EC).opacity(0.10)

    /// Ink on glass. Light, because the surface under it is dark.
    static let ink          = Color(hex: 0xF7F4EC)
    static let inkSecondary = Color(hex: 0xC2CBC3)
    static let inkMuted     = Color(hex: 0x98A79E)

    /// Edges. Quiet — separation comes from the material and the elevation first.
    static let border       = Color(hex: 0xF7F4EC).opacity(0.16)
    static let borderStrong = Color(hex: 0xF7F4EC).opacity(0.26)

    // MARK: actions

    /// Primary action on glass: mint fill, dark lettering.
    static let cta   = Color(hex: 0x6FD3A0)
    static let onCTA = Color(hex: 0x10261C)
    /// Accent for icons and live values on glass.
    static let green = Color(hex: 0x6FD3A0)
    /// Accents drawn on felt.
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

/// Grade bands, on glass. Light inks over their own low-alpha washes — the previous
/// dark-on-pale-tint pair would have vanished once the surface went dark.
/// Measured 6.5 / 6.9 / 6.1:1 against the glass, so the verdict clears AA; shape,
/// structure and wording still carry it if colour is stripped entirely.
enum GTBand {
    static let spotOnInk  = Color(hex: 0x8FE3BB)
    static let closeInk   = Color(hex: 0xE8C089)
    static let offInk     = Color(hex: 0xF0A49C)
    static let spotOnTint = Color(hex: 0x6FD3A0).opacity(0.16)
    static let closeTint  = Color(hex: 0xE0A85A).opacity(0.16)
    static let offTint    = Color(hex: 0xE06B60).opacity(0.16)
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
