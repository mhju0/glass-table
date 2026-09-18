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
        VStack(spacing: size * 0.035) {
            Text(rank)
                .font(GT.fixed(size * 0.34))
                .lineLimit(1)
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: suitSymbol)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: size * 0.38, weight: .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, size * 0.085)
        .padding(.top, size * 0.045)
        .padding(.bottom, size * 0.08)
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
