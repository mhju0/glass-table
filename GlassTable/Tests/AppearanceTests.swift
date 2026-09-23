import Foundation
import SwiftUI
import Testing
import UIKit
@testable import GlassTable

struct AppearanceTests {
    @Test func appearancePreferenceRoundTripsWithoutProgressState() throws {
        let suite = "appearance-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(defaults.string(forKey: AppAppearance.storageKey) == nil)
        defaults.set(AppAppearance.dark.rawValue, forKey: AppAppearance.storageKey)

        let saved = try #require(defaults.string(forKey: AppAppearance.storageKey))
        #expect(AppAppearance(rawValue: saved) == .dark)
        #expect(AppAppearance.system.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func semanticTextPairsMeetNormalTextContrast(style: UIUserInterfaceStyle) throws {
        let pairs: [(Color, Color, String)] = [
            (GT.onFelt, GT.felt, "page primary"),
            (GT.onFeltSecondary, GT.felt, "page secondary"),
            (GT.ink, GT.glass, "panel primary"),
            (GT.inkSecondary, GT.glass, "panel secondary"),
            (GT.inkMuted, GT.glass, "panel muted"),
            (GT.inkMuted, GT.surface, "field muted"),
            (GT.onCTA, GT.cta, "primary action"),
            (GT.green, GT.glass, "success"),
            (GTBand.spotOnInk, GTBand.spotOnTint, "exact grade"),
            (GTBand.closeInk, GTBand.closeTint, "close grade"),
            (GTBand.offInk, GTBand.offTint, "off grade"),
        ]

        for (foreground, background, name) in pairs {
            let ratio = try contrast(foreground, background, style: style)
            #expect(ratio >= 4.5, "\(name) contrast was \(ratio):1")
        }
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func componentEdgesMeetNonTextContrast(style: UIUserInterfaceStyle) throws {
        let pairs: [(Color, Color, String)] = [
            (GT.glassEdge, GT.glass, "panel edge"),
            (GT.borderStrong, GT.glass, "control edge on panel"),
            (GT.borderStrong, GT.surface, "control edge on field"),
        ]

        for (foreground, background, name) in pairs {
            let ratio = try contrast(foreground, background, style: style)
            #expect(ratio >= 3, "\(name) contrast was \(ratio):1")
        }
    }

    @Test func fixedPokerObjectPairsMeetContrastInEitherAppearance() throws {
        let textPairs: [(Color, Color, String)] = [
            (GT.onTable, GT.tableFelt, "table primary"),
            (GT.onTableSecondary, GT.tableFelt, "table secondary"),
            (GT.onTableMuted, GT.tableFelt, "table muted"),
            (GT.onTable, GT.segPot, "pot segment"),
            (GT.onTable, GT.segBet, "bet segment"),
            (GT.onTable, GT.segCall, "call segment"),
            (GT.tableAccent, GT.tableFelt, "table selection"),
            (GT.onTableAccent, GT.tableAccent, "filled table selection"),
            (GT.cardInk, GT.cardFace, "card ink"),
            (GT.cardSuitRed, GT.cardFace, "red card ink"),
        ]

        for style in [UIUserInterfaceStyle.light, .dark] {
            for (foreground, background, name) in textPairs {
                let ratio = try contrast(foreground, background, style: style)
                #expect(ratio >= 4.5, "\(name) contrast was \(ratio):1")
            }
        }
    }

    @Test func adaptivePageChangesWhilePokerTableStaysFixed() throws {
        let lightPage = try rgba(GT.felt, style: .light)
        let darkPage = try rgba(GT.felt, style: .dark)
        let lightTable = try rgba(GT.tableFelt, style: .light)
        let darkTable = try rgba(GT.tableFelt, style: .dark)

        #expect(lightPage != darkPage)
        #expect(lightTable == darkTable)
    }

    private func contrast(_ foreground: Color, _ background: Color,
                          style: UIUserInterfaceStyle) throws -> Double {
        let foreground = try rgba(foreground, style: style)
        let background = try rgba(background, style: style)
        let lighter = max(foreground.luminance, background.luminance)
        let darker = min(foreground.luminance, background.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func rgba(_ color: Color, style: UIUserInterfaceStyle) throws -> RGBA {
        let resolved = UIColor(color).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: style)
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let converted = resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try #require(converted, "Color must resolve in the sRGB color space")
        return RGBA(red: Double(red), green: Double(green), blue: Double(blue))
    }
}

private struct RGBA: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    var luminance: Double {
        0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    private func linear(_ channel: Double) -> Double {
        channel <= 0.03928
            ? channel / 12.92
            : pow((channel + 0.055) / 1.055, 2.4)
    }
}
