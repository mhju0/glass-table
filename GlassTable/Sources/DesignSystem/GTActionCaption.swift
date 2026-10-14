// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI

struct GTActionCaption: View {
    enum Weight {
        case body, semibold

        func fontName(bold: Bool) -> String {
            switch self {
            case .body: bold ? "Pretendard-SemiBold" : "Pretendard-Regular"
            case .semibold: bold ? "Pretendard-Bold" : "Pretendard-SemiBold"
            }
        }
    }

    let text: String
    var weight: Weight = .body
    var baseSize: CGFloat = 12
    var ink: Color = GT.ink
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.displayScale) private var displayScale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var direction
    @State private var bold = UIAccessibility.isBoldTextEnabled

    private var traits: UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(preferredContentSizeCategory: typeSize.captionCategory),
            UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light),
            UITraitCollection(accessibilityContrast: contrast == .increased ? .high : .normal)
        ])
    }

    private var font: UIFont {
        let base = UIFont(name: weight.fontName(bold: bold), size: baseSize)
            ?? UIFont.systemFont(ofSize: baseSize, weight: weight == .semibold || bold ? .semibold : .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base, compatibleWith: traits)
    }

    var body: some View {
        let currentFont = font
        NativeActionCaption(text: text, font: currentFont,
                            ink: UIColor(ink).resolvedColor(with: traits),
                            locale: locale.identifier, direction: direction)
            .alignmentGuide(.firstTextBaseline) { _ in
                let lineHeight = ceil(currentFont.lineHeight * displayScale) / displayScale
                return currentFont.ascender + (lineHeight - currentFont.lineHeight) / 2
            }
            .onAppear { bold = UIAccessibility.isBoldTextEnabled }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.boldTextStatusDidChangeNotification)) { _ in
                bold = UIAccessibility.isBoldTextEnabled
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                bold = UIAccessibility.isBoldTextEnabled
            }
    }
}

private struct NativeActionCaption: UIViewRepresentable {
    let text: String
    let font: UIFont
    let ink: UIColor
    let locale: String
    let direction: LayoutDirection

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = false
        label.adjustsFontForContentSizeCategory = false
        label.isUserInteractionEnabled = false
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        configure(label)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        configure(label)
    }

    private func configure(_ label: UILabel) {
        let sizingChanged = label.text != text || label.font != font
        label.text = text
        label.font = font
        label.textColor = ink
        label.textAlignment = .natural
        label.semanticContentAttribute = direction == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        label.accessibilityLabel = text
        label.accessibilityLanguage = locale
        if sizingChanged { label.invalidateIntrinsicContentSize() }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let width = proposal.width.flatMap { $0.isFinite ? max(0, $0) : nil } ?? .greatestFiniteMagnitude
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: min(width, fitted.width), height: fitted.height)
    }
}

private extension DynamicTypeSize {
    var captionCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}
