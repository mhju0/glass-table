// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

/// Seven cards, the five that play outlined; the rest step back but stay readable.
/// The two private cards come first, set apart from the shared five. Cards whose rank
/// decided a same-name contest get a thicker outline. Every outline is drawn inside
/// the card, so it never reaches a neighbour.
struct SevenCardRow: View {
    @Environment(\.learningLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let hole: [Card]
    let board: [Card]
    let used: [Card]
    var deciding: [Card] = []
    var comparisonCards: [Card] = []
    let size: CGFloat
    /// Sets the last shared card apart as the river, as the outs answer deals it.
    var separatesRiver = false
    @State private var showsCue = false

    /// The row's fixed width: card faces never follow Dynamic Type.
    static func width(size: CGFloat) -> CGFloat { 7 * size * 0.72 + 6 * 5 + 8 }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array((hole + board).enumerated()), id: \.offset) { index, card in
                cell(card, plays: used.contains(card), decides: deciding.contains(card), index: index)
            }
        }
        .onAppear {
            guard !comparisonCards.isEmpty || !deciding.isEmpty else { return }
            withAnimation(reduceMotion ? nil : GT.Motion.fade) { showsCue = true }
        }
    }

    private func cell(_ card: Card, plays: Bool, decides: Bool, index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: PlayingCardView.cornerRadius(for: size))
        let isEvidence = decides || comparisonCards.contains(card)
        let note = !plays ? language.text(", 쓰지 않음", ", not used")
            : decides ? language.text(", 승부를 가른 카드", ", decided it")
            : isEvidence ? language.text(", 비교할 카드", ", comparison card") : ""
        return PlayingCardView(card: card, size: size)
            .overlay {
                if isEvidence {
                    shape.strokeBorder(GT.cardInk, lineWidth: 2)
                    shape.inset(by: 2).strokeBorder(GT.tableAccent, lineWidth: 2)
                        .opacity(showsCue || reduceMotion ? 1 : 0)
                } else if plays {
                    shape.strokeBorder(GT.cardInk, lineWidth: 1)
                }
            }
            .opacity(plays ? 1 : 0.55)
            .padding(.leading, index == 2 || (separatesRiver && index == 6) ? 8 : 0)
            .accessibilityLabel(card.spoken(in: language) + note)
    }
}

extension BestFiveHand {
    /// Emphasize the cards that form this hand type using the evaluator's five.
    var comparisonCards: [Card] {
        guard deciding.isEmpty else { return deciding }
        switch brief.category {
        case 1, 3, 7: // Pair, trips, quads
            return used.filter { $0.rank == brief.topRank }
        case 2: // Two pair
            let pairs = Dictionary(grouping: used, by: \.rank)
            return used.filter { pairs[$0.rank]?.count == 2 }
        case 4, 5, 6, 8: // Straight, flush, full house, straight flush
            return used
        default:
            return []
        }
    }
}

/// Two players' seven cards after the answer is in: each row dims the two cards that
/// do not play, names the hand and counts how many of the five came from the player.
/// The sentence underneath is the reveal's own. Never shown before an answer is locked.
struct BestFiveComparison: View {
    @Environment(\.learningLanguage) private var language
    let pair: BestFivePair

    /// About 290pt for seven cards, so the row fits a 375pt-wide phone inside a card.
    static let cardSize: CGFloat = 50

    var body: some View {
        VStack(alignment: .leading, spacing: GT.Space.related) {
            ForEach(Array(pair.rows.enumerated()), id: \.offset) { index, hand in
                row(hand, index: index)
            }
            Text(pair.why(in: language))
                .font(GT.body(GT.Typography.explanationSize)).foregroundStyle(GT.ink)
                .lineSpacing(GT.Typography.explanationLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("best-five-why")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("best-five-comparison")
    }

    private func row(_ hand: BestFiveHand, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(hand.owner.title(in: language))
                    .font(GT.semibold(13)).foregroundStyle(GT.inkSecondary)
                Text(hand.name(in: language))
                    .font(GT.title(17)).foregroundStyle(GT.ink)
                Text(hand.countLine(in: language))
                    .font(GT.body(14)).foregroundStyle(GT.inkSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("best-five-label-\(index)")
            SevenCardRow(hole: hand.hole, board: hand.board, used: hand.used,
                         deciding: hand.deciding, comparisonCards: hand.comparisonCards,
                         size: Self.cardSize)
                .fixedSize()
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("best-five-cards-\(index)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("best-five-row-\(index)")
    }
}
