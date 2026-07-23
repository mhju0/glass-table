// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine

struct PlayingCardView: View {
    let card: Card
    var size: CGFloat = 42
    var dead: Bool = false   // "looks like an out but loses" — dimmed + struck

    private static let suits = ["♣", "♦", "♥", "♠"]
    private static let suitNames = ["클럽", "다이아", "하트", "스페이드"]
    private static let ranks = ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]
    private var isRed: Bool { card.suit == 1 || card.suit == 2 }
    private var label: String { "\(Self.ranks[card.rank - 2])\(Self.suits[card.suit])" }

    var body: some View {
        Text(label)
            .font(GT.title(size * 0.36))
            .lineLimit(1)
            .minimumScaleFactor(0.5)   // "10♥" and wide ranks shrink to fit instead of wrapping vertically
            .padding(.horizontal, size * 0.08)  // breathing room — label never touches the card edge
            .foregroundStyle(isRed ? GT.suitRed : GT.ink)
            .frame(width: size * 0.72, height: size)
            .background(.white, in: RoundedRectangle(cornerRadius: size * 0.17))
            .overlay {
                if dead {
                    Rectangle().fill(GT.ink).frame(height: 2)
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
    }.padding().background(GT.green)
}
