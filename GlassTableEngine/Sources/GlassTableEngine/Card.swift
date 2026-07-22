// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

public struct Card: Equatable, Hashable, CustomStringConvertible {
    public let rank: Int  // 2...14 (11=J, 12=Q, 13=K, 14=A)
    public let suit: Int  // 0=c, 1=d, 2=h, 3=s

    public init(rank: Int, suit: Int) {
        self.rank = rank
        self.suit = suit
    }

    private static let rankChars = Array("23456789TJQKA")  // index 0 -> rank 2
    private static let suitChars = Array("cdhs")

    public init?(_ text: String) {
        let chars = Array(text)
        guard chars.count == 2,
              let ri = Card.rankChars.firstIndex(of: chars[0]),
              let si = Card.suitChars.firstIndex(of: chars[1])
        else { return nil }
        self.rank = ri + 2
        self.suit = si
    }

    public static func parse(_ s: String) -> [Card]? {
        let chars = Array(s)
        guard chars.count % 2 == 0 else { return nil }
        var out: [Card] = []
        var i = 0
        while i < chars.count {
            guard let c = Card(String(chars[i...i+1])) else { return nil }
            out.append(c)
            i += 2
        }
        return out
    }

    public var description: String {
        "\(Card.rankChars[rank - 2])\(Card.suitChars[suit])"
    }
}

public enum Deck {
    public static let all: [Card] = {
        var cards: [Card] = []
        for rank in 2...14 {
            for suit in 0...3 {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
        return cards
    }()
}
