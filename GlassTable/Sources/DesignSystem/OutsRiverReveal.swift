// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// The outs answer once it is locked in: both players' seven cards with one river
/// dealt, then every winning river grouped by the kind of hand it gives me. A tap
/// deals that river into both rows; the names, the five that play and the line
/// underneath come from `BestFivePair` for that card. The first winning card starts
/// picked, so the rows are never empty. Never shown before an answer is locked in.
struct OutsRiverReveal: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.dynamicTypeSize) private var typeSize
    let spot: OutsSpot
    @State private var picked: Card?

    private static let rowCardSize: CGFloat = 40
    private static let listCardSize: CGFloat = 30
    /// The type names' column beside the river cards; nine 30pt cards fit after it on
    /// a 375pt-wide phone.
    private static let labelWidth: CGFloat = 88

    var body: some View {
        let groups = OutsOutcomeGroups.make(hero: spot.hero, villain: spot.villain,
                                            board: spot.board, candidates: spot.outs)
        let river = picked ?? groups.first?.cards.first ?? spot.excluded.first
        // Tighter than GT.Space.related so the English labels, which stack more often,
        // still leave every river card above the folded sheet on a 375×812 phone.
        VStack(alignment: .leading, spacing: 8) {
            if let river { rows(river) }
            SectionLabel(text: language.text("이기는 리버 \(spot.outCount)장 · 눌러서 비교",
                                             "Winning rivers · \(spot.outCount) · tap to compare"))
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    groupRow(title: typeName(group), count: countText(group.cards.count),
                             cards: group.cards, dead: false, river: river)
                        .accessibilityIdentifier("outs-group-\(index)")
                }
                if !spot.excluded.isEmpty {
                    groupRow(title: language.text("제외 · 무승부 또는 패배", "Excluded · ties or losses"),
                             count: nil, cards: spot.excluded.sorted(by: BeatScript.byRank),
                             dead: true, river: river)
                        .accessibilityIdentifier("outs-group-excluded")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The opponent's seven cards and mine, the river set apart at the end.
    private func rows(_ river: Card) -> some View {
        let pair = BestFivePair(first: spot.villain, firstOwner: .opponent,
                                second: spot.hero, secondOwner: .learner, board: spot.board + [river])
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(pair.rows.enumerated()), id: \.offset) { index, hand in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(index == 0 ? language.text("상대", "Opponent") : language.text("나", "You"))
                            .font(GT.semibold(13)).foregroundStyle(GT.onFeltSecondary)
                        Text(hand.name(in: language))
                            .font(GT.title(15)).foregroundStyle(GT.onFelt)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("outs-row-label-\(index)")
                    SevenCardRow(hole: hand.hole, board: hand.board, used: hand.used,
                                 deciding: hand.deciding, size: Self.rowCardSize, separatesRiver: true)
                        .fixedSize()
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("outs-row-cards-\(index)")
                }
            }
            Text(pair.why(in: language))
                .font(GT.body(15)).foregroundStyle(GT.onFelt)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("outs-why")
        }
    }

    @ViewBuilder
    private func groupRow(title: String, count: String?, cards: [Card], dead: Bool, river: Card?) -> some View {
        let name = Text(title).font(GT.semibold(14)).foregroundStyle(GT.onFelt)
        let number = count.map {
            Text($0).font(GT.body(13).monospacedDigit()).foregroundStyle(GT.onFeltSecondary)
        }
        // The count sits beside a short name and under a long one.
        let label = ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 5) { name; number }.fixedSize()
            VStack(alignment: .leading, spacing: 0) { name; number }
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        let list = FlowRow(spacing: 5) {
            ForEach(cards, id: \.self) { card in riverButton(card, dead: dead, picked: card == river) }
        }
        // At accessibility sizes the name takes its own line above the fixed-size cards.
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) { label; list }
                .accessibilityElement(children: .contain)
        } else {
            HStack(alignment: .center, spacing: 10) {
                label.frame(width: Self.labelWidth, alignment: .leading)
                list
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func riverButton(_ card: Card, dead: Bool, picked isPicked: Bool) -> some View {
        Button {
            withAnimation(GT.Motion.change) { picked = card }
        } label: {
            PlayingCardView(card: card, size: Self.listCardSize, dead: dead)
                .overlay {
                    if isPicked {
                        RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: Self.listCardSize))
                            .strokeBorder(GT.cta, lineWidth: 2.5)
                    }
                }
                // Without it the next card's hit area covered most of this one, so a
                // tap on 9♥ dealt 8♥ (OutsRevealTests).
                .contentShape(Rectangle())
        }
        .buttonStyle(GTPress())
        .accessibilityLabel(card.spoken(in: language))
        .accessibilityAddTraits(isPicked ? .isSelected : [])
        .accessibilityHint(language.text("리버로 넣어 두 패 비교하기", "Deal it as the river and compare both hands"))
        .accessibilityIdentifier("outs-river-\(card.description)")
    }

    /// The kind of hand, named as on the hand-rank page.
    private func typeName(_ group: OutsOutcomeGroup) -> String {
        HoldemBasics.ladder.first { $0.category == group.category && $0.isRoyal == group.isRoyal }?
            .name(in: language) ?? ""
    }

    private func countText(_ count: Int) -> String {
        language.text("\(count)장", count == 1 ? "1 card" : "\(count) cards")
    }
}
