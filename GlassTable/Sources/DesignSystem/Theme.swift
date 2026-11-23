// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import UIKit
import CoreText
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
        /// The one content edge of a page. Controls in the top bar line up with it too.
        static let edge: CGFloat = 18
        /// Inside a card: the gap above the text equals the gap beside it.
        static let card: CGFloat = 16
        /// Inside a sheet or popover, whose larger corner needs more room than a card's.
        static let sheet: CGFloat = 20
        static let seat: CGFloat = 10
    }

    enum Radius {
        static let tile: CGFloat = 8
        static let control: CGFloat = 10
        static let panel: CGFloat = 10
    }

    enum Motion {
        static let press = Animation.interactiveSpring(response: 0.22, dampingFraction: 0.9)
        static let change = Animation.interactiveSpring(response: 0.34, dampingFraction: 0.9)
        /// Fades and entrances: strong ease-out.
        static let fade = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)
        /// A chip or card travelling across the table: strong ease-in-out.
        static let move = Animation.timingCurve(0.77, 0, 0.175, 1, duration: 0.22)
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

    static let felt = Color.adaptive(light: 0xF4E8D1, dark: 0x19271E)
    static let paper = Color.adaptive(light: 0xFFF3DA, dark: 0x25392C)
    static let glass = Color.adaptive(light: 0xFFFAF0, dark: 0x2B4234)
    static let sheet = Color.adaptive(light: 0xFFFBF1, dark: 0x294133)
    static let surface = paper
    static let progressTrack = Color.adaptive(light: 0xEADBB7, dark: 0x50614B, darkHigh: 0x425440)

    static let ink = Color.adaptive(light: 0x23382E, dark: 0xFFF2D7, darkHigh: 0xFFF9E7)
    static let inkSecondary = Color.adaptive(light: 0x4D6052, dark: 0xD5DFC6,
                                             lightHigh: 0x354638, darkHigh: 0xF5F8E9)
    static let inkMuted = inkSecondary

    static let border = Color.adaptive(light: 0x8E8065, dark: 0x8B987A,
                                       lightHigh: 0x6C604B, darkHigh: 0xBFCBAA)
    static let glassEdge = border
    static let borderStrong = Color.adaptive(light: 0x796D56, dark: 0xA3AE8D,
                                             lightHigh: 0x5A5040, darkHigh: 0xD0DCBD)

    // Existing page-ink names. Table objects use the fixed tokens below.
    static let onFelt = ink
    static let onFeltSecondary = inkSecondary
    static let onFeltMuted = inkMuted
    static let hairlineFelt = border

    // MARK: Fixed poker-table object

    static let tableFelt = Color(hex: 0x16694F)
    static let tableFeltLight = Color(hex: 0x20785B)
    static let tableFeltDeep = Color(hex: 0x104E3A)
    static let tableHairline = Color(hex: 0x759E86)
    static let onTable = Color(hex: 0xFFF7E5)
    static let onTableSecondary = Color(hex: 0xEFF7E8)
    static let onTableMuted = Color.adaptive(light: 0xE4F2DC, dark: 0xE4F2DC,
                                             lightHigh: 0xFFF7E5, darkHigh: 0xFFF7E5)
    static let tableAccent = Color(hex: 0xFFEDBA)
    static let onTableAccent = Color(hex: 0x38250F)
    static let tableRail = Color(hex: 0x14523E)
    static let tableSeat = Color(hex: 0x104E3A)
    static let tableSeatLine = Color(hex: 0x487A64)
    static let tableSeatActive = tableAccent
    static let tableStatus = onTableSecondary
    static let chipTop = Color(hex: 0xF2ECDD)
    static let chipSide = Color(hex: 0xD6CCB4)
    static let chipEdge = Color(hex: 0x2F3B40)
    static let cardBack = Color(hex: 0x2C3A42)
    static let cardBackLine = Color(hex: 0xE9E2CF)
    static let feltDeep = tableFeltDeep

    // MARK: Action and feedback

    /// Amber ink and its existing inverse for compact indicators, links and charts.
    static let cta = Color.adaptive(light: 0x664215, dark: 0xFCE2AD, lightHigh: 0x573610)
    static let onCTA = Color.adaptive(light: 0xFFFFFF, dark: 0x241B0E)
    static let mint = cta

    /// A raised action face uses dark ink in both appearances.
    static let actionFill = Color(hex: 0xFFC86D)
    static let actionInk = onTableAccent
    static let actionEdge = Color.adaptive(light: 0x846137, dark: 0xAC824D,
                                           lightHigh: 0x67491F, darkHigh: 0xD5AA73)

    static let supportFill = Color.adaptive(light: 0xD7ECCE, dark: 0x375940)
    static let supportInk = Color.adaptive(light: 0x284D37, dark: 0xF0F7DC,
                                           lightHigh: 0x1C3827, darkHigh: 0xF5F8E9)
    static let supportEdge = Color.adaptive(light: 0x698663, dark: 0x8EAD80,
                                            lightHigh: 0x4C6848, darkHigh: 0xB6CEA4)
    static let retryFill = Color.adaptive(light: 0xF8DFCF, dark: 0x533D35)
    static let retryInk = Color.adaptive(light: 0x593B30, dark: 0xFFECE1,
                                         lightHigh: 0x462B21, darkHigh: 0xFFF5EC)
    static let retryEdge = Color.adaptive(light: 0xAB735D, dark: 0xCA9983,
                                          lightHigh: 0x8C523F, darkHigh: 0xEDBDA5)

    static let green = Color.adaptive(light: 0x16694F, dark: 0xBFE4AE,
                                      lightHigh: 0x13513E, darkHigh: 0xD0EFAB)

    // MARK: Lesson diagrams

    static let diagramHoney = Color.adaptive(light: 0xF4E6C9, dark: 0x483B27)
    static let diagramRangeFill = Color.adaptive(light: 0xB7CFA3, dark: 0x4B7055,
                                                 lightHigh: 0xB0C99A, darkHigh: 0x45694D)
    static let diagramCardEdge = Color(hex: 0x956021)
    static let segPot = Color(hex: 0x24593F)
    static let segBet = Color(hex: 0x5B6E43)
    static let segCall = actionFill
    static let actionBet = green
    static let actionCall = cta

    static let suitRed = Color.adaptive(light: 0x9E263A, dark: 0xF0A39A, lightHigh: 0x7E2435)

    // MARK: Playing cards

    static let cardFace = Color(hex: 0xFFF8E6)
    static let cardEdge = Color(hex: 0x8E8065)
    static let cardInk = Color(hex: 0x23382E)
    static let cardSuitRed = Color.adaptive(light: 0x9E263A, dark: 0x9E263A,
                                            lightHigh: 0x7E2435, darkHigh: 0x7E2435)

    // relativeTo: .body makes ordinary text follow Dynamic Type. Titles follow Apple's
    // title styles, which grow less at accessibility sizes, so a long word stays whole.
    //
    // A custom face ignores the system Bold Text setting, so each role steps up one
    // Pretendard weight itself when it is on, the way system text does.
    static func title(_ s: CGFloat) -> Font {
        .custom(boldText ? "Pretendard-ExtraBold" : "Pretendard-Bold",
                size: s, relativeTo: titleStyle(s))
    }

    private static var boldText: Bool { UIAccessibility.isBoldTextEnabled }

    static func titleStyle(_ s: CGFloat) -> Font.TextStyle {
        switch s {
        case 30...: .largeTitle
        case 26..<30: .title
        case 21..<26: .title2
        case 19..<21: .title3
        default: .body
        }
    }

    enum TextRole {
        case title(CGFloat), semibold(CGFloat), body(CGFloat)

        var size: CGFloat {
            switch self { case .title(let size), .semibold(let size), .body(let size): size }
        }

        var style: Font.TextStyle {
            if case .title = self { return GT.titleStyle(size) }
            return .body
        }

        /// Hangul reaches higher than Latin capitals in Pretendard. Measure the
        /// matching script's ink, then scale with the text's Dynamic Type role.
        func inkLeading(in language: LearningLanguage) -> CGFloat {
            let name: String
            switch self {
            case .title: name = GT.boldText ? "Pretendard-ExtraBold" : "Pretendard-Bold"
            case .semibold: name = GT.boldText ? "Pretendard-Bold" : "Pretendard-SemiBold"
            case .body: name = GT.boldText ? "Pretendard-SemiBold" : "Pretendard-Regular"
            }
            let font = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
            let character: UniChar = language == .korean ? 0xAC00 : 0x0048
            var glyph = CGGlyph()
            var characters = character
            let ctFont = CTFontCreateWithName(name as CFString, size, nil)
            guard CTFontGetGlyphsForCharacters(ctFont, &characters, &glyph, 1) else {
                return max(0, font.ascender - font.capHeight)
            }
            let bounds = CTFontGetBoundingRectsForGlyphs(ctFont, .default, &glyph, nil, 1)
            return max(0, font.ascender - bounds.maxY)
        }
    }

    /// Card ranks and suits are pictograms sized to the card. VoiceOver carries the
    /// accessible value while the glyph stays fixed so a five-card row cannot clip.
    static func fixed(_ s: CGFloat) -> Font {
        .custom("Pretendard-Bold", fixedSize: s)
    }

    static func semibold(_ s: CGFloat) -> Font {
        .custom(boldText ? "Pretendard-Bold" : "Pretendard-SemiBold", size: s, relativeTo: .body)
    }

    static func body(_ s: CGFloat) -> Font {
        .custom(boldText ? "Pretendard-SemiBold" : "Pretendard-Regular", size: s, relativeTo: .body)
    }
}

/// Grade feedback remains text-first and changes tone with the app appearance.
enum GTBand {
    static let spotOnInk = GT.supportInk
    static let closeInk = Color.adaptive(light: 0x664215, dark: 0xFCE2AD,
                                         lightHigh: 0x573610, darkHigh: 0xFFF0D1)
    static let offInk = GT.retryInk
    static let spotOnTint = GT.supportFill
    static let closeTint = GT.diagramHoney
    static let offTint = GT.retryFill
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

    /// Light and dark values, plus optional stronger values for Increase Contrast.
    static func adaptive(light: UInt32, dark: UInt32,
                         lightHigh: UInt32? = nil, darkHigh: UInt32? = nil) -> Color {
        Color(uiColor: UIColor { traits in
            let high = traits.accessibilityContrast == .high
            let value = traits.userInterfaceStyle == .dark
                ? (high ? darkHigh ?? dark : dark)
                : (high ? lightHigh ?? light : light)
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
