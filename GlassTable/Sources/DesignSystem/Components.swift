// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine

/// Press feedback for every tappable surface: slight shrink + dim, 150ms.
struct GTPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A row of cards at the largest ladder size that fits the width — big cards on
/// today's heads-up spots, graceful shrink when future spots put more cards in a row.
struct CardRow: View {
    let cards: [Card]
    var dead: Bool = false
    private func row(_ size: CGFloat) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.offset) {
                PlayingCardView(card: $0.element, size: size, dead: dead)
            }
        }
    }
    var body: some View {
        ViewThatFits(in: .horizontal) { row(64); row(56); row(48); row(40) }
    }
}

struct SectionLabel: View {
    let text: String
    var onDark: Bool = true
    var body: some View {
        Text(text).font(GT.semibold(10)).tracking(0.4)
            .foregroundStyle(onDark ? Color.white.opacity(0.62) : GT.inkMuted)
    }
}

struct GradePill: View {
    let band: GradeBand
    private var label: String {
        switch band { case .spotOn: return "정확"; case .close: return "근접"; case .off: return "빗나감" }
    }
    private var colors: (bg: Color, fg: Color) {
        switch band {
        case .spotOn: return (Color(hex: 0xE7F7EF), Color(hex: 0x12864E))
        case .close:  return (Color(hex: 0xFEF0DA), Color(hex: 0xC77700))
        case .off:    return (Color(hex: 0xFDECEC), Color(hex: 0xD23B3B))
        }
    }
    var body: some View {
        Text(label).font(GT.title(13))
            .padding(.horizontal, 13).padding(.vertical, 5)
            .background(colors.bg, in: Capsule())
            .foregroundStyle(colors.fg)
    }
}

/// "용어 · 팟 오즈" — opens the glossary scrolled to one term, from inside a reveal.
/// Owns its own sheet state so a call site is one line.
struct GlossaryChip: View {
    let term: String
    @State private var open = false
    var body: some View {
        Button { open = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "text.book.closed.fill").font(.system(size: 9.5))
                Text("용어 · \(term)").font(GT.semibold(11))
            }
            .foregroundStyle(GT.inkSecondary)
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(GT.surface, in: Capsule())
        }
        .buttonStyle(GTPress())
        .accessibilityLabel("용어집에서 \(term) 보기")
        .sheet(isPresented: $open) { GlossaryView(focus: term) }
    }
}

struct PrimaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(15)).foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(GT.cta, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(GTPress())
    }
}

struct SecondaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(15)).foregroundStyle(GT.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(GTPress())
    }
}

struct EstimateStepper: View {
    let value: Int
    var step: Int = 1
    var suffix: String = ""
    let onAdjust: (Int) -> Void
    private func key(_ s: String, _ d: Int) -> some View {
        Button { onAdjust(d) } label: {
            Text(s).font(GT.semibold(22)).foregroundStyle(GT.inkSecondary)
                .frame(width: 44, height: 44)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
        }.buttonStyle(GTPress())
    }
    var body: some View {
        HStack(spacing: 12) {
            key("−", -step)
            Text("\(value)\(suffix)").font(GT.title(24).monospacedDigit()).foregroundStyle(GT.green)
                .frame(minWidth: 60, minHeight: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 13))
            key("+", step)
        }
    }
}
