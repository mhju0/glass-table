// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// A range's five buckets as one stacked bar, weakest on the left.
///
/// The bar exists because the *number* is not the lesson. "A-high boards favour the
/// opener" is only visible as a shape, and two bars stacked above each other make the
/// comparison without asking anyone to subtract two percentages in their head.
///
/// Colour is never the only channel: the segments are ordered weakest→strongest and
/// carry their own labels underneath, so the bar survives greyscale and the legend is
/// readable without matching swatches to a key.
struct BucketBarView: View {
    let label: String
    let distribution: RangeOnBoard

    /// Weakest to strongest: dim felt-ink through to full mint. A single hue ramp, so
    /// "further right is stronger" is legible to any form of colour blindness.
    private func fill(_ b: MadeHand) -> Color {
        switch b {
        case .air:      return GT.onFelt.opacity(0.14)
        case .draw:     return GT.onFelt.opacity(0.28)
        case .weakPair: return GT.mint.opacity(0.34)
        case .topPair:  return GT.mint.opacity(0.62)
        case .strong:   return GT.mint
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
                Spacer(minLength: 8)
                Text("페어 이상 \(pctText(distribution.pairOrBetter * 100))%")
                    .font(GT.title(13).monospacedDigit()).foregroundStyle(GT.onFelt)
            }
            GeometryReader { geo in
                HStack(spacing: 1.5) {
                    ForEach(MadeHand.allCases, id: \.self) { b in
                        // A zero-width segment would still take its 1.5pt of spacing and
                        // print a stray sliver, so drop it entirely.
                        if distribution.share(b) > 0 {
                            Rectangle().fill(fill(b))
                                .frame(width: max(1, geo.size.width * distribution.share(b)))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .frame(height: 22)
            // Every bar carries its own legend. Sharing one between two bars looked
            // tidier and was wrong: the legend prints per-bucket *percentages*, so a
            // single copy under the lower bar silently attributed one range's numbers
            // to both.
            legend
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var legend: some View {
        // Wraps, because five Korean bucket names do not fit one line on a mini.
        FlowRow(spacing: 9) {
            ForEach(MadeHand.allCases, id: \.self) { b in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(fill(b))
                        .frame(width: 9, height: 9)
                    Text("\(b.korean) \(pctText(distribution.share(b) * 100))%")
                        .font(GT.body(10)).foregroundStyle(GT.onFeltMuted)
                }
            }
        }
    }

    private var spoken: String {
        label + ", " + MadeHand.allCases
            .map { "\($0.korean) \(pctText(distribution.share($0) * 100))퍼센트" }
            .joined(separator: ", ")
    }
}

/// Minimal wrapping row. `LazyVGrid` cannot do variable-width items and an `HStack`
/// clips; five bucket labels need to wrap on a 12 mini.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
                       cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
