// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import GlassTableDrills

/// The appearance applied to the app and to system-presented UI.
///
/// This preference is deliberately independent of poker progress. It lives in
/// `UserDefaults` through `AppStorage`, so importing or resetting a progress backup
/// never changes how the app looks.
enum AppAppearance: String, CaseIterable, Identifiable {
    static let storageKey = "appAppearance"

    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        title(in: .korean)
    }

    func title(in language: LearningLanguage) -> String {
        switch self {
        case .system: language.text("시스템", "System")
        case .light: language.text("라이트", "Light")
        case .dark: language.text("다크", "Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Semantic design tokens for both app appearances.
///
/// Neutral surfaces follow the selected appearance. The poker table, playing cards,
/// and their ink stay fixed because they are objects inside the interface, not page
/// chrome. Amber is reserved for actions and selection; green reports success.
enum GT {
    enum Space {
        static let compact: CGFloat = 8
        static let related: CGFloat = 12
        static let section: CGFloat = 20
        static let screen: CGFloat = 24
    }

    enum Radius {
        static let control: CGFloat = 14
        static let panel: CGFloat = 20
        static let sheet: CGFloat = 28
    }

    enum Motion {
        static let press = Animation.interactiveSpring(response: 0.22, dampingFraction: 0.9)
        static let change = Animation.interactiveSpring(response: 0.34, dampingFraction: 0.9)
    }

    enum Typography {
        static let bodyLineSpacing: CGFloat = 3
        static let explanationLineSpacing: CGFloat = 4
        static let questionSize: CGFloat = 18
        static let explanationSize: CGFloat = 16
        static let buttonSize: CGFloat = 17
        static let resultSize: CGFloat = 22
    }

    // MARK: Adaptive app surfaces

    /// Compatibility names used throughout the app. These now describe the page,
    /// not the poker table; new table UI uses the explicit fixed roles below.
    static let felt = Color.adaptive(light: 0xF2EEE5, dark: 0x17191C)
    static let onFelt = Color.adaptive(light: 0x222C29, dark: 0xF4F0E6)
    static let onFeltSecondary = Color.adaptive(light: 0x515E58, dark: 0xBFC3C8)
    static let onFeltMuted = Color.adaptive(light: 0x5A6660, dark: 0xADB2B8)
    static let hairlineFelt = Color.adaptive(light: 0xC4BCB0, dark: 0x4A4F55)

    static let glass = Color.adaptive(light: 0xFFFDF7, dark: 0x24272B)
    static let glassEdge = Color.adaptive(light: 0x817A70, dark: 0x757A81)
    static let surface = Color.adaptive(light: 0xE7E1D6, dark: 0x1D2024)

    static let ink = Color.adaptive(light: 0x222C29, dark: 0xF4F0E6)
    static let inkSecondary = Color.adaptive(light: 0x515E58, dark: 0xBFC3C8)
    static let inkMuted = Color.adaptive(light: 0x5A6660, dark: 0xADB2B8)

    static let border = Color.adaptive(light: 0xC4BCB0, dark: 0x4A4F55)
    static let borderStrong = Color.adaptive(light: 0x746E65, dark: 0x989DA4)

    // MARK: Fixed poker-table object

    static let tableFelt = Color(hex: 0x153D33)
    static let tableFeltDeep = Color(hex: 0x102A23)
    static let tableHairline = Color(hex: 0x547A70)
    static let onTable = Color(hex: 0xF4F0E6)
    static let onTableSecondary = Color(hex: 0xC8D6D0)
    static let onTableMuted = Color(hex: 0xA8BBB4)
    static let tableAccent = Color(hex: 0xEDC17F)
    static let onTableAccent = Color(hex: 0x241B0E)
    /// The shared table's material: a rail darker than the felt, seats as darker
    /// areas of it, and ivory chips. Only cards, chips and the dealer disc cast shadows.
    static let tableRail = Color(hex: 0x0D2A20)
    static let tableSeat = Color(hex: 0x123A2D)
    static let tableSeatLine = Color(hex: 0x2A5646)
    static let tableSeatActive = Color(hex: 0xF3CA87)
    static let tableStatus = Color(hex: 0xCFDAD2)
    static let chipTop = Color(hex: 0xF2ECDD)
    static let chipSide = Color(hex: 0xD6CCB4)
    static let chipEdge = Color(hex: 0x2F3B40)
    static let cardBack = Color(hex: 0x2C3A42)
    static let cardBackLine = Color(hex: 0xE9E2CF)

    /// Existing card backs remain part of the fixed table object.
    static let feltDeep = tableFeltDeep

    // MARK: Action and feedback

    /// Amber marks the action or selection under the user's control. The light
    /// appearance uses a deeper amber so the token remains legible as text.
    static let cta = Color.adaptive(light: 0x8A5500, dark: 0xEDC17F)
    static let onCTA = Color.adaptive(light: 0xFFFFFF, dark: 0x241B0E)
    static let mint = cta

    /// Green is a result/status color, not the primary action color.
    static let green = Color.adaptive(light: 0x216B4D, dark: 0x83C9A4)

    /// Price-bar colors retain their poker meaning on the fixed table.
    static let segPot = Color(hex: 0x24593F)
    static let segBet = Color(hex: 0x2F7352)
    static let segCall = Color(hex: 0x7A5C18)
    static let actionBet = Color.adaptive(light: 0x216B4D, dark: 0x83C9A4)
    static let actionCall = Color.adaptive(light: 0x8A5500, dark: 0xEDC17F)

    static let suitRed = Color.adaptive(light: 0x9B332D, dark: 0xF0A39A)

    // MARK: Playing cards

    static let cardFace = Color(hex: 0xEFEBE0)
    static let cardInk = Color(hex: 0x1A2621)
    static let cardSuitRed = Color(hex: 0xC0392B)

    // relativeTo: .body makes ordinary text follow Dynamic Type.
    static func title(_ s: CGFloat) -> Font {
        .custom("Pretendard-Bold", size: s, relativeTo: .body)
    }

    /// Card ranks and suits are pictograms sized to the card. VoiceOver carries the
    /// accessible value while the glyph stays fixed so a five-card row cannot clip.
    static func fixed(_ s: CGFloat) -> Font {
        .custom("Pretendard-Bold", fixedSize: s)
    }

    static func semibold(_ s: CGFloat) -> Font {
        .custom("Pretendard-SemiBold", size: s, relativeTo: .body)
    }

    static func body(_ s: CGFloat) -> Font {
        .custom("Pretendard-Regular", size: s, relativeTo: .body)
    }
}

/// Grade feedback remains text-first and changes tone with the app appearance.
enum GTBand {
    static let spotOnInk = Color.adaptive(light: 0x216B4D, dark: 0x83C9A4)
    static let closeInk = Color.adaptive(light: 0x805000, dark: 0xE8C089)
    static let offInk = Color.adaptive(light: 0x9B332D, dark: 0xF0A39A)
    static let spotOnTint = Color.adaptive(light: 0xDCEDE4, dark: 0x263D34)
    static let closeTint = Color.adaptive(light: 0xF1E4CC, dark: 0x3B3325)
    static let offTint = Color.adaptive(light: 0xF2DEDB, dark: 0x3D2929)
}

/// App backdrop. The subtle spade keeps the Glass Table identity in both appearances
/// without turning the entire interface into a green poker table.
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
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255)
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(hex: value)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255,
                  alpha: 1)
    }
}
