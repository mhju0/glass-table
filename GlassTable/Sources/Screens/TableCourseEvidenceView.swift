// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct TableCourseEvidenceView: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var textSize
    static let chartAnchor = "table-course-chart-top"
    let evidence: TableCourseEvidence

    var body: some View {
        if !evidence.seats.isEmpty || !evidence.cards.isEmpty || !evidence.board.isEmpty
            || !evidence.rows.isEmpty || evidence.chart != nil {
            VStack(alignment: .leading, spacing: GT.Space.related) {
                if !evidence.seats.isEmpty { diagram(evidence.seats) }
                if !evidence.cards.isEmpty { cards(evidence.cards, title: language.text("내 카드", "My cards")) }
                if !evidence.board.isEmpty { cards(evidence.board, title: language.text("공용 카드", "Shared cards")) }
                ForEach(Array(evidence.rows.enumerated()), id: \.offset) { _, row in
                    VStack(alignment: .leading, spacing: GT.Space.compact) {
                        Text(row.label.text(in: language)).font(GT.semibold(14)).foregroundStyle(GT.onTable)
                        Text(row.value.text(in: language)).font(GT.body(14)).foregroundStyle(GT.onTableSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                }
                if let chart = evidence.chart { chartGrid(chart) }
            }
            .padding(GT.Space.related)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GT.tableFeltDeep, in: RoundedRectangle(cornerRadius: GT.Radius.panel))
            .overlay(RoundedRectangle(cornerRadius: GT.Radius.panel).strokeBorder(GT.tableHairline))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("table-course-evidence")
        }
    }

    @ViewBuilder private func diagram(_ seats: [TableCourseSeat]) -> some View {
        Text(language.text("시계 방향", "Clockwise order"))
            .font(GT.semibold(14)).foregroundStyle(GT.onTable)
        if textSize > .large {
            VStack(alignment: .leading, spacing: GT.Space.compact) {
                ForEach(Array(seats.enumerated()), id: \.offset) { offset, seat in
                    seatTile(seat, offset: offset).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let tileWidth = min(94, width * 0.33)
                ZStack {
                    Ellipse().strokeBorder(GT.tableHairline, lineWidth: 1)
                        .frame(width: width - tileWidth, height: height - 48)
                        .accessibilityHidden(true)
                    ForEach(Array(seats.enumerated()), id: \.offset) { offset, seat in
                        let angle = -Double.pi / 2 + (2 * .pi * Double(offset) / Double(seats.count))
                        seatTile(seat, offset: offset)
                            .frame(width: tileWidth)
                            .position(x: width / 2 + (width - tileWidth) / 2 * cos(angle),
                                      y: height / 2 + (height - 66) / 2 * sin(angle))
                    }
                }
            }
            .frame(height: seats.count > 4 ? 278 : 222)
        }
    }

    private func seatTile(_ seat: TableCourseSeat, offset: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: GT.Radius.control)
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                if seat.highlighted {
                    Image(systemName: "scope").font(GT.semibold(11))
                        .foregroundStyle(GT.onTable).accessibilityHidden(true)
                }
                Text(seat.label.text(in: language)).font(GT.semibold(13)).foregroundStyle(GT.onTable)
            }
            if let detail = seat.detail { Text(detail.text(in: language)).font(GT.body(12)) }
            if let chips = seat.chips {
                Text(language.text("\(chips)칩", chips == 1 ? "1 chip" : "\(chips) chips"))
                    .font(GT.body(12).monospacedDigit())
            }
            if seat.folded { Text(language.text("폴드", "Folded")).font(GT.body(12)) }
        }
        .foregroundStyle(GT.onTableSecondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.tableFeltDeep, in: shape)
        .overlay(shape.strokeBorder(seat.highlighted ? GT.actionFill : GT.tableHairline,
                                    lineWidth: seat.highlighted ? 2 : 1))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(seat.highlighted ? .isSelected : [])
        .accessibilitySortPriority(Double(-offset))
        .accessibilityIdentifier("table-course-seat-\(offset)")
    }

    private func cards(_ cards: [Card], title: String) -> some View {
        VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(title).font(GT.semibold(14)).foregroundStyle(GT.onTable)
            HStack(spacing: GT.Space.compact) {
                ForEach(cards, id: \.self) { PlayingCardView(card: $0, size: 44) }
            }
        }
    }

    private func chartGrid(_ chart: TableCourseChart) -> some View {
        let focusRow = chart.rows.first { $0.contains(where: \.highlighted) }
        let highlighted = focusRow?.first(where: \.highlighted)
        return VStack(alignment: .leading, spacing: GT.Space.compact) {
            Text(chart.title.text(in: language)).font(GT.semibold(15)).foregroundStyle(GT.onTable)
                .fixedSize(horizontal: false, vertical: true)
                .id(Self.chartAnchor)
            if let focusRow, let index = focusRow.firstIndex(where: \.highlighted) {
                let start = max(1, min(index - 1, focusRow.count - 3))
                Label(language.text("표시된 칸", "Highlighted cell"), systemImage: "scope")
                    .font(GT.semibold(14)).foregroundStyle(GT.onTable)
                HStack(spacing: 2) {
                    ForEach(focusRow.dropFirst(start).prefix(3), id: \.label) { cell in
                        chartCell(cell, chart: chart, isHeader: false)
                            .accessibilityIdentifier(cell.highlighted ? "table-course-highlighted-cell" : cell.label)
                    }
                }
                .gtTablePartTextCap()
            }
            Text(language.text("차트를 옆으로 밀어 보세요.", "Swipe sideways for more."))
                .font(GT.body(13)).foregroundStyle(GT.onTableSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    VStack(spacing: 2) {
                        ForEach(Array(chart.rows.enumerated()), id: \.offset) { rowIndex, row in
                            HStack(spacing: 2) {
                                ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, cell in
                                    let isHeader = rowIndex == 0 || columnIndex == 0
                                    chartCell(cell, chart: chart, isHeader: isHeader)
                                        .id(isHeader ? "header-\(rowIndex)-\(columnIndex)" : cell.label)
                                }
                            }
                        }
                    }
                    .gtTablePartTextCap()
                }
                .task(id: highlighted?.label) {
                    if let highlighted {
                        await Task.yield()
                        proxy.scrollTo(highlighted.label, anchor: .center)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("table-course-chart")
            }
        }
    }

    private func chartCell(_ cell: TableCourseChartCell, chart: TableCourseChart, isHeader: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        let fill = isHeader ? GT.tableFeltDeep : cell.active ? GT.actionFill : cell.secondary ? GT.supportFill : GT.glass
        let ink = isHeader ? GT.onTable : cell.active ? GT.actionInk : cell.secondary ? GT.supportInk : GT.ink
        let action = cell.active ? chart.activeLabel : cell.secondary ? chart.secondaryLabel : chart.inactiveLabel
        return Text(cell.label)
            .font(GT.semibold(11).monospaced()).foregroundStyle(ink).lineLimit(1).fixedSize()
            .frame(minWidth: textSize.isAccessibilitySize ? 56 : 31, minHeight: textSize.isAccessibilitySize ? 36 : 24)
            .background(fill, in: shape)
            .overlay(alignment: .topTrailing) {
                if cell.active || cell.secondary {
                    Image(systemName: cell.active ? "plus" : "circle.fill")
                        .font(GT.fixed(5).bold())
                        .foregroundStyle(ink)
                        .padding(2)
                        .accessibilityHidden(true)
                }
            }
            .overlay {
                if cell.highlighted {
                    shape.strokeBorder(ink, lineWidth: 2)
                }
            }
            .accessibilityHidden(isHeader)
            .accessibilityValue(action?.text(in: language) ?? "")
            .accessibilityAddTraits(cell.highlighted ? .isSelected : [])
    }
}
