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
    @Environment(\.learningLanguage) private var language
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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityRow(row))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .overlay(alignment: .topLeading) {
            // Keep the quick total before the 13 navigable rows. VoiceOver users can
            // hear the range size/comparison without traversing all 169 cells, then
            // inspect any row when they need the underlying evidence.
            Color.clear.frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)
        }
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
                .lineLimit(1)
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
        .accessibilityHidden(true)
    }

    private func accessibilityRow(_ row: Int) -> String {
        let cells = RangeGrid.ranks.map { col in
            let hand = RangeGrid.classAt(row: row, col: col)
            let truth = range.weight(hand) > 0
            let compared = (outline?.weight(hand) ?? 0) > 0
            let state: String
            if outline != nil {
                switch (truth, compared) {
                case (true, true): state = language.text("정답과 선택한 답에 포함", "in both the answer and your choice")
                case (true, false): state = language.text("정답에만 포함", "only in the answer")
                case (false, true): state = language.text("선택한 답에만 포함", "only in your choice")
                case (false, false): state = language.text("제외", "excluded")
                }
            } else {
                state = truth ? language.text("포함", "included") : language.text("제외", "excluded")
            }
            let selected = highlight == hand ? language.text(", 선택한 핸드", ", selected hand") : ""
            return "\(hand.description) \(state)\(selected)"
        }
        let rank = String(RangeGrid.classAt(row: row, col: row).description.prefix(1))
        return language.text("\(rank) 행. ", "Row \(rank). ") + cells.joined(separator: ", ")
    }

    private var accessibilitySummary: String {
        let pct = Int(range.percent.rounded())
        if let outline {
            let missed = range.subtracting(outline).comboCount
            let over = outline.subtracting(range).comboCount
            return language.text("레인지 비교 표. 정답은 전체 조합의 \(pct)%. "
                                 + "놓친 콤보 \(missed)개, 넣지 않았어야 할 콤보 \(over)개.",
                                 "Range comparison. The answer is \(pct)% of all hands. "
                                 + "\(missed) missed combinations and \(over) extra combinations.")
        }
        guard let highlight else { return language.text("레인지 표, 전체 조합의 \(pct)%", "Range chart, \(pct)% of all hands") }
        let inside = range.weight(highlight) > 0
        return language.text("레인지 표, 전체 조합의 \(pct)%. \(KO.topic(highlight.description)) \(inside ? "포함" : "제외").",
                             "Range chart, \(pct)% of all hands. \(highlight.description) is \(inside ? "included" : "excluded").")
    }
}

/// The comparison grid's cells are about 6pt at a phone's width, so the hands that
/// differ are also listed in text: which were missed and which were extra.
struct RangeDifferenceList: View {
    @Environment(\.learningLanguage) private var language
    let truth: HandRange
    let guess: HandRange
    /// Past this many, the row ends with a count instead of more names.
    var limit = 12

    var body: some View {
        let shared = hands(truth.intersection(guess))
        let missed = hands(truth.subtracting(guess))
        let extra = hands(guess.subtracting(truth))
        VStack(alignment: .leading, spacing: 6) {
                row(language.text("일치한 핸드", "Matched hands"), shared)
                if !missed.isEmpty {
                    row(language.text("놓친 핸드", "Missed"), missed)
                }
                if !extra.isEmpty {
                    row(language.text("넘친 핸드", "Extra"), extra)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("range-difference-list")
    }

    /// Strongest first, so the most costly differences are the ones that get named.
    private func hands(_ range: HandRange) -> [HandClass] {
        range.classes.sorted { ($0.high, $0.low, $0.suited ? 1 : 0) > ($1.high, $1.low, $1.suited ? 1 : 0) }
    }

    private func row(_ title: String, _ hands: [HandClass]) -> some View {
        let names = hands.prefix(limit).map(\.description).joined(separator: " ")
        let more = hands.count > limit
            ? language.text(" 외 \(hands.count - limit)개", " and \(hands.count - limit) more") : ""
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(title) · \(language.text("\(hands.count)종류", "\(hands.count) kinds"))")
                .font(GT.semibold(12)).foregroundStyle(GT.onFeltSecondary)
            Text(hands.isEmpty ? language.text("없어요", "None") : names + more)
                .font(GT.body(14).monospacedDigit()).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
