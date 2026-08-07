// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

/// Three materials, and only three.
///
/// - **Felt** — the table. Dark, matte, always.
/// - **Glass** — every elevated surface: sheets, cards, panels. Green, lit along its
///   top edge, floating on a shadow.
/// - **Paper** — playing-card faces, and nothing else.
///
/// **The rule: ink never flips, because the surface under it never flips.**
///
/// The app is pinned to the dark appearance (`UIUserInterfaceStyle` in project.yml),
/// so there is no second set of values to keep in step. It used to ship two, and they
/// measured 1.50:1 apart on the felt and **1.04:1 on every glass surface** — the same
/// pixel. Two schemes were being maintained and one was being shipped.
///
/// **Glass is a colour, not a material.** It was `.ultraThinMaterial` under a tint and
/// an ivory veil. But `FeltBackground` is a flat fill plus a spade at 3.5% opacity, so
/// the blur had nothing to blur: it cost an offscreen pass per surface to arrive at a
/// solid tint, and it forced `.dark` onto the material to stop the system flipping it.
/// The opaque value below is where that stack already landed (#38473E measured off a
/// real screenshot), so the app looks the same and the boundary is now controllable.
enum GT {
    // MARK: felt — the table

    static let felt         = Color(hex: 0x0F211A)
    static let feltDeep     = Color(hex: 0x0A1811)
    static let hairlineFelt = Color(hex: 0x244134)

    /// Ink on felt. Fixed.
    static let onFelt          = Color(hex: 0xF2EFE7)
    static let onFeltSecondary = Color(hex: 0x9DB3A6)
    static let onFeltMuted     = Color(hex: 0x7E978A)

    // MARK: glass — every elevated surface

    /// Every elevated surface. Deliberately kept dark: brightening it to clear 3:1
    /// against the felt takes it to #566D60, where `inkMuted` falls to 2.2:1 and the
    /// three band inks to 2.6–3.3:1. That trades one boundary failure for six ink
    /// failures, so the boundary is carried by `borderStrong` instead.
    ///
    /// Measured on this value: ink 8.6:1, inkSecondary 5.7:1, green 5.2:1,
    /// 정확 6.3:1, 근접 5.6:1, 빗나감 4.7:1 — all clear WCAG AA.
    static let glass = Color(hex: 0x3B4941)
    /// The lit edge that sells elevation — light catching the lip of a raised surface.
    static let glassEdge = Color(hex: 0x6FD3A0).opacity(0.40)

    /// Playing-card faces stay **paper**. It is the one surface in the app that is not
    /// glass, and that is the point of the metaphor — measured 7.7:1 against the felt,
    /// the highest contrast anywhere in the app and the fastest thing to read.
    static let cardFace = Color(hex: 0xEFEBE0)

    /// Inset block inside glass — the "why" panel, stepper keys, unfilled pips, a
    /// choice that is not selected.
    ///
    /// Recessed: a well cut **down** toward the table, not a smudge of ivory laid on
    /// top. Direction is forced, not chosen. White ink cannot survive two 3:1 steps up
    /// from the felt — the second one puts the fill at #A8AEA6, where `ink` is 1.9:1 —
    /// so an inset that must be distinguishable has nowhere to go but down.
    static let surface  = Color(hex: 0x16261E)

    /// Ink on glass. Light, because the surface under it is dark.
    static let ink          = Color(hex: 0xF7F4EC)
    static let inkSecondary = Color(hex: 0xC2CBC3)
    static let inkMuted     = Color(hex: 0x98A79E)

    /// Edges. **The edge is the boundary now**, not the material — a surface that is
    /// only 1.8:1 off its background is not a boundary no matter how it was made.
    ///
    /// `borderStrong` is **opaque**, unlike every edge before it. `strokeBorder` insets
    /// and paints over the shape's own fill, so a translucent edge resolves against
    /// whatever it happens to be drawn on: at 43% ivory it came out #8C938B on a card
    /// and #777F77 on a recessed choice button, and only the first cleared 3:1 against
    /// the surface behind it. A fixed value is the same edge everywhere.
    ///
    /// Measured 3.0:1 against the glass and 5.3:1 against the felt or a recessed
    /// inset — clears WCAG 1.4.11 on both sides. The old 26% ivory managed 2.49:1 and
    /// 1.86:1, which is why three choice buttons read as three rows of text.
    static let border       = Color(hex: 0xF7F4EC).opacity(0.16)
    static let borderStrong = Color(hex: 0x8C938B)

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

    /// Lit relatives of the two price-bar segments, for the accent rule under a table
    /// action button. The segments themselves are sized to carry `onFelt` numerals on
    /// felt, so as a hairline on `surface` they measure 2.79:1 (벳) and 2.54:1 (콜) —
    /// both under WCAG 1.4.11's 3:1 for a non-text element. These are the same hues
    /// raised until they clear it: 4.6:1 and 4.2:1 on `surface`.
    ///
    /// They mark **what kind of money** a button commits — the same thing the price
    /// bar's colours mean — and never which button is better. The table grades the
    /// choice, so an action rendered as the sheet's primary CTA would hand over the
    /// answer before the user commits.
    static let actionBet  = Color(hex: 0x3E9A6E)
    static let actionCall = Color(hex: 0xA67C1F)

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
