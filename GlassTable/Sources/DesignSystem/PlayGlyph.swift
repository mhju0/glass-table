// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine

/// The Play list's row pictures (owner, 2026-10-18: D2·c, with D2·d for graded practice),
/// drawn in Learn's glyph language (`SkillGlyph`): the same plain tile, white mini cards,
/// grey for everything else, green only for "good" and amber only on the open table.
/// Purely decorative: each row's text carries the meaning. Everything stays fixed-size.
struct PlayGlyph: View {
    enum Kind {
        /// The open table: the learner's two cards (backs between hands) and the hand count.
        case open(hole: [Card], hand: Int, of: Int?)
        case quick, long, graded, review
    }

    let kind: Kind

    var body: some View {
        picture
            .frame(width: 64, height: 48)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: GT.Radius.tile, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder private var picture: some View {
        switch kind {
        case let .open(hole, hand, limit):
            VStack(spacing: 3) {
                HStack(spacing: 2) {
                    if hole.count == 2 {
                        face(hole[0], highlighted: true)
                        face(hole[1], highlighted: true)
                    } else {
                        back(highlighted: true)
                        back(highlighted: true)
                    }
                }
                Text(limit.map { "\(hand) / \($0)" } ?? "\(hand)")
                    .font(GT.fixed(10)).foregroundStyle(GT.onFeltSecondary)
            }
        case .quick, .long:
            HStack(spacing: 8) {
                ZStack {
                    ForEach(-1...1, id: \.self) { step in
                        back()
                            .overlay(Self.shape.stroke(GT.surface, lineWidth: 1))
                            .rotationEffect(.degrees(Double(step) * 14))
                            .offset(x: CGFloat(step) * 8, y: step == 0 ? -2 : 0)
                    }
                }
                .frame(width: 30)
                if case .quick = kind {
                    Text("\(TableSetupView.quickHands)").font(GT.fixed(12)).foregroundStyle(GT.onFeltSecondary)
                } else {
                    Image(systemName: "infinity").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GT.onFeltSecondary)
                }
            }
        case .graded:
            HStack(spacing: 7) {
                back()
                VStack(spacing: 4) {
                    Circle().fill(GT.green).frame(width: 11, height: 11)
                        .overlay(Image(systemName: "checkmark").font(.system(size: 6, weight: .heavy))
                            .foregroundStyle(GT.surface))
                    Circle().strokeBorder(GT.onFeltMuted, lineWidth: 1.2).frame(width: 11, height: 11)
                        .overlay(Image(systemName: "xmark").font(.system(size: 5, weight: .bold))
                            .foregroundStyle(GT.onFeltMuted))
                }
            }
        case .review:
            HStack(alignment: .bottom, spacing: 2) {
                back()
                back()
                face(Card(rank: 11, suit: 2)).offset(y: -5)
                back()
            }
        }
    }

    private static let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    private static let suits = ["suit.club.fill", "suit.diamond.fill", "suit.heart.fill", "suit.spade.fill"]
    private static let shape = RoundedRectangle(cornerRadius: 2.5, style: .continuous)

    /// Learn's white mini card (`SkillGlyph.card`), with the suit under the rank so a
    /// real hand reads at a glance. An amber edge marks the learner's own cards.
    private func face(_ card: Card, highlighted: Bool = false) -> some View {
        let red = card.suit == 1 || card.suit == 2
        return VStack(spacing: 0) {
            Text(Self.ranks[card.rank - 2]).font(GT.fixed(card.rank == 10 ? 6.5 : 7.5))
            Image(systemName: Self.suits[card.suit]).font(.system(size: 6, weight: .semibold))
        }
        .foregroundStyle(red ? GT.cardSuitRed : GT.cardInk)
        .frame(width: 12, height: 17)
        .background(GT.cardFace, in: Self.shape)
        .overlay(Self.shape.stroke(highlighted ? GT.mint : GT.cardEdge, lineWidth: highlighted ? 1.5 : 0.5))
    }

    /// A face-down card in Learn's grey, the size of its white cards.
    private func back(highlighted: Bool = false) -> some View {
        Self.shape.fill(GT.onFeltMuted)
            .frame(width: 12, height: 17)
            .overlay(Self.shape.stroke(GT.mint, lineWidth: highlighted ? 1.5 : 0))
    }
}
