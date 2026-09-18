// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct PlayingCardView: View {
    static let canonicalSize: CGFloat = 68
    let card: Card
    var size: CGFloat = canonicalSize
    var dead: Bool = false   // "looks like an out but loses" — dimmed + struck
    /// Not dealt yet. Occupies the same footprint so the row never reflows when the
    /// card lands — the eye should follow the card, not the layout.
    var faceDown: Bool = false

    private static let suitSymbols = ["suit.club.fill", "suit.diamond.fill",
                                      "suit.heart.fill", "suit.spade.fill"]
    private static let suitNames = ["클럽", "다이아", "하트", "스페이드"]
    private static let ranks = ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]
    private var isRed: Bool { card.suit == 1 || card.suit == 2 }
    private var rank: String { Self.ranks[card.rank - 2] }

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
        HStack(spacing: size * 0.015) {
            Text(rank)
                .font(GT.fixed(size * 0.25))
                .fixedSize()
            Image(systemName: Self.suitSymbols[card.suit])
                .symbolRenderingMode(.monochrome)
                .font(.system(size: size * 0.19, weight: .semibold))
                .frame(width: size * 0.19, alignment: .center)
        }
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
            .accessibilityLabel("\(card.spokenKorean)\(dead ? ", 제외" : "")")
    }
}

#Preview {
    HStack {
        PlayingCardView(card: Card("Ah")!)
        PlayingCardView(card: Card("Ks")!)
        PlayingCardView(card: Card("2h")!, dead: true)
    }.padding().background(GT.felt)
}
