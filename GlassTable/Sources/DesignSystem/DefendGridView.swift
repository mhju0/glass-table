// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// The defending chart as a 13×13 grid, decisions.md §B convention: colour = action,
/// red 3벳, amber 콜, grey 폴드. Bands come straight from `DefendChart`, so the grid
/// can never drift from what the table actually graded against.
struct DefendGridView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.learningLanguage) private var language
    @State private var showExplorer = false
    let opener: Position
    var highlight: HandClass?
    var cards: [Card] = []

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
                        Text(language.text(a.rawValue, a.englishTitle)).font(GT.body(10)).foregroundStyle(GT.inkSecondary)
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
            Button { showExplorer = true } label: {
                Label(language.text("크게 보고 핸드 찾기", "Enlarge and explore hands"), systemImage: "plus.magnifyingglass")
                    .font(GT.semibold(14)).frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(GTPress())
        }
        .sheet(isPresented: $showExplorer) {
            DefendChartExplorer(opener: opener, ownHand: highlight)
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
            if cards.count == 2 {
                HStack(spacing: 5) {
                    ForEach(cards, id: \.self) { card in PlayingCardView(card: card, size: 46) }
                }
            } else if !dynamicTypeSize.isAccessibilitySize {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Self.bandFill(verdict))
                    Text(hand.description)
                        .font(GT.title(17))
                        .foregroundStyle(verdict == .fold ? GT.ink : GT.onCTA)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(width: 54, height: 44)
                .padding(.horizontal, 9)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(language.text("내 핸드 \(hand.description) · \(verdict.rawValue)", "My hand \(hand.description) · \(verdict.englishTitle)"))
                    .font(GT.title(15)).foregroundStyle(GT.ink)
                Text(language.text("테두리로 표시한 칸이 내 핸드예요", "The outlined cell is your hand"))
                    .font(GT.body(11)).foregroundStyle(GT.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GT.surface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(language.text("내 핸드 \(hand.description), 디펜드 차트 판정 \(verdict.rawValue)", "My hand \(hand.description), chart action \(verdict.englishTitle)"))
        .accessibilityIdentifier("defend-selected-evidence")
    }

    private func accessibilityRow(_ row: Int) -> String {
        let cells = RangeGrid.ranks.map { col in
            let hand = RangeGrid.classAt(row: row, col: col)
            return "\(hand.description) \(language.text(action(hand).rawValue, action(hand).englishTitle))"
        }
        let rank = String(RangeGrid.classAt(row: row, col: row).description.prefix(1))
        return language.text("\(rank) 행. ", "\(rank) row. ") + cells.joined(separator: ", ")
    }

    private var chartAccessibilitySummary: String {
        guard let highlight else {
            return language.text("\(opener.rawValue) 오픈에 대한 디펜드 차트. 3벳, 콜, 폴드 밴드.", "Response chart against a raise from \(opener.rawValue). Raise, call and fold bands.")
        }
        return language.text("\(opener.rawValue) 오픈에 대한 디펜드 차트. 내 핸드 \(highlight.description), 판정 \(action(highlight).rawValue).", "Response chart against \(opener.rawValue). My hand \(highlight.description), action \(action(highlight).englishTitle).")
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

private extension DefendAction {
    var englishTitle: String {
        switch self { case .fold: "Fold"; case .call: "Call"; case .threeBet: "Raise again" }
    }
}

private struct DefendChartExplorer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var typeSize
    let opener: Position
    let ownHand: HandClass?
    @State private var selected: HandClass?

    private func action(_ hand: HandClass) -> DefendAction {
        if DefendChart.threeBetRange(vsOpenFrom: opener).weight(hand) > 0 { return .threeBet }
        if DefendChart.callRange(vsOpenFrom: opener).weight(hand) > 0 { return .call }
        return .fold
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("핸드 차트", "Hand chart")).font(GT.title(24))
                    Text(language.text("s는 같은 무늬, o는 다른 무늬예요. AA처럼 같은 글자는 페어예요.", "s means same suit; o means different suits. Repeated ranks, like AA, are pairs."))
                        .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
                    if let hand = selected ?? ownHand {
                        let verdict = action(hand)
                        Text("\(hand.description) · \(language.text(verdict.rawValue, verdict.englishTitle))")
                            .font(GT.title(19)).accessibilityIdentifier("chart-explorer-selection")
                    }
                    if let ownHand {
                        Button(language.text("내 핸드로 돌아가기", "Return to my hand")) {
                            selected = ownHand
                            proxy.scrollTo(ownHand.description, anchor: .center)
                        }.frame(minHeight: 44)
                    }
                    ScrollView([.horizontal, .vertical]) {
                        VStack(spacing: 4) {
                            ForEach(RangeGrid.ranks, id: \.self) { row in
                                HStack(spacing: 4) {
                                    ForEach(RangeGrid.ranks, id: \.self) { col in
                                        let hand = RangeGrid.classAt(row: row, col: col)
                                        let verdict = action(hand)
                                        Button { selected = hand } label: {
                                            VStack(spacing: 4) {
                                                Text(hand.description).font(GT.semibold(15))
                                                Text(language.text(verdict.rawValue, verdict.englishTitle))
                                                    .font(GT.body(11))
                                            }
                                            .frame(width: typeSize.isAccessibilitySize ? 150 : 78)
                                            .frame(minHeight: typeSize.isAccessibilitySize ? 140 : 60)
                                            .foregroundStyle(verdict == .fold ? GT.ink : GT.onCTA)
                                            .background(DefendGridView.bandFill(verdict), in: RoundedRectangle(cornerRadius: 8))
                                            .overlay {
                                                if hand == (selected ?? ownHand) {
                                                    RoundedRectangle(cornerRadius: 8).strokeBorder(GT.ink, lineWidth: 3)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .id(hand.description)
                                        .accessibilityIdentifier("chart-cell-\(hand.description)")
                                        .accessibilityLabel("\(hand.description), \(language.text(verdict.rawValue, verdict.englishTitle))")
                                        .accessibilityAddTraits(hand == (selected ?? ownHand) ? .isSelected : [])
                                    }
                                }
                            }
                        }.padding(4)
                    }
                    .onAppear {
                        if let ownHand { proxy.scrollTo(ownHand.description, anchor: .center) }
                    }
                }
                .padding(18)
            }
            .background(FeltBackground())
            .gtChrome(.topBarLeading) { ChromeButton.close { dismiss() } }
            .gtChrome(.topBarTrailing) { LanguageButton() }
        }
    }
}
