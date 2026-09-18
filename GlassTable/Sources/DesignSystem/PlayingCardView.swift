// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct PlayingCardView: View {
    static let canonicalSize: CGFloat = 68
    static func cornerRadius(for size: CGFloat) -> CGFloat { size * 0.07 }

    let card: Card
    var size: CGFloat = canonicalSize
    var dead: Bool = false
    var faceDown: Bool = false

    private static let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    private static let suitSymbols = ["suit.club.fill", "suit.diamond.fill",
                                      "suit.heart.fill", "suit.spade.fill"]
    private var rank: String { Self.ranks[card.rank - 2] }
    private var suitSymbol: String { Self.suitSymbols[card.suit] }
    private var ink: Color { card.suit == 1 || card.suit == 2 ? GT.cardSuitRed : GT.cardInk }

    var body: some View {
        Group {
            if faceDown { back } else { face }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(faceDown
                            ? "아직 나오지 않은 카드"
                            : "\(card.spokenKorean)\(dead ? ", 제외" : "")")
    }

    private var back: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius(for: size))
            .fill(GT.feltDeep)
            .overlay(RoundedRectangle(cornerRadius: Self.cornerRadius(for: size))
                .strokeBorder(GT.hairlineFelt, lineWidth: 1.5))
            .overlay(Image(systemName: "suit.spade.fill")
                .font(.system(size: size * 0.28))
                .foregroundStyle(GT.onFelt.opacity(0.22)))
            .frame(width: size * 0.72, height: size)
    }

    private var face: some View {
        VStack(spacing: 0) {
            index
                .frame(maxWidth: .infinity, alignment: .leading)

            centerArtwork
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            index
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, size * 0.045)
        .padding(.vertical, size * 0.025)
        .foregroundStyle(ink)
        .frame(width: size * 0.72, height: size)
        .background(Color(hex: 0xFDFEEE), in: RoundedRectangle(cornerRadius: Self.cornerRadius(for: size)))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius(for: size))
                .strokeBorder(GT.cardInk.opacity(0.18), lineWidth: 0.6)
        }
        .overlay {
            if dead {
                Rectangle().fill(GT.cardInk).frame(height: 2)
                    .padding(.horizontal, size * 0.1)
            }
        }
        .opacity(dead ? 0.55 : 1)
    }

    private var index: some View {
        HStack(spacing: size * 0.025) {
            Text(rank)
                .font(GT.fixed(size * 0.265))
                .lineLimit(1)
                .fixedSize()
            Image(systemName: suitSymbol)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: size * 0.13, weight: .bold))
                .frame(width: size * 0.14)
        }
        .frame(height: size * 0.255)
    }

    @ViewBuilder
    private var centerArtwork: some View {
        if card.rank == 14 {
            Image(systemName: suitSymbol)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: size * 0.25, weight: .semibold))
        } else if card.rank >= 11 {
            CourtArtwork(card: card, cardSize: size)
        } else {
            NumberCardPips(rank: card.rank, symbol: suitSymbol, ink: ink)
                .frame(width: size * 0.47)
        }
    }
}

private struct NumberCardPips: View {
    let rank: Int
    let symbol: String
    let ink: Color

    private var positions: [CGPoint] {
        switch rank {
        case 2: [point(0.5, 0.12), point(0.5, 0.88)]
        case 3: [point(0.5, 0.08), point(0.5, 0.50), point(0.5, 0.92)]
        case 4: columns([0.15, 0.85])
        case 5: columns([0.12, 0.88]) + [point(0.5, 0.5)]
        case 6: columns([0.10, 0.50, 0.90])
        case 7: columns([0.08, 0.50, 0.92]) + [point(0.5, 0.28)]
        case 8: columns([0.07, 0.50, 0.93]) + [point(0.5, 0.27), point(0.5, 0.73)]
        case 9: columns([0.07, 0.33, 0.67, 0.93]) + [point(0.5, 0.5)]
        case 10: columns([0.07, 0.33, 0.67, 0.93]) + [point(0.5, 0.23), point(0.5, 0.77)]
        default: []
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(positions.enumerated()), id: \.offset) { _, position in
                Image(systemName: symbol)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: proxy.size.width * 0.22, weight: .semibold))
                    .foregroundStyle(ink)
                    .rotationEffect(.degrees(position.y > 0.5 ? 180 : 0))
                    .position(x: proxy.size.width * position.x,
                              y: proxy.size.height * position.y)
            }
        }
    }

    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    private func columns(_ rows: [CGFloat]) -> [CGPoint] {
        rows.flatMap { y in [point(0.22, y), point(0.78, y)] }
    }
}

/// Crops the public-domain deck to its traditional double-ended court portrait.
/// Native indices remain crisp and identically sized for every rank, including 10.
private struct CourtArtwork: View {
    let card: Card
    let cardSize: CGFloat

    var body: some View {
        Image("card_\(card.suit)_\(card.rank)")
            .resizable()
            .interpolation(.high)
            .frame(width: cardSize * 0.72, height: cardSize)
            .frame(width: cardSize * 0.343, height: cardSize * 0.53)
            .clipped()
            .scaleEffect(0.68)
            .frame(height: cardSize * 0.36)
    }
}

#if DEBUG
struct PlayingCardDeckSpecimen: View {
    private var ranks: [Int] {
        ProcessInfo.processInfo.environment["GT_DEMO_CARD_DECK"] == "high"
            ? [14, 13, 12, 11, 10, 9, 8]
            : [2, 3, 4, 5, 6, 7, 8]
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: GT.Space.related) {
                ForEach(0 ..< 4, id: \.self) { suit in
                    HStack(spacing: 8) {
                        ForEach(ranks, id: \.self) { rank in
                            PlayingCardView(card: Card(rank: rank, suit: suit))
                        }
                    }
                }
                HStack(spacing: 8) {
                    PlayingCardView(card: Card(rank: 14, suit: 2), dead: true)
                    PlayingCardView(card: Card(rank: 14, suit: 3), faceDown: true)
                }
            }
            .padding()
        }
        .background(GT.felt)
    }
}
#endif

#Preview {
    HStack {
        PlayingCardView(card: Card("Ah")!)
        PlayingCardView(card: Card("Ks")!)
        PlayingCardView(card: Card("2h")!, dead: true)
    }
    .padding()
    .background(GT.felt)
}
