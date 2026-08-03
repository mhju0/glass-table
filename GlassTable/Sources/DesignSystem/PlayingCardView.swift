// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine

struct PlayingCardView: View {
    let card: Card
    var size: CGFloat = 42
    var dead: Bool = false   // "looks like an out but loses" — dimmed + struck
    /// Not dealt yet. Occupies the same footprint so the row never reflows when the
    /// card lands — the eye should follow the card, not the layout.
    var faceDown: Bool = false

    private static let suits = ["♣", "♦", "♥", "♠"]
    private static let suitNames = ["클럽", "다이아", "하트", "스페이드"]
    private static let ranks = ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]
    private var isRed: Bool { card.suit == 1 || card.suit == 2 }
    private var label: String { "\(Self.ranks[card.rank - 2])\(Self.suits[card.suit])" }

    var body: some View {
        if faceDown { back } else { face }
    }

    private var back: some View {
        RoundedRectangle(cornerRadius: size * 0.17)
            .fill(GT.feltDeep)
            .overlay(RoundedRectangle(cornerRadius: size * 0.17)
                .strokeBorder(GT.hairlineFelt, lineWidth: 1.5))
            .overlay(Image(systemName: "suit.spade.fill")
                .font(.system(size: size * 0.28))
                .foregroundStyle(GT.onFelt.opacity(0.22)))
            .frame(width: size * 0.72, height: size)
            .accessibilityLabel("아직 나오지 않은 카드")
    }

    private var face: some View {
        Text(label)
            .font(GT.title(size * 0.36))
            .lineLimit(1)
            .minimumScaleFactor(0.5)   // "10♥" and wide ranks shrink to fit instead of wrapping vertically
            .padding(.horizontal, size * 0.08)  // breathing room — label never touches the card edge
            .foregroundStyle(isRed ? GT.cardSuitRed : GT.cardInk)
            .frame(width: size * 0.72, height: size)
            .background(GT.cardFace, in: RoundedRectangle(cornerRadius: size * 0.17))
            .overlay {
                if dead {
                    Rectangle().fill(GT.cardInk).frame(height: 2)
                        .padding(.horizontal, size * 0.1)
                }
            }
            .opacity(dead ? 0.55 : 1)
            .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
            .accessibilityLabel("\(Self.suitNames[card.suit]) \(Self.ranks[card.rank - 2])\(dead ? ", 제외" : "")")
    }
}

#Preview {
    HStack {
        PlayingCardView(card: Card("Ah")!)
        PlayingCardView(card: Card("Ks")!)
        PlayingCardView(card: Card("2h")!, dead: true)
    }.padding().background(GT.felt)
}
