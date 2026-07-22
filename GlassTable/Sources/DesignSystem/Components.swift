// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine

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

struct PrimaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(15)).foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(GT.cta, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct EstimateStepper: View {
    let value: Int
    let onAdjust: (Int) -> Void
    private func key(_ s: String, _ d: Int) -> some View {
        Button { onAdjust(d) } label: {
            Text(s).font(GT.semibold(22)).foregroundStyle(GT.inkSecondary)
                .frame(width: 44, height: 44)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
        }.buttonStyle(.plain)
    }
    var body: some View {
        HStack(spacing: 12) {
            key("−", -1)
            Text("\(value)").font(GT.title(24)).foregroundStyle(GT.green)
                .frame(minWidth: 60, minHeight: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 13))
            key("+", 1)
        }
    }
}
