// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// The defending chart as a 13×13 grid, decisions.md §B convention: colour = action,
/// red 3벳, green 콜, grey 폴드. Bands come straight from `DefendChart`, so the grid
/// can never drift from what the table actually graded against.
struct DefendGridView: View {
    let opener: Position
    var highlight: HandClass?

    private func action(_ h: HandClass) -> DefendAction {
        if DefendChart.threeBetRange(vsOpenFrom: opener).weight(h) > 0 { return .threeBet }
        if DefendChart.callRange(vsOpenFrom: opener).weight(h) > 0 { return .call }
        return .fold
    }

    private func fill(_ a: DefendAction) -> Color {
        switch a {
        case .threeBet: return GT.suitRed.opacity(0.85)
        case .call: return GT.mint.opacity(0.80)
        case .fold: return GT.surface
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Colour never alone: the legend names each band next to its swatch.
            HStack(spacing: 12) {
                ForEach(DefendAction.allCases, id: \.self) { a in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(fill(a))
                            .frame(width: 9, height: 9)
                        Text(a.rawValue).font(GT.body(10)).foregroundStyle(GT.inkSecondary)
                    }
                }
            }
            GeometryReader { geo in
                let side = (geo.size.width - 1.5 * 12) / 13
                VStack(spacing: 1.5) {
                    ForEach(RangeGrid.ranks, id: \.self) { row in
                        HStack(spacing: 1.5) {
                            ForEach(RangeGrid.ranks, id: \.self) { col in
                                cell(RangeGrid.classAt(row: row, col: col), side: side)
                            }
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(opener.rawValue) 오픈에 대한 디펜드 차트")
    }

    private func cell(_ h: HandClass, side: CGFloat) -> some View {
        let a = action(h)
        return ZStack {
            Rectangle().fill(fill(a))
            Text(h.description)
                .font(.system(size: max(6, side * 0.30), weight: .semibold))
                .minimumScaleFactor(0.5).lineLimit(1)
                .foregroundStyle(a == .fold ? GT.inkMuted : GT.onCTA)
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: max(1.5, side * 0.14)))
        .overlay {
            if highlight == h {
                RoundedRectangle(cornerRadius: max(1.5, side * 0.14))
                    .strokeBorder(GT.ink, lineWidth: 2)
            }
        }
    }
}
