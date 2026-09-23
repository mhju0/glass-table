// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// The defending chart as a 13×13 grid, decisions.md §B convention: colour = action,
/// red 3벳, amber 콜, grey 폴드. Bands come straight from `DefendChart`, so the grid
/// can never drift from what the table actually graded against.
struct DefendGridView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let opener: Position
    var highlight: HandClass?

    private func action(_ h: HandClass) -> DefendAction {
        if DefendChart.threeBetRange(vsOpenFrom: opener).weight(h) > 0 { return .threeBet }
        if DefendChart.callRange(vsOpenFrom: opener).weight(h) > 0 { return .call }
        return .fold
    }

    static func bandFill(_ a: DefendAction) -> Color {
        switch a {
        case .threeBet: return GT.suitRed
        case .call: return GT.cta
        case .fold: return GT.surface
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let highlight {
                selectedHandSummary(highlight)
            }
            // Colour never alone: the legend names each band next to its swatch.
            HStack(spacing: 12) {
                ForEach(DefendAction.allCases, id: \.self) { a in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(Self.bandFill(a))
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
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(accessibilityRow(row))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .accessibilityElement(children: .contain)
        .overlay(alignment: .topLeading) {
            Color.clear.frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chartAccessibilitySummary)
        }
    }

    private func selectedHandSummary(_ hand: HandClass) -> some View {
        let verdict = action(hand)
        return HStack(spacing: 12) {
            if !dynamicTypeSize.isAccessibilitySize {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Self.bandFill(verdict))
                    Text(hand.description)
                        .font(GT.title(17))
                        .foregroundStyle(verdict == .fold ? GT.ink : GT.onCTA)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 9)
                .frame(minWidth: 54, minHeight: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("내 핸드 \(hand.description) · \(verdict.rawValue)")
                    .font(GT.title(15)).foregroundStyle(GT.ink)
                Text("테두리로 강조한 칸이 차트 속 내 핸드 위치예요")
                    .font(GT.body(11)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.surface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("내 핸드 \(hand.description), 디펜드 차트 판정 \(verdict.rawValue)")
        .accessibilityIdentifier("defend-selected-evidence")
    }

    private func accessibilityRow(_ row: Int) -> String {
        let cells = RangeGrid.ranks.map { col in
            let hand = RangeGrid.classAt(row: row, col: col)
            return "\(hand.description) \(action(hand).rawValue)"
        }
        let rank = String(RangeGrid.classAt(row: row, col: row).description.prefix(1))
        return "\(rank) 행. " + cells.joined(separator: ", ")
    }

    private var chartAccessibilitySummary: String {
        guard let highlight else {
            return "\(opener.rawValue) 오픈에 대한 디펜드 차트. 3벳, 콜, 폴드 밴드."
        }
        return "\(opener.rawValue) 오픈에 대한 디펜드 차트. "
             + "내 핸드 \(highlight.description), 판정 \(action(highlight).rawValue)."
    }

    private func cell(_ h: HandClass, side: CGFloat) -> some View {
        let a = action(h)
        return ZStack {
            Rectangle().fill(Self.bandFill(a))
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
        .accessibilityHidden(true)
    }
}
