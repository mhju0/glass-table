// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// The 13×13 range grid, in the layout every solver and chart already uses
/// (`decisions.md` §B): pairs down the diagonal AA→22, **suited above it, offsuit
/// below**. Identical everywhere, so it needs no orientation.
///
/// **Display only in R2.** Thirteen cells across a 339pt screen is ~24pt each, well
/// under the 44pt touch minimum — painting needs a magnifier or a different gesture,
/// and that belongs to R3, which is the slice where Range Read paints. Showing a
/// chart and pointing at one hand needs no touch target at all.
struct RangeGridView: View {
    let range: HandRange
    /// Drawn with a ring, so "where does my hand sit" is answered by looking.
    var highlight: HandClass?
    /// A second range drawn as a ring around each of its cells, so a reveal can put a
    /// guess on top of the truth in one grid instead of two.
    ///
    /// Fill and ring are independent channels, which is what makes the comparison
    /// readable without colour: filled + ringed = agreed, filled only = missed,
    /// ringed only = over-included. Two grids side by side on a phone would be ~12pt
    /// a cell, and a third colour would be neither.
    var outline: HandRange?
    var cellSpacing: CGFloat = 1.5



    var body: some View {
        GeometryReader { geo in
            let side = (geo.size.width - cellSpacing * 12) / 13
            VStack(spacing: cellSpacing) {
                ForEach(RangeGrid.ranks, id: \.self) { row in
                    HStack(spacing: cellSpacing) {
                        ForEach(RangeGrid.ranks, id: \.self) { col in
                            cell(for: RangeGrid.classAt(row: row, col: col), side: side)
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private func cell(for h: HandClass, side: CGFloat) -> some View {
        let w = range.weight(h)
        let lit = highlight == h
        return ZStack {
            // A partial weight renders as a proportional fill from the bottom rather
            // than collapsing to one colour, so a mixed range is never misread as
            // pure — the grid is already correct for when R3 starts painting.
            Rectangle().fill(GT.surface)
            if w > 0 {
                GeometryReader { g in
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Rectangle().fill(GT.mint.opacity(0.85))
                            .frame(height: g.size.height * w)
                    }
                }
            }
            Text(h.description)
                .font(.system(size: max(6, side * 0.30), weight: .semibold))
                .minimumScaleFactor(0.5).lineLimit(1)
                .foregroundStyle(w > 0 ? GT.onCTA : GT.inkMuted)
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: max(1.5, side * 0.14)))
        .overlay {
            let ringed = (outline?.weight(h) ?? 0) > 0
            if lit {
                RoundedRectangle(cornerRadius: max(1.5, side * 0.14))
                    .strokeBorder(GT.ink, lineWidth: 2)
            } else if ringed {
                RoundedRectangle(cornerRadius: max(1.5, side * 0.14))
                    .strokeBorder(GT.ink, lineWidth: max(1, side * 0.09))
            }
        }
    }

    private var accessibilitySummary: String {
        let pct = Int(range.percent.rounded())
        if let outline {
            let missed = range.subtracting(outline).comboCount
            let over = outline.subtracting(range).comboCount
            return "레인지 비교 표. 정답 상위 \(pct)%. "
                 + "놓친 콤보 \(missed)개, 넣지 않았어야 할 콤보 \(over)개."
        }
        guard let h = highlight else { return "레인지 표, 상위 \(pct)%" }
        let inside = range.weight(h) > 0
        return "레인지 표, 상위 \(pct)%. \(h.description)는 \(inside ? "포함" : "제외")."
    }
}
